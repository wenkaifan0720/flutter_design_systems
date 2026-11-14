/// Work in flight and what is new: a spinner, skeletons, a meter and count
/// badges.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitFeedbackDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Spinner, skeleton, meter, badge',
  sections: [
    kitSection(
      'Circular progress',
      children: [
        kitRow(const [
          MinimalCircularProgressIndicator(label: 'Syncing'),
          MinimalCircularProgressIndicator(value: 0.35, size: 24),
          MinimalCircularProgressIndicator(
            value: 1,
            size: 24,
            tone: MinimalTone.success,
          ),
        ]),
      ],
    ),
    kitSection('Skeleton', children: [kitSpecimenSkeletonRow()]),
    kitSection(
      'Meter',
      children: [
        // Under its thresholds a meter reads in the ink; past them it warns.
        const MinimalMeter(
          label: 'Projects',
          value: 3,
          max: 10,
          valueLabel: '3/10',
          warningAt: 0.8,
          destructiveAt: 0.95,
        ),
        kitSpecimenMeterStorage(),
        const MinimalMeter(
          label: 'Seats',
          value: 19,
          max: 20,
          valueLabel: '19/20',
          warningAt: 0.8,
          destructiveAt: 0.95,
        ),
      ],
    ),
    kitSection('Badge', children: [kitSpecimenBadgeCounts()]),
  ],
);

// --- catalog specimens -------------------------------------------------------

/// A list row loading: a face and two lines.
Widget kitSpecimenSkeletonRow() => const Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    MinimalSkeleton.circle(size: 32),
    MinimalGap(MinimalSpacing.s12),
    Expanded(child: MinimalSkeleton.text(lines: 2)),
  ],
);

/// A spinner beside the words of a wait.
Widget kitSpecimenCircularProgress() => Builder(
  builder: (context) {
    final t = context.minimalTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MinimalCircularProgressIndicator(label: 'Syncing'),
        const MinimalGap(MinimalSpacing.s8),
        Text('Syncing…', style: t.bodySmall.c(t.mutedForeground)),
      ],
    );
  },
);

/// Storage nearly full.
Widget kitSpecimenMeterStorage() => const MinimalMeter(
  label: 'Storage',
  value: 8.4,
  max: 10,
  valueLabel: '8.4 of 10 GB',
  warningAt: 0.8,
  destructiveAt: 0.95,
);

/// Counts on a glyph and a face, and a dot. A count stands out past its
/// host's corner without taking room, so the row leaves that room itself:
/// the gap is wider than a "99+" reaches at the largest text, and the top
/// clears the half a count that stands above its glyph.
Widget kitSpecimenBadgeCounts() => const Padding(
  padding: EdgeInsets.only(top: MinimalSpacing.s8),
  child: Wrap(
    spacing: MinimalSpacing.s32,
    runSpacing: MinimalSpacing.s24,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      MinimalBadge(count: 3, child: MinimalIcon(LucideIcons.bell, size: 24)),
      MinimalBadge(count: 128, child: MinimalIcon(LucideIcons.inbox, size: 24)),
      MinimalBadge(tone: MinimalTone.success, child: MinimalAvatar('Ana Ruiz')),
      // A quiet count stands after what it counts, as a list's does.
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Archived'),
          MinimalGap(MinimalSpacing.s8),
          MinimalBadge(count: 12, tone: MinimalTone.neutral),
        ],
      ),
    ],
  ),
);
