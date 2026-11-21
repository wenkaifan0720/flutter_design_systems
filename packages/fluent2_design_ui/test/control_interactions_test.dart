// Keyboard, pointer, and accessibility behaviour of interactive controls.
import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

Widget _host(Widget child, {double scale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (BuildContext context, Widget? page) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: Fluent2Host(child: page!),
  ),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void _window(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

const _people = [
  Fluent2Option('ana', 'Ana Ruiz'),
  Fluent2Option('kai', 'Kai Chen'),
];

void main() {
  testWidgets('a tooltip waits 250 ms under the pointer and Escape hides it', (
    t,
  ) async {
    _window(t, const Size(800, 600));
    await t.pumpWidget(
      _host(
        Center(
          child: Fluent2Tooltip(
            message: 'Share',
            child: Fluent2IconButton(
              Fluent2Icons.share,
              label: 'Share file',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(t.getCenter(find.byType(Fluent2IconButton)));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('Share'), findsNothing);
    await t.pump(const Duration(milliseconds: 100));
    await t.pumpAndSettle();
    expect(find.text('Share'), findsOneWidget);
    // The bubble stands above its control.
    expect(
      t.getRect(find.text('Share')).bottom,
      lessThan(t.getRect(find.byType(Fluent2IconButton)).top),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(find.text('Share'), findsNothing);
  });

  testWidgets(
    "a combobox's search says Loading, then that it failed, and Try again "
    'runs it again',
    (t) async {
      _window(t, const Size(800, 600));
      final asked = <String>[];
      late Completer<Iterable<Fluent2Option<String>>> answer;
      await t.pumpWidget(
        _host(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              child: Fluent2Combobox<String>(
                label: 'Assignee',
                value: null,
                options: const [],
                onChanged: (_) {},
                search: (words) {
                  asked.add(words);
                  answer = Completer();
                  return answer.future;
                },
              ),
            ),
          ),
        ),
      );
      await t.tap(find.byType(EditableText));
      await t.enterText(find.byType(EditableText), 'ka');
      await t.pump();
      expect(asked, isNotEmpty);
      expect(find.text('Loading'), findsOneWidget);
      answer.completeError(StateError('offline'));
      await t.pump();
      await t.pump();
      expect(find.text("Couldn't load results"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      final before = asked.length;
      await t.tap(find.text('Try again'));
      await t.pump();
      expect(asked.length, before + 1);
      answer.complete(_people.where((p) => p.label.contains('Ka')));
      await t.pump();
      await t.pump();
      expect(find.text('Kai Chen'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'a tab bar is one tab stop: the arrows choose, mirrored right to left, '
    'and a tab says its place',
    (t) async {
      final s = t.ensureSemantics();
      for (final direction in TextDirection.values) {
        var at = 0;
        await t.pumpWidget(
          _host(
            Directionality(
              textDirection: direction,
              child: StatefulBuilder(
                builder: (context, set) => Fluent2TabList(
                  tabs: const ['Chat', 'Files', 'Wiki'],
                  selectedIndex: at,
                  onChanged: (i) => set(() => at = i),
                ),
              ),
            ),
          ),
        );
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        await t.pump();
        await t.sendKeyEvent(
          direction == TextDirection.ltr
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowLeft,
        );
        await t.pumpAndSettle();
        expect(at, 1, reason: direction.name);
        await t.sendKeyEvent(LogicalKeyboardKey.end);
        await t.pumpAndSettle();
        expect(at, 2, reason: direction.name);
        expect(
          find.bySemanticsLabel('Wiki\nTab 3 of 3'),
          findsOneWidget,
          reason: direction.name,
        );
      }
      s.dispose();
    },
  );

  testWidgets('a tab row measures its tabs again as the reader\'s text grows', (
    t,
  ) async {
    _window(t, const Size(390, 844));
    Widget row(double scale) => _host(
      scale: scale,
      Fluent2TabList(
        selectedIndex: 0,
        onChanged: (_) {},
        tabs: [for (var i = 0; i < 6; i++) 'Section $i'],
      ),
    );
    await t.pumpWidget(row(1));
    await t.pumpWidget(row(2));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    final words = t.renderObject<RenderBox>(find.text('Section 0').last);
    final tab = t.renderObject<RenderBox>(
      find
          .ancestor(
            of: find.text('Section 0').last,
            matching: find.byType(RawButton),
          )
          .first,
    );
    expect(tab.size.width, greaterThan(words.size.width));
  });

  testWidgets('a rating clears to no stars on Home', (t) async {
    double? asked;
    await t.pumpWidget(
      _host(
        Fluent2Rating(
          label: 'Rate this meeting',
          value: 3,
          onChanged: (v) => asked = v,
        ),
      ),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.home);
    await t.pump();
    expect(asked, 0);
  });

  testWidgets(
    'a spin button says its value with its next ones, and Page Up goes to '
    'the next ten steps',
    (t) async {
      final s = t.ensureSemantics();
      num value = 2;
      await t.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, set) => Fluent2SpinButton(
              label: 'Copies',
              value: value,
              max: 50,
              onChanged: (v) => set(() => value = v),
            ),
          ),
        ),
      );
      expect(
        t.getSemantics(find.bySemanticsLabel('Copies')),
        isSemantics(
          label: 'Copies',
          value: '2',
          increasedValue: '3',
          decreasedValue: '1',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          isEnabled: true,
          hasEnabledState: true,
        ),
      );
      await t.tap(find.byType(EditableText));
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await t.pump();
      expect(value, 10);
      s.dispose();
    },
  );

  testWidgets(
    'a dialog takes the focus, is an alert to a screen reader when it '
    'confirms, and gives the focus back as it closes',
    (t) async {
      _window(t, const Size(800, 600));
      final s = t.ensureSemantics();
      final opener = FocusNode(debugLabel: 'opener');
      addTearDown(opener.dispose);
      bool? answer;
      await t.pumpWidget(
        _host(
          Builder(
            builder: (context) => Fluent2Button(
              'Delete',
              focusNode: opener,
              onPressed: () async => answer = await Fluent2Dialog.confirm(
                context,
                title: 'Delete Q3 plan.docx?',
                confirmLabel: 'Delete',
              ),
            ),
          ),
        ),
      );
      opener.requestFocus();
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(find.text('Delete Q3 plan.docx?'), findsOneWidget);
      expect(opener.hasFocus, isFalse);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.namesRoute ?? false),
        ),
        findsWidgets,
      );
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(answer, isFalse);
      expect(opener.hasFocus, isTrue);
      s.dispose();
    },
  );

  testWidgets("a phone's sheet goes on a fling down", (t) async {
    _window(t, const Size(390, 844));
    String? picked = 'open';
    await t.pumpWidget(
      _host(
        Builder(
          builder: (context) => Fluent2Button(
            'Sort',
            onPressed: () async => picked = await Fluent2Sheet.show<String>(
              context,
              title: 'Sort by',
              builder: (context) => [const Text('Name'), const Text('Date')],
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Sort'));
    await t.pumpAndSettle();
    expect(find.text('Sort by'), findsOneWidget);
    await t.fling(find.text('Sort by'), const Offset(0, 400), 1500);
    await t.pumpAndSettle();
    expect(find.text('Sort by'), findsNothing);
    expect(picked, isNull);
  });

  testWidgets('a line chart is one tab stop whose arrows step its points', (
    t,
  ) async {
    _window(t, const Size(800, 600));
    await t.pumpWidget(
      _host(
        const SizedBox(
          width: 480,
          child: Fluent2LineChart(
            label: 'Files shared',
            labels: ['Mon', 'Tue', 'Wed'],
            series: [
              Fluent2ChartSeries('You', [3, 5, 4]),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Tue'), findsNothing);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pumpAndSettle();
    // The card names the point the keys reached.
    expect(find.text('Tue'), findsOneWidget);
  });

  testWidgets("a shortcut's keys are the platform's", (t) async {
    const find_ = SingleActivator(LogicalKeyboardKey.keyK, control: true);
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await t.pumpWidget(_host(const Fluent2Kbd.shortcut(find_)));
    expect(find.text('Ctrl+K'), findsOneWidget);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await t.pumpWidget(_host(const Fluent2Kbd.shortcut(find_)));
    expect(find.text('⌃ K'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
