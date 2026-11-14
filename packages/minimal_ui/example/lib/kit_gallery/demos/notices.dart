/// What a page says beside its content: tooltips, inline alerts and an
/// action sheet.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitNoticesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Tooltip, banner, action sheet',
  sections: [
    kitSection(
      'Tooltip',
      children: [
        kitSpecimenTooltipIcons(),
        kitNote('Point at a glyph, long-press it, or tab to it.'),
      ],
    ),
    kitSection(
      'Banner',
      children: [
        kitSpecimenBannerTrial(),
        _LiveBanner(),
        const MinimalBanner(
          tone: MinimalTone.destructive,
          title: 'Sync failed',
          message: 'Changes stay on this device until it works again.',
        ),
        const MinimalBanner(
          tone: MinimalTone.success,
          title: 'Domain verified',
        ),
      ],
    ),
    kitSection(
      'Action sheet',
      children: [
        // In a row, so the trigger hugs its label.
        Builder(
          builder: (context) => kitRow([
            MinimalButton(
              'Photo actions',
              variant: MinimalButtonVariant.secondary,
              onPressed: () => showMinimalActionSheet(
                context,
                title: 'IMG_2041.jpg',
                actions: [
                  MinimalActionSheetAction(
                    'Share',
                    icon: LucideIcons.share,
                    onPressed: () {},
                  ),
                  MinimalActionSheetAction(
                    'Save to files',
                    icon: LucideIcons.download,
                    onPressed: () {},
                  ),
                  MinimalActionSheetAction(
                    'Delete',
                    icon: LucideIcons.trash2,
                    destructive: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ]),
        ),
        _Afloat(kitSpecimenActionSheet()),
      ],
    ),
  ],
);

/// The action sheet shown in place, with room for its one soft shadow
/// (about 40 px out each side and 60 below): the shadow ends before the
/// next heading and, on a page wider than a phone, inside the column, never
/// over the sidebar's rule.
class _Afloat extends StatelessWidget {
  const _Afloat(this.card);

  final Widget card;

  @override
  Widget build(BuildContext context) {
    final side = MinimalLayout.isCompact(context) ? 0.0 : MinimalSpacing.s40;
    return Padding(
      padding: EdgeInsets.fromLTRB(side, 0, side, MinimalSpacing.s48),
      child: card,
    );
  }
}

class _LiveBanner extends StatefulWidget {
  @override
  State<_LiveBanner> createState() => _LiveBannerState();
}

class _LiveBannerState extends State<_LiveBanner> {
  bool _shown = true;

  @override
  Widget build(BuildContext context) => _shown
      ? MinimalBanner(
          tone: MinimalTone.primary,
          title: 'New: saved views',
          message: 'Keep a filter and a sort under a name.',
          onDismissed: () => setState(() => _shown = false),
        )
      : MinimalButton(
          'Show the banner again',
          variant: MinimalButtonVariant.ghost,
          onPressed: () => setState(() => _shown = true),
        );
}

// --- catalog specimens -------------------------------------------------------

/// A toolbar's glyphs, each named by a tooltip.
Widget kitSpecimenTooltipIcons() => kitRow([
  MinimalTooltip(
    message: 'Archive',
    child: MinimalIconButton(
      LucideIcons.archive,
      label: 'Archive',
      onPressed: () {},
    ),
  ),
  MinimalTooltip(
    message: 'Copy link',
    child: MinimalIconButton(
      LucideIcons.link,
      label: 'Copy link',
      onPressed: () {},
    ),
  ),
]);

/// A trial ending, with its one action.
Widget kitSpecimenBannerTrial() => MinimalBanner(
  tone: MinimalTone.warning,
  title: 'Your trial ends Friday',
  message: 'Add a card to keep your projects.',
  actions: [
    MinimalButton('Add card', size: MinimalButtonSize.small, onPressed: () {}),
  ],
  onDismissed: () {},
);

/// A photo's actions, Delete last.
Widget kitSpecimenActionSheet() => MinimalActionSheet(
  title: 'IMG_2041.jpg',
  onCancel: () {},
  actions: [
    MinimalActionSheetAction(
      'Share',
      icon: LucideIcons.share,
      onPressed: () {},
    ),
    MinimalActionSheetAction(
      'Save to files',
      icon: LucideIcons.download,
      onPressed: () {},
    ),
    MinimalActionSheetAction(
      'Delete',
      icon: LucideIcons.trash2,
      destructive: true,
      onPressed: () {},
    ),
  ],
);
