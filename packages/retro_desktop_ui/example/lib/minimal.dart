import 'package:material_ui/material_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await retroDesktopLoadFonts();
  runApp(
    MaterialApp(
      builder: (context, child) => RetroDesktopHost(child: child!),
      home: Center(child: RetroDesktopButton('Save', onPressed: () {})),
    ),
  );
}
