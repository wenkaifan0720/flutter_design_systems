/// Frosted's entry fields: [FrostedPasswordField] with its eye,
/// [FrostedInputGroup] with words before and after the text,
/// [FrostedInputOtp]'s one-time-code slots and [FrostedFormField] giving
/// any control a field's label, helper and error.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitEntryDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Entry',
  sections: [
    kitSection(
      'Password',
      children: [
        const FrostedPasswordField(label: 'Password', value: 'correct horse'),
        const FrostedPasswordField(
          label: 'New password',
          newPassword: true,
          helper: 'At least 12 characters',
        ),
        const FrostedPasswordField(
          label: 'Password',
          value: 'short',
          error: 'Too short',
        ),
      ],
    ),
    kitSection(
      'Input group',
      children: [
        const FrostedInputGroup(
          label: 'Website',
          prefix: Text('https://'),
          suffix: Text('.com'),
          value: 'example',
        ),
        const FrostedInputGroup(
          label: 'Weight',
          suffix: Text('kg'),
          value: '72',
          keyboardType: TextInputType.number,
        ),
      ],
    ),
    kitSection(
      'One-time code',
      children: [
        const FrostedInputOtp(label: 'Code from your text'),
        const FrostedInputOtp(label: 'PIN', length: 4, obscure: true),
        const FrostedInputOtp(
          label: 'Code from your text',
          error: "That code didn't match",
        ),
      ],
    ),
    kitSection(
      'Form field',
      children: [
        KitHeld<Set<String>>(
          const {'Email'},
          (chosen, set) => FrostedFormField(
            label: 'Notify me by',
            helper: 'Pick at least one',
            error: chosen.isEmpty ? 'Pick at least one' : null,
            required: true,
            mergeSemantics: false,
            child: kitRow([
              for (final way in const ['Email', 'Text', 'Push'])
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
  label: 'Notify me',
  helper: 'Pick at least one',
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
  label: 'Website',
  prefix: const Text('https://'),
  suffix: const Text('.com'),
  value: 'harbor',
  onChanged: (_) {},
);

/// The code from a text, its cells empty.
Widget kitSpecimenInputOtp() =>
    FrostedInputOtp(label: 'Code from your text', onCompleted: (_) {});

/// A password, hidden, with its reveal.
Widget kitSpecimenPasswordField() => FrostedPasswordField(
  label: 'Password',
  value: 'harbor-2026',
  onChanged: (_) {},
);
