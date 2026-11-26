import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

export 'package:comic_ui/comic_ui.dart' show comicLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = ComicThemeData.offset(brightness);
  return ComicTheme(
    data: theme,
    child: ColoredBox(
      color: theme.colors.background,
      child: DefaultTextStyle.merge(style: theme.body, child: child),
    ),
  );
}
