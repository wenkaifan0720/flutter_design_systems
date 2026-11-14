import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/components/structure/structure.dart'
    show FrostedCardFace, FrostedFacedCard;
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _phone = Size(390, 844);
const _narrow = Size(320, 844);
const _desktop = Size(1280, 900);

/// The width a stretched child takes on the phone: the view less the 20
/// of room each side the host leaves.
const _phoneRoom = 350.0;

Widget _host(
  Widget child, {
  Brightness brightness = Brightness.light,
  String preset = 'opal',
  double textScale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (BuildContext context, Widget? page) => FrostedHost(
    light: FrostedThemeData.preset(preset, Brightness.light),
    dark: FrostedThemeData.preset(preset, Brightness.dark),
    brightness: brightness,
    child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: page!,
    ),
  ),
  home: child,
);

/// Pumps [child] stretched across a page 20 in from each side, at [size],
/// and fails on any exception the build raised (an overflow).
Future<void> _pump(
  WidgetTester t,
  Widget child, {
  Size size = _phone,
  Brightness brightness = Brightness.light,
  String preset = 'opal',
  double textScale = 1,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    _host(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child],
        ),
      ),
      brightness: brightness,
      preset: preset,
      textScale: textScale,
    ),
  );
  expect(t.takeException(), isNull);
}

/// Pumps a tall column of [children] in a scroll, for a build of everything.
Future<void> _pumpAll(
  WidgetTester t,
  List<Widget> children, {
  Brightness brightness = Brightness.light,
  String preset = 'opal',
  Size size = _phone,
}) => _pump(
  t,
  Expanded(
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: children,
      ),
    ),
  ),
  brightness: brightness,
  preset: preset,
  size: size,
);

SemanticsNode _node(WidgetTester t, Finder finder) => t.getSemantics(finder);

/// A widget test with semantics on for its whole body, the handle let go
/// before the end-of-test checks.
void _test(String name, Future<void> Function(WidgetTester t) body) =>
    testWidgets(name, (t) async {
      final handle = t.ensureSemantics();
      try {
        await body(t);
      } finally {
        handle.dispose();
      }
    });

FrostedThemeData get _light =>
    FrostedThemeData.preset('opal', Brightness.light);

void _open() {}

/// A row as the transactions list draws one.
Widget _row({
  String title = 'Blue Fern Café',
  String sub = 'Dining out · 8:12 AM',
  num amount = -6.75,
  VoidCallback? onTap = _open,
  bool current = false,
}) => Builder(
  builder: (context) => FrostedListTile(
    leading: FrostedMonogram(title, hue: context.frostedTheme.hues.coral),
    title: title,
    meta: sub,
    trailing: FrostedAmount(amount),
    onPressed: onTap,
    selected: current,
  ),
);

List<FrostedKeyValue> _facts({VoidCallback? onTap}) => [
  const FrostedKeyValue(label: 'Target', value: r'$1,800'),
  const FrostedKeyValue(label: 'Date', value: 'Oct 1, 2027'),
  FrostedKeyValue(label: 'Held in', value: 'Savings ·· 9015', onPressed: onTap),
  const FrostedKeyValue(label: 'Auto-save', value: r'$100 on the 1st'),
  FrostedKeyValue(label: 'From', value: 'Everyday', onPressed: onTap),
  const FrostedKeyValue(label: 'Started', value: 'May 1, 2026'),
];

Widget _recordHero() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedRecordHero(
      mark: FrostedIconMark(LucideIcons.chartLine, hue: t.hues.lagoon),
      title: 'Investing',
      subtitle: 'Brokerage',
      amount: 48920.70,
      of: 'Market value',
      hue: t.hues.lagoon,
      chips: [
        const FrostedTag(
          r'+$391.37 · +0.81%',
          icon: LucideIcons.trendingUp,
          tone: FrostedTone.success,
        ),
        Text('today', style: t.textTheme.bodyMedium),
      ],
      note: 'Market closed · prices at 4:00 PM ET',
    );
  },
);

Widget _insight({VoidCallback? onTap = _open}) => Builder(
  builder: (context) => FrostedInsight(
    icon: LucideIcons.utensils,
    kind: 'Insight · Dining out',
    title: r'$36.40 over budget',
    body: r'13 visits to Blue Fern Café came to **$84.25**.',
    hue: context.frostedTheme.hues.coral,
    visits: 13,
    onPressed: onTap,
  ),
);

Widget _note({VoidCallback? onTap = _open, bool unread = false}) => FrostedNote(
  lead: FrostedTransactionMark.income('Northwind Studio'),
  title: 'Paycheck landed',
  body: r'+$3,412.50 from Northwind Studio.',
  when: 'Fri, Oct 23 · 6:31 AM',
  unread: unread,
  onPressed: onTap,
);

Widget _everything(BuildContext context) {
  final t = context.frostedTheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      for (final face in FrostedCardFace.values)
        FrostedFacedCard(
          face: face,
          hue: t.hues.cyan,
          child: Text(face.name, style: t.textTheme.titleMedium),
        ),
      const FrostedCardHeader('Transactions', trailing: Text('32 in October')),
      const FrostedSectionHeader('Accounts', aside: '5 accounts'),
      _row(),
      FrostedTransactionRow(
        mark: FrostedTransactionMark.purchase('Harbor Transit', hue: t.hue(5)),
        title: 'Harbor Transit',
        subtitle: 'Transport · 7:48 AM',
        amount: -2.90,
        pending: true,
        account: 'Everyday',
        accountIcon: LucideIcons.wallet,
        onPressed: _open,
      ),
      const FrostedDayHead('Today', net: -9.65, first: true),
      FrostedRowGroup(
        timeline: true,
        children: [
          FrostedListTile(
            leading: FrostedDateBlock(
              DateTime(2026, 11),
              soon: true,
              hue: t.hues.periwinkle,
            ),
            title: 'Rent',
            meta: 'Everyday ·· 4821 · In 4 days',
            trailing: const FrostedAmount(1150, signed: false),
            onPressed: _open,
          ),
          FrostedListTile(
            leading: FrostedDateBlock(DateTime(2026, 11, 3)),
            title: 'Kite Mobile',
            meta: 'Keel Card ·· 7730 · In 6 days',
            trailing: const FrostedAmount(35, signed: false),
            onPressed: _open,
          ),
        ],
      ),
      const FrostedMonthDivider('September 2026'),
      FrostedDescriptionList(children: _facts(onTap: _open)),
      _recordHero(),
      FrostedRecordHero.centred(
        mark: FrostedTransactionMark.purchase(
          'Mesa Taqueria',
          hue: t.hues.coral,
          size: FrostedMarkSize.large,
        ),
        title: 'Mesa Taqueria',
        subtitle: 'Dining out · Keel Card',
        amount: -38.40,
        hue: t.hues.coral,
        chips: [
          const FrostedTag('Posted', icon: LucideIcons.check),
          Text('Tue, Sep 29 · 12:40 PM', style: t.textTheme.bodyMedium),
        ],
      ),
      FrostedRecordHero.review(
        route: const Text('route'),
        amount: 500,
        subtitle: 'From Everyday to Savings',
        hue: t.hues.seafoam,
      ),
      _insight(),
      FrostedSuggestion(
        icon: LucideIcons.sparkles,
        title: r'Suggested $275',
        subtitle: 'Your September and October average',
        hue: t.hues.coral,
      ),
      _note(unread: true),
      FrostedNoteHero(
        mark: FrostedIconMark(
          LucideIcons.receipt,
          hue: t.hues.periwinkle,
          size: FrostedMarkSize.large,
        ),
        when: 'New · Today · 9:00 AM',
        title: 'Rent is due in 4 days',
        body: r'$1,150.00 to Linden Court Apartments on Nov 1.',
        action: 'See your bills',
        hue: t.hues.periwinkle,
        onPressed: _open,
      ),
      const FrostedNudge(r'Add $110 to stay on track.'),
      const FrostedNudge(
        r'On track for next October at $100 a month.',
        ok: true,
      ),
      const FrostedBanner(
        icon: LucideIcons.snowflake,
        title: 'Your Keel Card is frozen',
        body: 'New purchases and cash withdrawals are declined.',
      ),
      FrostedBrowseCard(
        icon: LucideIcons.house,
        hue: t.hues.periwinkle,
        title: 'Rent & home',
        subtitle: r'$1,150.00',
        onPressed: _open,
      ),
      FrostedAccountCard(
        icon: LucideIcons.wallet,
        hue: t.hues.cyan,
        name: 'Everyday',
        kind: 'Checking',
        mask: '•• 4821',
        balance: 6248.30,
        onPressed: _open,
      ),
      FrostedTicket(
        name: 'Linden Court Apartments',
        title: 'Linden Court Apartments',
        subtitle: 'One payment from Everyday',
        hue: t.hues.periwinkle,
        chip: 'Autopay',
        chipIcon: LucideIcons.check,
        onPressed: _open,
      ),
    ],
  );
}

void main() {
  setUp(
    () =>
        TestWidgetsFlutterBinding
            .instance
            .platformDispatcher
            .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        ),
  );
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  group('structure', () {
    _test('every face builds in both presets, light and dark', (t) async {
      for (final preset in FrostedThemeData.presets) {
        for (final brightness in Brightness.values) {
          await _pumpAll(
            t,
            [Builder(builder: _everything)],
            preset: preset,
            brightness: brightness,
          );
          expect(find.byType(FrostedCard), findsWidgets);
        }
      }
    });

    _test('everything builds on the desktop', (t) async {
      await _pumpAll(t, [Builder(builder: _everything)], size: _desktop);
      expect(find.byType(FrostedCard), findsWidgets);
    });

    _test('a tile with a tap is one link saying its label', (t) async {
      var opened = 0;
      await _pump(
        t,
        FrostedCard(
          label: 'October so far',
          onPressed: () => opened++,
          child: const Text('words'),
        ),
      );
      final node = _node(t, find.bySemanticsLabel('October so far'));
      expect(node, isSemantics(isLink: true, hasTapAction: true));
      await t.tap(find.byType(FrostedCard));
      expect(opened, 1);
    });

    _test('a tile without a tap names its group', (t) async {
      await _pump(
        t,
        const FrostedCard(label: 'Budget', child: Text('On pace')),
      );
      final node = _node(t, find.bySemanticsLabel(RegExp('^Budget')));
      expect(node, isSemantics(isLink: false, hasTapAction: false));
      expect(find.text('On pace'), findsOneWidget);
    });

    _test('a tile pads its child and takes the page width', (t) async {
      await _pump(t, const FrostedCard(child: Text('words')));
      expect(t.getSize(find.byType(FrostedCard)).width, _phoneRoom);
      final tile = t.getTopLeft(find.byType(FrostedCard));
      final words = t.getTopLeft(find.text('words'));
      expect(words.dx - tile.dx, 16);
      expect(words.dy - tile.dy, 16);
    });

    _test('the tile header is a header with its end at the far end', (t) async {
      await _pump(
        t,
        const FrostedCardHeader(
          'Transactions',
          trailing: Text('32 in October'),
        ),
      );
      expect(
        _node(t, find.bySemanticsLabel('Transactions')),
        isSemantics(isHeader: true),
      );
      expect(t.getTopRight(find.text('32 in October')).dx, closeTo(370, 1));
      expect(
        t.getSize(find.byType(FrostedCardHeader)).height,
        greaterThanOrEqualTo(36),
      );
    });

    _test('a section shows on a phone and hides on the desktop', (t) async {
      await _pump(
        t,
        const FrostedSectionHeader('Accounts', aside: '5 accounts'),
      );
      expect(
        _node(t, find.bySemanticsLabel('Accounts')),
        isSemantics(isHeader: true),
      );
      expect(find.text('5 accounts'), findsOneWidget);
      await _pump(
        t,
        const FrostedSectionHeader('Accounts', aside: '5 accounts'),
        size: _desktop,
      );
      expect(find.text('Accounts'), findsNothing);
    });

    _test('a row is one link saying its title, sub and amount', (t) async {
      await _pump(t, _row());
      final node = _node(t, find.byType(FrostedListTile));
      expect(node, isSemantics(isLink: true, hasTapAction: true));
      expect(node.getSemanticsData().label, contains('Blue Fern Café'));
      expect(node.getSemanticsData().label, contains('Dining out · 8:12 AM'));
      expect(node.getSemanticsData().label, contains('6.75'));
      expect(
        t.getSize(find.byType(FrostedListTile)).height,
        greaterThanOrEqualTo(52),
      );
    });

    _test('a row without a tap still reads as one', (t) async {
      await _pump(t, _row(onTap: null));
      final node = _node(t, find.byType(FrostedListTile));
      expect(node, isSemantics(isLink: false));
      expect(node.getSemanticsData().label, contains('Blue Fern Café'));
    });

    _test('the current row keeps its width while its mark bleeds', (t) async {
      await _pump(t, _row(current: true));
      expect(t.getSize(find.byType(FrostedListTile)).width, _phoneRoom);
      expect(
        t.getTopLeft(find.text('Blue Fern Café')).dx,
        t.getTopLeft(find.byType(FrostedListTile)).dx + 36 + 12,
      );
    });

    _test('a long title keeps to its lines at 320 and text scale 1.3', (
      t,
    ) async {
      await _pump(
        t,
        _row(
          title: 'Linden Court Apartments monthly rent and parking',
          sub: 'Rent & home · Everyday ·· 4821 · Mon, Nov 1',
        ),
        size: _narrow,
        textScale: 1.3,
      );
      expect(find.byType(FrostedListTile), findsOneWidget);
    });

    _test("a row end puts the note under the amount in its tone", (t) async {
      await _pump(
        t,
        const Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FrostedRowEnd(
            amount: Text('amount'),
            note: 'Pending',
            noteIcon: LucideIcons.clock,
            noteTone: FrostedTone.warning,
          ),
        ),
      );
      expect(
        t.getTopLeft(find.text('Pending')).dy,
        greaterThan(t.getBottomLeft(find.text('amount')).dy),
      );
      expect(
        t.widget<Text>(find.text('Pending')).style!.color,
        _light.colorScheme.warning,
      );
      expect(find.byIcon(LucideIcons.clock), findsOneWidget);
    });

    _test(
      'a transaction row says Pending and shows its account on the desktop only',
      (t) async {
        Widget row() => Builder(
          builder: (context) => FrostedTransactionRow(
            mark: FrostedTransactionMark.purchase(
              'Blue Fern Café',
              hue: context.frostedTheme.hues.coral,
            ),
            title: 'Blue Fern Café',
            subtitle: 'Dining out · 8:12 AM',
            amount: -6.75,
            pending: true,
            account: 'Keel Card',
            accountIcon: LucideIcons.creditCard,
            onPressed: _open,
          ),
        );
        await _pump(t, row());
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('Keel Card'), findsNothing);
        await _pump(t, row(), size: _desktop);
        expect(find.text('Keel Card'), findsOneWidget);
        expect(
          t
              .getSize(
                find
                    .ancestor(
                      of: find.text('Keel Card'),
                      matching: find.byType(SizedBox),
                    )
                    .first,
              )
              .width,
          148,
        );
        expect(
          t.getSize(find.byType(FrostedRowEnd)).width,
          greaterThanOrEqualTo(96),
        );
        // The row's one node is its tile's (the row decides its columns by
        // its own width, through a LayoutBuilder that makes no node).
        expect(
          _node(
            t,
            find.descendant(
              of: find.byType(FrostedTransactionRow),
              matching: find.byType(FrostedListTile),
            ),
          ).getSemanticsData().label,
          contains('Keel Card'),
        );
      },
    );

    _test('a day head is a header with the day\'s net, 2 down when first', (
      t,
    ) async {
      await _pump(
        t,
        const Column(
          children: [
            FrostedDayHead('Today', net: -9.65, first: true),
            FrostedDayHead('Yesterday', net: 3409.60),
          ],
        ),
      );
      expect(
        _node(t, find.bySemanticsLabel('Today')),
        isSemantics(isHeader: true),
      );
      expect(find.byType(FrostedAmount), findsNWidgets(2));
      expect(
        t.getTopLeft(find.text('Today')).dy -
            t.getTopLeft(find.byType(FrostedDayHead).first).dy,
        2,
      );
      expect(
        t.getTopLeft(find.text('Yesterday')).dy -
            t.getTopLeft(find.byType(FrostedDayHead).last).dy,
        14,
      );
    });

    _test('a row group rules hairlines and spines between two rows only', (
      t,
    ) async {
      await _pump(
        t,
        FrostedRowGroup(hairlines: true, children: [_note(), _note(), _note()]),
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border != null,
        ),
        findsNWidgets(2),
      );
      await _pump(
        t,
        FrostedRowGroup(
          timeline: true,
          children: [
            const FrostedDayHead('November', first: true),
            FrostedListTile(
              leading: FrostedDateBlock(DateTime(2026, 11)),
              title: 'Rent',
            ),
            FrostedListTile(
              leading: FrostedDateBlock(DateTime(2026, 11, 3)),
              title: 'Kite Mobile',
            ),
            const FrostedDayHead('December'),
            FrostedListTile(
              leading: FrostedDateBlock(DateTime(2026, 12)),
              title: 'Rent',
            ),
          ],
        ),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 1 && w.height == 12,
        ),
        findsOneWidget,
      );
    });

    _test('a month divider is a header under its hairline', (t) async {
      await _pump(t, const FrostedMonthDivider('September 2026'));
      expect(
        _node(t, find.bySemanticsLabel('September 2026')),
        isSemantics(isHeader: true),
      );
      expect(
        t.getTopLeft(find.text('September 2026')).dy -
            t.getTopLeft(find.byType(FrostedMonthDivider)).dy,
        27,
      );
    });

    _test(
      'key values rule a hairline between lines, a tappable fact is a link',
      (t) async {
        var opened = 0;
        await _pump(
          t,
          FrostedDescriptionList(children: _facts(onTap: () => opened++)),
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).border != null,
          ),
          findsNWidgets(5),
        );
        final held = _node(t, find.byType(FrostedKeyValue).at(2));
        expect(held, isSemantics(isLink: true, hasTapAction: true));
        expect(held.getSemanticsData().label, contains('Held in'));
        expect(held.getSemanticsData().label, contains('Savings ·· 9015'));
        expect(
          _node(t, find.byType(FrostedKeyValue).first),
          isSemantics(isLink: false),
        );
        expect(t.getTopRight(find.text('Oct 1, 2027')).dx, closeTo(370, 1));
        expect(find.byIcon(FrostedGlyphs.forward), findsNWidgets(2));
        // a.kv-r: the chevron is the line's own part, 12 after the value.
        expect(
          t.getTopLeft(find.byIcon(FrostedGlyphs.forward).first).dx -
              t.getTopRight(find.text('Savings ·· 9015')).dx,
          closeTo(12, 0.01),
        );
        await t.tap(find.text('Held in'));
        expect(opened, 1);
        // One-line facts: the first and the ruled ones alike stand 52, the
        // hairline inside the 52 as the source's border-box rows keep it.
        for (final kv in find.byType(FrostedKeyValue).evaluate()) {
          expect(kv.size!.height, closeTo(52, 0.01));
        }
      },
    );

    _test('a fact holds a widget value and a sub', (t) async {
      await _pump(
        t,
        const FrostedDescriptionList(
          children: [
            FrostedKeyValue(
              label: 'Amount',
              valueWidget: FrostedAmount(500, signed: false),
              subtitle: 'arrives today',
            ),
          ],
        ),
      );
      expect(find.byType(FrostedAmount), findsOneWidget);
      expect(
        t.getTopLeft(find.text('arrives today')).dy,
        greaterThan(t.getBottomLeft(find.byType(FrostedAmount)).dy),
      );
    });

    _test(
      'key values in a grid stand three across on the desktop, lines on a phone',
      (t) async {
        await _pump(
          t,
          FrostedDescriptionList(grid: true, children: _facts(onTap: _open)),
          size: _desktop,
        );
        final target = t.getTopLeft(find.text('Target'));
        final date = t.getTopLeft(find.text('Date'));
        final held = t.getTopLeft(find.text('Held in'));
        final auto = t.getTopLeft(find.text('Auto-save'));
        expect(date.dy, target.dy);
        expect(held.dy, target.dy);
        expect(date.dx, greaterThan(target.dx));
        expect(held.dx, greaterThan(date.dx));
        expect(auto.dy, greaterThan(target.dy));
        expect(auto.dx, target.dx);
        expect(t.getTopLeft(find.text(r'$1,800')).dy, greaterThan(target.dy));
        expect(t.getTopLeft(find.text(r'$1,800')).dx, target.dx);
        // Every fact as tall as its row (`align-items: stretch`): beside a
        // fact with a line under its value, a linked one's press reaches the
        // row's floor.
        await _pump(
          t,
          FrostedDescriptionList(
            grid: true,
            children: [
              const FrostedKeyValue(label: 'Target', value: r'$24,000'),
              const FrostedKeyValue(
                label: 'Date',
                value: 'None set',
                subtitle: 'Reaches May 2027',
              ),
              FrostedKeyValue(
                label: 'Held in',
                value: 'Savings ·· 9015',
                onPressed: _open,
              ),
            ],
          ),
          size: _desktop,
        );
        final press = t.getRect(
          find.descendant(
            of: find.byType(FrostedDescriptionList),
            matching: find.byType(FrostedPressable),
          ),
        );
        expect(press.top, t.getRect(find.byType(FrostedDescriptionList)).top);
        expect(
          press.bottom,
          t.getRect(find.byType(FrostedDescriptionList)).bottom,
        );
        expect(
          press.bottom,
          greaterThan(t.getRect(find.text('Reaches May 2027')).bottom),
        );
        await _pump(t, FrostedDescriptionList(grid: true, children: _facts()));
        expect(
          t.getTopLeft(find.text('Date')).dx,
          t.getTopLeft(find.text('Target')).dx,
        );
        expect(
          t.getTopLeft(find.text('Date')).dy,
          greaterThan(t.getTopLeft(find.text('Target')).dy),
        );
      },
    );

    _test(
      'a record hero heads its record: header, figure, chips and a full note',
      (t) async {
        await _pump(t, _recordHero());
        expect(
          _node(t, find.bySemanticsLabel('Investing')),
          isSemantics(isHeader: true),
        );
        expect(find.byType(FrostedMoney), findsOneWidget);
        expect(find.text('Market value'), findsOneWidget);
        expect(find.byType(FrostedTag), findsOneWidget);
        expect(
          t.getSize(find.text('Market closed · prices at 4:00 PM ET')).width,
          _phoneRoom - 32,
        );
        expect(
          t.getTopLeft(find.text('today')).dy,
          lessThan(
            t.getTopLeft(find.text('Market closed · prices at 4:00 PM ET')).dy,
          ),
        );
      },
    );

    _test('a centred hero centres its mark, title and figure', (t) async {
      await _pump(
        t,
        Builder(
          builder: (context) => FrostedRecordHero.centred(
            mark: FrostedTransactionMark.purchase(
              'Mesa Taqueria',
              hue: context.frostedTheme.hues.coral,
              size: FrostedMarkSize.large,
            ),
            title: 'Mesa Taqueria',
            subtitle: 'Dining out · Keel Card',
            amount: -38.40,
            hue: context.frostedTheme.hues.coral,
            chips: const [FrostedTag('Posted', icon: LucideIcons.check)],
          ),
        ),
      );
      expect(
        t.getCenter(find.byType(FrostedTransactionMark)).dx,
        closeTo(195, 1),
      );
      expect(t.getCenter(find.text('Mesa Taqueria')).dx, closeTo(195, 1));
      expect(t.getCenter(find.byType(FrostedMoney)).dx, closeTo(195, 1));
      expect(t.getCenter(find.byType(FrostedTag)).dx, closeTo(195, 1));
      expect(
        t.getTopLeft(find.byType(FrostedTransactionMark)).dy -
            t.getTopLeft(find.byType(FrostedCard)).dy,
        28,
      );
    });

    _test('a centred hero centres short words on the tile, not at its '
        'start (`.txn-hero` under its rim)', (t) async {
      await _pump(
        t,
        Builder(
          builder: (context) => FrostedRecordHero.centred(
            mark: FrostedTransactionMark.purchase(
              'Lumen',
              hue: context.frostedTheme.hues.lemon,
              size: FrostedMarkSize.large,
            ),
            title: 'Lumen',
            subtitle: 'Fun',
            amount: -6.75,
            hue: context.frostedTheme.hues.lemon,
            chips: const [FrostedTag('Posted', icon: LucideIcons.check)],
          ),
        ),
      );
      // The words are far narrower than the tile: each stands on its centre.
      expect(t.getSize(find.text('Lumen')).width, lessThan(_phoneRoom / 2));
      for (final part in [
        find.byType(FrostedTransactionMark),
        find.text('Lumen'),
        find.text('Fun'),
        find.byType(FrostedMoney),
        find.byType(FrostedTag),
      ]) {
        expect(t.getCenter(part).dx, closeTo(195, 1));
      }
    });

    _test('a review hero holds its route over the figure', (t) async {
      await _pump(
        t,
        const FrostedRecordHero.review(
          route: Text('route'),
          amount: 500,
          subtitle: 'From Everyday to Savings',
        ),
      );
      expect(
        t.getTopLeft(find.text('route')).dy -
            t.getTopLeft(find.byType(FrostedCard)).dy,
        24,
      );
      expect(
        t.getTopLeft(find.byType(FrostedMoney)).dy,
        greaterThan(t.getBottomLeft(find.text('route')).dy),
      );
      expect(
        t.getTopLeft(find.text('From Everyday to Savings')).dy,
        greaterThan(t.getBottomLeft(find.byType(FrostedMoney)).dy),
      );
    });

    _test('an insight bolds its runs, says its visits and is a link', (
      t,
    ) async {
      await _pump(t, _insight());
      expect(
        find.textContaining(r'$84.25', findRichText: true),
        findsOneWidget,
      );
      final insight = _node(t, find.byType(FrostedInsight)).getSemanticsData();
      expect(insight.label, contains('13 visits'));
      expect(insight.label, contains(r'$36.40 over budget'));
      expect(
        _node(t, find.byType(FrostedInsight)),
        isSemantics(isLink: true, hasTapAction: true),
      );
      final span =
          t
                  .widget<RichText>(
                    find.textContaining(r'$84.25', findRichText: true),
                  )
                  .text
              as TextSpan;
      // Text.rich wraps the runs in the inherited style's span: walk the tree.
      final bold = <String?>[];
      span.visitChildren((s) {
        if (s is TextSpan && s.style?.fontWeight == FontWeight.w600) {
          bold.add(s.text);
        }
        return true;
      });
      expect(bold, [r'$84.25']);
    });

    _test('an insight wraps at 320 and text scale 1.3', (t) async {
      await _pump(t, _insight(), size: _narrow, textScale: 1.3);
      expect(find.byType(FrostedInsight), findsOneWidget);
    });

    _test('a suggestion is a statement, or a button with a tap', (t) async {
      Widget suggest({VoidCallback? onTap}) => Builder(
        builder: (context) => FrostedSuggestion(
          icon: LucideIcons.sparkles,
          title: r'Suggested $275',
          subtitle: 'Your September and October average',
          hue: context.frostedTheme.hues.coral,
          onPressed: onTap,
        ),
      );
      await _pump(t, suggest());
      expect(
        _node(t, find.byType(FrostedSuggestion)),
        isSemantics(isButton: false),
      );
      await _pump(t, suggest(onTap: _open));
      final node = _node(t, find.byType(FrostedSuggestion));
      expect(node, isSemantics(isButton: true, hasTapAction: true));
      expect(node.getSemanticsData().label, contains(r'Suggested $275'));
    });

    _test('a note is one link with its words, its dot and its chevron', (
      t,
    ) async {
      await _pump(t, _note(unread: true));
      final node = _node(t, find.byType(FrostedNote));
      expect(node, isSemantics(isLink: true, hasTapAction: true));
      expect(node.getSemanticsData().label, contains('Paycheck landed'));
      expect(node.getSemanticsData().label, contains('Fri, Oct 23 · 6:31 AM'));
      expect(node.getSemanticsData().label, contains('Unread'));
      expect(find.byIcon(FrostedGlyphs.forward), findsOneWidget);
      // The when on .cap's 15.6 line (the engine lays it on a whole pixel),
      // 5 under the words (its 4 and their 1).
      final when = t.getRect(find.text('Fri, Oct 23 · 6:31 AM'));
      final body = t.getRect(find.text(r'+$3,412.50 from Northwind Studio.'));
      expect(when.top - body.bottom, closeTo(5, 0.01));
      final whenStyle = t.widget<Text>(find.text('Fri, Oct 23 · 6:31 AM'));
      expect(
        whenStyle.style!.fontSize! * whenStyle.style!.height!,
        closeTo(15.6, 0.01),
      );
      await _pump(t, _note(onTap: null));
      expect(find.byIcon(FrostedGlyphs.forward), findsNothing);
      expect(
        _node(t, find.byType(FrostedNote)).getSemanticsData().label,
        isNot(contains('Unread')),
      );
    });

    _test('a note wraps its body at 320 and text scale 1.3', (t) async {
      await _pump(t, _note(), size: _narrow, textScale: 1.3);
      expect(find.byType(FrostedNote), findsOneWidget);
    });

    _test('a note hero is a link with its header and its action', (t) async {
      await _pump(
        t,
        const FrostedNoteHero(
          mark: FrostedIconMark(
            LucideIcons.receipt,
            size: FrostedMarkSize.large,
          ),
          when: 'New · Today · 9:00 AM',
          title: 'Rent is due in 4 days',
          body: r'$1,150.00 to Linden Court Apartments on Nov 1.',
          action: 'See your bills',
          onPressed: _open,
        ),
      );
      expect(_node(t, find.byType(FrostedNoteHero)), isSemantics(isLink: true));
      final words = _node(
        t,
        find.byType(FrostedNoteHero),
      ).getSemanticsData().label;
      expect(words, contains('Rent is due in 4 days'));
      expect(words, contains('New · Today · 9:00 AM'));
      expect(find.text('See your bills'), findsOneWidget);
      expect(words, contains('Unread'));
    });

    _test('a nudge is warm, or green when ok, its action at the end', (
      t,
    ) async {
      await _pump(
        t,
        FrostedNudge(
          r'Add $110 to stay on track.',
          action: FrostedButton(
            r'Add $110',
            size: FrostedButtonSize.small,
            onPressed: _open,
          ),
        ),
      );
      expect(find.byIcon(LucideIcons.clock), findsOneWidget);
      expect(
        t.widget<Icon>(find.byIcon(LucideIcons.clock)).color,
        _light.colorScheme.warning,
      );
      expect(t.getTopRight(find.byType(FrostedButton)).dx, closeTo(360, 1));
      await _pump(t, const FrostedNudge('On track.', ok: true));
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(
        t.widget<Icon>(find.byIcon(LucideIcons.check)).color,
        _light.colorScheme.moneyIn,
      );
    });

    _test('a banner is cold and wraps its body', (t) async {
      const banner = FrostedBanner(
        icon: LucideIcons.snowflake,
        title: 'Your Keel Card is frozen',
        body: 'New purchases and cash withdrawals are declined. Autopay, refunds and payments still go through.',
      );
      await _pump(t, banner, size: _narrow, textScale: 1.3);
      expect(
        t.widget<Text>(find.text('Your Keel Card is frozen')).style!.color,
        _light.colorScheme.cold,
      );
      expect(
        t.widget<Text>(find.text('Your Keel Card is frozen')).style!.fontWeight,
        FontWeight.w600,
      );
      expect(t.getSize(find.byType(FrostedBanner)).height, greaterThan(80));
    });

    _test('a banner takes the inset a page hands it', (t) async {
      Future<double> wordsIn(EdgeInsets? padding) async {
        await _pump(
          t,
          FrostedBanner(
            icon: LucideIcons.snowflake,
            title: 'Frozen',
            body: 'Declined.',
            padding: padding,
          ),
        );
        return t.getTopLeft(find.text('Frozen')).dx -
            t.getTopLeft(find.byType(FrostedBanner)).dx;
      }

      // 16 + the 36 mark + 12; the Cards page's desktop 20 stands it 4 on.
      expect(await wordsIn(null), 64);
      expect(
        await wordsIn(const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
        68,
      );
    });

    _test('two browse cards share a line, each a link', (t) async {
      await _pump(
        t,
        Builder(
          builder: (context) {
            final t = context.frostedTheme;
            return Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FrostedBrowseCard(
                    icon: LucideIcons.house,
                    hue: t.hues.periwinkle,
                    title: 'Rent & home',
                    subtitle: r'$1,150.00',
                    onPressed: _open,
                  ),
                ),
                Expanded(
                  child: FrostedBrowseCard(
                    icon: LucideIcons.utensils,
                    hue: t.hues.coral,
                    title: 'Dining out',
                    subtitle: r'$286.40',
                    onPressed: _open,
                  ),
                ),
              ],
            );
          },
        ),
      );
      expect(
        t.getSize(find.byType(FrostedBrowseCard).first).width,
        (_phoneRoom - 8) / 2,
      );
      final node = _node(t, find.byType(FrostedBrowseCard).first);
      expect(node, isSemantics(isLink: true, hasTapAction: true));
      expect(node.getSemanticsData().label, contains('Rent & home'));
      expect(find.byType(FrostedIconMark), findsNWidgets(2));
      // .browse-c .row-t { font-size: 14px } on .row-t's 1.25: a 17.5
      // line (the engine lays it on a whole pixel) over the 12 figure's, 1
      // apart, 10 inside.
      final title = t.widget<Text>(find.text('Rent & home').first).style!;
      expect(title.fontSize! * title.height!, closeTo(17.5, 0.01));
      final card = t.getRect(find.byType(FrostedBrowseCard).first);
      final words = t.getRect(find.text('Rent & home').first);
      final figure = t.getRect(find.text(r'$1,150.00'));
      expect(words.top - card.top, closeTo(10, 0.01));
      expect(figure.top - words.bottom, closeTo(1, 0.01));
      expect(card.bottom - figure.bottom, closeTo(10, 0.01));
      // The figure is `num()`'s: the display face, tabular.
      final sub = t.widget<Text>(find.text(r'$1,150.00')).style!;
      expect(sub.fontFamily, FrostedThemeData.face);
      expect(sub.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    _test(
      'an account card says its name and kind, its figure in the small face',
      (t) async {
        await _pump(
          t,
          Builder(
            builder: (context) => FrostedAccountCard(
              icon: LucideIcons.wallet,
              hue: context.frostedTheme.hues.cyan,
              name: 'Everyday',
              kind: 'Checking',
              mask: '•• 4821',
              balance: 6248.30,
              note: r'+$73.42 interest',
              onPressed: _open,
            ),
          ),
        );
        expect(
          _node(t, find.bySemanticsLabel('Everyday, Checking')),
          isSemantics(isLink: true, hasTapAction: true),
        );
        expect(
          t.widget<FrostedMoney>(find.byType(FrostedMoney)).size,
          FrostedMoneySize.small,
        );
        expect(find.text('•• 4821'), findsOneWidget);
        // The note stands 6 under the figure (`.acct-note { margin-top:
        // 6px }` inside the figure's own item), not the card's gap more.
        expect(
          t.getTopLeft(find.text(r'+$73.42 interest')).dy -
              t.getBottomLeft(find.byType(FrostedMoney)).dy,
          FrostedChromeMetrics.accountNoteGap,
        );
      },
    );

    _test('a ticket carries its monogram, two lines and its chip', (t) async {
      await _pump(
        t,
        Builder(
          builder: (context) => FrostedTicket(
            name: 'Linden Court Apartments',
            title: 'Linden Court Apartments',
            subtitle: 'One payment from Everyday',
            hue: context.frostedTheme.hues.periwinkle,
            chip: 'Autopay',
            chipIcon: LucideIcons.check,
            onPressed: _open,
          ),
        ),
        size: _narrow,
      );
      expect(find.byType(FrostedMonogram), findsOneWidget);
      expect(find.text('Autopay'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      final node = _node(t, find.byType(FrostedTicket));
      expect(node, isSemantics(isLink: true, hasTapAction: true));
      expect(node.getSemanticsData().label, contains('Autopay'));
      expect(t.getSize(find.byType(FrostedMonogram)).width, 32);
    });
  });
}
