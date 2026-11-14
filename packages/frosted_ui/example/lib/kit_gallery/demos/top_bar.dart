/// The top bar in each register, the screen deriving its chrome from the
/// route live (push a page and its way back appears, raise it as a sheet
/// page and its close does), and the light every page stands under.
/// [FrostedScaffold] stands the page over its [FrostedLightField] and pins the
/// bar over the page on a phone; its [FrostedAppBar] never authors a back or
/// a close.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitTopBarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Top bar & screen',
  sections: [
    kitSection(
      'Derived by the route',
      children: [
        Builder(
          builder: (context) => kitRow([
            FrostedButton.glass(
              'Push a page',
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const _Detail())),
            ),
            FrostedButton.glass(
              'As a sheet page',
              onPressed: () => Navigator.of(context).push(
                FrostedSheet.pageRoute<void>(
                  context: context,
                  drawer: true,
                  builder: (_) => const _Detail(),
                ),
              ),
            ),
          ]),
        ),
      ],
    ),
    kitSection(
      "Home's greeting",
      children: [
        const FrostedAppBar.greeting(
          title: 'Good evening, Maren',
          subtitle: 'Wednesday, October 28',
        ),
      ],
    ),
    kitSection(
      "A tab's title, with its caption and its own control",
      children: [
        const FrostedAppBar(title: 'Goals'),
        FrostedAppBar(
          title: 'Spending',
          caption: 'October 2026',
          actions: [
            FrostedButton.glass(
              'October',
              size: FrostedButtonSize.small,
              icon: LucideIcons.chevronDown,
              onPressed: () {},
            ),
          ],
        ),
      ],
    ),
    kitSection(
      'As a pushed page draws it',
      children: [
        kitInRegister(
          RoutePresentation.pushed,
          const FrostedAppBar(title: 'Account', backLabel: 'Home'),
        ),
      ],
    ),
    kitSection(
      'As a sheet page draws it',
      children: [_sheetHead(const FrostedAppBar(title: 'Category'))],
    ),
    kitSection('The light', children: [const _LightStrip()]),
  ],
);

/// The page's light on the canvas, the whole field (560 on a phone, 640 on
/// the desktop), in a hairline so the panel keeps its edge where the washes
/// fade into the ground.
class _LightStrip extends StatelessWidget {
  const _LightStrip();

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final radius = BorderRadius.circular(FrostedCorners.r18);
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: t.colorScheme.border),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        // The whole field, so its washes fade out inside the strip (cut at
        // 220 they ended on a line at their brightest).
        child: SizedBox(
          height: FrostedLightField.heightIn(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: t.colorScheme.background),
              const Positioned(
                left: 0,
                top: 0,
                right: 0,
                child: FrostedLightField(),
              ),
              Padding(
                padding: FrostedInsets.all16,
                child: Text(
                  'LILAC, ROSE AND PEACH',
                  style: t.textTheme.overline.c(t.colorScheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail();

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return FrostedScaffold(
      topBar: const FrostedAppBar(title: 'Account', backLabel: 'Home'),
      footer: Builder(
        builder: (context) => FrostedButton(
          'Copy account number',
          icon: LucideIcons.copy,
          expand: true,
          onPressed: () => FrostedToast.show(
            context,
            'Account number copied',
            icon: LucideIcons.copy,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FrostedGap(FrostedSpacing.s24),
          Text(
            FrostedFormat.money(6248.30),
            style: t.textTheme.displaySmall.tabular,
          ),
          const FrostedGap(FrostedSpacing.s8),
          Text(
            '+\$73.42 interest',
            style: t.textTheme.bodyMedium.c(t.colorScheme.moneyIn),
          ),
        ],
      ),
    );
  }
}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Home's first screen: the greeting, the net worth's head, the figure and
/// the month's change, and the four acts, with the nav over the page's foot
/// as the shell lays it. (The figure and the acts are set in type until the
/// money parts and the acts land in Stage C.)
Widget kitSpecimenScreenHome() => Stack(
  fit: StackFit.expand,
  children: [
    FrostedScaffold(
      topBar: const FrostedAppBar.greeting(
        title: 'Good evening, Maren',
        subtitle: 'Wednesday, October 28',
      ),
      body: Builder(
        builder: (context) {
          final t = context.frostedTheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FrostedGap(FrostedSpacing.s12),
              Text('Net worth', style: t.textTheme.labelMedium),
              const FrostedGap(FrostedSpacing.s4),
              Text(
                FrostedFormat.money(78182.56),
                style: t.textTheme.displaySmall.tabular,
              ),
              const FrostedGap(FrostedSpacing.s8),
              Wrap(
                spacing: FrostedSpacing.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '+${FrostedFormat.money(2904.18)}',
                    style: t.textTheme.amount.c(t.colorScheme.moneyIn),
                  ),
                  Text(
                    'this month',
                    style: t.textTheme.bodyMedium.c(t.colorScheme.textTertiary),
                  ),
                ],
              ),
              const FrostedGap(FrostedSpacing.s24),
              FrostedButtonRow(
                children: [
                  FrostedButton(
                    'Move money',
                    icon: LucideIcons.arrowLeftRight,
                    onPressed: () {},
                  ),
                  FrostedButton.glass(
                    'Pay a bill',
                    icon: LucideIcons.receipt,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ),
    Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: FrostedNavigationBar(
        items: sampleTabs,
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
    ),
  ],
);

/// Transfer's review: what is moving and where, its details in one column,
/// and the act that sends it at the foot (DERIVED: the source sets its acts
/// in the page).
Widget kitSpecimenScreenFooter() => kitInRegister(
  RoutePresentation.pushed,
  FrostedScaffold(
    topBar: const FrostedAppBar(title: 'Review', backLabel: 'Transfer'),
    footer: FrostedButton('Transfer \$500.00', expand: true, onPressed: () {}),
    body: Builder(
      builder: (context) {
        final t = context.frostedTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FrostedGap(FrostedSpacing.s24),
            Center(
              child: Text('You are moving', style: t.textTheme.labelMedium),
            ),
            const FrostedGap(FrostedSpacing.s8),
            Center(
              child: Text(
                FrostedFormat.money(500),
                style: t.textTheme.displaySmall.tabular,
              ),
            ),
            const FrostedGap(FrostedSpacing.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: FrostedSpacing.s10,
              children: [
                Text(
                  'Everyday',
                  style: t.textTheme.titleMedium.c(t.colorScheme.textSecondary),
                ),
                Icon(
                  FrostedGlyphs.arrowRight,
                  size: FrostedIconSize.i16,
                  color: t.colorScheme.textTertiary,
                ),
                Text(
                  'Savings',
                  style: t.textTheme.titleMedium.c(t.colorScheme.textSecondary),
                ),
              ],
            ),
            const FrostedGap(FrostedSpacing.s24),
            for (final (key, value) in const [
              ('From', 'Everyday ··4821'),
              ('To', 'Savings ··9015'),
              ('Note', 'November top-up'),
              ('When', 'Today · Wed, Oct 28'),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedSpacing.s8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        key,
                        style: t.textTheme.bodyMedium.c(
                          t.colorScheme.textTertiary,
                        ),
                      ),
                    ),
                    Text(
                      value,
                      style: t.textTheme.bodyMedium.c(
                        t.colorScheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  ),
);

/// A bar on the page's gutter, as a screen's room holds it.
Widget _onGutter(Widget bar) => Builder(
  builder: (context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: FrostedBreakpoints.gutter(context),
    ),
    child: bar,
  ),
);

/// A bar on the gutter over the top of its page's light, as a screen holds
/// it: the light laid at its own height and clipped to the bar's.
Widget _onLight(Widget bar) => Stack(
  children: [
    const Positioned(left: 0, top: 0, right: 0, child: FrostedLightField()),
    _onGutter(bar),
  ],
);

Widget kitSpecimenTopBarGreeting() => _onLight(
  const FrostedAppBar.greeting(
    title: 'Good evening, Maren',
    subtitle: 'Wednesday, October 28',
  ),
);

Widget kitSpecimenTopBarRoot() =>
    _onLight(const FrostedAppBar(title: 'Spending', caption: 'October 2026'));

Widget kitSpecimenTopBarPushed() => kitInRegister(
  RoutePresentation.pushed,
  _onLight(const FrostedAppBar(title: 'Account', backLabel: 'Home')),
);

/// A sheet page's [bar] on its card, under the card's grabber (drawn here
/// from its tokens; the sheet page places the real one). The card stands
/// [height] tall when given: the specimen's card is the Category sheet's
/// 540.
Widget _sheetHead(FrostedAppBar bar, {double? height}) => kitInRegister(
  RoutePresentation.sheet,
  Builder(
    builder: (context) => SizedBox(
      height: height,
      child: FrostedSheetCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FrostedChromeMetrics.sheetSide,
            FrostedChromeMetrics.sheetTop,
            FrostedChromeMetrics.sheetSide,
            FrostedChromeMetrics.sheetSide,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: FrostedChromeMetrics.grabberWidth,
                  height: FrostedChromeMetrics.grabberHeight,
                  decoration: BoxDecoration(
                    color: context.frostedTheme.glass.grabber,
                    borderRadius: BorderRadius.circular(FrostedCorners.r2),
                  ),
                ),
              ),
              const SizedBox(height: FrostedChromeMetrics.grabberGap),
              bar,
            ],
          ),
        ),
      ),
    ),
  ),
);

Widget kitSpecimenTopBarSheet() =>
    _sheetHead(const FrostedAppBar(title: 'Category'), height: 540);
