import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/column_host.dart';

void main() {
  group('MinimalSection', () {
    testWidgets('prints its title upper-cased as a header, with the count', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        columnHost(
          const MinimalSection(
            title: 'Last 12 weeks',
            count: '71 / 84',
            child: SizedBox(height: 20),
          ),
        ),
      );
      expect(find.text('LAST 12 WEEKS'), findsOneWidget);
      expect(find.text('71 / 84'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('LAST 12 WEEKS')),
        // One header node: the label and its count read together.
        matchesSemantics(label: 'LAST 12 WEEKS\n71 / 84', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('its action taps, and with no callback it is disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        columnHost(
          Column(
            children: [
              MinimalSection(
                title: 'Activity',
                actionLabel: 'View all',
                onAction: () => taps += 1,
                child: const SizedBox(),
              ),
              const MinimalSection(
                title: 'Notes',
                actionLabel: 'Export',
                child: SizedBox(),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('View all'));
      await tester.tap(find.text('Export'), warnIfMissed: false);
      expect(taps, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Export')),
        matchesSemantics(
          label: 'Export',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('its header is the group header band, 14 above and 6 below', (
      tester,
    ) async {
      await tester.pumpWidget(
        columnHost(
          const Column(
            children: [
              MinimalSection(title: 'Morning', child: SizedBox()),
              MinimalSection(title: 'Evening', gutter: true, child: SizedBox()),
              MinimalCard(
                padding: EdgeInsets.zero,
                child: MinimalSection(
                  title: 'Night',
                  gutter: true,
                  child: SizedBox(),
                ),
              ),
            ],
          ),
        ),
      );
      EdgeInsets band(String label) => tester
          .widget<MinimalSectionHeader>(
            find.byWidgetPredicate(
              (w) => w is MinimalSectionHeader && w.label == label,
            ),
          )
          .padding
          .resolve(TextDirection.ltr);
      expect(band('Morning'), const EdgeInsets.fromLTRB(0, 14, 0, 6));
      expect(
        band('Evening'),
        const EdgeInsets.fromLTRB(
          MinimalChromeMetrics.gutter,
          14,
          MinimalChromeMetrics.gutter,
          6,
        ),
      );
      expect(
        band('Night'),
        const EdgeInsets.fromLTRB(MinimalCard.inset, 14, MinimalCard.inset, 6),
      );
    });
  });
}
