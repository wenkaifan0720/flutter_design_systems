/// Panels and speech above a page, plus live controls that raise each surface.
library;

import 'package:flutter/material.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';

Widget kitRaisedDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Raised panels',
  sections: [
    kitSection('A decision', children: [kitSpecimenDialog()]),
    kitSection('A longer task', children: [kitSpecimenSheet()]),
    kitSection('A choice', children: [kitSpecimenMenu()]),
    kitSection('Choices as you type', children: [kitSpecimenAutocomplete()]),
    kitSection('A small explanation', children: [kitSpecimenTooltip()]),
    kitSection('An announcement', children: [kitSpecimenSnackBar()]),
    kitSection('A toast', children: [kitSpecimenToast()]),
    kitSection('Try them', children: [kitTryRaised()]),
  ],
);

/// Live controls that raise each surface for real: a toast, a dialog, a sheet, a menu, a tooltip and a snack bar.
Widget kitTryRaised() => Builder(
  builder: (context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ComicButton(
        'Toast',
        onPressed: () =>
            showComicToast(context, 'Link copied', tone: ComicTone.success),
      ),
      ComicButton(
        'Dialog',
        onPressed: () => showComicDialog<void>(
          context,
          builder: (context) => ComicDialog(
            title: 'Keep this issue?',
            message: 'It will stay in your collection.',
            // The same decision as the page's own: Later, then the confirming act last.
            actions: [
              ComicButton.text(
                'Later',
                onPressed: () => Navigator.pop(context),
              ),
              ComicButton.filled(
                'Keep',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
      ComicButton(
        'Sheet',
        onPressed: () => showComicBottomSheet<void>(
          context,
          builder: (_) => const ComicBottomSheet(
            title: 'Issue details',
            child: Text('A longer explanation belongs in this panel.'),
          ),
        ),
      ),
      ComicMenuAnchor<String>(
        items: const [
          ComicMenuItem('save', 'Save'),
          ComicMenuItem('share', 'Share'),
        ],
        onSelected: (value) => kitFeedback(
          context,
          value == 'save' ? 'Issue saved.' : 'Share link copied.',
        ),
        builder: (context, open) => ComicButton('Menu', onPressed: open),
      ),
      ComicTooltip(
        message: 'Save this issue to your collection',
        child: Builder(
          builder: (anchor) => ComicButton(
            'Explain',
            onPressed: () {
              final box = anchor.findRenderObject()! as RenderBox;
              showComicTooltip(
                context,
                message: 'Save this issue to your collection',
                anchor: box.localToGlobal(Offset.zero) & box.size,
              );
            },
          ),
        ),
      ),
      ComicButton(
        'Announcement',
        onPressed: () => showComicSnackBar(
          context,
          'Issue saved',
          actionLabel: 'Undo',
          onAction: () => kitFeedback(context, 'Save undone.'),
        ),
      ),
    ],
  ),
);

Widget _raised(Widget child, double height) => SizedBox(
  height: height,
  child: Builder(
    builder: (context) => Stack(
      fit: StackFit.expand,
      children: [
        // This page is inactive under the modal, like a route below a barrier.
        ExcludeSemantics(
          child: Semantics(
            enabled: false,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Your collection\nIssue 12\nIssue 11'),
            ),
          ),
        ),
        ColoredBox(color: ComicTheme.of(context).colors.scrim),
        child,
      ],
    ),
  ),
);
Widget kitSpecimenDialog() => kitState<String?>(
  null,
  (context, value, change) => _raised(
    ComicDialog(
      title: 'Keep this issue?',
      message: value ?? 'Read it again whenever you like.',
      actions: [
        ComicButton.text('Later', onPressed: () => change('Saved for later.')),
        ComicButton.filled(
          'Keep',
          onPressed: () => change('Issue kept in your collection.'),
        ),
      ],
    ),
    340,
  ),
);
Widget kitSpecimenSheet() => kitState(
  true,
  (context, value, change) => value
      ? _raised(
          // A sheet rises from the foot and is as tall as what it holds: the page shows above it, under the scrim.
          Align(
            alignment: Alignment.bottomCenter,
            child: ComicBottomSheet(
              title: 'Issue details',
              onClose: () => change(false),
              child: const Text(
                'A panel for the longer explanation, with room to read and a clear way back.',
              ),
            ),
          ),
          300,
        )
      : ComicButton('Show details', onPressed: () => change(true)),
);
const _cities = [
  'Amsterdam',
  'Athens',
  'Barcelona',
  'Berlin',
  'Bologna',
  'Lisbon',
  'London',
  'Lyon',
  'Madrid',
  'Marseille',
  'Milan',
  'Paris',
  'Porto',
  'Prague',
  'Rome',
  'Vienna',
];

Widget kitSpecimenAutocomplete() => Builder(
  builder: (context) => ComicCombobox<String>(
    label: 'City',
    hint: 'Start typing a city',
    helper: 'A city not on the list says so.',
    options: _cities,
    onSelected: (city) => kitFeedback(context, '$city chosen.'),
  ),
);

Widget kitSpecimenMenu() => Builder(
  builder: (context) => ComicMenu<String>(
    items: const [
      ComicMenuItem('save', 'Save this issue'),
      ComicMenuItem('share', 'Share'),
      ComicMenuItem('print', 'Print', enabled: false),
    ],
    onSelected: (value) => kitFeedback(
      context,
      value == 'save' ? 'Issue saved.' : 'Share link copied.',
    ),
  ),
);
Widget kitSpecimenTooltip() =>
    const ComicTooltipFace(message: 'Save this issue');
Widget kitSpecimenSnackBar() => kitState(
  true,
  (context, value, change) => value
      ? ComicSnackBar(
          'Issue saved to your collection',
          actionLabel: 'Undo',
          onAction: () => change(false),
          onDismiss: () => change(false),
        )
      : ComicButton.text('Save again', onPressed: () => change(true)),
);

Widget kitSpecimenToast() => const Align(
  alignment: AlignmentDirectional.centerStart,
  child: ComicToast('Link copied', tone: ComicTone.success),
);
