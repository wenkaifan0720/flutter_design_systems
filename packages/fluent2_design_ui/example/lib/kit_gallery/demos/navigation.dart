/// Ways through an app past its tab bar and nav pane: the rail on a wide
/// window, a list's pages, a setup's steps, a tour's dots, the desktop's
/// menu bar and the command box.
library;

import 'package:material_ui/material_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import '../kit.dart';

Widget kitNavigationDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Rail, pages, steps & commands',
  sections: [
    kitSection('The app\'s shell', children: [kitSpecimenAppShell()]),
    kitSection('Navigation rail', children: [kitSpecimenNavigationRail()]),
    kitSection(
      'Nav pane beside the page',
      children: [
        kitSpecimenNavPaneBeside(),
        kitSpecimenNavPaneBeside(media: true),
      ],
    ),
    kitSection('Pages of results', children: [kitSpecimenPagination()]),
    kitSection('Steps', children: [kitSpecimenStepProgress()]),
    kitSection('Page dots', children: [kitSpecimenPageDots()]),
  ],
);

/// The app's frame: the places in a tab bar on a phone, the rail from 640
/// and the pane from 1024, the page beside them.
Widget kitSpecimenAppShell() {
  var at = 0;
  return StatefulBuilder(
    builder: (context, set) => SizedBox(
      height: 360,
      child: Fluent2AppShell(
        header: const Text('Northwind'),
        destinations: kitTabs,
        selectedIndex: at,
        onDestinationSelected: (i) => set(() => at = i),
        body: Fluent2Scaffold(
          topBar: Fluent2AppBar(title: kitTabs[at].label),
          body: const SizedBox(height: 120),
        ),
      ),
    ),
  );
}

Widget kitSpecimenNavigationRail() {
  var at = 1;
  return StatefulBuilder(
    builder: (context, set) => SizedBox(
      height: 320,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Fluent2NavigationRail(
            semanticLabel: 'Northwind',
            items: kitTabs,
            selectedIndex: at,
            onDestinationSelected: (i) => set(() => at = i),
          ),
          Expanded(
            child: Center(
              child: Builder(
                builder: (context) {
                  final t = context.fluent2Theme;
                  return Text(
                    kitTabs[at].label,
                    style: t.subtitle1.c(t.textPrimary),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The desktop's frame as the shell draws it: the nav pane at the start on
/// the ground and the page beside it on the content layer (folded to its
/// glyphs where the room is narrow). With [media], the pane of a media tab:
/// on the media ground, solid.
Widget kitSpecimenNavPaneBeside({bool media = false}) {
  var at = 0;
  return StatefulBuilder(
    builder: (context, set) => LayoutBuilder(
      builder: (context, box) {
        final pane = Fluent2NavigationDrawer(
          items: kitTabs,
          selectedIndex: at,
          onDestinationSelected: (i) => set(() => at = i),
          brand: 'Northwind',
          collapsed: box.maxWidth < 560,
          solid: media,
        );
        return SizedBox(
          height: 320,
          child: Fluent2Beside(
            pane: media ? Fluent2MediaGround(child: pane) : pane,
            child: Center(
              child: Builder(
                builder: (context) {
                  final t = context.fluent2Theme;
                  return Text(
                    kitTabs[at].label,
                    style: t.subtitle1.c(t.textPrimary),
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget kitSpecimenPagination() {
  var page = 3;
  return StatefulBuilder(
    builder: (context, set) => Fluent2Pagination(
      semanticLabel: 'Files',
      page: page,
      pages: 12,
      onChanged: (p) => set(() => page = p),
    ),
  );
}

Widget kitSpecimenStepProgress() => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.l,
  children: [
    Fluent2StepProgress(
      count: 4,
      currentStep: 1,
      name: 'Choose a plan',
      phase: 'Setup',
    ),
    Fluent2StepProgress(count: 4, currentStep: 3, name: 'Invite your team'),
  ],
);

Widget kitSpecimenPageDots() {
  var at = 1;
  return StatefulBuilder(
    builder: (context, set) => Fluent2PageDots(
      count: 4,
      selectedIndex: at,
      semanticLabel: 'Tour, page ${at + 1} of 4',
      onChanged: (i) => set(() => at = i),
    ),
  );
}
