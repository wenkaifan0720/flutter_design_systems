// The bar's first and last faces stand on the page's keylines (the gutter),
// as its doc says; their tap targets grow inward. The back button's air to
// the breadcrumb is the documented barCrumbGap, measured from its face.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

Finder _face(int i) => find
    .descendant(
      of: find.byType(MinimalIconButton).at(i),
      matching: find.byType(DecoratedBox),
    )
    .first;

Future<void> _pushed(WidgetTester tester, TextDirection direction) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final nav = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: nav,
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: MinimalHost(brightness: Brightness.light, child: app!),
      ),
      home: const MinimalScaffold(
        topBar: MinimalAppBar(title: 'Books'),
        body: SizedBox(),
      ),
    ),
  );
  nav.currentState!.push(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => MinimalScaffold(
        topBar: MinimalAppBar(
          title: 'Middlemarch',
          parent: 'Books',
          actions: [
            MinimalIconButton(
              LucideIcons.pencil,
              semanticLabel: 'Edit',
              onPressed: () {},
            ),
          ],
        ),
        body: const SizedBox(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(minimalLoadFonts);

  testWidgets('LTR: the back face and the last action stand on the gutter', (
    tester,
  ) async {
    await _pushed(tester, TextDirection.ltr);
    const gutter = MinimalChromeMetrics.gutter;
    final back = tester.getRect(_face(0));
    expect(back.left, gutter);
    expect(tester.getRect(_face(1)).right, 390 - gutter);
    final crumb = tester.getRect(find.textContaining('Books'));
    expect(crumb.left - back.right, MinimalChromeMetrics.barCrumbGap);
  });

  testWidgets('RTL: the faces stand on the mirrored gutter', (tester) async {
    await _pushed(tester, TextDirection.rtl);
    const gutter = MinimalChromeMetrics.gutter;
    final back = tester.getRect(_face(0));
    expect(back.right, 390 - gutter);
    expect(tester.getRect(_face(1)).left, gutter);
    final crumb = tester.getRect(find.textContaining('Books'));
    expect(back.left - crumb.right, MinimalChromeMetrics.barCrumbGap);
  });
}
