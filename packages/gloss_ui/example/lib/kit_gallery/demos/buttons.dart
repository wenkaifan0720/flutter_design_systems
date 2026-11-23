/// Gloss's keys: gel, pearl, letterpressed words, and beads.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The buttons page.
Widget kitButtonsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Buttons',
  sections: [
    KitSection(
      title: 'Keys',
      note: 'One gel key per screen; pearl for the rest.',
      children: [
        KitRow(
          children: [
            GlossButton.filled('Plan the week', onPressed: () {}),
            GlossButton('Shopping list', onPressed: () {}),
            GlossButton.text('Skip', onPressed: () {}),
          ],
        ),
        KitRow(
          children: [
            GlossButton.filled(
              'Add to plan',
              icon: const Icon(LucideIcons.plus),
              onPressed: () {},
            ),
            GlossButton(
              'Share',
              icon: const Icon(LucideIcons.share2),
              onPressed: () {},
            ),
            GlossButton.text(
              'Print',
              icon: const Icon(LucideIcons.printer),
              onPressed: () {},
            ),
          ],
        ),
        const KitRow(
          children: [
            GlossButton.filled('Send the list', onPressed: null),
            GlossButton('Share', onPressed: null),
            GlossButton.text('Undo', onPressed: null),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Destructive',
      children: [
        KitRow(
          children: [
            GlossButton.filled(
              'Delete plan',
              isDestructiveAction: true,
              onPressed: () {},
            ),
            GlossButton('Remove', isDestructiveAction: true, onPressed: () {}),
            GlossButton.text(
              'Sign out',
              isDestructiveAction: true,
              onPressed: () {},
            ),
          ],
        ),
      ],
    ),
    const KitSection(title: 'Beads', children: [_Beads()]),
    const KitSection(
      title: 'Groups, toggles and the split key',
      children: [_Groups()],
    ),
  ],
);

class _Beads extends StatefulWidget {
  const _Beads();

  @override
  State<_Beads> createState() => _BeadsState();
}

class _BeadsState extends State<_Beads> {
  bool _saved = true;

  @override
  Widget build(BuildContext context) => KitRow(
    children: [
      GlossIconButton(
        onPressed: () => setState(() => _saved = !_saved),
        isSelected: _saved,
        tooltip: 'Save',
        icon: const Icon(LucideIcons.heart),
      ),
      GlossIconButton(
        onPressed: () {},
        tooltip: 'Timer',
        icon: const Icon(LucideIcons.timer),
      ),
      GlossIconButton.filled(
        onPressed: () {},
        tooltip: 'Add',
        icon: const Icon(LucideIcons.plus),
      ),
      GlossIconButton.plain(
        onPressed: () {},
        tooltip: 'Search',
        icon: const Icon(LucideIcons.search),
      ),
      const GlossIconButton(
        onPressed: null,
        tooltip: 'Reminders',
        icon: Icon(LucideIcons.bell),
      ),
    ],
  );
}

class _Groups extends StatefulWidget {
  const _Groups();

  @override
  State<_Groups> createState() => _GroupsState();
}

class _GroupsState extends State<_Groups> {
  Set<String> _diet = {'veg'};
  String _said = '';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GlossButtonGroup(
        items: [
          GlossButtonGroupItem(
            label: 'Halve',
            onPressed: () => setState(() => _said = 'Halved'),
          ),
          GlossButtonGroupItem(
            label: 'Double',
            onPressed: () => setState(() => _said = 'Doubled'),
          ),
          GlossButtonGroupItem(
            label: 'Reset',
            onPressed: () => setState(() => _said = ''),
          ),
        ],
      ),
      const SizedBox(height: GlossSpacing.regular),
      GlossToggleGroup<String>(
        semanticLabel: 'Diet',
        toggles: const [
          GlossToggle(value: 'veg', label: 'Vegan'),
          GlossToggle(value: 'gf', label: 'Gluten-free'),
          GlossToggle(value: 'df', label: 'Dairy-free'),
        ],
        selected: _diet,
        onSelectionChanged: (next) => setState(() => _diet = next),
      ),
      const SizedBox(height: GlossSpacing.regular),
      Wrap(
        spacing: GlossSpacing.medium,
        runSpacing: GlossSpacing.medium,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          GlossSplitButton.filled(
            label: 'Add to plan',
            onPressed: () => setState(() => _said = 'Added to tonight'),
            actions: [
              GlossSplitAction(
                label: 'Add to Friday',
                onPressed: () => setState(() => _said = 'Added to Friday'),
              ),
              GlossSplitAction(
                label: 'Add to the weekend',
                onPressed: () => setState(() => _said = 'Added to Saturday'),
              ),
            ],
          ),
          GlossSplitButton(
            label: 'Share',
            onPressed: () {},
            actions: [GlossSplitAction(label: 'Copy link', onPressed: () {})],
          ),
          GlossLink('Read the method', onPressed: () {}),
          const GlossKbd('Ctrl K'),
        ],
      ),
      if (_said.isNotEmpty) ...[
        const SizedBox(height: GlossSpacing.small),
        Text(_said, style: GlossTheme.of(context).textTheme.secondary),
      ],
    ],
  );
}
