/// The three presentations a preview gives a page, switched by the
/// system's own segmented control: the Habits root over the tab bar (its
/// leading title and meta), then a habit's page pushed off it (the back
/// button and the `Habits / HAB-4` crumb) and raised as a sheet (the
/// card's header and close) — the route derives every piece of chrome, and
/// a pushed or raised page stands over the root it came from (`under:`).
/// Below it, a subtree that mounts its own host in the other appearance.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

// Its own heading, not the page's name again (the page it stands on is
// titled Host and preview already).
Widget kitPreviewDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'A page, previewed',
  sections: [
    _Presentations(brightness: brightness),
    _NestedHost(brightness),
  ],
);

const List<MinimalNavItem> _tabs = [
  MinimalNavItem(LucideIcons.calendarCheck, 'Today'),
  MinimalNavItem(LucideIcons.listChecks, 'Habits'),
  MinimalNavItem(LucideIcons.activity, 'Trends'),
  MinimalNavItem(LucideIcons.settings, 'Settings'),
];

class _Presentations extends StatefulWidget {
  const _Presentations({required this.brightness});

  final Brightness brightness;

  @override
  State<_Presentations> createState() => _PresentationsState();
}

class _PresentationsState extends State<_Presentations> {
  MinimalPresentation _presentation = MinimalPresentation.root;

  /// The previewed phone's width on the page.
  static const double _phone = 300;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return kitSection(
      'Presentation',
      children: [
        // The control as wide as the phone it switches, so their edges
        // line up.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: _phone,
            child: MinimalSegmentedButton<MinimalPresentation>(
              segments: [
                for (final p in MinimalPresentation.values)
                  MinimalButtonSegment(
                    p,
                    p.name[0].toUpperCase() + p.name.substring(1),
                  ),
              ],
              value: _presentation,
              label: 'Presentation',
              onChanged: (p) => setState(() => _presentation = p),
            ),
          ),
        ),
        // The phone stands on the column's start, under the control that
        // switches it. It is clipped to its corners and its hairline paints
        // above the page, so the page's opaque ground never covers the rule.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: _phone,
            foregroundDecoration: ShapeDecoration(
              shape: t.shapes.large.copyWith(
                side: BorderSide(color: t.borderStrong, width: t.hairline),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(t.sheetRadius),
              child: AspectRatio(
                aspectRatio: 390 / 844,
                child: FittedBox(
                  child: SizedBox(
                    width: 390,
                    height: 844,
                    child: MinimalPreview(
                      // A new presentation is a new stage: the page is raised
                      // afresh on its route.
                      key: ValueKey(_presentation),
                      light: kitTheme(Brightness.light),
                      dark: kitTheme(Brightness.dark),
                      brightness: widget.brightness,
                      presentation: _presentation,
                      tabs: _tabs,
                      activeIndex: 1,
                      // A detail page is never a nav root: as a root the
                      // preview shows the list it is reached from.
                      under: const _HabitsRoot(),
                      child: _presentation == MinimalPresentation.root
                          ? const _HabitsRoot()
                          : const _HabitPage(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The root the page was reached from, standing beneath it pushed or
/// raised.
class _HabitsRoot extends StatelessWidget {
  const _HabitsRoot();

  @override
  Widget build(BuildContext context) => MinimalScaffold(
    // Ritual's six, the count its bar gives.
    topBar: const MinimalAppBar(title: 'Habits', subtitle: '6'),
    padding: EdgeInsets.zero,
    body: MinimalListSection(
      children: [
        for (final (name, streak, status) in const [
          ('Meditate', '4d', MinimalTaskStatus.done),
          ('Morning run', '12d', MinimalTaskStatus.done),
          ('Drink water', '10d', MinimalTaskStatus.todo),
          ('Journal', '3d', MinimalTaskStatus.todo),
          ('Read 20 pages', '6d', MinimalTaskStatus.done),
          ('Water the plants', '2d', MinimalTaskStatus.paused),
        ])
          MinimalListTile(
            leading: MinimalStatusIcon(status, semanticLabel: name),
            muted: status != MinimalTaskStatus.todo,
            title: name,
            meta: streak,
            chevron: true,
            onTap: () {},
          ),
      ],
    ),
  );
}

/// The page under preview: it authors its parent, its id and two actions,
/// and never its own way out. It prints its own heading, so its bar leaves
/// the title out and reads `Habits / HAB-4` when pushed.
class _HabitPage extends StatelessWidget {
  const _HabitPage();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // Words print in the body face; figures (a time, a date, a count) in
    // mono, with any quiet prose that qualifies them after.
    final rows = <(IconData, String, InlineSpan)>[
      (
        LucideIcons.repeat,
        'Repeats',
        TextSpan(text: 'Every day', style: t.bodySmall),
      ),
      (
        LucideIcons.bell,
        'Reminder',
        TextSpan(
          text: MinimalFormat.clock(DateTime(2026, 8, 28, 7)),
          style: t.mono,
        ),
      ),
      (
        LucideIcons.flame,
        'Streak',
        TextSpan(
          children: [
            TextSpan(text: '12d', style: t.mono),
            TextSpan(
              text: ' · best 21d',
              style: t.bodySmall.c(t.mutedForeground),
            ),
          ],
        ),
      ),
      (
        LucideIcons.calendar,
        'Started',
        TextSpan(
          text: MinimalFormat.isoDate(DateTime(2026, 6, 2)),
          style: t.mono,
        ),
      ),
    ];
    return MinimalScaffold(
      topBar: MinimalAppBar(
        parent: 'Habits',
        subtitle: 'HAB-4',
        actions: [
          MinimalIconButton(
            LucideIcons.star,
            label: 'Favourite',
            onPressed: () {},
          ),
          MinimalIconButton(
            LucideIcons.ellipsis,
            label: 'More',
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Morning run', style: t.h1),
          const MinimalGap(MinimalSpacing.s4),
          Text(
            'Out the door before 8. Any distance counts.',
            style: t.bodySmall.c(t.mutedForeground),
          ),
          const MinimalGap(MinimalSpacing.s12),
          for (final (icon, key, value) in rows)
            Container(
              height: t.rowHeightCompact,
              decoration: BoxDecoration(border: Border(top: t.rule)),
              child: Row(
                children: [
                  MinimalIcon(icon),
                  const MinimalGap(MinimalSpacing.s8),
                  SizedBox(
                    width: 92,
                    child: Text(key, style: t.bodySmall.c(t.mutedForeground)),
                  ),
                  Expanded(
                    child: Text.rich(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A subtree that mounts its own [MinimalHost] in the opposite appearance —
/// a lab swatch, an inverted panel.
class _NestedHost extends StatelessWidget {
  const _NestedHost(this.brightness);

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final other = brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    return kitSection(
      'A nested host',
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(context.minimalTheme.cardRadius),
          child: MinimalHost(
            light: kitTheme(Brightness.light),
            dark: kitTheme(Brightness.dark),
            brightness: other,
            child: Builder(
              builder: (context) {
                final t = context.minimalTheme;
                return Padding(
                  padding: MinimalInsets.all16,
                  child: Row(
                    children: [
                      // The glyph of the appearance it shows.
                      MinimalIcon(
                        other == Brightness.dark
                            ? LucideIcons.moon
                            : LucideIcons.sun,
                        color: t.foreground,
                      ),
                      const MinimalGap(10),
                      // Short enough for one line beside Open on a phone,
                      // so no word stands alone on a second.
                      Expanded(
                        child: Text(
                          other == Brightness.dark
                              ? 'Dark appearance, inline.'
                              : 'Light appearance, inline.',
                          style: t.body,
                        ),
                      ),
                      const MinimalGap(MinimalSpacing.s12),
                      MinimalButton(
                        'Open',
                        size: MinimalButtonSize.small,
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
