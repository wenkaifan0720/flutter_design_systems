/// [FrostedColorPicker]: a colour by eye (its saturation and brightness
/// field, its hue) or by its hex, with or without its opacity.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitColorPickerDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Color picker',
  sections: [
    kitSection(
      'Colour',
      children: [
        KitHeld<Color>(
          const Color(0xFF5B6CFF),
          (colour, set) => FrostedColorPicker(value: colour, onChanged: set),
        ),
      ],
    ),
    kitSection(
      'With opacity',
      children: [
        KitHeld<Color>(
          const Color(0xB3FF7A59),
          (colour, set) => FrostedColorPicker(
            value: colour,
            onChanged: set,
            showAlpha: true,
          ),
        ),
      ],
    ),
  ],
);

/// A goal's colour, forest chosen.
Widget kitSpecimenColorPicker() =>
    FrostedColorPicker(value: const Color(0xFF2F7D5B), onChanged: (_) {});
