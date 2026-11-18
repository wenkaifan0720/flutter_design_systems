/// Rows that open, and the hairline between things that are not rows.
library;

import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitDisclosureDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Disclosure & divider',
  sections: [
    kitSection('Accordion', children: [kitSpecimenDisclosureFaq()]),
    kitSection('With a glyph and a line', children: [_disclosureSettings()]),
    kitSection(
      'Divider',
      children: [
        kitSpecimenDividerOr(),
        Builder(
          builder: (context) {
            final t = context.minimalTheme;
            // The rules run the words' line; at large text a word gives
            // way (ellipsized) before the row runs past the page.
            Widget word(String w) => Flexible(
              child: Text(
                w,
                style: t.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
            return SizedBox(
              height: MediaQuery.textScalerOf(context).scale(24),
              child: Row(
                children: [
                  word('Edit'),
                  const MinimalDivider.vertical(),
                  word('Share'),
                  const MinimalDivider.vertical(),
                  word('Archive'),
                ],
              ),
            );
          },
        ),
      ],
    ),
  ],
);

// --- catalog specimens -------------------------------------------------------

/// Three questions, the first open.
Widget kitSpecimenDisclosureFaq() => Builder(
  builder: (context) {
    final t = context.minimalTheme;
    Widget answer(String s) => Text(s, style: t.bodySmall.c(t.mutedForeground));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalDisclosure(
          title: 'Can I change plans later?',
          initiallyExpanded: true,
          child: answer(
            'Yes. A change takes effect at the next billing date, and unused '
            'time is credited.',
          ),
        ),
        MinimalDisclosure(
          title: 'Who can see my projects?',
          child: answer('Members of the workspace, and guests you invite.'),
        ),
        MinimalDisclosure(
          title: 'Can I export my history?',
          child: answer('Yes, as a CSV file from Settings, at any time.'),
        ),
      ],
    );
  },
);

/// Settings that open: each row led by its glyph, a line under its title.
/// A list whose rows all carry a glyph keeps one keyline. The gallery's own
/// section, not a catalog specimen.
Widget _disclosureSettings() => Builder(
  builder: (context) {
    final t = context.minimalTheme;
    Widget answer(String s) => Text(s, style: t.bodySmall.c(t.mutedForeground));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalDisclosure(
          title: 'Reminders',
          subtitle: 'Times, sounds, quiet hours',
          leading: LucideIcons.bell,
          child: answer('Each habit keeps its own reminder time.'),
        ),
        MinimalDisclosure(
          title: 'Advanced',
          subtitle: 'Webhooks, API keys, audit log',
          leading: LucideIcons.settings2,
          child: answer('Developer settings live here.'),
        ),
      ],
    );
  },
);

/// A form's "or" between two ways in.
Widget kitSpecimenDividerOr() => const MinimalDivider(label: 'or');
