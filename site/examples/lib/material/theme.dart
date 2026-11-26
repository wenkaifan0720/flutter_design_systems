import 'package:material_ui/material_ui.dart';

/// Material draws with Roboto and its icon font, both preloaded by the site.
Future<void> materialLoadFonts() async {}

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = ThemeData(brightness: brightness);
  return Theme(
    data: theme,
    child: Material(color: theme.colorScheme.surface, child: child),
  );
}
