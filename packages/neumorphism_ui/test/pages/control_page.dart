// A thing you set. Star: NeumorphicDial, the fluted dial: a band with its keys on a phone, whole on a desktop, with latches for its mode, level rows
// for what it drives and a step line for what it did. Copy it for a page where one value is what you came to change.
import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    const head = NeumorphicPageHead(
      title: 'The main unit',
      subtitle: 'Lower level, 6 items',
      chips: [
        NeumorphicChip(
          'Busy since 19:45',
          icon: NeumorphicGlyphs.users,
          live: true,
        ),
        NeumorphicChip('1.1 units today', icon: NeumorphicGlyphs.zap),
      ],
    );
    final dial = NeumorphicDial(
      compact: true,
      value: 72,
      min: 40,
      max: 90,
      now: 68,
      major: 10,
      step: 1.25,
      label: 'Rising to',
      labelIcon: NeumorphicGlyphs.trendingUp,
      figure: '72',
      sub: 'Now 68',
      caption: '72 by about 20:25',
      captionDetail: 'Set at 19:45',
      onDecrease: () {},
      onIncrease: () {},
    );
    final mode = NeumorphicLatchGroup(
      options: const [
        NeumorphicLatch('Run', icon: NeumorphicGlyphs.play),
        NeumorphicLatch('Eco', icon: NeumorphicGlyphs.leaf),
        NeumorphicLatch('Auto', icon: NeumorphicGlyphs.calendarClock),
        NeumorphicLatch('Off', icon: NeumorphicGlyphs.power),
      ],
      value: 'Run',
      onChanged: (_) {},
    );
    const stats = NeumorphicStats([
      NeumorphicStat('Humidity', '46', '%'),
      NeumorphicStat('Air', '720', 'ppm'),
      NeumorphicStat('At 22:30', '40'),
    ]);
    final levels = NeumorphicCard(
      title: 'What it drives',
      subtitle: '2 of 3 on',
      children: [
        NeumorphicList(
          children: [
            NeumorphicLevelRow(
              icon: NeumorphicGlyphs.fan,
              title: 'First unit',
              state: 'Off, was 80%',
              value: false,
              isFirst: true,
              onChanged: (_) {},
            ),
            NeumorphicLevelRow(
              icon: NeumorphicGlyphs.gauge,
              title: 'Second unit',
              state: 'On, 30%',
              value: true,
              level: .3,
              figure: '30%',
              onChanged: (_) {},
              onLevel: (_) {},
            ),
            NeumorphicLevelRow(
              icon: NeumorphicGlyphs.lightbulb,
              title: 'Third unit',
              state: 'On, 15%',
              value: true,
              level: .15,
              figure: '15%',
              onChanged: (_) {},
              onLevel: (_) {},
            ),
          ],
        ),
      ],
    );
    const today = NeumorphicCard(
      title: 'Today',
      subtitle: '68 at 20:10',
      children: [
        NeumorphicStepLine(
          readings: [
            (0, 50),
            (3, 48),
            (6, 49),
            (8, 62),
            (10, 52),
            (12, 46),
            (14, 44),
            (16, 58),
            (18, 64),
            (20, 68),
          ],
          steps: [
            (0, 45),
            (6.5, 62),
            (8.2, 45),
            (15.5, 62),
            (17, 66),
            (19.75, 72),
            (22.5, 45),
            (24, 45),
          ],
          now: 20.17,
          xMax: 24,
          yMin: 40,
          yMax: 80,
          yTicks: [50, 60, 70],
          xLabels: [(0, '00'), (6, '06'), (12, '12'), (18, '18'), (24, '24')],
          keys: [
            NeumorphicLegendItem('Reading'),
            NeumorphicLegendItem('Set', kind: NeumorphicLegendSwatch.line),
          ],
          note: 'From 22:30: 40',
        ),
      ],
    );
    final next = NeumorphicCard(
      title: 'What it does next',
      subtitle: 'Next at 22:30',
      children: [
        NeumorphicWell(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: NeumorphicList(
            children: const [
              NeumorphicStepRow(
                time: '19:45',
                title: 'Busy, now',
                value: '72',
                state: NeumorphicStepStatus.live,
                isFirst: true,
              ),
              NeumorphicStepRow(
                time: '22:30',
                title: 'Closed',
                value: '40',
                state: NeumorphicStepStatus.next,
              ),
              NeumorphicStepRow(
                time: '06:30',
                title: 'Open',
                value: '65',
                state: NeumorphicStepStatus.next,
              ),
            ],
          ),
        ),
      ],
    );
    return NeumorphicScaffold(
      topBar: t.desk
          ? null
          : NeumorphicAppBar(
              title: 'The main unit',
              leading: NeumorphicAppBar.autoLeading(context),
            ),
      body: t.desk
          ? NeumorphicRow(
              spans: const [7, 5],
              children: [
                NeumorphicColumn(gap: 28, children: [head, dial, mode, stats]),
                NeumorphicColumn(
                  gap: 28,
                  children: [
                    levels,
                    today,
                    NeumorphicGrow(child: next),
                  ],
                ),
              ],
            )
          : NeumorphicSections(
              children: [
                NeumorphicColumn(gap: 18, children: [dial, mode]),
                levels,
                stats,
                today,
                next,
              ],
            ),
    );
  }
}
