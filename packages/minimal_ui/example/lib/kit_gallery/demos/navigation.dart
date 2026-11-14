/// Navigation beyond the phone's tab bar: the rail and the sidebar of a
/// wide window, pages of a long list, page dots and a run of steps.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

const _places = [
  MinimalNavItem(LucideIcons.inbox, 'Inbox'),
  MinimalNavItem(LucideIcons.listTodo, 'Issues'),
  MinimalNavItem(LucideIcons.folder, 'Projects'),
  MinimalNavItem(LucideIcons.chartColumn, 'Insights'),
];

Widget kitNavigationDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Rail, sidebar, pages',
  sections: [
    kitSection('Navigation rail', children: [_LiveRail()]),
    kitSection('Sidebar', children: [_LiveSidebar()]),
    kitSection('Pagination', children: [_LivePages()]),
    kitSection('Page dots', children: [_LiveDots()]),
    kitSection('Step progress', children: [_LiveSteps()]),
  ],
);

class _LiveRail extends StatefulWidget {
  @override
  State<_LiveRail> createState() => _LiveRailState();
}

class _LiveRailState extends State<_LiveRail> {
  int _at = 1;

  @override
  Widget build(BuildContext context) => _Window(
    nav: MinimalNavigationRail(
      destinations: _places,
      selectedIndex: _at,
      onDestinationSelected: (i) => setState(() => _at = i),
    ),
    place: _places[_at].label ?? '',
  );
}

const _teams = [
  MinimalNavItem(LucideIcons.hash, 'Design'),
  MinimalNavItem(LucideIcons.hash, 'Platform'),
];

class _LiveSidebar extends StatefulWidget {
  @override
  State<_LiveSidebar> createState() => _LiveSidebarState();
}

class _LiveSidebarState extends State<_LiveSidebar> {
  int _at = 0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // On a phone's column the sidebar narrows to its words, so the page
    // beside it keeps room for its rows.
    builder: (context, box) => _Window(
      nav: MinimalNavigationDrawer(
        width: box.maxWidth < 2 * _sidebar ? _narrow : _sidebar,
        selectedIndex: _at,
        onDestinationSelected: (i) => setState(() => _at = i),
        sections: const [
          MinimalNavigationSection(destinations: _places),
          MinimalNavigationSection(title: 'Your teams', destinations: _teams),
        ],
      ),
      place: [..._places, ..._teams][_at].label ?? '',
    ),
  );

  /// The sidebar's own width.
  static const double _sidebar = 248;

  /// Its width on a phone's column: room for its longest words ("Platform"
  /// chosen, "Your teams") at the largest text.
  static const double _narrow = 136;
}

/// A wide window in small: [nav] (a rail or a sidebar) down its start, the
/// page of the current [place] beside it, in the window's hairline frame.
class _Window extends StatelessWidget {
  const _Window({required this.nav, required this.place});

  final Widget nav;
  final String place;

  /// As tall as the rail's four places or the sidebar's two sections, at
  /// the largest text; the page beside them fills it.
  static const double _height = 280;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Container(
      height: _height,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(color: t.background, shape: t.shapes.medium),
      // The hairline paints over what it holds, so the nav's own ground
      // never covers the rim's curve.
      foregroundDecoration: ShapeDecoration(
        shape: t.shapes.medium.copyWith(
          side: BorderSide(color: t.border, width: t.hairline),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          nav,
          Expanded(child: _Page(place)),
        ],
      ),
    );
  }
}

/// What each place opens on: a row's title and its mono figure (a time, an
/// id, a project's key, a figure).
const Map<String, List<(String, String)>> _pageRows = {
  'Inbox': [
    ('Ada commented', '07:40'),
    ('Ines assigned you', '07:12'),
    ('Sam closed a bug', '06:58'),
    ('Weekly digest', '06:00'),
  ],
  'Issues': [
    ('Reminder fires twice', 'HAB-12'),
    ('Streak resets at noon', 'HAB-9'),
    ('Chart skips Sunday', 'HAB-7'),
    ('Sync stalls offline', 'HAB-5'),
  ],
  'Projects': [
    ('Ritual for iOS', 'IOS'),
    ('Ritual on the web', 'WEB'),
    ('Design system', 'DS'),
    ('Onboarding', 'ONB'),
  ],
  'Insights': [
    ('Kept this week', '82%'),
    ('Longest streak', '21d'),
    ('Opened this week', '14'),
    ('Closed this week', '11'),
  ],
  'Design': [
    ('Night palette', 'HAB-14'),
    ('Icon review', 'HAB-11'),
    ('Type scale', 'HAB-8'),
    ('Empty states', 'HAB-6'),
  ],
  'Platform': [
    ('Sync over cellular', 'HAB-21'),
    ('Push tokens expire', 'HAB-19'),
    ('Web build size', 'HAB-17'),
    ('Crash on resume', 'HAB-16'),
  ],
};

/// The page a place opens: its name, then its first rows. A page too
/// narrow for the figures shows the titles alone; past the window's foot it
/// scrolls, as a page does.
class _Page extends StatelessWidget {
  const _Page(this.place);

  final String place;

  /// From this wide a row has room for its figure, at 100% text; it grows
  /// with the text, so larger words keep the room the figure would take.
  static const double _figuresFrom = 200;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final figuresFrom = MediaQuery.textScalerOf(context).scale(_figuresFrom);
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        // 12 over the heading: its line centres on the sidebar's first
        // item beside it.
        padding: const EdgeInsets.fromLTRB(
          MinimalSpacing.s16,
          MinimalSpacing.s12,
          MinimalSpacing.s16,
          MinimalSpacing.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                place,
                style: t.h3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const MinimalGap(MinimalSpacing.s8),
            MinimalListSection(
              gutter: false,
              children: [
                for (final (title, figure)
                    in _pageRows[place] ?? const <(String, String)>[])
                  MinimalListTile(
                    title: title,
                    meta: box.maxWidth >= figuresFrom ? figure : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePages extends StatefulWidget {
  @override
  State<_LivePages> createState() => _LivePagesState();
}

class _LivePagesState extends State<_LivePages> {
  int _page = 5;

  /// Under this width the pagination folds its numbers away (the part's own
  /// break), so a narrower column shows the folded form once.
  static const double _folds = 360;

  @override
  Widget build(BuildContext context) {
    Widget pages() => MinimalPagination(
      page: _page,
      pageCount: 20,
      onPageChanged: (p) => setState(() => _page = p),
    );
    return LayoutBuilder(
      builder: (context, box) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A column too narrow for the numbers already shows the folded
          // form: drawing the 300 px one too would only repeat it.
          if (box.maxWidth >= _folds) ...[
            pages(),
            const MinimalGap(MinimalSpacing.s16),
          ],
          SizedBox(width: box.maxWidth < 300 ? null : 300, child: pages()),
          const MinimalGap(MinimalSpacing.s8),
          kitNote(
            'In a column under 360 px the numbers fold to the page '
            'count between its arrows.',
          ),
        ],
      ),
    );
  }
}

class _LiveDots extends StatefulWidget {
  @override
  State<_LiveDots> createState() => _LiveDotsState();
}

class _LiveDotsState extends State<_LiveDots> {
  int _at = 1;

  @override
  Widget build(BuildContext context) => MinimalPageDots(
    count: 4,
    selectedIndex: _at,
    onChanged: (i) => setState(() => _at = i),
  );
}

class _LiveSteps extends StatefulWidget {
  @override
  State<_LiveSteps> createState() => _LiveStepsState();
}

class _LiveStepsState extends State<_LiveSteps> {
  int _at = 1;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MinimalStepProgress(
        steps: const ['Account', 'Plan', 'Payment', 'Done'],
        current: _at,
        onStepPressed: (i) => setState(() => _at = i),
      ),
      const MinimalGap(MinimalSpacing.s16),
      kitRow([
        MinimalButton(
          'Back',
          variant: MinimalButtonVariant.secondary,
          onPressed: _at == 0 ? null : () => setState(() => _at--),
        ),
        MinimalButton(
          'Continue',
          onPressed: _at >= 4 ? null : () => setState(() => _at++),
        ),
      ]),
    ],
  );
}

// --- catalog specimens -------------------------------------------------------

/// The rail with Issues current.
Widget kitSpecimenNavigationRail() => SizedBox(
  height: 280,
  child: Align(
    alignment: AlignmentDirectional.centerStart,
    child: MinimalNavigationRail(
      destinations: _places,
      selectedIndex: 1,
      onDestinationSelected: (_) {},
    ),
  ),
);

/// The sidebar with a teams section.
Widget kitSpecimenNavigationDrawer() => SizedBox(
  height: 300,
  child: Align(
    alignment: AlignmentDirectional.centerStart,
    child: MinimalNavigationDrawer(
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      sections: const [
        MinimalNavigationSection(destinations: _places),
        MinimalNavigationSection(
          title: 'Your teams',
          destinations: [MinimalNavItem(LucideIcons.hash, 'Design')],
        ),
      ],
    ),
  ),
);

/// Page 6 of 20.
Widget kitSpecimenPagination() =>
    MinimalPagination(page: 5, pageCount: 20, onPageChanged: (_) {});

/// The second of four pages.
Widget kitSpecimenPageDots() =>
    MinimalPageDots(count: 4, selectedIndex: 1, onChanged: (_) {});

/// A checkout on its second step.
Widget kitSpecimenStepProgress() => const MinimalStepProgress(
  steps: ['Account', 'Plan', 'Payment', 'Done'],
  current: 1,
);
