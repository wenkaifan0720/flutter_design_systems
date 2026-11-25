// A pager's page keys are written in the app's digits, through ui_core's
// formatDecimal, as its words ("3 of 12") already are: Arabic-Indic in
// Arabic, Persian digits in Persian, at a phone's width and a desktop's,
// either way round. English reads as it did.
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';

final _ascii = RegExp('[0-9]');

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required Size size,
  required TextDirection direction,
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
      builder: (context, _) => Directionality(
        textDirection: direction,
        child: KeycapTheme(
          data: KeycapThemeData.light(),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: KeycapPagination(
                page: 3,
                pageCount: 12,
                onPageChanged: (_) {},
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

void main() {
  for (final (lang, three, twelve, threeOfTwelve) in const [
    ('ar', '٣', '١٢', '٣ من ١٢'),
    ('fa', '۳', '۱۲', '۳ از ۱۲'),
  ]) {
    for (final size in const [Size(390, 844), Size(1440, 900)]) {
      for (final direction in TextDirection.values) {
        testWidgets('$lang, ${size.width.toInt()} wide, ${direction.name}: '
            "the pages are in the app's digits", (tester) async {
          await _pump(
            tester,
            locale: Locale(lang),
            size: size,
            direction: direction,
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

  testWidgets('en: the page keys read 1, 3 and 12, as before', (tester) async {
    await _pump(
      tester,
      locale: const Locale('en'),
      size: const Size(1440, 900),
      direction: TextDirection.ltr,
    );
    expect(_printed(tester), containsAll(['1', '3', '12']));
  });
}
