// The answers summary: what the reader said, set out to check, each with
// the way back to change it.
import 'package:flutter/material.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitAnswersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Answers summary',
  intro:
      'What was asked in bold, the answer beside it, Change at the end. '
      'Below 560 wide the three stand one under another.',
  sections: [
    KitSection(
      title: 'Your details',
      children: [
        CivicSummaryList(
          rows: [
            for (final (label, value) in const [
              ('Name', 'Amara Okafor'),
              ('Date of birth', '27 March 1987'),
              ('Address', '14 Ropewalk Row\nBrindlemere\nBR4 7QX'),
              ('Vehicle', 'Car or van'),
            ])
              CivicSummaryRow(
                label: label,
                value: Text(value),
                actionLabel: 'Change',
                actionSemanticLabel: 'Change ${label.toLowerCase()}',
                onActionPressed: () {},
              ),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'A card for each vehicle',
      children: [
        CivicSummaryCard(
          title: 'Vehicle 1',
          actions: [
            CivicLink(
              onPressed: () {},
              semanticLabel: 'Remove vehicle 1',
              child: const Text('Remove'),
            ),
          ],
          child: const CivicSummaryList(
            rows: [
              CivicSummaryRow(label: 'Registration', value: Text('BR21 KXT')),
              CivicSummaryRow(label: 'Make', value: Text('Hatchback, blue')),
            ],
          ),
        ),
      ],
    ),
  ],
);
