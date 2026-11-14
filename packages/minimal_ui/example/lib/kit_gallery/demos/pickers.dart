/// Minimal's pickers: picker rows opening the anchored menu or a
/// selection sheet, date and time rows whose mono pills open a calendar or
/// the time columns in place (or a confirming sheet), the calendar and the
/// time columns inline, and the menu itself — actions with glyphs and mono
/// shortcuts, checked choices, a destructive group, a long-press context
/// menu.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The comparison page's Friday.
final DateTime _today = DateTime(2026, 8, 28);

const List<MinimalSelectOption<String>> _repeats = [
  MinimalSelectOption('daily', 'Every day', icon: LucideIcons.repeat),
  MinimalSelectOption('weekdays', 'Weekdays', icon: LucideIcons.briefcase),
  MinimalSelectOption('evening', 'Every evening', icon: LucideIcons.moon),
  MinimalSelectOption('weekly', 'Once a week', icon: LucideIcons.calendar),
  MinimalSelectOption(
    'custom',
    'Custom…',
    icon: LucideIcons.slidersHorizontal,
    enabled: false,
  ),
];

const List<MinimalSelectOption<String>> _parts = [
  MinimalSelectOption(
    'morning',
    'Morning',
    subtitle: 'Before 12:00 · Meditate, Morning run',
    icon: LucideIcons.sunrise,
  ),
  MinimalSelectOption(
    'afternoon',
    'Afternoon',
    subtitle: '12:00–18:00 · Drink water',
    icon: LucideIcons.sun,
  ),
  MinimalSelectOption(
    'evening',
    'Evening',
    subtitle: 'After 18:00 · Journal, Read 20 pages',
    icon: LucideIcons.moon,
  ),
  MinimalSelectOption(
    'anytime',
    'Any time',
    subtitle: 'Shows until it is done',
    icon: LucideIcons.infinity,
  ),
];

Widget kitPickersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Pickers & menu',
  sections: [
    kitSection(
      'Picker rows',
      children: [
        const _Schedule(),
        kitNote(
          'Repeats opens the anchored menu; Time of day a sheet whose '
          'options carry their explanations. A disabled option shows but '
          'cannot be chosen.',
        ),
      ],
    ),
    kitSection(
      'States',
      children: [
        MinimalFormSection(
          children: [
            MinimalSelect(
              label: 'Area',
              icon: LucideIcons.folder,
              value: null,
              options: _parts,
              prompt: 'None',
              onChanged: (_) {},
            ),
            const MinimalSelect(
              label: 'Owner',
              icon: LucideIcons.user,
              value: 'you',
              options: [MinimalSelectOption('you', 'You')],
            ),
          ],
        ),
      ],
    ),
    kitSection(
      'Dates and times',
      children: [
        const _Dates(),
        kitNote(
          'Each pill opens its own picker in place; Ends asks for Done in a '
          'sheet. Paused until has nothing to set while the habit runs, so '
          'it is disabled: the row dims as a whole.',
        ),
      ],
    ),
    kitSection(
      'Calendar',
      children: [
        _Inline(
          start: DateTime(2026, 8, 21),
          builder: (value, onChanged) => kitMonth(
            MinimalDatePicker(
              label: 'Started',
              value: value,
              mode: MinimalDatePickerMode.date,
              presentation: MinimalDatePickerPresentation.inline,
              today: _today,
              first: DateTime(2026, 8, 3),
              onChanged: onChanged,
            ),
          ),
        ),
        kitNote(
          'Weekdays and day numbers in mono, the choice on the accent, today '
          '(28 Aug) underlined; days before 3 Aug are out of range.',
        ),
      ],
    ),
    kitSection(
      'Time',
      children: [
        _Inline(
          start: DateTime(2026, 8, 28, 21, 30),
          builder: (value, onChanged) => MinimalDatePicker(
            label: 'Reminder',
            value: value,
            mode: MinimalDatePickerMode.time,
            presentation: MinimalDatePickerPresentation.wheel,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
    kitSection(
      'Date and time, inline',
      children: [
        _Inline(
          start: DateTime(2026, 9, 2, 7),
          builder: (value, onChanged) => kitMonth(
            MinimalDatePicker(
              label: 'Next check-in',
              value: value,
              presentation: MinimalDatePickerPresentation.inline,
              today: _today,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    ),
    kitSection(
      'Time · 12-hour clock, for an app that asks for it',
      children: [
        _Inline(
          start: DateTime(2026, 8, 28, 7),
          builder: (value, onChanged) => MinimalDatePicker(
            label: 'Wake-up',
            value: value,
            mode: MinimalDatePickerMode.time,
            presentation: MinimalDatePickerPresentation.wheel,
            use24HourFormat: false,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
    kitSection('Selection list', children: [const _PartList()]),
    kitSection(
      'Menu',
      children: [
        const _Menus(),
        kitNote(
          'Tap a trigger, or long-press the row for its actions (Shift+F10 '
          'from the keyboard). The arrow keys walk the items; Escape '
          'closes.',
        ),
      ],
    ),
  ],
);

/// A live schedule: menu and sheet picker rows, and a disabled one.
class _Schedule extends StatefulWidget {
  const _Schedule();

  @override
  State<_Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<_Schedule> {
  String _repeat = 'evening';
  String _part = 'evening';

  @override
  Widget build(BuildContext context) => MinimalFormSection(
    children: [
      MinimalSelect(
        label: 'Repeats',
        icon: LucideIcons.repeat,
        value: _repeat,
        options: _repeats,
        onChanged: (v) => setState(() => _repeat = v),
      ),
      MinimalSelect(
        label: 'Time of day',
        icon: LucideIcons.clock,
        value: _part,
        options: _parts,
        presentation: MinimalSelectPresentation.sheet,
        onChanged: (v) => setState(() => _part = v),
      ),
    ],
  );
}

/// Live date rows: a day, a clock time, both (confirmed in a sheet), and
/// a disabled one.
class _Dates extends StatefulWidget {
  const _Dates();

  @override
  State<_Dates> createState() => _DatesState();
}

class _DatesState extends State<_Dates> {
  DateTime _starts = DateTime(2026, 6, 2);
  DateTime _reminder = DateTime(2026, 8, 28, 21, 30);
  DateTime _ends = DateTime(2026, 12, 31, 23, 0);

  @override
  Widget build(BuildContext context) => MinimalFormSection(
    children: [
      MinimalDatePicker(
        label: 'Starts',
        icon: LucideIcons.calendar,
        value: _starts,
        mode: MinimalDatePickerMode.date,
        today: _today,
        onChanged: (v) => setState(() => _starts = v),
      ),
      MinimalDatePicker(
        label: 'Reminder',
        icon: LucideIcons.bell,
        value: _reminder,
        mode: MinimalDatePickerMode.time,
        onChanged: (v) => setState(() => _reminder = v),
      ),
      MinimalDatePicker(
        label: 'Ends',
        icon: LucideIcons.flag,
        value: _ends,
        today: _today,
        confirmSelection: true,
        onChanged: (v) => setState(() => _ends = v),
      ),
      MinimalDatePicker(
        label: 'Paused until',
        icon: LucideIcons.pause,
        value: DateTime(2026, 9, 14, 7, 0),
      ),
    ],
  );
}

/// Holds one date value for an inline picker.
class _Inline extends StatefulWidget {
  const _Inline({required this.start, required this.builder});

  final DateTime start;
  final Widget Function(DateTime value, ValueChanged<DateTime> onChanged)
  builder;

  @override
  State<_Inline> createState() => _InlineState();
}

class _InlineState extends State<_Inline> {
  late DateTime _value = widget.start;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

/// The sheet's list on the page, as a preference page would hold it.
class _PartList extends StatefulWidget {
  const _PartList();

  @override
  State<_PartList> createState() => _PartListState();
}

class _PartListState extends State<_PartList> {
  String _part = 'morning';

  @override
  // Edge to edge on a phone, its words on the gutter, as the Selection
  // page's lists run; on the column's keylines in a wider window.
  Widget build(BuildContext context) => KitBleed(
    child: Builder(
      builder: (context) => MinimalSelectionList(
        value: _part,
        options: _parts,
        onChanged: (v) => setState(() => _part = v),
        padding: KitBleed.inset(context),
      ),
    ),
  );
}

/// Menu triggers: an overflow square of actions, a sort pill of checked
/// choices, and a row with a long-press context menu.
class _Menus extends StatefulWidget {
  const _Menus();

  @override
  State<_Menus> createState() => _MenusState();
}

class _MenusState extends State<_Menus> {
  String _sort = 'Streak';

  /// A chosen action says what it did, as the app would.
  void _did(String action) => showMinimalSnackBar(context, switch (action) {
    'Open' => 'Morning run opens its page',
    'Mark done' => 'Morning run marked done',
    'Edit' => 'Editing Morning run',
    'Duplicate' => 'Morning run duplicated',
    'Archive' => 'Morning run archived',
    _ => 'Morning run deleted',
  });

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final actions = [
      MinimalMenuItem(
        'Mark done',
        icon: LucideIcons.circleCheck,
        shortcut: 'D',
        onPressed: () => _did('Mark done'),
      ),
      MinimalMenuItem(
        'Edit',
        icon: LucideIcons.pencil,
        shortcut: 'E',
        onPressed: () => _did('Edit'),
      ),
      MinimalMenuItem(
        'Duplicate',
        icon: LucideIcons.copy,
        shortcut: 'Alt D',
        onPressed: () => _did('Duplicate'),
      ),
      const MinimalMenuItem('Move to…', icon: LucideIcons.folderInput),
      MinimalMenuItem(
        'Archive',
        icon: LucideIcons.archive,
        startsGroup: true,
        onPressed: () => _did('Archive'),
      ),
      MinimalMenuItem(
        'Delete',
        icon: LucideIcons.trash2,
        destructive: true,
        shortcut: 'Del',
        onPressed: () => _did('Delete'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        kitRow([
          MinimalMenu.button(
            LucideIcons.ellipsis,
            label: 'Habit actions',
            items: actions,
          ),
          MinimalMenu.button(
            LucideIcons.arrowDownUp,
            text: 'Sort: $_sort',
            label: 'Sort habits',
            items: [
              for (final sort in const ['Streak', 'Name', 'Time of day'])
                MinimalMenuItem(
                  sort,
                  selected: sort == _sort,
                  onPressed: () => setState(() => _sort = sort),
                ),
            ],
          ),
        ]),
        const MinimalGap(MinimalSpacing.s12),
        // The dimmed trigger is a state, so it stands on its own line with
        // its words rather than as a third look in the row above.
        Row(
          children: [
            const MinimalMenu.button(
              LucideIcons.ellipsisVertical,
              label: 'No actions',
              items: [],
            ),
            const MinimalGap(MinimalSpacing.s12),
            Expanded(
              child: kitNote('With nothing to offer, the trigger dims.'),
            ),
          ],
        ),
        const MinimalGap(MinimalSpacing.s12),
        // A lone row stands between two rules, as a list of one: edge to
        // edge on a phone, as every list on the page.
        KitBleed(
          child: Builder(
            builder: (context) => Container(
              decoration: BoxDecoration(
                border: Border(top: t.rule, bottom: t.rule),
              ),
              child: MinimalListSection(
                gutter: false,
                children: [
                  MinimalMenu(
                    label: 'Morning run actions',
                    trigger: MinimalMenuTrigger.longPress,
                    items: actions,
                    child: MinimalListTile(
                      leading: const MinimalStatusIcon(MinimalTaskStatus.done),
                      title: 'Morning run',
                      meta: '12d',
                      // A done row steps back, as it does in every list.
                      muted: true,
                      padding: KitBleed.inset(context),
                      onTap: () => _did('Open'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style. The menu's open card has no public face,
// so MinimalMenu is seen live only (metadata.yaml).

/// The current choice over its up-down chevron: it opens the anchored menu.
Widget kitSpecimenPickerRowMenu() => _Body(
  child: MinimalFormSection(
    children: [
      MinimalSelect(
        label: 'Repeats',
        icon: LucideIcons.repeat,
        value: 'evening',
        options: _repeats,
        onChanged: (_) {},
      ),
    ],
  ),
);

/// A longer set that opens in a sheet, with its forward chevron.
Widget kitSpecimenPickerRowSheet() => _Body(
  child: MinimalFormSection(
    children: [
      MinimalSelect(
        label: 'Time of day',
        icon: LucideIcons.clock,
        value: 'morning',
        options: _parts,
        presentation: MinimalSelectPresentation.sheet,
        onChanged: (_) {},
      ),
    ],
  ),
);

/// Options with their explanations, the chosen one checked.
Widget kitSpecimenSelectionListParts() => _Body(
  child: MinimalSelectionList(
    value: 'morning',
    options: _parts,
    onChanged: (_) {},
  ),
);

/// The compact row: the date and the time as mono pills.
Widget kitSpecimenDatePickerCompact() => _Body(
  child: MinimalFormSection(
    children: [
      MinimalDatePicker(
        label: 'Starts',
        icon: LucideIcons.calendar,
        value: DateTime(2026, 9, 1, 7, 0),
        today: _today,
        onChanged: (_) {},
      ),
    ],
  ),
);

/// The month calendar in place, the choice on the accent, today underlined.
Widget kitSpecimenDatePickerInline() => MinimalDatePicker(
  label: 'Started',
  value: DateTime(2026, 8, 21),
  mode: MinimalDatePickerMode.date,
  presentation: MinimalDatePickerPresentation.inline,
  today: _today,
  first: DateTime(2026, 8, 3),
  onChanged: (_) {},
);

/// The hour and minute columns alone.
Widget kitSpecimenDatePickerWheel() => MinimalDatePicker(
  label: 'Reminder',
  value: DateTime(2026, 8, 28, 21, 30),
  mode: MinimalDatePickerMode.time,
  presentation: MinimalDatePickerPresentation.wheel,
  onChanged: (_) {},
);

/// Lays a specimen out as a scrolling page body does: its own height,
/// however tall the stage.
class _Body extends StatelessWidget {
  const _Body({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      UnconstrainedBox(constrainedAxis: Axis.horizontal, child: child);
}
