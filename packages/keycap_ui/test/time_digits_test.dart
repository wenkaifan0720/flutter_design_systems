// A time picker writes its hours and minutes in the app's digits, through
// ui_core's formatHour and formatMinute: Arabic-Indic in Arabic, Persian
// digits in Persian, on the 12-hour and the 24-hour face, at a phone's width
// and a desktop's, either way round. English reads as it did.
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';

final _ascii = RegExp('[0-9]');

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required Size size,
  required bool h24,
  required TextDirection direction,
  RawTimeOfDay value = const RawTimeOfDay(hour: 9, minute: 5),
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
          child: KeycapTimePicker(value: value, onChanged: (_) {}),
        ),
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

// The key's words: at a desktop's width the field is wider than its key.
Future<void> _open(WidgetTester tester) async {
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

void main() {
  // 09:05 on each face: the key's words, and two of the wheels' rows.
  for (final (lang, twelve, twentyFour, hour12, hour24, minute) in const [
    ('ar', '٩:٠٥', '٠٩:٠٥', '٩', '٠٩', '٠٥'),
    ('fa', '۹:۰۵', '۹:۰۵', '۹', '۹', '۰۵'),
  ]) {
    for (final size in const [Size(390, 844), Size(1440, 900)]) {
      for (final h24 in const [false, true]) {
        for (final direction in TextDirection.values) {
          final face = h24 ? '24-hour' : '12-hour';
          testWidgets('$lang, $face, ${size.width.toInt()} wide, '
              '${direction.name}: the key and the wheels write the app\'s '
              'digits', (tester) async {
            final locale = Locale(lang);
            await _pump(
              tester,
              locale: locale,
              size: size,
              h24: h24,
              direction: direction,
            );
            final words = RawWidgetsLocalizations.forLocale(locale);
            final key = h24
                ? twentyFour
                : '$twelve ${words.anteMeridiemAbbreviation}';
            expect(_printed(tester), contains(key));
            await _open(tester);
            final printed = _printed(tester);
            expect(printed, contains(h24 ? hour24 : hour12));
            expect(printed, contains(minute));
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

  for (final (h24, key, hour, minute) in const [
    (false, '9:05 AM', '9', '05'),
    (true, '09:05', '09', '05'),
  ]) {
    testWidgets('en, ${h24 ? '24' : '12'}-hour: the key reads $key, as '
        'before', (tester) async {
      await _pump(
        tester,
        locale: const Locale('en'),
        size: const Size(390, 844),
        h24: h24,
        direction: TextDirection.ltr,
      );
      expect(_printed(tester), contains(key));
      await _open(tester);
      final printed = _printed(tester);
      expect(printed, contains(hour));
      expect(printed, contains(minute));
      expect(printed, containsAll(h24 ? ['08', '10'] : ['8', '10']));
    });
  }

  // Persian's own clock is a 24-hour one; on the 12-hour face the picker
  // still writes the hour of the half day, in Persian digits.
  testWidgets('fa, 12-hour: 15:05 reads ۳:۰۵ and the afternoon word', (
    tester,
  ) async {
    const locale = Locale('fa');
    await _pump(
      tester,
      locale: locale,
      size: const Size(390, 844),
      h24: false,
      direction: TextDirection.rtl,
      value: const RawTimeOfDay(hour: 15, minute: 5),
    );
    final pm = RawWidgetsLocalizations.forLocale(locale)
        .postMeridiemAbbreviation;
    expect(_printed(tester), contains('۳:۰۵ $pm'));
    await _open(tester);
    expect(_printed(tester), contains('۳'));
    // A 24-hour wheel would show 13 to 17 round it; no minute is 14.
    expect(_printed(tester), isNot(contains('۱۴')));
  });
}
