// Check the painted date as well as the longer value a screen reader hears.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _due = DateTime(2026, 11, 20);

Future<void> _show(WidgetTester tester, Locale locale, Widget date) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(780, 1200);
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
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: 358, child: date),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ApplianceDatePicker _date() => ApplianceDatePicker(
  label: 'Due date',
  value: _due,
  firstDate: DateTime(2020),
  lastDate: DateTime(2040),
  onChanged: (_) {},
);

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets(
    'Arabic due date reads day, named month and year from the right',
    (tester) async {
      await _show(tester, const Locale('ar'), _date());
      const date = '٢٠ نوفمبر ٢٠٢٦';
      final text = find.text(date);
      expect(text, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(text);
      double centerOf(String part) {
        final begin = date.indexOf(part);
        final box = paragraph
            .getBoxesForSelection(
              TextSelection(
                baseOffset: begin,
                extentOffset: begin + part.length,
              ),
            )
            .single;
        return box.toRect().center.dx;
      }

      expect(centerOf('٢٠'), greaterThan(centerOf('نوفمبر')));
      expect(centerOf('نوفمبر'), greaterThan(centerOf('٢٠٢٦')));
      final words = RawWidgetsLocalizations.of(tester.element(text));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Due date')).value,
        words.formatFullDate(_due),
      );
    },
  );

  for (final (locale, expected) in [
    (const Locale('en'), 'Nov 20, 2026'),
    (const Locale('de'), '20. Nov. 2026'),
    (const Locale('ja'), '2026年11月20日'),
  ]) {
    testWidgets('a $locale date keeps the reader’s order and punctuation', (
      tester,
    ) async {
      await _show(tester, locale, _date());
      expect(find.text(expected), findsOneWidget);
    });
  }

  testWidgets(
    'Arabic ranges name both endpoints and keep each necessary year',
    (tester) async {
      final words = RawWidgetsLocalizations.forLocale(const Locale('ar'));
      final next = DateTime(2027, 1, 2);
      final sameYear = DateTime(2026, 11, 23);
      for (final (end, expected) in <(DateTime?, String)>[
        (null, '٢٠ نوفمبر'),
        (sameYear, '٢٠ نوفمبر – ٢٣ نوفمبر ٢٠٢٦'),
        (next, '٢٠ نوفمبر ٢٠٢٦ – ٢ يناير ٢٠٢٧'),
      ]) {
        await _show(
          tester,
          const Locale('ar'),
          ApplianceDateRangePicker(
            label: 'Period',
            value: RawDateRange(_due, end),
            firstDate: DateTime(2020),
            lastDate: DateTime(2040),
            onChanged: (_) {},
          ),
        );
        expect(find.text(expected), findsOneWidget);
        final spoken = tester
            .getSemantics(find.bySemanticsLabel('Period'))
            .value;
        expect(
          spoken,
          end == null
              ? words.formatFullDate(_due)
              : words.chartRangeLabel(
                  words.formatFullDate(_due),
                  words.formatFullDate(end),
                ),
        );
      }
    },
  );
}
