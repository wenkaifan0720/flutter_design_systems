/// Gloss's foundations: its glazes and inks, its type, its three depths
/// under one light, and its spacing.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../kit.dart';

/// The foundations page.
Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Foundations',
  sections: const [
    KitSection(
      title: 'Depths under one light',
      note:
          'Raised for what you press, level for what holds things, sunken '
          'for what holds a value.',
      children: [_Depths()],
    ),
    KitSection(title: 'Glazes', children: [_Glazes()]),
    KitSection(title: 'Type', children: [_Type()]),
    KitSection(title: 'Chrome', children: [_Chrome()]),
  ],
);

class _Depths extends StatelessWidget {
  const _Depths();

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    final t = GlossTheme.of(context).textTheme;
    Widget swatch(String name, GlossFace face) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, height: 64, child: GlossSurface(face: face)),
        const SizedBox(height: GlossSpacing.small),
        Text(name, style: t.secondary),
      ],
    );
    return KitRow(
      children: [
        swatch('Gel, raised', GlossFace.gel(c, radius: 16)),
        swatch('Pearl, raised', GlossFace.pearl(c, radius: 16)),
        swatch('Porcelain, level', GlossFace.porcelain(c, radius: 16)),
        swatch('Well, sunken', GlossFace.well(c, radius: 16)),
      ],
    );
  }
}

class _Glazes extends StatelessWidget {
  const _Glazes();

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    final t = GlossTheme.of(context).textTheme;
    Widget chip(String name, Color colour, Color words) => Container(
      width: 132,
      height: 56,
      padding: const EdgeInsets.all(GlossSpacing.small),
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(GlossMetrics.fieldRadius),
        border: Border.all(color: c.hairline),
      ),
      alignment: AlignmentDirectional.bottomStart,
      child: Text(name, style: t.caption.copyWith(color: words)),
    );
    return KitRow(
      children: [
        chip('Page', c.page, c.ink),
        chip('Well', c.well, c.ink),
        chip('Jade', c.jade, c.onJade),
        chip('Jade ink', c.well, c.jadeInk),
        chip('Ink', c.ink, c.page),
        chip('Second ink', c.well, c.inkSecondary),
        chip('Ruby', c.dangerFill, c.onDanger),
      ],
    );
  }
}

class _Type extends StatelessWidget {
  const _Type();

  @override
  Widget build(BuildContext context) {
    final t = GlossTheme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display 32', style: t.display),
        Text('Headline 24', style: t.headline),
        Text('Title 18', style: t.title),
        Text('Body 16: steps, notes and a row’s words.', style: t.body),
        Text('Label 16', style: t.label),
        Text('Secondary 14: a row’s second line.', style: t.secondary),
        Text('Caption 13', style: t.caption),
      ],
    );
  }
}

class _Chrome extends StatelessWidget {
  const _Chrome();

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(GlossMetrics.fieldRadius),
      child: GlossBar(
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text(
              'Letterpressed into the bar',
              style: glossLetterpress(theme.textTheme.title, theme.colors),
            ),
          ),
        ),
      ),
    );
  }
}
