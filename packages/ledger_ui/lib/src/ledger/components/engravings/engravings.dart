import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../internal/engraving.dart';
import '../../theme.dart';

/// The guilloche rosette (`art.guilloche`), a banknote's turned ornament
/// on its 400 grid scaled to its box: eighteen waved rings (r 150 ± 24, ten
/// waves) at .45 and twelve inside (r 100 ± 9, sixteen waves) at .4, in
/// [color] (the green by default). Drawn behind a card's face and as a
/// page's watermark; it says nothing to a screen reader.
///
/// ```dart
/// LedgerGuilloche(size: 320)
/// ```
class LedgerGuilloche extends StatelessWidget {
  /// A rosette [size] across, in [color].
  const LedgerGuilloche({this.size = 400, this.color, super.key});

  /// Its width and height.
  final double size;

  /// Its ink; null takes the green.
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _RosettePainter(color ?? context.ledgerTheme.accent),
    ),
  );
}

class _RosettePainter extends CustomPainter {
  _RosettePainter(this.color);

  final Color color;

  static final Path _outer = _rings(18, 360, 150, 24, 10);
  static final Path _inner = _rings(12, 320, 100, 9, 16);

  static Path _rings(int count, int steps, double r0, double amp, int waves) {
    final path = Path();
    for (var k = 0; k < count; k++) {
      final ph = 2 * math.pi * k / count;
      for (var s = 0; s <= steps; s++) {
        final t = 2 * math.pi * s / steps;
        final r = r0 + amp * math.sin(waves * t + ph);
        final x = 200 + r * math.cos(t), y = 200 + r * math.sin(t);
        s == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 400, size.height / 400)
      ..drawPath(_outer, ledgerStroke(color, .45))
      ..drawPath(_inner, ledgerStroke(color, .4))
      ..restore();
  }

  @override
  bool shouldRepaint(_RosettePainter old) => old.color != color;
}

/// A banknote's border (`art.guilloche_band`): ten interlaced sine waves
/// (eighteen across) on a 600 by 14 strip stretched to its width, in
/// [color] at .45: the head of a receipt, a cheque and a form. Says
/// nothing to a screen reader.
///
/// ```dart
/// LedgerGuillocheBand()
/// ```
class LedgerGuillocheBand extends StatelessWidget {
  /// A band [height] tall, in [color].
  const LedgerGuillocheBand({this.height = 14, this.color, super.key});

  /// The band's height.
  final double height;

  /// Its ink; null takes the green.
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BandPainter(color ?? context.ledgerTheme.accent),
      ),
    ),
  );
}

class _BandPainter extends CustomPainter {
  _BandPainter(this.color);

  final Color color;

  static final Path _band = () {
    const w = 600.0, h = 14.0, waves = 18, lines = 10, amp = h * .32;
    final path = Path();
    for (var k = 0; k < lines; k++) {
      final ph = 2 * math.pi * k / lines;
      const steps = w ~/ 2;
      for (var s = 0; s <= steps; s++) {
        final x = w * s / steps;
        final y =
            h / 2 +
            amp *
                math.sin(2 * math.pi * waves * x / w + ph) *
                math.cos(math.pi * x / w + ph / 3);
        s == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
    }
    return path;
  }();

  @override
  void paint(Canvas canvas, Size size) {
    // preserveAspectRatio="none": stretched, its strokes with it.
    canvas
      ..save()
      ..scale(size.width / 600, size.height / 14)
      ..drawPath(_band, ledgerStroke(color, .45))
      ..restore();
  }

  @override
  bool shouldRepaint(_BandPainter old) => old.color != color;
}

/// A card's chip, engraved (`art.chip_art`) on its 40 by 30 grid fitted
/// in its box: the rounded plate, its contact lines and a hatched pad, in
/// [color].
///
/// ```dart
/// LedgerCardChip(width: 42, height: 32, color: Color(0xD1EFE9DD))
/// ```
class LedgerCardChip extends StatelessWidget {
  /// A chip [width] by [height], in [color].
  const LedgerCardChip({
    required this.width,
    required this.height,
    required this.color,
    super.key,
  });

  /// The chip's width.
  final double width;

  /// The chip's height.
  final double height;

  /// Its ink.
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size(width, height), painter: _ChipPainter(color)),
  );
}

class _ChipPainter extends CustomPainter {
  _ChipPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // The SVG's default xMidYMid meet: scaled to fit, centred.
    final k = math.min(size.width / 40, size.height / 30);
    canvas
      ..save()
      ..translate((size.width - 40 * k) / 2, (size.height - 30 * k) / 2)
      ..scale(k)
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(.6, .6, 38.8, 28.8),
          const Radius.circular(5),
        ),
        ledgerStroke(color, 1.1),
      )
      ..drawPath(
        Path()
          ..moveTo(.6, 10.5)
          ..lineTo(12, 10.5)
          ..moveTo(.6, 19.5)
          ..lineTo(12, 19.5)
          ..moveTo(28, 10.5)
          ..lineTo(39.4, 10.5)
          ..moveTo(28, 19.5)
          ..lineTo(39.4, 19.5)
          ..moveTo(12, .6)
          ..lineTo(12, 29.4)
          ..moveTo(28, .6)
          ..lineTo(28, 29.4)
          ..moveTo(12, 15)
          ..lineTo(28, 15),
        ledgerStroke(color, .8),
      )
      ..drawPath(
        ledgerHatchRect(13, 1.5, 27, 14, 2.2),
        ledgerStroke(ledgerInk(color, .7), .45),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_ChipPainter old) => old.color != color;
}

/// A tear line of punched holes (`.perf`): a hole of the darker paper,
/// shaded by the rule's ink, 2.1
/// round (fading out by 2.6) every 9 along a strip 6 tall, the last cut at
/// its end; [vertical] runs it down (`.vperf`). Says nothing.
///
/// ```dart
/// LedgerPerforation()
/// ```
class LedgerPerforation extends StatelessWidget {
  /// A tear line across, or down when [vertical].
  const LedgerPerforation({this.vertical = false, super.key});

  /// Whether the line runs down rather than across.
  final bool vertical;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: vertical ? null : 6,
      width: vertical ? 6 : null,
      child: CustomPaint(
        // The source's holes of the darker paper alone read as nothing on
        // the light paper (1.1:1, by day and by lamplight): each is shaded
        // by the rule's ink as well, so the tear line is seen.
        painter: _PerfPainter(
          Color.alphaBlend(
            context.ledgerTheme.border,
            context.ledgerTheme.surfaceAlt,
          ),
          vertical,
        ),
      ),
    ),
  );
}

class _PerfPainter extends CustomPainter {
  _PerfPainter(this.color, this.vertical);

  final Color color;
  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    final run = vertical ? size.height : size.width;
    canvas
      ..save()
      ..clipRect(Offset.zero & size);
    for (var at = 0.0; at < run; at += 9) {
      final c = vertical ? Offset(3, at + 3) : Offset(at + 3, 3);
      canvas.drawCircle(
        c,
        2.6,
        Paint()
          ..shader = ui.Gradient.radial(
            c,
            2.6,
            [color, color, color.withValues(alpha: 0)],
            const [0, 2.1 / 2.6, 1],
          ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PerfPainter old) =>
      old.color != color || old.vertical != vertical;
}

/// A page's watermark (`.watermark`): the guilloche rosette in the green
/// at .36, fading out down its lower half (a phone's, 360 round), or at.
/// 42 fading out from its middle (the desktop's, 300 round), placed as
/// the source places it over the page's column (top −10, right −150 on a
/// phone; top 156, left 476 from 1024). Stand it as a screen's backdrop
/// (`LedgerScreen(backdrop: const LedgerWatermark())`); it says nothing.
///
/// ```dart
/// LedgerWatermark()
/// ```
class LedgerWatermark extends StatelessWidget {
  /// A page's watermark.
  const LedgerWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final size = wide ? _deskSize : _phoneSize;
    final art = IgnorePointer(
      child: ExcludeSemantics(
        child: Opacity(
          opacity: wide ? _deskOpacity : _phoneOpacity,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (box) => wide
                // radial-gradient(closest-side, #000 62%, transparent).
                ? ui.Gradient.radial(
                    box.center,
                    box.shortestSide / 2,
                    [
                      const Color(0xFF000000),
                      const Color(0xFF000000),
                      const Color(0x00000000),
                    ],
                    const [0, .62, 1],
                  )
                // linear-gradient(180deg, #000 0 38%, transparent 92%).
                : ui.Gradient.linear(
                    box.topCenter,
                    box.bottomCenter,
                    [
                      const Color(0xFF000000),
                      const Color(0xFF000000),
                      const Color(0x00000000),
                    ],
                    const [0, .38, .92],
                  ),
            child: LedgerGuilloche(size: size, color: t.accent),
          ),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        wide
            ? Positioned(top: _deskTop, left: _deskLeft, child: art)
            : Positioned(top: _phoneTop, right: _phoneRight, child: art),
      ],
    );
  }

  static const double _phoneSize = 360;
  static const double _deskSize = 300;
  static const double _phoneOpacity = .36;
  static const double _deskOpacity = .42;
  static const double _phoneTop = -10;
  static const double _phoneRight = -150;
  static const double _deskTop = 156;
  static const double _deskLeft = 476;
}
