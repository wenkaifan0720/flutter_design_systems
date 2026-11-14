/// The elevation group's demo: the six levels as shadows on the
/// surface-container ground, tonal elevation on the surface role, and a
/// nested surface adding its tone to its parent's.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The elevation group's demo, in [brightness].
Widget kitElevationDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Elevation',
  sections: const <Widget>[_Shadows(), _Tonal(), _Nested()],
);

Widget _tile(
  BuildContext context,
  ExpressiveElevationLevel level, {
  required Color color,
  bool tonal = false,
}) {
  final t = context.expressiveTheme;
  // At least 72dp square, growing with large text. A tonal tile wears a
  // hairline so level 0 (the surface itself) still shows as a tile.
  return ConstrainedBox(
    constraints: const BoxConstraints(
      minWidth: ExpressiveSpacing.s72,
      minHeight: ExpressiveSpacing.s72,
    ),
    child: ExpressiveSurface(
      shape: t.shapes.medium,
      color: color,
      contentColor: t.colors.onSurface,
      side: tonal
          ? BorderSide(color: t.colors.outlineVariant)
          : BorderSide.none,
      shadowElevation: tonal ? ExpressiveElevationLevel.level0 : level,
      tonalElevation: tonal ? level : ExpressiveElevationLevel.level0,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.all(ExpressiveSpacing.s8),
      child: Center(
        child: Text(
          '${level.name.replaceFirst('level', 'Level ')}\n'
          '${ExpressiveElevation.dpOf(level).round()} dp',
          textAlign: TextAlign.center,
          style: t.type.labelSmall,
        ),
      ),
    ),
  );
}

class _Shadows extends StatelessWidget {
  const _Shadows();

  @override
  Widget build(BuildContext context) {
    final c = context.expressiveTheme.colors;
    return kitSection(
      'Shadow elevation',
      children: <Widget>[
        Wrap(
          spacing: ExpressiveSpacing.s16,
          runSpacing: ExpressiveSpacing.s16,
          children: <Widget>[
            for (final level in ExpressiveElevationLevel.values)
              _tile(context, level, color: c.surfaceContainerLow),
          ],
        ),
      ],
    );
  }
}

class _Tonal extends StatelessWidget {
  const _Tonal();

  @override
  Widget build(BuildContext context) {
    final c = context.expressiveTheme.colors;
    return kitSection(
      'Tonal elevation (the surface role, tinted)',
      children: <Widget>[
        Wrap(
          spacing: ExpressiveSpacing.s16,
          runSpacing: ExpressiveSpacing.s16,
          children: <Widget>[
            for (final level in ExpressiveElevationLevel.values)
              _tile(context, level, color: c.surface, tonal: true),
          ],
        ),
      ],
    );
  }
}

class _Nested extends StatelessWidget {
  const _Nested();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Nested surfaces add their tone',
      children: <Widget>[
        ExpressiveSurface(
          shape: t.shapes.large,
          color: t.colors.surface,
          contentColor: t.colors.onSurface,
          tonalElevation: ExpressiveElevationLevel.level1,
          child: Padding(
            padding: const EdgeInsets.all(ExpressiveSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text('Level 1'),
                const SizedBox(height: ExpressiveSpacing.s8),
                ExpressiveSurface(
                  shape: t.shapes.medium,
                  color: t.colors.surface,
                  tonalElevation: ExpressiveElevationLevel.level2,
                  child: const Padding(
                    padding: EdgeInsets.all(ExpressiveSpacing.s16),
                    child: Text('Level 1 + level 2: 4 dp of tone'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
