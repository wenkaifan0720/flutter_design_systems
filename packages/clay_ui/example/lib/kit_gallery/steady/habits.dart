/// Steady's habits: the list with its filters and search, a habit's page
/// (its streaks, its month, its note), and on a desk the two side by side.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'editor.dart';
import 'steady.dart';

/// The habit list's filters.
enum SteadyFilter {
  /// Every habit that is not paused.
  all,

  /// The morning's.
  morning,

  /// The afternoon's.
  afternoon,

  /// The evening's.
  evening,

  /// The paused ones.
  paused;

  /// Its name on its chip.
  String get label => switch (this) {
    all => 'All',
    morning => 'Morning',
    afternoon => 'Afternoon',
    evening => 'Evening',
    paused => 'Paused',
  };

  /// Whether [h] passes it.
  bool passes(SteadyHabit h) => switch (this) {
    all => !h.paused,
    paused => h.paused,
    morning => !h.paused && h.time == SteadyTime.morning,
    afternoon => !h.paused && h.time == SteadyTime.afternoon,
    evening => !h.paused && h.time == SteadyTime.evening,
  };
}

/// Habits: the list, and on a desk the chosen habit beside it.
class SteadyHabits extends StatefulWidget {
  /// The habits place, searched for [initialQuery].
  const SteadyHabits({super.key, this.initialQuery = ''});

  /// What the search holds when it opens.
  final String initialQuery;

  @override
  State<SteadyHabits> createState() => _SteadyHabitsState();
}

class _SteadyHabitsState extends State<SteadyHabits> {
  SteadyFilter _filter = SteadyFilter.all;
  late final _search = TextEditingController(text: widget.initialQuery);

  @override
  void initState() {
    super.initState();
    _search.addListener(_searched);
  }

  void _searched() => setState(() {});

  @override
  void dispose() {
    _search
      ..removeListener(_searched)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = SteadyFrame.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final split = width >= steadySplitWidth;
    final query = _search.text.trim().toLowerCase();
    // A search looks through every habit, paused ones too.
    final shown = frame.habits
        .where(
          (h) => query.isEmpty
              ? _filter.passes(h)
              : h.name.toLowerCase().contains(query),
        )
        .toList();
    final list = _HabitList(
      habits: shown,
      search: _search,
      filter: _filter,
      onFilter: (f) => setState(() => _filter = f),
      chosen: split ? frame.chosen : null,
      onOpen: (h) {
        if (split) {
          frame.choose(h.id);
        } else {
          frame.push(SteadyHabitPage(habit: h));
        }
      },
    );
    if (!split) {
      // The one way to a new habit is the dock's coral key, the same on
      // every page.
      return SteadyPage(title: 'Habits', large: true, children: [list]);
    }
    // A desk: the list in a column of its own, the chosen habit beside it,
    // each scrolling on its own.
    final theme = context.clayTheme;
    final margin = ClaySpacing.pageMargin(width);
    return ColoredBox(
      color: theme.colors.ground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Each pane its own Tab group: the list, then the habit.
          SizedBox(
            width: 420,
            child: FocusTraversalGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ClayTopBar(title: 'Habits'),
                  Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: ListView(
                        // Room at the column's end for the cards' shadows,
                        // which the list's edge would otherwise cut.
                        padding: EdgeInsetsDirectional.fromSTEB(
                          margin,
                          ClaySpacing.small,
                          ClaySpacing.large,
                          ClaySpacing.huge,
                        ),
                        children: [list],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // The chosen habit while the list shows it: a search that hides it
          // empties the pane rather than leave a habit it did not find.
          Expanded(
            child: FocusTraversalGroup(
              child: shown.any((h) => h.id == frame.chosen)
                  ? SteadyHabitPage(
                      key: ValueKey(frame.chosen),
                      habit: frame.habit(frame.chosen),
                      beside: true,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitList extends StatelessWidget {
  const _HabitList({
    required this.habits,
    required this.search,
    required this.filter,
    required this.onFilter,
    required this.onOpen,
    this.chosen,
  });

  final List<SteadyHabit> habits;
  final TextEditingController search;
  final SteadyFilter filter;
  final ValueChanged<SteadyFilter> onFilter;
  final ValueChanged<SteadyHabit> onOpen;
  final String? chosen;

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim();
    final searching = query.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClaySearchField(
          controller: search,
          hintText: 'Search habits',
          semanticLabel: 'Search habits',
        ),
        const SizedBox(height: ClaySpacing.regular),
        // The filters wrap: every chip whole, where a tap reaches it. A
        // search reads every habit, so they rest while it runs.
        if (!searching)
          Wrap(
            spacing: ClaySpacing.small,
            runSpacing: ClaySpacing.small,
            children: [
              for (final f in SteadyFilter.values)
                ClayChip(
                  label: f.label,
                  selected: f == filter,
                  onSelected: (_) => onFilter(f),
                ),
            ],
          ),
        const SizedBox(height: ClaySpacing.small),
        if (habits.isEmpty)
          ClayCard(
            child: ClayStateView(
              state: ClayState.empty,
              icon: searching ? LucideIcons.searchX : LucideIcons.sprout,
              title: searching
                  ? 'No habits match \u201c$query\u201d'
                  : filter == SteadyFilter.paused
                  ? 'Nothing paused'
                  : 'No ${filter.label.toLowerCase()} habits',
              message: searching
                  ? 'Try another word, or add it as a new habit.'
                  : filter == SteadyFilter.paused
                  ? 'A paused habit keeps its streak until you start again.'
                  : 'Give a habit this time of day in its editor.',
              actions: [
                if (searching)
                  ClayButton(
                    'Clear search',
                    icon: const Icon(LucideIcons.x),
                    onPressed: search.clear,
                  ),
              ],
            ),
          )
        else
          ClayGroup(
            header: searching
                ? clayPlural(
                    context,
                    habits.length,
                    one: '1 result',
                    other: '${habits.length} results',
                  )
                : clayPlural(
                    context,
                    habits.length,
                    one: '1 habit',
                    other: '${habits.length} habits',
                  ),
            children: [
              for (final h in habits)
                ClayListTile(
                  key: ValueKey('habit-${h.id}'),
                  leading: ClayIconTile(tint: h.tint, child: Icon(h.icon)),
                  title: h.name,
                  subtitle: h.paused
                      ? 'Paused'
                      : '${steadyRepeats[h.repeat]} · ${h.time.label}',
                  trailingText: h.streak == 0 ? null : '${h.streak} days',
                  selected: h.id == chosen,
                  onTap: () => onOpen(h),
                ),
            ],
          ),
      ],
    );
  }
}

/// A habit's page: its streaks, its month, its note; the key to edit it.
class SteadyHabitPage extends StatefulWidget {
  /// The page of [habit]; [beside] when it stands beside the list.
  const SteadyHabitPage({super.key, required this.habit, this.beside = false});

  /// The habit.
  final SteadyHabit habit;

  /// Whether it stands beside the list (a desk), with no way back.
  final bool beside;

  @override
  State<SteadyHabitPage> createState() => _SteadyHabitPageState();
}

class _SteadyHabitPageState extends State<SteadyHabitPage> {
  int _range = 0;

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    final frame = SteadyFrame.of(context);
    final theme = context.clayTheme;
    final c = theme.colors;
    final edit = ClayButton(
      'Edit habit',
      icon: const Icon(LucideIcons.pencil),
      onPressed: () => frame.push(SteadyEditor(habit: h)),
    );
    final tick = ClayButton.filled(
      h.done ? 'Done today' : (h.goal == 1 ? 'Mark done' : 'Log one'),
      icon: const Icon(LucideIcons.check),
      onPressed: () => setState(() => frame.tick(h)),
    );
    return SteadyPage(
      title: h.name,
      maxWidth: 720,
      bottom: SteadyKeys(primary: tick, secondary: edit),
      children: [
        ClayCard(
          child: Row(
            children: [
              ClayIconTile(tint: h.tint, size: 56, child: Icon(h.icon)),
              const SizedBox(width: ClaySpacing.regular),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.today,
                      style: theme.textTheme.title.copyWith(color: c.ink),
                    ),
                    Text(
                      '${steadyRepeats[h.repeat]} · ${h.time.label}'
                      '${h.reminder == null ? '' : ' · ${steadyClock(h.reminder!)}'}',
                      style: theme.textTheme.secondary,
                    ),
                    if (h.goal > 1) ...[
                      const SizedBox(height: ClaySpacing.medium),
                      ClayProgressBar(
                        value: h.progress / h.goal,
                        color: c.tint(h.tint),
                        semanticLabel: 'Today',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClaySpacing.regular),
        _Stats(
          stats: [
            _Stat(
              label: 'Current run',
              value: '${h.streak}',
              unit: 'days',
              icon: LucideIcons.flame,
            ),
            _Stat(
              label: 'Best run',
              value: '${h.best}',
              unit: 'days',
              icon: LucideIcons.trophy,
            ),
            _Stat(
              label: 'This month',
              value: '${(h.month * 100).round()}',
              unit: '%',
              icon: LucideIcons.calendarDays,
            ),
          ],
        ),
        steadyGroupGap,
        ClayTabBar(
          tabs: const ['November', 'Five weeks'],
          selectedIndex: _range,
          onTap: (i) => setState(() => _range = i),
        ),
        const SizedBox(height: ClaySpacing.regular),
        ClayCard(
          child: _Calendar(habit: h, month: _range == 0),
        ),
        if (h.note.isNotEmpty) ...[
          steadyGroupGap,
          ClayGroup(
            header: 'Why it matters',
            children: [
              Padding(
                padding: const EdgeInsets.all(ClaySpacing.roomy),
                child: Text(
                  h.note,
                  style: theme.textTheme.body.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The habit's figures side by side, or one under another where side by
/// side their words would be cut (large text on a phone).
class _Stats extends StatelessWidget {
  const _Stats({required this.stats});

  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, box) {
        const gap = ClaySpacing.medium;
        final each = (box.maxWidth - gap * (stats.length - 1)) / stats.length;
        if (each >= 104 * scale) {
          return Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(child: stats[i]),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) const SizedBox(height: gap),
              stats[i],
            ],
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final c = theme.colors;
    return ClayCard(
      padding: const EdgeInsets.all(ClaySpacing.regular),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: c.accentInk),
            const SizedBox(height: ClaySpacing.small),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: theme.textTheme.headline.copyWith(color: c.ink),
                  ),
                  TextSpan(text: ' $unit', style: theme.textTheme.secondary),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.caption.copyWith(color: c.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The habit's days: a whole November, or the last five weeks. A day done is
/// a ball of its pastel holding its date, a day missed a cup pressed into the
/// card, today ringed, days to come bare; a key under them says which is which.
class _Calendar extends StatelessWidget {
  const _Calendar({required this.habit, required this.month});

  final SteadyHabit habit;
  final bool month;

  // Steady's today, and the day its history runs to (that week's Sunday).
  static final DateTime _today = DateTime(2026, 11, 19);
  static final DateTime _lastKnown = DateTime(2026, 11, 22);

  /// Whether [day] was done; null for a day still to come.
  bool? _doneOn(DateTime day) {
    if (day.isAfter(_today)) return null;
    final i = habit.history.length - 1 - _lastKnown.difference(day).inDays;
    return i >= 0 && habit.history[i];
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final c = theme.colors;
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    // Mondays: the one before 1 November, or five weeks back from today's.
    final first = month ? DateTime(2026, 10, 26) : DateTime(2026, 10, 19);
    final weeks = month ? 6 : 5;
    final tint = c.tint(habit.tint);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (final n in names)
                Expanded(
                  child: Center(
                    child: Text(
                      n,
                      style: theme.textTheme.caption.copyWith(
                        color: c.inkSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ClaySpacing.small),
        for (var w = 0; w < weeks; w++)
          Padding(
            padding: const EdgeInsets.only(bottom: ClaySpacing.small),
            child: Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          // Built from the date's parts, so a clock change
                          // never shifts a day.
                          final day = DateTime(
                            first.year,
                            first.month,
                            first.day + w * 7 + d,
                          );
                          return _Day(
                            day: day,
                            done: _doneOn(day),
                            tint: tint,
                            shown: !month || day.month == 11,
                            today: day == _today,
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: ClaySpacing.tight),
        ExcludeSemantics(
          child: Wrap(
            spacing: ClaySpacing.large,
            runSpacing: ClaySpacing.small,
            children: [
              _KeyItem(
                face: ClayFace.raised(c, color: tint, radius: 8),
                label: 'Done',
              ),
              _KeyItem(face: ClayFace.well(c, radius: 8), label: 'Missed'),
              _KeyItem(
                face: ClayFace.well(
                  c,
                  radius: 8,
                ).copyWith(focus: 1, focusColor: c.accentInk),
                label: 'Today',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyItem extends StatelessWidget {
  const _KeyItem({required this.face, required this.label});

  final ClayFace face;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(dimension: 16, child: ClaySurface(face: face)),
        const SizedBox(width: ClaySpacing.small),
        Text(label, style: theme.textTheme.secondary),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.day,
    required this.done,
    required this.tint,
    required this.shown,
    required this.today,
  });

  final DateTime day;
  final bool? done;
  final Color tint;
  final bool shown;
  final bool today;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final c = theme.colors;
    if (!shown) return const SizedBox.square(dimension: 32);
    final done = this.done;
    final state = done == null ? 'to come' : (done ? 'done' : 'missed');
    final weight = today ? FontWeight.w600 : FontWeight.w400;
    final number = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '${day.day}',
        maxLines: 1,
        style: theme.textTheme.caption.copyWith(
          color: done == null
              ? c.inkDisabled
              : (done ? c.onColor(tint) : c.inkSecondary),
          fontWeight: weight,
          fontVariations: clayWeight(weight),
        ),
      ),
    );
    final face = done == null
        ? null
        : (done
              ? ClayFace.raised(c, color: tint, radius: 16)
              : ClayFace.well(c, radius: 16));
    return Semantics(
      label:
          '${day.day} ${_months[day.month - 1]}${today ? ', today' : ''}, '
          '$state',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 32,
        child: face == null
            ? Center(child: number)
            : ClaySurface(
                face: today
                    ? face.copyWith(focus: 1, focusColor: c.accentInk)
                    : face,
                child: Center(child: number),
              ),
      ),
    );
  }
}

/// One day's bar on a week card: a groove filled to [share] with a coral
/// volume; [today] in full ink.
class SteadyBar extends StatelessWidget {
  /// A bar at [share], 0 to 1.
  const SteadyBar({super.key, required this.share, this.today = false});

  /// How full it is.
  final double share;

  /// Whether it is today's.
  final bool today;

  @override
  Widget build(BuildContext context) {
    final c = context.clayTheme.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        return SizedBox(
          width: 18,
          height: h,
          child: ClaySurface(
            face: ClayFace.well(c, radius: 9),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: share <= 0
                  ? const SizedBox.shrink()
                  : SizedBox(
                      width: 18,
                      height: (h * share).clamp(18.0, h),
                      child: ClaySurface(
                        face: ClayFace.raised(
                          c,
                          color: today ? c.accent : c.tint(ClayTint.peach),
                          radius: 9,
                        ).copyWith(shadowOpacity: 0),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
