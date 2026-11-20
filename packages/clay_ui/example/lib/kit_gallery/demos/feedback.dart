/// Clay's feedback: bars, rings, the spinner, banners and whole-card states.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';

import '../kit.dart';

/// The feedback page.
Widget kitFeedbackDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Feedback',
  sections: const [
    KitSection(
      title: 'Bars',
      note: 'A groove that fills with a coral volume.',
      maxWidth: 420,
      children: [
        ClayProgressBar(value: 0.62, semanticLabel: 'Weekly goal'),
        ClayProgressBar(value: 0.3, semanticLabel: 'Water', height: 8),
      ],
    ),
    KitSection(title: 'Rings', children: [_Rings()]),
    KitSection(
      title: 'Waiting',
      children: [ClaySpinner(semanticLabel: 'Loading habits')],
    ),
    KitSection(
      title: 'Banners',
      note:
          'A slab across the page with a ball for its tone; a failure says '
          'what still holds and what to do.',
      children: [_Banners()],
    ),
    KitSection(
      title: 'Empty, failed, loading, done',
      note: 'A whole card given to one state: a ball, a line, a way on.',
      children: [_States()],
    ),
  ],
);

class _Rings extends StatelessWidget {
  const _Rings();

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    return KitRow(
      children: [
        ClayProgressRing(
          value: 0.6,
          semanticLabel: 'Today',
          child: Text('3/5', style: theme.textTheme.headline),
        ),
        ClayProgressRing(
          value: 0.85,
          size: 72,
          thickness: 10,
          color: theme.colors.success,
          semanticLabel: 'Walks',
        ),
      ],
    );
  }
}

class _Banners extends StatelessWidget {
  const _Banners();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const ClayBanner(
        title: 'Reminders are off',
        message: 'Turn them on in Settings to be nudged.',
        tone: ClayBannerTone.warning,
      ),
      const SizedBox(height: ClaySpacing.regular),
      ClayBanner(
        title: 'Sync failed',
        message: 'Your ticks are safe on this phone.',
        tone: ClayBannerTone.danger,
        actions: [ClayButton('Try again', onPressed: () {})],
      ),
      const SizedBox(height: ClaySpacing.regular),
      const ClayBanner(
        title: 'A week kept',
        message: 'Seven days of water in a row.',
        tone: ClayBannerTone.success,
      ),
      const SizedBox(height: ClaySpacing.regular),
      const ClayBanner(
        title: 'New: check-ins',
        message: 'Log how the day feels beside your habits.',
      ),
    ],
  );
}

class _States extends StatelessWidget {
  const _States();

  @override
  Widget build(BuildContext context) {
    final views = [
      ClayStateView(
        state: ClayState.empty,
        title: 'No habits yet',
        message: 'Start with one small thing.',
        actions: [ClayButton.filled('New habit', onPressed: () {})],
      ),
      ClayStateView(
        state: ClayState.error,
        title: 'Sync failed',
        message: 'Your habits are safe on this phone.',
        actions: [ClayButton('Try again', onPressed: () {})],
      ),
      const ClayStateView(state: ClayState.loading, title: 'Loading your week'),
      const ClayStateView(
        state: ClayState.success,
        title: 'All done today',
        message: 'Every habit ticked. See you tomorrow.',
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 600 ? 2 : 1;
        final rows = <Widget>[];
        for (var i = 0; i < views.length; i += columns) {
          if (i > 0) rows.add(const SizedBox(height: ClaySpacing.regular));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = i; j < i + columns && j < views.length; j++) ...[
                    if (j > i) const SizedBox(width: ClaySpacing.regular),
                    Expanded(child: ClayCard(child: views[j])),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
