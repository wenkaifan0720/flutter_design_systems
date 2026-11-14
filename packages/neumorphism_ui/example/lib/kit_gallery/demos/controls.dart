/// What a person presses, types or picks. The ones you can latch say so three ways, so they read with no shadow: a pigment mark, bold words, a pressed face.
library;

import 'package:flutter/material.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitControlsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Buttons, latches, fields',
  sections: [
    kitSection('An icon that acts', children: [kitSpecimenIconButton()]),
    kitSection('The act', children: [kitSpecimenActButton()]),
    kitSection('A plain button', children: [kitSpecimenLineButton()]),
    kitSection('A quiet action', children: [kitSpecimenQuietButton()]),
    kitSection('A destructive action', children: [kitSpecimenDangerButton()]),
    kitSection('Button sizes and waiting', children: [kitButtonStates()]),
    kitSection('Removable chips', children: [kitRemovableChips()]),
    kitSection('A link', children: [kitSpecimenTextLink()]),
    kitSection('A round push button', children: [kitSpecimenRoundButton()]),
    kitSection('A chip', children: [kitSpecimenChip()]),
    kitSection('A latch bank', children: [kitSpecimenLatches()]),
    kitSection('A field', children: [kitSpecimenTextField()]),
    kitSection('A select', children: [kitSpecimenSelectField()]),
    kitSection('Bigger choices', children: [kitSpecimenChoices()]),
    kitSection('A stepper', children: [kitSpecimenStepper()]),
    kitSection('A switch', children: [kitSpecimenSwitch()]),
    kitSection('A switch with its words', children: [kitSpecimenSwitchRow()]),
    kitSection('A slider', children: [kitSpecimenSlider()]),
    kitSection('A progress line', children: [kitSpecimenProgress()]),
    kitSection('A check', children: [kitSpecimenCheck()]),
  ],
);

Widget kitSpecimenActButton() => NeumorphicButton.filled(
  'Turn off',
  icon: NeumorphicGlyphs.power,
  onPressed: () {},
);

Widget kitSpecimenLineButton() => NeumorphicButton(
  'Open',
  icon: NeumorphicGlyphs.arrowRight,
  onPressed: () {},
);

Widget kitSpecimenTextLink() => NeumorphicLink('A link', onPressed: () {});

Widget kitSpecimenRoundButton() => Wrap(
  spacing: 16,
  children: [
    NeumorphicRoundButton(
      NeumorphicGlyphs.moon,
      label: 'Off',
      onPressed: () {},
    ),
    NeumorphicRoundButton(
      NeumorphicGlyphs.clapperboard,
      label: 'On',
      selected: true,
      onPressed: () {},
    ),
    NeumorphicRoundButton(
      NeumorphicGlyphs.inbox,
      label: 'Inbox',
      badge: '2',
      onPressed: () {},
    ),
  ],
);

Widget kitSpecimenChip() => Wrap(
  spacing: 10,
  runSpacing: 10,
  children: [
    const NeumorphicChip('A fact', icon: NeumorphicGlyphs.zap),
    const NeumorphicChip(
      'A live fact',
      icon: NeumorphicGlyphs.shieldCheck,
      live: true,
    ),
    NeumorphicChip('Chosen', selected: true, onPressed: () {}),
  ],
);

Widget kitSpecimenLatches() => NeumorphicLatchGroup(
  options: const [
    NeumorphicLatch('Run', icon: NeumorphicGlyphs.play),
    NeumorphicLatch('Eco', icon: NeumorphicGlyphs.leaf),
    NeumorphicLatch('Off', icon: NeumorphicGlyphs.power),
  ],
  value: 'Run',
  onChanged: (_) {},
);

Widget kitSpecimenTextField() => const NeumorphicColumn(
  gap: 12,
  children: [
    NeumorphicTextField(hint: 'A name'),
    NeumorphicTextField(hint: 'A longer note', lines: 3),
  ],
);

Widget kitSpecimenSelectField() =>
    NeumorphicSelectField(value: 'A town', onPressed: () {});

Widget kitSpecimenChoices() => NeumorphicChoices(
  options: const [
    NeumorphicChoice('The first', note: 'A small note'),
    NeumorphicChoice('The second', note: 'A small note'),
  ],
  value: 'The first',
  onChanged: (_) {},
);

Widget kitSpecimenStepper() => NeumorphicNumberField(
  value: '2',
  unit: 'people',
  note: 'Up to 12',
  onDecrease: () {},
  onIncrease: () {},
);

Widget kitSpecimenSwitch() {
  var a = false, b = true;
  return StatefulBuilder(
    builder: (context, setState) => Wrap(
      spacing: 16,
      children: [
        NeumorphicSwitch(
          value: a,
          label: 'Lights',
          onChanged: (v) => setState(() => a = v),
        ),
        NeumorphicSwitch(
          value: b,
          label: 'Fan',
          onChanged: (v) => setState(() => b = v),
        ),
      ],
    ),
  );
}

Widget kitSpecimenSwitchRow() => NeumorphicSwitchRow(
  label: 'Reminders',
  note: 'On, at 09:00',
  value: true,
  onChanged: (_) {},
);

Widget kitSpecimenSlider() =>
    NeumorphicSlider(label: 'Level', value: .3, onChanged: (_) {});

Widget kitSpecimenProgress() =>
    const NeumorphicProgress(value: .21, start: '0:25:12', end: '1:58:00');

Widget kitSpecimenCheck() => const Wrap(
  spacing: 16,
  children: [NeumorphicRoundCheckbox(), NeumorphicRoundCheckbox(value: true)],
);

Widget kitSpecimenIconButton() => Wrap(
  spacing: 12,
  children: [
    NeumorphicIconButton(NeumorphicGlyphs.plus, label: 'Add', onPressed: () {}),
    NeumorphicIconButton(
      NeumorphicGlyphs.bell,
      label: 'Notifications',
      selected: true,
      badge: '2',
      onPressed: () {},
    ),
    const NeumorphicIconButton(NeumorphicGlyphs.lock, label: 'Locked'),
  ],
);

Widget kitSpecimenQuietButton() =>
    NeumorphicButton.text('Skip for now', onPressed: () {});
Widget kitSpecimenDangerButton() => NeumorphicButton(
  'Delete file',
  isDestructiveAction: true,
  onPressed: () {},
);
Widget kitButtonStates() => Wrap(
  spacing: 14,
  runSpacing: 14,
  children: [
    for (final size in NeumorphicButtonSize.values)
      NeumorphicButton('Save', size: size, onPressed: () {}),
    const NeumorphicButton.filled('Saving', busy: true),
    const NeumorphicButton('Unavailable'),
  ],
);
Widget kitRemovableChips() => Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [
    NeumorphicChip('Studio', onPressed: () {}, onDeleted: () {}),
    NeumorphicChip('Selected', selected: true, onDeleted: () {}),
    NeumorphicChip('Unavailable', enabled: false, onDeleted: () {}),
  ],
);
