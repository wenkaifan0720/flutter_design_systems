// The dialog, the sheets, the command palette and the toast, open as a
// page shows them.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitOverlaysDemo(Brightness brightness) =>
    kitApp(brightness: brightness, home: const _Overlays());

class _Overlays extends StatelessWidget {
  const _Overlays();

  @override
  Widget build(BuildContext context) => CivicScaffold(
    topBar: const CivicTopBar(title: 'Civic', emblem: KitEmblem()),
    body: CivicPageBody(
      title: 'Dialog, sheets, palette & toast',
      children: [
        const Text(
          'A dialog stops the page for one question; a sheet holds a short '
          'task beside the page; the palette finds a page or an action that '
          'is also in sight; a toast says something happened, and the page '
          'says it too.',
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
            onPressed: () => showCivicBottomSheet<void>(
              context: context,
              title: 'Filter applications',
              builder: (context) => const _Filters(),
              actions: [
                CivicButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Show applications'),
                ),
              ],
            ),
            child: const Text('Open a bottom sheet'),
          ),
        ),
        const SizedBox(height: CivicSpacing.s16),
        Builder(
          builder: (context) => CivicButton.secondary(
            onPressed: () => showCivicSideSheet<void>(
              context: context,
              title: 'Filter applications',
              builder: (context) => const _Filters(),
              actions: [
                CivicButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Show applications'),
                ),
              ],
            ),
            child: const Text('Open a side sheet'),
          ),
        ),
        const SizedBox(height: CivicSpacing.s16),
        Builder(
          builder: (context) => CivicButton.secondary(
            onPressed: () => showCivicActionSheet<String>(
              context: context,
              title: 'Application BRM-4821-K',
              message: 'Resident permit, Zone C',
              actions: const [
                CivicActionSheetAction(
                  value: 'print',
                  label: 'Print your answers',
                  icon: LucideIcons.printer,
                ),
                CivicActionSheetAction(
                  value: 'download',
                  label: 'Download a copy',
                  icon: LucideIcons.download,
                ),
                CivicActionSheetAction(
                  value: 'withdraw',
                  label: 'Withdraw application',
                  isDestructiveAction: true,
                ),
              ],
            ),
            child: const Text('Open an action sheet'),
          ),
        ),
        const SizedBox(height: CivicSpacing.s16),
        Builder(
          builder: (context) => CivicButton.secondary(
            onPressed: () => showCivicCommandPalette(
              context: context,
              commands: [
                for (final (label, group, keys) in [
                  ('Your applications', 'Pages', null),
                  ('Your permits', 'Pages', null),
                  ('Contact the council', 'Pages', null),
                  ('Apply for a permit', 'Actions', null),
                  // The browser's own print keys, as the platform names them.
                  (
                    'Print this page',
                    'Actions',
                    switch (defaultTargetPlatform) {
                      TargetPlatform.macOS || TargetPlatform.iOS => '⌘ P',
                      _ => 'Ctrl P',
                    },
                  ),
                ])
                  DesignCommand(
                    label: label,
                    group: group,
                    shortcut: keys,
                    onPressed: () {},
                  ),
              ],
            ),
            child: const Text('Find a page or action'),
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

class _Filters extends StatefulWidget {
  const _Filters();

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  final Set<String> _shown = {'In progress'};

  @override
  Widget build(BuildContext context) => CivicFieldset(
    labelText: 'Status',
    children: [
      for (final status in const ['In progress', 'Approved', 'Refused'])
        CivicCheckbox(
          value: _shown.contains(status),
          labelText: status,
          onChanged: (on) => setState(
            () => on == true ? _shown.add(status) : _shown.remove(status),
          ),
        ),
    ],
  );
}
