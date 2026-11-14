/// [FrostedMedia]: a wide picture on its seeded ground, a set of seeds, one
/// with a part laid over it in the night's ink and one in a tile's corner.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitImageDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Image',
  sections: [
    kitSection('Wide', children: [kitSpecimenImageWide()]),
    kitSection('Seeds', children: [kitSpecimenImageSeeds()]),
    kitSection(
      'With a part over it',
      children: [
        FrostedMedia(
          seed: 'Lisbon in May',
          aspect: 16 / 9,
          label: 'Lisbon in May',
          child: Align(
            alignment: AlignmentDirectional.bottomEnd,
            child: Padding(
              padding: const EdgeInsets.all(FrostedSpacing.s12),
              child: Builder(
                builder: (context) {
                  final t = context.frostedTheme;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: FrostedSpacing.s4,
                    children: [
                      Icon(
                        LucideIcons.plane,
                        size: FrostedIconSize.i14,
                        color: t.colorScheme.textPrimary,
                      ),
                      Text(
                        '12 days',
                        style: t.textTheme.labelMedium.c(
                          t.colorScheme.textPrimary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    ),
  ],
);

/// A wide picture drawn from its seed, read as an image.
Widget kitSpecimenImageWide() => const FrostedMedia(
  seed: 'Lisbon in May',
  aspect: 16 / 9,
  label: 'Lisbon in May',
);

/// Three seeds side by side: the same words give the same ground.
Widget kitSpecimenImageSeeds() => const Row(
  spacing: FrostedSpacing.s8,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: FrostedMedia(seed: 'Lisbon in May', aspect: 2 / 3),
    ),
    Expanded(
      child: FrostedMedia(seed: 'Lisbon in May', aspect: 2 / 3),
    ),
    Expanded(
      child: FrostedMedia(
        seed: 'Harbor Transit',
        aspect: 2 / 3,
        radius: FrostedCorners.r10,
      ),
    ),
  ],
);
