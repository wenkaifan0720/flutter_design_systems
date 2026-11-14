// No icon falls back to a missing-glyph box. Every glyph a live page draws, through the gallery's own navigation at a
// phone's and a desktop's width, comes from a font the app bundles, and that font's character map holds its codepoint.
// A glyph from a font the build leaves out (Material's icons, when nothing asks for them) or a codepoint the bundled
// font lacks is the tofu box the web build would show.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/live.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/hearth.dart' show hearthScreens;
import 'gallery_support.dart' show loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;

/// The codepoints a TrueType font maps to a glyph other than .notdef, from its cmap's format 4 and 12 subtables.
Set<int> mappedCodepoints(ByteData font) {
  final tables = font.getUint16(4);
  int? cmap;
  for (var i = 0; i < tables; i++) {
    final record = 12 + i * 16;
    final tag = String.fromCharCodes([
      for (var j = 0; j < 4; j++) font.getUint8(record + j),
    ]);
    if (tag == 'cmap') cmap = font.getUint32(record + 8);
  }
  if (cmap == null) throw StateError('no cmap table');
  final mapped = <int>{};
  final subtables = font.getUint16(cmap + 2);
  for (var i = 0; i < subtables; i++) {
    final at = cmap + font.getUint32(cmap + 4 + i * 8 + 4);
    switch (font.getUint16(at)) {
      case 4:
        final segments = font.getUint16(at + 6) ~/ 2;
        final ends = at + 14, starts = ends + segments * 2 + 2;
        final deltas = starts + segments * 2, ranges = deltas + segments * 2;
        for (var s = 0; s < segments; s++) {
          final start = font.getUint16(starts + s * 2);
          final end = font.getUint16(ends + s * 2);
          final delta = font.getInt16(deltas + s * 2);
          final range = font.getUint16(ranges + s * 2);
          if (start == 0xFFFF) continue;
          for (var c = start; c <= end; c++) {
            var glyph = 0;
            if (range == 0) {
              glyph = (c + delta) & 0xFFFF;
            } else {
              final index = ranges + s * 2 + range + (c - start) * 2;
              glyph = font.getUint16(index);
              if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
            }
            if (glyph != 0) mapped.add(c);
          }
        }
      case 12:
        final groups = font.getUint32(at + 12);
        for (var g = 0; g < groups; g++) {
          final group = at + 16 + g * 12;
          final start = font.getUint32(group);
          final end = font.getUint32(group + 4);
          final first = font.getUint32(group + 8);
          for (var c = start; c <= end; c++) {
            if (first + (c - start) != 0) mapped.add(c);
          }
        }
    }
  }
  return mapped;
}

void main() {
  // Each bundled family's mapped codepoints, read once outside the test's fake clock: an asset read inside it never
  // completes.
  final fonts = <String, Set<int>>{};
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
    final manifest = (json.decode(
      await rootBundle.loadString('FontManifest.json'),
    ) as List<dynamic>).cast<Map<String, dynamic>>();
    for (final entry in manifest) {
      final mapped = <int>{};
      for (final font
          in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        mapped.addAll(
          mappedCodepoints(await rootBundle.load(font['asset'] as String)),
        );
      }
      fonts[entry['family'] as String] = mapped;
    }
  });

  testWidgets('every glyph on every live page is in a bundled font', (
    tester,
  ) async {
    Set<int>? codepoints(IconData icon) =>
        fonts[icon.fontPackage == null
            ? icon.fontFamily
            : 'packages/${icon.fontPackage}/${icon.fontFamily}'];

    final seen = <String, IconData>{};
    void collect(String where) {
      for (final icon in tester.widgetList<Icon>(
        find.byType(Icon, skipOffstage: false),
      )) {
        final data = icon.icon;
        if (data != null) {
          seen['$where U+${data.codePoint.toRadixString(16)}'] = data;
        }
      }
    }

    for (final width in [390.0, 1440.0]) {
      // The gallery's pages and each of Hearth's screens.
      for (final id in {
        for (final page in liveGalleryPages) page.id,
        for (final screen in hearthScreens) screen.id,
      }) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          GalleryApp(
            key: UniqueKey(),
            initialPage: id,
            initialCustomizing: true,
          ),
        );
        await settle(tester);
        collect('$id@$width');
      }
    }
    // The drawer is the phone's: open it at a phone's width.
    tester.view.physicalSize = const Size(390, 900);
    await tester.pumpWidget(GalleryApp(key: UniqueKey()));
    await settle(tester);
    await tester.tap(find.byKey(const Key('gallery-menu')));
    await settle(tester);
    collect('drawer');

    expect(seen, isNotEmpty);
    final missing = <String>[];
    for (final MapEntry(key: where, value: icon) in seen.entries) {
      final mapped = codepoints(icon);
      if (mapped == null) {
        missing.add(
          '$where: ${icon.fontPackage ?? ''}/${icon.fontFamily} is not bundled',
        );
      } else if (!mapped.contains(icon.codePoint)) {
        missing.add('$where: ${icon.fontFamily} has no glyph');
      }
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
  });
}
