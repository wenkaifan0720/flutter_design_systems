// A tag input with no onChanged takes no choices: its entry is disabled,
// its tags' remove keys take no press and its label greys, while one with
// onChanged takes them.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialApp, Scaffold, TextField;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(WidgetTester tester, Widget input) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: input)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

({bool entry, bool remove, bool label}) _takes(WidgetTester tester) => (
  entry: tester.widget<TextField>(find.byType(TextField)).enabled ?? true,
  remove:
      tester
          .widget<RawButton>(
            find.byWidgetPredicate(
              (w) => w is RawButton && w.semanticLabel == 'Remove Hall',
            ),
          )
          .onPressed !=
      null,
  label: tester
      .widget<ApplianceFieldLabel>(find.byType(ApplianceFieldLabel))
      .enabled,
);

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('a tag input with no onChanged takes no choices', (tester) async {
    await _show(
      tester,
      ApplianceTagInput<String>(
        labelText: 'Rooms',
        values: const ['Hall'],
        options: const ['Hall', 'Kitchen'],
        onChanged: (_) {},
      ),
    );
    expect(_takes(tester), (entry: true, remove: true, label: true));

    await _show(
      tester,
      const ApplianceTagInput<String>(
        labelText: 'Rooms',
        values: ['Hall'],
        options: ['Hall', 'Kitchen'],
        onChanged: null,
      ),
    );
    expect(_takes(tester), (entry: false, remove: false, label: false));
  });
}
