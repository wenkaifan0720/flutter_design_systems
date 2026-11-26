// A window list's and a tab bar's numbers are written in the reader's
// digits, as Terminal's dates, times and counters are: an Arabic app's
// window list reads "١:اليوم", not "1:اليوم" beside its "٢٠ نوفمبر".
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('ar'),
  supportedLocales: const [Locale('en'), Locale('ar')],
  localizationsDelegates: [
    RawWidgetsLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: TermTheme(
    data: TermThemeData.dark(),
    child: Align(alignment: Alignment.bottomCenter, child: child),
  ),
);

List<String> _painted(WidgetTester tester) => [
  for (final p in tester.renderObjectList<RenderParagraph>(
    find.byType(RichText),
  ))
    p.text.toPlainText(includeSemanticsLabels: false),
];

void main() {
  setUpAll(loadFaces);

  testWidgets('an Arabic window list numbers its windows in its digits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        TermNavigationBar(
          destinations: const [
            TermNavigationDestination(label: 'runs'),
            TermNavigationDestination(label: 'env'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final words = _painted(tester).join(' ');
    expect(words, contains('\u{661}:runs'));
    expect(words, contains('\u{662}:env'));
    expect(words, isNot(contains('1:')));
  });

  testWidgets('an Arabic rail numbers its places in its digits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        TermNavigationRail(
          destinations: const [
            TermNavigationDestination(label: 'runs', glyph: '#'),
            TermNavigationDestination(label: 'env', glyph: '='),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final words = _painted(tester);
    expect(words, containsAll(['\u{661}', '\u{662}']));
    expect(words, isNot(contains('1')));
  });

  testWidgets('an Arabic tab bar numbers its tabs in its digits', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TermTabBar(
          tabs: const ['steps', 'log'],
          selectedIndex: 0,
          onTap: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final words = _painted(tester);
    expect(words, containsAll(['\u{661}', '\u{662}']));
    expect(words, isNot(contains('1')));
  });
}
