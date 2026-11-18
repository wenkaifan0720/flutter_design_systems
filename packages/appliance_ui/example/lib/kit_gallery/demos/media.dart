import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Portholes, label plates, pictures in windows, an empty display, a
/// rating plate, a timeline.
Widget kitMediaDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Cards and media',
  sections: const [_Media()],
);

class _Media extends StatelessWidget {
  const _Media();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const KitSection(
        title: 'People and labels',
        note: 'Round portholes; label plates stuck to the panel.',
        children: [
          KitRow(
            children: [
              ApplianceAvatar(name: 'Ada Brook', size: 48),
              ApplianceAvatar(name: 'Sam Lee'),
              ApplianceAvatar(name: 'Kit', size: 28),
              ApplianceAvatarGroup(
                names: [
                  'Ada Brook',
                  'Sam Lee',
                  'Kit Ward',
                  'Jo Hart',
                  'Ravi Shah',
                ],
              ),
            ],
          ),
          KitRow(
            children: [
              ApplianceTag('In stock', tone: ApplianceTagTone.ready),
              ApplianceTag('New', tone: ApplianceTagTone.signal),
              ApplianceTag('Last few', tone: ApplianceTagTone.danger),
              ApplianceTag('Discontinued'),
              ApplianceBadge('3'),
            ],
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      const KitSection(
        title: 'Pictures',
        note: 'A picture behind a window; the window\'s floor until it comes.',
        children: [
          KitRow(
            children: [
              SizedBox(
                width: 220,
                child: ApplianceMedia(
                  slotId: 'appliance_kettle',
                  semanticLabel: 'A cream kettle',
                  aspectRatio: 4 / 3,
                  placeholder: Icon(LucideIcons.cookingPot),
                ),
              ),
              SizedBox(
                width: 220,
                child: ApplianceMedia(
                  slotId: 'appliance_toaster',
                  semanticLabel: 'A two-slice toaster',
                  aspectRatio: 4 / 3,
                  placeholder: Icon(LucideIcons.croissant),
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Nothing yet',
        note: 'A dark display with only dashes lit.',
        plate: false,
        children: [
          ApplianceEmptyState(
            title: 'Your basket is empty',
            message: 'Things you add stand here until you check out.',
            action: ApplianceButton('Browse the shop', onPressed: () {}),
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      const KitSection(
        title: 'Rating plate and timeline',
        note: 'Terms over their values; lamps down a seam.',
        children: [
          ApplianceDescriptionList(
            items: [
              ('Capacity', '1.7 litres'),
              ('Power', '3 kW'),
              ('Warranty', 'Two years, parts and labour'),
            ],
          ),
          ApplianceTimeline(
            entries: [
              ApplianceTimelineEntry(title: 'Ordered', time: 'Mon 09:40'),
              ApplianceTimelineEntry(
                title: 'Packed',
                detail: 'At the Leith depot',
                time: 'Mon 14:05',
              ),
              ApplianceTimelineEntry(
                title: 'Out for delivery',
                detail: 'Due between 10:00 and 12:00',
                time: 'Tue 08:12',
                state: ApplianceTimelineState.current,
              ),
              ApplianceTimelineEntry(
                title: 'Delivered',
                state: ApplianceTimelineState.upcoming,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
