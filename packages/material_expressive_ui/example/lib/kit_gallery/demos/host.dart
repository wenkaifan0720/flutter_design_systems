/// The host group's demo: the host every page stands on — the theme in
/// force, its ground, its text and icon defaults, the platform its
/// behaviour follows and the text scale it passes through unclamped — and
/// a subtree that mounts its own [ExpressiveHost] in the other brightness.
library;

import 'package:flutter/material.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../kit.dart';

/// The host group's demo, in [brightness].
Widget kitHostDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Host',
  sections: <Widget>[const _Page(), _NestedHost(brightness)],
);

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final platform = Theme.of(context).platform;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return kitSection(
      'The page',
      children: <Widget>[
        const Row(
          children: <Widget>[
            ExpressiveIcon(ExpressiveSymbols.palette),
            SizedBox(width: ExpressiveSpacing.s8),
            Expanded(child: Text('Body text and icons in the content colour.')),
          ],
        ),
        Text('Theme: ${t.id} · ${t.brightness.name}'),
        Text('Behaviour follows: ${platform.name}'),
        Text('Text scale: ${scale.toStringAsFixed(1)}× (never clamped)'),
        Text(
          'On Android the system bars are drawn edge to edge, transparent '
          'over the ground.',
          style: TextStyle(color: t.colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// A subtree that mounts its own host in the opposite brightness.
class _NestedHost extends StatelessWidget {
  const _NestedHost(this.brightness);

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final other = brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    return kitSection(
      'A nested host',
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(ExpressiveSpacing.s16),
          child: ExpressiveHost(
            light: kitTheme(Brightness.light),
            dark: kitTheme(Brightness.dark),
            brightness: other,
            child: Padding(
              padding: const EdgeInsets.all(ExpressiveChromeMetrics.margin),
              child: Text('The ${other.name} theme, mounted inline.'),
            ),
          ),
        ),
      ],
    );
  }
}
