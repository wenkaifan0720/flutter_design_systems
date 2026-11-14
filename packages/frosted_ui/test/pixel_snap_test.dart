// A filter chip's and a segment's 12 px words paint with their left edge on the device-pixel grid (coordinator,
// 11-12: on Linux the text contrast guideline read Activity's "Pending" chip at 1.62 and Settings' night "Light"
// segment at 4.31 and 4.35; their inks stand 7.6:1 and 11:1, but thin glyphs laid at a fractional x cover no pixel
// whole, so the words read as their edges' shade). Rows started at a fractional x, at 1x and 2x.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

const _chips = ['All', 'Money in', 'Pending', 'Harbor Card'];
const _segments = ['Light', 'Dark', 'System'];

void main() {
  setUpAll(frostedLoadFonts);

  for (final dpr in [1.0, 2.0]) {
    testWidgets('at ${dpr}x the chips and segments paint their words on '
        'whole device pixels', (tester) async {
      tester.view.physicalSize = Size(390 * dpr, 300 * dpr);
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);
      final t = FrostedThemeData.preset(
        FrostedThemeData.presets.first,
        Brightness.light,
      );
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, page) =>
              FrostedHost(light: t, dark: t, child: page!),
          home: ColoredBox(
            color: t.colorScheme.background,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.3, 16.7, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    FrostedFilterChipGroup<int>(
                      value: 0,
                      onChanged: (_) {},
                      options: [
                        for (var i = 0; i < _chips.length; i++)
                          FrostedFilterOption(i, _chips[i]),
                      ],
                    ),
                    FrostedSegmentedButton<int>(
                      label: 'Appearance',
                      value: 0,
                      onChanged: (_) {},
                      segments: [
                        for (var i = 0; i < _segments.length; i++)
                          FrostedButtonSegment(i, _segments[i]),
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
      for (final word in [..._chips, ..._segments]) {
        final p = tester.renderObject<RenderParagraph>(find.text(word));
        final x =
            MatrixUtils.transformPoint(p.getTransformTo(null), Offset.zero).dx *
            dpr;
        expect(
          (x - x.roundToDouble()).abs(),
          lessThan(0.01),
          reason: '"$word" paints from device x $x',
        );
      }
    });
  }
}
