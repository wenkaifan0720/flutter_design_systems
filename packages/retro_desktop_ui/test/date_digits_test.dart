// The days of a date picker and of a calendar are in the app's digits: in an Arabic app, Arabic-Indic, as ui_core's
// calendar writes them (RawCalendarDayDetails.label).
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

// Material's English words under any locale: the look gives its own, an app has flutter_localizations' Arabic.
class _AnyMaterial extends LocalizationsDelegate<MaterialLocalizations> {
  const _AnyMaterial();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(const Locale('en'));
  @override
  bool shouldReload(_AnyMaterial old) => false;
}

class _AnyCupertino extends LocalizationsDelegate<CupertinoLocalizations> {
  const _AnyCupertino();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(const Locale('en'));
  @override
  bool shouldReload(_AnyCupertino old) => false;
}

void main() {
  testWidgets(
    'in Arabic a date picker\'s month, weekdays and days are in ui_core\'s words and digits',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            RetroDesktopLocalizations.delegate,
            RawWidgetsLocalizations.delegate,
            _AnyMaterial(),
            _AnyCupertino(),
            DefaultWidgetsLocalizations.delegate,
          ],
          builder: (context, app) =>
              RetroDesktopHost(brightness: Brightness.light, child: app!),
          home: Center(
            child: RetroDesktopDatePicker(
              value: DateTime(2026, 11, 20),
              today: DateTime(2026, 11, 20),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('١٢'), findsOneWidget);
      expect(find.text('12'), findsNothing);
      // The month's head and the weekdays in the same words as the days.
      final names = RawWidgetsLocalizations.forLocale(const Locale('ar'));
      expect(
        find.text(names.formatMonthYear(DateTime(2026, 11))),
        findsOneWidget,
      );
      expect(
        find.text(names.formatShortWeekday(DateTime.monday)),
        findsOneWidget,
      );
    },
  );

  testWidgets('in Arabic a calendar\'s days read in Arabic-Indic digits', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          RetroDesktopLocalizations.delegate,
          RawWidgetsLocalizations.delegate,
          _AnyMaterial(),
          _AnyCupertino(),
          DefaultWidgetsLocalizations.delegate,
        ],
        builder: (context, app) =>
            RetroDesktopHost(brightness: Brightness.light, child: app!),
        home: Center(
          child: RetroDesktopCalendar(
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
            value: DateTime(2026, 11, 20),
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('١٢'), findsOneWidget);
    expect(find.text('12'), findsNothing);
  });
}
