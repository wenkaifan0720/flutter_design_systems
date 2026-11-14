/// Tags, avatars, tiles: the small identity marks a row carries — the tone
/// palette they all speak in, the 20 px tinted tag, the deterministic
/// initials avatar at 24/28/32 and its overlapping stack, and the bordered
/// icon tile in every tone and size.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitIdentityDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Tags, avatars, tiles',
  sections: [
    kitSection(
      'Tone palette',
      children: [
        const _TonePalette(),
        kitNote(
          'Each tone shows its dot, its ink and its quiet fill: the same '
          'three colours every tag, tile, badge and delta speaks in. A '
          'neutral icon tile alone has no fill: it stands on the ground in '
          'a hairline, as a settings row\'s glyph does.',
        ),
      ],
    ),
    kitSection(
      'Tag',
      children: [
        kitRow(const [
          MinimalTag('Draft'),
          MinimalTag('New', tone: MinimalTone.primary),
          MinimalTag('Paid', tone: MinimalTone.success),
          MinimalTag('Late', tone: MinimalTone.warning),
          MinimalTag('Overdue', tone: MinimalTone.destructive),
        ]),
        // A category or a figure stays in ink; only a status takes a tone.
        kitRow(const [
          MinimalTag('v2.4', icon: LucideIcons.tag),
          MinimalTag('Evening', icon: LucideIcons.moon),
          MinimalTag('12d', icon: LucideIcons.flame),
          MinimalTag(
            'Kept',
            icon: LucideIcons.circleCheck,
            tone: MinimalTone.success,
          ),
        ]),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: MinimalTag('Standing order · every Tuesday and Friday'),
        ),
        kitNote(
          'A category or a figure stays in ink; a tone marks a status. A '
          'long label runs its words, and ellipsizes only where its line '
          'ends.',
        ),
      ],
    ),
    kitSection(
      'Avatar · 24 / 28 / 32',
      children: [
        kitRow(const [
          MinimalAvatar('Hanna Berg', size: 24),
          MinimalAvatar('Hanna Berg'),
          MinimalAvatar('Hanna Berg', size: 32),
        ]),
        kitRow([for (final name in _people) MinimalAvatar(name)]),
        kitRow(const [
          MinimalAvatar(
            'Tom Alves',
            size: 32,
            image: MinimalPlaceholderImage(MinimalMediaKind.avatar, 3),
          ),
          MinimalAvatar('Mara Quintero', size: 32, media: 'face-mara'),
        ]),
        kitNote(
          'Initials and shade come from the name, the same every time: the '
          'initials in ink on a neutral shade of the muted ground, never the '
          'accent or a status colour. A media slot that has not resolved '
          'falls back to the initials.',
        ),
      ],
    ),
    kitSection('Avatar stack', children: const [_Members()]),
    kitSection(
      'Icon tile',
      children: [
        // Each tone on a glyph that has its status: a tile names a kind of
        // thing, and only a status colours one.
        kitRow([
          for (final tone in MinimalTone.values)
            MinimalIconTile(switch (tone) {
              MinimalTone.neutral => LucideIcons.settings,
              MinimalTone.primary => LucideIcons.bell,
              MinimalTone.success => LucideIcons.circleCheck,
              MinimalTone.warning => LucideIcons.clock,
              MinimalTone.destructive => LucideIcons.triangleAlert,
            }, tone: tone),
        ]),
        kitRow(const [
          MinimalIconTile(LucideIcons.settings, size: 24),
          MinimalIconTile(LucideIcons.settings),
          MinimalIconTile(LucideIcons.settings, size: 32),
          MinimalIconTile(LucideIcons.settings, size: 40),
        ]),
        MinimalListSection(
          inset: true,
          children: [
            MinimalListTile(
              leading: const MinimalIconTile(LucideIcons.receipt),
              title: 'Orders',
              meta: '38',
              chevron: true,
              onTap: () {},
            ),
            // Kinds of thing, so neutral: the words say which.
            MinimalListTile(
              leading: const MinimalIconTile(LucideIcons.croissant),
              title: 'Products',
              meta: '24',
              chevron: true,
              onTap: () {},
            ),
            MinimalListTile(
              leading: const MinimalIconTile(LucideIcons.users),
              title: 'Customers',
              meta: '112',
              chevron: true,
              onTap: () {},
            ),
          ],
        ),
      ],
    ),
  ],
);

const _people = [
  'Oskar Lind',
  'Ines Duarte',
  'Tom Alves',
  'Liv Sande',
  'Jonas Weber',
  'Café Morgen',
];

/// Each tone's three resolved colours: ink, subtle fill and dot.
class _TonePalette extends StatelessWidget {
  const _TonePalette();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    Widget chip(Color color) => Container(
      width: 20,
      height: 20,
      decoration: ShapeDecoration(
        color: color,
        shape: t.shapes.mark.copyWith(
          side: BorderSide(color: t.border, width: t.hairline),
        ),
      ),
    );
    return MinimalListSection(
      inset: true,
      children: [
        for (final tone in MinimalTone.values)
          Builder(
            builder: (context) {
              final MinimalToneColors colors = t.tone(tone);
              return MinimalListTile(
                dense: true,
                leading: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.indicator,
                    shape: BoxShape.circle,
                  ),
                ),
                title: tone.name,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    chip(colors.foreground),
                    const MinimalGap(MinimalSpacing.s4),
                    chip(colors.background),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

/// A member list whose stack grows and folds into +N.
class _Members extends StatefulWidget {
  const _Members();

  @override
  State<_Members> createState() => _MembersState();
}

class _MembersState extends State<_Members> {
  static const _everyone = [
    'Hanna Berg',
    'Oskar Lind',
    'Ines Duarte',
    'Tom Alves',
    'Liv Sande',
    'Mara Quintero',
    'Jonas Weber',
  ];

  int _count = 3;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final members = _everyone.take(_count).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        kitRow(const [
          MinimalAvatarGroup(['Hanna Berg', 'Oskar Lind']),
          MinimalAvatarGroup([
            'Hanna Berg',
            'Oskar Lind',
            'Ines Duarte',
          ], size: 28),
          MinimalAvatarGroup(_everyone, size: 32, max: 3),
        ]),
        const MinimalGap(MinimalSpacing.s12),
        MinimalCard(
          padding: MinimalInsets.horizontal12Vertical8,
          child: Row(
            children: [
              MinimalAvatarGroup(members, size: 28),
              const MinimalGap(MinimalSpacing.s12),
              Expanded(
                child: Text(
                  '${members.length} members',
                  style: t.bodySmall.c(t.mutedForeground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              MinimalIconButton(
                LucideIcons.minus,
                label: 'Remove member',
                size: MinimalButtonSize.small,
                variant: MinimalIconButtonVariant.outline,
                onPressed: _count > 1
                    ? () => setState(() => _count -= 1)
                    : null,
              ),
              const MinimalGap(MinimalSpacing.s4),
              MinimalIconButton(
                LucideIcons.plus,
                label: 'Add member',
                size: MinimalButtonSize.small,
                variant: MinimalIconButtonVariant.outline,
                onPressed: _count < _everyone.length
                    ? () => setState(() => _count += 1)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// A record's state in the success tone.
Widget kitSpecimenTagSuccess() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalTag('Paid', tone: MinimalTone.success),
    MinimalGap(MinimalSpacing.s8),
    MinimalTag(
      'Kept',
      icon: LucideIcons.circleCheck,
      tone: MinimalTone.success,
    ),
  ],
);

/// A record's state in the danger tone.
Widget kitSpecimenTagDanger() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [MinimalTag('Overdue', tone: MinimalTone.destructive)],
);

/// The neutral tag on its hairline, and a category's dot label.
Widget kitSpecimenTagNeutral() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalTag('v2.4', icon: LucideIcons.tag),
    MinimalGap(MinimalSpacing.s8),
    MinimalTag('Bug', dot: MinimalTone.destructive),
  ],
);

/// People as deterministic initials, each on the shade their name picks.
Widget kitSpecimenAvatarInitials() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalAvatar('Hanna Berg', size: 32),
    MinimalGap(MinimalSpacing.s8),
    MinimalAvatar('Oskar Lind', size: 32),
    MinimalGap(MinimalSpacing.s8),
    MinimalAvatar('Ines Duarte', size: 32),
    MinimalGap(MinimalSpacing.s8),
    MinimalAvatar('Tom Alves', size: 32),
  ],
);

/// The photo register, drawn by its placeholder until the photo resolves.
Widget kitSpecimenAvatarPhoto() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalAvatar(
      'Tom Alves',
      size: 32,
      image: MinimalPlaceholderImage(MinimalMediaKind.avatar, 3),
    ),
    MinimalGap(MinimalSpacing.s8),
    MinimalAvatar(
      'Liv Sande',
      size: 32,
      image: MinimalPlaceholderImage(MinimalMediaKind.avatar, 5),
    ),
  ],
);

/// A project's members overlapping, the rest as a count.
Widget kitSpecimenAvatarStackMembers() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalAvatarGroup([
      'Hanna Berg',
      'Oskar Lind',
      'Ines Duarte',
      'Tom Alves',
      'Liv Sande',
      'Jonas Weber',
    ], size: 28),
  ],
);

/// Glyphs on their squares, neutral and in each tone.
Widget kitSpecimenIconTileTones() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalIconTile(LucideIcons.settings, size: 32),
    MinimalGap(MinimalSpacing.s8),
    MinimalIconTile(LucideIcons.bell, tone: MinimalTone.primary, size: 32),
    MinimalGap(MinimalSpacing.s8),
    MinimalIconTile(LucideIcons.croissant, tone: MinimalTone.warning, size: 32),
    MinimalGap(MinimalSpacing.s8),
    MinimalIconTile(
      LucideIcons.circleCheck,
      tone: MinimalTone.success,
      size: 32,
    ),
    MinimalGap(MinimalSpacing.s8),
    MinimalIconTile(
      LucideIcons.triangleAlert,
      tone: MinimalTone.destructive,
      size: 32,
    ),
  ],
);
