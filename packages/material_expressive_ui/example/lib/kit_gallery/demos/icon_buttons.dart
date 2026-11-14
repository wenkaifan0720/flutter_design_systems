/// The icon-buttons group's demo: the four styles, the size ladder (L and
/// XL as the page's one hero moment), narrow / uniform / wide, round and
/// square, toggles that fill as they check, the ambient and vibrant
/// colours, and the disabled state.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The icon-buttons group's demo, in [brightness].
Widget kitIconButtonsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Icon buttons',
  sections: const <Widget>[
    _Styles(),
    _Sizes(),
    _Hero(),
    _Widths(),
    _Shapes(),
    _Toggles(),
    _Colours(),
    _Disabled(),
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
    'Four styles, lowest emphasis first',
    children: <Widget>[
      _wrap(const <Widget>[
        ExpressiveIconButton(
          ExpressiveSymbols.skipPrevious,
          semanticLabel: 'Previous track',
          onPressed: _noop,
        ),
        ExpressiveIconButton.outlined(
          ExpressiveSymbols.shuffle,
          semanticLabel: 'Shuffle',
          onPressed: _noop,
        ),
        ExpressiveIconButton.filledTonal(
          ExpressiveSymbols.playlistAdd,
          semanticLabel: 'Add to playlist',
          onPressed: _noop,
        ),
        ExpressiveIconButton.filled(
          ExpressiveSymbols.playArrow,
          semanticLabel: 'Play',
          onPressed: _noop,
        ),
      ]),
      const _Caption(
        'Standard, outlined, tonal, filled. Press and hold: the corners '
        'tighten on a spring that never bounces.',
      ),
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
        ExpressiveIconButton.filled(
          ExpressiveSymbols.edit,
          size: ExpressiveIconButtonSize.extraSmall,
          semanticLabel: 'Edit',
          onPressed: _noop,
        ),
        ExpressiveIconButton.filled(
          ExpressiveSymbols.edit,
          semanticLabel: 'Edit',
          onPressed: _noop,
        ),
        ExpressiveIconButton.filled(
          ExpressiveSymbols.edit,
          size: ExpressiveIconButtonSize.medium,
          semanticLabel: 'Edit',
          onPressed: _noop,
        ),
      ]),
      _wrap(const <Widget>[
        ExpressiveIconButton.filledTonal(
          ExpressiveSymbols.share,
          size: ExpressiveIconButtonSize.extraSmall,
          semanticLabel: 'Share',
          onPressed: _noop,
        ),
        ExpressiveIconButton.filledTonal(
          ExpressiveSymbols.share,
          semanticLabel: 'Share',
          onPressed: _noop,
        ),
        ExpressiveIconButton.filledTonal(
          ExpressiveSymbols.share,
          size: ExpressiveIconButtonSize.medium,
          semanticLabel: 'Share',
          onPressed: _noop,
        ),
      ]),
    ],
  );
}

/// L and XL are hero sizes: the page spends its one hero moment on them.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => kitSection(
    'Hero sizes · L 96 · XL 136',
    children: <Widget>[
      ExpressiveHeroMoment(
        label: 'record',
        child: _wrap(const <Widget>[
          ExpressiveIconButton.filledTonal(
            ExpressiveSymbols.pause,
            size: ExpressiveIconButtonSize.large,
            semanticLabel: 'Pause',
            onPressed: _noop,
          ),
          ExpressiveIconButton.filled(
            ExpressiveSymbols.mic,
            size: ExpressiveIconButtonSize.extraLarge,
            shape: ExpressiveIconButtonShape.square,
            semanticLabel: 'Record',
            onPressed: _noop,
          ),
        ]),
      ),
      const _Caption('One hero moment per page: the primary action only.'),
    ],
  );
}

class _Widths extends StatelessWidget {
  const _Widths();

  @override
  Widget build(BuildContext context) => kitSection(
    'Narrow · uniform · wide',
    children: <Widget>[
      _wrap(const <Widget>[
        ExpressiveIconButton.filledTonal(
          ExpressiveSymbols.zoomOut,
          width: ExpressiveIconButtonWidth.narrow,
          semanticLabel: 'Zoom out',
          onPressed: _noop,
        ),
        ExpressiveIconButton.filledTonal(
          ExpressiveSymbols.fullscreen,
          semanticLabel: 'Fit to screen',
          onPressed: _noop,
        ),
        ExpressiveIconButton.filledTonal(
          ExpressiveSymbols.zoomIn,
          width: ExpressiveIconButtonWidth.wide,
          semanticLabel: 'Zoom in',
          onPressed: _noop,
        ),
      ]),
      _wrap(const <Widget>[
        ExpressiveIconButton.filled(
          ExpressiveSymbols.remove,
          size: ExpressiveIconButtonSize.medium,
          width: ExpressiveIconButtonWidth.narrow,
          semanticLabel: 'Fewer guests',
          onPressed: _noop,
        ),
        ExpressiveIconButton.filled(
          ExpressiveSymbols.add,
          size: ExpressiveIconButtonSize.medium,
          width: ExpressiveIconButtonWidth.wide,
          semanticLabel: 'More guests',
          onPressed: _noop,
        ),
      ]),
    ],
  );
}

class _Shapes extends StatelessWidget {
  const _Shapes();

  @override
  Widget build(BuildContext context) => kitSection(
    'Round · square',
    children: <Widget>[
      _wrap(const <Widget>[
        ExpressiveIconButton.filled(
          ExpressiveSymbols.photoCamera,
          size: ExpressiveIconButtonSize.medium,
          semanticLabel: 'Take photo',
          onPressed: _noop,
        ),
        ExpressiveIconButton.filled(
          ExpressiveSymbols.photoCamera,
          size: ExpressiveIconButtonSize.medium,
          shape: ExpressiveIconButtonShape.square,
          semanticLabel: 'Take photo',
          onPressed: _noop,
        ),
        ExpressiveIconButton.outlined(
          ExpressiveSymbols.image,
          size: ExpressiveIconButtonSize.medium,
          semanticLabel: 'Gallery',
          onPressed: _noop,
        ),
        ExpressiveIconButton.outlined(
          ExpressiveSymbols.image,
          size: ExpressiveIconButtonSize.medium,
          shape: ExpressiveIconButtonShape.square,
          semanticLabel: 'Gallery',
          onPressed: _noop,
        ),
      ]),
    ],
  );
}

/// Toggles in every style: tap to check — the glyph fills and the corners
/// morph to the checked shape.
class _Toggles extends StatefulWidget {
  const _Toggles();

  @override
  State<_Toggles> createState() => _TogglesState();
}

class _TogglesState extends State<_Toggles> {
  final Map<String, bool> _on = <String, bool>{
    'favorite': true,
    'bookmark': false,
    'notifications': true,
    'pin': false,
    'star': false,
    'mic': true,
  };

  Widget _toggle(
    String id,
    IconData icon,
    String label,
    ExpressiveIconButtonKind style, {
    ExpressiveIconButtonShape shape = ExpressiveIconButtonShape.round,
    ExpressiveIconButtonSize size = ExpressiveIconButtonSize.small,
  }) => switch (style) {
    ExpressiveIconButtonKind.standard => ExpressiveIconToggleButton(
      icon,
      value: _on[id]!,
      shape: shape,
      size: size,
      semanticLabel: label,
      onChanged: (value) => setState(() => _on[id] = value),
    ),
    ExpressiveIconButtonKind.filled => ExpressiveIconToggleButton.filled(
      icon,
      value: _on[id]!,
      shape: shape,
      size: size,
      semanticLabel: label,
      onChanged: (value) => setState(() => _on[id] = value),
    ),
    ExpressiveIconButtonKind.filledTonal =>
      ExpressiveIconToggleButton.filledTonal(
        icon,
        value: _on[id]!,
        shape: shape,
        size: size,
        semanticLabel: label,
        onChanged: (value) => setState(() => _on[id] = value),
      ),
    ExpressiveIconButtonKind.outlined => ExpressiveIconToggleButton.outlined(
      icon,
      value: _on[id]!,
      shape: shape,
      size: size,
      semanticLabel: label,
      onChanged: (value) => setState(() => _on[id] = value),
    ),
  };

  @override
  Widget build(BuildContext context) => kitSection(
    'Toggles · tap to check',
    children: <Widget>[
      _wrap(<Widget>[
        _toggle(
          'favorite',
          ExpressiveSymbols.favorite,
          'Favourite',
          ExpressiveIconButtonKind.standard,
        ),
        _toggle(
          'bookmark',
          ExpressiveSymbols.bookmark,
          'Save',
          ExpressiveIconButtonKind.outlined,
        ),
        _toggle(
          'notifications',
          ExpressiveSymbols.notifications,
          'Notify me',
          ExpressiveIconButtonKind.filledTonal,
        ),
        _toggle(
          'pin',
          ExpressiveSymbols.pushPin,
          'Pin',
          ExpressiveIconButtonKind.filled,
        ),
      ]),
      _wrap(<Widget>[
        _toggle(
          'star',
          ExpressiveSymbols.star,
          'Star',
          ExpressiveIconButtonKind.filledTonal,
          size: ExpressiveIconButtonSize.medium,
        ),
        _toggle(
          'mic',
          ExpressiveSymbols.mic,
          'Microphone',
          ExpressiveIconButtonKind.filled,
          size: ExpressiveIconButtonSize.medium,
          shape: ExpressiveIconButtonShape.square,
        ),
      ]),
      const _Caption(
        'A round toggle checks to square corners; a square one checks round.',
      ),
    ],
  );
}

/// Standard and outlined buttons take the ambient icon colour; `vibrant`
/// takes the tokens' own.
class _Colours extends StatelessWidget {
  const _Colours();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Ambient · vibrant',
      children: <Widget>[
        _wrap(<Widget>[
          const ExpressiveIconButton(
            ExpressiveSymbols.moreVert,
            semanticLabel: 'More',
            onPressed: _noop,
          ),
          const ExpressiveIconButton(
            ExpressiveSymbols.moreVert,
            vibrant: true,
            semanticLabel: 'More',
            onPressed: _noop,
          ),
          const ExpressiveIconButton.outlined(
            ExpressiveSymbols.tune,
            semanticLabel: 'Filters',
            onPressed: _noop,
          ),
          const ExpressiveIconButton.outlined(
            ExpressiveSymbols.tune,
            vibrant: true,
            semanticLabel: 'Filters',
            onPressed: _noop,
          ),
          IconTheme.merge(
            data: IconThemeData(color: t.colors.tertiary),
            child: const ExpressiveIconButton(
              ExpressiveSymbols.eco,
              semanticLabel: 'Eco mode',
              onPressed: _noop,
            ),
          ),
        ]),
        const _Caption(
          'Ambient follows the surface\'s content colour (the last one sits '
          'under a tertiary tint); vibrant uses on-surface-variant.',
        ),
      ],
    );
  }
}

class _Disabled extends StatelessWidget {
  const _Disabled();

  @override
  Widget build(BuildContext context) => kitSection(
    'Disabled',
    children: <Widget>[
      _wrap(const <Widget>[
        ExpressiveIconButton(
          ExpressiveSymbols.delete,
          semanticLabel: 'Delete',
          onPressed: null,
        ),
        ExpressiveIconButton.outlined(
          ExpressiveSymbols.delete,
          semanticLabel: 'Delete',
          onPressed: null,
        ),
        ExpressiveIconButton.filledTonal(
          ExpressiveSymbols.delete,
          semanticLabel: 'Delete',
          onPressed: null,
        ),
        ExpressiveIconButton.filled(
          ExpressiveSymbols.delete,
          semanticLabel: 'Delete',
          onPressed: null,
        ),
        ExpressiveIconToggleButton.filled(
          ExpressiveSymbols.favorite,
          value: true,
          semanticLabel: 'Favourite',
          onChanged: null,
        ),
      ]),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// A tonal icon button.
Widget kitSpecimenIconButtonTonal() => const Center(
  child: ExpressiveIconButton.filledTonal(
    ExpressiveSymbols.edit,
    semanticLabel: 'Edit',
    onPressed: _noop,
  ),
);

/// A favourite toggled on.
Widget kitSpecimenIconToggleOn() => Center(
  child: ExpressiveIconToggleButton(
    ExpressiveSymbols.favorite,
    value: true,
    onChanged: (_) {},
    semanticLabel: 'Favourite',
  ),
);
