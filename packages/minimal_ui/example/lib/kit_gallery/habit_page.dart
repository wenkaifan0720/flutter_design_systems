/// The gallery's shared habit page: one source for the Habit screen a phone
/// pushes off the list, for the detail a laptop stands beside it, and for
/// the example's Habits app.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'habits.dart';

/// A habit's page: its name and note, its properties (status and repeat
/// set from their menus), the last twelve weeks as a heat map with its key,
/// and its activity. Archive, in the overflow menu, asks first, then takes
/// the habit off the list with an undo ([onArchived] says where to go).
/// [habits] is the tracker's state and [id] the habit; null for both shows
/// Morning run on a tracker of the page's own.
class KitHabitPage extends StatefulWidget {
  const KitHabitPage({
    super.key,
    this.habits,
    this.id = 'HAB-4',
    this.parent = 'Today',
    this.onArchived,
  });

  final KitHabits? habits;
  final String id;

  /// The page it was opened from, for the bar's way back.
  final String? parent;

  /// What follows an archive: the phone's page pops; the laptop's detail
  /// shows another habit.
  final VoidCallback? onArchived;

  @override
  State<KitHabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<KitHabitPage> {
  late final KitHabits _own = KitHabits();
  KitHabits get _habits => widget.habits ?? _own;
  bool _favourite = false;

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  Future<void> _archive(KitHabit habit) async {
    final sure =
        await showMinimalDialog<bool>(
          context,
          builder: (_) => MinimalDialog(
            title: 'Archive ${habit.name}?',
            message:
                'It leaves Today and stops reminding you. Its record is kept.',
            confirmLabel: 'Archive',
            cancelLabel: 'Keep',
            destructive: true,
          ),
        ) ??
        false;
    if (!sure || !mounted) return;
    final undo = _habits.remove(habit);
    widget.onArchived?.call();
    if (!mounted) return;
    showMinimalSnackBar(
      context,
      '${habit.name} archived',
      icon: LucideIcons.archive,
      actionLabel: 'Undo',
      onAction: undo,
    );
  }

  void _pause(KitHabit habit, bool paused) {
    if (habit.paused == paused) return;
    final undo = _habits.setPaused(habit, paused);
    showMinimalSnackBar(
      context,
      paused ? '${habit.name} paused' : '${habit.name} resumed',
      icon: paused ? LucideIcons.pause : LucideIcons.play,
      actionLabel: 'Undo',
      onAction: undo,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _habits,
    builder: (context, _) {
      final habit = _habits.byId(widget.id);
      if (habit == null) return const MinimalScaffold(body: SizedBox.shrink());
      return _page(context, habit);
    },
  );

  Widget _page(BuildContext context, KitHabit habit) {
    final t = context.minimalTheme;
    final record = habit.record;
    final today = record.isEmpty ? null : record.length - 1;
    final kept = record.where((level) => level > 0).length;
    final streak = _habits.streak(habit);
    return MinimalScaffold(
      topBar: MinimalAppBar(
        parent: widget.parent,
        subtitle: habit.id,
        actions: [
          MinimalIconButton(
            LucideIcons.star,
            label: 'Favourite',
            selected: _favourite,
            onPressed: () => setState(() => _favourite = !_favourite),
          ),
          MinimalMenu.button(
            LucideIcons.ellipsis,
            label: 'Habit actions',
            items: [
              MinimalMenuItem(
                habit.paused ? 'Resume' : 'Pause',
                icon: habit.paused ? LucideIcons.play : LucideIcons.pause,
                onPressed: () => _pause(habit, !habit.paused),
              ),
              MinimalMenuItem(
                'Archive',
                icon: LucideIcons.archive,
                destructive: true,
                startsGroup: true,
                onPressed: () => _archive(habit),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(habit.name, style: t.h1)),
          if (habit.note.isNotEmpty) ...[
            const MinimalGap(MinimalSpacing.s4),
            Text(habit.note, style: t.body.c(t.mutedForeground)),
          ],
          const MinimalGap(MinimalSpacing.s16),
          MinimalDescriptionList(
            properties: [
              MinimalProperty(
                icon: LucideIcons.circleDot,
                label: 'Status',
                value: habit.paused ? 'Paused' : 'Active',
                tone: habit.paused ? MinimalTone.neutral : MinimalTone.success,
                items: [
                  MinimalMenuItem(
                    'Active',
                    selected: !habit.paused,
                    onPressed: () => _pause(habit, false),
                  ),
                  MinimalMenuItem(
                    'Paused',
                    selected: habit.paused,
                    onPressed: () => _pause(habit, true),
                  ),
                ],
              ),
              MinimalProperty(
                icon: LucideIcons.repeat,
                label: 'Repeats',
                value: habit.repeat,
                items: [
                  for (final repeat in kitHabitRepeats)
                    MinimalMenuItem(
                      repeat,
                      selected: repeat == habit.repeat,
                      onPressed: () => _habits.setRepeat(habit, repeat),
                    ),
                ],
              ),
              MinimalProperty(
                icon: LucideIcons.bell,
                label: 'Reminder',
                value: habit.reminder ?? 'None',
                mono: habit.reminder != null,
              ),
              MinimalProperty(
                icon: LucideIcons.flame,
                label: 'Streak',
                value: '${streak}d',
                detail: habit.best > streak ? 'best ${habit.best}d' : null,
                mono: true,
              ),
              MinimalProperty(
                icon: LucideIcons.calendar,
                label: 'Started',
                value: MinimalFormat.isoDate(habit.started),
                mono: true,
              ),
            ],
          ),
          MinimalSectionHeader(
            'Last 12 weeks',
            // The days up to and including today: the blank weekend ahead
            // is not a day missed.
            count: record.isEmpty ? null : '$kept / ${record.length}',
            padding: const EdgeInsets.fromLTRB(
              0,
              MinimalSpacing.s24,
              0,
              MinimalSpacing.s8,
            ),
          ),
          if (record.isEmpty)
            Text(
              'No days yet. The record starts with the first day kept.',
              style: t.bodySmall.c(t.mutedForeground),
            )
          else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: MinimalHeatmap(
                levels: record,
                weeks: 12,
                today: today,
                legend: true,
                semanticLabel: '$kept of the last ${record.length} days kept',
              ),
            ),
          const MinimalSectionHeader(
            'Activity',
            padding: EdgeInsets.fromLTRB(
              0,
              MinimalSpacing.s24,
              0,
              MinimalSpacing.s4,
            ),
          ),
          MinimalTimeline(
            entries: [
              if (_habits.kept(habit))
                MinimalActivity(
                  at: DateTime(2026, 8, 28, 7, 12),
                  text: 'Marked done',
                ),
              if (habit.record.isNotEmpty) ...[
                MinimalActivity(
                  at: DateTime(2026, 8, 27, 7, 40),
                  text: 'Marked done',
                  detail: 'note added',
                ),
                MinimalActivity(
                  at: DateTime(2026, 8, 26, 6, 58),
                  text: 'Marked done',
                ),
              ],
              MinimalActivity(
                at: DateTime(
                  habit.started.year,
                  habit.started.month,
                  habit.started.day,
                  9,
                  30,
                ),
                text: 'Created',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
