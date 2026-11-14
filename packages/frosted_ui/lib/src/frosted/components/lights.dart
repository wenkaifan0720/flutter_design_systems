import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../theme.dart';

/// The light behind the glass, as the source lays it over the top of every
/// page (`.aurora`): three washes of colour, each a disc blurred to a soft
/// glow, lilac at the left, rose over the middle and peach lower at the
/// right, in a field 560 tall on a phone and 640 on the desktop, running
/// on under the sidebar's glass. It is decoration: it takes no taps and says
/// nothing. `FrostedScaffold` places one on every page.
///
/// ```dart
/// FrostedLightField()
/// ```
class FrostedLightField extends StatelessWidget {
  /// Creates a [FrostedLightField].
  const FrostedLightField({this.top = 0, super.key});

  /// Room above the field's own top that its washes run on into: the
  /// status bar over a page, which the source's browser page has none of.
  final double top;

  /// The field's height on a phone or the desktop, over [top].
  static double heightIn(BuildContext context, {double top = 0}) =>
      top +
      (FrostedBreakpoints.isWide(context)
          ? FrostedChromeMetrics.lightFieldWide
          : FrostedChromeMetrics.lightField);

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.fromHeight(heightIn(context, top: top)),
            painter: FrostedLightPainter(
              lights: t.lights,
              wide: wide,
              top: top,
              textDirection:
                  Directionality.maybeOf(context) ?? TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
  }
}

/// One wash of the light: its disc's diameter, where it stands (from the
/// field's start, or from its end when [fromEnd]) and its share of the
/// colour.
@immutable
class FrostedLightWash {
  /// Creates a [FrostedLightWash].
  const FrostedLightWash({
    required this.diameter,
    required this.x,
    required this.y,
    required this.opacity,
    this.fromEnd = false,
  });

  /// How wide the disc of light is.
  final double diameter;

  /// Its centre across the field, from the start (from the end with
  /// [fromEnd]); right to left, the start is the right.
  final double x;

  /// Its centre down the field, from its top.
  final double y;

  /// How strong it is.
  final double opacity;

  /// Whether [x] counts from the end.
  final bool fromEnd;
}

/// Paints the three washes: the phone's (`.b1` 260 at -90, 60; `.b2` 240
/// at 170, -40; `.b3` 200 at 250 down, 20 past the right edge; blurred 56)
/// or the desktop's (480 at 250, 140; 400 at 700, 40; 360 at 120 down, 40
/// in from the right; blurred 72), each kept to the field. The field's
/// last quarter fades out, so a glow that runs past its foot (the
/// desktop's lilac does) ends softly rather than at a line.
class FrostedLightPainter extends CustomPainter {
  /// Creates a [FrostedLightPainter].
  const FrostedLightPainter({
    required this.lights,
    required this.wide,
    this.top = 0,
    this.textDirection = TextDirection.ltr,
  });

  /// The washes' colours.
  final FrostedLights lights;

  /// Whether the field is the desktop's.
  final bool wide;

  /// How far down the field starts.
  final double top;

  /// The reading direction: right to left, the washes mirror.
  final TextDirection textDirection;

  /// The phone's washes.
  static const List<FrostedLightWash> phone = [
    FrostedLightWash(diameter: 260, x: -90, y: 60, opacity: 0.85),
    FrostedLightWash(diameter: 240, x: 170, y: -40, opacity: 0.78),
    FrostedLightWash(
      diameter: 200,
      x: -20,
      y: 250,
      opacity: 0.75,
      fromEnd: true,
    ),
  ];

  /// The desktop's.
  static const List<FrostedLightWash> desktop = [
    FrostedLightWash(diameter: 480, x: 250, y: 140, opacity: 0.85),
    FrostedLightWash(diameter: 400, x: 700, y: 40, opacity: 0.78),
    FrostedLightWash(
      diameter: 360,
      x: 40,
      y: 120,
      opacity: 0.75,
      fromEnd: true,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final washes = wide ? desktop : phone;
    final colors = [lights.lilac, lights.rose, lights.peach];
    final blur = wide
        ? FrostedChromeMetrics.lightBlurWide
        : FrostedChromeMetrics.lightBlur;
    final field = Offset.zero & size;
    canvas.saveLayer(field, Paint());
    for (final (i, w) in washes.indexed) {
      final fromRight = w.fromEnd != (textDirection == TextDirection.rtl);
      final left = fromRight ? size.width - w.x - w.diameter : w.x;
      final rect = Rect.fromLTWH(left, top + w.y, w.diameter, w.diameter);
      canvas.drawOval(
        rect,
        Paint()
          ..color = colors[i].withValues(
            alpha: colors[i].a * w.opacity * lights.strength,
          )
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blur),
      );
    }
    const keep = Color(0xFFFFFFFF), gone = Color(0x00FFFFFF);
    canvas.drawRect(
      field,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          field.topCenter,
          field.bottomCenter,
          const [keep, keep, gone],
          const [0, 0.75, 1],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(FrostedLightPainter old) =>
      old.lights != lights ||
      old.wide != wide ||
      old.top != top ||
      old.textDirection != textDirection;
}
