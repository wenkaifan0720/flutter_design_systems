/// The media group's demo: the image on the corner scale, at its ratios and
/// fits, masked by library shapes (one hero moment), and the avatar in its
/// three kinds, five sizes and three tones. Pictures resolve from media
/// slots; the gallery bundles none, so each shows the placeholder a pending
/// picture paints.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The media group's demo, in [brightness].
Widget kitMediaDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Media',
  sections: const <Widget>[
    _Corners(),
    _Ratios(),
    _Shaped(),
    _AvatarSizes(),
    _AvatarKinds(),
    _People(),
    _Piles(),
  ],
);

class _Corners extends StatelessWidget {
  const _Corners();

  @override
  Widget build(BuildContext context) => kitSection(
    'Image · corner scale',
    children: <Widget>[
      const ExpressiveMedia(
        slotId: 'harbour-dusk',
        aspectRatio: 16 / 9,
        corner: ExpressiveCorner.extraLarge,
        semanticLabel: 'The harbour at dusk',
      ),
      Row(
        spacing: kitGap,
        children: <Widget>[
          for (final (slot, corner) in const <(String, ExpressiveCorner)>[
            ('market-stall', ExpressiveCorner.none),
            ('bread-loaf', ExpressiveCorner.medium),
            ('tomato-crate', ExpressiveCorner.large),
            ('forest-canopy', ExpressiveCorner.extraLarge),
          ])
            Expanded(
              child: ExpressiveMedia(
                slotId: slot,
                aspectRatio: 1,
                corner: corner,
              ),
            ),
        ],
      ),
    ],
  );
}

class _Ratios extends StatelessWidget {
  const _Ratios();

  @override
  Widget build(BuildContext context) => kitSection(
    'Image · ratio, fit and alignment',
    children: const <Widget>[
      Row(
        spacing: kitGap,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            // Cropped to 3:4 and pinned to the bottom, so the stand keeps
            // its base (alignment).
            child: ExpressiveMedia(
              slotId: 'stage-microphone',
              aspectRatio: 3 / 4,
              alignment: Alignment.bottomCenter,
              corner: ExpressiveCorner.large,
              semanticLabel: 'A microphone waiting on a dim stage',
            ),
          ),
          Expanded(
            child: ExpressiveMedia(
              slotId: 'landscape-dunes',
              aspectRatio: 4 / 3,
              fit: BoxFit.contain,
              corner: ExpressiveCorner.large,
              semanticLabel: 'Dunes at noon',
            ),
          ),
        ],
      ),
    ],
  );
}

class _Shaped extends StatelessWidget {
  const _Shaped();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Shaped · one hero moment',
      children: <Widget>[
        ExpressiveHeroMoment(
          label: 'shaped media',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: kitGap,
            children: <Widget>[
              Row(
                spacing: kitGap,
                children: <Widget>[
                  for (final (slot, shape)
                      in const <(String, ExpressiveMaterialShape)>[
                        ('album-tide', ExpressiveMaterialShape.cookie9Sided),
                        ('album-ember', ExpressiveMaterialShape.clover4Leaf),
                        ('album-moss', ExpressiveMaterialShape.arch),
                        ('album-salt', ExpressiveMaterialShape.sunny),
                      ])
                    Expanded(
                      child: ExpressiveMedia.shaped(slotId: slot, shape: shape),
                    ),
                ],
              ),
              Row(
                spacing: ExpressiveSpacing.s16,
                children: <Widget>[
                  const ExpressiveAvatar(
                    name: 'Ines Okafor',
                    size: ExpressiveAvatarSize.extraLarge,
                    shape: ExpressiveMaterialShape.cookie12Sided,
                    tone: ExpressiveMediaTone.tertiary,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Ines Okafor',
                          style: t.type.titleLarge.copyWith(
                            color: t.colors.onSurface,
                          ),
                        ),
                        Text(
                          'Ceramicist · 14 pieces',
                          style: t.type.bodyMedium.copyWith(
                            color: t.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarSizes extends StatelessWidget {
  const _AvatarSizes();

  @override
  Widget build(BuildContext context) => kitSection(
    'Avatar · sizes xs–xl',
    children: <Widget>[
      Wrap(
        spacing: ExpressiveSpacing.s12,
        runSpacing: ExpressiveSpacing.s12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final size in ExpressiveAvatarSize.values)
            ExpressiveAvatar(
              name: 'Mara Quist',
              size: size,
              tone: ExpressiveMediaTone.primary,
            ),
        ],
      ),
    ],
  );
}

class _AvatarKinds extends StatelessWidget {
  const _AvatarKinds();

  @override
  Widget build(BuildContext context) => kitSection(
    'Avatar · image, initials, icon · three tones',
    children: const <Widget>[
      Wrap(
        spacing: ExpressiveSpacing.s12,
        runSpacing: ExpressiveSpacing.s12,
        children: <Widget>[
          ExpressiveAvatar(name: 'Theo Park', slotId: 'face-theo'),
          ExpressiveAvatar(
            name: 'Ada Lindqvist',
            tone: ExpressiveMediaTone.primary,
          ),
          ExpressiveAvatar(
            name: 'Ruth Bello',
            tone: ExpressiveMediaTone.secondary,
          ),
          ExpressiveAvatar(
            name: 'Kenji Mori',
            tone: ExpressiveMediaTone.tertiary,
          ),
          ExpressiveAvatar(
            name: 'Book club',
            icon: ExpressiveSymbols.group,
            tone: ExpressiveMediaTone.secondary,
          ),
          ExpressiveAvatar(name: ''),
        ],
      ),
    ],
  );
}

class _People extends StatelessWidget {
  const _People();

  static const List<(String, String)> _people = <(String, String)>[
    ('Lena Hartmann', 'Shared “Sunday loaves”'),
    ('Omar Haddad', 'Replied to your note'),
    ('Priya Raman', 'Joined Book club'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Avatar · in a row',
      children: <Widget>[
        for (final (name, line) in _people)
          Row(
            spacing: ExpressiveSpacing.s16,
            children: <Widget>[
              ExpressiveAvatar(
                name: name,
                slotId: 'face-${name.split(' ').first.toLowerCase()}',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: t.type.titleMedium.copyWith(
                        color: t.colors.onSurface,
                      ),
                    ),
                    Text(
                      line,
                      style: t.type.bodyMedium.copyWith(
                        color: t.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// A wide picture on the extra-large corner.
Widget kitSpecimenImageHarbour() => const ExpressiveMedia(
  slotId: 'harbour-dusk',
  aspectRatio: 16 / 9,
  corner: ExpressiveCorner.extraLarge,
  semanticLabel: 'The harbour at dusk',
);

/// Initials on their tonal circle, at three sizes.
Widget kitSpecimenAvatarInitials() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: <Widget>[
    ExpressiveAvatar(name: 'Mara Quist', size: ExpressiveAvatarSize.small),
    SizedBox(width: ExpressiveSpacing.s16),
    ExpressiveAvatar(name: 'Ines Okafor'),
    SizedBox(width: ExpressiveSpacing.s16),
    ExpressiveAvatar(name: 'Theo Brandt', size: ExpressiveAvatarSize.large),
  ],
);

class _Piles extends StatelessWidget {
  const _Piles();

  @override
  Widget build(BuildContext context) =>
      kitSection('Groups of faces', children: <Widget>[kitSpecimenFacePile()]);
}

/// Three faces, then nine with six counted, in two sizes.
Widget kitSpecimenFacePile() => const Wrap(
  spacing: ExpressiveSpacing.s24,
  runSpacing: ExpressiveSpacing.s16,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    ExpressiveAvatarGroup(
      faces: <ExpressiveFace>[
        ExpressiveFace('Noor Wahid'),
        ExpressiveFace('Ada Kim'),
        ExpressiveFace('Jon Ruiz'),
      ],
    ),
    ExpressiveAvatarGroup(
      faces: <ExpressiveFace>[
        ExpressiveFace('Noor Wahid'),
        ExpressiveFace('Ada Kim'),
        ExpressiveFace('Jon Ruiz'),
        ExpressiveFace('Mia Chen'),
      ],
      total: 9,
      size: ExpressiveAvatarSize.medium,
    ),
  ],
);
