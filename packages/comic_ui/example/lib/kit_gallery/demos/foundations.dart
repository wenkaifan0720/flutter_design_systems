/// The theme's type and colours and the page frame: ComicRow's spans give a desktop its columns and stack on a phone.
library;

import 'package:flutter/material.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';

Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Type, colour and the page frame',
  sections: [
    kitSection('Type', children: [const KitTypeScale()]),
    kitSection('The colours', children: [const KitSwatches()]),
    kitSection(
      'The page frame',
      children: [
        ComicRow(
          spans: [7, 5],
          children: [
            const ComicPanel(
              caption: 'Seven',
              child: ComicKvRow('Spans', '7 of 12', isFirst: true),
            ),
            const ComicPanel(
              caption: 'Five',
              child: ComicKvRow('Spans', '5 of 12', isFirst: true),
            ),
          ],
        ),
      ],
    ),
    kitSection('An object beside its words', children: [kitSpecimenBeside()]),
  ],
);

Widget kitSpecimenBeside() => ComicBeside(
  object: const ComicPerson(initials: 'AC', size: 56),
  child: const ComicColumn(
    gap: 4,
    children: [
      ComicLabel('A label'),
      ComicKvRow('A name', 'A value', isFirst: true),
    ],
  ),
);

/// Every type role, in its own words.
class KitTypeScale extends StatelessWidget {
  /// The look's type roles.
  const KitTypeScale({super.key});
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context).type;
    return ComicColumn(
      gap: 8,
      children: [
        Text('A SECTION', style: t.section),
        Text('A PANEL', style: t.panel),
        Text('A LINE IN THE LETTERING', style: t.item),
        Text('A title on a row', style: t.title),
        Text('Body words, for what a person reads.', style: t.body),
        Text('Small words, the line under a title.', style: t.small),
        Text('A LABEL', style: t.label),
      ],
    );
  }
}

/// The theme's named colours, each in a swatch.
class KitSwatches extends StatelessWidget {
  /// The current theme's colours.
  const KitSwatches({super.key});
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final colours = <(String, Color)>[
      ('Lamp', c.caption),
      ('Act', c.primary),
      ('Shade', c.shade),
      ('Drama', c.drama),
      ('Ground', c.background),
      ('Panel', c.card),
      ('Well', c.inset),
      // The line every frame is drawn in: black by day, cream at night (the print keeps its black contour).
      ('Line', c.nightLine),
    ];
    // Large text on a phone takes two columns, so no colour's name breaks inside a word.
    final large = MediaQuery.textScalerOf(context).scale(10) > 15;
    return ComicGridOf(
      columns: large && !t.desk ? 2 : 4,
      children: [
        for (final (name, colour) in colours)
          ComicColumn(
            gap: 4,
            children: [
              SizedBox(
                height: 40,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: colour,
                    shape: t.shapes.small.copyWith(
                      side: BorderSide(color: c.nightLine, width: 2.5),
                    ),
                  ),
                ),
              ),
              ComicLabel(name),
            ],
          ),
      ],
    );
  }
}
