/// The gallery's shared Ritual Today page: one source for the Today screen,
/// for the page the New habit sheet is raised over (so the dimmed page under
/// the sheet is the real one), and for the example's Habits app.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'habits.dart';

/// Which rows the count filters keep.
enum _View { all, open, done, paused }

/// Ritual's Today tab: the day's summary bar, the count filters, then the
/// habits grouped by time of day, each row a status glyph that marks it
/// kept, the name over its streak, and the week in squares. Marking a habit
/// moves the summary, the group counts and the filters with it. The bar
/// carries the solid `+` of the one create act ([onNew]); a row opens its
/// habit ([onOpen]). [habits] is the tracker's state; null keeps a fresh
/// one of the page's own. [leading] stands at the bar's start (an app's
/// way out).
class KitTodayPage extends StatefulWidget {
  const KitTodayPage({
    super.key,
    this.habits,
    this.onNew,
    this.onOpen,
    this.selected,
    this.leading,
  });

  final KitHabits? habits;
  final VoidCallback? onNew;
  final ValueChanged<KitHabit>? onOpen;
  final Widget? leading;

  /// The id of the habit whose detail stands beside the list (the laptop
  /// form), its row marked selected; null on a phone.
  final String? selected;

  @override
  State<KitTodayPage> createState() => _KitTodayPageState();
}

class _KitTodayPageState extends State<KitTodayPage> {
  late final KitHabits _own = KitHabits();
  KitHabits get _habits => widget.habits ?? _own;
  _View _view = _View.all;

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  MinimalTaskStatus _statusOf(KitHabit h) => h.paused
      ? MinimalTaskStatus.paused
      : _habits.kept(h)
      ? MinimalTaskStatus.done
      : MinimalTaskStatus.todo;

  bool _shows(KitHabit h) => _matches(h, _view);

  int _count(_View view) =>
      _habits.habits.where((h) => _matches(h, view)).length;

  bool _matches(KitHabit h, _View view) => switch (view) {
    _View.all => true,
    _View.open => _statusOf(h) == MinimalTaskStatus.todo,
    _View.done => _statusOf(h) == MinimalTaskStatus.done,
    _View.paused => h.paused,
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _habits,
    builder: (context, _) => _page(context),
  );

  Widget _page(BuildContext context) {
    final t = context.minimalTheme;
    final today = kitHabitsToday;
    final all = _habits.habits;
    // A paused habit is off the day's books: it counts toward nothing.
    final active = all.where((h) => !h.paused).toList();
    final kept = active.where(_habits.kept).length;
    final shown = [
      for (final group in kitHabitGroups)
        (group, all.where((h) => h.group == group && _shows(h)).toList()),
    ].where((g) => g.$2.isNotEmpty).toList();
    return MinimalScaffold(
      topBar: MinimalAppBar(
        leading: widget.leading,
        title: 'Today',
        subtitle:
            '${MinimalFormat.weekday(today)} ${MinimalFormat.dayMonth(today)}',
        actions: [
          MinimalIconButton(
            LucideIcons.plus,
            label: 'New habit',
            variant: MinimalIconButtonVariant.primary,
            onPressed: widget.onNew ?? () {},
          ),
        ],
      ),
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MinimalChromeMetrics.gutter,
              vertical: MinimalSpacing.s12,
            ),
            decoration: BoxDecoration(border: Border(bottom: t.rule)),
            child: MinimalSegmentBar(
              value: kept,
              total: active.length,
              label: 'kept',
              showPercent: true,
            ),
          ),
          MinimalFilterBar(
            children: [
              for (final view in _View.values)
                MinimalFilter(
                  switch (view) {
                    _View.all => 'All',
                    _View.open => 'Open',
                    _View.done => 'Done',
                    _View.paused => 'Paused',
                  },
                  count: _count(view),
                  selected: view == _view,
                  onPressed: () => setState(() => _view = view),
                ),
            ],
          ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s48),
              child: MinimalEmptyState(
                icon: LucideIcons.circleCheck,
                title: 'Nothing open',
                body: 'Every habit on today\'s list is kept.',
                actionLabel: 'Show all',
                onAction: () => setState(() => _view = _View.all),
              ),
            ),
          for (final (group, rows) in shown) ...[
            MinimalSectionHeader(group, count: _groupCount(group)),
            MinimalListSection(
              children: [
                for (final habit in rows)
                  _HabitRow(
                    habit,
                    status: _statusOf(habit),
                    streak: _habits.streak(habit),
                    selected: habit.id == widget.selected,
                    onToggle: habit.paused ? null : () => _habits.toggle(habit),
                    onOpen: widget.onOpen == null
                        ? null
                        : () => widget.onOpen!(habit),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// A group's kept count over its active habits, `2/3`; none for a group
  /// with nothing active (only paused habits), where `0/0` says nothing.
  String? _groupCount(String group) {
    final active = _habits.habits.where((h) => h.group == group && !h.paused);
    if (active.isEmpty) return null;
    final kept = active.where(_habits.kept).length;
    return '$kept/${active.length}';
  }
}

/// One habit on the day: its status glyph is the control that marks it
/// kept; the name leads, the streak is its one supporting line, and the
/// week stands at the end, so the squares line up down the list.
class _HabitRow extends StatelessWidget {
  const _HabitRow(
    this.habit, {
    required this.status,
    required this.streak,
    required this.onToggle,
    required this.onOpen,
    this.selected = false,
  });

  final KitHabit habit;
  final MinimalTaskStatus status;
  final int streak;
  final VoidCallback? onToggle;
  final VoidCallback? onOpen;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final done = status == MinimalTaskStatus.done;
    final week = [
      for (final (i, kept) in habit.week.indexed)
        i == kitTodayIndex ? done : kept,
    ];
    return MinimalListTile(
      title: habit.name,
      subtitle: habit.paused
          ? 'Paused'
          : streak == 0
          ? 'Starts today'
          : '$streak-day streak',
      muted: status != MinimalTaskStatus.todo,
      selected: selected,
      onTap: onOpen,
      leading: MinimalStatusIcon(
        status,
        semanticLabel: habit.name,
        onPressed: onToggle,
      ),
      trailing: MinimalWeekDots(completedDays: week, currentDay: kitTodayIndex),
    );
  }
}
