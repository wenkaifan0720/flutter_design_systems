// A record's history down its rule, newest first, what a list says when
// it has nothing to show, and what a page says while it loads or when it
// cannot load.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitHistoryDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Timeline, empty & loading states',
  sections: [
    KitSection(
      title: 'Timeline',
      children: [
        CivicTimeline(
          entries: [
            CivicTimelineEntry(
              title: 'Permit approved',
              date: '7 November 2026',
              child: CivicLink(
                onPressed: () {},
                child: const Text('Download your permit'),
              ),
            ),
            const CivicTimelineEntry(
              title: 'Proof of address checked',
              date: '5 November 2026',
              child: Text('We matched your tenancy agreement to your address.'),
            ),
            const CivicTimelineEntry(
              title: 'Application received',
              date: '3 November 2026',
            ),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Empty state',
      children: [
        CivicEmptyState(
          title: 'You have no applications yet',
          actions: [
            CivicButton(
              onPressed: () {},
              child: const Text('Apply for a permit'),
            ),
          ],
          children: const [
            Text('When you apply for a permit, it will show here.'),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'No results',
      children: [
        CivicEmptyState(
          title: 'No streets match "Quillon"',
          children: [
            Text('Check the spelling, or search without the house number.'),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Loading',
      children: [CivicLoadingState(label: 'Loading your applications')],
    ),
    KitSection(
      title: 'Could not load',
      children: [
        CivicErrorState(
          title: 'Sorry, there is a problem with the service',
          message: 'Your applications could not be shown. Try again later.',
          onRetry: () {},
        ),
      ],
    ),
  ],
);
