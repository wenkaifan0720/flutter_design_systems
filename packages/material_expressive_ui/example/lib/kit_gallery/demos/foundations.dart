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
  sections: <Widget>[const _Theme(), const _Format(), const _Metrics()],
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
