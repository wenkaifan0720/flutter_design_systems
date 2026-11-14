// ui_core's label sweep (design6 P, class (c), and the user's split button
// fault of 11-11, at compact only): every page of the example and every
// trip planner screen, under each density the look ships (standard on
// Android, compact on macOS and the web build), names each labelled control
// whose label or icon is off its face's middle, as laid out and as drawn.
//
// The check reads the drawn pixels, the rasterizer's as a golden's are:
// tagged `goldens`, so macOS runs it and Linux CI leaves it out.
@Tags(['goldens'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/trip.dart';
import 'gallery_support.dart';

const _check = DesignLabelCheck(
  look: 'Material Expressive',
  drawnTolerance: 0.5,
);

/// The density the platform under test gets (the look's
/// `adaptivePlatformDensity`).
String get _density =>
    defaultTargetPlatform == TargetPlatform.macOS ? 'compact' : 'standard';

/// What the sweep (ui_core fdd4fc74cc) reads off the middle that is not a
/// fault, with why; null for anything else. Logged, not failed (the
/// coordinator's interim rule, msg_80aedc5a5309).
String? _misread(String what, String problem) {
  if (RegExp(
    r'^\w+ · a button "[^"]*, Loading": the capitals of "[^"]*" are drawn',
  ).hasMatch(problem)) {
    return "a busy button's label is held unseen under its loading "
        "indicator; the ink read is the indicator's";
  }
  if (what == 'states' &&
      RegExp(r'^\w+ · a button "Directions": ').hasMatch(problem)) {
    return "the states page's raw ExpressivePressable demo: the page's own "
        'icon and words in the bare primitive, which draws no label of its '
        'own (every component built on it centres its label; the press '
        'morph shows real buttons)';
  }
  // ui_core 0e25289dfd's chosen-fill rule reads a toggle group's buttons as
  // cells in a trough: their unchosen faces (Compose's connected buttons,
  // surfaceContainer and secondaryContainer) are under its contrast floor
  // on the page. Each is a button of its own face, 32dp at compact density
  // inside its 48dp touch target; the 48 is the target, not a cell drawn.
  if (RegExp(
    r'^compact · a (checkbox|switch) "[^"]*": its chosen fill is [\d.]+ by '
    r'32 px in its cell of [\d.]+ by 48;',
  ).hasMatch(problem)) {
    return "a toggle group's button: its own 32dp face at compact density "
        'in its 48dp touch target (the target read as its cell)';
  }
  if ((what == 'nav' || what == 'badge') &&
      RegExp(
        r'^\w+ · a control "[^"]*": the capitals of "\d+" are drawn [\d.]+ '
        r'device px above the middle of its face$',
      ).hasMatch(problem)) {
    return "a tab's count badge read as its label: the figures are centred on "
        'their own pill, whose top stands on the label\'s (the pill is '
        "ExpressiveSurface's paint, which the sweep does not take as a face); "
        "the tab's label is on its middle";
  }
  final m = RegExp(
    r'(the label "(.*?)"|its icon) is ([\d.]+) px (below|above) the middle '
    'of its face as laid out',
  ).firstMatch(problem);
  if (m == null) return null;
  final word = m.group(2);
  final px = double.parse(m.group(3)!);
  final below = m.group(4) == 'below';
  if (word == null && px <= 1) {
    return "a symbol's ink is off its em box's middle (mic, playlist_add, "
        'push_pin); the box is centred';
  }
  if (word != null && !below && px <= 1 && RegExp(r'^\d+$').hasMatch(word)) {
    return "the time picker's display-large digits, placed as Compose "
        "places them (the oracle's type/display scenes)";
  }
  return null;
}

Future<void> _sweep(
  WidgetTester tester,
  String what,
  Widget Function() screen,
) async {
  final report = await _check.checkDensities(
    densities: {_density: (context, child) => child},
    screen: (context) => screen(),
    pump: (widget) async {
      await tester.pumpWidget(widget);
      await settle(tester);
    },
    runAsync: tester.runAsync,
  );
  expect(tester.takeException(), isNull);
  final faults = [
    for (final p in report.problems)
      if (_misread(what, p) == null) p,
  ];
  // ignore: avoid_print
  print(
    [
      'LABEL-CHECK $what $_density: ${report.problems.length} read, '
          '${faults.length} faults',
      for (final p in report.problems)
        '  ${_misread(what, p) == null ? '!' : '~'} $p',
    ].join('\n'),
  );
  expect(faults, isEmpty, reason: "labels off their faces' middles");
}

void main() {
  setUpAll(() async {
    await loadExpressiveFonts();
    await loadBundledFonts();
  });
  final densities = TargetPlatformVariant(const {
    TargetPlatform.android,
    TargetPlatform.macOS,
  });

  for (final page in galleryExamplePages) {
    testWidgets("${page.id}: every label on its face's middle", (tester) async {
      // At the page's whole height, so every control is laid out.
      await pumpGalleryPage(tester, page, 'baseline', Brightness.light);
      await _sweep(tester, page.id, () => page.build(Brightness.light));
    }, variant: densities);
  }

  for (final screen in TripScreens.all) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('trip $screen ${width.round()}: every label on its '
          "face's middle", (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, width < 600 ? 1700 : 1100);
        addTearDown(tester.view.reset);
        await _sweep(
          tester,
          'trip $screen ${width.round()}',
          () => GalleryApp(initialPage: screen),
        );
      }, variant: densities);
    }
  }
}
