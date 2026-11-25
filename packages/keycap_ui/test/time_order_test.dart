// A time picker's wheels keep hours before minutes, left to right, in
// either direction, as Material's time picker keeps them and as the time
// reads in a line of text ("٩:٠٥"): in Arabic, right to left, the hour's
// wheel stands left of the minutes', at a phone's width and a desktop's, on
// either face. The half day's keys keep the reading side.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';

Future<void> _open(
  WidgetTester tester, {
  required Size size,
  required bool h24,
  required TextDirection direction,
  Locale locale = const Locale('ar'),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, navigator) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: h24),
        child: Directionality(
          textDirection: direction,
          child: KeycapTheme(data: KeycapThemeData.light(), child: navigator!),
        ),
      ),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: KeycapTimePicker(
            value: const RawTimeOfDay(hour: 9, minute: 5),
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find
        .descendant(
          of: find.byType(KeycapTimePicker),
          matching: find.byType(Text),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

double _x(WidgetTester tester, String text) =>
    tester.getCenter(find.text(text).last).dx;

void main() {
  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    for (final h24 in const [false, true]) {
      testWidgets('ar, ${h24 ? '24' : '12'}-hour, ${size.width.toInt()} '
          'wide, right to left: the hour wheel stands left of the minutes', (
        tester,
      ) async {
        await _open(tester, size: size, h24: h24, direction: TextDirection.rtl);
        final hour = _x(tester, h24 ? '٠٩' : '٩');
        final colon = _x(tester, ':');
        final minute = _x(tester, '٠٥');
        expect(hour, lessThan(colon));
        expect(colon, lessThan(minute));
        if (!h24) {
          // The half day's keys read from the right: the morning's first.
          final am = RawWidgetsLocalizations.forLocale(const Locale('ar'))
              .anteMeridiemAbbreviation;
          final pm = RawWidgetsLocalizations.forLocale(const Locale('ar'))
              .postMeridiemAbbreviation;
          expect(_x(tester, am), greaterThan(_x(tester, pm)));
        }
      });
    }
  }

  testWidgets('en, left to right: hours before minutes, as before', (
    tester,
  ) async {
    await _open(
      tester,
      size: const Size(390, 844),
      h24: true,
      direction: TextDirection.ltr,
      locale: const Locale('en'),
    );
    expect(_x(tester, '09'), lessThan(_x(tester, '05')));
  });
}
