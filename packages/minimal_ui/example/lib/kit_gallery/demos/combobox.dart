/// A field that suggests as you type, and one that gathers several values
/// as tags, live.
library;

import 'package:material_ui/material_ui.dart';
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

// Longer than the list's height: it opens scrolled to the value.
const List<String> _zones = [
  'Honolulu',
  'Anchorage',
  'Los Angeles',
  'Denver',
  'Chicago',
  'New York',
  'São Paulo',
  'London',
  'Lisbon',
  'Berlin',
  'Stockholm',
  'Athens',
  'Istanbul',
  'Dubai',
  'Mumbai',
  'Singapore',
  'Tokyo',
  'Sydney',
  'Auckland',
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
    kitSection(
      'A long list',
      children: [
        const _Zone(),
        kitNote(
          'It opens on its value, near the end, and the keys keep '
          'the highlighted row in view.',
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

class _Zone extends StatefulWidget {
  const _Zone();

  @override
  State<_Zone> createState() => _ZoneState();
}

class _ZoneState extends State<_Zone> {
  String _zone = 'Tokyo';

  @override
  Widget build(BuildContext context) => MinimalCombobox<String>(
    label: 'Time zone',
    icon: LucideIcons.globe,
    options: _zones,
    displayString: (z) => z,
    value: _zone,
    onSelected: (z) => setState(() => _zone = z),
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
