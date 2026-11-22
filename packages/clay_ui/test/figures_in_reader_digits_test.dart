// A pie chart's shares, a meter's percentage and a calendar's days are
// written in the reader's digits, as the charts' values are: Arabic-Indic in
// Arabic, never Latin digits in an Arabic sentence.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

final _latin = RegExp('[0-9]');
final _arabic = RegExp('[٠-٩]');

Future<void> _show(WidgetTester tester, Widget part) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ClayTheme(data: ClayThemeData.clay(Brightness.light), child: app!),
      home: Localizations(
        locale: const Locale('ar'),
        delegates: const [
          RawWidgetsLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(padding: const EdgeInsets.all(16), child: part),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every run of words painted under [of].
List<String> _painted(WidgetTester tester, Finder of) => [
  for (final p in tester.renderObjectList<RenderParagraph>(
    find.descendant(of: of, matching: find.byType(RichText)),
  ))
    p.text.toPlainText(),
];

void main() {
  testWidgets('a pie chart writes its shares in Arabic digits', (tester) async {
    await _show(
      tester,
      const ClayPieChart(
        semanticLabel: 'Time by habit',
        slices: [
          ClayPieSlice(label: 'Walk', value: 40),
          ClayPieSlice(label: 'Read', value: 25),
        ],
      ),
    );
    final words = _painted(tester, find.byType(ClayPieChart)).join(' ');
    expect(words, contains(_arabic));
    expect(words, isNot(contains(_latin)));
  });

  testWidgets('a meter writes its percentage in Arabic digits', (tester) async {
    await _show(tester, const ClayMeter(value: 0.72, label: 'Storage'));
    final words = _painted(tester, find.byType(ClayMeter)).join(' ');
    expect(words, contains('٧٢'));
    expect(words, isNot(contains(_latin)));
    final said = tester.getSemantics(find.byType(ClayMeter).first);
    expect(said.value, isNot(contains(_latin)));
  });

  testWidgets('a calendar numbers its days in Arabic digits', (tester) async {
    await _show(
      tester,
      ClayCalendar(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        selectedDate: DateTime(2026, 11, 21),
        currentDate: DateTime(2026, 11, 21),
        onDateChanged: (_) {},
      ),
    );
    final words = _painted(tester, find.byType(ClayCalendar)).join(' ');
    expect(words, contains('٢١'));
    expect(words, isNot(contains(_latin)));
  });
}
