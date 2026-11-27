import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:appliance_ui/appliance_ui.dart';

import '../kit.dart';

/// Navigation: the top bar and the three ways round by width.
Widget kitNavigationDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Navigation',
  sections: const [_Navigation(), _Wayfinding()],
);

const _places = [
  ApplianceDestination(icon: LucideIcons.house, label: 'Home'),
  ApplianceDestination(icon: LucideIcons.layoutGrid, label: 'Shop'),
  ApplianceDestination(
    icon: LucideIcons.shoppingBasket,
    label: 'Basket',
    badge: '3',
  ),
  ApplianceDestination(icon: LucideIcons.settings, label: 'Settings'),
];

class _Navigation extends StatefulWidget {
  const _Navigation();

  @override
  State<_Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<_Navigation> {
  int _at = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitSection(
        title: 'Top bar',
        plate: false,
        children: [
          ApplianceAppBar(
            title: 'Basket',
            onBack: () {},
            actions: [
              ApplianceIconButton(
                icon: const Icon(LucideIcons.search),
                semanticLabel: 'Search',
                onPressed: () {},
                style: const ApplianceStyle(
                  minimumSize: WidgetStatePropertyAll(Size.square(40)),
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Key strip',
        note: 'Under 600 px. The current place is latched with its lamp lit.',
        plate: false,
        children: [
          MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: ApplianceNavigationBar(
              destinations: _places,
              selectedIndex: _at,
              onSelected: (i) => setState(() => _at = i),
            ),
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Side panel',
        note: 'From 1024 px: a bank of preset keys, a lamp beside each.',
        plate: false,
        children: [
          SizedBox(
            height: 300,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: ApplianceSideNavigation(
                  destinations: _places,
                  selectedIndex: _at,
                  legend: 'Shop',
                  onSelected: (i) => setState(() => _at = i),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Breadcrumbs, pages, steps, lamps, a menubar and the command palette.
class _Wayfinding extends StatefulWidget {
  const _Wayfinding();

  @override
  State<_Wayfinding> createState() => _WayfindingState();
}

class _WayfindingState extends State<_Wayfinding> {
  int _page = 3;
  int _dot = 1;
  bool _prices = true;

  @override
  Widget build(BuildContext context) {
    final commands = [
      RawCommand(label: 'New list', group: 'Lists', onPressed: () {}),
      RawCommand(
        label: 'Open the basket',
        group: 'Go to',
        shortcut: kitShortcutLabel(context, LogicalKeyboardKey.keyB),
        onPressed: () {},
      ),
      RawCommand(label: 'Orders', group: 'Go to', onPressed: () {}),
      RawCommand(label: 'Settings', group: 'Go to', onPressed: () {}),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSection(
          title: 'Where you are',
          note: 'The way back; numbered keys; lamps on a seam.',
          children: [
            ApplianceBreadcrumb(
              crumbs: [
                ApplianceCrumb('Shop', onPressed: () {}),
                ApplianceCrumb('Kitchen', onPressed: () {}),
                const ApplianceCrumb('Kettles'),
              ],
            ),
            AppliancePagination(
              page: _page,
              pageCount: 9,
              onChanged: (p) => setState(() => _page = p),
            ),
            const ApplianceStepProgress(
              steps: ['Basket', 'Delivery', 'Payment', 'Done'],
              current: 1,
            ),
            AppliancePageDots(
              count: 4,
              index: _dot,
              onChanged: (i) => setState(() => _dot = i),
            ),
          ],
        ),
        const SizedBox(height: ApplianceSpacing.extraLarge),
        KitSection(
          title: 'Menus and commands',
          note: 'Menus in a moulded strip; every command, searched.',
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ApplianceMenuBar(
                menus: [
                  RawMenuEntry(
                    label: 'List',
                    children: [
                      RawMenuEntry(label: 'New list', onPressed: () {}),
                      RawMenuEntry(
                        label: 'Print',
                        shortcut: kitShortcutLabel(
                          context,
                          LogicalKeyboardKey.keyP,
                        ),
                        onPressed: () {},
                      ),
                      const RawMenuEntry.divider(),
                      const RawMenuEntry(label: 'Share (offline)'),
                    ],
                  ),
                  RawMenuEntry(
                    label: 'View',
                    children: [
                      RawMenuEntry(
                        label: 'Show prices',
                        checked: _prices,
                        onPressed: () => setState(() => _prices = !_prices),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ApplianceCommandPalette(maxHeight: 220, commands: commands),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ApplianceButton(
                'Open the palette',
                icon: const Icon(LucideIcons.command),
                onPressed: () => showApplianceCommandPalette(
                  context: context,
                  commands: commands,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
