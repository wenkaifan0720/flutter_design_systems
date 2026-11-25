// A time picker writes its time and its hour and minute keys in the app's
// digits, through ui_core's formatHour, formatMinute and formatDecimal:
// Arabic-Indic in Arabic, Persian digits in Persian, on the 12-hour and the
// 24-hour face, at a phone's width and a desktop's, either way round, with
// or without Neumorphism's own delegate (intl writes Arabic in Western
// digits). English reads as it did.
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

final _ascii = RegExp('[0-9]');

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required Size size,
  required TextDirection direction,
  required Widget child,
  bool h24 = false,
  bool neumorphicWords = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: [
        if (neumorphicWords) NeumorphicLocalizations.delegate,
        RawWidgetsLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      builder: (context, _) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: h24),
        child: Directionality(
          textDirection: direction,
          child: NeumorphicHost(
            brightness: Brightness.light,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                // A phone's column, or a desktop's wider one.
                child: SizedBox(
                  width: size.width < 600 ? 358 : 800,
                  child: child,
                ),
              ),
            ),
          ),
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

Widget _picker(NeumorphicTime value) =>
    NeumorphicTimePicker(value: value, onChanged: (_) {});

void main() {
  // 09:05: the heading, an hour key and the minute's key.
  for (final (lang, twelve, twentyFour, hour, minute, eleven, twentyThree)
      in const [
        ('ar', '٩:٠٥', '٠٩:٠٥', '٩', '٠٥', '١١', '٢٣'),
        ('fa', '۹:۰۵', '۹:۰۵', '۹', '۰۵', '۱۱', '۲۳'),
      ]) {
    for (final size in const [Size(390, 844), Size(1440, 900)]) {
      for (final h24 in const [false, true]) {
        for (final direction in TextDirection.values) {
          testWidgets('$lang, ${h24 ? '24' : '12'}-hour, '
              '${size.width.toInt()} wide, ${direction.name}: the time and '
              "its keys are in the app's digits", (tester) async {
            final locale = Locale(lang);
            await _pump(
              tester,
              locale: locale,
              size: size,
              h24: h24,
              direction: direction,
              child: _picker(const NeumorphicTime(9, 5)),
            );
            final am = RawWidgetsLocalizations.forLocale(locale)
                .anteMeridiemAbbreviation;
            final printed = _printed(tester);
            expect(printed, contains(h24 ? twentyFour : '$twelve $am'));
            expect(printed, containsAll([hour, minute, eleven]));
            if (h24) expect(printed, contains(twentyThree));
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

  testWidgets("ar with Neumorphism's delegate: still Arabic-Indic", (
    tester,
  ) async {
    await _pump(
      tester,
      locale: const Locale('ar'),
      size: const Size(390, 844),
      direction: TextDirection.rtl,
      neumorphicWords: true,
      child: _picker(const NeumorphicTime(9, 5)),
    );
    final printed = _printed(tester);
    expect(printed.where((s) => s.startsWith('٩:٠٥')), isNotEmpty);
    expect(printed.where((s) => s.contains(_ascii)), isEmpty);
  });

  // Persian's own clock is a 24-hour one; on the 12-hour face the picker
  // writes the hour of the half day.
  testWidgets('fa, 12-hour: 15:05 reads ۳:۰۵ and the afternoon word', (
    tester,
  ) async {
    const locale = Locale('fa');
    await _pump(
      tester,
      locale: locale,
      size: const Size(390, 844),
      direction: TextDirection.rtl,
      child: _picker(const NeumorphicTime(15, 5)),
    );
    final pm = RawWidgetsLocalizations.forLocale(locale)
        .postMeridiemAbbreviation;
    expect(_printed(tester), contains('۳:۰۵ $pm'));
  });

  for (final (h24, heading, keys) in const [
    (false, '9:05 AM', ['12', '9', '11', '05']),
    (true, '09:05', ['0', '9', '23', '05']),
  ]) {
    testWidgets('en, ${h24 ? '24' : '12'}-hour: $heading, as before', (
      tester,
    ) async {
      await _pump(
        tester,
        locale: const Locale('en'),
        size: const Size(390, 844),
        h24: h24,
        direction: TextDirection.ltr,
        child: _picker(const NeumorphicTime(9, 5)),
      );
      expect(_printed(tester), containsAll([heading, ...keys]));
    });
  }
}
