/// Frosted's entry fields: [FrostedPasswordField] with its eye,
/// [FrostedInputGroup] with words before and after the text,
/// [FrostedInputOtp]'s one-time-code slots and [FrostedFormField] giving
/// any control a field's label, helper and error.
library;

import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitEntryDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  measured: true,
  title: kitSay('Entry'),
  sections: [
    kitSection(
      kitSay('Password'),
      children: [
        FrostedPasswordField(
          labelText: kitSay('Password'),
          value: 'correct horse',
        ),
        FrostedPasswordField(
          labelText: kitSay('New password'),
          newPassword: true,
          helperText: kitSay('At least 12 characters'),
        ),
        FrostedPasswordField(
          labelText: kitSay('Password'),
          value: 'short',
          errorText: kitSay('Too short'),
        ),
      ],
    ),
    kitSection(
      kitSay('Input group'),
      children: [
        FrostedInputGroup(
          labelText: kitSay('Website'),
          prefix: Text('https://'),
          suffix: Text('.com'),
          value: 'example',
        ),
        FrostedInputGroup(
          labelText: kitSay('Weight'),
          suffix: Text('kg'),
          value: '72',
          keyboardType: TextInputType.number,
        ),
      ],
    ),
    kitSection(
      kitSay('One-time code'),
      children: [
        FrostedInputOtp(labelText: kitSay('Code from your text')),
        FrostedInputOtp(labelText: kitSay('PIN'), length: 4, obscureText: true),
        FrostedInputOtp(
          labelText: kitSay('Code from your text'),
          errorText: kitSay("That code didn't match"),
        ),
      ],
    ),
    kitSection(
      kitSay('Form field'),
      children: [
        KitHeld<Set<String>>(
          {kitSay('Email')},
          (chosen, set) => FrostedFormField(
            labelText: kitSay('Notify me by'),
            helperText: kitSay('Pick at least one'),
            errorText: chosen.isEmpty ? kitSay('Pick at least one') : null,
            required: true,
            mergeSemantics: false,
            child: kitRow([
              for (final way in [
                kitSay('Email'),
                kitSay('Text'),
                kitSay('Push'),
              ])
                FrostedChip(
                  way,
                  selected: chosen.contains(way),
                  onPressed: () => set(
                    chosen.contains(way)
                        ? ({...chosen}..remove(way))
                        : {...chosen, way},
                  ),
                ),
            ]),
          ),
        ),
      ],
    ),
  ],
);

/// A labelled group of chips with its help line.
Widget kitSpecimenFormField() => FrostedFormField(
  labelText: kitSay('Notify me'),
  helperText: kitSay('Pick at least one'),
  mergeSemantics: false,
  child: Row(
    spacing: 8,
    children: [
      FrostedChip('Push', selected: true, onPressed: () {}),
      FrostedChip('Email', onPressed: () {}),
    ],
  ),
);

/// A website between its prefix and suffix.
Widget kitSpecimenInputGroup() => FrostedInputGroup(
  labelText: kitSay('Website'),
  prefix: const Text('https://'),
  suffix: const Text('.com'),
  value: 'harbor',
  onChanged: (_) {},
);

/// The code from a text, its cells empty.
Widget kitSpecimenInputOtp() => FrostedInputOtp(
  labelText: kitSay('Code from your text'),
  onCompleted: (_) {},
);

/// A password, hidden, with its reveal.
Widget kitSpecimenPasswordField() => FrostedPasswordField(
  labelText: kitSay('Password'),
  value: 'harbor-2026',
  onChanged: (_) {},
);
