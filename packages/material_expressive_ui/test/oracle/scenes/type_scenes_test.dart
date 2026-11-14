/// The `type` oracle group (Compose twin: `TypeScenes.kt`): the 30 styles,
/// one scene each, two lines of [typeSample] in `onSurface`, laid out with
/// the text-height behaviour Expressive's text sets (Compose's
/// `LineHeightStyle`).
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/keys.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/type/text_height.dart';

import '../harness/oracle.dart';

/// Two lines, so the line height shows between baselines too.
const String typeSample = 'Expressive\nType 2026';

/// Every style, by its key segment, largest first, baseline then
/// emphasized (the oracle's `TypeScenes.STYLES`).
final List<String> typeStyles = [
  for (final emphasized in [false, true])
    for (final role in ['display', 'headline', 'title', 'body', 'label'])
      for (final size in ['large', 'medium', 'small'])
        '$role-$size${emphasized ? '-emphasized' : ''}',
];

ExpressiveTypeKey _key(String segment) {
  final words = segment.split('-');
  final camel = [
    words.first,
    for (final w in words.skip(1)) w[0].toUpperCase() + w.substring(1),
  ].join();
  return ExpressiveTypeKey.values.byName(camel);
}

final OracleGroup typeScenes = OracleGroup(
  id: 'type',
  scenes: [
    for (final style in typeStyles)
      OracleScene(
        key: 'type/$style',
        size: const Size(400, 160),
        build: (context) {
          final theme = context.expressiveTheme;
          // Compose's LineHeightStyle(Center, Trim.None), as the text
          // role lays it out (internal/type/text_height.dart).
          final (type, behavior) = expressiveTextLayout(
            theme.type.of(_key(style)),
          );
          return OracleTag(
            'text',
            child: Text(
              typeSample,
              style: type.copyWith(color: theme.colors.onSurface),
              textHeightBehavior: behavior,
            ),
          );
        },
      ),
  ],
);

void main() => runOracleGroup(typeScenes);
