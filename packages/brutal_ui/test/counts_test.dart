// The counts a data table speaks under its pages: how many rows its filter
// leaves, and how many are selected. Each is given its count by the
// localizations (the rows by BrutalLocalizations, the selection by ui_core's
// DesignLocalizations), so English says "1 row" and "2 rows", and a language
// with more plural forms (Polish here: one, few, many) picks its own from an
// app's own words.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// An app's Polish, as it would give it.
class _Polish extends BrutalLocalizations {
  const _Polish();

  @override
  String rowCount(int count) {
    final last = count % 10;
    final tens = count % 100;
    if (count == 1) return '1 wiersz';
    if (last >= 2 && last <= 4 && (tens < 12 || tens > 14)) {
      return '$count wiersze';
    }
    return '$count wierszy';
  }
}

class _Words extends LocalizationsDelegate<BrutalLocalizations> {
  const _Words(this.words);

  final BrutalLocalizations words;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<BrutalLocalizations> load(Locale locale) =>
      SynchronousFuture<BrutalLocalizations>(words);

  @override
  bool shouldReload(_Words old) => old.words != words;
}

Widget _app(Widget page, {BrutalLocalizations? words}) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: words == null ? const Locale('en') : const Locale('pl'),
  supportedLocales: const [Locale('en'), Locale('pl')],
  localizationsDelegates: [
    if (words != null) _Words(words),
    DesignLocalizations.delegate,
  ],
  builder: (context, _) => BrutalTheme(
    data: BrutalThemeData.light(),
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 600, child: page),
    ),
  ),
);

// [rows] rows on pages of one, so the footer always stands.
BrutalTableController<int> _table(int rows) => BrutalTableController<int>(
  rows: [for (var i = 1; i <= rows; i++) i],
  columns: const [BrutalDataColumn(id: 'n', label: 'Number')],
  pageSize: 1,
);

Future<BrutalTableController<int>> _pump(
  WidgetTester tester,
  int rows, {
  BrutalLocalizations? words,
}) async {
  final table = _table(rows);
  addTearDown(table.dispose);
  await tester.pumpWidget(
    _app(
      BrutalDataTable<int>(controller: table, cell: (n, _) => '$n'),
      words: words,
    ),
  );
  return table;
}

void main() {
  test('English counts its rows in the singular and the plural', () {
    const words = BrutalLocalizations();
    expect(words.rowCount(1), '1 row');
    expect(words.rowCount(2), '2 rows');
  });

  for (final (words, rows, said) in [
    (null, 2, '2 rows'),
    (null, 5, '5 rows'),
    (const _Polish(), 2, '2 wiersze'),
    (const _Polish(), 5, '5 wierszy'),
    (const _Polish(), 22, '22 wiersze'),
  ]) {
    testWidgets('a table of $rows rows says "$said"', (tester) async {
      await _pump(tester, rows, words: words);
      expect(find.text(said), findsOneWidget);
    });
  }

  for (final (words, chosen, said) in [
    (null, 1, '1 item selected'),
    (null, 2, '2 items selected'),
    (const _Polish(), 1, '1 wybrany element'),
    (const _Polish(), 2, '2 wybrane elementy'),
    (const _Polish(), 5, '5 wybranych elementów'),
  ]) {
    testWidgets('a table with $chosen selected says "$said"', (tester) async {
      final table = await _pump(tester, 6, words: words);
      for (var n = 1; n <= chosen; n++) {
        table.toggle(n);
      }
      await tester.pump();
      expect(find.text(said), findsOneWidget);
    });
  }

  testWidgets('Polish counts one row in its own form', (tester) async {
    // A table on one page shows no count, so the one row is read off the
    // words the table would use.
    late BuildContext context;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
        words: const _Polish(),
      ),
    );
    expect(BrutalLocalizations.of(context).rowCount(1), '1 wiersz');
    expect(BrutalLocalizations.of(context).rowCount(12), '12 wierszy');
  });
}
