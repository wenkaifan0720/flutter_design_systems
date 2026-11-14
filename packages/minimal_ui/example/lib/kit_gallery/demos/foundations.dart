/// The system's foundations in one page: every colour role of the preset in
/// force as a labeled swatch with its hex, the Geist type scale, the spacing
/// and corner scales, the row and control density, the formatters and the
/// chrome metrics every bar is drawn from.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Foundations',
  sections: [
    kitSection('Colour roles', children: const [_Swatches()]),
    kitSection('Type · Geist, Geist Mono', children: const [_TypeScale()]),
    kitSection('Spacing', children: const [_Spacing()]),
    kitSection('Corners', children: const [_Corners()]),
    kitSection('Density', children: const [_Density()]),
    kitSection('Format', children: const [_Formats()]),
    kitSection(
      'Chrome metrics',
      children: [
        const _Metrics(),
        kitNote(
          'Rows and controls at the density in force, as drawn above; the '
          'bars, gutter and push hold at every density.',
        ),
      ],
    ),
  ],
);

/// A hairline-bordered panel of rows, the Minimal way of grouping without
/// a container's weight. The rows are clipped to the corners and the
/// hairline paints above them, so nothing covers the rule.
class _Panel extends StatelessWidget {
  const _Panel({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final radius = BorderRadius.circular(t.cardRadius);
    return Container(
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: t.border, width: t.hairline),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, row) in rows.indexed)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: i == 0 ? null : Border(top: t.rule),
                ),
                child: row,
              ),
          ],
        ),
      ),
    );
  }
}

/// A colour as an app writes it: `#RRGGBB`, and a translucent one's opacity
/// after it (`#0A0A0E · 38%`) rather than an alpha byte in front, which
/// beside six-digit codes reads as another colour.
String _hex(Color c) {
  final rgb = (c.toARGB32() & 0xFFFFFF)
      .toRadixString(16)
      .padLeft(6, '0')
      .toUpperCase();
  final alpha = (c.a * 100).round();
  return alpha == 100 ? '#$rgb' : '#$rgb · $alpha%';
}

class _Swatches extends StatelessWidget {
  const _Swatches();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // Families pair on their own rows: a role beside its text, its fill
    // beside its ink. Info and the selection's wash, roles of no family,
    // stand together after the tones; warning, which has no text role of its
    // own, closes the grid, so its lone cell is the grid's last and not a
    // hole among the pairs. The ungrouped neutrals pair with their neighbours
    // (the quietest ink beside the inverse text, the dark surface beside the
    // scrim).
    final rows = <((String, Color), (String, Color)?)>[
      (('background', t.background), ('card', t.card)),
      (('muted', t.muted), ('sunken', t.sunken)),
      (('border', t.border), ('borderStrong', t.borderStrong)),
      (('input', t.input), ('ring', t.ring)),
      (('foreground', t.foreground), ('mutedForeground', t.mutedForeground)),
      (('textTertiary', t.textTertiary), ('textInverse', t.textInverse)),
      (('surfaceInverse', t.surfaceInverse), ('overlay', t.overlay)),
      (('primary', t.primary), ('primaryForeground', t.primaryForeground)),
      (('primarySubtle', t.primarySubtle), ('primaryInk', t.primaryInk)),
      (('success', t.success), ('onSuccess', t.onSuccess)),
      (('successSubtle', t.successSubtle), ('successInk', t.successInk)),
      (
        ('destructive', t.destructive),
        ('destructiveForeground', t.destructiveForeground),
      ),
      (
        ('destructiveSubtle', t.destructiveSubtle),
        ('destructiveInk', t.destructiveInk),
      ),
      (('info', t.info), ('selection', t.selection)),
      (('warningSubtle', t.warningSubtle), ('warningInk', t.warningInk)),
      (('warning', t.warning), null),
    ];
    // Two to a row where both names fit whole; one to a row on a phone,
    // so `destructiveForeground` is never cut. A row with one role keeps
    // its divider and an empty cell, so the middle rule runs unbroken.
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth < _twoSwatchesFrom
          ? _Panel(
              rows: [
                for (final (a, b) in rows) ...[
                  _Swatch(a),
                  if (b != null) _Swatch(b),
                ],
              ],
            )
          : _Panel(
              rows: [
                for (final (a, b) in rows)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _Swatch(a)),
                        VerticalDivider(width: t.hairline, color: t.border),
                        Expanded(
                          child: b != null
                              ? _Swatch(b)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  /// From this wide two swatches share a row.
  static const double _twoSwatchesFrom = 480;
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.role);

  final (String, Color) role;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: ShapeDecoration(
              color: role.$2,
              shape: t.shapes.mark.copyWith(
                side: BorderSide(color: t.borderStrong, width: t.hairline),
              ),
            ),
          ),
          const MinimalGap(MinimalSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.$1,
                  style: t.bodySmall.medium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // A hex code reads left to right in any language: right to
                // left, the hash would trail a code that starts with a
                // letter.
                Text(
                  _hex(role.$2),
                  style: t.mono.c(t.mutedForeground),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final steps = <(String, TextStyle, String)>[
      ('giant', t.giant, '€1,284'),
      ('hero', t.hero, 'Morning run'),
      ('display', t.display, 'Three kept'),
      ('h1', t.h1, 'Morning run'),
      ('h2', t.h2, 'Today'),
      ('h3', t.h3, 'Last 12 weeks'),
      ('bodyLarge', t.bodyLarge, 'Out the door before 8.'),
      ('body', t.body, 'Any distance counts.'),
      ('bodySmall', t.bodySmall, 'Reminder moved to 07:00'),
      ('caption', t.caption, '23 of 28 days in August'),
      ('label', t.label, 'MORNING'),
      ('mono', t.mono, 'HAB-4  07:12  71/82'),
      ('figure', t.figure, '€1,284.50'),
      ('control', t.control, 'Create habit'),
    ];
    return _Panel(
      rows: [
        for (final (name, style, sample) in steps)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name · ${style.fontSize!.toStringAsFixed(0)}/'
                  '${(style.fontSize! * style.height!).round()} · '
                  '${style.fontWeight!.value}',
                  style: t.mono.c(t.mutedForeground),
                ),
                const MinimalGap(MinimalSpacing.s4),
                Text(
                  sample,
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Spacing extends StatelessWidget {
  const _Spacing();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    const steps = <(String, double)>[
      ('s2', MinimalSpacing.s2),
      ('s4', MinimalSpacing.s4),
      ('s8', MinimalSpacing.s8),
      ('s12', MinimalSpacing.s12),
      ('s16', MinimalSpacing.s16),
      ('s20', MinimalSpacing.s20),
      ('s24', MinimalSpacing.s24),
      ('s32', MinimalSpacing.s32),
      ('s40', MinimalSpacing.s40),
      ('s48', MinimalSpacing.s48),
      ('s64', MinimalSpacing.s64),
    ];
    return Column(
      children: [
        for (final (name, size) in steps)
          SizedBox(
            height: 22,
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(name, style: t.mono.c(t.mutedForeground)),
                ),
                // A measure, in the quiet ink: the accent is for acts.
                Container(
                  width: size * 3,
                  height: 8,
                  decoration: BoxDecoration(
                    color: t.mutedForeground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const MinimalGap(MinimalSpacing.s8),
                Text(
                  size.toStringAsFixed(0),
                  style: t.mono.c(t.mutedForeground),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Corners extends StatelessWidget {
  const _Corners();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final radii = <(String, double)>[
      ('smallRadius', t.smallRadius),
      ('controlRadius', t.controlRadius),
      ('cardRadius', t.cardRadius),
      ('sheetRadius', t.sheetRadius),
    ];
    // One corner to a row, a hairline square drawn with it, its name and
    // its figure beside: a name never breaks to fit a narrow column.
    return _Panel(
      rows: [
        for (final (name, radius) in radii)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: t.borderStrong,
                      width: t.hairline,
                    ),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
                const MinimalGap(MinimalSpacing.s12),
                Expanded(
                  child: Text(
                    name,
                    style: t.bodySmall.medium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const MinimalGap(MinimalSpacing.s8),
                // A value, in the ink as the Format and Chrome metrics
                // tables print theirs.
                Text(radius.toStringAsFixed(0), style: t.mono),
              ],
            ),
          ),
      ],
    );
  }
}

class _Density extends StatelessWidget {
  const _Density();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // Rows on the ground, under their group header, divided by hairlines:
    // never a card around a page's list. On this padded page the group
    // takes the bare register (no side padding of its own), so its header,
    // rows and rules keep the column's edges like everything beside them.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MinimalSectionHeader(
              'Morning',
              count: '2/4',
              padding: MinimalSectionHeader.inset.copyWith(left: 0, right: 0),
            ),
            MinimalListSection(
              gutter: false,
              children: [
                MinimalListTile(
                  leading: const MinimalStatusIcon(MinimalTaskStatus.done),
                  title: 'Row · ${t.rowHeight.round()}',
                  muted: true,
                  meta: '12d',
                ),
                const MinimalListTile(
                  leading: MinimalStatusIcon(MinimalTaskStatus.todo),
                  title: 'Drink water',
                  meta: '10d',
                ),
                MinimalListTile(
                  leading: const MinimalStatusIcon(MinimalTaskStatus.done),
                  title: 'Dense · ${t.rowHeightCompact.round()}',
                  muted: true,
                  dense: true,
                  meta: '4d',
                ),
                const MinimalListTile(
                  leading: MinimalStatusIcon(MinimalTaskStatus.todo),
                  title: 'Journal',
                  dense: true,
                  meta: '3d',
                ),
              ],
            ),
          ],
        ),
        const MinimalGap(MinimalSpacing.s12),
        kitRow([
          for (final size in MinimalButtonSize.values)
            MinimalButton(
              'Control ${size.name}',
              size: size,
              variant: MinimalButtonVariant.secondary,
              onPressed: () {},
            ),
        ]),
        const MinimalGap(MinimalSpacing.s12),
        Row(
          children: [
            for (final icon in const [
              LucideIcons.calendarCheck,
              LucideIcons.listChecks,
              LucideIcons.activity,
              LucideIcons.settings,
              LucideIcons.bell,
              LucideIcons.flame,
            ]) ...[
              MinimalIcon(icon, color: t.foreground),
              const MinimalGap(MinimalSpacing.s16),
            ],
          ],
        ),
        // The caption stands as far under the glyphs as a section's
        // caption under its demo.
        const MinimalGap(MinimalSpacing.s12),
        kitNote(
          'Rows and controls at ${_densityName(t.density)} density, the '
          "platform's own unless Customize sets one; a row stays "
          '${MinimalChromeMetrics.row.round()}, its own tap target, at every '
          'denser step. Icons 18 on the Lucide cut nearest a '
          '${t.iconStroke} stroke.',
        ),
      ],
    );
  }
}

/// The density in force, by its name.
String _densityName(MinimalDensity d) => d == MinimalDensity.compact
    ? 'compact'
    : d == MinimalDensity.comfortable
    ? 'comfortable'
    : d == MinimalDensity.standard
    ? 'standard'
    : 'a custom';

class _Formats extends StatelessWidget {
  const _Formats();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // One sample moment for every row; relative reads it two days on.
    final at = DateTime(2026, 8, 28, 7, 12);
    // The names' column grows with the text, so `dayMonth` keeps its air
    // before its value at the largest size.
    final keys = MediaQuery.textScalerOf(context).scale(92);
    final samples = <(String, String)>[
      ('money', MinimalFormat.money(128400, symbol: '€', cents: false)),
      ('date', MinimalFormat.date(at)),
      ('dayMonth', MinimalFormat.dayMonth(at)),
      ('weekday', MinimalFormat.weekday(at, short: false)),
      ('clock', MinimalFormat.clock(at)),
      ('time12', MinimalFormat.time12(at)),
      ('isoDate', MinimalFormat.isoDate(at)),
      ('stamp', MinimalFormat.stamp(at)),
      (
        'relative',
        MinimalFormat.relative(at, now: DateTime(2026, 8, 30, 7, 12)),
      ),
    ];
    return _Panel(
      rows: [
        for (final (name, value) in samples)
          SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: keys,
                    child: Text(name, style: t.bodySmall.c(t.mutedForeground)),
                  ),
                  // At the row's end, as the Chrome metrics and Corners
                  // tables set their values.
                  Expanded(
                    child: Text.rich(
                      _faced(value, name, t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A sample in the face an app prints it in: dates, times, ids and money
/// in mono; a weekday or a relative day is words, so it takes Geist at the
/// small body size the rows' words take beside mono, with any figure inside
/// it (`2` of `2 days ago`) back in mono.
TextSpan _faced(String value, String name, MinimalThemeData t) {
  if (name != 'weekday' && name != 'relative') {
    return TextSpan(text: value, style: t.mono);
  }
  final figure = RegExp(r'\d+');
  final spans = <TextSpan>[];
  var at = 0;
  for (final m in figure.allMatches(value)) {
    if (m.start > at) {
      spans.add(
        TextSpan(text: value.substring(at, m.start), style: t.bodySmall),
      );
    }
    spans.add(TextSpan(text: m[0], style: t.mono));
    at = m.end;
  }
  if (at < value.length) {
    spans.add(TextSpan(text: value.substring(at), style: t.bodySmall));
  }
  return TextSpan(children: spans);
}

class _Metrics extends StatelessWidget {
  const _Metrics();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    String ms(Duration d) => '${d.inMilliseconds} ms';
    // A value's words (`safe area`) print in Geist after its mono figure.
    final words = <String, String>{'tab bar': ' + safe area'};
    // Rows and controls at the density in force, as the Density list above
    // draws them; the bars, gutter and push hold at every density.
    String control(double height) => '${t.density.height(height).round()}';
    final metrics = <(String, String)>[
      ('top bar', '${MinimalChromeMetrics.barHeight.round()}'),
      ('tab bar', '${MinimalChromeMetrics.tabHeight.round()}'),
      ('row / dense', '${t.rowHeight.round()} / ${t.rowHeightCompact.round()}'),
      (
        'control sm / md / lg',
        '${control(MinimalChromeMetrics.controlSm)} / '
            '${control(MinimalChromeMetrics.control)} / '
            '${control(MinimalChromeMetrics.controlLg)}',
      ),
      ('gutter', '${MinimalChromeMetrics.gutter.round()}'),
      ('sheet inset', '${MinimalChromeMetrics.sheetInset.round()}'),
      (
        'push',
        '${ms(MinimalChromeMetrics.push)} · '
            '${MinimalChromeMetrics.pushSlide.round()} px',
      ),
      ('max text scale', '${MinimalChromeMetrics.maxTextScale}×'),
    ];
    return _Panel(
      rows: [
        for (final (name, value) in metrics)
          SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(name, style: t.bodySmall.c(t.mutedForeground)),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: value, style: t.mono),
                        if (words[name] case final tail?)
                          TextSpan(
                            text: tail,
                            style: t.bodySmall.c(t.mutedForeground),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
