/// The package example's Habits app: Ritual, a habit tracker, as a whole
/// app in the window. Today (the day's list; on a laptop the open habit
/// beside it), every habit by group, and settings. Its happy path runs end
/// to end: `+` raises New habit (a sheet on a phone, a card over the page
/// from a tablet up), Create adds the habit to Today with an undo, a row
/// opens its page, Pause and Archive change it (Archive asks first), and
/// each change can be undone from its toast.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../habit_form.dart';
import '../habit_page.dart';
import '../habits.dart';
import '../today_page.dart';
import 'app_frame.dart';

/// Ritual, standing in the window, [gallery] its way out.
class KitHabitsApp extends StatefulWidget {
  const KitHabitsApp({super.key, required this.gallery});

  final KitGalleryLink? gallery;

  @override
  State<KitHabitsApp> createState() => _KitHabitsAppState();
}

class _KitHabitsAppState extends State<KitHabitsApp> {
  final _habits = KitHabits();

  @override
  void dispose() {
    _habits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitApp(
    name: 'Ritual',
    gallery: widget.gallery,
    destinations: [
      (
        item: const MinimalNavItem(LucideIcons.calendarCheck, 'Today'),
        root: (_) => _TodayRoot(habits: _habits),
      ),
      (
        item: const MinimalNavItem(LucideIcons.listChecks, 'Habits'),
        root: (_) => _AllHabits(habits: _habits),
      ),
      (
        item: const MinimalNavItem(LucideIcons.settings, 'Settings'),
        root: (_) => _Settings(habits: _habits),
      ),
    ],
  );
}

/// Raises New habit over the app from [context]: a sheet on a phone, the
/// card centred over the page where the window is wide. Its toast, with the
/// undo, comes from [context]'s page, above the tab bar.
void _newHabit(BuildContext context, KitHabits habits) {
  Widget page(BuildContext _) => KitNewHabitPage(
    habits: habits,
    onCreated: (message, undo) => showMinimalSnackBar(
      context,
      message,
      icon: LucideIcons.check,
      actionLabel: undo == null ? null : 'Undo',
      onAction: undo,
    ),
  );
  final width = MediaQuery.sizeOf(context).width;
  Navigator.of(context, rootNavigator: true).push(
    MinimalBottomSheet.centresAt(width)
        ? MinimalBottomSheet.centredRoute<void>(context: context, builder: page)
        : MinimalBottomSheet.pageRoute<void>(context: context, builder: page),
  );
}

/// Opens [habit]'s page on [context]'s tab, its bar's way back to [parent].
void _open(
  BuildContext context,
  KitHabits habits,
  KitHabit habit,
  String parent,
) {
  final navigator = Navigator.of(context);
  navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => KitHabitPage(
        habits: habits,
        id: habit.id,
        parent: parent,
        onArchived: navigator.pop,
      ),
    ),
  );
}

/// Today: the day's list; on a laptop, the open habit's page beside it.
class _TodayRoot extends StatefulWidget {
  const _TodayRoot({required this.habits});

  final KitHabits habits;

  @override
  State<_TodayRoot> createState() => _TodayRootState();
}

class _TodayRootState extends State<_TodayRoot> {
  String _selected = 'HAB-4';

  /// The list's width beside the detail: a phone's, so its rows read as
  /// they do there.
  static const double _listWidth = 400;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => _build(
      context,
      wide: KitListAndDetail.sideBySide(box.maxWidth, _listWidth),
    ),
  );

  Widget _build(BuildContext context, {required bool wide}) {
    final habits = widget.habits;
    final list = KitTodayPage(
      habits: habits,
      leading: KitApp.leading(context),
      selected: wide ? _selected : null,
      onNew: () => _newHabit(context, habits),
      onOpen: (habit) => wide
          ? setState(() => _selected = habit.id)
          : _open(context, habits, habit, 'Today'),
    );
    if (!wide) return list;
    return ListenableBuilder(
      listenable: habits,
      builder: (context, _) {
        final t = context.minimalTheme;
        final shown = habits.byId(_selected) ?? habits.habits.firstOrNull;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: _listWidth, child: list),
            MinimalDivider.vertical(space: t.hairline),
            Expanded(
              child: shown == null
                  ? const MinimalScaffold(body: SizedBox.shrink())
                  : KitHabitPage(
                      key: ValueKey(shown.id),
                      habits: habits,
                      id: shown.id,
                      parent: null,
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Every habit, by time of day: what it is, how often and when it reminds.
class _AllHabits extends StatelessWidget {
  const _AllHabits({required this.habits});

  final KitHabits habits;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: habits,
    builder: (context, _) => MinimalScaffold(
      topBar: MinimalAppBar(
        leading: KitApp.leading(context),
        title: 'Habits',
        subtitle: '${habits.habits.length}',
        actions: [
          MinimalIconButton(
            LucideIcons.plus,
            label: 'New habit',
            variant: MinimalIconButtonVariant.primary,
            onPressed: () => _newHabit(context, habits),
          ),
        ],
      ),
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (habits.habits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s48),
              child: MinimalEmptyState(
                icon: LucideIcons.listChecks,
                title: 'No habits yet',
                body: 'Start with one small thing you want to do every day.',
                actionLabel: 'New habit',
                onAction: () => _newHabit(context, habits),
              ),
            ),
          for (final group in kitHabitGroups)
            if (habits.habits.any((h) => h.group == group)) ...[
              MinimalSectionHeader(
                group,
                count: '${habits.habits.where((h) => h.group == group).length}',
              ),
              MinimalListSection(
                children: [
                  for (final habit in habits.habits.where(
                    (h) => h.group == group,
                  ))
                    MinimalListTile(
                      title: habit.name,
                      subtitle: [
                        habit.paused ? 'Paused' : habit.repeat,
                        if (habit.reminder != null) habit.reminder!,
                      ].join(' · '),
                      muted: habit.paused,
                      chevron: true,
                      onTap: () => _open(context, habits, habit, 'Habits'),
                    ),
                ],
              ),
            ],
        ],
      ),
    ),
  );
}

/// The tracker's settings: reminders, the week, and the data.
class _Settings extends StatefulWidget {
  const _Settings({required this.habits});

  final KitHabits habits;

  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  bool _reminders = true;
  bool _summary = false;
  String _weekStarts = 'Monday';

  Future<void> _erase() async {
    final sure =
        await showMinimalDialog<bool>(
          context,
          builder: (_) => const MinimalDialog(
            title: 'Erase every habit?',
            message: 'Today and Habits empty, and their records go with them.',
            confirmLabel: 'Erase',
            cancelLabel: 'Keep',
            destructive: true,
          ),
        ) ??
        false;
    if (!sure || !mounted) return;
    final undo = widget.habits.clear();
    showMinimalSnackBar(
      context,
      'Every habit erased',
      icon: LucideIcons.trash2,
      actionLabel: 'Undo',
      onAction: undo,
    );
  }

  @override
  Widget build(BuildContext context) => MinimalScaffold(
    topBar: MinimalAppBar(leading: KitApp.leading(context), title: 'Settings'),
    // A form keeps the form measure on a wide window, on the title's edge:
    // each switch near enough its label to read as its pair.
    body: Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MinimalLayout.formWidth(context)),
        child: _sections(context),
      ),
    ),
  );

  Widget _sections(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MinimalFormSection(
        title: 'Reminders',
        footer: 'Each habit reminds you at its own time.',
        children: [
          MinimalFormRow(
            label: 'Remind me',
            icon: LucideIcons.bell,
            trailing: MinimalSwitch(
              value: _reminders,
              label: 'Remind me',
              onChanged: (on) => setState(() => _reminders = on),
            ),
          ),
          MinimalFormRow(
            label: 'Sunday summary',
            icon: LucideIcons.mail,
            trailing: MinimalSwitch(
              value: _summary,
              label: 'Sunday summary',
              onChanged: (on) => setState(() => _summary = on),
            ),
          ),
        ],
      ),
      const MinimalGap(MinimalSpacing.s24),
      MinimalFormSection(
        title: 'Week',
        children: [
          MinimalFormRow(
            label: 'Starts on',
            icon: LucideIcons.calendar,
            trailing: SizedBox(
              width: 176,
              child: MinimalSegmentedButton<String>(
                segments: const [
                  MinimalButtonSegment('Monday', 'Monday'),
                  MinimalButtonSegment('Sunday', 'Sunday'),
                ],
                value: _weekStarts,
                label: 'Week starts on',
                small: true,
                onChanged: (day) => setState(() => _weekStarts = day),
              ),
            ),
          ),
        ],
      ),
      const MinimalGap(MinimalSpacing.s24),
      MinimalFormSection(
        title: 'Data',
        children: [
          MinimalFormRow(
            label: 'Export as CSV',
            icon: LucideIcons.download,
            onPressed: () => showMinimalSnackBar(
              context,
              'ritual-2026-08-28.csv saved to Downloads',
              icon: LucideIcons.download,
            ),
          ),
        ],
      ),
      // The one destructive act: quiet, last, after space; its dialog
      // carries the solid button. Its row stands on the sections' edge.
      const MinimalGap(MinimalSpacing.s48),
      MinimalListSection(
        gutter: false,
        children: [
          MinimalListTile(
            title: 'Erase every habit',
            icon: LucideIcons.trash2,
            destructive: true,
            onTap: _erase,
          ),
        ],
      ),
    ],
  );
}
