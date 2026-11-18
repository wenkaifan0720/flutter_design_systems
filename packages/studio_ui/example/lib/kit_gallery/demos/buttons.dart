import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Keys: plain, lit, capless; with a glyph; destructive; off; icon keys and
/// transport keys.
Widget kitButtonsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Keys',
  sections: [
    KitSection(
      title: 'Kinds',
      note:
          'A key for most things; a lit key for the one thing a screen is '
          'for; a capless legend for the least.',
      children: [
        KitRow(
          children: [
            StudioButton.lit('Publish', onPressed: () {}),
            StudioButton('Save draft', onPressed: () {}),
            StudioButton.text('Details', onPressed: () {}),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'With a glyph',
      children: [
        KitRow(
          children: [
            StudioButton.lit(
              'Play',
              icon: const Icon(LucideIcons.play),
              onPressed: () {},
            ),
            StudioButton(
              'Mark',
              icon: const Icon(LucideIcons.flag),
              onPressed: () {},
            ),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Destructive and off',
      children: [
        KitRow(
          children: [
            StudioButton.lit(
              'Discard take',
              isDestructiveAction: true,
              onPressed: () {},
            ),
            StudioButton('Delete', isDestructiveAction: true, onPressed: () {}),
            const StudioButton.lit('Publish', onPressed: null),
            const StudioButton('Save draft', onPressed: null),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Icon keys and transport keys',
      note: 'An icon key latches in when selected, its glyph lit. The record key carries a red lamp.',
      children: [
        // Shown latched and rolling: press any to let them out.
        kitState<bool>(
          true,
          (context, on, set) => KitRow(
            children: [
              StudioIconButton(
                icon: const Icon(LucideIcons.search),
                tooltip: 'Search',
                onPressed: () {},
              ),
              StudioIconButton(
                icon: const Icon(LucideIcons.bookmark),
                tooltip: 'Save',
                selected: on,
                onPressed: () => set(!on),
              ),
              StudioTransportKey(
                icon: Icon(on ? LucideIcons.pause : LucideIcons.play),
                tooltip: on ? 'Pause' : 'Play',
                lit: on,
                onPressed: () => set(!on),
              ),
              StudioTransportKey(
                icon: const Icon(LucideIcons.circle),
                tooltip: 'Record',
                record: true,
                lit: on,
                onPressed: () => set(!on),
              ),
            ],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Floating key',
      note: 'One graphite key standing off the panel, its shadow under it.',
      children: [
        Builder(
          builder: (context) => KitRow(
            children: [
              StudioFloatingKey(
                icon: const Icon(LucideIcons.mic),
                tooltip: 'New recording',
                onPressed: () => kitFeedback(context, 'Recording'),
              ),
              StudioFloatingKey.extended(
                icon: const Icon(LucideIcons.mic),
                label: 'Record',
                onPressed: () => kitFeedback(context, 'Recording'),
              ),
            ],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Key rows and banks',
      note: 'Momentary keys set in one recess; a toggle bank latches, each key with its lamp.',
      children: [
        Builder(
          builder: (context) => StudioKeyRow(
            semanticLabel: 'Clip',
            items: [
              StudioKeyRowItem(
                label: 'Cut',
                icon: const Icon(LucideIcons.scissors),
                onPressed: () => kitFeedback(context, 'Cut'),
              ),
              StudioKeyRowItem(
                label: 'Split',
                onPressed: () => kitFeedback(context, 'Split'),
              ),
              StudioKeyRowItem(
                label: 'Fade',
                onPressed: () => kitFeedback(context, 'Faded'),
              ),
            ],
          ),
        ),
        kitState<Set<String>>(
          const {'Solo'},
          (context, v, set) => StudioToggleBank<String>(
            semanticLabel: 'Channel',
            options: const ['Mute', 'Solo', 'Arm'],
            selected: v,
            labelOf: (s) => s,
            onSelectionChanged: set,
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Split keys',
      note: 'The action and, beside it, a key that opens the others.',
      children: [
        Builder(
          builder: (context) => KitRow(
            children: [
              StudioSplitKey(
                label: 'Export',
                onPressed: () => kitFeedback(context, 'Exported as MP3'),
                actions: [
                  StudioMenuItem(
                    label: 'Export as WAV',
                    onPressed: () => kitFeedback(context, 'Exported as WAV'),
                  ),
                  StudioMenuItem(
                    label: 'Export stems',
                    onPressed: () => kitFeedback(context, 'Exported stems'),
                  ),
                ],
              ),
              StudioSplitKey(
                label: 'Publish',
                lit: true,
                onPressed: () => kitFeedback(context, 'Published'),
                actions: [
                  StudioMenuItem(
                    label: 'Schedule…',
                    onPressed: () => kitFeedback(context, 'Scheduled'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Links and keycaps',
      note: 'A link is words in the lit legend colour; a keycap names a key to press.',
      children: [
        Builder(
          builder: (context) => KitRow(
            children: [
              StudioLink(
                'Show notes',
                onPressed: () => kitFeedback(context, 'Show notes'),
              ),
              const StudioKbd.shortcut(
                SingleActivator(LogicalKeyboardKey.keyK, control: true),
              ),
              const StudioKbd(['Space'], semanticLabel: 'Space'),
            ],
          ),
        ),
      ],
    ),
  ],
);
