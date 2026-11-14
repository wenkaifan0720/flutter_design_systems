// Gaps the Keel app found: the dashed frame, the menu, the suggestion, the
// category tile, option and mini, the icon picker, Move's ways, allocation and
// holding rows, two acts in a row, the member card and the inked monogram. Each
// is pumped on a phone and at desktop width in both appearances, measured
// against the source's stylesheet, and read back through its semantics. Helpers
// copied from display_test.dart.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- The frame (display_test.dart) -------------------------------------------

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

List<String> _spoken(WidgetTester t) {
  final words = <String>[];
  void walk(SemanticsNode node) {
    if (node.isMergedIntoParent) return;
    final data = node.getSemanticsData();
    if (data.label.isNotEmpty) words.add(data.label);
    if (data.value.isNotEmpty) words.add(data.value);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  for (final view in t.binding.renderViews) {
    final root = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (root != null) walk(root);
  }
  return words;
}

SemanticsNode _node(WidgetTester t, Pattern label) =>
    t.getSemantics(find.bySemanticsLabel(label));

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

Widget _atStart(Widget child) =>
    Align(alignment: AlignmentDirectional.centerStart, child: child);

BoxDecoration _decorationOf(WidgetTester t, Finder f) =>
    t.widget<Container>(f).decoration! as BoxDecoration;

// --- The pilot's figures -------------------------------------------------------

/// the sample data spending.by_month, newest first.
const _months = [
  ('October 2026', 2486.12),
  ('September 2026', 2644.9),
  ('August 2026', 2512.4),
];

/// the sample data categories (the gallery's kitCategories): icon, name, spent,
/// budget.
const _categories = [
  (LucideIcons.keyRound, 'Rent & home', 1150.0, 1150.0),
  (LucideIcons.shoppingBasket, 'Groceries', 412.36, 450.0),
  (LucideIcons.utensils, 'Dining out', 286.4, 250.0),
];

void main() {
  setUpAll(_loadFonts);

  group('marks', () {
    testWidgets('the dashed frame dashes the faint ink round its padding', (
      t,
    ) async {
      await _everywhere(
        t,
        const LedgerDashedFrame(
          padding: EdgeInsets.all(18),
          child: Text('New goal'),
        ),
        (wide, theme) {
          final frame = t.getRect(find.byType(LedgerDashedFrame));
          final words = t.getRect(find.text('New goal'));
          // `.goal-new { padding: 18px }`.
          expect(words.left - frame.left, 18);
          expect(words.top - frame.top, 18);
          final paint = t.widget<CustomPaint>(
            find.descendant(
              of: find.byType(LedgerDashedFrame),
              matching: find.byType(CustomPaint),
            ),
          );
          expect(paint.painter, isA<CustomPainter>());
          expect(find.bySemanticsLabel('New goal'), findsOneWidget);
        },
      );
    });

    testWidgets('a chosen glyph is the green ring, wash and glyph', (t) async {
      await _everywhere(
        t,
        _atStart(
          const LedgerGlyph(
            LucideIcons.utensils,
            tone: LedgerGlyphTone.selected,
            size: LedgerGlyphSize.pick,
          ),
        ),
        (wide, theme) {
          final d = t.widget<DecoratedBox>(
            find.descendant(
              of: find.byType(LedgerGlyph),
              matching: find.byType(DecoratedBox),
            ),
          );
          final box = d.decoration as BoxDecoration;
          expect(box.color, theme.accentSubtle);
          expect((box.border! as Border).top.color, theme.accent);
          expect(t.widget<Icon>(find.byType(Icon)).color, theme.accent);
          expect(t.getSize(find.byType(LedgerGlyph)), const Size(36, 36));
        },
      );
    });

    testWidgets('the inked monogram: 72 (84 wide), paper letters on the ink', (
      t,
    ) async {
      await _everywhere(
        t,
        _atStart(
          const LedgerMonogram(
            'Maren Holt',
            tone: LedgerMonogramTone.inked,
            size: LedgerMonogramSize.member,
          ),
        ),
        (wide, theme) {
          expect(
            t.getSize(find.byType(LedgerMonogram)),
            Size.square(wide ? 84 : 72),
          );
          final letters = t.widget<Text>(find.text('MH'));
          expect(letters.style?.color, theme.textInverse);
          expect(letters.style?.fontSize, wide ? 32 : 30);
          final box = _decorationOf(
            t,
            find.descendant(
              of: find.byType(LedgerMonogram),
              matching: find.byType(Container),
            ),
          );
          expect(box.color, theme.surfaceInverse);
          // 3 of the slip's paper inside 1 of the ink.
          expect(box.boxShadow!.map((s) => s.spreadRadius), [4, 3]);
          expect(box.boxShadow!.last.color, theme.surface);
        },
      );
    });
  });

  group('choices', () {
    testWidgets('the menu: 300 wide, 46 a month, the chosen one checked', (
      t,
    ) async {
      var picked = '';
      await _everywhere(
        t,
        _atStart(
          LedgerMenu(
            head: 'Spent by month',
            semanticLabel: 'Months',
            items: [
              for (final (i, m) in _months.indexed)
                LedgerMenuItem(
                  m.$1,
                  amount: m.$2,
                  selected: i == 0,
                  onTap: () => picked = m.$1,
                  key: i == 0 ? const ValueKey('keep-month') : null,
                ),
            ],
          ),
        ),
        (wide, theme) {
          expect(t.getSize(find.byType(LedgerMenu)).width, 300);
          expect(find.text('SPENT BY MONTH'), findsOneWidget);
          final item = find.ancestor(
            of: find.text('September 2026'),
            matching: find.byType(Container),
          );
          expect(t.getSize(item.first).height, 46);
          expect(find.byIcon(LucideIcons.check), findsOneWidget);
          expect(
            t.widget<Text>(find.text('October 2026')).style?.fontWeight,
            FontWeight.w600,
          );
          final on = _node(t, 'October 2026');
          expect(on, isSemantics(isSelected: true));
          expect(on.getSemanticsData().value, r'$2,486.12');
          expect(_spoken(t), contains('Months'));
        },
      );
      await t.tap(find.text('August 2026'));
      expect(picked, 'August 2026');
      // A walkthrough's key lands on its item.
      await t.tap(find.byKey(const ValueKey('keep-month')));
      expect(picked, 'October 2026');
    });

    testWidgets('the suggestion: the green figure, its why, one Use button', (
      t,
    ) async {
      var used = 0;
      await _everywhere(
        t,
        LedgerSuggestion(
          amount: 275,
          text: 'Your September and October average, rounded to \$5.',
          onTap: () => used++,
        ),
        (wide, theme) {
          expect(t.widget<Text>(find.text(r'$275')).style?.color, theme.accent);
          expect(t.widget<Text>(find.text(r'$275')).style?.fontSize, 32);
          expect(find.text('USE'), findsOneWidget);
          expect(find.bySemanticsLabel(r'Use the suggested $275'), findsOne);
          final go = find.ancestor(
            of: find.text('USE'),
            matching: find.byType(Container),
          );
          expect(t.getSize(go.first).height, 32);
        },
      );
      await t.tap(find.text('USE'));
      expect(used, 1);
    });

    testWidgets('category tiles: two to a line, 8 apart, over in vermilion', (
      t,
    ) async {
      await _everywhere(
        t,
        LedgerCategoryTiles(
          tiles: [
            // Four, so no tile stands alone on its line (`ledgerPerLine`
            // sets three one to a line on a phone).
            for (final c in [
              ..._categories,
              (LucideIcons.bus, 'Transport', 96.0, 120.0),
            ])
              LedgerCategoryTile(
                icon: c.$1,
                name: c.$2,
                spent: c.$3,
                overBudget: c.$3 > c.$4,
                onTap: () {},
              ),
          ],
        ),
        (wide, theme) {
          final tiles = find.byType(LedgerCategoryTile);
          final a = t.getRect(tiles.at(0)), b = t.getRect(tiles.at(1));
          expect(b.left - a.right, 8);
          expect(a.height, b.height);
          final c = t.getRect(tiles.at(2));
          if (c.top > a.top) {
            expect(c.top - a.bottom, 8);
          } else {
            expect(c.left - b.right, 8);
          }
          expect(
            t.getSize(
              find.descendant(
                of: tiles.first,
                matching: find.byType(LedgerGlyph),
              ),
            ),
            const Size(32, 32),
          );
          final rent = t.getRect(find.byType(LedgerGlyph).first);
          // `.cat-tile`: 14 inside its 1 px rule.
          expect(rent.left - a.left, 15);
          expect(_node(t, r'Dining out, $286.40'), isSemantics(isLink: true));
        },
      );
    });

    testWidgets('an option: its glyph, its name, the chosen one checked', (
      t,
    ) async {
      var chosen = '';
      await _everywhere(
        t,
        LedgerRows(
          children: [
            for (final c in _categories)
              LedgerOption(
                icon: c.$1,
                label: c.$2,
                selected: c.$2 == 'Dining out',
                onTap: () => chosen = c.$2,
              ),
          ],
        ),
        (wide, theme) {
          expect(find.byIcon(LucideIcons.check), findsOneWidget);
          final rows = find.byType(LedgerOption);
          // `.opt`: 10 0 round a 36 glyph.
          expect(t.getSize(rows.first).height, 56);
          expect(_node(t, 'Dining out'), isSemantics(isSelected: true));
          expect(_node(t, 'Groceries'), isSemantics(isSelected: false));
        },
      );
      await t.tap(find.text('Groceries'));
      expect(chosen, 'Groceries');
    });

    testWidgets('the category mini: line, gauge 10 under, sub 6 under', (
      t,
    ) async {
      await _everywhere(
        t,
        Column(
          children: [
            LedgerCategoryMini(
              name: 'Dining out',
              spent: 286.4,
              budget: 250,
              pace: 28 / 31,
              subtitle: r'Budget $250',
              trailingSubtitle: r'Over by $36.40',
              onTap: () {},
            ),
            const LedgerCategoryMini(
              name: 'Groceries',
              spent: 389.12,
              subtitle: 'Spent in September',
            ),
          ],
        ),
        (wide, theme) {
          expect(find.byType(LedgerGauge), findsOneWidget);
          final gauge = t.getRect(find.byType(LedgerGauge));
          final line = t.getRect(find.byType(LedgerLeaderLine).first);
          expect(gauge.top - line.bottom, 10);
          expect(
            t.getRect(find.text(r'Budget $250')).top - gauge.bottom,
            closeTo(6, .01),
          );
          expect(
            t.widget<Text>(find.text(r'Over by $36.40')).style?.color,
            theme.over,
          );
          // One shape at every width: the gauge under the line.
          expect(gauge.left, line.left);
          expect(_node(t, RegExp('^Dining out')), isSemantics(isLink: true));
        },
      );
    });

    testWidgets('the icon picker: five 48 rounds to a line, spread on a phone, '
        'packed from 600, the chosen ringed', (t) async {
      var picked = -1;
      const icons = [
        LedgerIconChoice(LucideIcons.plane, 'plane'),
        LedgerIconChoice(LucideIcons.shield, 'shield'),
        LedgerIconChoice(LucideIcons.bike, 'bike'),
        LedgerIconChoice(LucideIcons.house, 'house'),
        LedgerIconChoice(LucideIcons.car, 'car'),
        LedgerIconChoice(LucideIcons.gift, 'gift'),
        LedgerIconChoice(LucideIcons.graduationCap, 'graduation-cap'),
      ];
      await _everywhere(
        t,
        LedgerIconPicker(
          choices: icons,
          selectedIndex: 0,
          onSelected: (i) => picked = i,
        ),
        (wide, theme) {
          final plane = t.getRect(find.byIcon(LucideIcons.plane));
          final gift = t.getRect(find.byIcon(LucideIcons.gift));
          // A second line 48 + 10 under the first, in the first column.
          expect(gift.top - plane.top, 58);
          expect(gift.center.dx, plane.center.dx);
          final car = t.getRect(find.byIcon(LucideIcons.car));
          final picker = t.getRect(find.byType(LedgerIconPicker));
          if (wide) {
            // Packed from the column's start, 16 apart: never spread
            // across a desktop column.
            expect(plane.center.dx, closeTo(picker.left + 24, .01));
            expect(car.center.dx - plane.center.dx, 4 * (48 + 16));
          } else {
            // Spread across a phone's line: the fifth round ends at its
            // end.
            expect(car.center.dx, closeTo(picker.right - 24, .01));
          }
          expect(_node(t, 'Icon: plane'), isSemantics(isSelected: true));
          expect(find.bySemanticsLabel('Icon: graduation cap'), findsOne);
          expect(_spoken(t), contains('Icon'));
        },
      );
      await t.tap(find.byIcon(LucideIcons.bike));
      expect(picked, 2);
    });

    testWidgets('the ways: two to a line on a phone, four from 1024', (
      t,
    ) async {
      await _everywhere(
        t,
        LedgerWays(
          ways: [
            for (final w in const [
              (LucideIcons.arrowRightLeft, 'Transfer', 'Between your accounts'),
              (LucideIcons.receipt, 'Pay a bill', 'Six due in November'),
              (LucideIcons.piggyBank, 'Add to goal', 'Lisbon is behind'),
              (LucideIcons.split, 'Split', 'Share a purchase'),
            ])
              LedgerWay(icon: w.$1, title: w.$2, text: w.$3, onTap: () {}),
          ],
        ),
        (wide, theme) {
          final a = t.getRect(find.text('Transfer'));
          final b = t.getRect(find.text('Pay a bill'));
          final c = t.getRect(find.text('Add to goal'));
          if (wide) {
            expect(c.top, a.top);
            // `.big .ring` 44 with 10 under, then 3 to the title (the
            // glyph's box stands inside the ring's 1 px rule).
            final ring = t.getRect(find.byIcon(LucideIcons.arrowRightLeft));
            expect(a.top - ring.top, closeTo(44 + 10 + 3 - 1, .01));
          } else {
            expect(b.top, a.top);
            expect(c.top, greaterThan(a.bottom));
            // `.big` 16 above the 36 ring (title centred on it).
            expect(t.widget<Text>(find.text('Transfer')).style?.fontSize, 24);
          }
          expect(
            _node(t, 'Transfer, Between your accounts'),
            isSemantics(isLink: true),
          );
          expect(_spoken(t), contains('Ways to move money'));
        },
      );
    });

    testWidgets('an allocation row: swatch, leader, share 52 wide', (t) async {
      await _everywhere(
        t,
        const LedgerRows(
          children: [
            LedgerAllocationRow(
              tone: LedgerStackTone.ink,
              name: 'Stocks',
              amount: 39432.6,
              share: '80.6%',
            ),
            LedgerAllocationRow(
              tone: LedgerStackTone.pale,
              name: 'Cash',
              amount: 2152,
              share: '4.4%',
            ),
          ],
        ),
        (wide, theme) {
          final row = t.getRect(find.byType(LedgerAllocationRow).first);
          // `.alloc-row`: 11 0 round a 20 line, three faces on one
          // baseline (a little over 20, as in the browser).
          expect(row.height, inInclusiveRange(42, 44));
          expect(
            t.getRect(find.text('Stocks')).top - row.top,
            greaterThanOrEqualTo(11),
          );
          final pct = t.getRect(find.text('80.6%'));
          expect(pct.right, row.right);
          expect(
            t.getRect(find.byType(LedgerLeaderLine).first).right,
            pct.right - 52 - 10,
          );
          expect(_spoken(t).join(' '), contains('Stocks'));
        },
      );
    });

    testWidgets('a holding: two lines on a phone, one row of columns wide', (
      t,
    ) async {
      await _everywhere(
        t,
        const LedgerHoldings(
          rows: [
            LedgerHoldingRow(
              name: 'Keel Total Market',
              symbol: 'KTMX',
              kind: 'Stocks',
              shares: '182.4 shares',
              value: 26410.2,
              today: 262.1,
            ),
            LedgerHoldingRow(
              name: 'Cash',
              symbol: 'CASH',
              kind: 'Cash',
              shares: 'Settled cash',
              value: 2152,
              today: 0,
            ),
          ],
        ),
        (wide, theme) {
          final row = t.getRect(find.byType(LedgerHoldingRow).first);
          // The live `.holding` at 390: 14, the title's 20, the sub's
          // 21.75, 14 (its rule outside it): 69.75; here the sub's line is
          // the whole 22, so 70.
          expect(row.height, closeTo(wide ? 64 : 70, .01));
          expect(find.text('FUND'), wide ? findsOneWidget : findsNothing);
          expect(find.text('Stocks'), wide ? findsOneWidget : findsNothing);
          final today = find.bySemanticsLabel(RegExp(r'\+\$262\.10 today'));
          expect(today, findsOneWidget);
          final todayText = find.descendant(
            of: find.byType(LedgerHoldingRow).first,
            matching: find.byWidgetPredicate(
              (w) => w is RichText && w.text.toPlainText() == r'+$262.10',
            ),
          );
          // Text.rich wraps its span in the ambient style: read its own.
          final outer = t.widget<RichText>(todayText).text as TextSpan;
          final style = outer.children!.first.style;
          // `.holding .h-today .amt { font-size: 12px }`, green as it rose.
          expect(style?.fontSize, 12);
          expect(style?.color, theme.moneyIn);
        },
      );
    });

    testWidgets('two acts share the row, 12 apart', (t) async {
      final row = LedgerButtonRow(
        children: [
          LedgerButton.filled(
            'Back to Home',
            icon: LucideIcons.house,
            expand: true,
            onPressed: () {},
          ),
          LedgerButton(
            'View transfer',
            icon: LucideIcons.receipt,
            expand: true,
            onPressed: () {},
          ),
        ],
      );
      // `.form-actions-row .btn { padding: 0 16px }`: the row pads its
      // buttons 16 inside their ends (22 alone), so "Back to Home" fits on
      // a phone too.
      for (final size in const [_phone, _desktop]) {
        await _pump(t, row, size: size);
        expect(t.takeException(), isNull);
        _expectWordsFit(t, '${size.width}');
        final words = t.getRect(find.text('Back to Home'));
        final face = t.getRect(find.byType(LedgerButton).first);
        expect(words.left - face.left, greaterThanOrEqualTo(16));
        final a = t.getRect(find.byType(LedgerButton).first);
        final b = t.getRect(find.byType(LedgerButton).last);
        expect(b.left - a.right, 12);
        expect(a.width, b.width);
      }
    });

    testWidgets('the member card: band, head, inked disc, seal, name, rule', (
      t,
    ) async {
      await _everywhere(
        t,
        const LedgerMemberCard(
          kind: 'Keel · Account holder',
          since: 'Since Mar 2023',
          name: 'Maren Holt',
          initials: 'MH',
          subtitle: 'Member since March 2023',
          seal: LedgerSeal(kicker: 'Keel', value: 'Member', foot: 'Since 2023'),
          details: [
            LedgerKeyValue('Email', 'maren.holt@example.com'),
            LedgerKeyValue('Phone', '(•••) •••-4410'),
          ],
        ),
        (wide, theme) {
          expect(find.byType(LedgerSlipBand), findsOneWidget);
          expect(find.text('KEEL · ACCOUNT HOLDER'), findsOneWidget);
          expect(
            t.getSize(find.byType(LedgerMonogram)),
            Size.square(wide ? 84 : 72),
          );
          expect(
            t.getSize(find.byType(LedgerSeal)),
            Size.square(wide ? 112 : 96),
          );
          final name = t.getRect(find.text('Maren Holt'));
          final disc = t.getRect(find.byType(LedgerMonogram));
          if (wide) {
            // "mg id seal": the name 22 after the disc.
            expect(name.left - disc.right, 22);
          } else {
            // "mg . seal" over "id id id".
            expect(name.left, disc.left);
            expect(name.top, greaterThan(disc.bottom));
          }
          expect(
            t.widget<Text>(find.text('Maren Holt')).style?.fontSize,
            wide ? 44 : 40,
          );
          expect(_node(t, 'Maren Holt'), isSemantics(isHeader: true));
          expect(find.text('maren.holt@example.com'), findsOneWidget);
        },
      );
    });
  });
}
