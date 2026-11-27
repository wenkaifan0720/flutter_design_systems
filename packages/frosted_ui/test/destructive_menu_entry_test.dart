// A loss in a menu ui_core raises reads as one: a menu bar's or a context
// menu's entry marked isDestructiveAction sets its words in the over tone,
// as a FrostedMenuItem's destructive item does, by day and by night; the
// entries beside it keep the menu's own words.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

Widget _host(FrostedThemeData t, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => FrostedHost(
    theme: t,
    darkTheme: t,
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

/// The colour [label]'s words are painted in.
Color? _ink(WidgetTester tester, String label) => tester
    .widget<RichText>(
      find.descendant(
        of: find.text(label).last,
        matching: find.byType(RichText),
      ),
    )
    .text
    .style
    ?.color;

List<RawMenuEntry> get _entries => [
  RawMenuEntry(label: 'Rename', onPressed: () {}),
  RawMenuEntry(label: 'Delete', isDestructiveAction: true, onPressed: () {}),
];

void main() {
  for (final t in [
    FrostedThemeData.opal(),
    FrostedThemeData.opal(Brightness.dark),
  ]) {
    final night = t.isDark ? 'night' : 'day';

    testWidgets("$night: a menu bar's destructive entry is set in the over "
        'tone', (tester) async {
      await tester.pumpWidget(
        _host(
          t,
          FrostedMenuBar(
            menus: [RawMenuEntry(label: 'File', children: _entries)],
          ),
        ),
      );
      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      expect(_ink(tester, 'Delete'), t.colorScheme.over);
      expect(_ink(tester, 'Rename'), isNot(t.colorScheme.over));
    });

    testWidgets("$night: a context menu's destructive entry is set in the "
        'over tone', (tester) async {
      await tester.pumpWidget(
        _host(
          t,
          FrostedContextMenu(
            items: _entries,
            child: const SizedBox(height: 120, child: Text('Card')),
          ),
        ),
      );
      await tester.tap(
        find.text('Card'),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      expect(_ink(tester, 'Delete'), t.colorScheme.over);
      expect(_ink(tester, 'Rename'), isNot(t.colorScheme.over));
    });
  }
}
