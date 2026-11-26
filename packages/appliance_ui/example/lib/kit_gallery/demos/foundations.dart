import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';

import '../kit.dart';

/// The foundations: the three depths, the lamp, the type and the colours.
Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Type and colour',
  sections: const [_Depths(), _Type(), _Colours(), _Finishes()],
);

class _Depths extends StatelessWidget {
  const _Depths();

  @override
  Widget build(BuildContext context) {
    final c = context.applianceTheme.colors;
    final t = context.applianceTheme.textTheme;
    Widget sample(String name, ApplianceFace face) => Column(
      children: [
        SizedBox(width: 88, height: 56, child: ApplianceSurface(face: face)),
        const SizedBox(height: ApplianceSpacing.small),
        Text(name, style: t.secondary),
      ],
    );
    return KitSection(
      title: 'Three depths, one light',
      note: 'Sunken wells, level faceplates, raised keys; lit from the top.',
      children: [
        KitRow(
          children: [
            sample('Sunken', ApplianceFace.well(c)),
            sample('Level', ApplianceFace.plate(c)),
            sample('Raised', ApplianceFace.key(c)),
            sample('Latched', ApplianceFace.keyDown(c)),
          ],
        ),
        const KitRow(
          children: [
            ApplianceLamp(lit: true),
            ApplianceLamp(lit: false),
            ApplianceLamp(lit: true, size: 10),
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
    final t = context.applianceTheme.textTheme;
    return KitSection(
      title: 'Type',
      note: 'Barlow. Nothing under 11 px; legends in tracked capitals.',
      gap: ApplianceSpacing.small,
      children: [
        Text('Display 30', style: t.display),
        Text('Title 22', style: t.title),
        Text('Heading 17', style: t.heading),
        Text('Body 16: what people read.', style: t.body),
        Text('Secondary 14: a supporting line.', style: t.secondary),
        Text('LEGEND 12', style: t.legend),
        Text('£24.00  £136.50', style: t.figure),
      ],
    );
  }
}

class _Colours extends StatelessWidget {
  const _Colours();

  @override
  Widget build(BuildContext context) {
    final c = context.applianceTheme.colors;
    final t = context.applianceTheme.textTheme;
    Widget chip(String name, Color colour) => SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ApplianceSurface(
              face: ApplianceFace.well(c, fill: colour, radius: 6),
            ),
          ),
          const SizedBox(height: 4),
          Text(name, style: t.secondary),
        ],
      ),
    );
    return KitSection(
      title: 'Colour',
      children: [
        KitRow(
          children: [
            chip('Housing', c.housingBottom),
            chip('Face', c.face),
            chip('Well', c.well),
            chip('Key', c.keyBottom),
            chip('Print', c.print),
            chip('Signal', c.signal),
            chip('Display', c.display),
            chip('Danger', c.danger),
          ],
        ),
      ],
    );
  }
}

// Each of Appliance's finishes at the page's brightness: a piece of its
// housing holding a key, a latched key and the signal key, named under it.
class _Finishes extends StatelessWidget {
  const _Finishes();

  @override
  Widget build(BuildContext context) {
    final page = context.applianceTheme;
    final brightness = page.colors.brightness;
    Widget key(ApplianceFace face, String legend, TextStyle style) => Expanded(
      child: SizedBox(
        height: 32,
        child: ApplianceSurface(
          face: face,
          child: Center(
            child: Text(
              legend,
              maxLines: 1,
              style: style.copyWith(color: face.foreground),
            ),
          ),
        ),
      ),
    );
    return KitSection(
      title: 'Finishes',
      note:
          'Six finishes, each the warm plastic at the same tones in another '
          'hue with a signal of its own: warm, mint, butter, powder, blush and '
          'slate (ApplianceThemeData.preset).',
      children: [
        LayoutBuilder(
          builder: (context, box) {
            // Six, three or two across, so the rows come out even.
            const gap = ApplianceSpacing.small;
            final across = box.maxWidth >= 6 * 132 + 5 * gap
                ? 6
                : box.maxWidth >= 3 * 132 + 2 * gap
                ? 3
                : 2;
            final width = ((box.maxWidth - (across - 1) * gap) / across)
                .floorToDouble();
            return KitRow(
              children: [
                for (final name in ApplianceThemeData.presets)
                  SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ApplianceTheme(
                          data: ApplianceThemeData.preset(name, brightness),
                          child: Builder(
                            builder: (context) {
                              final theme = context.applianceTheme;
                              final c = theme.colors;
                              final s = theme.textTheme.label.copyWith(
                                fontSize: 13,
                              );
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [c.housingTop, c.housingBottom],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    ApplianceMetrics.keyRadius,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    ApplianceSpacing.small,
                                  ),
                                  child: Row(
                                    children: [
                                      key(
                                        ApplianceFace.key(c, radius: 6),
                                        'Off',
                                        s,
                                      ),
                                      const SizedBox(width: 4),
                                      key(
                                        ApplianceFace.keyDown(c, radius: 6),
                                        'Eco',
                                        s,
                                      ),
                                      const SizedBox(width: 4),
                                      key(
                                        ApplianceFace(
                                          top: c.signalTop,
                                          bottom: c.signalBottom,
                                          lift: 1,
                                          radius: BorderRadius.circular(6),
                                          foreground: c.onSignal,
                                        ),
                                        'Go',
                                        s,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: ApplianceSpacing.small),
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
