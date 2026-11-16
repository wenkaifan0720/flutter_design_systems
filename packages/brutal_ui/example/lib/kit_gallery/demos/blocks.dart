import 'package:flutter/material.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Cards and media: the flat block, the pressable one on its shadow, the
/// one lead colour block a screen, the tags; disclosures, people as
/// squares, counts, pictures with their stand-in, a carousel and a
/// timeline.
Widget kitBlocksDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Cards and media',
  sections: const [_Blocks(), _Media()],
);

class _Blocks extends StatelessWidget {
  const _Blocks();

  @override
  Widget build(BuildContext context) {
    final theme = context.brutalTheme;
    final c = theme.colors;
    final t = theme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSection(
          title: 'Lead block',
          note:
              'One a screen: a flat colour, large, raised on the hard shadow. '
              'Words on it are black, by day and by night.',
          children: [
            BrutalBlock(
              lead: true,
              color: c.lime,
              onTap: () {},
              padding: const EdgeInsets.all(BrutalSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TONIGHT', style: t.caption.copyWith(color: c.onBlock)),
                  const SizedBox(height: BrutalSpacing.small),
                  Text('Low Tide', style: t.display.copyWith(color: c.onBlock)),
                  Text(
                    'Hall 4, doors 20:00',
                    style: t.body.copyWith(color: c.onBlock),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Blocks',
          note: 'Flat at rest; a block you can press stands on its shadow.',
          children: [
            BrutalBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your order', style: t.title),
                  const SizedBox(height: BrutalSpacing.small),
                  Text('2 × Standing, 32.00 each', style: t.body),
                ],
              ),
            ),
            BrutalBlock(
              onTap: () {},
              semanticLabel: 'Open Static Bloom',
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Static Bloom', style: t.title),
                        Text('Fri 20 Nov · The Cellar', style: t.secondary),
                      ],
                    ),
                  ),
                  const BrutalTag('From 18'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        const KitSection(
          title: 'Tags',
          children: [
            KitRow(
              children: [
                BrutalTag('Standing'),
                BrutalTag('Sold out', tone: BrutalTagTone.strong),
                BrutalTag('Few left', tone: BrutalTagTone.signal),
                BrutalTag('Cancelled', tone: BrutalTagTone.danger),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

const _people = [
  'Ines Okafor',
  'Tomas Lind',
  'Mara Quist',
  'Jun Arai',
  'Oskar Bell',
  'Ruth Mensah',
];

class _Media extends StatelessWidget {
  const _Media();

  @override
  Widget build(BuildContext context) {
    final c = context.brutalTheme.colors;
    final t = context.brutalTheme.textTheme;
    final slides = [c.lime, c.blue, c.pink];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: BrutalSpacing.extraLarge),
        const KitSection(
          title: 'Disclosure',
          note:
              'A press on the row opens it; the square holds a plus, a '
              'minus while open.',
          children: [
            BrutalDisclosureGroup(
              children: [
                BrutalDisclosure(
                  title: 'Can I get a refund?',
                  initiallyExpanded: true,
                  child: Text('Up to a day before the night, in full.'),
                ),
                BrutalDisclosure(
                  title: 'Is there step-free access?',
                  subtitle: 'The Shed and Dock 4',
                  child: Text('Yes, by the side door on Quay Street.'),
                ),
                BrutalDisclosure(
                  title: 'Can I bring a camera?',
                  child: Text('Phones only, no flash.'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Avatars and counts',
          note:
              'Squares in a block colour from the name; past four, the rest '
              'counted on ink. A count sits on a signal square.',
          children: [
            const KitRow(
              children: [
                BrutalAvatar(name: 'Ines Okafor'),
                BrutalAvatar(name: 'Tomas Lind', size: 48),
                BrutalAvatar(name: 'Mara Quist', size: 56),
                BrutalAvatar(name: 'Jun', size: 32),
              ],
            ),
            BrutalAvatarGroup(
              avatars: [for (final n in _people) BrutalAvatar(name: n)],
            ),
            KitRow(
              children: [
                BrutalBadge(
                  count: 3,
                  semanticLabel: '3 new',
                  child: Icon(LucideIcons.bell, size: 28, color: c.ink),
                ),
                BrutalBadge(
                  count: 128,
                  child: Icon(LucideIcons.mail, size: 28, color: c.ink),
                ),
                const BrutalBadge(count: 7),
              ],
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        const KitSection(
          title: 'Media',
          note:
              'A picture in the rule; while it loads, or if it fails, a '
              'ruled cross stands in.',
          children: [
            BrutalMedia(image: null, semanticLabel: 'The stage at The Shed'),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Carousel',
          note:
              'Swipe, the arrow keys, or the square cells; the dots say '
              'where.',
          children: [
            BrutalCarousel(
              itemCount: slides.length,
              semanticLabel: 'This week',
              itemBuilder: (context, i) => ColoredBox(
                color: slides[i],
                child: Center(
                  child: Text(
                    ['Low Tide', 'Paper Walls', 'Night Garden'][i],
                    style: t.headline.copyWith(color: c.onColor(slides[i])),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        const KitSection(
          title: 'Timeline',
          note:
              'Stops on a rule: ink once done, the next in the signal '
              'colour.',
          children: [
            BrutalTimeline(
              entries: [
                BrutalTimelineEntry(
                  title: 'Ordered',
                  time: 'Mon 10:02',
                  done: true,
                ),
                BrutalTimelineEntry(
                  title: 'Tickets sent',
                  time: 'Mon 10:03',
                  body: 'To ada@example.com',
                  done: true,
                ),
                BrutalTimelineEntry(title: 'Doors', time: 'Fri 19:30'),
                BrutalTimelineEntry(title: 'Last entry', time: 'Fri 22:00'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// Catalog specimens (metadata.yaml): one still per part, drawn the same in
// every preset; the stage chooses the preset.

Widget kitSpecimenBlock() => Builder(
  builder: (context) {
    final theme = context.brutalTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrutalBlock(
          lead: true,
          color: theme.colors.signal,
          label: 'Tonight',
          child: Text(
            'Low Tide',
            style: theme.textTheme.display.copyWith(
              color: theme.colors.onColor(theme.colors.signal),
            ),
          ),
        ),
        const SizedBox(height: BrutalSpacing.regular),
        BrutalBlock(
          onTap: () => kitFeedback(context, 'The night opens here.'),
          semanticLabel: 'Paper Walls, Dock 4, Saturday',
          child: const Text('Paper Walls\nDock 4, Saturday'),
        ),
      ],
    );
  },
);

Widget kitSpecimenTag() => const KitRow(
  children: [
    BrutalTag('Few left', tone: BrutalTagTone.signal),
    BrutalTag('Sold out', tone: BrutalTagTone.strong),
    BrutalTag('18+'),
    BrutalTag('Cancelled', tone: BrutalTagTone.danger),
  ],
);

Widget kitSpecimenDisclosure() => const BrutalDisclosure(
  title: 'Refunds',
  subtitle: 'Up to a day before',
  initiallyExpanded: true,
  child: Text(
    'Cancel up to a day before the doors open and the money goes back '
    'to your card.',
  ),
);

Widget kitSpecimenDisclosureGroup() => const BrutalDisclosureGroup(
  children: [
    BrutalDisclosure(
      title: 'Getting there',
      child: Text('Two minutes from the quay stop.'),
    ),
    BrutalDisclosure(
      title: 'Bags',
      child: Text('One small bag each; the cloakroom takes the rest.'),
    ),
    BrutalDisclosure(
      title: 'Access',
      child: Text('Step-free from the street to the bar.'),
    ),
  ],
);

Widget kitSpecimenTable() => const BrutalTable(
  columns: [
    BrutalTableColumn('Night', flex: 2),
    BrutalTableColumn('Sold', numeric: true),
    BrutalTableColumn('Left', numeric: true),
  ],
  rows: [
    ['Friday', '212', '38'],
    ['Saturday', '340', '0'],
    ['Sunday', '96', '154'],
  ],
);

Widget kitSpecimenDescriptionList() => const BrutalDescriptionList(
  entries: [
    BrutalDescription('Doors', '19:30'),
    BrutalDescription('Venue', 'The Shed, 12 Quay Street'),
    BrutalDescription('Seat', 'Standing'),
  ],
);

Widget kitSpecimenTimeline() => const BrutalTimeline(
  entries: [
    BrutalTimelineEntry(title: 'Ordered', time: 'Mon 10:02', done: true),
    BrutalTimelineEntry(title: 'Paid', time: 'Mon 10:03', done: true),
    BrutalTimelineEntry(
      title: 'Doors',
      time: 'Fri 19:30',
      body: 'Show the code at the door.',
    ),
  ],
);

Widget kitSpecimenAvatar() => const KitRow(
  children: [
    BrutalAvatar(name: 'Ada Park', size: 32),
    BrutalAvatar(name: 'Jun Arai'),
    BrutalAvatar(name: 'Ruth Mensah', size: 64),
  ],
);

Widget kitSpecimenAvatarGroup() => const Align(
  alignment: AlignmentDirectional.centerStart,
  child: BrutalAvatarGroup(
    avatars: [
      BrutalAvatar(name: 'Ada Park'),
      BrutalAvatar(name: 'Jun Arai'),
      BrutalAvatar(name: 'Ruth Mensah'),
      BrutalAvatar(name: 'Tom Ide'),
      BrutalAvatar(name: 'Sal Okafor'),
      BrutalAvatar(name: 'Bo Lind'),
    ],
  ),
);

Widget kitSpecimenBadge() => const KitRow(
  children: [
    BrutalBadge(count: 3, child: Icon(LucideIcons.bell)),
    BrutalBadge(count: 120, child: Icon(LucideIcons.mail)),
  ],
);

Widget kitSpecimenMedia() =>
    const BrutalMedia(image: null, semanticLabel: 'The stage at The Shed');

Widget kitSpecimenSkeleton() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const BrutalSkeleton(width: 180, height: 24),
    const SizedBox(height: BrutalSpacing.regular),
    BrutalSkeleton.lines(3),
  ],
);

Widget kitSpecimenMeter() => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    BrutalMeter(value: 0.6, label: 'Capacity', valueText: '60%'),
    SizedBox(height: BrutalSpacing.regular),
    BrutalMeter(value: 0.92, label: 'Sold', high: 0.85, valueText: '92%'),
  ],
);
