/// List rows: Minimal's list as it stands on a page — full bleed, 44 px
/// rows at the screen gutter, hairlines between them and no card around
/// them — then every slot and state of the row (glyph, tile, avatar,
/// caption, tag, mono meta, chevron; muted, selected, danger, disabled,
/// dense), the same rows inset in a card, and the dense single-line meta
/// row.
///
/// The page runs `padding: EdgeInsets.zero` like any full-bleed list, so
/// its non-list bands pad themselves with the gutter.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

// On an example page the phone grows with the rows ([kitScreen]'s grow), so
// no fixed window cuts the last band; it ends a short step under the last
// line.
Widget kitListRowsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'List rows',
  padding: const EdgeInsets.only(bottom: MinimalSpacing.s16),
  grow: true,
  body: const _Page(),
);

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TodayList(),
        // The rows lead with a glyph, a tile, a face and a priority mark;
        // each stands centred in the tile's 28 px slot, so every title
        // starts on one keyline.
        _band(
          'Anatomy',
          MinimalListSection(
            children: [
              MinimalListTile(
                icon: LucideIcons.flame,
                leadingWidth: _lead,
                title: 'Morning run',
                subtitle: 'Every day',
                meta: '07:00',
                chevron: true,
                onTap: () {},
              ),
              MinimalListTile(
                // A customer is a kind of thing, not a status: its tile
                // stays in ink.
                leading: const MinimalIconTile(LucideIcons.croissant),
                leadingWidth: _lead,
                title: 'Café Morgen',
                subtitle: '24 loaves',
                trailing: const MinimalStatusBadge(
                  'Baking',
                  tone: MinimalTone.primary,
                ),
                meta: '10:00',
                onTap: () {},
              ),
              MinimalListTile(
                leading: const MinimalAvatar('Hanna Berg', size: 24),
                leadingWidth: _lead,
                title: 'Hanna Berg',
                trailing: const MinimalStatusBadge(
                  'Late',
                  tone: MinimalTone.warning,
                ),
                meta: '09:30',
                onTap: () {},
              ),
              MinimalListTile(
                leading: const MinimalPriorityIcon(MinimalPriority.high),
                leadingWidth: _lead,
                title: 'Streak resets when the phone changes time zone',
                below: Row(
                  children: [
                    Text('HAB-12', style: t.mono.c(t.mutedForeground)),
                    const MinimalGap(MinimalSpacing.s8),
                    const MinimalTag('Bug', dot: MinimalTone.destructive),
                  ],
                ),
                trailing: const MinimalAvatar('Mira Holt', size: 24),
                onTap: () {},
              ),
              const MinimalListTile(
                icon: LucideIcons.calendarDays,
                leadingWidth: _lead,
                title: 'Started',
                meta: '2026-06-02',
              ),
            ],
          ),
          note:
              'A glyph, a tile or an avatar leads; a caption, a tag, a mono '
              'figure and a chevron follow. The last row does not open: a '
              'static fact, not a control.',
        ),
        const _SelectableList(),
        _band(
          'States',
          MinimalListSection(
            children: [
              MinimalListTile(
                leading: const MinimalStatusIcon(MinimalTaskStatus.done),
                title: 'Read 20 pages',
                subtitle: 'Done today',
                muted: true,
                meta: '6d',
                onTap: () {},
              ),
              MinimalListTile(
                leading: const MinimalStatusIcon(MinimalTaskStatus.paused),
                title: 'Water the plants',
                subtitle: 'Paused until 1 Sep',
                meta: '2d',
                enabled: false,
                onTap: () {},
              ),
              MinimalListTile(
                icon: LucideIcons.trash2,
                title: 'Delete habit',
                destructive: true,
                onTap: () {},
              ),
            ],
          ),
          note:
              'A kept habit quiets; a paused one dims and cannot be opened; '
              'a destructive row reads in red.',
        ),
        _band(
          'Dense · 36 px',
          MinimalListSection(
            children: [
              for (final (id, name, due) in _orders)
                MinimalListTile(
                  dense: true,
                  title: name,
                  leading: Text(id, style: t.mono.c(t.mutedForeground)),
                  meta: due,
                  onTap: () {},
                ),
            ],
          ),
        ),
        Padding(
          padding: MinimalInsets.gutter,
          child: MinimalSection(
            title: 'Inset in a card',
            child: MinimalListSection(
              inset: true,
              children: [
                MinimalListTile(
                  leading: const MinimalIconTile(LucideIcons.bell),
                  title: 'Notifications',
                  trailing: Text('On', style: t.bodySmall.c(t.mutedForeground)),
                  chevron: true,
                  onTap: () {},
                ),
                MinimalListTile(
                  leading: const MinimalIconTile(LucideIcons.users),
                  title: 'Members',
                  trailing: const MinimalAvatarGroup([
                    'Hanna Berg',
                    'Oskar Lind',
                    'Ines Duarte',
                  ]),
                  chevron: true,
                  onTap: () {},
                ),
                MinimalListTile(
                  leading: const MinimalIconTile(
                    LucideIcons.trash2,
                    tone: MinimalTone.destructive,
                  ),
                  title: 'Delete workspace',
                  destructive: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: MinimalInsets.gutter,
          child: MinimalSection(title: 'Meta rows', child: _MetaRows()),
        ),
      ],
    );
  }

  static const _orders = [
    ('1047', 'Hanna Berg', '09:30'),
    ('1046', 'Oskar Lind', '09:45'),
    ('1045', 'Café Morgen', '10:00'),
  ];

  /// The anatomy rows' leading slot: a [MinimalIconTile]'s 28 px, the
  /// widest mark they lead with.
  static const double _lead = 28;

  /// A section whose rows run full bleed under a gutter-aligned header,
  /// with an optional note under them on the gutter.
  Widget _band(String title, Widget rows, {String? note}) {
    final section = MinimalSection(title: title, gutter: true, child: rows);
    if (note == null) return section;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MinimalChromeMetrics.gutter,
            MinimalSpacing.s8,
            MinimalChromeMetrics.gutter,
            0,
          ),
          child: kitNote(note),
        ),
      ],
    );
  }
}

/// The Today list: two groups whose rows tick done on a tap.
class _TodayList extends StatefulWidget {
  const _TodayList();

  @override
  State<_TodayList> createState() => _TodayListState();
}

class _TodayListState extends State<_TodayList> {
  final Map<String, bool> _done = {
    'Meditate': true,
    'Morning run': true,
    'Drink water': false,
    'Journal': false,
    'Read 20 pages': true,
  };

  static const _streak = {
    'Meditate': 4,
    'Morning run': 12,
    'Drink water': 10,
    'Journal': 3,
    'Read 20 pages': 6,
  };

  Widget _group(String title, List<String> names) {
    final kept = names.where((n) => _done[n]!).length;
    return MinimalSection(
      title: title,
      count: '$kept/${names.length}',
      gutter: true,
      child: MinimalListSection(
        children: [
          for (final name in names)
            MinimalListTile(
              leading: MinimalStatusIcon(
                _done[name]! ? MinimalTaskStatus.done : MinimalTaskStatus.todo,
              ),
              title: name,
              muted: _done[name]!,
              meta: '${_streak[name]}d',
              onTap: () => setState(() => _done[name] = !_done[name]!),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _group('Morning', ['Meditate', 'Morning run', 'Drink water']),
      _group('Evening', ['Journal', 'Read 20 pages']),
    ],
  );
}

/// One selected row at a time: the open record in a split view.
class _SelectableList extends StatefulWidget {
  const _SelectableList();

  @override
  State<_SelectableList> createState() => _SelectableListState();
}

class _SelectableListState extends State<_SelectableList> {
  static const _issues = [
    ('HAB-4', 'Morning run', 'Active'),
    ('HAB-2', 'Drink water', 'Open'),
    ('HAB-6', 'Water the plants', 'Paused'),
  ];

  int _open = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MinimalSection(
        title: 'Selected',
        count: _issues[_open].$1,
        gutter: true,
        child: MinimalListSection(
          children: [
            for (final (i, (id, name, state)) in _issues.indexed)
              MinimalListTile(
                icon: LucideIcons.listChecks,
                title: name,
                subtitle: state,
                meta: id,
                selected: i == _open,
                onTap: () => setState(() => _open = i),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          MinimalChromeMetrics.gutter,
          MinimalSpacing.s8,
          MinimalChromeMetrics.gutter,
          0,
        ),
        child: kitNote(
          'Tap a row to open it. Every row of the set announces whether it '
          'is the selected one.',
        ),
      ),
    ],
  );
}

/// Dense single lines: an id, a flexible middle, a time. Hairlines divide
/// them, as the kit's lists do; none closes the last. Each line leads with
/// a different adornment, all in one slot, so every middle starts on one
/// keyline.
class _MetaRows extends StatelessWidget {
  /// The adornments' slot: as wide as the widest of them, the tag.
  static const double _lead = 40;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    Widget line(Widget row, {bool last = false}) => Container(
      padding: MinimalInsets.vertical8,
      decoration: last ? null : BoxDecoration(border: Border(bottom: t.rule)),
      child: row,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line(
          const MinimalMetaRow(
            leading: Text('1047'),
            leadingWidth: _lead,
            middle: Text('Hanna Berg · 3 loaves · rye, spelt, seeded'),
            trailing: Text('09:30'),
          ),
        ),
        line(
          const MinimalMetaRow(
            leading: MinimalTag('New', tone: MinimalTone.primary),
            leadingWidth: _lead,
            middle: Text(
              'Studio North asked to move their standing order to Tuesdays '
              'and Fridays from next week',
            ),
            trailing: Text('2m'),
          ),
        ),
        line(
          const MinimalMetaRow(
            leading: MinimalStatusIcon(MinimalTaskStatus.done, size: 16),
            leadingWidth: _lead,
            middle: Text('Marked done · note added'),
            trailing: Text('27 Aug 07:40'),
          ),
        ),
        line(
          const MinimalMetaRow(
            leading: MinimalAvatar('Ines Duarte', size: 24),
            leadingWidth: _lead,
            middle: Text('Ines Duarte'),
          ),
          last: true,
        ),
      ],
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style. Rows run edge to edge, as on a full-bleed
// page.

/// Glyph-led rows with a caption and a mono figure at the end.
Widget kitSpecimenListRowGlyphValue() => _Body(
  bleed: true,
  child: MinimalListSection(
    children: [
      MinimalListTile(
        icon: LucideIcons.flame,
        title: 'Morning run',
        subtitle: 'Every day',
        meta: '07:00',
        onTap: () {},
      ),
      MinimalListTile(
        icon: LucideIcons.bookOpen,
        title: 'Read 20 pages',
        subtitle: 'Every evening',
        meta: '21:30',
        onTap: () {},
      ),
    ],
  ),
);

/// People leading with their avatars, a status tag at the end.
Widget kitSpecimenListRowAvatarTag() => _Body(
  bleed: true,
  child: MinimalListSection(
    children: [
      MinimalListTile(
        leading: const MinimalAvatar('Hanna Berg', size: 24),
        title: 'Hanna Berg',
        subtitle: '3 loaves · rye, spelt',
        trailing: const MinimalStatusBadge('Late', tone: MinimalTone.warning),
        onTap: () {},
      ),
      MinimalListTile(
        leading: const MinimalAvatar('Oskar Lind', size: 24),
        title: 'Oskar Lind',
        subtitle: '2 baguettes',
        trailing: const MinimalStatusBadge('Ready', tone: MinimalTone.success),
        onTap: () {},
      ),
    ],
  ),
);

/// Products leading with their pictures, each opening its record.
Widget kitSpecimenListRowImageChevron() => _Body(
  bleed: true,
  child: MinimalListSection(
    children: [
      MinimalListTile(
        leading: const MinimalMedia(
          MinimalPlaceholderImage(MinimalMediaKind.food, 1),
          width: 32,
          height: 32,
          radius: MinimalCorners.r4,
        ),
        title: 'Sourdough loaf',
        subtitle: '€6.50 · 24 in stock',
        chevron: true,
        onTap: () {},
      ),
      MinimalListTile(
        leading: const MinimalMedia(
          MinimalPlaceholderImage(MinimalMediaKind.food, 4),
          width: 32,
          height: 32,
          radius: MinimalCorners.r4,
        ),
        title: 'Cinnamon bun',
        subtitle: '€3.20 · 40 in stock',
        chevron: true,
        onTap: () {},
      ),
    ],
  ),
);

/// Settings rows led by toned tiles, a switch at the end.
Widget kitSpecimenListRowTileControl() => _Body(
  bleed: true,
  child: MinimalListSection(
    children: [
      MinimalListTile(
        leading: const MinimalIconTile(
          LucideIcons.bell,
          tone: MinimalTone.primary,
        ),
        title: 'Notifications',
        trailing: MinimalSwitch(
          value: true,
          label: 'Notifications',
          onChanged: (_) {},
        ),
      ),
      MinimalListTile(
        leading: const MinimalIconTile(LucideIcons.moon),
        title: 'Quiet hours',
        trailing: MinimalSwitch(
          value: false,
          label: 'Quiet hours',
          onChanged: (_) {},
        ),
      ),
    ],
  ),
);

/// Rows on the page, divided and closed by hairlines, edge to edge.
Widget kitSpecimenRowGroupBleed() => _Body(
  bleed: true,
  child: MinimalListSection(
    children: [
      MinimalListTile(
        leading: const MinimalStatusIcon(MinimalTaskStatus.done),
        title: 'Meditate',
        muted: true,
        meta: '4d',
        onTap: () {},
      ),
      MinimalListTile(
        leading: const MinimalStatusIcon(MinimalTaskStatus.done),
        title: 'Morning run',
        muted: true,
        meta: '12d',
        onTap: () {},
      ),
      MinimalListTile(
        leading: const MinimalStatusIcon(MinimalTaskStatus.todo),
        title: 'Drink water',
        meta: '10d',
        onTap: () {},
      ),
    ],
  ),
);

/// The group standing in its own card, rules between rows only.
Widget kitSpecimenRowGroupInset() => _Body(
  child: MinimalListSection(
    inset: true,
    children: [
      MinimalListTile(
        leading: const MinimalIconTile(LucideIcons.receipt),
        title: 'Orders',
        meta: '38',
        chevron: true,
        onTap: () {},
      ),
      MinimalListTile(
        leading: const MinimalIconTile(
          LucideIcons.croissant,
          tone: MinimalTone.warning,
        ),
        title: 'Products',
        meta: '24',
        chevron: true,
        onTap: () {},
      ),
      MinimalListTile(
        leading: const MinimalIconTile(
          LucideIcons.users,
          tone: MinimalTone.primary,
        ),
        title: 'Customers',
        meta: '112',
        chevron: true,
        onTap: () {},
      ),
    ],
  ),
);

/// Dense lines of an order log: the id, the words, the time; hairlines
/// between them only.
Widget kitSpecimenMetaRowOrders() => _Body(
  child: Builder(
    builder: (context) {
      final t = context.minimalTheme;
      Widget line(Widget row, {bool last = false}) => Container(
        padding: MinimalInsets.vertical8,
        decoration: last ? null : BoxDecoration(border: Border(bottom: t.rule)),
        child: row,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(
            const MinimalMetaRow(
              leading: Text('1047'),
              middle: Text('Hanna Berg · 3 loaves · rye, spelt, seeded'),
              trailing: Text('09:30'),
            ),
          ),
          line(
            const MinimalMetaRow(
              leading: Text('1048'),
              middle: Text(
                'Studio North · standing order moved to Tuesdays and Fridays',
              ),
              trailing: Text('10:15'),
            ),
          ),
          line(
            const MinimalMetaRow(
              leading: Text('1049'),
              middle: Text('Café Morgen · 24 loaves'),
              trailing: Text('11:00'),
            ),
            last: true,
          ),
        ],
      );
    },
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
