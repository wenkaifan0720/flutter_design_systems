/// The toast group's demo: the snackbar inline in every layout — one line,
/// with an action, with the close button, two lines, the action on its own
/// line — then the live toasts: raised over the page, queued one after
/// another, and one that waits for its close button.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The toast group's demo, in [brightness].
Widget kitToastDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Toast',
  sections: const <Widget>[_OneLine(), _TwoLines(), _NewLine(), _Live()],
);

void _none() {}

/// A section of snackbars, each at its own width (at most the container's
/// 600dp) from the column's start, as a host raises them: a stretched bar
/// would leave its action stranded mid-column.
Widget _bars(String label, List<Widget> bars) => kitSection(
  label,
  children: <Widget>[
    for (final bar in bars)
      Align(alignment: AlignmentDirectional.centerStart, child: bar),
  ],
);

class _OneLine extends StatelessWidget {
  const _OneLine();

  @override
  Widget build(BuildContext context) => _bars('Single line', const <Widget>[
    ExpressiveSnackBar('Draft saved'),
    ExpressiveSnackBar(
      'Photo moved to the archive',
      actionLabel: 'Undo',
      onAction: _none,
    ),
    ExpressiveSnackBar(
      'Back online',
      actionLabel: 'Refresh',
      onAction: _none,
      withDismissAction: true,
      onDismiss: _none,
    ),
    ExpressiveSnackBar(
      'Offline mode is on',
      withDismissAction: true,
      onDismiss: _none,
    ),
  ]);
}

class _TwoLines extends StatelessWidget {
  const _TwoLines();

  @override
  Widget build(BuildContext context) => _bars('Two lines', const <Widget>[
    ExpressiveSnackBar(
      'Evening Run was shared with Priya, Tomás and two others from the '
      'Thursday running club',
      actionLabel: 'View',
      onAction: _none,
    ),
    ExpressiveSnackBar(
      'Your weekly summary is ready. It covers seven days of sleep, steps '
      'and movement, and how they compare with last week.',
      withDismissAction: true,
      onDismiss: _none,
    ),
  ]);
}

class _NewLine extends StatelessWidget {
  const _NewLine();

  @override
  Widget build(BuildContext context) =>
      _bars('Action on its own line', const <Widget>[
        ExpressiveSnackBar(
          'Two of your notes changed on another device while you were editing',
          actionLabel: 'Review changes',
          onAction: _none,
          actionOnNewLine: true,
        ),
        ExpressiveSnackBar(
          'Storage is almost full: 14.6 of 15 GB used',
          actionLabel: 'Free up space',
          onAction: _none,
          withDismissAction: true,
          onDismiss: _none,
          actionOnNewLine: true,
        ),
      ]);
}

class _Live extends StatelessWidget {
  const _Live();

  @override
  Widget build(BuildContext context) => kitSection(
    'Live',
    children: <Widget>[
      Wrap(
        spacing: kitGap,
        runSpacing: kitGap,
        children: <Widget>[
          ExpressiveFilledButton.tonal(
            'Save draft',
            onPressed: () => showExpressiveSnackBar(context, 'Draft saved'),
          ),
          ExpressiveFilledButton.tonal(
            'Archive',
            onPressed: () => showExpressiveSnackBar(
              context,
              'Photo moved to the archive',
              actionLabel: 'Undo',
              onAction: () => showExpressiveSnackBar(context, 'Photo restored'),
            ),
          ),
          ExpressiveFilledButton.tonal(
            'Queue three',
            onPressed: () {
              for (final message in const <String>[
                'Uploading 3 photos',
                'Upload finished',
                'Album shared with Priya',
              ]) {
                showExpressiveSnackBar(context, message);
              }
            },
          ),
          ExpressiveFilledButton.tonal(
            'Until closed',
            onPressed: () => showExpressiveSnackBar(
              context,
              'Sync paused while on mobile data',
              actionLabel: 'Resume',
              onAction: _none,
              withDismissAction: true,
              duration: ExpressiveSnackBarDuration.indefinite,
            ),
          ),
        ],
      ),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// A confirmation with its undo, as the toast shows it.
Widget kitSpecimenToastUndo() => const ExpressiveSnackBar(
  'Photo moved to the archive',
  actionLabel: 'Undo',
  onAction: _none,
);
