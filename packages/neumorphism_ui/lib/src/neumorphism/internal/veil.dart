// The veil a called-up dialog, sheet or palette lays over the page: the bare plaster, so the page behind fades toward
// the wall it is cast from. A grey (black at 40%) dirtied the plaster by day and turned a sheet's light cast into a
// glow on every side; by night it barely showed on the dark ground.
import 'dart:ui' show Color;

import '../theme.dart';

/// The plaster veil over the page behind a called-up surface.
Color neumorphicVeil(NeumorphicColors c) => c.ground.withValues(alpha: .72);
