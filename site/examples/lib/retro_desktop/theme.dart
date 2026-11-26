import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

export 'package:retro_desktop_ui/retro_desktop_ui.dart'
    show retroDesktopLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = RetroDesktopThemeData.classic(brightness);
  return RetroDesktopTheme(
    data: theme,
    child: ColoredBox(color: theme.colors.paper, child: child),
  );
}
