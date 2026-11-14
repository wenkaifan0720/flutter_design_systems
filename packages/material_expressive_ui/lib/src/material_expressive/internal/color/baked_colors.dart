/// The colour part of a baked theme and how it resolves into the public
/// [ExpressiveColorScheme]. Internal; the generated themes name
/// [ExpressiveBakedColors] through `baked_theme.dart`.
///
/// Owner: w1-color (with `color.dart` and the generator's `emit/color.ts`).
library;

import 'package:flutter/widgets.dart';

import '../../color.dart';
import '../themes/baked_theme.dart';

/// Every colour role of one theme, light and dark, by role name
/// ([ExpressiveColorRole.name], `onSurfaceVariant`), as ARGB.
@immutable
class ExpressiveBakedColors {
  /// Baked colours of the [light] and [dark] roles, with variants [atContrast].
  const ExpressiveBakedColors({
    required this.light,
    required this.dark,
    this.statusLight = const <String, int>{},
    this.statusDark = const <String, int>{},
    this.atContrast = const <String, ExpressiveBakedColors>{},
  });

  /// Every role in light.
  final Map<String, int> light;

  /// Every role in dark. Generated, never an inversion of [light].
  final Map<String, int> dark;

  /// The status tones in light (`success`, `onSuccess`, `successContainer`,
  /// `onSuccessContainer` and the same for `warning`): Material custom
  /// colours, never roles. Empty when the theme was baked without them.
  final Map<String, int> statusLight;

  /// The status tones in dark. Baked, never an inversion of [statusLight].
  final Map<String, int> statusDark;

  /// The same seed and variant baked at each other contrast level the
  /// baker allows, keyed by [_contrastKey(] (`'0'`, `'0.5'`, `'1'`); the
  /// theme's own contrast is [light] and [dark]. Empty for Compose's
  /// baseline, which has no contrast variants. The oracle captures a
  /// baked theme at contrast 0 and 1 through [expressiveResolveColors(]' `contrast`.
  final Map<String, ExpressiveBakedColors> atContrast;
}

/// A contrast level as [ExpressiveBakedColors.atContrast] and the oracle's
/// `schemes.g.json` key it: `0`, `0.5`, `1`.
String _contrastKey(double contrast) => contrast == contrast.truncateToDouble()
    ? contrast.toInt().toString()
    : contrast.toString();

/// md.sys.color.shadow: the neutral palette's tone 0, which is black for
/// every seed (material-color-utilities' `shadow`; the generator's parity
/// test holds every baked input to it), and what Compose's shadows paint
/// with (`DefaultShadowColor`). No theme varies it, so it is not baked.
const Color _shadow = Color(0xFF000000);

/// [baked]'s colour roles in [brightness], at the theme's own contrast or,
/// given [contrast], at that baked level. Throws when the level was not
/// baked, or when the baked part does not carry exactly the
/// [ExpressiveColorRole]s.
ExpressiveColorScheme expressiveResolveColors(
  ExpressiveBakedTheme baked,
  Brightness brightness, {
  double? contrast,
}) {
  var colors = baked.colors;
  if (contrast != null && contrast != baked.contrast) {
    final at = colors.atContrast[_contrastKey(contrast)];
    if (at == null) {
      throw StateError(
        'The baked theme "${baked.id}" has no colours at contrast $contrast '
        '(baked: ${[_contrastKey(baked.contrast), ...colors.atContrast.keys].join(', ')}).',
      );
    }
    colors = at;
  }
  return expressiveColorsFromArgb(
    brightness == Brightness.dark ? colors.dark : colors.light,
    'The baked theme "${baked.id}"',
  );
}

/// [roles], every [ExpressiveColorRole] by name as ARGB, as a scheme with
/// md.sys.color.shadow. Throws a [StateError] naming [owner] unless
/// [roles] carries exactly the [ExpressiveColorRole]s.
ExpressiveColorScheme expressiveColorsFromArgb(
  Map<String, int> roles,
  String owner,
) {
  final known = ExpressiveColorRole.values.map((role) => role.name).toSet();
  final extra = roles.keys.where((name) => !known.contains(name));
  if (extra.isNotEmpty) {
    throw StateError('$owner has unknown roles ${extra.join(', ')}.');
  }
  return ExpressiveColorScheme.fromRoles((role) {
    final argb = roles[role.name];
    if (argb == null) throw StateError('$owner has no role ${role.name}.');
    return Color(argb);
  }, shadow: _shadow);
}
