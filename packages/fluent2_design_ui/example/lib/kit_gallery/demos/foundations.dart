/// Foundations: the theme's roles (ui_core's, as views of Fluent's
/// aliases, and Fluent's own neutral layers, strokes and inks), the brand
/// ramp, the tones, the materials' grounds, the type ramp in Selawik, the
/// radii, the spacing, the elevations, a few of Fluent UI System Icons and
/// the chrome's metrics. Everything below reads `context.fluent2Theme`, so
/// the page restyles with the preset and the appearance.
library;

import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

import '../kit.dart';

Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Foundations',
  sections: [
    kitSection('Catalog roles', children: [const _Roles()]),
    kitSection('Neutral layers and strokes', children: [const _Layers()]),
    kitSection('Brand ramp', children: [const _Ramp()]),
    kitSection('Tones', children: [const _Tones()]),
    kitSection('Type ramp', children: [const _Type()]),
    kitSection('Corners', children: [const _Corners()]),
    kitSection('Spacing', children: [const _Spacing()]),
    kitSection('Elevation', children: [const _Elevation()]),
    kitSection('Icons', children: [const _Icons()]),
    kitSection('Chrome metrics', children: [const _Metrics()]),
    kitSection('Words and figures', children: [const _Format()]),
  ],
);

String _hex(Color c) {
  String two(double v) =>
      (v * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  final rgb = '#${two(c.r)}${two(c.g)}${two(c.b)}';
  return c.a < 1 ? '$rgb ${(c.a * 100).round()}%' : rgb;
}

class _Swatches extends StatelessWidget {
  const _Swatches(this.roles);

  final List<(String, Color)> roles;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Column(
      children: [
        for (final (name, color) in roles)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.xxs),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(Fluent2Radius.small),
                  ),
                  child: const SizedBox(width: 32, height: 20),
                ),
                const Fluent2Gap(Fluent2Spacing.m),
                // A token's name is one word: past the row's room (a large
                // text size) its value goes under it and a name still too
                // wide is drawn smaller, never broken inside the word.
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: Fluent2Spacing.m,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(name, style: t.caption1),
                      ),
                      Text(_hex(color), style: t.caption1.c(t.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Roles extends StatelessWidget {
  const _Roles();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return _Swatches([
      ('background (ground)', t.background),
      ('surface', t.surface),
      ('surfaceAlt', t.surfaceAlt),
      ('surfaceInverse', t.surfaceInverse),
      ('border', t.border),
      ('borderStrong', t.borderStrong),
      ('textPrimary', t.textPrimary),
      ('textSecondary', t.textSecondary),
      ('textTertiary', t.textTertiary),
      ('textInverse', t.textInverse),
      ('accent', t.accent),
      ('onAccent', t.onAccent),
      ('accentSubtle', t.accentSubtle),
      ('accentText', t.accentText),
      ('success', t.success),
      ('warning', t.warning),
      ('danger', t.danger),
      ('overlay', t.overlay),
    ]);
  }
}

class _Layers extends StatelessWidget {
  const _Layers();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    return _Swatches([
      ('neutralBackground1', c.neutralBackground1),
      ('neutralBackground2', c.neutralBackground2),
      ('neutralBackground3', c.neutralBackground3),
      ('neutralBackground4', c.neutralBackground4),
      ('neutralBackground5', c.neutralBackground5),
      ('neutralBackground6', c.neutralBackground6),
      ('subtleBackgroundHover', c.subtleBackgroundHover),
      ('neutralStroke1', c.neutralStroke1),
      ('neutralStroke2', c.neutralStroke2),
      ('neutralStrokeAccessible', c.neutralStrokeAccessible),
      ('strokeFocus2', c.strokeFocus2),
      ('neutralForeground4', c.neutralForeground4),
      ('neutralForegroundDisabled', c.neutralForegroundDisabled),
      ('brandForegroundLink', c.brandForegroundLink),
      ('acrylic fill', t.acrylic.fill),
    ]);
  }
}

class _Ramp extends StatelessWidget {
  const _Ramp();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Wrap(
      spacing: Fluent2Spacing.xs,
      runSpacing: Fluent2Spacing.xs,
      children: [
        for (var shade = 10; shade <= 160; shade += 10)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: t.brand(shade),
                  borderRadius: BorderRadius.circular(Fluent2Radius.small),
                  border: shade == 80
                      ? Border.all(color: t.focus, width: Fluent2Stroke.thick)
                      : null,
                ),
                child: const SizedBox(width: 36, height: 28),
              ),
              const Fluent2Gap(Fluent2Spacing.xxs),
              Text('$shade', style: t.caption2.c(t.textSecondary)),
            ],
          ),
      ],
    );
  }
}

class _Tones extends StatelessWidget {
  const _Tones();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Wrap(
      spacing: Fluent2Spacing.s,
      runSpacing: Fluent2Spacing.s,
      children: [
        for (final tone in Fluent2Tone.values)
          Builder(
            builder: (context) {
              final colors = t.tone(tone);
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.tint,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(Fluent2Radius.medium),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Fluent2Spacing.m,
                    vertical: Fluent2Spacing.s,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: Fluent2Spacing.s,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.solid,
                          borderRadius: BorderRadius.circular(
                            Fluent2Radius.circular,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Fluent2Spacing.s,
                          ),
                          child: Text(
                            'Aa',
                            style: t.caption1Strong.c(colors.onSolid),
                          ),
                        ),
                      ),
                      Text(kitSay(tone), style: t.body1.c(colors.ink)),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Type extends StatelessWidget {
  const _Type();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final slots = [
      ('display 68/92', t.display),
      ('largeTitle 40/52', t.largeTitle),
      ('title1 32/40', t.title1),
      ('title2 28/36', t.title2),
      ('title3 24/32', t.title3),
      ('subtitle1 20/28', t.subtitle1),
      ('subtitle2 16/22', t.subtitle2),
      ('body2 16/22', t.body2),
      ('body1 14/20', t.body1),
      ('body1Strong 14/20', t.body1Strong),
      ('caption1 12/16', t.caption1),
      ('caption1Strong 12/16', t.caption1Strong),
      ('caption2 10/14', t.caption2),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, style) in slots)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.xxs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: t.caption1.c(t.textTertiary)),
                _Specimen(style.c(t.textPrimary)),
              ],
            ),
          ),
        const Fluent2Gap(Fluent2Spacing.s),
        Text('1,204,385.60 · 09:41', style: t.body1.tabular),
      ],
    );
  }
}

/// A type ramp's sample words at their own size, running on to a second line
/// by whole words; where one word alone is wider than the column (a display
/// size at a large text size) the words are set just small enough for it to
/// fit and still run on by whole words, never broken inside one.
class _Specimen extends StatelessWidget {
  const _Specimen(this.style);

  final TextStyle style;

  static const _words = 'Quarterly review';

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      var widest = 0.0;
      for (final word in _words.split(' ')) {
        final painter = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        if (painter.width > widest) widest = painter.width;
        painter.dispose();
      }
      if (widest <= box.maxWidth) return Text(_words, style: style);
      // A little under the column, so rounding never pushes the word over.
      final size =
          MediaQuery.textScalerOf(context).scale(style.fontSize!) *
          (box.maxWidth - 4) /
          widest;
      return Text(
        _words,
        style: style.copyWith(fontSize: size),
        textScaler: TextScaler.noScaling,
      );
    },
  );
}

class _Corners extends StatelessWidget {
  const _Corners();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return kitRow([
      for (final (name, radius) in const [
        ('small 2', Fluent2Radius.small),
        ('medium 4', Fluent2Radius.medium),
        ('large 6', Fluent2Radius.large),
        ('xLarge 8', Fluent2Radius.xLarge),
        ('circular', Fluent2Radius.circular),
      ])
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: t.surface,
                border: Border.all(color: t.borderStrong),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: const SizedBox(width: 56, height: 40),
            ),
            const Fluent2Gap(Fluent2Spacing.xs),
            Text(name, style: t.caption1.c(t.textSecondary)),
          ],
        ),
    ]);
  }
}

class _Spacing extends StatelessWidget {
  const _Spacing();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, size) in const [
          ('xxs', Fluent2Spacing.xxs),
          ('xs', Fluent2Spacing.xs),
          ('sNudge', Fluent2Spacing.sNudge),
          ('s', Fluent2Spacing.s),
          ('mNudge', Fluent2Spacing.mNudge),
          ('m', Fluent2Spacing.m),
          ('l', Fluent2Spacing.l),
          ('xl', Fluent2Spacing.xl),
          ('xxl', Fluent2Spacing.xxl),
          ('xxxl', Fluent2Spacing.xxxl),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.xxs),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    '$name ${size.toInt()}',
                    style: t.caption1.c(t.textSecondary),
                  ),
                ),
                ColoredBox(
                  color: t.accent,
                  child: SizedBox(width: size, height: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Elevation extends StatelessWidget {
  const _Elevation();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final s = t.shadows;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.s),
      child: Wrap(
        spacing: Fluent2Spacing.xl,
        runSpacing: Fluent2Spacing.xl,
        children: [
          for (final (name, shadow) in [
            ('shadow2', s.shadow2),
            ('shadow4', s.shadow4),
            ('shadow8', s.shadow8),
            ('shadow16', s.shadow16),
            ('shadow28', s.shadow28),
            ('shadow64', s.shadow64),
            ('shadow4Brand', t.brandShadows.shadow4),
          ])
            DecoratedBox(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(Fluent2Radius.medium),
                boxShadow: shadow,
              ),
              child: SizedBox(
                width: 96,
                height: 56,
                child: Center(child: Text(name, style: t.caption1)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Icons extends StatelessWidget {
  const _Icons();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return kitRow([
      for (final icon in const [
        Fluent2Icons.home,
        Fluent2Icons.homeFilled,
        Fluent2Icons.chat,
        Fluent2Icons.calendarLtr,
        Fluent2Icons.folder,
        Fluent2Icons.people,
        Fluent2Icons.mail,
        Fluent2Icons.search,
        Fluent2Icons.settings,
        Fluent2Icons.alert,
        Fluent2Icons.add,
        Fluent2Icons.edit,
        Fluent2Icons.share,
        Fluent2Icons.delete,
        Fluent2Icons.star,
        Fluent2Icons.starFilled,
      ])
        Icon(icon, size: Fluent2IconSize.i24, color: t.textPrimary),
    ]);
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Column(
      children: [
        for (final (name, value) in [
          ('gutter / wide', '16 / 24'),
          ('top bar', '${Fluent2ChromeMetrics.barHeight.round()}'),
          ('tab bar', '${Fluent2ChromeMetrics.tabBarHeight.round()}'),
          ('nav pane', '${Fluent2ChromeMetrics.paneWidth.round()}'),
          ('nav pane item', '${Fluent2ChromeMetrics.paneItem.round()}'),
          ('sheet corner', '${Fluent2ChromeMetrics.sheetRadius.round()}'),
          ('hit target floor', '${Fluent2Layout.minHitTarget.round()}'),
          ('desktop from', '${Fluent2Layout.wide.round()}'),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.xxs),
            child: Row(
              children: [
                Expanded(child: Text(name, style: t.body1)),
                Text(value, style: t.body1.c(t.textSecondary).tabular),
              ],
            ),
          ),
      ],
    );
  }
}

/// Fluent2Format's shapes, measured against one fixed moment (a demo never
/// reads the clock).
class _Format extends StatelessWidget {
  const _Format();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final now = DateTime(2026, 11, 3, 14, 30);
    final rows = [
      ('date', Fluent2Format.date(now, weekday: true)),
      ('longDate', Fluent2Format.longDate(now)),
      (
        'timeRange',
        Fluent2Format.timeRange(
          DateTime(2026, 11, 3, 9),
          DateTime(2026, 11, 3, 9, 30),
        ),
      ),
      (
        'ago',
        Fluent2Format.ago(now.subtract(const Duration(hours: 2)), now: now),
      ),
      ('duration', Fluent2Format.duration(const Duration(minutes: 90))),
      ('bytes', Fluent2Format.bytes(2516582)),
      ('count', Fluent2Format.count(12400, compact: true)),
      ('plural', Fluent2Format.plural(3, 'reply', 'replies')),
    ];
    return Column(
      children: [
        for (final (name, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.xxs),
            child: Row(
              children: [
                Expanded(child: Text(name, style: t.body1)),
                Text(value, style: t.body1.c(t.textSecondary).tabular),
              ],
            ),
          ),
      ],
    );
  }
}
