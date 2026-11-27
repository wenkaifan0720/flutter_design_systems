// Where a page or a step stands, in the page's language: English keeps the source's words ("PAGE 2 OF 9", "Step 2 of
// 3, Amount"); Arabic and Persian say ui_core's position words (RawWidgetsLocalizations.positionLabel), at the narrow
// width where the pagination writes its page out.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

Widget _app(Locale locale, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      LedgerHost(brightness: Brightness.light, child: page!),
  home: Builder(
    builder: (context) => Localizations.override(
      context: context,
      locale: locale,
      delegates: const [RawWidgetsLocalizations.delegate],
      child: Material(
        type: MaterialType.transparency,
        child: Center(child: SizedBox(width: 200, child: child)),
      ),
    ),
  ),
);

void _phone(WidgetTester t) {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(390, 844);
  addTearDown(t.view.reset);
}

/// ui_core's words for [position] of [count] in [code].
Future<String> _of(String code, int position, int count) async =>
    (await RawWidgetsLocalizations.delegate.load(Locale(code)))
        .positionLabel(position, count);

Future<String> _page(String code) async =>
    code == 'en' ? 'PAGE 2 OF 9' : (await _of(code, 2, 9)).toUpperCase();
Future<String> _dot(String code) async =>
    code == 'en' ? 'Page 2 of 5' : _of(code, 2, 5);
Future<String> _step(String code) async =>
    code == 'en' ? 'Step 2 of 3, Amount' : '${await _of(code, 2, 3)}, Amount';

const _codes = ['en', 'ar', 'fa'];

void main() {
  test('Arabic and Persian have position words of their own', () async {
    for (final code in ['ar', 'fa']) {
      expect(await _of(code, 2, 9), isNot('2 of 9'));
    }
  });

  for (final code in _codes) {
    testWidgets('$code: a narrow pagination writes its page in the language', (
      t,
    ) async {
      _phone(t);
      await t.pumpWidget(
        _app(
          Locale(code),
          LedgerPagination(page: 2, pageCount: 9, onChanged: (_) {}),
        ),
      );
      final words = (await t.runAsync(() => _page(code)))!;
      expect(find.text(words), findsOneWidget);
    });

    testWidgets(
      '$code: page dots and step progress say their place in the language',
      (t) async {
        _phone(t);
        final semantics = t.ensureSemantics();
        await t.pumpWidget(
          _app(Locale(code), const LedgerPageDots(pageCount: 5, page: 1)),
        );
        final dot = (await t.runAsync(() => _dot(code)))!;
        expect(find.bySemanticsLabel(dot), findsOneWidget);
        await t.pumpWidget(
          _app(
            Locale(code),
            const LedgerStepProgress(
              steps: ['Payee', 'Amount', 'Review'],
              currentStep: 1,
            ),
          ),
        );
        final step = (await t.runAsync(() => _step(code)))!;
        expect(find.bySemanticsLabel(step), findsOneWidget);
        semantics.dispose();
      },
    );
  }
}
