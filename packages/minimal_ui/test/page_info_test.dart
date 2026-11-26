// A pager's and a step progress's place, outside English with no words of
// the app's own, comes in the shared words' own form ("٦ من ١٢"), not in
// English: "Page 6 of 12" stays English's.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Future<void> _show(WidgetTester tester, Locale locale, Widget part) async {
  tester.view
    ..physicalSize = const Size(340, 600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final rtl = locale.languageCode == 'ar' || locale.languageCode == 'fa';
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: const [
        MinimalLocalizations.delegate,
        RawWidgetsLocalizations.delegate,
      ],
      builder: (context, _) => Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: MinimalTheme(
          data: MinimalThemeData.standard(),
          child: Center(child: SizedBox(width: 300, child: part)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'fa', 'de']) {
    testWidgets('$language: a narrow pager prints its place in the shared '
        'words', (tester) async {
      await _show(
        tester,
        Locale(language),
        MinimalPagination(page: 5, pageCount: 12, onPageChanged: (_) {}),
      );
      final shared = RawWidgetsLocalizations.of(
        tester.element(find.byType(MinimalPagination)),
      );
      expect(find.text(shared.positionLabel(6, 12)), findsOneWidget);
      expect(find.textContaining('Page'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("$language: a step's place is the shared words'", (
      tester,
    ) async {
      await _show(tester, Locale(language), const SizedBox());
      final context = tester.element(find.byType(SizedBox).last);
      final shared = RawWidgetsLocalizations.of(context);
      final words = MinimalLocalizations.of(context);
      expect(words.stepOf(2, 4), shared.positionLabel(2, 4));
      expect(words.pageOf(2, 4), shared.positionLabel(2, 4));
    });
  }

  testWidgets('en: "Page 6 of 12" stays', (tester) async {
    await _show(
      tester,
      const Locale('en'),
      MinimalPagination(page: 5, pageCount: 12, onPageChanged: (_) {}),
    );
    expect(find.text('Page 6 of 12'), findsOneWidget);
  });
}
