// The Stage C display components: structure, marks, money (beyond what
// chrome_test.dart covers), notice, receipt, card face, seal, goals, gauge,
// engravings and register. Each is built from its doc comment's example or
// the Keel pilot's figures (the gallery's generated keel.dart), pumped on a
// phone and at desktop width in both appearances, and read back through its
// semantics.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- The frame ---------------------------------------------------------------

const Size _phone = Size(390, 844);
const Size _desktop = Size(1440, 900);
const Key _frame = ValueKey<String>('frame');

/// A page's column: the gutter at its sides (24, 56 from 1024), the widget
/// as wide as the column, free to grow down.
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

/// The theme the frame's widget is drawn in.
LedgerThemeData _theme(WidgetTester t) =>
    t.element(find.byKey(_frame)).ledgerTheme;

/// Pumps [child] on a phone and at desktop width, light and dark. Each lays
/// out clean (nothing overflows or throws, no words cut short), then
/// [check] runs.
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

/// Every line of words stands whole: none clipped at its end or its foot.
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

/// Every label and value the semantics tree speaks, in its order.
List<String> _spoken(WidgetTester t) {
  final words = <String>[];
  void walk(SemanticsNode node) {
    // A node merged into its parent speaks in the parent's words.
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

Matcher _live({String? label, bool link = true}) => isSemantics(
  label: label,
  isLink: link,
  isButton: !link,
  hasEnabledState: true,
  isEnabled: true,
  hasTapAction: true,
);

Matcher _inert({String? label, bool link = true}) => isSemantics(
  label: label,
  isLink: link,
  isButton: !link,
  hasEnabledState: true,
  isEnabled: false,
  hasTapAction: false,
);

Widget _atStart(Widget child) =>
    Align(alignment: AlignmentDirectional.centerStart, child: child);

/// The style the first run of words of the line [text] is set in.
TextStyle _style(WidgetTester t, String text) {
  final paragraph = t.renderObject<RenderParagraph>(
    find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText() == text,
    ),
  );
  TextStyle? found;
  void walk(InlineSpan span, TextStyle style) {
    if (found != null) return;
    final own = span.style == null ? style : style.merge(span.style);
    if (span is TextSpan) {
      if (span.text?.isNotEmpty ?? false) {
        found = own;
        return;
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        walk(child, own);
      }
    }
  }

  walk(paragraph.text, const TextStyle());
  return found!;
}

/// Loads every family the test asset bundle declares, so text lays out in
/// its real faces instead of the test font's boxes.
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

// --- The pilot's figures (copied from the gallery's keel.dart) ---------------

const _accounts = [
  (LucideIcons.wallet, 'Everyday', 6248.3, 'Checking ··4821', ''),
  (
    LucideIcons.landmark,
    'Savings',
    21500.0,
    '4.10% APY ··9015',
    '+\$73.42 in Oct',
  ),
  (LucideIcons.plane, 'Lisbon fund', 2840.0, 'Goal pot', '71% of \$4,000'),
  (
    LucideIcons.creditCard,
    'Keel Card',
    -1326.44,
    'Credit ··7730',
    'Due Nov 12 · autopay',
  ),
  (
    LucideIcons.trendingUp,
    'Investing',
    48920.7,
    'Brokerage',
    '+\$391.37 today (+0.81%)',
  ),
];
const _greenEnds = {'Savings', 'Investing'};

const List<(IconData, String)> _acts = [
  (LucideIcons.arrowRightLeft, 'Transfer'),
  (LucideIcons.receipt, 'Pay a bill'),
  (LucideIcons.piggyBank, 'Add to goal'),
  (LucideIcons.split, 'Split'),
];

const List<String> _ranges = ['1M', '3M', '1Y', 'All'];
const String _netWorthNote =
    'Sum of five accounts. The Keel Card balance of −\$1,326.44 is netted out.';

const List<(String, String)> _everydayDetails = [
  ('Account', '··4821'),
  ('Routing', '··0119'),
  ('Debit card', '··3907'),
  ('Opened', 'Mar 14, 2023'),
];

final List<(DateTime, String, String, double, String, bool)> _bills = [
  (DateTime(2026, 11, 1), 'Rent', 'Everyday ··4821', 1150, 'In 4 days', false),
  (
    DateTime(2026, 11, 3),
    'Kite Mobile',
    'Keel Card ··7730',
    35,
    'In 6 days',
    false,
  ),
  (
    DateTime(2026, 11, 12),
    'Keel Card payment',
    'Everyday ··4821',
    1326.44,
    'Autopay on',
    true,
  ),
  (
    DateTime(2026, 11, 15),
    'Newsline',
    'Keel Card ··7730',
    15.98,
    'In 18 days',
    false,
  ),
  (
    DateTime(2026, 11, 19),
    'Cloudbox',
    'Keel Card ··7730',
    2.99,
    'In 22 days',
    false,
  ),
  (
    DateTime(2026, 11, 27),
    'Streamline Music',
    'Keel Card ··7730',
    10.99,
    'In 30 days',
    false,
  ),
];
const double _billsTotal = 2541.4;

const List<(IconData, String, double, double, String, String, bool, String)>
_goals = [
  (
    LucideIcons.plane,
    'Lisbon in May',
    2840,
    4000,
    'by May 2027',
    'Behind',
    true,
    'At \$150 a month you reach \$3,890 by May 1. Add \$110 to stay on track.',
  ),
  (
    LucideIcons.shield,
    'Emergency fund',
    20860,
    24000,
    'reaches May 2027',
    'On track',
    false,
    'Six months of essentials. At \$400 a month plus Savings interest you get there in May 2027.',
  ),
  (
    LucideIcons.bike,
    'New bike',
    640,
    1800,
    'by Oct 2027',
    'On track',
    false,
    'On track for next October at \$100 a month.',
  ),
];

const List<(String, double, double, String, String)> _categories = [
  ('Rent & home', 1150, 1150, '100% of \$1,150', 'Paid Oct 1'),
  ('Groceries', 412.36, 450, '92% of \$450', '8% less than Sept'),
  ('Dining out', 286.4, 250, 'Budget \$250', 'Over by \$36.40'),
  ('Shopping', 214.75, 300, '72% of \$300', ''),
  ('Fun', 143.45, 200, '72% of \$200', ''),
  ('Transport', 118.2, 160, '74% of \$160', ''),
  ('Health', 96, 120, '80% of \$120', ''),
  ('Subscriptions', 64.96, 70, '93% of \$70', ''),
];
const int _day = 28;
const int _daysInMonth = 31;

const List<(IconData, String, String, String, bool)> _notes = [
  (
    LucideIcons.receipt,
    'Rent is due in 4 days',
    '\$1,150.00 to Linden Court Apartments on Nov 1.',
    '9:00 AM',
    true,
  ),
  (
    LucideIcons.arrowDownLeft,
    'Paycheck landed',
    '+\$3,412.50 from Northwind Studio.',
    'Oct 23',
    false,
  ),
  (
    LucideIcons.target,
    'Lisbon in May is 71% saved',
    '\$1,160 to go by May 1.',
    'Oct 22',
    false,
  ),
  (
    LucideIcons.chartPie,
    'Dining out is over budget',
    'You have spent \$257.11 of \$250.',
    'Oct 21',
    false,
  ),
  (
    LucideIcons.creditCard,
    'Keel Card autopay sent',
    '\$1,180.22 from Everyday.',
    'Oct 12',
    false,
  ),
  (
    LucideIcons.receipt,
    'Kite Mobile paid',
    '\$35.00 on your Keel Card.',
    'Oct 3',
    false,
  ),
];

/// A register's transaction: title, initials, category, time, day, account,
/// amount, pending.
typedef _Tx = (String, String, String, String, String, String, double, bool);

const List<(String, String?, double, List<_Tx>)> _days = [
  (
    'Today',
    'Wed, Oct 28',
    -9.65,
    [
      (
        'Blue Fern Café',
        'BF',
        'Dining out',
        '8:12 AM',
        'Today',
        'Keel Card',
        -6.75,
        true,
      ),
      (
        'Harbor Transit',
        'HT',
        'Transport',
        '7:48 AM',
        'Today',
        'Everyday',
        -2.9,
        true,
      ),
    ],
  ),
  (
    'Yesterday',
    'Tue, Oct 27',
    -75.17,
    [
      (
        'Green Basket Market',
        'GB',
        'Groceries',
        '6:22 PM',
        'Yesterday',
        'Keel Card',
        -64.18,
        false,
      ),
      (
        'Streamline Music',
        'SM',
        'Subscriptions',
        '6:00 AM',
        'Yesterday',
        'Keel Card',
        -10.99,
        false,
      ),
    ],
  ),
  (
    'Mon, Oct 26',
    null,
    -46.4,
    [
      (
        'Cinema Lumen',
        'CL',
        'Fun',
        '7:10 PM',
        'Mon, Oct 26',
        'Keel Card',
        -28,
        false,
      ),
      (
        'Alder Pharmacy',
        'AP',
        'Health',
        '12:35 PM',
        'Mon, Oct 26',
        'Keel Card',
        -18.4,
        false,
      ),
    ],
  ),
];
const _Tx _paycheck = (
  'Northwind Studio',
  'NS',
  'Paycheck',
  '6:30 AM',
  'Fri, Oct 23',
  'Everyday',
  3412.5,
  false,
);

const List<String> _cardNumber = ['4242', '4242', '4242', '7730'];
const List<String> _debitNumber = ['4242', '4242', '4242', '3907'];

const List<(String, double, LedgerStackTone)> _allocation = [
  ('Stocks', 39432.6, LedgerStackTone.ink),
  ('Bonds', 7336.1, LedgerStackTone.green),
  ('Cash', 2152, LedgerStackTone.pale),
];

LedgerTransactionRow _txRow(
  _Tx tx, {
  bool withDay = false,
  ValueChanged<String>? onTap,
}) {
  final (title, lead, category, time, day, account, amount, pending) = tx;
  return LedgerTransactionRow(
    title: title,
    initials: lead,
    category: category,
    when: withDay ? '$day, $time' : time,
    account: account,
    amount: amount,
    pending: pending,
    onTap: onTap == null ? null : () => onTap(title),
  );
}

LedgerDayGroup _dayGroup((String, String?, double, List<_Tx>) d) =>
    LedgerDayGroup(
      d.$1,
      note: d.$2,
      net: d.$3,
      rows: [for (final tx in d.$4) _txRow(tx, onTap: (_) {})],
    );

void main() {
  setUpAll(_loadFonts);
  setUpAll(_stillMotion);
  tearDownAll(_movingMotion);

  // --- structure -------------------------------------------------------------

  group('LedgerHead', () {
    testWidgets('a head reads its rubric as a heading, its note as words', (
      t,
    ) async {
      await _everywhere(t, const LedgerHead('Accounts', note: 'Balance'), (
        wide,
        theme,
      ) {
        expect(
          t.getSemantics(find.text('ACCOUNTS')),
          isSemantics(label: 'ACCOUNTS', isHeader: true),
        );
        expect(
          t.getSemantics(find.text('BALANCE')),
          isSemantics(label: 'BALANCE', isLink: false, hasTapAction: false),
        );
      });
    });

    testWidgets('a head with onTap makes its note a link', (t) async {
      var opened = 0;
      await _everywhere(
        t,
        LedgerHead(
          'Upcoming · 15 days',
          note: 'All bills',
          onTap: () => opened += 1,
        ),
        (wide, theme) =>
            expect(_node(t, 'All bills'), _live(label: 'All bills')),
      );
      await t.tap(find.text('ALL BILLS'));
      expect(opened, 1);
    });

    testWidgets('a hero head centres its parts beside its trailing control', (
      t,
    ) async {
      String? range;
      await _everywhere(
        t,
        LedgerHead.hero(
          'Net worth',
          footnote: '1',
          trailing: LedgerSegmentedControl(
            options: _ranges,
            value: '1Y',
            onChanged: (r) => range = r,
          ),
        ),
        (wide, theme) {
          expect(find.text('1'), findsOneWidget);
          expect(_node(t, RegExp('^NET WORTH')), isSemantics(isHeader: true));
          final head = t.getRect(find.byType(LedgerHead));
          final chips = t.getRect(find.byType(LedgerSegmentedControl));
          expect(chips.right, closeTo(head.right, .5));
          // Centred on one line with the rubric.
          expect(
            t.getRect(find.textContaining('NET WORTH')).center.dy,
            closeTo(chips.center.dy, .5),
          );
        },
      );
      await t.tap(find.text('3M'));
      expect(range, '3M');
    });
  });

  testWidgets('LedgerSection stands its child 8 under its head', (t) async {
    await _everywhere(
      t,
      LedgerSection(
        head: const LedgerHead('Goals', note: '3 active'),
        child: LedgerRows(
          children: [
            for (final g in _goals)
              LedgerGoalLine(
                icon: g.$1,
                name: g.$2,
                saved: g.$3,
                target: g.$4,
                by: g.$5,
              ),
          ],
        ),
      ),
      (wide, theme) {
        expect(
          t.getRect(find.byType(LedgerRows)).top -
              t.getRect(find.byType(LedgerHead)).bottom,
          LedgerChromeMetrics.headAfter,
        );
        expect(find.text('3 ACTIVE'), findsOneWidget);
      },
    );
  });

  group('LedgerRows and LedgerRow', () {
    testWidgets('the hairline between each row, none after the last', (
      t,
    ) async {
      Widget rows({required bool divided}) => LedgerRows(
        divided: divided,
        children: [
          for (final a in _accounts)
            LedgerRow(
              leading: LedgerGlyph(a.$1),
              title: a.$2,
              value: LedgerAmount(a.$3),
            ),
        ],
      );
      int hairlines(LedgerThemeData theme) => find
          .byWidgetPredicate(
            (w) => w is ColoredBox && w.color == theme.hairline,
          )
          .evaluate()
          .length;
      await _everywhere(
        t,
        rows(divided: true),
        (wide, theme) => expect(hairlines(theme), _accounts.length - 1),
      );
      await _everywhere(
        t,
        rows(divided: false),
        (wide, theme) => expect(hairlines(theme), 0),
      );
    });

    testWidgets('a row reads as one line: its title, its value, its sub', (
      t,
    ) async {
      await _everywhere(
        t,
        const LedgerRow(
          leading: LedgerGlyph(LucideIcons.wallet),
          title: 'Everyday',
          value: LedgerAmount(6248.30),
          subtitle: 'Checking ··4821',
          subtitleMonospace: true,
        ),
        (wide, theme) => expect(
          _node(t, 'Everyday\n\$6,248.30\nChecking ··4821'),
          isSemantics(isLink: false, hasTapAction: false),
        ),
      );
    });

    testWidgets('a row with onTap is one link to its record', (t) async {
      String? opened;
      await _everywhere(
        t,
        LedgerRows(
          children: [
            for (final a in _accounts)
              LedgerRow(
                leading: LedgerGlyph(a.$1),
                title: a.$2,
                value: LedgerAmount(a.$3),
                subtitle: a.$4,
                subtitleMonospace: true,
                trailingSubtitle: a.$5.isEmpty ? null : a.$5,
                trailingSubtitleTone: _greenEnds.contains(a.$2)
                    ? LedgerTone.moneyIn
                    : LedgerTone.plain,
                onTap: () => opened = a.$2,
              ),
          ],
        ),
        (wide, theme) {
          expect(
            _node(t, 'Savings\n\$21,500.00\n4.10% APY ··9015\n+\$73.42 in Oct'),
            _live(),
          );
          expect(_style(t, '+\$73.42 in Oct').color, theme.moneyIn);
        },
      );
      await t.tap(find.text('Savings'));
      expect(opened, 'Savings');
    });

    testWidgets("a date tab's row says its bill, not the tab", (t) async {
      await _everywhere(
        t,
        LedgerRows(
          children: [
            for (final b in _bills.take(3))
              LedgerRow(
                leading: LedgerDateTab(b.$1),
                title: b.$2,
                value: LedgerAmount(b.$4),
                subtitle: b.$5,
                subtitleTone: b.$6 ? LedgerTone.moneyIn : LedgerTone.plain,
              ),
          ],
        ),
        (wide, theme) {
          expect(find.text('NOV'), findsNWidgets(3));
          expect(_node(t, 'Rent\n\$1,150.00\nIn 4 days'), isNotNull);
          expect(_spoken(t).where((w) => w.contains('NOV')), isEmpty);
        },
      );
    });
  });

  group('LedgerKeyValue', () {
    testWidgets('reads its key and its value, the mask in the mono', (t) async {
      await _everywhere(
        t,
        Column(
          children: [
            const LedgerKeyValue('Status', 'Pending'),
            for (final (name, value) in _everydayDetails)
              LedgerKeyValue(name, value, monospace: value.startsWith('··')),
          ],
        ),
        (wide, theme) {
          expect(_node(t, 'Status\nPending'), isNotNull);
          expect(_node(t, 'Account\n··4821'), isNotNull);
          expect(_node(t, 'Opened\nMar 14, 2023'), isNotNull);
          final mask = t.widget<Text>(find.text('··4821'));
          expect(mask.style?.fontFamily, ledgerFontFamily('PlexMono'));
          final key = t.getRect(find.text('Status'));
          final value = t.getRect(find.text('Pending'));
          expect(key.left, wide ? 56 : 24);
          expect(
            value.right,
            closeTo((wide ? _desktop : _phone).width - (wide ? 56 : 24), .5),
          );
        },
      );
    });

    testWidgets('its action stands beside the value and takes its tap', (
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
          final value = t.getRect(find.text('Dining out'));
          expect(t.getRect(find.text('Change')).left, greaterThan(value.right));
          expect(_node(t, RegExp('^Category\nDining out')), isNotNull);
        },
      );
      await t.tap(find.text('Change'));
      expect(changed, 1);
    });
  });

  group('LedgerFacts', () {
    const month = [
      LedgerFact.money('Left', 213.88, note: '3 days to go'),
      LedgerFact(
        'Vs September',
        '−6%',
        note: '\$2,644.90 last month',
        tone: LedgerTone.moneyIn,
      ),
      LedgerFact.money(
        'Money in',
        6825,
        note: 'Two paychecks',
        showSign: true,
        tone: LedgerTone.moneyIn,
      ),
      LedgerFact('Pace', '90%', note: 'Day 28 of 31; 92% spent'),
    ];

    testWidgets('two across on a phone, one under another on the desktop', (
      t,
    ) async {
      await _everywhere(t, const LedgerFacts(facts: month), (wide, theme) {
        expect(_node(t, 'LEFT\n\$213.88\n3 days to go'), isNotNull);
        expect(_node(t, 'MONEY IN\n+\$6,825.00\nTwo paychecks'), isNotNull);
        expect(_node(t, 'VS SEPTEMBER\n−6%\n\$2,644.90 last month'), isNotNull);
        final left = t.getRect(find.text('LEFT'));
        final vs = t.getRect(find.text('VS SEPTEMBER'));
        if (wide) {
          expect(vs.top, greaterThan(left.bottom));
          expect(vs.left, left.left);
        } else {
          expect(vs.top, left.top);
          expect(vs.left, greaterThan(left.right));
        }
      });
    });

    testWidgets('three across under the ink rule, and the pair', (t) async {
      await _everywhere(
        t,
        const Column(
          children: [
            LedgerFacts(
              columns: LedgerFactColumns.three,
              ruled: true,
              facts: [
                LedgerFact.money(
                  'Money in',
                  6825,
                  note: 'Two paychecks',
                  showSign: true,
                  tone: LedgerTone.moneyIn,
                ),
                LedgerFact.money('Spent', 2486.12, note: '87 purchases'),
                LedgerFact.money('Moved', 1830.22, note: 'Own accounts'),
              ],
            ),
            LedgerFacts(
              columns: LedgerFactColumns.pair,
              facts: [
                LedgerFact('Visits', '13', note: 'at Blue Fern Café'),
                LedgerFact.money('Total', 84.25, note: 'in October'),
              ],
            ),
          ],
        ),
        (wide, theme) {
          expect(_node(t, 'SPENT\n\$2,486.12\n87 purchases'), isNotNull);
          expect(_node(t, 'TOTAL\n\$84.25\nin October'), isNotNull);
          final money = t.getRect(find.text('MONEY IN'));
          final spent = t.getRect(find.text('SPENT'));
          final visits = t.getRect(find.text('VISITS'));
          final total = t.getRect(find.text('TOTAL'));
          // The pair stands two across everywhere.
          expect(total.top, visits.top);
          if (wide) {
            expect(spent.top, greaterThan(money.bottom));
          } else {
            expect(spent.top, money.top);
          }
        },
      );
    });
  });

  testWidgets('LedgerNotes reads each mark with its words', (t) async {
    await _everywhere(
      t,
      const LedgerNotes(notes: [LedgerNote('1', _netWorthNote)]),
      (wide, theme) {
        expect(_node(t, '1\n$_netWorthNote'), isNotNull);
        expect(
          t.getRect(find.text(_netWorthNote)).left -
              t.getRect(find.text('1')).left,
          10 + 8,
        );
      },
    );
  });

  testWidgets('LedgerRecordHead names its record as a heading', (t) async {
    await _everywhere(
      t,
      const Column(
        children: [
          LedgerRecordHead(
            leading: LedgerGlyph(
              LucideIcons.wallet,
              size: LedgerGlyphSize.record,
            ),
            name: 'Everyday',
            subtitle: 'Checking ··4821',
          ),
          LedgerRecordHead(
            leading: LedgerGlyph(
              LucideIcons.landmark,
              size: LedgerGlyphSize.record,
            ),
            name: 'Savings',
            subtitle: '4.10% APY',
            mono: '··9015',
          ),
        ],
      ),
      (wide, theme) {
        expect(
          t.getSemantics(find.text('Everyday')),
          isSemantics(label: 'Everyday', isHeader: true),
        );
        expect(_node(t, '4.10% APY ··9015'), isNotNull);
        // The space before the mask is the sub's, not the mono's
        // (`APY · <span class=mono>··9015</span>`).
        final sub =
            t
                    .widget<RichText>(
                      find.byWidgetPredicate(
                        (w) =>
                            w is RichText &&
                            w.text.toPlainText() == '4.10% APY ··9015',
                      ),
                    )
                    .text
                as TextSpan;
        final runs = <String>[];
        sub.visitChildren((span) {
          if (span case TextSpan(:final text?)) runs.add(text);
          return true;
        });
        expect(runs, ['4.10% APY ', '··9015']);
        expect(
          t.widget<Text>(find.text('Everyday')).style?.fontSize,
          wide ? 40 : theme.title.fontSize,
        );
        expect(
          t.getSize(find.byType(LedgerGlyph).first).width,
          wide ? LedgerGlyphSize.record.desk : LedgerGlyphSize.record.phone,
        );
      },
    );
  });

  testWidgets('LedgerMonthRule heads the month it runs back into', (t) async {
    await _everywhere(
      t,
      const LedgerMonthRule('September 2026', note: 'Last month'),
      (wide, theme) {
        expect(
          t.getSemantics(find.text('SEPTEMBER 2026')),
          isSemantics(isHeader: true),
        );
        expect(find.text('LAST MONTH'), findsOneWidget);
      },
    );
  });

  group('LedgerFlag', () {
    testWidgets('one link, its strong words in the vermilion', (t) async {
      var opened = 0;
      await _everywhere(
        t,
        LedgerFlag(
          'Dining out is **over by \$36.40**',
          onTap: () => opened += 1,
        ),
        (wide, theme) {
          expect(_node(t, 'Dining out is over by \$36.40'), _live());
          final paragraph = t.renderObject<RenderParagraph>(
            find.byWidgetPredicate(
              (w) =>
                  w is RichText &&
                  w.text.toPlainText() == 'Dining out is over by \$36.40',
            ),
          );
          final strong = <String>[];
          paragraph.text.visitChildren((span) {
            if (span is TextSpan && span.style?.color == theme.over) {
              strong.add(span.text ?? '');
            }
            return true;
          });
          expect(strong, ['over by \$36.40']);
        },
      );
      await t.tap(find.byType(LedgerFlag));
      expect(opened, 1);
    });

    testWidgets('with no onTap it is announced disabled', (t) async {
      await _pump(t, const LedgerFlag('Dining out is **over by \$36.40**'));
      expect(_node(t, 'Dining out is over by \$36.40'), _inert());
    });
  });

  group('LedgerQuickActions', () {
    testWidgets('a strip on a phone, a list on the desktop, every way a link', (
      t,
    ) async {
      String? went;
      await _everywhere(
        t,
        LedgerQuickActions(
          actions: [
            for (final (icon, label) in _acts)
              LedgerQuickAction(icon, label, onTap: () => went = label),
          ],
        ),
        (wide, theme) {
          for (final (_, label) in _acts) {
            expect(_node(t, label), _live(label: label));
          }
          final first = t.getRect(find.text('Transfer'));
          final second = t.getRect(find.text('Pay a bill'));
          if (wide) {
            expect(second.top, greaterThan(first.bottom));
          } else {
            expect(second.top, first.top);
            expect(second.left, greaterThan(first.right));
          }
        },
      );
      await t.tap(find.text('Pay a bill'));
      expect(went, 'Pay a bill');
    });

    testWidgets('a way with no onTap is announced disabled', (t) async {
      await _pump(
        t,
        const LedgerQuickActions(
          actions: [LedgerQuickAction(LucideIcons.split, 'Split')],
        ),
      );
      expect(_node(t, 'Split'), _inert(label: 'Split'));
    });
  });

  testWidgets('LedgerDelta speaks its rise, its words and its pill', (t) async {
    await _everywhere(
      t,
      const LedgerDelta(
        rise: '\$2,904.18',
        words: ['this month'],
        pill: LedgerPill('+3.86%'),
      ),
      (wide, theme) {
        expect(
          _spoken(t),
          containsAllInOrder(['\$2,904.18', 'this month', '+3.86%']),
        );
        expect(
          t.widget<Text>(find.text('\$2,904.18')).style?.color,
          theme.moneyIn,
        );
      },
    );
  });

  // --- marks -----------------------------------------------------------------

  group('marks', () {
    testWidgets('glyphs, monograms and date tabs say nothing', (t) async {
      await _everywhere(
        t,
        Wrap(
          children: [
            for (final a in _accounts) LedgerGlyph(a.$1),
            const LedgerGlyph(
              LucideIcons.arrowRightLeft,
              tone: LedgerGlyphTone.move,
            ),
            const LedgerGlyph(
              LucideIcons.receipt,
              tone: LedgerGlyphTone.moneyIn,
            ),
            const LedgerGlyph(
              LucideIcons.ban,
              tone: LedgerGlyphTone.inked,
              size: LedgerGlyphSize.dense,
            ),
            for (final d in _days)
              for (final tx in d.$4) LedgerMonogram(tx.$1, initials: tx.$2),
            LedgerMonogram(_paycheck.$1, tone: LedgerMonogramTone.moneyIn),
            const LedgerMonogram(
              'Northwind Studio',
              size: LedgerMonogramSize.person,
              selected: true,
            ),
            for (final b in _bills.take(3)) LedgerDateTab(b.$1),
            // The one mark here that speaks.
            const LedgerPill('+3.86%'),
          ],
        ),
        (wide, theme) => expect(_spoken(t), ['+3.86%']),
      );
    });

    testWidgets(
      'a glyph stands at its size, the record larger on the desktop',
      (t) async {
        await _everywhere(
          t,
          Wrap(
            children: [
              for (final size in LedgerGlyphSize.values)
                LedgerGlyph(
                  LucideIcons.wallet,
                  size: size,
                  key: ValueKey(size),
                ),
            ],
          ),
          (wide, theme) {
            for (final size in LedgerGlyphSize.values) {
              expect(
                t.getSize(find.byKey(ValueKey(size))),
                Size.square(wide ? size.desk : size.phone),
              );
            }
          },
        );
      },
    );

    testWidgets("a monogram sets its name's initials", (t) async {
      await _everywhere(
        t,
        const Wrap(
          children: [
            LedgerMonogram('Blue Fern Café'),
            LedgerMonogram(
              'Northwind Studio',
              tone: LedgerMonogramTone.moneyIn,
            ),
            LedgerMonogram('Cloudbox', size: LedgerMonogramSize.record),
          ],
        ),
        (wide, theme) {
          expect(find.text('BF'), findsOneWidget);
          expect(t.widget<Text>(find.text('NS')).style?.color, theme.accent);
          expect(
            t.getSize(find.byType(LedgerMonogram).last).width,
            wide
                ? LedgerMonogramSize.record.desk
                : LedgerMonogramSize.record.phone,
          );
        },
      );
    });

    testWidgets('a date tab is 40 by 44: the month over the day', (t) async {
      await _everywhere(t, _atStart(LedgerDateTab(DateTime(2026, 11, 1))), (
        wide,
        theme,
      ) {
        expect(t.getSize(find.byType(LedgerDateTab)), const Size(40, 44));
        expect(
          t.getRect(find.text('NOV')).bottom,
          lessThanOrEqualTo(t.getRect(find.text('1')).top + .5),
        );
      });
    });

    testWidgets('pills and tags speak their words', (t) async {
      await _everywhere(
        t,
        const Wrap(
          spacing: 8,
          children: [
            LedgerPill('+3.86%'),
            LedgerPill('−6% vs September'),
            LedgerPill(
              'Behind',
              tone: LedgerPillTone.plain,
              size: LedgerPillSize.small,
            ),
            LedgerPill('Over', tone: LedgerPillTone.over),
            LedgerTag('Pending'),
            LedgerTag('New', tone: LedgerTagTone.unread),
          ],
        ),
        (wide, theme) {
          expect(_spoken(t), [
            '+3.86%',
            '−6% vs September',
            'Behind',
            'Over',
            'PENDING',
            'NEW',
          ]);
          expect(t.getSize(find.byType(LedgerPill).first).height, 24);
          expect(t.getSize(find.byType(LedgerPill).at(2)).height, 20);
          expect(t.getSize(find.byType(LedgerTag).first).height, 18);
          expect(t.widget<Text>(find.text('NEW')).style?.color, theme.accent);
        },
      );
    });

    testWidgets('a pill and a tag keep their own width in a loose room', (
      t,
    ) async {
      await _everywhere(
        t,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LedgerPill('Autopay on'),
            Text.rich(
              TextSpan(
                text: 'Blue Fern Coffee ',
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: LedgerTag('Pending'),
                  ),
                ],
              ),
            ),
          ],
        ),
        (wide, theme) {
          // `.pill` 0 10 around its words; `.tag` 0 7 inside its 1 px ring.
          expect(
            t.getSize(find.byType(LedgerPill)).width,
            t.getSize(find.text('Autopay on')).width + 2 * 10,
          );
          expect(
            t.getSize(find.byType(LedgerTag)).width,
            t.getSize(find.text('PENDING')).width + 2 * (7 + 1),
          );
          expect(t.getSize(find.byType(LedgerTag)).height, 18);
        },
      );
    });
  });

  // --- money (beyond chrome_test) -------------------------------------------

  group('money', () {
    testWidgets('an amount speaks as one, inked by its tone', (t) async {
      await _everywhere(
        t,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LedgerAmount(-84.25),
            LedgerAmount(3412.50, tone: LedgerTone.moneyIn, showSign: true),
            LedgerAmount(286.40, tone: LedgerTone.over),
            LedgerAmount(35, size: LedgerAmountSize.small),
          ],
        ),
        (wide, theme) {
          expect(_spoken(t), [
            '−\$84.25',
            '+\$3,412.50',
            '\$286.40',
            '\$35.00',
          ]);
          expect(_style(t, '−\$84.25').color, theme.textPrimary);
          expect(_style(t, '\$286.40').color, theme.over);
          expect(_style(t, '+\$3,412.50').color, theme.moneyIn);
          expect(_style(t, '\$35.00').fontSize, LedgerAmountSize.small.size);
        },
      );
    });

    testWidgets('each figure size is its phone size, its desktop size wide', (
      t,
    ) async {
      await _everywhere(
        t,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final size in LedgerFigureSize.values)
              LedgerFigure(2486.12, size: size),
          ],
        ),
        (wide, theme) {
          final wholes = t.widgetList<Text>(find.text('2,486')).toList();
          expect(wholes, hasLength(LedgerFigureSize.values.length));
          for (var i = 0; i < wholes.length; i++) {
            final size = LedgerFigureSize.values[i];
            expect(
              wholes[i].style?.fontSize,
              closeTo(wide ? size.desk : size.phone, .01),
              reason: size.name,
            );
          }
          expect(
            find.bySemanticsLabel('\$2,486.12'),
            findsNWidgets(wholes.length),
          );
        },
      );
    });

    testWidgets("the receipt's figure, and the over figure in the vermilion", (
      t,
    ) async {
      await _everywhere(
        t,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LedgerFigure(
              3412.50,
              tone: LedgerFigureTone.moneyIn,
              showSign: true,
              size: LedgerFigureSize.receipt,
            ),
            LedgerFigure(
              286.40,
              tone: LedgerFigureTone.over,
              size: LedgerFigureSize.hero,
            ),
          ],
        ),
        (wide, theme) {
          expect(find.bySemanticsLabel('+\$3,412.50'), findsOneWidget);
          expect(find.bySemanticsLabel('\$286.40'), findsOneWidget);
          expect(t.widget<Text>(find.text('286')).style?.color, theme.over);
          expect(
            t.widget<Text>(find.text('\$')).style?.color,
            theme.textSecondary,
          );
          expect(t.widget<Text>(find.text('+\$')).style?.color, theme.moneyIn);
        },
      );
    });

    testWidgets(
      'a leader line holds its name at the start, its value at the end',
      (t) async {
        await _everywhere(
          t,
          Builder(
            builder: (context) => LedgerLeaderLine(
              start: Text('Checking', style: context.ledgerTheme.rowTitle),
              end: const LedgerAmount(6248.30),
            ),
          ),
          (wide, theme) {
            final line = t.getRect(find.byType(LedgerLeaderLine));
            expect(t.getRect(find.text('Checking')).left, line.left);
            expect(
              t.getRect(find.byType(LedgerAmount)).right,
              closeTo(line.right, .01),
            );
            expect(_spoken(t), ['Checking', '\$6,248.30']);
          },
        );
      },
    );

    testWidgets("a statement's total reads its title with its sum", (t) async {
      await _everywhere(
        t,
        const LedgerStatementTotal(
          title: 'November total',
          amount: _billsTotal,
        ),
        (wide, theme) {
          expect(_node(t, 'November total\n\$2,541.40'), isNotNull);
          expect(_spoken(t), ['November total\n\$2,541.40']);
        },
      );
    });
  });

  // --- notice ----------------------------------------------------------------

  group('LedgerNoteRow', () {
    testWidgets('each notification is one link, the unread one tagged', (
      t,
    ) async {
      String? opened;
      await _everywhere(
        t,
        LedgerRows(
          divided: false,
          children: [
            for (final n in _notes)
              LedgerNoteRow(
                icon: n.$1,
                title: n.$2,
                body: n.$3,
                when: n.$4,
                unread: n.$5,
                onTap: () => opened = n.$2,
              ),
          ],
        ),
        (wide, theme) {
          expect(
            _node(t, 'Rent is due in 4 days, unread'),
            _live(label: 'Rent is due in 4 days, unread'),
          );
          expect(_node(t, 'Paycheck landed'), _live(label: 'Paycheck landed'));
          expect(find.text('NEW'), findsOneWidget);
          expect(
            t.widget<Text>(find.text('9:00 AM')).style?.color,
            theme.accent,
          );
        },
      );
      await t.tap(find.text('Paycheck landed'));
      expect(opened, 'Paycheck landed');
    });

    testWidgets('with no onTap it is announced disabled', (t) async {
      final n = _notes[1];
      await _pump(
        t,
        LedgerNoteRow(icon: n.$1, title: n.$2, body: n.$3, when: n.$4),
      );
      expect(_node(t, 'Paycheck landed'), _inert(label: 'Paycheck landed'));
    });
  });

  testWidgets('LedgerEffect reads its title over its words', (t) async {
    await _everywhere(
      t,
      const LedgerEffect(
        icon: LucideIcons.ban,
        title: 'Declined',
        text: 'New purchases and cash withdrawals.',
        blocking: true,
      ),
      (wide, theme) =>
          expect(_spoken(t), ['Declined\nNew purchases and cash withdrawals.']),
    );
  });

  // --- receipt ---------------------------------------------------------------

  group('receipt', () {
    testWidgets('a slip lifts its child off the page', (t) async {
      await _everywhere(
        t,
        const LedgerSlip(
          padding: EdgeInsets.all(20),
          child: LedgerKeyValue('Status', 'Pending'),
        ),
        (wide, theme) {
          final box = t.widget<Container>(
            find
                .descendant(
                  of: find.byType(LedgerSlip),
                  matching: find.byType(Container),
                )
                .first,
          );
          final decoration = box.decoration! as BoxDecoration;
          expect(decoration.color, theme.surface);
          expect(decoration.boxShadow, theme.paperShadow);
          expect(_spoken(t), ['Status\nPending']);
        },
      );
    });

    testWidgets('the stub is 18 tall across its slip and says nothing', (
      t,
    ) async {
      await _everywhere(
        t,
        const Column(children: [LedgerStub(), LedgerPill('+3.86%')]),
        (wide, theme) {
          final stub = t.getSize(find.byType(LedgerStub));
          expect(stub.height, 18);
          expect(
            stub.width,
            (wide ? _desktop : _phone).width - 2 * (wide ? 56 : 24),
          );
          expect(_spoken(t), ['+3.86%']);
        },
      );
    });

    testWidgets('a receipt names its merchant, its sum and its verdict', (
      t,
    ) async {
      await _everywhere(
        t,
        const LedgerReceipt(
          kind: 'Keel · Transaction',
          number: 'No. T280812BLUE',
          leading: LedgerMonogram(
            'Blue Fern Café',
            size: LedgerMonogramSize.record,
          ),
          name: 'Blue Fern Café',
          subtitle: 'Dining out · Keel Card ··7730',
          figure: LedgerFigure(-6.75),
          seal: LedgerSeal(
            kicker: 'Keel Card',
            value: 'Pending',
            foot: 'Oct 28',
            tone: LedgerSealTone.plain,
          ),
          details: [
            LedgerKeyValue('Status', 'Pending'),
            LedgerKeyValue('Date', 'Wednesday, October 28, 2026'),
            LedgerKeyValue('Time', '8:12 AM'),
            LedgerKeyValue('Card', 'Keel Card ··7730'),
            LedgerKeyValue('Category', 'Dining out'),
          ],
        ),
        (wide, theme) {
          expect(
            t.getSemantics(find.text('Blue Fern Café')),
            isSemantics(isHeader: true),
          );
          expect(find.text('KEEL · TRANSACTION'), findsOneWidget);
          expect(find.text('NO. T280812BLUE'), findsOneWidget);
          expect(find.bySemanticsLabel('−\$6.75'), findsOneWidget);
          expect(
            find.bySemanticsLabel('Keel Card, Pending, Oct 28'),
            findsOneWidget,
          );
          expect(_node(t, 'Status\nPending'), isNotNull);
          // The figure and the seal at the receipt's sizes.
          expect(
            t.widget<Text>(find.text('6')).style?.fontSize,
            wide
                ? LedgerFigureSize.receipt.desk
                : LedgerFigureSize.receipt.phone,
          );
          expect(
            t.getSize(find.byType(LedgerSeal)).width,
            wide ? LedgerSealSize.receipt.desk : LedgerSealSize.receipt.phone,
          );
          expect(find.byType(LedgerStub), findsOneWidget);
        },
      );
    });

    testWidgets("a paycheck's receipt holds its figure beside its seal", (
      t,
    ) async {
      await _everywhere(
        t,
        LedgerReceipt(
          kind: 'Keel · Money in',
          number: 'No. X230630EVER',
          leading: LedgerMonogram(
            _paycheck.$1,
            tone: LedgerMonogramTone.moneyIn,
            size: LedgerMonogramSize.record,
          ),
          name: _paycheck.$1,
          subtitle: 'Paycheck · Everyday ··4821',
          figure: const LedgerFigure(
            3412.50,
            tone: LedgerFigureTone.moneyIn,
            showSign: true,
          ),
          seal: const LedgerSeal(
            kicker: 'Everyday',
            value: 'Received',
            foot: 'Oct 23',
          ),
          details: const [
            LedgerKeyValue('Status', 'Posted'),
            LedgerKeyValue('Date', 'Friday, October 23, 2026'),
            LedgerKeyValue('Time', '6:30 AM'),
            LedgerKeyValue('From', 'Northwind Studio'),
            LedgerKeyValue('To', 'Everyday ··4821'),
          ],
        ),
        (wide, theme) {
          expect(find.bySemanticsLabel('+\$3,412.50'), findsOneWidget);
          expect(
            find.bySemanticsLabel('Everyday, Received, Oct 23'),
            findsOneWidget,
          );
          final figure = t.getRect(find.byType(LedgerFigure));
          final seal = t.getRect(find.byType(LedgerSeal));
          expect(figure.right, lessThanOrEqualTo(seal.left));
          // The seal pressed whole at the receipt's size, on the slip.
          expect(
            seal.width,
            closeTo(
              wide ? LedgerSealSize.receipt.desk : LedgerSealSize.receipt.phone,
              .01,
            ),
          );
          expect(
            seal.right,
            lessThanOrEqualTo(t.getRect(find.byType(LedgerSlip)).right),
          );
        },
      );
    });

    testWidgets('a cheque prints its lines, its micr line silent', (t) async {
      await _everywhere(
        t,
        const LedgerCheque(
          kind: 'Keel · Transfer',
          date: 'Wed, Oct 28, 2026',
          micr: '··0119 ··4821 ··9015',
          lines: [
            LedgerPickLine(
              label: 'From',
              icon: LucideIcons.wallet,
              name: 'Everyday',
              mask: '··4821',
            ),
            LedgerPickLine(
              label: 'To',
              icon: LucideIcons.landmark,
              name: 'Savings',
              mask: '··9015',
            ),
            LedgerChequeAmount(
              label: 'Amount',
              words: 'Five hundred and 00/100',
              unit: 'dollars',
              amount: 500,
            ),
          ],
        ),
        (wide, theme) {
          expect(find.text('KEEL · TRANSFER'), findsOneWidget);
          expect(find.text('WED, OCT 28, 2026'), findsOneWidget);
          expect(find.text('··0119 ··4821 ··9015'), findsOneWidget);
          final spoken = _spoken(t);
          expect(spoken.where((w) => w.contains('··0119')), isEmpty);
          expect(spoken, contains('From:\nEveryday\n··4821'));
          expect(spoken, contains('Amount\n\$500.00'));
          expect(find.byType(LedgerStub), findsOneWidget);
        },
      );
    });
  });

  // --- card face -------------------------------------------------------------

  group('LedgerCardFace', () {
    testWidgets('reads as its kind and last four, masked but the last', (
      t,
    ) async {
      await _everywhere(
        t,
        _atStart(
          const LedgerCardFace(
            brand: 'Keel',
            kind: 'Credit',
            number: _cardNumber,
            holder: 'MAREN HOLT',
            account: 'Keel Card',
          ),
        ),
        (wide, theme) {
          expect(_spoken(t), ['Credit card ending 7730']);
          expect(find.text('••••'), findsNWidgets(3));
          expect(find.text('7730'), findsOneWidget);
          expect(find.text('KEEL CARD'), findsOneWidget);
          expect(
            t.getSize(find.byType(LedgerCardFace)),
            wide ? const Size(400, 252) : const Size(390 - 48, 216),
          );
        },
      );
    });

    testWidgets('the debit card on its paper, small', (t) async {
      await _everywhere(
        t,
        _atStart(
          const LedgerCardFace(
            brand: 'Keel',
            kind: 'Debit',
            number: _debitNumber,
            holder: 'MAREN HOLT',
            account: 'Everyday',
            stock: LedgerCardStock.debit,
            size: LedgerCardSize.small,
          ),
        ),
        (wide, theme) {
          expect(_spoken(t), ['Debit card ending 3907']);
          expect(
            t.getSize(find.byType(LedgerCardFace)),
            wide ? const Size(280, 176) : const Size(264, 166),
          );
        },
      );
    });

    testWidgets('frozen: the account dropped, the seal pressed on its corner', (
      t,
    ) async {
      await _everywhere(
        t,
        _atStart(
          const LedgerCardFace(
            brand: 'Keel',
            kind: 'Credit',
            number: _cardNumber,
            holder: 'MAREN HOLT',
            account: 'Keel Card',
            frozen: true,
            seal: LedgerSeal(
              kicker: 'Keel Card',
              value: 'Frozen',
              foot: 'Oct 28',
              tone: LedgerSealTone.plain,
            ),
          ),
        ),
        (wide, theme) {
          expect(_spoken(t), [
            'Credit card ending 7730, frozen',
            'Keel Card, Frozen, Oct 28',
          ]);
          // The account is dropped from the face's foot: its words stand
          // only on the seal, as its kicker.
          expect(find.text('KEEL CARD'), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(LedgerSeal),
              matching: find.text('KEEL CARD'),
            ),
            findsOneWidget,
          );
          final card = t.getRect(
            find.descendant(
              of: find.byType(LedgerCardFace),
              matching: find.bySemanticsLabel(
                'Credit card ending 7730, frozen',
              ),
            ),
          );
          final seal = t.getRect(find.byType(LedgerSeal));
          expect(seal.bottom, greaterThan(card.bottom));
          expect(seal.right, greaterThan(card.right - seal.width));
        },
      );
    });
  });

  // --- seal --------------------------------------------------------------------

  group('LedgerSeal', () {
    testWidgets('reads its three lines; each size presses its round', (
      t,
    ) async {
      await _everywhere(
        t,
        Wrap(
          children: [
            for (final size in LedgerSealSize.values)
              LedgerSeal(
                kicker: 'Search',
                value: 'No\nentries',
                foot: 'October',
                tone: LedgerSealTone.plain,
                size: size,
                key: ValueKey(size),
              ),
          ],
        ),
        (wide, theme) {
          expect(
            find.bySemanticsLabel('Search, No entries, October'),
            findsNWidgets(LedgerSealSize.values.length),
          );
          for (final size in LedgerSealSize.values) {
            expect(
              t.getSize(find.byKey(ValueKey(size))),
              Size.square(wide ? size.desk : size.phone),
            );
          }
          // Each line in the look's own face, its package named once (a
          // style rebuilt from its family alone took the package twice and
          // fell back, in the package only).
          for (final p in t.renderObjectList<RenderParagraph>(
            find.descendant(
              of: find.byType(LedgerSeal),
              matching: find.byType(RichText),
            ),
          )) {
            final family = p.text.style?.fontFamily ?? '';
            expect(
              'packages/'.allMatches(family).length,
              lessThanOrEqualTo(1),
              reason: family,
            );
          }
        },
      );
    });

    testWidgets('in its three inks', (t) async {
      await _everywhere(
        t,
        Wrap(
          children: [
            LedgerSeal(
              kicker: 'October',
              value: 'Within\nbudget',
              foot: '${LedgerFormat.percent(2486.12, 2700)}% spent',
            ),
            LedgerSeal(
              kicker: 'October',
              value: 'Over',
              foot: '+${LedgerFormat.money(36.40)}',
              tone: LedgerSealTone.over,
            ),
            const LedgerSeal(
              kicker: 'Search',
              value: 'No\nentries',
              foot: 'October',
              tone: LedgerSealTone.plain,
            ),
          ],
        ),
        (wide, theme) => expect(_spoken(t), [
          'October, Within budget, 92% spent',
          'October, Over, +\$36.40',
          'Search, No entries, October',
        ]),
      );
    });
  });

  // --- goals -------------------------------------------------------------------

  group('LedgerGoalLine', () {
    testWidgets('one link read as its name, share and date', (t) async {
      String? opened;
      await _everywhere(
        t,
        LedgerRows(
          children: [
            for (final g in _goals)
              LedgerGoalLine(
                icon: g.$1,
                name: g.$2,
                saved: g.$3,
                target: g.$4,
                by: g.$5,
                onTap: () => opened = g.$2,
              ),
          ],
        ),
        (wide, theme) {
          expect(
            _node(t, 'Lisbon in May, 71%, by May 2027'),
            _live(label: 'Lisbon in May, 71%, by May 2027'),
          );
          expect(_node(t, 'Emergency fund, 87%, reaches May 2027'), _live());
          expect(_node(t, 'New bike, 36%, by Oct 2027'), _live());
          expect(find.text('71%'), findsOneWidget);
          expect(find.text('\$2,840 of \$4,000'), findsOneWidget);
        },
      );
      await t.tap(find.text('New bike'));
      expect(opened, 'New bike');
    });

    testWidgets('with no onTap it is announced disabled', (t) async {
      final g = _goals.first;
      await _pump(
        t,
        LedgerGoalLine(
          icon: g.$1,
          name: g.$2,
          saved: g.$3,
          target: g.$4,
          by: g.$5,
        ),
      );
      expect(_node(t, 'Lisbon in May, 71%, by May 2027'), _inert());
    });
  });

  group('LedgerGoalCard', () {
    testWidgets('its note under it on a phone, beside it on the desktop', (
      t,
    ) async {
      String? opened;
      await _everywhere(
        t,
        LedgerRows(
          children: [
            for (final g in _goals)
              LedgerGoalCard(
                icon: g.$1,
                name: g.$2,
                saved: g.$3,
                target: g.$4,
                by: g.$5,
                status: g.$6,
                behindSchedule: g.$7,
                note: g.$8,
                onTap: () => opened = g.$2,
              ),
          ],
        ),
        (wide, theme) {
          expect(
            _node(t, 'Lisbon in May, 71%, by May 2027, Behind'),
            _live(label: 'Lisbon in May, 71%, by May 2027, Behind'),
          );
          expect(
            _node(t, 'Emergency fund, 87%, reaches May 2027, On track'),
            _live(),
          );
          final note = t.getRect(find.text(_goals.first.$8));
          final gauge = t.getRect(find.byType(LedgerGauge).first);
          if (wide) {
            expect(note.left, greaterThan(gauge.right));
            expect(note.width, lessThanOrEqualTo(264));
          } else {
            expect(note.top, greaterThan(gauge.bottom));
          }
        },
      );
      await t.tap(find.text('Emergency fund'));
      expect(opened, 'Emergency fund');
    });

    testWidgets('with no onTap it is announced disabled', (t) async {
      final g = _goals.last;
      await _pump(
        t,
        LedgerGoalCard(
          icon: g.$1,
          name: g.$2,
          saved: g.$3,
          target: g.$4,
          by: g.$5,
          status: g.$6,
          note: g.$8,
        ),
      );
      expect(_node(t, 'New bike, 36%, by Oct 2027, On track'), _inert());
    });
  });

  group('LedgerCategoryLine', () {
    testWidgets('each category one link, the one over its budget vermilion', (
      t,
    ) async {
      String? opened;
      await _everywhere(
        t,
        LedgerRows(
          children: [
            for (final c in _categories)
              LedgerCategoryLine(
                name: c.$1,
                spent: c.$2,
                budget: c.$3,
                pace: _day / _daysInMonth,
                subtitle: c.$4,
                trailingSubtitle: c.$5.isEmpty ? null : c.$5,
                onTap: () => opened = c.$1,
              ),
          ],
        ),
        (wide, theme) {
          expect(
            _node(t, 'Dining out, \$286.40, Budget \$250, Over by \$36.40'),
            _live(label: 'Dining out, \$286.40, Budget \$250, Over by \$36.40'),
          );
          expect(_node(t, 'Fun, \$143.45, 72% of \$200'), _live());
          expect(
            t.widget<Text>(find.text('Dining out')).style?.color,
            theme.over,
          );
          expect(
            t.widget<Text>(find.text('Groceries')).style?.color,
            theme.textPrimary,
          );
        },
      );
      await t.tap(find.text('Groceries'));
      expect(opened, 'Groceries');
    });

    testWidgets('with no onTap it is announced disabled', (t) async {
      final c = _categories[2];
      await _pump(
        t,
        LedgerCategoryLine(
          name: c.$1,
          spent: c.$2,
          budget: c.$3,
          subtitle: c.$4,
          trailingSubtitle: c.$5,
        ),
      );
      expect(
        _node(t, 'Dining out, \$286.40, Budget \$250, Over by \$36.40'),
        _inert(),
      );
    });
  });

  // --- gauge -------------------------------------------------------------------

  group('gauge', () {
    testWidgets("the month's gauge reads the share spent, its labels shown", (
      t,
    ) async {
      await _everywhere(
        t,
        const LedgerGauge(
          ratio: 2486.12 / 2700,
          pace: 28 / 31,
          tick: false,
          paceLabel: 'Pace · day 28',
          startLabel: '\$0',
          endLabel: '\$2,700',
        ),
        (wide, theme) {
          expect(_spoken(t), ['Spent', '92%']);
          expect(
            t.getSemantics(find.byType(LedgerGauge)),
            isSemantics(label: 'Spent', value: '92%'),
          );
          expect(find.text('Pace · day 28'), findsOneWidget);
          final gauge = t.getRect(find.byType(LedgerGauge));
          expect(t.getRect(find.text('\$0')).left, gauge.left);
          expect(
            t.getRect(find.text('\$2,700')).right,
            closeTo(gauge.right, .5),
          );
        },
      );
    });

    testWidgets('a goal saved and a category over its budget', (t) async {
      await _everywhere(
        t,
        const Column(
          spacing: 24,
          children: [
            LedgerGauge(
              ratio: 2840 / 4000,
              tick: false,
              tone: LedgerGaugeTone.green,
              semanticLabel: 'Saved',
            ),
            LedgerGauge(
              ratio: 286.4 / 250,
              budgetAt: 250 / 300,
              pace: 28 / 31,
              semanticLabel: 'Dining out spent',
            ),
          ],
        ),
        (wide, theme) =>
            expect(_spoken(t), ['Saved', '71%', 'Dining out spent', '115%']),
      );
    });

    testWidgets('the stack bar reads as its label, 22 tall', (t) async {
      await _everywhere(
        t,
        LedgerStackBar(
          parts: [for (final p in _allocation) LedgerStackPart(p.$2, p.$3)],
        ),
        (wide, theme) {
          expect(_spoken(t), ['Allocation']);
          expect(t.getSize(find.byType(LedgerStackBar)).height, 22);
        },
      );
    });

    testWidgets('the budget rule reads its three sums', (t) async {
      await _everywhere(
        t,
        const LedgerBudgetRule(spent: 286.40, budget: 250, suggested: 275),
        (wide, theme) {
          expect(
            t.getSemantics(find.byType(LedgerBudgetRule)),
            isSemantics(
              label: 'Budget',
              value: '\$286.40 spent, budget \$250, suggested \$275',
            ),
          );
          final rule = t.getSize(find.byType(LedgerBudgetRule));
          // Its ratio's height, held to the whole pixel (LedgerWholeAspect).
          expect(
            rule.height,
            closeTo((rule.width * 30 / 432).roundToDouble(), .01),
          );
        },
      );
    });

    testWidgets('a chart key speaks each entry, every swatch drawn', (t) async {
      const words = {
        LedgerKeySwatch.line: 'Spent, cumulative',
        LedgerKeySwatch.pace: 'Budget pace',
        LedgerKeySwatch.bar: 'Spent per day',
        LedgerKeySwatch.payday: 'Paycheck',
        LedgerKeySwatch.tick: 'Budget \$250',
        LedgerKeySwatch.suggestion: 'Suggested \$275',
        LedgerKeySwatch.spent: 'Spent \$286.40',
        LedgerKeySwatch.spentOver: 'Spent \$286.40',
        LedgerKeySwatch.barGreen: 'Interest earned, by month',
        LedgerKeySwatch.allocationInk: 'Stocks',
        LedgerKeySwatch.allocationGreen: 'Bonds',
        LedgerKeySwatch.allocationPale: 'Cash',
      };
      expect(words.keys, containsAll(LedgerKeySwatch.values));
      await _everywhere(
        t,
        LedgerChartKey(
          entries: [
            for (final MapEntry(:key, :value) in words.entries)
              LedgerKeyEntry(key, value),
          ],
        ),
        (wide, theme) => expect(_spoken(t), words.values.toList()),
      );
    });
  });

  // --- engravings ----------------------------------------------------------------

  group('engravings', () {
    testWidgets('every ornament says nothing', (t) async {
      await _everywhere(
        t,
        Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LedgerGuilloche(size: 320),
              const LedgerGuillocheBand(),
              LedgerCardChip(
                width: 42,
                height: 32,
                color: context.ledgerTheme.textPrimary,
              ),
              const LedgerCardChip(
                width: 42,
                height: 32,
                color: Color(0xD1EFE9DD),
              ),
              const SizedBox(
                width: double.infinity,
                child: LedgerPerforation(),
              ),
              const SizedBox(
                height: 80,
                child: LedgerPerforation(vertical: true),
              ),
              const LedgerPill('+3.86%'),
            ],
          ),
        ),
        (wide, theme) {
          expect(_spoken(t), ['+3.86%']);
          expect(
            t.getSize(find.byType(LedgerGuilloche)),
            const Size.square(320),
          );
          expect(t.getSize(find.byType(LedgerGuillocheBand)).height, 14);
          expect(
            t.getSize(find.byType(LedgerCardChip).first),
            const Size(42, 32),
          );
          expect(t.getSize(find.byType(LedgerPerforation).first).height, 6);
          expect(t.getSize(find.byType(LedgerPerforation).last).width, 6);
        },
      );
    });

    testWidgets("the watermark stands behind a screen's column, silent", (
      t,
    ) async {
      for (final size in const [_phone, _desktop]) {
        for (final brightness in Brightness.values) {
          _size(t, size);
          await t.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, page) =>
                  LedgerHost(brightness: brightness, child: page!),
              home: const LedgerScreen(
                topBar: LedgerTopBar.none,
                backdrop: LedgerWatermark(),
                body: LedgerPill('+3.86%'),
              ),
            ),
          );
          final where = '${size.width.round()} wide, ${brightness.name}';
          expect(t.takeException(), isNull, reason: where);
          expect(_spoken(t), ['+3.86%'], reason: where);
          // A phone's rosette 360 round, the desktop's 300.
          expect(
            t.getSize(find.byType(LedgerGuilloche)),
            Size.square(size == _desktop ? 300 : 360),
            reason: where,
          );
        }
      }
    });
  });

  // --- register ------------------------------------------------------------------

  group('LedgerRegister', () {
    testWidgets('its day groups 20 apart, the column heads on the desktop', (
      t,
    ) async {
      await _everywhere(
        t,
        LedgerRegister(
          heads: const ['Time', 'Merchant', 'Category', 'Account', 'Amount'],
          children: [for (final d in _days.take(2)) _dayGroup(d)],
        ),
        (wide, theme) {
          for (final head in [
            'TIME',
            'MERCHANT',
            'CATEGORY',
            'ACCOUNT',
            'AMOUNT',
          ]) {
            expect(find.text(head), wide ? findsOneWidget : findsNothing);
          }
          final groups = find.byType(LedgerDayGroup);
          expect(
            t.getRect(groups.at(1)).top - t.getRect(groups.at(0)).bottom,
            wide ? 28 : 20,
          );
          // The rows stand in the heads' columns on the desktop.
          if (wide) {
            expect(
              t.getRect(find.text('Dining out')).left,
              t.getRect(find.text('CATEGORY')).left,
            );
            expect(
              t.getRect(find.text('Keel Card').first).left,
              t.getRect(find.text('ACCOUNT')).left,
            );
          }
        },
      );
    });

    testWidgets('a month rule stands 28 under the day before it', (t) async {
      await _everywhere(
        t,
        LedgerRegister(
          children: [
            _dayGroup(_days.first),
            const LedgerMonthRule('September 2026', note: 'Last month'),
          ],
        ),
        (wide, theme) => expect(
          t.getRect(find.byType(LedgerMonthRule)).top -
              t.getRect(find.byType(LedgerDayGroup)).bottom,
          28,
        ),
      );
    });

    testWidgets("Home's recent activity: each row carries its day", (t) async {
      final recent = [for (final d in _days) ...d.$4];
      await _everywhere(
        t,
        LedgerRegister(
          showDay: true,
          children: [
            for (final tx in recent) _txRow(tx, withDay: true, onTap: (_) {}),
          ],
        ),
        (wide, theme) {
          expect(find.text('Yesterday, 6:22 PM'), findsOneWidget);
          final hairlines = find.descendant(
            of: find.byType(LedgerRegister),
            matching: find.byWidgetPredicate(
              (w) => w is ColoredBox && w.color == theme.hairline,
            ),
          );
          expect(hairlines, findsNWidgets(recent.length - 1));
          if (wide) {
            // The first column widened to hold the day and the time.
            final column = find
                .ancestor(
                  of: find.text('Mon, Oct 26, 7:10 PM'),
                  matching: find.byType(SizedBox),
                )
                .first;
            expect(t.getSize(column).width, 176);
          }
        },
      );
    });

    testWidgets("a day's row stands the live 59 with its rule", (t) async {
      await _pump(t, LedgerRegister(children: [_dayGroup(_days.first)]));
      // `.daygroup .tx` at 390: 10, the title's 20, the 18 line of its
      // category and time (top to top), 10, and its 1 rule (LedgerRows').
      final rows = find.byType(LedgerTransactionRow);
      expect(t.getSize(rows.first).height, 58);
      expect(t.getRect(rows.at(1)).top - t.getRect(rows.first).top, 59);
    });

    testWidgets('a narrow desktop room: the columns give way, the figure '
        'scales whole', (t) async {
      final recent = [for (final d in _days) ...d.$4];
      // Home's board at 1024 and 1100 (width - 248 - 2 x 56): the register
      // spans it; the margin is four of its twelve columns (24 apart) less
      // its 32.
      for (final width in const [1024.0, 1100.0]) {
        final room = width - 248 - 2 * 56;
        final margin = (room - 11 * 24) / 12 * 4 + 3 * 24 - 32;
        await _pump(
          t,
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: room,
                  child: LedgerRegister(
                    showDay: true,
                    heads: const [
                      'Time',
                      'Merchant',
                      'Category',
                      'Account',
                      'Amount',
                    ],
                    children: [
                      for (final tx in recent)
                        _txRow(tx, withDay: true, onTap: (_) {}),
                    ],
                  ),
                ),
                SizedBox(
                  width: margin,
                  child: const LedgerFigure(
                    78182.56,
                    size: LedgerFigureSize.hero,
                  ),
                ),
              ],
            ),
          ),
          size: _desktop,
        );
        expect(t.takeException(), isNull, reason: '$room');
        // Where the source's grid spills, the merchant and the narrowed
        // cells may end in an ellipsis; every amount stands whole.
        for (final p in t.renderObjectList<RenderParagraph>(
          find.descendant(
            of: find.byType(LedgerAmount),
            matching: find.byType(RichText),
          ),
        )) {
          expect(
            p.getMaxIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(p.size.width + .5),
            reason: '"${p.text.toPlainText()}" ($room)',
          );
        }
        if (room < 720) {
          // Under 720 (1024's 664) the register takes its phone form rather
          // than cut every payee to 120: no heads, each row its own lines.
          expect(find.text('CATEGORY'), findsNothing, reason: '$room');
        } else {
          // The heads and the rows still share their columns.
          expect(
            t.getRect(find.text('CATEGORY')).left,
            t.getRect(find.text('Dining out').first).left,
          );
          expect(
            t.getRect(find.text('AMOUNT')).right,
            closeTo(t.getRect(find.byType(LedgerRegister)).right, .5),
          );
        }
        expect(
          t.getSize(find.byType(LedgerFigure)).width,
          lessThanOrEqualTo(margin),
        );
      }
    });

    testWidgets('its columns keep what the register asks', (t) async {
      for (final (columns, category, account) in const [
        (LedgerRegisterColumns.full, true, true),
        (LedgerRegisterColumns.oneAccount, true, false),
        (LedgerRegisterColumns.noCategory, false, true),
        (LedgerRegisterColumns.noCategoryOneAccount, false, false),
      ]) {
        await _pump(
          t,
          LedgerRegister(columns: columns, children: [_dayGroup(_days.first)]),
          size: _desktop,
        );
        expect(t.takeException(), isNull, reason: columns.name);
        // The category stands in its own column only when it is kept.
        expect(
          find.text('Dining out'),
          category ? findsOneWidget : findsNothing,
          reason: columns.name,
        );
        expect(
          find.text('Everyday'),
          account ? findsOneWidget : findsNothing,
          reason: columns.name,
        );
      }
      await _pump(
        t,
        LedgerRegister(searchResults: true, children: [_dayGroup(_days.first)]),
        size: _desktop,
      );
      expect(t.takeException(), isNull);
      _expectWordsFit(t, 'search');
    });
  });

  group('LedgerDayGroup', () {
    testWidgets('heads its day, its date and its net', (t) async {
      await _everywhere(
        t,
        Column(
          children: [
            _dayGroup(_days.first),
            LedgerDayGroup(
              'Fri, Oct 23',
              net: 3409.6,
              rows: [_txRow(_paycheck, onTap: (_) {})],
            ),
          ],
        ),
        (wide, theme) {
          expect(
            t.getSemantics(find.text('TODAY')),
            isSemantics(isHeader: true),
          );
          expect(find.text('WED, OCT 28'), findsOneWidget);
          expect(find.bySemanticsLabel('Net −\$9.65'), findsOneWidget);
          expect(find.bySemanticsLabel('Net +\$3,409.60'), findsOneWidget);
          // Its rows denser than a page's: 36 marks.
          expect(t.getSize(find.byType(LedgerMonogram).first).width, 36);
        },
      );
    });
  });

  group('LedgerTransactionRow', () {
    testWidgets('one link read as one line, its account on the desktop', (
      t,
    ) async {
      String? opened;
      await _everywhere(
        t,
        LedgerRegister(
          children: [
            LedgerDayGroup(
              _days.first.$1,
              note: _days.first.$2,
              net: _days.first.$3,
              rows: [
                for (final tx in _days.first.$4)
                  _txRow(tx, onTap: (s) => opened = s),
              ],
            ),
          ],
        ),
        (wide, theme) {
          final label = wide
              ? 'Blue Fern Café, Pending, Dining out, 8:12 AM, Keel Card, −\$6.75'
              : 'Blue Fern Café, Pending, Dining out, 8:12 AM, −\$6.75';
          expect(_node(t, label), _live(label: label));
          expect(find.text('PENDING'), findsNWidgets(2));
        },
      );
      await t.tap(find.textContaining('Harbor Transit'));
      expect(opened, 'Harbor Transit');
    });

    testWidgets('money in green on its wash, a move dashed and quiet', (
      t,
    ) async {
      await _everywhere(
        t,
        LedgerRows(
          children: [
            _txRow(_paycheck, onTap: (_) {}),
            LedgerTransactionRow(
              title: 'To Savings',
              category: 'Transfer',
              when: 'Today',
              account: 'Everyday',
              amount: -500,
              glyph: LucideIcons.arrowRightLeft,
              onTap: () {},
            ),
          ],
        ),
        (wide, theme) {
          expect(
            _node(
              t,
              RegExp(r'^Northwind Studio, Paycheck, 6:30 AM, .*\+\$3,412\.50$'),
            ),
            _live(),
          );
          expect(
            _node(t, RegExp(r'^To Savings, Transfer, Today, .*−\$500\.00$')),
            _live(),
          );
          expect(t.widget<Text>(find.text('NS')).style?.color, theme.accent);
          expect(
            t.widget<LedgerGlyph>(find.byType(LedgerGlyph)).tone,
            LedgerGlyphTone.move,
          );
          expect(_style(t, '−\$500.00').color, theme.move);
        },
      );
    });

    testWidgets('with no onTap it is announced disabled', (t) async {
      await _pump(t, _txRow(_days.first.$4.first));
      expect(
        _node(t, 'Blue Fern Café, Pending, Dining out, 8:12 AM, −\$6.75'),
        _inert(),
      );
    });
  });

  group('LedgerBillList and LedgerBillRow', () {
    testWidgets("November's bills, the heads' columns on the desktop", (
      t,
    ) async {
      String? opened;
      await _everywhere(
        t,
        LedgerBillList(
          heads: const ['Due', 'Payee', 'Account', 'Status', 'Amount'],
          children: [
            for (final b in _bills)
              LedgerBillRow(
                due: b.$1,
                name: b.$2,
                account: b.$3,
                amount: b.$4,
                status: b.$5,
                autopay: b.$6,
                onTap: () => opened = b.$2,
              ),
          ],
        ),
        (wide, theme) {
          for (final head in ['DUE', 'PAYEE', 'ACCOUNT', 'STATUS', 'AMOUNT']) {
            expect(find.text(head), wide ? findsOneWidget : findsNothing);
          }
          expect(
            _node(t, 'Rent, \$1,150.00, Nov 1'),
            _live(label: 'Rent, \$1,150.00, Nov 1'),
          );
          expect(_node(t, 'Keel Card payment, \$1,326.44, Nov 12'), _live());
          expect(
            t.widget<Text>(find.text('Autopay on')).style?.color,
            theme.moneyIn,
          );
          expect(
            t.widget<Text>(find.text('In 4 days')).style?.color,
            wide ? theme.textSecondary : theme.textTertiary,
          );
          if (wide) {
            expect(
              t.getRect(find.text('In 4 days')).left,
              t.getRect(find.text('STATUS')).left,
            );
          }
        },
      );
      await t.tap(find.text('Kite Mobile'));
      expect(opened, 'Kite Mobile');
    });

    testWidgets('a bill with no onTap is announced disabled', (t) async {
      final b = _bills.first;
      await _pump(
        t,
        LedgerBillRow(
          due: b.$1,
          name: b.$2,
          account: b.$3,
          amount: b.$4,
          status: b.$5,
        ),
      );
      expect(_node(t, 'Rent, \$1,150.00, Nov 1'), _inert());
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
