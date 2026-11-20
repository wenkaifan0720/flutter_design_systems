// Keycap answers every row of ui_core's shared component list once, its
// one absent row with a reason rather than a to-do, and every live specimen
// builds and lays out on a phone, by day and by night, in both reading
// directions, without a throw; and at 200% text, no words are cut short.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';

Widget _app(
  Brightness brightness,
  TextDirection direction,
  Widget child, {
  double text = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(text)),
    child: Directionality(
      textDirection: direction,
      child: KeycapHost(brightness: brightness, child: app!),
    ),
  ),
  home: KeycapScreen(body: child),
);

/// Every run of words laid out shorter than its lines need: words a fixed
/// height cuts off as text grows.
List<String> _cut(WidgetTester tester) => [
  for (final p in tester.allRenderObjects.whereType<RenderParagraph>())
    if (p.attached && p.hasSize && p.firstChild == null)
      if (p.getDryLayout(BoxConstraints(maxWidth: p.size.width))
          case final natural when p.size.height + 0.5 < natural.height)
        '"${p.text.toPlainText()}": ${p.size.height} of ${natural.height}',
];

void main() {
  test('every row is answered once, with a specimen or a reason', () {
    keycapInventory.verify();
    expect(
      keycapInventory.presentCount + keycapInventory.absentCount,
      DesignInventoryRow.all.length,
    );
    expect(keycapInventory.absentCount, 1);
  });

  for (final brightness in Brightness.values) {
    for (final direction in TextDirection.values) {
      for (final entry in keycapInventory.entries.where((e) => e.isPresent)) {
        testWidgets(
          '${entry.row} builds (${brightness.name}, ${direction.name})',
          (tester) async {
            tester.view.physicalSize = const Size(390, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final height = keycapInventoryHeights[entry.row];
            await tester.pumpWidget(
              _app(
                brightness,
                direction,
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: SizedBox(
                    height: height,
                    child: Builder(builder: entry.builder!),
                  ),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 500));
            expect(tester.takeException(), isNull);
            // Let springs and loops come to rest before the tree goes.
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }

  for (final entry in keycapInventory.entries.where((e) => e.isPresent)) {
    testWidgets('${entry.row} keeps its words whole at 200%', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          Brightness.light,
          TextDirection.ltr,
          Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              height: keycapInventoryHeights[entry.row],
              child: Builder(builder: entry.builder!),
            ),
          ),
          text: 2,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(_cut(tester), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
