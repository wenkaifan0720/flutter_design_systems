/// Clay's surfaces over a page: dialogs, sheets, toasts, menus, popovers,
/// hover cards and tips.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The overlays page.
Widget kitOverlaysDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Overlays',
  sections: [
    const KitSection(
      title: 'A dialog at rest',
      children: [
        ClayDialog(
          title: 'Delete “Morning walk”?',
          content: Text('Its 12-day streak and its notes go with it.'),
          actions: [
            ClayDialogAction(label: 'Keep', onPressed: _atRest),
            ClayDialogAction(
              label: 'Delete',
              onPressed: _atRest,
              isDefaultAction: true,
              isDestructiveAction: true,
            ),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Open one',
      children: [
        Builder(
          builder: (context) => KitRow(
            children: [
              ClayButton(
                'Dialog',
                onPressed: () => showClayDialog<void>(
                  context: context,
                  isAlert: true,
                  builder: (context) => ClayDialog(
                    title: 'Delete “Morning walk”?',
                    content: const Text(
                      'Its 12-day streak and its notes go with it.',
                    ),
                    actions: [
                      ClayDialogAction(
                        label: 'Keep',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      ClayDialogAction(
                        label: 'Delete',
                        isDefaultAction: true,
                        isDestructiveAction: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
              ClayButton(
                'Sheet',
                onPressed: () => showClayBottomSheet<void>(
                  context: context,
                  title: 'Reminder time',
                  builder: (context) =>
                      const Text('Remind me at 8:00 every morning.'),
                  footerBuilder: (context) => ClayButton.filled(
                    'Set reminder',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              ClayButton(
                'Toast',
                onPressed: () => showClayToast(
                  context,
                  'Habit archived',
                  actionLabel: 'Undo',
                  onAction: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    const KitSection(
      title: 'Side and action sheets',
      note:
          'A slab from the side for a desk; a stack of keys from below for '
          'what to do with one thing.',
      children: [_Sheets()],
    ),
    const KitSection(
      title: 'Menus, popovers and tips',
      note:
          'Floating slabs over the page, near what opened them: a menu of '
          'rows, a right-click menu, a popover, a card on hover, a tip.',
      children: [_Popovers()],
    ),
  ],
);

class _Sheets extends StatelessWidget {
  const _Sheets();

  @override
  Widget build(BuildContext context) => KitRow(
    children: [
      ClayButton(
        'Filters',
        icon: const Icon(LucideIcons.slidersHorizontal),
        onPressed: () => showClaySideSheet<void>(
          context: context,
          title: 'Filters',
          builder: (context) => const Text('Every habit, any time of day.'),
        ),
      ),
      ClayButton(
        'Habit actions',
        onPressed: () async {
          final picked = await showClayActionSheet<String>(
            context: context,
            title: 'Drink water',
            actions: const [
              ClaySheetAction(label: 'Pause', value: 'pause'),
              ClaySheetAction(label: 'Archive', value: 'archive'),
              ClaySheetAction(
                label: 'Delete',
                value: 'delete',
                isDestructiveAction: true,
              ),
            ],
          );
          if (picked != null && context.mounted) {
            showClayToast(context, 'Chose $picked');
          }
        },
      ),
    ],
  );
}

class _Popovers extends StatelessWidget {
  const _Popovers();

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitRow(
          children: [
            ClayMenu(
              items: [
                ClayMenuItem(
                  label: 'Edit',
                  icon: LucideIcons.pencil,
                  onPressed: () {},
                ),
                ClayMenuItem(
                  label: 'Pause',
                  icon: LucideIcons.pause,
                  onPressed: () {},
                ),
                ClayMenuItem(
                  label: 'Delete',
                  icon: LucideIcons.trash2,
                  isDestructiveAction: true,
                  onPressed: () {},
                ),
              ],
              builder: (context, toggle, open) => ClayIconButton(
                onPressed: toggle,
                isSelected: open,
                icon: const Icon(LucideIcons.ellipsis),
                tooltip: 'More',
              ),
            ),
            ClayPopover(
              semanticLabel: 'Streak',
              builder: (context, toggle, open) =>
                  ClayButton('Streak', onPressed: toggle),
              content: (context, close) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Twelve days running',
                    style: theme.textTheme.title.copyWith(
                      color: theme.colors.ink,
                    ),
                  ),
                  Text(
                    'Your best is 21. Keep going.',
                    style: theme.textTheme.secondary,
                  ),
                  const SizedBox(height: ClaySpacing.regular),
                  ClayButton('Close', onPressed: close),
                ],
              ),
            ),
            ClayHoverCard(
              content: (context) => Row(
                children: [
                  const ClayAvatar(name: 'Mia Okafor'),
                  const SizedBox(width: ClaySpacing.regular),
                  Expanded(
                    child: Text(
                      'Mia Okafor, a 41-day streak',
                      style: theme.textTheme.body.copyWith(
                        color: theme.colors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              child: ClayLink('Mia', onPressed: () {}),
            ),
            ClayTooltip(
              message: 'Edit this habit',
              child: ClayIconButton(
                onPressed: () {},
                icon: const Icon(LucideIcons.pencil),
                tooltip: 'Edit',
              ),
            ),
          ],
        ),
        const SizedBox(height: ClaySpacing.regular),
        ClayContextMenu(
          semanticLabel: 'Drink water, more',
          items: [
            ClayMenuItem(label: 'Pause', onPressed: () {}),
            ClayMenuItem(label: 'Archive', onPressed: () {}),
          ],
          child: const ClayGroup(
            children: [
              ClayListTile(
                title: 'Drink water',
                subtitle: 'Right-click or long-press for more',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// The dialog at rest is a picture of one: its keys look live and do nothing.
void _atRest() {}
