// On a wide window the page's measure stands in the middle of its pane: the
// bar, the body and the footer share one column, centred beside the
// sidebar, and a toast centres on that column.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _body = Key('body');

void main() {
  testWidgets('bar, body, footer and toast share the centred column', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            MinimalHost(brightness: Brightness.light, child: app!),
        home: MinimalAppShell.branches(
          destinations: const [
            MinimalNavItem(LucideIcons.libraryBig, 'Books'),
            MinimalNavItem(LucideIcons.settings, 'Settings'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          branches: [
            (context) => MinimalScaffold(
              maxWidth: MinimalLayout.contentWidth(context),
              topBar: const MinimalAppBar(title: 'Books'),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(key: _body, height: 40),
                  Builder(
                    builder: (context) => MinimalButton(
                      'Saved',
                      onPressed: () =>
                          showMinimalSnackBar(context, 'Book saved'),
                    ),
                  ),
                ],
              ),
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [MinimalButton('Edit', onPressed: () {})],
              ),
            ),
            (context) => const SizedBox(),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pane = tester.getRect(find.byType(MinimalScaffold));
    final body = tester.getRect(find.byKey(_body));
    // In the middle of the pane, beside the sidebar.
    expect(pane.left, greaterThan(0));
    expect(
      (body.left - pane.left) - (pane.right - body.right),
      moreOrLessEquals(0, epsilon: 1),
    );
    expect(body.width, lessThan(pane.width - 200));
    // The bar's title on the body's start, the footer's act on its end.
    expect(
      tester.getRect(find.text('Books').last).left,
      moreOrLessEquals(body.left, epsilon: 1),
    );
    expect(
      tester.getRect(find.text('Edit')).right,
      lessThanOrEqualTo(body.right + 1),
    );
    expect(
      tester.getRect(find.text('Edit')).right,
      greaterThan(body.right - 24),
    );
    // A toast centres on the column.
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    final toast = tester.getRect(find.text('Book saved'));
    final card = tester.getRect(
      find
          .ancestor(
            of: find.text('Book saved'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(card.center.dx, moreOrLessEquals(body.center.dx, epsilon: 1));
    expect(card.left, greaterThanOrEqualTo(body.left - 1));
    expect(card.right, lessThanOrEqualTo(body.right + 1));
    expect(toast.width, greaterThan(0));
  });
}
