/// The chevron Gloss's openers share, and the pearl dial bead a field that
/// opens a list ends in.
library;

import 'package:flutter/widgets.dart';

import '../surface.dart';
import '../theme.dart';

/// The chevron of a field or key that opens a list: it turns over as the
/// list opens.
class GlossChevron extends StatelessWidget {
  /// A chevron in [color], turned over while [open].
  const GlossChevron({super.key, required this.open, required this.color});

  /// Whether its list is open.
  final bool open;

  /// Its ink.
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: open ? 0.5 : 0),
    duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? Duration.zero
        : const Duration(milliseconds: 180),
    curve: Curves.easeOutBack,
    builder: (context, turns, _) => Transform.rotate(
      angle: turns * 6.283185307179586,
      child: CustomPaint(
        size: const Size(10, 6),
        painter: _ChevronPainter(color),
      ),
    ),
  );
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0.5, 0.5)
        ..lineTo(size.width / 2, size.height - 0.5)
        ..lineTo(size.width - 0.5, 0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

/// The ink of a chevron on a pearl bead in [c]: supporting grey by day; by
/// night the pearl's own ink, as the grey melts into the slate bead.
Color glossBeadInk(GlossColors c) =>
    c.brightness == Brightness.dark ? c.ink : c.inkSecondary;

/// The choices on a porcelain panel rounded 16; a lit row is a plate
/// inset 4 px, its corners 12, concentric with the panel's.

/// The pearl dial bead a field that opens a list ends in (a select, a
/// combobox): a knob [size] across holding a [GlossChevron], sunk while
/// [pressed] or [open]. Disabled, it lies flat and dull: nothing to press.
class GlossDialBead extends StatelessWidget {
  /// A bead [size] across.
  const GlossDialBead({
    super.key,
    required this.size,
    required this.enabled,
    required this.open,
    this.pressed = false,
  });

  /// Its width and height.
  final double size;

  /// Whether its field takes input.
  final bool enabled;

  /// Whether its list is open.
  final bool open;

  /// Whether its field is held down.
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    return SizedBox.square(
      dimension: size,
      child: AnimatedGlossSurface(
        face: enabled
            ? GlossFace.pearl(c).copyWith(travel: pressed || open ? 1 : 0)
            : GlossFace.pearl(c).copyWith(
                lens: 0,
                lift: 0,
                glow: const Color(0x00000000),
                foreground: c.inkDisabled,
              ),
        child: Center(
          child: GlossChevron(
            open: open,
            color: enabled ? glossBeadInk(c) : c.inkDisabled,
          ),
        ),
      ),
    );
  }
}
