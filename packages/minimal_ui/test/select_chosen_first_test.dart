// A select opened from the keys lands on its chosen option: with its third
// option chosen, Enter opens it and that option holds the focus, in the menu
// and in the sheet.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

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
  setUpAll(minimalLoadFonts);
  for (final presentation in MinimalSelectPresentation.values) {
    testWidgets('a ${presentation.name} select opened from the keys focuses '
        'its chosen option', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => MinimalHost(
            light: MinimalThemeData.preset('standard', Brightness.light),
            dark: MinimalThemeData.preset('standard', Brightness.dark),
            brightness: Brightness.light,
            child: app!,
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: MinimalSelect<int>(
                labelText: 'Repeat every',
                autofocus: true,
                presentation: presentation,
                value: 3,
                options: const [
                  MinimalSelectOption(1, 'One day'),
                  MinimalSelectOption(2, 'Two days'),
                  MinimalSelectOption(3, 'Three days'),
                  MinimalSelectOption(4, 'Four days'),
                  MinimalSelectOption(5, 'Five days'),
                ],
                onChanged: (_) {},
              ),
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
}
