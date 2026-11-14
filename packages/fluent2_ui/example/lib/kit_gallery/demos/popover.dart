/// Fluent 2's Tooltip (live on icon-only commands, and its bubble drawn
/// in place, normal and inverted, with and without the arrow), the
/// Popover surface (Fluent 2's flyout) in its three appearances, opened
/// from a control, and the TeachingPopover drawn in place and opened as
/// a tour's step.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

Widget kitPopoverDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Tooltip & popover',
  sections: [
    kitSection(
      'Tooltips (rest the pointer or long-press)',
      children: [
        kitRow([
          for (final (icon, name) in const [
            (Fluent2Icons.share, 'Share'),
            (Fluent2Icons.pin, 'Pin to the top of Files'),
            (Fluent2Icons.delete, 'Move to the recycle bin'),
          ])
            Fluent2Tooltip(
              message: name,
              child: Fluent2IconButton(icon, label: name, onPressed: () {}),
            ),
          Fluent2Tooltip(
            message: 'Copy link',
            appearance: Fluent2TooltipAppearance.inverted,
            position: Fluent2TooltipPosition.below,
            withArrow: true,
            child: Fluent2IconButton(
              Fluent2Icons.link,
              label: 'Copy link',
              onPressed: () {},
            ),
          ),
        ]),
      ],
    ),
    kitSection('Tooltip bubbles', children: [_tooltipBubbles()]),
    kitSection('Popover surfaces', children: [_flyouts()]),
    kitSection('Opened from a control', children: [const _OpenFlyout()]),
    kitSection(
      'Teaching popover',
      children: [
        kitSpecimenTeachingPopover(),
        kitSpecimenTeachingPopoverStep(),
      ],
    ),
    kitSection('A tour step', children: [const _OpenTour()]),
  ],
);

/// The tooltip's bubble, normal and inverted, the arrow on one.
Widget _tooltipBubbles() => kitRow([
  const Fluent2TooltipBubble(message: 'Share'),
  Fluent2TooltipBubble(
    message: 'Launch plan.docx, edited 2h ago by Kai Tanaka',
    placement: Fluent2ArrowPlacement()..offset = 40,
  ),
  Fluent2TooltipBubble(
    message: 'Copy link',
    appearance: Fluent2TooltipAppearance.inverted,
    placement: Fluent2ArrowPlacement()
      ..isAbove = false
      ..offset = 24,
  ),
]);

/// The surface in its three appearances, the arrow up on the first.
Widget _flyouts() => Builder(
  builder: (context) {
    final t = context.fluent2Theme;
    Widget words(String text, Color ink) => Text(text, style: t.body1.c(ink));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Fluent2Spacing.l,
      children: [
        Fluent2Flyout(
          arrowAt: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: Fluent2Spacing.s,
            children: [
              Text('Shared with 4 people', style: t.subtitle2.c(t.textPrimary)),
              words('Ines, Kai, Mara and Priya can edit.', t.textSecondary),
            ],
          ),
        ),
        Fluent2Flyout(
          appearance: Fluent2FlyoutAppearance.brand,
          child: words(
            'Meetings start in 5 minutes.',
            t.colors.neutralForegroundOnBrand,
          ),
        ),
        Fluent2Flyout(
          appearance: Fluent2FlyoutAppearance.inverted,
          size: Fluent2FlyoutSize.small,
          child: words(
            'Saved to Northwind',
            t.colors.neutralForegroundStaticInverted,
          ),
        ),
      ],
    );
  },
);

/// A single tip pointing up at its control, in the brand.
Widget kitSpecimenTeachingPopover() => Fluent2TeachingPopover(
  title: 'Pin your files',
  body: 'Pinned files stay at the top of Files for everyone on the team.',
  secondaryLabel: 'Not now',
  onSecondaryPressed: () {},
  onPrimaryPressed: () {},
  onDismiss: () {},
  arrowAt: 40,
);

/// A tour's second step on the neutral surface, pointing down at its
/// control.
Widget kitSpecimenTeachingPopoverStep() => Fluent2TeachingPopover(
  title: 'Channels keep work together',
  body: 'Start one for each project; its files and chat stay in it.',
  appearance: Fluent2FlyoutAppearance.neutral,
  secondaryLabel: 'Back',
  onSecondaryPressed: () {},
  primaryLabel: 'Next',
  onPrimaryPressed: () {},
  onDismiss: () {},
  step: 2,
  steps: 3,
  arrowAt: 48,
  arrowUp: false,
);

class _OpenFlyout extends StatelessWidget {
  const _OpenFlyout();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Builder(
      builder: (context) => Fluent2Button(
        'Who can see this',
        icon: Fluent2Icons.people,
        onPressed: () => Fluent2Flyout.show<void>(
          context,
          label: 'Access',
          preferBelow: true,
          builder: (context) {
            final t = context.fluent2Theme;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: Fluent2Spacing.s,
              children: [
                Text('Design channel', style: t.subtitle2.c(t.textPrimary)),
                Text(
                  'Everyone in Design can open and edit this file.',
                  style: t.body1.c(t.textSecondary),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _OpenTour extends StatelessWidget {
  const _OpenTour();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Builder(
      builder: (context) => Fluent2Button(
        'New channel',
        icon: Fluent2Icons.add,
        appearance: Fluent2ButtonAppearance.primary,
        onPressed: () => Fluent2TeachingPopover.show(
          context,
          title: 'Channels keep work together',
          body: 'Start one for each project; files and chat stay in it.',
          secondaryLabel: 'Back',
          primaryLabel: 'Next',
          step: 2,
          steps: 3,
        ),
      ),
    ),
  );
}
