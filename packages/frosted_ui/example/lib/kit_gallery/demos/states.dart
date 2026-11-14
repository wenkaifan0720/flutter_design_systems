/// What a page shows while it waits, when it fails and when it has nothing
/// ([FrostedLoadingState], [FrostedErrorState], [FrostedEmptyState] with its
/// [FrostedSpectrumArt]), and the toast: [FrostedToast.show] raising one live over
/// the page, and its slab ([FrostedSnackBar]) drawn in place.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitStatesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'States & toast',
  sections: [
    kitSection(
      'Toast, raised',
      children: [
        Builder(
          builder: (context) => kitRow([
            FrostedButton.glass(
              'Move to Groceries',
              onPressed: () => FrostedToast.show(
                context,
                'Moved to Groceries',
                actionLabel: 'Undo',
                onAction: () {},
              ),
            ),
            FrostedButton.glass(
              'Copy card number',
              icon: LucideIcons.copy,
              onPressed: () => FrostedToast.show(
                context,
                'Card number copied',
                icon: LucideIcons.copy,
              ),
            ),
          ]),
        ),
      ],
    ),
    kitSection(
      'Toast, in place',
      children: [
        kitSpecimenToastMoved(),
        kitSpecimenToastCopied(),
        kitSpecimenToastSent(),
      ],
    ),
    kitSection('Loading', children: [kitSpecimenLoadingState()]),
    kitSection('Error', children: [kitSpecimenErrorState()]),
    kitSection('Empty', children: [kitSpecimenEmptyState()]),
  ],
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

Widget kitSpecimenToastMoved() =>
    FrostedSnackBar('Moved to Groceries', actionLabel: 'Undo', onAction: () {});

Widget kitSpecimenToastCopied() =>
    const FrostedSnackBar('Card number copied', icon: LucideIcons.copy);

Widget kitSpecimenToastSent() =>
    const FrostedSnackBar('Request sent to Jonah', icon: LucideIcons.send);

Widget kitSpecimenLoadingState() =>
    const FrostedLoadingState(message: 'Loading your accounts');

Widget kitSpecimenErrorState() => FrostedErrorState(
  title: "Couldn't load your accounts",
  message: 'Check your connection, then try again.',
  onRetry: () {},
);

/// No results, as the source's search draws it: the prism over its beam
/// on a glass tile with the spectrum rim, and Clear filters.
Widget kitSpecimenEmptyState() => FrostedEmptyState(
  title: 'No results for “sushi”',
  body:
      'Nothing in October matches with the Money in filter on. Clear '
      'filters to search every transaction.',
  actionLabel: 'Clear filters',
  actionIcon: LucideIcons.x,
  onAction: () {},
);

/// A transfer sent.
Widget kitSpecimenStatusView() => const FrostedStatusView.success(
  title: 'Transfer sent',
  message: r'$500.00 to Jonah Reyes arrives Thursday.',
);
