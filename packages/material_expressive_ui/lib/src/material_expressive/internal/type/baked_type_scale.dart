/// The type part of a baked theme and how it resolves into the public
/// [ExpressiveTextTheme]: w1-type's slot, with `type.dart` and the
/// generator's `emit/type.ts`. Internal; the generated themes name
/// [ExpressiveBakedTextTheme] through `baked_theme.dart`.
///
/// Themes do not vary the scale: every theme wears Compose's
/// `TypeScaleTokens` in Roboto Flex, so the part carries nothing, and the
/// scale resolves in the English-like language-height category (a host
/// narrows it to its locale with [ExpressiveTextTheme.forLocale]).
library;

import 'package:flutter/widgets.dart';

import '../../type.dart';
import '../themes/baked_theme.dart';

/// What a theme bakes for its type scale: nothing yet — the one scale.
@immutable
class ExpressiveBakedTextTheme {
  /// A baked type scale.
  const ExpressiveBakedTextTheme();
}

/// [baked]'s type scale in [brightness]: the one scale, whatever either.
ExpressiveTextTheme expressiveResolveTextTheme(
  ExpressiveBakedTheme baked,
  Brightness brightness,
) => const ExpressiveTextTheme();
