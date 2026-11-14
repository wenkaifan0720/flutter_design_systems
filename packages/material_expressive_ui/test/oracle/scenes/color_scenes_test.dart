/// The `color` oracle group (Compose twin: `ColorScenes.kt`): every colour
/// role as a swatch, and the surface roles as a full window.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../harness/oracle.dart';

/// Every role, in Compose's `ColorScheme` constructor order (the oracle's
/// `BakedSchemes.ROLES`).
const List<String> colorRoles = [
  'primary', 'onPrimary', 'primaryContainer', 'onPrimaryContainer', //
  'inversePrimary', 'secondary', 'onSecondary', 'secondaryContainer',
  'onSecondaryContainer', 'tertiary', 'onTertiary', 'tertiaryContainer',
  'onTertiaryContainer', 'background', 'onBackground', 'surface',
  'onSurface', 'surfaceVariant', 'onSurfaceVariant', 'surfaceTint',
  'inverseSurface', 'inverseOnSurface', 'error', 'onError',
  'errorContainer', 'onErrorContainer', 'outline', 'outlineVariant',
  'scrim', 'surfaceBright', 'surfaceDim', 'surfaceContainer',
  'surfaceContainerHigh', 'surfaceContainerHighest', 'surfaceContainerLow',
  'surfaceContainerLowest', 'primaryFixed', 'primaryFixedDim',
  'onPrimaryFixed', 'onPrimaryFixedVariant', 'secondaryFixed',
  'secondaryFixedDim', 'onSecondaryFixed', 'onSecondaryFixedVariant',
  'tertiaryFixed', 'tertiaryFixedDim', 'onTertiaryFixed',
  'onTertiaryFixedVariant',
];

/// The surface roles, lowest to highest, as the screen scene stacks them:
/// 112 dp bands (whole pixels) from the top inset down.
const List<String> surfaceRoles = [
  'surfaceContainerLowest', 'surfaceContainerLow', 'surfaceContainer', //
  'surfaceContainerHigh', 'surfaceContainerHighest', 'surfaceDim',
  'surfaceBright',
];

Color _role(BuildContext context, String name) => context.expressiveTheme.colors
    .role(ExpressiveColorRole.values.byName(name));

final OracleGroup colorScenes = OracleGroup(
  id: 'color',
  scenes: [
    OracleScene(
      key: 'color/roles',
      size: const Size(296, 392),
      build: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          for (var i = 0; i < colorRoles.length; i += 6)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                for (final role in colorRoles.skip(i).take(6))
                  OracleTag(
                    role,
                    child: SizedBox.square(
                      dimension: 40,
                      child: ColoredBox(color: _role(context, role)),
                    ),
                  ),
              ],
            ),
        ],
      ),
    ),
    OracleScene.screen(
      key: 'color/surfaces',
      build: (context) => Padding(
        padding: MediaQuery.paddingOf(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final role in surfaceRoles)
              OracleTag(
                role,
                child: SizedBox(
                  height: 112,
                  child: ColoredBox(color: _role(context, role)),
                ),
              ),
          ],
        ),
      ),
    ),
  ],
);

void main() => runOracleGroup(colorScenes);
