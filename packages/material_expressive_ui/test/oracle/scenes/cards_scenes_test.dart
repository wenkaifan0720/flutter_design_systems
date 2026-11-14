/// The `cards` oracle group (Compose twin: `CardsScenes.kt`): the elevated,
/// filled and outlined card at rest and clickable-disabled, and a filled
/// clickable card keyboard-focused (its focus state layer). Every card is
/// 112dp square and empty, so only the container is compared: its shape
/// (radii recorded), colour, stroke and shadow.
library;

import 'package:material_ui/material_ui.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../harness/oracle.dart';

const Size _crop = Size(400, 144);
const double _side = 112;

/// The three variants side by side, tagged `card-<variant>`; clickable and
/// disabled when [disabled].
Widget _row(BuildContext context, {required bool disabled}) => Row(
  mainAxisSize: MainAxisSize.min,
  spacing: 16,
  children: [
    for (final variant in ExpressiveCardVariant.values)
      OracleTag(
        'card-${variant.name}',
        shape: context.expressiveTheme.shapes.medium,
        child: ExpressiveCard(
          variant: variant,
          onPressed: null,
          child: const SizedBox.square(dimension: _side),
        ),
      ),
  ],
);

final OracleGroup cardsScenes = OracleGroup(
  id: 'cards',
  // What a clickable card needs above it: the host's ripple and thin
  // Material theme.
  frame: (context, scene) {
    final theme = context.expressiveTheme;
    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<Object>>[
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: ExpressiveHost(
        light: theme,
        dark: theme,
        brightness: theme.brightness,
        child: scene,
      ),
    );
  },
  scenes: [
    OracleScene(
      key: 'cards/variants',
      size: _crop,
      build: (context) => _row(context, disabled: false),
    ),
    OracleScene(
      key: 'cards/disabled',
      size: _crop,
      build: (context) => _row(context, disabled: true),
    ),
    OracleScene(
      key: 'cards/filled/focused',
      size: const Size(144, 144),
      build: (context) => OracleTag(
        'card',
        shape: context.expressiveTheme.shapes.medium,
        child: ExpressiveCard.filled(
          onPressed: () {},
          child: const SizedBox.square(dimension: _side),
        ),
      ),
      interaction: const OracleFocus('card'),
    ),
  ],
);

void main() => runOracleGroup(cardsScenes);
