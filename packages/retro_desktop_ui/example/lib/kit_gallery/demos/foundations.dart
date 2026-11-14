/// The theme's type and colours and the page frame: a desktop of windows, tiled from 1024 wide and stacked on a phone.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../kit.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../demo_art.dart';

Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Type, colour and the page frame',
  sections: [
    kitSection('Type', children: [const _Type()]),
    kitSection('Colour', children: [const _Swatches()]),
    kitSection(
      'Keyboard and pointer states',
      children: [const _InteractionStates()],
    ),
    kitSection('An object beside its words', children: [kitSpecimenBeside()]),
  ],
);

/// The type scale, for the example's Type and colour page.
Widget kitTypeSamples() => const _Type();

/// The palette's swatches, for the example's Type and colour page.
Widget kitColourSamples() => const _Swatches();

/// Every pointer and keyboard state on one row, for the example's overview.
Widget kitStateSamples() => const _InteractionStates();

class _InteractionStates extends StatefulWidget {
  const _InteractionStates();
  @override
  State<_InteractionStates> createState() => _InteractionStatesState();
}

class _InteractionStatesState extends State<_InteractionStates> {
  int count = 0;
  // The look's own button shows each state on its face (the ring on focus, the bevel turned in while held, grey words
  // when unavailable): a hand-drawn paper box read as a text field, and bare grey words as a caption.
  @override
  Widget build(BuildContext context) => Wrap(
    // The count on the buttons' middle, as words beside a control sit.
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 12,
    children: [
      RetroDesktopButton('Activate', onPressed: () => setState(() => count++)),
      const RetroDesktopButton('Disabled', onPressed: null),
      Text('Tab to it, then Enter or Space. Activations: $count'),
    ],
  );
}

Widget kitSpecimenBeside() => RetroDesktopBeside(
  object: RetroDesktopDeskArt(RetroDesktopDeskMark.disk),
  child: RetroDesktopDescriptionList([
    RetroDesktopFact('Holds', '1.4 GB'),
    RetroDesktopFact('Free', '3.6 GB'),
  ]),
);

class _Type extends StatelessWidget {
  const _Type();
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context).type;
    return RetroDesktopColumn(
      gap: 8,
      children: [
        Text('14:40', style: t.big),
        Text('A big title', style: t.title),
        Text('A head', style: t.head),
        Text('The chrome of a window', style: t.chrome),
        Text('Words to read, set for a long line.', style: t.read),
        Text('Body words, for what a person reads.', style: t.body),
        Text('Small words, the line under a title.', style: t.meta),
        Text('1,204.50  09:14', style: t.figure),
      ],
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches();
  @override
  Widget build(BuildContext context) {
    final c = RetroDesktopTheme.of(context).colors;
    final colours = <(String, Color)>[
      ('Desk', c.desktop),
      ('Window', c.platinum),
      ('Paper', c.paper),
      ('Lit', c.highlight),
      ('Tint', c.highlightContainer),
      ('Hatch', c.hatch),
      ('Edge', c.outline),
      ('Ink', c.text),
    ];
    // As many columns as the longest name fits whole (at twice the text size four broke "Window" in two).
    final meta = RetroDesktopTheme.of(context).type.meta;
    final scaler = MediaQuery.textScalerOf(context);
    final widest = colours.fold(0.0, (w, e) {
      final p = TextPainter(
        text: TextSpan(text: e.$1, style: meta),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = p.width;
      p.dispose();
      return width > w ? width : w;
    });
    return LayoutBuilder(
      builder: (context, box) => RetroDesktopGridOf(
        columns: box.hasBoundedWidth
            ? ((box.maxWidth + 8) / (widest.ceilToDouble() + 8)).floor().clamp(
                1,
                4,
              )
            : 4,
        gap: 8,
        runGap: 8,
        children: [
          for (final (name, colour) in colours)
            RetroDesktopColumn(
              gap: 4,
              children: [
                SizedBox(
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colour,
                      border: Border.all(color: c.outline),
                    ),
                  ),
                ),
                Text(name, style: meta),
              ],
            ),
        ],
      ),
    );
  }
}
