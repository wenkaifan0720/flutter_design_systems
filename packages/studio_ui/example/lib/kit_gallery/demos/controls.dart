import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

import '../kit.dart';

/// Faders, knobs and meters: the physical controls.
Widget kitControlsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Faders, knobs and meters',
  sections: [
    KitSection(
      title: 'Faders',
      note: 'A metal cap riding a dark slot, lit up to the cap. Drag, press along it, or use the arrows.',
      children: [
        kitState<double>(
          0.4,
          (context, v, set) =>
              StudioFader(value: v, onChanged: set, semanticLabel: 'Position'),
        ),
        kitState<double>(
          3,
          (context, v, set) => StudioFader(
            value: v,
            max: 10,
            divisions: 10,
            onChanged: set,
            semanticLabel: 'Steps',
          ),
        ),
        const StudioFader(value: 0.6, onChanged: null, semanticLabel: 'Locked'),
        kitState<double>(
          0.7,
          (context, v, set) => SizedBox(
            height: 180,
            child: Row(
              children: [
                StudioFader(
                  value: v,
                  axis: Axis.vertical,
                  onChanged: set,
                  semanticLabel: 'Channel 1',
                ),
                StudioFader(
                  value: 1 - v,
                  axis: Axis.vertical,
                  onChanged: (x) => set(1 - x),
                  semanticLabel: 'Channel 2',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Knobs',
      note: 'Turned by a drag up or across; stepped knobs click into detents.',
      children: [
        kitState<double>(
          0.5,
          (context, v, set) => KitRow(
            children: [
              StudioKnob(value: v, onChanged: set, semanticLabel: 'Monitor'),
              StudioKnob(
                value: v,
                divisions: 6,
                onChanged: (x) => set(x),
                semanticLabel: 'Mode',
              ),
              StudioKnob(value: v, onChanged: null, semanticLabel: 'Locked'),
            ],
          ),
        ),
      ],
    ),
    const KitSection(
      title: 'Meters',
      note: 'Lit segments behind dark glass; red only past the clip line.',
      children: [
        StudioMeter(level: 0.5, peak: 0.66, semanticLabel: 'Left'),
        StudioMeter(level: 0.96, peak: 1, semanticLabel: 'Right'),
      ],
    ),
  ],
);
