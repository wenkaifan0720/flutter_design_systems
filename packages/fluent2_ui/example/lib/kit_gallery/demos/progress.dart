/// Fluent 2's ProgressBar (determinate in its four colours and two
/// thicknesses, with its field label and hint, and indeterminate), the
/// progress ring, the segment bar of a whole split into parts, and the
/// Skeleton standing in for a file list and a card still loading.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

Widget kitProgressDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Progress & skeleton',
  sections: [
    kitSection('Progress bar', children: [kitSpecimenProgressBars()]),
    kitSection(
      'Colours and thickness',
      children: [kitSpecimenProgressBarColours()],
    ),
    kitSection('Indeterminate', children: [kitSpecimenProgressBarBusy()]),
    kitSection('Segment bar', children: [kitSpecimenSegmentBar()]),
    kitSection('Skeleton', children: [kitSpecimenSkeletonList()]),
    kitSection(
      'Skeleton, pulse and translucent',
      children: [kitSpecimenSkeletonCard()],
    ),
  ],
);

/// An upload under way and the team's storage, each with its field.
Widget kitSpecimenProgressBars() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.l,
  children: const [
    Fluent2ProgressBar(
      value: 0.62,
      label: 'Uploading Launch plan.docx',
      hint: '3 of 5 files',
    ),
    Fluent2ProgressBar(
      value: 9.4,
      max: 10,
      thickness: Fluent2ProgressThickness.large,
      label: 'Team storage',
      hint: '9.4 GB of 10 GB used',
    ),
  ],
);

/// The four colours at the large thickness, and the square ends. A status
/// colour stands in its field, whose message says the status with its glyph.
Widget kitSpecimenProgressBarColours() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.m,
  children: [
    for (final (color, state, says) in const [
      (Fluent2ProgressColor.brand, Fluent2ValidationState.none, null),
      (
        Fluent2ProgressColor.success,
        Fluent2ValidationState.success,
        'Backed up',
      ),
      (
        Fluent2ProgressColor.warning,
        Fluent2ValidationState.warning,
        'Almost out of room',
      ),
      (
        Fluent2ProgressColor.error,
        Fluent2ValidationState.error,
        'Upload stopped',
      ),
    ])
      Fluent2FormField(
        validationMessage: says,
        validationState: state,
        child: Fluent2ProgressBar(
          value: 0.7,
          color: color,
          thickness: Fluent2ProgressThickness.large,
          semanticLabel: '${says ?? 'Uploading'}, 70%',
        ),
      ),
    const Fluent2ProgressBar(
      value: 0.4,
      shape: Fluent2ProgressShape.square,
      semanticLabel: 'Square ends',
    ),
  ],
);

/// Indeterminate, with its field: a third of the track, held still at
/// the middle.
Widget kitSpecimenProgressBarBusy() => const Fluent2ProgressBar(
  label: 'Preparing the export',
  hint: 'This can take a minute',
);

/// What fills the team's storage, the rest left free.
Widget kitSpecimenSegmentBar() => const Fluent2SegmentBar(
  label: 'Storage by type',
  total: 10,
  segments: [
    Fluent2SegmentBarPart('Documents', 3.2, valueText: '3.2 GB'),
    Fluent2SegmentBarPart('Images', 2.4, valueText: '2.4 GB'),
    Fluent2SegmentBarPart('Video', 1.9, valueText: '1.9 GB'),
    Fluent2SegmentBarPart('Recordings', 1.1, valueText: '1.1 GB'),
    Fluent2SegmentBarPart(
      'Other',
      0.8,
      valueText: '0.8 GB',
      hue: Fluent2ChartHue.neutral,
    ),
  ],
);

/// A file list still loading: an avatar and two lines a row.
Widget kitSpecimenSkeletonList() => Fluent2Skeleton(
  label: 'Loading files',
  child: Column(
    mainAxisSize: MainAxisSize.min,
    spacing: Fluent2Spacing.l,
    children: [
      for (var i = 0; i < 3; i++)
        Row(
          spacing: Fluent2Spacing.m,
          children: [
            const Fluent2SkeletonItem(
              shape: Fluent2SkeletonShape.circle,
              size: 32,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Fluent2Spacing.sNudge,
                children: [
                  const Fluent2SkeletonItem(size: 12),
                  FractionallySizedBox(
                    widthFactor: i.isEven ? 0.6 : 0.45,
                    child: const Fluent2SkeletonItem(size: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
    ],
  ),
);

/// A card still loading, pulsing, on a tinted ground.
Widget kitSpecimenSkeletonCard() => Builder(
  builder: (context) {
    final t = context.fluent2Theme;
    return Container(
      padding: const EdgeInsets.all(Fluent2Spacing.m),
      decoration: BoxDecoration(
        color: t.colors.brandBackground2,
        borderRadius: BorderRadius.circular(Fluent2Radius.medium),
      ),
      child: const Fluent2Skeleton(
        label: 'Loading the meeting',
        appearance: Fluent2SkeletonAppearance.translucent,
        animation: Fluent2SkeletonAnimation.pulse,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Fluent2Spacing.s,
          children: [
            Fluent2SkeletonItem(shape: Fluent2SkeletonShape.square, size: 40),
            Fluent2SkeletonItem(size: 16, width: 180),
            Fluent2SkeletonItem(size: 12),
            Fluent2SkeletonItem(size: 12, width: 120),
          ],
        ),
      ),
    );
  },
);
