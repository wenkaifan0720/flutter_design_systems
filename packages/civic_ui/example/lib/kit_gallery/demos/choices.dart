// Choices: radios with hints, checkboxes under a question, a select for a
// long list, and switches for settings that act at once.
import 'package:flutter/material.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitChoicesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Radios, checkboxes, select & switch',
  sections: const [_Radios(), _Checks(), _Select(), _Combobox(), _Switches()],
);

class _Radios extends StatefulWidget {
  const _Radios();

  @override
  State<_Radios> createState() => _RadiosState();
}

class _RadiosState extends State<_Radios> {
  String? _vehicle = 'car';
  String? _error;

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Radios',
    spacing: CivicSpacing.s32,
    children: [
      CivicRadioGroup<String>(
        labelText: 'What kind of vehicle is the permit for?',
        helperText: 'You can apply for one permit at a time.',
        groupValue: _vehicle,
        onChanged: (v) => setState(() => _vehicle = v),
        children: const [
          CivicRadio(value: 'car', labelText: 'Car or van'),
          CivicRadio(
            value: 'motorcycle',
            labelText: 'Motorcycle',
            helperText: 'Includes mopeds and scooters.',
          ),
          CivicRadio(
            value: 'electric',
            labelText: 'Electric vehicle',
            helperText: 'Electric vehicles pay a lower fee.',
          ),
          CivicRadioDivider(label: 'or'),
          CivicRadio(value: 'none', labelText: 'I do not have a vehicle yet'),
        ],
      ),
      CivicRadioGroup<String>(
        labelText: 'Do you live in Zone B?',
        errorText: _error ?? 'Select yes if you live in Zone B',
        groupValue: null,
        onChanged: (v) => setState(() => _error = ''),
        children: const [
          CivicRadio(value: 'yes', labelText: 'Yes'),
          CivicRadio(value: 'no', labelText: 'No'),
        ],
      ),
    ],
  );
}

class _Checks extends StatefulWidget {
  const _Checks();

  @override
  State<_Checks> createState() => _ChecksState();
}

class _ChecksState extends State<_Checks> {
  final Set<String> _on = {'email'};

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Checkboxes',
    children: [
      CivicFieldset(
        labelText: 'How would you like us to contact you?',
        helperText: 'Select all that apply.',
        children: [
          for (final (id, label, hint) in const [
            ('email', 'Email', null),
            (
              'text',
              'Text message',
              'We will only text you about this permit.',
            ),
            ('post', 'Post', null),
          ])
            CivicCheckbox(
              value: _on.contains(id),
              labelText: label,
              helperText: hint,
              onChanged: (v) =>
                  setState(() => v == true ? _on.add(id) : _on.remove(id)),
            ),
          const CivicCheckbox(
            value: true,
            labelText: 'Phone call (not offered)',
            onChanged: null,
          ),
        ],
      ),
    ],
  );
}

class _Select extends StatefulWidget {
  const _Select();

  @override
  State<_Select> createState() => _SelectState();
}

class _SelectState extends State<_Select> {
  String? _zone;

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Select',
    caption: 'For a list too long for radios.',
    children: [
      CivicSelect<String>(
        labelText: 'Permit zone',
        hintText: 'Choose a zone',
        value: _zone,
        onChanged: (v) => setState(() => _zone = v),
        items: const [
          CivicSelectItem(value: 'a', label: 'Zone A: Old Town'),
          CivicSelectItem(value: 'b', label: 'Zone B: Harbourside'),
          CivicSelectItem(value: 'c', label: 'Zone C: Mill Lane'),
          CivicSelectItem(value: 'd', label: 'Zone D: Northgate'),
          CivicSelectItem(
            value: 'e',
            label: 'Zone E: Riverside',
            enabled: false,
          ),
        ],
      ),
    ],
  );
}

class _Switches extends StatefulWidget {
  const _Switches();

  @override
  State<_Switches> createState() => _SwitchesState();
}

class _SwitchesState extends State<_Switches> {
  bool _larger = false;
  bool _reminders = true;

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Switches',
    caption: 'For a setting that acts at once.',
    spacing: CivicSpacing.s4,
    children: [
      CivicSwitch(
        value: _reminders,
        onChanged: (v) => setState(() => _reminders = v),
        labelText: 'Renewal reminders',
        helperText: 'We will email you a month before your permit ends.',
      ),
      CivicSwitch(
        value: _larger,
        onChanged: (v) => setState(() => _larger = v),
        labelText: 'Larger text',
      ),
      const CivicSwitch(
        value: true,
        onChanged: null,
        labelText: 'Paper permit (not offered)',
      ),
    ],
  );
}

const _countries = [
  'Albania',
  'Algeria',
  'Argentina',
  'Australia',
  'Austria',
  'Bangladesh',
  'Belgium',
  'Brazil',
  'Canada',
  'Chile',
  'Colombia',
  'Denmark',
  'Egypt',
  'Ethiopia',
  'Finland',
  'France',
  'Germany',
  'Ghana',
  'Greece',
  'India',
  'Ireland',
  'Italy',
  'Japan',
  'Kenya',
  'Mexico',
  'Morocco',
  'Nigeria',
  'Norway',
  'Pakistan',
  'Poland',
  'Portugal',
  'Spain',
  'Sweden',
  'Turkey',
];

class _Combobox extends StatefulWidget {
  const _Combobox();

  @override
  State<_Combobox> createState() => _ComboboxState();
}

class _ComboboxState extends State<_Combobox> {
  String? _country;

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Combobox',
    caption: 'For a list too long to scan: typing narrows it.',
    children: [
      CivicCombobox<String>(
        labelText: 'Country that issued your driving licence',
        options: _countries,
        value: _country,
        onSelected: (c) => setState(() => _country = c),
      ),
    ],
  );
}
