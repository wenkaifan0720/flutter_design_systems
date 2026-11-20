/// Resolves the generated type scale into [ExpressiveTextTheme]. The host
/// applies locale-specific line heights with [ExpressiveTextTheme.forLocale].
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
