// No glyph falls back to a missing-glyph box: every Lucide icon the package and its example name exists in the Lucide
// font the package bundles. The icon names are read from the sources, their code points from the icon package's own
// declarations, and the font's character map from its `cmap` table, so a name whose code point the shipped font lacks
// (the web build drew one as a box) fails here.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// The icon package's directory, from the package config the test runs under: the package's own, or its pub
/// workspace's above it.
Directory _lucide() {
  var dir = Directory.current.absolute;
  var file = File('${dir.path}/.dart_tool/package_config.json');
  while (!file.existsSync() && dir.parent.path != dir.path) {
    dir = dir.parent;
    file = File('${dir.path}/.dart_tool/package_config.json');
  }
  final config = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  final entry = (config['packages'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .firstWhere((p) => p['name'] == 'lucide_icons_flutter');
  final root = entry['rootUri'] as String;
  final uri = Uri.parse(root);
  return Directory.fromUri(
    uri.isAbsolute ? uri : file.parent.absolute.uri.resolveUri(uri),
  );
}

/// The code points a TrueType font maps, from its format 4 and 12 `cmap` subtables.
Set<int> _cmap(ByteData f) {
  final tables = f.getUint16(4);
  var cmap = -1;
  for (var i = 0; i < tables; i++) {
    final at = 12 + 16 * i;
    final tag = String.fromCharCodes([
      for (var k = 0; k < 4; k++) f.getUint8(at + k),
    ]);
    if (tag == 'cmap') cmap = f.getUint32(at + 8);
  }
  expect(cmap, greaterThan(0), reason: 'the font has no cmap');
  final out = <int>{};
  final count = f.getUint16(cmap + 2);
  for (var i = 0; i < count; i++) {
    final sub = cmap + f.getUint32(cmap + 4 + 8 * i + 4);
    switch (f.getUint16(sub)) {
      case 4:
        final segs = f.getUint16(sub + 6) ~/ 2;
        final ends = sub + 14, starts = ends + 2 * segs + 2;
        final deltas = starts + 2 * segs, offsets = deltas + 2 * segs;
        for (var s = 0; s < segs; s++) {
          final end = f.getUint16(ends + 2 * s);
          final start = f.getUint16(starts + 2 * s);
          final delta = f.getInt16(deltas + 2 * s);
          final offset = f.getUint16(offsets + 2 * s);
          for (var c = start; c <= end && c != 0xFFFF; c++) {
            int glyph;
            if (offset == 0) {
              glyph = (c + delta) & 0xFFFF;
            } else {
              final at = offsets + 2 * s + offset + 2 * (c - start);
              final g = f.getUint16(at);
              glyph = g == 0 ? 0 : (g + delta) & 0xFFFF;
            }
            if (glyph != 0) out.add(c);
          }
        }
      case 12:
        final groups = f.getUint32(sub + 12);
        for (var g = 0; g < groups; g++) {
          final at = sub + 16 + 12 * g;
          final start = f.getUint32(at), end = f.getUint32(at + 4);
          final glyph = f.getUint32(at + 8);
          for (var c = start; c <= end; c++) {
            if (glyph + (c - start) != 0) out.add(c);
          }
        }
    }
  }
  return out;
}

void main() {
  test('every Lucide icon the package and its example name is in the bundled font', () {
    final lucide = _lucide();
    final declared = <String, int>{};
    for (final m
        in RegExp(
          r"static const IconData (\w+) = const IconData\((\d+),\s*fontFamily: 'Lucide',",
        ).allMatches(
          File('${lucide.path}/lib/lucide_icons.dart').readAsStringSync(),
        )) {
      declared[m[1]!] = int.parse(m[2]!);
    }
    expect(declared.length, greaterThan(1000));
    final font = File('${lucide.path}/assets/lucide.ttf').readAsBytesSync();
    final mapped = _cmap(ByteData.sublistView(Uint8List.fromList(font)));
    expect(mapped.length, greaterThan(1000));

    final used = <String, Set<String>>{};
    for (final dir in ['lib', 'example/lib']) {
      for (final file in Directory(
        dir,
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        for (final m in RegExp(
          r'LucideIcons\.(\w+)',
        ).allMatches(file.readAsStringSync())) {
          (used[m[1]!] ??= {}).add(file.path);
        }
      }
    }
    expect(used, isNotEmpty);
    final failures = <String>[];
    for (final MapEntry(key: name, value: files) in used.entries) {
      final code = declared[name];
      if (code == null) {
        failures.add(
          '$name: not a Lucide icon in this version (${files.join(', ')})',
        );
      } else if (!mapped.contains(code)) {
        failures.add(
          '$name (U+${code.toRadixString(16).toUpperCase()}): not in lucide.ttf (${files.join(', ')})',
        );
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
