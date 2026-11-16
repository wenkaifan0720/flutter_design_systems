/// How a part lays its own `style:` over its component theme: state by
/// state, the style first, as [ExpressiveComponentThemeData.layered] does.
/// Internal; `merge` keeps a slot whole, as `ButtonStyle.merge` does.
library;

import '../component_themes.dart';

/// A component theme under a part's own style.
extension ExpressiveStyleLayers on ExpressiveComponentThemeData {
  /// [top] over this style, state by state: each slot is [top]'s where it
  /// resolves to a value for the states at hand, else this style's.
  ExpressiveComponentThemeData layeredUnder(
    ExpressiveComponentThemeData? top,
  ) => top == null ? this : ExpressiveComponentThemeData.layered([top, this]);
}
