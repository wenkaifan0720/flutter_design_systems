/// Media & reveal: the image frame (a declared media slot, and the muted,
/// hatched placeholder that stands in while it is pending — in a hero, a
/// grid, a row's thumbnail), the trusted media delivery underneath it, and
/// the 120 ms height-and-fade that brings a row or a block in and out.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitMediaDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Media & reveal',
  sections: [
    kitSection(
      'Media slot',
      children: [
        const MinimalMedia.media(
          'hero-bakery',
          height: 160,
          semanticLabel: 'The bakery counter at opening',
        ),
        kitNote(
          'A photo slot shows its picture once the app has one; until then '
          'a quiet placeholder, the same for the same slot, holds its place.',
        ),
      ],
    ),
    kitSection(
      'Placeholder grid',
      children: [
        Row(
          children: [
            for (final (i, kind) in const [
              MinimalMediaKind.food,
              MinimalMediaKind.product,
              MinimalMediaKind.interior,
            ].indexed) ...[
              if (i > 0) const MinimalGap(MinimalSpacing.s8),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: MinimalMedia(MinimalPlaceholderImage(kind, i + 2)),
                ),
              ),
            ],
          ],
        ),
        kitRow([
          for (final kind in MinimalMediaKind.values)
            MinimalMedia(
              MinimalPlaceholderImage(kind, 1),
              width: 44,
              height: 44,
            ),
        ]),
        kitRow(const [
          MinimalMedia(
            MinimalPlaceholderImage(MinimalMediaKind.nature, 4),
            width: 72,
            height: 48,
            radius: MinimalCorners.r4,
          ),
          MinimalMedia(
            MinimalPlaceholderImage(MinimalMediaKind.nature, 4),
            width: 72,
            height: 48,
          ),
          MinimalMedia(
            MinimalPlaceholderImage(MinimalMediaKind.nature, 4),
            width: 72,
            height: 48,
            radius: MinimalCorners.r12,
          ),
        ]),
        kitNote('Radius 4, 8 (the default) and 12; small tiles carry a glyph.'),
      ],
    ),
    kitSection(
      'In rows',
      children: [
        MinimalListSection(
          inset: true,
          children: [
            for (final (i, (name, detail, price)) in _products.indexed)
              MinimalListTile(
                // Sold out steps back, as a done row does; it still opens
                // its page.
                muted: detail == 'Sold out',
                leading: MinimalMedia(
                  MinimalPlaceholderImage(MinimalMediaKind.food, i * 3 + 1),
                  width: 32,
                  height: 32,
                ),
                title: name,
                subtitle: detail,
                meta: price,
                chevron: true,
                onTap: () {},
              ),
          ],
        ),
      ],
    ),
    kitSection(
      'Media delivery',
      children: [
        const _Delivery(),
        kitNote(
          'A face without a photo yet shows the initials it will keep '
          'until one arrives.',
        ),
      ],
    ),
    kitSection('Reveal', children: const [_RevealNote()]),
    kitSection(
      'Reveal · in a list',
      children: [
        const _RevealList(),
        kitNote(
          'A cross folds its row away and Add habit brings one back; the '
          'rows under it close up, nothing jumps.',
        ),
      ],
    ),
    kitSection('Reveal · horizontal', children: const [_RevealTags()]),
  ],
);

const _products = [
  ('Sourdough loaf', '800 g · 14 in stock', '€6.50'),
  ('Cardamom bun', '6 left · bakes 11:00', '€3.20'),
  ('Seeded rye', 'Sold out', '€5.80'),
];

/// The delivery primitive with a custom fallback: a face that falls back to
/// a Minimal avatar while its slot is unresolved.
class _Delivery extends StatelessWidget {
  const _Delivery();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return MinimalCard(
      padding: MinimalInsets.horizontal12Vertical8,
      child: Row(
        children: [
          const ClipOval(
            child: SizedBox.square(
              dimension: 32,
              child: MinimalMediaImage(
                slotId: 'face-oskar',
                fallback: MinimalAvatar('Oskar Lind', size: 32),
              ),
            ),
          ),
          const MinimalGap(MinimalSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Oskar Lind',
                  style: t.body.medium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Baker · early shift',
                  style: t.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A note that opens under its habit and folds away again.
class _RevealNote extends StatefulWidget {
  const _RevealNote();

  @override
  State<_RevealNote> createState() => _RevealNoteState();
}

class _RevealNoteState extends State<_RevealNote> {
  bool _note = true;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return MinimalCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // One node: the row's button, announcing whether its note is
          // open.
          MergeSemantics(
            child: Semantics(
              expanded: _note,
              child: MinimalListTile(
                icon: LucideIcons.flame,
                title: 'Morning run',
                subtitle: 'Note from Thursday',
                // The disclosure's chevron: down while shut, up while open.
                trailing: AnimatedRotation(
                  turns: _note ? 0.5 : 0,
                  duration: MinimalMotion.fast,
                  curve: MinimalMotion.out,
                  child: MinimalIcon(
                    LucideIcons.chevronDown,
                    size: MinimalIconSize.i16,
                    color: t.textTertiary,
                  ),
                ),
                onTap: () => setState(() => _note = !_note),
              ),
            ),
          ),
          MinimalReveal(
            visible: _note,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                MinimalCard.inset,
                MinimalSpacing.s12,
                MinimalCard.inset,
                MinimalSpacing.s12,
              ),
              decoration: BoxDecoration(border: Border(top: t.rule)),
              child: Text(
                'Out the door before 8. Any distance counts. Legs heavy '
                'after Thursday — keep it easy until Sunday.',
                style: t.bodySmall.c(t.mutedForeground),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A list whose rows are removed and added back, each folding in and out.
/// The rows carry no tick: what they show is arriving and leaving.
class _RevealList extends StatefulWidget {
  const _RevealList();

  @override
  State<_RevealList> createState() => _RevealListState();
}

class _RevealListState extends State<_RevealList> {
  static const _all = [
    ('Meditate', '4d'),
    ('Morning run', '12d'),
    ('Drink water', '10d'),
    ('Journal', '3d'),
    ('Read 20 pages', '6d'),
    ('Water the plants', '2d'),
  ];

  final Set<int> _shown = {0, 1, 2};

  @override
  Widget build(BuildContext context) {
    // The reveals are the group's rows: a row folded away draws no rule,
    // and the add row closes the card.
    return MinimalListSection(
      inset: true,
      children: [
        for (final (i, (name, streak)) in _all.indexed)
          MinimalReveal(
            visible: _shown.contains(i),
            child: MinimalListTile(
              title: name,
              subtitle: '$streak streak',
              padding: const EdgeInsetsDirectional.fromSTEB(
                MinimalCard.inset,
                0,
                MinimalSpacing.s8,
                0,
              ),
              trailing: MinimalIconButton(
                LucideIcons.x,
                label: 'Remove $name',
                size: MinimalButtonSize.small,
                onPressed: () => setState(() => _shown.remove(i)),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(MinimalSpacing.s8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: MinimalButton(
              'Add habit',
              icon: LucideIcons.plus,
              variant: MinimalButtonVariant.ghost,
              size: MinimalButtonSize.small,
              onPressed: _shown.length < _all.length
                  ? () => setState(() {
                      for (var i = 0; i < _all.length; i++) {
                        if (_shown.add(i)) break;
                      }
                    })
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// A tag that folds in beside a name and out again, its width easing: the
/// row's own switch turns it.
class _RevealTags extends StatefulWidget {
  const _RevealTags();

  @override
  State<_RevealTags> createState() => _RevealTagsState();
}

class _RevealTagsState extends State<_RevealTags> {
  bool _late = true;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalCard(
          padding: const EdgeInsets.symmetric(horizontal: MinimalSpacing.s12),
          child: ConstrainedBox(
            // A row's height, so the switch's whole target stands in it.
            constraints: BoxConstraints(minHeight: t.rowHeight),
            child: Row(
              children: [
                Text('1047', style: t.mono.c(t.mutedForeground)),
                const MinimalGap(MinimalSpacing.s12),
                // The name and its tag share what the switch leaves, so
                // the name keeps its whole width on a phone and at the
                // largest text.
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Hanna Berg',
                          style: t.body.medium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const MinimalGap(MinimalSpacing.s8),
                      MinimalReveal(
                        visible: _late,
                        axis: Axis.horizontal,
                        child: const MinimalTag(
                          'Late',
                          tone: MinimalTone.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const MinimalGap(MinimalSpacing.s12),
                MinimalSwitch(
                  value: _late,
                  label: 'Late',
                  onChanged: (late) => setState(() => _late = late),
                ),
              ],
            ),
          ),
        ),
        const MinimalGap(MinimalSpacing.s8),
        kitNote(
          'The switch folds the Late tag in beside the name and out again: '
          'its width eases, nothing jumps.',
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

/// A declared photo slot: its picture once resolved, its placeholder
/// holding the place until then.
Widget kitSpecimenImgMedia() => const MinimalMedia.media(
  'hero-bakery',
  height: 180,
  semanticLabel: 'The bakery counter at opening',
);

/// Square placeholders in a product grid, each seeded by its kind.
Widget kitSpecimenImgGrid() => Row(
  children: [
    for (final (i, kind) in const [
      MinimalMediaKind.food,
      MinimalMediaKind.product,
      MinimalMediaKind.interior,
    ].indexed) ...[
      if (i > 0) const MinimalGap(MinimalSpacing.s8),
      Expanded(
        child: AspectRatio(
          aspectRatio: 1,
          child: MinimalMedia(MinimalPlaceholderImage(kind, i + 2)),
        ),
      ),
    ],
  ],
);
