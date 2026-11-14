/// Fluent 2's text and choice inputs by its spec: the input (four
/// appearances, three sizes, glyphs, password, invalid, disabled), the
/// textarea, the search box and the search entry, the dropdown and the
/// combobox, the tag picker, and the link (brand, subtle, inline,
/// disabled), each live.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

class _Live<T> extends StatefulWidget {
  const _Live(this.initial, this.builder);

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<_Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<_Live<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

const _channels = [
  Fluent2Option('general', 'General', icon: Fluent2Icons.channel),
  Fluent2Option('design', 'Design', icon: Fluent2Icons.channel),
  Fluent2Option(
    'launch',
    'Launch',
    icon: Fluent2Icons.channel,
    secondary: '12',
  ),
  Fluent2Option(
    'archive',
    'Archive',
    icon: Fluent2Icons.archive,
    enabled: false,
  ),
];

const _rooms = [
  Fluent2Option('fjord', 'Fjord room, 2nd floor'),
  Fluent2Option('harbor', 'Harbor room, 3rd floor'),
  Fluent2Option('lantern', 'Lantern room, 3rd floor'),
  Fluent2Option('online', 'Online only'),
];

final _people = [for (final p in kitPeople) Fluent2Option(p.name, p.name)];

/// A field's width: Fluent's input keeps its own width unless a form gives
/// it one, so the page shows its inputs 400 wide from the column's start
/// (a form section runs them to its 560; a phone's column is narrower, and
/// there they run it).
const double _fieldWidth = 400;

Widget _atFieldWidth(Widget child) => Align(
  alignment: AlignmentDirectional.topStart,
  heightFactor: 1,
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: _fieldWidth),
    child: child,
  ),
);

Widget kitInputsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Inputs',
  sections: [
    kitSection('Input, appearances', children: [kitSpecimenInputAppearances()]),
    kitSection(
      'Input, sizes',
      children: [
        for (final size in Fluent2InputSize.values)
          _atFieldWidth(
            _Live<String>(
              '',
              (v, set) => Fluent2TextField(
                label: 'Project name, ${kitSay(size)}',
                hint: kitSay(size),
                value: v,
                size: size,
                onChanged: set,
              ),
            ),
          ),
      ],
    ),
    kitSection('Input, states', children: [kitSpecimenInputStates()]),
    kitSection('Textarea', children: [kitSpecimenTextarea()]),
    kitSection('Search box', children: [kitSpecimenSearchBox()]),
    kitSection('Search entry', children: [kitSpecimenSearchEntry()]),
    kitSection('Dropdown', children: [kitSpecimenDropdown()]),
    kitSection('Combobox', children: [kitSpecimenCombobox()]),
    kitSection('Tag picker', children: [kitSpecimenTagPicker()]),
    kitSection('Link', children: [kitSpecimenLink()]),
  ],
);

Widget kitSpecimenInputAppearances() => _atFieldWidth(
  Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: Fluent2Spacing.m,
    children: [
      for (final appearance in Fluent2InputAppearance.values)
        _Live<String>(
          '',
          (v, set) => Fluent2TextField(
            label: 'Project name, ${kitSay(appearance)}',
            hint: switch (appearance) {
              Fluent2InputAppearance.outline => 'Outline',
              Fluent2InputAppearance.underline => 'Underline',
              Fluent2InputAppearance.filledDarker => 'Filled darker',
              Fluent2InputAppearance.filledLighter => 'Filled lighter',
            },
            appearance: appearance,
            value: v,
            onChanged: set,
          ),
        ),
    ],
  ),
);

Widget kitSpecimenInputStates() => _atFieldWidth(
  Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: Fluent2Spacing.m,
    children: [
      _Live<String>(
        'ines@northwind.example',
        (v, set) => Fluent2TextField(
          label: 'Email',
          value: v,
          prefixIcon: Fluent2Icons.mail,
          onChanged: set,
        ),
      ),
      _Live<String>(
        'launch-2026',
        (v, set) => Fluent2TextField(
          label: 'Password',
          value: v,
          password: true,
          prefixIcon: Fluent2Icons.lockClosed,
          onChanged: set,
        ),
      ),
      _Live<String>(
        'northwind launch',
        (v, set) => Fluent2TextField(
          label: 'Channel name',
          value: v,
          invalid: true,
          onChanged: set,
        ),
      ),
      const Fluent2TextField(
        label: 'Workspace',
        value: 'Northwind',
        suffixIcon: Fluent2Icons.lockClosed,
      ),
    ],
  ),
);

Widget kitSpecimenTextarea() => _atFieldWidth(
  Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: Fluent2Spacing.m,
    children: [
      _Live<String>(
        '',
        (v, set) => Fluent2TextArea(
          label: 'Meeting notes',
          hint: 'What did the team decide?',
          value: v,
          onChanged: set,
        ),
      ),
      _Live<String>(
        'Ship the launch deck on Thursday. Kai owns the demo; Mara the '
        'press notes.',
        (v, set) => Fluent2TextArea(
          label: 'Summary',
          value: v,
          appearance: Fluent2InputAppearance.filledDarker,
          size: Fluent2InputSize.large,
          onChanged: set,
        ),
      ),
    ],
  ),
);

Widget kitSpecimenSearchBox() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.m,
  children: [
    _Live<String>(
      '',
      (v, set) =>
          Fluent2SearchBox(hint: 'Search files', value: v, onChanged: set),
    ),
    _Live<String>(
      'launch deck',
      (v, set) => Fluent2SearchBox(
        hint: 'Search files',
        value: v,
        appearance: Fluent2InputAppearance.filledDarker,
        onChanged: set,
        onClear: () => set(''),
      ),
    ),
  ],
);

Widget kitSpecimenSearchEntry() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.m,
  children: [
    Fluent2SearchEntry(hint: 'Search Northwind', onPressed: () {}),
    Fluent2SearchEntry(
      hint: 'Search files',
      query: 'launch deck',
      appearance: Fluent2InputAppearance.filledDarker,
      onPressed: () {},
      onFilter: () {},
    ),
  ],
);

Widget kitSpecimenDropdown() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.m,
  children: [
    _Live<String?>(
      null,
      (v, set) => Fluent2Select<String>(
        label: 'Channel',
        prompt: 'Choose a channel',
        options: _channels,
        value: v,
        onChanged: set,
      ),
    ),
    _Live<String?>(
      'design',
      (v, set) => Fluent2Select<String>(
        label: 'Channel',
        options: _channels,
        value: v,
        appearance: Fluent2InputAppearance.filledDarker,
        onChanged: set,
      ),
    ),
    const Fluent2Select<String>(
      label: 'Channel, disabled',
      options: _channels,
      value: 'general',
      onChanged: null,
    ),
  ],
);

Widget kitSpecimenCombobox() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.m,
  children: [
    _Live<String?>(
      'harbor',
      (v, set) => Fluent2Combobox<String>(
        label: 'Room',
        hint: 'Find a room',
        options: _rooms,
        value: v,
        // Words that match no room say so in the list.
        empty: 'No room by that name',
        onChanged: set,
      ),
    ),
    _Live<String?>(
      null,
      (v, set) => Fluent2Combobox<String>(
        label: 'Room',
        hint: 'Find a room',
        options: _rooms,
        value: v,
        invalid: true,
        onChanged: set,
      ),
    ),
  ],
);

Widget kitSpecimenTagPicker() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.m,
  children: [
    _Live<List<String>>(
      [kitPeople[1].name, kitPeople[2].name],
      (v, set) => Fluent2MultiSelect<String>(
        label: 'Invite',
        options: _people,
        selected: v,
        onChanged: set,
      ),
    ),
    _Live<List<String>>(
      const [],
      (v, set) => Fluent2MultiSelect<String>(
        label: 'Reviewers',
        hint: 'Add reviewers',
        options: _people,
        selected: v,
        size: Fluent2MultiSelectSize.large,
        onChanged: set,
      ),
    ),
    Fluent2MultiSelect<String>(
      label: 'Owners, disabled',
      options: _people,
      selected: [kitPeople[0].name],
      onChanged: null,
    ),
  ],
);

Widget kitSpecimenLink() => Builder(
  builder: (context) {
    final t = context.fluent2Theme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Fluent2Spacing.m,
      children: [
        kitRow([
          Fluent2Link('Open the launch brief', onPressed: () {}),
          Fluent2Link(
            'Version history',
            appearance: Fluent2LinkAppearance.subtle,
            onPressed: () {},
          ),
          const Fluent2Link('Archived file', onPressed: null),
        ]),
        Text.rich(
          TextSpan(
            style: t.body1.c(t.textPrimary),
            children: [
              const TextSpan(text: 'Kai shared '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Fluent2Link(
                  'Launch deck v4',
                  inline: true,
                  onPressed: () {},
                ),
              ),
              const TextSpan(text: ' with the Design channel.'),
            ],
          ),
        ),
      ],
    );
  },
);
