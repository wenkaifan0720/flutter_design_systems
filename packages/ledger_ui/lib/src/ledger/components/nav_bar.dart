import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../chrome_metrics.dart';
import '../internal/face.dart';
import '../theme.dart';

/// One destination of the app's root, as generated apps declare a tab: its
/// glyph, the [label] the tab bar and the sidebar print (and speak) and the
/// walkthrough [key] set on its hit target, positionally. While current it
/// wears its [selectedIcon] (null keeps [icon]); its page stands on its
/// [ground] (the design kit's surface or media). As the bar's green disc
/// (the app's main act), the sidebar's green act says its [actLabel]
/// ([LedgerNavItem.act]).
///
/// ```dart
/// LedgerNavItem(LucideIcons.chartPie, 'Spending', ValueKey('open-spending'))
/// ```
@immutable
class LedgerNavItem {
  /// A destination with [icon] and [label].
  const LedgerNavItem(this.icon, this.label, [this.key])
    : selectedIcon = null,
      ground = ChromeGround.surface,
      actLabel = null;

  /// The app's main act as a tab (the green disc on a phone), whose act in
  /// the sidebar says [actLabel]: "Move money" where the disc is "Move".
  ///
  /// ```dart
  /// LedgerNavItem.act(LucideIcons.arrowRightLeft, 'Move', actLabel: 'Move money')
  /// ```
  const LedgerNavItem.act(
    this.icon,
    this.label, {
    required String this.actLabel,
    this.key,
  }) : selectedIcon = null,
       ground = ChromeGround.surface;

  /// The item a runtime [NavTab] asks for.
  LedgerNavItem.fromTab(NavTab tab)
    : icon = tab.icon,
      label = tab.label,
      selectedIcon = tab.selectedIcon,
      key = tab.key,
      ground = tab.ground,
      actLabel = null;

  /// The destination's glyph.
  final IconData icon;

  /// The destination's name, printed and spoken.
  final String label;

  /// The glyph while current; null keeps [icon].
  final IconData? selectedIcon;

  /// The walkthrough key set on its hit target.
  final Key? key;

  /// What its page stands on: the design kit's surface or media.
  final ChromeGround ground;

  /// The sidebar act's words when this item is the disc.
  final String? actLabel;
}

/// The phone's tab bar, as the source's `.tabbar` draws it: raised
/// paper 84 tall with a rule over it, five columns of a 22 glyph over its
/// name in the third ink (the current one in the ink, the green tick under
/// it), the middle destination drawn as the green disc ringed in the paper
/// (Move). The columns stand in one row hung from under the rule, as tall
/// as its tallest column and never shorter than the bar's room over its 22
/// foot, each column at the row's foot: the disc's column fills the bar
/// from its rule and the tabs end 7 over the bar's foot, where the
/// browser's grid sets them. A [ShellAction] given to the shell stands
/// as the disc instead, between the tabs. [accessory] rides 8 over the
/// bar. It is paper, opaque: the source frosts it, but a page scrolled
/// under glass smears through (no glass, no glow).
///
/// ```dart
/// LedgerNavBar(items: tabs, selectedIndex: 0, onDestinationSelected: select)
/// ```
class LedgerNavBar extends StatelessWidget {
  /// A tab bar of [items], [selectedIndex] current.
  const LedgerNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.action,
    this.accessory,
    super.key,
  });

  /// The destinations, in order.
  final List<LedgerNavItem> items;

  /// The index of the current destination.
  final int selectedIndex;

  /// Called with the index of the destination pressed.
  final ValueChanged<int> onDestinationSelected;

  /// The shell's act, drawn as the disc.
  final ShellAction? action;

  /// A widget riding 8 over the bar.
  final Widget? accessory;

  /// Which tab is the disc: the middle of five, when no act takes it.
  static int? discTab(int count, {required bool action}) =>
      !action && count == 5 ? 2 : null;

  /// Where an act's disc stands among the tabs: the middle.
  static int discAction(int count) => count ~/ 2;

  /// Whether a bar of [count] tabs (and the shell's act, with [action])
  /// raises the disc.
  static bool hasDisc(int count, {required bool action}) =>
      action || discTab(count, action: false) != null;

  /// The height of a tab's column in [context]: its glyph and the 6 under
  /// it (the disc and the 4 it leaves, with [disc]), its name's line, the 4
  /// over the tick and the tick: 48, and 76 for the disc's.
  static double columnIn(BuildContext context, {required bool disc}) {
    final tab = context.ledgerTheme.tab;
    final line =
        MediaQuery.textScalerOf(context).scale(tab.fontSize!) * tab.height!;
    return (disc
            ? LedgerChromeMetrics.disc +
                  LedgerChromeMetrics.tabGap -
                  LedgerChromeMetrics.discSink
            : LedgerChromeMetrics.tabGlyph + LedgerChromeMetrics.tabGap) +
        line +
        (LedgerChromeMetrics.tabGap - LedgerChromeMetrics.tickLift) +
        LedgerChromeMetrics.tick;
  }

  /// The band a bar of [count] tabs stands in over a device inset of
  /// [inset]: [heightIn], or its rule and its row where a larger text
  /// scale makes the row the taller.
  static double bandIn(
    BuildContext context, {
    required double inset,
    required int count,
    required bool action,
  }) => math.max(
    heightIn(inset),
    _rule + columnIn(context, disc: hasDisc(count, action: action)),
  );

  /// The bar's height over a device inset of [inset]: 84, its 22 foot
  /// grown to the inset when the inset is larger.
  static double heightIn(double inset) =>
      LedgerChromeMetrics.tabBarHeight -
      LedgerChromeMetrics.tabBarFoot +
      math.max(LedgerChromeMetrics.tabBarFoot, inset);

  /// The rule over the bar, 1 (`border-top: 1px`).
  static const double _rule = 1;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final inset = MediaQuery.paddingOf(context).bottom;
    final act = action;
    final disc = discTab(items.length, action: act != null);
    final cells = <Widget>[
      for (final (i, item) in items.indexed)
        _Tab(
          key: item.key,
          icon: i == selectedIndex
              ? (item.selectedIcon ?? item.icon)
              : item.icon,
          label: item.label,
          selected: i == selectedIndex,
          disc: i == disc,
          onTap: () => onDestinationSelected(i),
        ),
    ];
    if (act != null) {
      cells.insert(
        discAction(items.length),
        _Tab(
          key: act.key,
          icon: act.icon,
          label: act.label ?? '',
          selected: false,
          disc: true,
          onTap: () => act.onPressed(context),
        ),
      );
    }
    final ground = DecoratedBox(
      decoration: BoxDecoration(
        color: t.tabBarFill,
        border: Border(top: BorderSide(color: t.border)),
      ),
    );
    final height = heightIn(inset);
    final foot = math.max(LedgerChromeMetrics.tabBarFoot, inset);
    // The source's grid hangs its one row from under the rule: the row is
    // as tall as its tallest column (the disc's 76) and never shorter than
    // the room over the foot (61), and every column stands at the row's
    // foot. The disc's column so fills the bar from the rule, and the row
    // runs 15 into the 22 foot, the tabs ending 7 over the bar's foot. The
    // bar grows only where a larger text scale makes the row taller than
    // all of it.
    final bar = Stack(
      children: [
        Positioned.fill(child: ground),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LedgerChromeMetrics.tabBarSide,
              _rule,
              LedgerChromeMetrics.tabBarSide,
              0,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: height - _rule - foot),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [for (final cell in cells) Expanded(child: cell)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LedgerChromeMetrics.accessoryGap,
        children: [?accessory, bar],
      ),
    );
  }
}

/// One tab: its glyph (or the disc), its name, and the tick under it.
class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.disc,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool disc;
  final VoidCallback onTap;

  // The least room between two tabs' names.
  static const double _nameGap = 4;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final ink = selected || disc ? t.textPrimary : t.textTertiary;
    final Widget? mark;
    if (disc) {
      const d = LedgerChromeMetrics.disc;
      mark = Padding(
        // The disc stands 2 into the gap under it.
        padding: const EdgeInsets.only(
          bottom: LedgerChromeMetrics.tabGap - LedgerChromeMetrics.discSink,
        ),
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.accent,
            // The paper ring over the drop, as CSS draws its first shadow
            // topmost (a BoxDecoration paints its last).
            boxShadow: [
              ...t.discShadow,
              BoxShadow(
                color: t.discRing,
                spreadRadius: LedgerChromeMetrics.discRing,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: LedgerChromeMetrics.tabGlyph,
            color: t.onAccent,
          ),
        ),
      );
    } else {
      mark = null;
    }
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // The chosen tab's ink and its green tick come and go in Ledger's
        // one motion.
        child: LedgerFace(
          style: LedgerFaceStyle(
            ink: ink,
            ground: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? t.accent : null,
            ),
          ),
          builder: (context, s, _) => Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              mark ??
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: LedgerChromeMetrics.tabGap,
                    ),
                    child: Icon(
                      icon,
                      size: LedgerChromeMetrics.tabGlyph,
                      color: s.ink,
                    ),
                  ),
              // A name wider than its column at a large text size sets
              // smaller on its one line rather than lose its end, never
              // closer than [_nameGap] to its neighbour's (a gap that grows
              // with the words, as a word space does).
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      MediaQuery.textScalerOf(context).scale(_nameGap) / 2,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: t.tab.colored(s.ink),
                  ),
                ),
              ),
              // The tick stands 2 up into the 6 under the name.
              const SizedBox(
                height:
                    LedgerChromeMetrics.tabGap - LedgerChromeMetrics.tickLift,
              ),
              Container(
                width: LedgerChromeMetrics.tick,
                height: LedgerChromeMetrics.tick,
                decoration: s.ground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
