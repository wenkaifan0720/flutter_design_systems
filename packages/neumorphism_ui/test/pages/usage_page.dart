// A period's numbers. Star: NeumorphicTwoWayBars, a day of two directions over an engraved axis, under one NeumorphicFigure, with NeumorphicShareBars for how
// it splits and NeumorphicColumnBars for how it compares. Copy it for a report: a total, what made it up, how it did against last time.
import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class UsagePage extends StatelessWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    const head = NeumorphicPageHead(overline: 'So far today', title: 'Usage');
    const figure = NeumorphicFigure(
      '17.8',
      unit: 'units used',
      delta: '9% below yesterday by now',
      icon: NeumorphicGlyphs.trendingDown,
    );
    const stats = NeumorphicStats([
      NeumorphicStat('Using now', '1.8', 'a day'),
      NeumorphicStat('Returned', '3.0'),
      NeumorphicStat('Cost', '€4.22'),
    ]);
    const bars = NeumorphicTwoWayBars(
      above: [
        .6,
        .5,
        .5,
        .5,
        .6,
        1.1,
        1.6,
        1.4,
        .7,
        .5,
        .4,
        .4,
        .4,
        .4,
        .5,
        .9,
        1.3,
        1.8,
        1.9,
        1.5,
        .3,
      ],
      below: {8: .1, 9: .3, 10: .5, 11: .6, 12: .6, 13: .5, 14: .3, 15: .1},
      now: 20.17,
      peak: '1.9',
      labels: {0: '00', 6: '06', 12: '12', 18: '18'},
      nowLabel: '20:10',
      keys: [
        NeumorphicLegendItem('Out, per hour'),
        NeumorphicLegendItem(
          'Back, per hour',
          kind: NeumorphicLegendSwatch.live,
        ),
      ],
    );
    const shares = NeumorphicShareBars(
      title: 'By kind',
      rows: [
        NeumorphicShare('The largest kind', '9.4', .53),
        NeumorphicShare('A second kind', '3.1', .17),
        NeumorphicShare('A third kind', '2.6', .15),
        NeumorphicShare('Everything else', '2.7', .15),
      ],
    );
    const week = NeumorphicColumn(
      gap: 10,
      children: [
        NeumorphicSubHead('Last 7 days', subtitle: 'Wed 17.8 → 20.6'),
        NeumorphicGrow(
          child: NeumorphicColumnBars(
            values: [23.9, 22.1, 25.3, 24.7, 21.8, 22.4, 17.8],
            labels: ['Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed'],
            now: 6,
            forecast: 20.6,
          ),
        ),
      ],
    );
    const today = NeumorphicCard(
      title: 'By the hour',
      subtitle: '00:00 to 20:10',
      children: [
        figure,
        bars,
        NeumorphicList(
          children: [
            NeumorphicKvRow('Highest hour', '1.9 at 18:00', isFirst: true),
            NeumorphicKvRow('Lowest hour', '0.4 at 11:00'),
            NeumorphicKvRow('Back at most', '0.6 at 12:00'),
          ],
        ),
      ],
    );
    return NeumorphicScaffold(
      rail: const [
        NeumorphicRailSet(
          label: 'Other periods',
          gap: 4,
          children: [
            NeumorphicRailLink(label: 'This week', figure: '131'),
            NeumorphicRailLink(label: 'This month', figure: '412'),
            NeumorphicRailLink(label: 'This year', figure: '4,820'),
          ],
        ),
      ],
      body: t.desk
          ? NeumorphicSections(
              children: [
                head,
                stats,
                NeumorphicRow(
                  spans: const [7, 5],
                  children: [
                    today,
                    NeumorphicCard(
                      title: 'How it splits',
                      children: const [
                        shares,
                        NeumorphicGrow(child: week),
                      ],
                    ),
                  ],
                ),
              ],
            )
          : NeumorphicSections(
              children: [
                NeumorphicColumn(gap: 14, children: const [head, figure]),
                const NeumorphicCard(
                  title: 'By the hour',
                  subtitle: '00:00 to 20:10',
                  children: [bars],
                ),
                stats,
                const NeumorphicCard(
                  title: 'How it splits',
                  children: [shares, week],
                ),
              ],
            ),
    );
  }
}
