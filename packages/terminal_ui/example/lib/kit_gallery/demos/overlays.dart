/// Over the screen: [TermDialog] and [showTermDialog], the y/N question
/// ([TermConfirmDialog], [showTermConfirmDialog]) with its typed guard, the
/// toast ([TermToaster], [TermToast], [TermTone]), and what a terminal
/// shows while it works: [TermSpinner], [TermProgressBar] and [TermCaret].
library;

import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../kit.dart';

Widget kitOverlaysDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'overlays & progress',
  sections: [
    kitSection(
      'a dialog, in place',
      children: [
        TermDialog(
          title: 'discard changes',
          footer: 'esc keep',
          content: const Text('the config has edits that are not saved.'),
          actions: [
            TermButton(label: 'keep', onPressed: () {}),
            TermButton.filled(
              label: 'discard',
              isDestructiveAction: true,
              onPressed: () {},
            ),
          ],
        ),
      ],
    ),
    kitSection('raise one', children: [const _Raise()]),
    kitSection('working', children: [const _Working()]),
  ],
);

class _Raise extends StatelessWidget {
  const _Raise();

  @override
  Widget build(BuildContext context) => kitRow([
    TermButton(
      label: 'deploy to production',
      onPressed: () => showTermConfirmDialog(
        context: context,
        title: 'deploy to production',
        message: 'atlas-api feat/rate-limits → production.',
        confirmLabel: 'deploy',
      ),
    ),
    TermButton(
      label: 'delete project',
      isDestructiveAction: true,
      onPressed: () => showTermConfirmDialog(
        context: context,
        title: 'delete project',
        message: 'atlas-api and its 1482 runs go for good.',
        confirmLabel: 'delete',
        isDestructiveAction: true,
        typedConfirmation: 'atlas-api',
      ),
    ),
    TermButton(
      label: 'about',
      onPressed: () => showTermDialog<void>(
        context: context,
        builder: (context) => TermDialog(
          title: 'slipway',
          footer: 'esc close',
          content: const Text('a deploy console, drawn on a character grid.'),
          actions: [
            TermButton.filled(
              label: 'ok',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
    TermButton(
      label: 'toast',
      onPressed: () => TermToaster.show(
        context,
        message: 'deploy #1490 queued',
        tone: TermTone.success,
        actionLabel: 'watch',
        onAction: () {},
      ),
    ),
  ]);
}

class _Working extends StatelessWidget {
  const _Working();

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const TermSpinner(),
            SizedBox(width: grid.cellWidth),
            const Flexible(child: Text('building the image')),
          ],
        ),
        const TermProgressBar(value: 0.42, semanticLabel: 'upload'),
        const TermProgressBar(
          value: null,
          semanticLabel: 'waiting for a runner',
        ),
        Row(
          children: [
            Text(r'$ slipway deploy ', style: TermTheme.of(context).textStyle),
            const TermCaret(),
          ],
        ),
        // The glyph in a cell of its own, so it stands first right to left
        // too, whatever letters the glyph and the name are.
        for (final tone in TermTone.values)
          DefaultTextStyle.merge(
            style: TermTheme.of(context).textStyle
                .copyWith(color: tone.colorIn(TermTheme.of(context))),
            child: Row(
              children: [
                Text(tone.glyph),
                SizedBox(width: grid.cellWidth),
                Text(tone.name),
              ],
            ),
          ),
      ],
    );
  }
}
