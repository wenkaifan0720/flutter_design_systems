/// Portraits with fallback initials and grouped faces.
library;

import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitShowsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'People and portraits',
  sections: [
    kitSection('Portraits', children: [kitSpecimenAvatar()]),
    kitSection('People together', children: [kitSpecimenFacePile()]),
  ],
);
Widget kitSpecimenAvatar() => const Wrap(
  spacing: 18,
  runSpacing: 12,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: [
    NeumorphicAvatar('NW', name: 'Nia Walker'),
    NeumorphicAvatar('AK', name: 'Amir Khan', selected: true),
    NeumorphicAvatar('JR', name: 'June Rivera', size: 56),
  ],
);
Widget kitSpecimenFacePile() => const NeumorphicAvatarGroup([
  NeumorphicFace('NW', name: 'Nia Walker'),
  NeumorphicFace('AK', name: 'Amir Khan'),
  NeumorphicFace('JR', name: 'June Rivera'),
  NeumorphicFace('LF', name: 'Luca Flores'),
  NeumorphicFace('SK', name: 'Sara Kim'),
  NeumorphicFace('AT', name: 'Ari Torres'),
], most: 3);
