/// Swipe actions on dense habit rows: the revealed squares in every tone,
/// rows open at rest to show the register, live rows to drag (both edges,
/// full swipe), and swipe-to-delete with the page's undo toast.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitSwipeDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Swipe',
  sections: [
    kitSection(
      'Revealed',
      children: [
        _List(
          rows: [
            MinimalSwipeActions(
              initiallyOpen: true,
              trailing: [
                MinimalSwipeAction(
                  'Delete',
                  icon: LucideIcons.trash2,
                  destructive: true,
                  onPressed: () {},
                ),
                MinimalSwipeAction(
                  'Snooze',
                  icon: LucideIcons.alarmClock,
                  tone: MinimalTone.warning,
                  onPressed: () {},
                ),
              ],
              child: const _HabitRow(_morningRun),
            ),
            MinimalSwipeActions(
              initiallyOpen: true,
              leading: [
                MinimalSwipeAction(
                  'Done',
                  icon: LucideIcons.check,
                  tone: MinimalTone.success,
                  onPressed: () {},
                ),
              ],
              child: const _HabitRow(_drinkWater, last: true),
            ),
          ],
        ),
      ],
    ),
    kitSection(
      'Tones',
      children: [
        // Every tone on a real row, a tray of one or two per row, so each
        // open row still names its habit beside its squares.
        _List(
          rows: [
            for (final (i, (habit, leading, actions)) in _tones.indexed)
              MinimalSwipeActions(
                initiallyOpen: true,
                leading: leading ? _actions(actions) : const [],
                trailing: leading ? const [] : _actions(actions),
                child: _HabitRow(habit, last: i == _tones.length - 1),
              ),
          ],
        ),
        kitNote(
          'An action with a status wears its tone: Delete in red, Snooze in '
          'amber, Undo in green. Pin is in ink, and More stays quiet.',
        ),
      ],
    ),
    kitSection(
      'Drag a row',
      children: [
        const _LiveList(),
        kitNote(
          'These rows rest closed: drag one sideways. Done or Undo waits '
          'under the leading edge, Snooze and Delete under the trailing; '
          'the last row also acts on a full swipe.',
        ),
      ],
    ),
    kitSection(
      'Swipe to delete',
      children: [
        const _DismissList(),
        kitNote(
          'Swipe a row off from the trailing edge; the toast offers it back.',
        ),
      ],
    ),
  ],
);

/// The tone specimens: a row, the edge its tray opens from (true: the
/// leading edge), and its actions. Actions list outward from the row's
/// edge, so a destructive one — first — lands at the far edge.
const List<(_Habit, bool, List<(String, IconData, MinimalTone)>)> _tones = [
  (
    _journal,
    false,
    [
      ('Delete', LucideIcons.trash2, MinimalTone.destructive),
      ('More', LucideIcons.ellipsis, MinimalTone.neutral),
    ],
  ),
  (_plants, false, [('Snooze', LucideIcons.alarmClock, MinimalTone.warning)]),
  (
    _meditate,
    true,
    [
      ('Undo', LucideIcons.undo2Dir, MinimalTone.success),
      ('Pin', LucideIcons.pin, MinimalTone.primary),
    ],
  ),
];

List<MinimalSwipeAction> _actions(
  List<(String, IconData, MinimalTone)> specs,
) => [
  for (final (label, icon, tone) in specs)
    MinimalSwipeAction(label, icon: icon, tone: tone, onPressed: () {}),
];

typedef _Habit = ({String id, String name, int streak, bool done});

const _Habit _meditate = (id: 'HAB-1', name: 'Meditate', streak: 4, done: true);
const _Habit _morningRun = (
  id: 'HAB-4',
  name: 'Morning run',
  streak: 12,
  done: true,
);
const _Habit _drinkWater = (
  id: 'HAB-2',
  name: 'Drink water',
  streak: 10,
  done: false,
);
const _Habit _journal = (id: 'HAB-3', name: 'Journal', streak: 3, done: false);
const _Habit _read = (
  id: 'HAB-5',
  name: 'Read 20 pages',
  streak: 6,
  done: true,
);
const _Habit _plants = (
  id: 'HAB-6',
  name: 'Water the plants',
  streak: 2,
  done: false,
);

/// Rows drag both ways: leading Done, trailing Snooze and Delete; the last
/// row also completes on a full swipe. Each action says what it did in a
/// toast, as the app would.
class _LiveList extends StatefulWidget {
  const _LiveList();

  @override
  State<_LiveList> createState() => _LiveListState();
}

class _LiveListState extends State<_LiveList> {
  void _say(String what) => showMinimalSnackBar(context, what);

  @override
  Widget build(BuildContext context) {
    final habits = [_meditate, _read, _plants];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _List(
          rows: [
            for (final (i, habit) in habits.indexed)
              MinimalSwipeActions(
                allowsFullSwipe: i == habits.length - 1,
                leading: [
                  MinimalSwipeAction(
                    habit.done ? 'Undo' : 'Done',
                    icon: habit.done ? LucideIcons.undo2Dir : LucideIcons.check,
                    tone: MinimalTone.success,
                    onPressed: () => _say(
                      habit.done
                          ? '${habit.name}: marked not done'
                          : '${habit.name}: marked done',
                    ),
                  ),
                ],
                trailing: [
                  MinimalSwipeAction(
                    'Delete',
                    icon: LucideIcons.trash2,
                    destructive: true,
                    onPressed: () => _say('${habit.name}: deleted'),
                  ),
                  MinimalSwipeAction(
                    'Snooze',
                    icon: LucideIcons.alarmClock,
                    tone: MinimalTone.warning,
                    onPressed: () => _say('${habit.name}: snoozed to 21:30'),
                  ),
                ],
                child: _HabitRow(habit, last: i == habits.length - 1),
              ),
          ],
        ),
      ],
    );
  }
}

/// Swipe-to-delete from the trailing edge; the page keeps the record and
/// offers it back through the toast's undo.
class _DismissList extends StatefulWidget {
  const _DismissList();

  @override
  State<_DismissList> createState() => _DismissListState();
}

class _DismissListState extends State<_DismissList> {
  final List<_Habit> _habits = [_meditate, _morningRun, _drinkWater, _journal];

  void _remove(_Habit habit) {
    final at = _habits.indexOf(habit);
    setState(() => _habits.remove(habit));
    showMinimalSnackBar(
      context,
      '${habit.name} deleted',
      icon: LucideIcons.trash2,
      actionLabel: 'Undo',
      onAction: () => setState(() => _habits.insert(at, habit)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_habits.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          kitNote('Every habit is gone.'),
          const MinimalGap(MinimalSpacing.s8),
          Align(
            alignment: Alignment.centerLeft,
            child: MinimalButton(
              'Restore',
              variant: MinimalButtonVariant.secondary,
              size: MinimalButtonSize.small,
              onPressed: () => setState(
                () => _habits.addAll([
                  _meditate,
                  _morningRun,
                  _drinkWater,
                  _journal,
                ]),
              ),
            ),
          ),
        ],
      );
    }
    return _List(
      rows: [
        for (final (i, habit) in _habits.indexed)
          MinimalDismissible(
            key: ValueKey(habit.id),
            label: i == 0 ? 'Delete' : 'Remove',
            onDismissed: () => _remove(habit),
            child: _HabitRow(habit, last: i == _habits.length - 1),
          ),
      ],
    );
  }
}

/// A full-bleed list: a bare run of rows between a hairline above and one
/// below — no card, no radius, so the revealed squares keep their square
/// corners. Edge to edge across a phone's page; in a wider window it stands
/// in the column, its rules and squares ending on the column's edges.
class _List extends StatelessWidget {
  const _List({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // A Container, not a bare DecoratedBox: it insets the rows inside the
    // rules, so their own ground never paints over them.
    return KitBleed(
      child: Container(
        decoration: BoxDecoration(
          color: t.background,
          border: Border(top: t.rule, bottom: t.rule),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }
}

/// A Today row: the status glyph, the name, the mono streak.
class _HabitRow extends StatelessWidget {
  const _HabitRow(this.habit, {this.last = false});

  final _Habit habit;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // The row keeps the gutter on both sides, on a phone and in a wider
    // window's column alike, so a revealed action never butts against its
    // streak.
    return Container(
      height: t.rowHeight,
      padding: MinimalInsets.gutter,
      decoration: BoxDecoration(border: last ? null : Border(bottom: t.rule)),
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
          Text(habit.id, style: t.mono.c(t.mutedForeground)),
          const MinimalGap(MinimalSpacing.s12),
          SizedBox(
            width: 30,
            child: Text(
              '${habit.streak}d',
              textAlign: TextAlign.right,
              style: t.mono.c(t.mutedForeground),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style. MinimalDismissible has no resting open
// state, so it is seen live only (metadata.yaml).

/// A row held open on its trailing tray: Delete and Snooze.
Widget kitSpecimenSwipeActionsTrailing() => _Body(
  child: _List(
    rows: [
      MinimalSwipeActions(
        initiallyOpen: true,
        trailing: [
          MinimalSwipeAction(
            'Delete',
            icon: LucideIcons.trash2,
            destructive: true,
            onPressed: () {},
          ),
          MinimalSwipeAction(
            'Snooze',
            icon: LucideIcons.alarmClock,
            tone: MinimalTone.warning,
            onPressed: () {},
          ),
        ],
        child: const _HabitRow(_morningRun, last: true),
      ),
    ],
  ),
);

/// A row held open on its leading tray: Done, in the success tone.
Widget kitSpecimenSwipeActionsLeading() => _Body(
  child: _List(
    rows: [
      MinimalSwipeActions(
        initiallyOpen: true,
        leading: [
          MinimalSwipeAction(
            'Done',
            icon: LucideIcons.check,
            tone: MinimalTone.success,
            onPressed: () {},
          ),
        ],
        child: const _HabitRow(_drinkWater, last: true),
      ),
    ],
  ),
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
