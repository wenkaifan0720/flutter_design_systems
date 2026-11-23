// A snack bar or a toast raised from a page with a footer stands above the
// footer, as a Scaffold keeps a snackbar above its footer; one raised from a
// route over the page stands at the foot.
import 'dart:async';

import 'package:comic_ui/comic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<GlobalKey> _page(WidgetTester tester, Key foot) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final page = GlobalKey();
  await tester.pumpWidget(
    comicApp(
      ComicScaffold(
        footer: KeyedSubtree(
          key: foot,
          child: ComicButton.filled('Add to pull list', onPressed: () {}),
        ),
        body: SizedBox(key: page, height: 200),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return page;
}

void main() {
  setUpAll(loadComicFonts);

  testWidgets("a snack bar stands above its page's footer", (tester) async {
    const foot = Key('foot');
    final page = await _page(tester, foot);
    showComicSnackBar(page.currentContext!, 'Saved to your collection');
    await tester.pumpAndSettle();
    final footer = tester.getRect(find.byKey(foot));
    final snack = tester.getRect(find.byType(ComicSnackBar));
    expect(snack.bottom, lessThanOrEqualTo(footer.top));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets("a toast stands above its page's footer", (tester) async {
    const foot = Key('foot');
    final page = await _page(tester, foot);
    showComicToast(page.currentContext!, 'Link copied');
    await tester.pumpAndSettle();
    final footer = tester.getRect(find.byKey(foot));
    final toast = tester.getRect(find.byType(ComicToast));
    expect(toast.bottom, lessThanOrEqualTo(footer.top));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'a snack bar raised from a route over the page stands at the foot',
    (tester) async {
      const foot = Key('foot');
      final page = await _page(tester, foot);
      final footer = tester.getRect(find.byKey(foot));
      final cover = GlobalKey();
      unawaited(
        Navigator.of(page.currentContext!).push(
          PageRouteBuilder<void>(
            pageBuilder: (context, _, _) => SizedBox.expand(key: cover),
          ),
        ),
      );
      await tester.pumpAndSettle();
      showComicSnackBar(cover.currentContext!, 'Saved to your collection');
      await tester.pumpAndSettle();
      final snack = tester.getRect(find.byType(ComicSnackBar));
      // The covered page's footer keeps nothing clear.
      expect(snack.bottom, greaterThan(footer.top));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );
}
