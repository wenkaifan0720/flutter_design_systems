// studioLoadFonts() loads every face Studio's parts draw with: Barlow, the
// Arabic chart face and Lucide, the glyphs (LucideIcons) every part's icon
// names. A face it skipped would draw its glyphs as empty boxes in the
// web's first frames.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

/// The file an asset key names: the package's own beside the test, another
/// package's in its own folder.
Future<File> _file(String key) async {
  final match = RegExp(r'^packages/([^/]+)/(.+)$').firstMatch(key);
  if (match == null || match.group(1) == studioFontPackage) {
    return File(match?.group(2) ?? key);
  }
  // The package's folder, from the nearest package config up from here.
  var dir = Directory.current.absolute;
  while (!File('${dir.path}/.dart_tool/package_config.json').existsSync()) {
    dir = dir.parent;
  }
  final config = File('${dir.path}/.dart_tool/package_config.json');
  final packages =
      (jsonDecode(config.readAsStringSync())
              as Map<String, Object?>)['packages']
          as List<Object?>;
  final entry = packages.cast<Map<String, Object?>>().firstWhere(
    (p) => p['name'] == match.group(1),
  );
  final root = config.uri.resolve('${entry['rootUri']}/');
  return File.fromUri(root.resolve(match.group(2)!));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the loader loads Lucide, the glyphs the parts draw with', () async {
    final asked = <String>{};
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = Uri.decodeFull(
        utf8.decode(
          message!.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        ),
      );
      asked.add(key);
      return ByteData.sublistView((await _file(key)).readAsBytesSync());
    });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));

    await studioLoadFonts();

    const glyph = LucideIcons.mic;
    expect(glyph.fontFamily, 'Lucide');
    expect(
      asked,
      contains('packages/${glyph.fontPackage}/assets/lucide.ttf'),
      reason: 'studioLoadFonts() skips Lucide',
    );
    expect(
      asked.where((key) => key.endsWith('Barlow-Regular.ttf')),
      isNotEmpty,
    );
  });
}
