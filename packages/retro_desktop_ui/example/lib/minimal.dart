import 'package:material_ui/material_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

void main() => runApp(
  MaterialApp(
    builder: (context, child) =>
        RetroDesktopTheme(data: RetroDesktopThemeData.classic(), child: child!),
    home: Center(child: RetroDesktopButton('Save', onPressed: () {})),
  ),
);
