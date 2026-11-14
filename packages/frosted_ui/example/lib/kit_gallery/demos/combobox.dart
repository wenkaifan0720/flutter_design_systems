/// [FrostedCombobox]: a field that filters its options as you type, and
/// [FrostedMultiSelect], whose choices stand as chips in the field.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

const _cities = [
  'Amsterdam',
  'Berlin',
  'Copenhagen',
  'Dublin',
  'Helsinki',
  'Lisbon',
  'Madrid',
  'Oslo',
  'Paris',
  'Prague',
  'Rome',
  'Vienna',
];

const _tags = ['Design', 'Research', 'Writing', 'Engineering', 'Review'];

// Reviewers are people (a "Design" tag stood in for one, self-review round
// 5).
const _people = ['Jonah Reyes', 'Priya Anand', 'Ines Park', 'Theo Lund'];

Widget kitComboboxDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Combobox',
  sections: [
    kitSection(
      'Combobox',
      children: [
        KitHeld<String?>(
          'Lisbon',
          (city, set) => FrostedCombobox<String>(
            label: 'City',
            options: _cities,
            value: city,
            onSelected: set,
            hint: 'Search cities',
          ),
        ),
        const FrostedCombobox<String>(
          label: 'City',
          options: _cities,
          requireSelection: true,
          hint: 'Search cities',
          helper: 'Only a listed city',
        ),
        const FrostedCombobox<String>(
          label: 'City',
          options: _cities,
          hint: 'Try Atlantis',
          helper: 'Words no city fits say so in the list',
        ),
        const FrostedCombobox<String>(
          label: 'City',
          options: _cities,
          hint: 'Search cities',
          error: 'Choose a city',
        ),
      ],
    ),
    kitSection(
      'Multi-select',
      children: [
        KitHeld<List<String>>(
          const ['Design', 'Review'],
          (chosen, set) => FrostedMultiSelect<String>(
            label: 'Tags',
            options: _tags,
            values: chosen,
            onChanged: set,
            onCreate: (text) => text.trim().isEmpty ? null : text.trim(),
            hint: 'Add a tag',
          ),
        ),
        KitHeld<List<String>>(
          const ['Jonah Reyes'],
          (chosen, set) => FrostedMultiSelect<String>(
            label: 'Reviewers',
            options: _people,
            values: chosen,
            onChanged: set,
            maxTags: 2,
            helper: 'Up to two',
          ),
        ),
      ],
    ),
  ],
);

/// A country, typed or chosen.
Widget kitSpecimenCombobox() => FrostedCombobox<String>(
  label: 'Country',
  options: const ['Portugal', 'Spain', 'France'],
  value: 'Portugal',
  onSelected: (_) {},
);

/// Two tags chosen of three.
Widget kitSpecimenMultiSelect() => FrostedMultiSelect<String>(
  label: 'Tags',
  options: const ['Travel', 'Food', 'Home'],
  values: const ['Travel', 'Food'],
  onChanged: (_) {},
);
