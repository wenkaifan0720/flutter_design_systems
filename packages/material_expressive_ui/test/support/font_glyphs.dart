/// What a bundled face draws: the codepoints with an outline in one of the
/// fonts under `assets/fonts/`, read from the file itself. icons_test checks
/// every symbol against the Symbols subset with it, and the example's
/// contract every character on a live page against the text faces.
library;

import 'package:flutter/services.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

/// [file] under `assets/fonts/`, from the package that bundles it.
Future<ByteData> loadBundledFont(String file) => rootBundle.load(
  expressiveFontPackage == null
      ? 'assets/fonts/$file'
      : 'packages/$expressiveFontPackage/assets/fonts/$file',
);

/// The glyph each codepoint of [font] maps to (its cmap's format 4 and 12
/// subtables), keeping only glyphs with an outline (glyf/loca): what a
/// codepoint draws instead of the missing-glyph box.
Map<int, int> outlinedGlyphs(ByteData font) {
  int table(String tag) {
    final code = tag.codeUnits.fold(0, (a, b) => a << 8 | b);
    for (var i = 0; i < font.getUint16(4); i++) {
      if (font.getUint32(12 + 16 * i) == code) {
        return font.getUint32(12 + 16 * i + 8);
      }
    }
    throw StateError('no $tag table');
  }

  final cmap = table('cmap');
  final glyphs = <int, int>{};
  for (var i = 0; i < font.getUint16(cmap + 2); i++) {
    final sub = cmap + font.getUint32(cmap + 4 + 8 * i + 4);
    switch (font.getUint16(sub)) {
      case 4:
        final segments = font.getUint16(sub + 6);
        final ends = sub + 14;
        final starts = ends + segments + 2;
        final deltas = starts + segments;
        final offsets = deltas + segments;
        for (var s = 0; s < segments; s += 2) {
          final start = font.getUint16(starts + s);
          final delta = font.getInt16(deltas + s);
          final offset = font.getUint16(offsets + s);
          for (var u = start; u <= font.getUint16(ends + s); u++) {
            if (u == 0xffff) break;
            final raw = offset == 0
                ? u
                : font.getUint16(offsets + s + offset + 2 * (u - start));
            if (offset != 0 && raw == 0) continue;
            glyphs.putIfAbsent(u, () => (raw + delta) & 0xffff);
          }
        }
      case 12:
        for (var g = 0; g < font.getUint32(sub + 12); g++) {
          final group = sub + 16 + 12 * g;
          final start = font.getUint32(group);
          for (var u = start; u <= font.getUint32(group + 4); u++) {
            glyphs.putIfAbsent(u, () => font.getUint32(group + 8) + u - start);
          }
        }
    }
  }
  final long = font.getInt16(table('head') + 50) == 1;
  final loca = table('loca');
  int at(int glyph) => long
      ? font.getUint32(loca + 4 * glyph)
      : 2 * font.getUint16(loca + 2 * glyph);
  glyphs.removeWhere((_, glyph) => glyph == 0 || at(glyph + 1) == at(glyph));
  return glyphs;
}
