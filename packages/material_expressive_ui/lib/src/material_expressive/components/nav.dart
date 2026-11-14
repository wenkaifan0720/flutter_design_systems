/// Navigation (CONTRACT §4.1 `tab-bar`, `side-nav`, `tabs`; §4.2
/// `ExpressiveNavItem`), ported from Compose material3 1.5.0-alpha29:
///
/// - [ExpressiveNavigationBar]: the flexible navigation bar (`ShortNavigationBar`
///   + `ShortNavigationBarItem`, measured by `NavigationItem.kt`'s
///   policies): 64dp, 3–5 labelled destinations, vertical destinations (icon over label)
///   on a phone, horizontal destinations (icon beside label) in a wider window,
///   equal-weight or centred.
/// - [ExpressiveNavigationRail]: the navigation rail (`WideNavigationRail`,
///   collapsed; `WideNavigationRailItem`), 96dp, with a header slot for the
///   floating action button.
/// - [ExpressiveTabBar]: in-page tabs, primary and secondary, fixed or
///   scrollable (`PrimaryTabRow`, `SecondaryTabRow` and their scrollable
///   forms; `Tab`), the indicator sliding on a spatial spring.
///
/// Every item is a pressable (`states.dart`): a navigation item's ripple is
/// the active indicator's, as Compose draws it (a touch anywhere on the
/// item reaches it), a tab's covers the tab. The selected item's icon
/// fills (`ExpressiveIcon`); the indicator grows from its centre on
/// `NavigationItemBehavior.indicatorMotion`. The shell (`shell.dart`)
/// draws the bar on a phone and the rail from 600dp.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show MaterialLocalizations;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart' show NavTab;

import '../icons.dart';
import '../component_themes.dart';
import '../elevation.dart';
import '../internal/badge_anchor.dart';
import '../internal/cap_label.dart';
import '../internal/styled_content.dart';
import '../internal/whole_words.dart';
import 'select.dart' show ExpressiveSelect;
import '../spacing.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/divider_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/navigation_bar_horizontal_item_tokens.g.dart';
import '../internal/tokens/navigation_bar_tokens.g.dart';
import '../internal/tokens/navigation_bar_vertical_item_tokens.g.dart';
import '../internal/tokens/navigation_rail_baseline_item_tokens.g.dart';
import '../internal/tokens/navigation_rail_collapsed_tokens.g.dart';
import '../internal/tokens/navigation_rail_color_tokens.g.dart';
import '../internal/tokens/navigation_rail_expanded_tokens.g.dart';
import '../internal/tokens/navigation_rail_horizontal_item_tokens.g.dart';
import '../internal/tokens/scrim_tokens.g.dart';
import '../internal/tokens/navigation_rail_vertical_item_tokens.g.dart';
import '../internal/tokens/primary_navigation_tab_tokens.g.dart';
import '../internal/tokens/secondary_navigation_tab_tokens.g.dart';
import '../internal/tokens/token_types.g.dart';
import '../motion.dart';
import '../shape.dart';
import '../states.dart';
import '../theme.dart';
import 'badge.dart';
import 'overlays.dart' show ExpressivePopupRoute;

// ---------------------------------------------------------------------------
// Items
// ---------------------------------------------------------------------------

/// One navigation destination (CONTRACT §4.2 `ExpressiveNavItem(icon,
/// label, key)`): its glyph, its label — required, Material always labels
/// its navigation — and the walkthrough key set on its hit target.
@immutable
class ExpressiveNavItem {
  /// A destination showing [icon] and labelled [label].
  const ExpressiveNavItem(
    this.icon,
    this.label, {
    this.key,
    this.selectedIcon,
    this.badge,
    this.enabled = true,
    this.style,
  });

  /// The design kit's tab as a navigation item: its glyph, label, selected
  /// glyph and key.
  ExpressiveNavItem.fromTab(
    NavTab tab, {
    this.badge,
    this.enabled = true,
    this.style,
  }) : icon = tab.icon,
       label = tab.label,
       key = tab.key,
       selectedIcon = tab.selectedIcon;

  /// Stateful visual overrides for this destination.
  final ExpressiveComponentThemeData? style;

  /// The glyph: one of `ExpressiveSymbols`, which fills when selected.
  final IconData icon;

  /// The label under (or beside) the glyph.
  final String label;

  /// The key on the item's hit target (a walkthrough step's).
  final Key? key;

  /// The glyph while selected; null fills [icon] instead.
  final IconData? selectedIcon;

  /// A badge on the glyph's top end corner: an [ExpressiveBadge].
  final Widget? badge;

  /// Whether the item can be selected.
  final bool enabled;
}

/// Where a navigation item's glyph stands against its label (Compose
/// `NavigationItemIconPosition`).
enum ExpressiveNavItemPosition {
  /// Icon over label: a vertical item (a phone's bar, the rail).
  top,

  /// Icon beside label, both inside the indicator: a horizontal item (a
  /// wider window's bar).
  start,
}

/// How a bar spreads its destinations (Compose `ShortNavigationBarArrangement`).
enum ExpressiveNavigationBarArrangement {
  /// Every item the same width, the bar's width shared out.
  equalWeight,

  /// The destinations gathered in the middle of the bar, each as wide as it needs
  /// up to its share.
  centered,
}

// ---------------------------------------------------------------------------
// The flexible navigation bar
// ---------------------------------------------------------------------------

/// The flexible navigation bar (Compose `ShortNavigationBar`): a 64dp
/// `surfaceContainer` band of [destinations] — 3 to 5 — over the system's bottom
/// and side insets, the [selectedIndex] item wearing the active indicator
/// (a `secondaryContainer` pill, the icon filled, the label in
/// `secondary`). Selecting an item calls [onSelected].
///
/// [itemPosition] top is the phone's vertical item; start the horizontal
/// item of a wider window, usually with [arrangement] centered.
class ExpressiveNavigationBar extends StatelessWidget {
  /// A navigation bar of [destinations] with [selectedIndex] active.
  const ExpressiveNavigationBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.itemPosition = ExpressiveNavItemPosition.top,
    this.arrangement = ExpressiveNavigationBarArrangement.equalWeight,
    this.style,
    super.key,
  });

  /// Stateful visual overrides for this navigation frame.
  final ExpressiveComponentThemeData? style;

  /// The destinations, in order.
  final List<ExpressiveNavItem> destinations;

  /// The selected destination's index.
  final int selectedIndex;

  /// Called with an item's index when it is tapped.
  final ValueChanged<int> onDestinationSelected;

  /// Vertical (top) or horizontal (start) destinations.
  final ExpressiveNavItemPosition itemPosition;

  /// How the destinations share the bar's width.
  final ExpressiveNavigationBarArrangement arrangement;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final visual = t.navigationBarTheme.merge(style);
    final insets = MediaQuery.paddingOf(context);
    final top = itemPosition == ExpressiveNavItemPosition.top;
    var minimumWidth = 0.0;
    for (final (index, item) in destinations.indexed) {
      final states = <WidgetState>{
        if (index == selectedIndex) WidgetState.selected,
        if (!item.enabled) WidgetState.disabled,
      };
      final own = _navigationContentStyle(visual)
          .merge(t.navigationItemTheme)
          .merge(item.style);
      final border = own.shape?.resolve(states);
      final inset =
          border
              ?.copyWith(
                side:
                    own.side?.resolve(states) ??
                    BorderSide.none.copyWith(
                      color: own.outline?.resolve(states),
                      style: own.outline?.resolve(states) == null
                          ? null
                          : BorderStyle.solid,
                    ),
              )
              .dimensions
              .resolve(Directionality.of(context)) ??
          EdgeInsets.zero;
      final g = (top ? _NavItemGeometry.barTop : _NavItemGeometry.barStart)
          .styled(t, own, states, inset);
      final labelRoom = top
          ? 0
          : MediaQuery.textScalerOf(context).scale(
              (own.textStyle?.resolve(states)?.fontSize ??
                      t.type.of(g.labelFont).fontSize ??
                      0) *
                  2,
            );
      minimumWidth += math.max(
        ExpressiveSpacing.s48,
        math.max(
          own.minimumSize?.resolve(states)?.width ?? 0,
          g.iconSize +
              g.indicatorHorizontalPadding * 2 +
              (top ? 0 : g.iconToLabel + labelRoom),
        ),
      );
    }
    return ExpressiveSurface(
      componentStyle: visual,
      shape: t.shapes.none,
      color: t.colors.role(NavigationBarTokens.containerColor),
      child: Padding(
        // ShortNavigationBarDefaults.windowInsets: the system bars'
        // horizontal and bottom sides.
        padding: EdgeInsets.only(
          left: insets.left,
          right: insets.right,
          bottom: insets.bottom,
        ),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          child: _NavigationViewport(
            minimumWidth: minimumWidth,
            // Flutter's NavigationBar: a tab bar of tabs.
            child: Semantics(
              role: SemanticsRole.tabBar,
              container: true,
              explicitChildNodes: true,
              // The destinations share the width equally: a word too wide
              // for its item shrinks every item's label alike.
              child: ExpressiveWholeWordsGroup(
                child: _NavBarLayout(
                  arrangement: arrangement,
                  minimumHeight: t.density.height(
                    ShortNavigationBarBehavior.minHeight,
                    floor: ExpressiveSpacing.s48,
                  ),
                  devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                  children: <Widget>[
                    for (final (index, item) in destinations.indexed)
                      _NavItem(
                        item: item,
                        componentStyle: _navigationContentStyle(visual)
                            .merge(t.navigationItemTheme),
                        selected: index == selectedIndex,
                        onTap: () => onDestinationSelected(index),
                        geometry: top
                            ? _NavItemGeometry.barTop
                            : _NavItemGeometry.barStart,
                        colors: _NavItemColors.bar(t, top: top),
                        animateLabelColor: false,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `EqualWeightContentMeasurePolicy` and `CenteredContentMeasurePolicy`:
/// the destinations share the width in whole device pixels, as Compose divides
/// integer pixels, and stand as tall as the tallest (at least 64dp).
class _NavBarLayout extends MultiChildRenderObjectWidget {
  const _NavBarLayout({
    required this.arrangement,
    required this.minimumHeight,
    required this.devicePixelRatio,
    required super.children,
  });

  final ExpressiveNavigationBarArrangement arrangement;
  final double minimumHeight;
  final double devicePixelRatio;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderNavBar(
    arrangement: arrangement,
    minimumHeight: minimumHeight,
    devicePixelRatio: devicePixelRatio,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderNavBar renderObject) {
    renderObject
      ..arrangement = arrangement
      ..minimumHeight = minimumHeight
      ..devicePixelRatio = devicePixelRatio
      ..textDirection = Directionality.of(context);
  }
}

class _NavBarParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderNavBar extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _NavBarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _NavBarParentData> {
  _RenderNavBar({
    required this._arrangement,
    required this._minimumHeight,
    required this._devicePixelRatio,
    required this._textDirection,
  });

  ExpressiveNavigationBarArrangement _arrangement;
  set arrangement(ExpressiveNavigationBarArrangement value) {
    if (value == _arrangement) return;
    _arrangement = value;
    markNeedsLayout();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _NavBarParentData) {
      child.parentData = _NavBarParentData();
    }
  }

  /// [dp] floored to whole device pixels (Compose's integer division).
  double _floorPx(double dp) =>
      (dp * _devicePixelRatio).floorToDouble() / _devicePixelRatio;

  double _minimumHeight;
  double get _minHeight => _minimumHeight;
  set minimumHeight(double value) {
    if (value == _minimumHeight) return;
    _minimumHeight = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) {
    final count = childCount;
    if (count == 0 || !width.isFinite) return _minHeight;
    final itemWidth = _floorPx(width / count);
    var height = _minHeight;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      height = math.max(height, child.getMaxIntrinsicHeight(itemWidth));
    }
    return height;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    Size(constraints.maxWidth, computeMaxIntrinsicHeight(constraints.maxWidth)),
  );

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final count = childCount;
    var itemHeight = math.max(constraints.minHeight, _minHeight);
    if (count == 0) {
      size = constraints.constrain(Size(width, itemHeight));
      return;
    }
    final widths = <double>[];
    var padding = 0.0;
    switch (_arrangement) {
      case ExpressiveNavigationBarArrangement.equalWeight:
        final itemWidth = _floorPx(width / count);
        for (var c = firstChild; c != null; c = childAfter(c)) {
          itemHeight = math.max(itemHeight, c.getMaxIntrinsicHeight(itemWidth));
          widths.add(itemWidth);
        }
      case ExpressiveNavigationBarArrangement.centered:
        final itemMaxWidth = _floorPx(width / count);
        padding = _centeredPadding(count, width);
        final itemMinWidth = _floorPx((width - padding * 2) / count);
        for (var c = firstChild; c != null; c = childAfter(c)) {
          itemHeight = math.max(
            itemHeight,
            c.getMaxIntrinsicHeight(itemMinWidth),
          );
        }
        for (var c = firstChild; c != null; c = childAfter(c)) {
          var itemWidth = itemMinWidth;
          final wanted = c.getMaxIntrinsicWidth(_minHeight);
          if (itemWidth < wanted) {
            itemWidth = math.min(wanted, itemMaxWidth);
            padding -= _floorPx((itemWidth - itemMinWidth) / 2);
          }
          widths.add(itemWidth);
        }
    }
    itemHeight = math.min(itemHeight, constraints.maxHeight);
    var x = padding;
    var index = 0;
    for (var c = firstChild; c != null; c = childAfter(c), index++) {
      final w = widths[index];
      c.layout(BoxConstraints.tight(Size(w, itemHeight)));
      final left = switch (_textDirection) {
        TextDirection.ltr => x,
        TextDirection.rtl => width - x - w,
      };
      (c.parentData! as BoxParentData).offset = Offset(left, 0);
      x += w;
    }
    size = constraints.constrain(Size(width, itemHeight));
  }

  /// `calculateCenteredContentHorizontalPadding`: the share of the bar
  /// either side of centred destinations, by their count.
  double _centeredPadding(int count, double width) {
    const maxCount = _centeredMaxItems;
    if (count > maxCount) return 0;
    final share =
        (_percent - _percentStep * (count + _countBias)) / 2 / _percent;
    return (share * width * _devicePixelRatio).roundToDouble() /
        _devicePixelRatio;
  }

  // ShortNavigationBar.kt: ((100 - 10 * (itemsCount + 3)) / 2f) / 100, and
  // none above 6 destinations. Arithmetic of a share, not lengths.
  static const int _centeredMaxItems = 6;
  static const int _percent = 100;
  static const int _percentStep = 10;
  static const int _countBias = 3;

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

// ---------------------------------------------------------------------------
// The navigation rail
// ---------------------------------------------------------------------------

/// The navigation rail (Compose `WideNavigationRail`), collapsed: a 96dp
/// `surface` column along the leading edge, [header] (the floating action
/// button, a menu button) 44dp below the top inset, then [destinations] 4dp apart
/// under it, each a 64dp vertical item.
///
/// [expanded], it is the wide rail: as wide as its longest label needs,
/// from 220 to 360dp, each item its icon and label in a row (the item's
/// icon at the start), the indicator round both, 20dp in from the rail's
/// edges, the destinations flush one under another. A collapsed rail holds three
/// to seven destinations; an expanded one holds more, and stands at
/// large widths (1200dp and up, where the shell expands it). [showExpressiveNavigationDrawer] raises
/// the same rail modally, the drawer of a phone.
///
/// The shell draws the collapsed rail instead of the bar from 600dp, and
/// the expanded one from 1200dp.
class ExpressiveNavigationRail extends StatelessWidget {
  /// A navigation rail of [destinations] with [selectedIndex] active.
  const ExpressiveNavigationRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.header,
    this.expanded = false,
    this.style,
    super.key,
  }) : _modal = false,
       _drawer = false;

  const ExpressiveNavigationRail._modal({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.header,
    this.style,
  }) : expanded = true,
       _modal = true,
       _drawer = true;

  const ExpressiveNavigationRail._standingDrawer({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.header,
    this.style,
  }) : expanded = true,
       _modal = false,
       _drawer = true;

  /// Whether the rail stands expanded: labels beside the icons, 220 to
  /// 360dp wide (Compose's `WideNavigationRailValue.Expanded`).
  final bool expanded;

  /// The modal rail [showExpressiveNavigationDrawer] raises: the modal
  /// container colour, its end corners large.
  final bool _modal;

  /// The drawer, standing or raised: each destination's indicator spans
  /// the drawer, 12dp in from its edges, and its count stands at the row's
  /// end (Material's navigation drawer); the rail's hug their content.
  final bool _drawer;

  /// Stateful visual overrides for this navigation frame.
  final ExpressiveComponentThemeData? style;

  /// The destinations, top to bottom.
  final List<ExpressiveNavItem> destinations;

  /// The selected destination's index.
  final int selectedIndex;

  /// Called with an item's index when it is tapped.
  final ValueChanged<int> onDestinationSelected;

  /// What stands above the destinations, 40dp over the first (Compose's
  /// `HeaderSpaceMinimum`): the shell's floating action button.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final visual = t.navigationRailTheme.merge(style);
    final insets = MediaQuery.paddingOf(context);
    final start = Directionality.of(context) == TextDirection.ltr
        ? insets.left
        : insets.right;
    final header = this.header;
    return ExpressiveSurface(
      componentStyle: visual,
      shape: _modal
          ? t.shapes.of(NavigationRailExpandedTokens.modalContainerShape).end()
          : t.shapes.none,
      color: t.colors.role(
        _modal
            ? NavigationRailExpandedTokens.modalContainerColor
            : NavigationRailCollapsedTokens.containerColor,
      ),
      child: Padding(
        // WideNavigationRailDefaults.windowInsets (vertical and start
        // system bars), then ContentPadding (TopSpace above).
        padding: EdgeInsetsDirectional.only(
          start: start,
          top: insets.top + NavigationRailCollapsedTokens.topSpace,
          bottom: insets.bottom,
        ),
        child: SizedBox(
          width: expanded
              ? _expandedWidth(context, t)
              : t.density.width(NavigationRailCollapsedTokens.containerWidth),
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // A rail's items share its width: a word too wide for an item
                // shrinks every item's label alike.
                final list = ExpressiveWholeWordsGroup(
                  child: Column(
                    crossAxisAlignment: _drawer
                        ? CrossAxisAlignment.stretch
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final (index, item)
                          in destinations.indexed) ...<Widget>[
                        if (index > 0 && !expanded)
                          const SizedBox(
                            height:
                                NavigationRailCollapsedTokens.itemVerticalSpace,
                          ),
                        if (expanded)
                          Padding(
                            // A drawer's indicators stand 12dp in at every
                            // density (Material's drawer): density moves
                            // heights, not where a container's content starts.
                            padding: EdgeInsets.symmetric(
                              horizontal: _drawer
                                  ? ExpressiveSpacing.s12
                                  : t.density.width(
                                      WideNavigationRailBehavior
                                          .itemHorizontalPadding,
                                      floor: 0,
                                    ),
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: ExpressiveSpacing.s48,
                              ),
                              child: _NavItem(
                                item: item,
                                componentStyle: _navigationContentStyle(visual)
                                    .merge(t.navigationItemTheme),
                                selected: index == selectedIndex,
                                onTap: () => onDestinationSelected(index),
                                geometry: _NavItemGeometry.railStart,
                                colors: _NavItemColors.rail(t, start: true),
                                animateLabelColor: true,
                                spans: _drawer,
                              ),
                            ),
                          )
                        else
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: t.density.height(
                                NavigationRailBaselineItemTokens
                                    .containerHeight,
                                floor: ExpressiveSpacing.s48,
                              ),
                            ),
                            child: _NavItem(
                              item: item,
                              componentStyle: _navigationContentStyle(visual)
                                  .merge(t.navigationItemTheme),
                              selected: index == selectedIndex,
                              onTap: () => onDestinationSelected(index),
                              geometry: _NavItemGeometry.railTop,
                              colors: _NavItemColors.rail(t),
                              animateLabelColor: true,
                            ),
                          ),
                      ],
                    ],
                  ),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (header != null) ...<Widget>[
                      header,
                      const SizedBox(
                        height:
                            NavigationRailBaselineItemTokens.headerSpaceMinimum,
                      ),
                    ],
                    // Compose's rail places its destinations without ever throwing;
                    // a rail shorter than its destinations (a landscape phone)
                    // scrolls them under the header instead of overflowing.
                    if (constraints.hasBoundedHeight)
                      Flexible(
                        child: SingleChildScrollView(
                          primary: false,
                          child: list,
                        ),
                      )
                    else
                      list,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Named: an app's copy of this file renames each public top-level name, and
// would read an unnamed extension's `on` as its name.
extension _ExpandedRailWidth on ExpressiveNavigationRail {
  /// The expanded rail's width: its widest item (Compose measures each
  /// item at the start position and adds the item padding either side),
  /// within 220 and 360dp.
  double _expandedWidth(BuildContext context, ExpressiveThemeData t) {
    final style = t.type.of(NavigationRailHorizontalItemTokens.labelTextFont);
    final scaler = MediaQuery.textScalerOf(context);
    var label = 0.0;
    for (final item in destinations) {
      final painter = TextPainter(
        text: TextSpan(text: item.label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      label = math.max(label, painter.width);
      painter.dispose();
    }
    final g = _NavItemGeometry.railStart;
    final item =
        g.iconSize +
        g.iconToLabel +
        label +
        2 * t.density.width(g.indicatorHorizontalPadding, floor: 0) +
        2 *
            (_drawer
                ? ExpressiveSpacing.s12
                : t.density.width(g.itemHorizontalPadding, floor: 0));
    return item.ceilToDouble().clamp(
      NavigationRailExpandedTokens.containerWidthMinimum,
      NavigationRailExpandedTokens.containerWidthMaximum,
    );
  }
}

/// Raises the expanded rail modally over a scrim, from the leading edge
/// (Compose's `ModalWideNavigationRail`, expanded and hidden when
/// collapsed): the navigation drawer of a phone, where a bar has no room
/// for every destination. It slides in on the fast spatial spring, the
/// modal container colour, its end corners large, its indicators spanning
/// it as [ExpressiveNavigationDrawer]'s do; a tap on the scrim or the system
/// back closes it. Resolves to the index chosen, or null.
///
/// ```dart
/// final index = await showExpressiveNavigationDrawer(context, destinations: destinations, selectedIndex: page);
/// ```
Future<int?> showExpressiveNavigationDrawer(
  BuildContext context, {
  required List<ExpressiveNavItem> destinations,
  required int selectedIndex,
  Widget? header,
  ExpressiveComponentThemeData? style,
  bool useRootNavigator = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final colors = context.expressiveTheme.colors;
  return navigator.push<int>(
    ExpressivePopupRoute<int>(
      spring: ExpressiveMotion.of(context)
          .spring(ExpressiveMotionKey.fastSpatial),
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      barrierColor: colors
          .role(ScrimTokens.containerColor)
          .withValues(alpha: ScrimTokens.containerOpacity),
      barrierLabel: Localizations.of<MaterialLocalizations>(
        context,
        MaterialLocalizations,
      )?.modalBarrierDismissLabel,
      // In from the leading edge; a spring's overshoot never lifts it off
      // the edge.
      transitionBuilder: (context, animation, child) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => FractionalTranslation(
          translation: Offset(
            (Directionality.of(context) == TextDirection.ltr ? -1 : 1) *
                (1 - animation.value.clamp(0.0, 1.0)),
            0,
          ),
          child: child,
        ),
      ),
      builder: (context) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: Localizations.of<MaterialLocalizations>(
            context,
            MaterialLocalizations,
          )?.drawerLabel,
          child: ExpressiveNavigationRail._modal(
            destinations: destinations,
            selectedIndex: selectedIndex,
            header: header,
            style: style,
            onDestinationSelected: (index) => Navigator.of(context).pop(index),
          ),
        ),
      ),
    ),
  );
}

/// The navigation drawer, standing: the expanded navigation rail (Material 3
/// Expressive retires the drawer for it), as wide as its longest label
/// needs, from 220 to 360dp, each destination its icon and label in a row
/// under a round indicator that spans the drawer 12dp in from its edges, a
/// count at the row's end (Material's drawer), beside the page at expanded
/// widths (840dp and up). On a phone the same drawer rises modally over a
/// scrim with [ExpressiveNavigationDrawer.show]. The expanded
/// [ExpressiveNavigationRail], whose indicators hug their content.
///
/// ```dart
/// ExpressiveNavigationDrawer(destinations: destinations, selectedIndex: page, onDestinationSelected: go)
/// ```
class ExpressiveNavigationDrawer extends StatelessWidget {
  /// A drawer of [destinations] with [selectedIndex] active.
  const ExpressiveNavigationDrawer({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.header,
    this.style,
    super.key,
  });

  /// Raises the drawer modally from the leading edge
  /// ([showExpressiveNavigationDrawer]); resolves to the index chosen, or
  /// null when it is dismissed.
  static Future<int?> show(
    BuildContext context, {
    required List<ExpressiveNavItem> destinations,
    required int selectedIndex,
    Widget? header,
    ExpressiveComponentThemeData? style,
    bool useRootNavigator = true,
  }) => showExpressiveNavigationDrawer(
    context,
    destinations: destinations,
    selectedIndex: selectedIndex,
    header: header,
    style: style,
    useRootNavigator: useRootNavigator,
  );

  /// The destinations, top to bottom.
  final List<ExpressiveNavItem> destinations;

  /// The selected destination's index.
  final int selectedIndex;

  /// Called with an item's index when it is tapped.
  final ValueChanged<int> onDestinationSelected;

  /// What stands above the destinations: a floating action button, a title.
  final Widget? header;

  /// Stateful visual overrides for this navigation frame.
  final ExpressiveComponentThemeData? style;

  @override
  Widget build(BuildContext context) =>
      ExpressiveNavigationRail._standingDrawer(
        destinations: destinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        header: header,
        style: style,
      );
}

// ---------------------------------------------------------------------------
// One navigation item
// ---------------------------------------------------------------------------

/// The numbers one item form is measured with (`ShortNavigationBarItem`'s
/// and `WideNavigationRailItem`'s arguments to `NavigationItem`).
@immutable
class _NavItemGeometry {
  const _NavItemGeometry({
    required this.position,
    required this.indicatorHorizontalPadding,
    required this.indicatorVerticalPadding,
    required this.indicatorToLabel,
    required this.iconToLabel,
    required this.itemVerticalPadding,
    required this.itemHorizontalPadding,
    required this.labelFont,
    required this.iconSize,
    this.reserveLabelPadding = false,
  });

  /// `ShortNavigationBarItem`, icon on top.
  static const _NavItemGeometry barTop = _NavItemGeometry(
    position: ExpressiveNavItemPosition.top,
    // TopIconIndicatorHorizontalPadding: (56 - 24) / 2.
    indicatorHorizontalPadding:
        (NavigationBarVerticalItemTokens.activeIndicatorWidth -
            NavigationBarVerticalItemTokens.iconSize) /
        2,
    // TopIconIndicatorVerticalPadding: (32 - 24) / 2.
    indicatorVerticalPadding:
        (NavigationBarVerticalItemTokens.activeIndicatorHeight -
            NavigationBarVerticalItemTokens.iconSize) /
        2,
    indicatorToLabel: ShortNavigationBarBehavior.topIconIndicatorToLabelPadding,
    iconToLabel: NavigationBarTokens.itemActiveIndicatorIconLabelSpace,
    // TopIconItemVerticalPadding.
    itemVerticalPadding: NavigationBarVerticalItemTokens.containerBetweenSpace,
    itemHorizontalPadding: 0,
    labelFont: NavigationBarTokens.labelTextFont,
    iconSize: NavigationBarVerticalItemTokens.iconSize,
  );

  /// `ShortNavigationBarItem`, icon at the start.
  static const _NavItemGeometry barStart = _NavItemGeometry(
    position: ExpressiveNavItemPosition.start,
    // StartIconIndicatorHorizontalPadding.
    indicatorHorizontalPadding:
        NavigationBarHorizontalItemTokens.activeIndicatorLeadingSpace,
    // StartIconIndicatorVerticalPadding: (40 - 24) / 2.
    indicatorVerticalPadding:
        (NavigationBarHorizontalItemTokens.activeIndicatorHeight -
            NavigationBarHorizontalItemTokens.iconSize) /
        2,
    indicatorToLabel: ShortNavigationBarBehavior.topIconIndicatorToLabelPadding,
    // StartIconToLabelPadding.
    iconToLabel: NavigationBarTokens.itemActiveIndicatorIconLabelSpace,
    itemVerticalPadding: 0,
    itemHorizontalPadding: 0,
    labelFont: NavigationBarTokens.labelTextFont,
    iconSize: NavigationBarHorizontalItemTokens.iconSize,
  );

  /// `WideNavigationRailItem` in a collapsed rail: the animated layout at
  /// icon-top, whose indicator padding is `IndicatorCollapsedPadding`.
  static const _NavItemGeometry railTop = _NavItemGeometry(
    position: ExpressiveNavItemPosition.top,
    indicatorHorizontalPadding:
        (NavigationRailVerticalItemTokens.activeIndicatorWidth -
            NavigationRailBaselineItemTokens.iconSize) /
        2,
    indicatorVerticalPadding:
        (NavigationRailVerticalItemTokens.activeIndicatorHeight -
            NavigationRailBaselineItemTokens.iconSize) /
        2,
    indicatorToLabel: NavigationRailVerticalItemTokens.iconLabelSpace,
    iconToLabel: NavigationRailBaselineItemTokens.activeIndicatorIconLabelSpace,
    itemVerticalPadding: 0,
    itemHorizontalPadding: WideNavigationRailBehavior.itemHorizontalPadding,
    labelFont: NavigationRailVerticalItemTokens.labelTextFont,
    iconSize: NavigationRailBaselineItemTokens.iconSize,
  );

  /// `WideNavigationRailItem` in an expanded rail: icon at the start,
  /// `IndicatorExpandedPadding` (16dp either side, (56 − 24) / 2 above and
  /// below: a 56dp indicator), 8dp from the icon to the label in
  /// `labelLarge`.
  static const _NavItemGeometry railStart = _NavItemGeometry(
    position: ExpressiveNavItemPosition.start,
    indicatorHorizontalPadding:
        NavigationRailHorizontalItemTokens.fullWidthLeadingSpace,
    indicatorVerticalPadding:
        (NavigationRailHorizontalItemTokens.activeIndicatorHeight -
            NavigationRailBaselineItemTokens.iconSize) /
        2,
    indicatorToLabel: NavigationRailVerticalItemTokens.iconLabelSpace,
    iconToLabel: NavigationRailHorizontalItemTokens.iconLabelSpace,
    itemVerticalPadding: 0,
    itemHorizontalPadding: WideNavigationRailBehavior.itemHorizontalPadding,
    labelFont: NavigationRailHorizontalItemTokens.labelTextFont,
    iconSize: NavigationRailBaselineItemTokens.iconSize,
  );

  final ExpressiveNavItemPosition position;
  final double indicatorHorizontalPadding;
  final double indicatorVerticalPadding;
  final double indicatorToLabel;
  final double iconToLabel;
  final double itemVerticalPadding;
  final double itemHorizontalPadding;
  final ExpressiveTypeKey labelFont;
  final double iconSize;
  final bool reserveLabelPadding;

  _NavItemGeometry styled(
    ExpressiveThemeData theme,
    ExpressiveComponentThemeData style,
    Set<WidgetState> states,
    EdgeInsets inset,
  ) {
    final override = style.padding?.resolve(states)?.resolve(TextDirection.ltr);
    final padding =
        override ??
        theme.density.padding(
          EdgeInsets.symmetric(
            horizontal: indicatorHorizontalPadding,
            vertical: indicatorVerticalPadding,
          ),
        );
    return _NavItemGeometry(
      position: position,
      indicatorHorizontalPadding: math.max(
        padding.left + inset.left,
        padding.right + inset.right,
      ),
      indicatorVerticalPadding: math.max(
        padding.top + inset.top,
        padding.bottom + inset.bottom,
      ),
      // Density moves the item's edges, never the space between its icon
      // and its label (as Flutter's density leaves a button's icon gap):
      // two steps took the 8dp and 4dp to nothing on desktop.
      indicatorToLabel: indicatorToLabel,
      iconToLabel: iconToLabel,
      itemVerticalPadding: theme.density.height(itemVerticalPadding, floor: 0),
      itemHorizontalPadding: theme.density.width(
        itemHorizontalPadding,
        floor: 0,
      ),
      labelFont: labelFont,
      iconSize: style.iconSize?.resolve(states) ?? iconSize,
      reserveLabelPadding:
          override != null || style.shape?.resolve(states) != null,
    );
  }
}

/// `NavigationItemColors` for one item form.
@immutable
class _NavItemColors {
  const _NavItemColors({
    required this.selectedIcon,
    required this.selectedText,
    required this.indicator,
    required this.unselectedIcon,
    required this.unselectedText,
    required this.ripple,
  });

  /// `ShortNavigationBarItemDefaults.colors()`.
  factory _NavItemColors.bar(ExpressiveThemeData t, {required bool top}) =>
      _NavItemColors(
        selectedIcon: t.colors.role(NavigationBarTokens.itemActiveIconColor),
        // A start-icon item's label takes the icon's colour (Compose's TODO
        // until a token exists).
        selectedText: t.colors.role(
          top
              ? NavigationBarTokens.itemActiveLabelTextColor
              : NavigationBarTokens.itemActiveIconColor,
        ),
        indicator: t.colors.role(NavigationBarTokens.itemActiveIndicatorColor),
        unselectedIcon: t.colors.role(
          NavigationBarTokens.itemInactiveIconColor,
        ),
        unselectedText: t.colors.role(
          NavigationBarTokens.itemInactiveLabelTextColor,
        ),
        // The ripple is the bar's content colour (contentColorFor its
        // container: onSurface).
        ripple: t.colors.onSurface,
      );

  /// `WideNavigationRailItemDefaults.colors()`. A start-icon item's label
  /// stands inside the indicator and takes the icon's colour, as the bar's
  /// start-icon item's does: `secondary` on `secondaryContainer` falls
  /// short of 4.5:1 in some schemes (slate dark 4.18:1).
  factory _NavItemColors.rail(ExpressiveThemeData t, {bool start = false}) =>
      _NavItemColors(
        selectedIcon: t.colors.role(NavigationRailColorTokens.itemActiveIcon),
        selectedText: t.colors.role(
          start
              ? NavigationRailColorTokens.itemActiveIcon
              : NavigationRailColorTokens.itemActiveLabelText,
        ),
        indicator: t.colors.role(NavigationRailColorTokens.itemActiveIndicator),
        unselectedIcon: t.colors.role(
          NavigationRailColorTokens.itemInactiveIcon,
        ),
        unselectedText: t.colors.role(
          NavigationRailColorTokens.itemInactiveLabelText,
        ),
        ripple: t.colors.onSurface,
      );

  final Color selectedIcon;
  final Color selectedText;
  final Color indicator;
  final Color unselectedIcon;
  final Color unselectedText;
  final Color ripple;

  Color icon({required bool selected, required bool enabled}) => !enabled
      ? unselectedIcon.withValues(alpha: NavigationItemBehavior.disabledAlpha)
      : selected
      ? selectedIcon
      : unselectedIcon;

  Color text({required bool selected, required bool enabled}) => !enabled
      ? unselectedText.withValues(alpha: NavigationItemBehavior.disabledAlpha)
      : selected
      ? selectedText
      : unselectedText;
}

/// One navigation item (Compose `NavigationItem`): the whole item is the
/// target; the ripple, focus and hover layers are the indicator's.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.componentStyle,
    required this.selected,
    required this.onTap,
    required this.geometry,
    required this.colors,
    required this.animateLabelColor,
    this.spans = false,
  });

  final ExpressiveNavItem item;
  final ExpressiveComponentThemeData componentStyle;
  final bool selected;
  final VoidCallback onTap;
  final _NavItemGeometry geometry;
  final _NavItemColors colors;
  final bool animateLabelColor;

  /// A drawer's item: its indicator spans the item's width, the icon and
  /// label at its start, a badge at its end instead of on the icon.
  final bool spans;

  @override
  Widget build(BuildContext context) => _NavigationStates(builder: _build);

  Widget _build(BuildContext context, WidgetStatesController controller) {
    final t = context.expressiveTheme;
    final enabled = item.enabled;
    final states = <WidgetState>{
      ...controller.value,
      if (selected) WidgetState.selected,
      if (!enabled) WidgetState.disabled,
    };
    final visual = componentStyle.merge(item.style);
    final indicatorShape =
        visual.shape?.resolve(states) ??
        t.shapes.of(NavigationBarTokens.itemActiveIndicatorShape);
    final outline = visual.outline?.resolve(states);
    final side =
        visual.side?.resolve(states) ??
        (outline == null
            ? BorderSide.none
            : BorderSide(color: outline, width: 1));
    final g = geometry.styled(
      t,
      visual,
      states,
      indicatorShape
          .copyWith(side: side)
          .dimensions
          .resolve(Directionality.of(context)),
    );
    final foreground = visual.foregroundColor?.resolve(states);
    final fill = visual.backgroundColor?.resolve(states);
    final minimum = visual.minimumSize?.resolve(states);
    final selectedIcon = item.selectedIcon;
    final iconColor =
        foreground ?? colors.icon(selected: selected, enabled: enabled);
    final Widget glyph = selected && selectedIcon != null
        ? Icon(selectedIcon, size: g.iconSize, color: iconColor)
        : ExpressiveIcon(
            item.icon,
            selected: selected,
            size: g.iconSize,
            color: iconColor,
          );
    final badge = item.badge;
    final icon = spans
        ? glyph
        : ExpressiveBadgeAnchor(badge: badge, child: glyph);
    final labelStyle = t.type
        .of(g.labelFont)
        .merge(visual.textStyle?.resolve(states));
    final textColor =
        foreground ?? colors.text(selected: selected, enabled: enabled);
    Widget labelIn(Color color) {
      final text = Text(
        item.label,
        textAlign: spans ? TextAlign.start : TextAlign.center,
        maxLines: geometry.position == ExpressiveNavItemPosition.start
            ? 1
            : null,
        overflow: geometry.position == ExpressiveNavItemPosition.start
            ? TextOverflow.ellipsis
            : null,
        style: labelStyle.copyWith(color: color),
      );
      // Under its icon, a label wraps between its words; a word wider than
      // the item (large text, a narrow bar) prints smaller, never broken.
      return geometry.position == ExpressiveNavItemPosition.start
          ? text
          : ExpressiveWholeWords(child: text);
    }

    final words = animateLabelColor
        ? ExpressiveSpringColor(
            value: textColor,
            motion: NavigationItemBehavior.labelColorMotion,
            builder: (context, color, _) => labelIn(color),
          )
        : labelIn(textColor);
    // A drawer's count stands at the row's end, clear of the words, as
    // Material's drawer badge label does; on the rail and the bar there is
    // no room beside the word, and it rides the icon's corner.
    final label = spans && badge != null
        ? Row(
            children: <Widget>[
              Expanded(child: words),
              const SizedBox(width: ExpressiveSpacing.s12),
              badge,
            ],
          )
        : words;
    return KeyedSubtree(
      key: item.key,
      // The item states its own selection: its pressable is the hit layer
      // under the pill, icon and label the item draws beside it, so the
      // pressable takes no role of its own (a role's tap would make that
      // empty layer the control a reader takes).
      child: MergeSemantics(
        child: Semantics(
          selected: selected,
          child: ExpressiveSpringValue(
            value: selected ? 1 : 0,
            motion: NavigationItemBehavior.indicatorMotion,
            builder: (context, progress, _) => ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minimum?.width ?? ExpressiveSpacing.s48,
                minHeight: minimum?.height ?? ExpressiveSpacing.s48,
              ),
              child: _NavItemLayout(
                geometry: g,
                fill: spans,
                progress: fill != null || side.style != BorderStyle.none
                    ? 1
                    : math.max(0, progress),
                devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                children: <Widget>[
                  ExpressivePressable(
                    statesController: controller,
                    style: ExpressiveComponentThemeData(
                      overlayColor: visual.overlayColor,
                      shape: visual.shape,
                    ),
                    shapes: ExpressivePressShapes.all(indicatorShape),
                    motion: NavigationItemBehavior.indicatorMotion,
                    color: const Color(_transparent),
                    contentColor: foreground ?? colors.ripple,
                    role: ExpressivePressRole.none,
                    semanticsRole: SemanticsRole.tab,
                    selected: selected,
                    minimumInteractiveSize: false,
                    // The expanded rail's destinations stack flush: a ring outside
                    // the pill ran under the next item, and a selected next
                    // item's indicator covered its lower edge. Inside, as a
                    // list row draws it; the item paints this layer over its
                    // indicator, so the ring shows on a selected pill too.
                    focusInward: identical(
                      geometry,
                      _NavItemGeometry.railStart,
                    ),
                    onPressed: enabled ? onTap : null,
                    child: const SizedBox.expand(),
                  ),
                  _Indicator(
                    color: fill ?? colors.indicator,
                    shape: indicatorShape.copyWith(side: side),
                    progress: fill != null || side.style != BorderStyle.none
                        ? 1
                        : progress,
                  ),
                  icon,
                  label,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const int _transparent = 0;
}

/// Compose's `Indicator`: the active indicator at [progress] opacity (its
/// width is the layout's).
class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.color,
    required this.shape,
    required this.progress,
  });

  final Color color;
  final ShapeBorder shape;
  final double progress;

  @override
  Widget build(BuildContext context) => ExpressiveSpringShape(
    value: shape,
    motion: NavigationItemBehavior.indicatorMotion,
    builder: (context, outline, _) => DecoratedBox(
      decoration: ShapeDecoration(
        color: color.withValues(alpha: color.a * progress.clamp(0, 1)),
        shape: outline,
      ),
    ),
  );
}

/// `NavigationItemLayout`: the indicator's ripple, the indicator, the icon
/// and the label, measured by `TopIconOrIconOnlyMeasurePolicy` or
/// `StartIconMeasurePolicy`.
class _NavItemLayout extends MultiChildRenderObjectWidget {
  const _NavItemLayout({
    required this.geometry,
    required this.progress,
    required this.devicePixelRatio,
    required super.children,
    this.fill = false,
  });

  final _NavItemGeometry geometry;
  final bool fill;
  final double progress;
  final double devicePixelRatio;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderNavItem(
    geometry: geometry,
    fill: fill,
    progress: progress,
    devicePixelRatio: devicePixelRatio,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderNavItem renderObject) {
    renderObject
      ..geometry = geometry
      ..fill = fill
      ..progress = progress
      ..devicePixelRatio = devicePixelRatio
      ..textDirection = Directionality.of(context);
  }
}

class _NavItemParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderNavItem extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _NavItemParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _NavItemParentData> {
  _RenderNavItem({
    required this._geometry,
    required this._fill,
    required this._progress,
    required this._devicePixelRatio,
    required this._textDirection,
  });

  _NavItemGeometry _geometry;
  set geometry(_NavItemGeometry value) {
    if (value == _geometry) return;
    _geometry = value;
    markNeedsLayout();
  }

  /// The item's indicator spans its width (a drawer's).
  bool _fill;
  set fill(bool value) {
    if (value == _fill) return;
    _fill = value;
    markNeedsLayout();
  }

  double _progress;
  set progress(double value) {
    if (value == _progress) return;
    _progress = value;
    markNeedsLayout();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _NavItemParentData) {
      child.parentData = _NavItemParentData();
    }
  }

  RenderBox get _ripple => firstChild!;
  RenderBox get _indicator => childAfter(_ripple)!;
  RenderBox get _icon => childAfter(_indicator)!;
  RenderBox get _label => childAfter(_icon)!;

  bool get _top => _geometry.position == ExpressiveNavItemPosition.top;

  double _px(double dp) =>
      (dp * _devicePixelRatio).roundToDouble() / _devicePixelRatio;

  /// The indicator's width [_progress] of the way open: on whole device
  /// pixels while it grows (no shimmer), exactly [full] once open, so a
  /// settled indicator never overhangs its item.
  double _animated(double full) =>
      (1 - _progress).abs() < 1e-3 ? full : _px(full * _progress);

  @override
  double computeMinIntrinsicWidth(double height) =>
      computeMaxIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) {
    final g = _geometry;
    final icon = _icon.getMaxIntrinsicWidth(double.infinity);
    final label = _label.getMaxIntrinsicWidth(double.infinity);
    if (_top) {
      return math.max(
        label,
        icon + g.indicatorHorizontalPadding * 2 + g.itemHorizontalPadding * 2,
      );
    }
    return icon + label + g.indicatorHorizontalPadding * 2 + g.iconToLabel;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) {
    final g = _geometry;
    final icon = _icon.getMaxIntrinsicHeight(width);
    if (_top) {
      final label = _label.getMaxIntrinsicHeight(width);
      return icon +
          label +
          g.itemVerticalPadding * 2 +
          g.indicatorVerticalPadding * 2 +
          g.indicatorToLabel;
    }
    final label = _label.getMaxIntrinsicHeight(width);
    return math.max(icon, label) + g.indicatorVerticalPadding * 2;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    Size(
      computeMaxIntrinsicWidth(constraints.maxHeight),
      computeMaxIntrinsicHeight(constraints.maxWidth),
    ),
  );

  void _place(RenderBox child, double x, double y) {
    final dx = switch (_textDirection) {
      TextDirection.ltr => x,
      TextDirection.rtl => size.width - x - child.size.width,
    };
    (child.parentData! as BoxParentData).offset = Offset(dx, y);
  }

  @override
  void performLayout() {
    final g = _geometry;
    final loose = constraints.loosen();
    if (_top) {
      _icon.layout(
        loose.deflate(
          EdgeInsets.symmetric(
            horizontal: g.indicatorHorizontalPadding,
            vertical: g.indicatorVerticalPadding,
          ),
        ),
        parentUsesSize: true,
      );
      final icon = _icon.size;
      final indicatorWidth = icon.width + g.indicatorHorizontalPadding * 2;
      final indicatorHeight = icon.height + g.indicatorVerticalPadding * 2;
      final animatedWidth = _animated(indicatorWidth);
      // Placed by their size read right to left (_place), so the parent
      // uses it.
      _ripple.layout(
        BoxConstraints.tight(Size(indicatorWidth, indicatorHeight)),
        parentUsesSize: true,
      );
      _indicator.layout(
        BoxConstraints.tight(Size(animatedWidth, indicatorHeight)),
        parentUsesSize: true,
      );
      _label.layout(
        loose.deflate(
          EdgeInsets.only(top: indicatorHeight + g.indicatorToLabel),
        ),
        parentUsesSize: true,
      );
      final label = _label.size;
      // placeLabelAndTopIcon (the bar) and placeAnimatedLabelAndIcon at
      // icon-top (the rail: its item padding either side of the
      // indicator, no vertical padding).
      final width = constraints.constrainWidth(
        math.max(label.width, indicatorWidth + g.itemHorizontalPadding * 2),
      );
      final contentHeight = indicatorHeight + g.indicatorToLabel + label.height;
      final ownHeight = contentHeight + g.itemVerticalPadding * 2;
      final height = constraints.constrainHeight(ownHeight);
      size = Size(width, height);
      // NavigationItem's box (contentAlignment = Center) centres the layout,
      // which measures itself under loosened constraints, in the item's
      // minimum height: a collapsed rail item's 52dp content sits 6dp down
      // its 64dp.
      final top = math.max(0.0, _px((height - ownHeight) / 2));
      final iconY = top + g.itemVerticalPadding + g.indicatorVerticalPadding;
      final indicatorY = iconY - g.indicatorVerticalPadding;
      _place(_indicator, (width - animatedWidth) / 2, indicatorY);
      _place(_ripple, (width - indicatorWidth) / 2, indicatorY);
      _place(_icon, (width - icon.width) / 2, iconY);
      _place(
        _label,
        (width - label.width) / 2,
        iconY + icon.height + g.indicatorVerticalPadding + g.indicatorToLabel,
      );
      return;
    }
    // StartIconMeasurePolicy + placeLabelAndStartIcon.
    _icon.layout(loose, parentUsesSize: true);
    final icon = _icon.size;
    if (_fill && constraints.hasBoundedWidth) {
      // A drawer's item: the indicator spans the item, the icon and the
      // label from its start, the label (with a count at its end) taking
      // the rest of the row.
      final width = constraints.maxWidth;
      final start = g.indicatorHorizontalPadding;
      final words = math.max(
        0.0,
        width - start * 2 - icon.width - g.iconToLabel,
      );
      _label.layout(
        BoxConstraints(
          minWidth: words,
          maxWidth: words,
          maxHeight: loose.maxHeight,
        ),
        parentUsesSize: true,
      );
      final label = _label.size;
      final indicatorHeight =
          math.max(icon.height, label.height) + g.indicatorVerticalPadding * 2;
      final animatedWidth = _animated(width);
      _ripple.layout(
        BoxConstraints.tight(Size(width, indicatorHeight)),
        parentUsesSize: true,
      );
      _indicator.layout(
        BoxConstraints.tight(Size(animatedWidth, indicatorHeight)),
        parentUsesSize: true,
      );
      final height = constraints.constrainHeight(indicatorHeight);
      size = Size(width, height);
      final y = (height - indicatorHeight) / 2;
      _place(_indicator, (width - animatedWidth) / 2, y);
      _place(_ripple, 0, y);
      _place(_icon, start, (height - icon.height) / 2);
      _place(
        _label,
        start + icon.width + g.iconToLabel,
        (height - label.height) / 2,
      );
      return;
    }
    _label.layout(
      loose.deflate(
        (g.reserveLabelPadding
                ? EdgeInsets.symmetric(
                    horizontal: g.indicatorHorizontalPadding,
                    vertical: g.indicatorVerticalPadding,
                  )
                : EdgeInsets.zero)
            .add(EdgeInsets.only(left: icon.width + g.iconToLabel)),
      ),
      parentUsesSize: true,
    );
    final label = _label.size;
    final indicatorWidth =
        icon.width +
        label.width +
        g.iconToLabel +
        g.indicatorHorizontalPadding * 2;
    final indicatorHeight =
        math.max(icon.height, label.height) + g.indicatorVerticalPadding * 2;
    final animatedWidth = _animated(indicatorWidth);
    _ripple.layout(
      BoxConstraints.tight(Size(indicatorWidth, indicatorHeight)),
      parentUsesSize: true,
    );
    _indicator.layout(
      BoxConstraints.tight(Size(animatedWidth, indicatorHeight)),
      parentUsesSize: true,
    );
    final width = constraints.constrainWidth(indicatorWidth);
    final height = constraints.constrainHeight(indicatorHeight);
    size = Size(width, height);
    _place(
      _indicator,
      (width - animatedWidth) / 2,
      (height - indicatorHeight) / 2,
    );
    _place(
      _ripple,
      (width - indicatorWidth) / 2,
      (height - indicatorHeight) / 2,
    );
    final content = icon.width + g.iconToLabel + label.width;
    final iconX = (width - content) / 2;
    _place(_icon, iconX, (height - icon.height) / 2);
    _place(
      _label,
      iconX + icon.width + g.iconToLabel,
      (height - label.height) / 2,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Compose's order: the indicator, the label, the icon, the ripple over
    // them all.
    void at(RenderBox child) => context.paintChild(
      child,
      (child.parentData! as BoxParentData).offset + offset,
    );
    at(_indicator);
    at(_label);
    at(_icon);
    at(_ripple);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // The whole item is the target, and a touch anywhere reaches the
    // indicator's ripple, from where it landed (Compose's
    // MappedInteractionSource: the ripple spreads from the touch, clipped
    // to the pill). The hit itself is taken at the pill's centre, inside
    // its shape wherever the finger was.
    final ripple = _ripple;
    final offset = (ripple.parentData! as BoxParentData).offset;
    final centre = ripple.size.center(Offset.zero);
    return result.addWithPaintOffset(
      offset: offset,
      position: position,
      hitTest: (result, transformed) =>
          ripple.hitTest(result, position: centre),
    );
  }
}

// ---------------------------------------------------------------------------
// Tabs
// ---------------------------------------------------------------------------

/// Primary or secondary tabs (Compose `PrimaryTabRow` / `SecondaryTabRow`).
enum ExpressiveTabBarVariant {
  /// Top-level content tabs: a short 3dp indicator under the label, the
  /// selected label in `primary`.
  primary,

  /// Tabs inside a content area: a full-width indicator, the selected label
  /// in `onSurface`.
  secondary,
}

/// One tab: a [label], an [icon], or both (the icon over the label).
@immutable
class ExpressiveTab {
  /// A tab showing a [label], an [icon] or both.
  const ExpressiveTab({this.label, this.icon, this.badge, this.key, this.style})
    : assert(label != null || icon != null, 'a tab has a label or an icon');

  /// Stateful visual overrides for this tab.
  final ExpressiveComponentThemeData? style;

  /// The tab's text.
  final String? label;

  /// The tab's glyph: one of `ExpressiveSymbols`.
  final IconData? icon;

  /// A badge on the icon (or on the label, when there is no icon).
  final Widget? badge;

  /// The key on the tab's hit target.
  final Key? key;
}

/// In-page tabs (Compose `PrimaryTabRow`, `SecondaryTabRow`,
/// `PrimaryScrollableTabRow`, `SecondaryScrollableTabRow`): [tabs] on a
/// `surface` band over a hairline divider, the [selectedIndex] tab in the
/// selected colour over its indicator, which slides and resizes to a new
/// selection on a spatial spring. Fixed tabs share the width on a phone;
/// in a window [ExpressiveSelect.wideFrom] or wider they keep to their
/// labels (90dp at least) from the start edge, as Material's
/// `TabAlignment.start` lays them out (sharing the width only when their
/// labels need it all). [scrollable] tabs are as wide as their labels (90dp
/// at least), start 52dp in and scroll the selected tab to the middle.
class ExpressiveTabBar extends StatefulWidget {
  /// A row of [tabs] with [selectedIndex] selected.
  const ExpressiveTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.variant = ExpressiveTabBarVariant.primary,
    this.scrollable = false,
    this.edgePadding = TabRowBehavior.scrollableEdgeStartPadding,
    this.style,
    super.key,
  });

  /// Stateful visual overrides for the tab-row frame.
  final ExpressiveComponentThemeData? style;

  /// The tabs, in order.
  final List<ExpressiveTab> tabs;

  /// The selected tab's index.
  final int selectedIndex;

  /// Called with a tab's index when it is tapped.
  final ValueChanged<int> onChanged;

  /// Primary or secondary.
  final ExpressiveTabBarVariant variant;

  /// Whether the tabs scroll (as wide as their content) or share the width.
  final bool scrollable;

  /// A scrollable row's padding before its first tab and after its last.
  final double edgePadding;

  @override
  State<ExpressiveTabBar> createState() => _ExpressiveTabBarState();
}

class _ExpressiveTabBarState extends State<ExpressiveTabBar>
    with TickerProviderStateMixin {
  late final AnimationController _left = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _width = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _scroll = AnimationController.unbounded(
    vsync: this,
  )..addListener(_scrolled);
  final ScrollController _scrollController = ScrollController();

  /// The indicator's targets once laid out; null before the first layout,
  /// when it stands at them without motion.
  ({double left, double width})? _target;
  int? _scrolledTo;
  bool _scrollable = false;

  @override
  void dispose() {
    _left.dispose();
    _width.dispose();
    _scroll.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrolled() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      position.jumpTo(
        _scroll.value.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    }
  }

  /// Told by the layout where the selected tab's indicator belongs (and,
  /// scrollable, where the row should scroll): springs there on
  /// `TabRowBehavior.indicatorMotion` (`TabIndicatorOffsetNode`).
  void _laidOut(double left, double width, _TabPosition selected) {
    if (!mounted) return;
    final motion = ExpressiveMotion.of(context);
    final target = _target;
    if (target == null) {
      _left.value = left;
      _width.value = width;
    } else {
      if (target.left != left) {
        _left.springTo(left, motion.spring(TabRowBehavior.indicatorMotion));
      }
      if (target.width != width) {
        _width.springTo(width, motion.spring(TabRowBehavior.indicatorMotion));
      }
    }
    _target = (left: left, width: width);
    if (_scrollable && _scrolledTo != widget.selectedIndex) {
      _scrolledTo = widget.selectedIndex;
      _scrollToCentre(selected);
    }
  }

  /// `ScrollableTabData.onLaidOut`: brings the selected tab to the middle
  /// of the viewport, as far as the row can scroll.
  void _scrollToCentre(_TabPosition tab) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final visible = position.viewportDimension;
    final centred = tab.left - (visible / 2 - tab.width / 2);
    final offset = centred.clamp(0, position.maxScrollExtent).toDouble();
    if (offset == position.pixels) return;
    _scroll.value = position.pixels;
    _scroll.springTo(
      offset,
      ExpressiveMotion.of(context).spring(TabRowBehavior.scrollMotion),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildRow);

  Widget _buildRow(BuildContext context, BoxConstraints constraints) {
    final t = context.expressiveTheme;
    final visual = t.tabBarTheme.merge(widget.style);
    final scrollable =
        widget.scrollable ||
        constraints.maxWidth < widget.tabs.length * ExpressiveSpacing.s48;
    if (_scrollable != scrollable) _scrolledTo = null;
    _scrollable = scrollable;
    // From 600, fixed tabs keep to their labels from the start edge.
    final start =
        !scrollable &&
        MediaQuery.sizeOf(context).width >= ExpressiveSelect.wideFrom;
    final primary = widget.variant == ExpressiveTabBarVariant.primary;
    final selectedColor = t.colors.role(
      primary
          ? PrimaryNavigationTabTokens.activeLabelTextColor
          : SecondaryNavigationTabTokens.activeLabelTextColor,
    );
    final unselectedColor = t.colors.role(
      primary
          ? PrimaryNavigationTabTokens.inactiveLabelTextColor
          : SecondaryNavigationTabTokens.inactiveLabelTextColor,
    );
    final indicatorColor = t.colors.role(
      PrimaryNavigationTabTokens.activeIndicatorColor,
    );
    final indicatorShape = (primary
        ? _cornerBorder(PrimaryNavigationTabTokens.activeIndicatorShape)
        : t.shapes.none);
    final indicator = DecoratedBox(
      decoration: ShapeDecoration(color: indicatorColor, shape: indicatorShape),
    );
    final divider = ColoredBox(color: t.colors.role(DividerTokens.color));
    final children = <Widget>[
      for (final (index, tab) in widget.tabs.indexed)
        _Tab(
          tab: tab,
          componentStyle: _navigationContentStyle(visual).merge(t.tabTheme),
          selected: index == widget.selectedIndex,
          selectedColor: selectedColor,
          unselectedColor: unselectedColor,
          onTap: () => widget.onChanged(index),
        ),
      divider,
      indicator,
    ];
    final layout = _TabRowLayout(
      scrollable: scrollable,
      start: start,
      dividerThickness: DividerTokens.thickness,
      indicatorThickness: PrimaryNavigationTabTokens.activeIndicatorHeight,
      matchContent: primary,
      selectedIndex: widget.selectedIndex,
      edgePadding: widget.edgePadding,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      left: _left,
      width: _width,
      placed: _target != null,
      onLaidOut: _laidOut,
      children: children,
    );
    // Flutter's TabBar: a tab bar of tabs, inside the scroll view when the
    // tabs scroll.
    final tabBar = Semantics(
      role: SemanticsRole.tabBar,
      container: true,
      explicitChildNodes: true,
      // Fixed tabs sharing the row's width equally: a word too wide for its
      // tab shrinks every tab's label alike. Not when each tab keeps to its
      // own label (from 600, or scrolling): there no word is cut, and a
      // short label measured against a long one's word would shrink.
      child: scrollable || start
          ? layout
          : ExpressiveWholeWordsGroup(child: layout),
    );
    final Widget row = scrollable
        ? SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: tabBar,
          )
        : tabBar;
    return ExpressiveSurface(
      componentStyle: visual,
      shape: t.shapes.none,
      color: t.colors.role(
        primary
            ? PrimaryNavigationTabTokens.containerColor
            : SecondaryNavigationTabTokens.containerColor,
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: scrollable
            ? Stack(
                children: <Widget>[
                  // The scrollable row's divider stands under it, the
                  // viewport's width.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SizedBox(
                      height: DividerTokens.thickness,
                      child: divider,
                    ),
                  ),
                  row,
                ],
              )
            : row,
      ),
    );
  }
}

/// A corners token as a border (the primary indicator's 3dp corners).
ExpressiveCornerBorder _cornerBorder(CornersToken corners) {
  ExpressiveCornerSize size(CornerToken corner) => switch (corner) {
    CornerDp(:final dp) => ExpressiveCornerSize.dp(dp),
    CornerPercent(:final percent) => ExpressiveCornerSize.fraction(
      percent / _hundred,
    ),
  };
  return ExpressiveCornerBorder(
    topStart: size(corners.topStart),
    topEnd: size(corners.topEnd),
    bottomEnd: size(corners.bottomEnd),
    bottomStart: size(corners.bottomStart),
  );
}

const int _hundred = 100;

/// One tab (Compose `Tab`): the whole tab is the pressable; its content
/// colour fades to the selected colour on `TabBehavior.fadeInMotion` and
/// back on `fadeOutMotion` (`TabTransition`).
class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.componentStyle,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final ExpressiveTab tab;
  final ExpressiveComponentThemeData componentStyle;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final label = tab.label;
    final icon = tab.icon;
    return KeyedSubtree(
      key: tab.key,
      child: ExpressiveSpringColor(
        value: selected ? selectedColor : unselectedColor,
        motion: selected ? TabBehavior.fadeInMotion : TabBehavior.fadeOutMotion,
        builder: (context, color, _) => ExpressivePressable(
          style: tab.style,
          componentStyle: componentStyle,
          shapes: const ExpressivePressShapes.all(ExpressiveCornerBorder()),
          motion: TabRowBehavior.indicatorMotion,
          color: const Color(_transparent),
          contentColor: selectedColor,
          role: ExpressivePressRole.tab,
          semanticsRole: SemanticsRole.tab,
          selected: selected,
          minimumInteractiveSize: false,
          // The tab's face is its cell: the state layer fills it and the
          // label stands on its middle. Unmarked, the clear layer's only
          // ink is a badge's pill, and the count read as the label.
          markFace: true,
          // The ring stands inside the tab, as Material's tabs draw their
          // focus ring inward: outside it, the row clips the ring and a
          // neighbour's would overlap it.
          focusRect: (size) => (Offset.zero & size).deflate(
            ExpressiveFocusRing.offset + ExpressiveFocusRing.thickness,
          ),
          onPressed: onTap,
          child: Builder(
            builder: (context) {
              final scope = ExpressiveStyleScope.maybeOf(context)!;
              final visual = scope.style;
              final states = scope.states;
              final foreground =
                  visual.foregroundColor?.resolve(states) ?? color;
              Widget? text;
              if (label != null) {
                // A word wider than its tab (large text) prints smaller,
                // whole, rather than breaking mid-word ("Upco/ming").
                text = expressiveFaceLabel(
                  ExpressiveWholeWords(
                    child: Text(
                      label,
                      maxLines: _maxLines,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: t.type
                          .of(PrimaryNavigationTabTokens.labelTextFont)
                          .merge(visual.textStyle?.resolve(states))
                          .copyWith(color: foreground),
                    ),
                  ),
                );
                final badge = tab.badge;
                if (icon == null && badge != null) {
                  // After the label, its top on the label's: BadgedBox
                  // stands a badge 12dp in over an icon's corner, which on
                  // a word covered its last letters ("Mentio2").
                  text = Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Flexible(child: text),
                      const SizedBox(width: ExpressiveSpacing.s4),
                      IgnorePointer(child: badge),
                    ],
                  );
                }
                text = Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TabBehavior.horizontalTextPadding,
                  ),
                  child: text,
                );
              }
              Widget? glyph;
              if (icon != null) {
                glyph = ExpressiveBadgeAnchor(
                  badge: tab.badge,
                  child: Icon(
                    icon,
                    size:
                        visual.iconSize?.resolve(states) ??
                        PrimaryNavigationTabTokens.iconSize,
                    color: foreground,
                  ),
                );
              }
              return ExpressiveStyledContent(
                center: false,
                child: _TabContent(
                  textScaler: MediaQuery.textScalerOf(context),
                  density: t.density,
                  text: text,
                  icon: glyph,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Compose's samples' `maxLines = 2`.
  static const int _maxLines = 2;
  static const int _transparent = 0;
}

/// `TabBaselineLayout`, centred across the tab (`Tab`'s column).
class _TabContent extends MultiChildRenderObjectWidget {
  _TabContent({
    required this.textScaler,
    required this.density,
    Widget? text,
    Widget? icon,
  }) : _hasText = text != null,
       _hasIcon = icon != null,
       super(children: <Widget>[?text, ?icon]);

  final TextScaler textScaler;
  final ExpressiveDensity density;
  final bool _hasText;
  final bool _hasIcon;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTabContent(
    hasText: _hasText,
    hasIcon: _hasIcon,
    textScaler: textScaler,
    density: density,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTabContent renderObject,
  ) {
    renderObject
      ..hasText = _hasText
      ..hasIcon = _hasIcon
      ..textScaler = textScaler
      ..density = density;
  }
}

class _TabContentParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTabContent extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TabContentParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TabContentParentData> {
  _RenderTabContent({
    required this._hasText,
    required this._hasIcon,
    required this._textScaler,
    required this._density,
  });

  bool _hasText;
  set hasText(bool value) {
    if (value == _hasText) return;
    _hasText = value;
    markNeedsLayout();
  }

  bool _hasIcon;
  set hasIcon(bool value) {
    if (value == _hasIcon) return;
    _hasIcon = value;
    markNeedsLayout();
  }

  ExpressiveDensity _density;
  set density(ExpressiveDensity value) {
    if (value == _density) return;
    _density = value;
    markNeedsLayout();
  }

  TextScaler _textScaler;
  set textScaler(TextScaler value) {
    if (value == _textScaler) return;
    _textScaler = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TabContentParentData) {
      child.parentData = _TabContentParentData();
    }
  }

  RenderBox? get _text => _hasText ? firstChild : null;
  RenderBox? get _icon => _hasIcon ? lastChild : null;

  double get _specHeight => _density.height(
    _hasText && _hasIcon
        ? TabBehavior.largeHeight
        : PrimaryNavigationTabTokens.containerHeight,
    floor: ExpressiveSpacing.s48,
  );

  double get _iconDistance =>
      _textScaler.scale(TabBehavior.iconDistanceFromBaseline);

  @override
  double computeMinIntrinsicWidth(double height) =>
      computeMaxIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
    _text?.getMaxIntrinsicWidth(double.infinity) ?? 0,
    _icon?.getMaxIntrinsicWidth(double.infinity) ?? 0,
  );

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    _specHeight,
    (_icon?.getMaxIntrinsicHeight(width) ?? 0) +
        (_text?.getMaxIntrinsicHeight(width) ?? 0) +
        _iconDistance,
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) => Size(
    constraints.hasBoundedWidth
        ? constraints.maxWidth
        : constraints.constrainWidth(computeMaxIntrinsicWidth(double.infinity)),
    constraints.hasBoundedHeight
        ? constraints.maxHeight
        : constraints.constrainHeight(
            computeMaxIntrinsicHeight(constraints.maxWidth),
          ),
  );

  @override
  void performLayout() {
    final loose = constraints.loosen();
    final text = _text;
    final icon = _icon;
    text?.layout(loose, parentUsesSize: true);
    icon?.layout(loose, parentUsesSize: true);
    final contentWidth = math.max(text?.size.width ?? 0, icon?.size.width ?? 0);
    final tabHeight = math.max(
      _specHeight,
      (icon?.size.height ?? 0) + (text?.size.height ?? 0) + _iconDistance,
    );
    // The Tab's column fills the tab (fillMaxWidth) and centres the layout
    // across it and down it. The pressable's stack hands this box loosened
    // constraints, so it takes their bounded maximum.
    size = Size(
      constraints.hasBoundedWidth
          ? constraints.maxWidth
          : constraints.constrainWidth(contentWidth),
      constraints.hasBoundedHeight
          ? constraints.maxHeight
          : constraints.constrainHeight(tabHeight),
    );
    final dx = (size.width - contentWidth) / 2;
    final dy = (size.height - tabHeight) / 2;
    void place(RenderBox child, double x, double y) =>
        (child.parentData! as BoxParentData).offset = Offset(dx + x, dy + y);
    if (text != null && icon != null) {
      final first = text.getDistanceToBaseline(TextBaseline.alphabetic)!;
      final lineHeight = text.getMaxIntrinsicHeight(double.infinity);
      final lines = math.max(1, (text.size.height / lineHeight).round());
      final last = first + (lines - 1) * lineHeight;
      final baselineOffset = lines == 1
          ? TabBehavior.singleLineTextBaselineWithIcon
          : TabBehavior.doubleLineTextBaselineWithIcon;
      final textOffset =
          baselineOffset + PrimaryNavigationTabTokens.activeIndicatorHeight;
      final iconOffset = icon.size.height + _iconDistance - first;
      final textY = tabHeight - last - textOffset;
      place(text, (contentWidth - text.size.width) / 2, textY);
      place(icon, (contentWidth - icon.size.width) / 2, textY - iconOffset);
      return;
    }
    final only = (text ?? icon)!;
    place(only, 0, (tabHeight - only.size.height) / 2);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A tab's place in its row (Compose `TabPosition`).
@immutable
class _TabPosition {
  const _TabPosition(this.left, this.width, this.contentWidth);

  final double left;
  final double width;
  final double contentWidth;

  @override
  bool operator ==(Object other) =>
      other is _TabPosition &&
      other.left == left &&
      other.width == width &&
      other.contentWidth == contentWidth;

  @override
  int get hashCode => Object.hash(left, width, contentWidth);
}

typedef _TabLaidOut = void Function(
  double left,
  double width,
  _TabPosition selected,
);

/// `TabRowImpl` / `ScrollableTabRowImpl`: the tabs, then the divider, then
/// the indicator (the last two children).
class _TabRowLayout extends MultiChildRenderObjectWidget {
  const _TabRowLayout({
    required this.scrollable,
    required this.start,
    required this.dividerThickness,
    required this.indicatorThickness,
    required this.matchContent,
    required this.selectedIndex,
    required this.edgePadding,
    required this.devicePixelRatio,
    required this.left,
    required this.width,
    required this.placed,
    required this.onLaidOut,
    required super.children,
  });

  final bool scrollable;

  /// Fixed tabs at their labels' widths from the start edge, not sharing
  /// the width.
  final bool start;
  final double dividerThickness;
  final double indicatorThickness;
  final bool matchContent;
  final int selectedIndex;
  final double edgePadding;
  final double devicePixelRatio;
  final Animation<double> left;
  final Animation<double> width;
  final bool placed;
  final _TabLaidOut onLaidOut;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTabRow(
    scrollable: scrollable,
    start: start,
    dividerThickness: dividerThickness,
    indicatorThickness: indicatorThickness,
    matchContent: matchContent,
    selectedIndex: selectedIndex,
    edgePadding: edgePadding,
    devicePixelRatio: devicePixelRatio,
    left: left,
    width: width,
    placed: placed,
    onLaidOut: onLaidOut,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderTabRow renderObject) {
    renderObject
      ..scrollable = scrollable
      ..start = start
      ..dividerThickness = dividerThickness
      ..indicatorThickness = indicatorThickness
      ..matchContent = matchContent
      ..selectedIndex = selectedIndex
      ..edgePadding = edgePadding
      ..devicePixelRatio = devicePixelRatio
      ..left = left
      ..width = width
      ..placed = placed
      ..onLaidOut = onLaidOut
      ..textDirection = Directionality.of(context);
  }
}

class _TabRowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTabRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TabRowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TabRowParentData> {
  _RenderTabRow({
    required this._scrollable,
    required this._start,
    required this._dividerThickness,
    required this._indicatorThickness,
    required this._matchContent,
    required this._selectedIndex,
    required this._edgePadding,
    required this._devicePixelRatio,
    required this._left,
    required this._width,
    required this._placed,
    required this.onLaidOut,
    required this._textDirection,
  });

  double _dividerThickness;
  double _indicatorThickness;
  set dividerThickness(double value) {
    if (value == _dividerThickness) return;
    _dividerThickness = value;
    markNeedsLayout();
  }

  set indicatorThickness(double value) {
    if (value == _indicatorThickness) return;
    _indicatorThickness = value;
    markNeedsLayout();
  }

  bool _scrollable;
  set scrollable(bool value) {
    if (value == _scrollable) return;
    _scrollable = value;
    markNeedsLayout();
  }

  bool _start;
  set start(bool value) {
    if (value == _start) return;
    _start = value;
    markNeedsLayout();
  }

  bool _matchContent;
  set matchContent(bool value) {
    if (value == _matchContent) return;
    _matchContent = value;
    markNeedsLayout();
  }

  int _selectedIndex;
  set selectedIndex(int value) {
    if (value == _selectedIndex) return;
    _selectedIndex = value;
    markNeedsLayout();
  }

  double _edgePadding;
  set edgePadding(double value) {
    if (value == _edgePadding) return;
    _edgePadding = value;
    markNeedsLayout();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsLayout();
  }

  Animation<double> _left;
  set left(Animation<double> value) {
    if (value == _left) return;
    if (attached) _left.removeListener(markNeedsLayout);
    _left = value;
    if (attached) _left.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  Animation<double> _width;
  set width(Animation<double> value) {
    if (value == _width) return;
    if (attached) _width.removeListener(markNeedsLayout);
    _width = value;
    if (attached) _width.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  bool _placed;
  set placed(bool value) {
    if (value == _placed) return;
    _placed = value;
    markNeedsLayout();
  }

  _TabLaidOut onLaidOut;

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  _TabPosition? _reported;
  ({double left, double width})? _reportedTarget;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _left.addListener(markNeedsLayout);
    _width.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _left.removeListener(markNeedsLayout);
    _width.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TabRowParentData) {
      child.parentData = _TabRowParentData();
    }
  }

  List<RenderBox> get _tabs {
    final tabs = <RenderBox>[];
    for (var c = firstChild; c != null; c = childAfter(c)) {
      tabs.add(c);
    }
    return tabs.sublist(0, tabs.length - 2);
  }

  RenderBox get _divider => childBefore(lastChild!)!;
  RenderBox get _indicator => lastChild!;

  double _floorPx(double dp) =>
      (dp * _devicePixelRatio).floorToDouble() / _devicePixelRatio;

  double _px(double dp) =>
      (dp * _devicePixelRatio).roundToDouble() / _devicePixelRatio;

  static const double _padding = TabBehavior.horizontalTextPadding;

  // A tab at its label's width (90dp at least: Compose's
  // ScrollableTabRowMinimumTabWidth), as a scrollable row and a fixed one
  // from 600 lay it out.
  double _labelWidth(RenderBox tab, double height) => math.max(
    TabRowBehavior.scrollableMinTabWidth,
    tab.getMaxIntrinsicWidth(height),
  );

  double _rowHeight(List<RenderBox> tabs, double tabWidth) => tabs.fold(
    0,
    (height, tab) => math.max(height, tab.getMaxIntrinsicHeight(tabWidth)),
  );

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) {
    final tabs = _tabs;
    if (tabs.isEmpty) return 0;
    return _rowHeight(
      tabs,
      _scrollable || !width.isFinite
          ? double.infinity
          : _floorPx(width / tabs.length),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final tabs = _tabs;
    if (_start && !_scrollable) {
      return tabs.fold(0, (sum, tab) => sum + _labelWidth(tab, height));
    }
    if (!_scrollable) {
      return tabs.fold(
        0,
        (sum, tab) => sum + tab.getMaxIntrinsicWidth(double.infinity),
      );
    }
    return tabs.fold(
      _edgePadding * 2,
      (sum, tab) =>
          sum +
          math.max(
            TabRowBehavior.scrollableMinTabWidth,
            tab.getMaxIntrinsicWidth(double.infinity),
          ),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      computeMaxIntrinsicWidth(height);

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    Size(
      _scrollable
          ? computeMaxIntrinsicWidth(double.infinity)
          : constraints.maxWidth,
      computeMaxIntrinsicHeight(constraints.maxWidth),
    ),
  );

  void _place(RenderBox child, double x, double y) {
    final dx = switch (_textDirection) {
      TextDirection.ltr => x,
      TextDirection.rtl => size.width - x - child.size.width,
    };
    (child.parentData! as BoxParentData).offset = Offset(dx, y);
  }

  @override
  void performLayout() {
    final tabs = _tabs;
    final positions = <_TabPosition>[];
    double rowWidth;
    double rowHeight;
    final labels = _start && !_scrollable
        ? [for (final tab in tabs) _labelWidth(tab, double.infinity)]
        : null;
    if (labels != null &&
        labels.fold(0.0, (a, b) => a + b) <= constraints.maxWidth) {
      // From 600 (TabAlignment.start): each tab at its label's width from
      // the start edge, the divider across the row.
      rowWidth = constraints.maxWidth;
      rowHeight = _rowHeight(tabs, double.infinity);
      var left = 0.0;
      for (final (index, tab) in tabs.indexed) {
        final width = labels[index];
        tab.layout(
          BoxConstraints.tight(Size(width, rowHeight)),
          parentUsesSize: true,
        );
        final content = math.max(
          tab.getMaxIntrinsicWidth(double.infinity) - _padding * 2,
          TabRowBehavior.indicatorMinWidth,
        );
        positions.add(_TabPosition(left, width, content));
        left += width;
      }
      size = constraints.constrain(Size(rowWidth, rowHeight));
      for (final (index, tab) in tabs.indexed) {
        _place(tab, positions[index].left, 0);
      }
    } else if (!_scrollable) {
      rowWidth = constraints.maxWidth;
      final tabWidth = tabs.isEmpty ? 0.0 : _floorPx(rowWidth / tabs.length);
      rowHeight = _rowHeight(tabs, tabWidth);
      for (final (index, tab) in tabs.indexed) {
        final content =
            math.min(tab.getMaxIntrinsicWidth(rowHeight), tabWidth) -
            _padding * 2;
        positions.add(
          _TabPosition(
            tabWidth * index,
            tabWidth,
            math.max(content, TabRowBehavior.indicatorMinWidth),
          ),
        );
        tab.layout(
          BoxConstraints.tight(Size(tabWidth, rowHeight)),
          parentUsesSize: true,
        );
      }
      size = constraints.constrain(Size(rowWidth, rowHeight));
      for (final (index, tab) in tabs.indexed) {
        _place(tab, positions[index].left, 0);
      }
    } else {
      rowHeight = _rowHeight(tabs, double.infinity);
      var left = _edgePadding;
      for (final tab in tabs) {
        // Compose measures each tab at least ScrollableTabRowMinimumTabWidth
        // wide; the tab is then laid out at exactly that width so its content
        // centres across it (Tab's column fills the width).
        final width = math.max(
          TabRowBehavior.scrollableMinTabWidth,
          tab.getMaxIntrinsicWidth(rowHeight),
        );
        tab.layout(
          BoxConstraints.tight(Size(width, rowHeight)),
          parentUsesSize: true,
        );
        final content = math.max(
          tab.getMaxIntrinsicWidth(double.infinity) - _padding * 2,
          TabRowBehavior.indicatorMinWidth,
        );
        positions.add(_TabPosition(left, width, content));
        left += width;
      }
      rowWidth = left + _edgePadding;
      size = constraints.constrain(Size(rowWidth, rowHeight));
      for (final (index, tab) in tabs.indexed) {
        _place(tab, positions[index].left, 0);
      }
    }

    // The fixed row's divider spans it, over the tabs' bottom edge; the
    // scrollable row's stands under the viewport (the widget draws it), so
    // this one is laid out empty.
    _divider.layout(
      BoxConstraints.tight(
        Size(_scrollable ? 0 : size.width, _dividerThickness),
      ),
      parentUsesSize: true,
    );
    _place(_divider, 0, size.height - _dividerThickness);

    if (positions.isEmpty) {
      _indicator.layout(BoxConstraints.tight(Size.zero));
      return;
    }
    final index = _selectedIndex.clamp(0, positions.length - 1);
    final selected = positions[index];
    final targetWidth = _matchContent ? selected.contentWidth : selected.width;
    final target = (left: selected.left, width: targetWidth);
    if (_reportedTarget != target || _reported != selected) {
      _reportedTarget = target;
      _reported = selected;
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => onLaidOut(target.left, target.width, selected),
      );
    }
    final left = _placed ? _left.value : target.left;
    final width = math.max(0.0, _px(_placed ? _width.value : target.width));
    _indicator.layout(
      BoxConstraints.tight(Size(width, _indicatorThickness)),
      parentUsesSize: true,
    );
    // Compose centres the indicator in the tab it is measured against (its
    // modifier reports a narrower width than the tab's fixed constraint).
    final inset = _matchContent ? (selected.width - width) / 2 : 0.0;
    _place(_indicator, left + inset, size.height - _indicatorThickness);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final tab in _tabs.reversed) {
      final offset = (tab.parentData! as BoxParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) =>
            tab.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}

ExpressiveComponentThemeData _navigationContentStyle(
  ExpressiveComponentThemeData style,
) => ExpressiveComponentThemeData(
  foregroundColor: style.foregroundColor,
  textStyle: style.textStyle,
  iconSize: style.iconSize,
);

class _NavigationStates extends StatefulWidget {
  const _NavigationStates({required this.builder});
  final Widget Function(BuildContext, WidgetStatesController) builder;
  @override
  State<_NavigationStates> createState() => _NavigationStatesState();
}

class _NavigationStatesState extends State<_NavigationStates> {
  final controller = WidgetStatesController();
  bool _queued = false;
  @override
  void initState() {
    super.initState();
    controller.addListener(_changed);
  }

  void _changed() {
    // A descendant pressable synchronizes disabled during its build. Paint
    // interaction updates immediately, and defer only notifications from build.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_queued) return;
      _queued = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _queued = false;
        if (mounted) setState(() {});
      });
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, controller);
}

class _NavigationViewport extends StatelessWidget {
  const _NavigationViewport({required this.minimumWidth, required this.child});
  final double minimumWidth;
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: math.max(constraints.maxWidth, minimumWidth),
        child: child,
      ),
    ),
  );
}
