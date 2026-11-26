// Tags, a row of buttons and a path wrap as ui_core's chip group: their
// run spacing is part of each target, so wrapped rows keep the touch floor
// between them.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  testWidgets('tag input, button group and breadcrumb are chip groups', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: TermTheme(
          data: TermThemeData.dark(),
          child: Material(
            child: ListView(
              children: [
                TermTagInput<String>(
                  values: const ['api', 'billing', 'cron', 'deploy', 'edge'],
                  onChanged: (_) {},
                  labelText: 'services',
                ),
                TermButtonGroup(
                  children: [
                    for (final l in ['logs', 'retry', 'roll back', 'promote'])
                      TermButton(label: l, onPressed: () {}),
                  ],
                ),
                TermBreadcrumb(
                  crumbs: [
                    (label: '~', onPressed: () {}),
                    (label: 'atlas-api', onPressed: () {}),
                    (label: 'deployments', onPressed: () {}),
                    (label: '#1482', onPressed: null),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    for (final owner in [
      find.byType(TermTagInput<String>),
      find.byType(TermButtonGroup),
      find.byType(TermBreadcrumb),
    ]) {
      expect(
        find.descendant(of: owner, matching: find.byType(RawChipGroup)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: owner, matching: find.byType(Wrap)),
        findsNothing,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
