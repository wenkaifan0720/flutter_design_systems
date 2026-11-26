import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

export 'package:gloss_ui/gloss_ui.dart' show glossLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = GlossThemeData.jade(brightness);
  return GlossTheme(
    data: theme,
    child: ColoredBox(color: theme.colors.page, child: child),
  );
}
