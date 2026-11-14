/// The toolbar group's demo: floating toolbars in both colours, leading and
/// trailing actions that expand and shrink away, the toolbar beside its
/// FAB (folding into it), vertical toolbars, the docked toolbar spread and
/// fixed, and toolbars that answer a scroll (leaving the screen, or
/// collapsing).
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The toolbar group's demo, in [brightness].
Widget kitToolbarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Toolbars',
  sections: const <Widget>[
    _Colours(),
    _Expanding(),
    _WithFab(),
    _Vertical(),
    _Docked(),
    _OnScroll(),
  ],
);

void _noop() {}

/// A quiet caption line under a row.
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

/// A standard icon button: the toolbar's content colour.
Widget _act(IconData icon, String label) =>
    ExpressiveIconButton(icon, semanticLabel: label, onPressed: _noop);

/// The editing actions a note editor keeps at hand.
List<Widget> _formatting() => <Widget>[
  _act(ExpressiveSymbols.formatBold, 'Bold'),
  _act(ExpressiveSymbols.formatItalic, 'Italic'),
  _act(ExpressiveSymbols.formatListBulleted, 'Bulleted list'),
  _act(ExpressiveSymbols.formatQuote, 'Quote'),
];

/// [child] centred in the band, scaled down if a large text scale or a
/// narrow screen leaves it too little room.
Widget _centred(Widget child) => Center(
  child: FittedBox(fit: BoxFit.scaleDown, child: child),
);

class _Colours extends StatelessWidget {
  const _Colours();

  @override
  Widget build(BuildContext context) => kitSection(
    'Floating · standard and vibrant',
    children: <Widget>[
      _centred(
        ExpressiveFloatingToolbar(
          semanticLabel: 'Formatting',
          children: _formatting(),
        ),
      ),
      _centred(
        ExpressiveFloatingToolbar(
          kind: ExpressiveToolbarKind.vibrant,
          semanticLabel: 'Formatting',
          children: _formatting(),
        ),
      ),
      const _Caption(
        'A pill that floats 16dp over the content. Vibrant is for the one '
        'toolbar that leads the screen.',
      ),
    ],
  );
}

class _Expanding extends StatefulWidget {
  const _Expanding();

  @override
  State<_Expanding> createState() => _ExpandingState();
}

class _ExpandingState extends State<_Expanding> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) => kitSection(
    'Expand and collapse',
    children: <Widget>[
      _centred(
        ExpressiveFloatingToolbar(
          expanded: _expanded,
          semanticLabel: 'Photo edits',
          leading: <Widget>[
            _act(ExpressiveSymbols.undo, 'Undo'),
            _act(ExpressiveSymbols.redo, 'Redo'),
          ],
          trailing: <Widget>[_act(ExpressiveSymbols.moreVert, 'More')],
          children: <Widget>[
            _act(ExpressiveSymbols.tune, 'Adjust'),
            _act(ExpressiveSymbols.palette, 'Filters'),
          ],
        ),
      ),
      Center(
        child: ExpressiveIconToggleButton.filledTonal(
          ExpressiveSymbols.unfoldMore,
          value: _expanded,
          semanticLabel: 'Show every action',
          onChanged: (value) => setState(() => _expanded = value),
        ),
      ),
      const _Caption(
        'Leading and trailing actions spring in from their edges and shrink '
        'away; the core actions stay.',
      ),
    ],
  );
}

class _WithFab extends StatefulWidget {
  const _WithFab();

  @override
  State<_WithFab> createState() => _WithFabState();
}

class _WithFabState extends State<_WithFab> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) => kitSection(
    'Beside a FAB',
    children: <Widget>[
      _centred(
        ExpressiveFloatingToolbar(
          expanded: _expanded,
          semanticLabel: 'Inbox actions',
          floatingActionButton: const ExpressiveToolbarFab(
            icon: ExpressiveSymbols.edit,
            semanticLabel: 'Write a message',
            onPressed: _noop,
          ),
          children: <Widget>[
            _act(ExpressiveSymbols.archive, 'Archive'),
            _act(ExpressiveSymbols.label, 'Label'),
            _act(ExpressiveSymbols.schedule, 'Snooze'),
            _act(ExpressiveSymbols.delete, 'Delete'),
          ],
        ),
      ),
      // Playback stays left to right in either reading direction (media
      // controls are not mirrored).
      _centred(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ExpressiveFloatingToolbar(
            expanded: _expanded,
            kind: ExpressiveToolbarKind.vibrant,
            fabPosition: ExpressiveToolbarFabPosition.start,
            semanticLabel: 'Playback',
            floatingActionButton: const ExpressiveToolbarFab(
              icon: ExpressiveSymbols.playArrow,
              kind: ExpressiveToolbarKind.vibrant,
              semanticLabel: 'Play',
              onPressed: _noop,
            ),
            children: <Widget>[
              _act(ExpressiveSymbols.shuffle, 'Shuffle'),
              _act(ExpressiveSymbols.skipPrevious, 'Previous'),
              _act(ExpressiveSymbols.skipNext, 'Next'),
            ],
          ),
        ),
      ),
      Center(
        child: ExpressiveIconToggleButton.filledTonal(
          ExpressiveSymbols.unfoldLess,
          value: !_expanded,
          semanticLabel: 'Fold into the FAB',
          onChanged: (value) => setState(() => _expanded = !value),
        ),
      ),
      const _Caption(
        'Folded, the toolbar shrinks into its FAB, which grows from 56 to '
        '80dp. The FAB may lead or trail. Never a FAB menu here.',
      ),
    ],
  );
}

class _Vertical extends StatelessWidget {
  const _Vertical();

  @override
  Widget build(BuildContext context) => kitSection(
    'Vertical',
    children: <Widget>[
      _centred(
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: kitGap * 3,
          children: <Widget>[
            ExpressiveFloatingToolbar(
              axis: Axis.vertical,
              semanticLabel: 'Map layers',
              children: <Widget>[
                _act(ExpressiveSymbols.myLocation, 'My location'),
                _act(ExpressiveSymbols.map, 'Layers'),
                _act(ExpressiveSymbols.explore, 'Compass'),
              ],
            ),
            ExpressiveFloatingToolbar(
              axis: Axis.vertical,
              kind: ExpressiveToolbarKind.vibrant,
              semanticLabel: 'Route',
              floatingActionButton: const ExpressiveToolbarFab(
                icon: ExpressiveSymbols.navigation,
                kind: ExpressiveToolbarKind.vibrant,
                semanticLabel: 'Start route',
                onPressed: _noop,
              ),
              children: <Widget>[
                _act(ExpressiveSymbols.directionsWalk, 'Walk'),
                _act(ExpressiveSymbols.directionsBike, 'Cycle'),
                _act(ExpressiveSymbols.directionsCar, 'Drive'),
              ],
            ),
            ExpressiveFloatingToolbar(
              axis: Axis.vertical,
              expanded: false,
              semanticLabel: 'Route, folded',
              floatingActionButton: const ExpressiveToolbarFab(
                icon: ExpressiveSymbols.navigation,
                semanticLabel: 'Start route',
                onPressed: _noop,
              ),
              children: <Widget>[
                _act(ExpressiveSymbols.directionsWalk, 'Walk'),
                _act(ExpressiveSymbols.directionsBike, 'Cycle'),
              ],
            ),
          ],
        ),
      ),
      const _Caption(
        'Beside the content on a wide screen: plain, with its FAB below, '
        'and folded into the FAB.',
      ),
    ],
  );
}

class _Docked extends StatelessWidget {
  const _Docked();

  @override
  Widget build(BuildContext context) => kitSection(
    'Docked',
    children: <Widget>[
      ExpressiveDockedToolbar(
        safeArea: false,
        semanticLabel: 'Photo actions',
        children: <Widget>[
          _act(ExpressiveSymbols.share, 'Share'),
          _act(ExpressiveSymbols.favoriteBorder, 'Favourite'),
          _act(ExpressiveSymbols.edit, 'Edit'),
          _act(ExpressiveSymbols.info, 'Details'),
          _act(ExpressiveSymbols.delete, 'Delete'),
        ],
      ),
      ExpressiveDockedToolbar(
        safeArea: false,
        kind: ExpressiveToolbarKind.vibrant,
        arrangement: ExpressiveDockedToolbarArrangement.fixed,
        semanticLabel: 'Reply',
        children: <Widget>[
          _act(ExpressiveSymbols.reply, 'Reply'),
          _act(ExpressiveSymbols.forum, 'Reply all'),
          _act(ExpressiveSymbols.send, 'Forward'),
        ],
      ),
      const _Caption(
        'Edge to edge at the bottom, 64dp over the inset: spread across '
        'the width, or centred 32dp apart.',
      ),
    ],
  );
}

class _OnScroll extends StatefulWidget {
  const _OnScroll();

  @override
  State<_OnScroll> createState() => _OnScrollState();
}

class _OnScrollState extends State<_OnScroll> {
  final ExpressiveToolbarScrollBehavior _exit =
      ExpressiveToolbarScrollBehavior();

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => kitSection(
    'On scroll',
    children: <Widget>[
      _Window(
        child: Stack(
          children: <Widget>[
            NotificationListener<ScrollNotification>(
              onNotification: _exit.handleScrollNotification,
              child: const _Notes(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: ExpressiveFloatingToolbar.screenOffset,
                ),
                child: ExpressiveFloatingToolbar(
                  scrollBehavior: _exit,
                  semanticLabel: 'Notes',
                  children: <Widget>[
                    _act(ExpressiveSymbols.checklist, 'New list'),
                    _act(ExpressiveSymbols.mic, 'Voice note'),
                    _act(ExpressiveSymbols.image, 'Photo note'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const _Caption(
        'Scroll the notes: the toolbar leaves as they move on and returns '
        'as they come back, settling on a spring.',
      ),
      _Window(
        child: ExpressiveToolbarScrollExpansion(
          child: const _Notes(),
          builder: (context, expanded, notes) => Stack(
            children: <Widget>[
              notes,
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: ExpressiveFloatingToolbar.screenOffset,
                  ),
                  child: ExpressiveFloatingToolbar(
                    expanded: expanded,
                    semanticLabel: 'Notes',
                    floatingActionButton: const ExpressiveToolbarFab(
                      icon: ExpressiveSymbols.add,
                      semanticLabel: 'New note',
                      onPressed: _noop,
                    ),
                    children: <Widget>[
                      _act(ExpressiveSymbols.checklist, 'New list'),
                      _act(ExpressiveSymbols.mic, 'Voice note'),
                      _act(ExpressiveSymbols.image, 'Photo note'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const _Caption(
        'Or it folds into its FAB after 40dp of scrolling on, and unfolds '
        'after 40dp back.',
      ),
    ],
  );
}

/// A clipped, bounded window onto some scrolling content.
class _Window extends StatelessWidget {
  const _Window({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(ExpressiveSpacing.s16),
      child: ColoredBox(
        color: t.colors.surfaceContainerLow,
        child: SizedBox(height: ExpressiveSpacing.s16 * 18, child: child),
      ),
    );
  }
}

/// A list of notes to scroll.
class _Notes extends StatelessWidget {
  const _Notes();

  static const List<String> _titles = <String>[
    'Seed order for the spring beds',
    'Chapter four: the harbour at dusk',
    'Things to ask the landlord',
    'Weekend ride: coast road loop',
    'Gift ideas for Priya',
    'Sourdough starter feeding times',
    'Books Jonah recommended',
    'Kitchen shelf measurements',
    'Pottery class, week six notes',
    'Questions for the vet',
    'Camping list for the lakes',
    'Recipe: charred leeks, hazelnuts',
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ExpressiveSpacing.s16,
        ExpressiveSpacing.s8,
        ExpressiveSpacing.s16,
        ExpressiveSpacing.s16 * 6,
      ),
      children: <Widget>[
        for (final title in _titles)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: ExpressiveSpacing.s12,
            ),
            child: Text(
              title,
              style: t.type.bodyLarge.copyWith(color: t.colors.onSurface),
            ),
          ),
      ],
    );
  }
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// The floating toolbar of a note editor with its FAB.
Widget kitSpecimenFloatingToolbarEditor() => Center(
  child: ExpressiveFloatingToolbar(
    semanticLabel: 'Formatting',
    floatingActionButton: const ExpressiveToolbarFab(
      icon: ExpressiveSymbols.check,
      semanticLabel: 'Done',
      onPressed: _noop,
    ),
    children: _formatting(),
  ),
);

/// The docked toolbar of a photo, full width at the foot.
Widget kitSpecimenDockedToolbarPhoto() => ExpressiveDockedToolbar(
  semanticLabel: 'Photo actions',
  children: <Widget>[
    _act(ExpressiveSymbols.share, 'Share'),
    _act(ExpressiveSymbols.favoriteBorder, 'Favourite'),
    _act(ExpressiveSymbols.edit, 'Edit'),
    _act(ExpressiveSymbols.info, 'Details'),
    _act(ExpressiveSymbols.delete, 'Delete'),
  ],
);
