/// A field that suggests as you type, and one that gathers several values
/// as tags, live.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

const List<String> _people = [
  'Ana Souza',
  'Ben Okafor',
  'Chen Wei',
  'Dara Kelly',
  'Eli Navarro',
  'Farah Haddad',
  'Gus Lindqvist',
];

const List<String> _labels = [
  'bug',
  'design',
  'docs',
  'infra',
  'mobile',
  'performance',
  'web',
];

Widget kitComboboxDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Combobox & multi-select',
  sections: [
    kitSection(
      'Combobox',
      children: [
        const _Assignee(),
        kitNote(
          'Type to narrow; ↑ ↓ move, ↵ picks, Esc closes. A name nobody '
          'has says “No results” in the list.',
        ),
      ],
    ),
    kitSection('Multi-select', children: const [_Labels()]),
    kitSection(
      'States',
      children: [
        // The pick the error turns down: the issue's own author.
        MinimalCombobox<String>(
          label: 'Reviewer',
          options: _people,
          displayString: (p) => p,
          value: _people[1],
          error: 'Ben Okafor wrote this; pick another reviewer.',
          onSelected: (_) {},
        ),
        MinimalCombobox<String>(
          label: 'Owner',
          options: _people,
          displayString: (p) => p,
          value: _people.first,
          enabled: false,
        ),
      ],
    ),
  ],
);

class _Assignee extends StatefulWidget {
  const _Assignee();

  @override
  State<_Assignee> createState() => _AssigneeState();
}

class _AssigneeState extends State<_Assignee> {
  String? _who;

  @override
  Widget build(BuildContext context) => MinimalCombobox<String>(
    label: 'Assignee',
    hint: 'Search people',
    icon: LucideIcons.user,
    options: _people,
    displayString: (p) => p,
    value: _who,
    onSelected: (p) => setState(() => _who = p),
  );
}

class _Labels extends StatefulWidget {
  const _Labels();

  @override
  State<_Labels> createState() => _LabelsState();
}

class _LabelsState extends State<_Labels> {
  List<String> _on = ['design', 'web'];

  @override
  Widget build(BuildContext context) => MinimalMultiSelect<String>(
    label: 'Labels',
    hint: 'Add a label',
    helper: 'Backspace removes the last; a new word makes a new label.',
    options: _labels,
    displayString: (l) => l,
    values: _on,
    onCreate: (text) => text.trim().isEmpty ? null : text.trim(),
    onChanged: (v) => setState(() => _on = v),
  );
}

// --- catalog specimens -------------------------------------------------------

/// A suggesting field, filled.
Widget kitSpecimenCombobox() => Padding(
  padding: const EdgeInsets.all(MinimalSpacing.s16),
  child: MinimalCombobox<String>(
    label: 'Assignee',
    icon: LucideIcons.user,
    options: _people,
    displayString: (p) => p,
    value: _people[2],
    onSelected: (_) {},
  ),
);

/// Several values gathered as tags.
Widget kitSpecimenMultiSelect() => Padding(
  padding: const EdgeInsets.all(MinimalSpacing.s16),
  child: MinimalMultiSelect<String>(
    label: 'Labels',
    options: _labels,
    displayString: (l) => l,
    values: const ['design', 'web', 'mobile'],
    onChanged: (_) {},
  ),
);
