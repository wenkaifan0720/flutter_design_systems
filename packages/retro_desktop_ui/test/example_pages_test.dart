// The example app is where a reader finds the parts, so it has to hold all of them. Every widget the package exports is
// built by at least one of its live pages, at a phone's width or a desk's; and every icon those pages draw is a glyph the
// bundled icon face has, so none falls back to an empty box.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The pages are the example app's; a test reads them from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

/// Exported widgets only an action raises, each with where the example raises it. Everything else must be on a page.
const onDemand = <String, String>{
  'RetroDesktopTextContextMenu': "a field's long press or right click",
  'RetroDesktopShell':
      "the router adapter an app's shell wraps around its routes",
  'RetroDesktopDialogAction': "a dialog's buttons: Dialogs and sheets, Before closing, Review changes (proven below)",
};

/// Every public widget class the barrel exports, from the source, so a new export fails until a page builds it.
Set<String> exportedWidgets() {
  final barrel = [
    File('lib/src/retro_desktop.dart'),
    File('lib/src/retro_desktop.dart'),
  ].firstWhere((file) => file.existsSync());
  final classes = <String, String>{};
  final hidden = <String>{};
  for (final export in RegExp(
    r"export '([^']+)'([^;]*);",
    dotAll: true,
  ).allMatches(barrel.readAsStringSync())) {
    final uri = export[1]!;
    if (uri.contains(':')) continue;
    if (export[2]!.contains('hide')) {
      hidden.addAll(
        export[2]!.split('hide').last.split(',').map((s) => s.trim()),
      );
    }
    final source = File('${barrel.parent.path}/$uri').readAsStringSync();
    for (final item in RegExp(
      r'^class ((?:Animated)?RetroDesktop\w+)(?:<[^\n]+?>)?\s+extends\s+(\w+)',
      multiLine: true,
    ).allMatches(source)) {
      classes[item[1]!] = item[2]!;
    }
  }
  bool widget(String type) =>
      type.endsWith('Widget') ||
      (classes.containsKey(type) && widget(classes[type]!));
  return {
    for (final entry in classes.entries)
      if (!hidden.contains(entry.key) && widget(entry.value)) entry.key,
  };
}

/// The code points a TrueType face maps to a glyph other than .notdef, read from its cmap (formats 4 and 12).
Set<int> mappedCodePoints(ByteData d) {
  int? cmap;
  for (var i = 0; i < d.getUint16(4); i++) {
    final record = 12 + 16 * i;
    if (String.fromCharCodes([
          for (var k = 0; k < 4; k++) d.getUint8(record + k),
        ]) ==
        'cmap') {
      cmap = d.getUint32(record + 8);
    }
  }
  if (cmap == null) return const {};
  final out = <int>{};
  for (var i = 0; i < d.getUint16(cmap + 2); i++) {
    final at = cmap + d.getUint32(cmap + 4 + 8 * i + 4);
    switch (d.getUint16(at)) {
      case 4:
        final segments = d.getUint16(at + 6) ~/ 2;
        final ends = at + 14;
        final starts = ends + 2 * segments + 2;
        final deltas = starts + 2 * segments;
        final ranges = deltas + 2 * segments;
        for (var s = 0; s < segments; s++) {
          final end = d.getUint16(ends + 2 * s);
          final start = d.getUint16(starts + 2 * s);
          final delta = d.getInt16(deltas + 2 * s);
          final range = d.getUint16(ranges + 2 * s);
          for (var c = start; c <= end && c != 0xFFFF; c++) {
            var glyph = 0;
            if (range == 0) {
              glyph = (c + delta) & 0xFFFF;
            } else {
              final g = d.getUint16(ranges + 2 * s + range + 2 * (c - start));
              glyph = g == 0 ? 0 : (g + delta) & 0xFFFF;
            }
            if (glyph != 0) out.add(c);
          }
        }
      case 12:
        for (var g = 0; g < d.getUint32(at + 12); g++) {
          final r = at + 16 + 12 * g;
          final start = d.getUint32(r), end = d.getUint32(r + 4);
          final first = d.getUint32(r + 8);
          for (var c = start; c <= end; c++) {
            if (first + (c - start) != 0) out.add(c);
          }
        }
    }
  }
  return out;
}

void main() {
  setUpAll(() async {
    await loadRetroDesktopFonts();
    await loadBundledFonts();
  });

  test('the pages carry plain names, in the order a reader looks', () {
    expect(examplePages.map((p) => p.name).take(16), [
      'Overview',
      'Buttons',
      'Text fields',
      'Selection',
      'Pickers',
      'Navigation',
      'Lists and tables',
      'Cards and media',
      'Dialogs and sheets',
      'Feedback',
      'Charts',
      'All components',
      'Type and colour',
      'Form',
      'Settings',
      'List',
    ]);
    expect(
      examplePages.map((p) => p.name).toSet(),
      hasLength(examplePages.length),
    );
  });

  testWidgets(
    'every exported widget is live on a page, and every icon has its glyph',
    (tester) async {
      final lucide = mappedCodePoints(
        await rootBundle.load(
          'packages/lucide_icons_flutter/assets/lucide.ttf',
        ),
      );
      expect(lucide, isNotEmpty, reason: 'The icon face has no cmap.');
      final built = <String>{};
      final tofu = <String>{};
      final drawn = <int>{};
      for (final page in examplePages) {
        for (final width in [galleryWidth, 1440.0]) {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 900);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            KeyedSubtree(
              key: ValueKey('${page.name}/$width'),
              child: page.build(Brightness.light),
            ),
          );
          await settle(tester);
          for (final w in tester.allWidgets) {
            built.add(w.runtimeType.toString().split('<').first);
            if (w is Icon && w.icon != null) {
              final icon = w.icon!;
              drawn.add(icon.codePoint);
              final ours =
                  icon.fontFamily == 'Lucide' &&
                  icon.fontPackage == 'lucide_icons_flutter';
              if (!ours || !lucide.contains(icon.codePoint)) {
                tofu.add(
                  '${page.name}: U+${icon.codePoint.toRadixString(16)} '
                  'in ${icon.fontPackage}/${icon.fontFamily}',
                );
              }
            }
          }
        }
      }
      final missing = exportedWidgets()
          .difference(built)
          .difference(onDemand.keys.toSet());
      expect(
        missing,
        isEmpty,
        reason:
            'Exported but on no live page: ${(missing.toList()..sort()).join(', ')}',
      );
      expect(tofu, isEmpty, reason: 'Icons with no glyph: ${tofu.join('; ')}');
      // The web build subsets the icon face to the glyphs its code names; the
      // build's own check reads this list against the subset it shipped.
      final out = Platform.environment['RETRO_ICONS_OUT'];
      if (out != null) {
        File(out).writeAsStringSync('${(drawn.toList()..sort()).join('\n')}\n');
      }
    },
  );

  testWidgets("a dialog's actions are one tap away on Dialogs and sheets", (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    final page = examplePages.firstWhere((p) => p.name == 'Dialogs and sheets');
    await tester.pumpWidget(page.build(Brightness.light));
    await settle(tester);
    final open = find.text('Review changes');
    await tester.ensureVisible(open);
    await settle(tester);
    await tester.tap(open);
    await settle(tester);
    expect(
      find.byWidgetPredicate(
        (w) => w.runtimeType.toString().startsWith('RetroDesktopDialogAction'),
      ),
      findsNWidgets(2),
    );
  });
}
