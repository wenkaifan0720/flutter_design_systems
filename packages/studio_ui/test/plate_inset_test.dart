import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

const _frame = ValueKey('painted edges');
const _red = Color(0xFFEF0000), _green = Color(0xFF00EF00);
const _ratio = 4;
typedef _Pixel = bool Function(int r, int g, int b);
bool _glass(int r, int g, int b) => r > g + 45 && r > b + 45;
bool _key(int r, int g, int b) => g > r + 45 && g > b + 45;
bool _amber(int r, int g, int b) =>
    r > 140 && g > 60 && r > g + 32 && g > b + 45;
bool _metal(int r, int g, int b) => math.min(r, math.min(g, b)) > 160;

class _Photo {
  const _Photo(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width, height;
  bool has(int x, int y, _Pixel color) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    final i = (y * width + x) * 4;
    return bytes[i + 3] > 200 && color(bytes[i], bytes[i + 1], bytes[i + 2]);
  }

  Rect bounds(_Pixel color, {Rect? area}) {
    var x0 = width, y0 = height, x1 = -1, y1 = -1;
    final crop = area ?? Rect.fromLTWH(0, 0, width / _ratio, height / _ratio);
    for (
      var y = (crop.top * _ratio).floor();
      y < (crop.bottom * _ratio).ceil();
      y++
    ) {
      for (
        var x = (crop.left * _ratio).floor();
        x < (crop.right * _ratio).ceil();
        x++
      ) {
        if (!has(x, y, color)) continue;
        x0 = math.min(x, x0);
        x1 = math.max(x, x1);
        y0 = math.min(y, y0);
        y1 = math.max(y, y1);
      }
    }
    expect(
      x1,
      greaterThanOrEqualTo(x0),
      reason: 'The face must leave visible ink.',
    );
    return Rect.fromLTRB(
      x0 / _ratio,
      y0 / _ratio,
      (x1 + 1) / _ratio,
      (y1 + 1) / _ratio,
    );
  }

  _Photo difference(_Photo before) {
    final mask = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i += 4) {
      if ((bytes[i] - before.bytes[i]).abs() > 12 ||
          (bytes[i + 1] - before.bytes[i + 1]).abs() > 12 ||
          (bytes[i + 2] - before.bytes[i + 2]).abs() > 12) {
        mask[i + 1] = 255;
        mask[i + 3] = 255;
      }
    }
    return _Photo(mask, width, height);
  }

  void corner(_Pixel color, Rect bounds, double radius, {bool right = false}) {
    final x = ((right ? bounds.right : bounds.left) * _ratio).round();
    final y = (bounds.top * _ratio).round();
    var cut = 0;
    while (cut < bounds.shortestSide * _ratio / 2 &&
        !has(right ? x - cut - 1 : x + cut, y + cut, color)) {
      cut++;
    }
    expect(
      cut / _ratio,
      closeTo(radius * (1 - math.sqrt(.5)), 1.1),
      reason: 'Painted upper corner of $bounds at radius $radius',
    );
  }
}

Future<_Photo> _paint(WidgetTester tester, double width, Widget child) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(2 * width, 1688);
  addTearDown(tester.view.reset);
  final theme = StudioThemeData.light();
  final colors = theme.colors.copyWith(
    panel: _red,
    panelLow: _red,
    display: _red,
    displayLow: _red,
    key: _green,
    keyLow: _green,
  );
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => StudioHost(
        brightness: Brightness.light,
        theme: theme.copyWith(colors: colors, textureStrength: 0),
        child: app!,
      ),
      home: Center(
        child: RepaintBoundary(key: _frame, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frame),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _ratio.toDouble());
    try {
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return _Photo(rgba!.buffer.asUint8List(), image.width, image.height);
    } finally {
      image.dispose();
    }
  }))!;
}

void main() {
  setUpAll(studioLoadFonts);
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'tag and banner faces follow their frames at ${width.toInt()}',
      (tester) async {
        final tag = await _paint(
          tester,
          width,
          SizedBox(
            width: 280,
            child: StudioTagInput<String>(
              values: const ['Audio'],
              labelOf: (s) => s,
              onChanged: (_) {},
            ),
          ),
        );
        final field = tag.bounds(_glass), chip = tag.bounds(_key);
        expect(chip.left - field.left, closeTo(4, 1));
        expect(chip.top - field.top, closeTo(4, 1));
        expect(field.bottom - chip.bottom, closeTo(4, 1));
        tag.corner(_glass, field, 9);
        tag.corner(_key, chip, 5);
        final message = await _paint(
          tester,
          width,
          SizedBox(
            width: 300,
            child: StudioBanner(message: 'Saved', onClose: () {}),
          ),
        );
        final banner = message.bounds(_glass), close = message.bounds(_key);
        expect(banner.right - close.right, closeTo(8, 1));
        expect(close.top - banner.top, closeTo(8, 1));
        expect(banner.bottom - close.bottom, closeTo(8, 1));
        message.corner(_glass, banner, 14, right: true);
        message.corner(_key, close, 6, right: true);
      },
    );
    testWidgets(
      'the key, filter and navigation banks have even lips at ${width.toInt()}',
      (tester) async {
        for (final bank in <Widget>[
          StudioKeyRow(
            items: [
              StudioKeyRowItem(label: 'In', onPressed: () {}),
              StudioKeyRowItem(label: 'Out', onPressed: () {}),
            ],
          ),
          StudioSegmentedButton<int>(
            segments: const [
              StudioSegment(value: 0, label: 'All'),
              StudioSegment(value: 1, label: 'New'),
            ],
            value: 0,
            onChanged: (_) {},
            expand: true,
          ),
          StudioNavigationBar(
            destinations: const [
              StudioDestination(
                icon: SizedBox.square(dimension: 18),
                label: 'Home',
              ),
              StudioDestination(
                icon: SizedBox.square(dimension: 18),
                label: 'Library',
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ]) {
          final photo = await _paint(
            tester,
            width,
            SizedBox(width: 280, child: bank),
          );
          final local = bank is StudioNavigationBar
              ? tester
                    .getRect(
                      find
                          .descendant(
                            of: find.byWidget(bank),
                            matching: find.byWidgetPredicate(
                              (w) =>
                                  w is StudioSurface &&
                                  w.face.depth == StudioDepth.sunk,
                            ),
                          )
                          .first,
                    )
                    .shift(-tester.getTopLeft(find.byKey(_frame)))
              : null;
          final outer = photo.bounds(_glass, area: local),
              inner = photo.bounds(
                _key,
                area: Rect.fromLTRB(
                  outer.left,
                  outer.top,
                  outer.left + 70,
                  outer.bottom,
                ),
              );
          expect(inner.left - outer.left, closeTo(4, 1.25));
          expect(inner.top - outer.top, closeTo(4, 1.25));
          expect(outer.bottom - inner.bottom, closeTo(4, 1.25));
          photo.corner(_glass, outer, 10);
          photo.corner(_key, inner, 6);
        }
      },
    );
    testWidgets(
      'a held menu row sinks a slot that follows the list bezel, and tab '
      'lamps sit above the groove at ${width.toInt()}',
      (tester) async {
        // Focus and hover light the row's legend; only a held press sinks
        // its slot into the glass.
        Widget menu(bool held) => SizedBox(
          width: 240,
          child: StudioListBezel(
            child: StudioMenuRow(
              label: 'Settings',
              states: {if (held) WidgetState.pressed},
            ),
          ),
        );
        final idle = await _paint(tester, width, menu(false));
        final active = await _paint(tester, width, menu(true));
        final bezel = idle.bounds(_glass);
        final changed = active.difference(idle), slot = changed.bounds(_key);
        expect(slot.left - bezel.left, closeTo(4, 1.5));
        expect(slot.top - bezel.top, closeTo(4, 1.5));
        expect(bezel.right - slot.right, closeTo(4, 1.5));
        changed.corner(_key, slot, 6);
        final tabs = await _paint(
          tester,
          width,
          StudioTabBar(
            tabs: const ['Chapters', 'People'],
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        );
        final height = tabs.height / _ratio;
        final strip = tabs.bounds(
          (r, g, b) => r > 235 && g > 135 && g < 198 && b < 100,
          area: Rect.fromLTRB(0, height - 7, tabs.width / _ratio, height),
        );
        expect(strip.height, closeTo(3, 0.75));
        expect(height - strip.bottom, closeTo(1, 0.75));
      },
    );
    testWidgets(
      'switch and fader lights terminate inside their slots at ${width.toInt()}',
      (tester) async {
        final toggle = await _paint(
          tester,
          width,
          StudioSwitch(value: false, onChanged: (_) {}),
        );
        final cap = toggle.bounds(_metal);
        expect(cap.width, closeTo(StudioSwitch.capSize.width, 2));
        expect(cap.height, closeTo(StudioSwitch.capSize.height, 2));
        expect(
          cap.left,
          closeTo(
            (toggle.width / _ratio - StudioSwitch.size.width) / 2 +
                StudioSwitch.lip,
            1,
          ),
        );
        expect(
          cap.top,
          closeTo(
            (toggle.height / _ratio - StudioSwitch.size.height) / 2 +
                StudioSwitch.lip,
            1,
          ),
        );
        toggle.corner(_metal, cap, StudioThemeData.light().radiusCap);
        final fader = await _paint(
          tester,
          width,
          SizedBox(
            width: 240,
            child: StudioFader(value: .6, onChanged: (_) {}),
          ),
        );
        final light = fader.bounds(
          _amber,
          area: Rect.fromLTWH(0, 0, 120, fader.height / _ratio),
        );
        expect(
          light.left,
          closeTo(StudioFader.cap.width / 2 - StudioFader.slot / 2 + 1, 1),
        );
        expect(light.height, closeTo(StudioFader.slot - 2, 1));
        fader.corner(_amber, light, StudioFader.slot / 2 - 1);
        final radio = await _paint(
          tester,
          width,
          StudioRadio<int>(value: 1, groupValue: 1, onChanged: (_) {}),
        );
        final face = radio.bounds(_key),
            lamp = radio.bounds(
              _amber,
              area: Rect.fromCenter(center: face.center, width: 14, height: 14),
            );
        expect(lamp.center.dx, closeTo(face.center.dx, 1));
        expect(lamp.center.dy, closeTo(face.center.dy, 2));
      },
    );
  }
}
