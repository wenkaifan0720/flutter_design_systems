import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _ratio = 4.0;
const _frame = ValueKey('measured control');

class _Pixels {
  _Pixels(this.bytes, this.width);
  final ByteData bytes;
  final int width;

  bool matches(int x, int y, Color ink) {
    final offset = 4 * (y * width + x);
    final color = ink.toARGB32();
    return (bytes.getUint8(offset) - (color >> 16 & 255)).abs() <= 5 &&
        (bytes.getUint8(offset + 1) - (color >> 8 & 255)).abs() <= 5 &&
        (bytes.getUint8(offset + 2) - (color & 255)).abs() <= 5;
  }
}

Future<_Pixels> _paint(
  WidgetTester t,
  double width,
  BrutalThemeData theme,
  Widget control,
) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 844);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) => BrutalTheme(data: theme, child: child!),
      home: Center(
        child: RepaintBoundary(
          key: _frame,
          child: ColoredBox(color: theme.colors.paper, child: control),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(_frame));
  final pixels = await t.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _ratio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return _Pixels(data!, image.width);
    } finally {
      image.dispose();
    }
  });
  return pixels!;
}

Rect _rectInFrame(WidgetTester t, Finder f) =>
    t.getRect(f).shift(-t.getTopLeft(find.byKey(_frame)));

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('radio ring and dot share their painted centre at $width', (
      t,
    ) async {
      addTearDown(t.view.reset);
      final theme = BrutalThemeData.light();
      final pixels = await _paint(
        t,
        width,
        theme,
        BrutalRadio<int>(value: 1, groupValue: 1, onChanged: (_) {}),
      );
      final ring = _rectInFrame(
        t,
        find
            .descendant(
              of: find.byType(BrutalRadio<int>),
              matching: find.byType(CustomPaint),
            )
            .last,
      );
      final center = ring.center;
      for (final axis in Axis.values) {
        bool inkAt(double offset) {
          final point =
              center +
              (axis == Axis.horizontal ? Offset(offset, 0) : Offset(0, offset));
          return pixels.matches(
            (point.dx * _ratio).floor(),
            (point.dy * _ratio).floor(),
            theme.colors.ink,
          );
        }

        for (final side in [-1.0, 1.0]) {
          expect(inkAt(side * 5.6), isTrue);
          expect(inkAt(side * 6.4), isFalse);
          expect(inkAt(side * 9.6), isFalse);
          expect(inkAt(side * 10.4), isTrue);
          expect(inkAt(side * 11.6), isTrue);
          expect(inkAt(side * 12.4), isFalse);
        }
      }
    });

    testWidgets('switch keeps an even square inset at $width', (t) async {
      addTearDown(t.view.reset);
      final theme = BrutalThemeData.light();
      for (final on in [false, true]) {
        final pixels = await _paint(
          t,
          width,
          theme,
          BrutalSwitch(value: on, onChanged: (_) {}),
        );
        final track = _rectInFrame(
          t,
          find
              .descendant(
                of: find.byType(BrutalSwitch),
                matching: find.byType(CustomPaint),
              )
              .first,
        );
        final ink = on ? theme.colors.paper : theme.colors.ink;
        final front = on ? track.right : track.left;
        final sign = on ? -1 : 1;
        bool inThumb(double dx, double dy) => pixels.matches(
          ((front + sign * dx) * _ratio).floor(),
          ((track.top + dy) * _ratio).floor(),
          ink,
        );
        for (final dy in [4.3, 14.0, 23.7]) {
          expect(inThumb(3.6, dy), isFalse);
          expect(inThumb(4.4, dy), isTrue);
        }
        expect(inThumb(8.0, 3.6), isFalse);
        expect(inThumb(8.0, 24.4), isFalse);
      }
    });
  }
}
