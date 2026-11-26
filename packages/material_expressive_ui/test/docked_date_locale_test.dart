/// A docked date picker prints its day as the app's language writes a short
/// date, in its digits, as Material's date field (`formatCompactDate`): an
/// Arabic app read "11/20/2026". English keeps Compose's MM/DD/YYYY. The
/// year is the bare figure a short date writes, not the year said on its own
/// (Japanese's 2026年).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

/// What the field of a docked picker showing 18 September 2026 reads in a
/// [locale] app, with ui_core's words for it.
Future<String> _shown(
  WidgetTester tester,
  Locale locale, {
  String Function(DateTime day)? format,
}) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xff000000),
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, child) => ExpressiveHost(
        theme: _theme,
        brightness: Brightness.light,
        child: child!,
      ),
      home: Center(
        child: SizedBox(
          width: 320,
          child: ExpressiveDockedDatePicker(
            label: 'Due',
            value: DateTime(2026, 9, 18),
            format: format,
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.widget<EditableText>(find.byType(EditableText)).controller.text;
}

void main() {
  setUpAll(expressiveLoadFonts);

  testWidgets('English keeps MM/DD/YYYY', (tester) async {
    expect(await _shown(tester, const Locale('en')), '09/18/2026');
  });

  testWidgets('German writes the day first', (tester) async {
    expect(await _shown(tester, const Locale('de')), '18.9.2026');
  });

  testWidgets('Arabic writes the day first, in its digits', (tester) async {
    final arabic = RawWidgetsLocalizations.forLocale(const Locale('ar'));
    final shown = await _shown(tester, const Locale('ar'));
    expect(shown, isNot(contains('/09/')));
    expect(
      shown,
      arabic.dateFieldPattern
          .replaceFirst('d', arabic.formatDecimal(18))
          .replaceFirst('M', arabic.formatDecimal(9))
          .replaceFirst('y', arabic.formatYear(DateTime(2026))),
    );
    expect(shown, contains(arabic.formatYear(DateTime(2026))));
  });

  testWidgets('Japanese, Korean and Chinese write the year bare', (
    tester,
  ) async {
    expect(await _shown(tester, const Locale('ja')), '2026/9/18');
    expect(await _shown(tester, const Locale('ko')), '2026. 9. 18.');
    expect(await _shown(tester, const Locale('zh')), '2026/9/18');
  });

  testWidgets('an app\'s format still wins', (tester) async {
    expect(
      await _shown(tester, const Locale('ar'), format: (d) => 'day ${d.day}'),
      'day 18',
    );
  });
}
