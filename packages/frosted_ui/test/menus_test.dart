// The menus check (coordinator msg_4b9e9c92778f, from the user's walk of
// Expressive's menus), in every menu Frosted opens: a select's (its own
// FrostedMenu), a menu bar's and a split button's (ui_core's, painted by
// Frosted). (1) One lit row: Frosted paints the keys' row and the pointer's
// row with the same wash, so a pointer moving over a row moves the one lit
// row there and the keys go on from it; a pointer resting on a row the keys
// left lights nothing. (2) The keyboard's ring stands inside its row, the
// menu's inset clear all round it, its corner concentric with the menu's.
// (3) Opened by a pointer no row is lit until the pointer or the keys move;
// opened by a key the first row is (a select's chosen one, as a select's
// list opens on its value).
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';
import 'package:frosted_ui/src/frosted/internal/panel.dart';

Widget _host(FrostedThemeData t, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => FrostedHost(
    light: t,
    dark: t,
    brightness: t.isDark ? Brightness.dark : Brightness.light,
    child: page!,
  ),
  home: ColoredBox(
    color: t.colorScheme.background,
    child: Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SizedBox(width: 400, child: child),
      ),
    ),
  ),
);

class _Room extends StatefulWidget {
  const _Room();

  @override
  State<_Room> createState() => _RoomState();
}

String? _room;

class _RoomState extends State<_Room> {
  String? _value = 'g';

  @override
  Widget build(BuildContext context) => FrostedSelect<String>(
    label: 'Room',
    value: _value,
    onChanged: (v) => setState(() => _room = _value = v),
    options: const [
      FrostedSelectOption('k', 'Kitchen'),
      FrostedSelectOption('s', 'Study'),
      FrostedSelectOption('g', 'Garden'),
    ],
  );
}

/// The rows of [labels] lit by the wash (a chosen row stands on its plate).
List<String> _lit(WidgetTester tester, List<String> labels, Color wash) => [
  for (final label in labels)
    if (find
        .ancestor(of: find.text(label).last, matching: find.byType(FrostedFace))
        .evaluate()
        .any((e) => (e.widget as FrostedFace).color == wash))
      label,
];

Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  return mouse;
}

Future<void> _over(WidgetTester tester, TestGesture mouse, String label) async {
  await mouse.moveTo(tester.getCenter(find.text(label).last));
  await tester.pumpAndSettle();
}

Future<void> _click(WidgetTester tester, TestGesture mouse, Finder f) async {
  await mouse.moveTo(tester.getCenter(f));
  await mouse.down(tester.getCenter(f));
  await mouse.up();
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => _room = null);

  for (final t in [
    FrostedThemeData.opal(),
    FrostedThemeData.opal(Brightness.dark),
  ]) {
    final night = t.isDark ? 'night' : 'day';
    final wash = t.glass.wash;

    testWidgets("$night: a select's menu: a pointer open lights nothing; the "
        'pointer and the keys move one lit row; Return takes the pointer\'s', (
      tester,
    ) async {
      const rows = ['Kitchen', 'Study', 'Garden'];
      await tester.pumpWidget(_host(t, const _Room()));
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.text('Garden'));
      expect(find.text('Kitchen'), findsOneWidget, reason: 'open');
      expect(_lit(tester, rows, wash), isEmpty, reason: 'nothing lit');

      await _over(tester, mouse, 'Kitchen');
      expect(_lit(tester, rows, wash), ['Kitchen']);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, rows, wash), [
        'Study',
      ], reason: 'on from the pointer; the resting pointer lights nothing');
      // The keyboard's ring inside its row: its outer line is the row's
      // edge, the menu's inset clear all round, corners concentric.
      const ring =
          FrostedChromeMetrics.focusRingGap +
          FrostedChromeMetrics.focusRingWidth;
      final rings = tester.widgetList<FrostedFocusRing>(
        find.ancestor(
          of: find.text('Study').last,
          matching: find.byType(FrostedFocusRing),
        ),
      );
      expect(rings.first.insets, const EdgeInsets.all(ring));
      expect(
        rings.first.radius + ring,
        FrostedChromeMetrics.menuRadius - FrostedChromeMetrics.menuInset,
        reason: 'concentric with the menu',
      );

      await _over(tester, mouse, 'Kitchen');
      expect(_lit(tester, rows, wash), ['Kitchen'], reason: 'the pointer');
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_room, 'k', reason: "Return takes the pointer's row");
    });

    testWidgets("$night: a menu bar's menu: a pointer open lights nothing; "
        'one lit row under the pointer and the keys; a key open lights the '
        'first', (tester) async {
      const rows = ['New', 'Open', 'Open recent', 'Print'];
      await tester.pumpWidget(
        _host(
          t,
          FrostedMenuBar(
            menus: [
              DesignMenuEntry(
                label: 'File',
                children: [
                  for (final r in rows)
                    DesignMenuEntry(label: r, onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      );
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.text('File'));
      expect(find.text('Print'), findsOneWidget, reason: 'open');
      expect(_lit(tester, rows, wash), isEmpty, reason: 'nothing lit');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, rows, wash), ['New'], reason: 'Down: the first');
      await _over(tester, mouse, 'Open');
      expect(_lit(tester, rows, wash), ['Open']);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, rows, wash), ['Open recent'], reason: 'one row');
      await _over(tester, mouse, 'Print');
      expect(_lit(tester, rows, wash), ['Print']);
      await _key(tester, LogicalKeyboardKey.escape);
      expect(find.text('Print'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _host(
          t,
          FrostedMenuBar(
            menus: [
              DesignMenuEntry(
                label: 'File',
                children: [
                  for (final r in rows)
                    DesignMenuEntry(label: r, onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, rows, wash), ['New'], reason: 'a key: the first');
    });

    testWidgets("$night: a split button's menu: a pointer open lights "
        'nothing; one lit row under the pointer and the keys', (tester) async {
      const rows = ['Save as…', 'Save a copy', 'Export'];
      await tester.pumpWidget(
        _host(
          t,
          FrostedSplitButton(
            label: 'Save',
            onPressed: () {},
            actions: [
              for (final r in rows)
                FrostedSplitAction(label: r, onPressed: () {}),
            ],
          ),
        ),
      );
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.byIcon(FrostedGlyphs.chevronDown));
      expect(find.text('Export'), findsOneWidget, reason: 'open');
      expect(_lit(tester, rows, wash), isEmpty, reason: 'nothing lit');
      await _over(tester, mouse, 'Save a copy');
      expect(_lit(tester, rows, wash), ['Save a copy']);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, rows, wash), ['Export'], reason: 'one row');
    });

    testWidgets("$night: a split button's menu as the web gives it: opened "
        "by the control's semantic tap after a key (no press reaches the "
        'app), the focus highlight touch\'s until a key: no row lit; the '
        'pointer moving over a row lights it', (tester) async {
      final semantics = tester.ensureSemantics();
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      const rows = ['Save as…', 'Save a copy', 'Export'];
      await tester.pumpWidget(
        _host(
          t,
          FrostedSplitButton(
            label: 'Save',
            onPressed: () {},
            actions: [
              for (final r in rows)
                FrostedSplitAction(label: r, onPressed: () {}),
            ],
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.escape);
      final toggle = find.byIcon(FrostedGlyphs.chevronDown);
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(toggle));
      await tester.pump();
      tester.semantics.tap(find.semantics.byLabel('More'));
      await tester.pumpAndSettle();
      expect(find.text('Export'), findsOneWidget, reason: 'open');
      expect(_lit(tester, rows, wash), isEmpty, reason: 'nothing lit');
      await _over(tester, mouse, 'Save a copy');
      expect(_lit(tester, rows, wash), ['Save a copy']);
      await _over(tester, mouse, 'Save as…');
      expect(_lit(tester, rows, wash), ['Save as…']);
      semantics.dispose();
    });

    testWidgets('$night: a panel row: held, the wash; a resting pointer '
        'alone, nothing', (tester) async {
      Future<void> row(Set<WidgetState> states) => tester.pumpWidget(
        _host(t, FrostedPanelRow(label: 'Lisbon', states: states)),
      );
      await row({WidgetState.focused});
      expect(_lit(tester, ['Lisbon'], wash), ['Lisbon']);
      await row({WidgetState.hovered});
      expect(_lit(tester, ['Lisbon'], wash), isEmpty);
    });
  }
}
