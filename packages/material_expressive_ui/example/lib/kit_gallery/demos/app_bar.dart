/// The app-bar group's demo: the small top app bar (plain, with navigation
/// and actions, centred with a subtitle, folding extra actions into its
/// overflow menu, filled once content scrolls under it), the medium and
/// large flexible bars expanded, halfway and collapsed, a live collapsing
/// bar, the search app bar at rest and scrolled, the search bar opening its
/// full-screen and contained views (filter chips, live results), and the
/// inline search field.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The app-bar group's demo, in [brightness].
Widget kitAppBarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'App bars',
  liveSections: const <Widget>[
    _LiveBar(),
    _Collapsing(),
    _SearchViews(),
    _InlineField(),
  ],
  sections: const <Widget>[
    _Small(),
    _Flexible(),
    _Collapsing(),
    _SearchAppBars(),
    _SearchViews(),
    _InlineField(),
  ],
);

void _noop() {}

class _LiveBar extends StatefulWidget {
  const _LiveBar();

  @override
  State<_LiveBar> createState() => _LiveBarState();
}

class _LiveBarState extends State<_LiveBar> {
  var _size = ExpressiveAppBarSize.small;
  var _saved = false;

  @override
  Widget build(BuildContext context) => kitSection(
    'Small, medium and large',
    children: <Widget>[
      ExpressiveSegmentedButton<ExpressiveAppBarSize>(
        segments: const <ExpressiveButtonSegment<ExpressiveAppBarSize>>[
          ExpressiveButtonSegment(ExpressiveAppBarSize.small, 'Small'),
          ExpressiveButtonSegment(ExpressiveAppBarSize.medium, 'Medium'),
          ExpressiveButtonSegment(ExpressiveAppBarSize.large, 'Large'),
        ],
        value: _size,
        onChanged: (value) => setState(() => _size = value),
      ),
      _Frame(
        ExpressiveAppBar(
          title: 'Field notes',
          subtitle: 'Week 21',
          size: _size,
          actions: <ExpressiveAppBarAction>[
            ExpressiveAppBarAction(
              _saved
                  ? ExpressiveSymbols.bookmark
                  : ExpressiveSymbols.bookmarkBorder,
              label: _saved ? 'Unsave notes' : 'Save notes',
              onPressed: () => setState(() => _saved = !_saved),
            ),
          ],
        ),
      ),
      Text(_saved ? '1 saved note' : 'No saved notes'),
    ],
  );
}

/// A bar in a framed window, as it stands at the top of a screen.
class _Frame extends StatelessWidget {
  const _Frame(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: ShapeDecoration(
        shape: t.shapes.medium.copyWith(
          side: BorderSide(color: t.colors.outlineVariant),
        ),
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: t.shapes.medium),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeLeft: true,
          removeRight: true,
          child: child,
        ),
      ),
    );
  }
}

/// A quiet caption line under a bar.
class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Text(
      text,
      style: t.type.bodySmall.copyWith(color: t.colors.onSurfaceVariant),
    );
  }
}

/// A navigation icon for a root: the drawer's.
Widget _menu() => const ExpressiveIconButton(
  ExpressiveSymbols.menu,
  onPressed: _noop,
  semanticLabel: 'Open navigation',
);

class _Small extends StatelessWidget {
  const _Small();

  @override
  Widget build(BuildContext context) => kitSection(
    'Small: title, navigation, actions',
    children: <Widget>[
      const _Frame(ExpressiveAppBar(title: 'Inbox')),
      _Frame(
        ExpressiveAppBar(
          title: 'Field notes',
          leading: _menu(),
          actions: const <Widget>[
            ExpressiveAppBarAction(
              ExpressiveSymbols.search,
              label: 'Search notes',
              onPressed: _noop,
            ),
            ExpressiveAppBarAction(
              ExpressiveSymbols.bookmarkBorder,
              label: 'Saved',
              onPressed: _noop,
            ),
          ],
        ),
      ),
      const _Frame(
        ExpressiveAppBar(
          title: 'Lisbon in May',
          subtitle: '12 photos · 3 shared',
          centered: true,
          leading: ExpressiveIconButton(
            ExpressiveSymbols.arrowBack,
            onPressed: _noop,
            semanticLabel: 'Back',
          ),
          actions: <Widget>[
            ExpressiveAppBarAction(
              ExpressiveSymbols.share,
              label: 'Share album',
              onPressed: _noop,
            ),
          ],
        ),
      ),
      const _Caption('Centred, with a subtitle.'),
      _Frame(
        ExpressiveAppBar(
          title: 'Quarterly review',
          leading: _menu(),
          actions: const <Widget>[
            ExpressiveAppBarAction(
              ExpressiveSymbols.edit,
              label: 'Edit',
              onPressed: _noop,
            ),
            ExpressiveAppBarAction(
              ExpressiveSymbols.share,
              label: 'Share',
              onPressed: _noop,
            ),
            ExpressiveAppBarAction(
              ExpressiveSymbols.print,
              label: 'Print',
              onPressed: _noop,
            ),
            ExpressiveAppBarAction(
              ExpressiveSymbols.archive,
              label: 'Archive',
              onPressed: _noop,
            ),
          ],
          overflow: const <ExpressiveMenuEntry>[
            ExpressiveMenuDivider(),
            ExpressiveMenuItem(
              'Version history',
              icon: ExpressiveSymbols.history,
              onPressed: _noop,
            ),
          ],
        ),
      ),
      const _Caption(
        'Four actions: two show, the rest fold into the overflow menu.',
      ),
      const _Frame(
        ExpressiveAppBar(
          title: 'Inbox',
          scroll: ExpressiveAppBarScroll(contentOffset: -ExpressiveSpacing.s64),
        ),
      ),
      const _Caption('Content scrolled under it: surfaceContainer.'),
    ],
  );
}

class _Flexible extends StatelessWidget {
  const _Flexible();

  @override
  Widget build(BuildContext context) {
    Widget bar(
      ExpressiveAppBarSize size,
      double fraction, {
      String? subtitle,
      bool centered = false,
    }) => Builder(
      builder: (context) {
        final range = ExpressiveAppBar(
          title: 'Journal',
          subtitle: subtitle,
          size: size,
        ).collapseRangeOf(context);
        return _Frame(
          ExpressiveAppBar(
            title: 'Journal',
            subtitle: subtitle,
            size: size,
            centered: centered,
            leading: _menu(),
            actions: const <Widget>[
              ExpressiveAppBarAction(
                ExpressiveSymbols.calendarMonth,
                label: 'Calendar',
                onPressed: _noop,
              ),
            ],
            scroll: ExpressiveAppBarScroll(heightOffset: -range * fraction),
          ),
        );
      },
    );

    return kitSection(
      'Medium and large flexible: expanded, halfway, collapsed',
      children: <Widget>[
        bar(ExpressiveAppBarSize.medium, 0),
        bar(ExpressiveAppBarSize.medium, 0, subtitle: 'Week 21'),
        bar(ExpressiveAppBarSize.large, 0, subtitle: 'Week 21'),
        bar(ExpressiveAppBarSize.large, 0, centered: true),
        const _Caption('Centred.'),
        bar(ExpressiveAppBarSize.large, 0.5, subtitle: 'Week 21'),
        const _Caption('Halfway: the big title fades as the small one comes.'),
        bar(ExpressiveAppBarSize.large, 1, subtitle: 'Week 21'),
        const _Caption('Collapsed to the small row, filled.'),
      ],
    );
  }
}

/// A live large flexible bar over a scrolling list: it collapses as the
/// list scrolls, and snaps open or shut when the scroll stops midway.
class _Collapsing extends StatelessWidget {
  const _Collapsing();

  @override
  Widget build(BuildContext context) => kitSection(
    'Collapsing with the content (scroll the list)',
    children: <Widget>[
      _Frame(
        SizedBox(
          height: ExpressiveSpacing.s72 * 5,
          child: ExpressiveScaffold(
            topBar: const ExpressiveAppBar(
              title: 'Reading list',
              subtitle: '9 saved',
              large: true,
              collapsing: true,
              actions: <Widget>[
                ExpressiveAppBarAction(
                  ExpressiveSymbols.sort,
                  label: 'Sort',
                  onPressed: _noop,
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[for (final title in _reading) _Row(title)],
            ),
          ),
        ),
      ),
    ],
  );
}

const List<String> _reading = <String>[
  'The quiet art of mending',
  'Notes from a night ferry',
  'How rivers choose their beds',
  'A field guide to city moss',
  'Letters to a young baker',
  'The weight of small bells',
  'Salt, smoke and time',
  'Walking the old coast road',
  'On keeping a garden diary',
];

/// One line of the reading list.
class _Row extends StatelessWidget {
  const _Row(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ExpressiveSpacing.s12),
      child: Row(
        children: <Widget>[
          Icon(ExpressiveSymbols.book, color: t.colors.onSurfaceVariant),
          const SizedBox(width: ExpressiveSpacing.s16),
          Expanded(
            child: Text(
              title,
              style: t.type.bodyLarge.copyWith(color: t.colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAppBars extends StatelessWidget {
  const _SearchAppBars();

  @override
  Widget build(BuildContext context) => kitSection(
    'Search app bar',
    children: <Widget>[
      _Frame(
        ExpressiveAppBar.search(
          leading: _menu(),
          search: const ExpressiveSearchBar(
            hintText: 'Search mail',
            avatar: ExpressiveAvatar(
              name: 'Ana Ruiz',
              size: ExpressiveAvatarSize.small,
            ),
            avatarLabel: 'Ana Ruiz, account',
            onAvatarTap: _noop,
          ),
        ),
      ),
      _Frame(
        ExpressiveAppBar.search(
          leading: _menu(),
          search: const ExpressiveSearchBar(
            hintText: 'Search mail',
            avatar: ExpressiveAvatar(
              name: 'Ana Ruiz',
              size: ExpressiveAvatarSize.small,
            ),
          ),
          scroll: const ExpressiveAppBarScroll(
            contentOffset: -ExpressiveSpacing.s64,
          ),
        ),
      ),
      const _Caption(
        'Content scrolled under it: the bar and the search bar fill.',
      ),
    ],
  );
}

const List<String> _places = <String>[
  'Alfama viewpoint',
  'Belém tower',
  'LX Factory',
  'Time Out Market',
  'Jardim da Estrela',
  'Oceanário',
];

/// Results for [query]: the places whose name holds it.
Widget _results(BuildContext context, String query) {
  final t = context.expressiveTheme;
  final matches = _places
      .where((p) => p.toLowerCase().contains(query.toLowerCase()))
      .toList();
  return ListView(
    padding: const EdgeInsets.all(ExpressiveSpacing.s16),
    children: <Widget>[
      Text(
        query.isEmpty ? 'Recent' : '${matches.length} places',
        style: t.type.titleSmall.copyWith(color: t.colors.onSurfaceVariant),
      ),
      for (final place in query.isEmpty ? _places.take(3) : matches)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: ExpressiveSpacing.s12),
          child: Row(
            children: <Widget>[
              Icon(
                query.isEmpty
                    ? ExpressiveSymbols.history
                    : ExpressiveSymbols.place,
                color: t.colors.onSurfaceVariant,
              ),
              const SizedBox(width: ExpressiveSpacing.s16),
              Expanded(
                child: Text(
                  place,
                  style: t.type.bodyLarge.copyWith(color: t.colors.onSurface),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _SearchViews extends StatefulWidget {
  const _SearchViews();

  @override
  State<_SearchViews> createState() => _SearchViewsState();
}

class _SearchViewsState extends State<_SearchViews> {
  bool _open = true;
  bool _free = false;

  List<Widget> _filters() => <Widget>[
    ExpressiveChip.filter(
      'Open now',
      selected: _open,
      onPressed: () => setState(() => _open = !_open),
    ),
    ExpressiveChip.filter(
      'Free entry',
      selected: _free,
      onPressed: () => setState(() => _free = !_free),
    ),
  ];

  @override
  Widget build(BuildContext context) => kitSection(
    'Search bar and search view (tap to open)',
    children: <Widget>[
      ExpressiveSearchBar(
        hintText: 'Search Lisbon',
        trailing: const <Widget>[
          ExpressiveIconButton(
            ExpressiveSymbols.mic,
            onPressed: _noop,
            semanticLabel: 'Search by voice',
          ),
        ],
        filters: _filters(),
        results: _results,
      ),
      const _Caption('Full screen: the bar grows into the view.'),
      ExpressiveSearchBar(
        hintText: 'Search Lisbon',
        contained: true,
        avatar: const ExpressiveAvatar(
          name: 'Ana Ruiz',
          size: ExpressiveAvatarSize.small,
        ),
        filters: _filters(),
        results: _results,
      ),
      const _Caption('Contained: the field keeps its pill.'),
    ],
  );
}

class _InlineField extends StatelessWidget {
  const _InlineField();

  @override
  Widget build(BuildContext context) => kitSection(
    'Search field',
    children: const <Widget>[
      ExpressiveSearchField(hintText: 'Filter messages'),
      ExpressiveSearchField(hintText: 'Search this thread', onCancel: _noop),
      _Caption('With a cancel arrow; a clear control shows once typed.'),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md): one
// configuration each, the same in every style; kitSpecimenStage styles and
// places them.

/// A root's small bar: the drawer, the title and two actions.
Widget kitSpecimenTopBarSmall() => ExpressiveAppBar(
  title: 'Field notes',
  leading: _menu(),
  actions: const <Widget>[
    ExpressiveAppBarAction(
      ExpressiveSymbols.search,
      label: 'Search notes',
      onPressed: _noop,
    ),
    ExpressiveAppBarAction(
      ExpressiveSymbols.bookmarkBorder,
      label: 'Saved',
      onPressed: _noop,
    ),
  ],
);

/// The large flexible bar expanded, with its subtitle.
Widget kitSpecimenTopBarLarge() => ExpressiveAppBar(
  title: 'Journal',
  subtitle: 'Week 21',
  size: ExpressiveAppBarSize.large,
  leading: _menu(),
  actions: const <Widget>[
    ExpressiveAppBarAction(
      ExpressiveSymbols.calendarMonth,
      label: 'Calendar',
      onPressed: _noop,
    ),
  ],
);

/// The search bar at rest with the account avatar.
Widget kitSpecimenSearchBarAvatar() => const ExpressiveSearchBar(
  hintText: 'Search mail',
  avatar: ExpressiveAvatar(name: 'Ana Ruiz', size: ExpressiveAvatarSize.small),
  avatarLabel: 'Ana Ruiz, account',
  onAvatarTap: _noop,
);

/// The inline search field with its cancel arrow.
Widget kitSpecimenSearchFieldCancel() => const ExpressiveSearchField(
  hintText: 'Search this thread',
  onCancel: _noop,
);
