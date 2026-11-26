import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

export 'package:neumorphism_ui/neumorphism_ui.dart' show neumorphicLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = NeumorphicThemeData.porcelain(brightness);
  return NeumorphicTheme(
    data: theme,
    child: ColoredBox(
      color: theme.colors.ground,
      child: DefaultTextStyle.merge(style: theme.body, child: child),
    ),
  );
}
