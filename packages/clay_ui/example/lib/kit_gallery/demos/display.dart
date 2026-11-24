/// Clay's display parts: disclosures, tables, descriptions, timelines,
/// faces, badges, tags, media, skeletons and meters.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The display page.
Widget kitDisplayDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Display',
  sections: const [
    KitSection(
      title: 'Disclosures',
      note:
          'A slab that opens to show more; in a group they share one slab, '
          'a groove between them.',
      children: [_Disclosures()],
    ),
    KitSection(
      title: 'Tables and descriptions',
      note:
          'Rows of figures on one slab, numbers to the end; terms beside '
          'their values, stacked on a phone.',
      children: [_Tables()],
    ),
    KitSection(
      title: 'A timeline',
      note: 'Balls on a groove: those reached raised in coral.',
      children: [_Timeline()],
    ),
    KitSection(
      title: 'Faces, badges and tags',
      note:
          'A face moulded in a pastel its name picks; a count raised over a '
          'corner; a word pressed into a pill.',
      children: [_Faces()],
    ),
    KitSection(
      title: 'Media and skeletons',
      note:
          'A picture set in a soft frame; while it loads, slabs breathe in '
          'its place.',
      children: [_Media()],
    ),
    KitSection(
      title: 'Meters',
      note: 'A reading in a groove; past its high mark it turns to danger.',
      maxWidth: 480,
      children: [_Meters()],
    ),
  ],
);

class _Disclosures extends StatelessWidget {
  const _Disclosures();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClayDisclosure(
        title: 'Why a glass first thing',
        initiallyExpanded: true,
        child: Text(
          'A night without water leaves you a little dry; a glass before '
          'coffee sets the day.',
        ),
      ),
      SizedBox(height: ClaySpacing.regular),
      ClayDisclosureGroup(
        children: [
          ClayDisclosure(
            title: 'Reminders',
            child: Text('Each habit sets its own time and days.'),
          ),
          ClayDisclosure(
            title: 'Streaks',
            child: Text('A missed day pauses a streak; two end it.'),
          ),
          ClayDisclosure(
            title: 'Your data',
            child: Text('Everything stays on this phone until you sync.'),
          ),
        ],
      ),
    ],
  );
}

class _Tables extends StatelessWidget {
  const _Tables();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClayTable(
        columns: [
          ClayTableColumn('Habit', flex: 2),
          ClayTableColumn('This week', numeric: true),
          ClayTableColumn('Streak', numeric: true),
        ],
        rows: [
          ['Drink water', '6 of 7', '12'],
          ['Morning walk', '5 of 7', '9'],
          ['Read', '4 of 7', '4'],
          ['Stretch', '7 of 7', '21'],
        ],
      ),
      SizedBox(height: ClaySpacing.regular),
      ClayCard(
        child: ClayDescriptionList(
          entries: [
            ClayDescription('Started', '2 November'),
            ClayDescription('Goal', '8 glasses a day'),
            ClayDescription('Best streak', '21 days'),
            ClayDescription('Reminder', 'Every day at 8:00'),
          ],
        ),
      ),
    ],
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) => const ClayCard(
    child: ClayTimeline(
      entries: [
        ClayTimelineEntry(
          title: 'Started Drink water',
          time: '2 Nov',
          body: 'Eight glasses a day.',
        ),
        ClayTimelineEntry(title: 'First week kept', time: '9 Nov'),
        ClayTimelineEntry(title: 'Twelve days running', time: 'Today'),
        ClayTimelineEntry(title: 'Thirty days', time: '2 Dec', done: false),
      ],
    ),
  );
}

class _Faces extends StatelessWidget {
  const _Faces();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KitRow(
        children: [
          ClayAvatar(name: 'Mia Okafor'),
          ClayAvatar(name: 'Sam Lee', size: 48),
          ClayAvatar(name: 'Ana Ruiz', size: 56),
          ClayAvatarGroup(
            avatars: [
              ClayAvatar(name: 'Mia Okafor'),
              ClayAvatar(name: 'Sam Lee'),
              ClayAvatar(name: 'Ana Ruiz'),
              ClayAvatar(name: 'Tom Berg'),
              ClayAvatar(name: 'Ida Holm'),
              ClayAvatar(name: 'Noor Haddad'),
            ],
          ),
        ],
      ),
      SizedBox(height: ClaySpacing.large),
      // A count runs on past its part's corner, as Material's badges do:
      // the row leaves it room.
      KitRow(
        spacing: ClaySpacing.extraLarge,
        children: [
          ClayBadge(count: 3, child: Icon(LucideIcons.bell, size: 24)),
          ClayBadge(count: 120, child: Icon(LucideIcons.inbox, size: 24)),
          ClayBadge(count: 2, child: ClayAvatar(name: 'Mia Okafor')),
        ],
      ),
      SizedBox(height: ClaySpacing.large),
      KitRow(
        children: [
          ClayTag('Morning'),
          ClayTag('Kept', tone: ClayTagTone.success, icon: LucideIcons.check),
          ClayTag('New', tone: ClayTagTone.accent),
          ClayTag('Missed', tone: ClayTagTone.danger),
        ],
      ),
    ],
  );
}

class _Media extends StatelessWidget {
  const _Media();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const frame = ClayMedia(
        image: null,
        semanticLabel: 'A path through birches',
      );
      final loading = ClayCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                ClaySkeleton(width: 40, height: 40, radius: 20),
                SizedBox(width: ClaySpacing.regular),
                Expanded(child: ClaySkeleton(height: 16)),
              ],
            ),
            const SizedBox(height: ClaySpacing.regular),
            for (final w in const [1.0, 0.8, 0.6]) ...[
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: w,
                child: const ClaySkeleton(height: 12),
              ),
              const SizedBox(height: ClaySpacing.small),
            ],
          ],
        ),
      );
      if (box.maxWidth < 560) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            frame,
            const SizedBox(height: ClaySpacing.regular),
            loading,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: frame),
          const SizedBox(width: ClaySpacing.regular),
          Expanded(child: loading),
        ],
      );
    },
  );
}

class _Meters extends StatelessWidget {
  const _Meters();

  @override
  Widget build(BuildContext context) => const ClayCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClayMeter(
          value: 6,
          max: 8,
          label: 'Glasses today',
          valueText: '6 of 8',
        ),
        SizedBox(height: ClaySpacing.large),
        ClayMeter(value: 0.42, label: 'Storage used', valueText: '42%'),
        SizedBox(height: ClaySpacing.large),
        ClayMeter(
          value: 3.4,
          max: 4,
          high: 3,
          label: 'Coffee today',
          valueText: '3.4 cups',
        ),
      ],
    ),
  );
}
