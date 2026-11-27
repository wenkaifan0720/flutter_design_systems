// A grouped list's rows are parted by rules: between rows, never above the first, which the card's rim already closes.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

final _rules = find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.painter.runtimeType.toString() == '_TopRule',
);

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets(
    'a section\'s first row stands under the card\'s rim with no rule above it',
    (tester) async {
      await tester.pumpWidget(
        neumorphicApp(
          NeumorphicListSection(
            children: [
              NeumorphicListTile(title: 'Stoner', onPressed: () {}),
              const NeumorphicListTile(title: 'Pachinko'),
              const NeumorphicKvRow('Author', 'Min Jin Lee'),
            ],
          ),
        ),
      );
      expect(_rules, findsNWidgets(2));
      final first = tester.getRect(find.text('Stoner'));
      for (final rule in _rules.evaluate()) {
        final box = rule.renderObject! as RenderBox;
        expect(box.localToGlobal(Offset.zero).dy, greaterThan(first.bottom));
      }
    },
  );

  testWidgets('under a section\'s label the first row keeps its rule', (
    tester,
  ) async {
    await tester.pumpWidget(
      neumorphicApp(
        const NeumorphicListSection(
          label: 'Shelf',
          children: [
            NeumorphicListTile(title: 'Stoner'),
            NeumorphicListTile(title: 'Pachinko'),
          ],
        ),
      ),
    );
    expect(_rules, findsNWidgets(2));
  });

  testWidgets('a rule inside the first row is the row\'s own and stays', (
    tester,
  ) async {
    await tester.pumpWidget(
      neumorphicApp(
        const NeumorphicListSection(
          children: [
            NeumorphicRuled(
              child: Column(
                children: [
                  Text('Stoner'),
                  NeumorphicRuled(child: Text('John Williams')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    expect(_rules, findsOneWidget);
  });
}
