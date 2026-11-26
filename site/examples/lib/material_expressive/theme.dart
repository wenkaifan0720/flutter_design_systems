import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

export 'package:material_expressive_ui/material_expressive_ui.dart'
    show expressiveLoadFonts;

// The host wears the theme and shows snackbars above the preview's navigator.
Widget wrapLook(Brightness brightness, Widget child) {
  final theme = ExpressiveThemeData.grove(brightness);
  return ExpressiveHost(
    theme: ExpressiveThemeData.grove(Brightness.light),
    darkTheme: ExpressiveThemeData.grove(Brightness.dark),
    brightness: brightness,
    child: ColoredBox(
      color: theme.colors.surface,
      child: DefaultTextStyle.merge(style: theme.type.bodyMedium, child: child),
    ),
  );
}
