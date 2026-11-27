import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'faces.dart';
import 'support/centred_host.dart';

void main() {
  testWidgets('a 32 px control lands taps across the tap floor\'s target', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      centredHost(
        MinimalIconButton(
          Icons.add,
          semanticLabel: 'Add',
          onPressed: () => taps += 1,
        ),
      ),
    );
    final box = faceOf(tester, find.byType(MinimalIconButton));
    expect(box.height, MinimalChromeMetrics.barControl);
    final reach = (MinimalLayout.tapTargets.touch.height - box.height) / 2;
    await tester.tapAt(box.topCenter - Offset(0, reach - 1));
    expect(taps, 1);
    await tester.tapAt(box.topCenter - Offset(0, reach + 4));
    expect(taps, 1);
  });

  testWidgets('an icon button announces its label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      centredHost(
        MinimalIconButton(
          Icons.search,
          semanticLabel: 'Search',
          onPressed: () {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('an icon button is ghost in a row, outlined in a bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      centredHost(
        Column(
          children: [
            MinimalIconButton(Icons.add, onPressed: () {}),
            MinimalAppBar(
              title: 'Today',
              large: true,
              actions: [MinimalIconButton(Icons.search, onPressed: () {})],
            ),
          ],
        ),
      ),
    );
    // A ghost face paints nothing, so it carries no decoration at all.
    BoxDecoration? face(IconData icon) =>
        tester
                .widget<Container>(
                  find
                      .ancestor(
                        of: find.byIcon(icon, skipOffstage: false),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration?;
    expect(face(Icons.add)?.border, isNull);
    expect(face(Icons.search)?.border, isNotNull);
  });
}
