/// A region with its own quiet scrollbar, and two panes a divider resizes,
/// live.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';

import '../kit.dart';

const List<String> _notes = [
  '1.4.0 — Calendar picks a range across two months.',
  '1.3.2 — The data table keeps its selection across pages.',
  '1.3.1 — Toasts pause while a pointer rests on them.',
  '1.3.0 — The menu bar opens its submenus on the arrow keys.',
  '1.2.4 — A colour picker reads and writes hex.',
  '1.2.3 — Split buttons take a danger action under a hairline.',
  '1.2.2 — Sheets come from either side.',
  '1.2.1 — A carousel stops playing under Reduce Motion.',
  '1.2.0 — Tree views open every sibling on *.',
  '1.1.0 — Rows reorder from the keyboard with Alt and the arrows.',
];

// The version in mono, as every figure: its digits keep one width, so the
// dashes after them stand in one column.
Widget _note(BuildContext context, String line) {
  final t = context.minimalTheme;
  final (version, rest) = switch (line.indexOf(' ')) {
    -1 => (line, ''),
    final i => (line.substring(0, i), line.substring(i)),
  };
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s8),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: version,
            style: t.mono
                .c(t.foreground)
                .copyWith(fontSize: t.bodySmall.fontSize),
          ),
          TextSpan(text: rest),
        ],
      ),
      style: t.bodySmall.c(t.foreground),
    ),
  );
}

// A pane stands on the card's own ground: a fill of its own would paint over
// the card's rounded rim at its corners.
Widget _pane(BuildContext context, String title, String body) => Container(
  padding: const EdgeInsets.all(MinimalSpacing.s12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: context.minimalTheme.label),
      const MinimalGap(MinimalSpacing.s8),
      Text(
        body,
        style: context.minimalTheme.bodySmall.c(
          context.minimalTheme.mutedForeground,
        ),
      ),
    ],
  ),
);

Widget kitPanesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Scroll area & resizable',
  sections: [
    kitSection(
      'Scroll area',
      children: [
        Builder(
          // The card adds no padding of its own: the area's padding scrolls
          // with the notes, so they run under the frame's edge and the next
          // one peeks there (a padded card had cut them a band short).
          builder: (context) => MinimalCard(
            padding: EdgeInsets.zero,
            child: MinimalScrollArea(
              height: 200,
              padding: const EdgeInsets.all(MinimalCard.inset),
              label: 'Release notes',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final n in _notes) _note(context, n)],
              ),
            ),
          ),
        ),
        kitNote(
          'The bar shows while it scrolls or a pointer rests on it; the '
          'region is a tab stop the arrows scroll.',
        ),
      ],
    ),
    kitSection(
      'Resizable',
      children: [
        Builder(
          builder: (context) => SizedBox(
            height: 260,
            child: MinimalCard(
              padding: EdgeInsets.zero,
              child: MinimalResizable(
                initialFraction: 0.4,
                minFirst: 120,
                minSecond: 160,
                handle: true,
                first: _pane(context, 'INBOX', '12\u00a0threads'),
                // The thread over a shorter reply, so this divider meets
                // the upright one below its grip, not on it; the frame is
                // tall enough that the reply keeps its words at 200%.
                second: MinimalResizable(
                  axis: Axis.vertical,
                  initialFraction: 0.6,
                  minFirst: 60,
                  minSecond: 60,
                  handle: true,
                  first: _pane(context, 'THREAD', 'Ana Souza · 3 replies'),
                  second: _pane(context, 'REPLY', 'Write a reply…'),
                ),
              ),
            ),
          ),
        ),
        kitNote(
          'Drag a divider, or tab to it and use the arrows; Enter folds the '
          'first pane away and back.',
        ),
      ],
    ),
  ],
);
