import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_ledger/stint_ledger.dart';

void main() {
  // Typed at a person's pace, a search that empties the list keeps its
  // field: the same input, focused, holding every key. (A field rebuilt on
  // another page, or whose node split when its clear key came, dropped
  // the keys on the web.)
  for (final width in [390.0, 1440.0]) {
    testWidgets('the Tasks search keeps its field as results empty at $width', (
      t,
    ) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Size(width, width < 600 ? 844 : 960);
      addTearDown(t.view.reset);
      final semantics = t.ensureSemantics();
      await t.pumpWidget(
        StintLedger(
          launch: const StintLaunch(place: Place.tasks),
          repository: StintRepository(),
        ),
      );
      await t.pumpAndSettle();
      final field = find.byType(EditableText).first;
      await t.tap(field);
      await t.pumpAndSettle();
      final input = t.state<EditableTextState>(field);
      for (final typed in ['z', 'zz', 'zzz']) {
        t.testTextInput.updateEditingValue(
          TextEditingValue(
            text: typed,
            selection: TextSelection.collapsed(offset: typed.length),
          ),
        );
        await t.pumpAndSettle();
        final now = t.state<EditableTextState>(find.byType(EditableText).first);
        expect(now, same(input));
        expect(now.widget.focusNode.hasFocus, isTrue);
        expect(now.widget.controller.text, typed);
      }
      expect(find.text(const StintWords().noMatches), findsOneWidget);
      semantics.dispose();
    });
  }
}
