// A key that latches reads as Flutter's IconButton(isSelected:) does: a
// button, selected while it is latched, not a switch.
import 'dart:ui' show SemanticsFlags, Tristate;

import 'package:material_ui/material_ui.dart'
    show IconButton, MaterialApp, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  setUpAll(glossLoadFonts);

  for (final latched in [true, false]) {
    testWidgets('an icon key, ${latched ? '' : 'not '}latched, reads as '
        'IconButton(isSelected: $latched) does', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) =>
              GlossHost(brightness: Brightness.light, child: app!),
          home: Scaffold(
            body: Column(
              children: [
                MergeSemantics(
                  child: Semantics(
                    label: 'Flutter toggle',
                    child: IconButton(
                      isSelected: latched,
                      onPressed: () {},
                      icon: const Icon(LucideIcons.star),
                    ),
                  ),
                ),
                GlossIconButton(
                  icon: const Icon(LucideIcons.star),
                  tooltip: 'Favourite',
                  selected: latched,
                  onPressed: () {},
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
      final gloss = flags('Favourite');
      expect(gloss.isButton, isTrue);
      expect(gloss.isButton, flutter.isButton);
      expect(gloss.isSelected, latched ? Tristate.isTrue : Tristate.isFalse);
      expect(gloss.isSelected, flutter.isSelected);
      expect(gloss.isToggled, Tristate.none, reason: 'not a switch');
      expect(gloss.isToggled, flutter.isToggled);
      semantics.dispose();
    });
  }
}
