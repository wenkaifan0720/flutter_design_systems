// A list opens with the keys on what is chosen, from its first frame: a
// select's chosen option; a date field's calendar, its cursor on the chosen
// day. No frame shows the keys elsewhere before they move.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

Widget _app(Widget page) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => TermTheme(data: TermThemeData.dark(), child: app!),
  home: Align(
    alignment: Alignment.topCenter,
    child: SizedBox(width: 360, child: page),
  ),
);

// The words of the row or day holding the keyboard's focus.
String? _focused() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  String? found;
  void visit(Element e) {
    if (found != null) return;
    final w = e.widget;
    if (w is Text && (w.data?.trim().isNotEmpty ?? false)) {
      found = w.data;
    } else {
      e.visitChildren(visit);
    }
  }

  visit(context as Element);
  return found;
}

void main() {
  setUpAll(loadFaces);

  testWidgets("a select opened from the keys has its third option, the chosen "
      "one, focused from the list's first frame", (tester) async {
    await tester.pumpWidget(
      _app(
        TermSelect<String>(
          labelText: 'environment',
          value: 'production',
          items: const [
            TermSelectItem(value: 'staging', label: 'staging'),
            TermSelectItem(value: 'canary', label: 'canary'),
            TermSelectItem(value: 'production', label: 'production'),
          ],
          onChanged: (_) {},
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final seen = <String?>[];
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    for (var k = 0; k < 12; k++) {
      await tester.pump(const Duration(milliseconds: 16));
      seen.add(_focused());
    }
    expect(find.text('canary'), findsOneWidget, reason: 'the list is open');
    expect(seen.toSet(), {'production'}, reason: 'frame by frame: $seen');
  });

  testWidgets("a date field opened from the keys has its calendar, the cursor "
      "on the chosen day, focused from the calendar's first frame", (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        TermDatePicker(
          labelText: 'freeze from',
          value: DateTime(2026, 11, 20),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final inCalendar = <bool>[];
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    for (var k = 0; k < 12; k++) {
      await tester.pump(const Duration(milliseconds: 16));
      final focused = FocusManager.instance.primaryFocus?.context;
      inCalendar.add(
        focused != null &&
            focused.findAncestorWidgetOfExactType<TermCalendar>() != null,
      );
    }
    expect(find.byType(TermCalendar), findsOneWidget, reason: 'it opened');
    expect(inCalendar.toSet(), {true}, reason: 'frame by frame: $inCalendar');
    // The calendar says the day its cursor is on as it takes the keys.
    final said = tester.takeAnnouncements().map((a) => a.message).join(' | ');
    final day = RawWidgetsLocalizations.of(
      tester.element(find.byType(TermCalendar)),
    ).formatFullDate(DateTime(2026, 11, 20));
    expect(said, contains(day));
  });
}
