// A socket that holds nothing (a table row's tick, a timeline's step to
// come) keeps a fine rim round its mouth, as an empty checkbox does, so it
// reads on its ground by day and by night (by night both were all but
// gone, about 1.1:1).
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

double _lum(int r, int g, int b) {
  double lin(int v) {
    final s = v / 255;
    return s <= 0.04045
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
}

final _shot = GlobalKey();

void main() {
  setUpAll(glossLoadFonts);

  for (final brightness in Brightness.values) {
    testWidgets('empty sockets keep a rim, $brightness', (tester) async {
      tester.view
        ..physicalSize = const Size(480, 520)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = GlossTableController<String>(
        rows: const ['Lemon risotto'],
        columns: const [GlossDataColumn<String>(id: 'dish', label: 'Dish')],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: _shot,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, app) => GlossHost(
              theme: GlossThemeData.light(),
              darkTheme: GlossThemeData.dark(),
              brightness: brightness,
              child: app!,
            ),
            home: GlossScaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlossDataTable<String>(
                      controller: controller,
                      cell: (row, column) => row,
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: GlossCheckbox(value: false, onChanged: (_) {}),
                    ),
                    const SizedBox(height: 24),
                    const GlossTimeline(
                      entries: [
                        GlossTimelineEntry(
                          title: 'Stir in the lemon',
                          time: '18:30',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData();
        image.dispose();
        return data!;
      }))!;
      double at(int x, int y) {
        final i = (y * 480 + x) * 4;
        return _lum(
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          bytes.getUint8(i + 2),
        );
      }

      // The strongest step between the socket's rim (its outer 2 px) and
      // the ground just outside it.
      double rim(Rect r) {
        final ground = at(r.center.dx.round(), (r.top - 3).round());
        var best = 1.0;
        for (var y = r.top.floor(); y < r.bottom.ceil(); y++) {
          for (var x = r.left.floor(); x < r.right.ceil(); x++) {
            final edge = [
              x - r.left,
              r.right - 1 - x,
              y - r.top,
              r.bottom - 1 - y,
            ].reduce((a, b) => a < b ? a : b);
            if (edge > 1.5) continue;
            final l = at(x, y);
            final ratio =
                (l > ground ? l + 0.05 : ground + 0.05) /
                (l > ground ? ground + 0.05 : l + 0.05);
            if (ratio > best) best = ratio;
          }
        }
        return best;
      }

      final ticks = find.descendant(
        of: find.byType(GlossDataTable<String>),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 20 && w.height == 20,
        ),
      );
      final node = find
          .descendant(
            of: find.byType(GlossTimeline),
            matching: find.byType(GlossSurface),
          )
          .first;
      final box = find
          .descendant(
            of: find.byType(GlossCheckbox),
            matching: find.byType(CustomPaint),
          )
          .evaluate()
          .map((e) => tester.getRect(find.byElementPredicate((x) => x == e)))
          .firstWhere((r) => r.width == r.height && r.width < 40);
      final checkbox = rim(box);
      final measured = {
        'header tick': rim(tester.getRect(ticks.at(0))),
        'row tick': rim(tester.getRect(ticks.at(1))),
        'step to come': rim(tester.getRect(node)),
      };
      // ignore: avoid_print
      print('RIM $brightness checkbox $checkbox $measured');
      for (final MapEntry(:key, :value) in measured.entries) {
        expect(value, greaterThanOrEqualTo(checkbox * 0.9), reason: key);
      }
    });
  }
}
