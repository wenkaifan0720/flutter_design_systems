/// How a Frosted page is built: [FrostedCard] in its faces (the glass, the
/// spectrum rim, the ghost), headed by a [FrostedCardHeader] or, on the canvas,
/// by a [FrostedSectionHeader]; the rows ([FrostedListTile] with its [FrostedRowEnd], a
/// [FrostedTransactionRow] under its [FrostedDayHead]) in a [FrostedRowGroup] on a
/// timeline, across a [FrostedMonthDivider], or marking the row the page is
/// about; a record's facts ([FrostedDescriptionList] of [FrostedKeyValue], in lines
/// or three across on the desktop); a record's head ([FrostedRecordHero] for
/// an account, a category, a transaction centred, a move's review);
/// Spending's [FrostedInsight]; a sheet's [FrostedSuggestion]; what is new
/// ([FrostedNoteHero]) over the earlier [FrostedNote]s; the [FrostedNudge] warm
/// and at ease; the cold [FrostedBanner]; categories to browse
/// ([FrostedBrowseCard]); Home's accounts ([FrostedAccountCard]); and a bill's
/// [FrostedTicket], each at the look's own values.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitStructureDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Structure',
  sections: [
    kitSection(
      'The tile: the glass, the spectrum rim, the ghost',
      children: [
        kitSpecimenTile(),
        kitSpecimenTileRim(),
        kitSpecimenTileGhost(),
      ],
    ),
    kitSection(
      'A section head on the canvas (the desktop hides it)',
      children: [kitSpecimenSection()],
    ),
    kitSection("Home's accounts as rows", children: [kitSpecimenRows()]),
    kitSection(
      'Transactions under their day',
      children: [kitSpecimenTransactionRows()],
    ),
    kitSection(
      'The row the page is about, marked',
      children: [kitSpecimenRowsMarked()],
    ),
    kitSection('Bills on the timeline', children: [kitSpecimenTimeline()]),
    kitSection('Across a month', children: [kitSpecimenMonthDivider()]),
    kitSection('Days in a list', children: [kitSpecimenDayHeads()]),
    kitSection("A purchase's details", children: [kitSpecimenKeyValues()]),
    kitSection(
      "A goal's facts, three across on the desktop",
      children: [kitSpecimenKeyValuesGrid()],
    ),
    kitSection("An account's head", children: [kitSpecimenRecordHero()]),
    kitSection(
      "A category's head, ending in its act",
      children: [kitSpecimenRecordHeroCategory()],
    ),
    kitSection(
      "A transaction's head, centred",
      children: [kitSpecimenRecordHeroCentred()],
    ),
    kitSection("A move's review", children: [kitSpecimenRecordHeroReview()]),
    kitSection('An insight', children: [kitSpecimenInsight()]),
    kitSection(
      'A suggestion, and one to take',
      children: [
        kitSpecimenSuggestion(),
        Builder(
          builder: (context) => FrostedSuggestion(
            icon: LucideIcons.sparkles,
            title: r'Suggested $450',
            // Groceries' own (orchid), beside dining out's $275 (round 11:
            // two figures under one reason).
            subtitle: 'Groceries, your September and October average',
            hue: context.frostedTheme.hues.orchid,
            trailing: FrostedButton.glass(
              'Use',
              size: FrostedButtonSize.small,
              onPressed: _open,
            ),
          ),
        ),
      ],
    ),
    kitSection('What is new', children: [kitSpecimenNoteHero()]),
    kitSection('Earlier notes', children: [kitSpecimenNotes()]),
    kitSection(
      'A nudge, and one at ease',
      children: [kitSpecimenNudge(), kitSpecimenNudgeOk()],
    ),
    kitSection('A standing notice', children: [kitSpecimenBanner()]),
    kitSection('Categories to browse', children: [kitSpecimenBrowseCards()]),
    kitSection("Home's accounts", children: [kitSpecimenAccountCards()]),
    kitSection("A bill's ticket", children: [kitSpecimenTicket()]),
  ],
);

void _open() {}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Home's month so far on the plain glass: a head with its caption, the
/// figure against the budget and a line under it; the whole opens Spending.
Widget kitSpecimenTile() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedCard(
      onPressed: _open,
      label: 'October so far',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FrostedCardHeader(
            'October so far',
            trailing: Text('day 28 of 31', style: t.textTheme.labelMedium),
          ),
          const FrostedMoney(3214.09, size: FrostedMoneySize.regular),
          const SizedBox(height: FrostedSpacing.s8),
          Text(r'of $3,500 · $285.91 left', style: t.textTheme.bodyMedium),
        ],
      ),
    );
  },
);

/// The spectrum rim along the top of the glass: a goal's standing.
Widget kitSpecimenTileRim() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedCard.rim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FrostedCardHeader('Lisbon in May'),
          const FrostedMoney(2840, size: FrostedMoneySize.small, cents: false),
          const SizedBox(height: FrostedSpacing.s8),
          Text(
            r'71% of $4,000 · by May 1, 2027',
            style: t.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  },
);

/// The ghost of a goal not yet real: faint white in a hairline ring.
Widget kitSpecimenTileGhost() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedCard.ghost(
      child: Row(
        spacing: FrostedSpacing.s12,
        children: [
          const FrostedIconMark(LucideIcons.target, quiet: true),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FrostedSpacing.s2,
              children: [
                Text(
                  'Your goal',
                  style: t.textTheme.titleMedium.c(t.colorScheme.textTertiary),
                ),
                Text('No date yet', style: t.textTheme.bodyMedium),
              ],
            ),
          ),
          FrostedMoney(
            0,
            size: FrostedMoneySize.small,
            ink: t.colorScheme.textTertiary,
          ),
        ],
      ),
    );
  },
);

/// Home's Accounts head on the canvas, the count at its end.
Widget kitSpecimenSection() =>
    const FrostedSectionHeader('Accounts', aside: '5 accounts');

/// Home's accounts in a list tile: each with its token, its kind, its
/// balance and a note under it; every row opens the account.
Widget kitSpecimenRows() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedListSection(
      rows: [
        FrostedListTile(
          leading: FrostedIconMark(LucideIcons.wallet, hue: t.hues.cyan),
          title: 'Everyday',
          meta: 'Checking ·· 4821',
          trailing: const FrostedRowEnd(
            amount: FrostedAmount(6248.30, signed: false),
          ),
          onPressed: _open,
        ),
        FrostedListTile(
          leading: FrostedIconMark(LucideIcons.piggyBank, hue: t.hues.seafoam),
          title: 'Savings',
          meta: '4.10% APY ·· 9015',
          trailing: const FrostedRowEnd(
            amount: FrostedAmount(21500, signed: false),
            note: r'+$73.42 interest',
            noteTone: FrostedTone.success,
          ),
          onPressed: _open,
        ),
        FrostedListTile(
          leading: FrostedIconMark(LucideIcons.plane, hue: t.hues.sunset),
          title: 'Lisbon fund',
          meta: 'Goal pot',
          trailing: const FrostedRowEnd(
            amount: FrostedAmount(2840, signed: false),
            note: r'71% of $4,000',
          ),
          onPressed: _open,
        ),
        FrostedListTile(
          leading: const FrostedTransactionMark.payment(),
          title: 'Harbor Card',
          meta: 'Credit ·· 4821',
          trailing: const FrostedRowEnd(
            amount: FrostedAmount(-1326.44),
            note: 'Due Nov 12',
            noteIcon: LucideIcons.clock,
          ),
          onPressed: _open,
        ),
        FrostedListTile(
          leading: FrostedIconMark(LucideIcons.chartLine, hue: t.hues.lagoon),
          title: 'Investing',
          meta: 'Brokerage',
          trailing: const FrostedRowEnd(
            amount: FrostedAmount(48920.70, signed: false),
            note: r'+$391.37 today',
            noteTone: FrostedTone.success,
          ),
          onPressed: _open,
        ),
      ],
    );
  },
);

/// Today's two purchases, both still pending, under the day's net; the
/// desktop adds the account each moved on.
Widget kitSpecimenTransactionRows() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedListSection(
      rows: [
        const FrostedDayHead('Today', net: -9.65, first: true),
        FrostedTransactionRow(
          mark: FrostedTransactionMark.purchase(
            'Blue Fern Café',
            hue: t.hues.coral,
          ),
          title: 'Blue Fern Café',
          subtitle: 'Dining out · 8:12 AM',
          amount: -6.75,
          pending: true,
          account: 'Harbor Card',
          accountIcon: LucideIcons.creditCard,
          onPressed: _open,
        ),
        FrostedTransactionRow(
          mark: FrostedTransactionMark.purchase(
            'Harbor Transit',
            hue: t.hues.mint,
          ),
          title: 'Harbor Transit',
          subtitle: 'Transport · 7:48 AM',
          amount: -2.90,
          pending: true,
          account: 'Everyday',
          accountIcon: LucideIcons.wallet,
          onPressed: _open,
        ),
        const FrostedDayHead('Fri, Oct 23', net: 3409.60),
        FrostedTransactionRow(
          mark: FrostedTransactionMark.income('Northwind Studio'),
          title: 'Northwind Studio',
          subtitle: 'Paycheck · 6:31 AM',
          amount: 3412.50,
          account: 'Everyday',
          accountIcon: LucideIcons.wallet,
          onPressed: _open,
        ),
        FrostedTransactionRow(
          mark: FrostedTransactionMark.purchase(
            'Streamline Music',
            hue: t.hues.sky,
          ),
          title: 'Streamline Music',
          subtitle: 'Subscriptions · 6:00 AM',
          amount: -2.90,
          account: 'Harbor Card',
          accountIcon: LucideIcons.creditCard,
          onPressed: _open,
        ),
      ],
    );
  },
);

/// Three moves from Everyday, the one the page is about marked among them.
Widget kitSpecimenRowsMarked() => FrostedListSection(
  rows: [
    FrostedListTile(
      leading: const FrostedTransactionMark.payment(),
      title: 'Harbor Card autopay',
      meta: 'Mon, Oct 12 · Card payment',
      trailing: const FrostedAmount(-1180.22),
      onPressed: _open,
    ),
    FrostedListTile(
      leading: const FrostedTransactionMark.move(),
      title: 'To Lisbon fund',
      meta: 'Thu, Oct 1 · Transfer',
      trailing: const FrostedAmount(-150),
      onPressed: _open,
    ),
    FrostedListTile(
      leading: const FrostedTransactionMark.move(),
      title: 'To Savings',
      meta: 'Thu, Oct 1 · Transfer',
      trailing: const FrostedAmount(-500),
      selected: true,
      onPressed: _open,
    ),
  ],
);

/// November's bills on their timeline: each dated, the rent soon, the
/// spine between the date blocks.
Widget kitSpecimenTimeline() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedCard(
      child: FrostedRowGroup(
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
            meta: 'Harbor Card ·· 7730 · In 6 days',
            trailing: const FrostedAmount(35, signed: false),
            onPressed: _open,
          ),
          FrostedListTile(
            leading: FrostedDateBlock(DateTime(2026, 11, 12)),
            title: 'Harbor Card payment',
            meta: 'Everyday ·· 4821 · In 15 days',
            trailing: const FrostedAmount(1326.44, signed: false),
            onPressed: _open,
          ),
        ],
      ),
    );
  },
);

/// Dining out's purchases running from October into September.
Widget kitSpecimenMonthDivider() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedCard(
      child: FrostedRowGroup(
        children: [
          FrostedTransactionRow(
            mark: FrostedTransactionMark.purchase(
              'Blue Fern Café',
              hue: t.hues.coral,
            ),
            title: 'Blue Fern Café',
            subtitle: 'Thu, Oct 1 · 8:05 AM',
            amount: -6.48,
            onPressed: _open,
          ),
          const FrostedMonthDivider('September 2026'),
          FrostedTransactionRow(
            mark: FrostedTransactionMark.purchase(
              'Mesa Taqueria',
              hue: t.hues.coral,
            ),
            title: 'Mesa Taqueria',
            subtitle: 'Tue, Sep 29 · 12:40 PM',
            amount: -38.40,
            onPressed: _open,
          ),
          FrostedTransactionRow(
            mark: FrostedTransactionMark.purchase(
              'Blue Fern Café',
              hue: t.hues.coral,
            ),
            title: 'Blue Fern Café',
            subtitle: 'Mon, Sep 28 · 8:10 AM',
            amount: -6.48,
            onPressed: _open,
          ),
        ],
      ),
    );
  },
);

/// Recent activity by day: each day's head with its net over its rows.
Widget kitSpecimenDayHeads() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedListSection(
      rows: [
        // Each day's net is its rows' sum (round 11: Today said -$9.65 over
        // its one -$6.75 row).
        const FrostedDayHead('Today', net: -6.75, first: true),
        FrostedTransactionRow(
          mark: FrostedTransactionMark.purchase(
            'Blue Fern Café',
            hue: t.hues.coral,
          ),
          title: 'Blue Fern Café',
          subtitle: 'Dining out · 8:12 AM',
          amount: -6.75,
          pending: true,
          onPressed: _open,
        ),
        const FrostedDayHead('Yesterday', net: -75.17),
        FrostedTransactionRow(
          mark: FrostedTransactionMark.purchase(
            'Green Basket Market',
            hue: t.hues.orchid,
          ),
          title: 'Green Basket Market',
          subtitle: 'Groceries · 6:22 PM',
          amount: -64.18,
          onPressed: _open,
        ),
        FrostedTransactionRow(
          mark: FrostedTransactionMark.purchase(
            'Streamline Music',
            hue: t.hues.sky,
          ),
          title: 'Streamline Music',
          subtitle: 'Subscriptions · 6:00 AM',
          amount: -10.99,
          onPressed: _open,
        ),
      ],
    );
  },
);

/// A pending purchase's details, its category opening the way to change it.
Widget kitSpecimenKeyValues() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedCard(
      child: FrostedDescriptionList(
        children: [
          const FrostedKeyValue(label: 'Status', value: 'Pending'),
          const FrostedKeyValue(
            label: 'Date',
            value: 'Wed, Oct 28, 2026',
            subtitle: '8:12 AM',
          ),
          const FrostedKeyValue(label: 'Card', value: 'Harbor Card ·· 4821'),
          FrostedKeyValue(
            label: 'Category',
            value: 'Dining out',
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: FrostedSpacing.s8,
              children: [
                FrostedSwatch(t.hues.coral),
                // The name wraps at large text rather than running past the
                // row's end.
                Flexible(
                  child: Text(
                    'Dining out',
                    style: t.textTheme.titleMedium.line(20.8),
                  ),
                ),
              ],
            ),
            onPressed: _open,
          ),
        ],
      ),
    );
  },
);

/// A goal's facts: six, in lines on a phone and three across on the
/// desktop, the account ones opening their accounts.
Widget kitSpecimenKeyValuesGrid() => FrostedCard(
  child: FrostedDescriptionList(
    grid: true,
    children: [
      const FrostedKeyValue(label: 'Target', value: r'$1,800'),
      const FrostedKeyValue(label: 'Date', value: 'Oct 1, 2027'),
      FrostedKeyValue(
        label: 'Held in',
        value: 'Savings ·· 9015',
        onPressed: _open,
      ),
      const FrostedKeyValue(label: 'Auto-save', value: r'$100 on the 1st'),
      FrostedKeyValue(label: 'From', value: 'Everyday', onPressed: _open),
      const FrostedKeyValue(label: 'Started', value: 'May 1, 2026'),
    ],
  ),
);

/// Everyday's head: its token, kind and mask, the balance available now.
Widget kitSpecimenRecordHero() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedRecordHero(
      mark: FrostedIconMark(LucideIcons.wallet, hue: t.hues.cyan),
      title: 'Everyday',
      subtitle: 'Checking ·· 4821',
      amount: 6248.30,
      of: 'Available now',
      hue: t.hues.cyan,
    );
  },
);

/// Dining out's head: what October spent of its budget, over by a chip,
/// and Edit budget at the head's end.
Widget kitSpecimenRecordHeroCategory() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedRecordHero(
      mark: FrostedIconMark(LucideIcons.utensils, hue: t.hues.coral),
      title: 'Dining out',
      amount: 286.40,
      of: r'of $250 budget · **115%**',
      hue: t.hues.coral,
      ofEnd: const FrostedTag(r'Over by $36.40', tone: FrostedTone.danger),
      trailing: FrostedButton.glass(
        'Edit budget',
        size: FrostedButtonSize.small,
        icon: LucideIcons.pencil,
        onPressed: _open,
      ),
    );
  },
);

/// Mesa Taqueria's lunch: the large mark, the name and where it was paid,
/// the figure, then Posted and when.
Widget kitSpecimenRecordHeroCentred() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedRecordHero.centred(
      mark: FrostedTransactionMark.purchase(
        'Mesa Taqueria',
        hue: t.hues.coral,
        size: FrostedMarkSize.large,
      ),
      title: 'Mesa Taqueria',
      subtitle: 'Dining out · Harbor Card',
      amount: -38.40,
      hue: t.hues.coral,
      chips: [
        const FrostedTag('Posted', icon: LucideIcons.check),
        Text('Tue, Sep 29 · 12:40 PM', style: t.textTheme.bodyMedium),
      ],
    );
  },
);

/// A transfer's review: from Everyday to Savings over the figure.
Widget kitSpecimenRecordHeroReview() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedRecordHero.review(
      route: FrostedRoute(
        fromName: 'Everyday',
        fromIcon: LucideIcons.wallet,
        fromHue: t.hues.cyan,
        toName: 'Savings',
        toIcon: LucideIcons.piggyBank,
        toHue: t.hues.seafoam,
      ),
      amount: 500,
      subtitle: 'From Everyday to Savings',
      hue: t.hues.seafoam,
    );
  },
);

/// Dining out over its budget, the thirteen visits to Blue Fern Café that
/// took it there; the whole opens the search.
Widget kitSpecimenInsight() => Builder(
  builder: (context) => FrostedInsight(
    icon: LucideIcons.utensils,
    kind: 'Insight · Dining out',
    title: r'$36.40 over budget',
    body: r'13 visits to Blue Fern Café came to **$84.25**.',
    hue: context.frostedTheme.hues.coral,
    visits: 13,
    onPressed: _open,
    label: 'Insight: Dining out',
  ),
);

/// The budget sheet's suggestion: Suggested $275 and why, a statement.
Widget kitSpecimenSuggestion() => Builder(
  builder: (context) => FrostedSuggestion(
    icon: LucideIcons.sparkles,
    title: r'Suggested $275',
    subtitle: 'Your September and October average',
    hue: context.frostedTheme.hues.coral,
  ),
);

/// What is new on Notifications: the rent due, in its own rimmed tile
/// washed in the rent's hue; the whole opens the bills.
Widget kitSpecimenNoteHero() => Builder(
  builder: (context) => FrostedNoteHero(
    mark: FrostedIconMark(
      LucideIcons.receipt,
      hue: context.frostedTheme.hues.periwinkle,
      size: FrostedMarkSize.large,
    ),
    when: 'New · Today · 9:00 AM',
    title: 'Rent is due in 4 days',
    body: r'$1,150.00 to Linden Court Apartments on Nov 1.',
    action: 'See your bills',
    hue: context.frostedTheme.hues.periwinkle,
    onPressed: _open,
  ),
);

/// The earlier notifications in a list tile, a hairline between each.
Widget kitSpecimenNotes() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedListSection(
      hairlines: true,
      rows: [
        FrostedNote(
          lead: FrostedTransactionMark.income('Northwind Studio'),
          title: 'Paycheck landed',
          body: r'+$3,412.50 from Northwind Studio.',
          when: 'Fri, Oct 23 · 6:31 AM',
          onPressed: _open,
        ),
        FrostedNote(
          lead: FrostedIconMark(LucideIcons.target, hue: t.hues.sunset),
          title: 'Lisbon in May is 71% saved',
          body: r'$1,160 to go by May 1.',
          when: 'Thu, Oct 22 · 10:00 AM',
          onPressed: _open,
        ),
        FrostedNote(
          lead: FrostedIconMark(LucideIcons.chartPie, hue: t.hues.coral),
          title: 'Dining out is over budget',
          body: r'You have spent $286.40 of $250.',
          when: 'Wed, Oct 21 · 12:31 PM',
          unread: true,
          onPressed: _open,
        ),
      ],
    );
  },
);

/// Lisbon in May is behind: the warm nudge, with its act.
Widget kitSpecimenNudge() => FrostedNudge(
  r'Add $110 to stay on track.',
  action: FrostedButton(
    r'Add $110',
    size: FrostedButtonSize.small,
    icon: LucideIcons.plus,
    onPressed: _open,
  ),
);

/// The bike is on track: the nudge at ease in the green of money in.
Widget kitSpecimenNudgeOk() =>
    const FrostedNudge(r'On track for next October at $100 a month.', ok: true);

/// The frozen card's notice in the cold ink.
Widget kitSpecimenBanner() => const FrostedBanner(
  icon: LucideIcons.snowflake,
  title: 'Your card is frozen',
  body:
      'New purchases and cash withdrawals are declined. Autopay, refunds '
      'and payments still go through.',
);

/// Two categories to browse from the empty search, side by side.
Widget kitSpecimenBrowseCards() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return Row(
      spacing: FrostedChromeMetrics.browseCardsGap,
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
);

/// Home's first two accounts side by side, each washed in its hue.
Widget kitSpecimenAccountCards() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    // `.accts` is a grid: both cards take the taller one's height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostedBreakpoints.gap(context),
        children: [
          Expanded(
            child: FrostedAccountCard(
              icon: LucideIcons.wallet,
              hue: t.hues.cyan,
              name: 'Everyday',
              kind: 'Checking',
              mask: '•• 4821',
              balance: 6248.30,
              onPressed: _open,
            ),
          ),
          Expanded(
            child: FrostedAccountCard(
              icon: LucideIcons.piggyBank,
              hue: t.hues.seafoam,
              name: 'Savings',
              kind: '4.10% APY',
              mask: '•• 9015',
              balance: 21500,
              note: r'+$73.42 interest',
              noteTone: FrostedTone.success,
              onPressed: _open,
            ),
          ),
        ],
      ),
    );
  },
);

/// The rent's ticket: Linden Court on its monogram, one payment from
/// Everyday, on autopay.
Widget kitSpecimenTicket() => Builder(
  builder: (context) => FrostedTicket(
    name: 'Linden Court Apartments',
    title: 'Linden Court Apartments',
    subtitle: 'One payment from Everyday',
    hue: context.frostedTheme.hues.periwinkle,
    chip: 'Autopay',
    chipIcon: LucideIcons.check,
    onPressed: _open,
  ),
);
