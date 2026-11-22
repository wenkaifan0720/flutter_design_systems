import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Keys: alpha, modifier, accent, a printed legend, square keys, keys with
/// two legends, shortcuts.
Widget kitButtonsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Buttons',
  sections: [
    const _Keys(),
    const _Square(),
    const _Legends(),
    ...kitSpecimens(const [
      'ButtonGroup',
      'ToggleGroup',
      'SplitButton',
      'Link',
      'Kbd',
    ]),
  ],
);

class _Keys extends StatelessWidget {
  const _Keys();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Keys',
    note:
        'A press takes the key down onto its switch; it comes back up '
        'when let go. Light keys are neutral, darker keys secondary, the '
        'one coloured key the screen\'s main action.',
    children: [
      KitRow(
        children: [
          KeycapButton(onPressed: () {}, child: const Text('Cancel')),
          KeycapButton.modifier(
            onPressed: () {},
            child: const Text('Save draft'),
          ),
          KeycapButton.accent(onPressed: () {}, child: const Text('Publish')),
        ],
      ),
      KitRow(
        children: [
          KeycapButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: () {},
            child: const Text('Share'),
          ),
          KeycapButton.text(onPressed: () {}, child: const Text('Details')),
          KeycapButton(
            isDestructiveAction: true,
            onPressed: () {},
            child: const Text('Delete note'),
          ),
          KeycapButton.accent(
            isDestructiveAction: true,
            onPressed: () {},
            child: const Text('Delete'),
          ),
        ],
      ),
      const KitRow(
        children: [
          KeycapButton(onPressed: null, child: Text('Disabled')),
          KeycapButton.modifier(onPressed: null, child: Text('Disabled')),
          KeycapButton.accent(onPressed: null, child: Text('Disabled')),
        ],
      ),
    ],
  );
}

class _Square extends StatefulWidget {
  const _Square();

  @override
  State<_Square> createState() => _SquareState();
}

class _SquareState extends State<_Square> {
  final _on = <String>{'bold'};

  @override
  Widget build(BuildContext context) {
    Widget latch(String id, IconData icon, String label) => KeycapIconButton(
      icon: Icon(icon),
      semanticLabel: label,
      selected: _on.contains(id),
      onPressed: () => setState(() {
        if (!_on.remove(id)) _on.add(id);
      }),
    );
    return KitSection(
      title: 'Square keys',
      note: 'A latching key stays part way down, in the darker plastic.',
      children: [
        KitRow(
          children: [
            KeycapIconButton(
              icon: const Icon(LucideIcons.search),
              semanticLabel: 'Search',
              onPressed: () {},
            ),
            KeycapIconButton(
              icon: const Icon(LucideIcons.plus),
              semanticLabel: 'New note',
              accent: true,
              onPressed: () {},
            ),
            const KeycapIconButton(
              icon: Icon(LucideIcons.trash2),
              semanticLabel: 'Delete',
              onPressed: null,
            ),
          ],
        ),
        Row(
          children: [
            latch('bold', LucideIcons.bold, 'Bold'),
            const SizedBox(width: KeycapMetrics.keyGap),
            latch('italic', LucideIcons.italic, 'Italic'),
            const SizedBox(width: KeycapMetrics.keyGap),
            latch('underline', LucideIcons.underline, 'Underline'),
          ],
        ),
      ],
    );
  }
}

class _Legends extends StatelessWidget {
  const _Legends();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Two legends',
    note:
        'A tall key printed with a name and a count, as a keycap is '
        'printed with a letter and a symbol; a shortcut as its keys.',
    children: [
      Row(
        children: [
          Expanded(
            child: KeycapLegendKey(
              icon: const Icon(LucideIcons.inbox),
              legend: 'Inbox',
              subLegend: '12',
              onPressed: () {},
            ),
          ),
          const SizedBox(width: KeycapMetrics.keyGap * 2),
          Expanded(
            child: KeycapLegendKey(
              icon: const Icon(LucideIcons.briefcase),
              legend: 'Work',
              subLegend: '38',
              modifier: true,
              onPressed: () {},
            ),
          ),
        ],
      ),
      const KitRow(
        children: [
          KeycapShortcut(keys: ['Ctrl', 'N'], semanticLabel: 'Control N'),
          KeycapShortcut(
            keys: ['Ctrl', 'Shift', 'M'],
            semanticLabel: 'Control Shift M',
          ),
        ],
      ),
    ],
  );
}
