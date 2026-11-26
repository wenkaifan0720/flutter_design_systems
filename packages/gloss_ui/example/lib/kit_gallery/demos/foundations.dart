/// Gloss's foundations: its glazes and inks, its six gels, its type, its
/// three depths under one light, and its spacing.
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
    KitSection(
      title: 'Gels',
      note:
          'Six gels on the same porcelain: jade, sapphire, amethyst, amber, '
          'rose and teal (GlossThemeData.preset).',
      children: [_Gels()],
    ),
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

// Each of Gloss's gels at the page's brightness: a piece of its porcelain
// holding a pearl key and the gel's key, named under it.
class _Gels extends StatelessWidget {
  const _Gels();

  @override
  Widget build(BuildContext context) {
    final page = GlossTheme.of(context);
    final brightness = page.colors.brightness;
    Widget key(GlossFace face, String words, TextStyle style) => Expanded(
      child: SizedBox(
        height: 32,
        child: GlossSurface(
          face: face,
          child: Center(
            child: Text(
              words,
              maxLines: 1,
              style: style.copyWith(color: face.foreground),
            ),
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, box) {
        // Six, three or two across, so the rows come out even.
        const gap = GlossSpacing.small;
        final across = box.maxWidth >= 6 * 132 + 5 * gap
            ? 6
            : box.maxWidth >= 3 * 132 + 2 * gap
            ? 3
            : 2;
        final width = ((box.maxWidth - (across - 1) * gap) / across)
            .floorToDouble();
        return KitRow(
          children: [
            for (final name in GlossThemeData.presets)
              SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlossTheme(
                      data: GlossThemeData.preset(name, brightness),
                      child: Builder(
                        builder: (context) {
                          final theme = GlossTheme.of(context);
                          final c = theme.colors;
                          final s = theme.textTheme.label.copyWith(
                            fontSize: 13,
                          );
                          return GlossSurface(
                            face: GlossFace.porcelain(c, radius: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(GlossSpacing.small),
                              child: Row(
                                children: [
                                  key(
                                    GlossFace.pearl(c, radius: 16),
                                    'Back',
                                    s,
                                  ),
                                  const SizedBox(width: 6),
                                  key(GlossFace.gel(c, radius: 16), 'Save', s),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name[0].toUpperCase() + name.substring(1),
                      style: page.textTheme.secondary,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
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
