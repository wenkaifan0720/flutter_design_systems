/// The chips group's demo: assist, filter, input and suggestion chips, flat
/// and elevated, enabled and disabled, the filter chip's check springing in,
/// the morphing Expressive shapes, and chip rows that wrap or scroll — all
/// live, so press, focus and hover show on the real thing.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../kit.dart';

/// The chips group's demo, in [brightness].
Widget kitChipsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Chips',
  sections: const <Widget>[
    _Assist(),
    _Filter(),
    _Input(),
    _Suggestion(),
    _Rows(),
    _EdgeRow(),
  ],
);

void _noop() {}

class _Assist extends StatelessWidget {
  const _Assist();

  @override
  Widget build(BuildContext context) => kitSection(
    'Assist',
    children: <Widget>[
      ExpressiveChipRow(
        children: <Widget>[
          const ExpressiveChip.assist(
            'Add to calendar',
            icon: ExpressiveSymbols.calendarMonth,
            onPressed: _noop,
          ),
          if (!KitLiveViewport.of(context))
            const ExpressiveChip.assist(
              'Directions',
              icon: ExpressiveSymbols.map,
              onPressed: _noop,
            ),
          if (!KitLiveViewport.of(context))
            const ExpressiveChip.assist('Share', onPressed: _noop),
        ],
      ),
      ExpressiveChipRow(
        children: <Widget>[
          const ExpressiveChip.assist(
            'Book a table',
            icon: ExpressiveSymbols.restaurant,
            elevated: true,
            onPressed: _noop,
          ),
          if (!KitLiveViewport.of(context))
            const ExpressiveChip.assist(
              'Call',
              icon: ExpressiveSymbols.call,
              elevated: true,
              onPressed: _noop,
            ),
        ],
      ),
      if (!KitLiveViewport.of(context))
        const ExpressiveChipRow(
          children: <Widget>[
            ExpressiveChip.assist(
              'Offline',
              icon: ExpressiveSymbols.cloudDownload,
              enabled: false,
            ),
            ExpressiveChip.assist(
              'Offline',
              icon: ExpressiveSymbols.cloudDownload,
              elevated: true,
              enabled: false,
            ),
          ],
        ),
    ],
  );
}

class _Filter extends StatefulWidget {
  const _Filter();

  @override
  State<_Filter> createState() => _FilterState();
}

class _FilterState extends State<_Filter> {
  final Set<String> _flat = <String>{'Open now'};
  final Set<String> _elevated = <String>{'Vegetarian'};
  final Set<String> _morph = <String>{'Patio'};

  Widget _row(
    Set<String> picked,
    List<String> labels, {
    bool elevated = false,
    bool morph = false,
  }) => ExpressiveChipRow(
    children: <Widget>[
      for (final label in labels)
        ExpressiveChip.filter(
          label,
          selected: picked.contains(label),
          elevated: elevated,
          morph: morph,
          onPressed: () => setState(
            () => picked.contains(label)
                ? picked.remove(label)
                : picked.add(label),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => kitSection(
    'Filter',
    children: <Widget>[
      _row(_flat, const <String>['Open now', 'Under \$20', 'Takeout']),
      _row(_elevated, const <String>[
        'Vegetarian',
        'Gluten-free',
      ], elevated: true),
      _row(_morph, const <String>[
        'Patio',
        'Quiet',
        'Kid-friendly',
      ], morph: true),
      if (!KitLiveViewport.of(context))
        const ExpressiveChipRow(
          children: <Widget>[
            ExpressiveChip.filter(
              'Cuisine',
              selected: false,
              icon: ExpressiveSymbols.localDining,
              trailingIcon: ExpressiveSymbols.arrowDropDown,
              onPressed: _noop,
            ),
            ExpressiveChip.filter('Closed', selected: false, enabled: false),
            ExpressiveChip.filter('Booked', selected: true, enabled: false),
          ],
        ),
    ],
  );
}

class _Input extends StatefulWidget {
  const _Input();

  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  final List<String> _guests = <String>['Mara Quist', 'Theo Lind', 'Ada Wren'];
  String? _picked = 'Theo Lind';

  @override
  Widget build(BuildContext context) => kitSection(
    'Input',
    children: <Widget>[
      ExpressiveChipRow(
        children: <Widget>[
          for (final guest in _guests)
            ExpressiveChip.input(
              guest,
              avatar: ExpressiveAvatar(
                name: guest,
                size: ExpressiveAvatarSize.extraSmall,
              ),
              selected: _picked == guest,
              morph: true,
              onPressed: () =>
                  setState(() => _picked = _picked == guest ? null : guest),
              onDeleted: () => setState(() => _guests.remove(guest)),
            ),
          if (_guests.isEmpty)
            ExpressiveChip.assist(
              'Invite again',
              icon: ExpressiveSymbols.groupAdd,
              onPressed: () => setState(
                () => _guests.addAll(<String>[
                  'Mara Quist',
                  'Theo Lind',
                  'Ada Wren',
                ]),
              ),
            ),
        ],
      ),
      if (!KitLiveViewport.of(context))
        const ExpressiveChipRow(
          children: <Widget>[
            ExpressiveChip.input(
              'Lisbon',
              icon: ExpressiveSymbols.flight,
              onPressed: _noop,
              onDeleted: _noop,
            ),
            ExpressiveChip.input('#hiking', onPressed: _noop, onDeleted: _noop),
            ExpressiveChip.input('Draft', icon: ExpressiveSymbols.draft),
            ExpressiveChip.input(
              'Archived',
              icon: ExpressiveSymbols.archive,
              enabled: false,
              onDeleted: _noop,
            ),
          ],
        ),
    ],
  );
}

class _Suggestion extends StatelessWidget {
  const _Suggestion();

  @override
  Widget build(BuildContext context) => kitSection(
    'Suggestion',
    children: <Widget>[
      ExpressiveChipRow(
        children: <Widget>[
          const ExpressiveChip.suggestion('Sounds good!', onPressed: _noop),
          if (!KitLiveViewport.of(context))
            const ExpressiveChip.suggestion('Running late', onPressed: _noop),
          const ExpressiveChip.suggestion(
            'On my way',
            icon: ExpressiveSymbols.directionsWalk,
            onPressed: _noop,
          ),
        ],
      ),
      ExpressiveChipRow(
        children: <Widget>[
          const ExpressiveChip.suggestion(
            'Best trails nearby',
            elevated: true,
            onPressed: _noop,
          ),
          if (!KitLiveViewport.of(context))
            const ExpressiveChip.suggestion(
              'Sunrise spots',
              icon: ExpressiveSymbols.wbSunny,
              elevated: true,
              onPressed: _noop,
            ),
          if (!KitLiveViewport.of(context))
            const ExpressiveChip.suggestion('Expired', enabled: false),
        ],
      ),
    ],
  );
}

class _Rows extends StatefulWidget {
  const _Rows();

  @override
  State<_Rows> createState() => _RowsState();
}

class _RowsState extends State<_Rows> {
  static const List<String> _genres = <String>[
    'Ambient',
    'Jazz',
    'Folk',
    'Electronic',
    'Classical',
    'Soul',
    'Post-rock',
    'Lo-fi',
  ];
  final Set<String> _picked = <String>{'Jazz', 'Soul'};

  @override
  Widget build(BuildContext context) => kitSection(
    'Chip rows',
    children: <Widget>[
      if (!KitLiveViewport.of(context))
        ExpressiveChipRow(
          scrollable: true,
          children: <Widget>[
            for (final genre in _genres)
              ExpressiveChip.filter(
                genre,
                selected: _picked.contains(genre),
                onPressed: () => setState(
                  () => _picked.contains(genre)
                      ? _picked.remove(genre)
                      : _picked.add(genre),
                ),
              ),
          ],
        ),
      ExpressiveChipRow(
        children: <Widget>[
          for (final genre
              in KitLiveViewport.of(context) ? _genres.take(3) : _genres)
            ExpressiveChip.filter(
              genre,
              selected: _picked.contains(genre),
              onPressed: () => setState(
                () => _picked.contains(genre)
                    ? _picked.remove(genre)
                    : _picked.add(genre),
              ),
            ),
        ],
      ),
    ],
  );
}

/// A scrolling row edge to edge: a page places it outside its margin and
/// gives the margin to the row's padding, inside the scroll, so the chips
/// line up with the page at rest and cut off at the screen's edge. Here a
/// `surfaceContainer` band stands in for the screen.
class _EdgeRow extends StatefulWidget {
  const _EdgeRow();

  @override
  State<_EdgeRow> createState() => _EdgeRowState();
}

class _EdgeRowState extends State<_EdgeRow> {
  static const List<String> _ranges = <String>[
    'Morning',
    'Evening',
    'Above target',
    'With a note',
    'This week',
    'Last 30 days',
  ];
  String _picked = 'This week';

  @override
  Widget build(BuildContext context) => kitSection(
    'Chip row · edge to edge, the margin inside the scroll',
    children: <Widget>[
      ColoredBox(
        color: context.expressiveTheme.colors.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ExpressiveSpacing.s8),
          child: ExpressiveChipRow(
            scrollable: true,
            padding: const EdgeInsets.symmetric(
              horizontal: ExpressiveChromeMetrics.margin,
            ),
            children: <Widget>[
              for (final range in _ranges)
                ExpressiveChip.filter(
                  range,
                  selected: range == _picked,
                  onPressed: () => setState(() => _picked = range),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// A filter chip, selected: its check leads the label.
Widget kitSpecimenChipFilterSelected() => Center(
  child: ExpressiveChip.filter('Open now', selected: true, onPressed: () {}),
);

/// A row of filters flowing onto a second line, two chosen.
Widget kitSpecimenChipRowFilters() => ExpressiveChipRow(
  children: <Widget>[
    for (final (label, on) in const <(String, bool)>[
      ('Open now', true),
      ('Free entry', false),
      ('Step-free', true),
      ('Family', false),
      ('Late hours', false),
      ('Outdoor', false),
    ])
      ExpressiveChip.filter(label, selected: on, onPressed: () {}),
  ],
);
