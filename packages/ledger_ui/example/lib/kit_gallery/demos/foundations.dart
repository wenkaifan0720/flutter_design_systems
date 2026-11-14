/// Foundations: the theme's roles (the catalog's and Ledger's own: the
/// rules, the money inks, the seal, the hatches and the chrome's papers),
/// its type slots, shapes and spacing in the preset on show, the format
/// helpers, and the chrome's metrics. Everything below reads
/// `context.ledgerTheme`, so the page restyles with the preset and the
/// appearance.
library;

import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

import '../kit.dart';

Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Foundations',
  sections: [
    kitSection('Colour roles', children: [const _Roles()]),
    kitSection('Ledger roles', children: [const _OwnRoles()]),
    kitSection('Papers', children: [const _Papers()]),
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

String _number(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(2);

class _Swatches extends StatelessWidget {
  const _Swatches(this.roles);

  final List<(String, Color)> roles;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
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
                    border: Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(t.smallRadius),
                  ),
                  child: const SizedBox(width: 32, height: 22),
                ),
                const LedgerGap(LedgerSpacing.s12),
                // A role's name tied to its value by the dot leader, as a
                // ledger's line is.
                Expanded(
                  child: LedgerLeaderLine(
                    start: Text(name, style: t.bodySmall),
                    end: Text(_hex(color), style: t.amount),
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
    final t = context.ledgerTheme;
    return _Swatches([
      ('background', t.background),
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
      ('onSuccess', t.onSuccess),
      ('successSubtle', t.successSubtle),
      ('warning', t.warning),
      ('warningSubtle', t.warningSubtle),
      ('danger', t.danger),
      ('onDanger', t.onDanger),
      ('dangerSubtle', t.dangerSubtle),
      ('overlay', t.overlay),
    ]);
  }
}

class _OwnRoles extends StatelessWidget {
  const _OwnRoles();

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return _Swatches([
      ('hairline', t.hairline),
      ('textFaint', t.textFaint),
      ('headRule', t.headRule),
      ('accentRule', t.accentRule),
      ('moneyIn', t.moneyIn),
      ('moneyInCents', t.moneyInCents),
      ('over', t.over),
      ('overCents', t.overCents),
      ('move', t.move),
      ('moveCents', t.moveCents),
      ('pace', t.pace),
      ('seal', t.seal),
      ('sealOver', t.sealOver),
      ('sealInk', t.sealInk),
      ('hatchInk', t.hatchInk),
      ('hatchGreen', t.hatchGreen),
      ('hatchPale', t.hatchPale),
      ('topBarFill', t.topBarFill),
      ('tabBarFill', t.tabBarFill),
      ('sideBarFill', t.sideBarFill),
      ('selectedFill', t.selectedFill),
      ('selectedRing', t.selectedRing),
      ('discRing', t.discRing),
      ('dotRing', t.dotRing),
      ('avatar', t.avatar),
      ('onAvatar', t.onAvatar),
      ('toast', t.toast),
      ('onToast', t.onToast),
      ('onToastAction', t.onToastAction),
      ('toastRing', t.toastRing),
      ('menuSelected', t.menuSelected),
    ]);
  }
}

/// The papers the chrome lays down, each with its own shadow: a memo slip,
/// a sheet's card, the toast's dark slip.
class _Papers extends StatelessWidget {
  const _Papers();

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Row(
      spacing: LedgerSpacing.s12,
      children: [
        Expanded(
          child: _Face(
            label: 'Paper',
            ink: t.textPrimary,
            decoration: BoxDecoration(
              color: t.surface,
              border: Border.all(color: t.border),
              borderRadius: BorderRadius.circular(t.cardRadius),
              boxShadow: t.paperShadow,
            ),
          ),
        ),
        Expanded(
          child: _Face(
            label: 'Sheet',
            ink: t.textPrimary,
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(t.sheetRadius),
              boxShadow: t.sheetShadow,
            ),
          ),
        ),
        Expanded(
          child: _Face(
            label: 'Toast',
            ink: t.onToast,
            decoration: BoxDecoration(
              color: t.toast,
              border: Border.all(color: t.toastRing),
              borderRadius: BorderRadius.circular(t.cardRadius),
              boxShadow: t.toastShadow,
            ),
          ),
        ),
      ],
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.label,
    required this.ink,
    required this.decoration,
  });

  final String label;
  final Color ink;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return DecoratedBox(
      decoration: decoration,
      child: SizedBox(
        height: 72,
        child: Center(
          child: Text(label.toUpperCase(), style: t.label.copyWith(color: ink)),
        ),
      ),
    );
  }
}

class _Slots extends StatelessWidget {
  const _Slots();

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final slots = <(String, TextStyle)>[
      ('figure', t.figure),
      ('figureMedium', t.figureMedium),
      ('figureSmall', t.figureSmall),
      ('title', t.title),
      ('barTitle', t.barTitle),
      ('sheetTitle', t.sheetTitle),
      ('wordmark', t.wordmark),
      ('body', t.body),
      ('rowTitle', t.rowTitle),
      ('bodySmall', t.bodySmall),
      ('label', t.label),
      ('meta', t.meta),
      ('amount', t.amount),
      ('tab', t.tab),
      ('button', t.button),
      ('buttonSmall', t.buttonSmall),
      ('navLink', t.navLink),
      ('link', t.link),
      ('pill', t.pill),
      ('tag', t.tag),
      ('toastText', t.toastText),
      ('toastAction', t.toastAction),
      ('monogram', t.monogram),
      ('initials', t.initials),
      ('footnote', t.footnote),
      ('search', t.search),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LedgerSpacing.s8,
      children: [
        for (final (name, style) in slots)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$name ${_number(style.fontSize ?? 0)}',
                style: t.meta.copyWith(color: t.textTertiary),
              ),
              // The large figures' "$" rises past their tight line: room
              // under the name so it never runs into it.
              if (style.fontSize! > 40) SizedBox(height: style.fontSize! * .14),
              _OnItsGround(
                // A toast's words, and an avatar's paper initials, are set
                // on the ink, as they stand.
                inverse: name.startsWith('toast') || name == 'initials',
                avatar: name == 'initials',
                child: Text(
                  // October's spending and its groceries (the sample data).
                  style.fontSize! > 40
                      ? LedgerFormat.money(2486.12, showCents: false)
                      : 'Groceries, ${LedgerFormat.money(412.36)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // The initials in the avatar's own ink, by day and night.
                  style: name == 'initials' ? style.colored(t.onAvatar) : style,
                ),
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
    final t = context.ledgerTheme;
    final radii = <(String, double)>[
      ('sheet', t.sheetRadius),
      ('card', t.cardRadius),
      ('small', t.smallRadius),
      ('control', t.controlRadius),
    ];
    Widget shape((String, double) r) => Column(
      // Each swatch fills its share, its name under it on the
      // swatch's start (a bare SizedBox(height:) took no width,
      // drawing no swatch at all).
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: LedgerSpacing.s6,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.borderStrong),
            borderRadius: BorderRadius.circular(r.$2),
          ),
          child: const SizedBox(width: double.infinity, height: 64),
        ),
        Text('${r.$1} ${_number(r.$2)}', style: t.amount),
      ],
    );
    // Four across on a wide page; on a phone or with a large text two, so
    // each name stays whole on its line. Swatches share their top line.
    final across =
        LedgerLayout.isWide(context) &&
            MediaQuery.textScalerOf(context).scale(1) <= 1
        ? radii.length
        : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LedgerSpacing.s16,
      children: [
        for (var i = 0; i < radii.length; i += across)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: LedgerSpacing.s12,
            children: [
              for (final r in radii.skip(i).take(across))
                Expanded(child: shape(r)),
            ],
          ),
      ],
    );
  }
}

class _Spacing extends StatelessWidget {
  const _Spacing();

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    const steps = <double>[
      LedgerSpacing.s4,
      LedgerSpacing.s8,
      LedgerSpacing.s12,
      LedgerSpacing.s16,
      LedgerSpacing.s20,
      LedgerSpacing.s24,
      LedgerSpacing.s32,
      LedgerSpacing.s48,
      LedgerSpacing.s72,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: LedgerSpacing.s6,
      children: [
        for (final step in steps)
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text('${step.round()}', style: t.amount),
              ),
              DecoratedBox(
                decoration: BoxDecoration(color: t.accent),
                child: SizedBox(width: step * 3, height: 8),
              ),
            ],
          ),
      ],
    );
  }
}

/// A type specimen on the ground its words are set on: the page's paper, or
/// the toast's ink for the toast's words.
class _OnItsGround extends StatelessWidget {
  const _OnItsGround({
    required this.inverse,
    required this.child,
    this.avatar = false,
  });

  final bool inverse;
  final Widget child;

  /// On the avatar's ground rather than the toast's.
  final bool avatar;

  @override
  Widget build(BuildContext context) {
    if (!inverse) return child;
    final t = context.ledgerTheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: avatar ? t.avatar : t.toast,
          borderRadius: BorderRadius.circular(t.smallRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LedgerSpacing.s12,
            vertical: LedgerSpacing.s6,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Formats extends StatelessWidget {
  const _Formats();

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final lines = <(String, String)>[
      ('money', LedgerFormat.money(78182.56)),
      ('money out', LedgerFormat.money(-1326.44)),
      ('money in', LedgerFormat.money(3412.5, showSign: true)),
      ('whole', LedgerFormat.money(2700, showCents: false)),
      ('day', LedgerFormat.day(DateTime(2026, 10, 26), now: kitNow)),
      // The sample's today, as every other line reads it.
      ('date', LedgerFormat.date(kitNow, showWeekday: true)),
      ('long date', LedgerFormat.longDate(kitNow)),
      ('in days', LedgerFormat.inDays(DateTime(2026, 11, 1), now: kitNow)),
      ('greeting', LedgerFormat.greeting('Maren', now: kitNow)),
      ('today', LedgerFormat.today(kitNow)),
      ('now', LedgerFormat.nowLabel(kitNow)),
      ('initials', LedgerFormat.initials('Blue Fern Café')),
      ('percent', '${LedgerFormat.percent(2840, 4000)}%'),
      ('plural', LedgerFormat.plural(3, 'bill')),
    ];
    return Column(
      spacing: LedgerSpacing.s6,
      children: [
        for (final (name, value) in lines)
          LedgerLeaderLine(
            start: Text(name, style: t.bodySmall),
            end: Text(value, style: t.amount),
          ),
      ],
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics();

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    const metrics = <(String, double)>[
      ('gutter', LedgerChromeMetrics.gutter),
      ('gutter, desktop', LedgerChromeMetrics.gutterWide),
      ('top bar', LedgerChromeMetrics.topBarHeight),
      ('tab bar', LedgerChromeMetrics.tabBarHeight),
      ('disc', LedgerChromeMetrics.disc),
      ('sidebar', LedgerChromeMetrics.sideWidth),
      ('button', LedgerChromeMetrics.button),
      ('quiet button', LedgerChromeMetrics.quietButton),
      ('icon button', LedgerChromeMetrics.iconButton),
      ('ringed button', LedgerChromeMetrics.ringButton),
      ('avatar', LedgerChromeMetrics.avatar),
      ('dialog, desktop', LedgerChromeMetrics.dialogWidth),
      ('toast, desktop', LedgerChromeMetrics.toastWidth),
      ('double rule', LedgerChromeMetrics.doubleRule),
      ('leader pitch', LedgerChromeMetrics.leaderPitch),
    ];
    return Column(
      spacing: LedgerSpacing.s6,
      children: [
        for (final (name, value) in metrics)
          LedgerLeaderLine(
            start: Text(name, style: t.bodySmall),
            end: Text(_number(value), style: t.amount),
          ),
      ],
    );
  }
}
