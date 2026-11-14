/// Foundations: the theme's roles (the catalog's and Frosted's own: the glass,
/// the act, the flow inks and their tints, the chrome's grounds), the
/// spectrum and its rim, the three lights, its type slots, shapes and
/// spacing in the preset on show, the format helpers, and the chrome's
/// metrics. Everything below reads `context.frostedTheme`, so the page
/// restyles with the preset and the appearance.
library;

import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

import '../kit.dart';

Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Foundations',
  sections: [
    kitSection('Colour roles', children: [const _Roles()]),
    kitSection('Frosted roles', children: [const _OwnRoles()]),
    kitSection('Spectrum', children: [const _Spectrum()]),
    kitSection('The rim', children: [const _Rim()]),
    kitSection('Lights', children: [const _Lights()]),
    kitSection('Type slots', children: [const _Slots()]),
    kitSection('Shape', children: [const _Shapes()]),
    kitSection('Spacing', children: [const _Spacing()]),
    kitSection('Format', children: [const _Formats()]),
    kitSection('Chrome metrics', children: [const _Metrics()]),
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
    final t = context.frostedTheme;
    return Column(
      children: [
        for (final (name, color) in roles)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: t.colorScheme.border),
                    borderRadius: BorderRadius.circular(FrostedCorners.r10),
                  ),
                  child: const SizedBox(width: 32, height: 22),
                ),
                const FrostedGap(FrostedSpacing.s12),
                Expanded(child: Text(name, style: t.textTheme.bodyMedium)),
                Text(
                  _hex(color),
                  textDirection: TextDirection.ltr,
                  style: t.textTheme.monoSmall,
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
    final t = context.frostedTheme;
    return _Swatches([
      ('background', t.colorScheme.background),
      ('surface', t.colorScheme.surface),
      ('surfaceAlt', t.colorScheme.surfaceAlt),
      ('surfaceInverse', t.colorScheme.surfaceInverse),
      ('border', t.colorScheme.border),
      ('borderStrong', t.colorScheme.borderStrong),
      ('textPrimary', t.colorScheme.textPrimary),
      ('textSecondary', t.colorScheme.textSecondary),
      ('textTertiary', t.colorScheme.textTertiary),
      ('textInverse', t.colorScheme.textInverse),
      ('accent', t.colorScheme.accent),
      ('onAccent', t.colorScheme.onAccent),
      ('accentSubtle', t.colorScheme.accentSubtle),
      ('accentText', t.colorScheme.accentText),
      ('success', t.colorScheme.success),
      ('successSubtle', t.colorScheme.successSubtle),
      ('warning', t.colorScheme.warning),
      ('warningSubtle', t.colorScheme.warningSubtle),
      ('danger', t.colorScheme.danger),
      ('dangerSubtle', t.colorScheme.dangerSubtle),
      ('overlay', t.colorScheme.overlay),
    ]);
  }
}

class _OwnRoles extends StatelessWidget {
  const _OwnRoles();

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Swatches([
          ('textQuiet', t.colorScheme.textTertiary),
          ('hairline', t.colorScheme.border),
          ('wash', t.glass.wash),
          ('glass', t.glass.fill),
          ('glassHi', t.glass.fillHigh),
          ('glassEdge', t.glass.edge),
          ('glassRim', t.glass.rim),
          ('well', t.glass.well),
          ('plane', t.glass.plane),
          ('moneyIn', t.colorScheme.moneyIn),
          ('moneyInTint', t.colorScheme.moneyInTint),
          ('over', t.colorScheme.over),
          ('overTint', t.colorScheme.overTint),
          ('warn', t.colorScheme.warning),
          ('warnTint', t.colorScheme.warningSubtle),
          ('cold', t.colorScheme.cold),
          ('coldTint', t.colorScheme.coldTint),
          ('barFill', t.glass.bar),
          ('sideFill', t.glass.sidebar),
          ('navCurrent', t.glass.navCurrent),
          ('menuFill', t.glass.menu),
          ('unreadDot', t.colorScheme.unreadDot),
        ]),
        const FrostedGap(FrostedSpacing.s12),
        Row(
          spacing: FrostedSpacing.s12,
          children: [
            Expanded(
              child: _Face(
                label: 'Glass',
                decoration: BoxDecoration(
                  color: t.glass.fill,
                  border: Border.all(color: t.glass.edge),
                  borderRadius: BorderRadius.circular(FrostedCorners.r18),
                ),
              ),
            ),
            Expanded(
              child: _Face(
                label: 'Act',
                ink: t.colorScheme.onButton,
                decoration: BoxDecoration(
                  gradient: t.colorScheme.buttonFill,
                  borderRadius: BorderRadius.circular(FrostedCorners.r18),
                ),
              ),
            ),
            Expanded(
              child: _Face(
                label: 'Sheet',
                decoration: BoxDecoration(
                  gradient: t.glass.sheetFace,
                  border: Border.all(color: t.glass.sheetEdge),
                  borderRadius: BorderRadius.circular(FrostedCorners.r18),
                ),
              ),
            ),
            Expanded(
              child: _Face(
                label: 'Toast',
                ink: t.toast.text,
                decoration: BoxDecoration(
                  gradient: t.toast.slab,
                  borderRadius: BorderRadius.circular(FrostedCorners.r18),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.label, required this.decoration, this.ink});

  final String label;
  final BoxDecoration decoration;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return DecoratedBox(
      decoration: decoration,
      child: SizedBox(
        height: 72,
        child: Center(
          child: Text(
            label,
            style: t.textTheme.labelLarge.c(ink ?? t.colorScheme.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// The eight categories' hues, each as its band (the two close stops its
/// marks wear) over its ink on its tint.
class _Spectrum extends StatelessWidget {
  const _Spectrum();

  static const _names = [
    'rent',
    'groc',
    'dine',
    'shop',
    'fun',
    'tran',
    'heal',
    'subs',
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final hues = t.hues.categories;
    return Row(
      spacing: FrostedSpacing.s6,
      children: [
        for (var i = 0; i < hues.length; i++)
          Expanded(
            child: Column(
              spacing: FrostedSpacing.s6,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: hues[i].band,
                    borderRadius: BorderRadius.circular(FrostedCorners.r10),
                  ),
                  child: const SizedBox(height: 28, width: double.infinity),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: hues[i].tint,
                    borderRadius: BorderRadius.circular(FrostedCorners.r10),
                  ),
                  child: SizedBox(
                    height: 20,
                    child: Center(
                      child: Text(
                        _names[i],
                        style: t.textTheme.monoSmall.c(hues[i].ink),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The spectrum rim, the one place the whole spectrum shows: a 1px line
/// along a glass tile's top, drawn here at 4 so it reads, over its five
/// hues.
class _Rim extends StatelessWidget {
  const _Rim();

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostedSpacing.s8,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: t.glass.spectrumRim),
          child: const SizedBox(height: 4),
        ),
        // The rim is a light, not a reading line: it runs left to right in
        // any language, and its stops stand under it in the same order
        // (mirrored, they ran against the strip, self-review round 5).
        Row(
          textDirection: TextDirection.ltr,
          spacing: FrostedSpacing.s6,
          children: [
            for (final stop in t.glass.spectrumStops)
              Expanded(
                child: Column(
                  spacing: FrostedSpacing.s6,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: stop,
                        borderRadius: BorderRadius.circular(FrostedCorners.r10),
                      ),
                      child: const SizedBox(height: 20, width: double.infinity),
                    ),
                    Text(
                      _hex(stop),
                      textDirection: TextDirection.ltr,
                      style: t.textTheme.monoSmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The three washes every page is lit by, at the preset's strength.
class _Lights extends StatelessWidget {
  const _Lights();

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final lights = <(String, Color)>[
      ('Lilac', t.lights.lilac),
      ('Rose', t.lights.rose),
      ('Peach', t.lights.peach),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostedSpacing.s8,
      children: [
        Row(
          spacing: FrostedSpacing.s8,
          children: [
            for (final (name, light) in lights)
              Expanded(
                child: Column(
                  spacing: FrostedSpacing.s6,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: light.withValues(alpha: t.lights.strength),
                        borderRadius: BorderRadius.circular(FrostedCorners.r10),
                      ),
                      child: const SizedBox(height: 40, width: double.infinity),
                    ),
                    Text(name.toUpperCase(), style: t.textTheme.overline),
                  ],
                ),
              ),
          ],
        ),
        Text(
          'Strength ${(t.lights.strength * 100).round()}%',
          style: t.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Slots extends StatelessWidget {
  const _Slots();

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final slots = <(String, TextStyle)>[
      ('giant 96', t.textTheme.displayLarge),
      ('display 64', t.textTheme.displayMedium),
      ('figure 40', t.textTheme.displaySmall),
      ('figureSmall 28', t.textTheme.headlineLarge),
      ('stat', t.textTheme.stat),
      ('hero', t.textTheme.headlineMedium),
      ('h1', t.textTheme.headlineSmall),
      ('h2', t.textTheme.titleLarge),
      ('h3', t.textTheme.titleSmall),
      ('bodyLarge', t.textTheme.bodyLarge),
      ('body', t.textTheme.titleMedium),
      ('bodySmall', t.textTheme.bodyMedium),
      ('amount', t.textTheme.amount),
      ('amountSmall', t.textTheme.amountSmall),
      ('caption', t.textTheme.labelMedium),
      ('note', t.textTheme.bodySmall),
      ('label', t.textTheme.labelLarge),
      ('labelSmall', t.textTheme.labelSmall),
      ('link', t.textTheme.link),
      ('tab', t.textTheme.tab),
      ('eyebrow', t.textTheme.overline),
      ('mono', t.textTheme.mono),
      ('monoSmall', t.textTheme.monoSmall),
      ('monogram', t.textTheme.monogram),
      ('wordmark', t.textTheme.wordmark),
    ];
    // Each slot's name stands clear of the specimen above it: the display
    // sizes' tight lines put the next name against their descenders.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostedSpacing.s16,
      children: [
        for (final (name, style) in slots)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FrostedSpacing.s4,
            children: [
              Text(name, style: t.textTheme.monoSmall),
              Text(
                style.fontSize! > 40 ? '\$482' : 'Groceries, 1,248.30',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ],
          ),
      ],
    );
  }
}

class _Shapes extends StatelessWidget {
  const _Shapes();

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final radii = <(String, double)>[
      ('sheet', FrostedCorners.r22),
      ('tile', FrostedCorners.r18),
      ('control', FrostedCorners.r12),
      ('small', FrostedCorners.r10),
    ];
    return Row(
      spacing: FrostedSpacing.s12,
      children: [
        for (final (name, radius) in radii)
          Expanded(
            child: Column(
              spacing: FrostedSpacing.s6,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.glass.fill,
                    border: Border.all(color: t.glass.edge),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: const SizedBox(height: 64, width: double.infinity),
                ),
                Text('$name ${radius.round()}', style: t.textTheme.monoSmall),
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
    final t = context.frostedTheme;
    const steps = <double>[
      FrostedSpacing.s4,
      FrostedSpacing.s8,
      FrostedSpacing.s10,
      FrostedSpacing.s12,
      FrostedSpacing.s16,
      FrostedSpacing.s20,
      FrostedSpacing.s24,
      FrostedSpacing.s32,
      FrostedSpacing.s40,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FrostedSpacing.s6,
      children: [
        for (final step in steps)
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text('${step.round()}', style: t.textTheme.monoSmall),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: t.colorScheme.textPrimary,
                  borderRadius: BorderRadius.circular(FrostedCorners.r2),
                ),
                child: SizedBox(width: step * 4, height: 8),
              ),
            ],
          ),
      ],
    );
  }
}

class _Formats extends StatelessWidget {
  const _Formats();

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final now = DateTime(2026, 10, 28, 19, 40);
    final lines = <(String, String)>[
      ('money', FrostedFormat.money(78182.56)),
      ('money out', FrostedFormat.money(-1326.44)),
      ('money in', FrostedFormat.money(3412.5, sign: true)),
      ('whole', FrostedFormat.money(2700, cents: false)),
      ('day', FrostedFormat.day(DateTime(2026, 10, 26), now: now)),
      ('date', FrostedFormat.date(DateTime(2026, 11, 12), weekday: true)),
      ('in days', FrostedFormat.inDays(DateTime(2026, 11, 1), now: now)),
      ('greeting', FrostedFormat.greeting('Maren', now: now)),
      ('now', FrostedFormat.nowLabel(now)),
      ('initials', FrostedFormat.initials('Blue Fern Café')),
      ('percent', '${FrostedFormat.percent(2840, 4000)}%'),
      ('plural', FrostedFormat.plural(3, 'bill')),
    ];
    return Column(
      spacing: FrostedSpacing.s6,
      children: [
        for (final (name, value) in lines)
          Row(
            children: [
              Expanded(child: Text(name, style: t.textTheme.bodyMedium)),
              Text(value, style: t.textTheme.amount),
            ],
          ),
      ],
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics();

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    const metrics = <(String, double)>[
      ('gutter', FrostedChromeMetrics.gutter),
      ('gutter, desktop', FrostedChromeMetrics.gutterWide),
      ('top bar inset', FrostedChromeMetrics.barInset),
      ('tab bar slab', FrostedChromeMetrics.slabHeight),
      ('move pill', FrostedChromeMetrics.movePill),
      ('sidebar', FrostedChromeMetrics.sideWidth),
      ('button', FrostedChromeMetrics.buttonHeight),
      ('round button', FrostedChromeMetrics.roundButton),
      ('option', FrostedChromeMetrics.option),
      ('sheet, desktop', FrostedChromeMetrics.sheetWideWidth),
      ('menu', FrostedChromeMetrics.menuWidth),
      ('toast, desktop', FrostedChromeMetrics.toastWideWidth),
    ];
    return Column(
      spacing: FrostedSpacing.s6,
      children: [
        for (final (name, value) in metrics)
          Row(
            children: [
              Expanded(child: Text(name, style: t.textTheme.bodyMedium)),
              Text('${value.round()}', style: t.textTheme.amount),
            ],
          ),
      ],
    );
  }
}
