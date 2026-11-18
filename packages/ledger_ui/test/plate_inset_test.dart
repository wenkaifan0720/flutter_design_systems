import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
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
  LedgerThemeData theme,
  Widget control,
) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 844);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) => LedgerTheme(data: theme, child: child!),
      home: Center(
        child: RepaintBoundary(
          key: _frame,
          child: ColoredBox(color: theme.background, child: control),
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
    testWidgets('segmented fill follows the outer corner at $width', (t) async {
      addTearDown(t.view.reset);
      const radius = 12.0;
      const inset = 2.0;
      final theme = LedgerThemeData.light().copyWith(controlRadius: radius);
      for (final current in ['First', 'Last']) {
        final pixels = await _paint(
          t,
          width,
          theme,
          LedgerSegmentedControl<String>(
            options: const ['First', 'Last'],
            value: current,
            onChanged: (_) {},
          ),
        );
        final size = t.getSize(find.byKey(_frame));
        final mirrored = current == 'Last';
        for (final depth in [0.625, 1.625, 3.125, 5.125]) {
          final row = ((inset + depth) * _ratio).floor();
          final scan = Iterable<int>.generate(
            (size.width * _ratio / 2).floor(),
          );
          final first = scan.firstWhere(
            (x) => pixels.matches(
              mirrored ? pixels.width - 1 - x : x,
              row,
              theme.textPrimary,
            ),
          );
          const r = radius - inset;
          final expected =
              inset + r - math.sqrt(r * r - (r - depth) * (r - depth));
          expect(
            (first + .5) / _ratio,
            closeTo(expected, .65),
            reason: '$current at $depth from the rounded edge',
          );
        }
        final x = ((mirrored ? size.width * .75 : size.width * .25) * _ratio)
            .floor();
        final top = Iterable<int>.generate((size.height * _ratio / 2).floor())
            .firstWhere((y) => pixels.matches(x, y, theme.textPrimary));
        final bottom =
            Iterable<int>.generate((size.height * _ratio / 2).floor())
                .firstWhere(
                  (y) => pixels.matches(
                    x,
                    (size.height * _ratio).round() - 1 - y,
                    theme.textPrimary,
                  ),
                );
        expect(top / _ratio, closeTo(inset, .3));
        expect(bottom / _ratio, closeTo(inset, .3));
      }
    });

    testWidgets(
      'the search clear button shares the centre of the field cap at $width',
      (t) async {
        addTearDown(t.view.reset);
        final controller = TextEditingController(text: 'Book');
        addTearDown(controller.dispose);
        final theme = LedgerThemeData.light();
        final pixels = await _paint(
          t,
          width,
          theme,
          SizedBox(
            width: 280,
            child: LedgerSearchField(
              controller: controller,
              onCleared: controller.clear,
            ),
          ),
        );
        final size = t.getSize(find.byKey(_frame));
        final x = ((size.width - size.height / 2) * _ratio).floor();
        final y = (size.height * _ratio / 2).floor();
        final n = (size.height * _ratio).round();
        final sample = Iterable<int>.generate(n ~/ 2);
        final top = sample.firstWhere(
          (depth) => pixels.matches(x, depth, theme.surfaceAlt),
        );
        final bottom = sample.firstWhere(
          (depth) => pixels.matches(x, n - 1 - depth, theme.surfaceAlt),
        );
        final end = sample.firstWhere(
          (depth) =>
              pixels.matches(pixels.width - 1 - depth, y, theme.surfaceAlt),
        );
        expect(end / _ratio, closeTo(top / _ratio, .3));
        expect(bottom / _ratio, closeTo(top / _ratio, .3));
      },
    );

    testWidgets(
      'switch and radio dots share their painted holder centres at $width',
      (t) async {
        addTearDown(t.view.reset);
        final theme = LedgerThemeData.light();
        for (final on in [false, true]) {
          final pixels = await _paint(
            t,
            width,
            theme,
            LedgerSwitch(value: on, onChanged: (_) {}),
          );
          final track = _rectInFrame(
            t,
            find
                .descendant(
                  of: find.byType(LedgerSwitch),
                  matching: find.byType(CustomPaint),
                )
                .last,
          );
          final center = Offset(
            on ? track.right - track.height / 2 : track.left + track.height / 2,
            track.center.dy,
          );
          final ink = on ? theme.surface : theme.textTertiary;
          _expectDot(pixels, center, ink, on ? 8.5 : 6.0);
        }
        final pixels = await _paint(
          t,
          width,
          theme,
          LedgerRadio<int>(value: 1, groupValue: 1, onChanged: (_) {}),
        );
        final outer = find.descendant(
          of: find.byType(LedgerRadio<int>),
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).shape == BoxShape.circle &&
                (w.decoration as BoxDecoration).border != null,
          ),
        );
        _expectDot(
          pixels,
          _rectInFrame(t, outer.first).center,
          theme.textPrimary,
          5.0,
        );
      },
    );
  }
}

void _expectDot(_Pixels pixels, Offset center, Color ink, double radius) {
  final cx = (center.dx * _ratio).floor();
  final cy = (center.dy * _ratio).floor();
  final reach = ((radius + 2) * _ratio).ceil();
  final offsets = List<int>.generate(reach * 2, (i) => i - reach);
  final alongX = offsets
      .where((offset) => pixels.matches(cx + offset, cy, ink))
      .toList();
  final alongY = offsets
      .where((offset) => pixels.matches(cx, cy + offset, ink))
      .toList();
  for (final span in [alongX, alongY]) {
    expect((span.first + span.last + 1) / (2 * _ratio), closeTo(0, .3));
    expect((span.last - span.first + 1) / (2 * _ratio), closeTo(radius, .4));
  }
}
