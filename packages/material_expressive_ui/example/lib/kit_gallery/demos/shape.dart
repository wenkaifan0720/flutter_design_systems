/// The shape group's demo: the corner scale step by step, the inner-corner
/// variants, the 35 library shapes as image masks, and a morph (the
/// LoadingIndicator's first pair) at five points of its progress.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The shape group's demo, in [brightness].
Widget kitShapeDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Shape',
  sections: const <Widget>[_Scale(), _Inner(), _Library(), _Morph()],
);

/// One swatch: [child] over [label], [width] wide (as wide as [child], or
/// it squeezes a wider tile: the corner scale's 112dp tiles stood 72dp
/// wide, so extraExtraLarge rounded as full, 11-13).
///
/// A token's name breaks only between its words (`extraLarge` over
/// `Increased`): set as one word it broke wherever the width ran out
/// ("extraSma ll", 11-09).
Widget _swatch(
  BuildContext context,
  String label,
  Widget child, {
  double width = ExpressiveSpacing.s72,
}) {
  final t = context.expressiveTheme;
  final style = t.type.labelMedium.copyWith(color: t.colors.onSurfaceVariant);
  return SizedBox(
    width: width,
    child: Column(
      children: <Widget>[
        child,
        const SizedBox(height: ExpressiveSpacing.s4),
        Semantics(
          label: label,
          excludeSemantics: true,
          // One paragraph, breakable only where a word starts (a zero-width
          // space there), and set left to right in either direction: as a
          // Wrap of words its halves swapped in RTL ("Smallextra", 11-13).
          child: Text(
            label.replaceAll(_wordBreak, '\u200B'),
            style: style,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    ),
  );
}

/// Where a camelCase name's next word starts: `cookie4|Sided`.
final RegExp _wordBreak = RegExp('(?<=[a-z0-9])(?=[A-Z])');

/// A tile in [shape], [dimension] square: the corner scale's tiles are 112dp,
/// wide enough that its 28, 32 and 48dp steps and full each round
/// differently.
Widget _filled(
  BuildContext context,
  ShapeBorder shape, {
  double dimension = ExpressiveSpacing.s64,
}) => SizedBox.square(
  dimension: dimension,
  child: DecoratedBox(
    decoration: ShapeDecoration(
      color: context.expressiveTheme.colors.primaryContainer,
      shape: shape,
    ),
  ),
);

/// The corner scale's tile: 112dp, so 28, 32 and 48dp and full differ.
const double _scaleTile = ExpressiveSpacing.s72 + ExpressiveSpacing.s40;

class _Scale extends StatelessWidget {
  const _Scale();

  @override
  Widget build(BuildContext context) {
    final shapes = context.expressiveTheme.shapes;
    return kitSection(
      'Corner scale',
      children: <Widget>[
        Wrap(
          spacing: kitGap,
          runSpacing: kitGap,
          children: <Widget>[
            for (final corner in ExpressiveCorner.values)
              _swatch(
                context,
                corner.name,
                width: _scaleTile,
                _filled(context, shapes.corner(corner), dimension: _scaleTile),
              ),
          ],
        ),
      ],
    );
  }
}

class _Inner extends StatelessWidget {
  const _Inner();

  @override
  Widget build(BuildContext context) {
    final large = context.expressiveTheme.shapes.large;
    return kitSection(
      'Inner corners (large)',
      children: <Widget>[
        Wrap(
          spacing: kitGap,
          runSpacing: kitGap,
          children: <Widget>[
            _swatch(context, 'top', _filled(context, large.top())),
            _swatch(context, 'bottom', _filled(context, large.bottom())),
            _swatch(context, 'start', _filled(context, large.start())),
            _swatch(context, 'end', _filled(context, large.end())),
          ],
        ),
      ],
    );
  }
}

class _Library extends StatelessWidget {
  const _Library();

  @override
  Widget build(BuildContext context) {
    final c = context.expressiveTheme.colors;
    return kitSection(
      'Library shapes (image masks)',
      children: <Widget>[
        Wrap(
          spacing: kitGap,
          runSpacing: kitGap,
          children: <Widget>[
            for (final shape in ExpressiveMaterialShape.values)
              _swatch(
                context,
                shape.name,
                SizedBox.square(
                  dimension: ExpressiveSpacing.s64,
                  child: ClipPath(
                    clipper: ShapeBorderClipper(
                      shape: ExpressiveMaterialShapeBorder(shape),
                    ),
                    // Flat tone, as every surface of the look.
                    child: ColoredBox(color: c.primary),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Morph extends StatelessWidget {
  const _Morph();

  static const List<double> _stops = <double>[0, 0.25, 0.5, 0.75, 1];

  @override
  Widget build(BuildContext context) {
    final morph = ExpressiveMorph.between(
      ExpressiveMaterialShape.softBurst,
      ExpressiveMaterialShape.cookie9Sided,
    );
    return kitSection(
      'Morph: softBurst to cookie9Sided',
      children: <Widget>[
        Wrap(
          spacing: kitGap,
          runSpacing: kitGap,
          children: <Widget>[
            for (final progress in _stops)
              _swatch(
                context,
                _progressLabel(progress),
                SizedBox.square(
                  dimension: ExpressiveSpacing.s64,
                  child: CustomPaint(
                    painter: _MorphPainter(
                      morph,
                      progress,
                      context.expressiveTheme.colors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MorphPainter extends CustomPainter {
  _MorphPainter(this.morph, this.progress, this.color);

  final ExpressiveMorph morph;
  final double progress;
  final Color color;
  final Path _path = Path();

  @override
  void paint(Canvas canvas, Size size) {
    morph.writePath(_path, progress, size);
    canvas.drawPath(_path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MorphPainter old) =>
      old.morph != morph || old.progress != progress || old.color != color;
}

/// A morph stop as a label: `0`, `0.25`, `1` (not `0.0` / `1.0`).
String _progressLabel(double progress) =>
    progress == progress.roundToDouble() ? '${progress.round()}' : '$progress';
