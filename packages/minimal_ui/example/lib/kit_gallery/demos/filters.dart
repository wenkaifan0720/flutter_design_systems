/// Count filters: the Today strip filtering its rows live, the bakery's
/// strip with a display control held at the end, filters by status glyph,
/// a disabled empty view, a strip that outruns the width and scrolls, and
/// one without its hairline where a table header follows.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitFiltersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Filter bar',
  sections: [
    kitSection('Filtering a list', children: const [_TodayList()]),
    kitSection(
      'With a trailing control',
      children: [
        _Strip(
          filters: const [('Open', 6), ('Ready', 9), ('Done', 23)],
          trailing: MinimalIconButton(
            LucideIcons.slidersHorizontal,
            label: 'Display options',
            variant: MinimalIconButtonVariant.outline,
            size: MinimalButtonSize.small,
            onPressed: () {},
          ),
        ),
      ],
    ),
    kitSection(
      'By status',
      children: const [
        _Strip(
          filters: [('Todo', 4), ('In progress', 2), ('Done', 11)],
          statuses: [
            MinimalTaskStatus.todo,
            MinimalTaskStatus.active,
            MinimalTaskStatus.done,
          ],
        ),
      ],
    ),
    kitSection(
      'Disabled and uncounted',
      children: [
        KitBleed(
          child: Builder(
            builder: (context) => MinimalFilterBar(
              padding: _inset(context),
              children: [
                MinimalFilter('Everything', selected: true, onPressed: () {}),
                MinimalFilter('Mine', onPressed: () {}),
                const MinimalFilter('Archived', count: 0),
              ],
            ),
          ),
        ),
        kitNote('A view with nothing in it yet stays visible, disabled.'),
      ],
    ),
    kitSection(
      'Outrunning the width',
      children: [
        // A phone's width at any window: the screen itself on a phone, 320
        // on the column's start from a tablet up, so the six filters always
        // outrun it.
        Builder(
          builder: (context) => MinimalLayout.capControl(
            context,
            const _Strip(
              filters: [
                ('Backlog', 14),
                ('Todo', 8),
                ('In progress', 3),
                ('Review', 2),
                ('Done', 41),
                ('Cancelled', 5),
              ],
            ),
          ),
        ),
        kitNote('Past the width the strip scrolls sideways, its edge faded.'),
      ],
    ),
    kitSection(
      'No hairline',
      children: const [
        _Strip(
          filters: [('All', 38), ('Late', 2), ('Baking', 2)],
          divider: false,
        ),
      ],
    ),
  ],
);

/// A strip's inset under a [KitBleed]: the side its rows take (the gutter
/// on a phone, none on a wider window's column), the strip's own air above
/// and below.
EdgeInsetsDirectional _inset(BuildContext context) =>
    EdgeInsetsDirectional.symmetric(
      horizontal: KitBleed.inset(context).left,
      vertical: MinimalFilterBar.defaultPadding.top,
    );

/// A live strip over nothing: it holds its own selection.
class _Strip extends StatefulWidget {
  const _Strip({
    required this.filters,
    this.statuses,
    this.trailing,
    this.divider = true,
  });

  final List<(String, int)> filters;
  final List<MinimalTaskStatus>? statuses;
  final Widget? trailing;
  final bool divider;

  @override
  State<_Strip> createState() => _StripState();
}

class _StripState extends State<_Strip> {
  // The first filter is on, so its frame stands on the keyline every
  // strip's first item stands on.
  int _view = 0;

  // Full bleed on a phone, as a strip stands over a list: its inset lives in
  // the scroll's padding, so a strip that outruns the width runs into the
  // screen's edge and the next filter shows, faded, beyond it. In a wider
  // window it stands in the column, as the lists do.
  @override
  Widget build(BuildContext context) => KitBleed(
    child: Builder(
      builder: (context) => MinimalFilterBar(
        trailing: widget.trailing,
        divider: widget.divider,
        padding: _inset(context),
        children: [
          for (final (i, (label, count)) in widget.filters.indexed)
            MinimalFilter(
              label,
              count: count,
              leading: switch (widget.statuses) {
                final statuses? => MinimalStatusIcon(
                  statuses[i],
                  size: MinimalIconSize.i14,
                ),
                null => null,
              },
              selected: i == _view,
              onPressed: () => setState(() => _view = i),
            ),
        ],
      ),
    ),
  );
}

typedef _Habit = ({String name, String state, int streak});

const List<_Habit> _habits = [
  (name: 'Meditate', state: 'Done', streak: 4),
  (name: 'Morning run', state: 'Done', streak: 12),
  (name: 'Drink water', state: 'Open', streak: 10),
  (name: 'Journal', state: 'Open', streak: 3),
  (name: 'Read 20 pages', state: 'Done', streak: 6),
  (name: 'Water the plants', state: 'Paused', streak: 2),
];

/// Today's strip — All 6 · Open 2 · Done 3 · Paused 1 — over the rows it
/// keeps.
class _TodayList extends StatefulWidget {
  const _TodayList();

  @override
  State<_TodayList> createState() => _TodayListState();
}

class _TodayListState extends State<_TodayList> {
  static const List<String> _views = ['All', 'Open', 'Done', 'Paused'];
  int _view = 0;

  int _count(String view) => view == 'All'
      ? _habits.length
      : _habits.where((h) => h.state == view).length;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final view = _views[_view];
    final kept = [
      for (final h in _habits)
        if (view == 'All' || h.state == view) h,
    ];
    // Edge to edge on a phone, as the strips below are; in a wider window
    // on the column's keylines. The strip and the rows take one inset.
    return KitBleed(
      child: _Frame(
        child: Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MinimalFilterBar(
                padding: _inset(context),
                children: [
                  for (final (i, label) in _views.indexed)
                    MinimalFilter(
                      label,
                      count: _count(label),
                      selected: i == _view,
                      onPressed: () => setState(() => _view = i),
                    ),
                ],
              ),
              for (final (i, habit) in kept.indexed)
                Container(
                  height: t.rowHeight,
                  padding: KitBleed.inset(context),
                  decoration: BoxDecoration(
                    border: i == kept.length - 1
                        ? null
                        : Border(bottom: t.rule),
                  ),
                  child: Row(
                    children: [
                      MinimalStatusIcon(switch (habit.state) {
                        'Done' => MinimalTaskStatus.done,
                        'Paused' => MinimalTaskStatus.paused,
                        _ => MinimalTaskStatus.todo,
                      }),
                      const MinimalGap(10),
                      Expanded(
                        child: Text(
                          habit.name,
                          style: t.body.medium.c(
                            habit.state == 'Open'
                                ? t.foreground
                                : t.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${habit.streak}d',
                        style: t.mono.c(t.mutedForeground),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The page the strip and its rows fill: a bare run between a hairline
/// above and one below, as Today's strip sits on a rule — rows are never
/// carded.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // A Container, not a bare DecoratedBox: it insets the rows inside the
    // rules, so their own ground never paints over them.
    return Container(
      decoration: BoxDecoration(
        color: t.background,
        border: Border(top: t.rule, bottom: t.rule),
      ),
      child: child,
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// Count filters over a list, one selected, full bleed on the hairline.
Widget kitSpecimenFilterBarCounts() => _Body(
  bleed: true,
  child: MinimalFilterBar(
    children: [
      MinimalFilter('All', count: 38, selected: true, onPressed: () {}),
      MinimalFilter('Late', count: 2, onPressed: () {}),
      MinimalFilter('Baking', count: 4, onPressed: () {}),
      MinimalFilter('Ready', count: 9, onPressed: () {}),
    ],
  ),
);

/// Status filters with their glyphs, a display control held at the end.
Widget kitSpecimenFilterBarTrailing() => _Body(
  bleed: true,
  child: MinimalFilterBar(
    trailing: MinimalIconButton(
      LucideIcons.slidersHorizontal,
      label: 'Display options',
      variant: MinimalIconButtonVariant.outline,
      size: MinimalButtonSize.small,
      onPressed: () {},
    ),
    children: [
      MinimalFilter(
        'Todo',
        count: 4,
        leading: const MinimalStatusIcon(MinimalTaskStatus.todo, size: 14),
        selected: true,
        onPressed: () {},
      ),
      MinimalFilter(
        'In progress',
        count: 2,
        leading: const MinimalStatusIcon(MinimalTaskStatus.active, size: 14),
        onPressed: () {},
      ),
      MinimalFilter(
        'Done',
        count: 11,
        leading: const MinimalStatusIcon(MinimalTaskStatus.done, size: 14),
        onPressed: () {},
      ),
    ],
  ),
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
