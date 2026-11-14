import 'package:flutter/widgets.dart';

import '../theme.dart';

/// The ink that reads on an opaque [fill]: [preferred] when it reads 4.5:1
/// there, else white or the theme's dark ink, whichever reads better (a
/// count's words on the unread dot, a tone's glyph on its disc). Plumbing of
/// the components.
Color frostedInkOn(FrostedThemeData t, Color fill, {Color? preferred}) {
  if (preferred != null && FrostedThemeData.contrast(preferred, fill) >= 4.5) {
    return preferred;
  }
  const white = Color(0xFFFFFFFF);
  final dark = t.isDark ? t.colorScheme.background : t.colorScheme.textPrimary;
  return FrostedThemeData.contrast(white, fill) >=
          FrostedThemeData.contrast(dark, fill)
      ? white
      : dark;
}
