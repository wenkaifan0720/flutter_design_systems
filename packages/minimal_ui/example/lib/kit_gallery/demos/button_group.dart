/// Joined actions and inline links: a button group (a toolbar) and the
/// link's three uses.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitButtonGroupDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Button group & link',
  sections: [
    kitSection(
      'Button group',
      children: [
        kitSpecimenButtonGroupRange(),
        kitSpecimenButtonGroupFormat(),
        kitNote(
          'One frame, split by full-height hairlines; each action fills its '
          'cell, so its press and focus take the frame\'s corners at the '
          'ends and square ones between.',
        ),
      ],
    ),
    kitSection(
      'Expanded',
      children: [
        // The glyphs that follow the reading direction, as the pagination's
        // and the carousel's arrows do: right to left, Previous points right.
        MinimalButtonGroup(
          expand: true,
          items: [
            MinimalButtonGroupItem(
              label: 'Previous',
              icon: LucideIcons.chevronLeftDir,
              onPressed: () {},
            ),
            MinimalButtonGroupItem(
              label: 'Next',
              icon: LucideIcons.chevronRightDir,
              iconTrails: true,
              onPressed: () {},
            ),
          ],
        ),
      ],
    ),
    kitSection('Link', children: [kitSpecimenLinkInline()]),
  ],
);

// --- catalog specimens -------------------------------------------------------

/// A calendar's week, stepped: back, today and forward, joined. Acts that
/// run once; a choice of Day, Week or Month that stays is a toggle group's.
Widget kitSpecimenButtonGroupRange() => MinimalButtonGroup(
  items: [
    MinimalButtonGroupItem(
      icon: LucideIcons.chevronLeftDir,
      semanticLabel: 'Previous week',
      onPressed: () {},
    ),
    MinimalButtonGroupItem(label: 'Today', onPressed: () {}),
    MinimalButtonGroupItem(
      icon: LucideIcons.chevronRightDir,
      semanticLabel: 'Next week',
      onPressed: () {},
    ),
  ],
);

/// A text toolbar of glyphs: acts that run once (undo, redo, copy, add a
/// link), not formats that stay on, which are a toggle group's.
Widget kitSpecimenButtonGroupFormat() => MinimalButtonGroup(
  items: [
    MinimalButtonGroupItem(
      icon: LucideIcons.undo2Dir,
      semanticLabel: 'Undo',
      onPressed: () {},
    ),
    MinimalButtonGroupItem(
      icon: LucideIcons.redo2Dir,
      semanticLabel: 'Redo',
      onPressed: () {},
    ),
    MinimalButtonGroupItem(
      icon: LucideIcons.copy,
      semanticLabel: 'Copy',
      onPressed: () {},
    ),
    MinimalButtonGroupItem(
      icon: LucideIcons.link,
      semanticLabel: 'Add a link',
      onPressed: () {},
    ),
  ],
);

/// A sign-in form's links: in a line, alone, and one that leaves the app.
Widget kitSpecimenLinkInline() => Builder(
  builder: (context) {
    final t = context.minimalTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A sentence: at a large text size the link runs on to the next
        // line rather than past the column's edge.
        Wrap(
          spacing: MinimalSpacing.s4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('No account?', style: t.body.c(t.mutedForeground)),
            MinimalLink('Create one', onPressed: () {}),
          ],
        ),
        const MinimalGap(MinimalSpacing.s12),
        MinimalLink('Forgot password?', onPressed: () {}),
        const MinimalGap(MinimalSpacing.s12),
        MinimalLink('Terms of service', external: true, onPressed: () {}),
      ],
    );
  },
);
