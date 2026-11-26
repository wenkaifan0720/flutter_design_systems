import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

export 'package:minimal_ui/minimal_ui.dart' show minimalLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = MinimalThemeData.standard(brightness);
  return MinimalTheme(
    data: theme,
    child: ColoredBox(
      color: theme.background,
      child: DefaultTextStyle.merge(style: theme.body, child: child),
    ),
  );
}
