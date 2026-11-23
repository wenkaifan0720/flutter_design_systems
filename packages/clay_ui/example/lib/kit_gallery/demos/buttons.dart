/// Clay's keys: the coral key, white clay keys, words alone, balls, groups,
/// toggles, split keys, links and key caps.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The buttons page.
Widget kitButtonsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Buttons',
  sections: [
    KitSection(
      title: 'Keys',
      note:
          'One coral key per screen; white clay for the rest; words alone '
          'for the least.',
      children: [
        KitRow(
          children: [
            ClayButton.filled('Add habit', onPressed: () {}),
            ClayButton('Log water', onPressed: () {}),
            ClayButton.text('Skip today', onPressed: () {}),
          ],
        ),
        KitRow(
          children: [
            ClayButton.filled(
              'New habit',
              icon: const Icon(LucideIcons.plus),
              onPressed: () {},
            ),
            ClayButton(
              'Share week',
              icon: const Icon(LucideIcons.share2),
              onPressed: () {},
            ),
            ClayButton.text(
              'Export',
              icon: const Icon(LucideIcons.download),
              onPressed: () {},
            ),
          ],
        ),
        const KitRow(
          children: [
            ClayButton.filled('Save habit', onPressed: null),
            ClayButton('Pause', onPressed: null),
            ClayButton.text('Undo', onPressed: null),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Destructive',
      children: [
        KitRow(
          children: [
            ClayButton.filled(
              'Delete habit',
              isDestructiveAction: true,
              onPressed: () {},
            ),
            ClayButton(
              'Reset streak',
              isDestructiveAction: true,
              onPressed: () {},
            ),
            ClayButton.text(
              'Sign out',
              isDestructiveAction: true,
              onPressed: () {},
            ),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Balls',
      note:
          'A glyph on a round ball of clay; a toggle held on warms toward '
          'the accent; a bare glyph on a bar.',
      children: [
        KitRow(
          children: [
            ClayIconButton(
              onPressed: () {},
              icon: const Icon(LucideIcons.pencil),
              tooltip: 'Edit',
            ),
            ClayIconButton.filled(
              onPressed: () {},
              icon: const Icon(LucideIcons.plus),
              tooltip: 'Add habit',
            ),
            const _Toggle(),
            ClayIconButton.plain(
              onPressed: () {},
              icon: const Icon(LucideIcons.search),
              tooltip: 'Search',
            ),
            const ClayIconButton(
              onPressed: null,
              icon: Icon(LucideIcons.trash2),
              tooltip: 'Delete',
            ),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'A key face on its own',
      note: 'The face a dialog draws its keys with.',
      children: [
        const KitRow(
          children: [
            ClayButtonFace(
              label: 'Pressed',
              states: {WidgetState.pressed},
              kind: ClayButtonKind.filled,
            ),
            ClayButtonFace(label: 'Focused', states: {WidgetState.focused}),
          ],
        ),
        ClayPressDepth(
          pressed: false,
          builder: (depth) => const SizedBox.shrink(),
        ),
      ],
    ),
    const KitSection(
      title: 'Groups, toggles and split keys',
      note:
          'Keys sharing one slab, a groove between them; toggles held on '
          'rise in the groove; a key with its other ways behind a ball.',
      children: [_Groups()],
    ),
    const KitSection(
      title: 'Links and keys on the keyboard',
      note: 'Words in coral ink, underlined under focus; a key cap in clay.',
      children: [_Links()],
    ),
  ],
);

class _Toggle extends StatefulWidget {
  const _Toggle();

  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool _on = true;

  @override
  Widget build(BuildContext context) => ClayIconButton(
    onPressed: () => setState(() => _on = !_on),
    isSelected: _on,
    icon: const Icon(LucideIcons.bell),
    tooltip: 'Reminders',
  );
}

class _Groups extends StatelessWidget {
  const _Groups();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClayButtonGroup(
        items: [
          ClayButtonGroupItem(
            label: 'Skip',
            icon: LucideIcons.skipForward,
            onPressed: () {},
          ),
          ClayButtonGroupItem(
            label: 'Snooze',
            icon: LucideIcons.alarmClock,
            onPressed: () {},
          ),
          ClayButtonGroupItem(
            label: 'Note',
            icon: LucideIcons.notebookPen,
            onPressed: () {},
          ),
        ],
      ),
      const SizedBox(height: ClaySpacing.regular),
      KitLive<Set<String>>(
        const {'morning'},
        (context, on, set) => ClayToggleGroup<String>(
          toggles: const [
            ClayToggle(value: 'morning', label: 'Morning'),
            ClayToggle(value: 'afternoon', label: 'Afternoon'),
            ClayToggle(value: 'evening', label: 'Evening'),
          ],
          selected: on,
          onSelectionChanged: set,
        ),
      ),
      const SizedBox(height: ClaySpacing.regular),
      ClaySplitButton(
        label: 'Log it',
        onPressed: () => showClayToast(context, 'Logged for today'),
        actions: [
          ClaySplitAction(
            label: 'Log for yesterday',
            onPressed: () => showClayToast(context, 'Logged for yesterday'),
          ),
          ClaySplitAction(label: 'Log twice', onPressed: () {}),
        ],
      ),
    ],
  );
}

class _Links extends StatelessWidget {
  const _Links();

  @override
  Widget build(BuildContext context) => KitRow(
    children: [
      ClayLink('See all habits', onPressed: () {}),
      const ClayLink('Archived', onPressed: null),
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [ClayKbd('Ctrl'), SizedBox(width: 4), ClayKbd('K')],
      ),
    ],
  );
}
