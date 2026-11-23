/// A toggle button reads as Flutter's `IconButton(isSelected:)` reads: a
/// button that is selected or not, never a switch.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

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

void main() {
  testWidgets('an icon toggle button reads as IconButton(isSelected:)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => ExpressiveHost(
          theme: _theme,
          brightness: Brightness.light,
          child: app!,
        ),
        home: Material(
          child: Row(
            children: [
              IconButton(
                isSelected: true,
                onPressed: () {},
                icon: const Icon(Icons.star, semanticLabel: 'Flutter'),
              ),
              for (final on in [true, false])
                ExpressiveIconToggleButton(
                  ExpressiveSymbols.gridView,
                  value: on,
                  onChanged: (_) {},
                  semanticLabel: on ? 'Grid on' : 'Grid off',
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Flutter')),
      _toggleButton('Flutter', selected: true),
      reason: "Flutter's own toggle button, the reading to match",
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Grid on')),
      _toggleButton('Grid on', selected: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Grid off')),
      _toggleButton('Grid off', selected: false),
    );
    handle.dispose();
  });

  testWidgets('a toggle button with a label reads as a selected button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var on = true;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => ExpressiveHost(
          theme: _theme,
          brightness: Brightness.light,
          child: app!,
        ),
        home: Material(
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) => ExpressiveToggleButton(
                label: 'Bold',
                value: on,
                onChanged: (value) => setState(() => on = value),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Bold')),
      _toggleButton('Bold', selected: true),
    );
    await tester.tap(find.text('Bold'));
    await tester.pumpAndSettle();
    expect(on, isFalse);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Bold')),
      _toggleButton('Bold', selected: false),
    );
    handle.dispose();
  });
}
