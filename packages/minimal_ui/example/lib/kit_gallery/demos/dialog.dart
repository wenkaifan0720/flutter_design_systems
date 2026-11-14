/// The confirm dialog: standing over a dimmed page as it is raised, live
/// over the scrim (confirm, destructive,
/// acknowledge — the answer printed under the buttons), then each card
/// standing in place at its own width, floating as when raised: the plain
/// question, the destructive one, the lone acknowledgement, and a title
/// with no body.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import '../kit.dart';

Widget kitDialogDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Dialog',
  sections: [
    kitSection('Over a page', children: const [_OverPage()]),
    kitSection('Raise one', children: const [_Live()]),
    _standing(
      'Confirm',
      MinimalDialog(
        title: 'Archive Morning run?',
        message:
            'It leaves Today and stops reminding you. Its 12-day streak '
            'and history stay in Habits.',
        confirmLabel: 'Archive',
        cancelLabel: 'Cancel',
        elevated: true,
        onConfirm: () {},
        onCancel: () {},
      ),
    ),
    _standing(
      'Destructive',
      MinimalDialog(
        title: 'Delete HAB-4?',
        message:
            'Morning run and 71 check-ins are deleted. This cannot be '
            'undone.',
        confirmLabel: 'Delete habit',
        cancelLabel: 'Keep',
        destructive: true,
        elevated: true,
        onConfirm: () {},
        onCancel: () {},
      ),
    ),
    _standing(
      'Acknowledge',
      MinimalDialog(
        title: 'Reminder moved',
        message: 'Morning run now reminds you at 07:00 every day.',
        confirmLabel: 'Got it',
        elevated: true,
        onConfirm: () {},
      ),
    ),
    _standing(
      'Title only',
      MinimalDialog(
        title: 'Discard this draft?',
        confirmLabel: 'Discard',
        cancelLabel: 'Keep editing',
        // Discarding loses the work, so the act is destructive.
        destructive: true,
        elevated: true,
        onConfirm: () {},
        onCancel: () {},
      ),
    ),
  ],
);

/// A card in place at its own width on the column's start, floating as it
/// does when raised (a section would stretch it across the column).
Widget _standing(String title, MinimalDialog dialog) => kitSection(
  title,
  children: [Align(alignment: AlignmentDirectional.centerStart, child: dialog)],
);

/// Buttons that raise each register modally and print the answer.
class _Live extends StatefulWidget {
  const _Live();

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  Future<void> _ask(
    String what, {
    required String title,
    String? body,
    required String confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    final confirmed =
        await showMinimalDialog<bool>(
          context,
          builder: (_) => MinimalDialog(
            title: title,
            message: body,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
            destructive: destructive,
          ),
        ) ??
        false;
    if (!mounted || !confirmed) return;
    // A confirmed act says what it did, as the app would.
    showMinimalSnackBar(context, switch (what) {
      'Archive' => 'Morning run archived',
      'Delete' => 'HAB-4 deleted',
      _ => 'Reminder at 07:00',
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      kitRow([
        MinimalButton(
          'Archive',
          variant: MinimalButtonVariant.secondary,
          onPressed: () => _ask(
            'Archive',
            title: 'Archive Morning run?',
            body: 'It leaves Today; its history stays in Habits.',
            confirmLabel: 'Archive',
            cancelLabel: 'Cancel',
          ),
        ),
        // Three triggers, one treatment: each only raises its dialog, and the
        // red belongs to the act inside it, Delete habit.
        MinimalButton(
          'Delete',
          variant: MinimalButtonVariant.secondary,
          onPressed: () => _ask(
            'Delete',
            title: 'Delete HAB-4?',
            body: 'Morning run and its check-ins are deleted.',
            confirmLabel: 'Delete habit',
            cancelLabel: 'Keep',
            destructive: true,
          ),
        ),
        MinimalButton(
          'Acknowledge',
          variant: MinimalButtonVariant.secondary,
          onPressed: () => _ask(
            'Acknowledge',
            title: 'Reminder moved',
            body: 'Morning run now reminds you at 07:00.',
            confirmLabel: 'Got it',
          ),
        ),
      ]),
    ],
  );
}

/// The dialog as it stands when raised: Today's rows under the scrim, the
/// card centred over them. The rows keep the page's gutter and the card
/// stands closer to the frame's edge than that, so every row it crosses
/// hides whole under it, as on a phone — no clipped letters either side.
/// The frame is the rows' own height: whole rows, the last closed by the
/// frame's edge, no band under it.
class _OverPage extends StatelessWidget {
  const _OverPage();

  static const _habits = [
    ('Meditate', '4d'),
    ('Morning run', '12d'),
    ('Drink water', '10d'),
    ('Journal', '3d'),
    ('Read 20 pages', '6d'),
    ('Water the plants', '2d'),
    ('Stretch before bed', '5d'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: t.background,
        shape: t.shapes.medium.copyWith(
          side: BorderSide(color: t.border, width: t.hairline),
        ),
      ),
      // The rows size the frame; the scrim and the card stand over them.
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, (name, streak)) in _habits.indexed)
                Container(
                  height: t.rowHeight,
                  padding: MinimalInsets.gutter,
                  decoration: BoxDecoration(
                    border: i == _habits.length - 1
                        ? null
                        : Border(bottom: t.rule),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: t.body.medium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(streak, style: t.mono.c(t.mutedForeground)),
                    ],
                  ),
                ),
            ],
          ),
          Positioned.fill(child: ColoredBox(color: t.overlay)),
          Positioned.fill(
            child: Center(
              // The screen's gutter at its sides, as showMinimalDialog
              // stands it.
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinimalChromeMetrics.gutter,
                  vertical: MinimalSpacing.s16,
                ),
                child: MinimalDialog(
                  title: 'Delete Morning run?',
                  message: 'Its 71 check-ins go with it.',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  destructive: true,
                  // It stands for the raised card, so it floats like one.
                  elevated: true,
                  onConfirm: () {},
                  onCancel: () {},
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`): the raised card over the dimmed page, as showMinimalDialog
// stands it. The stage (kitSpecimenStage) styles it; a builder never names
// a style.

/// The destructive question: the confirm in the danger fill.
Widget kitSpecimenDialogDestructive() => _Raised(
  MinimalDialog(
    title: 'Delete HAB-4?',
    message: 'Morning run and 71 check-ins are deleted. This cannot be undone.',
    confirmLabel: 'Delete habit',
    cancelLabel: 'Keep',
    destructive: true,
    elevated: true,
    onConfirm: () {},
    onCancel: () {},
  ),
);

/// A question with its cancel and its confirm.
Widget kitSpecimenDialogConfirm() => _Raised(
  MinimalDialog(
    title: 'Archive Morning run?',
    message:
        'It leaves Today and stops reminding you. Its 12-day streak and '
        'history stay in Habits.',
    confirmLabel: 'Archive',
    cancelLabel: 'Cancel',
    elevated: true,
    onConfirm: () {},
    onCancel: () {},
  ),
);

/// An acknowledgement: one button, nothing to decide.
Widget kitSpecimenDialogAcknowledge() => _Raised(
  MinimalDialog(
    title: 'Reminder moved',
    message: 'Morning run now reminds you at 07:00 every day.',
    confirmLabel: 'Got it',
    elevated: true,
    onConfirm: () {},
  ),
);

/// Stands a dialog card where [showMinimalDialog] raises it: centred on the
/// gutter inside the safe area, over the dimmed page.
class _Raised extends StatelessWidget {
  const _Raised(this.card);

  final Widget card;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.minimalTheme.overlay,
    child: SafeArea(
      child: Center(
        child: Padding(padding: MinimalInsets.gutter, child: card),
      ),
    ),
  );
}
