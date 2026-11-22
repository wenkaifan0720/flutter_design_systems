// A combobox's options wear the keys' ring after a key, as a select's
// options do: a list a press opened marks its chosen option alone (its words
// in the accent's ink and a check), never with a ring that reads as the
// keys' place on it.
import 'package:clay_ui/clay_parts.dart' show ClayMenuRow;
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

/// The labels of the rows lit by the keys: [WidgetState.focused] reaches
/// them as a ring.
List<String> _ringed(WidgetTester tester) => [
  for (final e in find.byWidgetPredicate((w) => w is ClayMenuRow).evaluate())
    if ((e.widget as ClayMenuRow).states.contains(WidgetState.focused))
      (e.widget as ClayMenuRow).label,
];

void main() {
  setUpAll(clayLoadFonts);

  testWidgets('a combobox a press opened rings no option; a key brings the '
      'ring', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            ClayTheme(data: ClayThemeData.clay(Brightness.light), child: app!),
        home: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ClayCombobox<String>(
              label: 'Category',
              value: 'Mind',
              options: const ['Health', 'Mind', 'Home'],
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is ClayMenuRow), findsWidgets);
    expect(_ringed(tester), isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_ringed(tester), hasLength(1));
  });
}
