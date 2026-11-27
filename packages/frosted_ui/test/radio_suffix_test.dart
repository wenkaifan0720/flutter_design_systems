// A radio's suffix (a palette's swatches) follows its words, right beside
// them at any width, so it reads as that choice's; it is drawn, not read: the
// row is named by its label.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  for (final direction in TextDirection.values) {
    for (final width in [360.0, 1200.0]) {
      testWidgets('the suffix stands beside the words '
          '(${direction.name}, ${width.toInt()})', (t) async {
        final semantics = t.ensureSemantics();
        const part = Key('part');
        t.view.physicalSize = const Size(1440, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, page) => Directionality(
              textDirection: direction,
              child: FrostedHost(child: page!),
            ),
            home: Center(
              child: SizedBox(
                width: width,
                child: FrostedRadioGroup<String>(
                  labelText: 'Palette',
                  value: 'a',
                  onChanged: (_) {},
                  options: const [
                    FrostedRadio(
                      'a',
                      'Opal',
                      suffix: SizedBox(key: part, width: 44, height: 20),
                    ),
                    FrostedRadio('b', 'Jade'),
                  ],
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final swatch = t.getRect(find.byKey(part));
        final words = t.getRect(find.text('Opal'));
        final mark = t.getRect(
          find
              .descendant(
                of: find.byType(FrostedRadio<String>).first,
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final ltr = direction == TextDirection.ltr;
        // After the words, by the row's small gap; the words stand between
        // the radio and the swatches.
        final gap = ltr ? swatch.left - words.right : words.left - swatch.right;
        expect(gap, inInclusiveRange(4, 16));
        expect(
          ltr ? mark.right <= words.left : mark.left >= words.right,
          isTrue,
        );
        expect(find.bySemanticsLabel('Opal'), findsOneWidget);
        semantics.dispose();
      });
    }
  }
}
