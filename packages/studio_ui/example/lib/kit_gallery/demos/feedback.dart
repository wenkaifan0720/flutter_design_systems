import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

import '../kit.dart';

/// Lamps and progress: what says how far, or that something waits.
Widget kitFeedbackDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Lamps and progress',
  sections: [
    const KitSection(
      title: 'Progress',
      note: 'LED segments behind glass, lit as far as done; with no figure a lit run sweeps.',
      children: [
        StudioProgressBar(value: 0.64, semanticLabel: 'Uploading'),
        StudioProgressBar(semanticLabel: 'Preparing'),
      ],
    ),
    const KitSection(
      title: 'Spinners',
      note: 'A ring of lamps, one chasing round; a lamp ring shows a figure.',
      children: [
        KitRow(
          children: [
            StudioSpinner(semanticLabel: 'Loading'),
            StudioSpinner(size: 20, semanticLabel: 'Loading'),
            StudioLampRing(lit: 0.7, semanticLabel: 'Seventy per cent'),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Skeleton',
      note: 'Glass breathing where words will be.',
      children: [
        StudioSkeleton(width: 280, height: 20),
        StudioSkeleton(width: 200),
        StudioSkeleton(width: 240),
      ],
    ),
    KitSection(
      title: 'Banner',
      note: 'A strip across the top of a pane: a lamp, the words, an action.',
      children: [
        Builder(
          builder: (context) => StudioBanner(
            message: 'A new mix of episode 12 is ready.',
            actionLabel: 'Listen',
            onAction: () => kitFeedback(context, 'Playing the new mix'),
            onClose: () => kitFeedback(context, 'Closed'),
          ),
        ),
        Builder(
          builder: (context) => StudioBanner(
            title: 'Offline',
            message: 'Episodes you downloaded still play.',
            danger: true,
            actionLabel: 'Retry',
            onAction: () => kitFeedback(context, 'Trying again'),
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Status views',
      note: 'Empty, failed and loading, each in a pane of its own.',
      children: [
        Builder(
          builder: (context) => StudioStatusView(
            title: 'No episodes yet',
            message: 'Record one, or import a file.',
            actionLabel: 'Record',
            onAction: () => kitFeedback(context, 'Recording'),
          ),
        ),
        Builder(
          builder: (context) => StudioStatusView.error(
            title: 'Upload failed',
            message: 'The connection dropped at 64%.',
            actionLabel: 'Try again',
            onAction: () => kitFeedback(context, 'Uploading again'),
          ),
        ),
        const StudioStatusView.loading(title: 'Fetching your shows'),
      ],
    ),
  ],
);
