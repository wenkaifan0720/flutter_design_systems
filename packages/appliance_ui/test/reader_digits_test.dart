// Figures are set in the reader's digits: a stepper's window and a chart's
// scale read Arabic-Indic digits on an Arabic page.
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

final _ascii = RegExp('[0-9]');

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('an Arabic stepper reads Arabic-Indic digits', (tester) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      const Locale('ar'),
      ApplianceStepper(
        value: 45,
        min: 5,
        max: 480,
        step: 15,
        semanticLabel: 'التقدير بالدقائق',
        onChanged: (_) {},
      ),
    );
    expect(find.text('٤٥'), findsOneWidget);
    expect(find.text('45'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('التقدير بالدقائق')),
      isSemantics(label: 'التقدير بالدقائق', value: '٤٥'),
    );
    semantics.dispose();
  });

  testWidgets('an Arabic chart reads its figures in Arabic-Indic digits', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      const Locale('ar'),
      const ApplianceBarChart(
        semanticLabel: 'الساعات',
        height: 200,
        labels: ['ن', 'ث', 'ر'],
        series: [
          ApplianceChartSeries('الساعات', [1, 2.5, 4]),
        ],
      ),
    );
    // The chart's node reads its values; none in Western digits.
    final node = tester.getSemantics(find.bySemanticsLabel('الساعات'));
    final words = [node.label, node.value, node.hint].join(' ');
    expect(words, contains(RegExp('[٠-٩]')));
    expect(words, isNot(contains(_ascii)));
    semantics.dispose();
  });
}
