// The label sweep (ui_core's DesignLabelCheck): every labelled control's
// label on the middle of its face, as laid out and as drawn (its capitals
// within half a device pixel), on every gallery page and every app screen,
// under standard and compact density.
// ignore_for_file: avoid_relative_lib_imports, avoid_print
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';

import '../example/lib/main.dart';
import 'keylines_test.dart'
    show keylineScreens, loadKeylineFonts, precacheShownImages;

/// Why the Pickers page cannot be read: its time wheels keep their
/// off-screen rows laid out and never painted.
const String _unpaintedWheels =
    'the time wheels keep their off-screen rows (100 by 32, each under a '
    'RepaintBoundary of a SliverFixedExtentList) laid out in the scroll '
    "view's cache area and never painted, and DrawnPixels.read refuses a "
    'screen holding an unpainted boundary (probe 11-11: 72 of them); the '
    'selects on this page are held by p_classes_test (d); 0.2.0: ui_core '
    "reads a screen past an unpainted boundary (the 0.2.0 list's wheels)";

/// Screens the check cannot read, by page or `screen at width`, with the
/// reason named.
const Map<String, String> _misreadings = {'Pickers': _unpaintedWheels};

/// Problems the check names that Minimal means, each held by its words with
/// the reason, and taken to ui_core's owner as a misreading (11-11).
final Map<RegExp, String> _held = {
  RegExp(r'a control "Note": the capitals of "Note"'):
      'a label beside a two-line entry stands on its first line, not the '
      "row's middle",
  RegExp(r'a control "(Done|Todo)": the capitals of "[^"]+" are drawn'):
      'the navigation preview draws a 390 px phone at 300 px (a FittedBox): '
      'its list rows read off by a device pixel or two there and level '
      'at full size on every app screen',
};

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, Size size, String query) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(GalleryApp.at(Uri.parse('http://localhost/?$query')));
  await _settle(tester);
}

Future<void> _check(WidgetTester tester, String at) async {
  await precacheShownImages(tester);
  final report =
      await const DesignLabelCheck(look: 'Minimal', drawnTolerance: 0.5).check(
        tester.element(find.byType(WidgetsApp).first),
        runAsync: tester.runAsync,
      );
  final unheld = DesignAlignmentReport(report.look, [
    for (final p in report.problems)
      if (!_held.keys.any((r) => r.hasMatch(p))) p,
  ]);
  print(
    '$at: ${unheld.problems.length} named, '
    '${report.problems.length - unheld.problems.length} held',
  );
  for (final p in unheld.problems) {
    print('  $p');
  }
  unheld.verify();
}

void main() {
  setUpAll(loadKeylineFonts);

  for (final density in const ['standard', 'compact']) {
    for (final page in examplePages) {
      final at = '$density · ${page.name}';
      testWidgets(at, skip: _misreadings.containsKey(page.name), (
        tester,
      ) async {
        final slug = GalleryApp.pageSlug(page.name);
        await _open(
          tester,
          const Size(1440, 900),
          'page=$slug&density=$density',
        );
        await _check(tester, at);
      }, tags: 'goldens');
    }
    for (final size in const [Size(390, 844), Size(1440, 900)]) {
      for (final screen in keylineScreens) {
        final where = '${screen.name} at ${size.width.round()}';
        final at = '$density · $where';
        testWidgets(at, skip: _misreadings.containsKey(where), (tester) async {
          await _open(tester, size, 'app=${screen.app}&density=$density');
          await screen.open(tester);
          await _check(tester, at);
        }, tags: 'goldens');
      }
    }
  }
}
