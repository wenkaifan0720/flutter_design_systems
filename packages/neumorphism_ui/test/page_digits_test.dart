// A pager's page keys are written in the app's digits, through ui_core's
// formatDecimal, as their spoken names already are: Arabic-Indic in Arabic,
// Persian digits in Persian, at a phone's width and a desktop's, either way
// round. English reads as it did.
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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

Widget get _pager =>
    NeumorphicPagination(count: 12, page: 2, onChanged: (_) {});

void main() {
  for (final (lang, three, twelve, threeOfTwelve) in const [
    ('ar', '٣', '١٢', '٣ من ١٢'),
    ('fa', '۳', '۱۲', '۳ از ۱۲'),
  ]) {
    for (final size in const [Size(390, 844), Size(1440, 900)]) {
      for (final direction in TextDirection.values) {
        testWidgets('$lang, ${size.width.toInt()} wide, ${direction.name}: '
            "the page keys are in the app's digits", (tester) async {
          await _pump(
            tester,
            locale: Locale(lang),
            size: size,
            direction: direction,
            child: _pager,
          );
          final printed = _printed(tester);
          // A phone's pager says where it stands in words; a desktop's has a
          // key for each page shown.
          expect(
            printed,
            size.width < 600
                ? contains(threeOfTwelve)
                : containsAll([three, twelve]),
          );
          expect(
            printed.where((s) => s.contains(_ascii)),
            isEmpty,
            reason: printed.join(' | '),
          );
        });
      }
    }
  }

  testWidgets('en: the page keys read 3 and 12, as before', (tester) async {
    await _pump(
      tester,
      locale: const Locale('en'),
      size: const Size(1440, 900),
      direction: TextDirection.ltr,
      child: _pager,
    );
    expect(_printed(tester), containsAll(['1', '3', '12']));
  });
}
