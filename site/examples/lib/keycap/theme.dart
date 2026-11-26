import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

export 'package:keycap_ui/keycap_ui.dart' show keycapLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = KeycapThemeData.of(brightness);
  return KeycapTheme(
    data: theme,
    child: ColoredBox(
      color: theme.colors.ground,
      child: DefaultTextStyle.merge(style: theme.textTheme.body, child: child),
    ),
  );
}
