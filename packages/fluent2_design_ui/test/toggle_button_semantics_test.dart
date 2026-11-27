// A toggle button stays a button: Fluent2IconButton with `selected` and
// Fluent2ToggleButton read as Flutter's IconButton(isSelected:) does, a
// button that is selected or not, never a switch.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (BuildContext context, Widget? page) =>
      Fluent2Host(brightness: Brightness.light, child: page!),
  home: Material(child: Center(child: child)),
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
    testWidgets('Fluent2IconButton(selected: $on) and '
        'Fluent2ToggleButton(value: $on) read as '
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
      // IconButton's name is its tooltip; the flags are what compare. Each
      // Fluent 2 button's node is found by its name: the widget's outermost
      // box is its tap target, which owns no node.
      expect(
        tester.getSemantics(find.byType(IconButton)),
        _toggleButton(selected: on),
      );

      await tester.pumpWidget(
        _host(
          Fluent2IconButton(
            Fluent2Icons.star,
            semanticLabel: 'Pin',
            selected: on,
            onPressed: () {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Pin')),
        _toggleButton(label: 'Pin', selected: on),
      );

      await tester.pumpWidget(
        _host(
          Fluent2ToggleButton(
            'Mic',
            value: on,
            icon: Fluent2Icons.mic,
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Mic')),
        _toggleButton(label: 'Mic', selected: on),
      );
    });
  }

  testWidgets('an ordinary Fluent2IconButton is a button with no selected '
      'state', (tester) async {
    await tester.pumpWidget(
      _host(
        Fluent2IconButton(
          Fluent2Icons.share,
          semanticLabel: 'Share',
          onPressed: () {},
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Share')),
      isSemantics(
        label: 'Share',
        isButton: true,
        hasSelectedState: false,
        hasToggledState: false,
      ),
    );
  });
}
