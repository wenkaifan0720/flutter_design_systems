// The foundations: the six palettes, the palette by role (each with its
// contrast on the page), the type ramp, the focus every part shares, the material an app's
// own part can wear, what an app can change, the measures, and how
// dates, times and sums are written.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Foundations',
  intro:
      "One accent for each job: the palette's colour to act (blue in "
      "Civic's own), red for an error, green for done, yellow for where the "
      'keyboard is. Everything else is ink on white.',
  sections: const [
    _Palettes(),
    _Palette(),
    _Type(),
    _Focus(),
    _Material(),
    _Customise(),
    _Measures(),
    _Words(),
  ],
);

/// The six palettes ([CivicThemeData.palettes]) in the page's brightness,
/// each a page of its own under its own theme: its name, a button and a
/// link, the parts themselves.
class _Palettes extends StatelessWidget {
  const _Palettes();

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return KitSection(
      title: 'Palettes',
      caption:
          'Six action colours; the words, errors, successes and the focus '
          'stay the same in each.',
      spacing: CivicSpacing.s8,
      children: [
        // A tile is 168 wide at the reading size, two to a phone's row and three to the reading column's, and
        // grows with the text (one to a row at twice the size) so a button's word never breaks.
        LayoutBuilder(
          builder: (context, box) {
            final width = MediaQuery.textScalerOf(context)
                .scale(168)
                .clamp(0.0, box.maxWidth);
            return Wrap(
              spacing: CivicSpacing.s8,
              runSpacing: CivicSpacing.s8,
              children: [
                for (final palette in CivicThemeData.palettes)
                  _Swatch(
                    palette.id,
                    t.brightness == Brightness.dark
                        ? CivicThemeData.dark(palette: palette)
                        : CivicThemeData.light(palette: palette),
                    width: width,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.id, this.palette, {required this.width});

  final String id;
  final CivicThemeData palette;
  final double width;

  @override
  Widget build(BuildContext context) => CivicTheme(
    data: palette,
    child: Builder(
      builder: (context) {
        final t = context.civicTheme;
        return Container(
          width: width,
          decoration: BoxDecoration(
            color: t.background,
            border: Border.all(color: t.rule),
          ),
          child: Padding(
            padding: const EdgeInsets.all(CivicSpacing.s12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CivicSpacing.s8,
              children: [
                Text(
                  '${id[0].toUpperCase()}${id.substring(1)}',
                  style: context.civicText.label,
                ),
                CivicButton(onPressed: () {}, child: const Text('Continue')),
                CivicLink(onPressed: () {}, child: const Text('Link')),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _Palette extends StatelessWidget {
  const _Palette();

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final roles = <(String, Color, Color)>[
      ('Words', t.textPrimary, t.background),
      ('Secondary words', t.textSecondary, t.background),
      ('Action', t.action, t.onAction),
      ('Error', t.danger, t.onDanger),
      ('Success', t.success, t.onSuccess),
      ('Focus', t.focus, t.onFocus),
      ('Band', t.surface, t.textPrimary),
      ('Rule', t.rule, t.textPrimary),
    ];
    return KitSection(
      title: 'Colour',
      caption: 'Each role with the words that stand on it.',
      spacing: CivicSpacing.s8,
      children: [
        for (final (name, fill, on) in roles)
          DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(color: t.rule),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CivicSpacing.s16,
                vertical: CivicSpacing.s12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: context.civicText.label.copyWith(
                        color: name == 'Words' || name == 'Secondary words'
                            ? fill
                            : on,
                      ),
                    ),
                  ),
                  Text(
                    _hex(fill),
                    style: context.civicText.bodySmall.copyWith(
                      color: name == 'Words' || name == 'Secondary words'
                          ? fill
                          : on,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class _Type extends StatelessWidget {
  const _Type();

  @override
  Widget build(BuildContext context) {
    final text = context.civicText;
    return KitSection(
      title: 'Type',
      caption:
          'Atkinson Hyperlegible Next, drawn so that letters people confuse '
          'look different. Body text is 19 on a wide window, 18 on a phone.',
      spacing: CivicSpacing.s12,
      children: [
        Text('Apply for a permit', style: text.headingXL),
        Text('Check your answers', style: text.headingL),
        Text('Your vehicle', style: text.headingM),
        Text('What happens next', style: text.headingS),
        Text(
          'We will email you when we have decided. Most decisions take 5 '
          'working days.',
          style: text.body,
        ),
        Text(
          'Reference numbers are set so 0 and O, 1 and l differ:',
          style: text.caption,
        ),
        Text('BRM-4821-K0O1l', style: text.code),
      ],
    );
  }
}

class _Focus extends StatelessWidget {
  const _Focus();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Focus',
    caption:
        'Where the keyboard is, as no other look shows it: a button or a link '
        'floods yellow over a thick ink bar; a box to write in keeps its '
        'white and wears a yellow ring around a doubled edge.',
    children: [
      Wrap(
        spacing: CivicSpacing.s24,
        runSpacing: CivicSpacing.s16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          KitFocused(
            builder: (c) => CivicButton(
              onPressed: () {},
              expand: false,
              statesController: c,
              child: const Text('Continue'),
            ),
          ),
          KitFocused(
            builder: (c) => CivicLink(
              onPressed: () {},
              statesController: c,
              child: const Text('Change your address'),
            ),
          ),
        ],
      ),
      const CivicTextField(
        labelText: 'Postcode',
        widthInCharacters: 10,
        autofocus: true,
      ),
    ],
  );
}

class _Material extends StatelessWidget {
  const _Material();

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    Widget face({required bool focused}) => CivicFace(
      fill: t.action,
      edgeColor: t.actionEdge,
      edgeHeight: CivicMetrics.bar,
      focused: focused,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CivicSpacing.s16,
          CivicSpacing.s12,
          CivicSpacing.s16,
          CivicSpacing.s12 + CivicMetrics.bar,
        ),
        child: Text(
          focused ? 'A face, focused' : 'A face',
          style: context.civicText.button.copyWith(
            color: focused ? t.onFocus : t.onAction,
          ),
        ),
      ),
    );
    Widget well({required bool focused}) => CivicWell(
      focused: focused,
      child: Padding(
        padding: const EdgeInsets.all(CivicMetrics.edge + CivicSpacing.s12),
        child: Text(focused ? 'A well, focused' : 'A well'),
      ),
    );
    return KitSection(
      title: 'Material',
      caption:
          "Civic's two surfaces, public so an app's own part can wear the "
          'look: the face a button wears, on a solid edge a press sinks '
          'onto, and the well a field is. The colours are the app’s; the '
          'edges and the focus are the look’s.',
      children: [
        Wrap(
          spacing: CivicSpacing.s24,
          runSpacing: CivicSpacing.s24,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            face(focused: false),
            face(focused: true),
            well(focused: false),
            Padding(
              padding: const EdgeInsets.all(CivicMetrics.focusRing),
              child: well(focused: true),
            ),
          ],
        ),
      ],
    );
  }
}

class _Customise extends StatelessWidget {
  const _Customise();

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    // An app's own green, darkened (or lightened by night) to 7:1.
    final brand = CivicThemeData.from(
      brightness: t.brightness,
      action: const Color(0xFF0A7D4F),
    );
    return KitSection(
      title: 'Customise',
      caption:
          'An app changes what keeps the look: its colours (each held to '
          '7:1 on the page), its face, a part’s colours and room. The focus, '
          'the edges, the large type and the tap floors stay.',
      children: [
        CivicTheme(
          data: brand,
          child: Wrap(
            spacing: CivicSpacing.s24,
            runSpacing: CivicSpacing.s16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CivicButton(
                onPressed: () {},
                expand: false,
                child: const Text('In the app’s green'),
              ),
              CivicLink(onPressed: () {}, child: const Text('A green link')),
            ],
          ),
        ),
        CivicTheme(
          data: t.copyWith(
            primaryButtonStyle: const CivicStyle(
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: CivicSpacing.s40),
              ),
            ),
          ),
          child: CivicButton(
            onPressed: () {},
            expand: false,
            child: const Text('Every primary button wider'),
          ),
        ),
        CivicButton.secondary(
          onPressed: () {},
          expand: false,
          style: CivicStyle(fill: WidgetStatePropertyAll(t.surface)),
          child: const Text('One button on the grey'),
        ),
      ],
    );
  }
}

class _Measures extends StatelessWidget {
  const _Measures();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Measures',
    children: [
      CivicSummaryList(
        rows: [
          const CivicSummaryRow(label: 'Grid', value: Text('4 points')),
          const CivicSummaryRow(
            label: 'Page margins',
            value: Text('20 on a phone, 32 on a tablet, 40 from 1024'),
          ),
          const CivicSummaryRow(
            label: 'Reading width',
            value: Text('640 at most: short lines'),
          ),
          const CivicSummaryRow(
            label: 'Controls',
            value: Text('48 tall; a box to tick is 40 square'),
          ),
          const CivicSummaryRow(
            label: 'Targets',
            value: Text('40 for a finger, 24 for a pointer at the least'),
          ),
          const CivicSummaryRow(
            label: 'Corners',
            value: Text('Square, but for radios and round marks'),
          ),
          CivicSummaryRow(
            label: 'Top bar',
            value: Text(
              '${CivicChromeMetrics.topBar.round()} tall, on a '
              '${CivicChromeMetrics.topBarRule.round()} rule in blue',
            ),
          ),
          CivicSummaryRow(
            label: 'Navigation',
            value: Text(
              'A bar ${CivicChromeMetrics.navigationBar.round()} tall on a '
              'phone; a column '
              '${CivicChromeMetrics.sideNavigation.round()} wide from 600',
            ),
          ),
        ],
      ),
    ],
  );
}

class _Words extends StatelessWidget {
  const _Words();

  @override
  Widget build(BuildContext context) {
    final sent = DateTime(2026, 11, 3, 9);
    final ends = DateTime(2027, 11, 2, 17, 30);
    return KitSection(
      title: 'Dates, times and sums',
      children: [
        CivicSummaryList(
          rows: [
            CivicSummaryRow(
              label: 'A date',
              value: Text(CivicFormat.date(sent, weekday: true)),
            ),
            CivicSummaryRow(
              label: 'Two dates',
              value: Text(CivicFormat.dateRange(sent, ends)),
            ),
            CivicSummaryRow(
              label: 'Times',
              value: Text(
                '${CivicFormat.clockRange(sent, ends, twentyFourHour: false)}, '
                'or ${CivicFormat.clock(DateTime(2026, 11, 3, 12), twentyFourHour: false)}',
              ),
            ),
            CivicSummaryRow(
              label: 'Sums',
              value: Text(
                '${CivicFormat.money(6000, symbol: '€')} a year, '
                '${CivicFormat.money(625, symbol: '€')} a month',
              ),
            ),
            CivicSummaryRow(
              label: 'Counts',
              value: Text(CivicFormat.plural(1240, 'permit')),
            ),
          ],
        ),
      ],
    );
  }
}
