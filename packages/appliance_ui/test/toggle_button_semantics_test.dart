// A key that latches reads as Flutter's IconButton(isSelected:) does: a
// button, selected while it is latched, not a switch. An icon key that
// latches, a chip and the password field's eye are each one.
import 'dart:ui' show SemanticsFlags, Tristate;

import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart'
    show IconButton, MaterialApp, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(applianceLoadFonts);

  for (final latched in [true, false]) {
    testWidgets('an icon key and a chip, ${latched ? '' : 'not '}latched, '
        'read as IconButton(isSelected: $latched) does', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) =>
              ApplianceHost(brightness: Brightness.light, child: app!),
          home: Scaffold(
            body: Column(
              children: [
                MergeSemantics(
                  child: Semantics(
                    label: 'Flutter toggle',
                    child: IconButton(
                      isSelected: latched,
                      onPressed: () {},
                      icon: const Icon(LucideIcons.heart),
                    ),
                  ),
                ),
                ApplianceIconButton(
                  icon: const Icon(LucideIcons.heart),
                  semanticLabel: 'Favourite',
                  selected: latched,
                  onPressed: () {},
                ),
                ApplianceChip(
                  'On offer',
                  selected: latched,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      SemanticsFlags flags(String label) => tester
          .getSemantics(find.bySemanticsLabel(label))
          .getSemanticsData()
          .flagsCollection;
      final flutter = flags('Flutter toggle');
      for (final label in ['Favourite', 'On offer']) {
        final appliance = flags(label);
        expect(appliance.isButton, isTrue, reason: label);
        expect(appliance.isButton, flutter.isButton, reason: label);
        expect(
          appliance.isSelected,
          latched ? Tristate.isTrue : Tristate.isFalse,
          reason: label,
        );
        expect(appliance.isSelected, flutter.isSelected, reason: label);
        expect(appliance.isToggled, Tristate.none, reason: '$label: a switch');
        expect(appliance.isToggled, flutter.isToggled, reason: label);
      }
      semantics.dispose();
    });
  }
}
