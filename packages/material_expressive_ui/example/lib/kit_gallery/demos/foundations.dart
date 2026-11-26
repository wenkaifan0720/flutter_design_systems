/// The foundations group's demo: the theme in force (its record and what
/// each foundation holds), the themes the system offers, the formatters
/// and the chrome metrics. Each foundation has its own group and demo
/// (color, type, shape, motion, spacing, icons, elevation, states).
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../kit.dart';

/// The foundations group's demo, in [brightness].
Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Foundations',
  sections: <Widget>[
    const _Theme(),
    const _Palettes(),
    const _Format(),
    const _Metrics(),
  ],
);

class _Theme extends StatelessWidget {
  const _Theme();

  @override
  Widget build(BuildContext context) {
    final ExpressiveThemeData t = context.expressiveTheme;
    return kitSection(
      'Theme',
      children: <Widget>[
        Text('${t.id} · ${t.brightness.name}'),
        Text('Expression: ${t.expression.name}'),
        Text('Themes: ${ExpressiveThemeData.presets.join(', ')}'),
        Text('Motion: ${t.motion.scheme.name} springs'),
        Text('Corners: ${ExpressiveCorner.values.length} steps'),
        Text(
          'State layers: hover ${t.states.hoverOpacity} · focus '
          '${t.states.focusOpacity} · pressed ${t.states.pressedOpacity} · '
          'dragged ${t.states.draggedOpacity}',
        ),
        Text(
          'Elevation: ${ExpressiveElevationLevel.values.map(ExpressiveElevation.dpOf).join(' · ')} dp',
        ),
      ],
    );
  }
}

// Each of Expressive's six presets at the page's brightness: a tile of its
// container holding its primary, secondary and tertiary and its filled
// button, named under it.
class _Palettes extends StatelessWidget {
  const _Palettes();

  @override
  Widget build(BuildContext context) {
    final page = context.expressiveTheme;
    return kitSection(
      'Palettes',
      children: <Widget>[
        LayoutBuilder(
          builder: (context, box) {
            // Six, three or two across, so the rows come out even.
            const gap = ExpressiveSpacing.s8;
            final across = box.maxWidth >= 6 * 150 + 5 * gap
                ? 6
                : box.maxWidth >= 3 * 150 + 2 * gap
                ? 3
                : 2;
            final width = ((box.maxWidth - (across - 1) * gap) / across)
                .floorToDouble();
            return Wrap(
              spacing: gap,
              runSpacing: ExpressiveSpacing.s16,
              children: <Widget>[
                for (final id in ExpressiveThemeData.presets)
                  SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ExpressiveTheme(
                          data: ExpressiveThemeData.preset(id, page.brightness),
                          child: const _PaletteTile(),
                        ),
                        const SizedBox(height: ExpressiveSpacing.s4),
                        Text(
                          id[0].toUpperCase() + id.substring(1),
                          style: page.type.bodySmall.copyWith(
                            color: page.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile();

  @override
  Widget build(BuildContext context) {
    final c = context.expressiveTheme.colors;
    Widget dot(Color color) => Padding(
      padding: const EdgeInsetsDirectional.only(end: ExpressiveSpacing.s4),
      child: SizedBox.square(
        dimension: 16,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ExpressiveSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                dot(c.primary),
                dot(c.secondary),
                dot(c.tertiary),
              ],
            ),
            const SizedBox(height: ExpressiveSpacing.s12),
            ExpressiveFilledButton('Save', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

class _Format extends StatelessWidget {
  const _Format();

  @override
  Widget build(BuildContext context) {
    final day = DateTime(2026, 9, 26, 7, 30);
    return kitSection(
      'Format',
      children: <Widget>[
        Text('Money: ${ExpressiveFormat.money(128450)}'),
        Text('Count: ${ExpressiveFormat.count(1240)}'),
        Text('Date: ${ExpressiveFormat.date(day)}'),
        Text('Time: ${ExpressiveFormat.time(context, day)}'),
      ],
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics();

  @override
  Widget build(BuildContext context) => kitSection(
    'Chrome metrics',
    children: const <Widget>[
      Text('Navigation bar: ${ExpressiveChromeMetrics.navBarHeight}'),
      Text('Floating action button: ${ExpressiveChromeMetrics.fabSize}'),
      Text('Sheet corner: ${ExpressiveChromeMetrics.sheetCornerRadius}'),
      Text('Margin: ${ExpressiveChromeMetrics.margin}'),
    ],
  );
}
