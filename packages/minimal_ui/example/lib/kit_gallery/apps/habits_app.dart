/// The package example's Habits app: Ritual, a habit tracker, as a whole
/// app in the window. Today (the day's list; on a laptop the open habit
/// beside it), every habit by group, and settings. Its happy path runs end
/// to end: `+` raises New habit (a sheet on a phone, a card over the page
/// from a tablet up), Create adds the habit to Today with an undo, a row
/// opens its page, Pause and Archive change it (Archive asks first), and
/// each change can be undone from its toast.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../habit_form.dart';
import '../habit_page.dart';
import '../habits.dart';
import '../host_bridge.dart'
    if (dart.library.js_interop) '../host_bridge_web.dart';
import '../kit_words.dart';
import '../today_page.dart';
import 'app_frame.dart';

/// Ritual, standing in the window, [gallery] its way out, opened at
/// [screen].
class KitHabitsApp extends StatefulWidget {
  const KitHabitsApp({super.key, required this.gallery, this.screen});

  final KitGalleryLink? gallery;

  /// The screen it opens at, one of [screens]; null opens Today.
  final String? screen;

  /// Today; a habit's page (on a laptop, beside Today); New habit raised
  /// over Today; the habit's page asking whether to archive it; every
  /// habit; settings.
  static const screens = [
    'today',
    'habit',
    'new-habit',
    'archive',
    'habits',
    'settings',
  ];

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
    name: ar('Ritual', 'طقوس'),
    gallery: widget.gallery,
    initial: switch (widget.screen) {
      'habits' => 1,
      'settings' => 2,
      _ => 0,
    },
    destinations: [
      (
        item: MinimalNavItem(LucideIcons.calendarCheck, ar('Today', 'اليوم')),
        root: (_) => _TodayRoot(habits: _habits, opening: widget.screen),
      ),
      (
        item: MinimalNavItem(LucideIcons.listChecks, ar('Habits', 'العادات')),
        root: (_) => _AllHabits(habits: _habits),
      ),
      (
        item: MinimalNavItem(LucideIcons.settings, ar('Settings', 'الإعدادات')),
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
      actionLabel: undo == null ? null : ar('Undo', 'تراجع'),
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

/// Opens [habit]'s page on [context]'s tab, its bar's way back to [parent];
/// [asking], asking whether to archive it.
void _open(
  BuildContext context,
  KitHabits habits,
  KitHabit habit,
  String parent, {
  bool asking = false,
}) {
  final navigator = Navigator.of(context);
  navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => KitHabitPage(
        habits: habits,
        id: habit.id,
        parent: parent,
        onArchived: navigator.pop,
        asking: asking,
      ),
    ),
  );
}

/// Today: the day's list; on a laptop, the open habit's page beside it.
class _TodayRoot extends StatefulWidget {
  const _TodayRoot({required this.habits, this.opening});

  final KitHabits habits;

  /// The screen the app opens at ([KitHabitsApp.screens]).
  final String? opening;

  @override
  State<_TodayRoot> createState() => _TodayRootState();
}

class _TodayRootState extends State<_TodayRoot> {
  String _selected = 'HAB-4';
  bool _wide = false;

  /// Whether the open habit's page, on its first build, asks whether to
  /// archive it.
  late bool _asking = widget.opening == 'archive';

  /// The list's width beside the detail: a phone's, so its rows read as
  /// they do there.
  static const double _listWidth = 400;

  @override
  void initState() {
    super.initState();
    final opening = widget.opening;
    if (opening == 'habit' || opening == 'archive' || opening == 'new-habit') {
      // Once Today stands: beside it on a laptop the habit is already open.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAt(opening!));
    }
  }

  void _openAt(String opening) {
    if (!mounted) return;
    final habits = widget.habits;
    if (opening == 'new-habit') return _newHabit(context, habits);
    final habit = habits.byId(_selected);
    if (_wide || habit == null) return;
    _asking = false;
    _open(
      context,
      habits,
      habit,
      ar('Today', 'اليوم'),
      asking: opening == 'archive',
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => _build(
      context,
      wide: KitListAndDetail.sideBySide(box.maxWidth, _listWidth),
    ),
  );

  Widget _build(BuildContext context, {required bool wide}) {
    _wide = wide;
    final habits = widget.habits;
    final list = KitTodayPage(
      habits: habits,
      leading: KitApp.leading(context),
      selected: wide ? _selected : null,
      onNew: () => _newHabit(context, habits),
      onOpen: (habit) => wide
          ? setState(() => _selected = habit.id)
          : _open(context, habits, habit, ar('Today', 'اليوم')),
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
                      asking: _asking,
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
        title: ar('Habits', 'العادات'),
        subtitle: '${habits.habits.length}',
        actions: [
          MinimalIconButton(
            LucideIcons.plus,
            label: ar('New habit', 'عادة جديدة'),
            variant: MinimalIconButtonVariant.primary,
            onPressed: () => _newHabit(context, habits),
          ),
        ],
      ),
      padding: EdgeInsets.zero,
      // One column of rows: the form measure on a wide window, as Settings.
      body: KitApp.measured(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (habits.habits.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: MinimalSpacing.s48,
                ),
                child: MinimalEmptyState(
                  icon: LucideIcons.listChecks,
                  title: ar('No habits yet', 'لا عادات بعد'),
                  body: ar(
                    'Start with one small thing you want to do every day.',
                    'ابدأ بشيء صغير تريد فعله كل يوم.',
                  ),
                  actionLabel: ar('New habit', 'عادة جديدة'),
                  onAction: () => _newHabit(context, habits),
                ),
              ),
            for (final group in kitHabitGroups)
              if (habits.habits.any((h) => h.group == group)) ...[
                MinimalSectionHeader(
                  group,
                  count:
                      '${habits.habits.where((h) => h.group == group).length}',
                ),
                MinimalListSection(
                  children: [
                    for (final habit in habits.habits.where(
                      (h) => h.group == group,
                    ))
                      MinimalListTile(
                        title: habit.name,
                        subtitle: [
                          habit.paused ? ar('Paused', 'متوقفة') : habit.repeat,
                          if (habit.reminder != null) habit.reminder!,
                        ].join(' · '),
                        muted: habit.paused,
                        chevron: true,
                        onTap: () => _open(
                          context,
                          habits,
                          habit,
                          ar('Habits', 'العادات'),
                        ),
                      ),
                  ],
                ),
              ],
          ],
        ),
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
  String _weekStarts = ar('Monday', 'الاثنين');

  Future<void> _export() async {
    final filename = 'ritual-${MinimalFormat.isoDate(kitHabitsToday)}.csv';
    try {
      await exportHabitsCsv(widget.habits.toCsv(), filename);
    } catch (_) {
      if (!mounted) return;
      showMinimalSnackBar(
        context,
        ar('Could not export habits', 'تعذر تصدير العادات'),
      );
      return;
    }
    if (!mounted) return;
    showMinimalSnackBar(
      context,
      kIsWeb
          ? ar('Download started: $filename', 'بدأ تنزيل $filename')
          : ar('Habits copied as CSV', 'نُسخت العادات بصيغة CSV'),
      icon: kIsWeb ? LucideIcons.download : LucideIcons.copy,
    );
  }

  Future<void> _erase() async {
    final sure =
        await showMinimalDialog<bool>(
          context,
          builder: (_) => MinimalDialog(
            title: ar('Erase every habit?', 'أتمحو كل العادات؟'),
            message: ar(
              'Today and Habits empty, and their records go with them.',
              'تفرغ «اليوم» و«العادات»، وتذهب سجلاتها معها.',
            ),
            confirmLabel: ar('Erase', 'امحُ'),
            cancelLabel: ar('Keep', 'أبقِها'),
            destructive: true,
          ),
        ) ??
        false;
    if (!sure || !mounted) return;
    final undo = widget.habits.clear();
    showMinimalSnackBar(
      context,
      ar('Every habit erased', 'مُحيت كل العادات'),
      icon: LucideIcons.trash2,
      actionLabel: ar('Undo', 'تراجع'),
      onAction: undo,
    );
  }

  @override
  Widget build(BuildContext context) => MinimalScaffold(
    topBar: MinimalAppBar(
      leading: KitApp.leading(context),
      title: ar('Settings', 'الإعدادات'),
    ),
    // A form keeps the form measure on a wide window, on the title's edge.
    body: KitApp.measured(_sections(context)),
  );

  Widget _sections(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MinimalFormSection(
        title: ar('Reminders', 'التذكيرات'),
        footer: ar(
          'Each habit reminds you at its own time.',
          'تذكّرك كل عادة في وقتها.',
        ),
        children: [
          MinimalFormRow(
            label: ar('Remind me', 'ذكّرني'),
            icon: LucideIcons.bell,
            trailing: MinimalSwitch(
              value: _reminders,
              label: ar('Remind me', 'ذكّرني'),
              onChanged: (on) => setState(() => _reminders = on),
            ),
          ),
          MinimalFormRow(
            label: ar('Sunday summary', 'ملخص الأحد'),
            icon: LucideIcons.mail,
            trailing: MinimalSwitch(
              value: _summary,
              label: ar('Sunday summary', 'ملخص الأحد'),
              onChanged: (on) => setState(() => _summary = on),
            ),
          ),
        ],
      ),
      const MinimalGap(MinimalSpacing.s24),
      MinimalFormSection(
        title: ar('Week', 'الأسبوع'),
        children: [
          MinimalFormRow(
            label: ar('Starts on', 'يبدأ في'),
            icon: LucideIcons.calendar,
            // At least 176 wide, and as wide as its words at large text.
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 176),
              child: MinimalSegmentedButton<String>(
                expand: false,
                segments: [
                  MinimalButtonSegment(
                    ar('Monday', 'الاثنين'),
                    ar('Monday', 'الاثنين'),
                  ),
                  MinimalButtonSegment(
                    ar('Sunday', 'الأحد'),
                    ar('Sunday', 'الأحد'),
                  ),
                ],
                value: _weekStarts,
                label: ar('Week starts on', 'يبدأ الأسبوع في'),
                small: true,
                onChanged: (day) => setState(() => _weekStarts = day),
              ),
            ),
          ),
        ],
      ),
      const MinimalGap(MinimalSpacing.s24),
      MinimalFormSection(
        title: ar('Data', 'البيانات'),
        children: [
          MinimalFormRow(
            label: kIsWeb
                ? ar('Export as CSV', 'تصدير بصيغة CSV')
                : ar('Copy as CSV', 'نسخ بصيغة CSV'),
            icon: kIsWeb ? LucideIcons.download : LucideIcons.copy,
            onPressed: _export,
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
            title: ar('Erase every habit', 'امحُ كل العادات'),
            icon: LucideIcons.trash2,
            destructive: true,
            onTap: _erase,
          ),
        ],
      ),
    ],
  );
}
