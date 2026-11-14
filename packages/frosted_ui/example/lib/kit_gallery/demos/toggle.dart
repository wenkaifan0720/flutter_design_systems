/// [FrostedToggleGroup]: pressed-in buttons, one or several on at once,
/// and [FrostedSplitButton]: an act with its alternatives behind a chevron.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitToggleDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Toggle',
  sections: [
    kitSection(
      'One at a time',
      children: [
        KitHeld<Set<String>>(
          const {'left'},
          (on, set) => FrostedToggleGroup<String>(
            label: 'Alignment',
            segments: const [
              FrostedButtonSegment('left', 'Left'),
              FrostedButtonSegment('centre', 'Centre'),
              FrostedButtonSegment('right', 'Right'),
            ],
            selected: on,
            onChanged: set,
          ),
        ),
      ],
    ),
    kitSection(
      'Several at once',
      children: [
        KitHeld<Set<String>>(
          const {'b'},
          (on, set) => FrostedToggleGroup<String>(
            label: 'Text style',
            multiple: true,
            allowEmpty: true,
            segments: const [
              FrostedButtonSegment('b', 'Bold'),
              FrostedButtonSegment('i', 'Italic'),
              FrostedButtonSegment('u', 'Underline'),
            ],
            selected: on,
            onChanged: set,
          ),
        ),
      ],
    ),
    kitSection(
      'Inert',
      children: [
        const FrostedToggleGroup<String>(
          label: 'View',
          segments: [
            FrostedButtonSegment('list', 'List'),
            FrostedButtonSegment('grid', 'Grid'),
          ],
          selected: {'list'},
          onChanged: null,
        ),
      ],
    ),
    kitSection(
      'Split button',
      children: [
        kitRow([
          FrostedSplitButton(
            label: 'Save',
            onPressed: () {},
            actions: [
              FrostedSplitAction(label: 'Save as…', onPressed: () {}),
              FrostedSplitAction(label: 'Save all', onPressed: () {}),
              // No onPressed: disabled.
              const FrostedSplitAction(label: 'Export', onPressed: null),
            ],
          ),
          FrostedSplitButton(
            label: 'Share',
            glass: true,
            onPressed: () {},
            actions: [
              FrostedSplitAction(label: 'Copy link', onPressed: () {}),
              FrostedSplitAction(label: 'Invite people', onPressed: () {}),
            ],
          ),
        ]),
      ],
    ),
  ],
);

/// Save, and its other ways behind the arrow.
Widget kitSpecimenSplitButton() => Center(
  heightFactor: 1,
  child: FrostedSplitButton(
    label: 'Save',
    onPressed: () {},
    actions: [FrostedSplitAction(label: 'Save as draft', onPressed: () {})],
  ),
);

/// Money out shown, of in and out.
Widget kitSpecimenToggleGroup() => Center(
  heightFactor: 1,
  child: FrostedToggleGroup<String>(
    label: 'Show',
    multiple: true,
    segments: const [
      FrostedButtonSegment('in', 'Money in'),
      FrostedButtonSegment('out', 'Money out'),
    ],
    selected: const {'out'},
    onChanged: (_) {},
  ),
);
