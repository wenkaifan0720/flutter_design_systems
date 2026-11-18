/// Larder's Home: the season's lead on a faceplate with its display window,
/// the shelves as keys, and the new goods.
library;

import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'larder.dart';
import 'search.dart';
import 'shop.dart';

/// Home.
class LarderHome extends StatelessWidget {
  /// Home.
  const LarderHome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.applianceTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final frame = LarderFrame.of(context);
    final fresh = larderProducts.where((p) => p.isNew).toList();
    final more = larderProducts.where((p) => !p.isNew).take(4).toList();
    return LarderPage(
      title: 'Home',
      maxWidth: larderDeskWidth,
      actions: [
        ApplianceIconButton(
          icon: const Icon(LucideIcons.search),
          semanticLabel: 'Search',
          onPressed: () => frame.push(const LarderSearchPage()),
          style: const ApplianceStyle(
            minimumSize: WidgetStatePropertyAll(Size.square(40)),
          ),
        ),
      ],
      children: [
        AppliancePanel(
          padding: const EdgeInsets.all(ApplianceSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Display(text: 'Free delivery over £40'),
              const SizedBox(height: ApplianceSpacing.large),
              Text('Pour, brew and keep.', style: t.display),
              const SizedBox(height: ApplianceSpacing.small),
              Text(
                'New this season: a pour-over set, an enamel stock pot, and '
                'tins that close with a click.',
                style: t.body.copyWith(color: c.printMuted),
              ),
              const SizedBox(height: ApplianceSpacing.large),
              Wrap(
                spacing: ApplianceSpacing.medium,
                runSpacing: ApplianceSpacing.medium,
                children: [
                  ApplianceButton.filled(
                    'Shop the new goods',
                    onPressed: () => frame.go(LarderPlace.shop),
                  ),
                  ApplianceButton(
                    'Your basket',
                    icon: const Icon(LucideIcons.shoppingBasket),
                    onPressed: () => frame.go(LarderPlace.basket),
                  ),
                ],
              ),
            ],
          ),
        ),
        larderGroupGap,
        const ApplianceSectionHeader('Shelves'),
        Wrap(
          spacing: ApplianceSpacing.small,
          runSpacing: ApplianceSpacing.small,
          children: [
            for (final shelf in LarderCategory.values)
              ApplianceButton(
                shelf.label,
                icon: Icon(shelf.icon),
                onPressed: () => frame.go(LarderPlace.shop),
              ),
          ],
        ),
        larderGroupGap,
        const ApplianceSectionHeader('New this season'),
        LarderProductGrid(products: fresh),
        larderGroupGap,
        const ApplianceSectionHeader('Kitchen basics'),
        LarderProductGrid(products: more),
      ],
    );
  }
}

/// A display window set in a faceplate: smoked glass, a lamp and a lit
/// legend.
class _Display extends StatelessWidget {
  const _Display({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.applianceTheme;
    final c = theme.colors;
    return ApplianceSurface(
      face: ApplianceFace.well(c, fill: c.display, radius: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ApplianceLamp(lit: true, color: c.signalTop),
            const SizedBox(width: ApplianceSpacing.small + 2),
            Flexible(
              child: Text(
                text.toUpperCase(),
                style: theme.textTheme.legend.copyWith(color: c.onDisplay),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
