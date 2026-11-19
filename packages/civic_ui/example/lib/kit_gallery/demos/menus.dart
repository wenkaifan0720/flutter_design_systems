// Menus, a split button, a popover and tooltips: what opens beside a
// control on a press or the keys, never on a hover alone, each action also
// in sight on the page.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitMenusDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Menus, popovers & tooltips',
  intro:
      'A menu gathers lesser actions that are also on the page. A pointer '
      'greys a row; the keys move the yellow plate.',
  sections: const [_Menus(), _Split(), _Popover(), _Tips()],
);

class _Menus extends StatefulWidget {
  const _Menus();

  @override
  State<_Menus> createState() => _MenusState();
}

class _MenusState extends State<_Menus> {
  String? _done;

  @override
  Widget build(BuildContext context) {
    final done = _done;
    return KitSection(
      title: 'Menu',
      caption:
          'Opened by a press, Enter or Space. Up and Down move through it; '
          'Escape closes it.',
      children: [
        Wrap(
          spacing: CivicSpacing.s16,
          runSpacing: CivicSpacing.s16,
          children: [
            CivicMenu<String>(
              semanticLabel: 'Application actions',
              items: [
                CivicMenuItem(
                  value: 'Print your answers',
                  label: 'Print your answers',
                  icon: LucideIcons.printer,
                  // The browser's own print keys, as the platform names them.
                  trailing: switch (defaultTargetPlatform) {
                    TargetPlatform.macOS || TargetPlatform.iOS => '⌘ P',
                    _ => 'Ctrl P',
                  },
                ),
                const CivicMenuItem(
                  value: 'Download a copy',
                  label: 'Download a copy',
                  icon: LucideIcons.download,
                ),
                const CivicMenuItem(
                  value: 'Change your vehicle',
                  label: 'Change your vehicle',
                  enabled: false,
                ),
                const CivicMenuItem(
                  value: 'Withdraw application',
                  label: 'Withdraw application',
                  isDestructiveAction: true,
                  startsGroup: true,
                ),
              ],
              onSelected: (action) => setState(() => _done = action),
              builder: (context, anchor) => CivicButton.secondary(
                onPressed: anchor.toggle,
                icon: anchor.isOpen
                    ? LucideIcons.chevronUp
                    : LucideIcons.chevronDown,
                child: const Text('Actions'),
              ),
            ),
          ],
        ),
        if (done != null)
          Semantics(liveRegion: true, child: Text('You chose: $done.')),
      ],
    );
  }
}

class _Split extends StatefulWidget {
  const _Split();

  @override
  State<_Split> createState() => _SplitState();
}

class _SplitState extends State<_Split> {
  String? _done;

  void _say(String words) => setState(() => _done = words);

  @override
  Widget build(BuildContext context) {
    final done = _done;
    return KitSection(
      title: 'Split button',
      caption:
          'The action and, joined to it, the chevron that opens the actions '
          'like it. Two buttons, two tab stops.',
      children: [
        CivicSplitButton(
          label: 'Send application',
          onPressed: () => _say('Send application'),
          actions: [
            CivicSplitAction(
              'Save and come back later',
              onPressed: () => _say('Save and come back later'),
            ),
            CivicSplitAction(
              'Print your answers',
              icon: LucideIcons.printer,
              onPressed: () => _say('Print your answers'),
            ),
          ],
        ),
        CivicSplitButton.secondary(
          label: 'Download',
          menuLabel: 'More ways to download',
          onPressed: () => _say('Download'),
          actions: [
            CivicSplitAction('As a PDF', onPressed: () => _say('As a PDF')),
            CivicSplitAction(
              'As a spreadsheet',
              onPressed: () => _say('As a spreadsheet'),
            ),
          ],
        ),
        if (done != null)
          Semantics(liveRegion: true, child: Text('You chose: $done.')),
      ],
    );
  }
}

class _Popover extends StatelessWidget {
  const _Popover();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Popover',
    caption:
        'A little more, beside its link. The focus moves into it and back '
        'when it closes. Nothing opens on a hover.',
    children: [
      CivicPopover(
        title: 'Who counts as a visitor',
        content: const Text(
          'Anyone staying less than 14 days who does not live at the '
          'address. A carer is not a visitor: apply for a carer’s permit.',
        ),
        builder: (context, anchor) => CivicLink(
          onPressed: anchor.toggle,
          child: const Text('Who counts as a visitor?'),
        ),
      ),
    ],
  );
}

class _Tips extends StatelessWidget {
  const _Tips();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Tooltips',
    caption:
        'A glyph’s name, on a pointer’s rest, the keyboard’s focus or a '
        'long press. It names; it never says what the page must.',
    children: [
      Wrap(
        spacing: CivicSpacing.s8,
        runSpacing: CivicSpacing.s8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CivicIconButton(
            icon: LucideIcons.printer,
            semanticLabel: 'Print this page',
            tooltip: 'Print this page',
            onPressed: () {},
          ),
          CivicIconButton(
            icon: LucideIcons.share2,
            semanticLabel: 'Share this page',
            tooltip: 'Share this page',
            onPressed: () {},
          ),
          CivicTooltip(
            message: 'Opens in a new window',
            child: CivicLink(
              onPressed: () {},
              child: const Text('Parking zones map'),
            ),
          ),
        ],
      ),
    ],
  );
}
