import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Wells: groups of rows, cards.
Widget kitListsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Lists and cards',
  sections: [
    const _Groups(),
    const _Cards(),
    ...kitSpecimens(const [
      'Disclosure',
      'Table',
      'DataTable',
      'ScrollArea',
      'Resizable',
      'CarouselView',
      'ReorderableListView',
      'SwipeActions',
      'RefreshIndicator',
      'TreeView',
      'Timeline',
    ]),
  ],
);

class _Groups extends StatefulWidget {
  const _Groups();

  @override
  State<_Groups> createState() => _GroupsState();
}

class _GroupsState extends State<_Groups> {
  bool _pin = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KeycapListGroup(
        header: 'Recent',
        footer: 'Notes you edited in the last week.',
        children: [
          KeycapListTile(
            title: 'Talk for the allotment society',
            subtitle: 'Start with the frost of 3 November',
            trailingText: '10 min',
            showChevron: false,
            onTap: () {},
          ),
          KeycapListTile(
            title: 'Monday stand-up',
            subtitle: 'Search results ship behind the flag',
            trailingText: '09:40',
            selected: true,
            showChevron: false,
            onTap: () {},
          ),
          KeycapListTile(
            leading: const Icon(LucideIcons.folder),
            title: 'Garden',
            trailingText: '2',
            onTap: () {},
          ),
          KeycapListTile(
            leading: const Icon(LucideIcons.fileType),
            title: 'Export as',
            value: 'Markdown',
            onTap: () {},
          ),
          KeycapSwitchListTile(
            leading: const Icon(LucideIcons.pin),
            title: 'Pin to Home',
            value: _pin,
            onChanged: (v) => setState(() => _pin = v),
          ),
          KeycapListTile(
            leading: const Icon(LucideIcons.trash2),
            title: 'Empty Recently deleted',
            isDestructiveAction: true,
            showChevron: false,
            onTap: () {},
          ),
          const KeycapListTile(
            title: 'Disabled',
            subtitle: 'Not now',
            enabled: false,
          ),
        ],
      ),
    ],
  );
}

class _Cards extends StatelessWidget {
  const _Cards();

  @override
  Widget build(BuildContext context) {
    final t = context.keycapTheme.textTheme;
    return KitSection(
      title: 'Cards',
      note:
          'A card is a well too: what is raised is pressed, what is sunk '
          'is read.',
      well: false,
      children: [
        KeycapCard(
          onTap: () {},
          semanticLabel: 'Roast squash soup',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Roast squash soup', style: t.heading),
              const SizedBox(height: KeycapSpacing.tight),
              Text(
                'One squash, two onions, a thumb of ginger.',
                style: t.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
