// The dialog and the toast, open as a page shows them.
import 'package:flutter/material.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitOverlaysDemo(Brightness brightness) =>
    kitApp(brightness: brightness, home: const _Overlays());

class _Overlays extends StatelessWidget {
  const _Overlays();

  @override
  Widget build(BuildContext context) => CivicScaffold(
    topBar: const CivicTopBar(title: 'Civic', emblem: KitEmblem()),
    body: CivicPageBody(
      title: 'Dialog & toast',
      children: [
        const Text(
          'A dialog stops the page for one question; a toast says something '
          'happened, and the page says it too.',
        ),
        const SizedBox(height: CivicSpacing.s32),
        Builder(
          builder: (context) => CivicButton.secondary(
            onPressed: () => showCivicDialog<void>(
              context: context,
              builder: (context) => const _Cancel(),
            ),
            child: const Text('Open the dialog'),
          ),
        ),
        const SizedBox(height: CivicSpacing.s16),
        Builder(
          builder: (context) => CivicButton.secondary(
            onPressed: () =>
                CivicToast.show(context, 'Your answers have been saved'),
            child: const Text('Show a toast'),
          ),
        ),
        const SizedBox(height: CivicSpacing.s48),
        const CivicSectionHeader(title: 'The dialog, open'),
        const _Cancel(),
      ],
    ),
  );
}

class _Cancel extends StatelessWidget {
  const _Cancel();

  @override
  Widget build(BuildContext context) => CivicDialog(
    title: 'Cancel your application?',
    content: const Text(
      'You will lose the answers you have given. You can start again at any '
      'time.',
    ),
    actions: [
      CivicButton(
        onPressed: () => Navigator.of(context).maybePop(),
        isDestructiveAction: true,
        child: const Text('Cancel application'),
      ),
      CivicButton.secondary(
        onPressed: () => Navigator.of(context).maybePop(),
        child: const Text('Keep my answers'),
      ),
    ],
  );
}
