// A calendar's days of the months either side read at 4.5:1 on its panel, by day and by night: a press on one picks
// it, so its figure is a control's words. They stood at 2.67:1, the secondary ink at 60 %.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../example/lib/kit_gallery/kit.dart';

const _root = Key('root');

double _contrast(Color a, Color b) {
  final (x, y) = (a.computeLuminance(), b.computeLuminance());
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}

void main() {
  setUpAll(glossLoadFonts);

  for (final brightness in Brightness.values) {
    testWidgets("the next month's days read at 4.5:1 (${brightness.name})", (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        kitApp(
          brightness: brightness,
          home: RepaintBoundary(
            key: _root,
            child: Builder(
              builder: (context) => ColoredBox(
                color: GlossTheme.of(context).colors.page,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GlossCalendar(
                      firstDate: DateTime(2026),
                      lastDate: DateTime(2027),
                      selectedDate: DateTime(2026, 11, 20),
                      onDateChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // November 2026 ends on a Monday: the last week holds December's 1st to 5th.
      final threes = find.text('3').evaluate().toList()
        ..sort(
          (a, b) => tester
              .getRect(find.byWidget(a.widget))
              .top
              .compareTo(tester.getRect(find.byWidget(b.widget)).top),
        );
      final december = threes.last.widget as Text;
      final at = tester.getRect(find.byWidget(december));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(_root),
      );
      final image = (await tester.runAsync(() => boundary.toImage()))!;
      final bytes = (await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      final i =
          (at.center.dy.round() * image.width + (at.left - 8).round()) * 4;
      final ground = Color.fromARGB(
        255,
        bytes.getUint8(i),
        bytes.getUint8(i + 1),
        bytes.getUint8(i + 2),
      );
      image.dispose();
      final ink = Color.alphaBlend(december.style!.color!, ground);
      expect(
        _contrast(ink, ground),
        greaterThanOrEqualTo(4.5),
        reason: 'ink $ink on $ground',
      );
    });
  }
}
