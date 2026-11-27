import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

import '../kit.dart';

/// The foundations: the three depths under one light, the metal and the
/// glass, the indicator lamp, the readout, the type.
Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Metal, glass and light',
  sections: [
    KitSection(
      title: 'Three depths',
      note:
          'One light from the top. A key stands proud and casts a shadow; a '
          'panel lies flush; glass is set in, its shadow falling inside.',
      children: [
        Builder(
          builder: (context) {
            final c = StudioTheme.of(context).colors;
            Widget swatch(String name, StudioFace face) => Column(
              children: [
                SizedBox(
                  width: 96,
                  height: 64,
                  child: StudioSurface(face: face),
                ),
                const SizedBox(height: StudioSpacing.small),
                Text(name),
              ],
            );
            return KitRow(
              children: [
                swatch('Raised', c.keyFace),
                swatch('Level', c.panelFace),
                swatch('Sunk', c.displayFace),
                swatch('Readout', c.readoutFace),
              ],
            );
          },
        ),
      ],
    ),
    KitSection(
      title: 'The lamp',
      note: 'The one accent: something is on. Red only for a live take or a failure.',
      children: [
        Builder(
          builder: (context) {
            final c = StudioTheme.of(context).colors;
            return KitRow(
              children: [
                const StudioLamp(on: false, size: 10),
                const StudioLamp(on: true, size: 10),
                StudioLamp(on: true, size: 10, color: c.danger),
                const StudioReadout('1:04:09'),
                const StudioReadout('-6', unit: ' dB'),
              ],
            );
          },
        ),
      ],
    ),
    KitSection(
      title: 'Presets',
      note:
          'Six finishes, each by day and by night: the metal, its legend, the '
          'lamp and the readout glass. StudioThemeData.preset(id, brightness) '
          'picks one.',
      children: const [_Presets()],
    ),
    KitSection(
      title: 'Type',
      note: 'Barlow throughout. Legends engraved in small capitals where the script has them; sentence case everywhere else.',
      children: [
        Builder(
          builder: (context) {
            final t = StudioTheme.of(context).textTheme;
            final c = StudioTheme.of(context).colors;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display 34', style: t.display.copyWith(color: c.legend)),
                Text(
                  'Headline 24',
                  style: t.headline.copyWith(color: c.legend),
                ),
                Text('Title 17', style: t.title),
                Text(
                  'Body 16: what people read.',
                  style: t.body.copyWith(color: c.legend),
                ),
                Text('Label 15', style: t.label),
                Text(
                  'Secondary 14',
                  style: t.secondary.copyWith(color: c.legendMuted),
                ),
                Text(
                  'Caption 13',
                  style: t.caption.copyWith(color: c.legendMuted),
                ),
                const SizedBox(height: StudioSpacing.small),
                const StudioLegend('Audio quality'),
                const StudioLegend('جودة الصوت'),
              ],
            );
          },
        ),
      ],
    ),
    KitSection(
      title: 'Page change',
      note:
          'StudioPageTransitionsBuilder: a page slides 40 px in on its rails from the end side, as a module into a rack, '
          'and the page it covers dims; back is the reverse. Give an app studioPageTransitions.',
      children: [
        Builder(
          builder: (context) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: StudioButton(
              'Open a page',
              onPressed: () => Navigator.of(context).push(
                PageRouteBuilder<void>(
                  transitionDuration:
                      const StudioPageTransitionsBuilder().transitionDuration,
                  reverseTransitionDuration:
                      const StudioPageTransitionsBuilder()
                          .reverseTransitionDuration,
                  pageBuilder: (context, _, _) => const _PageChangeDemo(),
                  transitionsBuilder: (context, animation, secondary, child) =>
                      const StudioPageTransitionsBuilder().buildTransitions(
                        ModalRoute.of(context)! as PageRoute<void>,
                        context,
                        animation,
                        secondary,
                        child,
                      ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ],
);

/// Studio's presets, each by day and by night.
class _Presets extends StatelessWidget {
  const _Presets();

  /// Each preset in a line.
  static const Map<String, String> _about = {
    'anodised': 'Silver and graphite under an amber lamp',
    'cobalt': 'Blue-anodised metal under a blue lamp',
    'teal': 'Blue-green steel under a teal lamp',
    'moss': 'Olive metal under a green lamp',
    'violet': 'Plum metal under a violet lamp',
    'graphite': 'Neutral steel under a cool white lamp',
  };

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final id in [for (final p in StudioThemeData.palettes) p.id])
          Padding(
            padding: const EdgeInsets.only(bottom: StudioSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: t.label.copyWith(color: c.legend)),
                Text(
                  _about[id] ?? '',
                  style: t.caption.copyWith(color: c.legendMuted),
                ),
                const SizedBox(height: StudioSpacing.small),
                Wrap(
                  spacing: StudioSpacing.small,
                  runSpacing: StudioSpacing.small,
                  children: [
                    _PresetTile(id, Brightness.light),
                    _PresetTile(id, Brightness.dark),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One preset in one appearance: its metal, its legend, its lamp and its
/// readout glass.
class _PresetTile extends StatelessWidget {
  const _PresetTile(this.id, this.brightness);

  final String id;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final night = brightness == Brightness.dark;
    return Semantics(
      label: '$id, ${night ? 'night' : 'day'}',
      excludeSemantics: true,
      child: StudioTheme(
        data: StudioThemeData.preset(id, brightness),
        child: Builder(
          builder: (context) {
            final theme = StudioTheme.of(context);
            final c = theme.colors;
            return Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsetsDirectional.fromSTEB(
                StudioSpacing.small,
                StudioSpacing.tight,
                StudioSpacing.tight,
                StudioSpacing.tight,
              ),
              decoration: BoxDecoration(
                color: c.chassis,
                borderRadius: BorderRadius.circular(StudioRadii.key),
                border: Border.all(color: c.groove),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StudioLamp(on: true, size: 8),
                  const SizedBox(width: StudioSpacing.small),
                  Text(
                    'Aa',
                    style: theme.textTheme.label.copyWith(color: c.legend),
                  ),
                  const SizedBox(width: StudioSpacing.small),
                  // The readout glass and its figures: lit glass under dark
                  // figures by day, figures glowing on dark glass by night.
                  StudioSurface(
                    face: c.readoutFace.copyWith(radius: StudioRadii.key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: StudioSpacing.small - 2,
                        vertical: 2,
                      ),
                      child: Text(
                        '42',
                        style: theme.textTheme.readout.copyWith(
                          fontSize: 13,
                          height: 20 / 13,
                          color: c.readoutLit,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PageChangeDemo extends StatelessWidget {
  const _PageChangeDemo();

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return ColoredBox(
      color: c.chassis,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioAppBar(
            title: 'A page',
            leading: StudioIconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const Expanded(child: Center(child: Text('Slid in on its rails.'))),
        ],
      ),
    );
  }
}
