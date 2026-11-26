import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

export 'package:studio_ui/studio_ui.dart' show studioLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = StudioThemeData.anodised(brightness);
  return StudioTheme(
    data: theme,
    child: ColoredBox(
      color: theme.colors.chassis,
      child: DefaultTextStyle.merge(style: theme.textTheme.body, child: child),
    ),
  );
}
