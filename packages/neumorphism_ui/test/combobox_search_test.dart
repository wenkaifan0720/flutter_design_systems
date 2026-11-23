// The combobox's and the multi-select's search on ui_core: while it runs the list says it is loading; when it fails
// the list says so and offers Try again, which a tap or the keys (Down, then Enter) run, the focus staying in the field.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

const _cities = ['Lisbon', 'London', 'Lyon'];

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final multi in [false, true]) {
    final name = multi ? 'multi-select' : 'combobox';
    Widget field(DesignOptionSearchFn search) => neumorphicApp(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 320,
          child: multi
              ? NeumorphicMultiSelect<String>(
                  labelText: 'Cities',
                  values: const [],
                  onChanged: (_) {},
                  search: search,
                )
              : NeumorphicCombobox<String>(
                  labelText: 'City',
                  options: const [],
                  onSelected: (_) {},
                  search: search,
                ),
        ),
      ),
    );

    testWidgets('$name: loading, then the options found', (tester) async {
      final answer = Completer<Iterable<String>>();
      await tester.pumpWidget(field((query) => answer.future));
      await tester.enterText(find.byType(EditableText), 'L');
      await tester.pump();
      expect(find.text('Loading'), findsOneWidget);
      answer.complete(_cities);
      await tester.pumpAndSettle();
      expect(find.text('Loading'), findsNothing);
      expect(find.text('Lyon'), findsOneWidget);
    });

    testWidgets(
      '$name: a failed search offers Try again, by tap or by the keys',
      (tester) async {
        var calls = 0;
        var fail = true;
        await tester.pumpWidget(
          field((query) async {
            calls++;
            if (fail) throw StateError('offline');
            return _cities;
          }),
        );
        await tester.enterText(find.byType(EditableText), 'L');
        await tester.pumpAndSettle();
        expect(find.text('Try again'), findsOneWidget);
        final before = calls;
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(calls, before + 1, reason: 'a tap searches again');
        expect(find.text('Try again'), findsOneWidget);
        fail = false;
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        // Enter in the field: the text input's done action.
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text('Lisbon'), findsOneWidget);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
          reason: 'the focus stays in the field',
        );
      },
    );
  }
}

typedef DesignOptionSearchFn = FutureOr<Iterable<String>> Function(
  String query,
);
