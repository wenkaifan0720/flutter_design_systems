// A toggle button reads as Flutter's `IconButton(isSelected:)` reads: a
// button that is selected or not, never a switch.
// ignore_for_file: avoid_relative_lib_imports
import 'package:material_ui/material_ui.dart'
    show Icon, IconButton, Icons, Material;
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';

Matcher _toggleButton(String label, {required bool selected}) => isSemantics(
  label: label,
  isButton: true,
  hasSelectedState: true,
  isSelected: selected,
  hasToggledState: false,
  hasCheckedState: false,
  hasEnabledState: true,
  isEnabled: true,
  hasTapAction: true,
);

Future<void> _show(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 1400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      home: Material(
        child: Align(alignment: Alignment.topCenter, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SemanticsNode _node(WidgetTester tester, Pattern label) =>
    tester.getSemantics(find.bySemanticsLabel(label));

void main() {
  testWidgets('a latching icon key and a chip read as '
      'IconButton(isSelected:)', (tester) async {
    final handle = tester.ensureSemantics();
    await _show(
      tester,
      Wrap(
        spacing: 8,
        children: [
          IconButton(
            isSelected: true,
            onPressed: () {},
            icon: const Icon(Icons.star, semanticLabel: 'Flutter'),
          ),
          for (final on in [true, false])
            KeycapIconButton(
              icon: const Icon(LucideIcons.bold),
              semanticLabel: on ? 'Bold on' : 'Bold off',
              selected: on,
              onPressed: () {},
            ),
          for (final on in [true, false])
            KeycapChip(
              on ? 'Vegan' : 'Spicy',
              selected: on,
              onSelected: (_) {},
            ),
        ],
      ),
    );
    expect(
      _node(tester, 'Flutter'),
      _toggleButton('Flutter', selected: true),
      reason: "Flutter's own toggle button, the reading to match",
    );
    expect(_node(tester, 'Bold on'), _toggleButton('Bold on', selected: true));
    expect(
      _node(tester, 'Bold off'),
      _toggleButton('Bold off', selected: false),
    );
    expect(_node(tester, 'Vegan'), _toggleButton('Vegan', selected: true));
    expect(_node(tester, 'Spicy'), _toggleButton('Spicy', selected: false));
    handle.dispose();
  });

  testWidgets("a password field's reveal key is a button, selected while "
      'the password shows', (tester) async {
    final handle = tester.ensureSemantics();
    await _show(
      tester,
      const SizedBox(width: 358, child: KeycapPasswordField(label: 'Password')),
    );
    final reveal = find.bySemanticsLabel(
      RegExp('password', caseSensitive: false),
    );
    SemanticsNode key() => tester.getSemantics(reveal.last);
    expect(key(), _toggleButton(key().label, selected: false));
    await tester.tap(reveal.last);
    await tester.pumpAndSettle();
    expect(key(), _toggleButton(key().label, selected: true));
    handle.dispose();
  });
}
