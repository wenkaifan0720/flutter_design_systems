// fluent2LoadFonts() loads every face Fluent 2's parts draw with: each
// family a glyph or a style names in the library, the icon faces with
// Selawik. A face it skipped would draw its glyphs as empty boxes in the
// web's first frames.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

/// Each family the package's pubspec declares, with its files.
Map<String, List<String>> _declared() {
  final faces = <String, List<String>>{};
  String? family;
  for (final line in File('pubspec.yaml').readAsLinesSync()) {
    final named = RegExp(r'^\s*- family: (\S+)').firstMatch(line);
    if (named != null) family = named.group(1);
    final asset = RegExp(r'^\s*- asset: (\S+)').firstMatch(line);
    if (asset != null && family != null) {
      faces.putIfAbsent(family, () => []).add(asset.group(1)!);
    }
  }
  return faces;
}

/// Each family a glyph or a style in the library names.
Set<String> _drawn() => {
  for (final file in Directory('lib').listSync(recursive: true))
    if (file is File && file.path.endsWith('.dart'))
      for (final match in RegExp(
        r"fontFamily: '([^']+)'",
      ).allMatches(file.readAsStringSync()))
        match.group(1)!,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the loader loads each icon family the parts draw with', () async {
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
      final path = key.replaceFirst('packages/$fluent2FontPackage/', '');
      return ByteData.sublistView(File(path).readAsBytesSync());
    });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));

    await fluent2LoadFonts();

    final declared = _declared();
    final drawn = _drawn();
    expect(drawn, containsAll(['Fluent2Icons', 'Fluent2IconsFilled']));
    for (final family in drawn) {
      expect(declared[family], isNotNull, reason: '$family is not bundled');
      for (final asset in declared[family]!) {
        expect(
          asked,
          contains('packages/$fluent2FontPackage/$asset'),
          reason: 'fluent2LoadFonts() skips $family ($asset)',
        );
      }
    }
  });
}
