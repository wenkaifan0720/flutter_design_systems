// A calendar's days are written in the reader's digits (ui_core's
// RawWidgetsLocalizations): Arabic-Indic in Arabic, Western in English.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

Future<void> _pump(WidgetTester t, Locale locale) async {
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
        child: NeumorphicHost(
          brightness: Brightness.light,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 358,
              child: NeumorphicCalendar(
                firstDate: DateTime(2026, 8),
                lastDate: DateTime(2026, 8, 31),
                initialDate: DateTime(2026, 8, 12),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  for (final (locale, twelve) in const [
    (Locale('ar'), '١٢'),
    (Locale('en'), '12'),
  ]) {
    testWidgets("a calendar's days are in ${locale.languageCode} digits", (
      t,
    ) async {
      await _pump(t, locale);
      expect(find.text(twelve), findsOneWidget);
    });
  }
}
