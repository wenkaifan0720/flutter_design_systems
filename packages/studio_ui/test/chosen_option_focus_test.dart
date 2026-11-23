// A list opens with the keys on what is chosen, from its first frame: a
// select's chosen option; a date picker's calendar, on the chosen day. No
// frame shows the keys elsewhere before they move.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

// The gallery's app frame; a test reads it from the example.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart' show kitApp;

Widget _page(Widget field) => kitApp(
  brightness: Brightness.light,
  home: Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(width: 320, child: field),
    ),
  ),
);

const _shows = ['Morning edition', 'Field notes', 'Late session'];

// The words of the option or day holding the keyboard's focus.
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
  setUpAll(studioLoadFonts);

  testWidgets('a select opened from the keys has its third option, the '
      "chosen one, focused from the list's first frame", (tester) async {
    await tester.pumpWidget(
      _page(
        StudioSelect<String>(
          labelText: 'Show',
          value: _shows.last,
          items: [for (final s in _shows) StudioSelectItem(value: s, label: s)],
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
    expect(
      find.text('Field notes'),
      findsOneWidget,
      reason: 'the list is open',
    );
    expect(seen.toSet(), {_shows.last}, reason: 'frame by frame: $seen');
  });

  testWidgets('a date picker opened from the keys has them on the chosen '
      "day from the calendar's first frame", (tester) async {
    DateTime? taken;
    await tester.pumpWidget(
      _page(
        StudioDatePicker(
          labelText: 'Release date',
          value: DateTime(2026, 11, 20),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          onChanged: (day) => taken = day,
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.byType(StudioCalendar), findsOneWidget, reason: 'it opened');
    final focused = FocusManager.instance.primaryFocus?.context;
    expect(
      focused?.findAncestorWidgetOfExactType<StudioCalendar>(),
      isNotNull,
      reason: 'the calendar holds the keys from its first frame',
    );
    // The keys stand on the chosen day: one step on is the day after it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taken, DateTime(2026, 11, 21));
  });
}
