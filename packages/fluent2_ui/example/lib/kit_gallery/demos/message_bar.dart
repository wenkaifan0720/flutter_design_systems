/// Fluent 2's MessageBar: its four intents, a title before the body,
/// actions after it (laid on one line while they fit and under the body
/// when not), dismissible, the square cut for an edge, and a bar that
/// goes when dismissed.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

Widget kitMessageBarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Message bar',
  sections: [
    kitSection('Intents', children: [kitSpecimenMessageBarIntents()]),
    kitSection('With actions', children: [kitSpecimenMessageBarActions()]),
    kitSection(
      'Multiline',
      children: [
        Fluent2MessageBar(
          title: 'Storage almost full',
          body:
              'Northwind has used 9.4 GB of its 10 GB. Uploads will pause '
              'when the space runs out; archive old files or add storage.',
          intent: Fluent2MessageIntent.warning,
          layout: Fluent2MessageLayout.multiline,
          actions: [
            Fluent2Button(
              'Add storage',
              size: Fluent2ButtonSize.small,
              onPressed: () {},
            ),
            Fluent2Button(
              'Review files',
              size: Fluent2ButtonSize.small,
              appearance: Fluent2ButtonAppearance.subtle,
              onPressed: () {},
            ),
          ],
          onDismiss: () {},
        ),
      ],
    ),
    kitSection('Square, at an edge', children: [kitSpecimenMessageBarSquare()]),
    kitSection('Dismissible', children: [const _Dismissible()]),
  ],
);

/// The four intents, each with a title.
Widget kitSpecimenMessageBarIntents() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.s,
  children: const [
    Fluent2MessageBar(
      title: 'Sync paused',
      body: 'Files will sync again when you reconnect.',
    ),
    Fluent2MessageBar(
      title: 'Shared',
      body: 'Launch plan.docx is now shared with Design.',
      intent: Fluent2MessageIntent.success,
    ),
    Fluent2MessageBar(
      title: 'Due today',
      body: 'Review the Q4 deck before 5 PM.',
      intent: Fluent2MessageIntent.warning,
    ),
    Fluent2MessageBar(
      title: 'Upload failed',
      body: 'Budget.xlsx is larger than 250 MB.',
      intent: Fluent2MessageIntent.error,
    ),
  ],
);

/// An invitation with its actions and a dismiss.
Widget kitSpecimenMessageBarActions() => Fluent2MessageBar(
  body: 'Priya Raman invited you to the Design channel.',
  actions: [
    Fluent2Button('Join', size: Fluent2ButtonSize.small, onPressed: () {}),
    Fluent2Button(
      'Not now',
      size: Fluent2ButtonSize.small,
      appearance: Fluent2ButtonAppearance.subtle,
      onPressed: () {},
    ),
  ],
  onDismiss: () {},
);

/// The square cut a page sets across its top edge.
Widget kitSpecimenMessageBarSquare() => Fluent2MessageBar(
  body: 'You are viewing an older version of Launch plan.docx.',
  square: true,
  icon: Fluent2Icons.history,
  actions: [
    Fluent2Button('Restore', size: Fluent2ButtonSize.small, onPressed: () {}),
  ],
);

class _Dismissible extends StatefulWidget {
  const _Dismissible();

  @override
  State<_Dismissible> createState() => _DismissibleState();
}

class _DismissibleState extends State<_Dismissible> {
  bool _shown = true;

  @override
  Widget build(BuildContext context) => _shown
      ? Fluent2MessageBar(
          body: 'Tomas Lindqvist left a comment on your file.',
          intent: Fluent2MessageIntent.info,
          onDismiss: () => setState(() => _shown = false),
        )
      : Align(
          alignment: AlignmentDirectional.centerStart,
          child: Fluent2Button(
            'Show again',
            appearance: Fluent2ButtonAppearance.subtle,
            onPressed: () => setState(() => _shown = true),
          ),
        );
}
