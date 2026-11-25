// A time picker writes its hours and minutes in the app's digits, through
// ui_core's formatHour and formatMinute: Arabic-Indic in Arabic, Persian
// digits in Persian, at a phone's width and a desktop's, either way round.
// Brutal's clock is a 24-hour one whatever the platform asks; English reads
// as it did.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _ascii = RegExp('[0-9]');

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required Size size,
  required TextDirection direction,
  required Widget child,
  bool h24 = false,
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
          child: BrutalTheme(data: BrutalThemeData.light(), child: navigator!),
        ),
      ),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every line of words on screen.
List<String> _printed(WidgetTester tester) => [
  for (final p in tester.allRenderObjects.whereType<RenderParagraph>())
    p.text.toPlainText(),
];

Widget _picker(BrutalTime value) =>
    BrutalTimePicker(value: value, onChanged: (_) {});

void main() {
  // 09:05: the chosen rows, and a row either side of the hour.
  for (final (lang, hour, minute, before, after) in const [
    ('ar', '٠٩', '٠٥', '٠٨', '١٠'),
    ('fa', '۹', '۰۵', '۸', '۱۰'),
  ]) {
    for (final size in const [Size(390, 844), Size(1440, 900)]) {
      for (final h24 in const [false, true]) {
        for (final direction in TextDirection.values) {
          testWidgets('$lang, ${h24 ? '24' : '12'}-hour platform, '
              '${size.width.toInt()} wide, ${direction.name}: the wheels '
              "write the app's digits", (tester) async {
            await _pump(
              tester,
              locale: Locale(lang),
              size: size,
              h24: h24,
              direction: direction,
              child: _picker(const BrutalTime(hour: 9, minute: 5)),
            );
            final printed = _printed(tester);
            expect(printed, containsAll([hour, minute, before, after]));
            expect(
              printed.where((s) => s.contains(_ascii)),
              isEmpty,
              reason: printed.join(' | '),
            );
          });
        }
      }
    }
  }

  testWidgets('en: the wheels read 09 and 05, as before', (tester) async {
    await _pump(
      tester,
      locale: const Locale('en'),
      size: const Size(390, 844),
      direction: TextDirection.ltr,
      child: _picker(const BrutalTime(hour: 9, minute: 5)),
    );
    expect(_printed(tester), containsAll(['08', '09', '10', '05']));
  });
}
