// A list opened from the keys puts the focus on what is chosen: a select's
// chosen option, a date picker's chosen day.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Widget _app(Widget home, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      builder: (context, app) =>
          KeycapHost(brightness: brightness, child: app!),
      home: home,
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets("a select opened from the keys focuses its chosen option", (
    tester,
  ) async {
    _phone(tester);
    final select = KeycapSelect<int>(
      items: [
        for (var i = 1; i <= 12; i++)
          KeycapSelectItem(value: i, label: 'Every $i days'),
      ],
      value: 9,
      onChanged: (_) {},
    );
    await tester.pumpWidget(
      _app(
        Align(
          alignment: Alignment.topCenter,
          child: Padding(padding: const EdgeInsets.all(24), child: select),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Every 1 days'), findsOneWidget, reason: 'the list opens');
    final focused = FocusManager.instance.primaryFocus!.context!;
    final at = find.byElementPredicate((e) => identical(e, focused));
    expect(
      tester.getRect(at).overlaps(tester.getRect(find.byWidget(select))),
      isFalse,
      reason: 'the focus stayed on the select',
    );
    expect(
      find.descendant(of: at, matching: find.text('Every 9 days')),
      findsOneWidget,
    );
    // It shows: the list keeps the chosen option in view.
    final row = tester.getRect(
      find.descendant(of: at, matching: find.text('Every 9 days')),
    );
    expect(row.bottom, lessThanOrEqualTo(844));
  });

  testWidgets("a date picker opened from the keys focuses its chosen day", (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: KeycapDatePicker(
              value: DateTime(2026, 11, 20),
              firstDate: DateTime(2026),
              lastDate: DateTime(2027, 12, 31),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(KeycapCalendar), findsOneWidget, reason: 'it opens');
    final focused = FocusManager.instance.primaryFocus!.context!;
    final at = find.byElementPredicate((e) => identical(e, focused));
    expect(find.descendant(of: at, matching: find.text('20')), findsOneWidget);
  });
}
