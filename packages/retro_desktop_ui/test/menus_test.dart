// One current row in every open menu (a menu bar's, a split button's, a menu anchor's): the look draws the pointer's
// row and the keyboard's alike, in the highlight's bar, so the pointer moves the one lit row and the keys go on from
// there, as the period's menus did; never two lit rows. Opened by the pointer a menu lights no row until the pointer or
// the keys move; opened by the keys it lights the first. A row is lit when it stands on the look's highlight bar.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

const _rows = ['New', 'Open', 'Print', 'Close', 'Quit'];

Widget _host(Widget child) => MaterialApp(
  builder: (context, child) =>
      RetroDesktopTheme(data: RetroDesktopThemeData.classic(), child: child!),
  home: Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(width: 360, child: child),
    ),
  ),
);

// The rows on the look's highlight bar.
List<String> _lit(WidgetTester tester) => [
  for (final words in _rows)
    if (_on(tester, words)) words,
];

bool _on(WidgetTester tester, String words) {
  final row = find.byWidgetPredicate((w) => w is Text && w.data == words);
  if (row.evaluate().isEmpty) return false;
  final highlight = RetroDesktopTheme.of(tester.element(row.first))
      .colors
      .highlight;
  return find
      .ancestor(
        of: row,
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is ShapeDecoration &&
              (w.decoration as ShapeDecoration).color == highlight,
        ),
      )
      .evaluate()
      .isNotEmpty;
}

// A menu kind: the widget, what a click opens it by, and the keys that open it from the first Tab stop.
typedef _Kind = ({Widget widget, Finder opener, List<LogicalKeyboardKey> keys});

final Map<String, _Kind> _kinds = {
  "a menu bar's menu": (
    widget: RetroDesktopMenuBar(
      menus: [
        DesignMenuEntry(
          label: 'File',
          children: [
            for (final label in _rows)
              DesignMenuEntry(label: label, onPressed: () {}),
          ],
        ),
      ],
    ),
    opener: find.text('File'),
    keys: [LogicalKeyboardKey.tab, LogicalKeyboardKey.arrowDown],
  ),
  "a split button's menu": (
    widget: RetroDesktopSplitButton(
      label: 'Save',
      onPressed: () {},
      actions: [
        for (final label in _rows)
          DesignSplitAction(label: label, onPressed: () {}),
      ],
    ),
    opener: find.byType(RetroDesktopTriangleMark),
    keys: [
      LogicalKeyboardKey.tab,
      LogicalKeyboardKey.tab,
      LogicalKeyboardKey.enter,
    ],
  ),
  "a menu anchor's menu": (
    widget: RetroDesktopMenuAnchor<String>(
      items: [for (final label in _rows) RetroDesktopMenuItem(label, label)],
      builder: (context, open) => RetroDesktopButton('More', onPressed: open),
      onSelected: (_) {},
    ),
    opener: find.text('More'),
    keys: [LogicalKeyboardKey.tab, LogicalKeyboardKey.enter],
  ),
};

void main() {
  for (final MapEntry(key: name, value: kind) in _kinds.entries) {
    testWidgets(
      '$name: one lit row, the pointer moving it and the keys going on from '
      'it; opened by a click nothing lit, by the keys the first',
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
      (tester) async {
        tester.view
          ..physicalSize = const Size(1440, 900)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_host(kind.widget));
        await tester.pumpAndSettle();

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: tester.getCenter(kind.opener));
        await tester.pump();
        await mouse.down(tester.getCenter(kind.opener));
        await mouse.up();
        await tester.pumpAndSettle();
        expect(find.text('Quit'), findsOneWidget, reason: 'open');
        expect(_lit(tester), isEmpty, reason: 'opened by a click');

        Future<void> point(String words) async {
          await mouse.moveTo(tester.getCenter(find.text(words)));
          await tester.pumpAndSettle();
        }

        Future<void> key(LogicalKeyboardKey key) async {
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
        }

        await point('Print');
        expect(_lit(tester), ['Print'], reason: 'the pointer lights its row');
        await key(LogicalKeyboardKey.arrowDown);
        expect(_lit(tester), [
          'Close',
        ], reason: 'the keys go on from the pointer, one row lit');
        await point('Open');
        expect(_lit(tester), ['Open'], reason: 'the pointer takes it back');
        await key(LogicalKeyboardKey.arrowUp);
        expect(_lit(tester), ['New']);

        // Closed, then opened from the keys with the pointer still where it was.
        await key(LogicalKeyboardKey.escape);
        expect(find.text('Quit'), findsNothing, reason: 'closed');
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(_host(kind.widget));
        await tester.pumpAndSettle();
        for (final k in kind.keys) {
          await key(k);
        }
        expect(find.text('Quit'), findsOneWidget, reason: 'open');
        expect(_lit(tester), ['New'], reason: 'opened by the keys');
        await key(LogicalKeyboardKey.arrowDown);
        expect(_lit(tester), ['Open']);
      },
    );
  }
}
