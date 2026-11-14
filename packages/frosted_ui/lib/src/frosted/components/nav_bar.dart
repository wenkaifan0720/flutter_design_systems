import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../chrome_metrics.dart';
import '../internal/css_shadow.dart';
import '../internal/face.dart';
import '../internal/key_focus.dart';
import '../internal/sliding_pill.dart';
import '../internal/styled.dart';
import '../theme.dart';
import '../internal/chosen_plate.dart';
import '../internal/dim.dart';

/// One destination of the tab bar and the sidebar, as generated apps
/// declare a tab: its [icon], the [label] printed under it (and spoken) and
/// the walkthrough [key] set on its hit target, positionally. While selected
/// it wears its [selectedIcon] (null wears [icon] in the ink); its root
/// stands on its [ground]. As the app's main act (the ink pill in the tab
/// bar's middle), the sidebar's ink button prints its [actionLabel]
/// ([FrostedNavItem.action]).
///
/// ```dart
/// FrostedNavItem(FrostedGlyphs.chartPie, 'Spending', ValueKey('open-spending'))
/// ```
@immutable
class FrostedNavItem {
  /// Creates a [FrostedNavItem].
  const FrostedNavItem(this.icon, this.label, [this.key])
    : selectedIcon = null,
      ground = ChromeGround.surface,
      actionLabel = null;

  /// The app's main act as a tab (the ink pill on a phone), whose ink
  /// button in the sidebar says [actionLabel]: "Move money" where the pill is
  /// "Move".
  ///
  /// ```dart
  /// FrostedNavItem.action(FrostedGlyphs.arrowRightLeft, 'Move', actionLabel: 'Move money')
  /// ```
  const FrostedNavItem.action(
    this.icon,
    this.label, {
    required String this.actionLabel,
    this.key,
  }) : selectedIcon = null,
       ground = ChromeGround.surface;

  /// The item a runtime [NavTab] asks for.
  FrostedNavItem.fromTab(NavTab tab)
    : icon = tab.icon,
      label = tab.label,
      selectedIcon = tab.selectedIcon,
      key = tab.key,
      ground = tab.ground,
      actionLabel = null;

  /// The destination's glyph.
  final IconData icon;

  /// The destination's name.
  final String label;

  /// The glyph while it is the current destination; null keeps [icon].
  final IconData? selectedIcon;

  /// A key for its tab.
  final Key? key;

  /// The ground its page stands on (the canvas, or media under the bar).
  final ChromeGround ground;

  /// The words the sidebar's ink button prints when this tab is the app's
  /// main act: "Move money" where the pill is called "Move". Null prints
  /// [label].
  final String? actionLabel;
}

/// The phone tab bar, as the source draws it (`.tabbar`): a frosted slab
/// of glass 64 tall with its corners at 22, a rim of light along its top,
/// its hairline edge and a soft shadow under it, standing 12 in from the
/// screen's sides over a fade into the canvas (12 under it, or the system's
/// inset where that is more). The tabs share its width evenly, each its
/// glyph 4 over its word in the faint ink, the selected one in the ink with
/// its word semibold. The middle of five tabs, or the shell's [action], is
/// the ink pill: the app's main act printing its glyph and its word on the
/// ink, ringed while its page is shown. An [accessory] stands 8 over the
/// slab. On the media ground ([solid]) the band is the solid ground and
/// nothing blurs.
///
/// The shell mounts the one bar at the foot of every root; a page never
/// composes navigation.
///
/// ```dart
/// FrostedNavigationBar(items: tabs, selectedIndex: 0, onDestinationSelected: select)
/// ```
class FrostedNavigationBar extends StatelessWidget {
  /// Creates a [FrostedNavigationBar].
  const FrostedNavigationBar({
    required this.items,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.action,
    this.accessory,
    this.solid = false,
    this.style,
    super.key,
  });

  /// The destinations, three to five.
  final List<FrostedNavItem> items;

  /// The selected destination's index.
  final int selectedIndex;

  /// Called with the index of the pressed tab.
  final ValueChanged<int>? onDestinationSelected;

  /// The shell's act, drawn as the ink pill in the slab's middle.
  final ShellAction? action;

  /// What rides over the slab (a now-playing strip).
  final Widget? accessory;

  /// Paint the solid ground and blur nothing (the media ground).
  final bool solid;

  /// This bar's own style, over `FrostedThemeData.components.navigationBar`:
  /// the slab's fill, edge colour or a whole side, shape and padding.
  ///
  /// ```dart
  /// FrostedNavigationBar(
  ///   items: tabs,
  ///   style: const FrostedStyle(
  ///     fill: WidgetStatePropertyAll(Color(0xF2FFFFFF)),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  /// Where the ink pill stands among [count] tabs: the middle one of five
  /// (the source's Move) when the shell has no act of its own; none
  /// otherwise.
  static int? actTab(int count, {required bool action}) =>
      !action && count == 5 ? 2 : null;

  /// Where the shell's act stands as the pill among [count] tabs: in the
  /// slab's middle, before the tab at the returned index.
  static int actIndex(int count) => count ~/ 2;

  /// The bar's height over a bottom [inset]: the slab and the room under
  /// it.
  static double heightIn(double inset) =>
      FrostedChromeMetrics.slabHeight +
      math.max(FrostedChromeMetrics.tabBarBottom, inset);

  /// The fade the bar stands on: nothing at its top, most of the canvas at
  /// 48%, the canvas from 80%.
  static LinearGradient fade(FrostedThemeData t) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      t.glass.barFade.withValues(alpha: 0),
      t.glass.barFade.withValues(
        alpha: FrostedChromeMetrics.tabBarFadeMidAlpha,
      ),
      t.glass.barFade,
    ],
    stops: const [
      0,
      FrostedChromeMetrics.tabBarFadeMid,
      FrostedChromeMetrics.tabBarFadeLow,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final inset = MediaQuery.paddingOf(context).bottom;
    final act = action;
    final actTab = FrostedNavigationBar.actTab(
      items.length,
      action: act != null,
    );
    final go = onDestinationSelected;
    final cells = <Widget>[
      for (final (i, item) in items.indexed)
        if (i == actTab)
          _ActCell(
            child: FrostedNavAction(
              key: item.key,
              icon: item.icon,
              label: item.label,
              selected: i == selectedIndex,
              onPressed: go == null ? null : () => go(i),
            ),
          )
        else
          Expanded(
            child: _Tab(
              item: item,
              selected: i == selectedIndex,
              onTap: go == null ? null : () => go(i),
            ),
          ),
    ];
    if (act != null) {
      cells.insert(
        FrostedNavigationBar.actIndex(items.length),
        _ActCell(
          child: FrostedNavAction(
            key: act.key,
            icon: act.icon,
            label: act.label ?? '',
            lit: act.accent,
            onPressed: () => act.onPressed(context),
          ),
        ),
      );
    }
    final cellTabs = <int?>[for (var i = 0; i < items.length; i++) i];
    if (act != null) {
      cellTabs.insert(FrostedNavigationBar.actIndex(items.length), null);
    }
    final s = FrostedStyleLayers(style, t.components.navigationBar);
    final (edge, edges) = s.edgeOf(t.glass.edge, FrostedStrokes.regular);
    final slab = SizedBox(
      height: FrostedChromeMetrics.slabHeight,
      // The bar's glass: the page passes under it, blurred, with nothing
      // fading it out above.
      child: FrostedFace(
        material: solid ? FrostedMaterial.paint : FrostedMaterial.bar,
        radius: BorderRadius.circular(
          FrostedStyleLayers.radiusOf(
            s.shape,
            FrostedChromeMetrics.slabHeight,
            FrostedChromeMetrics.slabRadius,
          ),
        ),
        shape: s.shape,
        color: s.fill ?? (solid ? t.colorScheme.surface : null),
        edge: edge,
        edges: edges,
        sheen: t.glass.rim,
        shadows: t.shadows.bar,
        padding:
            s.padding?.resolve(Directionality.of(context)) ??
            const EdgeInsets.symmetric(
              horizontal: FrostedChromeMetrics.slabInset,
            ),
        child: _SlidingSelection(
          selected: selectedIndex,
          act: actTab,
          tabs: cellTabs,
          solid: solid,
          children: cells,
        ),
      ),
    );
    final bottom = math.max(FrostedChromeMetrics.tabBarBottom, inset);
    final box = Padding(
      padding: EdgeInsets.fromLTRB(
        FrostedChromeMetrics.tabBarSide,
        0,
        FrostedChromeMetrics.tabBarSide,
        bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostedChromeMetrics.accessoryGap,
        children: [?accessory, slab],
      ),
    );
    if (solid) return ColoredBox(color: t.colorScheme.background, child: box);
    return box;
  }
}

/// The tabs' row with the selection under them: a brighter pill of glass
/// that slides from the tab left to the tab chosen (at once under Reduce
/// Motion). The act's cell ([act]) never takes the pill: the ink pill is
/// its own.
class _SlidingSelection extends StatelessWidget {
  const _SlidingSelection({
    required this.selected,
    required this.act,
    required this.tabs,
    required this.solid,
    required this.children,
  });

  /// On the media ground: the pill is painted, blurring nothing, as the
  /// band under it is.
  final bool solid;

  final int selected;
  final int? act;

  /// Each cell's tab, null for the shell's act.
  final List<int?> tabs;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // The act's own tab is selected by its ink pill.
    final cell = selected == act ? -1 : tabs.indexOf(selected);
    return FrostedSlidingPill(
      count: children.length,
      selected: cell < 0 ? null : cell,
      inset: const EdgeInsets.all(FrostedChromeMetrics.selectionInset),
      // The chosen tab stands on the thickest, brightest glass in the bar,
      // raised off it; on the media ground it is painted, as the band is.
      pill: FrostedChosenPlate(
        radius: BorderRadius.circular(FrostedCorners.r10 + 4),
        painted: solid,
      ),
      builder: (context, keys) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, cell) in children.indexed)
            cell is Expanded
                ? Expanded(
                    flex: cell.flex,
                    child: KeyedSubtree(key: keys[i], child: cell.child),
                  )
                : KeyedSubtree(key: keys[i], child: cell),
        ],
      ),
    );
  }
}

/// The slab's middle column: as wide as the pill, 6 of room either side.
class _ActCell extends StatelessWidget {
  const _ActCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: FrostedChromeMetrics.movePillRoom,
    ),
    child: Center(child: child),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected, required this.onTap});

  final FrostedNavItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final ink = selected
        ? t.colorScheme.textPrimary
        : t.colorScheme.textTertiary;
    final tap = onTap;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      onTap: tap,
      // Tab reaches each destination; Enter or Space goes there. The ring
      // stands inside the cell, so the slab never clips it.
      child: FrostedKeyFocus(
        enabled: tap != null,
        radius: FrostedCorners.r10,
        ringInsets: EdgeInsets.all(
          FrostedChromeMetrics.focusRingGap + FrostedStrokes.heavy,
        ),
        keys: {
          if (tap != null) ...{
            LogicalKeyboardKey.enter: tap,
            LogicalKeyboardKey.numpadEnter: tap,
            LogicalKeyboardKey.space: tap,
          },
        },
        child: GestureDetector(
          key: item.key,
          behavior: HitTestBehavior.opaque,
          onTap: tap,
          child: FrostedEase<(Color, TextStyle)>(
            value: (
              ink,
              selected
                  ? t.textTheme.tab.semibold.c(ink)
                  : t.textTheme.tab.c(ink),
            ),
            lerp: FrostedEase.inkAndWords,
            builder: (context, shown) => _tabFace(t, shown.$1, shown.$2),
          ),
        ),
      ),
    );
  }

  Widget _tabFace(FrostedThemeData t, Color ink, TextStyle words) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.tabGap,
      children: [
        Icon(
          selected ? (item.selectedIcon ?? item.icon) : item.icon,
          size: FrostedChromeMetrics.tabGlyph,
          color: ink,
        ),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: words,
        ),
      ],
    ),
  );
}

/// The ink pill in the tab bar's middle (`.move-btn`): the app's main act,
/// 40 tall, its glyph 5 before its word on the ink with a light along its
/// top and its own lift; ringed in white and ink while [current]. Unlit
/// ([lit] false) it is a pill of the brighter glass with its glyph and
/// word in the ink. Read as a button named [label]. The tab bar stands its
/// middle tab or the shell's act as one.
///
/// ```dart
/// FrostedNavAction(icon: FrostedGlyphs.arrowRightLeft, label: 'Move', selected: true, onPressed: openMove)
/// ```
class FrostedNavAction extends StatelessWidget {
  /// Creates a [FrostedNavAction].
  const FrostedNavAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.lit = true,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The act's glyph.
  final IconData icon;

  /// The word on the pill, and what a screen reader says.
  final String label;

  /// What a press does.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// Whether the pill's page is the one shown.
  final bool selected;

  /// The ink pill, or the glass one of a quieter act.
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    const h = FrostedChromeMetrics.movePill;
    final ink = lit ? t.colorScheme.onButton : t.colorScheme.textPrimary;
    final rings = selected
        ? [
            frostedShadow(
              color: t.colorScheme.ringInner,
              spread: FrostedChromeMetrics.movePillRingInner,
            ),
            frostedShadow(
              color: t.colorScheme.ringOuter,
              spread: FrostedChromeMetrics.movePillRingOuter,
            ),
          ]
        : const <BoxShadow>[];
    final words = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.movePillGap,
      children: [
        Icon(icon, size: FrostedChromeMetrics.movePillGlyph, color: ink),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.textTheme.tab.semibold.c(ink),
        ),
      ],
    );
    final padding = const EdgeInsetsDirectional.only(
      start: FrostedChromeMetrics.movePillInsetStart,
      end: FrostedChromeMetrics.movePillInsetEnd,
    ).resolve(Directionality.of(context));
    final press = onPressed;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: press,
      // Tab reaches the act; Enter or Space presses it.
      child: FrostedKeyFocus(
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: press != null,
        radius: h / 2,
        keys: {
          if (press != null) ...{
            LogicalKeyboardKey.enter: press,
            LogicalKeyboardKey.numpadEnter: press,
            LogicalKeyboardKey.space: press,
          },
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: press,
          child: _pill(t, h, rings, padding, words),
        ),
      ),
    );
  }

  Widget _pill(
    FrostedThemeData t,
    double h,
    List<BoxShadow> rings,
    EdgeInsets padding,
    Widget words,
  ) => SizedBox(
    height: h,
    child: lit
        ? FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(h / 2),
            gradients: [t.colorScheme.buttonFill],
            sheen: t.colorScheme.buttonSheen,
            shadows: [
              ...rings,
              frostedShadow(
                y: 6,
                blur: 14,
                spread: -8,
                color: t.shadows.button.first.color.withValues(alpha: 0.6),
              ),
            ],
            padding: padding,
            child: words,
          )
        : FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(h / 2),
            color: t.glass.fillHigh,
            edge: t.glass.edge,
            sheen: t.glass.rim,
            shadows: rings,
            padding: padding,
            child: words,
          ),
  );
}
