// The look's home. Star: NeumorphicRelief, whole on a phone and a desktop: a set of grouped things as one casting, what's on lit, one
// flagged. Copy it for the one page of an app that shows everything at a glance. Use the relief once in an app. Other pages take a
// compact hero.
import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    const head = NeumorphicPageHead(
      overline: 'Wednesday, 20:10',
      title: 'Good evening',
      chips: [
        NeumorphicChip(
          'All well',
          icon: NeumorphicGlyphs.circleCheck,
          live: true,
        ),
        NeumorphicChip('4 of 9 on', icon: NeumorphicGlyphs.layers),
      ],
    );
    const relief = NeumorphicRelief(
      title: '12',
      subtitle: 'North Street',
      count: '*4 of 9* on',
      courses: [
        NeumorphicCourse('Upper', [
          NeumorphicBay(figure: '18', name: 'Studio', note: 'Free'),
          NeumorphicBay(figure: '12', name: 'Store', note: 'Closed'),
          NeumorphicBay(figure: '7', name: 'Office', note: 'Free'),
        ]),
        NeumorphicCourse('Middle', [
          NeumorphicBay(figure: '24', name: 'Workshop', note: 'Free'),
          NeumorphicBay(
            figure: '31',
            name: 'Meeting room',
            note: 'On, 80%',
            lit: .8,
            flag: NeumorphicGlyphs.bell,
          ),
          NeumorphicBay(figure: '9', name: 'Kitchen', note: 'Closed'),
        ]),
        NeumorphicCourse('Lower', [
          NeumorphicBay(figure: '15', name: 'Hall', note: 'On, 40%', lit: .4),
          NeumorphicBay(
            figure: '42',
            name: 'Main room',
            note: 'On, 40%',
            lit: .4,
          ),
          NeumorphicBay(
            figure: '6',
            name: 'Front desk',
            note: 'On, 20%',
            lit: .2,
          ),
        ]),
      ],
      ground: [
        NeumorphicGroundNote('Outside 7°', icon: NeumorphicGlyphs.trees),
        NeumorphicGroundNote('Two doors open', icon: NeumorphicGlyphs.doorOpen),
        NeumorphicGroundNote('9 areas, 23 items'),
      ],
    );
    final nudge = NeumorphicNudge(
      title: 'The meeting room has been on since 16:10.',
      note: 'Nobody is booked in.',
      icon: NeumorphicGlyphs.bell,
      action: NeumorphicButton.filled(
        'Turn off',
        icon: NeumorphicGlyphs.power,
        onPressed: () {},
      ),
    );
    const modes = NeumorphicWallSet(
      title: 'Modes',
      subtitle: 'Next at 22:30',
      child: NeumorphicPushGroup(
        items: [
          NeumorphicPush(
            icon: NeumorphicGlyphs.sunrise,
            label: 'Open',
            note: 'Ran 06:45',
          ),
          NeumorphicPush(
            icon: NeumorphicGlyphs.logOut,
            label: 'Away',
            note: 'Off 16:05',
          ),
          NeumorphicPush(
            icon: NeumorphicGlyphs.users,
            label: 'Busy',
            note: 'Since 19:45',
            selected: true,
          ),
          NeumorphicPush(
            icon: NeumorphicGlyphs.moonStar,
            label: 'Closed',
            note: 'At 22:30',
          ),
        ],
      ),
    );
    const levels = NeumorphicWallSet(
      title: 'Levels',
      subtitle: 'Three in use',
      child: NeumorphicGridOf(
        columns: 3,
        gap: 8,
        children: [
          NeumorphicGauge(
            value: 72,
            now: 68,
            figure: '68',
            name: 'Main',
            note: 'Rising to 72',
            noteIcon: NeumorphicGlyphs.trendingUp,
            live: true,
          ),
          NeumorphicGauge(
            value: 40,
            now: 44,
            figure: '44',
            name: 'Second',
            note: 'Steady',
          ),
          NeumorphicGauge(
            value: 25,
            now: 26,
            figure: '26',
            name: 'Third',
            note: 'Steady',
          ),
        ],
      ),
    );
    return NeumorphicScaffold(
      rail: const [
        NeumorphicRailSet(
          label: 'Who is in',
          children: [
            NeumorphicWhoRow(
              initials: 'AB',
              name: 'A person',
              note: 'In since 17:40',
              led: true,
            ),
            NeumorphicWhoRow(
              initials: 'CD',
              name: 'Another person',
              note: 'In since 18:52',
              led: true,
            ),
          ],
        ),
      ],
      actions: const [NeumorphicMonogram('AB', size: 32, led: true)],
      body: t.desk
          ? NeumorphicRow(
              spans: const [7, 5],
              children: [
                relief,
                NeumorphicColumn(
                  gap: 48,
                  children: [head, nudge, modes, levels],
                ),
              ],
            )
          : NeumorphicSections(
              children: [
                NeumorphicColumn(gap: 18, children: const [head, relief]),
                nudge,
                modes,
                levels,
              ],
            ),
    );
  }
}
