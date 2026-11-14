/// Minimal's search: the 32 px field filtering a live habit list with
/// scopes (and its empty result), the field holding a query with its clear
/// cap, Cancel on focus, the floating toolbar register, disabled; and the
/// entry that opens search elsewhere, with its filter square.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitSearchDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Search',
  sections: [
    kitSection(
      'Live',
      children: [
        const _HabitSearch(),
        kitNote(
          'Type to filter; Escape clears the query, then leaves the field. '
          'While it is empty the / key hint says how to reach it.',
        ),
      ],
    ),
    kitSection(
      'States',
      children: [
        _Query(
          text: 'morning',
          builder: (c) => MinimalSearchField(
            hint: 'Search habits',
            controller: c,
            clearable: true,
          ),
        ),
        const MinimalSearchField(
          hint: 'Search habits',
          showCancel: true,
          shortcut: '⌘ K',
        ),
        const MinimalSearchField(hint: 'Search archived', enabled: false),
        kitNote('The second field shows Cancel beside it while focused.'),
      ],
    ),
    kitSection(
      'Toolbar',
      children: [
        _Query(
          text: 'read',
          builder: (c) => MinimalSearchField(
            hint: 'Search everything',
            presentation: MinimalSearchPresentation.toolbar,
            controller: c,
            showCancel: true,
          ),
        ),
        kitNote(
          'The search that floats over a long list, always one tap from '
          'clear.',
        ),
      ],
    ),
    kitSection('Entry', children: const [_Entries()]),
  ],
);

/// A field that starts with a query in it.
class _Query extends StatefulWidget {
  const _Query({required this.text, required this.builder});

  final String text;
  final Widget Function(TextEditingController controller) builder;

  @override
  State<_Query> createState() => _QueryState();
}

class _QueryState extends State<_Query> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

/// Today's habits as every demo prints them: id, name, state, streak.
const List<(String, String, MinimalTaskStatus, int)> _habits = [
  ('HAB-1', 'Meditate', MinimalTaskStatus.done, 4),
  ('HAB-4', 'Morning run', MinimalTaskStatus.done, 12),
  ('HAB-2', 'Drink water', MinimalTaskStatus.todo, 10),
  ('HAB-3', 'Journal', MinimalTaskStatus.todo, 3),
  ('HAB-5', 'Read 20 pages', MinimalTaskStatus.done, 6),
  ('HAB-6', 'Water the plants', MinimalTaskStatus.paused, 2),
];

/// The field over a live list: the query and the scope filter the rows,
/// and an empty result says so.
class _HabitSearch extends StatefulWidget {
  const _HabitSearch();

  @override
  State<_HabitSearch> createState() => _HabitSearchState();
}

class _HabitSearchState extends State<_HabitSearch> {
  String _query = '';
  int _scope = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final q = _query.trim().toLowerCase();
    final rows = [
      for (final habit in _habits)
        if ((q.isEmpty ||
                habit.$2.toLowerCase().contains(q) ||
                habit.$1.toLowerCase().contains(q)) &&
            switch (_scope) {
              1 => habit.$3 == MinimalTaskStatus.todo,
              2 => habit.$3 == MinimalTaskStatus.done,
              _ => true,
            })
          habit,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalSearchField(
          hint: 'Search habits',
          shortcut: '/',
          clearable: true,
          scopes: const ['All', 'Open', 'Done'],
          scopeIndex: _scope,
          onScopeChanged: (i) => setState(() => _scope = i),
          onChanged: (v) => setState(() => _query = v),
        ),
        if (rows.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s16),
            decoration: BoxDecoration(border: Border(top: t.rule)),
            child: Text(
              'No habits match “${_query.trim()}”.',
              style: t.bodySmall.c(t.mutedForeground),
              textAlign: TextAlign.center,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(border: Border(top: t.rule)),
            child: MinimalListSection(
              gutter: false,
              children: [
                for (final (id, name, status, streak) in rows)
                  MinimalListTile(
                    dense: true,
                    leading: MinimalStatusIcon(status),
                    title: name,
                    muted: status != MinimalTaskStatus.todo,
                    trailing: Text(id, style: t.mono.c(t.mutedForeground)),
                    meta: '${streak}d',
                    // The streak's fixed column keeps the ids aligned.
                    metaWidth: 30,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Entries that open search elsewhere: plain, with a detail line and a
/// shortcut, with the filter square (active and not), and disabled.
class _Entries extends StatefulWidget {
  const _Entries();

  @override
  State<_Entries> createState() => _EntriesState();
}

class _EntriesState extends State<_Entries> {
  bool _filters = true;

  /// An entry opens the search itself; here a toast says so.
  void _open(BuildContext context) => showMinimalSnackBar(
    context,
    'Search opens full screen',
    icon: LucideIcons.search,
  );

  @override
  Widget build(BuildContext context) {
    // The page's field stack: the section's 12 between 44 px bands, as the
    // States fields stand, about 24 between faces. The two-line entry fills
    // its band, so 8 more stand on each side of it for the air a one-line
    // band holds round its face.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalSearchEntry(
          label: 'Search habits',
          shortcut: 'Ctrl K',
          onPressed: () => _open(context),
        ),
        const MinimalGap(MinimalSpacing.s20),
        MinimalSearchEntry(
          label: 'Search issues',
          detail: 'In Habits · 6 open',
          onPressed: () => _open(context),
          onFilter: () => setState(() => _filters = !_filters),
          filtersActive: _filters,
        ),
        const MinimalGap(MinimalSpacing.s20),
        MinimalSearchEntry(
          label: 'Search orders',
          onPressed: () => _open(context),
          onFilter: () {},
        ),
        const MinimalGap(MinimalSpacing.s12),
        const MinimalSearchEntry(label: 'Search archive'),
        const MinimalGap(MinimalSpacing.s8),
        kitNote(
          'The filter square is its own control: a dot shows while a filter '
          'is on.',
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

/// The empty field, its shortcut's caps at the end.
Widget kitSpecimenSearchFieldShortcut() =>
    const MinimalSearchField(hint: 'Search habits', shortcut: '⌘ K');

/// The field holding a query, the clear glyph at the end.
Widget kitSpecimenSearchFieldQuery() => _Query(
  text: 'morning',
  builder: (c) =>
      MinimalSearchField(hint: 'Search habits', controller: c, clearable: true),
);

/// The field with its scope filters printed under it.
Widget kitSpecimenSearchFieldScopes() => const MinimalSearchField(
  hint: 'Search habits',
  shortcut: '/',
  scopes: ['All', 'Open', 'Done'],
  scopeIndex: 1,
);

/// A search that opens elsewhere, with its shortcut.
Widget kitSpecimenSearchEntryShortcut() => MinimalSearchEntry(
  label: 'Search habits',
  shortcut: 'Ctrl K',
  onPressed: () {},
);

/// The entry with its detail line and the filter square, filters on.
Widget kitSpecimenSearchEntryFilter() => MinimalSearchEntry(
  label: 'Search issues',
  detail: 'In Habits · 6 open',
  onPressed: () {},
  onFilter: () {},
  filtersActive: true,
);
