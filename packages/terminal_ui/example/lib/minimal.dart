import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() => runApp(
  MaterialApp(
    builder: (context, child) => TermHost(child: child!),
    home: Center(
      child: TermButton.filled(label: 'deploy', onPressed: () {}),
    ),
  ),
);
