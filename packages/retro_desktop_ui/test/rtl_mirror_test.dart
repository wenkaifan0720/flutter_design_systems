// Right to left: a bar and a slider fill from the start side. (Where each everyday part's words and marks stand is
// world_checks_test's, with the check every look shares.)
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

void _take(Object? _) {}

const _part = ValueKey('part');

Future<void> _pump(
  WidgetTester tester,
  Widget part,
  TextDirection direction,
) async {
  tester.view.physicalSize = const Size(390, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    retroDesktopApp(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: 320,
            child: RepaintBoundary(key: _part, child: part),
          ),
        ),
      ),
      direction: direction,
    ),
  );
  await tester.pumpAndSettle();
}

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary =
      find.byKey(_part).evaluate().single.renderObject!
          as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

// The mean brightness of a quarter of the part's middle row: the start quarter or the end quarter, read on screen.
Future<(double, double)> _quarters(WidgetTester tester) async {
  final size = tester.getSize(find.byKey(_part));
  final w = size.width.round(), h = size.height.round();
  final px = await _pixels(tester);
  double mean(int from, int to) {
    var sum = 0.0;
    for (var y = h ~/ 3; y < h * 2 ~/ 3; y++) {
      for (var x = from; x < to; x++) {
        final i = (y * w + x) * 4;
        sum += px[i] + px[i + 1] + px[i + 2];
      }
    }
    return sum / ((to - from) * (h * 2 ~/ 3 - h ~/ 3) * 3);
  }

  return (mean(w ~/ 16, w * 5 ~/ 16), mean(w * 11 ~/ 16, w * 15 ~/ 16));
}

final _fills = <(String, Widget Function())>[
  (
    'a progress bar',
    () => const RetroDesktopLinearProgressIndicator(
      value: .2,
      label: 'Copying',
      quiet: true,
    ),
  ),
  (
    'a slider',
    () =>
        const RetroDesktopSlider(label: 'Volume', value: .1, onChanged: _take),
  ),
];

void main() {
  setUpAll(loadRetroDesktopFonts);

  // The theme may add Material's words under its own Localizations, which sets the locale's direction: an app's
  // right to left above the theme, under an English locale, must reach its parts.
  testWidgets('the theme keeps the app\'s right to left', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: RetroDesktopTheme(
            data: RetroDesktopThemeData.preset('classic', Brightness.light),
            child: child!,
          ),
        ),
        home: Builder(
          builder: (context) => Text(Directionality.of(context).name),
        ),
      ),
    );
    expect(find.text('rtl'), findsOneWidget);
  });

  for (final (name, part) in _fills) {
    testWidgets('$name fills from the start right to left', (tester) async {
      await _pump(tester, part(), TextDirection.ltr);
      final (ltrStart, ltrEnd) = await _quarters(tester);
      await _pump(tester, part(), TextDirection.rtl);
      final (rtlStart, rtlEnd) = await _quarters(tester);
      // Left to right the start quarter (the left) differs from the end; right to left the same quarters trade places.
      expect((ltrStart - ltrEnd).abs(), greaterThan(4));
      expect(rtlEnd, moreOrLessEquals(ltrStart, epsilon: 6));
      expect(rtlStart, moreOrLessEquals(ltrEnd, epsilon: 6));
    }, tags: const ['goldens']);
  }
}
