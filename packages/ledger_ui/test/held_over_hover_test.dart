// A press shows on top of a hover. With the pointer already over a control,
// as it is on a desktop, pressing it changes the face again, toward the ink
// (darker by day, lighter by night): part-way through Ledger's motion and
// once it settles. Every control family is pressed here, in both themes.
//
// In a scroll view, as a page holds its controls, ui_core shows the press
// kPressTimeout after the button goes down (a drag may still claim the
// pointer); the faces are read from there.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _shot = ValueKey('control');

Widget _host(Widget child, Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => LedgerHost(brightness: brightness, child: page!),
  // On the page's paper, in a scroll view.
  home: Builder(
    builder: (context) => SingleChildScrollView(
      child: RepaintBoundary(
        key: _shot,
        child: ColoredBox(
          color: context.ledgerTheme.background,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: SizedBox(
              width: 420,
              child: Align(alignment: Alignment.topLeft, child: child),
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<Uint8List> _pixels(WidgetTester t) async {
  final box = t.renderObject<RenderRepaintBoundary>(find.byKey(_shot));
  return (await t.runAsync(() async {
    final image = await box.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }))!;
}

/// How a held picture of a face differs from its hovered one: the largest
/// change of any channel, how many pixels changed by more than 8 of 255,
/// and how much nearer [ink] those pixels came, summed over their channels.
({int most, int changed, int inked}) _held(
  Uint8List hovered,
  Uint8List held,
  Color ink,
) {
  final to = [
    (ink.r * 255).round(),
    (ink.g * 255).round(),
    (ink.b * 255).round(),
  ];
  var most = 0;
  var changed = 0;
  var inked = 0;
  for (var i = 0; i < hovered.length; i += 4) {
    var px = 0;
    var nearer = 0;
    for (var c = 0; c < 3; c++) {
      final d = (hovered[i + c] - held[i + c]).abs();
      if (d > px) px = d;
      nearer += (hovered[i + c] - to[c]).abs() - (held[i + c] - to[c]).abs();
    }
    if (px > most) most = px;
    if (px > 8) {
      changed++;
      inked += nearer;
    }
  }
  return (most: most, changed: changed, inked: inked);
}

/// A press a reader sees: some marks changed by more than 16 of 255 and
/// more than 40 pixels by more than 8, nearer the ink on the whole.
Matcher get _shows => predicate<({int most, int changed, int inked})>(
  (d) => d.most > 16 && d.changed > 40 && d.inked > 0,
  'a change toward the ink of more than 16 over more than 40 pixels',
);

void main() {
  final controls = <String, (Widget, Finder)>{
    'filled button': (
      LedgerButton.filled('Continue', onPressed: () {}),
      find.text('Continue'),
    ),
    'ringed button': (
      LedgerButton('Add money', onPressed: () {}),
      find.text('Add money'),
    ),
    'ink button': (
      LedgerButton.ink('Freeze card', onPressed: () {}),
      find.text('Freeze card'),
    ),
    'text button': (
      LedgerButton.text('View all', onPressed: () {}),
      find.text('View all'),
    ),
    'row': (
      LedgerTransactionRow(
        title: 'Blue Fern Café',
        category: 'Dining out',
        when: '8:12 AM',
        account: 'Everyday Card',
        amount: -6.75,
        onTap: () {},
      ),
      find.text('Blue Fern Café'),
    ),
    'chip': (LedgerChip('Paid', onTap: () {}), find.text('Paid')),
    'check': (
      LedgerCheck(value: false, label: 'Pay rent', onChanged: (_) {}),
      find.byType(LedgerCheck),
    ),
    'check, ticked': (
      LedgerCheck(value: true, label: 'Pay rent', onChanged: (_) {}),
      find.byType(LedgerCheck),
    ),
    'checkbox': (
      LedgerCheckbox(
        value: false,
        label: 'Email me a receipt',
        onChanged: (_) {},
      ),
      find.text('Email me a receipt'),
    ),
    'checkbox, ticked': (
      LedgerCheckbox(
        value: true,
        label: 'Email me a receipt',
        onChanged: (_) {},
      ),
      find.text('Email me a receipt'),
    ),
    'icon button': (
      LedgerIconButton(
        LucideIcons.search,
        semanticLabel: 'Search',
        onPressed: () {},
      ),
      find.byIcon(LucideIcons.search),
    ),
    'ringed icon button': (
      LedgerIconButton.outlined(
        LucideIcons.chevronLeft,
        semanticLabel: 'Back',
        onPressed: () {},
      ),
      find.byIcon(LucideIcons.chevronLeft),
    ),
    'bell': (LedgerBell(unread: 1, onPressed: () {}), find.byType(LedgerBell)),
    'back': (
      LedgerBack(label: 'Activity', onPressed: () {}),
      find.byType(LedgerBack),
    ),
    'select': (
      LedgerSelect<String>(
        label: 'Currency',
        value: 'USD',
        items: const [
          LedgerSelectItem(value: 'USD', label: 'US dollar'),
          LedgerSelectItem(value: 'EUR', label: 'Euro'),
        ],
        onChanged: (_) {},
      ),
      find.text('US dollar'),
    ),
    'multi-select': (
      LedgerMultiSelect<String>(
        label: 'Split with',
        values: const ['Maren'],
        options: const ['Maren', 'Theo', 'Ana'],
        onChanged: (_) {},
      ),
      find.byType(LedgerPressable),
    ),
    'page number': (
      LedgerPagination(page: 2, pageCount: 9, onChanged: (_) {}),
      find.text('3'),
    ),
    'page dots': (
      LedgerPageDots(count: 5, index: 1, onChanged: (_) {}),
      find.byType(LedgerPageDots),
    ),
    'disclosure': (
      const LedgerDisclosure(
        title: 'Fees',
        note: r'$2.40',
        child: Text('Card fee'),
      ),
      find.text('Fees'),
    ),
    'crumb': (
      LedgerBreadcrumb([
        LedgerCrumb('Accounts', onTap: () {}),
        LedgerCrumb('Everyday', onTap: () {}),
        const LedgerCrumb('October'),
      ]),
      find.byType(LedgerPressable),
    ),
    'menu item': (
      LedgerMenu(
        head: 'Spent by month',
        semanticLabel: 'Months',
        items: [LedgerMenuItem('October 2026', amount: 2486.12, onTap: () {})],
      ),
      find.text('October 2026'),
    ),
    'avatar': (
      LedgerAvatar(initials: 'MH', label: 'Profile', onTap: () {}),
      find.byType(LedgerAvatar),
    ),
    'file pick': (
      LedgerFileUpload(label: 'Receipts', files: const [], onPick: () {}),
      find.byType(LedgerFileUpload),
    ),
    'search entry': (
      LedgerSearchEntry(hint: 'Search entries', onTap: () {}),
      find.text('Search entries'),
    ),
    'note row': (
      LedgerNoteRow(
        icon: LucideIcons.receipt,
        title: 'Rent is due in 4 days',
        body: 'To Linden Court.',
        when: '9:00 AM',
        onTap: () {},
      ),
      find.text('Rent is due in 4 days'),
    ),
    'filter': (
      LedgerFilters(
        label: 'Direction',
        options: const ['All', 'Money in', 'Money out'],
        value: 'All',
        onChanged: (_) {},
      ),
      find.text('Money in'),
    ),
    'goal line': (
      LedgerGoalLine(
        icon: LucideIcons.plane,
        name: 'Lisbon in May',
        saved: 2840,
        target: 4000,
        by: 'by May 2027',
        onTap: () {},
      ),
      find.text('Lisbon in May'),
    ),
    'category line': (
      LedgerCategoryLine(
        name: 'Dining out',
        spent: 286.40,
        budget: 250,
        pace: 28 / 31,
        onTap: () {},
      ),
      find.text('Dining out'),
    ),
    'head': (
      LedgerHead('Upcoming', note: 'All bills', onTap: () {}),
      find.byType(LedgerPressable),
    ),
    'split button': (
      LedgerSplitButton(
        'Export',
        onPressed: () {},
        actions: [LedgerSplitAction(label: 'As CSV', onPressed: () {})],
      ),
      find.text('Export'),
    ),
    'split chevron': (
      LedgerSplitButton(
        'Export',
        onPressed: () {},
        actions: [LedgerSplitAction(label: 'As CSV', onPressed: () {})],
      ),
      find.byIcon(LucideIcons.chevronDown),
    ),
    'slider': (
      LedgerSlider(label: 'Budget', value: 500, max: 2000, onChanged: (_) {}),
      find.byType(LedgerSlider),
    ),
    'side bar item': (
      SizedBox(
        height: 400,
        child: LedgerSideBar(
          items: const [
            LedgerNavItem(LucideIcons.house, 'Home'),
            LedgerNavItem(LucideIcons.list, 'Register'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
      find.text('Register'),
    ),
    'radio': (
      LedgerRadio<String>(
        value: 'system',
        groupValue: 'light',
        label: 'As the system is',
        onChanged: (_) {},
      ),
      find.text('As the system is'),
    ),
    'switch': (
      LedgerToggleRow(
        icon: LucideIcons.receipt,
        title: 'Bills',
        value: false,
        onChanged: (_) {},
      ),
      find.text('Bills'),
    ),
    'tab': (
      LedgerTabs(
        tabs: const ['Entries', 'Notes'],
        counts: const [12, 3],
        selectedIndex: 0,
        onSelected: (_) {},
      ),
      find.textContaining('Notes', findRichText: true),
    ),
    'segment': (
      LedgerToggleGroup<String>(
        options: const ['Day', 'Week', 'Month'],
        selected: const {'Day'},
        label: 'Range',
        labelOf: (v) => v,
        onChanged: (_) {},
      ),
      find.text('Week'),
    ),
    'card': (
      LedgerGoalCard(
        icon: LucideIcons.plane,
        name: 'Lisbon in May',
        saved: 2840,
        target: 4000,
        by: 'by May 2027',
        status: 'On track',
        note: 'Saving steadily.',
        onTap: () {},
      ),
      find.text('Lisbon in May'),
    ),
    'tab bar tab': (
      LedgerNavBar(
        items: const [
          LedgerNavItem(LucideIcons.house, 'Home'),
          LedgerNavItem(LucideIcons.list, 'Register'),
          LedgerNavItem(LucideIcons.plus, 'New entry'),
          LedgerNavItem(LucideIcons.chartPie, 'Budgets'),
          LedgerNavItem(LucideIcons.settings, 'Settings'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
      find.text('Register'),
    ),
    'tab bar disc': (
      LedgerNavBar(
        items: const [
          LedgerNavItem(LucideIcons.house, 'Home'),
          LedgerNavItem(LucideIcons.list, 'Register'),
          LedgerNavItem(LucideIcons.plus, 'New entry'),
          LedgerNavItem(LucideIcons.chartPie, 'Budgets'),
          LedgerNavItem(LucideIcons.settings, 'Settings'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
      find.byIcon(LucideIcons.plus),
    ),
  };

  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: (control, at)) in controls.entries) {
      testWidgets('$name, ${brightness.name}: a press shows over the hover', (
        t,
      ) async {
        t.view.physicalSize = const Size(600, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(_host(control, brightness));
        await t.pumpAndSettle();
        final ink = t.element(find.byKey(_shot)).ledgerTheme.textPrimary;
        final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        final spot = t.getCenter(at.first);
        await mouse.moveTo(spot);
        await t.pumpAndSettle();
        final hovered = await _pixels(t);

        await mouse.down(spot);
        await t.pump(kPressTimeout);
        // Half-way through the motion.
        await t.pump(LedgerMotion.fast ~/ 2);
        final early = _held(hovered, await _pixels(t), ink);
        expect(early, _shows, reason: 'half-way: $early');
        await t.pumpAndSettle();
        final settled = _held(hovered, await _pixels(t), ink);
        expect(settled, _shows, reason: 'settled: $settled');

        await mouse.up();
        await t.pumpAndSettle();
      });
    }
  }
}
