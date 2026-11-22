import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/page_host.dart';

void main() {
  group('MinimalBreadcrumb', () {
    testWidgets('ancestors are controls, the current step is not', (
      tester,
    ) async {
      var back = 0;
      await tester.pumpWidget(
        pageApp(
          MinimalBreadcrumb(
            crumbs: [
              MinimalBreadcrumbItem('Habits', onPressed: () => back++),
              const MinimalBreadcrumbItem('HAB-4', mono: true),
            ],
          ),
        ),
      );
      expect(find.text('/'), findsOneWidget);
      await tester.tap(find.text('Habits'));
      expect(back, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Habits')),
        isSemantics(isButton: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('HAB-4')),
        isSemantics(isButton: false, isSelected: true),
      );
    });
  });

  testWidgets('a tappable crumb has the full 44 px tap band', (tester) async {
    var back = 0;
    await tester.pumpWidget(
      pageApp(
        MinimalBreadcrumb(
          crumbs: [
            MinimalBreadcrumbItem('Habits', onPressed: () => back++),
            const MinimalBreadcrumbItem('HAB-4', mono: true),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(MinimalBreadcrumb)).height, 44);
    final crumb = tester.getRect(find.bySemanticsLabel('Habits'));
    await tester.tapAt(Offset(crumb.center.dx, crumb.top - 6));
    await tester.tapAt(Offset(crumb.center.dx, crumb.bottom + 6));
    expect(back, 2);
    // A path of context alone is as tall as its text.
    await tester.pumpWidget(
      pageApp(
        const MinimalBreadcrumb(
          crumbs: [
            MinimalBreadcrumbItem('Habits'),
            MinimalBreadcrumbItem('HAB-4', mono: true),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(MinimalBreadcrumb)).height, lessThan(44));
  });

  testWidgets('a long path shortens its longest step, never overflows', (
    tester,
  ) async {
    await tester.pumpWidget(
      pageApp(
        const MinimalBreadcrumb(
          crumbs: [
            MinimalBreadcrumbItem('Orders'),
            MinimalBreadcrumbItem('Café Morgen, weekly bread and pastry order'),
            MinimalBreadcrumbItem('#1045', mono: true),
          ],
        ),
        width: 320,
      ),
    );
    expect(tester.takeException(), isNull);
    final orders = tester.renderObject<RenderParagraph>(find.text('Orders'));
    expect(orders.didExceedMaxLines, isFalse);
    final long = tester.renderObject<RenderParagraph>(
      find.text('Café Morgen, weekly bread and pastry order'),
    );
    expect(long.didExceedMaxLines, isTrue);
    expect(tester.getRect(find.text('#1045')).right, lessThanOrEqualTo(320));
  });
}
