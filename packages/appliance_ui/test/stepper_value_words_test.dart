// A stepper says its number in the words it is given (a unit), in its window
// and to a screen reader.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

Future<void> _show(WidgetTester tester, Locale locale, Widget part) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(780, 1000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Localizations(
        locale: locale,
        delegates: const [
          RawWidgetsLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: ApplianceHost(
            brightness: Brightness.light,
            child: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(width: 358, child: part),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('a stepper says its number in the words it is given', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      const Locale('en'),
      ApplianceStepper(
        value: 45,
        min: 5,
        max: 480,
        step: 15,
        semanticLabel: 'Estimate',
        valueText: (minutes) => '$minutes min',
        onChanged: (_) {},
      ),
    );
    expect(find.text('45 min'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Estimate')),
      isSemantics(label: 'Estimate', value: '45 min'),
    );
    semantics.dispose();
  });
}
