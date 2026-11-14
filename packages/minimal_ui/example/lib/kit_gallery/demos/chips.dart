/// Minimal's filter pills: a single-choice status filter with counts
/// that filters a live list (and shows the empty result), multi-select
/// pills with glyphs, every state, and a long set wrapping in its row.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitChipsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Chips',
  sections: [
    kitSection('Filter · single choice', children: const [_StatusFilter()]),
    kitSection('Multi-select · with glyphs', children: const [_Tags()]),
    kitSection(
      'States',
      children: [
        MinimalChipRow(
          children: [
            MinimalChip('Idle', onPressed: () {}),
            MinimalChip('Selected', selected: true, onPressed: () {}),
            MinimalChip('Count', count: 12, onPressed: () {}),
            MinimalChip('Glyph', icon: LucideIcons.sun, onPressed: () {}),
            const MinimalChip('Disabled'),
            const MinimalChip('Disabled on', selected: true),
          ],
        ),
      ],
    ),
    kitSection(
      'Wrapping row',
      children: [
        MinimalChipRow(children: _dayChips(_weekdays)),
        kitNote('A chip row wraps; it never overflows the phone.'),
      ],
    ),
  ],
);

const List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Monday to Friday, by their places in [_days].
const Set<int> _weekdays = {0, 1, 2, 3, 4};

/// The days a habit repeats on as chips: each day, then the words for a
/// set of days, picked when [on] is exactly that set (Mon to Fri picked
/// picks Weekdays too).
List<Widget> _dayChips(Set<int> on) {
  bool exactly(Set<int> days) =>
      on.length == days.length && on.containsAll(days);
  return [
    for (final (i, day) in _days.indexed)
      MinimalChip(day, selected: on.contains(i), onPressed: () {}),
    for (final (label, days) in const [
      ('Weekdays', _weekdays),
      ('Weekends', {5, 6}),
      ('Every day', {0, 1, 2, 3, 4, 5, 6}),
    ])
      MinimalChip(label, selected: exactly(days), onPressed: () {}),
  ];
}

enum _Status { all, open, done, paused, archived }

typedef _Habit = ({String name, _Status status, String streak});

const List<_Habit> _habits = [
  (name: 'Meditate', status: _Status.done, streak: '4d'),
  (name: 'Morning run', status: _Status.done, streak: '12d'),
  (name: 'Drink water', status: _Status.open, streak: '10d'),
  (name: 'Journal', status: _Status.open, streak: '3d'),
  (name: 'Read 20 pages', status: _Status.done, streak: '6d'),
  (name: 'Water the plants', status: _Status.paused, streak: '2d'),
];

/// Ritual's status filter: one choice at a time, counts from the data, and
/// the list under it follows — Archived matches nothing.
class _StatusFilter extends StatefulWidget {
  const _StatusFilter();

  @override
  State<_StatusFilter> createState() => _StatusFilterState();
}

class _StatusFilterState extends State<_StatusFilter> {
  _Status _on = _Status.all;

  List<_Habit> _matching(_Status s) =>
      s == _Status.all ? _habits : _habits.where((h) => h.status == s).toList();

  String _name(_Status s) =>
      s.name.substring(0, 1).toUpperCase() + s.name.substring(1);

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final shown = _matching(_on);
    // The page's one list row, as the filter bar's list draws the same
    // habits: it grows by what larger text adds to a 16 px line, as the
    // kit's rows do, so a label never touches its rules.
    final row = t.rowHeight + MediaQuery.textScalerOf(context).scale(16) - 16;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalChipRow(
          children: [
            for (final s in _Status.values)
              MinimalChip(
                _name(s),
                count: _matching(s).length,
                selected: s == _on,
                onPressed: () => setState(() => _on = s),
              ),
          ],
        ),
        const MinimalGap(MinimalSpacing.s12),
        // The rows stand as every list on the page does: edge to edge on a
        // phone, their words on the gutter; on the column's keylines in a
        // wider window.
        KitBleed(
          child: Builder(builder: (context) => _list(context, t, shown, row)),
        ),
      ],
    );
  }

  Widget _list(
    BuildContext context,
    MinimalThemeData t,
    List<_Habit> shown,
    double row,
  ) {
    final inset = KitBleed.inset(context);
    return Container(
      decoration: BoxDecoration(border: Border(top: t.rule)),
      child: shown.isEmpty
          ? Padding(
              padding: MinimalInsets.vertical16,
              child: Column(
                children: [
                  Text('No archived habits', style: t.body.medium),
                  const MinimalGap(MinimalSpacing.s4),
                  Text(
                    'Archive a habit to keep its history without it.',
                    style: t.bodySmall.c(t.mutedForeground),
                    textAlign: TextAlign.center,
                  ),
                  const MinimalGap(MinimalSpacing.s12),
                  MinimalButton(
                    'Show all',
                    size: MinimalButtonSize.small,
                    variant: MinimalButtonVariant.secondary,
                    onPressed: () => setState(() => _on = _Status.all),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (final h in shown)
                  Container(
                    constraints: BoxConstraints(minHeight: row),
                    padding: inset,
                    decoration: BoxDecoration(border: Border(bottom: t.rule)),
                    child: Row(
                      children: [
                        MinimalStatusIcon(switch (h.status) {
                          _Status.done => MinimalTaskStatus.done,
                          _Status.paused => MinimalTaskStatus.paused,
                          _ => MinimalTaskStatus.todo,
                        }),
                        const MinimalGap(10),
                        // A done or paused habit steps back to the muted
                        // ink, as the filter bar's list draws it.
                        Expanded(
                          child: Text(
                            h.name,
                            style: t.body.medium.c(
                              h.status == _Status.open
                                  ? t.foreground
                                  : t.mutedForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(h.streak, style: t.mono.c(t.mutedForeground)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Multi-select pills with glyphs: the times of day a habit can belong to.
class _Tags extends StatefulWidget {
  const _Tags();

  @override
  State<_Tags> createState() => _TagsState();
}

class _TagsState extends State<_Tags> {
  final Set<String> _on = {'Evening'};

  static const _tags = [
    ('Morning', LucideIcons.sunrise),
    ('Afternoon', LucideIcons.sun),
    ('Evening', LucideIcons.moon),
    ('Anytime', LucideIcons.clock),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalChipRow(
          children: [
            for (final (name, icon) in _tags)
              MinimalChip(
                name,
                icon: icon,
                selected: _on.contains(name),
                onPressed: () => setState(() {
                  if (!_on.remove(name)) _on.add(name);
                }),
              ),
          ],
        ),
        const MinimalGap(MinimalSpacing.s8),
        // The count is a figure (mono); the words stay in Geist.
        _on.isEmpty
            ? Text('No time of day', style: t.bodySmall.c(t.mutedForeground))
            : Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${_on.length}', style: t.mono),
                    TextSpan(
                      text: ' selected',
                      style: t.bodySmall.c(t.mutedForeground),
                    ),
                  ],
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
// builder never names a style.

/// The chosen filter, with its mono count.
Widget kitSpecimenChipSelected() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [MinimalChip('Open', count: 2, selected: true, onPressed: () {})],
);

/// A filter at rest, with its glyph.
Widget kitSpecimenChipRest() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalChip('Morning', icon: LucideIcons.sunrise, onPressed: () {}),
  ],
);

/// The days a habit repeats on, weekdays chosen, wrapping its line.
Widget kitSpecimenChipRowDays() =>
    MinimalChipRow(children: _dayChips(_weekdays));
