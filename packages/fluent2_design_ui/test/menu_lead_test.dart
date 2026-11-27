// One current row in every open menu, as Fluent's menus keep one: a menu a control opens (Fluent2Menu.show) and a
// split button's menu, under a mouse on a Mac. Opened by a click, no row lights until the pointer or a key moves;
// opened by a key, the row in focus wears the focus ring at once. The pointer moving over a row lights it in the hover
// fill and takes the focus there; a key then rings its row and puts the pointer's fill out. The rows stand 5 in from
// the menu's outer edge on all four sides (Fluent's 4 inside its 1 px stroke), so no ring or fill touches it.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

const _sortBy = [
  Fluent2MenuItem('name', 'Name', checked: false),
  Fluent2MenuItem('modified', 'Modified', checked: true),
  Fluent2MenuItem('size', 'File size', checked: false),
];

const _commands = [
  Fluent2MenuItem('open', 'Open'),
  Fluent2MenuItem('rename', 'Rename'),
  Fluent2MenuItem('copy', 'Copy link'),
];

Future<void> _stage(WidgetTester t, Widget body) async {
  t.view.physicalSize = const Size(1440, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) =>
          Fluent2Host(brightness: Brightness.light, child: navigator!),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(alignment: Alignment.topLeft, child: body),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Widget _menuButton(FocusNode node, List<Fluent2MenuItem<String>> items) =>
    Builder(
      builder: (anchor) => Fluent2Button(
        'Sort',
        focusNode: node,
        onPressed: () => Fluent2Menu.show<String>(anchor, items: items),
      ),
    );

final _split = Fluent2SplitButton(
  'Reply',
  onPressed: () {},
  actions: [
    Fluent2SplitAction('Reply all', onPressed: () {}),
    Fluent2SplitAction('Forward', onPressed: () {}),
    Fluent2SplitAction('Copy link', onPressed: () {}),
  ],
);

Finder _row(String label) =>
    find.byWidgetPredicate((w) => w is Fluent2MenuRowFace && w.label == label);

/// The open menu's rows that light: a focus ring on them, or a fill other
/// than the menu's own (a chosen row's brand fill aside).
List<String> _lit(WidgetTester t) {
  final lit = <String>[];
  for (final e in find.byType(Fluent2MenuRowFace).evaluate()) {
    final face = e.widget as Fluent2MenuRowFace;
    final row = find.byElementPredicate((x) => identical(x, e));
    final ring = find.descendant(
      of: row,
      matching: find.byType(Fluent2FocusRing),
    );
    final box = t.widget<Container>(
      find.descendant(of: row, matching: find.byType(Container)).first,
    );
    final fill = (box.decoration! as BoxDecoration).color;
    final rest = e.fluent2Theme.colors.neutralBackground1;
    final filled = !face.checked && fill != rest;
    if (ring.evaluate().isNotEmpty || filled) lit.add(face.label);
  }
  return lit;
}

/// The words of the row the focus is on.
String? _focused() {
  final at = FocusManager.instance.primaryFocus?.context;
  if (at == null) return null;
  final face = find.descendant(
    of: find.byElementPredicate((e) => identical(e, at)),
    matching: find.byType(Fluent2MenuRowFace),
  );
  final found = face.evaluate();
  return found.isEmpty
      ? null
      : (found.first.widget as Fluent2MenuRowFace).label;
}

Future<TestGesture> _mouse(WidgetTester t, Offset at) async {
  final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: at);
  addTearDown(mouse.removePointer);
  await t.pump();
  return mouse;
}

Future<void> _click(WidgetTester t, TestGesture mouse, Offset at) async {
  await mouse.moveTo(at);
  await mouse.down(at);
  await mouse.up();
  await t.pumpAndSettle();
}

/// Moves the pointer over [label]'s row, as a hand does: from just above it.
Future<void> _over(WidgetTester t, TestGesture mouse, String label) async {
  final at = t.getCenter(_row(label));
  await mouse.moveTo(at - const Offset(0, 3));
  await t.pump();
  await mouse.moveTo(at);
  await t.pumpAndSettle();
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pumpAndSettle();
}

/// The gaps from the open menu's outer edge to its first row (start, top,
/// end) and from its last row to its foot.
List<double> _gaps(WidgetTester t, String first, String last) {
  final plate = t.getRect(
    find
        .ancestor(
          of: _row(first),
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                ((w.decoration as BoxDecoration).boxShadow?.isNotEmpty ??
                    false),
          ),
        )
        .first,
  );
  final top = t.getRect(_row(first));
  final foot = t.getRect(_row(last));
  return [
    top.left - plate.left,
    top.top - plate.top,
    plate.right - top.right,
    plate.bottom - foot.bottom,
  ];
}

void main() {
  testWidgets('a menu a click opens lights no row; the pointer leads, then '
      'a key', (t) async {
    final button = FocusNode(debugLabel: 'button');
    addTearDown(button.dispose);
    await _stage(t, _menuButton(button, _sortBy));
    final at = t.getCenter(find.text('Sort'));
    final mouse = await _mouse(t, at);
    await _click(t, mouse, at);
    expect(find.text('File size'), findsOneWidget, reason: 'it opens');
    expect(_lit(t), isEmpty, reason: 'a click lights no row');
    expect(_focused(), 'Modified', reason: 'the keys start from the checked');

    await _over(t, mouse, 'Name');
    expect(_lit(t), ['Name'], reason: "the pointer's row, filled");
    expect(_focused(), 'Name', reason: 'the focus follows the pointer');

    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Modified', reason: 'the keys go on from it');
    expect(_lit(t), ['Modified'], reason: "the keys' ring; the fill out");

    await _over(t, mouse, 'File size');
    expect(_lit(t), ['File size'], reason: 'the pointer leads again');
    expect(_focused(), 'File size');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('a menu a key opens rings its row at once', (t) async {
    final button = FocusNode(debugLabel: 'button');
    addTearDown(button.dispose);
    await _stage(t, _menuButton(button, _commands));
    button.requestFocus();
    await t.pumpAndSettle();
    await _key(t, LogicalKeyboardKey.enter);
    expect(_lit(t), ['Open']);
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_lit(t), ['Rename']);
    expect(_gaps(t, 'Open', 'Copy link'), [5, 5, 5, 5]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("a split button's menu: a click lights none, Down rings the "
      'first; the pointer leads', (t) async {
    await _stage(t, _split);
    final toggle =
        t.getRect(find.byType(Fluent2SplitButton)).centerRight -
        const Offset(8, 0);
    final mouse = await _mouse(t, toggle);
    await _click(t, mouse, toggle);
    expect(find.text('Forward'), findsOneWidget, reason: 'it opens');
    expect(_lit(t), isEmpty, reason: 'a click lights no row');
    await _over(t, mouse, 'Forward');
    expect(_lit(t), ['Forward']);
    expect(_focused(), 'Forward', reason: 'the focus follows the pointer');
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_lit(t), ['Copy link'], reason: "the keys' ring; the fill out");
    expect(_gaps(t, 'Reply all', 'Copy link'), [5, 5, 5, 5]);
    await _key(t, LogicalKeyboardKey.escape);
    expect(find.text('Forward'), findsNothing, reason: 'it closes');

    await mouse.moveTo(const Offset(1400, 880));
    Focus.of(t.element(find.text('Reply'))).requestFocus();
    await t.pumpAndSettle();
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_lit(t), ['Reply all'], reason: 'opened by a key: its first');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
