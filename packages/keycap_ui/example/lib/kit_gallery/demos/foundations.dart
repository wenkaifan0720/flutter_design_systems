import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';

import '../kit.dart';

/// The colourway, the cap and the type.
Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Type and colour',
  sections: const [_Colourway(), _Type()],
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
    return KitSection(
      title: 'The colourway',
      note: 'Each kind of key in its own plastic; the roles never swap.',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            cap('Alpha', c.alpha, 'Neutral'),
            const SizedBox(width: KeycapSpacing.small),
            cap('Mod', c.modifier, 'Secondary, latched'),
            const SizedBox(width: KeycapSpacing.small),
            cap('Enter', c.accent, 'The main action'),
            const SizedBox(width: KeycapSpacing.small),
            cap('Del', c.danger, 'Confirms a loss'),
          ],
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
