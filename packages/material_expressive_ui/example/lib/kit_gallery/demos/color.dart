/// The colour group's demo: every colour role of the theme in force, each
/// drawn as a tile in its role with its name set in the role Material pairs
/// with it, grouped the way Material's role families are.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The colour group's demo, in [brightness].
Widget kitColorDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Colour',
  sections: const <Widget>[
    _Family('Accents', _accents),
    _Family('Surfaces', _surfaces),
    _Family('Fixed accents', _fixed),
    _Family('Inverse, outlines and scrim', _utility),
  ],
);

/// A tile: [role] filled, its name set in [on]; with no [on], [role] as its edge.
typedef _Tile = (ExpressiveColorRole role, ExpressiveColorRole? on);

const List<_Tile> _accents = <_Tile>[
  (ExpressiveColorRole.primary, ExpressiveColorRole.onPrimary),
  (ExpressiveColorRole.onPrimary, ExpressiveColorRole.primary),
  (
    ExpressiveColorRole.primaryContainer,
    ExpressiveColorRole.onPrimaryContainer,
  ),
  (
    ExpressiveColorRole.onPrimaryContainer,
    ExpressiveColorRole.primaryContainer,
  ),
  (ExpressiveColorRole.secondary, ExpressiveColorRole.onSecondary),
  (ExpressiveColorRole.onSecondary, ExpressiveColorRole.secondary),
  (
    ExpressiveColorRole.secondaryContainer,
    ExpressiveColorRole.onSecondaryContainer,
  ),
  (
    ExpressiveColorRole.onSecondaryContainer,
    ExpressiveColorRole.secondaryContainer,
  ),
  (ExpressiveColorRole.tertiary, ExpressiveColorRole.onTertiary),
  (ExpressiveColorRole.onTertiary, ExpressiveColorRole.tertiary),
  (
    ExpressiveColorRole.tertiaryContainer,
    ExpressiveColorRole.onTertiaryContainer,
  ),
  (
    ExpressiveColorRole.onTertiaryContainer,
    ExpressiveColorRole.tertiaryContainer,
  ),
  (ExpressiveColorRole.error, ExpressiveColorRole.onError),
  (ExpressiveColorRole.onError, ExpressiveColorRole.error),
  (ExpressiveColorRole.errorContainer, ExpressiveColorRole.onErrorContainer),
  (ExpressiveColorRole.onErrorContainer, ExpressiveColorRole.errorContainer),
];

const List<_Tile> _surfaces = <_Tile>[
  (ExpressiveColorRole.surfaceDim, ExpressiveColorRole.onSurface),
  (ExpressiveColorRole.surface, ExpressiveColorRole.onSurface),
  (ExpressiveColorRole.surfaceBright, ExpressiveColorRole.onSurface),
  (ExpressiveColorRole.surfaceContainerLowest, ExpressiveColorRole.onSurface),
  (ExpressiveColorRole.surfaceContainerLow, ExpressiveColorRole.onSurface),
  (ExpressiveColorRole.surfaceContainer, ExpressiveColorRole.onSurface),
  (ExpressiveColorRole.surfaceContainerHigh, ExpressiveColorRole.onSurface),
  (ExpressiveColorRole.surfaceContainerHighest, ExpressiveColorRole.onSurface),
  (ExpressiveColorRole.surfaceVariant, ExpressiveColorRole.onSurfaceVariant),
  (ExpressiveColorRole.onSurface, ExpressiveColorRole.surface),
  (ExpressiveColorRole.onSurfaceVariant, ExpressiveColorRole.surface),
  (ExpressiveColorRole.background, ExpressiveColorRole.onBackground),
  (ExpressiveColorRole.onBackground, ExpressiveColorRole.background),
  (ExpressiveColorRole.surfaceTint, ExpressiveColorRole.onPrimary),
];

const List<_Tile> _fixed = <_Tile>[
  (ExpressiveColorRole.primaryFixed, ExpressiveColorRole.onPrimaryFixed),
  (ExpressiveColorRole.primaryFixedDim, ExpressiveColorRole.onPrimaryFixed),
  (ExpressiveColorRole.onPrimaryFixed, ExpressiveColorRole.primaryFixed),
  (ExpressiveColorRole.onPrimaryFixedVariant, ExpressiveColorRole.primaryFixed),
  (ExpressiveColorRole.secondaryFixed, ExpressiveColorRole.onSecondaryFixed),
  (ExpressiveColorRole.secondaryFixedDim, ExpressiveColorRole.onSecondaryFixed),
  (ExpressiveColorRole.onSecondaryFixed, ExpressiveColorRole.secondaryFixed),
  (
    ExpressiveColorRole.onSecondaryFixedVariant,
    ExpressiveColorRole.secondaryFixed,
  ),
  (ExpressiveColorRole.tertiaryFixed, ExpressiveColorRole.onTertiaryFixed),
  (ExpressiveColorRole.tertiaryFixedDim, ExpressiveColorRole.onTertiaryFixed),
  (ExpressiveColorRole.onTertiaryFixed, ExpressiveColorRole.tertiaryFixed),
  (
    ExpressiveColorRole.onTertiaryFixedVariant,
    ExpressiveColorRole.tertiaryFixed,
  ),
];

const List<_Tile> _utility = <_Tile>[
  (ExpressiveColorRole.inverseSurface, ExpressiveColorRole.inverseOnSurface),
  (ExpressiveColorRole.inverseOnSurface, ExpressiveColorRole.inverseSurface),
  (ExpressiveColorRole.inversePrimary, ExpressiveColorRole.inverseSurface),
  (ExpressiveColorRole.outline, null),
  (ExpressiveColorRole.outlineVariant, null),
  (ExpressiveColorRole.scrim, ExpressiveColorRole.surface),
];

class _Family extends StatelessWidget {
  const _Family(this.title, this.tiles);

  final String title;
  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) {
    final ExpressiveColorScheme c = context.expressiveTheme.colors;
    return kitSection(
      title,
      children: <Widget>[
        // A role with no colour of its own to write on (an edge's) is
        // drawn as the tile's edge, its name in `onSurface` on `surface`.
        for (final (role, on) in tiles)
          DecoratedBox(
            decoration: BoxDecoration(
              color: on == null ? c.surface : c.role(role),
              border: on == null
                  ? Border.all(color: c.role(role), width: ExpressiveSpacing.s4)
                  : Border.all(color: c.outlineVariant),
            ),
            child: Padding(
              // The edge's extra width taken from the padding, so every
              // tile is the same height.
              padding: EdgeInsets.symmetric(
                horizontal:
                    ExpressiveSpacing.s16 -
                    (on == null ? ExpressiveSpacing.s4 - 1 : 0),
                vertical:
                    ExpressiveSpacing.s8 -
                    (on == null ? ExpressiveSpacing.s4 - 1 : 0),
              ),
              child: Text(
                role.name,
                style: TextStyle(
                  color: c.role(on ?? ExpressiveColorRole.onSurface),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
