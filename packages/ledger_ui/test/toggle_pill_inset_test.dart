// A toggle group's pill holds its words clear of its rules at any text size: larger text grows the pill (the acts
// page's "Category" at 200% sat 3.7 px from the foot in 0.6.0), held by ui_core_test's DesignFaceInsetCheck.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ui_core_test/ui_core_test.dart' show DesignFaceInsetCheck;

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

void main() {
  setUpAll(_loadFonts);
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'at ${scale}x text, the pills hold their words clear of their rules',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(390, 844);
        addTearDown(t.view.reset);
        await t.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, page) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: LedgerHost(brightness: Brightness.light, child: page!),
            ),
            home: Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LedgerToggleGroup<String>(
                  label: 'Columns',
                  multiSelectionEnabled: true,
                  emptySelectionAllowed: true,
                  options: const ['Time', 'Payee', 'Category'],
                  labelOf: (v) => v,
                  selected: const {'Payee'},
                  onSelectionChanged: (_) {},
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final report = await const DesignFaceInsetCheck(look: 'Ledger').check(
          t.element(find.byType(LedgerToggleGroup<String>)),
          runAsync: t.runAsync,
        );
        report.verify();
        // At the words' own size the pill keeps the source's 32.
        if (scale == 1) {
          final pill = find
              .ancestor(
                of: find.text('Time'),
                matching: find.byType(DecoratedBox),
              )
              .first;
          expect(t.getSize(pill).height, 32);
        }
      },
    );
  }
}
