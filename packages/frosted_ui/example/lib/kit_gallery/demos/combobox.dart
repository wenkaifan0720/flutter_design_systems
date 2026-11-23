/// [FrostedCombobox]: a field that filters its options as you type, and
/// [FrostedMultiSelect], whose choices stand as chips in the field.
library;

import 'package:material_ui/material_ui.dart';
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

// A long list, its value near the end: the list opens with the chosen row
// in view and keeps the row the keys light in view as they move.
const _countries = [
  'Austria',
  'Belgium',
  'Brazil',
  'Canada',
  'Chile',
  'Croatia',
  'Denmark',
  'Estonia',
  'Finland',
  'France',
  'Germany',
  'Greece',
  'Iceland',
  'India',
  'Ireland',
  'Italy',
  'Japan',
  'Kenya',
  'Mexico',
  'Netherlands',
  'New Zealand',
  'Norway',
  'Poland',
  'Portugal',
  'Singapore',
  'Spain',
  'Sweden',
  'Switzerland',
  'United Kingdom',
  'Uruguay',
];

// Reviewers are people, not tags.
const _people = ['Jonah Reyes', 'Priya Anand', 'Ines Park', 'Theo Lund'];

Widget kitComboboxDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  measured: true,
  title: 'Combobox',
  sections: [
    kitSection(
      'Combobox',
      children: [
        KitHeld<String?>(
          'Lisbon',
          (city, set) => FrostedCombobox<String>(
            labelText: 'City',
            options: _cities,
            value: city,
            onSelected: set,
            hintText: 'Search cities',
          ),
        ),
        const FrostedCombobox<String>(
          labelText: 'City',
          options: _cities,
          requireSelection: true,
          hintText: 'Search cities',
          helperText: 'Only a listed city',
        ),
        const FrostedCombobox<String>(
          labelText: 'City',
          options: _cities,
          hintText: 'Try Atlantis',
          helperText: 'Words no city fits say so in the list',
        ),
        const FrostedCombobox<String>(
          labelText: 'City',
          options: _cities,
          hintText: 'Search cities',
          errorText: 'Choose a city',
        ),
      ],
    ),
    kitSection(
      'Multi-select',
      children: [
        KitHeld<List<String>>(
          const ['Design', 'Review'],
          (chosen, set) => FrostedMultiSelect<String>(
            labelText: 'Tags',
            options: _tags,
            values: chosen,
            onChanged: set,
            onCreate: (text) => text.trim().isEmpty ? null : text.trim(),
            hintText: 'Add a tag',
          ),
        ),
        KitHeld<List<String>>(
          const ['Jonah Reyes'],
          (chosen, set) => FrostedMultiSelect<String>(
            labelText: 'Reviewers',
            options: _people,
            values: chosen,
            onChanged: set,
            maxTags: 2,
            helperText: 'Up to two',
          ),
        ),
      ],
    ),
    kitSection(
      'A long list',
      children: [
        KitHeld<String?>(
          'Switzerland',
          (country, set) => FrostedCombobox<String>(
            labelText: 'Country',
            options: _countries,
            value: country,
            onSelected: set,
            hintText: 'Search countries',
          ),
        ),
      ],
    ),
  ],
);

/// A country, typed or chosen.
Widget kitSpecimenCombobox() => FrostedCombobox<String>(
  labelText: 'Country',
  options: const ['Portugal', 'Spain', 'France'],
  value: 'Portugal',
  onSelected: (_) {},
);

/// Two tags chosen of three.
Widget kitSpecimenMultiSelect() => FrostedMultiSelect<String>(
  labelText: 'Tags',
  options: const ['Travel', 'Food', 'Home'],
  values: const ['Travel', 'Food'],
  onChanged: (_) {},
);
