// The everyday parts in each of Ledger's presets, by day and by lamplight,
// held to golden pictures: a change to a token or a part's drawing shows up
// as a changed picture. Recorded on macOS; elsewhere, `--exclude-tags goldens`.
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : ledgerFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// The inventory rows drawn: the parts every screen is made of.
const List<String> _rows = [
  'Button',
  'IconButton',
  'TextField',
  'Select',
  'Checkbox',
  'Switch',
  'SegmentedButton',
  'Chip',
  'Badge',
  'Banner',
  'ListTile',
];

/// Why the comparisons skip themselves, or null when they run. The pictures stay in the repository this package is
/// generated from and its build lays them in test/goldens; a published copy goes without them and compares nothing,
/// though `--update-goldens` still records them.
final String? _noPictures =
    autoUpdateGoldenFiles || Directory('test/goldens/theme').existsSync()
    ? null
    : 'no golden pictures in test/goldens/theme: they stay in the repository Ledger is generated from';

void main() {
  group('theme', _presets, skip: _noPictures);
}

void _presets() {
  setUpAll(_loadFonts);

  final entries = [
    for (final row in _rows)
      ledgerInventory.entries.firstWhere(
        (e) => e.row == row && e.builder != null,
      ),
  ];

  for (final id in [for (final p in LedgerThemeData.palettes) p.id]) {
    for (final brightness in Brightness.values) {
      testWidgets('$id ${brightness.name}', (t) async {
        t.view.physicalSize = const Size(390 * 2, 1600 * 2);
        t.view.devicePixelRatio = 2;
        addTearDown(t.view.reset);
        final theme = LedgerThemeData.preset(id, brightness);
        const panel = Key('panel');
        await t.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) =>
                LedgerTheme(data: theme, child: child!),
            home: Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                key: panel,
                child: ColoredBox(
                  color: theme.background,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final e in entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Builder(builder: e.builder!),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(t.takeException(), isNull);
        await expectLater(
          find.byKey(panel),
          matchesGoldenFile('goldens/theme/${id}_${brightness.name}.png'),
        );
      }, tags: 'goldens');
    }
  }
}
