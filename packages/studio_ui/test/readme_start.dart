// The README's first Dart block, word for word: readme_start_test.dart
// compiles it, runs it and holds the README to it.
import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

void main() => runApp(
  MaterialApp(
    builder: (context, child) => StudioHost(child: child!),
    home: const StudioScreen(
      topBar: StudioAppBar(title: 'Library'),
      body: StudioDisplay(child: Text('Rooms that sound right, 38 min.')),
    ),
  ),
);
