// A swipe row lays no paper of its own: at rest nothing is under it (its acts are built only in the strip a drag
// uncovers), so it shows whatever ground it stands on, a card's or a sheet's as much as the page's, and its words
// keep their place on the row's keyline with no face round them.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Future<void> _pump(WidgetTester t, LedgerThemeData theme, Color ground) =>
    t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: LedgerTheme(
            data: theme,
            child: RepaintBoundary(
              child: ColoredBox(
                color: ground,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: LedgerSwipeActions(
                        trailing: [
                          LedgerSwipeAction('Archive', onPressed: () {}),
                        ],
                        child: LedgerRow(
                          title: 'Route note',
                          subtitle: 'Unread',
                          onTap: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(_loadFonts);

  for (final b in Brightness.values) {
    testWidgets('a swipe row on a slip and on the sunken paper, ${b.name}', (
      t,
    ) async {
      t.view.devicePixelRatio = 2;
      t.view.physicalSize = const Size(780, 400);
      addTearDown(t.view.reset);
      final theme = LedgerThemeData.preset('quire', b);
      for (final ground in [theme.surface, theme.surfaceAlt]) {
        await _pump(t, theme, ground);
        await t.pumpAndSettle();
        // Nothing painted between the ground and the row's words.
        expect(
          find.descendant(
            of: find.byType(LedgerSwipeActions),
            matching: find.byWidgetPredicate(
              (w) => w is ColoredBox && w.color == theme.background,
            ),
          ),
          findsNothing,
        );
        final report = await const DesignFaceInsetCheck(look: 'Ledger').check(
          t.element(find.byType(LedgerSwipeActions)),
          runAsync: t.runAsync,
        );
        expect(report.problems, isEmpty, reason: '$ground');
      }
    });
  }
}
