// A select's list is clay from its first frame: as it starts to open, the
// page under it never shows through its rows. Before, it faded in over about
// 120 ms, the field below it showing through its words.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

/// How much of [of] shows: the product of the opacities above it.
double _shown(WidgetTester tester, Finder of) {
  var shown = 1.0;
  for (final o in tester.widgetList<Opacity>(
    find.ancestor(of: of, matching: find.byType(Opacity)),
  )) {
    shown *= o.opacity;
  }
  return shown;
}

void main() {
  setUpAll(clayLoadFonts);

  testWidgets("a select's list is opaque from its first frame", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            ClayTheme(data: ClayThemeData.clay(Brightness.light), child: app!),
        home: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClaySelect<String>(
                labelText: 'Repeat',
                value: 'Every day',
                items: const [
                  ClaySelectItem(value: 'Every day', label: 'Every day'),
                  ClaySelectItem(value: 'Weekdays', label: 'Weekdays'),
                  ClaySelectItem(value: 'Once a week', label: 'Once a week'),
                ],
                onChanged: (_) {},
              ),
              const SizedBox(height: 24),
              const ClayTextField(labelText: 'Notes'),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ClaySelect<String>));
    // The list's first frame and its second, 16 ms into the spring.
    for (var i = 0; i < 2; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Weekdays'), findsOneWidget, reason: 'the list is open');
      expect(_shown(tester, find.text('Weekdays')), greaterThan(0.99));
    }
    await tester.pumpAndSettle();
  });
}
