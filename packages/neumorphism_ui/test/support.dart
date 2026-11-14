// What the part tests share: the real faces, an app shell, and the check that a part with odd data neither throws nor
// overflows at a phone and a desktop width, in both modes and both directions.
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

const long = 'Donaudampfschifffahrtsgesellschaftskapitänsmütze';
const longLine =
    'A much longer line than the example ever had to carry, with $long in the middle of it, and then more';

/// Loads the bundled faces the pubspec names, so a long word is measured as it would be on a device.
Future<void> loadNeumorphicFonts() async {
  final faces = <String, List<String>>{};
  String? family;
  for (final line in File('pubspec.yaml').readAsLinesSync()) {
    final found = RegExp(r'^\s*- family:\s*(.+)$').firstMatch(line);
    final asset = RegExp(r'^\s*- asset:\s*(.+)$').firstMatch(line);
    if (found != null) family = found[1]!.trim();
    if (asset != null && family != null) {
      (faces[family] ??= []).add(asset[1]!.trim());
    }
  }
  for (final MapEntry(key: name, value: files) in faces.entries) {
    final loader = FontLoader(neumorphicFontFamily(name));
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }
}

/// Loads the glyph face the look draws its icons in (Lucide, a dependency's font, so not in the pubspec), so an icon's
/// ink is measured where a device draws it, not as the test font's square.
Future<void> loadNeumorphicGlyphs() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final name = family['family'] as String;
    if (!name.startsWith('packages/lucide_icons_flutter/')) continue;
    final loader = FontLoader(name);
    for (final font
        in (family['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// [home] in a host wearing a preset. The width is the view's.
Widget neumorphicApp(
  Widget home, {
  String preset = 'porcelain',
  bool dark = false,
  TextDirection direction = TextDirection.ltr,
  double width = 390,
  double textScale = 1,
}) {
  final base = NeumorphicThemeData.preset(
    preset,
    dark ? Brightness.dark : Brightness.light,
  );
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, child) => NeumorphicTheme(
      data: base.atWidth(MediaQuery.sizeOf(context).width),
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Directionality(textDirection: direction, child: child!),
      ),
    ),
    home: Scaffold(body: home),
  );
}

/// Pumps [child] in a page-like column at each width, mode and direction, and fails on any overflow or exception.
void check(String name, Widget Function() child) {
  for (final width in const [320.0, 1440.0]) {
    for (final dark in const [false, true]) {
      for (final dir in const [TextDirection.ltr, TextDirection.rtl]) {
        for (final scale in const [1.0, 2.0]) {
          testWidgets(
            '$name @$width ${dark ? 'dark' : 'light'} ${dir.name} text $scale',
            (tester) async {
              tester.view.physicalSize = Size(width, 1200);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              await tester.pumpWidget(
                neumorphicApp(
                  SingleChildScrollView(
                    child: Center(
                      child: SizedBox(width: width - 40, child: child()),
                    ),
                  ),
                  dark: dark,
                  direction: dir,
                  textScale: scale,
                ),
              );
              await tester.pump();
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
