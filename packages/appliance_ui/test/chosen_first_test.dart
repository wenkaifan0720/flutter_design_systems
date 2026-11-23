// A select opened from the keys lands on its chosen option, and a date
// picker's calendar on its chosen day, so the keys go on from there.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(WidgetTester tester, Widget field) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(24), child: field),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// Whether the focus is on, or inside, what reads [label].
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
  setUpAll(applianceLoadFonts);

  testWidgets('a select with its third option chosen, opened from the keys, '
      'has that option focused', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    int? chosen;
    await _show(
      tester,
      ApplianceSelect<int>(
        labelText: 'Deliver every',
        focusNode: focus,
        value: 3,
        items: const [
          ApplianceSelectItem(value: 1, label: 'One week'),
          ApplianceSelectItem(value: 2, label: 'Two weeks'),
          ApplianceSelectItem(value: 3, label: 'Three weeks'),
          ApplianceSelectItem(value: 4, label: 'Four weeks'),
          ApplianceSelectItem(value: 5, label: 'Five weeks'),
        ],
        onChanged: (value) => chosen = value,
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(focus.hasPrimaryFocus, isFalse, reason: 'the focus left the field');
    expect(_focusOn('Three weeks'), isTrue, reason: 'the chosen option');
    // The keys go on from there: one down is the fourth.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, 4);
  });

  testWidgets('a date picker opened from the keys walks on from its chosen '
      'day', (tester) async {
    DateTime? picked;
    await _show(
      tester,
      ApplianceDatePicker(
        labelText: 'Delivery day',
        value: DateTime(2026, 11, 18),
        firstDate: DateTime(2026, 11, 1),
        lastDate: DateTime(2026, 12, 31),
        currentDate: DateTime(2026, 11, 10),
        onChanged: (day) => picked = day,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked, DateTime(2026, 11, 19), reason: 'the day after the chosen');
  });
}
