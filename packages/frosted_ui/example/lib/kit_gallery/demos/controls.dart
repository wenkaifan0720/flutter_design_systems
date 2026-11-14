/// The chrome's controls: [FrostedButton] in its two variants (the ink, the
/// glass), each at its small size for a tile's head or a line of words,
/// and two sharing a line in a [FrostedButtonRow]; [FrostedIconButton] (back,
/// close, the bell with its [FrostedBadgeDot]); [FrostedAvatar], the owner on
/// the pearl, each enabled and disabled; [FrostedLink], a line with a
/// link inside it; [FrostedAvatarGroup], a group's faces overlapped; and
/// [FrostedProfileHero], the owner's lead on the profile, its [FrostedProfileCount]s
/// at its foot.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitControlsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Controls',
  sections: [
    // Each where an app stands it, its caption saying where: a button off
    // the keyline is placed there, not adrift.
    kitSection(
      'The one act, full width (from 600 wide, 320 at most)',
      children: [kitSpecimenButtonInk()],
    ),
    kitSection(
      'Centred, as an empty search holds it',
      children: [kitSpecimenButtonGlass()],
    ),
    kitSection(
      'Small, at the end of a tile’s head',
      children: [kitSpecimenButtonSmall()],
    ),
    kitSection(
      'Disabled',
      children: [
        kitRow([
          const FrostedButton('Review transfer', onPressed: null),
          const FrostedButton.glass('Cancel', onPressed: null),
          const FrostedButton.glass(
            'Edit',
            size: FrostedButtonSize.small,
            onPressed: null,
          ),
        ]),
      ],
    ),
    kitSection(
      'A row of two, and a longer word keeping its width',
      children: [
        FrostedButtonRow(
          children: [
            FrostedButton.glass('Cancel', onPressed: () {}),
            FrostedButton(
              'Freeze',
              icon: LucideIcons.snowflake,
              onPressed: () {},
            ),
          ],
        ),
        // The review's acts, inline after its details as the source sets
        // them.
        FrostedButtonRow(
          children: [
            FrostedButton.glass('Edit', onPressed: () {}),
            FrostedButton('Transfer \$500.00', onPressed: () {}),
          ],
        ),
      ],
    ),
    kitSection('Round buttons', children: [kitSpecimenRoundButtons()]),
    kitSection(
      'Round, disabled',
      children: [
        kitRow([
          const FrostedIconButton(
            LucideIcons.share,
            label: 'Share',
            onPressed: null,
          ),
          const FrostedBell(unread: 0, onPressed: null),
        ]),
      ],
    ),
    kitSection(
      'Avatars',
      children: [
        kitSpecimenAvatars(),
        kitRow([
          const FrostedAvatar('JR', size: FrostedAvatarSize.large),
          const FrostedAvatar(
            'IP',
            size: FrostedAvatarSize.large,
            selected: true,
          ),
          const FrostedAvatar(
            'TW',
            size: FrostedAvatarSize.large,
            dimmed: true,
          ),
        ]),
      ],
    ),
    kitSection(
      'A group, overlapped',
      children: [
        kitSpecimenAvatarStack(),
        const FrostedAvatarGroup(['Jonah Reyes', 'Ines Park']),
      ],
    ),
    kitSection("The profile's lead", children: [kitSpecimenProfileHero()]),
    kitSection(
      'A lead with no contact and two counts',
      children: [
        const FrostedProfileHero(
          initials: 'JR',
          name: 'Jonah Reyes',
          meta: 'Member since June 2025',
          counts: [
            FrostedProfileCount(2, 'accounts'),
            FrostedProfileCount(1, 'card'),
          ],
        ),
      ],
    ),
    kitSection(
      'A link inside a line, the last one disabled',
      children: [
        kitSpecimenTextLink(),
        FrostedLink(
          'Change these any time in Profile.',
          link: 'Profile',
          onPressed: () {},
        ),
        const FrostedLink(
          'at Blue Fern Café in October, \$6.48 a visit',
          link: 'Blue Fern Café',
          onPressed: null,
        ),
      ],
    ),
  ],
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// The one act, full width (a sheet's foot, the move's review).
Widget kitSpecimenButtonInk() =>
    FrostedButton('Review transfer', expand: true, onPressed: () {});

/// Clear filters on the glass, centred as the empty search holds it.
Widget kitSpecimenButtonGlass() => Center(
  heightFactor: 1,
  child: FrostedButton.glass(
    'Clear filters',
    icon: LucideIcons.x,
    onPressed: () {},
  ),
);

/// The small pair at a tile head's end: See all on the glass, Add money
/// on the ink.
Widget kitSpecimenButtonSmall() => Align(
  alignment: AlignmentDirectional.centerEnd,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    spacing: FrostedSpacing.s8,
    children: [
      FrostedButton.glass(
        'See all',
        size: FrostedButtonSize.small,
        onPressed: () {},
      ),
      FrostedButton(
        'Add money',
        size: FrostedButtonSize.small,
        icon: LucideIcons.plus,
        onPressed: () {},
      ),
    ],
  ),
);

Widget kitSpecimenRoundButtons() => Row(
  spacing: FrostedSpacing.s16,
  children: [
    FrostedIconButton(
      FrostedGlyphs.back,
      label: 'Back to Home',
      onPressed: () {},
    ),
    FrostedBell(unread: 1, onPressed: () {}),
    FrostedIconButton(
      LucideIcons.x,
      label: 'Close',
      size: FrostedIconButtonSize.small,
      onPressed: () {},
    ),
  ],
);

Widget kitSpecimenAvatars() => Row(
  spacing: FrostedSpacing.s16,
  children: [
    FrostedAvatar('MH', name: 'Profile and settings', onPressed: () {}),
    const FrostedAvatar('MH', size: FrostedAvatarSize.small),
  ],
);

/// Four people of a group of nine overlapped on their pearls, the other
/// five folded into one round of glass.
Widget kitSpecimenAvatarStack() => const Align(
  alignment: AlignmentDirectional.centerStart,
  heightFactor: 1,
  child: FrostedAvatarGroup([
    'Maren Holt',
    'Jonah Reyes',
    'Ines Park',
    'Tomas Weiss',
  ], total: 9),
);

/// The profile's lead: the owner on the 80 pearl, since when, how to
/// reach them, and what they hold.
Widget kitSpecimenProfileHero() => const FrostedProfileHero(
  initials: 'MH',
  name: 'Maren Holt',
  meta: 'Member since October 2023',
  contact: ['maren.holt@example.com', '+1 (415) 555-0142'],
  counts: [
    FrostedProfileCount(5, 'accounts'),
    FrostedProfileCount(2, 'cards'),
    FrostedProfileCount(3, 'goals'),
  ],
);

/// The search summary's line, its merchant a link to the category.
Widget kitSpecimenTextLink() => FrostedLink(
  'at Blue Fern Café in October, \$6.48 a visit',
  link: 'Blue Fern Café',
  onPressed: () {},
);
