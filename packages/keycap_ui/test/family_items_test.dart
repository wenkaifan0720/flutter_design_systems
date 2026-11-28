// The family's round-3 items, as Keycap answers them: the loader brings
// Lucide's glyphs with the face, so a web build never draws an icon as an
// empty box, and the README gives one list of delegates, the example's.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  test(
    'keycapLoadFonts loads the face and the icon font the parts draw with',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final asked = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        asked.add(utf8.decode(message!.buffer.asUint8List()));
        return ByteData(8);
      });
      addTearDown(
        () => messenger.setMockMessageHandler('flutter/assets', null),
      );
      await keycapLoadFonts();
      // The icons Keycap's parts draw are Lucide's, from its package.
      expect(LucideIcons.chevronDown.fontFamily, 'Lucide');
      expect(LucideIcons.chevronDown.fontPackage, 'lucide_icons_flutter');
      expect(
        asked,
        contains('packages/lucide_icons_flutter/assets/lucide.ttf'),
      );
      expect(
        asked.where((key) => key.endsWith('.ttf') && key.contains('Rubik-')),
        hasLength(3),
      );
    },
  );

  test(
    "the README's delegates are the example's, with no flutter_localizations",
    () {
      final readme = File('README.md').readAsStringSync();
      final example = File('example/lib/main.dart').readAsStringSync();
      for (final line in [
        'supportedLocales: RawWidgetsLocalizations.supportedLocales,',
        'RawWidgetsLocalizations.delegate,',
        '...GlobalMaterialLocalizations.delegates,',
      ]) {
        expect(RegExp(RegExp.escape(line)).allMatches(readme), hasLength(1));
        expect(example, contains(line));
      }
      expect(readme, contains('needs no `flutter_localizations` dependency'));
    },
  );
}
