/// Fluent 2's people: the avatar at its sizes (initials, the person glyph,
/// a square group), in its three colours, its presence badges, the brand
/// ring while active, the avatar group stacked and spread with its
/// overflow count, and the persona with one, two and three lines.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

Widget kitPeopleDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'People',
  sections: [
    kitSection('Sizes', children: [kitSpecimenAvatarSizes()]),
    kitSection('Colours', children: [kitSpecimenAvatarColours()]),
    kitSection('Presence', children: [kitSpecimenPresence()]),
    kitSection(
      'Active, square, no name',
      children: [
        kitRow([
          const Fluent2Avatar(
            name: 'Kai Tanaka',
            size: 48,
            color: Fluent2AvatarColor.colorful,
            selected: true,
          ),
          const Fluent2Avatar(
            name: 'Design team',
            size: 48,
            shape: Fluent2AvatarShape.square,
            color: Fluent2AvatarColor.brand,
          ),
          const Fluent2Avatar(size: 48),
          Fluent2Avatar(
            name: 'Mara Okafor',
            size: 48,
            color: Fluent2AvatarColor.colorful,
            onPressed: () {},
          ),
        ]),
      ],
    ),
    kitSection('Groups', children: [kitSpecimenAvatarGroup()]),
    kitSection('Persona', children: [kitSpecimenPersona()]),
  ],
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

Widget kitSpecimenAvatarSizes() => kitRow([
  for (final size in const [20.0, 24.0, 32.0, 40.0, 48.0, 56.0, 72.0])
    Fluent2Avatar(
      name: 'Ines Duarte',
      size: size,
      color: Fluent2AvatarColor.colorful,
    ),
]);

Widget kitSpecimenAvatarColours() => kitRow([
  const Fluent2Avatar(name: 'Ines Duarte', size: 40),
  const Fluent2Avatar(
    name: 'Ines Duarte',
    size: 40,
    color: Fluent2AvatarColor.brand,
  ),
  for (final person in kitPeople)
    Fluent2Avatar(
      name: person.name,
      size: 40,
      color: Fluent2AvatarColor.colorful,
    ),
]);

Widget kitSpecimenPresence() => kitRow([
  for (final (i, presence) in Fluent2Presence.values.indexed)
    Fluent2Avatar(
      name: kitPeople[i % kitPeople.length].name,
      size: 40,
      color: Fluent2AvatarColor.colorful,
      presence: presence,
    ),
]);

Widget kitSpecimenAvatarGroup() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: Fluent2Spacing.l,
  children: [
    Fluent2AvatarGroup(people: kitPeople, max: 4),
    Fluent2AvatarGroup(
      people: kitPeople,
      max: 4,
      size: 24,
      layout: Fluent2AvatarGroupLayout.spread,
    ),
  ],
);

Widget kitSpecimenPersona() => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: Fluent2Spacing.l,
  children: [
    Fluent2Persona(
      name: 'Kai Tanaka',
      size: 24,
      presence: Fluent2Presence.available,
    ),
    Fluent2Persona(
      name: 'Mara Okafor',
      secondary: 'Product designer',
      presence: Fluent2Presence.busy,
    ),
    Fluent2Persona(
      name: 'Ines Duarte',
      secondary: 'Design lead · Northwind',
      tertiary: 'In a meeting until 16:00',
      size: 56,
      presence: Fluent2Presence.doNotDisturb,
    ),
  ],
);
