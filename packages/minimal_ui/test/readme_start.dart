// The README's first Dart block, word for word: readme_start_test.dart
// compiles it, runs it and holds the README to it.
import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';

void main() => runApp(
  MaterialApp(
    builder: (context, child) =>
        MinimalTheme(data: MinimalThemeData.standard(), child: child!),
    home: const MinimalScaffold(
      topBar: MinimalAppBar(title: 'Requests'),
      body: MinimalListTile(title: 'Replace the lobby lights', meta: 'REQ-142'),
    ),
  ),
);
