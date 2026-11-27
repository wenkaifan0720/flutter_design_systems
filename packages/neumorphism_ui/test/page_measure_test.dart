// A page on a wide window: its column stands centred at the page's measure, and a pushed page's head and its footer's
// acts line up with the words on it, as the page's own column does.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

const _places = [
  RawNavigationDestination(label: 'Books', icon: NeumorphicGlyphs.file),
  RawNavigationDestination(label: 'Settings', icon: NeumorphicGlyphs.settings),
];

Future<GlobalKey<NavigatorState>> _pump(
  WidgetTester t,
  double width,
  TextDirection direction,
) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final key = GlobalKey<NavigatorState>();
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => Directionality(
        textDirection: direction,
        child: NeumorphicHost(child: page!),
      ),
      home: NeumorphicAppShell(
        navigatorKeys: [key, GlobalKey<NavigatorState>()],
        destinations: _places,
        branches: [
          (context) => const NeumorphicScaffold(
            maxWidth: 760,
            topBar: NeumorphicAppBar(title: 'Books'),
            body: SizedBox(
              key: ValueKey('root body'),
              width: double.infinity,
              child: Text('Root words'),
            ),
          ),
          (context) => const NeumorphicScaffold(body: Text('Settings')),
        ],
      ),
    ),
  );
  await t.pumpAndSettle();
  return key;
}

void main() {
  for (final width in [1440.0, 1920.0, 2560.0]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'a pushed page lines its head and its acts up with its words at $width ${direction.name}',
        (t) async {
          final key = await _pump(t, width, direction);
          final rtl = direction == TextDirection.rtl;
          // A root's head stands in its column.
          final root = t.getRect(find.byKey(const ValueKey('root body')));
          expect(
            root.width,
            lessThanOrEqualTo(760),
            reason: 'the root keeps to its measure',
          );
          final rootTitle = t.getRect(find.text('Books').last);
          expect(
            rtl
                ? (rootTitle.right - root.right).abs()
                : (rootTitle.left - root.left).abs(),
            lessThan(1.5),
            reason: "the root's title over its words",
          );
          key.currentState!.push(
            MaterialPageRoute<void>(
              builder: (context) => NeumorphicScaffold(
                maxWidth: 760,
                topBar: const NeumorphicAppBar(title: 'Detail'),
                body: const SizedBox(
                  key: ValueKey('body'),
                  width: double.infinity,
                  child: Text('Detail words'),
                ),
                footer: NeumorphicButton.filled('Save', onPressed: () {}),
              ),
            ),
          );
          await t.pumpAndSettle();
          final body = t.getRect(find.byKey(const ValueKey('body')));
          expect(
            body.width,
            lessThanOrEqualTo(760),
            reason: 'the page keeps to its measure',
          );
          final title = t.getRect(find.text('Detail'));
          final back = t.getRect(find.byType(NeumorphicBackButton));
          // The way back starts the head where the words start; the title follows it.
          expect(
            rtl
                ? (back.right - body.right).abs()
                : (back.left - body.left).abs(),
            lessThan(1.5),
            reason: 'the way back at the start of the words',
          );
          expect(
            rtl ? title.right < back.left : title.left > back.right,
            isTrue,
            reason: 'the title after the way back',
          );
          final save = t.getRect(find.widgetWithText(NeumorphicButton, 'Save'));
          expect(
            rtl
                ? (save.left - body.left).abs()
                : (save.right - body.right).abs(),
            lessThan(1.5),
            reason: "the footer's act ends where the words end",
          );
        },
      );
    }
  }
}
