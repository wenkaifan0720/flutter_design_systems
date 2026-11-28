// A palette changes colour only: every preset sets its words in Ledger's own
// faces, sizes, leading and tracking, stands on Ledger's corners and
// density, so switching palettes moves nothing on the page. The page itself
// is the proof too: the same parts stand at the same places in every
// palette.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

Map<String, TextStyle> _roles(LedgerThemeData t) => {
  'figure': t.figure,
  'figureMedium': t.figureMedium,
  'figureSmall': t.figureSmall,
  'title': t.title,
  'barTitle': t.barTitle,
  'sheetTitle': t.sheetTitle,
  'wordmark': t.wordmark,
  'body': t.body,
  'rowTitle': t.rowTitle,
  'bodySmall': t.bodySmall,
  'label': t.label,
  'meta': t.meta,
  'amount': t.amount,
  'tab': t.tab,
  'button': t.button,
  'buttonSmall': t.buttonSmall,
  'navLink': t.navLink,
  'link': t.link,
  'pill': t.pill,
  'tag': t.tag,
  'toastText': t.toastText,
  'toastAction': t.toastAction,
  'monogram': t.monogram,
  'initials': t.initials,
  'footnote': t.footnote,
  'search': t.search,
};

String _shape(TextStyle s) =>
    '${s.fontFamily} ${s.fontSize} ${s.height} ${s.letterSpacing} '
    '${s.fontWeight} ${s.fontStyle} ${s.fontFeatures} ${s.leadingDistribution}';

Future<Map<String, Rect>> _page(WidgetTester t, LedgerThemeData theme) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, _) => LedgerHost(
        brightness: theme.brightness,
        theme: theme,
        darkTheme: theme,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 342,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LedgerHead('Colour'),
                const LedgerKeyValue('Status', 'Reading'),
                const LedgerKeyValue('Account', '··4821', monospace: true),
                LedgerButton.filled('Save book', onPressed: () {}),
                const LedgerHead('Density'),
                const LedgerTag('Favourite'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  return {
    for (final words in [
      'COLOUR',
      'Colour',
      'Status',
      'Reading',
      '··4821',
      'Save book',
      'DENSITY',
      'Density',
      'Favourite',
    ])
      if (find.text(words).evaluate().isNotEmpty)
        words: t.getRect(find.text(words)),
  };
}

void main() {
  for (final b in Brightness.values) {
    final quire = LedgerThemeData.preset('quire', b);
    for (final p in LedgerThemeData.palettes.skip(1)) {
      test(
        '${p.id} by ${b.name} keeps Ledger\'s type, corners and density',
        () {
          final t = LedgerThemeData.preset(p.id, b);
          final mine = _roles(t), own = _roles(quire);
          for (final role in own.keys) {
            expect(
              _shape(mine[role]!),
              _shape(own[role]!),
              reason: '${p.id} $role',
            );
          }
          expect(t.density, quire.density, reason: p.id);
          expect(t.shapeScheme, quire.shapeScheme, reason: p.id);
        },
      );
    }
  }

  testWidgets('every palette stands the page where Quire does', (t) async {
    for (final b in Brightness.values) {
      final own = await _page(t, LedgerThemeData.preset('quire', b));
      expect(own, isNotEmpty);
      for (final p in LedgerThemeData.palettes.skip(1)) {
        final mine = await _page(t, LedgerThemeData.preset(p.id, b));
        for (final words in own.keys) {
          expect(
            mine[words],
            own[words],
            reason: '${p.id} ${b.name}: "$words"',
          );
        }
      }
    }
  });
}
