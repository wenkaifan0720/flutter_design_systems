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
  measured: true,
  title: kitSay('States & toast'),
  sections: [
    kitSection(
      kitSay('Toast, raised'),
      children: [
        Builder(
          builder: (context) => kitRow([
            FrostedButton.glass(
              kitSay('Move to Groceries'),
              onPressed: () => FrostedToast.show(
                context,
                kitSay('Moved to Groceries'),
                actionLabel: kitSay('Undo'),
                onAction: () {},
              ),
            ),
            FrostedButton.glass(
              kitSay('Copy card number'),
              icon: LucideIcons.copy,
              onPressed: () => FrostedToast.show(
                context,
                kitSay('Card number copied'),
                icon: LucideIcons.copy,
              ),
            ),
          ]),
        ),
      ],
    ),
    kitSection(
      kitSay('Toast, in place'),
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

Widget kitSpecimenToastMoved() => FrostedSnackBar(
  kitSay('Moved to Groceries'),
  actionLabel: kitSay('Undo'),
  onAction: () {},
);

Widget kitSpecimenToastCopied() =>
    FrostedSnackBar(kitSay('Card number copied'), icon: LucideIcons.copy);

Widget kitSpecimenToastSent() =>
    FrostedSnackBar(kitSay('Request sent to Jonah'), icon: FrostedGlyphs.send);

Widget kitSpecimenLoadingState() =>
    FrostedLoadingState(message: kitSay('Loading your accounts'));

Widget kitSpecimenErrorState() => FrostedErrorState(
  title: kitSay("Couldn't load your accounts"),
  message: kitSay('Check your connection, then try again.'),
  onRetry: () {},
);

/// No results, as the source's search draws it: the prism over its beam
/// on a glass tile with the spectrum rim, and Clear filters.
Widget kitSpecimenEmptyState() => FrostedEmptyState(
  title: kitSay('No results for “sushi”'),
  body: kitSay(
    'Nothing in October matches the Money in filter. Clear filters to search every transaction.',
  ),
  actionLabel: kitSay('Clear filters'),
  actionIcon: LucideIcons.x,
  onAction: () {},
);

/// A transfer sent.
Widget kitSpecimenStatusView() => FrostedStatusView.success(
  title: kitSay('Transfer sent'),
  message: kitSay(r'$500.00 to Jonah Reyes arrives Thursday.'),
);
