// A date tab and a range picker's days are written in the reader's digits,
// as the date picker's are (ui_core's RawWidgetsLocalizations): Arabic-Indic
// in Arabic, Western in English.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:ledger_ui/ledger_ui.dart';

Future<void> _pump(WidgetTester t, Locale locale, Widget part) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, _) => Directionality(
        textDirection: locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: LedgerHost(
          brightness: Brightness.light,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(width: 340, child: part),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  for (final (locale, twenty, twelve) in const [
    (Locale('ar'), '٢٠', '١٢'),
    (Locale('en'), '20', '12'),
  ]) {
    testWidgets('a date tab writes the day in ${locale.languageCode} digits', (
      t,
    ) async {
      await _pump(t, locale, LedgerDateTab(DateTime(2026, 8, 20)));
      expect(find.text(twenty), findsOneWidget);
    });

    testWidgets("a range picker's days are in ${locale.languageCode} digits", (
      t,
    ) async {
      await _pump(
        t,
        locale,
        LedgerDateRangePicker(
          firstDate: DateTime(2026, 8),
          lastDate: DateTime(2026, 8, 31),
          currentDate: DateTime(2026, 8, 12),
          onChanged: (_) {},
        ),
      );
      expect(find.text(twelve), findsWidgets);
    });
  }
}
