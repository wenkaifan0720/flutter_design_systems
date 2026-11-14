/// The commit strip in each register: a mono figure (with its words in
/// Geist when it has any) and its prose line beside the action, the action alone at full width, busy, standing on its
/// own card — and the footer placement a page gives it: docked at the
/// bottom of this page standalone, on an example page in a screen of its
/// own, so the dock never cuts the strips above it.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';

import '../kit.dart';

/// The strip a screen docks as its footer.
Widget _docked() => MinimalActionBar(
  summaryContent: const _Summary('3/5', ' kept', 'Two to go today'),
  label: 'Log all',
  onPressed: () {},
);

Widget kitActionBarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Action bar',
  bottom: kitEmbedded ? null : _docked(),
  sections: [
    kitSection(
      'Summary and action',
      children: [
        MinimalActionBar(
          summary: '€1,284',
          detail: '38 orders · 6 open',
          label: 'Close day',
          onPressed: () {},
        ),
      ],
    ),
    kitSection(
      'Action alone',
      children: [MinimalActionBar(label: 'Create habit', onPressed: () {})],
    ),
    kitSection(
      'Busy',
      children: [
        MinimalActionBar(
          summary: '21:30',
          detail: 'Stretch before bed · every evening',
          label: 'Create habit',
          busy: true,
          busyLabel: 'Creating…',
          onPressed: () {},
        ),
      ],
    ),
    kitSection(
      'Floating',
      children: [
        MinimalActionBar(
          summaryContent: const _Summary(
            '2',
            ' selected',
            'Morning run, Journal',
          ),
          label: 'Archive',
          floating: true,
          onPressed: () {},
        ),
      ],
    ),
    if (kitEmbedded)
      kitSection(
        'Docked',
        children: [
          KitRouteFrame(
            // Room for the summary stacking over its act at the largest
            // text.
            height: 250,
            page: MinimalScaffold(
              topBar: const MinimalAppBar(
                title: 'Today',
                subtitle: 'Fri 28 Aug',
              ),
              footer: _docked(),
              body: Builder(
                builder: (context) {
                  final t = context.minimalTheme;
                  return Text(
                    'Journal and Drink water are still to log.',
                    style: t.bodySmall.c(t.mutedForeground),
                  );
                },
              ),
            ),
          ),
          kitNote(
            'The screen\'s footer: docked on the ground over a hairline, '
            'clear of the home indicator.',
          ),
        ],
      )
    else
      kitNote(
        'The strip below is the screen\'s footer: docked on the ground over '
        'a hairline, clear of the home indicator.',
      ),
  ],
);

/// A summary that mixes a figure with words: the figure in the mono
/// figure face, the words after it in Geist, the prose line under both.
class _Summary extends StatelessWidget {
  const _Summary(this.figure, this.words, this.detail);

  final String figure;
  final String words;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: figure, style: t.figure),
              TextSpan(text: words, style: t.bodyLarge.c(t.mutedForeground)),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          detail,
          style: t.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style. A docked bar is drawn as its screen's
// footer, so the ground, the hairline and the safe area are the screen's.

/// The day's total beside the action, docked as a screen's footer.
Widget kitSpecimenActionBarDocked() => MinimalScaffold(
  body: const SizedBox.shrink(),
  footer: MinimalActionBar(
    summary: '€1,284',
    detail: '38 orders · 6 open',
    label: 'Close day',
    onPressed: () {},
  ),
);

/// The action alone, taking the whole width of the footer.
Widget kitSpecimenActionBarAlone() => MinimalScaffold(
  body: const SizedBox.shrink(),
  footer: MinimalActionBar(label: 'Create habit', onPressed: () {}),
);

/// A composed summary on the bar's own card, for a body that keeps its
/// edges.
Widget kitSpecimenActionBarFloating() => MinimalActionBar(
  summaryContent: const _Summary('2', ' selected', 'Morning run, Journal'),
  label: 'Archive',
  floating: true,
  onPressed: () {},
);
