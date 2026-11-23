// What Ledger gains on ui_core 0.3.0's behaviours: the raised dialog opens on its safe act
// and Escape closes it; the tabs and the navigation frame are one tab stop with the arrows, the frame's tabs a tab bar
// to a screen reader with its act a button beside it; the combobox runs a search, its failure and a retry; a wheel
// steps with the keys; the tooltip shows on the keyboard's focus (32 tall on a phone) and Escape hides it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:ledger_ui/src/ledger/internal/shell_faces.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _app(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      LedgerHost(brightness: Brightness.light, child: page!),
  home: home,
);

Future<void> _at(WidgetTester t, Size size, Widget app) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(app);
  await t.pumpAndSettle();
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pumpAndSettle();
}

void main() {
  group('the raised dialog', () {
    for (final (type, enter) in [
      (LedgerDialogType.destructive, false),
      (LedgerDialogType.confirm, true),
    ]) {
      testWidgets(
        'a ${type.name} one opens on its safe act (Enter answers $enter); Escape closes it unanswered',
        (t) async {
          final answers = <bool?>[];
          await _at(
            t,
            const Size(1440, 900),
            _app(
              Builder(
                builder: (context) => Center(
                  child: LedgerButton(
                    'Ask',
                    onPressed: () async => answers.add(
                      await LedgerDialog.show(
                        context,
                        title: 'Delete the entry?',
                        type: type,
                        confirmLabel: 'Delete',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.tap(find.text('Ask'));
          await t.pumpAndSettle();
          await _key(t, LogicalKeyboardKey.enter);
          expect(find.text('Delete the entry?'), findsNothing);
          await t.tap(find.text('Ask'));
          await t.pumpAndSettle();
          await _key(t, LogicalKeyboardKey.escape);
          expect(find.text('Delete the entry?'), findsNothing);
          expect(answers, [enter, null]);
        },
      );
    }
  });

  testWidgets(
    'the tabs are one tab stop: the arrows move the choice (wrapping) and each tab says its count and place',
    (t) async {
      final semantics = t.ensureSemantics();
      var tab = 0;
      await _at(
        t,
        const Size(1440, 900),
        _app(
          Material(
            child: StatefulBuilder(
              builder: (context, set) => LedgerTabs(
                tabs: const ['Overview', 'Entries', 'Notes'],
                counts: const [null, 12, 3],
                selectedIndex: tab,
                onSelected: (i) => set(() => tab = i),
              ),
            ),
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Entries, 12\nTab 2 of 3$')),
        findsOneWidget,
      );
      await _key(t, LogicalKeyboardKey.tab);
      await _key(t, LogicalKeyboardKey.arrowRight);
      expect(tab, 1);
      await _key(t, LogicalKeyboardKey.end);
      expect(tab, 2);
      await _key(t, LogicalKeyboardKey.arrowRight);
      expect(tab, 0, reason: 'the arrows wrap');
      semantics.dispose();
    },
  );

  group('the navigation frame', () {
    const items = [
      LedgerNavItem(LucideIcons.house, 'Home'),
      LedgerNavItem(LucideIcons.chartPie, 'Spending'),
      LedgerNavItem(LucideIcons.settings, 'Settings'),
    ];
    for (final (name, size) in const [
      ('tab bar', Size(390, 844)),
      ('rail', Size(800, 900)),
      ('side bar', Size(1440, 900)),
    ]) {
      testWidgets(
        'its $name is one tab stop: the arrows move along it and Enter chooses',
        (t) async {
          final semantics = t.ensureSemantics();
          var chosen = 0;
          var acted = 0;
          await _at(
            t,
            size,
            _app(
              StatefulBuilder(
                builder: (context, set) => LedgerNavigationFrame(
                  destinations: items,
                  selectedIndex: chosen,
                  onDestinationSelected: (i) => set(() => chosen = i),
                  brand: 'Quill',
                  action: ShellAction(
                    icon: LucideIcons.plus,
                    label: 'New entry',
                    onPressed: (_) => acted++,
                  ),
                  body: const SizedBox.expand(),
                ),
              ),
            ),
          );
          expect(
            find.bySemanticsLabel(RegExp(r'^Spending\nTab 2 of 3$')),
            findsOneWidget,
          );
          // The act is a button, never one of the tabs.
          expect(
            t.getSemantics(find.bySemanticsLabel('New entry')),
            isSemantics(isButton: true, hasTapAction: true),
          );
          await t.tap(find.byIcon(LucideIcons.plus));
          await t.pumpAndSettle();
          expect(acted, 1);
          // Tab reaches the destinations' one stop (past the wordmark and the act), on the chosen one.
          bool onBar() {
            final at = FocusManager.instance.primaryFocus?.context;
            if (at is! Element ||
                (at.findAncestorWidgetOfExactType<LedgerNavBar>() == null &&
                    at.findAncestorWidgetOfExactType<LedgerSideBar>() ==
                        null)) {
              return false;
            }
            var face = false;
            void visit(Element e) {
              if (e.widget is LedgerShellFace) {
                face = true;
              } else {
                e.visitChildren(visit);
              }
            }

            at.visitChildren(visit);
            return face;
          }

          for (var i = 0; i < 12 && !onBar(); i++) {
            await _key(t, LogicalKeyboardKey.tab);
          }
          expect(onBar(), isTrue);
          await _key(
            t,
            size.width < 600
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowDown,
          );
          expect(chosen, 0, reason: 'moving focus chooses nothing');
          await _key(t, LogicalKeyboardKey.enter);
          expect(chosen, 1);
          semantics.dispose();
        },
      );
    }
  });

  testWidgets(
    "the combobox's search: it says it failed, offers Try again, and the retry finds",
    (t) async {
      var calls = 0;
      var failing = true;
      await _at(
        t,
        const Size(1440, 900),
        _app(
          Material(
            child: Center(
              child: SizedBox(
                width: 320,
                child: LedgerCombobox<String>(
                  labelText: 'Payee',
                  search: (query) async {
                    calls++;
                    if (failing) throw StateError('offline');
                    return const ['Blue Fern Café'];
                  },
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await t.enterText(find.byType(EditableText), 'Bl');
      await t.pumpAndSettle();
      final words = RawWidgetsLocalizations.of(
        t.element(find.byType(EditableText)),
      );
      expect(find.text(words.searchFailedMessage), findsOneWidget);
      failing = false;
      final before = calls;
      await t.tap(find.text(words.retryButtonLabel));
      await t.pumpAndSettle();
      expect(calls, before + 1);
      expect(find.text('Blue Fern Café'), findsOneWidget);
    },
  );

  testWidgets('a wheel steps with the keys and says its value', (t) async {
    final semantics = t.ensureSemantics();
    var value = DateTime(2026, 11, 17, 9, 30);
    await _at(
      t,
      const Size(390, 844),
      _app(
        Material(
          child: Center(
            child: StatefulBuilder(
              builder: (context, set) => LedgerDatePicker(
                labelText: 'Due',
                value: value,
                mode: LedgerDatePickerMode.time,
                presentation: LedgerDatePickerPresentation.wheel,
                onChanged: (v) => set(() => value = v),
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      t.getSemantics(find.bySemanticsLabel(RegExp('Hour'))),
      isSemantics(value: '9', hasIncreaseAction: true),
    );
    await _key(t, LogicalKeyboardKey.tab);
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(value, DateTime(2026, 11, 17, 10, 30));
    semantics.dispose();
  });

  group("a page on ui_core's bottom sheet", () {
    const body = ValueKey<String>('body');

    testWidgets(
      'in a preview stage shorter than the window it stands its full height',
      (t) async {
        await _at(
          t,
          const Size(1024, 2000),
          _app(
            const Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 390,
                height: 560,
                child: LedgerPreview(
                  presentation: LedgerPresentation.sheet,
                  child: SizedBox.expand(key: body),
                ),
              ),
            ),
          ),
        );
        final page = t.getRect(find.byKey(body));
        // Its foot on the stage's and the barrier's middle under it: the
        // keyboard is read from the navigator's screen, never inferred from
        // the window's height less the stage's.
        expect(page.bottom, moreOrLessEquals(560, epsilon: 1));
        expect(page.contains(const Offset(195, 280)), isTrue, reason: '$page');
      },
    );

    testWidgets(
      'over the keyboard it keeps its top and stands on the keyboard',
      (t) async {
        await _at(
          t,
          const Size(390, 844),
          _app(
            Builder(
              builder: (context) => Center(
                child: LedgerButton(
                  'Open',
                  onPressed: () => Navigator.of(context).push(
                    LedgerSheet.pageRoute<void>(
                      context: context,
                      builder: (_) => const SizedBox.expand(key: body),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('Open'));
        await t.pumpAndSettle();
        final before = t.getRect(find.byKey(body));
        expect(before.bottom, moreOrLessEquals(844, epsilon: 1));
        t.view.viewInsets = const FakeViewPadding(bottom: 300);
        await t.pumpAndSettle();
        final after = t.getRect(find.byKey(body));
        expect(after.top, moreOrLessEquals(before.top, epsilon: 0.5));
        expect(after.bottom, moreOrLessEquals(544, epsilon: 1));
      },
    );
  });

  testWidgets('the tooltip shows on the keyboard focus and Escape hides it', (
    t,
  ) async {
    await _at(
      t,
      const Size(1440, 900),
      _app(
        Center(
          child: LedgerTooltip(
            message: 'Export as CSV',
            child: LedgerIconButton(
              LucideIcons.download,
              semanticLabel: 'Export',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await _key(t, LogicalKeyboardKey.tab);
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(find.text('Export as CSV'), findsOneWidget);
    final slip = t.getRect(
      find
          .ancestor(
            of: find.text('Export as CSV'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(slip.height, 32, reason: "a phone's least, as 0.2.1's slip stood");
    await _key(t, LogicalKeyboardKey.escape);
    expect(find.text('Export as CSV'), findsNothing);
  });
}
