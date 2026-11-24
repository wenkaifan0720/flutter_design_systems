// A toast stands one line clear of the shell's status line where the line
// runs the screen's width at its foot (beside a rail or a side pane, or in a
// shell with no destinations), as it stands one line clear of a phone's
// window list: the status line is a bar, not a line of the page.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  for (final (width, places) in const [
    (1440.0, true),
    (900.0, true),
    (1440.0, false),
  ]) {
    testWidgets('at $width a toast stands one line over the status line'
        '${places ? '' : ' of a shell with no destinations'}', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, app) => TermTheme(
            data: TermThemeData.light(),
            child: TermToaster(child: app!),
          ),
          home: TermScaffold(
            destinations: places
                ? const [
                    TermNavigationDestination(label: 'runs'),
                    TermNavigationDestination(label: 'deploys'),
                  ]
                : const [],
            statusLine: const TermStatusLine(mode: 'RUNS'),
            body: Builder(
              builder: (context) => Center(
                child: TermButton(
                  label: 'deploy',
                  onPressed: () => TermToaster.show(
                    context,
                    message: 'deployed atlas-api to staging',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('deploy'));
      await tester.pumpAndSettle();
      final grid = TermGrid.of(
        tester.element(find.byType(TermScaffold)),
        const TermGrid(),
      );
      final line = tester.getRect(find.byType(TermStatusLine));
      expect(line.bottom, 900);
      expect(
        line.top - tester.getRect(find.byType(TermToast)).bottom,
        closeTo(grid.lineHeight, 0.5),
      );
    });
  }
}
