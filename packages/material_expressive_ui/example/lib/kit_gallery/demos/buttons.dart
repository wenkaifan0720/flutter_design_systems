/// The buttons group's demo: the five common-button styles, the size
/// ladder (L and XL as the page's one hero moment), round and square, the
/// states, a screen's buttons by emphasis, toggle buttons, the standard
/// group's squish, the
/// segmented control (Material's connected group) and the link.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The buttons group's demo, in [brightness].
Widget kitButtonsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Buttons',
  sections: const <Widget>[
    _Styles(),
    _Sizes(),
    _Hero(),
    _Shapes(),
    _States(),
    _Variants(),
    _Toggles(),
    _Transport(),
    _Groups(),
    _Segmented(),
    _ToggleGroups(),
    _Links(),
    _Busy(),
  ],
);

void _noop() {}

/// [children] in a row that wraps, 8dp apart.
Widget _wrap(List<Widget> children) => Wrap(
  spacing: kitGap,
  runSpacing: kitGap,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: children,
);

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

class _Styles extends StatelessWidget {
  const _Styles();

  @override
  Widget build(BuildContext context) => kitSection(
    'Five styles, highest emphasis first',
    children: <Widget>[
      _wrap(const <Widget>[
        ExpressiveFilledButton('Book table', onPressed: _noop),
        ExpressiveFilledButton.tonal('Save for later', onPressed: _noop),
        ExpressiveElevatedButton('Add guest', onPressed: _noop),
        ExpressiveOutlinedButton('Share', onPressed: _noop),
        ExpressiveTextButton('Not now', onPressed: _noop),
      ]),
      _wrap(const <Widget>[
        ExpressiveFilledButton(
          'Check in',
          icon: ExpressiveSymbols.login,
          onPressed: _noop,
        ),
        ExpressiveFilledButton.tonal(
          'Directions',
          icon: ExpressiveSymbols.map,
          onPressed: _noop,
        ),
        ExpressiveOutlinedButton(
          'Next stop',
          trailingIcon: ExpressiveSymbols.arrowForward,
          onPressed: _noop,
        ),
      ]),
      const _Caption('Press and hold: the corners tighten on a spring.'),
    ],
  );
}

class _Sizes extends StatelessWidget {
  const _Sizes();

  @override
  Widget build(BuildContext context) => kitSection(
    'Sizes · XS 32 · S 40 · M 56',
    children: <Widget>[
      _wrap(const <Widget>[
        ExpressiveFilledButton(
          'Reply',
          size: ExpressiveButtonSize.extraSmall,
          icon: ExpressiveSymbols.reply,
          onPressed: _noop,
        ),
        ExpressiveFilledButton(
          'Reply',
          icon: ExpressiveSymbols.reply,
          onPressed: _noop,
        ),
        ExpressiveFilledButton(
          'Reply',
          size: ExpressiveButtonSize.medium,
          icon: ExpressiveSymbols.reply,
          onPressed: _noop,
        ),
      ]),
      _wrap(const <Widget>[
        ExpressiveFilledButton.tonal(
          'Filters',
          size: ExpressiveButtonSize.extraSmall,
          onPressed: _noop,
        ),
        ExpressiveFilledButton.tonal('Filters', onPressed: _noop),
        ExpressiveFilledButton.tonal(
          'Filters',
          size: ExpressiveButtonSize.medium,
          onPressed: _noop,
        ),
      ]),
    ],
  );
}

/// L and XL are hero sizes: the page spends its one hero moment on a single
/// primary action, and the segmented control picks which size it wears.
class _Hero extends StatefulWidget {
  const _Hero();

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  ExpressiveButtonSize _size = ExpressiveButtonSize.large;

  @override
  Widget build(BuildContext context) => kitSection(
    'Hero sizes · L 96 · XL 136',
    children: <Widget>[
      ExpressiveSegmentedButton<ExpressiveButtonSize>(
        segments: const <ExpressiveButtonSegment<ExpressiveButtonSize>>[
          ExpressiveButtonSegment(ExpressiveButtonSize.large, 'Large'),
          ExpressiveButtonSegment(
            ExpressiveButtonSize.extraLarge,
            'Extra large',
          ),
        ],
        value: _size,
        onChanged: (next) => setState(() => _size = next),
      ),
      ExpressiveHeroMoment(
        label: 'primary action',
        // On the column's edge, as every other example and its caption.
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: ExpressiveFilledButton(
            'Start',
            size: _size,
            icon: ExpressiveSymbols.playArrow,
            onPressed: _noop,
          ),
        ),
      ),
      const _Caption(
        'One per page, on the primary action only: it spends the '
        'expression budget.',
      ),
    ],
  );
}

class _Shapes extends StatelessWidget {
  const _Shapes();

  @override
  Widget build(BuildContext context) => kitSection(
    'Round and square',
    children: <Widget>[
      _wrap(const <Widget>[
        ExpressiveFilledButton('Round', onPressed: _noop),
        ExpressiveFilledButton(
          'Square',
          shape: ExpressiveButtonShape.square,
          onPressed: _noop,
        ),
        ExpressiveFilledButton.tonal(
          'Square',
          size: ExpressiveButtonSize.medium,
          shape: ExpressiveButtonShape.square,
          onPressed: _noop,
        ),
        ExpressiveOutlinedButton(
          'Square',
          size: ExpressiveButtonSize.extraSmall,
          shape: ExpressiveButtonShape.square,
          onPressed: _noop,
        ),
      ]),
    ],
  );
}

class _States extends StatelessWidget {
  const _States();

  @override
  Widget build(BuildContext context) => kitSection(
    'Disabled',
    children: <Widget>[
      _wrap(const <Widget>[
        ExpressiveFilledButton('Pay now'),
        ExpressiveFilledButton.tonal('Pay now'),
        ExpressiveElevatedButton('Pay now'),
        ExpressiveOutlinedButton('Pay now'),
        ExpressiveTextButton('Pay now'),
      ]),
    ],
  );
}

class _Variants extends StatelessWidget {
  const _Variants();

  @override
  Widget build(BuildContext context) => kitSection(
    'By emphasis · filled · tonal · text · in the error colour',
    children: <Widget>[
      _wrap(<Widget>[
        const ExpressiveFilledButton('Continue', onPressed: _noop),
        const ExpressiveFilledButton.tonal('Edit', onPressed: _noop),
        const ExpressiveTextButton('Skip', onPressed: _noop),
        ExpressiveFilledButton(
          'Delete',
          style: ExpressiveFilledButton.styleFrom(
            backgroundColor: context.expressiveTheme.colors.error,
            foregroundColor: context.expressiveTheme.colors.onError,
          ),
          icon: ExpressiveSymbols.delete,
          onPressed: _noop,
        ),
      ]),
      const ExpressiveFilledButton(
        'Confirm booking',
        size: ExpressiveButtonSize.medium,
        expand: true,
        onPressed: _noop,
      ),
    ],
  );
}

class _Toggles extends StatefulWidget {
  const _Toggles();

  @override
  State<_Toggles> createState() => _TogglesState();
}

class _TogglesState extends State<_Toggles> {
  final Set<int> _on = <int>{0, 3};

  static const List<(ExpressiveToggleButtonKind, String, IconData)> _items =
      <(ExpressiveToggleButtonKind, String, IconData)>[
        (
          ExpressiveToggleButtonKind.filled,
          'Favourite',
          ExpressiveSymbols.favorite,
        ),
        (ExpressiveToggleButtonKind.tonal, 'Saved', ExpressiveSymbols.bookmark),
        (
          ExpressiveToggleButtonKind.elevated,
          'Alerts',
          ExpressiveSymbols.notifications,
        ),
        (
          ExpressiveToggleButtonKind.outlined,
          'Pinned',
          ExpressiveSymbols.pushPin,
        ),
      ];

  void _set(int index, bool on) =>
      setState(() => on ? _on.add(index) : _on.remove(index));

  @override
  Widget build(BuildContext context) => kitSection(
    'Toggle buttons · round checks to square',
    children: <Widget>[
      _wrap(<Widget>[
        for (var i = 0; i < _items.length; i++)
          ExpressiveToggleButton(
            value: _on.contains(i),
            onChanged: (on) => _set(i, on),
            label: _items[i].$2,
            icon: _items[i].$3,
            kind: _items[i].$1,
          ),
      ]),
      _wrap(<Widget>[
        ExpressiveToggleButton(
          value: _on.contains(4),
          onChanged: (on) => _set(4, on),
          label: 'Mute',
          icon: ExpressiveSymbols.volumeOff,
          shape: ExpressiveButtonShape.square,
          kind: ExpressiveToggleButtonKind.tonal,
        ),
        const ExpressiveToggleButton(
          value: true,
          onChanged: null,
          label: 'Locked',
          icon: ExpressiveSymbols.lock,
        ),
      ]),
    ],
  );
}

/// A media transport: a toggle button whose content is a solid glyph
/// ([ExpressiveToggleButton.content]) and whose colours stay filled in both
/// states ([ExpressiveToggleButtonColors]), between two tonal icon buttons
/// that join the group's squish.
class _Transport extends StatefulWidget {
  const _Transport();

  @override
  State<_Transport> createState() => _TransportState();
}

class _TransportState extends State<_Transport> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final c = context.expressiveTheme.colors;
    return kitSection(
      'Transport · a glyph for content, filled checked or not',
      children: <Widget>[
        // Playback keeps time running left to right in either reading
        // direction (Material's bidirectionality: media controls are not
        // mirrored), at the reading direction's start like the rows around
        // it.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: IconTheme.merge(
              data: const IconThemeData(fill: ExpressiveSymbolsFont.filled),
              child: ExpressiveButtonGroup(
                size: ExpressiveButtonSize.medium,
                children: <Widget>[
                  ExpressiveIconButton.filledTonal(
                    ExpressiveSymbols.replay10,
                    size: ExpressiveIconButtonSize.medium,
                    width: ExpressiveIconButtonWidth.narrow,
                    semanticLabel: 'Back 10 seconds',
                    onPressed: _noop,
                  ),
                  ExpressiveToggleButton(
                    value: _playing,
                    onChanged: (on) => setState(() => _playing = on),
                    label: _playing ? 'Pause' : 'Play',
                    size: ExpressiveButtonSize.medium,
                    colors: ExpressiveToggleButtonColors(
                      container: c.primary,
                      content: c.onPrimary,
                    ),
                    child: ExpressiveIcon(
                      _playing
                          ? ExpressiveSymbols.pause
                          : ExpressiveSymbols.playArrow,
                    ),
                  ),
                  ExpressiveIconButton.filledTonal(
                    ExpressiveSymbols.forward30,
                    size: ExpressiveIconButtonSize.medium,
                    width: ExpressiveIconButtonWidth.narrow,
                    semanticLabel: 'Forward 30 seconds',
                    onPressed: _noop,
                  ),
                ],
              ),
            ),
          ),
        ),
        const _Caption(
          'Press any control: it widens and its neighbours give way, icon '
          'buttons included. Play springs round to square as it checks, '
          'and keeps primary in both states.',
        ),
      ],
    );
  }
}

class _Groups extends StatelessWidget {
  const _Groups();

  @override
  Widget build(BuildContext context) => kitSection(
    'Button group · press one, its neighbours give way',
    children: const <Widget>[
      ExpressiveButtonGroup(
        expand: true,
        children: <Widget>[
          ExpressiveFilledButton.tonal(
            'Reply',
            icon: ExpressiveSymbols.reply,
            onPressed: _noop,
          ),
          ExpressiveFilledButton.tonal(
            'Forward',
            icon: ExpressiveSymbols.send,
            onPressed: _noop,
          ),
          ExpressiveFilledButton.tonal(
            'Archive',
            icon: ExpressiveSymbols.archive,
            onPressed: _noop,
          ),
        ],
      ),
      ExpressiveButtonGroup(
        size: ExpressiveButtonSize.extraSmall,
        children: <Widget>[
          ExpressiveFilledButton(
            'Play',
            size: ExpressiveButtonSize.extraSmall,
            onPressed: _noop,
          ),
          ExpressiveOutlinedButton(
            'Queue',
            size: ExpressiveButtonSize.extraSmall,
            onPressed: _noop,
          ),
          ExpressiveTextButton(
            'Lyrics',
            size: ExpressiveButtonSize.extraSmall,
            onPressed: _noop,
          ),
        ],
      ),
    ],
  );
}

class _Segmented extends StatefulWidget {
  const _Segmented();

  @override
  State<_Segmented> createState() => _SegmentedState();
}

class _SegmentedState extends State<_Segmented> {
  String _range = 'week';
  Set<String> _amenities = <String>{'wifi', 'breakfast'};
  int _party = 2;

  @override
  Widget build(BuildContext context) => kitSection(
    'Segmented control · the connected button group',
    children: <Widget>[
      ExpressiveSegmentedButton<String>(
        segments: const <ExpressiveButtonSegment<String>>[
          ExpressiveButtonSegment('day', 'Day'),
          ExpressiveButtonSegment('week', 'Week'),
          ExpressiveButtonSegment('month', 'Month'),
        ],
        value: _range,
        onChanged: (next) => setState(() => _range = next),
      ),
      ExpressiveMultiChoiceSegmentedButton<String>(
        emptySelectionAllowed: true,
        kind: ExpressiveToggleButtonKind.tonal,
        segments: const <ExpressiveButtonSegment<String>>[
          ExpressiveButtonSegment(
            'wifi',
            'Wi-Fi',
            icon: ExpressiveSymbols.wifi,
          ),
          ExpressiveButtonSegment('pets', 'Pets', icon: ExpressiveSymbols.pets),
          ExpressiveButtonSegment(
            'breakfast',
            'Breakfast',
            icon: ExpressiveSymbols.localCafe,
          ),
        ],
        value: _amenities,
        onChanged: (next) => setState(() => _amenities = next),
      ),
      const _Caption('Multi-select: each segment toggles on its own.'),
      ExpressiveSegmentedButton<int>(
        size: ExpressiveButtonSize.extraSmall,
        expand: false,
        segments: const <ExpressiveButtonSegment<int>>[
          ExpressiveButtonSegment(1, '1'),
          ExpressiveButtonSegment(2, '2'),
          ExpressiveButtonSegment(3, '3'),
          ExpressiveButtonSegment(4, '4+'),
        ],
        value: _party,
        onChanged: (next) => setState(() => _party = next),
      ),
      const ExpressiveSegmentedButton<String>(
        size: ExpressiveButtonSize.medium,
        segments: <ExpressiveButtonSegment<String>>[
          ExpressiveButtonSegment('list', 'List'),
          ExpressiveButtonSegment('map', 'Map'),
        ],
        value: 'list',
        onChanged: null,
      ),
      const _Caption('Medium, disabled.'),
    ],
  );
}

class _Links extends StatelessWidget {
  const _Links();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Link',
      children: <Widget>[
        Text.rich(
          TextSpan(
            style: t.type.bodyMedium.copyWith(color: t.colors.onSurface),
            children: <InlineSpan>[
              const TextSpan(text: 'Free cancellation until Friday. Read the '),
              ExpressiveLink.span('house rules', onPressed: _noop),
              const TextSpan(text: ' or '),
              ExpressiveLink.span('contact your host', onPressed: _noop),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }
}

// Catalog specimens (docs/architecture/component-catalog.md): one
// configuration each, the same in every style; kitSpecimenStage styles and
// places them.

/// The primary button with its glyph.
Widget kitSpecimenButtonPrimary() => const Center(
  child: ExpressiveFilledButton(
    'Check in',
    icon: ExpressiveSymbols.login,
    onPressed: _noop,
  ),
);

/// A destructive act's button: Material has no destructive button, so an
/// app colours a filled one `error` on `onError` through `style:`.
Widget kitSpecimenButtonDanger() => Center(
  child: Builder(
    builder: (context) {
      final c = context.expressiveTheme.colors;
      return ExpressiveFilledButton(
        'Delete trip',
        style: ExpressiveFilledButton.styleFrom(
          backgroundColor: c.error,
          foregroundColor: c.onError,
        ),
        icon: ExpressiveSymbols.delete,
        onPressed: _noop,
      );
    },
  ),
);

/// A tonal toggle, on: its corners squared.
Widget kitSpecimenToggleButtonOn() => Center(
  child: ExpressiveToggleButton(
    value: true,
    onChanged: (_) {},
    label: 'Mute',
    icon: ExpressiveSymbols.volumeOff,
    kind: ExpressiveToggleButtonKind.tonal,
  ),
);

/// Three tonal buttons sharing the width.
Widget kitSpecimenButtonGroupReply() => const ExpressiveButtonGroup(
  expand: true,
  children: <Widget>[
    ExpressiveFilledButton.tonal(
      'Reply',
      icon: ExpressiveSymbols.reply,
      onPressed: _noop,
    ),
    ExpressiveFilledButton.tonal(
      'Forward',
      icon: ExpressiveSymbols.send,
      onPressed: _noop,
    ),
    ExpressiveFilledButton.tonal(
      'Archive',
      icon: ExpressiveSymbols.archive,
      onPressed: _noop,
    ),
  ],
);

/// Day, week or month: the connected group, week chosen.
Widget kitSpecimenSegmentedRange() => ExpressiveSegmentedButton<String>(
  segments: const <ExpressiveButtonSegment<String>>[
    ExpressiveButtonSegment('day', 'Day'),
    ExpressiveButtonSegment('week', 'Week'),
    ExpressiveButtonSegment('month', 'Month'),
  ],
  value: 'week',
  onChanged: (_) {},
);

/// Wi-Fi, pets or breakfast: the connected group choosing several, Wi-Fi
/// and breakfast chosen.
Widget kitSpecimenSegmentedAmenities() =>
    ExpressiveMultiChoiceSegmentedButton<String>(
      emptySelectionAllowed: true,
      kind: ExpressiveToggleButtonKind.tonal,
      segments: const <ExpressiveButtonSegment<String>>[
        ExpressiveButtonSegment('wifi', 'Wi-Fi', icon: ExpressiveSymbols.wifi),
        ExpressiveButtonSegment('pets', 'Pets', icon: ExpressiveSymbols.pets),
        ExpressiveButtonSegment(
          'breakfast',
          'Breakfast',
          icon: ExpressiveSymbols.localCafe,
        ),
      ],
      value: const <String>{'wifi', 'breakfast'},
      onChanged: (_) {},
    );

/// A link on its own line.
Widget kitSpecimenLinkRules() =>
    const ExpressiveLink('Read the house rules', onPressed: _noop);

class _Busy extends StatelessWidget {
  const _Busy();

  @override
  Widget build(BuildContext context) =>
      kitSection('Busy', children: <Widget>[kitSpecimenButtonBusy()]);
}

/// A filled and a tonal button waiting on their own action, beside one at
/// rest: the same size and colours, a loading indicator for the label.
Widget kitSpecimenButtonBusy() => Wrap(
  spacing: kitGap,
  runSpacing: kitGap,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    ExpressiveFilledButton('Pay', onPressed: () {}, busy: true),
    ExpressiveFilledButton.tonal('Sync', onPressed: () {}, busy: true),
    ExpressiveFilledButton('Pay', onPressed: () {}),
  ],
);

class _ToggleGroups extends StatefulWidget {
  const _ToggleGroups();

  @override
  State<_ToggleGroups> createState() => _ToggleGroupsState();
}

class _ToggleGroupsState extends State<_ToggleGroups> {
  String _align = 'start';
  Set<String> _marks = <String>{'bold'};

  @override
  Widget build(BuildContext context) => kitSection(
    'Toggle group · one, or several, on',
    children: <Widget>[
      ExpressiveToggleGroup<String>(
        label: 'Alignment',
        value: _align,
        onChanged: (v) => setState(() => _align = v),
        segments: const <ExpressiveButtonSegment<String>>[
          ExpressiveButtonSegment('start', 'Start'),
          ExpressiveButtonSegment('center', 'Centre'),
          ExpressiveButtonSegment('end', 'End'),
        ],
      ),
      const SizedBox(height: ExpressiveSpacing.s16),
      ExpressiveToggleGroup<String>.multiple(
        label: 'Text style',
        kind: ExpressiveToggleButtonKind.tonal,
        values: _marks,
        onChanged: (v) => setState(() => _marks = v),
        segments: const <ExpressiveButtonSegment<String>>[
          ExpressiveButtonSegment('bold', 'Bold'),
          ExpressiveButtonSegment('italic', 'Italic'),
          ExpressiveButtonSegment('underline', 'Underline'),
        ],
      ),
    ],
  );
}

/// Three alignments, Centre on.
Widget kitSpecimenToggleGroupAlign() => ExpressiveToggleGroup<String>(
  label: 'Alignment',
  value: 'center',
  onChanged: (_) {},
  segments: const <ExpressiveButtonSegment<String>>[
    ExpressiveButtonSegment('start', 'Start'),
    ExpressiveButtonSegment('center', 'Centre'),
    ExpressiveButtonSegment('end', 'End'),
  ],
);
