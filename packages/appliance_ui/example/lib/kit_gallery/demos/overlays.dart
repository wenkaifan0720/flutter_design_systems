import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Overlays: the lid, the sheet and the display window.
Widget kitOverlaysDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Dialogs and sheets',
  sections: const [_Overlays(), _Anchored()],
);

class _Overlays extends StatelessWidget {
  const _Overlays();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Overlays',
    note: 'A lid over the dimmed housing; a sheet up its track; a toast.',
    children: [
      KitRow(
        children: [
          ApplianceButton(
            'Dialog',
            onPressed: () => showApplianceDialog<void>(
              context: context,
              builder: (context) => ApplianceDialog(
                title: 'Remove from the basket?',
                content: const Text('It goes back on the shelf.'),
                actions: [
                  ApplianceButton(
                    'Keep it',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ApplianceButton.filled(
                    'Remove',
                    isDestructiveAction: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
          ApplianceButton(
            'Sheet',
            onPressed: () => showApplianceBottomSheet<void>(
              context: context,
              title: 'Filter',
              builder: (context) => const Text('In stock only'),
            ),
          ),
          ApplianceButton(
            'Toast',
            onPressed: () => showApplianceToast(
              context,
              'Added to basket',
              actionLabel: 'Undo',
              onAction: () {},
            ),
          ),
        ],
      ),
    ],
  );
}

/// Side and action sheets, plates beside their openers, tooltips, menus
/// and banners.
class _Anchored extends StatelessWidget {
  const _Anchored();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitSection(
        title: 'More lids',
        note: 'A tall lid from the side; a short lid of choices.',
        children: [
          KitRow(
            children: [
              ApplianceButton(
                'Side sheet',
                onPressed: () => showApplianceSideSheet<void>(
                  context: context,
                  title: 'Filters',
                  builder: (context) => const Text('In stock only'),
                ),
              ),
              ApplianceButton(
                'Action sheet',
                onPressed: () => showApplianceActionSheet(
                  context: context,
                  title: 'Order 1042',
                  actions: [
                    ApplianceSheetAction('Track the order', onPressed: () {}),
                    ApplianceSheetAction(
                      'Cancel the order',
                      isDestructiveAction: true,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Beside the opener',
        note: 'A plate lifted beside what opened it; a word lit in a window.',
        children: [
          KitRow(
            children: [
              AppliancePopover(
                semanticLabel: 'Delivery note',
                builder: (context, anchor) =>
                    ApplianceButton('Delivery note', onPressed: anchor.toggle),
                content: (context, close) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ApplianceTextField(labelText: 'Note', maxLines: 3),
                    const SizedBox(height: ApplianceSpacing.medium),
                    ApplianceButton.filled('Save', onPressed: close),
                  ],
                ),
              ),
              ApplianceMenu(
                semanticLabel: 'Order',
                entries: [
                  RawMenuEntry(label: 'Track', onPressed: () {}),
                  RawMenuEntry(label: 'Reorder', onPressed: () {}),
                  const RawMenuEntry.divider(),
                  RawMenuEntry(
                    label: 'Cancel',
                    isDestructiveAction: true,
                    onPressed: () {},
                  ),
                ],
                builder: (context, anchor) => ApplianceIconButton(
                  icon: const Icon(LucideIcons.ellipsis),
                  semanticLabel: 'More',
                  onPressed: anchor.toggle,
                ),
              ),
              const ApplianceTooltip(
                message: 'Keeps warm for 30 minutes',
                child: Text('Keep warm'),
              ),
              ApplianceHoverCard(
                card: (context) => const Text('Ships in two days from Leith.'),
                child: ApplianceLink('Kettle', onPressed: () {}),
              ),
            ],
          ),
          ApplianceContextMenu(
            semanticLabel: 'Kettle',
            entries: [
              RawMenuEntry(label: 'Save for later', onPressed: () {}),
              RawMenuEntry(
                label: 'Remove',
                isDestructiveAction: true,
                onPressed: () {},
              ),
            ],
            child: const ApplianceListTile(
              title: 'Kettle',
              subtitle: 'Right-click or long-press for its menu',
            ),
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      const KitSection(
        title: 'Menu rows',
        note:
            'The row every menu paints: at rest, lit under the pointer, a '
            'chosen lamp, greyed, and one that destroys.',
        children: [
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ApplianceMenuRow(label: 'Track', states: {}),
                ApplianceMenuRow(
                  label: 'Reorder',
                  states: {WidgetState.hovered},
                ),
                ApplianceMenuRow(
                  label: 'Sort by price',
                  states: {},
                  selected: true,
                ),
                ApplianceMenuRow(
                  label: 'Sort by name',
                  states: {},
                  selected: false,
                ),
                ApplianceMenuRow(label: 'Archive', states: {}, enabled: false),
                ApplianceMenuRow(
                  label: 'Cancel the order',
                  states: {},
                  isDestructiveAction: true,
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Banners',
        note: 'A lit strip across the page.',
        plate: false,
        children: [
          ApplianceBanner(
            title: 'Card expiring',
            message: 'Your card on file runs out this month.',
            action: ApplianceButton.text('Update', onPressed: () {}),
            onClose: () {},
          ),
          const ApplianceBanner(
            title: 'Order placed',
            tone: ApplianceBannerTone.ready,
          ),
          const ApplianceBanner(
            title: 'Payment failed',
            message: 'Nothing was taken.',
            tone: ApplianceBannerTone.danger,
          ),
        ],
      ),
    ],
  );
}
