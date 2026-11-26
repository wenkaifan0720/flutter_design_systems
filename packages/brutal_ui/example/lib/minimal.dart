import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(
  MaterialApp(
    builder: (context, child) =>
        BrutalHost(theme: BrutalThemeData.light(), child: child!),
    home: Center(child: BrutalButton.filled('Buy tickets', onPressed: () {})),
  ),
);
