// The bundled faces, loaded for a test: in Flutter's test font every glyph
// is as wide as the font is tall, so a line of words would be a third
// wider than its cells and a fit could not be judged.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:terminal_ui/terminal_ui.dart';

/// Loads JetBrains Mono and Liberation Mono under the names the theme asks
/// for. Run it from `setUpAll`.
Future<void> loadFaces() async {
  const faces = {
    'JetBrainsMono': ['JetBrainsMonoNL-Regular', 'JetBrainsMonoNL-Bold'],
    'LiberationMono': ['LiberationMono-Regular', 'LiberationMono-Bold'],
  };
  for (final MapEntry(key: family, value: files) in faces.entries) {
    final loader = FontLoader(termRegisteredFamily(family));
    for (final file in files) {
      final bytes = File('assets/fonts/$file.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
}
