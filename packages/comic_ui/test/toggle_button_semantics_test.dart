// A toggle button stays a button: a password field's show and hide, and a
// ComicIconButton with `selected`, read as Flutter's IconButton(isSelected:)
// does, a button that is selected or not, never a switch.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

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

Future<void> _expectIconButton(WidgetTester tester, bool selected) async {
  await tester.pumpWidget(
    comicApp(
      Center(
        child: IconButton(
          isSelected: selected,
          tooltip: 'Pin',
          icon: const SizedBox.square(dimension: 24),
          onPressed: () {},
        ),
      ),
    ),
  );
  // IconButton's name is its tooltip; the flags are what compare.
  expect(
    tester.getSemantics(find.byType(IconButton)),
    _toggleButton(selected: selected),
  );
}

void main() {
  testWidgets('a password field\'s show and hide reads as '
      'IconButton(isSelected:)', (tester) async {
    for (final shown in [false, true]) {
      await _expectIconButton(tester, shown);
    }

    await tester.pumpWidget(
      comicApp(const Center(child: ComicPasswordField(labelText: 'Password'))),
    );
    // Hidden: the button shows it, and is not selected.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Show password')),
      _toggleButton(label: 'Show password', selected: false),
    );
    await tester.tap(find.bySemanticsLabel('Show password'));
    await tester.pump();
    // Shown: the button hides it, and is selected.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Hide password')),
      _toggleButton(label: 'Hide password', selected: true),
    );
  });

  testWidgets('ComicIconButton(selected: true) reads as '
      'IconButton(isSelected: true)', (tester) async {
    await _expectIconButton(tester, true);
    await tester.pumpWidget(
      comicApp(
        Center(
          child: ComicIconButton(
            ComicGlyphs.bell,
            label: 'Pin',
            isSelected: true,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Pin')),
      _toggleButton(label: 'Pin', selected: true),
    );
  });
}
