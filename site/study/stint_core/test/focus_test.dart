import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';

void main() {
  late FocusNode field, key;

  Future<void> form(WidgetTester tester) async {
    field = FocusNode(debugLabel: 'field');
    key = FocusNode(debugLabel: 'key');
    addTearDown(field.dispose);
    addTearDown(key.dispose);
    final words = TextEditingController(text: 'Noor Haddad');
    addTearDown(words.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            EditableText(
              controller: words,
              focusNode: field,
              style: const TextStyle(),
              cursorColor: const Color(0xFF000000),
              backgroundCursorColor: const Color(0xFF808080),
            ),
            Focus(focusNode: key, child: const SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  testWidgets('A key that saved lets its focus go, and not back to the field', (
    tester,
  ) async {
    await form(tester);
    field.requestFocus();
    await tester.pump();
    key.requestFocus();
    await tester.pump();
    releaseSaveFocus();
    // The key is disabled as the draft comes clean.
    key.canRequestFocus = false;
    await tester.pump();
    expect(key.hasFocus, isFalse);
    expect(field.hasFocus, isFalse);
  });

  testWidgets('A field keeps its focus through a save', (tester) async {
    await form(tester);
    field.requestFocus();
    await tester.pump();
    releaseSaveFocus();
    await tester.pump();
    expect(field.hasPrimaryFocus, isTrue);
  });

  testWidgets('A save from the shortcut leaves focus where it is', (
    tester,
  ) async {
    await form(tester);
    key.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    releaseSaveFocus();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(key.hasPrimaryFocus, isTrue);
  });
}
