// A pill of a toggle group of any number reads as Flutter's
// IconButton(isSelected:) does: a button, selected while it is on, not a
// switch.
import 'dart:ui' show SemanticsFlags, Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('a pill of a toggle group of any number reads as '
      'IconButton(isSelected:) does', (t) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(
      MaterialApp(
        builder: (context, app) => LedgerHost(child: app!),
        home: Scaffold(
          body: Column(
            children: [
              for (final on in [true, false])
                MergeSemantics(
                  child: Semantics(
                    label: 'Flutter ${on ? 'on' : 'off'}',
                    child: IconButton(
                      isSelected: on,
                      onPressed: () {},
                      icon: const Icon(LucideIcons.columns3),
                    ),
                  ),
                ),
              LedgerToggleGroup<String>(
                semanticLabel: 'Columns',
                options: const ['Date', 'Payee'],
                labelOf: (c) => c,
                multiSelectionEnabled: true,
                selected: const {'Date'},
                onSelectionChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    SemanticsFlags flags(String label) => t
        .getSemantics(find.bySemanticsLabel(label))
        .getSemanticsData()
        .flagsCollection;
    for (final (pill, flutter, on) in [
      ('Date', 'Flutter on', true),
      ('Payee', 'Flutter off', false),
    ]) {
      final ledger = flags(pill);
      final material = flags(flutter);
      expect(ledger.isButton, isTrue, reason: pill);
      expect(ledger.isButton, material.isButton, reason: pill);
      expect(
        ledger.isSelected,
        on ? Tristate.isTrue : Tristate.isFalse,
        reason: pill,
      );
      expect(ledger.isSelected, material.isSelected, reason: pill);
      expect(ledger.isToggled, Tristate.none, reason: '$pill: not a switch');
      expect(ledger.isToggled, material.isToggled, reason: pill);
    }
    semantics.dispose();
  });
}
