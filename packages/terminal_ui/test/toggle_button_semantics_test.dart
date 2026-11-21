// A toggle button stays a button: it reads as Flutter's
// IconButton(isSelected:) does, a button that is selected or not, never a
// switch. TermIconButton with `selected`, and the password field's show and
// hide.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: TermTheme(
    data: TermThemeData.dark(),
    child: Center(child: child),
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
  setUpAll(loadFaces);

  for (final on in [true, false]) {
    testWidgets('TermIconButton(selected: $on) reads as '
        'IconButton(isSelected: $on)', (t) async {
      await t.pumpWidget(
        _host(
          IconButton(
            isSelected: on,
            tooltip: 'pin',
            icon: const SizedBox.square(dimension: 24),
            onPressed: () {},
          ),
        ),
      );
      // IconButton's name is its tooltip; the flags are what compare.
      expect(
        t.getSemantics(find.byType(IconButton)),
        _toggleButton(selected: on),
      );

      await t.pumpWidget(
        _host(
          TermIconButton(
            glyph: '*',
            semanticLabel: 'pin',
            selected: on,
            onPressed: () {},
          ),
        ),
      );
      expect(
        t.getSemantics(find.byType(TermIconButton)),
        _toggleButton(label: 'pin', selected: on),
      );
    });
  }

  testWidgets('an ordinary TermIconButton is a button with no selected state', (
    t,
  ) async {
    await t.pumpWidget(
      _host(
        TermIconButton(glyph: '?', semanticLabel: 'help', onPressed: () {}),
      ),
    );
    expect(
      t.getSemantics(find.byType(TermIconButton)),
      isSemantics(
        label: 'help',
        isButton: true,
        hasSelectedState: false,
        hasToggledState: false,
      ),
    );
  });

  testWidgets("the password field's reveal is a button, selected while the "
      'password shows', (t) async {
    final token = TextEditingController(text: 'hunter2');
    addTearDown(token.dispose);
    await t.pumpWidget(
      _host(
        SizedBox(
          width: 400,
          child: TermPasswordField(labelText: 'token', controller: token),
        ),
      ),
    );
    final reveal = find.bySemanticsLabel(
      RegExp('password', caseSensitive: false),
    );
    expect(
      t.getSemantics(reveal.last),
      isSemantics(
        isButton: true,
        hasSelectedState: true,
        isSelected: false,
        hasToggledState: false,
      ),
    );
    await t.tap(find.text('show'));
    await t.pumpAndSettle();
    expect(
      t.getSemantics(reveal.last),
      isSemantics(
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasToggledState: false,
      ),
    );
  });
}
