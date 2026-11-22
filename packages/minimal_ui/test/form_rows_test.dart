import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scrolling_host.dart';

void main() {
  group('form rows', () {
    testWidgets('a section prints its title upper-cased, as a header', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        scrollingHost(
          const MinimalFormSection(
            title: 'Schedule',
            footer: 'Reminders follow the device time zone.',
            children: [MinimalFormRow(label: 'Remind me')],
          ),
        ),
      );
      expect(find.text('SCHEDULE'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.text('SCHEDULE'))
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isTrue,
      );
      expect(find.text('Reminders follow the device time zone.'), findsOne);
      handle.dispose();
    });

    testWidgets('a tappable form row is one button', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        scrollingHost(
          MinimalFormRow(label: 'Archive habit', onPressed: () => taps += 1),
        ),
      );
      await tester.tap(find.text('Archive habit'));
      expect(taps, 1);
      final node = tester.getSemantics(find.bySemanticsLabel('Archive habit'));
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('an input row names its field and shows its error', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final typed = <String>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalInputRow(
            label: 'Goal',
            mono: true,
            error: 'Between 1 and 240 minutes.',
            onChanged: typed.add,
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Goal'));
      expect(node.getSemanticsData().flagsCollection.isTextField, isTrue);
      await tester.enterText(find.byType(TextField), '30');
      expect(typed, ['30']);
      expect(find.text('Between 1 and 240 minutes.'), findsOneWidget);
      handle.dispose();
    });
  });
}
