import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/widgets.dart';

export 'package:civic_ui/civic_ui.dart' show civicLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = brightness == Brightness.dark
      ? CivicThemeData.dark()
      : CivicThemeData.light();
  return CivicTheme(
    data: theme,
    child: ColoredBox(
      color: theme.background,
      child: DefaultTextStyle.merge(style: theme.text.body, child: child),
    ),
  );
}
