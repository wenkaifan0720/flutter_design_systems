/// [FrostedNavigationRail], [FrostedBreadcrumb], [FrostedPagination],
/// [FrostedStepProgress] and [FrostedPageDots]: the ways through a place.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitMoveDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Rail, breadcrumb & pages',
  sections: [
    kitSection(
      'Navigation rail',
      children: [
        // The rail stands down a window's start edge: here a small window,
        // its corners rounded, tall enough for every destination at the
        // text size in force (larger text grows each one).
        Builder(
          builder: (context) {
            final grow = MediaQuery.textScalerOf(context).scale(1) - 1;
            return ClipRRect(
              borderRadius: BorderRadius.circular(FrostedCorners.r18),
              child: SizedBox(
                height: 420 + 220 * grow,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: KitHeld<int>(
                    0,
                    (i, set) => FrostedNavigationRail(
                      label: 'Sections',
                      items: sampleTabs,
                      selectedIndex: i,
                      onDestinationSelected: set,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    kitSection(
      'Breadcrumb',
      children: [
        FrostedBreadcrumb(
          items: [
            FrostedBreadcrumbItem('Home', onPressed: () {}),
            FrostedBreadcrumbItem('Projects', onPressed: () {}),
            const FrostedBreadcrumbItem('Launch plan'),
          ],
        ),
      ],
    ),
    kitSection(
      'Pagination',
      children: [
        KitHeld<int>(
          0,
          (i, set) =>
              FrostedPagination(pageCount: 4, selectedIndex: i, onChanged: set),
        ),
        KitHeld<int>(
          6,
          (i, set) => FrostedPagination(
            pageCount: 24,
            selectedIndex: i,
            onChanged: set,
          ),
        ),
      ],
    ),
    kitSection(
      'Steps',
      children: const [
        FrostedStepProgress(
          count: 4,
          currentStep: 1,
          name: 'Shipping',
          phase: 'Step 2 of 4',
        ),
      ],
    ),
    kitSection(
      'Page dots',
      children: [
        Center(
          child: KitHeld<int>(
            1,
            (i, set) => FrostedPageDots(
              count: 5,
              selectedIndex: i,
              label: 'Welcome pages',
              onChanged: set,
            ),
          ),
        ),
      ],
    ),
  ],
);

/// The way to a card.
Widget kitSpecimenBreadcrumb() => FrostedBreadcrumb(
  items: [
    FrostedBreadcrumbItem('Home', onPressed: () {}),
    FrostedBreadcrumbItem('Cards', onPressed: () {}),
    const FrostedBreadcrumbItem('Everyday · 4821'),
  ],
);

/// The five places on a rail, Home current.
Widget kitSpecimenNavigationRail() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: FrostedNavigationRail(
    items: sampleTabs,
    selectedIndex: 0,
    onDestinationSelected: (_) {},
  ),
);

/// The second of four pages.
Widget kitSpecimenPageDots() => Center(
  heightFactor: 1,
  child: FrostedPageDots(
    count: 4,
    selectedIndex: 1,
    label: 'Welcome',
    onChanged: (_) {},
  ),
);

/// Page three of twelve.
Widget kitSpecimenPagination() => Center(
  heightFactor: 1,
  child: FrostedPagination(pageCount: 12, selectedIndex: 2, onChanged: (_) {}),
);

/// The first of four steps.
Widget kitSpecimenStepProgress() =>
    const FrostedStepProgress(count: 4, currentStep: 1, name: 'Amount');
