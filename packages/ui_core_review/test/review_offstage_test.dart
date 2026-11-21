// The review's checks run from a navigator as ui_core_test's do
// (cursor_check_test.dart): past the pages its overlay keeps offstage.
import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_review/ui_core_review.dart';

void main() {
  testWidgets(
    'every review check runs from a navigator, past the pages its overlay '
    'keeps offstage, laid out once or never',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Route<void> page(Widget child) => PageRouteBuilder<void>(
        pageBuilder: (context, _, _) => ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: Center(child: child),
        ),
      );
      // A button that keeps the arrow, which the web's click cursor should
      // be: the check names it where it reads it.
      Widget button(String label) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: () {},
          child: const MouseRegion(
            cursor: SystemMouseCursors.basic,
            child: SizedBox(width: 120, height: 44),
          ),
        ),
      );
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Navigator(
            key: navigator,
            // The first page is built under the second, offstage: never laid
            // out (a transform placed in its own size, by its alignment).
            onGenerateInitialRoutes: (_, _) => [
              page(Transform.scale(scale: 1, child: button('Under'))),
              page(button('Middle')),
            ],
          ),
        ),
      );
      // The second, laid out, goes offstage under a third.
      unawaited(navigator.currentState!.push(page(button('Top'))));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Navigator));
      final reports = <DesignAlignmentReport>[
        await const DesignKeylineCheck(look: 'Test')
            .check(context, runAsync: tester.runAsync),
        await const DesignRowCheck(look: 'Test')
            .check(context, runAsync: tester.runAsync),
        await const DesignWidthCheck(look: 'Test')
            .check(context, runAsync: tester.runAsync),
        await const DesignSpacingCheck(look: 'Test')
            .check(context, runAsync: tester.runAsync),
      ];
      expect(tester.takeException(), isNull);
      for (final report in reports) {
        for (final problem in report.problems) {
          expect(problem, isNot(contains('Under')));
          expect(problem, isNot(contains('Middle')));
        }
      }
      semantics.dispose();
    },
  );
}
