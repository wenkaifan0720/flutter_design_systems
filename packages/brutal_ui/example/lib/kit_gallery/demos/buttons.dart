import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Buttons: framed, filled with the signal colour, text; icon buttons;
/// each pressed into its shadow, off, and destructive.
Widget kitButtonsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Buttons',
  sections: [
    KitSection(
      title: 'Kinds',
      note:
          'Framed for most things; filled with the signal colour for the one '
          'thing a screen is for; text for the least.',
      children: [
        KitRow(
          children: [
            BrutalButton.filled('Buy tickets', onPressed: () {}),
            BrutalButton('Save', onPressed: () {}),
            BrutalButton.text('Details', onPressed: () {}),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'With a glyph',
      children: [
        KitRow(
          children: [
            BrutalButton.filled(
              'Get tickets',
              onPressed: () {},
              icon: const Icon(LucideIcons.ticket),
            ),
            BrutalButton(
              'Share',
              onPressed: () {},
              icon: const Icon(LucideIcons.share2),
            ),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Destructive',
      children: [
        KitRow(
          children: [
            BrutalButton.filled(
              'Cancel ticket',
              onPressed: () {},
              isDestructiveAction: true,
            ),
            BrutalButton(
              'Remove card',
              onPressed: () {},
              isDestructiveAction: true,
            ),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Off',
      note: 'No shadow, grey rule: nothing to press.',
      children: [
        KitRow(
          children: [
            BrutalButton.filled('Pay', onPressed: null),
            BrutalButton('Save', onPressed: null),
            BrutalButton.text('Details', onPressed: null),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Icon buttons',
      note: 'Square, 48 px. Chosen, it turns over to ink.',
      children: [
        KitRow(
          children: [
            BrutalIconButton(
              onPressed: () {},
              icon: const Icon(LucideIcons.heart),
              tooltip: 'Save event',
            ),
            BrutalIconButton(
              onPressed: () {},
              selected: true,
              icon: const Icon(LucideIcons.heart),
              tooltip: 'Saved',
            ),
            BrutalIconButton.plain(
              onPressed: () {},
              icon: const Icon(LucideIcons.ellipsis),
              tooltip: 'More',
            ),
            const BrutalIconButton(
              onPressed: null,
              icon: Icon(LucideIcons.share2),
              tooltip: 'Share',
            ),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Split button',
      note:
          'The main action and a menu of other ways to do it: two faces, '
          'each with its own shadow and press. The menu half stays pressed '
          'while its menu is open.',
      children: [
        KitRow(
          children: [
            BrutalSplitButton(
              label: 'Buy tickets',
              filled: true,
              onPressed: () {},
              actions: [
                BrutalMenuItem(label: 'Buy as a gift', onPressed: () {}),
                BrutalMenuItem(label: 'Hold for a day', onPressed: () {}),
              ],
            ),
            BrutalSplitButton(
              label: 'Export',
              onPressed: () {},
              actions: [
                BrutalMenuItem(
                  label: 'As a calendar file',
                  icon: LucideIcons.calendar,
                  onPressed: () {},
                ),
                BrutalMenuItem(
                  label: 'As a PDF',
                  icon: LucideIcons.fileText,
                  onPressed: () {},
                ),
                const BrutalMenuItem(label: 'To wallet', onPressed: null),
              ],
            ),
            const BrutalSplitButton(
              label: 'Export',
              onPressed: null,
              actions: [],
            ),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Toolbar',
      note:
          'Cells on shared rules in one raised strip; a pressed cell goes '
          'ink.',
      children: [
        BrutalButtonGroup(
          semanticLabel: 'Ticket',
          items: [
            BrutalButtonGroupItem(
              label: 'Print',
              icon: LucideIcons.printer,
              onPressed: () {},
            ),
            BrutalButtonGroupItem(
              label: 'Share',
              icon: LucideIcons.share2,
              onPressed: () {},
            ),
            const BrutalButtonGroupItem(
              label: 'Transfer',
              icon: LucideIcons.arrowLeftRight,
              onPressed: null,
            ),
          ],
        ),
        BrutalButtonGroup(
          semanticLabel: 'Zoom',
          items: [
            BrutalButtonGroupItem(
              icon: LucideIcons.minus,
              tooltip: 'Zoom out',
              onPressed: () {},
            ),
            BrutalButtonGroupItem(label: '100%', onPressed: () {}),
            BrutalButtonGroupItem(
              icon: LucideIcons.plus,
              tooltip: 'Zoom in',
              onPressed: () {},
            ),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Toggles',
      note:
          'A flat strip whose cells stay ink while they are on: several at '
          'once, or one of a set.',
      children: [_Toggles()],
    ),
    KitSection(
      title: 'Links',
      note: 'Underlined words; a press inverts them.',
      children: [
        KitRow(
          children: [
            BrutalLink('Terms of sale', onPressed: () {}),
            BrutalLink('How refunds work', onPressed: () {}),
            const BrutalLink('Venue map', onPressed: null),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Keys',
      note: 'Keys as small raised caps, for a shortcut beside its command.',
      children: [
        KitRow(
          children: [
            BrutalKbd(['⌘', 'K'], semanticLabel: 'Command K'),
            BrutalKbd(['Ctrl', 'Shift', 'P'], semanticLabel: 'Control Shift P'),
            BrutalKbd(['Esc'], semanticLabel: 'Escape'),
          ],
        ),
      ],
    ),
  ],
);

class _Toggles extends StatefulWidget {
  const _Toggles();

  @override
  State<_Toggles> createState() => _TogglesState();
}

class _TogglesState extends State<_Toggles> {
  Set<String> _style = {'bold'};
  Set<String> _view = {'list'};

  static const _glyphs = {
    'bold': LucideIcons.bold,
    'italic': LucideIcons.italic,
    'underline': LucideIcons.underline,
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      BrutalToggleGroup<String>(
        semanticLabel: 'Text style',
        options: const ['bold', 'italic', 'underline'],
        selected: _style,
        onSelectionChanged: (next) => setState(() => _style = next),
        labelOf: (s) => s,
        iconOf: (s) => _glyphs[s]!,
      ),
      const SizedBox(height: BrutalSpacing.regular),
      BrutalToggleGroup<String>(
        semanticLabel: 'View',
        options: const ['list', 'grid', 'map'],
        selected: _view,
        multiSelectionEnabled: false,
        emptySelectionAllowed: false,
        onSelectionChanged: (next) => setState(() => _view = next),
        labelOf: (s) => '${s[0].toUpperCase()}${s.substring(1)}',
      ),
      const SizedBox(height: BrutalSpacing.regular),
      BrutalToggleGroup<String>(
        semanticLabel: 'View',
        options: const ['list', 'grid', 'map'],
        selected: const {'grid'},
        onSelectionChanged: null,
        labelOf: (s) => '${s[0].toUpperCase()}${s.substring(1)}',
      ),
    ],
  );
}

Widget kitSpecimenButton() => Builder(
  builder: (context) => KitRow(
    children: [
      BrutalButton.filled(
        'Get tickets',
        onPressed: () => kitFeedback(context, 'Two tickets held.'),
        icon: const Icon(LucideIcons.ticket),
      ),
      BrutalButton(
        'Save',
        onPressed: () => kitFeedback(context, 'Saved for later.'),
      ),
      BrutalButton.text(
        'Details',
        onPressed: () => kitFeedback(context, 'The details open here.'),
      ),
    ],
  ),
);

Widget kitSpecimenIconButton() => kitState(
  true,
  (context, saved, change) => KitRow(
    children: [
      BrutalIconButton(
        onPressed: () => change(!saved),
        selected: saved,
        icon: const Icon(LucideIcons.heart),
        tooltip: saved ? 'Saved' : 'Save',
      ),
      BrutalIconButton(
        onPressed: () => kitFeedback(context, 'Link copied.'),
        icon: const Icon(LucideIcons.share2),
        tooltip: 'Share',
      ),
      BrutalIconButton.plain(
        onPressed: () => kitFeedback(context, 'More open here.'),
        icon: const Icon(LucideIcons.ellipsis),
        tooltip: 'More',
      ),
    ],
  ),
);

Widget kitSpecimenSplitButton() => Builder(
  builder: (context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: BrutalSplitButton(
      label: 'Share',
      onPressed: () => kitFeedback(context, 'Link copied.'),
      actions: [
        BrutalMenuItem(
          label: 'Copy link',
          icon: LucideIcons.link,
          onPressed: () => kitFeedback(context, 'Link copied.'),
        ),
        BrutalMenuItem(
          label: 'Send by email',
          icon: LucideIcons.mail,
          onPressed: () => kitFeedback(context, 'Email written.'),
        ),
      ],
    ),
  ),
);

Widget kitSpecimenFloatingButton() => Builder(
  builder: (context) => Padding(
    padding: const EdgeInsets.all(BrutalSpacing.large),
    child: Align(
      alignment: AlignmentDirectional.centerEnd,
      child: BrutalFloatingButton(
        onPressed: () => kitFeedback(context, 'A new event.'),
        icon: const Icon(LucideIcons.plus),
        tooltip: 'New event',
        label: 'New event',
      ),
    ),
  ),
);

Widget kitSpecimenButtonGroup() => Builder(
  builder: (context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: BrutalButtonGroup(
      semanticLabel: 'Seats',
      items: [
        BrutalButtonGroupItem(
          onPressed: () => kitFeedback(context, 'One seat fewer.'),
          label: 'Fewer',
        ),
        BrutalButtonGroupItem(
          onPressed: () => kitFeedback(context, 'Seats held.'),
          label: 'Hold',
        ),
        BrutalButtonGroupItem(
          onPressed: () => kitFeedback(context, 'One seat more.'),
          label: 'More',
        ),
      ],
    ),
  ),
);

Widget kitSpecimenToggleGroup() => kitState<Set<String>>(
  const {'Music'},
  (context, chosen, change) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: BrutalToggleGroup<String>(
      semanticLabel: 'Kinds of night',
      options: const ['Music', 'Talks', 'Film'],
      selected: chosen,
      onSelectionChanged: change,
      labelOf: (s) => s,
    ),
  ),
);

Widget kitSpecimenLink() => Builder(
  builder: (context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: BrutalLink(
      'Refund terms',
      onPressed: () => kitFeedback(context, 'The terms open here.'),
    ),
  ),
);

Widget kitSpecimenKbd() => const Align(
  alignment: AlignmentDirectional.centerStart,
  child: BrutalKbd(['Ctrl', 'K']),
);
