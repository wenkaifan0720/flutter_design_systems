// The look's error mark: the warning glyph in the danger ink, raised on a bead of the material. A field that fails
// carries it at its end, and the line under it in its place where the field has none, so the field itself reads as
// failed with no colour of its own: the danger ink is the glyph's and the words', never the material's.
import 'package:flutter/widgets.dart';

import '../frames.dart';
import '../glyphs.dart';
import '../theme.dart';
import 'geometry.dart' show neumorphicFillPaint;
import 'relief.dart';

/// The warning glyph in the danger ink on a bead of the material, [size] across.
class NeumorphicErrorMark extends StatelessWidget {
  /// An error mark [size] across, its glyph [glyphSize].
  const NeumorphicErrorMark({super.key, this.size = 24, this.glyphSize = 14});

  /// The bead's diameter.
  final double size;

  /// The glyph's size on it.
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    // Its own size wherever it stands, a stretching column's too.
    return ExcludeSemantics(
      child: Align(
        alignment: AlignmentDirectional.topStart,
        widthFactor: 1,
        heightFactor: 1,
        child: CustomPaint(
          painter: NeumorphicBeadPainter(
            const CircleBorder(),
            t.colors,
            null,
            0,
            t.relief,
            NeumorphicFlatScope.of(context),
          ),
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: Icon(
                NeumorphicGlyphs.triangleAlert,
                size: glyphSize,
                color: t.colors.danger,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A bead (a badge's, an error's mark): raised off what it sits on, its face the material's (or an app's fill), its lit side and face
/// warmed by the pigment while the count is [fresh].
class NeumorphicBeadPainter extends CustomPainter {
  /// A bead of [border]'s shape in [c]'s material; [fresh] (0 to 1) warms it with the pigment.
  const NeumorphicBeadPainter(
    this.border,
    this.c,
    this.fill,
    this.fresh,
    this.elevation,
    this.flat,
  );

  /// The bead's outline.
  final ShapeBorder border;

  /// The material's colours.
  final NeumorphicColors c;

  /// An app's own face; null is the material's.
  final Color? fill;

  /// How warm the bead stands, from 0 (the material's) to 1 (warmed by the pigment).
  final double fresh;

  /// The theme's depth.
  final NeumorphicReliefDepth elevation;

  /// Whether casts are off (high contrast, a flat scope).
  final bool flat;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final shape = border.getOuterPath(box);
    final warm = Color.lerp(c.highlight, c.pigmentHi, .6 * fresh)!;
    neumorphicPaintRaised(
      canvas,
      shape,
      c,
      light: (const Offset(-1.5, -1.5), 3),
      dark: (const Offset(1.5, 1.5), 4),
      lightColor: warm,
      face: fill == null
          ? LinearGradient(
              begin: c.light,
              end: -c.light,
              colors: [c.faceStart, c.faceEnd],
            ).createShader(box)
          : LinearGradient(colors: [fill!, fill!]).createShader(box),
      flat: flat,
      elevation: elevation,
    );
    if (fresh > 0) {
      canvas.drawPath(
        shape,
        neumorphicFillPaint(c.wash.withValues(alpha: c.wash.a * 2 * fresh)),
      );
    }
  }

  @override
  bool shouldRepaint(NeumorphicBeadPainter old) =>
      old.border != border ||
      old.c != c ||
      old.fill != fill ||
      old.fresh != fresh ||
      old.elevation != elevation ||
      old.flat != flat;
}
