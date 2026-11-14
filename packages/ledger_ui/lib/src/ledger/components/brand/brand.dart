import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/hatch.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// The brand mark: a ruled globe, its lower half engraved in 45° hatching,
/// drawn in the green as the source's `brand_mark` draws it on its 24 grid
/// (the ring 10.6 round at 1.3, the rule across at 1.3, the hatch 2.3 apart
/// at .8 inside 8.6, under the rule). Scales with [size]; [color] inks it
/// otherwise (a card's face prints it in its own green).
///
/// ```dart
/// LedgerBrandMark()
/// ```
class LedgerBrandMark extends StatelessWidget {
  /// The brand mark, [size] across.
  const LedgerBrandMark({
    this.size = LedgerChromeMetrics.brandMark,
    this.color,
    super.key,
  });

  /// Its width and height.
  final double size;

  /// Its ink; null is the green.
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _BrandMarkPainter(color ?? context.ledgerTheme.accent),
    ),
  );
}

class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter(this.color);

  final Color color;

  /// The hatch, once: the same walk on the same grid every time.
  static final Path _hatch = ledgerHatch(
    (x, y) =>
        (x - 12) * (x - 12) + (y - 12) * (y - 12) <= 8.6 * 8.6 && y >= 12.9,
    2,
    12,
    22,
    22,
    2.3,
    step: 0.05,
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = 1.3;
    canvas.drawCircle(const Offset(12, 12), 10.6, stroke);
    canvas.drawLine(const Offset(1.4, 12), const Offset(22.6, 12), stroke);
    canvas.drawPath(_hatch, stroke..strokeWidth = 0.8);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) => old.color != color;
}

/// How large a [LedgerWordmark] stands: [regular] the phone's top bar's
/// (its name at 28), [large] the side bar's (30).
enum LedgerWordmarkSize {
  /// The phone's top bar's: its name at 28.
  regular,

  /// The side bar's: its name at 30.
  large,
}

/// The wordmark: the brand mark and the app's name in the serif, 10 apart,
/// as the phone's top bar and the sidebar head the app (the sidebar's word
/// at 30, inset 8). Says "[name], home"; [onTap] goes home.
///
/// ```dart
/// LedgerWordmark('Keel')
/// ```
///
/// ```dart
/// LedgerWordmark('Keel', size: LedgerWordmarkSize.large)
/// ```
class LedgerWordmark extends StatelessWidget {
  /// The wordmark of [name].
  const LedgerWordmark(
    this.name, {
    this.onTap,
    this.size = LedgerWordmarkSize.regular,
    super.key,
  });

  /// The app's name.
  final String name;

  /// Goes to the first tab; null draws the mark alone, unpressable.
  final VoidCallback? onTap;

  /// How large it stands.
  final LedgerWordmarkSize size;

  /// The app's name as its `Title` (MaterialApp.title) gives it, or null.
  static String? nameOf(BuildContext context) {
    final title = context.findAncestorWidgetOfExactType<Title>()?.title;
    return title == null || title.isEmpty ? null : title;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final style = size == LedgerWordmarkSize.large
        ? t.wordmark.sized(LedgerChromeMetrics.wordmarkWide)
        : t.wordmark;
    // A logo: the name keeps its size with a large text, as the mark beside
    // it does, and stands in its bar (it is spoken whole).
    final mark = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: LedgerChromeMetrics.brandGap,
      children: [
        const LedgerBrandMark(),
        Text(
          name,
          maxLines: 1,
          softWrap: false,
          textScaler: TextScaler.noScaling,
          style: style,
        ),
      ],
    );
    return LedgerPressable(
      onTap: onTap,
      label: '$name, home',
      role: LedgerPressRole.link,
      child: mark,
    );
  }
}
