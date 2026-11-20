// The menus check, in every menu Frosted opens: a select's (its own
// FrostedMenu), a menu bar's and a split button's (ui_core's, painted by
// Frosted). (1) One lit row: Frosted clears the frost under the keys' row and
// the pointer's row alike, so a pointer moving over a row moves the one lit
// row there and the keys go on from it; a pointer resting on a row the keys
// left lights nothing. (2) The clearing stands inside its row, the menu's
// inset clear all round it, its corner concentric with the menu's.
// (3) Opened by a pointer no row is lit until the pointer or the keys move;
// opened by a key the first row is (a select's chosen one, as a select's
// list opens on its value).
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
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

/// The rows of [labels] lit: the frost under them cleared.
List<String> _lit(WidgetTester tester, List<String> labels) => [
  for (final label in labels)
    if (find
        .ancestor(
          of: find.text(label).last,
          matching: find.byType(FrostedCleared),
        )
        .evaluate()
        .any((e) => (e.widget as FrostedCleared).level > 0))
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
  testWidgets('at 200% on a phone, a month name in a menu wraps whole beside '
      'its amount; a line stands at the row\'s least height', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget menu() => FrostedMenu<String>(
      title: 'Spent by month',
      label: 'Months',
      items: [
        // Short amounts: the test font draws every glyph a whole em wide.
        for (final (month, spent) in const [
          ('August 2026', '\$9'),
          ('October 2026', '\$8'),
        ])
          FrostedMenuItem(
            month,
            month,
            trailing: Text(spent),
            checked: month == 'October 2026',
          ),
      ],
      onSelected: (_) {},
    );
    Future<void> pump(double scale) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, page) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: FrostedHost(brightness: Brightness.light, child: page!),
          ),
          home: Align(
            alignment: AlignmentDirectional.topEnd,
            child: Padding(padding: const EdgeInsets.all(16), child: menu()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await pump(1);
    final rest = tester.getSize(find.byType(FrostedPressable).first).height;
    expect(rest, FrostedBreakpoints.touchHitTarget);
    await pump(2);
    for (final month in ['August 2026', 'October 2026']) {
      final words = tester.renderObject<RenderParagraph>(find.text(month));
      expect(words.didExceedMaxLines, isFalse, reason: '$month whole');
      final row = tester.getRect(
        find.ancestor(
          of: find.text(month),
          matching: find.byType(FrostedPressable),
        ),
      );
      final drawn = tester.getRect(find.text(month));
      expect(row.top, lessThan(drawn.top), reason: '$month inside its row');
      expect(
        row.bottom,
        greaterThan(drawn.bottom),
        reason: '$month inside its row',
      );
    }
  });

  setUp(() => _room = null);

  for (final t in [
    FrostedThemeData.opal(),
    FrostedThemeData.opal(Brightness.dark),
  ]) {
    final night = t.isDark ? 'night' : 'day';

    testWidgets("$night: a select's menu: a pointer open lights nothing; the "
        'pointer and the keys move one lit row; Return takes the pointer\'s', (
      tester,
    ) async {
      const rows = ['Kitchen', 'Study', 'Garden'];
      await tester.pumpWidget(_host(t, const _Room()));
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.text('Garden'));
      expect(find.text('Kitchen'), findsOneWidget, reason: 'open');
      expect(_lit(tester, rows), isEmpty, reason: 'nothing lit');

      await _over(tester, mouse, 'Kitchen');
      expect(_lit(tester, rows), ['Kitchen']);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, rows), [
        'Study',
      ], reason: 'on from the pointer; the resting pointer lights nothing');
      // The keys' row clears within its own edge, the menu's inset clear
      // all round, corners concentric.
      final cleared = tester.widgetList<FrostedCleared>(
        find.ancestor(
          of: find.text('Study').last,
          matching: find.byType(FrostedCleared),
        ),
      );
      expect(cleared.first.inside, isTrue);
      expect(cleared.first.insets, EdgeInsets.zero);
      expect(
        (cleared.first.outline as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(
          FrostedChromeMetrics.menuRadius - FrostedChromeMetrics.menuInset,
        ),
        reason: 'concentric with the menu',
      );

      await _over(tester, mouse, 'Kitchen');
      expect(_lit(tester, rows), ['Kitchen'], reason: 'the pointer');
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
      expect(_lit(tester, rows), isEmpty, reason: 'nothing lit');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, rows), ['New'], reason: 'Down: the first');
      await _over(tester, mouse, 'Open');
      expect(_lit(tester, rows), ['Open']);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, rows), ['Open recent'], reason: 'one row');
      await _over(tester, mouse, 'Print');
      expect(_lit(tester, rows), ['Print']);
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
      expect(_lit(tester, rows), ['New'], reason: 'a key: the first');
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
      expect(_lit(tester, rows), isEmpty, reason: 'nothing lit');
      await _over(tester, mouse, 'Save a copy');
      expect(_lit(tester, rows), ['Save a copy']);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, rows), ['Export'], reason: 'one row');
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
      expect(_lit(tester, rows), isEmpty, reason: 'nothing lit');
      await _over(tester, mouse, 'Save a copy');
      expect(_lit(tester, rows), ['Save a copy']);
      await _over(tester, mouse, 'Save as…');
      expect(_lit(tester, rows), ['Save as…']);
      semantics.dispose();
    });

    testWidgets('$night: a context menu opens where it was asked for, as '
        'wide as its rows', (tester) async {
      await tester.pumpWidget(
        _host(
          t,
          FrostedContextMenu(
            items: [
              DesignMenuEntry(label: 'Copy', onPressed: () {}),
              DesignMenuEntry(label: 'Delete', onPressed: () {}),
            ],
            child: const SizedBox(height: 160),
          ),
        ),
      );
      final at =
          tester.getTopLeft(find.byType(FrostedContextMenu)) +
          const Offset(120, 60);
      final right = await tester.startGesture(
        at,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await right.up();
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsOneWidget, reason: 'open');
      final panel = tester.getRect(
        find
            .ancestor(
              of: find.text('Copy'),
              matching: find.byType(FrostedPanel),
            )
            .first,
      );
      final row = tester.getRect(
        find
            .ancestor(
              of: find.text('Copy'),
              matching: find.byType(FrostedPanelRow),
            )
            .first,
      );
      expect(
        panel.width,
        moreOrLessEquals(row.width + 2 * FrostedChromeMetrics.menuInset),
        reason: 'as wide as its rows, not the window',
      );
      expect(
        (panel.left - at.dx).abs(),
        lessThanOrEqualTo(4),
        reason: 'at the pointer',
      );
      expect((panel.top - at.dy).abs(), lessThanOrEqualTo(4));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsNothing);
    });

    testWidgets('$night: a panel row: held, cleared; a resting pointer '
        'alone, nothing', (tester) async {
      Future<void> row(Set<WidgetState> states) => tester.pumpWidget(
        _host(t, FrostedPanelRow(label: 'Lisbon', states: states)),
      );
      await row({WidgetState.focused});
      expect(_lit(tester, ['Lisbon']), ['Lisbon']);
      await row({WidgetState.hovered});
      expect(_lit(tester, ['Lisbon']), isEmpty);
    });
  }
}
