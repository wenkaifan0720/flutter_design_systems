import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_host.dart' show FrostedHost;
import 'package:frosted_ui/frosted_ui.dart';

export 'package:frosted_ui/frosted_ui.dart' show frostedLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  return FrostedHost(
    brightness: brightness,
    theme: FrostedThemeData.opal(Brightness.light),
    darkTheme: FrostedThemeData.opal(Brightness.dark),
    child: Stack(
      fit: StackFit.expand,
      children: [const FrostedBackdropView(), child],
    ),
  );
}
