// A loss's button (Delete, Discard) wears danger's colours: a primary on
// danger's solid, with its hover and pressed steps; another appearance in
// danger's ink on its own face, so a dialog's Discard beside its Save reads
// as the loss it is. Out of use it wears the disabled greys.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/button/button.dart'
    show Fluent2ButtonBox, Fluent2ButtonFace;

// WCAG's contrast ratio of two opaque colours.
double _contrast(Color a, Color b) {
  final (x, y) = (a.computeLuminance(), b.computeLuminance());
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

void main() {
  for (final brightness in Brightness.values) {
    final t = Fluent2ThemeData.lapis(brightness);
    final c = t.colors;
    final on = brightness.name;

    test('a danger primary stands on danger\'s solid, $on', () {
      final rest = Fluent2ButtonFace.of(
        t,
        Fluent2ButtonAppearance.primary,
        Fluent2Press.rest,
        danger: true,
      );
      expect(rest.fill, c.statusDangerBackground3);
      expect(_contrast(rest.ink, rest.fill), greaterThanOrEqualTo(4.5));
      expect(
        Fluent2ButtonFace.of(
          t,
          Fluent2ButtonAppearance.primary,
          Fluent2Press.hover,
          danger: true,
        ).fill,
        c.statusDangerBackground3Hover,
      );
      expect(
        Fluent2ButtonFace.of(
          t,
          Fluent2ButtonAppearance.primary,
          Fluent2Press.pressed,
          danger: true,
        ).fill,
        c.statusDangerBackground3Pressed,
      );
    });

    test('a danger secondary keeps its face, its words in danger\'s ink, '
        '$on', () {
      for (final press in [
        Fluent2Press.rest,
        Fluent2Press.hover,
        Fluent2Press.pressed,
      ]) {
        final plain = Fluent2ButtonFace.of(
          t,
          Fluent2ButtonAppearance.secondary,
          press,
        );
        final loss = Fluent2ButtonFace.of(
          t,
          Fluent2ButtonAppearance.secondary,
          press,
          danger: true,
        );
        expect(loss.fill, plain.fill);
        expect(loss.stroke, plain.stroke);
        expect(loss.ink, t.danger);
        expect(_contrast(loss.ink, loss.fill), greaterThanOrEqualTo(4.5));
      }
    });

    test('a disabled danger button wears the disabled greys, $on', () {
      for (final appearance in Fluent2ButtonAppearance.values) {
        expect(
          Fluent2ButtonFace.of(
            t,
            appearance,
            Fluent2Press.disabled,
            danger: true,
          ),
          Fluent2ButtonFace.of(t, appearance, Fluent2Press.disabled),
        );
      }
    });
  }

  testWidgets("a confirmation of a loss draws its act on danger's solid", (
    tester,
  ) async {
    final theme = Fluent2ThemeData.lapis();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, route) => Fluent2Theme(
          data: theme,
          child: Fluent2Host(child: route!),
        ),
        home: Builder(
          builder: (context) => Center(
            child: Fluent2Button(
              'Ask',
              onPressed: () => Fluent2Dialog.confirm(
                context,
                title: 'Delete Q3 plan.docx?',
                confirmLabel: 'Delete',
                danger: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
    final box = tester.widget<Fluent2ButtonBox>(
      find.ancestor(
        of: find.text('Delete'),
        matching: find.byType(Fluent2ButtonBox),
      ),
    );
    expect(box.face.fill, theme.colors.statusDangerBackground3);
  });
}
