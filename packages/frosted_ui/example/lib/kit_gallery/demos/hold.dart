/// [FrostedDisclosure], [FrostedDivider], [FrostedBadge], [FrostedTimeline]
/// and [FrostedTable]: what holds and orders content.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitHoldDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Disclosure, table & timeline',
  sections: [
    kitSection(
      'Disclosure',
      children: [
        const FrostedDisclosure(
          title: 'What does the plan include?',
          initiallyExpanded: true,
          child: Text(
            'Unlimited projects, shared folders and priority support.',
          ),
        ),
        const FrostedDisclosure(
          title: 'Can I cancel at any time?',
          meta: 'Billing',
          child: Text('Yes. Your plan runs to the end of the period.'),
        ),
      ],
    ),
    kitSection(
      'Divider',
      children: [
        const FrostedDivider(),
        // At least 24 tall, and as tall as the words when the text grows.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 24),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FrostedSpacing.s12,
              children: const [
                Center(widthFactor: 1, child: Text('Left')),
                FrostedDivider.vertical(),
                Center(widthFactor: 1, child: Text('Right')),
              ],
            ),
          ),
        ),
      ],
    ),
    kitSection(
      'Badge',
      children: [
        kitRow([
          FrostedBadge(
            3,
            label: '3 unread',
            child: FrostedIconButton(
              FrostedGlyphs.bell,
              label: 'Notifications',
              onPressed: () {},
            ),
          ),
          const FrostedBadge(120, label: '120 new'),
          FrostedBadge.dot(
            label: 'New',
            child: const FrostedAvatar('IP', name: 'Ines Park'),
          ),
        ]),
      ],
    ),
    kitSection(
      'Timeline',
      children: const [
        FrostedTimeline(
          entries: [
            FrostedTimelineEntry(
              title: 'Order placed',
              time: '9:04 AM',
              meta: 'Two items',
            ),
            FrostedTimelineEntry(title: 'Packed', time: '11:30 AM'),
            FrostedTimelineEntry(
              title: 'Out for delivery',
              time: '2:15 PM',
              current: true,
            ),
            FrostedTimelineEntry(title: 'Delivered'),
          ],
        ),
      ],
    ),
    kitSection(
      'Table',
      children: const [
        FrostedTable(
          semanticsLabel: 'Team',
          columns: [
            FrostedTableColumn('Name', flex: 2),
            FrostedTableColumn('Role', flex: 2),
            FrostedTableColumn('Tasks', numeric: true),
          ],
          rows: [
            ['Ines Park', 'Design', 12],
            ['Theo Lane', 'Engineering', 31],
            ['Ada Moss', 'Research', 7],
          ],
        ),
      ],
    ),
  ],
);

/// Three unread on the bell.
Widget kitSpecimenBadge() => const Center(
  heightFactor: 1,
  child: FrostedBadge(3, child: Icon(FrostedGlyphs.notifications)),
);

/// A question, closed over its answer.
Widget kitSpecimenDisclosure() => const FrostedDisclosure(
  title: 'When does a transfer arrive?',
  child: Text(
    'Between Harbor accounts at once; to another bank by the next '
    'working day.',
  ),
);

/// A hairline between two groups.
Widget kitSpecimenDivider() => const FrostedDivider();

/// A receipt's lines, the figures tabular at the end.
Widget kitSpecimenTable() => const FrostedTable(
  columns: [
    FrostedTableColumn('Item'),
    FrostedTableColumn('Qty', numeric: true),
    FrostedTableColumn('Price', numeric: true),
  ],
  rows: [
    ['Flat white', '2', r'$9.00'],
    ['Almond croissant', '1', r'$4.75'],
  ],
);

/// A transfer on its way.
Widget kitSpecimenTimelineSteps() => const FrostedTimeline(
  entries: [
    FrostedTimelineEntry(title: 'Transfer sent', time: '9:02'),
    FrostedTimelineEntry(title: 'With the bank', time: '9:05', current: true),
    FrostedTimelineEntry(title: 'Arrives Thursday'),
  ],
);
