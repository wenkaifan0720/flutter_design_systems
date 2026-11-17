// Every example in the package's docs, compiled here (an example that stops compiling fails analysis) and run where
// it is a widget (testDocExamples, ui_core's template in doc_examples.dart). Written from lib's examples by the
// catalog's gen_doc_examples step; the names the examples assume are in doc_example_stubs.dart.
// ignore_for_file: prefer_const_constructors, unnecessary_lambdas, avoid_redundant_argument_values, unused_local_variable, unused_element
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_parts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'doc_example_stubs.dart';
import 'doc_examples.dart';

void main() {
  testDocExamples(
    self: 'test/doc_examples_test.dart',
    skip: const {'ledger_parts.dart'},
    wrap: (child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      // Motion reduced: a loader that runs until its work lands stands still, so each example settles.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: LedgerHost(brightness: Brightness.light, child: child!),
      ),
      home: Scaffold(body: child),
    ),
    examples: {
      'LedgerTheme': (context) => LedgerTheme(
        data: LedgerThemeData.light().copyWith(density: LedgerDensity.compact),
        child: page,
      ),
      'Text': (context) => Text(LedgerFormat.money(-1326.44), style: t.amount),
      'Text 2': (context) => Text(
        'The Keel Card balance of ${LedgerFormat.unbroken(LedgerFormat.money(-1326.44))} is netted out.',
      ),
      'Text 3': (context) =>
          Text('${LedgerFormat.isolated('+3.86%')} since September'),
      'LedgerInventoryGallery': (context) =>
          LedgerInventoryGallery(inventory: ledgerInventory),
      'LedgerInventoryGallery 2': (context) => const LedgerInventoryGallery(),
      'PageTransitionsTheme': (context) => const PageTransitionsTheme(
        builders: {TargetPlatform.android: LedgerPageTransitions()},
      ),
      'ThemeData': (context) => ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: ledgerPageTransitions,
        ),
      ),
      'LedgerButton': (context) => LedgerButton(
        'Export',
        onPressed: export,
        style: LedgerStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24),
          ),
        ),
      ),
      'LedgerTheme 2': (context) =>
          LedgerTheme(data: LedgerThemeData.light(), child: page),
      'LedgerThemeData.from': (context) => LedgerThemeData.from(
        paper: const Color(0xFFF4F1EA),
        ink: const Color(0xFF1B2433),
        accent: const Color(0xFF2B4C9B),
      ),
      'AnimatedLedgerTheme': (context) => AnimatedLedgerTheme(
        data: night ? LedgerThemeData.dark() : LedgerThemeData.light(),
        child: page,
      ),
      'LedgerNavItem': (context) => LedgerNavItem(
        LucideIcons.chartPie,
        'Spending',
        ValueKey('open-spending'),
      ),
      'LedgerNavItem.act': (context) => LedgerNavItem.act(
        LucideIcons.arrowRightLeft,
        'Move',
        actLabel: 'Move money',
      ),
      'LedgerNavBar': (context) => LedgerNavBar(
        items: tabs,
        selectedIndex: 0,
        onDestinationSelected: select,
      ),
      'LedgerNavigationFrame': (context) => LedgerNavigationFrame(
        destinations: tabs,
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        brand: 'Quill',
        body: pages[tab],
      ),
      'LedgerPreview': (context) => LedgerPreview(
        presentation: LedgerPresentation.pushed,
        child: const AccountPage(),
      ),
      'LedgerScreen': (context) => LedgerScreen(
        topBar: const LedgerTopBar(
          title: 'Goals',
          meta: 'Wednesday, October 28',
        ),
        body: goals,
      ),
      'LedgerScreen.form': (context) => LedgerScreen.form(
        topBar: const LedgerTopBar(title: 'New entry'),
        footer: save,
        body: form,
      ),
      'LedgerSheetHead': (context) => LedgerSheetHead(
        title: 'Category',
        close: LedgerIconButton.outlined(
          LucideIcons.x,
          semanticLabel: 'Close',
          size: LedgerIconButtonSize.small,
          onPressed: () {},
        ),
      ),
      'LedgerSheetShell': (context) => LedgerSheetShell(
        title: 'Add money',
        foot: [LedgerButton.filled('Confirm', onPressed: add)],
        children: [amount, from],
      ),
      'LedgerSideBar': (context) => LedgerSideBar(
        items: tabs,
        selectedIndex: 0,
        onDestinationSelected: select,
        brand: 'Keel',
      ),
      'LedgerSideBar 2': (context) => LedgerSideBar(
        items: tabs,
        selectedIndex: 0,
        onDestinationSelected: select,
        extended: false,
      ),
      'LedgerLoadingState': (context) =>
          LedgerLoadingState(message: 'Loading activity'),
      'LedgerErrorState': (context) => LedgerErrorState(
        title: 'Activity didn’t load',
        message: 'Check your connection and try again.',
        onRetryPressed: reload,
      ),
      'LedgerEmptyState': (context) => LedgerEmptyState(
        title: 'Nothing for',
        titleItalic: '“sushi”',
        body: 'Clear the filters to search all of it.',
        seal: const LedgerSeal(
          kicker: 'Search',
          value: 'No\nentries',
          foot: 'October',
          tone: LedgerSealTone.plain,
        ),
        actionLabel: 'Clear filters',
        actionIcon: LucideIcons.x,
        onActionPressed: clear,
      ),
      'LedgerToastCard': (context) => LedgerToastCard(
        'Moved to Groceries',
        actionLabel: 'Undo',
        onActionPressed: undo,
      ),
      'LedgerAccount': (context) => LedgerAccount(
        name: 'Maren Holt',
        initials: 'MH',
        meta: 'Since Mar 2023',
        unread: 2,
        onProfilePressed: (context) => open('/profile'),
      ),
      'LedgerAccountScope': (context) =>
          LedgerAccountScope(account: account, child: child),
      'LedgerAccountMarks': (context) => LedgerAccountMarks(account: account),
      'LedgerBack': (context) => LedgerBack(
        label: 'Activity',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      'LedgerBack.close': (context) =>
          LedgerBack.close(onPressed: () => Navigator.of(context).maybePop()),
      'LedgerTopBar': (context) => LedgerTopBar(
        title: 'Good evening,',
        titleItalic: 'Maren',
        meta: 'Wednesday, October 28 · 7:40 PM',
      ),
      'LedgerStatementSlip': (context) => LedgerStatementSlip(
        kind: 'Keel Card · Statement',
        number: '··7730',
        balance: 1326.44,
        due: 'Nov 12',
        dueNote: 'In 15 days',
        details: const [LedgerKeyValue('Autopay', 'Full balance')],
      ),
      'LedgerMemo': (context) => LedgerMemo(
        text: 'Dining out is\n',
        over: '\$36.40 over',
        textAfter: '\nbudget.',
        seal: const LedgerSeal(
          kicker: 'Dining',
          value: 'Over',
          foot: '+\$36.40',
          tone: LedgerSealTone.over,
        ),
        leading: const LedgerMonogram(
          'Blue Fern Café',
          size: LedgerMonogramSize.dense,
        ),
        note: '13 visits to Blue Fern Café\ncame to ',
        noteAmount: '\$84.25',
        noteAfter: '.',
        onTap: () {},
      ),
      'LedgerMemoSlip': (context) => LedgerMemoSlip(
        label: 'On track',
        note: 'Flights in March, the rest by May.',
        actions: [
          LedgerButton('Add money', icon: LucideIcons.plus, onPressed: () {}),
        ],
      ),
      'LedgerFrozenBanner': (context) => LedgerFrozenBanner(
        title: 'Frozen today at 9:41 AM',
        text: 'Nothing is cancelled. Unfreeze it any time.',
        effects: const [
          LedgerEffect(
            icon: LucideIcons.ban,
            title: 'Declined',
            text: 'New purchases and cash withdrawals.',
            blocking: true,
          ),
        ],
        actionLabel: 'Unfreeze card',
        onActionPressed: () {},
      ),
      'LedgerDialogLead': (context) => LedgerDialogLead(
        'Freezing stops the card, not the account.\nUnfreeze it any time.',
      ),
      'LedgerDoneHead': (context) => LedgerDoneHead(
        meta: 'Transfer sent · 9:41 AM',
        title: '\$500.00 is on its way to',
        emphasis: 'Savings',
      ),
      'LedgerSplitTicket': (context) => LedgerSplitTicket(
        start: 'Blue Fern Café · Wed, Oct 28',
        end: 'Total \$6.75',
        mine: const LedgerSplitHalf(
          name: 'Maren Holt',
          initials: 'MH',
          note: 'Your half',
          amount: 3.38,
        ),
        theirs: const LedgerSplitHalf(
          name: 'Sam Ortiz',
          initials: 'SO',
          note: 'Owes you',
          amount: 3.37,
        ),
      ),
      'LedgerSavedAfter': (context) => LedgerSavedAfter(
        value: '\$2,950 · 74%',
        ratio: .7375,
        subtitle: '\$2,840 saved + \$110',
        trailingSubtitle: 'of \$4,000',
      ),
      'LedgerBeforeRow': (context) => LedgerBeforeRow(
        title: 'Saved before Jun 1',
        value: const LedgerAmount(
          790,
          tone: LedgerTone.moneyIn,
          showSign: true,
        ),
        subtitle: '3 contributions',
      ),
      'LedgerDisclosure': (context) => LedgerDisclosure(
        title: 'Fees',
        note: r'$2.40',
        child: Text('Card fee'),
      ),
      'LedgerTabs': (context) => LedgerTabs(
        tabs: const ['Overview', 'Entries', 'Notes'],
        counts: const [null, 12, 3],
        selectedIndex: tab,
        onSelected: (i) => setState(() => tab = i),
      ),
      'LedgerSplitButton': (context) => LedgerSplitButton(
        'Export',
        onPressed: () {},
        actions: [
          LedgerSplitAction(label: 'As CSV', onPressed: () {}),
          LedgerSplitAction(label: 'As PDF', onPressed: () {}),
        ],
      ),
      'LedgerKbd': (context) =>
          LedgerKbd(const ['⌘', 'K'], semanticLabel: 'Command K'),
      'LedgerPagination': (context) =>
          LedgerPagination(page: 2, pageCount: 9, onChanged: (p) {}),
      'LedgerTooltip': (context) => LedgerTooltip(
        message: 'Export as CSV',
        child: LedgerIconButton(
          LucideIcons.download,
          semanticLabel: 'Export',
          onPressed: () {},
        ),
      ),
      'LedgerReorderableList': (context) => LedgerReorderableList<String>(
        items: names,
        labelOf: (n) => n,
        onReorder: (from, to) =>
            setState(() => names.insert(to, names.removeAt(from))),
        itemBuilder: (context, n) => Text(n),
      ),
      'LedgerCardFace': (context) => LedgerCardFace(
        brand: 'Keel',
        kind: 'Credit',
        number: const ['4242', '4242', '4242', '7730'],
        holder: 'MAREN HOLT',
        account: 'Keel Card',
      ),
      'LedgerCardDetails': (context) => LedgerCardDetails(
        number: const ['4242', '4242', '4242', '7730'],
        expiry: '09/29',
        cvc: '317',
        name: 'Maren Holt',
      ),
      'LedgerDateRangePicker': (context) => LedgerDateRangePicker(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        value: LedgerDateRange(DateTime(2026, 10, 12), DateTime(2026, 10, 19)),
        onChanged: (r) {},
      ),
      'LedgerProgressBar': (context) =>
          LedgerProgressBar(value: .6, label: 'Uploading the statement'),
      'LedgerProgressRing': (context) => LedgerProgressRing(
        value: .4,
        label: 'Saving the budget',
        showValue: true,
      ),
      'LedgerSkeleton': (context) => LedgerSkeleton(lines: 2, avatar: true),
      'LedgerGlyph': (context) => LedgerGlyph(LucideIcons.wallet),
      'LedgerGlyph 2': (context) => LedgerGlyph(
        LucideIcons.arrowRightLeft,
        tone: LedgerGlyphTone.move,
        size: LedgerGlyphSize.dense,
      ),
      'LedgerMonogram': (context) => LedgerMonogram('Blue Fern Café'),
      'LedgerMonogram 2': (context) =>
          LedgerMonogram('Northwind Studio', tone: LedgerMonogramTone.moneyIn),
      'LedgerMonogram 3': (context) => LedgerMonogram(
        'Maren Holt',
        tone: LedgerMonogramTone.inked,
        size: LedgerMonogramSize.member,
      ),
      'LedgerDashedFrame': (context) => LedgerDashedFrame(
        padding: const EdgeInsets.all(18),
        child: Text('New goal'),
      ),
      'LedgerDateTab': (context) => LedgerDateTab(DateTime(2026, 11, 1)),
      'LedgerPill': (context) => LedgerPill('+3.86%'),
      'LedgerPill 2': (context) => LedgerPill(
        'Behind',
        tone: LedgerPillTone.plain,
        size: LedgerPillSize.small,
      ),
      'LedgerTag': (context) => LedgerTag('Pending'),
      'LedgerGoalLine': (context) => LedgerGoalLine(
        icon: LucideIcons.plane,
        name: 'Lisbon in May',
        saved: 2840,
        target: 4000,
        by: 'by May 2027',
        onTap: () {},
      ),
      'LedgerGoalCard': (context) => LedgerGoalCard(
        icon: LucideIcons.plane,
        name: 'Lisbon in May',
        saved: 2840,
        target: 4000,
        by: 'by May 2027',
        status: 'Behind',
        behindSchedule: true,
        note: 'Add \$110 to stay on track.',
        onTap: () {},
      ),
      'LedgerCategoryLine': (context) => LedgerCategoryLine(
        name: 'Dining out',
        spent: 286.40,
        budget: 250,
        pace: 28 / 31,
        subtitle: 'Budget \$250',
        trailingSubtitle: 'Over by \$36.40',
        onTap: () {},
      ),
      'LedgerAvatarStack': (context) => LedgerAvatarStack(
        names: const ['Maren Holt', 'Jonas Ahn', 'Priya Rao', 'Lee Wong'],
        total: 9,
      ),
      'LedgerRangeSlider': (context) => LedgerRangeSlider(
        label: 'Amount',
        values: const LedgerRangeValues(20, 180),
        max: 500,
        format: (v) => '\$${v.round()}',
        onChanged: (v) {},
      ),
      'LedgerMenuItem': (context) => LedgerMenuItem(
        'October 2026',
        amount: 2486.12,
        selected: true,
        onTap: () {},
      ),
      'LedgerMenuItem 2': (context) => LedgerMenuItem(
        'October 2026',
        key: const ValueKey('keep-month'),
        selected: true,
        onTap: () {},
      ),
      'LedgerMenu': (context) => LedgerMenu(
        head: 'Spent by month',
        semanticLabel: 'Months',
        items: [
          LedgerMenuItem(
            'October 2026',
            amount: 2486.12,
            selected: true,
            onTap: () {},
          ),
        ],
      ),
      'LedgerSuggestion': (context) => LedgerSuggestion(
        amount: 275,
        text: 'Your September and October average, rounded to \$5.',
        onTap: () {},
      ),
      'LedgerCategoryTile': (context) => LedgerCategoryTile(
        icon: LucideIcons.utensils,
        name: 'Dining out',
        spent: 286.40,
        overBudget: true,
        onTap: () {},
      ),
      'LedgerCategoryTiles': (context) => LedgerCategoryTiles(
        tiles: [
          for (final c in categories)
            LedgerCategoryTile(
              icon: c.icon,
              name: c.name,
              spent: c.spent,
              onTap: () {},
            ),
        ],
      ),
      'LedgerOption': (context) => LedgerOption(
        icon: LucideIcons.utensils,
        label: 'Dining out',
        selected: true,
        onTap: () {},
      ),
      'LedgerCategoryMini': (context) => LedgerCategoryMini(
        name: 'Dining out',
        spent: 286.40,
        budget: 250,
        pace: 28 / 31,
        subtitle: 'Budget \$250',
        trailingSubtitle: 'Over by \$36.40',
        onTap: () {},
      ),
      'LedgerIconChoice': (context) =>
          LedgerIconChoice(LucideIcons.plane, 'plane'),
      'LedgerIconPicker': (context) => LedgerIconPicker(
        choices: const [
          LedgerIconChoice(LucideIcons.plane, 'plane'),
          LedgerIconChoice(LucideIcons.shield, 'shield'),
        ],
        selectedIndex: 0,
        onSelected: (i) {},
      ),
      'LedgerWay': (context) => LedgerWay(
        icon: LucideIcons.arrowRightLeft,
        title: 'Transfer',
        text: 'Between your accounts',
        onTap: () {},
      ),
      'LedgerWays': (context) => LedgerWays(
        ways: const [
          LedgerWay(
            icon: LucideIcons.arrowRightLeft,
            title: 'Transfer',
            text: 'Between your accounts',
          ),
        ],
      ),
      'LedgerAllocationRow': (context) => LedgerAllocationRow(
        tone: LedgerStackTone.ink,
        name: 'Stocks',
        amount: 39432.60,
        share: '80.6%',
      ),
      'LedgerHoldingRow': (context) => LedgerHoldingRow(
        name: 'Keel Total Market',
        symbol: 'KTMX',
        kind: 'Stocks',
        shares: '182.4 shares',
        value: 26410.20,
        today: 262.10,
      ),
      'LedgerHoldings': (context) => LedgerHoldings(
        rows: const [
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
      'LedgerButtonRow': (context) => LedgerButtonRow(
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
      ),
      'LedgerMemberCard': (context) => LedgerMemberCard(
        kind: 'Keel · Account holder',
        since: 'Since Mar 2023',
        name: 'Maren Holt',
        initials: 'MH',
        subtitle: 'Member since March 2023',
        seal: const LedgerSeal(
          kicker: 'Keel',
          value: 'Member',
          foot: 'Since 2023',
        ),
        details: const [LedgerKeyValue('Email', 'maren.holt@example.com')],
      ),
      'LedgerComposer': (context) => LedgerComposer(
        controller: reply,
        hint: 'Write a reply',
        onAttachPressed: pick,
        onSubmitted: () => send(reply.text),
      ),
      'LedgerBrandMark': (context) => LedgerBrandMark(),
      'LedgerWordmark': (context) => LedgerWordmark('Keel'),
      'LedgerWordmark 2': (context) =>
          LedgerWordmark('Keel', size: LedgerWordmarkSize.large),
      'LedgerChip': (context) => LedgerChip(
        'Groceries',
        count: 12,
        selected: filter == 'Groceries',
        onTap: () => pick('Groceries'),
      ),
      'LedgerChipRow': (context) => LedgerChipRow(
        label: 'Categories',
        children: [
          for (final c in categories)
            LedgerChip(
              c.name,
              count: c.count,
              selected: picked.contains(c),
              onTap: () => toggle(c),
            ),
        ],
      ),
      'LedgerSideSheet': (context) => LedgerSideSheet(
        title: 'Filters',
        onClose: () {},
        child: Text('Money in'),
      ),
      'LedgerTextArea': (context) => LedgerTextArea(
        label: 'Memo',
        hint: 'What it was for',
        maxLength: 280,
      ),
      'LedgerMultiSelect': (context) => LedgerMultiSelect<String>(
        label: 'Split with',
        values: const ['Maren'],
        options: const ['Maren', 'Theo', 'Ana'],
        onChanged: (v) {},
      ),
      'LedgerCheckbox': (context) => LedgerCheckbox(
        value: true,
        label: 'Email me a receipt',
        onChanged: (v) {},
      ),
      'LedgerRadio': (context) => LedgerRadio<String>(
        value: 'monthly',
        groupValue: plan,
        label: 'Monthly',
        onChanged: (v) {},
      ),
      'LedgerGridLine': (context) => LedgerGridLine(2000, '\$2k'),
      'LedgerChartMark': (context) => LedgerChartMark(23, 'Pay +\$3,412.50'),
      'LedgerChartNote': (context) => LedgerChartNote(
        0,
        '**Rent**\n\$1,150.00 · Nov 1',
        lift: 40,
        deskLift: 46,
        deskText: '**Rent** \$1,150.00 · Nov 1',
      ),
      'LedgerNetWorthChart': (context) => LedgerNetWorthChart(
        values: const [61.4, 62.9, 78.18],
        low: 56,
        high: 82,
        grid: const [LedgerGridLine(80, '80k')],
        endLabel: 'Oct 78.18k',
      ),
      'LedgerCumulativeChart': (context) => LedgerCumulativeChart(
        cumulative: spent,
        budget: 2700,
        days: 31,
        high: 3000,
        grid: grid,
        budgetLabel: 'Budget \$2,700',
      ),
      'LedgerDayBars': (context) =>
          LedgerDayBars(values: daily, days: 31, cap: 190, grid: grid),
      'LedgerVisitRuler': (context) => LedgerVisitRuler(
        visits: const [(28, 6.75), (23, 6.5)],
        days: 31,
        today: 28,
        current: 28,
        startLabel: 'Oct 1',
        endLabel: 'Oct 31',
      ),
      'LedgerMonthLine': (context) => LedgerMonthLine(
        values: balance,
        start: 2479.82,
        days: 31,
        low: 0,
        high: 7400,
        grid: grid,
        endLabel: '\$6,248.30',
      ),
      'LedgerChartBracket': (context) =>
          LedgerChartBracket(2, 11, '2026 to date **\$667.75**'),
      'LedgerMonthBars': (context) => LedgerMonthBars(
        values: interest,
        bracket: const LedgerChartBracket(2, 11, '2026 to date **\$667.75**'),
        marks: const [LedgerChartMark(11, '+\$73.42')],
      ),
      'LedgerStepTotal': (context) => LedgerStepTotal(
        steps: const [(1, 1150), (3, 35)],
        days: 30,
        high: 3000,
        grid: grid,
        month: 'Nov',
      ),
      'LedgerGoalChart': (context) => LedgerGoalChart(
        history: saved,
        months: 19,
        target: 4000,
        low: 0,
        high: 4400,
        grid: grid,
        targetLabel: 'Target \$4,000',
      ),
      'LedgerSlider': (context) => LedgerSlider(
        label: 'Monthly budget',
        value: budget,
        min: 100,
        max: 2000,
        divisions: 19,
        format: (v) => '\$${v.round()}',
        onChanged: (v) => setState(() => budget = v),
      ),
      'LedgerActionSheet': (context) => LedgerActionSheet<String>(
        acts: const [LedgerSheetAct('Download', value: 'download')],
        onSelected: (v) {},
      ),
      'LedgerActionBar': (context) => LedgerActionBar(
        summary: '\$1,240.00',
        detail: 'Due Nov 1',
        label: 'Pay now',
        onTap: pay,
      ),
      'LedgerSeal': (context) => LedgerSeal(
        kicker: 'Search',
        value: 'No\nentries',
        foot: 'October',
        tone: LedgerSealTone.plain,
      ),
      'LedgerCarousel': (context) => LedgerCarousel(
        semanticLabel: 'Highlights',
        itemCount: 3,
        itemBuilder: (context, i) => Text('Slide $i'),
      ),
      'LedgerPullToRefresh': (context) => LedgerPullToRefresh(
        onRefresh: () async => fetch(),
        child: ListView(children: rows),
      ),
      'LedgerCombobox': (context) => LedgerCombobox<String>(
        label: 'Payee',
        options: const ['Blue Fern Café', 'Corner Market'],
        onSelected: (v) {},
      ),
      'LedgerToggleGroup': (context) => LedgerToggleGroup<String>(
        label: 'Show',
        options: const ['day', 'week', 'month'],
        labelOf: (v) => v,
        selected: const {'week'},
        onChanged: (next) {},
      ),
      'LedgerNoteRow': (context) => LedgerNoteRow(
        icon: LucideIcons.receipt,
        title: 'Rent is due in 4 days',
        body: '\$1,150.00 to Linden Court Apartments on Nov 1.',
        when: '9:00 AM',
        unread: true,
        onTap: () {},
      ),
      'LedgerEffect': (context) => LedgerEffect(
        icon: LucideIcons.ban,
        title: 'Declined',
        text: 'New purchases and cash withdrawals.',
        blocking: true,
      ),
      'LedgerEffects': (context) => LedgerEffects(
        children: [
          LedgerEffect(
            icon: LucideIcons.ban,
            title: 'Declined',
            text: 'New purchases and cash withdrawals.',
            blocking: true,
          ),
          LedgerEffect(
            icon: LucideIcons.check,
            title: 'Still goes through',
            text: 'Autopay on Nov 12, refunds and payments.',
          ),
        ],
      ),
      'LedgerPieChart': (context) => LedgerPieChart(
        label: 'October by category',
        shares: const [
          LedgerShare('Rent', 1150),
          LedgerShare('Groceries', 486),
        ],
      ),
      'LedgerSparkline': (context) => LedgerSparkline(
        label: 'Balance, 30 days',
        values: const [4.2, 4.6, 4.1, 5.0, 6.2],
      ),
      'LedgerPopover': (context) => LedgerPopover(
        semanticLabel: 'How this is worked out',
        title: 'Safe to spend',
        anchor: (context, a) => LedgerButton.text('How?', onPressed: a.toggle),
        child: Text('Your balance less bills due before payday.'),
      ),
      'LedgerInputGroup': (context) => LedgerInputGroup(
        label: 'Shop address',
        before: 'https://',
        after: '.ledger.app',
        hint: 'your-shop',
      ),
      'LedgerRegister': (context) => LedgerRegister(
        heads: const ['Time', 'Merchant', 'Category', 'Account', 'Amount'],
        children: [
          for (final d in days)
            LedgerDayGroup(d.label, net: d.net, rows: d.rows),
        ],
      ),
      'LedgerDayGroup': (context) => LedgerDayGroup(
        'Today',
        note: 'Wed, Oct 28',
        net: -9.65,
        rows: [
          LedgerTransactionRow(
            title: 'Blue Fern Café',
            category: 'Dining out',
            when: '8:12 AM',
            account: 'Checking',
            amount: -9.65,
          ),
        ],
      ),
      'LedgerTransactionRow': (context) => LedgerTransactionRow(
        title: 'Blue Fern Café',
        category: 'Dining out',
        when: '8:12 AM',
        account: 'Keel Card',
        amount: -6.75,
        pending: true,
        onTap: () {},
      ),
      'LedgerBillList': (context) => LedgerBillList(
        heads: const ['Due', 'Payee', 'Account', 'Status', 'Amount'],
        children: [
          LedgerBillRow(
            due: DateTime(2026, 11, 1),
            name: 'Rent',
            account: 'Checking',
            status: 'In 4 days',
            amount: 1850,
          ),
        ],
      ),
      'LedgerBillRow': (context) => LedgerBillRow(
        due: DateTime(2026, 11, 1),
        name: 'Rent',
        account: 'Everyday ··4821',
        status: 'In 4 days',
        amount: 1150,
        onTap: () {},
      ),
      'LedgerSlip': (context) => LedgerSlip(child: memo),
      'LedgerSlip 2': (context) => LedgerSlip(
        child: Column(
          children: [
            const LedgerSlipBand(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const LedgerSlipHead('Keel · New goal', 'Savings'),
                  ...fields,
                ],
              ),
            ),
          ],
        ),
      ),
      'LedgerStub': (context) => LedgerStub(),
      'LedgerSlipHead': (context) =>
          LedgerSlipHead('Keel · New goal', 'Savings'),
      'LedgerReceipt': (context) => LedgerReceipt(
        kind: 'Keel · Transaction',
        number: 'No. T280812BLUE',
        leading: const LedgerMonogram(
          'Blue Fern Café',
          size: LedgerMonogramSize.record,
        ),
        name: 'Blue Fern Café',
        subtitle: 'Dining out · Keel Card ··7730',
        figure: const LedgerFigure(-6.75),
        seal: const LedgerSeal(
          kicker: 'Keel Card',
          value: 'Pending',
          foot: 'Oct 28',
          tone: LedgerSealTone.plain,
        ),
        details: const [LedgerKeyValue('Status', 'Pending')],
      ),
      'LedgerCheque': (context) => LedgerCheque(
        kind: 'Keel · Transfer',
        date: 'Wed, Oct 28, 2026',
        micr: '··0119 ··4821 ··9015',
        lines: [
          LedgerPickLine(
            label: 'From',
            icon: LucideIcons.wallet,
            name: 'Checking',
            mask: '··4821',
          ),
          LedgerChequeAmount(
            label: 'Amount',
            words: 'Two hundred and 00/100',
            unit: 'dollars',
            amount: 200,
          ),
        ],
      ),
      'LedgerCheque 2': (context) => LedgerCheque(
        kind: 'Keel · Transfer',
        date: 'Wed, Oct 28, 2026',
        micr: '··0119 ··4821 ··9015',
        lines: lines,
        stamp: const LedgerSeal(
          kicker: 'Keel · Transfer',
          value: 'Sent',
          foot: 'Oct 28',
        ),
      ),
      'LedgerSwipeAction': (context) => LedgerSwipeAction(
        'Delete',
        icon: LucideIcons.trash2,
        tone: LedgerSwipeTone.destructive,
        onPressed: delete,
      ),
      'LedgerSwipeActions': (context) => LedgerSwipeActions(
        trailing: [
          LedgerSwipeAction(
            'Delete',
            icon: LucideIcons.trash2,
            tone: LedgerSwipeTone.destructive,
            onPressed: delete,
          ),
        ],
        child: row,
      ),
      'LedgerButton.filled': (context) => LedgerButton.filled(
        'Move money',
        icon: LucideIcons.arrowRightLeft,
        onPressed: () {},
      ),
      'LedgerButton 2': (context) => LedgerButton(
        'Add money',
        size: LedgerButtonSize.medium,
        icon: LucideIcons.plus,
        onPressed: () {},
      ),
      'LedgerButton.ink': (context) =>
          LedgerButton.ink('Freeze card', onPressed: () {}),
      'LedgerButton.text': (context) =>
          LedgerButton.text('View all', onPressed: () {}),
      'LedgerDatePicker': (context) => LedgerDatePicker(
        label: 'Due',
        value: due,
        mode: LedgerDatePickerMode.dateAndTime,
        onChanged: setDue,
      ),
      'LedgerScrollArea': (context) => LedgerScrollArea(
        controller: scroll,
        semanticLabel: 'Terms',
        child: SingleChildScrollView(
          controller: scroll,
          child: const Text('Terms'),
        ),
      ),
      'LedgerStepProgress': (context) => LedgerStepProgress(
        steps: const ['Payee', 'Amount', 'Review'],
        current: 1,
      ),
      'LedgerPageDots': (context) =>
          LedgerPageDots(count: 5, index: 1, onChanged: (i) {}),
      'LedgerFigure': (context) =>
          LedgerFigure(78182.56, size: LedgerFigureSize.hero),
      'LedgerFigure 2': (context) => LedgerFigure(
        3412.50,
        tone: LedgerFigureTone.moneyIn,
        showSign: true,
        size: LedgerFigureSize.receipt,
      ),
      'LedgerAmount': (context) => LedgerAmount(-84.25),
      'LedgerAmount 2': (context) =>
          LedgerAmount(3412.50, tone: LedgerTone.moneyIn, showSign: true),
      'LedgerStatementTotal': (context) =>
          LedgerStatementTotal(title: 'Net worth', amount: 78182.56),
      'LedgerLeaderLine': (context) => LedgerLeaderLine(
        start: Text('Checking', style: t.rowTitle),
        end: LedgerAmount(6248.30),
      ),
      'LedgerDivider': (context) => LedgerDivider(label: 'Earlier'),
      'LedgerFileUpload': (context) => LedgerFileUpload(
        label: 'Receipts',
        files: const [LedgerFile('Blue Fern.jpg', bytes: 182000)],
        onPick: () {},
        onRemove: (f) {},
      ),
      'LedgerGauge': (context) => LedgerGauge(
        ratio: 2486.12 / 2700,
        pace: 28 / 31,
        tick: false,
        paceLabel: 'Pace · day 28',
        startLabel: '\$0',
        endLabel: '\$2,700',
      ),
      'LedgerStackPart': (context) =>
          LedgerStackPart(39432.60, LedgerStackTone.ink),
      'LedgerStackBar': (context) => LedgerStackBar(
        parts: const [
          LedgerStackPart(80.6, LedgerStackTone.ink),
          LedgerStackPart(15, LedgerStackTone.green),
          LedgerStackPart(4.4, LedgerStackTone.pale),
        ],
      ),
      'LedgerBudgetRule': (context) =>
          LedgerBudgetRule(spent: 286.40, budget: 250, suggested: 275),
      'LedgerKeyEntry': (context) =>
          LedgerKeyEntry(LedgerKeySwatch.pace, 'Budget pace'),
      'LedgerChartKey': (context) => LedgerChartKey(
        entries: const [
          LedgerKeyEntry(LedgerKeySwatch.line, 'Spent, cumulative'),
          LedgerKeyEntry(LedgerKeySwatch.pace, 'Budget pace'),
        ],
      ),
      'LedgerCodeField': (context) => LedgerCodeField(
        label: 'Code from your bank',
        length: 6,
        onCompleted: (code) {},
      ),
      'LedgerAvatar': (context) => LedgerAvatar(
        initials: 'MH',
        label: 'Profile and settings',
        onTap: () {},
      ),
      'LedgerPasswordField': (context) => LedgerPasswordField(
        label: 'Password',
        helper: 'At least 12 characters',
        controller: password,
      ),
      'LedgerCommandPalette': (context) => LedgerCommandPalette(
        commands: const [
          LedgerCommand(label: 'New entry', group: 'Entries', shortcut: 'N'),
        ],
      ),
      'LedgerTextField': (context) => LedgerTextField(
        label: 'Name',
        hint: 'As it is on the account',
        controller: name,
      ),
      'LedgerTextField 2': (context) => LedgerTextField(
        label: 'Amount',
        prefix: r'$',
        hint: '0.00',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      'LedgerTextField 3': (context) => LedgerTextField(
        label: 'Email',
        error: 'Enter an email address',
        onChanged: (v) {},
      ),
      'LedgerCounter': (context) =>
          LedgerCounter(streak, format: (v) => '\$v days'),
      'LedgerSelect': (context) => LedgerSelect<String>(
        label: 'Currency',
        value: 'USD',
        items: const [
          LedgerSelectItem(value: 'USD', label: 'US dollar'),
          LedgerSelectItem(value: 'EUR', label: 'Euro'),
        ],
        onChanged: (v) {},
      ),
      'LedgerBreadcrumb': (context) => LedgerBreadcrumb([
        LedgerCrumb('Accounts', onTap: () {}),
        LedgerCrumb('Everyday', onTap: () {}),
        LedgerCrumb('October'),
      ]),
      'LedgerIconButton': (context) => LedgerIconButton(
        LucideIcons.search,
        semanticLabel: 'Search',
        onPressed: () {},
      ),
      'LedgerIconButton.outlined': (context) => LedgerIconButton.outlined(
        LucideIcons.chevronLeft,
        semanticLabel: 'Back to Home',
        size: LedgerIconButtonSize.small,
        onPressed: () {},
      ),
      'SizedBox': (context) => SizedBox(
        height: LedgerIconButton.sideOf(t, LedgerIconButtonSize.medium),
        child: row,
      ),
      'LedgerBell': (context) => LedgerBell(unread: 1, onPressed: () {}),
      'LedgerBell.outlined': (context) =>
          LedgerBell.outlined(unread: 1, onPressed: () {}),
      'LedgerTimeline': (context) => LedgerTimeline(
        entries: const [
          LedgerTimelineEntry(when: 'Oct 26', title: 'Sent'),
          LedgerTimelineEntry(
            when: 'Oct 28',
            title: 'Cleared',
            state: LedgerTimelineState.current,
          ),
        ],
      ),
      'LedgerCheck': (context) => LedgerCheck(
        value: done,
        label: 'Pay rent',
        onChanged: (v) => setState(() => done = v),
      ),
      'LedgerHead': (context) => LedgerHead('Accounts', note: 'Balance'),
      'LedgerHead 2': (context) => LedgerHead(
        'Upcoming · 15 days',
        note: 'All bills',
        onTap: () => open('/bills'),
      ),
      'LedgerHead.hero': (context) =>
          LedgerHead.hero('Net worth', footnote: '1', trailing: range),
      'LedgerMoreLink': (context) => LedgerMoreLink(
        'See all 13 visits',
        onTap: () => open('/activity/search'),
      ),
      'LedgerSection': (context) => LedgerSection(
        head: const LedgerHead('Goals', note: '3 active'),
        child: goals,
      ),
      'LedgerRows': (context) => LedgerRows(
        children: [
          for (final a in accounts)
            LedgerRow(title: a.name, value: LedgerAmount(a.balance)),
        ],
      ),
      'LedgerRow': (context) => LedgerRow(
        leading: const LedgerGlyph(LucideIcons.wallet),
        title: 'Everyday',
        value: const LedgerAmount(6248.30),
        subtitle: 'Checking ··4821',
        subtitleMonospace: true,
      ),
      'LedgerKeyValue': (context) => LedgerKeyValue('Status', 'Pending'),
      'LedgerKeyValue 2': (context) =>
          LedgerKeyValue('Account', '··4821', monospace: true),
      'LedgerFact.money': (context) =>
          LedgerFact.money('Left', 213.88, note: '3 days to go'),
      'LedgerFact': (context) =>
          LedgerFact('Pace', '90%', note: 'Day 28 of 31; 92% spent'),
      'LedgerFacts': (context) => LedgerFacts(
        facts: [
          LedgerFact.money('Left', 213.88, note: '3 days to go'),
          LedgerFact('Pace', '90%', note: 'Day 28 of 31'),
        ],
      ),
      'LedgerNote': (context) => LedgerNote('1', 'Sum of five accounts.'),
      'LedgerNotes': (context) =>
          LedgerNotes(notes: [LedgerNote('1', 'Sum of five accounts.')]),
      'LedgerRecordHead': (context) => LedgerRecordHead(
        leading: const LedgerGlyph(
          LucideIcons.wallet,
          size: LedgerGlyphSize.record,
        ),
        name: 'Everyday',
        subtitle: 'Checking ··4821',
      ),
      'LedgerMonthRule': (context) =>
          LedgerMonthRule('September 2026', note: 'Last month'),
      'LedgerFlag': (context) =>
          LedgerFlag('Dining out is **over by \$36.40**', onTap: () {}),
      'LedgerQuickAction': (context) => LedgerQuickAction(
        LucideIcons.arrowRightLeft,
        'Transfer',
        onTap: () {},
        key: const ValueKey('home-transfer'),
      ),
      'LedgerQuickActions': (context) => LedgerQuickActions(
        actions: [
          LedgerQuickAction(
            LucideIcons.arrowRightLeft,
            'Transfer',
            onTap: () {},
          ),
        ],
      ),
      'LedgerDelta': (context) => LedgerDelta(
        rise: '\$2,904.18',
        words: ['this month'],
        pill: LedgerPill('+3.86%'),
      ),
      'LedgerSearchEntry': (context) => LedgerSearchEntry(
        hint: 'Search entries',
        onTap: () => open('/search'),
        onFilterPressed: openFilters,
        filterCount: 2,
      ),
      'LedgerWeekStrip': (context) => LedgerWeekStrip(
        days: const [
          LedgerDayMark.kept,
          LedgerDayMark.kept,
          LedgerDayMark.missed,
          LedgerDayMark.today,
          LedgerDayMark.upcoming,
          LedgerDayMark.upcoming,
          LedgerDayMark.upcoming,
        ],
        label: 'Morning pages this week',
      ),
      'LedgerGuilloche': (context) => LedgerGuilloche(size: 320),
      'LedgerGuillocheBand': (context) => LedgerGuillocheBand(),
      'LedgerCardChip': (context) =>
          LedgerCardChip(width: 42, height: 32, color: Color(0xD1EFE9DD)),
      'LedgerPerforation': (context) => LedgerPerforation(),
      'LedgerWatermark': (context) => LedgerWatermark(),
      'LedgerBanner': (context) => LedgerBanner(
        title: 'Your October statement is ready',
        tone: LedgerBannerTone.note,
        actionLabel: 'Open',
        onAction: () {},
      ),
      'LedgerSegmentedControl': (context) => LedgerSegmentedControl(
        options: const ['1M', '3M', '1Y', 'All'],
        value: '1Y',
        onChanged: (r) {},
      ),
      'LedgerSegmentedControl 2': (context) =>
          LedgerSegmentedControl<({String short, int months})>(
            options: ranges,
            value: ranges.last,
            labelOf: (r) => r.short,
            onChanged: (r) {},
          ),
      'LedgerFilters': (context) => LedgerFilters(
        label: 'Direction',
        options: const ['All', 'Money in', 'Money out'],
        value: 'All',
        onChanged: (f) {},
      ),
      'LedgerFilters 2': (context) =>
          LedgerFilters<({String words, bool? incoming})>(
            label: 'Direction',
            options: directions,
            value: directions.first,
            labelOf: (d) => d.words,
            onChanged: (d) {},
          ),
      'LedgerSwitch': (context) =>
          LedgerSwitch(value: true, semanticLabel: 'Bills', onChanged: (on) {}),
      'LedgerToggleRow': (context) => LedgerToggleRow(
        icon: LucideIcons.receipt,
        title: 'Bills',
        subtitle: 'A reminder before each bill is due',
        value: true,
        onChanged: (on) {},
      ),
      'LedgerSettingRow': (context) => LedgerSettingRow(
        icon: LucideIcons.gauge,
        title: 'Monthly limit',
        value: '\$2,000',
        onTap: () {},
      ),
      'LedgerSettingRow 2': (context) => LedgerSettingRow(
        icon: LucideIcons.circleDollarSign,
        title: 'Currency',
        value: 'USD',
        subtitle: 'US dollar',
      ),
      'LedgerSearchField': (context) => LedgerSearchField(
        hint: 'Search merchants and categories',
        onTap: () => open('/activity/search'),
      ),
      'LedgerField': (context) =>
          LedgerField(label: 'Note', controller: note, hint: 'What it is for'),
      'LedgerField 2': (context) => LedgerField(
        label: 'When',
        child: LedgerSegmentedControl(
          options: const ['Today', 'Later'],
          value: when,
          onChanged: pick,
        ),
      ),
      'LedgerField 3': (context) =>
          LedgerField(label: 'Note', value: 'November top-up'),
      'LedgerPickLine': (context) => LedgerPickLine(
        label: 'From',
        icon: LucideIcons.wallet,
        name: 'Everyday',
        mask: '··4821',
        balance: 6248.30,
        note: 'Available',
        onTap: () {},
      ),
      'LedgerPickLine 2': (context) => LedgerPickLine(
        label: 'From',
        icon: LucideIcons.wallet,
        name: 'Everyday',
        mask: '··4821',
        balance: 6248.30,
        note: 'Available',
        showChevron: true,
      ),
      'LedgerChequeAmount': (context) => LedgerChequeAmount(
        label: 'Amount',
        words: 'Five hundred and 00/100',
        unit: 'dollars',
        amount: 500,
      ),
      'LedgerChequeAmount 2': (context) => LedgerChequeAmount(
        label: 'Amount',
        words: 'Five hundred and 00/100',
        unit: 'dollars',
        amount: 500,
        typed: true,
      ),
      'LedgerStepper': (context) =>
          LedgerStepper(value: 250, label: 'Monthly budget', onChanged: (v) {}),
      'LedgerStepper 2': (context) => LedgerStepper(
        value: 250,
        label: 'Monthly budget',
        lowerLabel: 'Lower the budget',
        raiseLabel: 'Raise the budget',
        onChanged: (v) {},
      ),
      'LedgerStepper 3': (context) => LedgerStepper(
        value: 110,
        label: 'Amount to add',
        step: 1,
        showRings: false,
      ),
      'LedgerBadge': (context) => LedgerBadge(
        count: 3,
        child: LedgerIconButton(
          LucideIcons.inbox,
          semanticLabel: 'Inbox',
          onPressed: () {},
        ),
      ),
      'LedgerDataTable': (context) =>
          LedgerDataTable<({String title, String amount})>(
            controller: table,
            cellText: (e, column) => column.id == 'amount' ? e.amount : e.title,
          ),
      'LedgerMedia': (context) => LedgerMedia(
        image: const AssetImage('assets/photos/receipt.jpg'),
        caption: 'Corner Market, Oct 27',
        semanticLabel: 'The receipt from Corner Market',
      ),
    },
  );
}

/// The examples that are an app, a route, a call or a statement: compiled, never run.
Future<void> _compiledOnly(BuildContext context) async {
  final loader = FontLoader(ledgerFontFamily('PlexMono'))..addFont(bytes);
  await loader.load();
  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await ledgerLoadFonts();
    runApp(const MyApp());
  }

  final look = LedgerStyleOf([style, t.components.chip], states);
  final paper = look.fill ?? t.surface;
  final theme = LedgerThemeData.light().copyWith(
    components: const LedgerComponentThemes(
      chip: LedgerStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
    ),
  );
  show(
    MaterialApp(
      builder: (context, child) => LedgerTheme(
        data: MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? LedgerThemeData.dark()
            : LedgerThemeData.light(),
        child: child!,
      ),
      home: const AccountsPage(),
    ),
  );
  show(
    MaterialApp.router(builder: (context, child) => LedgerHost(child: child!)),
  );
  show(LedgerHost.navigatorOf(context).push(route));
  show(LedgerPage<void>(name: 'account', child: const AccountPage()));
  final picked = await LedgerSheet.show<String>(
    context,
    title: 'Category',
    builder: (context) => [options],
  );
  show(
    LedgerSheetPage<void>(
      name: 'goal-new',
      drawer: true,
      child: const NewGoalPage(),
    ),
  );
  LedgerToast.show(
    context,
    'Moved to Groceries',
    actionLabel: 'Undo',
    onActionPressed: undo,
  );
  show(LedgerToaster(child: app));
  final applied = await showLedgerSideSheet<bool>(
    context,
    title: 'Filters',
    builder: (context) => filters,
  );
  final act = await showLedgerActionSheet<String>(
    context,
    title: 'Receipt',
    acts: const [LedgerSheetAct('Delete', value: 'delete', destructive: true)],
  );
  final ok = await LedgerDialog.show(
    context,
    title: 'Delete this entry?',
    body: 'It leaves your records for good.',
    type: LedgerDialogType.destructive,
    confirmLabel: 'Delete',
  );
}
