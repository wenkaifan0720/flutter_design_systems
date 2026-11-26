import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

export 'package:appliance_ui/appliance_ui.dart' show applianceLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = ApplianceThemeData.from(brightness: brightness);
  return ApplianceTheme(
    data: theme,
    child: ColoredBox(
      color: theme.colors.housingTop,
      child: DefaultTextStyle.merge(style: theme.textTheme.body, child: child),
    ),
  );
}
