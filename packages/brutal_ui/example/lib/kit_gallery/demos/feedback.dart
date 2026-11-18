import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Notices in their four tones, the four page states, the spinner and the
/// progress bar.
Widget kitFeedbackDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Feedback',
  sections: [
    KitSection(
      title: 'Notices',
      note:
          'A ruled box led by a cell of its tone: ink for news, lime when it '
          'worked, orange to look first, red when it failed.',
      children: [
        const BrutalNotice(
          title: 'Doors open at 19:00',
          message: 'The hall opens an hour before the band.',
        ),
        const BrutalNotice(
          tone: BrutalNoticeTone.success,
          title: 'Two tickets are in Tickets',
          message: 'We sent them to ada.park@example.com as well.',
        ),
        const BrutalNotice(
          tone: BrutalNoticeTone.warning,
          title: 'Six tickets left',
          message: 'Standing for Low Tide is nearly gone.',
        ),
        BrutalNotice(
          tone: BrutalNoticeTone.danger,
          title: 'Your bank declined the card',
          message:
              'Nothing was charged. Check the card ending 4417 or use '
              'another.',
          actions: [
            BrutalButton.text('Try again', onPressed: () {}),
            BrutalButton.text('Use another card', onPressed: () {}),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Page states',
      note:
          'What a page says in place of its content, on its leading edge: '
          'a square cell, a title, what to do next.',
      children: [
        BrutalStateView(
          state: BrutalState.empty,
          icon: const Icon(LucideIcons.searchX),
          title: 'Nothing matches “jazz”',
          message: 'Search looks at titles, venues and who is on.',
          actions: [BrutalButton('Clear search', onPressed: () {})],
        ),
        BrutalStateView(
          state: BrutalState.error,
          title: 'The week did not load',
          message: 'Check the connection, then try again.',
          actions: [BrutalButton('Try again', onPressed: () {})],
        ),
        const BrutalStateView(
          state: BrutalState.loading,
          title: 'Loading the week',
        ),
        const BrutalStateView(
          state: BrutalState.success,
          title: 'You are on the list',
          message: 'We will write when tickets go on sale.',
        ),
      ],
    ),
    const KitSection(
      title: 'Progress',
      note:
          'A heavy bar running round a square while the length is unknown; '
          'a bar filling a ruled track when it is known.',
      children: [
        KitRow(
          children: [
            BrutalSpinner(semanticLabel: 'Loading'),
            BrutalSpinner(size: 40),
          ],
        ),
        BrutalProgressBar(value: 0.35, semanticLabel: 'Upload'),
        BrutalProgressBar(semanticLabel: 'Loading the week'),
      ],
    ),
    const KitSection(
      title: 'Skeleton',
      note:
          'Flat grey blocks where content will come, breathing slowly; '
          'still when motion is reduced.',
      children: [
        Row(
          children: [
            BrutalSkeleton(width: 48, height: 48),
            SizedBox(width: BrutalSpacing.medium),
            Expanded(child: BrutalSkeleton()),
          ],
        ),
        BrutalSkeleton(height: 120),
      ],
    ),
    KitSection(
      title: 'Meter',
      note:
          'How much, on a known scale: cells fill with ink, and with the '
          'danger colour past the high mark.',
      children: [
        const BrutalMeter(
          value: 0.42,
          label: 'Capacity',
          valueText: '210 of 500',
        ),
        const BrutalMeter(
          value: 470,
          max: 500,
          high: 450,
          label: 'Capacity',
          valueText: '470 of 500',
        ),
        BrutalSkeleton.lines(3),
      ],
    ),
  ],
);

// Catalog specimens (metadata.yaml): one still per part, drawn the same in
// every preset; the stage chooses the preset.

Widget kitSpecimenNotice() => Builder(
  builder: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const BrutalNotice(
        title: 'Doors open at 19:00',
        message: 'Bring the code on your phone or printed.',
      ),
      const SizedBox(height: BrutalSpacing.regular),
      BrutalNotice(
        tone: BrutalNoticeTone.danger,
        title: 'Your card was declined',
        actions: [
          BrutalButton(
            'Use another card',
            onPressed: () => kitFeedback(context, 'Your cards open here.'),
          ),
        ],
      ),
    ],
  ),
);

Widget kitSpecimenStateView() => Builder(
  builder: (context) => BrutalStateView(
    state: BrutalState.empty,
    icon: const Icon(LucideIcons.ticket),
    title: 'No tickets yet',
    message: 'The nights you book stand here.',
    actions: [
      BrutalButton.filled(
        'Find a night',
        onPressed: () => kitFeedback(context, 'This week opens here.'),
      ),
    ],
  ),
);

Widget kitSpecimenSpinner() => const KitRow(
  children: [
    BrutalSpinner(size: 20, semanticLabel: 'Loading'),
    BrutalSpinner(semanticLabel: 'Loading'),
    BrutalSpinner(size: 32, semanticLabel: 'Loading'),
  ],
);

Widget kitSpecimenProgressBar() => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    BrutalProgressBar(value: 0.4, semanticLabel: 'Upload'),
    SizedBox(height: BrutalSpacing.regular),
    BrutalProgressBar(semanticLabel: 'Loading'),
  ],
);
