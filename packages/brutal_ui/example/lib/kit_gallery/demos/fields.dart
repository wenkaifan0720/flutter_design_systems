import 'package:flutter/material.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Fields and selects: empty, filled, with help, wrong, off; a select shut
/// and open.
Widget kitFieldsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Fields and selects',
  sections: const [
    KitSection(
      title: 'Text fields',
      note:
          'A square box in the rule, its label above. Focused, a second '
          'square line stands 2 px outside it.',
      children: [
        BrutalTextField(label: 'Name on ticket', hint: 'As on your ID'),
        BrutalTextField(
          label: 'Email',
          hint: 'you@example.com',
          helper: 'We send the tickets here.',
          keyboardType: TextInputType.emailAddress,
        ),
        BrutalTextField(
          label: 'Search',
          hint: 'Artists, venues',
          prefixIcon: Icon(LucideIcons.search),
        ),
        BrutalTextField(
          label: 'Card number',
          hint: '1234 5678 9012 3456',
          error: 'That card number is one digit short.',
        ),
        BrutalTextField(label: 'Promo code', hint: 'None', enabled: false),
      ],
    ),
    KitSection(
      title: 'Text area',
      note: 'The same box, several lines tall; it grows to its limit.',
      children: [
        BrutalTextField(
          label: 'Note to the venue',
          hint: 'Access needs, a late arrival',
          maxLines: 6,
          minLines: 3,
        ),
      ],
    ),
    KitSection(
      title: 'Search, password, add-ons',
      note:
          'A search box clears itself; a password shows itself; add-ons '
          'stand in cells of their own on the box\'s rules.',
      children: [
        BrutalSearchField(hint: 'Events, venues, who is on'),
        BrutalPasswordField(
          label: 'Password',
          helper: 'At least 12 characters.',
        ),
        BrutalInputGroup(
          label: 'Your page',
          before: 'https://',
          after: '.admit.events',
          hint: 'your-night',
        ),
        BrutalInputGroup(
          label: 'Donation',
          before: '€',
          hint: '5.00',
          keyboardType: TextInputType.number,
          error: 'Give at least €1.',
        ),
      ],
    ),
    KitSection(
      title: 'One-time code',
      note:
          'A strip of cells over one real input: paste and a texted code '
          'fill it whole. The caret\'s cell carries a heavy bar.',
      children: [
        BrutalCodeField(
          label: 'Code from your bank',
          helper: 'Six figures, sent by text.',
        ),
        BrutalCodeField(
          label: 'Door code',
          length: 4,
          error: 'That code has been used.',
        ),
      ],
    ),
    KitSection(
      title: 'Suggesting fields',
      note:
          'A combobox narrows a list as you type; tags gather several '
          'values in one box.',
      children: [_Suggesting()],
    ),
    KitSection(
      title: 'Any control with a label',
      note: 'A label over it, help or an error under it.',
      children: [_Labelled()],
    ),
    KitSection(
      title: 'Selects',
      note:
          'Shaped like a field; the chevron in a cell of its own. The list '
          'hangs from the box on a shared rule.',
      children: [_Selects()],
    ),
  ],
);

class _Selects extends StatefulWidget {
  const _Selects();

  @override
  State<_Selects> createState() => _SelectsState();
}

class _SelectsState extends State<_Selects> {
  String? _city = 'harbour';
  String? _when;

  static const _cities = [
    BrutalSelectItem(value: 'north', label: 'North quarter'),
    BrutalSelectItem(value: 'harbour', label: 'Harbour'),
    BrutalSelectItem(value: 'old-town', label: 'Old town'),
    BrutalSelectItem(value: 'riverside', label: 'Riverside'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      BrutalSelect<String>(
        label: 'City',
        items: _cities,
        value: _city,
        onChanged: (v) => setState(() => _city = v),
      ),
      const SizedBox(height: BrutalSpacing.regular),
      BrutalSelect<String>(
        label: 'When',
        hint: 'Any day',
        items: const [
          BrutalSelectItem(value: 'tonight', label: 'Tonight'),
          BrutalSelectItem(value: 'weekend', label: 'This weekend'),
          BrutalSelectItem(value: 'month', label: 'This month'),
        ],
        value: _when,
        error: _when == null ? 'Pick a day to see times.' : null,
        onChanged: (v) => setState(() => _when = v),
      ),
      const SizedBox(height: BrutalSpacing.regular),
      const BrutalSelect<String>(
        label: 'Seat',
        hint: 'Standing only',
        items: [],
        value: null,
        onChanged: null,
      ),
    ],
  );
}

const _venues = [
  'Gallery Nine',
  'Library Hall',
  'Kino 2',
  'The Cellar',
  'Hall 4',
  'Basement 3',
  "St Anne's",
];

class _Suggesting extends StatefulWidget {
  const _Suggesting();

  @override
  State<_Suggesting> createState() => _SuggestingState();
}

class _SuggestingState extends State<_Suggesting> {
  String? _venue = 'Kino 2';
  List<String> _kinds = ['Film', 'Talks'];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      BrutalCombobox<String>(
        label: 'Venue',
        hint: 'Type a venue',
        options: _venues,
        labelOf: (v) => v,
        value: _venue,
        onSelected: (v) => setState(() => _venue = v),
      ),
      const SizedBox(height: BrutalSpacing.regular),
      BrutalTagInput<String>(
        label: 'Kinds of night',
        hint: 'Add a kind',
        values: _kinds,
        options: const ['Film', 'Music', 'Talks', 'Art', 'Late', 'Family'],
        labelOf: (k) => k,
        onChanged: (next) => setState(() => _kinds = next),
      ),
    ],
  );
}

class _Labelled extends StatefulWidget {
  const _Labelled();

  @override
  State<_Labelled> createState() => _LabelledState();
}

class _LabelledState extends State<_Labelled> {
  String _seat = 'standing';

  @override
  Widget build(BuildContext context) => BrutalFormField(
    labelText: 'Where you stand',
    helperText: 'Standing has no seat number.',
    required: true,
    mergeSemantics: false,
    child: BrutalSegmentedButton<String>(
      segments: const [
        BrutalSegment(value: 'standing', label: 'Standing'),
        BrutalSegment(value: 'balcony', label: 'Balcony'),
      ],
      value: _seat,
      onChanged: (v) => setState(() => _seat = v),
    ),
  );
}

// Catalog specimens (metadata.yaml): one still per part, drawn the same in
// every preset; the stage chooses the preset.

Widget kitSpecimenTextField() => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    BrutalTextField(label: 'Name on the ticket', hint: 'As on your ID'),
    SizedBox(height: BrutalSpacing.regular),
    BrutalTextField(
      label: 'Email',
      helper: 'Your tickets go here.',
      error: 'An email address has an @ in it.',
    ),
  ],
);

Widget kitSpecimenSearchField() =>
    const BrutalSearchField(hint: 'Events, venues, people');

Widget kitSpecimenPasswordField() => const BrutalPasswordField(
  label: 'Password',
  helper: 'Twelve characters or more.',
);

Widget kitSpecimenInputGroup() => const BrutalInputGroup(
  label: 'Price',
  before: '£',
  after: 'each',
  keyboardType: TextInputType.number,
);

Widget kitSpecimenCodeField() =>
    const BrutalCodeField(label: 'The code we sent you');

Widget kitSpecimenCombobox() => BrutalCombobox<String>(
  label: 'Venue',
  hint: 'Type a venue',
  options: const ['The Shed', 'Dock 4', 'Cellar', 'Glasshouse'],
  labelOf: (s) => s,
);

Widget kitSpecimenTagInput() => kitState<List<String>>(
  const ['Jazz', 'Folk'],
  (context, values, change) => BrutalTagInput<String>(
    label: 'Genres',
    values: values,
    onChanged: change,
    options: const ['Jazz', 'Folk', 'Techno', 'Soul'],
    labelOf: (s) => s,
  ),
);

Widget kitSpecimenFormField() => kitState(
  true,
  (context, on, change) => BrutalFormField(
    labelText: 'Reminders',
    helperText: 'A day before the doors open.',
    child: BrutalSwitch(value: on, onChanged: change),
  ),
);

Widget kitSpecimenSelect() => kitState(
  'shed',
  (context, venue, change) => BrutalSelect<String>(
    label: 'Venue',
    value: venue,
    onChanged: change,
    items: const [
      BrutalSelectItem(value: 'shed', label: 'The Shed'),
      BrutalSelectItem(value: 'dock', label: 'Dock 4'),
      BrutalSelectItem(value: 'cellar', label: 'Cellar'),
    ],
  ),
);
