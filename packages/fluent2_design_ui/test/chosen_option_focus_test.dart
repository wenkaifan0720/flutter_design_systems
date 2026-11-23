// A list opens with the keys on what is chosen, from its first frame: a
// select's chosen option; a date picker's calendar, on the chosen day. No
// frame shows the keys elsewhere before they move.
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart' show loadFluent2TestFonts;

Widget _app(
  Widget page, {
  double scale = 1,
  Brightness brightness = Brightness.light,
}) => WidgetsApp(
  color: const Color(0xFF000000),
  debugShowCheckedModeBanner: false,
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    Fluent2Localizations.delegate,
  ],
  builder: (context, child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: scale,
    maxScaleFactor: scale,
    child: Fluent2Host(brightness: brightness, child: child!),
  ),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (context, _, _) => page,
  ),
);

Widget _page(Widget field) => Align(
  alignment: Alignment.topCenter,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: SizedBox(width: 320, child: field),
  ),
);

const _environments = [
  Fluent2Option('staging', 'Staging'),
  Fluent2Option('canary', 'Canary'),
  Fluent2Option('production', 'Production'),
];

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
  setUpAll(loadFluent2TestFonts);

  testWidgets('a select opened from the keys has its third option, the '
      "chosen one, focused from the list's first frame", (tester) async {
    await tester.pumpWidget(
      _app(
        _page(
          Fluent2Select<String>(
            label: 'Environment',
            options: _environments,
            value: 'production',
            onChanged: (_) {},
          ),
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
    expect(find.text('Canary'), findsOneWidget, reason: 'the list is open');
    expect(seen.toSet(), {'Production'}, reason: 'frame by frame: $seen');
  });

  testWidgets('a date picker opened from the keys has its calendar focused, '
      "on the chosen day, from the calendar's first frame", (tester) async {
    await tester.pumpWidget(
      _app(
        _page(
          Fluent2DatePicker(
            label: 'Freeze from',
            value: DateTime(2026, 11, 20),
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
            onChanged: (_) {},
          ),
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
            focused.findAncestorWidgetOfExactType<Fluent2Calendar>() != null,
      );
    }
    expect(find.byType(Fluent2Calendar), findsOneWidget, reason: 'it opened');
    expect(inCalendar.toSet(), {true}, reason: 'frame by frame: $inCalendar');
    // The calendar says the day it holds as it takes the keys.
    final said = tester.takeAnnouncements().map((a) => a.message).join(' | ');
    expect(said, allOf(contains('November'), contains('20')));
  });
}
