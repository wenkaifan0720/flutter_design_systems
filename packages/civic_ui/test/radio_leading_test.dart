// A radio's leading part stands between its circle and its words, on the
// middle of their first line, in either direction, out of its name.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const _swatch = ValueKey('swatch');

Future<void> _pump(WidgetTester tester, TextDirection direction) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: 600,
              child: CivicTheme(
                data: CivicThemeData.light(),
                child: CivicRadioGroup<String>(
                  labelText: 'Colour',
                  groupValue: 'plum',
                  onChanged: (_) {},
                  children: const [
                    CivicRadio(
                      value: 'plum',
                      labelText: 'Plum',
                      helperText: 'Deep and warm',
                      leading: SizedBox.square(key: _swatch, dimension: 24),
                    ),
                    CivicRadio(value: 'slate', labelText: 'Slate'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'the leading part stands beside the words (${direction.name})',
      (tester) async {
        await _pump(tester, direction);
        final ltr = direction == TextDirection.ltr;
        final swatch = tester.getRect(find.byKey(_swatch));
        final words = tester.getRect(find.text('Plum'));
        final hint = tester.getRect(find.text('Deep and warm'));
        final plain = tester.getRect(find.text('Slate'));
        // 12 between it and the words, the circle's 40 and its gap before it.
        expect(ltr ? words.left - swatch.right : swatch.left - words.right, 12);
        expect(
          ltr ? swatch.left : 600 - swatch.right,
          ltr ? plain.left : 600 - plain.right,
          reason: "it starts where a plain answer's words start",
        );
        // On the middle of the words' first line.
        expect(
          swatch.center.dy,
          moreOrLessEquals(words.center.dy, epsilon: 0.5),
        );
        // The hint under the words, not under it.
        expect(ltr ? hint.left : hint.right, ltr ? words.left : words.right);
      },
    );
  }

  testWidgets('the leading part adds nothing to the answer\'s name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, TextDirection.ltr);
    expect(
      tester.getSemantics(find.text('Plum')),
      matchesSemantics(
        label: 'Plum',
        hint: 'Deep and warm',
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });
}
