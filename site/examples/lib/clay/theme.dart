import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';

export 'package:clay_ui/clay_ui.dart' show clayLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = ClayThemeData.clay(brightness);
  return ClayTheme(
    data: theme,
    child: ColoredBox(color: theme.colors.ground, child: child),
  );
}
