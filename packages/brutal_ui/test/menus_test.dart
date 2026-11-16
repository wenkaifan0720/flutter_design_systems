// Brutal's menus as a desktop meets them (a menu, a menu bar's menu, a split
// button's menu): one row is lit, the keyboard's, and the pointer's move takes
// the keyboard to its row; a menu a pointer opened lights no row until the
// pointer moves onto one or a key is pressed, and the first Down lights the
// first row; a menu a key opened lights the first row. A select's list is one
// place for the pointer and the keys too.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  home: BrutalTheme(
    data: BrutalThemeData.light(),
    child: Builder(
      builder: (context) => ColoredBox(
        color: BrutalTheme.of(context).colors.paper,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  ),
);

// The rows a square line is drawn in (the row's foreground painter).
List<String> _lit(WidgetTester tester) => [
  for (final row in find.byType(BrutalMenuRow).evaluate())
    if (tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byWidget(row.widget),
            matching: find.byType(CustomPaint),
          ),
        )
        .any((paint) => paint.foregroundPainter != null))
      (row.widget as BrutalMenuRow).label,
];

final _items = [
  BrutalMenuItem(label: 'Share', onPressed: () {}),
  BrutalMenuItem(label: 'Duplicate', onPressed: () {}),
  BrutalMenuItem(label: 'Archive', onPressed: () {}),
];

typedef _Menu = ({
  String id,
  Widget widget,
  Offset Function(WidgetTester tester) trigger,
});

final List<_Menu> _menus = [
  (
    id: 'BrutalMenu',
    widget: BrutalMenu(
      items: _items,
      builder: (context, toggle, open) =>
          BrutalButton('More', onPressed: toggle),
    ),
    trigger: (tester) => tester.getCenter(find.text('More')),
  ),
  (
    id: "BrutalMenuBar's menu",
    widget: BrutalMenuBar(menus: [BrutalMenuBarMenu('Ticket', _items)]),
    trigger: (tester) => tester.getCenter(find.text('Ticket')),
  ),
  (
    id: "BrutalSplitButton's menu",
    widget: BrutalSplitButton(label: 'Save', onPressed: () {}, actions: _items),
    // The toggle: the cell with the triangle.
    trigger: (tester) => tester.getCenter(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.size == const Size(12, 8),
      ),
    ),
  ),
];

Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: const Offset(1000, 800));
  addTearDown(mouse.removePointer);
  return mouse;
}

// A hand's move onto [row]'s words, from just above them.
Future<void> _onto(WidgetTester tester, TestGesture mouse, String row) async {
  final at = tester.getCenter(find.text(row).last);
  await mouse.moveTo(at - const Offset(0, 3));
  await tester.pump();
  await mouse.moveTo(at);
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

// Tab until the keyboard is on the trigger (a control, not the page's scope).
Future<void> _tabTo(WidgetTester tester, Offset trigger) async {
  for (var i = 0; i < 8; i++) {
    final node = FocusManager.instance.primaryFocus;
    if (node != null &&
        node is! FocusScopeNode &&
        node.rect.contains(trigger)) {
      return;
    }
    await _key(tester, LogicalKeyboardKey.tab);
  }
  fail('the keyboard never reached the trigger');
}

final _desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

void main() {
  for (final m in _menus) {
    group(m.id, () {
      testWidgets('opened by a click, no row is lit; the pointer moving onto '
          'a row lights it alone, the keys move on from it, and the pointer '
          'takes the lit row back', (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(m.widget));
        final mouse = await _mouse(tester);
        await mouse.moveTo(m.trigger(tester));
        await tester.pump();
        await mouse.down(m.trigger(tester));
        await tester.pump();
        await mouse.up();
        await tester.pumpAndSettle();
        expect(find.text('Duplicate'), findsOneWidget);
        expect(_lit(tester), isEmpty);
        await _onto(tester, mouse, 'Duplicate');
        expect(_lit(tester), ['Duplicate']);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(_lit(tester), ['Archive']);
        await _onto(tester, mouse, 'Share');
        expect(_lit(tester), ['Share']);
      }, variant: _desktop);

      testWidgets('opened by a click, the first Down lights the first row and '
          'does nothing more', (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(m.widget));
        final mouse = await _mouse(tester);
        await mouse.moveTo(m.trigger(tester));
        await tester.pump();
        await mouse.down(m.trigger(tester));
        await tester.pump();
        await mouse.up();
        await tester.pumpAndSettle();
        expect(_lit(tester), isEmpty);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(_lit(tester), ['Share']);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(_lit(tester), ['Duplicate']);
      }, variant: _desktop);

      testWidgets('opened by Enter, the first row is lit; the pointer moving '
          'onto another row takes the lit row there', (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(m.widget));
        final mouse = await _mouse(tester);
        await _tabTo(tester, m.trigger(tester));
        await _key(tester, LogicalKeyboardKey.enter);
        expect(find.text('Duplicate'), findsOneWidget);
        expect(_lit(tester), ['Share']);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(_lit(tester), ['Duplicate']);
        await _onto(tester, mouse, 'Archive');
        expect(_lit(tester), ['Archive']);
      }, variant: _desktop);

      testWidgets('opened by a touch, no row is lit; a mouse moving onto a '
          'row lights it all the same (a tablet with a trackpad)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(m.widget));
        await tester.tapAt(m.trigger(tester));
        await tester.pumpAndSettle();
        expect(find.text('Duplicate'), findsOneWidget);
        expect(_lit(tester), isEmpty);
        final mouse = await _mouse(tester);
        await _onto(tester, mouse, 'Duplicate');
        expect(_lit(tester), ['Duplicate']);
      });
    });
  }

  testWidgets("a select's list: the pointer's move takes the keyboard to its "
      'row, so one row is where you are', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 320,
          child: BrutalSelect<String>(
            label: 'Section',
            value: 'Stalls',
            items: const [
              BrutalSelectItem(value: 'Stalls', label: 'Stalls'),
              BrutalSelectItem(value: 'Circle', label: 'Circle'),
              BrutalSelectItem(value: 'Balcony', label: 'Balcony'),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    final mouse = await _mouse(tester);
    await _tabTo(tester, tester.getCenter(find.text('Stalls')));
    await _key(tester, LogicalKeyboardKey.enter);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    final circle = Focus.of(tester.element(find.text('Circle').last));
    expect(circle.hasPrimaryFocus, isTrue);
    await _onto(tester, mouse, 'Balcony');
    final balcony = Focus.of(tester.element(find.text('Balcony').last));
    expect(balcony.hasPrimaryFocus, isTrue);
    expect(circle.hasPrimaryFocus, isFalse);
  }, variant: _desktop);

  testWidgets("a select's list opened by a touch: a mouse moving onto a row "
      'lights it alone, and the keys move the line on', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const rows = ['Stalls', 'Circle', 'Balcony'];
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 320,
          child: BrutalSelect<String>(
            label: 'Section',
            value: 'Stalls',
            items: [for (final r in rows) BrutalSelectItem(value: r, label: r)],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    // The rows a square line is drawn in.
    List<String> lit() => [
      for (final r in rows)
        if (find.text(r).evaluate().isNotEmpty &&
            tester
                .widgetList<CustomPaint>(
                  find.ancestor(
                    of: find.text(r).last,
                    matching: find.byType(CustomPaint),
                  ),
                )
                .any((p) => p.foregroundPainter is BrutalInsetFocusPainter))
          r,
    ];
    await tester.tap(find.text('Stalls'));
    await tester.pumpAndSettle();
    expect(find.text('Balcony'), findsOneWidget);
    expect(lit(), isEmpty);
    final mouse = await _mouse(tester);
    await _onto(tester, mouse, 'Balcony');
    expect(lit(), ['Balcony']);
    await _onto(tester, mouse, 'Circle');
    expect(lit(), ['Circle']);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(lit(), ['Balcony']);
  });
}
