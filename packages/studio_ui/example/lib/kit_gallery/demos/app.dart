import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

const _places = [
  StudioTab(LucideIcons.house, 'Home'),
  StudioTab(LucideIcons.libraryBig, 'Library'),
  StudioTab(LucideIcons.slidersHorizontal, 'Settings'),
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
          'The faceplate bar with its way back, the body on the brushed '
          'panel in the page margins, the one lit key fixed at the foot on '
          'the bar metal.',
      children: [_Framed(height: 460, child: kitSpecimenScreen())],
    ),
    KitSection(
      title: 'Places and the act',
      note:
          'The key bank on a phone (a rail on a tablet, the side panel on a '
          'desk); the act is the graphite floating key over the page, which '
          'keeps it clear.',
      children: [_Framed(height: 500, child: kitSpecimenAppShell())],
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

/// A whole screen set into the page, behind a machined edge.
class _Framed extends StatelessWidget {
  const _Framed({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: StudioSurface(
      face: context.studioTheme.colors.recessFace,
      child: Padding(
        padding: const EdgeInsets.all(StudioMetrics.recessInset),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            StudioRadii.panel - StudioMetrics.recessInset,
          ),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            child: child,
          ),
        ),
      ),
    ),
  );
}

// Catalog specimens: one still per part, drawn the same in every preset;
// the stage chooses the preset.

Widget kitSpecimenScreen() => Builder(
  builder: (context) {
    final t = context.studioTheme;
    return StudioScreen(
      topBar: StudioAppBar(
        title: 'Episode',
        leading: StudioIconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          tooltip: 'Back',
          onPressed: () => kitFeedback(context, 'Back to the Library.'),
        ),
      ),
      footer: StudioButton.lit(
        'Play episode',
        icon: const Icon(LucideIcons.play),
        onPressed: () => kitFeedback(context, 'Playing from the start.'),
      ),
      body: StudioDisplay(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Episode 42',
              style: t.textTheme.secondary.copyWith(
                color: t.colors.onDisplayMuted,
              ),
            ),
            const SizedBox(height: StudioSpacing.small),
            Text(
              'Rooms that sound right',
              style: t.textTheme.headline.copyWith(color: t.colors.onDisplay),
            ),
            const SizedBox(height: StudioSpacing.medium),
            const StudioReadout('38:12', unit: 'min'),
          ],
        ),
      ),
    );
  },
);

Widget kitSpecimenAppShell() => kitState<int>(
  0,
  (context, index, change) => StudioAppShell(
    tabs: _places,
    selectedIndex: index,
    onSelected: change,
    brand: 'Roomtone',
    action: StudioShellAction(
      icon: LucideIcons.mic,
      label: 'New recording',
      onPressed: (context) => kitFeedback(context, 'Recording starts here.'),
    ),
    child: StudioScreen(
      body: Builder(
        builder: (context) {
          final t = context.studioTheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _places[index].label,
                style: t.textTheme.headline.copyWith(color: t.colors.legend),
              ),
              const SizedBox(height: StudioSpacing.regular),
              const StudioDisplay(
                child: Text('Three new episodes since Monday, one in drafts.'),
              ),
            ],
          );
        },
      ),
    ),
  ),
);

Widget kitSpecimenLoadingState() => const StudioLoadingState();

Widget kitSpecimenErrorState() => Builder(
  builder: (context) => StudioErrorState(
    title: 'Could not load the library',
    message: 'Check your connection, then try again.',
    onRetry: () => kitFeedback(context, 'Trying again.'),
  ),
);

Widget kitSpecimenInput() => Builder(
  builder: (context) => StudioInput(
    hint: 'Search episodes',
    onSubmitted: (text) => kitFeedback(context, 'Searching for "$text".'),
  ),
);
