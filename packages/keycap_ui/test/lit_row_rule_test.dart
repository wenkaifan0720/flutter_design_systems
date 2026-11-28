// A lit row's tint runs from wall to wall of its well, and so does the rule
// beside it, so no step of the floor shows at the tint's ends (a 1 px
// notch at each end of a chosen colourway). Between unlit rows the
// rule keeps its inset.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(keycapLoadFonts);

  for (final dir in TextDirection.values) {
    for (final chosen in [0, 2, 4]) {
      testWidgets('the rules beside the lit row run wall to wall '
          '(row $chosen, ${dir.name})', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const names = ['Classic', 'Retro', 'Sage', 'Rose', 'Lilac'];
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => Directionality(
              textDirection: dir,
              child: KeycapHost(brightness: Brightness.light, child: child!),
            ),
            home: KeycapScreen(
              body: KeycapListGroup(
                header: 'Colourway',
                children: [
                  for (final (i, name) in names.indexed)
                    KeycapListTile(
                      title: name,
                      selected: i == chosen,
                      onTap: () {},
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final rows = [
          for (final name in names)
            tester.getRect(
              find.ancestor(
                of: find.text(name),
                matching: find.byType(KeycapListTile),
              ),
            ),
        ];
        final lit = rows[chosen];
        final rules = find.byType(KeycapDivider).evaluate().toList();
        expect(rules, hasLength(names.length - 1));
        for (final (i, e) in rules.indexed) {
          // The rule's ink: its line inside its inset.
          final rule = tester.getRect(
            find.descendant(
              of: find.byElementPredicate((el) => el == e),
              matching: find.byType(ColoredBox),
            ),
          );
          // Rule i stands between row i and row i + 1.
          final beside = i == chosen || i + 1 == chosen;
          if (beside) {
            expect(rule.left, closeTo(lit.left, 0.5), reason: 'rule $i');
            expect(rule.right, closeTo(lit.right, 0.5), reason: 'rule $i');
          } else {
            expect(rule.left, greaterThan(lit.left + 8), reason: 'rule $i');
            expect(rule.right, lessThan(lit.right - 8), reason: 'rule $i');
          }
        }
      });
    }
  }
}
