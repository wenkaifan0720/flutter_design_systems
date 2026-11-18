/// Larder's Settings: the appearance, reading direction and density the
/// whole app takes, the notices it sends, and the account.
library;

import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'larder.dart';

/// Settings.
class LarderSettings extends StatelessWidget {
  /// Settings.
  const LarderSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = LarderPrefs.of(context);
    const gap = SizedBox(height: ApplianceSpacing.extraLarge);
    Widget toggle(
      String title,
      String? subtitle,
      IconData icon,
      bool value,
      void Function(LarderPrefs p, bool v) set,
    ) => ApplianceListTile(
      leading: Icon(icon),
      title: title,
      subtitle: subtitle,
      trailing: ApplianceSwitch(
        value: value,
        semanticLabel: title,
        onChanged: (v) => prefs.update((p) => set(p, v)),
      ),
    );
    final density = ApplianceSelect<ApplianceDensity>(
      label: 'Density',
      value: prefs.density,
      items: const [
        ApplianceSelectItem(
          value: ApplianceDensity.standard,
          label: 'Standard',
        ),
        ApplianceSelectItem(
          value: ApplianceDensity.comfortable,
          label: 'Comfortable',
        ),
        ApplianceSelectItem(value: ApplianceDensity.compact, label: 'Compact'),
      ],
      onChanged: (v) => prefs.update((p) => p.density = v),
    );
    final direction = ApplianceSelect<TextDirection>(
      label: 'Reading direction',
      value: prefs.direction,
      items: const [
        ApplianceSelectItem(value: TextDirection.ltr, label: 'Left to right'),
        ApplianceSelectItem(value: TextDirection.rtl, label: 'Right to left'),
      ],
      onChanged: (v) => prefs.update((p) => p.direction = v),
    );
    List<Widget> appearance(bool wide) => [
      const ApplianceSectionHeader('Appearance'),
      AppliancePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ApplianceSegmentedButton<LarderAppearance>(
              semanticLabel: 'Appearance',
              expand: true,
              segments: const [
                ApplianceSegment(
                  value: LarderAppearance.light,
                  label: 'Light',
                  icon: Icon(LucideIcons.sun),
                ),
                ApplianceSegment(
                  value: LarderAppearance.dark,
                  label: 'Dark',
                  icon: Icon(LucideIcons.moon),
                ),
                ApplianceSegment(
                  value: LarderAppearance.system,
                  label: 'System',
                  icon: Icon(LucideIcons.monitor),
                ),
              ],
              value: prefs.appearance,
              onChanged: (v) => prefs.update((p) => p.appearance = v),
            ),
            const SizedBox(height: ApplianceSpacing.large),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: density),
                  const SizedBox(width: ApplianceSpacing.regular),
                  Expanded(child: direction),
                ],
              )
            else ...[
              density,
              const SizedBox(height: ApplianceSpacing.large),
              direction,
            ],
            const SizedBox(height: ApplianceSpacing.large),
            const ApplianceDivider(),
            const SizedBox(height: ApplianceSpacing.regular),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Show prices with tax',
                    style: context.applianceTheme.textTheme.body,
                  ),
                ),
                const SizedBox(width: ApplianceSpacing.medium),
                ApplianceSwitch(
                  value: prefs.withTax,
                  semanticLabel: 'Show prices with tax',
                  onChanged: (v) => prefs.update((p) => p.withTax = v),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
    final notices = ApplianceListGroup(
      header: 'Notices',
      footer: 'Order updates come as an order moves; the letter once a month.',
      children: [
        toggle(
          'Order updates',
          'When an order ships and arrives',
          LucideIcons.bell,
          prefs.orderUpdates,
          (p, v) => p.orderUpdates = v,
        ),
        toggle(
          'New season letter',
          'The new goods, once a month',
          LucideIcons.sparkles,
          prefs.newsletter,
          (p, v) => p.newsletter = v,
        ),
        toggle(
          'Key sounds',
          null,
          LucideIcons.volume2,
          prefs.keySounds,
          (p, v) => p.keySounds = v,
        ),
      ],
    );
    final account = ApplianceListGroup(
      header: 'Account',
      children: [
        ApplianceListTile(
          leading: const Icon(LucideIcons.user),
          title: 'Name',
          trailingText: larderShopper.name,
          onTap: () {},
        ),
        ApplianceListTile(
          leading: const Icon(LucideIcons.mapPin),
          title: 'Address',
          trailingText: larderShopper.address,
          onTap: () {},
        ),
        ApplianceListTile(
          leading: const Icon(LucideIcons.creditCard),
          title: 'Cards',
          trailingText: 'One saved',
          onTap: () {},
        ),
        ApplianceListTile(
          title: 'Sign out',
          destructive: true,
          showChevron: false,
          onTap: () => showApplianceToast(context, 'Signed out'),
        ),
      ],
    );
    final help = ApplianceListGroup(
      header: 'Help',
      children: [
        ApplianceListTile(
          leading: const Icon(LucideIcons.packageCheck),
          title: 'Delivery and returns',
          onTap: () {},
        ),
        ApplianceListTile(
          leading: const Icon(LucideIcons.mail),
          title: 'Write to the shop',
          onTap: () {},
        ),
        ApplianceListTile(
          leading: const Icon(LucideIcons.info),
          title: 'About Larder',
          onTap: () => LarderFrame.of(context).go(LarderPlace.overview),
        ),
        const ApplianceListTile(
          leading: Icon(LucideIcons.tag),
          title: 'Version',
          trailingText: '1.0',
          showChevron: false,
        ),
      ],
    );
    Widget column(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    return LarderPage(
      title: 'Settings',
      maxWidth: larderDeskWidth,
      children: [
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 860
              // On a desk, two rows of panes: how the app looks beside what
              // it sends; who you are beside where to ask.
              ? column([
                  for (final (i, (start, end)) in [
                    (column(appearance(true)), notices),
                    (account, help),
                  ].indexed) ...[
                    if (i > 0) gap,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: start),
                        const SizedBox(width: ApplianceSpacing.large),
                        Expanded(child: end),
                      ],
                    ),
                  ],
                ])
              : Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ApplianceMetrics.readingWidth,
                    ),
                    child: column([
                      ...appearance(false),
                      gap,
                      notices,
                      gap,
                      account,
                      gap,
                      help,
                    ]),
                  ),
                ),
        ),
      ],
    );
  }
}
