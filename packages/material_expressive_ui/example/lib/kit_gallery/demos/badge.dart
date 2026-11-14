/// The badge group's demo: the dot and the count badge alone, standing on
/// icons (a dot, a count, "999+" past the cap), on a navigation item and on
/// a tab.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The badge group's demo, in [brightness].
Widget kitBadgeDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Badges',
  sections: <Widget>[
    kitSection(
      'Dot and count',
      children: <Widget>[
        Wrap(
          spacing: ExpressiveSpacing.s24,
          runSpacing: ExpressiveSpacing.s16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const ExpressiveBadge(),
            const ExpressiveBadge(label: '1'),
            ExpressiveBadge.count(28),
            ExpressiveBadge.count(1204),
            const ExpressiveBadge(label: 'New'),
          ],
        ),
      ],
    ),
    kitSection(
      'On icons',
      children: <Widget>[
        Wrap(
          spacing: ExpressiveSpacing.s32,
          runSpacing: ExpressiveSpacing.s24,
          children: <Widget>[
            const _Badged(
              icon: ExpressiveSymbols.notifications,
              badge: ExpressiveBadge(semanticLabel: 'New notifications'),
            ),
            _Badged(
              icon: ExpressiveSymbols.email,
              badge: ExpressiveBadge.count(
                3,
                semanticLabel: '3 unread messages',
              ),
            ),
            _Badged(
              icon: ExpressiveSymbols.shoppingCart,
              badge: ExpressiveBadge.count(
                12,
                semanticLabel: '12 items in the cart',
              ),
            ),
            _Badged(
              icon: ExpressiveSymbols.forum,
              badge: ExpressiveBadge.count(
                2048,
                semanticLabel: 'Over 999 new posts',
              ),
            ),
          ],
        ),
      ],
    ),
    kitSection('Tags', children: <Widget>[kitSpecimenTag()]),
    kitSection('On navigation items', children: const <Widget>[_BadgedBar()]),
    kitSection('On tabs', children: const <Widget>[_BadgedTabs()]),
  ],
);

class _Badged extends StatelessWidget {
  const _Badged({required this.icon, required this.badge});

  final IconData icon;

  /// The badge to stand on the icon: its label and name.
  final ExpressiveBadge badge;

  @override
  Widget build(BuildContext context) => ExpressiveBadge(
    label: badge.label,
    semanticLabel: badge.semanticLabel,
    child: Icon(icon, color: context.expressiveTheme.colors.onSurfaceVariant),
  );
}

class _BadgedBar extends StatefulWidget {
  const _BadgedBar();

  @override
  State<_BadgedBar> createState() => _BadgedBarState();
}

class _BadgedBarState extends State<_BadgedBar> {
  int _selected = 0;

  // A compact-width part: at a phone's width from 600.
  @override
  Widget build(BuildContext context) => kitPhoneWidth(
    title: const <String>['Home', 'Inbox', 'Events', 'You'][_selected],
    child: MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      removeBottom: true,
      child: ExpressiveNavigationBar(
        selectedIndex: _selected,
        onDestinationSelected: (index) => setState(() => _selected = index),
        destinations: <ExpressiveNavItem>[
          const ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
          ExpressiveNavItem(
            ExpressiveSymbols.inbox,
            'Inbox',
            badge: ExpressiveBadge.count(8, semanticLabel: '8 new'),
          ),
          const ExpressiveNavItem(
            ExpressiveSymbols.event,
            'Events',
            badge: ExpressiveBadge(semanticLabel: 'Something new'),
          ),
          const ExpressiveNavItem(ExpressiveSymbols.person, 'You'),
        ],
      ),
    ),
  );
}

class _BadgedTabs extends StatefulWidget {
  const _BadgedTabs();

  @override
  State<_BadgedTabs> createState() => _BadgedTabsState();
}

class _BadgedTabsState extends State<_BadgedTabs> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => ExpressiveTabBar(
    selectedIndex: _selected,
    onChanged: (index) => setState(() => _selected = index),
    tabs: <ExpressiveTab>[
      const ExpressiveTab(label: 'Open'),
      ExpressiveTab(
        label: 'Review',
        badge: ExpressiveBadge.count(4, semanticLabel: '4 to review'),
      ),
      const ExpressiveTab(
        label: 'Done',
        badge: ExpressiveBadge(semanticLabel: 'New'),
      ),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// Counts and a dot on the glyphs they belong to.
Widget kitSpecimenBadgeOnIcons() => Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: <Widget>[
    const ExpressiveBadge(
      semanticLabel: 'New notifications',
      child: Icon(ExpressiveSymbols.notifications),
    ),
    ExpressiveBadge.count(
      3,
      semanticLabel: '3 unread messages',
      child: const Icon(ExpressiveSymbols.email),
    ),
    ExpressiveBadge.count(
      1204,
      semanticLabel: 'Over 999 posts',
      child: const Icon(ExpressiveSymbols.forum),
    ),
  ],
);

/// A tag in each tone, one with a glyph.
Widget kitSpecimenTag() => const Wrap(
  spacing: kitGap,
  runSpacing: kitGap,
  children: <Widget>[
    ExpressiveTag('Indoor'),
    ExpressiveTag('New', tone: ExpressiveTone.primary),
    ExpressiveTag(
      'Overdue',
      tone: ExpressiveTone.error,
      icon: ExpressiveSymbols.schedule,
    ),
  ],
);
