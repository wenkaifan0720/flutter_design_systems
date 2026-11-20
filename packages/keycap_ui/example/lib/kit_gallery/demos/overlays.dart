import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';

import '../kit.dart';

/// Panels laid over the keyboard.
Widget kitOverlaysDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Dialogs and sheets',
  sections: [
    const _Overlays(),
    ...kitSpecimens(const [
      'Menu',
      'Popover',
      'HoverCard',
      'Tooltip',
      'Sheet',
      'ActionSheet',
    ]),
  ],
);

class _Overlays extends StatelessWidget {
  const _Overlays();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Dialog, sheet, toast',
    note: 'A panel of keycap plastic set down over the dimmed keyboard.',
    children: [
      KitRow(
        children: [
          KeycapButton(
            onPressed: () => showKeycapDialog<void>(
              context: context,
              isAlert: true,
              builder: (context) => KeycapDialog(
                title: 'Delete “Bulbs to order”?',
                content: const Text(
                  'It moves to Recently deleted, where it stays for 30 days.',
                ),
                actions: [
                  KeycapButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Keep note'),
                  ),
                  KeycapButton.accent(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ),
            child: const Text('Dialog'),
          ),
          KeycapButton(
            onPressed: () => showKeycapBottomSheet<void>(
              context: context,
              title: 'Share note',
              builder: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Anyone with the link can read “Roast squash soup”.',
                    style: context.keycapTheme.textTheme.body,
                  ),
                  const SizedBox(height: KeycapSpacing.large),
                  KeycapButton.accent(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Copy link'),
                  ),
                ],
              ),
            ),
            child: const Text('Sheet'),
          ),
          KeycapButton(
            onPressed: () => showKeycapToast(
              context,
              'Moved to Work',
              actionLabel: 'Undo',
              onAction: () {},
            ),
            child: const Text('Toast'),
          ),
        ],
      ),
    ],
  );
}
