// The gaps the Keel app found in Ledger's structure, register, chrome, states
// and charts, each pinned to the source's value: its stylesheet, its pages or
// the capture.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- The frame (as display_test.dart's) ---------------------------------------

const Size _phone = Size(390, 844);
const Size _desktop = Size(1440, 900);
const Key _frame = ValueKey<String>('frame');

Widget _host(Widget child, Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => LedgerHost(brightness: brightness, child: page!),
  home: Builder(
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: LedgerLayout.gutter(context),
        vertical: 24,
      ),
      child: KeyedSubtree(key: _frame, child: child),
    ),
  ),
);

/// A whole page (a screen, a sidebar) in the light appearance.
Widget _page(Widget child, {String title = 'Keel'}) => MaterialApp(
  title: title,
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      LedgerHost(brightness: Brightness.light, child: page!),
  home: KeyedSubtree(key: _frame, child: child),
);

void _size(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  Size size = _phone,
  Brightness brightness = Brightness.light,
}) async {
  _size(t, size);
  await t.pumpWidget(_host(child, brightness));
}

LedgerThemeData _theme(WidgetTester t) =>
    t.element(find.byKey(_frame)).ledgerTheme;

Future<void> _everywhere(
  WidgetTester t,
  Widget child, [
  void Function(bool wide, LedgerThemeData theme)? check,
]) async {
  for (final size in const [_phone, _desktop]) {
    for (final brightness in Brightness.values) {
      await _pump(t, child, size: size, brightness: brightness);
      final where = '${size.width.round()} wide, ${brightness.name}';
      expect(t.takeException(), isNull, reason: where);
      _expectWordsFit(t, where);
      check?.call(size == _desktop, _theme(t));
    }
  }
}

void _expectWordsFit(WidgetTester t, String where) {
  for (final p in t.allRenderObjects.whereType<RenderParagraph>()) {
    if (!p.hasSize) continue;
    final words = p.text.toPlainText();
    final oneLine = !p.softWrap || p.maxLines == 1;
    if (oneLine) {
      expect(
        p.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(p.size.width + .5),
        reason: '"$words" is cut short ($where)',
      );
    } else {
      expect(p.didExceedMaxLines, isFalse, reason: '"$words" ($where)');
    }
    expect(
      p.getMinIntrinsicHeight(p.size.width),
      lessThanOrEqualTo(p.size.height + .5),
      reason: '"$words" is cut at its foot ($where)',
    );
  }
}

SemanticsNode _node(WidgetTester t, Pattern label) =>
    t.getSemantics(find.bySemanticsLabel(label));

RenderParagraph _paragraph(WidgetTester t, String words) =>
    t.renderObject<RenderParagraph>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == words,
      ),
    );

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    // The look names its faces as the package that bundles them registers
    // them (ledgerFontFamily); a family a package already names keeps it.
    final loader = FontLoader(
      family.startsWith('packages/') ? family : ledgerFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

const _five = [
  LedgerNavItem(LucideIcons.house, 'Home'),
  LedgerNavItem(LucideIcons.chartPie, 'Spending'),
  LedgerNavItem.act(LucideIcons.arrowRightLeft, 'Move', actLabel: 'Move money'),
  LedgerNavItem(LucideIcons.target, 'Goals'),
  LedgerNavItem(LucideIcons.creditCard, 'Cards'),
];

void main() {
  setUpAll(_loadFonts);
  setUpAll(_stillMotion);
  tearDownAll(_movingMotion);

  // --- 5: the side bar's current act ------------------------------------------

  group('LedgerSideBar', () {
    BoxDecoration act(WidgetTester t) => t
        .widgetList<Container>(
          find.descendant(
            of: find.byType(LedgerSideBar),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.color == _theme(t).accent);

    testWidgets('the current act is ringed: the paper gap over the green', (
      t,
    ) async {
      _size(t, _desktop);
      Widget bar(int selected) => _page(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: LedgerChromeMetrics.sideWidth,
            height: _desktop.height,
            child: LedgerSideBar(
              items: _five,
              selectedIndex: selected,
              onDestinationSelected: (_) {},
              brand: 'Keel',
            ),
          ),
        ),
      );
      await t.pumpWidget(bar(2));
      final theme = _theme(t);
      // `.btn-move.is-on`: `0 0 0 3px paper-lo, 0 0 0 4px
      // green`; CSS paints the first on top, Flutter the last.
      final rings = act(t).boxShadow!;
      expect(rings, hasLength(2));
      expect(rings.first.color, theme.accent);
      expect(rings.first.spreadRadius, 4);
      expect(rings.last.color, theme.sideBarFill);
      expect(rings.last.spreadRadius, 3);
      // Not current: the green drop alone.
      await t.pumpWidget(bar(0));
      expect(act(t).boxShadow, theme.primaryShadow);
    });
  });

  // --- the key-value's action ---------------------------------------------------

  group('LedgerKeyValue', () {
    testWidgets('its action is its own button, outside the key and value', (
      t,
    ) async {
      var changed = 0;
      await _everywhere(
        t,
        LedgerKeyValue(
          'Category',
          'Dining out',
          action: LedgerButton(
            'Change',
            size: LedgerButtonSize.small,
            onPressed: () => changed += 1,
          ),
        ),
        (wide, theme) {
          // The key and the value one node, the act's words not in it.
          expect(_node(t, 'Category\nDining out'), isNotNull);
          expect(
            _node(t, 'Change'),
            isSemantics(label: 'Change', isButton: true, hasTapAction: true),
          );
          // The value and the act still share a baseline, 10 apart.
          final value = t.getRect(find.text('Dining out'));
          final act = t.getRect(find.text('Change'));
          expect(act.left, greaterThan(value.right));
        },
      );
      // A tap at the act's node lands on it.
      await t.tapAt(t.getRect(find.bySemanticsLabel('Change')).center);
      expect(changed, 1);
    });
  });

  // --- 7: a form's column under the phone's bar -------------------------------

  group('LedgerScreen', () {
    testWidgets("a form's column stands 24 under a pushed page's bar", (
      t,
    ) async {
      const body = ValueKey<String>('body');
      Future<double> top({required bool form}) async {
        _size(t, _phone);
        await t.pumpWidget(
          LedgerPreview(
            presentation: LedgerPresentation.pushed,
            child: form
                ? const LedgerScreen.form(
                    topBar: LedgerTopBar(title: 'Transfer', backLabel: 'Move'),
                    body: SizedBox(key: body, height: 40),
                  )
                : const LedgerScreen(
                    topBar: LedgerTopBar(title: 'Transfer', backLabel: 'Move'),
                    body: SizedBox(key: body, height: 40),
                  ),
          ),
        );
        await t.pumpAndSettle();
        return t.getRect(find.byKey(body)).top -
            t.getRect(find.byType(LedgerScreen)).top;
      }

      // `.form-col` 24 under the 60 bar; `.cell-first` 28.
      expect(await top(form: true), 60 + 24);
      expect(await top(form: false), 60 + 28);
    });
  });

  // --- 11: a lone word stands whole -----------------------------------------

  group('LedgerRow', () {
    testWidgets('a word wider than its room stands whole', (t) async {
      await _everywhere(
        t,
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 160,
            child: LedgerRows(
              children: [
                LedgerRow(
                  leading: LedgerGlyph(LucideIcons.wallet),
                  title: 'Everyday',
                  value: LedgerAmount(6248.3),
                ),
                LedgerRow(
                  title: 'Linden Court Apartments',
                  value: LedgerAmount(1850),
                ),
              ],
            ),
          ),
        ),
        (wide, theme) {
          // One line of 20, as CSS breaks no word.
          final lone = _paragraph(t, 'Everyday');
          expect(lone.size.height, 20);
          expect(
            lone.size.width,
            greaterThanOrEqualTo(lone.getMinIntrinsicWidth(double.infinity)),
          );
          // A name of words still wraps, at its spaces.
          final long = _paragraph(t, 'Linden Court Apartments');
          expect(long.size.height, greaterThan(20));
          expect(
            long.size.width,
            greaterThanOrEqualTo(long.getMinIntrinsicWidth(double.infinity)),
          );
        },
      );
    });
  });

  // --- 12: the measures -------------------------------------------------------

  group('measures', () {
    testWidgets("a figure's cents deepen its line as CSS's do", (t) async {
      await _everywhere(
        t,
        const Column(
          children: [
            LedgerFacts(
              facts: [
                LedgerFact.money('Left', 213.88, note: '3 days to go'),
                LedgerFact('Pace', '90%', note: 'Day 28 of 31; 92% spent'),
              ],
            ),
            LedgerFacts(
              columns: LedgerFactColumns.three,
              ruled: true,
              facts: [
                LedgerFact.money('Spent', 2486.12, note: '87 purchases'),
                LedgerFact('Moves', '4', note: 'Own accounts'),
                LedgerFact.money('Moved', 1830.22, note: 'Own accounts'),
              ],
            ),
          ],
        ),
        (wide, theme) {
          // `.fact .v` 28px/30px (32/34 stacked, 24/28 three across), the
          // cents 18 (15) on the same px line: their
          // inline box's foot stands under the figure's, 33.5 in all in
          // Chrome (39 stacked, 31.5 three across; the capture's
          // three-across cell, everyday's facts, measures 104: a 31 line).
          final two = _paragraph(t, '\$213.88').size.height;
          final three = _paragraph(t, '\$2,486.12').size.height;
          expect(_paragraph(t, '90%').size.height, wide ? 34 : 30);
          expect(_paragraph(t, '4').size.height, wide ? 34 : 28);
          expect(two, closeTo(wide ? 39 : 33.5, .6));
          expect(three, closeTo(wide ? 39 : 31.5, .6));
        },
      );
    });

    testWidgets("a day's head stands in the body's line", (t) async {
      await _everywhere(
        t,
        LedgerDayGroup('Today', note: 'Wed, Oct 28', net: -9.65, rows: []),
        (wide, theme) {
          // `.dayhead` 10 0 9 (12 0 10) over its rule; its net a span in
          // the body's 15/1.45 (21.75) line: 41.75 tall on a phone, as the
          // capture's head (283 to its rule at 324.75).
          expect(
            t.getSize(find.byType(LedgerDayGroup)).height,
            closeTo(wide ? 44.75 : 41.75, .3),
          );
        },
      );
    });

    testWidgets('a day stands 4 under its month rule', (t) async {
      await _everywhere(
        t,
        LedgerRegister(
          children: [
            const LedgerMonthRule('September 2026', note: 'Last month'),
            LedgerDayGroup('Wed, Sep 30', net: -18.4, rows: const []),
          ],
        ),
        (wide, theme) => expect(
          // `.month-rule + .daygroup { margin-top: 4px }`.
          t.getRect(find.byType(LedgerDayGroup)).top -
              t.getRect(find.byType(LedgerMonthRule)).bottom,
          4,
        ),
      );
    });
  });

  // --- 13: keys on the links ---------------------------------------------------

  group('keys', () {
    testWidgets("a head's link carries its key", (t) async {
      var opened = 0;
      await _pump(
        t,
        LedgerHead(
          'Upcoming · 15 days',
          note: 'All bills',
          onTap: () => opened += 1,
          linkKey: const ValueKey<String>('home-bills'),
        ),
      );
      expect(find.byKey(const ValueKey<String>('home-bills')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey<String>('home-bills')));
      expect(opened, 1);
    });

    testWidgets("each quick action's link carries its key", (t) async {
      for (final size in const [_phone, _desktop]) {
        final opened = <String>[];
        await _pump(
          t,
          LedgerQuickActions(
            actions: [
              for (final (icon, label) in const [
                (LucideIcons.arrowRightLeft, 'Transfer'),
                (LucideIcons.receipt, 'Pay a bill'),
              ])
                LedgerQuickAction(
                  icon,
                  label,
                  key: ValueKey<String>(label),
                  onTap: () => opened.add(label),
                ),
            ],
          ),
          size: size,
        );
        await t.tap(find.byKey(const ValueKey<String>('Pay a bill')));
        await t.tap(find.byKey(const ValueKey<String>('Transfer')));
        expect(opened, ['Pay a bill', 'Transfer'], reason: '$size');
      }
    });
  });

  // --- 15: the masthead's heading ---------------------------------------------

  group('LedgerTopBar', () {
    testWidgets("a heading stands in the masthead's title place", (t) async {
      const month = ValueKey<String>('month');
      for (final size in const [_phone, _desktop]) {
        _size(t, size);
        final wide = size == _desktop;
        await t.pumpWidget(
          _page(
            LedgerScreen(
              topBar: LedgerTopBar(
                title: 'Spending',
                meta: wide ? 'Spending · October 1–28, 2026' : null,
                heading: const SizedBox(key: month, height: 44),
              ),
              body: const Text('body'),
            ),
          ),
        );
        expect(t.takeException(), isNull);
        final heading = t.getRect(find.byKey(month));
        // The title's words give way to it.
        expect(find.text('Spending'), findsNothing, reason: '$size');
        if (wide) {
          // `.monthbar { margin-top: 10px }` under the meta.
          final meta = t.getRect(find.text('SPENDING · OCTOBER 1–28, 2026'));
          expect(heading.top, meta.bottom + 10);
        } else {
          // `.masthead` 24 under the 60 strip.
          expect(heading.top, 60 + 24);
          expect(heading.width, 390 - 2 * 24);
        }
      }
    });
  });

  // --- 16: the empty page on the desktop --------------------------------------

  group('LedgerEmptyState', () {
    testWidgets("the desktop's blank page: padded 36 36 32 56, title 44", (
      t,
    ) async {
      await _everywhere(t, const LedgerEmptyState(title: 'Nothing for'), (
        wide,
        theme,
      ) {
        final page = t.getRect(find.byType(LedgerEmptyState));
        final title = t.getRect(find.text('Nothing for'));
        // The empty page's padding, the desktop's or a phone's.
        expect(title.left - page.left, wide ? 56 : 34);
        expect(title.top - page.top, wide ? 36 : 26);
        expect(page.bottom - title.bottom, wide ? 32 : 24);
        expect(title.height, wide ? 46 : 34);
      });
    });
  });

  // --- 17: the pair under a head --------------------------------------------

  group('LedgerFacts', () {
    testWidgets('the pair draws the ink rule only where no head stands', (
      t,
    ) async {
      for (final ruled in [false, true]) {
        await _everywhere(
          t,
          LedgerFacts(
            columns: LedgerFactColumns.pair,
            ruled: ruled,
            facts: const [
              LedgerFact('Visits', '13', note: 'at Blue Fern Café'),
              LedgerFact.money('Total', 84.25, note: 'in October'),
            ],
          ),
          (wide, theme) {
            final outer = t.widget<Container>(
              find
                  .descendant(
                    of: find.byType(LedgerFacts),
                    matching: find.byType(Container),
                  )
                  .first,
            );
            final top = (outer.decoration as BoxDecoration?)?.border?.top;
            // `.head:not(.desk) + .facts` drops it.
            expect(
              top?.color,
              ruled ? theme.headRule : isNull,
              reason: 'ruled $ruled, wide $wide',
            );
          },
        );
      }
    });
  });

  // --- 18: the net worth's keys -------------------------------------------------

  group('LedgerNetWorthChart', () {
    testWidgets('a key wider than its slot stands whole under its point', (
      t,
    ) async {
      await _everywhere(
        t,
        const LedgerNetWorthChart(
          values: [61.4, 62.9, 64, 66.1, 68, 70.2, 71, 73.4, 75, 76.2, 77.5],
          low: 56,
          high: 82,
          grid: [LedgerGridLine(80, '80k')],
          endLabel: 'Oct 78.18k',
          months: ['2024', '', '', '', '', '2025', '', '', '', '', 'Now'],
        ),
        (wide, theme) {
          final chart = t.getRect(find.byType(LedgerNetWorthChart));
          // `.xlabs`: 11 slots and the 30 gutter (36 from 1024).
          final slot = (chart.width - (wide ? 36 : 30)) / 11;
          final year = t.getRect(find.text('2025'));
          expect(year.center.dx - chart.left, closeTo(5.5 * slot, .5));
          expect(year.width, greaterThan(slot));
        },
      );
    });
  });

  // --- 19: the More link ------------------------------------------------------

  group('LedgerMoreLink', () {
    testWidgets('a link on its own: green capitals, its chevron, its key', (
      t,
    ) async {
      var opened = 0;
      await _everywhere(
        t,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LedgerMoreLink(
            'See all 13 visits',
            key: const ValueKey<String>('txn-merchant'),
            onTap: () => opened += 1,
          ),
        ),
        (wide, theme) {
          expect(
            _node(t, 'See all 13 visits'),
            isSemantics(isLink: true, hasTapAction: true),
          );
          expect(find.text('SEE ALL 13 VISITS'), findsOneWidget);
          final style = _paragraph(t, 'SEE ALL 13 VISITS').text.style!;
          expect(style.color, theme.accentText);
          expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
        },
      );
      await t.tap(find.byKey(const ValueKey<String>('txn-merchant')));
      expect(opened, 1);
    });
  });
}

/// Reduced motion on, as a reader who asked for it has it: every Ledger
/// change lands at once, so a test reads the settled frame.
void _stillMotion() =>
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );

/// The platform's own motion back.
void _movingMotion() => TestWidgetsFlutterBinding.instance.platformDispatcher
    .clearAccessibilityFeaturesTestValue();
