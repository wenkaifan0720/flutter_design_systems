// What the part tests share: the real faces, an app shell, and the check that a part with odd data neither throws nor
// overflows at a phone and a desktop width, in both modes and both directions.
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

const long = 'Donaudampfschifffahrtsgesellschaftskapitänsmütze';
const longLine =
    'A much longer line than the example ever had to carry, with $long in the middle of it, and then more';

/// Loads the bundled faces the pubspec names, so a long word is measured as it would be on a device.
Future<void> loadComicFonts() async {
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
    final loader = FontLoader(comicFontFamily(name));
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }
}

/// [home] in a host wearing a preset. The width is the view's.
Widget comicApp(
  Widget home, {
  String preset = 'offset',
  bool dark = false,
  TextDirection direction = TextDirection.ltr,
  double width = 390,
}) {
  final base = ComicTheme.preset(
    preset,
    dark ? Brightness.dark : Brightness.light,
  );
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, child) => ComicTheme(
      data: base.atWidth(MediaQuery.sizeOf(context).width),
      child: Directionality(textDirection: direction, child: child!),
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
            comicApp(
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
