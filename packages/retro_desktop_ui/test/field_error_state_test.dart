// An error that turns up while a field is in use changes its edge and its note, never the field under them: the editor
// keeps its words, its state and its focus, so the error is said on the field the reader is on.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);

  testWidgets(
    'a text field keeps its editor, its words and its focus when an error turns up and goes',
    (tester) async {
      final error = ValueNotifier<String?>(null);
      addTearDown(error.dispose);
      await tester.pumpWidget(
        retroDesktopApp(
          ValueListenableBuilder<String?>(
            valueListenable: error,
            builder: (context, value, _) =>
                RetroDesktopTextField(labelText: 'Email', errorText: value),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'sam@');
      await tester.pump();
      final editor = tester.state<EditableTextState>(find.byType(EditableText));
      for (final shown in const ['Enter an email address.', null]) {
        error.value = shown;
        await tester.pump();
        final now = tester.state<EditableTextState>(find.byType(EditableText));
        expect(
          identical(now, editor),
          isTrue,
          reason:
              'the error ${shown == null ? 'went' : 'came'}: the same editor',
        );
        expect(now.textEditingValue.text, 'sam@');
        expect(now.widget.focusNode.hasFocus, isTrue);
      }
    },
  );

  testWidgets('a date field keeps its face when an error turns up and goes', (
    tester,
  ) async {
    final error = ValueNotifier<String?>(null);
    addTearDown(error.dispose);
    await tester.pumpWidget(
      retroDesktopApp(
        ValueListenableBuilder<String?>(
          valueListenable: error,
          builder: (context, value, _) => RetroDesktopDateField(
            labelText: 'Started',
            value: null,
            errorText: value,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    final glyph = find.descendant(
      of: find.byType(RetroDesktopDateField),
      matching: find.byIcon(RetroDesktopGlyphs.calendar),
    );
    final before = tester.element(glyph);
    for (final shown in const ['Pick a day.', null]) {
      error.value = shown;
      await tester.pump();
      expect(
        identical(tester.element(glyph), before),
        isTrue,
        reason: 'the box under the edge is the same one',
      );
    }
  });
}
