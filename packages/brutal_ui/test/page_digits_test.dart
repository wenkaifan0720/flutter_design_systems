// A pager's pages and a date range field's days are written in the app's
// digits, through ui_core's formatDecimal, as the pager's spoken words and
// the field's month already are: Arabic-Indic in Arabic, Persian digits in
// Persian, at a phone's width and a desktop's, either way round. English
// reads as it did.
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

Widget _parts({required bool narrow}) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    BrutalPagination(page: 3, pageCount: 12, onPageChanged: (_) {}),
    const SizedBox(height: 12),
    // Too narrow for page keys: the pager writes where it stands.
    SizedBox(
      width: narrow ? 260 : 600,
      child: BrutalPagination(page: 3, pageCount: 12, onPageChanged: (_) {}),
    ),
    const SizedBox(height: 12),
    SizedBox(
      width: 300,
      child: BrutalDateRangePicker(
        value: BrutalDateRange(
          start: DateTime(2026, 11, 14),
          end: DateTime(2026, 11, 20),
        ),
        onChanged: (_) {},
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
      ),
    ),
  ],
);

void main() {
  for (final (lang, three, twelve, fourteen) in const [
    ('ar', '٣', '١٢', '١٤ – ٢٠ '),
    ('fa', '۳', '۱۲', '۱۴ – ۲۰ '),
  ]) {
    for (final size in const [Size(390, 844), Size(1440, 900)]) {
      for (final direction in TextDirection.values) {
        testWidgets('$lang, ${size.width.toInt()} wide, ${direction.name}: '
            "pages and a span's days are in the app's digits", (tester) async {
          await _pump(
            tester,
            locale: Locale(lang),
            size: size,
            direction: direction,
            child: _parts(narrow: true),
          );
          final printed = _printed(tester);
          expect(printed, containsAll([three, twelve, '$three / $twelve']));
          expect(printed.where((s) => s.startsWith(fourteen)), isNotEmpty);
          expect(
            printed.where((s) => s.contains(_ascii)),
            isEmpty,
            reason: printed.join(' | '),
          );
        });
      }
    }
  }

  testWidgets('en: the figures read as before', (tester) async {
    await _pump(
      tester,
      locale: const Locale('en'),
      size: const Size(390, 844),
      direction: TextDirection.ltr,
      child: _parts(narrow: true),
    );
    final printed = _printed(tester);
    expect(printed, containsAll(['1', '3', '12', '3 / 12']));
    expect(printed.where((s) => s.startsWith('14 – 20 ')), isNotEmpty);
  });
}
