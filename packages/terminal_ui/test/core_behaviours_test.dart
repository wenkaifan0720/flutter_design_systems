// What Terminal's parts do on ui_core's behaviours: a dialog keeps
// the focus and gives it back, a tab bar and a shell's places are one stop,
// F6 crosses from the places to the page, a context menu opens where it is
// asked for, a search says what it is doing, a rating takes digits and a
// tap before its first mark, a line chart picks its points by the keys, and
// a key drawn `^K` is heard in words.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

Widget _host(Widget child, {bool fill = false}) => MaterialApp(
  home: TermTheme(
    data: TermThemeData.dark(),
    child: Builder(
      builder: (context) => ColoredBox(
        color: TermTheme.of(context).background,
        child: fill
            ? child
            : Align(
                alignment: Alignment.topLeft,
                child: Padding(padding: const EdgeInsets.all(16), child: child),
              ),
      ),
    ),
  ),
);

final _desk = TargetPlatformVariant.only(TargetPlatform.macOS);

void _noop() {}

Future<void> _tab(WidgetTester tester, [int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
}

/// Whether the keyboard focus is inside [f].
bool _focusIn(Finder f) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final at = f.evaluate().single;
  var inside = identical(focused, at);
  focused.visitAncestorElements((e) {
    if (identical(e, at)) inside = true;
    return !inside;
  });
  return inside;
}

class _Live<T> extends StatefulWidget {
  const _Live(this.initial, this.build);
  final T initial;
  final Widget Function(BuildContext, T, ValueChanged<T>) build;
  @override
  State<_Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<_Live<T>> {
  late T value = widget.initial;
  @override
  Widget build(BuildContext context) =>
      widget.build(context, value, (v) => setState(() => value = v));
}

void main() {
  testWidgets('a dialog keeps Tab inside and gives the focus back', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TermButton(
            label: 'open',
            onPressed: () => showTermDialog<void>(
              context: context,
              builder: (context) => TermDialog(
                title: 'discard changes',
                content: const Text('the form has edits.'),
                actions: [
                  TermButton(
                    label: 'keep',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const TermButton(label: 'discard', onPressed: _noop),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await _tab(tester);
    final opener = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(TermDialog), findsOneWidget);
    // Round the dialog's two buttons and back, never out of it.
    for (var i = 0; i < 5; i++) {
      await _tab(tester);
      expect(_focusIn(find.byType(TermDialog)), isTrue);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(TermDialog), findsNothing);
    expect(FocusManager.instance.primaryFocus, opener);
  }, variant: _desk);

  testWidgets('the y/N question is an alert to a screen reader', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TermButton(
            label: 'delete',
            onPressed: () => showTermConfirmDialog(
              context: context,
              title: 'delete run',
              message: 'its logs go too.',
              confirmLabel: 'delete',
              sheet: false,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.role == SemanticsRole.alertDialog,
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('a tab bar is one stop; the arrows choose; a tab is heard '
      'with its place', (tester) async {
    final semantics = tester.ensureSemantics();
    final chosen = <int>[];
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Live<int>(
              0,
              (context, v, set) => TermTabBar(
                tabs: const ['steps', 'log', 'env'],
                selectedIndex: v,
                onTap: (i) {
                  chosen.add(i);
                  set(i);
                },
              ),
            ),
            const TermButton(label: 'after', onPressed: _noop),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel(RegExp('log\nTab 2 of 3')), findsOneWidget);
    await _tab(tester);
    expect(_focusIn(find.byType(TermTabBar)), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(chosen, [1]);
    // One stop: the next Tab leaves the bar.
    await _tab(tester);
    expect(_focusIn(find.byType(TermTabBar)), isFalse);
    semantics.dispose();
  }, variant: _desk);

  testWidgets("a shell's places are one stop, the arrows along them; F6 "
      'goes to the page', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 700);
    addTearDown(tester.view.reset);
    final chosen = <int>[];
    await tester.pumpWidget(
      _host(
        _Live<int>(
          0,
          (context, v, set) => TermScaffold(
            title: 'slipway',
            destinations: const [
              TermNavigationDestination(label: 'home', glyph: '~'),
              TermNavigationDestination(label: 'runs', glyph: '▶'),
              TermNavigationDestination(label: 'deploy', glyph: '↑'),
            ],
            selectedIndex: v,
            onDestinationSelected: (i) {
              chosen.add(i);
              set(i);
            },
            body: const Center(
              child: TermButton(label: 'on the page', onPressed: _noop),
            ),
          ),
        ),
        fill: true,
      ),
    );
    await _tab(tester);
    expect(_focusIn(find.byType(TermSideBar)), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(chosen, isEmpty, reason: 'the arrows move; Enter chooses');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, [1]);
    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pumpAndSettle();
    expect(_focusIn(find.byType(TermSideBar)), isFalse);
  }, variant: _desk);

  testWidgets('a context menu opens at a right click and on Shift+F10, in '
      "the menubar's rows", (tester) async {
    await tester.pumpWidget(
      _host(
        const TermContextMenu(
          semanticLabel: 'run #1482',
          menuChildren: [
            RawMenuEntry(label: 'rerun', shortcut: 'r', onPressed: _noop),
            RawMenuEntry(label: 'copy link', onPressed: _noop),
          ],
          child: TermButton(label: 'run #1482', onPressed: _noop),
        ),
      ),
    );
    final at = tester.getCenter(find.text('run #1482'));
    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await mouse.addPointer(location: at);
    addTearDown(mouse.removePointer);
    await mouse.down(at);
    await mouse.up();
    await tester.pumpAndSettle();
    expect(find.byType(TermMenuRow), findsNWidgets(2));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(TermMenuRow), findsNothing);
    await _tab(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(find.byType(TermMenuRow), findsNWidgets(2));
  }, variant: _desk);

  testWidgets('a search says it is looking, what it found, and that it '
      'failed over a row that tries again', (tester) async {
    var answer = Completer<Iterable<String>>();
    var asked = 0;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 320,
          child: TermCombobox<String>(
            labelText: 'branch',
            options: const [],
            search: (q) {
              asked++;
              return answer.future;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'ma');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('searching'), findsOneWidget);
    answer.complete(['main', 'release/main']);
    await tester.pumpAndSettle();
    expect(find.text('searching'), findsNothing);
    expect(find.text('release/main'), findsOneWidget);
    answer = Completer();
    await tester.enterText(find.byType(EditableText), 'mai');
    await tester.pump();
    answer.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('search failed'), findsOneWidget);
    final before = asked;
    answer = Completer();
    await tester.tap(find.text('try again'));
    await tester.pump();
    expect(asked, before + 1);
    expect(find.text('searching'), findsOneWidget);
    answer.complete(const []);
    await tester.pumpAndSettle();
  }, variant: _desk);

  testWidgets('a rating takes the digits, and a tap before its first mark '
      'gives none', (tester) async {
    var stars = 3;
    await tester.pumpWidget(
      _host(
        _Live<int>(
          3,
          (context, v, set) => TermRating(
            semanticLabel: 'how did it go',
            value: v,
            onChanged: (n) {
              stars = n;
              set(n);
            },
          ),
        ),
      ),
    );
    await _tab(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await tester.pumpAndSettle();
    expect(stars, 5);
    final cell = tester.element(find.byType(TermRating)).termGrid.cellWidth;
    final start = tester.getTopLeft(find.byType(TermRating));
    final mid = tester.getCenter(find.byType(TermRating)).dy;
    await tester.tapAt(Offset(start.dx + cell / 2, mid));
    await tester.pumpAndSettle();
    expect(stars, 0);
  }, variant: _desk);

  testWidgets('a line chart is a stop whose arrows pick its points', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 320,
          child: TermLineChart(
            semanticLabel: 'deploys',
            series: [
              TermSeries(label: 'deploys', values: [10, 33, 20]),
            ],
          ),
        ),
      ),
    );
    final shown = find.text('20').evaluate().length;
    await _tab(tester);
    expect(_focusIn(find.byType(TermLineChart)), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    // The last point's readout over the plot.
    expect(find.text('20').evaluate().length, shown + 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('20').evaluate().length, shown);
  }, variant: _desk);

  testWidgets('a key drawn ^K is heard in words', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        TermKey.of(
          const SingleActivator(LogicalKeyboardKey.keyK, control: true),
        ),
      ),
    );
    expect(find.text('^K'), findsOneWidget);
    final heard = tester.getSemantics(find.byType(TermKey)).label;
    expect(heard, isNot(contains('^')));
    expect(heard, endsWith('+K'));
    semantics.dispose();
  }, variant: _desk);
}
