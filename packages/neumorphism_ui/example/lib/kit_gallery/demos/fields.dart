/// Passwords, groups, combos, colours and the wheel.
library;

import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitFieldsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Passwords, groups, combos and colours',
  sections: kitFieldsSections(),
);

List<Widget> kitFieldsSections() => [
  kitSection('A secret', children: [kitSpecimenPasswordField()]),
  kitSection(
    'Words fixed around the text',
    children: [kitSpecimenInputGroup()],
  ),
  kitSection('Type to find one', children: [kitSpecimenCombobox()]),
  kitSection('Several, as tags', children: [kitSpecimenMultiSelect()]),
  kitSection(
    'A label and help around any field',
    children: [kitSpecimenFormField()],
  ),
  kitSection('A span between two values', children: [kitSpecimenRangeSlider()]),
  kitSection('Any colour', children: [kitSpecimenColorPicker()]),
  kitSection(
    'One from a short list, on a wheel',
    children: [kitSpecimenWheelPicker()],
  ),
];

Widget kitSpecimenPasswordField() => const NeumorphicPasswordField(
  label: 'Password',
  hint: 'At least eight letters',
);

Widget kitSpecimenInputGroup() => const NeumorphicInputGroup(
  label: 'Website',
  prefix: 'https://',
  keyboardType: TextInputType.url,
  suffix: '.com',
  hint: 'your-home',
);

Widget kitSpecimenCombobox() => const NeumorphicCombobox<String>(
  label: 'Room',
  hint: 'Type a room',
  helper: 'Words no room fits say so in the list',
  options: ['Bedroom', 'Kitchen', 'Study', 'Hall', 'Attic'],
);

Widget kitSpecimenMultiSelect() => kitValue<List<String>>(
  const ['Bedroom', 'Study'],
  (context, rooms, change) => NeumorphicMultiSelect<String>(
    label: 'Rooms',
    hint: 'Add a room',
    values: rooms,
    onChanged: change,
    options: const ['Bedroom', 'Kitchen', 'Study', 'Hall', 'Attic'],
  ),
);

Widget kitSpecimenFormField() => const NeumorphicFormField(
  label: 'Email',
  help: 'The receipt goes here',
  required: true,
  child: NeumorphicTextField(hint: 'name@example.com'),
);

Widget kitSpecimenRangeSlider() => kitValue<DesignRangeValues>(
  const DesignRangeValues(18, 22),
  (context, values, change) => NeumorphicRangeSlider(
    label: 'Comfort',
    values: values,
    min: 12,
    max: 28,
    divisions: 16,
    valueLabel: (v) => '${v.round()}°',
    onChanged: change,
  ),
);

Widget kitSpecimenColorPicker() => kitHeld<DesignColorController>(
  () => DesignColorController(const Color(0xFFB5624C)),
  (context, controller) =>
      NeumorphicColorPicker(controller: controller, label: 'Lamp colour'),
);

Widget kitSpecimenWheelPicker() => kitValue<int>(
  2,
  (context, lamps, change) => NeumorphicWheelPicker<int>(
    label: 'Lamps',
    items: const [1, 2, 3, 4, 5, 6, 7, 8],
    value: lamps,
    onChanged: change,
    itemLabel: (n) => n == 1 ? '1 lamp' : '$n lamps',
    width: 220,
  ),
);
