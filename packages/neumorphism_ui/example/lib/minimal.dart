import 'package:material_ui/material_ui.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

void main() => runApp(
  MaterialApp(
    builder: (context, child) =>
        NeumorphicTheme(data: NeumorphicThemeData.porcelain(), child: child!),
    home: NeumorphicScaffold(
      body: Center(child: NeumorphicButton('Save', onPressed: () {})),
    ),
  ),
);
