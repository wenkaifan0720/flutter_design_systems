// The veil a called-up dialog, sheet or palette lays over the page: the bare wall, so the page behind fades toward
// the wall it is cast from. A grey (black at 40%) would dirty the wall by day and turn a sheet's light cast into a
// glow on every side; by night it would barely show on the dark ground.
import 'dart:ui' show Color;

import '../theme.dart';

/// The veil over the page behind a called-up surface: the wall's colour at 72%.
Color neumorphicVeil(NeumorphicColors c) => c.ground.withValues(alpha: .72);
