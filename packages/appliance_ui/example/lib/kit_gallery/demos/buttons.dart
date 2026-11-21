import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Keys: the ordinary key, the signal key, the printed legend, square keys.
Widget kitButtonsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Buttons',
  sections: const [_Keys(), _MoreKeys()],
);

class _Keys extends StatefulWidget {
  const _Keys();

  @override
  State<_Keys> createState() => _KeysState();
}

class _KeysState extends State<_Keys> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitSection(
        title: 'Keys',
        note: 'A press sinks the key; it springs back when let go.',
        children: [
          KitRow(
            children: [
              ApplianceButton.filled('Add to basket', onPressed: () {}),
              ApplianceButton('Save for later', onPressed: () {}),
              ApplianceButton.text('Details', onPressed: () {}),
            ],
          ),
          KitRow(
            children: [
              ApplianceButton(
                'Search',
                icon: const Icon(LucideIcons.search),
                onPressed: () {},
              ),
              ApplianceButton.filled(
                'Remove',
                isDestructiveAction: true,
                onPressed: () {},
              ),
              const ApplianceButton('Disabled', onPressed: null),
              const ApplianceButton.filled('Disabled', onPressed: null),
            ],
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Square keys',
        note: 'A toggle key latches down and lights its lamp.',
        children: [
          KitRow(
            children: [
              ApplianceIconButton(
                icon: const Icon(LucideIcons.search),
                semanticLabel: 'Search',
                onPressed: () {},
              ),
              ApplianceIconButton(
                icon: const Icon(LucideIcons.heart),
                semanticLabel: 'Save',
                selected: _saved,
                onPressed: () => setState(() => _saved = !_saved),
              ),
              const ApplianceIconButton(
                icon: Icon(LucideIcons.trash2),
                semanticLabel: 'Remove',
                onPressed: null,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// The other keys: a strip of keys, latching keys, a split key, links, key
/// caps.
class _MoreKeys extends StatefulWidget {
  const _MoreKeys();

  @override
  State<_MoreKeys> createState() => _MoreKeysState();
}

class _MoreKeysState extends State<_MoreKeys> {
  Set<String> _programme = {'eco'};
  Set<String> _marks = {'bold'};

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitSection(
        title: 'Key strips',
        note: 'Keys moulded into one strip; latching keys stay down, lamp lit.',
        children: [
          ApplianceToolbar(
            semanticLabel: 'Text',
            children: [
              ApplianceIconButton(
                icon: const Icon(LucideIcons.bold),
                semanticLabel: 'Bold',
                onPressed: () {},
              ),
              ApplianceIconButton(
                icon: const Icon(LucideIcons.italic),
                semanticLabel: 'Italic',
                onPressed: () {},
              ),
              ApplianceIconButton(
                icon: const Icon(LucideIcons.link),
                semanticLabel: 'Link',
                onPressed: () {},
              ),
            ],
          ),
          ApplianceToggleGroup<String>(
            semanticLabel: 'Programme',
            options: const [
              ApplianceToggleOption(value: 'eco', label: 'Eco'),
              ApplianceToggleOption(value: 'quick', label: 'Quick'),
              ApplianceToggleOption(value: 'deep', label: 'Deep'),
              ApplianceToggleOption(
                value: 'steam',
                label: 'Steam',
                enabled: false,
              ),
            ],
            selected: _programme,
            onSelectionChanged: (v) => setState(() => _programme = v),
          ),
          ApplianceToggleGroup<String>(
            semanticLabel: 'Marks',
            multiSelectionEnabled: true,
            emptySelectionAllowed: true,
            options: const [
              ApplianceToggleOption(
                value: 'bold',
                label: 'Bold',
                icon: Icon(LucideIcons.bold),
                showLabel: false,
              ),
              ApplianceToggleOption(
                value: 'italic',
                label: 'Italic',
                icon: Icon(LucideIcons.italic),
                showLabel: false,
              ),
              ApplianceToggleOption(
                value: 'underline',
                label: 'Underline',
                icon: Icon(LucideIcons.underline),
                showLabel: false,
              ),
            ],
            selected: _marks,
            onSelectionChanged: (v) => setState(() => _marks = v),
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Split keys, links and key caps',
        note: 'The split key\'s second half opens more ways to do it.',
        children: [
          KitRow(
            children: [
              ApplianceSplitButton(
                label: 'Save',
                onPressed: () {},
                menuLabel: 'More ways to save',
                actions: [
                  RawSplitAction(label: 'Save a copy', onPressed: () {}),
                  RawSplitAction(label: 'Save as a template', onPressed: () {}),
                ],
              ),
              ApplianceSplitButton(
                label: 'Order',
                filled: true,
                onPressed: () {},
                menuLabel: 'More ways to order',
                actions: [
                  RawSplitAction(label: 'Order every month', onPressed: () {}),
                ],
              ),
            ],
          ),
          KitRow(
            children: [
              ApplianceLink('Delivery and returns', onPressed: () {}),
              const ApplianceLink('Gift cards (closed)', onPressed: null),
            ],
          ),
          KitRow(
            children: [
              ApplianceKbd.shortcut(kitShortcut(LogicalKeyboardKey.keyK)),
              const ApplianceKbd('Esc'),
            ],
          ),
        ],
      ),
    ],
  );
}
