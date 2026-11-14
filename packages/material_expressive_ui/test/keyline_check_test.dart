// ui_core's keyline check (design6 P) over the trip planner's screens at a
// phone's and a desktop's width, at touch density (Android) and a pointer's
// (macOS, the compact the web build gets). The look puts one
// DesignKeylineRegion in each card, each list section and each scaffold's
// content, so a screen's cards and sections are held to its margins and each
// card's and section's rows to its own keylines. keylines_test.dart stays
// for what this does not read: words inside a tappable row (one control
// here), surfaces against content, and the bar's words on the page margin.
// With EXPRESSIVE_DESIGN_REVIEW_OUT set, each screen is drawn through
// DesignKeylineSheet for the review page.
//
// The check reads the drawn pixels, the rasterizer's as a golden's are:
// tagged `goldens`, so macOS runs it and Linux CI leaves it out.
@Tags(['goldens'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/trip.dart';
import 'gallery_support.dart';

const _capture = ValueKey('keyline-check');

const _check = DesignKeylineCheck(look: 'Material Expressive');

/// What the check (ui_core fdd4fc74cc) still misreads on these screens,
/// each by the start of its problem and how it misreads: logged, not failed
/// (the coordinator's interim rule, msg_80aedc5a5309). Anything else fails.
const _misreads = <(String, String)>[
  (
    'Delivery: "Delivery" starts',
    'it reads the radio by its 20dp ring, 2dp inside the 24dp slot marked as '
        'its face, in a selectable row (standard density)',
  ),
  (
    'Hike kit: "Promo code" starts',
    "it holds the header to the promo field's face; the header is in line "
        "with the field's words, as Material sets a subheader in line with "
        "the items' text (and as the list sections' headers above it are)",
  ),
  (
    // ui_core 0e25289dfd names the control by its word.
    'Hike kit: "Apply" ends',
    "it does not see the Apply button's tonal face at standard density and "
        'reads its word, 24dp in from the face\'s end',
  ),
  (
    'Shared with you: "Pick up',
    "it judges the detail head's one-line subtitle at its ragged end",
  ),
];

String? _misread(String problem) {
  for (final (start, how) in _misreads) {
    if (problem.startsWith(start)) return how;
  }
  return null;
}

void main() {
  setUpAll(() async {
    await loadExpressiveFonts();
    await loadBundledFonts();
  });
  final output = Platform.environment['EXPRESSIVE_DESIGN_REVIEW_OUT'];
  final densities = TargetPlatformVariant(const {
    TargetPlatform.android,
    TargetPlatform.macOS,
  });

  for (final screen in TripScreens.all) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('$screen ${width.round()}: the keyline check', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, width < 600 ? 1700 : 1100);
        addTearDown(tester.view.reset);
        final app = GalleryApp(
          key: ValueKey('$screen/$width/${defaultTargetPlatform.name}'),
          initialPage: screen,
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: _capture,
            child: output == null
                ? app
                : DesignKeylineSheet(check: _check, child: app),
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
        final report = await _check.check(
          tester.element(find.byType(GalleryApp)),
          runAsync: tester.runAsync,
        );
        if (output != null) {
          // The sheet measures a frame late.
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 300)),
          );
          await tester.pump();
          final density = defaultTargetPlatform == TargetPlatform.macOS
              ? 'compact'
              : 'standard';
          final boundary = tester.renderObject(
            find.byKey(_capture),
          ) as RenderRepaintBoundary;
          final image = await tester.runAsync(
            () => boundary.toImage(pixelRatio: 1),
          );
          final bytes = await tester.runAsync(
            () => image!.toByteData(format: ui.ImageByteFormat.png),
          );
          final file = File(
            '$output/keyline-check/${screen}_${width.round()}_$density.png',
          )..createSync(recursive: true);
          file.writeAsBytesSync(bytes!.buffer.asUint8List());
        }
        final faults = [
          for (final p in report.problems)
            if (_misread(p) == null) p,
        ];
        // ignore: avoid_print
        print(
          [
            'KEYLINE-CHECK $screen ${width.round()} '
                '${defaultTargetPlatform.name}: ${report.problems.length}',
            for (final p in report.problems)
              '  ${_misread(p) == null ? '!' : '~'} $p',
          ].join('\n'),
        );
        expect(faults, isEmpty, reason: 'off the keylines');
      }, variant: densities);
    }
  }
}
