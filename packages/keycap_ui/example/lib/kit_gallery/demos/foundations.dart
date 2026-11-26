import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The colourway, the cap and the type.
Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Type and colour',
  sections: const [_Colourway(), _Colourways(), _Type()],
);

class _Colourway extends StatelessWidget {
  const _Colourway();

  @override
  Widget build(BuildContext context) {
    final theme = context.keycapTheme;
    final c = theme.colors;
    Widget cap(String name, KeycapCapColors k, String role) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 56,
            child: KeycapCap(
              face: KeycapFace.of(k, c),
              walls: KeycapMetrics.walls(56),
              child: Center(
                child: Text(
                  name,
                  style: theme.textTheme.label.copyWith(color: k.legend),
                ),
              ),
            ),
          ),
          const SizedBox(height: KeycapSpacing.small),
          Text(role, style: theme.textTheme.secondary),
        ],
      ),
    );
    const gap = SizedBox(width: KeycapSpacing.small);
    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [a, gap, b],
    );
    final alpha = cap('Alpha', c.alpha, 'Neutral');
    final mod = cap('Mod', c.modifier, 'Secondary, latched');
    final enter = cap('Enter', c.accent, 'The main action');
    final del = cap('Del', c.danger, 'Confirms a loss');
    return KitSection(
      title: 'The colourway',
      note: 'Each kind of key in its own plastic; the roles never swap.',
      children: [
        // Two by two at a large text size, where four in a row cut their
        // legends and break their roles' words.
        if (MediaQuery.textScalerOf(context).scale(16) > 24) ...[
          pair(alpha, mod),
          const SizedBox(height: KeycapSpacing.regular),
          pair(enter, del),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [alpha, gap, mod, gap, enter, gap, del],
          ),
      ],
    );
  }
}

// Each of Keycap's colourways at the page's brightness: a piece of its case
// holding an alpha, a modifier and its accent key, named under it.
class _Colourways extends StatelessWidget {
  const _Colourways();

  @override
  Widget build(BuildContext context) {
    final page = context.keycapTheme;
    final brightness = page.colors.brightness;
    Widget cap(KeycapColors c, KeycapCapColors k, Widget legend) => Expanded(
      child: KeycapCap(
        face: KeycapFace.of(k, c),
        walls: KeycapMetrics.walls(32),
        child: Center(
          child: IconTheme.merge(
            data: IconThemeData(color: k.legend, size: 16),
            child: legend,
          ),
        ),
      ),
    );
    return KitSection(
      title: 'Colourways',
      note:
          'Six colourways, each the classic keyboard\'s plastics at the same '
          'tones in other hues: classic, retro, sage, rose, lilac and ocean '
          '(KeycapThemeData.preset).',
      children: [
        LayoutBuilder(
          builder: (context, box) {
            // Six, three or two across, so the rows come out even.
            const gap = KeycapSpacing.small;
            final across = box.maxWidth >= 6 * 120 + 5 * gap
                ? 6
                : box.maxWidth >= 3 * 120 + 2 * gap
                ? 3
                : 2;
            final width = ((box.maxWidth - (across - 1) * gap) / across)
                .floorToDouble();
            return KitRow(
              children: [
                for (final name in KeycapThemeData.presets)
                  SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KeycapTheme(
                          data: KeycapThemeData.preset(name, brightness),
                          child: Builder(
                            builder: (context) {
                              final theme = context.keycapTheme;
                              final c = theme.colors;
                              final s = theme.textTheme.secondary;
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  color: c.ground,
                                  border: Border.all(color: c.edge),
                                  borderRadius: BorderRadius.circular(
                                    KeycapMetrics.keyRadius,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    KeycapSpacing.small,
                                  ),
                                  child: SizedBox(
                                    height: 32,
                                    child: Row(
                                      children: [
                                        cap(
                                          c,
                                          c.alpha,
                                          Text(
                                            'A',
                                            style: s.copyWith(
                                              color: c.alpha.legend,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        cap(
                                          c,
                                          c.modifier,
                                          Text(
                                            'Fn',
                                            style: s.copyWith(
                                              color: c.modifier.legend,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        cap(
                                          c,
                                          c.accent,
                                          const Icon(
                                            LucideIcons.cornerDownLeft,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: KeycapSpacing.small),
                        Text(name, style: page.textTheme.secondary),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Type extends StatelessWidget {
  const _Type();

  @override
  Widget build(BuildContext context) {
    final t = context.keycapTheme.textTheme;
    return KitSection(
      title: 'Type',
      note: 'Rubik: its softened corners read like a moulded legend.',
      gap: KeycapSpacing.small,
      children: [
        Text('Talk for the allotment society', style: t.display),
        Text('Monday stand-up', style: t.title),
        Text('Garden · 2 notes', style: t.heading),
        Text(
          'Start with the frost of 3 November and what it took.',
          style: t.body,
        ),
        Text('Edited 10 minutes ago', style: t.secondary),
        Text('Continue writing', style: t.label),
        Text('PINNED DRAFT', style: t.legend),
        Text('1,204 words', style: t.figure),
      ],
    );
  }
}
