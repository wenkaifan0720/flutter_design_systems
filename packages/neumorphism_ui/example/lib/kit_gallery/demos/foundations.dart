/// The theme's type and colours and the page frame: NeumorphicRow's spans give a desktop its columns and stack on a phone.
library;

import 'package:material_ui/material_ui.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Type, colour and the page frame',
  sections: [
    kitSection('Type', children: [const _Type()]),
    kitSection('The colours a page may read', children: [const _Swatches()]),
    kitSection('Palettes', children: [const _Palettes()]),
    kitSection(
      'The page frame',
      children: [
        const NeumorphicRow(
          spans: [7, 5],
          children: [
            NeumorphicCard(
              title: 'Seven',
              children: [NeumorphicKvRow('Spans', '7 of 12', isFirst: true)],
            ),
            NeumorphicCard(
              title: 'Five',
              children: [NeumorphicKvRow('Spans', '5 of 12', isFirst: true)],
            ),
          ],
        ),
      ],
    ),
    kitSection('An object beside its words', children: [kitSpecimenBeside()]),
  ],
);

/// The six palettes in the page's brightness, for the example's Type and colour page.
Widget kitPaletteSamples() => const _Palettes();

Widget kitSpecimenBeside() => NeumorphicBeside(
  object: const NeumorphicMonogram('AB', size: 56),
  child: const NeumorphicColumn(
    gap: 4,
    children: [
      NeumorphicEyebrow('An eyebrow'),
      NeumorphicKvRow('A label', 'A value', isFirst: true),
    ],
  ),
);

class _Type extends StatelessWidget {
  const _Type();
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context).textTheme;
    return NeumorphicColumn(
      gap: 8,
      children: [
        Text('21.5', style: t.figure),
        Text('A page title', style: t.page),
        Text('A value', style: t.value),
        Text('A row title', style: t.title),
        Text('Body words, for what a person reads.', style: t.body),
        Text('A caption, the line under a title.', style: t.caption),
        Text('A small label', style: t.micro),
      ],
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches();
  @override
  Widget build(BuildContext context) {
    final c = NeumorphicTheme.of(context).colors;
    final colours = <(String, Color)>[
      ('Wall', c.ground),
      ('Face', c.faceStart),
      ('Well', c.wellStart),
      ('Rim', c.rim),
      ('Ink', c.ink),
      ('Second ink', c.inkSecondary),
      ('Third ink', c.inkTertiary),
      ('Lamp', c.art.lamp),
    ];
    return NeumorphicGridOf(
      columns: 4,
      gap: 10,
      runGap: 10,
      children: [
        for (final (name, colour) in colours)
          NeumorphicColumn(
            gap: 4,
            children: [
              SizedBox(
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colour,
                    borderRadius: BorderRadius.circular(NeumorphicRadii.cap),
                    border: Border.all(color: c.quiet),
                  ),
                ),
              ),
              NeumorphicLabel(name),
            ],
          ),
      ],
    );
  }
}

// Each of the six palettes (NeumorphicThemeData.presets, the default first) in the page's brightness: its name over its
// wall, face, well, pigment, the pigment's words and the ink, a hairline between like ones so they stay apart.
class _Palettes extends StatelessWidget {
  const _Palettes();
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final brightness = c.dark ? Brightness.dark : Brightness.light;
    final corner = BorderRadius.circular(NeumorphicRadii.cap);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: NeumorphicColumn(
          gap: 12,
          children: [
            for (final id in NeumorphicThemeData.presets)
              NeumorphicColumn(
                gap: 4,
                children: [
                  Text(
                    id[0].toUpperCase() + id.substring(1),
                    style: t.textTheme.caption.copyWith(color: c.ink),
                  ),
                  ExcludeSemantics(
                    child: SizedBox(
                      height: 24,
                      child: DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(
                          borderRadius: corner,
                          border: Border.all(color: c.edge),
                        ),
                        child: ClipRRect(
                          borderRadius: corner,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, colour) in _strip(
                                NeumorphicThemeData.preset(
                                  id,
                                  brightness,
                                ).colors,
                              ).indexed) ...[
                                if (i > 0)
                                  SizedBox(
                                    width: 1,
                                    child: ColoredBox(color: c.edge),
                                  ),
                                Expanded(child: ColoredBox(color: colour)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static List<Color> _strip(NeumorphicColors p) => [
    p.ground,
    p.faceStart,
    p.wellStart,
    p.accent,
    p.accentInk,
    p.ink,
  ];
}
