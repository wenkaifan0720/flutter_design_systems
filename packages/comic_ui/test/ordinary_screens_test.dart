// The six ordinary screens in the example, with real open routes and menus.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/design_review.dart';
import 'gallery_support.dart';
import 'support.dart';

typedef _ReviewPage = ({
  String id,
  String title,
  Widget Function(Brightness) build,
});

const _reviewShot = ValueKey('design-review');
final _recorded =
    autoUpdateGoldenFiles ||
    Directory('test/goldens/design_review').existsSync();

Future<void> _pumpReview(
  WidgetTester tester,
  _ReviewPage page,
  Brightness mode,
  double width,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(key: _reviewShot, child: page.build(mode)),
  );
  await settle(tester);
  // Check the ordinary page before it becomes inactive under a barrier.
  expect(await inkedContrastFailures(tester), isEmpty);
  if (page.id == 'review-cards') {
    expect(
      tester.getTopLeft(find.text('OPEN PROJECT').first).dx,
      closeTo(tester.getTopLeft(find.text('Weekend plans')).dx, .01),
      reason: 'A card action shares the title and body text edge',
    );
  }
  for (final copy in ['Project owner', 'Ready to read']) {
    for (final element in find.text(copy).evaluate()) {
      final text = element.widget as Text;
      final style = DefaultTextStyle.of(element).style.merge(text.style);
      expect(style.fontSize, greaterThanOrEqualTo(14));
    }
  }
  Finder? raised;
  if (page.id == 'review-form') {
    final field = tester.getRect(find.byType(ComicSelectField));
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('review/dropdown')),
        matching: find.byType(ComicSelectField),
      ),
    );
    await settle(tester);
    expect(find.text('Express delivery'), findsOneWidget);
    raised = find.byType(ComicMenu<String>);
    final route = ModalRoute.of(tester.element(raised))! as PopupRoute;
    expect(route.barrierColor?.a ?? 0, 0);
    expect(tester.getRect(raised).width, closeTo(field.width, .01));
  }
  if (page.id == 'review-dialog') {
    await tester.tap(find.byKey(const ValueKey('review/dialog-open')));
    await settle(tester);
    expect(find.byType(ComicDialog), findsOneWidget);
    raised = find.byType(ComicDialog);
  }
  expect(tester.takeException(), isNull);
  for (final guideline in [
    androidTapTargetGuideline,
    iOSTapTargetGuideline,
    labeledTapTargetGuideline,
  ]) {
    expect(
      await guideline.evaluate(tester),
      isA<Evaluation>().having((result) => result.passed, 'passed', true),
    );
  }
  // The dimmed, blocked page behind a modal is not active content.
  expect(await inkedContrastFailures(tester, within: raised), isEmpty);
}

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });
  for (final page in reviewPages) {
    for (final width in [390.0, 1440.0]) {
      for (final mode in Brightness.values) {
        final label = '${page.id} ${mode.name} $width';
        // Its contrast is read from the drawn pixels: the rasterizer's, as a golden's (Linux CI leaves it to macOS).
        testWidgets('$label: layout and accessibility', (tester) async {
          await _pumpReview(tester, page, mode, width);
        }, tags: 'goldens');
        testWidgets(
          '$label: matches its golden',
          (tester) async {
            await _pumpReview(tester, page, mode, width);
            await expectLater(
              find.byKey(_reviewShot),
              matchesGoldenFile(
                'goldens/design_review/${page.id}_${mode.name}_${width.toInt()}.png',
              ),
            );
          },
          // Recorded on macOS.
          skip: !_recorded,
          tags: const ['goldens'],
        );
      }
    }
  }
}
