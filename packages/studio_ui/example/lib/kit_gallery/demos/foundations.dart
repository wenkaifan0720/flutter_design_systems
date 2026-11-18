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
