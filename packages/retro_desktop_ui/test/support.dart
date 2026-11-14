// What the part tests share: the real faces, an app shell, and the check that a part with odd data neither throws nor
// overflows at a phone and a desktop width, in both modes and both directions.
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

const long = 'Donaudampfschifffahrtsgesellschaftskapitänsmütze';
const longLine =
    'A much longer line than the example ever had to carry, with $long in the middle of it, and then more';

/// Loads the bundled faces the pubspec names, so a long word is measured as it would be on a device.
Future<void> loadRetroDesktopFonts() async {
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
    final loader = FontLoader(retroDesktopFontFamily(name));
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }
}

/// Loads the glyphs' own face from its package, as an app bundles it: the test's stand-in face draws a box that sits
/// higher in the line, so a test that reads a glyph's ink loads this.
Future<void> loadRetroDesktopGlyphFace([
  IconData glyph = RetroDesktopGlyphs.fileText,
]) async {
  final family = glyph.fontFamily!, package = glyph.fontPackage!;
  // A pub workspace keeps one package config at its root, so look up from the package for the nearest one.
  var dir = Directory.current.absolute;
  var config = File('${dir.path}/.dart_tool/package_config.json');
  while (!config.existsSync() && dir.parent.path != dir.path) {
    dir = dir.parent;
    config = File('${dir.path}/.dart_tool/package_config.json');
  }
  final packages =
      (jsonDecode(config.readAsStringSync())
              as Map<String, dynamic>)['packages']
          as List<dynamic>;
  final entry = packages.cast<Map<String, dynamic>>().firstWhere(
    (p) => p['name'] == package,
  );
  final root = config.uri.resolve('${entry['rootUri']}/');
  final pubspec = File.fromUri(root.resolve('pubspec.yaml')).readAsLinesSync();
  final named = RegExp(r'^\s*- family:\s*' + RegExp.escape(family) + r'\s*$');
  final at = pubspec.indexWhere(named.hasMatch);
  final line = pubspec.skip(at + 1).firstWhere((l) => l.contains('asset:'));
  final asset = RegExp(r'asset:\s*(\S+)').firstMatch(line)![1]!;
  final bytes = File.fromUri(root.resolve(asset)).readAsBytesSync();
  await (FontLoader(
    'packages/$package/$family',
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

/// Loads every family in the test bundle's FontManifest.json (the look's faces and each glyph package's weights) under
/// its manifest name, as an app bundles them: a family left out draws in the test's own font, whose missing glyph
/// stands on the baseline.
Future<void> loadRetroDesktopManifestFonts() async {
  final manifest = jsonDecode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font
        in (family['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// [home] in a host wearing a preset. The width is the view's.
Widget retroDesktopApp(
  Widget home, {
  String preset = 'classic',
  bool dark = false,
  TextDirection direction = TextDirection.ltr,
  double width = 390,
  double scale = 1,
}) {
  final base = RetroDesktopThemeData.preset(
    preset,
    dark ? Brightness.dark : Brightness.light,
  );
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, child) => RetroDesktopTheme(
      data: base.atWidth(MediaQuery.sizeOf(context).width),
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
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
        testWidgets('$name @$width ${dark ? 'dark' : 'light'} ${dir.name}', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            retroDesktopApp(
              SingleChildScrollView(
                child: Center(
                  child: SizedBox(width: width - 40, child: child()),
                ),
              ),
              dark: dark,
              direction: dir,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
