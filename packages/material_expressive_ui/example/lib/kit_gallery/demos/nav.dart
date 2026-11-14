/// The nav group's demo: the flexible navigation bar (3, 4 and 5 items;
/// vertical and horizontal items; badges; a disabled item), the navigation
/// rail, the navigation drawer standing and raised modally, and tabs — primary and secondary, fixed and scrollable, text and
/// icon — every one live: tap to move the selection and watch the
/// indicator spring.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The nav group's demo, in [brightness].
Widget kitNavDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Navigation',
  liveSections: <Widget>[const _BarVariants(), ..._sharedNavSections()],
  sections: <Widget>[
    kitSection(
      'Navigation bar · 3 items',
      children: const <Widget>[_LiveBar(items: _three)],
    ),
    kitSection(
      'Navigation bar · 4 items, badges',
      children: const <Widget>[_LiveBar(items: _fourBadged, selected: 1)],
    ),
    kitSection(
      'Navigation bar · 5 items',
      children: const <Widget>[_LiveBar(items: _five, selected: 2)],
    ),
    kitSection(
      'Horizontal items · centred',
      children: const <Widget>[
        _LiveBar(
          items: _three,
          position: ExpressiveNavItemPosition.start,
          arrangement: ExpressiveNavigationBarArrangement.centered,
        ),
      ],
    ),
    kitSection(
      'A disabled item',
      children: const <Widget>[_LiveBar(items: _withDisabled)],
    ),
    ..._sharedNavSections(),
  ],
);

List<Widget> _sharedNavSections() => <Widget>[
  kitSection('Navigation rail', children: const <Widget>[_LiveRail()]),
  kitSection(
    'Navigation drawer · standing, and raised over a scrim',
    children: const <Widget>[_LiveDrawer()],
  ),
  kitSection(
    'Primary tabs',
    children: const <Widget>[
      _LiveTabs(tabs: _travel),
      _LiveTabs(tabs: _travelIcons, selected: 1),
    ],
  ),
  kitSection(
    'Secondary tabs',
    children: const <Widget>[
      _LiveTabs(tabs: _inbox, variant: ExpressiveTabBarVariant.secondary),
    ],
  ),
  kitSection(
    'Scrollable tabs',
    children: const <Widget>[
      _LiveTabs(tabs: _menu, scrollable: true, selected: 3),
      _LiveTabs(
        tabs: _menu,
        scrollable: true,
        variant: ExpressiveTabBarVariant.secondary,
      ),
    ],
  ),
  kitSection(
    'Breadcrumbs · three steps, and six folded to four',
    children: const <Widget>[_Trails()],
  ),
  kitSection(
    'Pagination · the pages where they fit, the count where not',
    children: const <Widget>[_Paging()],
  ),
];

void _noTap() {}

const List<ExpressiveBreadcrumbItem> _shortTrail = <ExpressiveBreadcrumbItem>[
  ExpressiveBreadcrumbItem(
    'Home',
    icon: ExpressiveSymbols.home,
    onPressed: _noTap,
  ),
  ExpressiveBreadcrumbItem('Orders', onPressed: _noTap),
  ExpressiveBreadcrumbItem('#1042'),
];

const List<ExpressiveBreadcrumbItem> _longTrail = <ExpressiveBreadcrumbItem>[
  ExpressiveBreadcrumbItem(
    'Home',
    icon: ExpressiveSymbols.home,
    onPressed: _noTap,
  ),
  ExpressiveBreadcrumbItem('Library', onPressed: _noTap),
  ExpressiveBreadcrumbItem('Music', onPressed: _noTap),
  ExpressiveBreadcrumbItem('Albums', onPressed: _noTap),
  ExpressiveBreadcrumbItem('Blue Train', onPressed: _noTap),
  ExpressiveBreadcrumbItem('Moment’s Notice'),
];

/// Two breadcrumb trails: a short one, and a long one whose middle folds
/// into a menu.
class _Trails extends StatelessWidget {
  const _Trails();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: kitGap,
    children: <Widget>[
      ExpressiveBreadcrumb(items: _shortTrail),
      ExpressiveBreadcrumb(items: _longTrail),
    ],
  );
}

/// Pagination, live: three pages in a row; twelve as their pages where the
/// row fits (a tablet or desktop) and as the count where it doesn't (a
/// phone, the narrow column).
class _Paging extends StatefulWidget {
  const _Paging();

  @override
  State<_Paging> createState() => _PagingState();
}

class _PagingState extends State<_Paging> {
  int _page = 5;
  int _short = 2;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: kitGap,
    children: <Widget>[
      ExpressivePagination(
        page: _short,
        count: 3,
        onChanged: (p) => setState(() => _short = p),
      ),
      ExpressivePagination(
        page: _page,
        count: 12,
        onChanged: (p) => setState(() => _page = p),
      ),
      Center(
        child: SizedBox(
          width: 260,
          child: ExpressivePagination(
            page: _page,
            count: 12,
            onChanged: (p) => setState(() => _page = p),
          ),
        ),
      ),
    ],
  );
}

/// The short breadcrumb trail.
Widget kitSpecimenBreadcrumbsShort() =>
    const ExpressiveBreadcrumb(items: _shortTrail);

/// The long trail, its middle folded.
Widget kitSpecimenBreadcrumbsFolded() =>
    const ExpressiveBreadcrumb(items: _longTrail);

/// Page 5 of 12 at full width.
Widget kitSpecimenPaginationPages() =>
    ExpressivePagination(page: 5, count: 12, onChanged: (_) {});

class _BarVariants extends StatefulWidget {
  const _BarVariants();

  @override
  State<_BarVariants> createState() => _BarVariantsState();
}

class _BarVariantsState extends State<_BarVariants> {
  var _variant = 'three';

  @override
  Widget build(BuildContext context) {
    final items = switch (_variant) {
      'four' => _fourBadged,
      'five' => _five,
      'disabled' => _withDisabled,
      _ => _three,
    };
    final horizontal = _variant == 'horizontal';
    return kitSection(
      'Navigation bar',
      children: <Widget>[
        ExpressiveSelect<String>(
          key: const ValueKey('gallery-navigation-variant'),
          label: 'Variant',
          value: _variant,
          options: const [
            ExpressiveSelectOption('three', 'Three destinations'),
            ExpressiveSelectOption('four', 'Four with badges'),
            ExpressiveSelectOption('five', 'Five destinations'),
            ExpressiveSelectOption('horizontal', 'Horizontal layout'),
            ExpressiveSelectOption('disabled', 'Disabled destination'),
          ],
          onChanged: (value) => setState(() => _variant = value),
        ),
        _LiveBar(
          key: ValueKey(_variant),
          items: items,
          position: horizontal
              ? ExpressiveNavItemPosition.start
              : ExpressiveNavItemPosition.top,
          arrangement: horizontal
              ? ExpressiveNavigationBarArrangement.centered
              : ExpressiveNavigationBarArrangement.equalWeight,
        ),
      ],
    );
  }
}

const List<ExpressiveNavItem> _three = <ExpressiveNavItem>[
  ExpressiveNavItem(ExpressiveSymbols.today, 'Trips'),
  ExpressiveNavItem(ExpressiveSymbols.bookmark, 'Saved'),
  ExpressiveNavItem(ExpressiveSymbols.inbox, 'Inbox'),
];

const List<ExpressiveNavItem> _fourBadged = <ExpressiveNavItem>[
  ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
  ExpressiveNavItem(
    ExpressiveSymbols.chat,
    'Chats',
    badge: ExpressiveBadge(label: '3', semanticLabel: '3 unread chats'),
  ),
  ExpressiveNavItem(
    ExpressiveSymbols.notifications,
    'Updates',
    badge: ExpressiveBadge(semanticLabel: 'New updates'),
  ),
  ExpressiveNavItem(ExpressiveSymbols.person, 'You'),
];

const List<ExpressiveNavItem> _five = <ExpressiveNavItem>[
  ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
  ExpressiveNavItem(ExpressiveSymbols.explore, 'Explore'),
  ExpressiveNavItem(ExpressiveSymbols.map, 'Map'),
  ExpressiveNavItem(ExpressiveSymbols.favorite, 'Liked'),
  ExpressiveNavItem(ExpressiveSymbols.person, 'You'),
];

const List<ExpressiveNavItem> _withDisabled = <ExpressiveNavItem>[
  ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
  ExpressiveNavItem(ExpressiveSymbols.shoppingBag, 'Orders'),
  ExpressiveNavItem(ExpressiveSymbols.payments, 'Pay', enabled: false),
];

const List<ExpressiveNavItem> _railItems = <ExpressiveNavItem>[
  ExpressiveNavItem(ExpressiveSymbols.inbox, 'Inbox'),
  ExpressiveNavItem(
    ExpressiveSymbols.chat,
    'Chats',
    badge: ExpressiveBadge(label: '12', semanticLabel: '12 unread chats'),
  ),
  ExpressiveNavItem(ExpressiveSymbols.group, 'Rooms'),
  ExpressiveNavItem(ExpressiveSymbols.videocam, 'Calls'),
];

const List<ExpressiveTab> _travel = <ExpressiveTab>[
  ExpressiveTab(label: 'Flights'),
  ExpressiveTab(label: 'Hotels'),
  ExpressiveTab(label: 'Cars'),
];

const List<ExpressiveTab> _travelIcons = <ExpressiveTab>[
  ExpressiveTab(label: 'Flights', icon: ExpressiveSymbols.flight),
  ExpressiveTab(label: 'Hotels', icon: ExpressiveSymbols.hotel),
  ExpressiveTab(label: 'Cars', icon: ExpressiveSymbols.directionsCar),
];

const List<ExpressiveTab> _inbox = <ExpressiveTab>[
  ExpressiveTab(label: 'Overview'),
  ExpressiveTab(
    label: 'Mentions',
    badge: ExpressiveBadge(label: '2', semanticLabel: '2 new mentions'),
  ),
  ExpressiveTab(label: 'Archive'),
];

const List<ExpressiveTab> _menu = <ExpressiveTab>[
  ExpressiveTab(label: 'All'),
  ExpressiveTab(label: 'Breakfast'),
  ExpressiveTab(label: 'Lunch'),
  ExpressiveTab(label: 'Dinner'),
  ExpressiveTab(label: 'Desserts'),
  ExpressiveTab(label: 'Drinks'),
  ExpressiveTab(label: 'Snacks'),
  ExpressiveTab(label: 'Vegan'),
];

/// A bar that keeps its own selection, clear of the preview's insets (a
/// shell pads them; here the bar stands inside a page).
class _LiveBar extends StatefulWidget {
  const _LiveBar({
    required this.items,
    this.selected = 0,
    this.position = ExpressiveNavItemPosition.top,
    this.arrangement = ExpressiveNavigationBarArrangement.equalWeight,
    super.key,
  });

  final List<ExpressiveNavItem> items;
  final int selected;
  final ExpressiveNavItemPosition position;
  final ExpressiveNavigationBarArrangement arrangement;

  @override
  State<_LiveBar> createState() => _LiveBarState();
}

class _LiveBarState extends State<_LiveBar> {
  late int _selected = widget.selected;

  // A compact-width part: at a phone's width from 600.
  @override
  Widget build(BuildContext context) => kitPhoneWidth(
    title: widget.items[_selected].label,
    child: MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      removeBottom: true,
      child: ExpressiveNavigationBar(
        destinations: widget.items,
        selectedIndex: _selected,
        onDestinationSelected: (index) => setState(() => _selected = index),
        itemPosition: widget.position,
        arrangement: widget.arrangement,
      ),
    ),
  );
}

/// A rail beside a small panel of the selected destination.
class _LiveRail extends StatefulWidget {
  const _LiveRail();

  @override
  State<_LiveRail> createState() => _LiveRailState();
}

class _LiveRailState extends State<_LiveRail> {
  int _selected = 0;

  static const double _height = ExpressiveSpacing.s72 * 6;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final item = _railItems[_selected];
    return SizedBox(
      height: _height,
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeRight: true,
        removeTop: true,
        removeBottom: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ExpressiveNavigationRail(
              destinations: _railItems,
              selectedIndex: _selected,
              onDestinationSelected: (index) =>
                  setState(() => _selected = index),
            ),
            Expanded(
              child: ColoredBox(
                color: t.colors.surfaceContainerLow,
                child: Center(
                  child: Text(
                    item.label,
                    style: t.type.titleLarge.copyWith(
                      color: t.colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The drawer standing beside its page, and the same drawer raised modally:
/// a pick in either moves the selection.
class _LiveDrawer extends StatefulWidget {
  const _LiveDrawer();

  @override
  State<_LiveDrawer> createState() => _LiveDrawerState();
}

class _LiveDrawerState extends State<_LiveDrawer> {
  int _selected = 1;

  Future<void> _open() async {
    final picked = await ExpressiveNavigationDrawer.show(
      context,
      destinations: _railItems,
      selectedIndex: _selected,
    );
    if (picked != null && mounted) setState(() => _selected = picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: _LiveRailState._height,
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            removeTop: true,
            removeBottom: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ExpressiveNavigationDrawer(
                  destinations: _railItems,
                  selectedIndex: _selected,
                  onDestinationSelected: (index) =>
                      setState(() => _selected = index),
                ),
                Expanded(
                  child: ColoredBox(
                    color: t.colors.surfaceContainerLow,
                    child: Center(
                      child: Text(
                        _railItems[_selected].label,
                        style: t.type.titleLarge.copyWith(
                          color: t.colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        KitAction('Open as a modal drawer', onTap: _open),
      ],
    );
  }
}

/// Tabs that keep their own selection.
class _LiveTabs extends StatefulWidget {
  const _LiveTabs({
    required this.tabs,
    this.selected = 0,
    this.variant = ExpressiveTabBarVariant.primary,
    this.scrollable = false,
  });

  final List<ExpressiveTab> tabs;
  final int selected;
  final ExpressiveTabBarVariant variant;
  final bool scrollable;

  @override
  State<_LiveTabs> createState() => _LiveTabsState();
}

class _LiveTabsState extends State<_LiveTabs> {
  late int _selected = widget.selected;

  @override
  Widget build(BuildContext context) => ExpressiveTabBar(
    tabs: widget.tabs,
    selectedIndex: _selected,
    onChanged: (index) => setState(() => _selected = index),
    variant: widget.variant,
    scrollable: widget.scrollable,
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// Four labelled destinations, two carrying badges.
Widget kitSpecimenNavBarFour() => ExpressiveNavigationBar(
  destinations: _fourBadged,
  selectedIndex: 0,
  onDestinationSelected: (_) {},
);

/// The rail along the leading edge beside the selected destination.
Widget kitSpecimenNavRailInbox() => Builder(
  builder: (context) {
    final t = context.expressiveTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExpressiveNavigationRail(
          destinations: _railItems,
          selectedIndex: 1,
          onDestinationSelected: (_) {},
        ),
        Expanded(child: ColoredBox(color: t.colors.surfaceContainerLow)),
      ],
    );
  },
);

/// Three primary tabs fitting the width, the first selected.
Widget kitSpecimenTabsTravel() => ExpressiveTabBar(
  tabs: const <ExpressiveTab>[
    ExpressiveTab(label: 'Flights'),
    ExpressiveTab(label: 'Hotels'),
    ExpressiveTab(label: 'Cars'),
  ],
  selectedIndex: 0,
  onChanged: (_) {},
);

/// The drawer standing beside the selected destination.
Widget kitSpecimenNavDrawerChats() => Builder(
  builder: (context) {
    final t = context.expressiveTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExpressiveNavigationDrawer(
          destinations: _railItems,
          selectedIndex: 1,
          onDestinationSelected: (_) {},
        ),
        Expanded(child: ColoredBox(color: t.colors.surfaceContainerLow)),
      ],
    );
  },
);
