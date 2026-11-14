import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  for (final still in [false, true]) {
    testWidgets(
      'compact indicator ${still ? 'jumps with reduced motion' : 'animates between pages'}',
      (tester) async {
        final page = ValueNotifier(1);
        addTearDown(page.dispose);
        await tester.pumpWidget(
          neumorphicApp(
            Builder(
              builder: (context) => NeumorphicTheme(
                data: NeumorphicTheme.of(context),
                child: MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: still),
                  child: Center(
                    child: ValueListenableBuilder<int>(
                      valueListenable: page,
                      builder: (context, value, _) => NeumorphicPageDots(
                        count: 3,
                        selectedIndex: value,
                        label: 'Tour',
                        individualTargets: false,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<List<int>> pixels() async => (await tester.runAsync(() async {
          final image = await captureImage(
            tester.element(find.byType(NeumorphicPageDots)),
          );
          try {
            return (await image.toByteData())!.buffer.asUint8List().toList();
          } finally {
            image.dispose();
          }
        }))!;
        page.value = 2;
        await tester.pump();
        final start = await pixels();
        await tester.pump(const Duration(milliseconds: 100));
        final middle = await pixels();
        await tester.pumpAndSettle();
        final end = await pixels();
        if (still) {
          expect(start, orderedEquals(end));
        } else {
          expect(start, isNot(orderedEquals(middle)));
          expect(middle, isNot(orderedEquals(end)));
        }
        expect(tester.takeException(), isNull);
      },
      tags: ['goldens'],
    );
  }
  testWidgets('compact indicator handles pages disappearing and returning', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final count = ValueNotifier(3);
    addTearDown(count.dispose);
    final selected = <int>[];
    try {
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: ValueListenableBuilder<int>(
              valueListenable: count,
              builder: (context, value, _) => NeumorphicPageDots(
                count: value,
                selectedIndex: 0,
                label: 'Tour',
                individualTargets: false,
                onChanged: selected.add,
              ),
            ),
          ),
        ),
      );
      count.value = 0;
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Tour'), findsNothing);
      count.value = 4;
      await tester.pumpAndSettle();
      final target = find.bySemanticsLabel('Tour');
      expect(tester.getSemantics(target).getSemanticsData().value, '1 of 4');
      final rect = tester.getRect(target);
      await tester.tapAt(Offset(rect.right - 2, rect.center.dy));
      expect(selected, [1]);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
