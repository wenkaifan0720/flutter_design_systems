// Buttons in a row (design6, 11-11 16:34: "the outline a person sees is the
// box"): every control that shares a row with a button shows one top and one
// bottom by its visible outline, read from the pixels drawn, beside a plain
// line button; a variant may differ in fill, never in the size it shows. In
// both appearances, by day and by night, under each density, at a phone's
// width and a desktop's, two device pixels to a point.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

const _ratio = 2.0;

final _variants = <String, Widget Function()>{
  'the default button': () => RetroDesktopButton(
    'Open',
    wide: true,
    isDefaultAction: true,
    onPressed: () {},
  ),
  'an act button': () =>
      RetroDesktopButton('New task', isDefaultAction: true, onPressed: () {}),
  'a push button': () =>
      RetroDesktopButton('Discard', wide: true, onPressed: () {}),
  'a danger button': () => RetroDesktopButton(
    'Delete',
    isDefaultAction: true,
    isDestructiveAction: true,
    onPressed: () {},
  ),
  'a split button': () => RetroDesktopSplitButton(
    label: 'Save',
    onPressed: () {},
    actions: [DesignSplitAction(label: 'Save as…', onPressed: () {})],
  ),
  'a popup': () => RetroDesktopPopupButton('Workshop', onPressed: () {}),
  'an icon button': () => RetroDesktopIconButton(
    RetroDesktopGlyphs.tag,
    label: 'Tag',
    onPressed: () {},
  ),
  'a button group': () => RetroDesktopButtonGroup(
    items: [
      RetroDesktopButtonGroupItem(label: 'Back', onPressed: () {}),
      RetroDesktopButtonGroupItem(label: 'Next', onPressed: () {}),
    ],
  ),
  'a toggle group': () => RetroDesktopToggleGroup<String>(
    values: const ['Day', 'Week'],
    selected: const {'Day'},
    labelOf: (v) => v,
    onChanged: (_) {},
  ),
};

final _boundary = GlobalKey();
const _reference = ValueKey('reference'), _variant = ValueKey('variant');

void main() {
  setUpAll(() async {
    await loadRetroDesktopFonts();
    await loadRetroDesktopGlyphFace();
    await loadRetroDesktopManifestFonts();
  });

  for (final appearance in RetroDesktopAppearance.values) {
    for (final brightness in Brightness.values) {
      testWidgets('${appearance.name} ${brightness.name}: each variant shows a '
          'line button\'s top and bottom beside it', (tester) async {
        final faults = <String>[];
        for (final width in const [390.0, 1440.0]) {
          for (final density in RetroDesktopDensity.values) {
            for (final MapEntry(key: name, value: build) in _variants.entries) {
              tester.view.physicalSize = Size(width * _ratio, 300 * _ratio);
              tester.view.devicePixelRatio = _ratio;
              addTearDown(tester.view.reset);
              await tester.pumpWidget(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  builder: (context, page) => RetroDesktopTheme(
                    data: RetroDesktopThemeData.preset('classic', brightness)
                        .copyWith(appearance: appearance)
                        .atWidth(MediaQuery.sizeOf(context).width)
                        .copyWith(density: density),
                    child: page!,
                  ),
                  home: RepaintBoundary(
                    key: _boundary,
                    child: Builder(
                      builder: (context) => ColoredBox(
                        color: RetroDesktopTheme.of(context).colors.platinum,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                KeyedSubtree(
                                  key: _reference,
                                  child: RetroDesktopButton(
                                    'Cancel',
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                KeyedSubtree(key: _variant, child: build()),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pump();
              final shot = await tester.runAsync(() async {
                final box =
                    _boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final image = await box.toImage(pixelRatio: _ratio);
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.rawRgba,
                );
                final w = image.width;
                image.dispose();
                return (w, data!.buffer.asUint8List());
              });
              final (w, px) = shot!;
              int at(int x, int y) {
                final i = (y * w + x) * 4;
                return (px[i] << 16) | (px[i + 1] << 8) | px[i + 2];
              }

              final ground = at(4, 4);
              bool ink(int c) =>
                  ((c >> 16) - (ground >> 16)).abs() > 16 ||
                  (((c >> 8) & 255) - ((ground >> 8) & 255)).abs() > 16 ||
                  ((c & 255) - (ground & 255)).abs() > 16;
              // The outline's top and bottom rows, scanning a column a third
              // of the way in, from the control's reach box inward.
              (int, int)? outline(Key key) {
                final r = tester.getRect(find.byKey(key));
                final x = ((r.left + r.width / 3) * _ratio).round();
                final y0 = (r.top * _ratio).floor(),
                    y1 = (r.bottom * _ratio).ceil() - 1;
                var top = y0, bottom = y1;
                while (top <= y1 && !ink(at(x, top))) {
                  top++;
                }
                while (bottom >= y0 && !ink(at(x, bottom))) {
                  bottom--;
                }
                return top > bottom ? null : (top, bottom);
              }

              final a = outline(_reference), b = outline(_variant);
              final where =
                  '$width ${density.name}: $name beside a line button';
              if (a == null || b == null) {
                faults.add('$where: no outline found');
                continue;
              }
              if ((a.$1 - b.$1).abs() > 1 || (a.$2 - b.$2).abs() > 1) {
                faults.add(
                  '$where: its outline runs ${b.$1 / _ratio}..'
                  '${(b.$2 + 1) / _ratio}, the line button\'s '
                  '${a.$1 / _ratio}..${(a.$2 + 1) / _ratio}',
                );
              }
            }
          }
        }
        debugPrint(
          'ROWS ${appearance.name} ${brightness.name}: ${faults.length}',
        );
        expect(faults, isEmpty, reason: faults.join('\n'));
      }, tags: const ['goldens']);
    }
  }
}
