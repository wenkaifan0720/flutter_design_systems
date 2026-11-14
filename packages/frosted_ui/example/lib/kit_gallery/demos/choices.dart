/// [FrostedRadioGroup], [FrostedCheckRow], [FrostedChip], [FrostedChoices],
/// [FrostedRating] and [FrostedFileUpload]: one of many, several of many,
/// a score and a file.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitChoicesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Radios, chips, rating & upload',
  sections: [
    kitSection(
      'Radio group',
      children: [
        KitHeld<String?>(
          'standard',
          (v, set) => FrostedRadioGroup<String>(
            label: 'Delivery',
            value: v,
            onChanged: set,
            options: const [
              FrostedRadio('standard', 'Standard', note: '3 to 5 days'),
              FrostedRadio('express', 'Express', note: 'Next day'),
              FrostedRadio(
                'pickup',
                'Pick up',
                note: 'Closed today',
                enabled: false,
              ),
            ],
          ),
        ),
      ],
    ),
    kitSection(
      'Check rows',
      children: [
        KitHeld<bool?>(
          true,
          (v, set) => FrostedCheckRow(
            label: 'Email me a receipt',
            note: 'Sent to the address on file',
            value: v,
            onChanged: set,
          ),
        ),
        const FrostedCheckRow(
          label: 'Locked by your admin',
          value: false,
          enabled: false,
        ),
      ],
    ),
    kitSection(
      'Chips',
      children: [
        KitHeld<Set<String>>(
          const {'Design'},
          (on, set) => kitRow([
            for (final tag in const ['Design', 'Research', 'Writing'])
              FrostedChip(
                tag,
                selected: on.contains(tag),
                onPressed: () => set(
                  on.contains(tag) ? ({...on}..remove(tag)) : {...on, tag},
                ),
              ),
            FrostedChip(
              'Ines Park',
              onDeleted: () {},
              deleteLabel: 'Remove Ines Park',
            ),
          ]),
        ),
      ],
    ),
    kitSection(
      'Choices',
      children: [
        KitHeld<String?>(
          'm',
          (v, set) => FrostedChoices<String>(
            label: 'Size',
            value: v,
            onChanged: set,
            options: const [
              FrostedSelectOption('s', 'Small'),
              FrostedSelectOption('m', 'Medium'),
              FrostedSelectOption('l', 'Large'),
              FrostedSelectOption('xl', 'Extra large', enabled: false),
            ],
          ),
        ),
      ],
    ),
    kitSection(
      'Rating',
      children: [
        KitHeld<double>(
          4,
          (v, set) =>
              FrostedRating(value: v, label: 'Your rating', onChanged: set),
        ),
        const FrostedRating(value: 3.5, label: 'Average', allowHalf: true),
      ],
    ),
    kitSection(
      'File upload',
      children: [
        FrostedFileUpload(
          label: 'Attachments',
          hint: 'PDF or image, up to 10 MB',
          onPressed: () {},
          onRemoved: (_) {},
          files: const [
            FrostedUploadFile('brief.pdf', bytes: 248000),
            FrostedUploadFile('cover.png', bytes: 1820000, progress: 0.4),
          ],
        ),
      ],
    ),
  ],
);

/// A receipt by email, ticked.
Widget kitSpecimenCheckRow() => FrostedCheckRow(
  label: 'Email me a receipt',
  note: 'Sent to maren@harbor.app',
  value: true,
  onChanged: (_) {},
);

/// Two filters, one on.
Widget kitSpecimenChip() => Center(
  heightFactor: 1,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: [
      FrostedChip('Dining out', selected: true, onPressed: () {}),
      FrostedChip('Groceries', onPressed: () {}),
    ],
  ),
);

/// Round up to: one of three.
Widget kitSpecimenChoices() => FrostedChoices<String>(
  label: 'Round up to',
  options: const [
    FrostedSelectOption('1', r'$1'),
    FrostedSelectOption('2', r'$2'),
    FrostedSelectOption('5', r'$5'),
  ],
  value: '2',
  onChanged: (_) {},
);

/// Receipts, one attached.
Widget kitSpecimenFileUpload() => FrostedFileUpload(
  label: 'Receipts',
  hint: 'PDF or photos, up to 10 MB',
  onPressed: () {},
  files: const [FrostedUploadFile('blue-fern-receipt.pdf')],
  onRemoved: (_) {},
);

/// When it arrives, each with its fee.
Widget kitSpecimenRadioGroup() => FrostedRadioGroup<String>(
  label: 'Arrives',
  value: 'thu',
  onChanged: (_) {},
  options: const [
    FrostedRadio('now', 'Today', note: r'$1.50 fee'),
    FrostedRadio('thu', 'Thursday', note: 'Free'),
  ],
);

/// Four stars for a visit.
Widget kitSpecimenRating() => Center(
  heightFactor: 1,
  child: FrostedRating(
    value: 4,
    label: 'How was Blue Fern Café?',
    onChanged: (_) {},
  ),
);
