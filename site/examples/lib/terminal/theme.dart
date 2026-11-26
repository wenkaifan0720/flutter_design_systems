import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

export 'package:terminal_ui/terminal_ui.dart' show termLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = TermThemeData.of(brightness);
  return TermTheme(
    data: theme,
    child: ColoredBox(color: theme.background, child: child),
  );
}
