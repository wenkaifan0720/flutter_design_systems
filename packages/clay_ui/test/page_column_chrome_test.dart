// On a tablet and a desk, a page's top bar and its footer stand on the
// page's column: the back ball starts where the body does, the bar's last
// key ends where the body ends, and the footer's first key starts where the
// body starts, right to left too. The bar spread to the window's margins,
// 16 px out from the body at 1440, and the footer 17 px past it; then the
// footer's keys stood at the column's far end, away from a narrower form.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Finder _face(Finder of) =>
    find.descendant(of: of, matching: find.byType(ClaySurface)).first;

void main() {
  for (final width in [390.0, 768.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('the bar and the footer stand on the page column at '
          '${width.round()} (${direction.name})', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, app) => ClayTheme(
              data: ClayThemeData.clay(Brightness.light),
              child: app!,
            ),
            home: Directionality(
              textDirection: direction,
              child: ClayScaffold(
                destinations: const [
                  ClayDestination(icon: IconData(0xe000), label: 'Books'),
                  ClayDestination(icon: IconData(0xe001), label: 'Add'),
                  ClayDestination(icon: IconData(0xe002), label: 'Settings'),
                ],
                onDestinationSelected: (_) {},
                body: ClayScreen(
                  topBar: ClayTopBar(
                    title: 'Middlemarch',
                    onBack: () {},
                    actions: [
                      ClayIconButton.plain(
                        onPressed: () {},
                        icon: const Icon(IconData(0xe003)),
                        tooltip: 'Edit',
                      ),
                    ],
                  ),
                  body: const ClayGroup(
                    children: [ClayListTile(title: 'George Eliot')],
                  ),
                  footer: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ClayButton('Delete', onPressed: () {}),
                      const SizedBox(width: 12),
                      ClayButton.filled('Edit', onPressed: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final body = tester.getRect(_face(find.byType(ClayGroup)));
        final ball = tester.getRect(_face(find.byType(ClayIconButton).first));
        final action = tester.getRect(_face(find.byType(ClayIconButton).last));
        final footStart = tester.getRect(
          _face(find.widgetWithText(ClayButton, 'Delete')),
        );
        final framed = width >= ClayMetrics.railBreakpoint;
        final rtl = direction == TextDirection.rtl;
        expect(
          rtl ? ball.right : ball.left,
          moreOrLessEquals(rtl ? body.right : body.left, epsilon: 0.5),
          reason: 'the back ball ($ball) is off the body ($body)',
        );
        expect(
          rtl ? action.left : action.right,
          moreOrLessEquals(rtl ? body.left : body.right, epsilon: 0.5),
          reason: 'the bar\'s key ($action) is off the body ($body)',
        );
        if (framed) {
          expect(
            rtl ? footStart.right : footStart.left,
            moreOrLessEquals(rtl ? body.right : body.left, epsilon: 0.5),
            reason: 'the footer ($footStart) is off the body ($body)',
          );
        }
      });
    }
  }
}
