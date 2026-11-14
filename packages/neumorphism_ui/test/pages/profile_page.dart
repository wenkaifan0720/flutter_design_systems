// A person or an account. Star: three NeumorphicGauges set straight in the wall, under a monogram and a name. Copy it for an account, a member, a settings
// home: who this is, how they stand, what they've set. No card around the head: it stands on the wall.
import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final head = NeumorphicBeside(
      object: const NeumorphicMonogram('AB', size: 72, led: true),
      gap: 18,
      child: const NeumorphicPageHead(
        title: 'A person',
        subtitle: 'Member since 2019',
      ),
    );
    const gauges = NeumorphicWallSet(
      title: 'How it stands',
      subtitle: 'This month',
      child: NeumorphicGridOf(
        columns: 3,
        gap: 8,
        children: [
          NeumorphicGauge(
            value: 72,
            figure: '72',
            name: 'Done',
            note: 'Of 100',
            live: true,
          ),
          NeumorphicGauge(
            value: 45,
            figure: '45',
            name: 'Booked',
            note: 'Of 100',
          ),
          NeumorphicGauge(
            value: 18,
            figure: '18',
            name: 'Missed',
            note: 'Of 100',
          ),
        ],
      ),
    );
    final about = NeumorphicCard(
      title: 'About',
      children: const [
        NeumorphicList(
          children: [
            NeumorphicKvRow('Name', 'A person', isFirst: true),
            NeumorphicKvRow('Where', 'A town, a country'),
            NeumorphicKvRow('Status', 'Active', live: true),
            NeumorphicKvRow('Plan', 'The middle plan'),
          ],
        ),
      ],
    );
    final settings = NeumorphicCard(
      title: 'Settings',
      children: [
        NeumorphicList(
          children: [
            NeumorphicListTile(
              title: 'Messages',
              note: 'A note when something changes',
              isFirst: true,
              trailing: NeumorphicSwitch(value: true, onChanged: (_) {}),
            ),
            NeumorphicListTile(
              title: 'A weekly summary',
              note: 'On Mondays',
              trailing: NeumorphicSwitch(value: false, onChanged: (_) {}),
            ),
            NeumorphicListTile(
              title: 'Share with the team',
              trailing: NeumorphicSwitch(value: true, onChanged: (_) {}),
            ),
          ],
        ),
      ],
    );
    final others = NeumorphicCard(
      title: 'Also on this account',
      subtitle: '2',
      children: [
        const NeumorphicList(
          children: [
            NeumorphicWhoRow(
              initials: 'CD',
              name: 'Another person',
              note: 'Joined in March',
              led: true,
            ),
            NeumorphicWhoRow(
              initials: 'EF',
              name: 'A third person',
              note: 'Joined in June',
            ),
          ],
        ),
        NeumorphicButton(
          'Add someone',
          icon: NeumorphicGlyphs.userPlus,
          onPressed: () {},
        ),
      ],
    );
    return NeumorphicScaffold(
      actions: [
        NeumorphicRoundButton(
          NeumorphicGlyphs.settings,
          label: 'Settings',
          onPressed: () {},
        ),
      ],
      body: t.desk
          ? NeumorphicSections(
              children: [
                head,
                NeumorphicRow(
                  spans: const [7, 5],
                  children: [
                    NeumorphicColumn(
                      gap: 28,
                      children: [
                        gauges,
                        NeumorphicGrow(child: settings),
                      ],
                    ),
                    NeumorphicColumn(
                      gap: 28,
                      children: [
                        about,
                        NeumorphicGrow(child: others),
                      ],
                    ),
                  ],
                ),
              ],
            )
          : NeumorphicSections(
              children: [head, gauges, about, settings, others],
            ),
    );
  }
}
