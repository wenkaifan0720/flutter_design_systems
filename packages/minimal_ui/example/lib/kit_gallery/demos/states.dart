/// The three render states a page can be in besides loaded — waiting,
/// failed, empty — each in the frame it would fill, and the toast a page
/// confirms with, plain and with its one undo.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitStatesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'States & toast',
  sections: [
    kitSection(
      'Toast',
      children: [
        // At the width they float at: at most 560, on the column's start.
        const _AsFloated(
          MinimalSnackBar(
            'Morning run marked done',
            icon: LucideIcons.circleCheck,
          ),
        ),
        _AsFloated(
          MinimalSnackBar(
            'Habit archived',
            icon: LucideIcons.archive,
            actionLabel: 'Undo',
            onAction: () {},
          ),
        ),
        kitNote(
          'A toast floats above the tab bar for a moment; with an undo it '
          'stays longer. Try them live:',
        ),
        Builder(
          builder: (context) => kitRow([
            MinimalButton(
              'Show toast',
              variant: MinimalButtonVariant.secondary,
              onPressed: () => showMinimalSnackBar(
                context,
                'Morning run marked done',
                icon: LucideIcons.circleCheck,
              ),
            ),
            MinimalButton(
              'With undo',
              variant: MinimalButtonVariant.secondary,
              onPressed: () => showMinimalSnackBar(
                context,
                'Habit archived',
                icon: LucideIcons.archive,
                actionLabel: 'Undo',
                onAction: () {},
              ),
            ),
          ]),
        ),
      ],
    ),
    kitSection(
      'Loading',
      children: const [
        _Frame(child: MinimalLoadingState(message: 'Loading habits')),
      ],
    ),
    kitSection(
      'Error',
      children: [
        _Frame(
          child: MinimalErrorState(
            title: 'Could not sync',
            message:
                'The last change is saved on this device. Check your '
                'connection and try again.',
            onRetry: () {},
          ),
        ),
      ],
    ),
    kitSection(
      'Empty',
      children: [
        _Frame(
          child: MinimalEmptyState(
            icon: LucideIcons.inbox,
            title: 'No habits yet',
            body: 'Habits you add show up here, grouped by the time of day.',
            actionLabel: 'New habit',
            onAction: () {},
          ),
        ),
      ],
    ),
    kitSection(
      'Success, by name',
      children: [
        _Frame(child: kitSpecimenStatusViewSuccess()),
        kitNote(
          'One status view draws all four states: loading, error, empty and '
          'success.',
        ),
      ],
    ),
  ],
);

/// The region a state fills, outlined so its centring reads; it grows
/// with the text scale rather than clipping the state.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      decoration: ShapeDecoration(
        shape: t.shapes.medium.copyWith(
          side: BorderSide(color: t.border, width: t.hairline),
        ),
      ),
      child: child,
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style. showMinimalSnackBar presents MinimalSnackBar, so
// its specimens build the card.

/// The still loading state of a page that waits.
Widget kitSpecimenLoadingState() =>
    const MinimalLoadingState(message: 'Loading habits');

/// A failure with its retry.
Widget kitSpecimenErrorStateRetry() => MinimalErrorState(
  title: 'Could not sync',
  message:
      'The last change is saved on this device. Check your connection and '
      'try again.',
  onRetry: () {},
);

/// Nothing listed yet, with the next action.
Widget kitSpecimenEmptyStateAction() => MinimalEmptyState(
  icon: LucideIcons.inbox,
  title: 'No habits yet',
  body: 'Habits you add show up here, grouped by the time of day.',
  actionLabel: 'New habit',
  onAction: () {},
);

/// A toast shown in place at the width the toaster floats it at: at most
/// 560 px, on the column's start.
class _AsFloated extends StatelessWidget {
  const _AsFloated(this.toast);

  final Widget toast;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: toast,
    ),
  );
}

/// A confirmation with its undo, in the accent's ink.
Widget kitSpecimenToastUndo() => MinimalSnackBar(
  'Habit archived',
  icon: LucideIcons.archive,
  actionLabel: 'Undo',
  onAction: () {},
);

/// A plain confirmation.
Widget kitSpecimenToastPlain() => const MinimalSnackBar(
  'Morning run marked done',
  icon: LucideIcons.circleCheck,
);

/// A finished invite.
Widget kitSpecimenStatusViewSuccess() => MinimalStatusView.success(
  title: 'Invite sent',
  message: 'Ana will get an email in a minute.',
  actionLabel: 'Done',
  onAction: () {},
);
