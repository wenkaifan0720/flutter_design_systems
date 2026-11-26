import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

export 'package:fluent2_design_ui/fluent2_design_ui.dart' show fluent2LoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = Fluent2ThemeData.lapis(brightness);
  return Fluent2Theme(
    data: theme,
    child: ColoredBox(
      color: theme.background,
      child: DefaultTextStyle.merge(style: theme.body1, child: child),
    ),
  );
}
