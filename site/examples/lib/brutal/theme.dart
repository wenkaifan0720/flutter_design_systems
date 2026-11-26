import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

export 'package:brutal_ui/brutal_ui.dart' show brutalLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = brightness == Brightness.dark
      ? BrutalThemeData.dark()
      : BrutalThemeData.light();
  return BrutalTheme(
    data: theme,
    child: ColoredBox(
      color: theme.colors.paper,
      child: DefaultTextStyle.merge(style: theme.textTheme.body, child: child),
    ),
  );
}
