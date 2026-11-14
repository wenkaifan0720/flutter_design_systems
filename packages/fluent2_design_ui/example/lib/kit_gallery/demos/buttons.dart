/// Fluent 2's buttons by its spec: the five appearances (secondary,
/// primary, outline, subtle, transparent) at its three sizes, the shapes,
/// a glyph before or after, the icon button (with a selected and a badged
/// cut), the toggle button, the compound button with its second line, the
/// menu button with its chevron and the split button, each disabled too.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import '../kit.dart';

Widget kitButtonsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Buttons',
  sections: [
    kitSection('Appearances', children: [kitSpecimenButtonAppearances()]),
    kitSection('Sizes', children: [kitSpecimenButtonSizes()]),
    kitSection(
      'Shapes',
      children: [
        kitRow([
          for (final shape in Fluent2ButtonShape.values)
            Fluent2Button(kitSay(shape), shape: shape, onPressed: () {}),
        ]),
      ],
    ),
    kitSection(
      'With a glyph',
      children: [
        kitRow([
          Fluent2Button(
            'New meeting',
            icon: Fluent2Icons.calendarAdd,
            appearance: Fluent2ButtonAppearance.primary,
            onPressed: () {},
          ),
          Fluent2Button(
            'Upload',
            icon: Fluent2Icons.arrowUpload,
            onPressed: () {},
          ),
          Fluent2Button(
            'Next',
            icon: Fluent2Icons.chevronRight,
            iconPosition: Fluent2IconPosition.after,
            appearance: Fluent2ButtonAppearance.subtle,
            onPressed: () {},
          ),
        ]),
      ],
    ),
    kitSection('Disabled', children: [kitSpecimenButtonDisabled()]),
    kitSection('Icon buttons', children: [kitSpecimenIconButtons()]),
    kitSection('Toggle buttons', children: [const _Toggles()]),
    kitSection('Compound', children: [kitSpecimenCompoundButton()]),
    kitSection('Menu and split', children: [kitSpecimenMenuSplit()]),
    kitSection(
      'Full width',
      children: [
        Fluent2Button(
          'Join meeting',
          appearance: Fluent2ButtonAppearance.primary,
          size: Fluent2ButtonSize.large,
          expand: true,
          onPressed: () {},
        ),
      ],
    ),
  ],
);

class _Toggles extends StatefulWidget {
  const _Toggles();

  @override
  State<_Toggles> createState() => _TogglesState();
}

class _TogglesState extends State<_Toggles> {
  bool _mic = true;
  bool _camera = false;
  bool _pinned = true;

  @override
  Widget build(BuildContext context) => kitRow([
    Fluent2ToggleButton(
      'Mic',
      value: _mic,
      icon: Fluent2Icons.mic,
      checkedIcon: Fluent2Icons.micFilled,
      onChanged: (v) => setState(() => _mic = v),
    ),
    Fluent2ToggleButton(
      'Camera',
      value: _camera,
      icon: Fluent2Icons.video,
      checkedIcon: Fluent2Icons.videoFilled,
      onChanged: (v) => setState(() => _camera = v),
    ),
    Fluent2ToggleButton(
      'Pinned',
      value: _pinned,
      appearance: Fluent2ButtonAppearance.subtle,
      icon: Fluent2Icons.pin,
      checkedIcon: Fluent2Icons.pinFilled,
      onChanged: (v) => setState(() => _pinned = v),
    ),
  ]);
}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

Widget kitSpecimenButtonAppearances() => kitRow([
  for (final appearance in Fluent2ButtonAppearance.values)
    Fluent2Button(
      switch (appearance) {
        Fluent2ButtonAppearance.primary => 'Primary',
        Fluent2ButtonAppearance.secondary => 'Secondary',
        Fluent2ButtonAppearance.outline => 'Outline',
        Fluent2ButtonAppearance.subtle => 'Subtle',
        Fluent2ButtonAppearance.transparent => 'Transparent',
      },
      appearance: appearance,
      icon: Fluent2Icons.calendarLtr,
      onPressed: () {},
    ),
]);

Widget kitSpecimenButtonSizes() => kitRow([
  for (final size in Fluent2ButtonSize.values)
    Fluent2Button(
      switch (size) {
        Fluent2ButtonSize.small => 'Small',
        Fluent2ButtonSize.medium => 'Medium',
        Fluent2ButtonSize.large => 'Large',
      },
      size: size,
      appearance: Fluent2ButtonAppearance.primary,
      onPressed: () {},
    ),
  for (final size in Fluent2ButtonSize.values)
    Fluent2Button(
      switch (size) {
        Fluent2ButtonSize.small => 'Small',
        Fluent2ButtonSize.medium => 'Medium',
        Fluent2ButtonSize.large => 'Large',
      },
      size: size,
      onPressed: () {},
    ),
]);

Widget kitSpecimenButtonDisabled() => kitRow([
  for (final appearance in const [
    Fluent2ButtonAppearance.primary,
    Fluent2ButtonAppearance.secondary,
    Fluent2ButtonAppearance.subtle,
  ])
    Fluent2Button(
      'Send',
      appearance: appearance,
      icon: Fluent2Icons.send,
      onPressed: null,
    ),
]);

Widget kitSpecimenIconButtons() => kitRow([
  Fluent2IconButton(Fluent2Icons.edit, label: 'Edit', onPressed: () {}),
  Fluent2IconButton(
    Fluent2Icons.share,
    label: 'Share',
    appearance: Fluent2ButtonAppearance.secondary,
    onPressed: () {},
  ),
  Fluent2IconButton(
    Fluent2Icons.add,
    label: 'New',
    appearance: Fluent2ButtonAppearance.primary,
    shape: Fluent2ButtonShape.circular,
    onPressed: () {},
  ),
  Fluent2IconButton(
    Fluent2Icons.star,
    label: 'Favourite',
    selected: true,
    filled: Fluent2Icons.starFilled,
    onPressed: () {},
  ),
  Fluent2IconButton(
    Fluent2Icons.moreHorizontal,
    label: 'More',
    size: Fluent2ButtonSize.small,
    onPressed: () {},
  ),
]);

Widget kitSpecimenCompoundButton() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.s,
  children: [
    Fluent2CompoundButton(
      'New meeting',
      secondary: 'Schedule a video call',
      icon: Fluent2Icons.calendarAdd,
      appearance: Fluent2ButtonAppearance.primary,
      onPressed: () {},
    ),
    Fluent2CompoundButton(
      'Share a file',
      secondary: 'From Northwind Files',
      icon: Fluent2Icons.documentText,
      onPressed: () {},
    ),
  ],
);

Widget kitSpecimenMenuSplit() => kitRow([
  Fluent2MenuButton('Sort', icon: Fluent2Icons.arrowSort, onPressed: () {}),
  Fluent2MenuButton(
    'New',
    appearance: Fluent2ButtonAppearance.primary,
    onPressed: () {},
  ),
  Fluent2SplitButton(
    'Reply',
    icon: Fluent2Icons.arrowReply,
    onPressed: () {},
    actions: [
      Fluent2SplitAction('Reply all', onPressed: () {}),
      Fluent2SplitAction('Forward', onPressed: () {}),
    ],
  ),
  Fluent2SplitButton(
    'Send',
    appearance: Fluent2ButtonAppearance.primary,
    onPressed: () {},
    actions: [
      Fluent2SplitAction('Schedule send', onPressed: () {}),
      Fluent2SplitAction('Save as draft', onPressed: () {}),
    ],
  ),
]);
