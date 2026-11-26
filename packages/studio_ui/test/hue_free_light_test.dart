// Graphite, the preset with no hue, by day: its white light can't be seen
// on the silver, so what is on shows in ink (a lamp, a tab's bar, a latched
// key); the white shows only through the dark, in a switch's and a fader's
// slot and in the graphite main keys' lamps. Held here at the parts that
// draw it.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:studio_ui/studio_ui.dart';

final _day = StudioThemeData.preset('graphite', Brightness.light);

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) =>
      StudioHost(brightness: Brightness.light, theme: _day, child: app!),
  home: Center(child: child),
);

// The mean luminance of a column of [part]'s pixels, [at] of the way
// along it from its start.
Future<double> _column(WidgetTester tester, Finder part, double at) async {
  final box = tester.renderObject<RenderBox>(part);
  final rect = box.localToGlobal(Offset.zero) & box.size;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shot),
  );
  final origin = boundary.localToGlobal(Offset.zero);
  final data = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    image.dispose();
    return (bytes!, width);
  });
  final (bytes, width) = data!;
  final x = (rect.left - origin.dx + rect.width * at).round();
  var sum = 0.0;
  var n = 0;
  for (
    var y = (rect.top - origin.dy).round();
    y < (rect.bottom - origin.dy).round();
    y++
  ) {
    final i = (y * width + x) * 4;
    sum += Color.fromARGB(
      255,
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    ).computeLuminance();
    n++;
  }
  return sum / n;
}

final _shot = GlobalKey();

void main() {
  test('by day the light shows in ink, the white kept for the dark', () {
    final c = _day.colors;
    expect(RawPalette.contrastRatio(c.indicator, c.key), greaterThan(3));
    expect(RawPalette.contrastRatio(c.lightInDark, c.litKey), greaterThan(7));
  });

  testWidgets("the main keys' lamps are the white light", (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StudioButton.lit('Publish', onPressed: () {}),
            StudioTransportKey(
              icon: const Icon(LucideIcons.play),
              tooltip: 'Play',
              lit: true,
              onPressed: () {},
            ),
            StudioFloatingKey.extended(
              icon: const Icon(LucideIcons.mic),
              label: 'Record',
              onPressed: () {},
            ),
            StudioSplitKey(
              label: 'Export',
              lit: true,
              onPressed: () {},
              actions: const [],
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final lamps = tester
        .widgetList<StudioLamp>(find.byType(StudioLamp))
        .where((lamp) => lamp.on)
        .toList();
    expect(lamps, hasLength(4));
    for (final lamp in lamps) {
      expect(lamp.color, _day.colors.lightInDark);
    }
  });

  testWidgets('an on switch and a fader light their slots in the white', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        RepaintBoundary(
          key: _shot,
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StudioSwitch(
                  value: true,
                  onChanged: (_) {},
                  semanticLabel: 'On',
                ),
                StudioFader(value: 1, onChanged: (_) {}, semanticLabel: 'Full'),
                StudioFader(
                  value: 0,
                  onChanged: (_) {},
                  semanticLabel: 'Empty',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final slot = await _column(tester, find.byType(StudioSwitch), 0.2);
    final full = await _column(tester, find.byType(StudioFader).first, 0.5);
    final empty = await _column(tester, find.byType(StudioFader).last, 0.5);
    expect(slot, greaterThan(0.4), reason: 'the on slot is lit white');
    expect(full - empty, greaterThan(0.02), reason: 'the lit track is white');
  });
}
