/// Buttons: [TermButton] in brackets, its filled and destructive forms,
/// [TermIconButton], and the keys written beside them ([TermKey]).
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../kit.dart';

Widget kitButtonsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'buttons',
  sections: [
    kitSection(
      'the actions of a form',
      children: [
        kitRow([
          TermButton(
            label: 'cancel',
            shortcut: const SingleActivator(LogicalKeyboardKey.escape),
            onPressed: () {},
          ),
          TermButton.filled(
            label: 'deploy',
            shortcut: const SingleActivator(LogicalKeyboardKey.enter),
            onPressed: () {},
          ),
        ]),
      ],
    ),
    kitSection(
      'destroying something',
      children: [
        kitRow([
          TermButton(
            label: 'delete project',
            isDestructiveAction: true,
            onPressed: () {},
          ),
          TermButton.filled(
            label: 'delete',
            isDestructiveAction: true,
            onPressed: () {},
          ),
        ]),
      ],
    ),
    kitSection(
      'not now',
      children: [
        kitRow([
          const TermButton(label: 'rerun'),
          const TermButton.filled(label: 'deploy'),
        ]),
      ],
    ),
    kitSection('one glyph', children: [const _Glyphs()]),
    kitSection(
      'keys',
      children: [
        kitRow([
          TermKey.of(
            const SingleActivator(LogicalKeyboardKey.keyK, control: true),
          ),
          TermKey.of(
            const SingleActivator(LogicalKeyboardKey.digit2, alt: true),
          ),
          TermKey.of(
            const SingleActivator(LogicalKeyboardKey.enter, shift: true),
          ),
          TermKey(
            termKeyLabel(const SingleActivator(LogicalKeyboardKey.space)),
          ),
        ]),
      ],
    ),
  ],
);

class _Glyphs extends StatefulWidget {
  const _Glyphs();

  @override
  State<_Glyphs> createState() => _GlyphsState();
}

class _GlyphsState extends State<_Glyphs> {
  bool _follow = true;

  @override
  Widget build(BuildContext context) => kitRow([
    TermIconButton(glyph: '/', semanticLabel: 'search', onPressed: () {}),
    TermIconButton(glyph: '?', semanticLabel: 'help', onPressed: () {}),
    TermIconButton(
      glyph: '↓',
      semanticLabel: 'follow the log',
      selected: _follow,
      onPressed: () => setState(() => _follow = !_follow),
    ),
    const TermIconButton(glyph: '×', semanticLabel: 'close'),
  ]);
}
