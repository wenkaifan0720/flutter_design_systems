/// The theme's type and colours and the page frame: ComicRow's spans give a desktop its columns and stack on a phone.
library;

import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';

Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Type, colour and the page frame',
  sections: [
    kitSection('Type', children: [const KitTypeScale()]),
    kitSection('The colours', children: [const KitSwatches()]),
    kitSection('The print runs', children: [const KitPrintRuns()]),
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

Widget kitSpecimenBeside() => Builder(
  builder: (context) => ComicBeside(
    object: const ComicPerson(initials: 'AC', size: 56),
    child: ComicColumn(
      gap: 4,
      children: [
        ComicLabel(kitSay(context, 'A label')),
        ComicKvRow(
          kitSay(context, 'A name'),
          kitSay(context, 'A value'),
          isFirst: true,
        ),
      ],
    ),
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
        Text(kitSay(context, 'A SECTION'), style: t.section),
        Text(kitSay(context, 'A PANEL'), style: t.panel),
        Text(kitSay(context, 'A LINE IN THE LETTERING'), style: t.item),
        Text(kitSay(context, 'A title on a row'), style: t.title),
        Text(
          kitSay(context, 'Body words, for what a person reads.'),
          style: t.body,
        ),
        Text(
          kitSay(context, 'Small words, the line under a title.'),
          style: t.small,
        ),
        Text(kitSay(context, 'A LABEL'), style: t.label),
      ],
    );
  }
}

/// The six print runs ([ComicThemeData.presets]) in the page's appearance, each a page of its own under its own
/// theme: its name in a caption, its act's button and its group's link, the parts themselves.
class KitPrintRuns extends StatelessWidget {
  /// The look's print runs.
  const KitPrintRuns({super.key});
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return ComicGridOf(
      columns: t.desk ? 3 : 2,
      children: [
        for (final id in ComicThemeData.presets)
          ComicTheme(
            data: ComicThemeData.preset(id, t.colors.brightness),
            child: Builder(
              builder: (context) {
                final run = ComicTheme.of(context);
                return DecoratedBox(
                  decoration: ShapeDecoration(
                    color: run.colors.background,
                    shape: run.shapes.small.copyWith(
                      side: BorderSide(color: run.colors.nightLine, width: 2.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ComicColumn(
                      gap: 8,
                      children: [
                        // The run's name as the code names it, in its caption box; its act and its group's link.
                        ComicCaption(id, free: true, tight: true),
                        ComicButton.filled(
                          kitSay(context, 'Read on'),
                          onPressed: () {},
                        ),
                        ComicLink(
                          kitSay(context, 'See all'),
                          inSentence: false,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
      (kitSay(context, 'Lamp'), c.caption),
      (kitSay(context, 'Act'), c.primary),
      (kitSay(context, 'Shade'), c.shade),
      (kitSay(context, 'Drama'), c.drama),
      (kitSay(context, 'Ground'), c.background),
      (kitSay(context, 'Panel'), c.card),
      (kitSay(context, 'Well'), c.inset),
      // The line every frame is drawn in: black by day, cream at night (the print keeps its black contour).
      (kitSay(context, 'Line'), c.nightLine),
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
