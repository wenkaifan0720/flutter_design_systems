import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

const _places = [
  BrutalTab(LucideIcons.house, 'Home'),
  BrutalTab(LucideIcons.calendar, 'Events'),
  BrutalTab(LucideIcons.ticket, 'Tickets'),
  BrutalTab(LucideIcons.user, 'You'),
];

/// The app frame: a page, the app's places and act round a root, a page
/// waiting or failed, and the plain field.
Widget kitAppDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'App frame',
  sections: [
    KitSection(
      title: 'A page',
      note:
          'The bar with its way back, the body in the page margins, the one '
          'action fixed at the foot on a rule.',
      children: [_Framed(height: 420, child: kitSpecimenScreen())],
    ),
    KitSection(
      title: 'Places and the act',
      note:
          'The bar of places on a phone (a rail on a tablet, the side list on '
          'a desktop); the act is the signal square over the page, which '
          'keeps it clear.',
      children: [_Framed(height: 480, child: kitSpecimenAppShell())],
    ),
    KitSection(
      title: 'Waiting and failed',
      note: 'A whole page waiting, and one that could not load.',
      children: [
        SizedBox(height: 200, child: kitSpecimenLoadingState()),
        kitSpecimenErrorState(),
      ],
    ),
    KitSection(
      title: 'The plain field',
      note: 'A field with only a hint; on a page of your own, a text field.',
      children: [kitSpecimenInput()],
    ),
  ],
);

/// A whole screen drawn in a box of the page, in its rule.
class _Framed extends StatelessWidget {
  const _Framed({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: BrutalSurface(
      face: BrutalFace(
        fill: context.brutalTheme.colors.paper,
        border: context.brutalTheme.colors.ink,
        foreground: context.brutalTheme.colors.ink,
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: ClipRect(child: child),
      ),
    ),
  );
}

Widget kitSpecimenScreen() => Builder(
  builder: (context) {
    final t = context.brutalTheme.textTheme;
    return BrutalScreen(
      topBar: BrutalAppBar(
        title: 'Low Tide',
        onBack: () => kitFeedback(context, 'Back to Events.'),
      ),
      footer: BrutalButton.filled(
        'Buy tickets',
        onPressed: () => kitFeedback(context, 'Two tickets held.'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sat 21 Nov · Hall 4', style: t.secondary),
          const SizedBox(height: BrutalSpacing.small),
          Text('Low Tide', style: t.headline),
          const SizedBox(height: BrutalSpacing.regular),
          Text(
            'Doors at 19:00, the band at 20:00. Standing only; the bar '
            'closes at 23:30.',
            style: t.body,
          ),
        ],
      ),
    );
  },
);

Widget kitSpecimenAppShell() => kitState<int>(
  0,
  (context, index, change) => BrutalAppShell(
    tabs: _places,
    selectedIndex: index,
    onSelected: change,
    brand: 'Admit',
    action: BrutalShellAction(
      icon: LucideIcons.plus,
      label: 'New event',
      onPressed: (context) => kitFeedback(context, 'A new event opens here.'),
    ),
    child: BrutalScreen(
      body: Builder(
        builder: (context) {
          final t = context.brutalTheme.textTheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_places[index].label, style: t.headline),
              const SizedBox(height: BrutalSpacing.regular),
              Text(
                'Three nights this week, two of them sold out.',
                style: t.body,
              ),
            ],
          );
        },
      ),
    ),
  ),
);

Widget kitSpecimenLoadingState() => const BrutalLoadingState();

Widget kitSpecimenErrorState() => Builder(
  builder: (context) => BrutalErrorState(
    title: 'Could not load tonight',
    message: 'Check your connection, then try again.',
    onRetry: () => kitFeedback(context, 'Trying again.'),
  ),
);

Widget kitSpecimenInput() => Builder(
  builder: (context) => BrutalInput(
    hint: 'Search events',
    onSubmitted: (text) => kitFeedback(context, 'Searching for "$text".'),
  ),
);
