// By night an open list lies over glass as black as its own (a field's
// window, a pane). Its bezel is lit metal, so the list reads as a plate
// above that glass: on every side the rim stands at least 3:1 from the
// list's glass inside it and from the glass under it outside, the
// non-text contrast a control's edge needs. Graphite, the bars' tone, stood
// 1.2:1 there and the list melted into the field under it.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

double _luminance(Color c) {
  double lin(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  testWidgets('by night an open list\'s bezel stands 3:1 from the glass on '
      'both sides of it, all round', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(480, 400);
    addTearDown(tester.view.reset);
    final stage = GlobalKey();
    final list = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, page) =>
            StudioTheme(data: StudioThemeData.dark(), child: page!),
        home: Builder(
          builder: (context) {
            final c = StudioTheme.of(context).colors;
            return Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: stage,
                // The glass under the list: a field's window by night.
                child: ColoredBox(
                  color: c.displayLow,
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: SizedBox(
                      width: 300,
                      child: StudioListBezel(
                        key: list,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StudioMenuRow(label: 'Open studio', chosen: true),
                            StudioMenuRow(label: 'Field guide'),
                            StudioMenuRow(label: 'Workshop series'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final origin = tester.getTopLeft(find.byKey(stage));
    final rect = tester.getRect(find.byKey(list)).shift(-origin);
    final width = tester.getSize(find.byKey(stage)).width.round();
    final pixels = (await tester.runAsync(() async {
      final boundary =
          stage.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!.buffer.asUint8List();
    }))!;
    Color at(double x, double y) {
      final i = (y.floor() * width + x.floor()) * 4;
      return Color.fromARGB(255, pixels[i], pixels[i + 1], pixels[i + 2]);
    }

    final mid = rect.center;
    // Each side: a rim pixel (the rim's inner of its 2 px), the list's glass
    // 6 px inside it and the glass under the list 3 px outside it.
    final sides = <String, (Offset, Offset, Offset)>{
      'top': (
        Offset(mid.dx, rect.top + 1),
        Offset(mid.dx, rect.top + 8),
        Offset(mid.dx, rect.top - 3),
      ),
      'bottom': (
        Offset(mid.dx, rect.bottom - 2),
        Offset(mid.dx, rect.bottom - 9),
        Offset(mid.dx, rect.bottom + 2),
      ),
      'start': (
        Offset(rect.left + 1, mid.dy),
        Offset(rect.left + 8, mid.dy),
        Offset(rect.left - 3, mid.dy),
      ),
      'end': (
        Offset(rect.right - 2, mid.dy),
        Offset(rect.right - 9, mid.dy),
        Offset(rect.right + 2, mid.dy),
      ),
    };
    for (final MapEntry(key: side, value: (rimAt, inAt, outAt))
        in sides.entries) {
      final rim = at(rimAt.dx, rimAt.dy);
      final inside = at(inAt.dx, inAt.dy);
      final outside = at(outAt.dx, outAt.dy);
      expect(
        _contrast(rim, inside),
        greaterThanOrEqualTo(3),
        reason: '$side: rim $rim against the list\'s glass $inside',
      );
      expect(
        _contrast(rim, outside),
        greaterThanOrEqualTo(3),
        reason: '$side: rim $rim against the glass under it $outside',
      );
    }
  });
}
