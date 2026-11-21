// Figures follow the reader's digits: in Arabic a calendar's days, a time
// drum's hours and minutes, a stepper's count, a badge's count, a pager's
// figures, a file's upload and a chart's figures are set in Arabic-Indic
// digits, as the calendar's heading is; in English they read as English
// writes them, a chart's thousands grouped.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('ar'),
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 1600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          StudioHost(brightness: Brightness.light, child: app!),
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
          child: Align(alignment: Alignment.topCenter, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(studioLoadFonts);

  testWidgets('a calendar sets its days in Arabic-Indic digits in Arabic', (
    tester,
  ) async {
    await _show(
      tester,
      StudioCalendar(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        selectedDate: DateTime(2026, 11, 20),
        onDateChanged: (_) {},
      ),
    );
    expect(find.text('٢٠'), findsOneWidget);
    expect(find.text('٣٠'), findsOneWidget);
    expect(find.text('20'), findsNothing);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('a time drum sets its figures in Arabic-Indic digits in '
      'Arabic', (tester) async {
    await _show(
      tester,
      StudioTimePicker(
        value: const StudioTime(hour: 9, minute: 30),
        onChanged: (_) {},
      ),
    );
    expect(find.text('٠٩'), findsWidgets);
    expect(find.text('٣٠'), findsWidgets);
    expect(find.text('09'), findsNothing);
    expect(find.text('30'), findsNothing);
  });

  testWidgets('a stepper sets its count in Arabic-Indic digits in Arabic', (
    tester,
  ) async {
    await _show(
      tester,
      StudioStepper(
        value: 45,
        max: 480,
        semanticLabel: 'Estimate',
        onChanged: (_) {},
      ),
    );
    expect(find.text('٤٥'), findsOneWidget);
    expect(find.text('45'), findsNothing);
    // Its spoken value reads as it shows.
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.value == '٤٥',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a badge, a pager and a file upload set their figures in '
      'Arabic-Indic digits in Arabic', (tester) async {
    await _show(
      tester,
      Column(
        children: [
          const StudioBadge(count: 7, child: SizedBox.square(dimension: 24)),
          const StudioBadge(count: 120, child: SizedBox.square(dimension: 24)),
          StudioPagination(page: 3, pageCount: 12, onChanged: (_) {}),
          StudioFileDrop(
            onChoose: () {},
            files: const [
              StudioFile(name: 'take.wav', bytes: 2400000, progress: 0.4),
            ],
          ),
        ],
      ),
    );
    expect(find.text('٧'), findsOneWidget);
    expect(find.text('٩٩+'), findsOneWidget);
    expect(find.text('٠٣ / ١٢'), findsOneWidget);
    expect(find.textContaining('٤٠'), findsOneWidget);
    for (final ascii in ['7', '99+', '03 / 12']) {
      expect(find.text(ascii), findsNothing);
    }
    expect(find.textContaining('40%'), findsNothing);
  });

  testWidgets('a chart sets its figures in Arabic-Indic digits in Arabic', (
    tester,
  ) async {
    await _show(
      tester,
      const Column(
        children: [
          SizedBox(
            width: 340,
            child: StudioBarChart(
              semanticLabel: 'Hours',
              labels: ['أ', 'ب'],
              series: [
                StudioSeries('Hours', [12, 30]),
              ],
            ),
          ),
          StudioPieChart(
            semanticLabel: 'Split',
            slices: [StudioSlice('A', 62), StudioSlice('B', 38)],
          ),
        ],
      ),
    );
    // The ring's total, and the bars' spoken figures.
    expect(find.text('١٠٠'), findsOneWidget);
    expect(find.text('100'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.value ?? '').contains('١٢') &&
            (w.properties.value ?? '').contains('٣٠'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('in English the figures read as English writes them', (
    tester,
  ) async {
    await _show(
      tester,
      Column(
        children: [
          StudioStepper(value: 45, max: 480, onChanged: (_) {}),
          const StudioBadge(count: 120, child: SizedBox.square(dimension: 24)),
          StudioPagination(page: 3, pageCount: 12, onChanged: (_) {}),
          const StudioPieChart(
            semanticLabel: 'Split',
            slices: [StudioSlice('A', 62), StudioSlice('B', 38)],
          ),
        ],
      ),
      locale: const Locale('en'),
    );
    for (final text in ['45', '99+', '03 / 12', '100']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    // A chart's figures group their thousands, as the reader writes them.
    await _show(
      tester,
      const SizedBox(
        width: 340,
        child: StudioBarChart(
          semanticLabel: 'Plays',
          labels: ['Mon', 'Tue'],
          series: [
            StudioSeries('Plays', [1500, 820]),
          ],
        ),
      ),
      locale: const Locale('en'),
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.value ?? '').contains('1,500'),
      ),
      findsOneWidget,
    );
  });
}
