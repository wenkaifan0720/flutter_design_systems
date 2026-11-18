import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart' show ShellAction;
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/cap_center.dart';
import '../internal/end_glyph.dart';
import '../internal/face.dart';
import '../internal/shell_faces.dart';
import '../internal/state_face.dart';
import '../theme.dart';
import 'avatar/avatar.dart';
import 'brand/brand.dart';
import 'nav_bar.dart';
import 'pressable/pressable.dart';
import 'top_bar.dart';

/// The desktop's sidebar, as the source's `.sidebar` draws it in its 248
/// column of sunken paper, a rule down its end: the wordmark at 30, the
/// green act (the tab bar's disc, Move money, or the shell's act), the
/// other destinations as links of 40 (the current one on raised paper,
/// ringed in the hairline, its glyph green), and at its foot over a rule
/// the owner (the avatar, the name, the meta line and a chevron), which
/// opens the profile. On the profile ([profileSelected]) the foot is the
/// current place; with [selectedIndex] null (the notifications) no
/// destination is current. [solid] draws it on the
/// media ground's dark paper.
///
/// With [extended] false it is the tablet's rail, [railWidth] wide: the
/// brand mark, the green act as a disc, each destination its glyph alone
/// (named for a screen reader), the owner's avatar at the foot.
///
/// ```dart
/// LedgerSideBar(items: tabs, selectedIndex: 0, onDestinationSelected: select, brand: 'Keel')
/// ```
///
/// ```dart
/// LedgerSideBar(items: tabs, selectedIndex: 0, onDestinationSelected: select, extended: false)
/// ```
class LedgerSideBar extends StatelessWidget {
  /// The sidebar of [items], [selectedIndex] current.
  const LedgerSideBar({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.action,
    this.brand,
    this.profileSelected = false,
    this.solid = false,
    this.extended = true,
    super.key,
  });

  /// The sidebar's width: 248.
  static const double width = LedgerChromeMetrics.sideWidth;

  /// The rail's width ([extended] false): 80.
  static const double railWidth = 80;

  /// Whether it is the full sidebar (true) or the tablet's rail.
  final bool extended;

  /// The destinations, in the tab bar's order.
  final List<LedgerNavItem> items;

  /// The current destination; null lights none (a page none of them is).
  final int? selectedIndex;

  /// Called with the index of the destination pressed.
  final ValueChanged<int> onDestinationSelected;

  /// The shell's act, standing as the green act.
  final ShellAction? action;

  /// The app's name for the wordmark; null draws none.
  final String? brand;

  /// Whether the profile is shown (the foot is current).
  final bool profileSelected;

  /// Whether it stands on the media ground (opaque).
  final bool solid;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('extended', value: extended, ifTrue: 'extended'))
      ..add(IterableProperty<LedgerNavItem>('items', items))
      ..add(IntProperty('selectedIndex', selectedIndex, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        DiagnosticsProperty<ShellAction>('action', action, defaultValue: null),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(
        FlagProperty(
          'profileSelected',
          value: profileSelected,
          ifTrue: 'profileSelected',
        ),
      )
      ..add(FlagProperty('solid', value: solid, ifTrue: 'solid'));
  }

  @override
  Widget build(BuildContext context) {
    final account = LedgerAccountScope.maybeOf(context);
    final act = action;
    final disc = LedgerNavBar.discTab(items.length, action: act != null);
    final current = profileSelected ? -1 : selectedIndex ?? -1;
    // Under [LedgerNavigationFrame] ui_core's shell presses the
    // destinations (one tab stop, the arrows along them) and the bar paints
    // them.
    final built = LedgerShellDestinations.maybeOf(context);
    Widget dest(int i, Widget own) =>
        built != null && i < built.length ? built[i] : own;
    final Widget? green = act != null
        ? _SideAct(
            key: act.key,
            icon: act.icon,
            label: act.label ?? '',
            current: false,
            onTap: () => act.onPressed(context),
          )
        : disc != null
        ? dest(
            disc,
            _SideAct(
              key: items[disc].key,
              icon: items[disc].icon,
              label: items[disc].actLabel ?? items[disc].label,
              current: current == disc,
              onTap: () => onDestinationSelected(disc),
            ),
          )
        : null;
    final name = brand;
    final Widget bar = extended
        ? _side(context, account, green, disc, current, name, dest)
        : _rail(context, account, act, disc, current, name, dest);
    if (built == null) return bar;
    return LedgerDestinationFaces(
      paint: (context, i, states) {
        final item = items[i];
        if (!extended) {
          return _RailMark(
            key: item.key,
            icon: i == current ? (item.selectedIcon ?? item.icon) : item.icon,
            on: i == current,
            green: i == disc,
            states: states,
          );
        }
        return i == disc
            ? _SideAct(
                key: item.key,
                icon: item.icon,
                label: item.actLabel ?? item.label,
                current: i == current,
                states: states,
              )
            : _Link(item: item, current: i == current, states: states);
      },
      child: bar,
    );
  }

  Widget _side(
    BuildContext context,
    LedgerAccount? account,
    Widget? green,
    int? disc,
    int current,
    String? name,
    Widget Function(int i, Widget own) dest,
  ) {
    final t = context.ledgerTheme;
    // A Container insets its child by the rule too, as CSS's border-box
    // does: the column's room ends 20 inside the rule.
    return Container(
      decoration: BoxDecoration(
        color: t.sideBarFill,
        border: BorderDirectional(end: BorderSide(color: t.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        LedgerChromeMetrics.sidePad,
        LedgerChromeMetrics.sideTop,
        LedgerChromeMetrics.sidePad,
        LedgerChromeMetrics.sidePad,
      ),
      // A region for the keyline check: faces on the column, the mark, the
      // glyphs, the avatar and the profile's chevron on the inner keyline.
      child: DesignKeylineRegion(
        label: 'side bar',
        indents: const [LedgerChromeMetrics.navPad],
        trailingIndents: const [LedgerChromeMetrics.navPad],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: LedgerChromeMetrics.sideGap,
          children: [
            if (name != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LedgerChromeMetrics.sideBrandInset,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: LedgerWordmark(
                    name,
                    size: LedgerWordmarkSize.large,
                    onTap: items.isEmpty
                        ? null
                        : () => onDestinationSelected(0),
                  ),
                ),
              ),
            ?green,
            Semantics(
              container: true,
              explicitChildNodes: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: LedgerChromeMetrics.navGap,
                children: [
                  for (final (i, item) in items.indexed)
                    if (i != disc)
                      dest(
                        i,
                        _Link(
                          item: item,
                          current: i == current,
                          onTap: () => onDestinationSelected(i),
                        ),
                      ),
                ],
              ),
            ),
            const Spacer(),
            if (account != null)
              _Foot(account: account, current: profileSelected),
          ],
        ),
      ),
    );
  }

  Widget _rail(
    BuildContext context,
    LedgerAccount? account,
    ShellAction? act,
    int? disc,
    int current,
    String? name,
    Widget Function(int i, Widget own) dest,
  ) {
    final t = context.ledgerTheme;
    return Container(
      width: railWidth,
      decoration: BoxDecoration(
        color: t.sideBarFill,
        border: BorderDirectional(end: BorderSide(color: t.border)),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: LedgerChromeMetrics.sideTop,
      ),
      child: Column(
        spacing: LedgerChromeMetrics.sideGap,
        children: [
          if (name != null)
            Semantics(
              label: name,
              child: LedgerPressable(
                onTap: items.isEmpty ? null : () => onDestinationSelected(0),
                label: name,
                child: const LedgerBrandMark(size: 30),
              ),
            ),
          if (act != null)
            _RailMark(
              key: act.key,
              icon: act.icon,
              label: act.label ?? '',
              on: false,
              green: true,
              onTap: () => act.onPressed(context),
            )
          else if (disc != null)
            dest(
              disc,
              _RailMark(
                key: items[disc].key,
                icon: items[disc].icon,
                label: items[disc].actLabel ?? items[disc].label,
                on: current == disc,
                green: true,
                onTap: () => onDestinationSelected(disc),
              ),
            ),
          Semantics(
            container: true,
            explicitChildNodes: true,
            child: Column(
              spacing: LedgerChromeMetrics.navGap,
              children: [
                for (final (i, item) in items.indexed)
                  if (i != disc)
                    dest(
                      i,
                      _RailMark(
                        key: item.key,
                        icon: i == current
                            ? (item.selectedIcon ?? item.icon)
                            : item.icon,
                        label: item.label,
                        on: i == current,
                        onTap: () => onDestinationSelected(i),
                      ),
                    ),
              ],
            ),
          ),
          const Spacer(),
          if (account != null)
            LedgerAvatar(
              initials: account.initials,
              label: 'Profile and settings',
              onTap: account.onProfilePressed == null
                  ? null
                  : () => account.onProfilePressed!(context),
            ),
        ],
      ),
    );
  }
}

/// A rail's mark: a destination's glyph alone in a 48 circle (the current
/// one on raised paper, its glyph green), or the green act's disc.
class _RailMark extends StatelessWidget {
  const _RailMark({
    required this.icon,
    required this.on,
    this.label = '',
    this.green = false,
    this.onTap,
    this.states,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool on;
  final bool green;

  /// Its own press; null where ui_core's shell presses it ([states]).
  final VoidCallback? onTap;

  /// The shell's press's states.
  final Set<WidgetState>? states;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    // The chosen mark's fill and ring land at once, in the frame its page
    // does, as the side bar's links do.
    final face = LedgerFace(
      duration: Duration.zero,
      style: LedgerFaceStyle(
        ink: green
            ? t.onAccent
            : on
            ? t.accent
            : t.textSecondary,
        ground: BoxDecoration(
          shape: BoxShape.circle,
          color: green ? t.accent : (on ? t.selectedFill : null),
          boxShadow: green
              ? (on
                    ? [
                        BoxShadow(
                          color: t.accent,
                          spreadRadius:
                              LedgerChromeMetrics.sideActRingGap +
                              LedgerChromeMetrics.sideActRing,
                        ),
                        BoxShadow(
                          color: t.sideBarFill,
                          spreadRadius: LedgerChromeMetrics.sideActRingGap,
                        ),
                      ]
                    : t.primaryShadow)
              : on
              ? [BoxShadow(color: t.selectedRing, spreadRadius: 1)]
              : null,
        ),
      ),
      builder: (context, s, _) => Container(
        width: _size,
        height: _size,
        decoration: s.ground,
        child: Icon(icon, size: LedgerChromeMetrics.navGlyph, color: s.ink),
      ),
    );
    final shell = states;
    if (shell != null) {
      return LedgerStateFace(states: shell, radius: _size / 2, child: face);
    }
    return LedgerPressable(
      onTap: onTap,
      label: label,
      selected: on,
      radius: _size / 2,
      child: face,
    );
  }
}

/// The sidebar's green act (`.btn-move`): 44 tall, round, its glyph and its
/// words in the raised paper, the green drop under it; current, a ring of
/// the sidebar's paper and a green ring past it instead.
class _SideAct extends StatelessWidget {
  const _SideAct({
    required this.icon,
    required this.label,
    required this.current,
    this.onTap,
    this.states,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool current;

  /// Its own press; null where ui_core's shell presses it ([states]).
  final VoidCallback? onTap;

  /// The shell's press's states.
  final Set<WidgetState>? states;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final shell = states;
    Widget press(Widget face) => shell != null
        ? LedgerStateFace(states: shell, radius: t.controlRadius, child: face)
        : LedgerPressable(
            onTap: onTap,
            label: label,
            selected: current,
            radius: t.controlRadius,
            child: face,
          );
    return press(
      Container(
        height: LedgerChromeMetrics.sideAct,
        decoration: BoxDecoration(
          color: t.accent,
          borderRadius: BorderRadius.circular(t.controlRadius),
          // `.btn-move.is-on`: `0 0 0 3px paper-lo, 0 0 0
          // 4px green`. CSS paints its first shadow on top, Flutter its
          // last: the green ring goes first, the paper gap over it.
          boxShadow: current
              ? [
                  BoxShadow(
                    color: t.accent,
                    spreadRadius:
                        LedgerChromeMetrics.sideActRingGap +
                        LedgerChromeMetrics.sideActRing,
                  ),
                  BoxShadow(
                    color: t.sideBarFill,
                    spreadRadius: LedgerChromeMetrics.sideActRingGap,
                  ),
                ]
              : t.primaryShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: LedgerChromeMetrics.buttonGap,
          children: [
            Icon(
              icon,
              size: LedgerChromeMetrics.buttonGlyph,
              color: t.onAccent,
            ),
            Flexible(
              child: ledgerCapCenter(
                t.button,
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.button
                      .sized(LedgerChromeMetrics.sideActText)
                      .colored(t.onAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One destination's link (`.nav a`).
class _Link extends StatelessWidget {
  const _Link({
    required this.item,
    required this.current,
    this.onTap,
    this.states,
  });

  final LedgerNavItem item;
  final bool current;

  /// Its own press; null where ui_core's shell presses it ([states]).
  final VoidCallback? onTap;

  /// The shell's press's states.
  final Set<WidgetState>? states;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final shell = states;
    Widget press(Widget face) => shell != null
        ? KeyedSubtree(
            key: item.key,
            child: LedgerStateFace(
              states: shell,
              radius: t.controlRadius,
              child: face,
            ),
          )
        : LedgerPressable(
            key: item.key,
            onTap: onTap,
            label: item.label,
            selected: current,
            radius: t.controlRadius,
            child: face,
          );
    // The chosen link's fill, ring and ink land at once, in the frame its
    // page does: a selection never trails the page it names (the press
    // has already sunk the link on the tap).
    return press(
      LedgerFace(
        duration: Duration.zero,
        style: LedgerFaceStyle(
          ink: current ? t.textPrimary : t.textSecondary,
          quiet: current ? t.accent : t.textSecondary,
          ground: BoxDecoration(
            color: current ? t.selectedFill : null,
            borderRadius: BorderRadius.circular(t.controlRadius),
            boxShadow: current
                ? [BoxShadow(color: t.selectedRing, spreadRadius: 1)]
                : null,
          ),
        ),
        // 40, or the tap floor where a finger reaches it (a tablet's).
        builder: (context, s, _) => Container(
          height: math.max(
            LedgerChromeMetrics.navLink,
            DesignTapTargets.of(context).floorOn().height,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: LedgerChromeMetrics.navPad,
          ),
          decoration: s.ground,
          child: Row(
            spacing: LedgerChromeMetrics.navGlyphGap,
            children: [
              Icon(
                current ? (item.selectedIcon ?? item.icon) : item.icon,
                size: LedgerChromeMetrics.navGlyph,
                color: s.quiet,
              ),
              Expanded(
                child: ledgerCapCenter(
                  t.navLink,
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.navLink.colored(s.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sidebar's foot (`.side-profile`): the owner over a rule, opening the
/// profile.
class _Foot extends StatelessWidget {
  const _Foot({required this.account, required this.current});

  final LedgerAccount account;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final open = account.onProfilePressed;
    final meta = account.meta;
    // At a large text size the name and its meta take the bar's whole width
    // under the monogram, wrapping whole rather than a word a line beside it.
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    // The foot stands 16 under its rule (a Container insets by the rule).
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        LedgerChromeMetrics.profileSide,
        LedgerChromeMetrics.profileTop,
        LedgerChromeMetrics.profileSide,
        0,
      ),
      child: LedgerPressable(
        onTap: open == null ? null : () => open(context),
        label: 'Profile and settings',
        selected: current,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: DesignTapTargets.of(context).floorOn().height,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            heightFactor: 1,
            child: larger ? _stacked(t, meta) : _beside(t, meta),
          ),
        ),
      ),
    );
  }

  Widget get _chevron => Builder(
    builder: (context) => LedgerEndGlyph(
      LucideIcons.chevronRight,
      size: LedgerChromeMetrics.profileChevron,
      color: context.ledgerTheme.textFaint,
    ),
  );

  /// The monogram, the name over its meta, the chevron, on one line.
  Widget _beside(LedgerThemeData t, String? meta) => Row(
    spacing: LedgerChromeMetrics.profileGap,
    children: [
      LedgerAvatar(initials: account.initials),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              account.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.navLink.line(20).colored(t.textPrimary),
            ),
            if (meta != null)
              Text(
                meta.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.meta,
              ),
          ],
        ),
      ),
      _chevron,
    ],
  );

  /// The monogram and the chevron on a line, the name and its meta under
  /// them across the bar's width, wrapping whole.
  Widget _stacked(LedgerThemeData t, String? meta) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: LedgerChromeMetrics.profileGap,
    children: [
      Row(
        children: [
          LedgerAvatar(initials: account.initials),
          const Spacer(),
          _chevron,
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(account.name, style: t.navLink.line(20).colored(t.textPrimary)),
          if (meta != null) Text(meta.toUpperCase(), style: t.meta),
        ],
      ),
    ],
  );
}
