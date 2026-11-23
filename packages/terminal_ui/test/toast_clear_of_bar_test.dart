// A toast on a phone stands one line clear of the shell's window list (the
// tab bar), as it stands one line clear of the screen's foot where there is
// no bar: the shell keeps the bar clear, and the toaster keeps one line
// between, not two. A page pushed over the shell covers the bar, and the
// toast stands over the screen's foot until the page goes.
import 'dart:async' show unawaited;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  for (final (covered, bar) in const [
    (false, true),
    (false, false),
    (true, true),
  ]) {
    testWidgets(
      covered
          ? 'a toast stands one line over the foot while a page covers the '
                'window list, and over the list again as the page goes'
          : 'a toast stands one line over the ${bar ? 'window list' : "screen's foot"}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, app) => TermTheme(
              data: TermThemeData.dark(),
              child: TermToaster(child: app!),
            ),
            home: TermScaffold(
              destinations: bar
                  ? const [
                      TermNavigationDestination(label: 'runs'),
                      TermNavigationDestination(label: 'deploys'),
                    ]
                  : const [],
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
        Rect toast() => tester.getRect(find.byType(TermToast));
        final floor = bar
            ? tester.getRect(find.byType(TermNavigationBar)).top
            : 844.0;
        expect(floor - toast().bottom, closeTo(grid.lineHeight, 0.5));
        if (!covered) return;
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).first,
        );
        unawaited(
          navigator.push(
            PageRouteBuilder<void>(
              pageBuilder: (context, _, _) => const SizedBox.expand(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(844 - toast().bottom, closeTo(grid.lineHeight, 0.5));
        navigator.pop();
        await tester.pumpAndSettle();
        expect(floor - toast().bottom, closeTo(grid.lineHeight, 0.5));
      },
    );
  }
}
