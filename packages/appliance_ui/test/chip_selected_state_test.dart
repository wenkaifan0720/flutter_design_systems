// A chip that is selected but takes no presses (no onSelected) keeps
// showing that it is selected, as a disabled FilterChip keeps its check:
// it stands latched down like a selected chip turned off, and a screen
// reader hears a selected button that is disabled, as it does the
// FilterChip.
import 'dart:ui' show SemanticsFlags, Tristate;

import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart'
    show FilterChip, MaterialApp, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(WidgetTester tester, List<Widget> chips) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Scaffold(body: Column(children: chips)),
    ),
  );
  await tester.pumpAndSettle();
}

ApplianceFace _face(WidgetTester tester, Key chip) => tester
    .widget<AnimatedApplianceSurface>(
      find
          .descendant(
            of: find.byKey(chip),
            matching: find.byType(AnimatedApplianceSurface),
          )
          .first,
    )
    .face;

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('a selected chip with no onSelected stands latched down, '
      'as a selected chip turned off does', (tester) async {
    const held = ValueKey('held');
    const off = ValueKey('off');
    const plain = ValueKey('plain');
    await _show(tester, [
      const ApplianceChip('Vegan', key: held, selected: true),
      ApplianceChip(
        'Vegan',
        key: off,
        selected: true,
        enabled: false,
        onSelected: (_) {},
      ),
      const ApplianceChip('Vegan', key: plain),
    ]);
    expect(_face(tester, held), _face(tester, off));
    expect(_face(tester, held), isNot(_face(tester, plain)));
  });

  testWidgets('a selected chip with no onSelected reads as a disabled '
      'FilterChip does: a button, selected, not enabled', (tester) async {
    final semantics = tester.ensureSemantics();
    await _show(tester, [
      const FilterChip(
        label: Text('Flutter'),
        selected: true,
        onSelected: null,
      ),
      const ApplianceChip('Vegan', selected: true),
    ]);
    SemanticsFlags flags(String label) => tester
        .getSemantics(find.bySemanticsLabel(label))
        .getSemanticsData()
        .flagsCollection;
    final flutter = flags('Flutter');
    final appliance = flags('Vegan');
    expect(appliance.isSelected, Tristate.isTrue);
    expect(appliance.isSelected, flutter.isSelected);
    expect(appliance.isButton, flutter.isButton);
    expect(appliance.isEnabled, flutter.isEnabled);
    semantics.dispose();
  });
}
