// A toggle button stays a button: MinimalIconButton with `selected` reads as
// Flutter's IconButton(isSelected:) does, a button that is selected or not,
// never a switch or a checkbox.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: MinimalTheme(
    data: MinimalThemeData.standard(),
    child: Material(child: Center(child: child)),
  ),
);

Matcher _toggleButton({String? label, required bool selected}) => isSemantics(
  label: label,
  isButton: true,
  hasSelectedState: true,
  isSelected: selected,
  hasToggledState: false,
  hasCheckedState: false,
  hasEnabledState: true,
  isEnabled: true,
  isFocusable: true,
  hasTapAction: true,
  hasFocusAction: true,
);

void main() {
  for (final on in [true, false]) {
    testWidgets('MinimalIconButton(selected: $on) reads as '
        'IconButton(isSelected: $on)', (tester) async {
      await tester.pumpWidget(
        _host(
          IconButton(
            isSelected: on,
            tooltip: 'Pin',
            icon: const SizedBox.square(dimension: 24),
            onPressed: () {},
          ),
        ),
      );
      // IconButton's name is its tooltip; the flags are what compare.
      expect(
        tester.getSemantics(find.byType(IconButton)),
        _toggleButton(selected: on),
      );

      await tester.pumpWidget(
        _host(
          MinimalIconButton(
            LucideIcons.pin,
            semanticLabel: 'Pin',
            selected: on,
            onPressed: () {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(MinimalIconButton)),
        _toggleButton(label: 'Pin', selected: on),
      );
    });
  }

  testWidgets('an ordinary MinimalIconButton is a button with no selected '
      'state', (tester) async {
    await tester.pumpWidget(
      _host(
        MinimalIconButton(
          LucideIcons.info,
          semanticLabel: 'Help',
          onPressed: () {},
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(MinimalIconButton)),
      isSemantics(
        label: 'Help',
        isButton: true,
        hasSelectedState: false,
        hasToggledState: false,
      ),
    );
  });
}
