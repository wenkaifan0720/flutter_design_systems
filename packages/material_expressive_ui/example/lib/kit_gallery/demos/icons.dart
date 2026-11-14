/// The icons group's demo: Material Symbols Rounded as Expressive wears
/// them — a glyph's FILL following its selected state on the fast effects
/// spring (tap one), and every bundled glyph.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The icons group's demo, in [brightness].
Widget kitIconsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Icons',
  sections: const <Widget>[_Fill(), _Solid(), _Glyphs()],
);

/// Glyphs that fill when selected: tap one to toggle it.
class _Fill extends StatefulWidget {
  const _Fill();

  @override
  State<_Fill> createState() => _FillState();
}

class _FillState extends State<_Fill> {
  static const List<(IconData, String)> _glyphs = <(IconData, String)>[
    (ExpressiveSymbols.home, 'Home'),
    (ExpressiveSymbols.favorite, 'Favourite'),
    (ExpressiveSymbols.star, 'Star'),
    (ExpressiveSymbols.bookmark, 'Bookmark'),
    (ExpressiveSymbols.notifications, 'Alerts'),
    (ExpressiveSymbols.person, 'Profile'),
  ];

  final Set<int> _selected = <int>{1, 3};

  @override
  Widget build(BuildContext context) {
    return kitSection(
      'Fill follows selection',
      children: <Widget>[
        // Standard icon toggle buttons: the glyph in `primary` and filled
        // when on, `onSurfaceVariant` and outlined when off, each in its
        // 48dp touch target and announced as a toggle.
        Wrap(
          runSpacing: kitGap,
          children: <Widget>[
            for (final (index, (icon, label)) in _glyphs.indexed)
              ExpressiveIconToggleButton(
                icon,
                value: _selected.contains(index),
                onChanged: (on) => setState(
                  () => on ? _selected.add(index) : _selected.remove(index),
                ),
                semanticLabel: label,
              ),
          ],
        ),
      ],
    );
  }
}

/// Glyphs drawn solid at rest: the ambient `IconTheme`'s fill, as a media
/// transport draws play, pause and skip.
class _Solid extends StatelessWidget {
  const _Solid();

  static const List<(IconData, String)> _glyphs = <(IconData, String)>[
    (ExpressiveSymbols.replay10, 'Back 10 seconds'),
    (ExpressiveSymbols.playArrow, 'Play'),
    (ExpressiveSymbols.pause, 'Pause'),
    (ExpressiveSymbols.forward30, 'Forward 30 seconds'),
    (ExpressiveSymbols.queueMusic, 'Up next'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.expressiveTheme.colors;
    Widget row(double fill) => IconTheme.merge(
      data: IconThemeData(fill: fill, color: c.onSurface),
      child: Wrap(
        spacing: ExpressiveSpacing.s16,
        children: <Widget>[
          for (final (icon, label) in _glyphs)
            ExpressiveIcon(icon, semanticLabel: label),
        ],
      ),
    );
    return kitSection(
      'Solid at rest · the ambient fill',
      children: <Widget>[
        row(ExpressiveSymbolsFont.outlined),
        row(ExpressiveSymbolsFont.filled),
      ],
    );
  }
}

/// Every glyph the subset bundles, outlined.
class _Glyphs extends StatefulWidget {
  const _Glyphs();

  @override
  State<_Glyphs> createState() => _GlyphsState();
}

class _GlyphsState extends State<_Glyphs> {
  static const _pageSize = 24;
  String _query = '';
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    if (KitLiveViewport.of(context)) return _browser(context);
    final c = context.expressiveTheme.colors;
    return kitSection(
      '${ExpressiveSymbols.byName.length} glyphs · ${ExpressiveSymbolsFont.family}',
      children: <Widget>[
        Wrap(
          spacing: ExpressiveSpacing.s12,
          runSpacing: ExpressiveSpacing.s12,
          children: <Widget>[
            for (final icon in ExpressiveSymbols.byName.values)
              Icon(icon, color: c.onSurface),
          ],
        ),
      ],
    );
  }

  Widget _browser(BuildContext context) {
    final theme = context.expressiveTheme;
    final query = _query.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
    final matches = ExpressiveSymbols.byName.entries
        .where((entry) => entry.key.contains(query))
        .toList();
    final pages = (matches.length / _pageSize).ceil();
    final page = pages == 0 ? 0 : _page.clamp(0, pages - 1);
    return kitSection(
      '${ExpressiveSymbols.byName.length} glyphs · ${ExpressiveSymbolsFont.family}',
      children: <Widget>[
        ExpressiveTextField(
          key: const ValueKey('gallery-symbol-filter'),
          label: 'Find symbols',
          hintText: 'Search by name',
          leading: const Icon(ExpressiveSymbols.search),
          onChanged: (value) => setState(() {
            _query = value;
            _page = 0;
          }),
        ),
        if (matches.isEmpty)
          const Text('No symbols match this name.')
        else
          Wrap(
            spacing: ExpressiveSpacing.s12,
            runSpacing: ExpressiveSpacing.s12,
            children: <Widget>[
              for (final entry
                  in matches.skip(page * _pageSize).take(_pageSize))
                SizedBox(
                  key: ValueKey('gallery-symbol/${entry.key}'),
                  width: 104,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(entry.value, color: theme.colors.onSurface),
                      const SizedBox(height: kitGap),
                      Text(
                        entry.key.replaceAll('_', ' '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.type.labelMedium.copyWith(
                          color: theme.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        Row(
          children: <Widget>[
            ExpressiveTextButton(
              'Previous',
              key: const ValueKey('gallery-symbol-previous'),
              onPressed: page == 0
                  ? null
                  : () => setState(() => _page = page - 1),
            ),
            Expanded(
              child: Text(
                '${pages == 0 ? 0 : page + 1} / $pages',
                textAlign: TextAlign.center,
              ),
            ),
            ExpressiveTextButton(
              'Next',
              key: const ValueKey('gallery-symbol-next'),
              onPressed: page + 1 >= pages
                  ? null
                  : () => setState(() => _page = page + 1),
            ),
          ],
        ),
      ],
    );
  }
}
