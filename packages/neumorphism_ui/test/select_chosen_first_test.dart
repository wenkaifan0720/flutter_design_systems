// A select opened from the keys lands on its chosen option: with its third
// option chosen, Enter opens it and that option holds the focus.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

// Whether the focus is on the option that reads [label].
bool _focusOn(String label) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  var found = false;
  void visit(Element element) {
    final widget = element.widget;
    if ((widget is Text && widget.data == label) ||
        (widget is RichText && widget.text.toPlainText() == label)) {
      found = true;
    }
    if (!found) element.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
  return found;
}

void main() {
  setUpAll(loadNeumorphicFonts);
  testWidgets('a select opened from the keys focuses its chosen option', (
    tester,
  ) async {
    await tester.pumpWidget(
      neumorphicApp(
        Padding(
          padding: const EdgeInsets.all(24),
          child: NeumorphicSelect<int>(
            labelText: 'Repeat every',
            autofocus: true,
            value: 3,
            options: const [
              NeumorphicMenuItem(1, 'One day'),
              NeumorphicMenuItem(2, 'Two days'),
              NeumorphicMenuItem(3, 'Three days'),
              NeumorphicMenuItem(4, 'Four days'),
              NeumorphicMenuItem(5, 'Five days'),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_focusOn('Three days'), isTrue, reason: 'the chosen option');
  });
}
