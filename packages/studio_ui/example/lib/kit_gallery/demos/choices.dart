import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

import '../kit.dart';

/// Switches, checkboxes, radios and the key bank.
Widget kitChoicesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Switches and choices',
  sections: [
    KitSection(
      title: 'Switches',
      note: 'A metal cap thrown in a dark slot; on, the slot behind it lights.',
      children: [
        kitState<bool>(
          true,
          (context, on, set) => KitRow(
            children: [
              StudioSwitch(value: on, onChanged: set, semanticLabel: 'Live'),
              StudioSwitch(
                value: !on,
                onChanged: (v) => set(!v),
                semanticLabel: 'Monitor',
              ),
              const StudioSwitch(
                value: true,
                onChanged: null,
                semanticLabel: 'Locked',
              ),
            ],
          ),
        ),
        kitState<bool>(
          true,
          (context, on, set) => StudioListGroup(
            children: [
              StudioListTile.toggle(
                title: 'New episodes',
                value: on,
                onChanged: set,
              ),
              StudioListTile.toggle(
                title: 'Weekly digest',
                value: !on,
                onChanged: (v) => set(!v),
              ),
            ],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Checkboxes and radios',
      note: 'Latching keys: checked, a square key stays in with its check lit; chosen, a round key stays in with its lamp lit. A group of radios is one Tab stop; the arrows choose.',
      children: [
        kitState<bool>(
          true,
          (context, on, set) => KitRow(
            children: [
              StudioCheckbox(
                value: on,
                onChanged: (v) => set(v),
                semanticLabel: 'Explicit',
              ),
              StudioCheckbox(
                value: !on,
                onChanged: (v) => set(!v),
                semanticLabel: 'Trailer',
              ),
              const StudioCheckbox(
                value: true,
                onChanged: null,
                semanticLabel: 'Locked',
              ),
              const StudioCheckbox(
                value: false,
                onChanged: null,
                isError: true,
                semanticLabel: 'Required',
              ),
            ],
          ),
        ),
        kitState<String>(
          'mp3',
          (context, v, set) => StudioRadioGroup<String>(
            options: const ['mp3', 'aac', 'wav'],
            value: v,
            labelOf: (f) => f.toUpperCase(),
            direction: Axis.horizontal,
            semanticLabel: 'Format',
            onChanged: set,
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Key bank',
      note: 'One key latched in at a time, its lamp lit. Arrows move along the bank.',
      children: [
        kitState<double>(
          1,
          (context, v, set) => StudioSegmentedButton<double>(
            semanticLabel: 'Speed',
            segments: const [
              StudioSegment(value: 1, label: '1×'),
              StudioSegment(value: 1.25, label: '1.25×'),
              StudioSegment(value: 1.5, label: '1.5×'),
              StudioSegment(value: 2, label: '2×'),
            ],
            value: v,
            onChanged: set,
          ),
        ),
      ],
    ),
  ],
);
