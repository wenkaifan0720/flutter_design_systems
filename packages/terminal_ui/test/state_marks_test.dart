// The marks a part's states paint. A field's focus is its caret and its one
// line heavy in the accent, never a second line round it (a doubled line is
// a pane's). A choice with an error keeps its ✗ when it is disabled. The
// pointer's mark is the accent's ink and nothing more, lighter than the
// keyboard's cursor, in a menu too until a key is pressed.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

final _themes = {'paper': TermThemeData.light, 'night': TermThemeData.dark};

Widget _host(TermThemeData theme, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: TermTheme(
    data: theme,
    child: ColoredBox(
      color: theme.background,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(width: 480, child: child),
        ),
      ),
    ),
  ),
);

/// The painters under [of], foreground ones too.
List<T> _painters<T>(WidgetTester t, Finder of) => [
  for (final paint in t.widgetList<CustomPaint>(
    find.descendant(of: of, matching: find.byType(CustomPaint)),
  ))
    for (final painter in [paint.painter, paint.foregroundPainter])
      if (painter is T) painter as T,
];

Color? _ink(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style?.color ??
    DefaultTextStyle.of(t.element(find.text(text))).style.color;

Future<TestGesture> _mouse(WidgetTester t) async {
  final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  return mouse;
}

void main() {
  setUpAll(loadFaces);

  for (final MapEntry(key: name, value: themeOf) in _themes.entries) {
    group(name, () {
      final theme = themeOf();

      testWidgets("a field's focus takes its one line heavy to the accent", (
        t,
      ) async {
        final node = FocusNode();
        addTearDown(node.dispose);
        await t.pumpWidget(
          _host(
            theme,
            TermTextField(
              focusNode: node,
              labelText: 'branch',
              hintText: 'main',
            ),
          ),
        );
        final frame = find.byType(TermFieldFrame);
        final rest = _painters<TermFramePainter>(t, frame).single;
        expect(rest.color, theme.rule);
        node.requestFocus();
        await t.pumpAndSettle();
        final line = _painters<TermFramePainter>(t, frame).single;
        expect(line.color, theme.accent);
        expect(line.stroke, rest.stroke * 2);
        expect(line.doubled, 0);
      });

      testWidgets("a one-time code's cell with the keys keeps one line", (
        t,
      ) async {
        final node = FocusNode();
        addTearDown(node.dispose);
        await t.pumpWidget(_host(theme, TermOtpField(focusNode: node)));
        node.requestFocus();
        await t.pumpAndSettle();
        final cells = _painters<TermBracketPainter>(
          t,
          find.byType(TermOtpField),
        );
        final keys = cells.where((c) => c.color == theme.accent).single;
        final others = cells.where((c) => c.color != theme.accent);
        expect(keys.stroke, others.first.stroke * 2);
        expect(cells.every((c) => c.doubled == 0), isTrue);
      });

      testWidgets('a disabled choice with an error keeps its ✗', (t) async {
        await t.pumpWidget(
          _host(
            theme,
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TermCheckbox(
                  value: false,
                  label: 'accept the terms',
                  isError: true,
                  onChanged: null,
                ),
              ],
            ),
          ),
        );
        expect(find.text('✗'), findsOneWidget);
        expect(_ink(t, '✗'), theme.danger);
        // The rest is dim, as any disabled choice's.
        expect(_ink(t, 'accept the terms'), theme.rule);
        expect(
          _painters<TermBracketPainter>(
            t,
            find.byType(TermCheckbox),
          ).single.color,
          theme.rule.withValues(alpha: 0.6),
        );
      });

      testWidgets('an enabled choice with an error says it twice', (t) async {
        await t.pumpWidget(
          _host(
            theme,
            TermCheckbox(
              value: false,
              label: 'accept the terms',
              isError: true,
              onChanged: (_) {},
            ),
          ),
        );
        expect(_ink(t, '✗'), theme.danger);
        expect(
          _painters<TermBracketPainter>(
            t,
            find.byType(TermCheckbox),
          ).single.color,
          theme.danger,
        );
      });

      final bracketed = <String, (Widget, Color)>{
        'a button': (
          TermButton(label: 'cancel', onPressed: () {}),
          theme.accent,
        ),
        'a filled button': (
          TermButton.filled(label: 'deploy', onPressed: () {}),
          theme.foreground,
        ),
        'a glyph button': (
          TermIconButton(glyph: '?', semanticLabel: 'help', onPressed: () {}),
          theme.accent,
        ),
        'a chip': (
          TermChip(label: 'mine', selected: false, onSelected: (_) {}),
          theme.accent,
        ),
        'a chosen chip': (
          TermChip(label: 'mine', selected: true, onSelected: (_) {}),
          theme.accent,
        ),
        'a checkbox': (
          TermCheckbox(value: false, label: 'on success', onChanged: (_) {}),
          theme.accent,
        ),
        'a radio': (
          TermRadio<String>(
            value: 'blue-green',
            groupValue: 'rolling',
            label: 'blue-green',
            onChanged: (_) {},
          ),
          theme.accent,
        ),
        'a switch': (
          TermSwitch(value: false, label: 'follow the log', onChanged: (_) {}),
          theme.accent,
        ),
      };
      for (final MapEntry(key: what, value: (part, ink)) in bracketed.entries) {
        testWidgets('under the pointer $what takes the ink in its brackets', (
          t,
        ) async {
          await t.pumpWidget(_host(theme, part));
          final face = find.byType(DesignPressable).first;
          final rest = _painters<TermBracketPainter>(t, face).first;
          final mouse = await _mouse(t);
          await mouse.moveTo(t.getCenter(face));
          await t.pumpAndSettle();
          final over = _painters<TermBracketPainter>(t, face).first;
          expect(over.color, ink);
          expect(over.color, isNot(rest.color));
          // The ink alone: no cursor, no fill that was not there.
          expect(over.cursor, 0);
          expect(over.fill, rest.fill);
          expect(over.fillAmount, rest.fillAmount);
          await mouse.moveTo(Offset.zero);
          await t.pumpAndSettle();
          expect(
            _painters<TermBracketPainter>(t, face).first.color,
            rest.color,
          );
        });
      }

      testWidgets("under the pointer a tab's words take the accent", (t) async {
        await t.pumpWidget(
          _host(
            theme,
            TermTabBar(
              tabs: const ['steps', 'log', 'env'],
              selectedIndex: 0,
              onTap: (_) {},
            ),
          ),
        );
        expect(_ink(t, 'log'), theme.foreground);
        final mouse = await _mouse(t);
        await mouse.moveTo(t.getCenter(find.text('log')));
        await t.pumpAndSettle();
        expect(_ink(t, 'log'), theme.accent);
        for (final cells in t.widgetList<TermCursorCells>(
          find.byType(TermCursorCells),
        )) {
          expect(cells.focus, 0);
        }
      });

      testWidgets("a menu's row under the pointer has the pointer's mark; a "
          'key brings the cursor', (t) async {
        await t.pumpWidget(
          _host(
            theme,
            TermMenu(
              semanticLabel: 'run actions',
              anchorBuilder: (context, anchor) => TermIconButton(
                glyph: '⋯',
                semanticLabel: 'more',
                onPressed: anchor.toggle,
              ),
              items: [
                TermMenuItem(label: 'rerun', onPressed: () {}),
                TermMenuItem(label: 'copy link', onPressed: () {}),
                TermMenuItem(label: 'archive', onPressed: () {}),
              ],
            ),
          ),
        );
        final mouse = await _mouse(t);
        await mouse.moveTo(t.getCenter(find.text('⋯')));
        await mouse.down(t.getCenter(find.text('⋯')));
        await mouse.up();
        await t.pumpAndSettle();
        double cursorOn(String label) => t
            .widget<TermCursorCells>(
              find.descendant(
                of: find.ancestor(
                  of: find.text(label),
                  matching: find.byType(TermMenuRow),
                ),
                matching: find.byType(TermCursorCells),
              ),
            )
            .focus;

        await mouse.moveTo(t.getCenter(find.text('copy link')));
        await t.pumpAndSettle();
        expect(cursorOn('copy link'), 0);
        expect(_ink(t, 'copy link'), theme.accent);

        await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await t.pumpAndSettle();
        expect(cursorOn('archive'), 1);
        expect(cursorOn('copy link'), 0);
      });
    });
  }
}
