/// Gloss's chrome: the top bar, tabs, the bottom bar, the rail and the
/// sidebar.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

const _places = [
  GlossDestination(icon: LucideIcons.house, label: 'Today'),
  GlossDestination(icon: LucideIcons.bookOpen, label: 'Recipes'),
  GlossDestination(icon: LucideIcons.calendarDays, label: 'Plan'),
  GlossDestination(icon: LucideIcons.shoppingBasket, label: 'List'),
];

/// The navigation page.
Widget kitNavigationDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Navigation',
  sections: const [
    KitSection(title: 'Bars', children: [_Bars()]),
    KitSection(title: 'Where you are', children: [_Trail()]),
    KitSection(title: 'Steps and pages', children: [_Steps()]),
    KitSection(
      title: 'A menu bar',
      note: 'A desktop app\'s menus, along the top of its window.',
      children: [_Menus()],
    ),
    KitSection(title: 'A command palette', children: [_Palette()]),
  ],
);

class _Bars extends StatefulWidget {
  const _Bars();

  @override
  State<_Bars> createState() => _BarsState();
}

class _BarsState extends State<_Bars> {
  int _place = 0;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // Each bar is shown as a window cut from a screen: a hairline frame
    // round it, so its edges end where the screen's would.
    final c = context.glossTheme.colors;
    Widget framed(Widget child) => DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlossMetrics.fieldRadius),
        border: Border.all(color: c.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlossMetrics.fieldRadius),
        child: ColoredBox(
          color: c.page,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            child: child,
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        framed(
          GlossTopBar(
            title: 'Miso aubergine',
            onBack: () {},
            actions: [
              GlossIconButton.plain(
                onPressed: () {},
                tooltip: 'Save',
                icon: const Icon(LucideIcons.heart),
              ),
            ],
          ),
        ),
        const SizedBox(height: GlossSpacing.large),
        GlossTabBar(
          tabs: const ['Ingredients', 'Method', 'Notes'],
          selectedIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: GlossSpacing.large),
        framed(
          GlossNavigationBar(
            destinations: _places,
            selectedIndex: _place,
            onDestinationSelected: (i) => setState(() => _place = i),
          ),
        ),
        const SizedBox(height: GlossSpacing.large),
        SizedBox(
          height: 360,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              framed(
                GlossNavigationRail(
                  destinations: _places,
                  selectedIndex: _place,
                  onDestinationSelected: (i) => setState(() => _place = i),
                ),
              ),
              const SizedBox(width: GlossSpacing.large),
              // The sidebar gives up width before the page runs out of it.
              Flexible(
                child: framed(
                  GlossSidebar(
                    header: const Text('Simmer'),
                    destinations: _places,
                    selectedIndex: _place,
                    onDestinationSelected: (i) => setState(() => _place = i),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Trail extends StatefulWidget {
  const _Trail();

  @override
  State<_Trail> createState() => _TrailState();
}

class _TrailState extends State<_Trail> {
  int _page = 1;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GlossBreadcrumb(
        crumbs: [
          GlossCrumb('Recipes', onPressed: () {}),
          GlossCrumb('Mains', onPressed: () {}),
          const GlossCrumb('Lemon risotto'),
        ],
      ),
      const SizedBox(height: GlossSpacing.large),
      GlossPagination(
        page: _page,
        pageCount: 9,
        onPageChanged: (p) => setState(() => _page = p),
      ),
    ],
  );
}

class _Steps extends StatefulWidget {
  const _Steps();

  @override
  State<_Steps> createState() => _StepsState();
}

class _StepsState extends State<_Steps> {
  int _dot = 0;
  int _step = 1;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlossStepProgress(
          steps: const ['Prep', 'Cook', 'Rest', 'Serve'],
          currentStep: _step,
        ),
      ),
      const SizedBox(height: GlossSpacing.medium),
      GlossButton.text(
        'Next step',
        onPressed: () => setState(() => _step = (_step + 1) % 4),
      ),
      const SizedBox(height: GlossSpacing.large),
      GlossPageDots(
        pageCount: 4,
        page: _dot,
        onPageChanged: (i) => setState(() => _dot = i),
      ),
    ],
  );
}

class _Menus extends StatelessWidget {
  const _Menus();

  @override
  Widget build(BuildContext context) => GlossMenuBar(
    menus: [
      GlossMenuBarMenu('Plan', [
        GlossMenuItem(label: 'New week', shortcut: 'Ctrl N', onPressed: () {}),
        GlossMenuItem(label: 'Print the week', onPressed: () {}),
      ]),
      GlossMenuBarMenu('Edit', [
        GlossMenuItem(label: 'Undo', shortcut: 'Ctrl Z', onPressed: () {}),
        GlossMenuItem(
          label: 'Clear the week',
          isDestructiveAction: true,
          onPressed: () {},
        ),
      ]),
    ],
  );
}

class _Palette extends StatelessWidget {
  const _Palette();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420, maxHeight: 320),
    child: GlossCommandPalette(
      hintText: 'Type a command',
      commands: [
        GlossCommand(
          label: 'Find a recipe',
          group: 'Go',
          icon: LucideIcons.search,
          onPressed: () {},
        ),
        GlossCommand(
          label: 'Open the plan',
          group: 'Go',
          icon: LucideIcons.calendarDays,
          onPressed: () {},
        ),
        GlossCommand(
          label: 'New shopping list',
          group: 'Make',
          icon: LucideIcons.shoppingBasket,
          shortcut: 'Ctrl L',
          onPressed: () {},
        ),
      ],
    ),
  );
}
