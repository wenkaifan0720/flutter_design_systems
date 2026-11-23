/// The gallery's shared habit page: one source for the Habit screen a phone
/// pushes off the list, for the detail a laptop stands beside it, and for
/// the example's Habits app.
library;

import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'habits.dart';
import 'kit_words.dart';

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
    this.asking = false,
  });

  final KitHabits? habits;
  final String id;

  /// The page it was opened from, for the bar's way back.
  final String? parent;

  /// What follows an archive: the phone's page pops; the laptop's detail
  /// shows another habit.
  final VoidCallback? onArchived;

  /// Whether the page opens asking whether to archive the habit.
  final bool asking;

  @override
  State<KitHabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<KitHabitPage> {
  late final KitHabits _own = KitHabits();
  KitHabits get _habits => widget.habits ?? _own;

  @override
  void initState() {
    super.initState();
    if (widget.asking) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final habit = _habits.byId(widget.id);
        if (mounted && habit != null) _archive(habit);
      });
    }
  }

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
            title: ar('Archive ${habit.name}?', 'أتؤرشف «${habit.name}»؟'),
            message: ar(
              'It leaves Today and stops reminding you. Its record is kept.',
              'تغادر «اليوم» ولن تذكّرك بعد الآن. يبقى سجلها محفوظًا.',
            ),
            confirmLabel: ar('Archive', 'أرشفة'),
            cancelLabel: ar('Keep', 'أبقِها'),
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
      ar('${habit.name} archived', 'أُرشفت «${habit.name}»'),
      icon: LucideIcons.archive,
      actionLabel: ar('Undo', 'تراجع'),
      onAction: undo,
    );
  }

  void _pause(KitHabit habit, bool paused) {
    if (habit.paused == paused) return;
    final undo = _habits.setPaused(habit, paused);
    showMinimalSnackBar(
      context,
      paused
          ? ar('${habit.name} paused', 'أُوقفت «${habit.name}»')
          : ar('${habit.name} resumed', 'استُؤنفت «${habit.name}»'),
      icon: paused ? LucideIcons.pause : LucideIcons.play,
      actionLabel: ar('Undo', 'تراجع'),
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
        // The default page it came from, in the gallery's language.
        parent: widget.parent == 'Today' ? ar('Today', 'اليوم') : widget.parent,
        subtitle: habit.id,
        actions: [
          MinimalIconButton(
            LucideIcons.star,
            label: ar('Favourite', 'مفضلة'),
            selected: habit.favourite,
            onPressed: () => _habits.toggleFavourite(habit),
          ),
          MinimalMenu.button(
            LucideIcons.ellipsis,
            label: ar('Habit actions', 'إجراءات العادة'),
            items: [
              MinimalMenuItem(
                habit.paused
                    ? ar('Resume', 'استئناف')
                    : ar('Pause', 'إيقاف مؤقت'),
                icon: habit.paused ? LucideIcons.play : LucideIcons.pause,
                onPressed: () => _pause(habit, !habit.paused),
              ),
              MinimalMenuItem(
                ar('Archive', 'أرشفة'),
                icon: LucideIcons.archive,
                isDestructiveAction: true,
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
                label: ar('Status', 'الحالة'),
                value: habit.paused
                    ? ar('Paused', 'متوقفة')
                    : ar('Active', 'نشطة'),
                tone: habit.paused ? MinimalTone.neutral : MinimalTone.success,
                items: [
                  MinimalMenuItem(
                    ar('Active', 'نشطة'),
                    selected: !habit.paused,
                    onPressed: () => _pause(habit, false),
                  ),
                  MinimalMenuItem(
                    ar('Paused', 'متوقفة'),
                    selected: habit.paused,
                    onPressed: () => _pause(habit, true),
                  ),
                ],
              ),
              MinimalProperty(
                icon: LucideIcons.repeat,
                label: ar('Repeats', 'التكرار'),
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
                label: ar('Reminder', 'التذكير'),
                value: habit.reminder ?? ar('None', 'لا شيء'),
                mono: habit.reminder != null,
              ),
              MinimalProperty(
                icon: LucideIcons.flame,
                label: ar('Streak', 'السلسلة'),
                value: kitDays(streak),
                detail: habit.best > streak
                    ? ar('best ${habit.best}d', 'الأفضل ${kitDays(habit.best)}')
                    : null,
                mono: true,
              ),
              MinimalProperty(
                icon: LucideIcons.calendar,
                label: ar('Started', 'البداية'),
                value: MinimalFormat.isoDate(habit.started),
                mono: true,
              ),
            ],
          ),
          MinimalSectionHeader(
            ar('Last 12 weeks', 'آخر 12 أسبوعًا'),
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
              ar(
                'No days yet. The record starts with the first day kept.',
                'لا أيام بعد. يبدأ السجل بأول يوم تلتزم به.',
              ),
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
                semanticLabel: ar(
                  '$kept of the last ${record.length} days kept',
                  'التُزم بها $kept من آخر ${record.length} يومًا',
                ),
              ),
            ),
          MinimalSectionHeader(
            ar('Activity', 'النشاط'),
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
                  text: ar('Marked done', 'عُلّمت منجزة'),
                ),
              if (habit.record.isNotEmpty) ...[
                MinimalActivity(
                  at: DateTime(2026, 8, 27, 7, 40),
                  text: ar('Marked done', 'عُلّمت منجزة'),
                  detail: ar('note added', 'أُضيفت ملاحظة'),
                ),
                MinimalActivity(
                  at: DateTime(2026, 8, 26, 6, 58),
                  text: ar('Marked done', 'عُلّمت منجزة'),
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
                text: ar('Created', 'أُنشئت'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
