/// Minimal's view switchers: the bordered segmented control (expanded
/// driving its content, hugging beside a heading, small, four-way and
/// disabled) and the underline tabs, with mono counts over the section they
/// pick, and scrolling.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import '../kit.dart';

Widget kitSegmentedTabsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Segmented & tabs',
  sections: [
    kitSection(
      'Segmented · expanded',
      children: [
        const _Range(),
        kitNote(
          'It spans a phone\'s column; from a tablet up it stops at '
          '320 px, on its start, and what it drives keeps its measure.',
        ),
      ],
    ),
    kitSection('Segmented · beside a heading', children: const [_Layout()]),
    kitSection(
      'Segmented · four views',
      children: [
        MinimalSegmentedButton(
          segments: const [
            MinimalButtonSegment(0, 'Day'),
            MinimalButtonSegment(1, 'Week'),
            MinimalButtonSegment(2, 'Month'),
            MinimalButtonSegment(3, 'Year'),
          ],
          value: 2,
          label: 'Range',
          onChanged: (_) {},
        ),
      ],
    ),
    kitSection(
      'Segmented · disabled',
      children: const [
        MinimalSegmentedButton(
          segments: [
            MinimalButtonSegment(0, 'Streak'),
            MinimalButtonSegment(1, 'Total'),
          ],
          value: 0,
          label: 'Metric',
        ),
      ],
    ),
    kitSection('Tabs · with counts', children: const [_DetailTabs()]),
    // Every strip stands as the lists do: edge to edge on a phone, so a
    // strip that outruns the width runs into the screen's edge, as the
    // filter bar's does; on the column's keylines in a wider window.
    kitSection(
      'Tabs · scrolling',
      children: [
        _bleed(
          (inset) => MinimalTabBar(
            tabs: const [
              'All habits',
              'Morning',
              'Evening',
              'Weekends',
              'Paused',
              'Archived',
            ],
            counts: const [6, 3, 2, 1, 1, 0],
            selectedIndex: 1,
            padding: inset,
            onChanged: (_) {},
          ),
        ),
      ],
    ),
    kitSection(
      'Tabs · disabled',
      children: [
        _bleed(
          (inset) => MinimalTabBar(
            tabs: const ['Overview', 'History'],
            selectedIndex: 0,
            padding: inset,
          ),
        ),
      ],
    ),
  ],
);

/// A strip under a [KitBleed], handed the inset its labels take.
Widget _bleed(Widget Function(EdgeInsets inset) strip) => KitBleed(
  child: Builder(builder: (context) => strip(KitBleed.inset(context))),
);

/// A full-width range switch whose content follows it.
class _Range extends StatefulWidget {
  const _Range();

  @override
  State<_Range> createState() => _RangeState();
}

class _RangeState extends State<_Range> {
  int _view = 1;

  // Figures only in the mono face: `23/28`, the words after it in Geist.
  static const _kept = ['6/6', '23/28', '71/82'];
  static const _rate = ['100%', '82%', '87%'];

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // The figures it drives keep the control's measure, so the rate ends
    // where the control does rather than across the page.
    return MinimalLayout.capControl(context, _content(t));
  }

  Widget _content(MinimalThemeData t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalSegmentedButton(
          segments: const [
            MinimalButtonSegment(0, 'Week'),
            MinimalButtonSegment(1, 'Month'),
            MinimalButtonSegment(2, '12 weeks'),
          ],
          value: _view,
          label: 'Range',
          onChanged: (v) => setState(() => _view = v),
        ),
        const MinimalGap(MinimalSpacing.s12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(_kept[_view], style: t.figure),
            const MinimalGap(MinimalSpacing.s8),
            Expanded(
              child: Text(
                'days kept',
                style: t.bodySmall.c(t.mutedForeground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(_rate[_view], style: t.mono.c(t.mutedForeground)),
          ],
        ),
      ],
    );
  }
}

/// A heading with a small hugging segmented control at its end.
class _Layout extends StatefulWidget {
  const _Layout();

  @override
  State<_Layout> createState() => _LayoutState();
}

class _LayoutState extends State<_Layout> {
  int _view = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Habits',
            style: t.h2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        MinimalSegmentedButton(
          segments: const [
            MinimalButtonSegment(0, 'List'),
            MinimalButtonSegment(1, 'Board'),
          ],
          value: _view,
          label: 'Layout',
          small: true,
          expand: false,
          onChanged: (v) => setState(() => _view = v),
        ),
      ],
    );
  }
}

/// A habit page's sections, as on a detail page: tabs with counts over the
/// section they pick, the hairline edge to edge on a phone and on the
/// column's keylines in a wider window.
class _DetailTabs extends StatefulWidget {
  const _DetailTabs();

  @override
  State<_DetailTabs> createState() => _DetailTabsState();
}

class _DetailTabsState extends State<_DetailTabs> {
  int _tab = 1;

  static const _overview = ['Every day', '07:00', 'Started 2026-06-02'];
  static const _notes = [
    'Out the door before 8.',
    'Any distance counts.',
    'Shoes by the door.',
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // Edge to edge on a phone, on the column's keylines in a wider window:
    // the labels and lines take the inset the KitBleed hands them.
    return KitBleed(
      child: Builder(builder: (context) => _sections(context, t)),
    );
  }

  Widget _sections(BuildContext context, MinimalThemeData t) {
    final inset = KitBleed.inset(context);
    // Every section's rows run as the strip's hairline does: edge to edge
    // on a phone, their words on the gutter.
    Widget row(Widget child) => Container(
      height: t.rowHeightCompact,
      padding: inset,
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(border: Border(bottom: t.rule)),
      child: child,
    );
    Widget line(String text, TextStyle style) => row(
      Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalTabBar(
          tabs: const ['Overview', 'Activity', 'Notes'],
          counts: const [null, 12, 3],
          selectedIndex: _tab,
          padding: inset,
          onChanged: (v) => setState(() => _tab = v),
        ),
        if (_tab == 0)
          for (final (i, text) in _overview.indexed)
            // The reminder is a time: mono. The rest are words.
            line(text, i == 1 ? t.mono : t.bodySmall),
        if (_tab == 1)
          // The log as the audit trail prints it: a mono time column as
          // wide as the larger text needs, the event in the body face.
          for (final (at, event) in _activity)
            row(
              Row(
                children: [
                  SizedBox(
                    width: MediaQuery.textScalerOf(context).scale(_stamp),
                    child: Text(
                      MinimalFormat.stamp(at),
                      style: t.mono.c(t.mutedForeground),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  const MinimalGap(10),
                  Expanded(
                    child: Text(
                      event,
                      style: t.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        if (_tab == 2)
          for (final text in _notes) line(text, t.bodySmall),
      ],
    );
  }

  /// The activity's time column, at the default text size.
  static const double _stamp = 92;

  static final List<(DateTime, String)> _activity = [
    (DateTime(2026, 8, 28, 7, 12), 'Marked done'),
    (DateTime(2026, 8, 27, 7, 40), 'Note added'),
    (DateTime(2026, 8, 26, 6, 58), 'Marked done'),
  ];
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// Three views of the same content, sharing the whole width.
Widget kitSpecimenSegmentedFull() => MinimalSegmentedButton(
  segments: const [
    MinimalButtonSegment(0, 'Week'),
    MinimalButtonSegment(1, 'Month'),
    MinimalButtonSegment(2, 'Year'),
  ],
  value: 1,
  label: 'Range',
  onChanged: (_) {},
);

/// The small control hugging its labels, beside a heading.
Widget kitSpecimenSegmentedBeside() => Builder(
  builder: (context) {
    final t = context.minimalTheme;
    return Row(
      children: [
        Expanded(child: Text('Habits', style: t.h2, maxLines: 1)),
        MinimalSegmentedButton(
          segments: const [
            MinimalButtonSegment(0, 'List'),
            MinimalButtonSegment(1, 'Board'),
          ],
          value: 0,
          label: 'Layout',
          small: true,
          expand: false,
          onChanged: (_) {},
        ),
      ],
    );
  },
);

/// A detail page's sections with their counts, full bleed on the
/// page's hairline.
Widget kitSpecimenTabsCounts() => _Body(
  bleed: true,
  child: MinimalTabBar(
    tabs: const ['Overview', 'Activity', 'Notes'],
    counts: const [null, 12, 3],
    selectedIndex: 1,
    padding: MinimalInsets.gutter,
    onChanged: (_) {},
  ),
);

/// More sections than the width holds: the strip scrolls sideways.
Widget kitSpecimenTabsScroll() => MinimalTabBar(
  tabs: const ['All habits', 'Morning', 'Evening', 'Weekends', 'Paused'],
  counts: const [6, 3, 2, 1, 1],
  selectedIndex: 1,
  onChanged: (_) {},
);

/// Lays a specimen out as a scrolling page body does: its own height,
/// however tall the stage — and with [bleed] edge to edge past the stage's
/// gutter, as on a `MinimalScaffold(padding: EdgeInsets.zero)` page.
class _Body extends StatelessWidget {
  const _Body({required this.child, this.bleed = false});

  final Widget child;
  final bool bleed;

  @override
  Widget build(BuildContext context) => UnconstrainedBox(
    constrainedAxis: Axis.horizontal,
    child: !bleed
        ? child
        : LayoutBuilder(
            builder: (context, c) => FractionallySizedBox(
              widthFactor:
                  (c.maxWidth + 2 * MinimalChromeMetrics.gutter) / c.maxWidth,
              child: child,
            ),
          ),
  );
}
