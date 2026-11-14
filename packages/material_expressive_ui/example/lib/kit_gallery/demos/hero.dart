/// The hero group's demo: one hero moment — the scope every opt-in hero
/// widget asserts above it (CONTRACT §3) — and the budget it spends: the
/// theme's expression and the page's count.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The hero group's demo, in [brightness].
Widget kitHeroDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Hero',
  sections: const <Widget>[_Moment(), _Budget()],
);

class _Moment extends StatelessWidget {
  const _Moment();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    return kitSection(
      'One hero moment',
      children: <Widget>[
        ExpressiveHeroMoment(
          label: 'featured trip',
          child: ExpressiveSurface(
            shape: t.shapes.extraExtraLarge,
            color: c.tertiaryContainer,
            contentColor: c.onTertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(ExpressiveSpacing.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Weekend away', style: t.type.labelLarge),
                  const SizedBox(height: ExpressiveSpacing.s8),
                  Text(
                    'Three days by the sea',
                    style: t.type.headlineMediumEmphasized,
                  ),
                  const SizedBox(height: ExpressiveSpacing.s8),
                  Text('Leaves Friday 07:30', style: t.type.bodyLarge),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Budget extends StatelessWidget {
  const _Budget();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final allowed = switch (t.expression) {
      ExpressiveExpression.calm => 'none',
      ExpressiveExpression.balanced => 'one',
      ExpressiveExpression.bold => 'two',
    };
    return kitSection(
      'The budget',
      children: <Widget>[
        Text(
          'This theme is ${t.expression.name}: $allowed per app, at most one '
          'per page.',
        ),
        Text(
          'L and XL buttons, shaped images, emphasized display type, vibrant '
          'menus, wavy progress and the FAB menu each ask for a hero moment '
          'above them.',
          style: TextStyle(color: t.colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
