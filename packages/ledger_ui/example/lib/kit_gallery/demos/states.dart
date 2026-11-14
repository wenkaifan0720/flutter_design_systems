/// What a page shows while it waits, when it fails and when it has nothing
/// ([LedgerLoadingState], [LedgerErrorState], [LedgerEmptyState]: the blank
/// ledger page, with its seal when it is empty), and the toast:
/// [LedgerToast.show] raising one live over the page, and its card
/// ([LedgerToastCard]) drawn in place.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
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
            LedgerButton(
              'Move to Groceries',
              onPressed: () => LedgerToast.show(
                context,
                'Moved to Groceries',
                actionLabel: 'Undo',
                onActionPressed: () {},
              ),
            ),
            LedgerButton(
              'Copy card number',
              icon: LucideIcons.copy,
              onPressed: () => LedgerToast.show(
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
        // At the width a toast is raised at, never the column's: a slip, not
        // a banner.
        for (final toast in [
          kitSpecimenToastMoved(),
          kitSpecimenToastCopied(),
          kitSpecimenToastSent(),
        ])
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: LedgerChromeMetrics.toastWidth,
              ),
              child: toast,
            ),
          ),
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

Widget kitSpecimenToastMoved() => LedgerToastCard(
  'Moved to Groceries',
  actionLabel: 'Undo',
  onActionPressed: () {},
);

Widget kitSpecimenToastCopied() =>
    const LedgerToastCard('Card number copied', icon: LucideIcons.copy);

Widget kitSpecimenToastSent() =>
    const LedgerToastCard('Request sent to Jonah', icon: LucideIcons.send);

Widget kitSpecimenLoadingState() =>
    const LedgerLoadingState(message: 'Loading activity');

Widget kitSpecimenErrorState() => LedgerErrorState(
  title: 'Activity didn’t load',
  message: 'Check your connection and try again.',
  onRetryPressed: () {},
);

/// The source's empty search (the sample data's search example, with the
/// Money in filter on).
Widget kitSpecimenEmptyState() => LedgerEmptyState(
  title: 'Nothing for',
  titleItalic: '“sushi”',
  body:
      'With the Money in filter on, nothing in October matches. Clear the filters to '
      'search all of it, or browse a category instead.',
  seal: const LedgerSeal(
    kicker: 'Search',
    value: 'No\nentries',
    foot: 'October',
    tone: LedgerSealTone.plain,
  ),
  actionLabel: 'Clear filters',
  actionIcon: LucideIcons.x,
  onActionPressed: () {},
);
