import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';

import '../kit.dart';

/// Slots lit as work goes, a ring, unlit plates, a page's outcome, a
/// needle, pull to refresh.
Widget kitFeedbackDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Feedback',
  sections: const [_Feedback()],
);

class _Feedback extends StatelessWidget {
  const _Feedback();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const KitSection(
        title: 'Progress',
        note: 'A slot lit as far as the work has gone; a ring lit round.',
        children: [
          ApplianceProgressBar(value: 0.4, semanticLabel: 'Uploading'),
          ApplianceProgressBar(semanticLabel: 'Working'),
          KitRow(
            children: [
              ApplianceProgressRing(value: 0.7, semanticLabel: 'Saving'),
              ApplianceProgressRing(semanticLabel: 'Working'),
              ApplianceProgressRing(
                size: 20,
                stroke: 3,
                semanticLabel: 'Small',
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      const KitSection(
        title: 'Loading',
        note: 'Unlit plates where the words will stand.',
        children: [
          Row(
            children: [
              ApplianceSkeleton(width: 48, height: 48, circle: true),
              SizedBox(width: ApplianceSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ApplianceSkeleton(width: 180, height: 14),
                    SizedBox(height: ApplianceSpacing.small),
                    ApplianceSkeleton(width: 120, height: 12),
                  ],
                ),
              ),
            ],
          ),
          ApplianceSkeleton(height: 96),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Outcomes',
        note: 'A whole page\'s outcome under its lamp.',
        children: [
          ApplianceStatusView(
            status: ApplianceStatus.error,
            title: 'Payment failed',
            message: 'Your card was declined. Nothing was taken.',
            actions: [
              ApplianceButton.filled('Try again', onPressed: () {}),
              ApplianceButton('Use another card', onPressed: () {}),
            ],
          ),
          const ApplianceStatusView(
            status: ApplianceStatus.success,
            title: 'Order placed',
            message: 'Order 1048 arrives on Tuesday.',
          ),
          const ApplianceStatusView(
            status: ApplianceStatus.working,
            title: 'Placing your order',
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      const KitSection(
        title: 'Meters',
        note: 'A needle over a printed scale, red near the top.',
        children: [
          KitRow(
            children: [
              ApplianceMeter(
                value: 0.62,
                label: 'Storage',
                valueText: '6.2 of 10 GB',
              ),
              ApplianceMeter(
                value: 0.92,
                label: 'Budget',
                valueText: '£276 of £300',
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Pull to refresh',
        note: 'Pull down: the ring fills, its lamp lights, it turns.',
        children: [
          SizedBox(
            height: 200,
            child: ApplianceRefresh(
              onRefresh: () => Future<void>.delayed(const Duration(seconds: 1)),
              child: ListView(
                children: const [
                  ApplianceListTile(
                    title: 'Order 1048',
                    subtitle: 'Arrives Tuesday',
                  ),
                  ApplianceListTile(title: 'Order 1042', subtitle: 'Delivered'),
                  ApplianceListTile(title: 'Order 1039', subtitle: 'Delivered'),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
