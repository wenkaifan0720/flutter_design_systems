/// [FrostedLinearProgressIndicator], [FrostedCircularProgressIndicator] and
/// [FrostedSkeleton]: known and running progress, and the bones a page
/// shows while its content loads.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitProgressDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Progress',
  sections: [
    kitSection(
      'Linear',
      children: const [
        FrostedLinearProgressIndicator(
          label: 'Uploading photos',
          value: 0.62,
          valueLabel: '62%',
        ),
        FrostedLinearProgressIndicator(label: 'Syncing'),
      ],
    ),
    kitSection(
      'Circular',
      children: [
        kitRow(const [
          FrostedCircularProgressIndicator(value: 0.25, label: 'Backup'),
          FrostedCircularProgressIndicator(value: 0.8, label: 'Storage'),
          FrostedCircularProgressIndicator(label: 'Loading'),
        ]),
      ],
    ),
    kitSection(
      'Skeleton',
      children: [
        Row(
          spacing: FrostedSpacing.s12,
          children: [
            const FrostedSkeleton.circle(),
            const Expanded(child: FrostedSkeleton.text(lines: 2)),
          ],
        ),
        const FrostedSkeleton(height: 120),
      ],
    ),
  ],
);

/// A quarter synced.
Widget kitSpecimenCircularProgress() => const Center(
  heightFactor: 1,
  child: FrostedCircularProgressIndicator(value: 0.25, label: 'Syncing'),
);

/// An upload past half.
Widget kitSpecimenLinearProgress() =>
    const FrostedLinearProgressIndicator(value: 0.6, label: 'Uploading');

/// A row's two lines still loading.
Widget kitSpecimenSkeleton() => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 8,
  children: [
    FrostedSkeleton(width: 160, height: 16),
    FrostedSkeleton(width: 240, height: 12),
  ],
);
