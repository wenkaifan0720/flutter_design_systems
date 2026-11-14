/// The chrome grammar as one small live app: three nav roots that keep
/// their own state behind the one docked tab bar, the shell's action square
/// in its trailing slot (the app's one create act, reachable from every
/// tab, so no root's top bar repeats it), a row that pushes a detail (the
/// Minimal fade-and-slide, the bar yielding, the derived back button and
/// breadcrumb), and a peer view that cross-fades in place.
///
/// [MinimalShell] itself takes a go_router `StatefulNavigationShell`, which
/// the gallery's import rules keep out of a demo; what stands in its place
/// is the same anatomy the shell builds — the branch container, the docked
/// bar over it, and the allowance each root reserves through
/// [MinimalShellInsets] — so everything below the shell is the real thing.
/// The package's own tests drive [MinimalShell] under a real router.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitShellDemo(Brightness brightness) => kitSurface(
  brightness: brightness,
  title: 'Shell & routes',
  height: _windowHeight,
  child: const _MiniApp(),
);

/// The window as tall as the Habits root: its bar, a header over each
/// group, a row for each habit and the tab bar, with no blank band between
/// the last row and the bar.
final double _windowHeight =
    MinimalChromeMetrics.barHeight +
    2 * _Group.height +
    (_morning.length + _evening.length) * MinimalChromeMetrics.row +
    MinimalNavigationBar.heightIn(0);

/// One habit in the demo's data.
class _Habit {
  const _Habit(this.id, this.name, this.streak, {this.done = false});

  final String id;
  final String name;
  final int streak;
  final bool done;
}

const List<_Habit> _morning = [
  _Habit('HAB-1', 'Meditate', 4, done: true),
  _Habit('HAB-4', 'Morning run', 12, done: true),
  _Habit('HAB-2', 'Drink water', 10),
];

const List<_Habit> _evening = [
  _Habit('HAB-3', 'Journal', 3),
  _Habit('HAB-5', 'Read 20 pages', 6, done: true),
];

class _MiniApp extends StatefulWidget {
  const _MiniApp();

  @override
  State<_MiniApp> createState() => _MiniAppState();
}

class _MiniAppState extends State<_MiniApp> {
  static const List<MinimalNavItem> _tabs = [
    MinimalNavItem(LucideIcons.listChecks, 'Habits'),
    MinimalNavItem(LucideIcons.activity, 'Trends'),
    MinimalNavItem(LucideIcons.settings, 'Settings'),
  ];

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    // The app's one create act: the accent, as Today's add wears it.
    final action = MinimalShellAction(
      icon: LucideIcons.plus,
      label: 'New habit',
      primary: true,
      onPressed: (context) =>
          showMinimalSnackBar(context, 'New habit', icon: LucideIcons.plus),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        MinimalShellInsets(
          allowance: MinimalNavigationBar.heightIn(bottom),
          child: IndexedStack(
            index: _tab,
            children: const [_HabitsRoot(), _TrendsRoot(), _SettingsRoot()],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: MinimalNavigationBar(
            items: _tabs,
            selectedIndex: _tab,
            onDestinationSelected: (index) => setState(() => _tab = index),
            action: action.icon,
            actionLabel: action.label,
            actionAccent: action.primary,
            onAction: () => action.onPressed(context),
          ),
        ),
      ],
    );
  }
}

/// A group header over its rows, hairlines between.
class _Group extends StatelessWidget {
  const _Group(this.label, this.count, {required this.rows, this.last = false});

  final String label;
  final String count;
  final List<_Habit> rows;

  /// The page's last group: its last row stands on the tab bar's rule and
  /// draws none of its own (a list's last row draws no rule).
  final bool last;

  /// The header's height: 14 over and 6 under its 16 px line.
  static const double height = 14 + 16 + 6;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MinimalChromeMetrics.gutter,
            14,
            MinimalChromeMetrics.gutter,
            6,
          ),
          child: Row(
            children: [
              Expanded(child: Text(label.toUpperCase(), style: t.label)),
              Text(count, style: t.mono.c(t.mutedForeground).medium),
            ],
          ),
        ),
        for (final (i, habit) in rows.indexed)
          _HabitRow(habit, rule: !last || i < rows.length - 1),
      ],
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow(this.habit, {this.rule = true});

  final _Habit habit;

  /// Whether a hairline runs under the row.
  final bool rule;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return MinimalPressable(
      radius: 0,
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => _HabitDetail(habit))),
      child: Container(
        height: t.rowHeight,
        padding: MinimalInsets.gutter,
        decoration: rule ? BoxDecoration(border: Border(bottom: t.rule)) : null,
        child: Row(
          children: [
            MinimalStatusIcon(
              habit.done ? MinimalTaskStatus.done : MinimalTaskStatus.todo,
            ),
            const MinimalGap(10),
            Expanded(
              child: Text(
                habit.name,
                style: t.body.medium.c(
                  habit.done ? t.mutedForeground : t.foreground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${habit.streak}d', style: t.mono.c(t.mutedForeground)),
          ],
        ),
      ),
    );
  }
}

/// A pushed page: it authors its parent crumb, its id and an action; the
/// back button is the route's.
class _HabitDetail extends StatelessWidget {
  const _HabitDetail(this.habit);

  final _Habit habit;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return MinimalScaffold(
      topBar: MinimalAppBar(
        parent: 'Habits',
        subtitle: habit.id,
        actions: [
          MinimalIconButton(
            LucideIcons.star,
            label: 'Favourite',
            onPressed: () {},
          ),
        ],
      ),
      footer: MinimalButton(
        habit.done ? 'Undo today' : 'Mark done',
        variant: habit.done
            ? MinimalButtonVariant.secondary
            : MinimalButtonVariant.primary,
        size: MinimalButtonSize.large,
        expand: true,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(habit.name, style: t.h1),
          const MinimalGap(MinimalSpacing.s4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${habit.streak}',
                  style: t.mono.c(t.mutedForeground),
                ),
                TextSpan(text: '-day streak. Keep it going tomorrow morning.'),
              ],
            ),
            style: t.bodySmall.c(t.mutedForeground),
          ),
        ],
      ),
    );
  }
}

/// The first root: the habits grouped by time of day. Its bar searches
/// and switches view; creating lives in the shell's action, never here too.
class _HabitsRoot extends StatelessWidget {
  const _HabitsRoot();

  @override
  Widget build(BuildContext context) => MinimalScaffold(
    topBar: MinimalAppBar(
      title: 'Habits',
      subtitle: '${_morning.length + _evening.length}',
      actions: [
        MinimalIconButton(
          LucideIcons.search,
          label: 'Search',
          onPressed: () {},
        ),
        MinimalIconButton(
          LucideIcons.layoutGrid,
          label: 'Switch view',
          onPressed: () => Navigator.of(context)
              .push(MinimalFadeRoute<void>(builder: (_) => const _BoardView())),
        ),
      ],
    ),
    padding: EdgeInsets.zero,
    body: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Group('Morning', '2/3', rows: _morning),
        _Group('Evening', '1/2', rows: _evening, last: true),
      ],
    ),
  );
}

/// A peer view that cross-fades in over the list rather than stepping
/// deeper.
class _BoardView extends StatelessWidget {
  const _BoardView();

  @override
  Widget build(BuildContext context) => MinimalScaffold(
    topBar: const MinimalAppBar(parent: 'Habits', title: 'Board'),
    body: MinimalEmptyState(
      icon: LucideIcons.layoutGrid,
      title: 'Board view',
      body: 'The board replaces the list in place, with a quick cross-fade.',
      actionLabel: 'Back to list',
      onAction: () => Navigator.of(context).maybePop(),
    ),
  );
}

class _TrendsRoot extends StatelessWidget {
  const _TrendsRoot();

  @override
  Widget build(BuildContext context) => const MinimalScaffold(
    topBar: MinimalAppBar(title: 'Trends'),
    scroll: false,
    body: MinimalEmptyState(
      icon: LucideIcons.activity,
      title: 'Not enough data yet',
      body: 'Trends appear after a week of check-ins.',
    ),
  );
}

class _SettingsRoot extends StatefulWidget {
  const _SettingsRoot();

  @override
  State<_SettingsRoot> createState() => _SettingsRootState();
}

class _SettingsRootState extends State<_SettingsRoot> {
  // Each root keeps its own state behind the bar.
  int _visits = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return MinimalScaffold(
      topBar: const MinimalAppBar(title: 'Settings'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This root keeps its state across tabs.', style: t.bodySmall),
          const MinimalGap(MinimalSpacing.s12),
          MinimalButton(
            'Counted $_visits',
            variant: MinimalButtonVariant.secondary,
            onPressed: () => setState(() => _visits += 1),
          ),
        ],
      ),
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// The bar alone, one configuration each, for the lab's Components pages
// (metadata.yaml `specimens`). The stage (kitSpecimenStage) styles and
// places them; a builder never names a style.

/// Three tabs and the ink create square: the plain tone, for an app whose
/// create act is not its standing invitation (the shell above wears the
/// accent).
Widget kitSpecimenNavBarShell() => MinimalNavigationBar(
  items: _MiniAppState._tabs,
  selectedIndex: 0,
  onDestinationSelected: (_) {},
  action: LucideIcons.plus,
  actionLabel: 'New habit',
  onAction: () {},
);

/// Four tabs and no action square.
Widget kitSpecimenNavBarOrders() => MinimalNavigationBar(
  items: const [
    MinimalNavItem(LucideIcons.inbox, 'Orders'),
    MinimalNavItem(LucideIcons.box, 'Stock'),
    MinimalNavItem(LucideIcons.users, 'Customers'),
    MinimalNavItem(LucideIcons.settings, 'Settings'),
  ],
  selectedIndex: 0,
  onDestinationSelected: (_) {},
);

/// Five glyph-only tabs and the accent action square.
Widget kitSpecimenNavBarIconsAccent() => MinimalNavigationBar(
  items: const [
    MinimalNavItem.iconOnly(LucideIcons.listChecks, semanticLabel: 'Habits'),
    MinimalNavItem.iconOnly(LucideIcons.activity, semanticLabel: 'Trends'),
    MinimalNavItem.iconOnly(LucideIcons.users, semanticLabel: 'Friends'),
    MinimalNavItem.iconOnly(LucideIcons.inbox, semanticLabel: 'Inbox'),
    MinimalNavItem.iconOnly(LucideIcons.settings, semanticLabel: 'Settings'),
  ],
  selectedIndex: 0,
  onDestinationSelected: (_) {},
  action: LucideIcons.plus,
  actionLabel: 'New habit',
  actionAccent: true,
  onAction: () {},
);
