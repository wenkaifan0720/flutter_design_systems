/// Minimal's controls that act: the button in four variants and three
/// sizes, with a glyph, disabled and expanded; the square icon button in
/// its four registers; and the press feedback a composed surface borrows.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitButtonDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Button',
  sections: [
    for (final size in MinimalButtonSize.values)
      kitSection(
        'Variants · ${size.name}',
        children: [
          kitRow([
            for (final variant in MinimalButtonVariant.values)
              MinimalButton(
                _label(variant),
                variant: variant,
                size: size,
                onPressed: () {},
              ),
          ]),
        ],
      ),
    kitSection(
      'With a glyph',
      children: [
        kitRow([
          MinimalButton('New habit', icon: LucideIcons.plus, onPressed: () {}),
          MinimalButton(
            'Filter',
            icon: LucideIcons.listFilter,
            variant: MinimalButtonVariant.secondary,
            onPressed: () {},
          ),
          MinimalButton(
            'Export',
            icon: LucideIcons.download,
            variant: MinimalButtonVariant.ghost,
            onPressed: () {},
          ),
        ]),
      ],
    ),
    kitSection(
      'Disabled',
      children: [
        kitRow([
          for (final variant in MinimalButtonVariant.values)
            MinimalButton(_label(variant), variant: variant),
        ]),
      ],
    ),
    kitSection(
      'Expanded',
      children: [
        MinimalButton('Create habit', expand: true, onPressed: () {}),
        kitNote(
          'It spans a phone\'s column; from a tablet up it stops at '
          '320 px, on its start.',
        ),
      ],
    ),
    // The icon buttons as the buttons above: one row a size, the four
    // registers in the same order and with the same glyphs in each.
    for (final size in MinimalButtonSize.values)
      kitSection(
        'Icon buttons · ${size.name}',
        children: [
          _iconButtons(size: size),
          if (size == MinimalButtonSize.large)
            kitNote(
              'Outline is the top bar\'s square; solid is the one primary '
              'act. Every control pads its hit area to 44.',
            ),
        ],
      ),
    kitSection(
      'Icon buttons · disabled',
      children: [_iconButtons(enabled: false)],
    ),
    kitSection(
      'Icon buttons · on and off',
      children: [
        const _Favourite(),
        kitNote(
          'Each register on, then off. On, the glyph and a square\'s '
          'hairline turn to the full ink; off, the glyph is muted.',
        ),
      ],
    ),
    kitSection('Pressable', children: const [_PressableTile()]),
  ],
);

/// The four icon button registers at [size], in their order: the search
/// square in the three quiet ones, the plus on the primary; disabled
/// unless [enabled].
Widget _iconButtons({
  MinimalButtonSize size = MinimalButtonSize.medium,
  bool enabled = true,
}) => kitRow([
  for (final variant in MinimalIconButtonVariant.values)
    MinimalIconButton(
      variant == MinimalIconButtonVariant.primary
          ? LucideIcons.plus
          : LucideIcons.search,
      label: variant == MinimalIconButtonVariant.primary
          ? 'New habit'
          : 'Search',
      variant: variant,
      size: size,
      onPressed: enabled ? () {} : null,
    ),
]);

String _label(MinimalButtonVariant variant) => switch (variant) {
  MinimalButtonVariant.primary => 'Create',
  MinimalButtonVariant.secondary => 'Cancel',
  MinimalButtonVariant.ghost => 'Skip',
  MinimalButtonVariant.destructive => 'Delete',
};

/// A composed surface that borrows the system's press feedback: the wash
/// while pressed, the focus ring under the keyboard, Enter to activate.
class _PressableTile extends StatefulWidget {
  const _PressableTile();

  @override
  State<_PressableTile> createState() => _PressableTileState();
}

class _PressableTileState extends State<_PressableTile> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return MinimalPressable(
      radius: t.cardRadius,
      checked: _done,
      semanticLabel: 'Morning run',
      onPressed: () => setState(() => _done = !_done),
      child: Container(
        padding: const EdgeInsets.all(MinimalSpacing.s12),
        decoration: ShapeDecoration(
          shape: t.shapes.medium.copyWith(
            side: BorderSide(color: t.border, width: t.hairline),
          ),
        ),
        child: Row(
          children: [
            MinimalStatusIcon(
              _done ? MinimalTaskStatus.done : MinimalTaskStatus.todo,
            ),
            const MinimalGap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Morning run', style: t.body.medium),
                  Text(
                    _done ? 'Kept today' : 'Tap to mark it kept',
                    style: t.caption,
                  ),
                ],
              ),
            ),
            // The streak grows the moment the day is kept.
            Text(_done ? '13d' : '12d', style: t.mono.c(t.mutedForeground)),
          ],
        ),
      ),
    );
  }
}

/// An on/off icon button: the favourite star, in the full ink while on.
class _Favourite extends StatefulWidget {
  const _Favourite();

  @override
  State<_Favourite> createState() => _FavouriteState();
}

class _FavouriteState extends State<_Favourite> {
  /// Each register twice, on then off; each star toggles alone.
  final _on = [true, false, true, false, true, false];

  static const _variants = [
    MinimalIconButtonVariant.outline,
    MinimalIconButtonVariant.ghost,
    MinimalIconButtonVariant.secondary,
  ];

  Widget _star(int i) => MinimalIconButton(
    LucideIcons.star,
    label: 'Favourite',
    variant: _variants[i ~/ 2],
    selected: _on[i],
    onPressed: () => setState(() => _on[i] = !_on[i]),
  );

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: MinimalSpacing.s24,
    runSpacing: MinimalSpacing.s8,
    children: [
      for (var pair = 0; pair < _variants.length; pair++)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _star(pair * 2),
            const SizedBox(width: MinimalSpacing.s8),
            _star(pair * 2 + 1),
          ],
        ),
    ],
  );
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// The one thing to act on, full width at the large size.
Widget kitSpecimenButtonPrimaryLarge() => MinimalButton(
  'Create habit',
  size: MinimalButtonSize.large,
  expand: true,
  onPressed: () {},
);

/// The bordered neutral beside it, with a leading glyph.
Widget kitSpecimenButtonSecondary() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalButton(
      'Filter',
      icon: LucideIcons.listFilter,
      variant: MinimalButtonVariant.secondary,
      onPressed: () {},
    ),
  ],
);

/// The quiet action, bare ink at the small size.
Widget kitSpecimenButtonGhostSmall() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalButton(
      'Skip today',
      variant: MinimalButtonVariant.ghost,
      size: MinimalButtonSize.small,
      onPressed: () {},
    ),
  ],
);

/// The destructive act in the danger fill.
Widget kitSpecimenButtonDanger() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalButton(
      'Delete habit',
      icon: LucideIcons.trash2,
      variant: MinimalButtonVariant.destructive,
      onPressed: () {},
    ),
  ],
);

/// The top bar's bordered squares.
Widget kitSpecimenIconButtonOutline() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalIconButton(
      LucideIcons.search,
      label: 'Search',
      variant: MinimalIconButtonVariant.outline,
      onPressed: () {},
    ),
    const MinimalGap(MinimalSpacing.s8),
    MinimalIconButton(
      LucideIcons.slidersHorizontal,
      label: 'Filters',
      variant: MinimalIconButtonVariant.outline,
      onPressed: () {},
    ),
  ],
);

/// The ink square the one primary act wears.
Widget kitSpecimenIconButtonSolid() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalIconButton(
      LucideIcons.plus,
      label: 'New habit',
      variant: MinimalIconButtonVariant.primary,
      onPressed: () {},
    ),
  ],
);

/// The bare glyph a row or a sheet header carries, one of them toggled on.
Widget kitSpecimenIconButtonGhost() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalIconButton(
      LucideIcons.star,
      label: 'Favourite',
      variant: MinimalIconButtonVariant.ghost,
      selected: true,
      onPressed: () {},
    ),
    const MinimalGap(MinimalSpacing.s8),
    MinimalIconButton(
      LucideIcons.ellipsis,
      label: 'More',
      variant: MinimalIconButtonVariant.ghost,
      onPressed: () {},
    ),
  ],
);
