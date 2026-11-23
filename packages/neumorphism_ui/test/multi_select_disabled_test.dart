// A multi-select with no onChanged is out of use, as every Flutter control with a null callback is: its chips show
// without a ✕, its field takes no focus and no typing, and no list opens.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

Widget _sized(Widget child) =>
    neumorphicApp(Center(child: SizedBox(width: 320, child: child)));

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadNeumorphicGlyphs();
  });

  testWidgets('with onChanged, each chip has its ✕', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _sized(
        NeumorphicMultiSelect<String>(
          labelText: 'Genres',
          values: const ['Noir'],
          options: const ['Noir', 'Western'],
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Remove Noir'), findsWidgets);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    semantics.dispose();
  });

  testWidgets(
    'with no onChanged, its chips have no ✕, its field takes no focus, and no list opens',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _sized(
          const NeumorphicMultiSelect<String>(
            labelText: 'Genres',
            values: ['Noir'],
            options: ['Noir', 'Western'],
            onChanged: null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Noir'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove Noir'), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(
        tester
            .widget<NeumorphicFieldBox>(find.byType(NeumorphicFieldBox))
            .states,
        contains(WidgetState.disabled),
      );
      await tester.tap(find.byType(EditableText), warnIfMissed: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
      expect(find.text('Western'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets('taking onChanged away puts a field in use out of use', (
    tester,
  ) async {
    var genres = const ['Noir'];
    Widget field(ValueChanged<List<String>>? onChanged) => _sized(
      NeumorphicMultiSelect<String>(
        labelText: 'Genres',
        values: genres,
        options: const ['Noir', 'Western'],
        onChanged: onChanged,
      ),
    );
    await tester.pumpWidget(field((next) => genres = next));
    await tester.showKeyboard(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    await tester.pumpWidget(field(null));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
    expect(find.text('Western'), findsNothing);
    expect(genres, ['Noir']);
  });
}
