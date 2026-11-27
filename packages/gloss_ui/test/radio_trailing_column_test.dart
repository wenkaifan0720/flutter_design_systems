// A radio group whose rows show something after their words (a palette's
// swatches) keeps it in one column: every row's words take the widest
// words' room, so what follows them starts on one line, right to left too.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

const _names = {'a': 'Teal', 'b': 'Amethyst', 'c': 'Rose'};

Future<void> _show(WidgetTester tester, TextDirection direction) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => GlossHost(child: app!),
      home: Directionality(
        textDirection: direction,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topCenter,
            child: GlossRadioGroup<String>(
              options: _names.keys.toList(),
              groupValue: 'a',
              labelOf: (id) => _names[id]!,
              trailingOf: (id) =>
                  SizedBox.square(key: ValueKey('mark $id'), dimension: 20),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(glossLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets(
      'what follows the words starts on one line (${direction.name})',
      (tester) async {
        await _show(tester, direction);
        Rect mark(String id) =>
            tester.getRect(find.byKey(ValueKey('mark $id')));
        final ltr = direction == TextDirection.ltr;
        double start(String id) => ltr ? mark(id).left : mark(id).right;
        expect(start('a'), moreOrLessEquals(start('b'), epsilon: 0.5));
        expect(start('c'), moreOrLessEquals(start('b'), epsilon: 0.5));
        // After the widest words, a small gap on.
        final widest = tester.getRect(find.text('Amethyst'));
        expect(
          ltr ? start('b') - widest.right : widest.left - start('b'),
          moreOrLessEquals(GlossSpacing.small, epsilon: 0.5),
        );
      },
    );
  }
}
