/// App bars: the small top app bar, the medium and large flexible app bars
/// (subtitle, centred, collapsing by scroll, colour fill on scroll) and the
/// search app bar; the search bar, its input field and the full-screen
/// search view (CONTRACT §4.1 `app-bar`, `search-field`; §4.2
/// `ExpressiveAppBar`). Owner: w2-appbar.
///
/// Ports of Compose material3 1.5.0-alpha29:
///
/// - `AppBar.kt`: `TopAppBar` (`SingleRowTopAppBar`), `MediumFlexibleTopAppBar`
///   and `LargeFlexibleTopAppBar` (`TwoRowsTopAppBar`), both laid out by
///   `TopAppBarLayout`'s measure policy ([_TopAppBarLayout] here, line for
///   line), and `TopAppBarState`'s height and content offsets
///   ([ExpressiveAppBarScroll]). `ExpressiveScaffold`, which owns the
///   scrollable, runs the exit-until-collapsed scroll and `settleAppBar`'s
///   snap.
/// - `SearchBar.kt`: `AppBarWithSearch` ([ExpressiveAppBar.search]), the
///   collapsed `SearchBar` ([ExpressiveSearchBar]), `SearchBarDefaults
///   .InputField` ([ExpressiveSearchField]) and `ExpandedFullScreenSearchBar`
///   / `ExpandedFullScreenContainedSearchBar` (the view a bar opens:
///   `FullScreenSearchBarLayout`'s geometry, predictive back included —
///   [expressiveSearchViewGeometry(]).
///
/// Deliberate deviations:
/// - The search view expands on the slow spatial spring and collapses on
///   the default one (`rememberSearchBarState`'s `animationSpecForExpand` /
///   `ForCollapse`: `SearchBarBehavior.expandMotion` / `collapseMotion`),
///   where the legacy `SearchBar` runs 400/250 ms tweens (RUN 2 decision
///   F10).
/// - The collapsed search bar is a button that opens the view rather than a
///   focusable text field whose focus expands it (Compose disables the soft
///   keyboard in the collapsed bar, so typing starts in the view either way).
/// - The search app bar fills its colour on scroll but never hides
///   (Compose's `enterAlwaysSearchBarScrollBehavior` is opt-in).
/// - A flexible bar's collapse range is measured from its title with a text
///   painter before layout (the screen's sliver needs it up front), where
///   Compose reads it from the laid-out title row; the two agree.
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart'
    show ValueListenable, visibleForTesting;
import 'package:material_ui/material_ui.dart'
    show Material, MaterialLocalizations, MaterialType, TextField, Theme;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart' show RoutePresentation;
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../elevation.dart';
import '../icons.dart';
import '../internal/cap_label.dart';
import '../internal/styled_content.dart';
import '../internal/tokens/app_bar_large_flexible_tokens.g.dart';
import '../internal/tokens/app_bar_medium_flexible_tokens.g.dart';
import '../internal/tokens/app_bar_small_tokens.g.dart';
import '../internal/tokens/app_bar_tokens.g.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/filled_text_field_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/search_bar_tokens.g.dart';
import '../internal/tokens/search_view_tokens.g.dart';
import '../motion.dart';
import '../states.dart';
import '../strings.dart';
import '../theme.dart';
import 'icon_buttons.dart';
import 'menus.dart';
import 'overlays.dart' show ExpressiveBackHandleRoute, expressiveSettleTime;
import 'page.dart' show ExpressivePage;

// ---------------------------------------------------------------------------
// Easings Compose maps scroll and gesture fractions through (layout
// mappings of a position, never timing curves).

/// `TopTitleAlphaEasing` (AppBar.kt): `CubicBezierEasing(.8f, 0f, .8f,
/// .15f)`, the collapsed title's alpha over the collapsed fraction. Inline
/// until the behaviour parser reads Kotlin's leading-dot literals
/// (behavior/app_bar.yaml).
const Curve _topTitleAlphaEasing = Cubic(0.8, 0, 0.8, 0.15);

/// `FastOutLinearInEasing` (compose.animation.core; the pinned material3
/// jar states the same curve as `MotionTokens.EasingLegacyAccelerate`): a
/// two-row bar's container colour over its collapsed fraction
/// (`TopAppBarColors.containerColor`).
const Curve _fastOutLinearIn = Cubic(
  AppBarBehavior.containerColorEasingX1,
  AppBarBehavior.containerColorEasingY1,
  AppBarBehavior.containerColorEasingX2,
  AppBarBehavior.containerColorEasingY2,
);

/// The overlapped fraction past which a single-row bar fills
/// (`overlappingFraction > 0.01f`, AppBar.kt and SearchBar.kt).
const _overlapThreshold = 0.01;

/// `SearchBarPredictiveBackMinScale` (SearchBar.kt): `9f / 10f`.
const _predictiveBackMinScale = 9 / 10;

// ---------------------------------------------------------------------------
// Scroll state.

/// Where a top bar stands against the content under it — Compose's
/// `TopAppBarState` offsets, as a value: [heightOffset] (0 at rest, down to
/// minus the bar's collapse range) and [contentOffset] (0 at rest, negative
/// as content scrolls under the bar).
///
/// `ExpressiveScaffold` publishes one around its bar
/// ([ExpressiveAppBarScrollScope]) from its scrollable; a bar outside a
/// screen stands at rest unless given one (a still of a bar mid-collapse).
///
/// ```dart
/// ExpressiveAppBar(title: 'Trips', large: true, scroll: ExpressiveAppBarScroll(heightOffset: -28))
/// ```
@immutable
class ExpressiveAppBarScroll {
  /// A top bar scroll state of [heightOffset], [contentOffset] and [overlay].
  const ExpressiveAppBarScroll({
    this.heightOffset = 0,
    this.contentOffset = 0,
    this.overlay = false,
  }) : assert(heightOffset <= 0, 'a bar only collapses (heightOffset <= 0)');

  /// At rest.
  static const ExpressiveAppBarScroll rest = ExpressiveAppBarScroll();

  /// How far the bar has collapsed, in dp: 0 expanded, negative collapsing.
  final double heightOffset;

  /// How far content has scrolled under the bar, in dp: 0 at rest,
  /// negative scrolled.
  final double contentOffset;

  /// Whether the bar stands over a full-bleed body (a hero under the status
  /// bar): transparent at rest, it fills once content passes under it.
  final bool overlay;

  /// Compose's `overlappedFraction` for a bar whose row is [rowHeight]
  /// tall: how much of it the scrolled content has passed under, 0 to 1.
  double overlappedFraction(double rowHeight) =>
      rowHeight <= 0 ? 0 : (-contentOffset / rowHeight).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      other is ExpressiveAppBarScroll &&
      other.heightOffset == heightOffset &&
      other.contentOffset == contentOffset &&
      other.overlay == overlay;

  @override
  int get hashCode => Object.hash(heightOffset, contentOffset, overlay);
}

/// Publishes the [ExpressiveAppBarScroll] of the scrollable a screen's bar
/// stands over; the bar reads it when it is given none of its own.
class ExpressiveAppBarScrollScope extends InheritedWidget {
  /// A scope publishing [scroll] to the bar below it.
  const ExpressiveAppBarScrollScope({
    required this.scroll,
    required super.child,
    super.key,
  });

  /// Where the bar stands.
  final ExpressiveAppBarScroll scroll;

  /// The nearest published scroll, or null.
  static ExpressiveAppBarScroll? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ExpressiveAppBarScrollScope>()
      ?.scroll;

  @override
  bool updateShouldNotify(ExpressiveAppBarScrollScope oldWidget) =>
      scroll != oldWidget.scroll;
}

// ---------------------------------------------------------------------------
// The top bar.

/// The top app bar's size (Compose's `TopAppBar`, `MediumFlexibleTopAppBar`,
/// `LargeFlexibleTopAppBar`).
enum ExpressiveAppBarSize {
  /// One 64dp row: navigation, title, actions.
  small,

  /// Two rows: the small row over a `headlineMedium` title row (112dp, 136
  /// with a subtitle).
  medium,

  /// Two rows: the small row over a `displaySmall` title row (120dp, 152
  /// with a subtitle).
  large,
}

/// One action of an [ExpressiveAppBar]: an icon button that folds into the
/// bar's overflow menu as an item when the bar has more than two.
///
/// ```dart
/// ExpressiveAppBarAction(ExpressiveSymbols.share, label: 'Share', onPressed: share)
/// ```
class ExpressiveAppBarAction extends StatelessWidget {
  /// An action showing [icon], named [label], that runs [onPressed].
  const ExpressiveAppBarAction(
    this.icon, {
    required this.label,
    required this.onPressed,
    this.style,
    super.key,
    this.focusNode,
    this.autofocus = false,
  });

  /// Stateful visual overrides, retained when the action folds into a menu.
  final ExpressiveComponentThemeData? style;

  /// The glyph: one of [ExpressiveSymbols].
  final IconData icon;

  /// What the action is called: the button's label and tooltip, the
  /// overflow item's text.
  final String label;

  /// What a tap does; null disables it.
  final VoidCallback? onPressed;

  /// The focus node of its press target; null lets the target keep its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => ExpressiveIconButton(
    focusNode: focusNode,
    autofocus: autofocus,
    icon,
    style: style,
    onPressed: onPressed,
    semanticLabel: label,
  );
}

/// The authored screen header (CONTRACT §4.2 `ExpressiveAppBar`): Material's
/// top app bar in its small, medium flexible and large flexible sizes, or
/// the search app bar ([ExpressiveAppBar.search]).
///
/// - [title] and [subtitle]; [centered] centres them (Compose's
///   `titleHorizontalAlignment = CenterHorizontally`).
/// - [leading] is the navigation icon; leave it unset and the route's exit
///   appears ([autoLeading]: the back arrow on a pushed page, close in a
///   sheet or a full-screen dialog, nothing on a root). Never author a back
///   or close control.
/// - [actions]: at most two show; with more, the rest — which must be
///   [ExpressiveAppBarAction]s — fold into the overflow menu, followed by
///   [overflow]'s entries.
/// - [size] (or `large: true`); [collapsing] lets a flexible bar collapse
///   to its small row as the screen's content scrolls, snapping on a spring
///   when the scroll stops midway. Colour fills on scroll: the small bar
///   springs to `surfaceContainer` when content passes under it; a flexible
///   bar fills as it collapses.
///
/// [none] declines the bar a screen would otherwise derive.
///
/// ```dart
/// ExpressiveAppBar(title: 'Trips', subtitle: '3 upcoming', large: true, collapsing: true, actions: [ExpressiveAppBarAction(ExpressiveSymbols.search, label: 'Search', onPressed: search)])
/// ```
class ExpressiveAppBar extends StatelessWidget {
  /// A small, medium or large top app bar.
  const ExpressiveAppBar({
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.overflow = const <ExpressiveMenuEntry>[],
    bool large = false,
    ExpressiveAppBarSize? size,
    this.centered = false,
    this.collapsing = false,
    this.scroll,
    this.style,
    super.key,
  }) : size =
           size ??
           (large ? ExpressiveAppBarSize.large : ExpressiveAppBarSize.small),
       search = null,
       assert(
         !collapsing || large || (size != null && size != .small),
         'collapsing is a flexible (medium or large) bar\'s',
       );

  /// The search app bar (Compose's `AppBarWithSearch`): [search] between the
  /// navigation icon and the actions.
  const ExpressiveAppBar.search({
    required ExpressiveSearchBar this.search,
    this.leading,
    this.actions = const <Widget>[],
    this.overflow = const <ExpressiveMenuEntry>[],
    this.scroll,
    this.style,
    super.key,
  }) : title = null,
       subtitle = null,
       size = ExpressiveAppBarSize.small,
       centered = false,
       collapsing = false;

  /// The explicit bar-less register: `topBar: ExpressiveAppBar.none`
  /// declines the bar the route would derive, for the page whose header is
  /// its own body. Leaving `topBar` unset means the derived bar.
  static const Widget none = SizedBox.shrink(
    key: ValueKey<String>('expressive:top-bar:none'),
  );

  /// Stateful visual overrides for this screen-edge frame.
  final ExpressiveComponentThemeData? style;

  /// The title.
  final String? title;

  /// One secondary line under the title.
  final String? subtitle;

  /// The navigation icon; the route's exit ([autoLeading]) when null.
  final Widget? leading;

  /// The trailing actions: two show, the rest fold into the overflow menu.
  final List<Widget> actions;

  /// Entries the overflow menu ends with.
  final List<ExpressiveMenuEntry> overflow;

  /// Small, medium flexible or large flexible.
  final ExpressiveAppBarSize size;

  /// Whether the title and subtitle are centred.
  final bool centered;

  /// Whether a flexible bar collapses as its screen's content scrolls.
  final bool collapsing;

  /// Where the bar stands against its content; the scope's
  /// ([ExpressiveAppBarScrollScope]) when null, else at rest.
  final ExpressiveAppBarScroll? scroll;

  /// The search app bar's search bar.
  final ExpressiveSearchBar? search;

  /// Whether this is a two-row (flexible) bar.
  bool get isFlexible => search == null && size != ExpressiveAppBarSize.small;

  /// The route's exit, drawn as the bar's navigation icon when [leading] is
  /// unset: the back arrow (Material's on both platforms) on a pushed page,
  /// close in a sheet or a full-screen dialog, nothing on a root. It pops
  /// the route.
  static Widget? autoLeading(BuildContext context) {
    final localizations = Localizations.of<MaterialLocalizations>(
      context,
      MaterialLocalizations,
    );
    void pop() => Navigator.maybePop(context);
    return switch (RoutePresentation.of(context)) {
      RoutePresentation.root => null,
      RoutePresentation.pushed => ExpressiveIconButton(
        ExpressiveSymbols.arrowBack,
        onPressed: pop,
        semanticLabel:
            localizations?.backButtonTooltip ??
            ExpressiveLocalizations.of(context).back,
      ),
      RoutePresentation.sheet => ExpressiveIconButton(
        ExpressiveSymbols.close,
        onPressed: pop,
        semanticLabel:
            localizations?.closeButtonTooltip ??
            ExpressiveLocalizations.of(context).close,
      ),
    };
  }

  /// The single row's height at [context] (Compose's
  /// `TopAppBarExpandedHeight`, grown for a title that needs more), without
  /// the status bar.
  double collapsedHeightOf(BuildContext context) {
    final resolved = context.expressiveTheme.appBarTheme.merge(style);
    const states = <WidgetState>{};
    final outline = resolved.outline?.resolve(states);
    final side =
        resolved.side?.resolve(states) ??
        BorderSide.none.copyWith(
          color: outline,
          style: outline == null ? null : BorderStyle.solid,
        );
    final shape =
        resolved.shape?.resolve(states) ??
        (resolved.side?.resolve(states) != null || outline != null
            ? context.expressiveTheme.shapes.none
            : null);
    final inset =
        shape
            ?.copyWith(side: side)
            .dimensions
            .resolve(Directionality.of(context)) ??
        EdgeInsets.zero;
    final padding =
        resolved.padding
            ?.resolve(states)
            ?.resolve(Directionality.of(context)) ??
        EdgeInsets.zero;
    return math.max(
      resolved.minimumSize?.resolve(states)?.height ?? 0,
      _rowHeightOf(context) + inset.vertical + padding.vertical,
    );
  }

  double _rowHeightOf(BuildContext context) {
    if (search != null) {
      return search!.heightOf(context) +
          2 * SearchBarBehavior.appBarVerticalPadding;
    }
    return math.max(
      context.expressiveTheme.density.height(
        AppBarSmallTokens.containerHeight,
        floor: 48,
      ),
      _titleBlockHeight(
        context,
        title,
        subtitle,
        AppBarSmallTokens.titleFont,
        AppBarSmallTokens.subtitleFont,
        style: style,
      ),
    );
  }

  /// How far a flexible bar collapses at [context]: its title row's height
  /// (0 for a small or a search bar).
  double collapseRangeOf(BuildContext context) {
    if (!isFlexible) return 0;
    final medium = size == ExpressiveAppBarSize.medium;
    final double expanded = medium
        ? (subtitle == null
              ? AppBarMediumFlexibleTokens.containerHeight
              : AppBarMediumFlexibleTokens.largeContainerHeight)
        : (subtitle == null
              ? AppBarLargeFlexibleTokens.containerHeight
              : AppBarLargeFlexibleTokens.largeContainerHeight);
    return math.max(
      context.expressiveTheme.density.height(expanded) -
          context.expressiveTheme.density.height(
            AppBarSmallTokens.containerHeight,
            floor: 48,
          ),
      _titleBlockHeight(
        context,
        title,
        subtitle,
        medium
            ? AppBarMediumFlexibleTokens.titleFont
            : AppBarLargeFlexibleTokens.titleFont,
        medium
            ? AppBarMediumFlexibleTokens.subtitleFont
            : AppBarLargeFlexibleTokens.subtitleFont,
        style: style,
      ),
    );
  }

  /// Whether a bar at [context] stands in a bottom sheet (not a full-screen
  /// dialog): its container is then the sheet's, and it takes no
  /// status-bar inset.
  static bool inSheet(BuildContext context) {
    if (RoutePresentation.of(context) != RoutePresentation.sheet) return false;
    final route = ModalRoute.of(context);
    return !(route is PageRoute && route.fullscreenDialog);
  }

  /// The status-bar inset a bar at [context] pads itself by.
  static double topInsetOf(BuildContext context) =>
      inSheet(context) ? 0 : MediaQuery.paddingOf(context).top;

  @override
  Widget build(BuildContext context) {
    final scroll =
        this.scroll ??
        ExpressiveAppBarScrollScope.maybeOf(context) ??
        ExpressiveAppBarScroll.rest;
    final theme = context.expressiveTheme;
    final resolved = theme.appBarTheme.merge(style);
    final states = <WidgetState>{
      if (scroll.heightOffset < 0 ||
          scroll.overlappedFraction(collapsedHeightOf(context)) >
              _overlapThreshold)
        WidgetState.scrolledUnder,
    };
    return ExpressiveTheme(
      data: theme.copyWith(appBarTheme: resolved),
      child: ExpressiveStyleScope(
        style: resolved,
        states: states,
        inset: EdgeInsets.zero,
        child: Builder(
          builder: (context) {
            final nav = leading ?? autoLeading(context);
            final search = this.search;
            if (search != null) {
              return _SearchAppBar(
                search: search,
                leading: nav,
                actions: _ActionsRow(actions: actions, overflow: overflow),
                scroll: scroll,
              );
            }
            if (!isFlexible) {
              return _SmallBar(bar: this, leading: nav, scroll: scroll);
            }
            return _FlexibleBar(bar: this, leading: nav, scroll: scroll);
          },
        ),
      ),
    );
  }
}

/// The height a title (and subtitle) block needs at [context]: one line of
/// each, at their styles and the text scale.
double _titleBlockHeight(
  BuildContext context,
  String? title,
  String? subtitle,
  ExpressiveTypeKey titleFont,
  ExpressiveTypeKey subtitleFont, {
  ExpressiveComponentThemeData? style,
}) {
  final type = context.expressiveTheme.type;
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
  double line(String? text, ExpressiveTypeKey font) {
    if (text == null) return 0;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: type
            .of(font)
            .merge(
              context.expressiveTheme.appBarTheme
                  .merge(style)
                  .textStyle
                  ?.resolve(const <WidgetState>{}),
            ),
      ),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }

  return line(title, titleFont) + line(subtitle, subtitleFont);
}

/// The trailing actions: the first two, then the overflow menu's button
/// when anything is left over.
class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.actions, required this.overflow});

  final List<Widget> actions;
  final List<ExpressiveMenuEntry> overflow;

  @override
  Widget build(BuildContext context) {
    final folds = actions.length > 2;
    assert(
      !folds || actions.skip(2).every((a) => a is ExpressiveAppBarAction),
      'a top bar shows two actions; the rest fold into its overflow menu, so '
      'they must be ExpressiveAppBarActions (or pass them as overflow entries)',
    );
    final shown = folds ? actions.take(2) : actions;
    final entries = <ExpressiveMenuEntry>[
      if (folds)
        for (final action in actions.skip(2).cast<ExpressiveAppBarAction>())
          ExpressiveMenuItem(
            action.label,
            icon: action.icon,
            style: action.style,
            onPressed: action.onPressed,
          ),
      ...overflow,
    ];
    final label =
        Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        )?.showMenuTooltip ??
        ExpressiveLocalizations.of(context).moreOptions;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...shown,
        if (entries.isNotEmpty)
          ExpressiveMenu(
            entries: entries,
            label: label,
            builder: (context, menu) => ExpressiveIconButton(
              ExpressiveSymbols.moreVert,
              onPressed: menu.toggle,
              semanticLabel: label,
            ),
          ),
      ],
    );
  }
}

/// The bar's container at rest or [scrolled] under: the app bar theme's
/// container slot (resolved with [WidgetState.scrolledUnder] when
/// [scrolled]) over the token.
Color _barContainer(ExpressiveThemeData t, {required bool scrolled}) =>
    ExpressiveComponentThemeData.resolve(
      t.appBarTheme.backgroundColor,
      <WidgetState>{if (scrolled) WidgetState.scrolledUnder},
      t.colors.role(
        scrolled
            ? AppBarTokens.onScrollContainerColor
            : AppBarTokens.containerColor,
      ),
    );

/// A title, subtitle or icon colour: the app bar theme's content slot over
/// [role].
Color _barContent(BuildContext context, ExpressiveColorRole role) =>
    ExpressiveComponentThemeData.resolve(
      context.expressiveTheme.appBarTheme.foregroundColor,
      ExpressiveStyleScope.maybeOf(context)?.states ?? const <WidgetState>{},
      context.expressiveTheme.colors.role(role),
    );

/// The navigation icon's slot: 4dp in from the start edge, in the leading
/// icon colour (`TopAppBarLayout`'s `navigationIcon` box).
Widget? _navSlot(BuildContext context, Widget? leading) {
  if (leading == null) return null;
  final t = context.expressiveTheme;
  return Padding(
    padding: const EdgeInsetsDirectional.only(
      start: AppBarBehavior.horizontalPadding,
    ),
    child: IconTheme.merge(
      data: IconThemeData(
        color: _barContent(context, AppBarTokens.leadingIconColor),
        size:
            t.appBarTheme.iconSize?.resolve(
              ExpressiveStyleScope.maybeOf(context)?.states ??
                  const <WidgetState>{},
            ) ??
            AppBarTokens.iconSize,
      ),
      child: leading,
    ),
  );
}

/// The actions' slot: 4dp in from the end edge, in the trailing icon colour.
Widget _actionsSlot(BuildContext context, Widget actions) {
  final t = context.expressiveTheme;
  return Padding(
    padding: const EdgeInsetsDirectional.only(
      end: AppBarBehavior.horizontalPadding,
    ),
    child: IconTheme.merge(
      data: IconThemeData(
        color: _barContent(context, AppBarTokens.trailingIconColor),
        size:
            t.appBarTheme.iconSize?.resolve(
              ExpressiveStyleScope.maybeOf(context)?.states ??
                  const <WidgetState>{},
            ) ??
            AppBarTokens.iconSize,
      ),
      child: actions,
    ),
  );
}

/// The bar's container: its colour behind everything, a traversal group.
Widget _container(BuildContext context, Color color, Widget child) {
  final theme = context.expressiveTheme;
  final resolved = theme.appBarTheme;
  return Semantics(
    container: true,
    explicitChildNodes: true,
    child: ExpressiveSurface(
      color: color,
      shape: theme.shapes.none,
      states:
          ExpressiveStyleScope.maybeOf(context)?.states ??
          const <WidgetState>{},
      style: ExpressiveComponentThemeData(
        shape: resolved.shape,
        side: resolved.side,
        outline: resolved.outline,
        overlayColor: resolved.overlayColor,
        padding: resolved.padding,
        minimumSize: resolved.minimumSize,
        textStyle: resolved.textStyle,
        iconSize: resolved.iconSize,
      ),
      child: child,
    ),
  );
}

/// One row's title and subtitle lines, at [alpha], their semantics hidden
/// when [hideSemantics] (a two-row bar announces one title at a time).
({Widget? title, Widget? subtitle}) _titles(
  BuildContext context, {
  required String? title,
  required String? subtitle,
  required ExpressiveTypeKey titleFont,
  required ExpressiveTypeKey subtitleFont,
  required bool centered,
  double alpha = 1,
  bool hideSemantics = false,
}) {
  final t = context.expressiveTheme;
  final align = centered ? TextAlign.center : TextAlign.start;
  Widget line(String text, ExpressiveTypeKey font, Color color, bool header) {
    Widget result = Opacity(
      opacity: alpha.clamp(0.0, 1.0),
      child: Text(
        text,
        style: t.type
            .of(font)
            .merge(
              t.appBarTheme.textStyle?.resolve(
                ExpressiveStyleScope.maybeOf(context)?.states ??
                    const <WidgetState>{},
              ),
            )
            .copyWith(color: color),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
      ),
    );
    result = hideSemantics
        ? ExcludeSemantics(child: result)
        : Semantics(header: header, child: result);
    return result;
  }

  return (
    title: title == null
        ? null
        : line(
            title,
            titleFont,
            _barContent(context, AppBarTokens.titleColor),
            true,
          ),
    subtitle: subtitle == null
        ? null
        : line(
            subtitle,
            subtitleFont,
            _barContent(context, AppBarTokens.subtitleColor),
            false,
          ),
  );
}

/// Compose's `SingleRowTopAppBar`: one row, its container springing to the
/// scrolled colour when content passes under it.
class _SmallBar extends StatelessWidget {
  const _SmallBar({
    required this.bar,
    required this.leading,
    required this.scroll,
  });

  final ExpressiveAppBar bar;
  final Widget? leading;
  final ExpressiveAppBarScroll scroll;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final sheet = ExpressiveAppBar.inSheet(context);
    final padding = MediaQuery.paddingOf(context);
    final filled =
        scroll.overlappedFraction(bar.collapsedHeightOf(context)) >
        _overlapThreshold;
    final rest = _barContainer(t, scrolled: false);
    final target = filled
        ? _barContainer(t, scrolled: true)
        : sheet || scroll.overlay
        ? rest.withValues(alpha: 0)
        : rest;
    final titles = _titles(
      context,
      title: bar.title,
      subtitle: bar.subtitle,
      titleFont: AppBarSmallTokens.titleFont,
      subtitleFont: AppBarSmallTokens.subtitleFont,
      centered: bar.centered,
    );
    return ExpressiveSpringColor(
      value: target,
      motion: AppBarBehavior.containerColorMotion,
      builder: (context, color, child) => _container(context, color, child!),
      child: Padding(
        padding: EdgeInsets.only(
          top: sheet ? 0 : padding.top,
          left: padding.left,
          right: padding.right,
        ),
        child: ClipRect(
          child: _TopAppBarLayout(
            height: bar._rowHeightOf(context),
            heightOffset: 0,
            bottomAligned: false,
            centered: bar.centered,
            titleBottomPadding: 0,
            navigationIcon: _navSlot(context, leading),
            title: titles.title,
            subtitle: titles.subtitle,
            actions: _actionsSlot(
              context,
              _ActionsRow(actions: bar.actions, overflow: bar.overflow),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compose's `TwoRowsTopAppBar` for the medium and large flexible bars: the
/// small row (its title fading in as the bar collapses) over the title row,
/// which shrinks by the height offset, its title fading out. The container
/// fills with the collapsed fraction.
class _FlexibleBar extends StatelessWidget {
  const _FlexibleBar({
    required this.bar,
    required this.leading,
    required this.scroll,
  });

  final ExpressiveAppBar bar;
  final Widget? leading;
  final ExpressiveAppBarScroll scroll;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final sheet = ExpressiveAppBar.inSheet(context);
    final padding = MediaQuery.paddingOf(context);
    final medium = bar.size == ExpressiveAppBarSize.medium;
    final range = bar.collapseRangeOf(context);
    final heightOffset = math.max(scroll.heightOffset, -range);
    final fraction = range == 0 ? 0.0 : (heightOffset / -range).clamp(0.0, 1.0);
    final rest = _barContainer(t, scrolled: false);
    final scrolled = _barContainer(t, scrolled: true);
    // Over a full-bleed body the bar is clear at rest and fills, on the
    // colour spring, once content passes under its small row.
    final overlaid =
        scroll.overlay &&
        scroll.overlappedFraction(bar.collapsedHeightOf(context)) >
            _overlapThreshold;
    final color = overlaid
        ? scrolled
        : Color.lerp(
            sheet || scroll.overlay ? rest.withValues(alpha: 0) : rest,
            scrolled,
            _fastOutLinearIn.transform(fraction),
          )!;
    final hideTopSemantics = fraction < 0.5;
    final small = _titles(
      context,
      title: bar.title,
      subtitle: bar.subtitle,
      titleFont: AppBarSmallTokens.titleFont,
      subtitleFont: AppBarSmallTokens.subtitleFont,
      centered: bar.centered,
      alpha: _topTitleAlphaEasing.transform(fraction),
      hideSemantics: hideTopSemantics,
    );
    final large = _titles(
      context,
      title: bar.title,
      subtitle: bar.subtitle,
      titleFont: medium
          ? AppBarMediumFlexibleTokens.titleFont
          : AppBarLargeFlexibleTokens.titleFont,
      subtitleFont: medium
          ? AppBarMediumFlexibleTokens.subtitleFont
          : AppBarLargeFlexibleTokens.subtitleFont,
      centered: bar.centered,
      alpha: 1 - fraction,
      hideSemantics: !hideTopSemantics,
    );
    final Widget body = Padding(
      padding: EdgeInsets.only(left: padding.left, right: padding.right),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: sheet ? 0 : padding.top),
            child: ClipRect(
              child: _TopAppBarLayout(
                height: bar._rowHeightOf(context),
                heightOffset: 0,
                bottomAligned: false,
                centered: bar.centered,
                titleBottomPadding: 0,
                navigationIcon: _navSlot(context, leading),
                title: small.title,
                subtitle: small.subtitle,
                actions: _actionsSlot(
                  context,
                  _ActionsRow(actions: bar.actions, overflow: bar.overflow),
                ),
              ),
            ),
          ),
          ClipRect(
            child: _TopAppBarLayout(
              height: range,
              heightOffset: heightOffset,
              bottomAligned: true,
              centered: bar.centered,
              titleBottomPadding: medium
                  ? AppBarBehavior.mediumTitleBottomPadding
                  : AppBarBehavior.largeTitleBottomPadding,
              title: large.title,
              subtitle: large.subtitle,
            ),
          ),
        ],
      ),
    );
    if (!scroll.overlay) return _container(context, color, body);
    return ExpressiveSpringColor(
      value: color,
      motion: AppBarBehavior.containerColorMotion,
      builder: (context, color, child) => _container(context, color, child!),
      child: body,
    );
  }
}

// ---------------------------------------------------------------------------
// TopAppBarLayout.

enum _BarSlot { navigationIcon, title, subtitle, actions }

/// Compose's `TopAppBarLayout` and `TopAppBarMeasurePolicy`: the navigation
/// icon at the start and the actions at the end, centred vertically; the
/// title block (title over subtitle, 4dp either side) after at least
/// `TopAppBarTitleInset` or the navigation icon, aligned to the start or
/// centred on the whole width and pushed clear of both ends, centred
/// vertically or set on the bottom by its last baseline. The row is
/// [height] tall (or the title block's height, if more) plus [heightOffset]
/// (≤ 0).
class _TopAppBarLayout
    extends SlottedMultiChildRenderObjectWidget<_BarSlot, RenderBox> {
  const _TopAppBarLayout({
    required this.height,
    required this.heightOffset,
    required this.bottomAligned,
    required this.centered,
    required this.titleBottomPadding,
    this.navigationIcon,
    this.title,
    this.subtitle,
    this.actions,
  });

  final double height;
  final double heightOffset;
  final bool bottomAligned;
  final bool centered;
  final double titleBottomPadding;
  final Widget? navigationIcon;
  final Widget? title;
  final Widget? subtitle;
  final Widget? actions;

  @override
  Iterable<_BarSlot> get slots => _BarSlot.values;

  @override
  Widget? childForSlot(_BarSlot slot) => switch (slot) {
    _BarSlot.navigationIcon => navigationIcon,
    _BarSlot.title => title,
    _BarSlot.subtitle => subtitle,
    _BarSlot.actions => actions,
  };

  @override
  _RenderTopAppBarLayout createRenderObject(BuildContext context) =>
      _RenderTopAppBarLayout(
        height: height,
        heightOffset: heightOffset,
        bottomAligned: bottomAligned,
        centered: centered,
        titleBottomPadding: titleBottomPadding,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTopAppBarLayout renderObject,
  ) {
    renderObject
      ..height = height
      ..heightOffset = heightOffset
      ..bottomAligned = bottomAligned
      ..centered = centered
      ..titleBottomPadding = titleBottomPadding
      ..textDirection = Directionality.of(context);
  }
}

class _RenderTopAppBarLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<_BarSlot, RenderBox> {
  _RenderTopAppBarLayout({
    required this._height,
    required this._heightOffset,
    required this._bottomAligned,
    required this._centered,
    required this._titleBottomPadding,
    required this._textDirection,
  });

  double _height;
  set height(double value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  double _heightOffset;
  set heightOffset(double value) {
    if (value == _heightOffset) return;
    _heightOffset = value;
    markNeedsLayout();
  }

  bool _bottomAligned;
  set bottomAligned(bool value) {
    if (value == _bottomAligned) return;
    _bottomAligned = value;
    markNeedsLayout();
  }

  bool _centered;
  set centered(bool value) {
    if (value == _centered) return;
    _centered = value;
    markNeedsLayout();
  }

  double _titleBottomPadding;
  set titleBottomPadding(double value) {
    if (value == _titleBottomPadding) return;
    _titleBottomPadding = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox? get _nav => childForSlot(_BarSlot.navigationIcon);
  RenderBox? get _title => childForSlot(_BarSlot.title);
  RenderBox? get _subtitle => childForSlot(_BarSlot.subtitle);
  RenderBox? get _actions => childForSlot(_BarSlot.actions);

  /// The children in paint order.
  List<RenderBox> get _ordered => <RenderBox>[
    ?_nav,
    ?_title,
    ?_subtitle,
    ?_actions,
  ];

  static const double _pad = AppBarBehavior.horizontalPadding;

  /// `TopAppBarTitleInset`: 16dp less the title box's own padding.
  static const double _titleInset = AppBarBehavior.titleStart - _pad;

  /// The row's natural height for a title block [block] tall
  /// (`maxLayoutHeight`), and its height at the offset.
  (double, double) _heights(double block) {
    final maxLayout = math.max(_height, block);
    return (maxLayout, math.max(0.0, maxLayout + _heightOffset));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final loose = BoxConstraints(maxWidth: constraints.maxWidth);
    final block =
        (_title?.getDryLayout(loose).height ?? 0) +
        (_subtitle?.getDryLayout(loose).height ?? 0);
    return constraints.constrain(
      Size(constraints.maxWidth, _heights(block).$2),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) => math.max(0.0, _height);

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(0.0, _height);

  @override
  void performLayout() {
    final maxWidth = constraints.maxWidth;
    final loose = BoxConstraints(maxWidth: maxWidth);
    final nav = _nav;
    final actions = _actions;
    nav?.layout(loose, parentUsesSize: true);
    actions?.layout(loose, parentUsesSize: true);
    final navWidth = nav?.size.width ?? 0.0;
    final actionsWidth = actions?.size.width ?? 0.0;
    final titleStartSpace = math.max(_titleInset, navWidth);
    final maxTitleWidth = math.max(
      0.0,
      maxWidth - titleStartSpace - actionsWidth,
    );
    // The title box carries 4dp either side of its lines.
    final lines = BoxConstraints(
      maxWidth: math.max(0.0, maxTitleWidth - 2 * _pad),
    );
    final title = _title;
    final subtitle = _subtitle;
    title?.layout(lines, parentUsesSize: true);
    subtitle?.layout(lines, parentUsesSize: true);
    final titleHeight = title?.size.height ?? 0.0;
    final subtitleHeight = subtitle?.size.height ?? 0.0;
    final boxWidth =
        math.max(title?.size.width ?? 0.0, subtitle?.size.width ?? 0.0) +
        2 * _pad;
    final boxHeight = titleHeight + subtitleHeight;
    // The block's last baseline (Compose's `LastBaseline`).
    var baseline = 0.0;
    if (subtitle != null) {
      baseline =
          titleHeight +
          (subtitle.getDistanceToBaseline(TextBaseline.alphabetic) ??
              subtitleHeight);
    } else if (title != null) {
      baseline =
          title.getDistanceToBaseline(TextBaseline.alphabetic) ?? titleHeight;
    }

    final (maxLayoutHeight, layoutHeight) = _heights(boxHeight);
    size = constraints.constrain(Size(maxWidth, layoutHeight));
    final contentHeight = layoutHeight;

    double placeX(double x, double width) =>
        _textDirection == TextDirection.rtl ? maxWidth - x - width : x;
    void place(RenderBox child, double x, double y) =>
        (child.parentData! as BoxParentData).offset = Offset(
          placeX(x, child.size.width),
          y,
        );

    if (nav != null) place(nav, 0, (contentHeight - nav.size.height) / 2);

    // Align on the whole width, then push clear of the start and the end.
    final end = actionsWidth;
    var titleX = _centered ? (maxWidth - boxWidth) / 2 : 0.0;
    if (titleX < titleStartSpace) {
      titleX += titleStartSpace - titleX;
    } else if (titleX + boxWidth > maxWidth - end) {
      titleX += (maxWidth - end) - (titleX + boxWidth);
    }
    final double titleY;
    if (!_bottomAligned) {
      titleY = (contentHeight - boxHeight) / 2;
    } else if (_titleBottomPadding == 0) {
      titleY = contentHeight - boxHeight;
    } else {
      final paddingFromBottom = _titleBottomPadding - (boxHeight - baseline);
      final heightWithPadding = paddingFromBottom + boxHeight;
      final adjusted = heightWithPadding > maxLayoutHeight
          ? paddingFromBottom - (heightWithPadding - maxLayoutHeight)
          : paddingFromBottom;
      titleY = contentHeight - boxHeight - math.max(0.0, adjusted);
    }
    double lineX(RenderBox line) {
      final inner = boxWidth - 2 * _pad;
      final within = _centered ? (inner - line.size.width) / 2 : 0.0;
      return titleX + _pad + within;
    }

    if (title != null) place(title, lineX(title), titleY);
    if (subtitle != null) {
      place(subtitle, lineX(subtitle), titleY + titleHeight);
    }
    if (actions != null) {
      place(
        actions,
        maxWidth - actionsWidth,
        (contentHeight - actions.size.height) / 2,
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in _ordered) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in _ordered.reversed) {
      final hit = result.addWithPaintOffset(
        offset: (child.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// The search app bar.

/// Compose's `AppBarWithSearch`: the navigation icon, the search bar (8dp
/// either side, 4dp above and below, centred in the space left) and the
/// actions. The bar's container springs to the scrolled colour, and the
/// search bar's to `surfaceContainerHighest`, when content passes under it.
class _SearchAppBar extends StatelessWidget {
  const _SearchAppBar({
    required this.search,
    required this.leading,
    required this.actions,
    required this.scroll,
  });

  final ExpressiveSearchBar search;
  final Widget? leading;
  final Widget actions;
  final ExpressiveAppBarScroll scroll;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final sheet = ExpressiveAppBar.inSheet(context);
    final padding = MediaQuery.paddingOf(context);
    final height =
        search.heightOf(context) + 2 * SearchBarBehavior.appBarVerticalPadding;
    final filled = scroll.overlappedFraction(height) > _overlapThreshold;
    final rest = _barContainer(t, scrolled: false);
    final target = filled
        ? _barContainer(t, scrolled: true)
        : sheet || scroll.overlay
        ? rest.withValues(alpha: 0)
        : rest;
    final nav = leading;
    return ExpressiveSpringColor(
      value: target,
      motion: AppBarBehavior.containerColorMotion,
      builder: (context, color, child) => _container(context, color, child!),
      child: Padding(
        padding: EdgeInsets.only(
          top: sheet ? 0 : padding.top,
          left: padding.left,
          right: padding.right,
        ),
        child: SizedBox(
          height: height,
          child: Row(
            children: <Widget>[
              if (nav != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: SearchBarBehavior.appBarHorizontalPadding,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: _barContent(
                        context,
                        AppBarTokens.leadingIconColor,
                      ),
                      size:
                          t.appBarTheme.iconSize?.resolve(
                            ExpressiveStyleScope.maybeOf(context)?.states ??
                                const <WidgetState>{},
                          ) ??
                          AppBarTokens.iconSize,
                    ),
                    child: nav,
                  ),
                ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SearchBarBehavior.asTopBarPadding,
                      vertical: SearchBarBehavior.appBarVerticalPadding,
                    ),
                    child: _InAppBar(scrolled: filled, child: search),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: SearchBarBehavior.appBarHorizontalPadding,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(
                    color: _barContent(context, AppBarTokens.trailingIconColor),
                    size:
                        t.appBarTheme.iconSize?.resolve(
                          ExpressiveStyleScope.maybeOf(context)?.states ??
                              const <WidgetState>{},
                        ) ??
                        AppBarTokens.iconSize,
                  ),
                  child: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tells a search bar it stands in a search app bar, and whether content
/// has scrolled under the bar (its container is then
/// `surfaceContainerHighest`).
class _InAppBar extends InheritedWidget {
  const _InAppBar({required this.scrolled, required super.child});

  final bool scrolled;

  static _InAppBar? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InAppBar>();

  @override
  bool updateShouldNotify(_InAppBar oldWidget) =>
      scrolled != oldWidget.scrolled;
}

// ---------------------------------------------------------------------------
// Search.

/// What the search view shows under its field for the live query.
typedef ExpressiveSearchResultsBuilder = Widget Function(
  BuildContext context,
  String query,
);

/// The search bar (Compose's `SearchBar` with its `InputField`): a 56dp
/// pill on `surfaceContainerHigh` — the search glyph (or [leading]), the
/// query or [placeholder], [trailing] icons and an [avatar] — that opens
/// the full-screen search view when tapped. The view (Compose's
/// `ExpandedFullScreenSearchBar`, or with [contained] its
/// `ExpandedFullScreenContainedSearchBar`) grows out of the bar: the field
/// with a back arrow and a clear control, the [filters] chips under it, and
/// [results] for the live query. The back arrow and the system back
/// (predictive on Android) collapse it.
///
/// Standing alone it fills the width it is given (up to 720dp); in a search
/// app bar ([ExpressiveAppBar.search]) it is Compose's 360dp where there is
/// room.
///
/// ```dart
/// ExpressiveSearchBar(hintText: 'Search recipes', avatar: ExpressiveAvatar(name: 'Ana Ruiz'), filters: [ExpressiveChip('Vegetarian', selected: veg, onPressed: toggleVeg)], results: (context, query) => recipeResults(query))
/// ```
class ExpressiveSearchBar extends StatefulWidget {
  /// A search bar that opens into a full-screen search showing [results].
  const ExpressiveSearchBar({
    this.style,
    this.controller,
    this.hintText,
    this.leading,
    this.trailing = const <Widget>[],
    this.avatar,
    this.onAvatarTap,
    this.avatarLabel,
    this.filters = const <Widget>[],
    this.results,
    this.contained = false,
    this.onChanged,
    this.onSubmitted,
    this.onOpen,
    this.onClose,
    super.key,
  });

  /// Stateful visual overrides for the search input and its open view.
  final ExpressiveComponentThemeData? style;

  /// The input's height, including its outline inset and requested padding.
  double heightOf(BuildContext context) {
    final theme = context.expressiveTheme;
    final resolved = theme.searchTheme.merge(style);
    const states = <WidgetState>{};
    final shape =
        resolved.shape?.resolve(states) ??
        (resolved.side?.resolve(states) != null ||
                resolved.outline?.resolve(states) != null
            ? theme.shapes.of(SearchBarTokens.containerShape)
            : null);
    final side =
        resolved.side?.resolve(states) ??
        BorderSide.none.copyWith(color: resolved.outline?.resolve(states));
    final inset =
        shape
            ?.copyWith(side: side)
            .dimensions
            .resolve(Directionality.of(context)) ??
        EdgeInsets.zero;
    final padding =
        resolved.padding
            ?.resolve(states)
            ?.resolve(Directionality.of(context)) ??
        EdgeInsets.zero;
    return math.max(
      resolved.minimumSize?.resolve(states)?.height ?? 0,
      _searchRowHeight(context, resolved, states) +
          inset.vertical +
          padding.vertical,
    );
  }

  /// The query's text; one is made when null.
  final TextEditingController? controller;

  /// What the empty field says (the strings' `search` when null).
  final String? hintText;

  /// The leading icon; the search glyph when null.
  final Widget? leading;

  /// Trailing icon buttons (a microphone, a filter).
  final List<Widget> trailing;

  /// The account avatar at the end (a 30dp circle).
  final Widget? avatar;

  /// What a tap on the avatar does.
  final VoidCallback? onAvatarTap;

  /// What the avatar is called to assistive technology.
  final String? avatarLabel;

  /// Filter chips under the view's field.
  final List<Widget> filters;

  /// The view's content for the live query.
  final ExpressiveSearchResultsBuilder? results;

  /// Whether the view keeps the field's pill on a `surfaceContainerLow`
  /// page (contained), rather than growing the bar into a full-screen
  /// `surfaceContainerHigh` field over a divider.
  final bool contained;

  /// Told as the query changes.
  final ValueChanged<String>? onChanged;

  /// Told when the keyboard's search action submits the query.
  final ValueChanged<String>? onSubmitted;

  /// Told when the view opens.
  final VoidCallback? onOpen;

  /// Told when the view has closed.
  final VoidCallback? onClose;

  @override
  State<ExpressiveSearchBar> createState() => ExpressiveSearchBarState();
}

/// The state of an [ExpressiveSearchBar]: opens and closes its view.
class ExpressiveSearchBarState extends State<ExpressiveSearchBar> {
  TextEditingController? _owned;
  TextEditingController get _query =>
      widget.controller ?? (_owned ??= TextEditingController());

  _SearchViewRoute? _route;

  /// The bar as it is now, for the open view (its filters and results
  /// follow the app's state).
  late final ValueNotifier<ExpressiveSearchBar> _current =
      ValueNotifier<ExpressiveSearchBar>(widget);

  /// Whether the view is open.
  bool get isOpen => _route != null;

  @override
  void didUpdateWidget(ExpressiveSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The view, open or still collapsing after its pop, is another route,
    // not below this bar: telling it while a frame builds would mark it
    // dirty out of order, so then it hears after the frame. [open] hands
    // it the bar as it is when it opens.
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      _current.value = widget;
      return;
    }
    scheduler.addPostFrameCallback((_) {
      if (mounted) _current.value = widget;
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _owned?.dispose();
    super.dispose();
  }

  /// Opens the search view over the app; completes when it has closed.
  Future<void> open() async {
    if (_route != null) return;
    _current.value = widget;
    final box = context.findRenderObject() as RenderBox?;
    final rect = box == null || !box.hasSize
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = _SearchViewRoute(
      bar: _current,
      query: _query,
      collapsed: rect,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      expand: ExpressiveMotion.of(context)
          .spring(SearchBarBehavior.expandMotion),
      collapse: ExpressiveMotion.of(context)
          .spring(SearchBarBehavior.collapseMotion),
      platform: Theme.of(context).platform,
    );
    setState(() => _route = route);
    widget.onOpen?.call();
    await navigator.push(route);
    if (!mounted) return;
    setState(() => _route = null);
    widget.onClose?.call();
  }

  /// Closes the search view.
  void close() {
    final route = _route;
    if (route == null || !route.isActive) return;
    if (route.isCurrent) {
      route.navigator?.pop();
    } else {
      route.navigator?.removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final inAppBar = _InAppBar.maybeOf(context);
    final color = inAppBar?.scrolled ?? false
        ? t.colors.surfaceContainerHighest
        : t.colors.role(SearchBarTokens.containerColor);
    return LayoutBuilder(
      builder: (context, constraints) {
        // In a search app bar, `sizeIn(360.dp, 720.dp)` in the space given;
        // standing alone, the width given up to 720dp.
        final available = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : SearchBarBehavior.minWidth;
        final width = inAppBar != null
            ? math.min(available, SearchBarBehavior.minWidth)
            : math.min(available, SearchBarBehavior.maxWidth);
        return Opacity(
          // The view draws the field while it is open (Compose hides the
          // collapsed bar under a full-screen view).
          opacity: _route != null ? 0 : 1,
          child: SizedBox(
            width: width,
            child: ListenableBuilder(
              listenable: _query,
              // A faint pill on the page: marked, so the keyline and label
              // checks take the bar as one item at its face.
              builder: (context, _) => DesignKeylineFace(
                child: _CollapsedSearchBar(
                  bar: widget,
                  query: _query.text,
                  color: color,
                  onTap: open,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The collapsed bar: a pill-shaped pressable holding the input field's
/// layout (leading icon, text, trailing icons, avatar).
class _CollapsedSearchBar extends StatelessWidget {
  const _CollapsedSearchBar({
    required this.bar,
    required this.query,
    required this.color,
    required this.onTap,
  });

  final ExpressiveSearchBar bar;
  final String query;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final hasQuery = query.isNotEmpty;
    return ExpressivePressable(
      style: bar.style,
      componentStyle: t.searchTheme,
      shapes: ExpressivePressShapes.all(
        t.shapes.of(SearchBarTokens.containerShape),
      ),
      motion: ExpressiveMotionKey.fastSpatial,
      color: color,
      contentColor: t.colors.role(SearchBarTokens.inputTextColor),
      // `SearchBarDefaults.TonalElevation` and `ShadowElevation` are Level0
      // (the token's level3 is the pre-Expressive bar's).
      onPressed: onTap,
      semanticLabel: hasQuery
          ? query
          : bar.hintText ?? ExpressiveLocalizations.of(context).search,
      child: ExpressiveStyledContent(
        center: false,
        child: Builder(
          builder: (context) {
            final scope = ExpressiveStyleScope.maybeOf(context)!;
            final styled = scope.style;
            final states = scope.states;
            return _SearchFieldRow(
              hideDecorativeLeadingWhenNarrow: bar.leading == null,
              leading:
                  bar.leading ??
                  ExpressiveIcon(
                    ExpressiveSymbols.search,
                    color:
                        styled.foregroundColor?.resolve(states) ??
                        t.colors.role(SearchBarTokens.leadingIconColor),
                  ),
              // The bar's words on its pill's middle, by their capitals
              // (the editable field's are not: its hint and typed text share
              // the line the input lays out, so typing never moves them).
              text: expressiveFaceLabel(
                Text(
                  hasQuery
                      ? query
                      : bar.hintText ??
                            ExpressiveLocalizations.of(context).search,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: t.type
                      .of(SearchBarTokens.inputTextFont)
                      .copyWith(
                        color: hasQuery
                            ? t.colors.role(SearchBarTokens.inputTextColor)
                            : t.colors.role(
                                SearchBarTokens.supportingTextColor,
                              ),
                      )
                      .merge(styled.textStyle?.resolve(states))
                      .copyWith(color: styled.foregroundColor?.resolve(states)),
                ),
              ),
              trailing: <Widget>[
                ...bar.trailing,
                if (bar.avatar != null)
                  _SearchAvatar(
                    avatar: bar.avatar!,
                    onTap: bar.onAvatarTap,
                    label: bar.avatarLabel,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The avatar at the end of a search bar: a 30dp circle in a 48dp target.
class _SearchAvatar extends StatelessWidget {
  const _SearchAvatar({required this.avatar, this.onTap, this.label});

  final Widget avatar;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    const shape = CircleBorder();
    final circle = SizedBox.square(
      dimension: SearchBarTokens.avatarSize,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: FittedBox(fit: BoxFit.cover, child: avatar),
      ),
    );
    final onTap = this.onTap;
    return SizedBox.square(
      dimension: HostBehavior.minimumInteractiveComponentSize,
      child: Center(
        child: onTap == null
            ? Semantics(label: label, image: true, child: circle)
            : ExpressivePressable(
                shapes: ExpressivePressShapes.all(shape),
                motion: ExpressiveMotionKey.fastSpatial,
                color: t.colors
                    .role(SearchBarTokens.containerColor)
                    .withValues(alpha: 0),
                contentColor: t.colors.role(SearchBarTokens.trailingIconColor),
                onPressed: onTap,
                semanticLabel: label,
                child: circle,
              ),
      ),
    );
  }
}

/// The input field's row (`TextFieldDefaults.decorator` without a label):
/// a 48dp leading slot moved 4dp in, the text 4dp after it (16dp from the
/// edge without it), and the trailing slot moved 4dp in.
class _SearchFieldRow extends StatelessWidget {
  const _SearchFieldRow({
    required this.text,
    this.leading,
    this.hideDecorativeLeadingWhenNarrow = false,
    this.trailing = const <Widget>[],
  });

  final Widget? leading;
  final bool hideDecorativeLeadingWhenNarrow;
  final Widget text;
  final List<Widget> trailing;

  /// `textFieldHorizontalIconPadding`: the 24dp icon inside its 48dp slot.
  static const double _iconPadding =
      (HostBehavior.minimumInteractiveComponentSize -
          FilledTextFieldTokens.leadingIconSize) /
      2;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    const pad = TextFieldBehavior.padding;
    final scope = ExpressiveStyleScope.maybeOf(context);
    final style = scope?.style ?? t.searchTheme;
    final states = scope?.states ?? const <WidgetState>{};
    return LayoutBuilder(
      builder: (context, constraints) {
        final leading =
            hideDecorativeLeadingWhenNarrow &&
                trailing.isNotEmpty &&
                constraints.maxWidth < 160
            ? null
            : this.leading;
        return SizedBox(
          height: _searchRowHeight(context, style, states),
          child: Row(
            children: <Widget>[
              if (leading != null)
                Transform.translate(
                  offset: Offset(
                    rtl
                        ? -SearchBarBehavior.iconOffsetX
                        : SearchBarBehavior.iconOffsetX,
                    0,
                  ),
                  child: SizedBox.square(
                    dimension: HostBehavior.minimumInteractiveComponentSize,
                    child: Center(
                      child: IconTheme.merge(
                        data: IconThemeData(
                          color:
                              style.foregroundColor?.resolve(states) ??
                              t.colors.role(SearchBarTokens.leadingIconColor),
                          size:
                              style.iconSize?.resolve(states) ??
                              FilledTextFieldTokens.leadingIconSize,
                        ),
                        child: leading,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: leading != null ? pad - _iconPadding : pad,
                    end: trailing.isNotEmpty ? pad - _iconPadding : pad,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: text,
                  ),
                ),
              ),
              if (trailing.isNotEmpty)
                Transform.translate(
                  offset: Offset(
                    rtl
                        ? SearchBarBehavior.iconOffsetX
                        : -SearchBarBehavior.iconOffsetX,
                    0,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color:
                          style.foregroundColor?.resolve(states) ??
                          t.colors.role(SearchBarTokens.trailingIconColor),
                      size:
                          style.iconSize?.resolve(states) ??
                          FilledTextFieldTokens.trailingIconSize,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: trailing,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The search input field (Compose's `SearchBarDefaults.InputField`): a
/// 56dp pill on `surfaceContainerHigh` that edits the query — a leading
/// search glyph ([leading]), [placeholder], a clear control ([clearable],
/// "Clear search": empties the query and keeps focus), [trailing] icons —
/// and, with [onCancel], a leading back arrow ("Cancel search": empties
/// the query, lets go of focus and tells [onCancel]). It is the search
/// view's field; on its own it is an inline search (a toolbar's, a list's).
///
/// ```dart
/// ExpressiveSearchField(hintText: 'Search messages', onChanged: filter, onCancel: endSearch)
/// ```
class ExpressiveSearchField extends StatefulWidget {
  /// A search field for a typed query, with a clear button when [clearable].
  const ExpressiveSearchField({
    this.style,
    this.controller,
    this.focusNode,
    this.hintText,
    this.leading,
    this.trailing = const <Widget>[],
    this.clearable = true,
    this.onChanged,
    this.onSubmitted,
    this.onCancel,
    this.autofocus = false,
    super.key,
  }) : _bare = false;

  /// The field as the full-screen view draws it: autofocused, and with no
  /// container of its own when [_bare].
  const ExpressiveSearchField._view({
    required this.style,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.trailing,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCancel,
    required this._bare,
  }) : leading = null,
       clearable = true,
       autofocus = true;

  /// Stateful visual overrides for the input.
  final ExpressiveComponentThemeData? style;

  /// The query's text; one is made when null.
  final TextEditingController? controller;

  /// The field's focus; one is made when null.
  final FocusNode? focusNode;

  /// What the empty field says (the strings' `search` when null).
  final String? hintText;

  /// The leading icon; the search glyph when null (the back arrow with
  /// [onCancel]).
  final Widget? leading;

  /// Trailing icon buttons, after the clear control.
  final List<Widget> trailing;

  /// Whether a clear control shows while there is a query.
  final bool clearable;

  /// Told as the query changes.
  final ValueChanged<String>? onChanged;

  /// Told when the keyboard's search action submits the query.
  final ValueChanged<String>? onSubmitted;

  /// With it, the leading slot is a back arrow that cancels the search.
  final VoidCallback? onCancel;

  /// Whether to take focus when first built.
  final bool autofocus;

  final bool _bare;

  @override
  State<ExpressiveSearchField> createState() => _ExpressiveSearchFieldState();
}

class _ExpressiveSearchFieldState extends State<ExpressiveSearchField> {
  bool _hovered = false;
  TextEditingController? _ownedController;
  FocusNode? _ownedFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownedFocus ??= FocusNode());

  @override
  void dispose() {
    _ownedController?.dispose();
    _ownedFocus?.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    _focus.requestFocus();
  }

  void _cancel() {
    if (_controller.text.isNotEmpty) {
      _controller.clear();
      widget.onChanged?.call('');
    }
    _focus.unfocus();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _focus,
    builder: (context, _) => _buildField(context),
  );

  Widget _buildField(BuildContext context) {
    final t = context.expressiveTheme;
    final states = <WidgetState>{
      if (_focus.hasFocus) WidgetState.focused,
      if (_hovered) WidgetState.hovered,
    };
    final resolved = t.searchTheme.merge(widget.style);
    final localizations = Localizations.of<MaterialLocalizations>(
      context,
      MaterialLocalizations,
    );
    final style = t.type
        .of(SearchBarTokens.inputTextFont)
        .copyWith(color: t.colors.role(SearchBarTokens.inputTextColor))
        .merge(resolved.textStyle?.resolve(states))
        .copyWith(color: resolved.foregroundColor?.resolve(states));
    final Widget leading = widget.onCancel != null
        ? ExpressiveIconButton(
            ExpressiveSymbols.arrowBack,
            onPressed: _cancel,
            semanticLabel: ExpressiveLocalizations.of(context).cancelSearch,
          )
        : widget.leading ??
              ExpressiveIcon(
                ExpressiveSymbols.search,
                color:
                    resolved.foregroundColor?.resolve(states) ??
                    t.colors.role(SearchBarTokens.leadingIconColor),
              );
    final field = ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final hasQuery = _controller.text.isNotEmpty;
        return _SearchFieldRow(
          hideDecorativeLeadingWhenNarrow:
              widget.onCancel == null && widget.leading == null,
          leading: leading,
          // The input's node is the field's whole height, as Compose's
          // decorated `BasicTextField` is: the line is centred in it.
          text: Semantics(
            label:
                localizations?.searchFieldLabel ??
                ExpressiveLocalizations.of(context).search,
            hint: widget.hintText ?? ExpressiveLocalizations.of(context).search,
            child: SizedBox(
              height: _searchRowHeight(context, resolved, states),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                // The words by their capitals on the field's middle: the
                // shift is the entry's, so the hint, the typed text and the
                // caret share it.
                child: expressiveFaceLabel(
                  Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: <Widget>[
                      if (!hasQuery)
                        ExcludeSemantics(
                          child: Text(
                            widget.hintText ??
                                ExpressiveLocalizations.of(context).search,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: style.copyWith(
                              color:
                                  resolved.foregroundColor?.resolve(states) ??
                                  t.colors.role(
                                    SearchBarTokens.supportingTextColor,
                                  ),
                            ),
                          ),
                        ),
                      Material(
                        type: MaterialType.transparency,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focus,
                          decoration: null,
                          style: style,
                          cursorColor: t.colors.role(
                            FilledTextFieldTokens.caretColor,
                          ),
                          maxLines: 1,
                          textInputAction: TextInputAction.search,
                          autofocus: widget.autofocus,
                          onChanged: widget.onChanged,
                          onSubmitted: widget.onSubmitted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          trailing: <Widget>[
            if (widget.clearable && hasQuery)
              ExpressiveIconButton(
                ExpressiveSymbols.close,
                onPressed: _clear,
                semanticLabel: ExpressiveLocalizations.of(context).clearSearch,
              ),
            ...widget.trailing,
          ],
        );
      },
    );
    // A tap anywhere on the field's row (its padding, the search glyph)
    // focuses it, as a tap anywhere on Compose's decorated `BasicTextField`
    // does; the input's own tap, placing the caret, and the icon buttons'
    // win the arena where they land.
    final row = GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: _focus.requestFocus,
      child: field,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ExpressiveStyleScope(
        style: resolved,
        states: states,
        inset: EdgeInsets.zero,
        child: ExpressiveSurface(
          style: widget.style,
          componentStyle: t.searchTheme,
          states: states,
          shape: widget._bare
              ? t.shapes.none
              : t.shapes.of(SearchBarTokens.containerShape),
          color: widget._bare
              ? expressiveTransparent
              : t.colors.role(SearchBarTokens.containerColor),
          child: row,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The search view.

/// The full-screen search view's route: a popup over the app whose
/// progress runs on springs (wave decision F11: expand out, collapse back,
/// as `rememberSearchBarState`), claiming the system's predictive back
/// gesture on Android.
class _SearchViewRoute extends PopupRoute<void>
    with ExpressiveBackHandleRoute<void> {
  _SearchViewRoute({
    required this.bar,
    required this.query,
    required this.collapsed,
    required this.capturedThemes,
    required this.expand,
    required this.collapse,
    required this.platform,
  });

  final ValueListenable<ExpressiveSearchBar> bar;
  final TextEditingController query;

  /// The collapsed bar's rectangle in global coordinates, when it had one.
  final Rect? collapsed;
  final CapturedThemes capturedThemes;

  /// The spring the view opens on (`SearchBarBehavior.expandMotion`).
  final SpringDescription expand;

  /// The spring the view closes on (`SearchBarBehavior.collapseMotion`).
  final SpringDescription collapse;
  final TargetPlatform platform;

  late final _SearchBackObserver _observer = _SearchBackObserver(this);

  /// The predictive back gesture in flight, or null.
  final ValueNotifier<_BackState?> back = ValueNotifier<_BackState?>(null);

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => expressiveSettleTime(expand);

  @override
  Duration get reverseTransitionDuration => expressiveSettleTime(collapse);

  @override
  void install() {
    super.install();
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    back.dispose();
    super.dispose();
  }

  @override
  TickerFuture didPush() {
    super.didPush();
    final controller = this.controller!;
    return controller.animateWith(
      designSpringSimulation(expand, from: controller.value, to: 1),
    );
  }

  @override
  bool didPop(void result) {
    // False when an overlay held open in the view took the pop
    // ([ExpressiveBackHandle]): the view stays open.
    if (!super.didPop(result)) return false;
    final controller = this.controller!;
    controller.animateBackWith(
      designSpringSimulation(collapse, from: controller.value, to: 0),
    );
    return true;
  }

  bool _claim(PredictiveBackEvent event) {
    if (platform != TargetPlatform.android ||
        event.isButtonEvent ||
        !isCurrent ||
        // An overlay held open in the view takes the back: the gesture
        // falls through to the navigator, whose pop closes it.
        willHandlePopInternally) {
      return false;
    }
    back.value = _BackState(first: event, last: event);
    return true;
  }

  void _follow(PredictiveBackEvent event) {
    final state = back.value;
    if (state == null) return;
    back.value = _BackState(first: state.first, last: event);
  }

  void _end({required bool commit}) {
    if (back.value == null) return;
    if (commit) {
      // Collapse from where the gesture left the view: its frame holds
      // while the progress springs home.
      if (isCurrent) navigator?.pop();
    } else {
      back.value = null;
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => capturedThemes.wrap(
    ValueListenableBuilder<ExpressiveSearchBar>(
      valueListenable: bar,
      builder: (context, bar, _) => _SearchView(
        bar: bar,
        query: query,
        collapsed: collapsed,
        progress: animation,
        back: back,
        onCollapse: () => Navigator.of(context).maybePop(),
      ),
    ),
  );
}

/// A predictive back gesture in flight: the event it began with and the
/// latest.
@immutable
class _BackState {
  const _BackState({required this.first, required this.last});

  final PredictiveBackEvent first;
  final PredictiveBackEvent last;

  /// The gesture's progress through `PredictiveBack.transform`.
  double get progress => ExpressivePage.predictiveBackEasing.transform(
    last.progress.clamp(0.0, 1.0),
  );

  /// How far the finger has moved vertically since the gesture began.
  double get deltaY =>
      (last.touchOffset?.dy ?? 0) - (first.touchOffset?.dy ?? 0);
}

/// Hands the system's predictive back events to the search view's route.
class _SearchBackObserver with WidgetsBindingObserver {
  _SearchBackObserver(this.route);

  final _SearchViewRoute route;

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) =>
      route._claim(backEvent);

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) =>
      route._follow(backEvent);

  @override
  void handleCancelBackGesture() => route._end(commit: false);

  @override
  void handleCommitBackGesture() => route._end(commit: true);
}

/// Compose's `FullScreenSearchBarLayout`: the surface grows from the
/// collapsed bar to the screen (or, contained, fades in at full size), its
/// corners going square; the field slides from the bar's place to the top,
/// under the status bar; the content fades in below it. A predictive back
/// gesture shrinks the whole view towards 90 % and the swiped-from edge.
class _SearchView extends StatefulWidget {
  const _SearchView({
    required this.bar,
    required this.query,
    required this.collapsed,
    required this.progress,
    required this.back,
    required this.onCollapse,
  });

  final ExpressiveSearchBar bar;
  final TextEditingController query;
  final Rect? collapsed;
  final Animation<double> progress;
  final ValueListenable<_BackState?> back;
  final VoidCallback onCollapse;

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final FocusNode _focus = FocusNode();

  /// The last gesture, kept through a committed gesture's collapse.
  _BackState? _lastBack;

  @override
  void initState() {
    super.initState();
    widget.progress.addStatusListener(_status);
  }

  void _status(AnimationStatus status) {
    // Let the keyboard go as the view collapses.
    if (status == AnimationStatus.reverse) _focus.unfocus();
  }

  @override
  void dispose() {
    widget.progress.removeStatusListener(_status);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final bar = widget.bar;
    final contained = bar.contained;
    final surfaceColor = contained
        ? t.colors.surfaceContainerLow
        : t.colors.role(SearchBarTokens.containerColor);
    final field = ExpressiveSearchField._view(
      style: bar.style,
      controller: widget.query,
      focusNode: _focus,
      hintText: bar.hintText,
      trailing: bar.trailing,
      onChanged: bar.onChanged,
      onSubmitted: bar.onSubmitted,
      onCancel: widget.onCollapse,
      bare: !contained,
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!contained)
          SizedBox(
            height: 1,
            child: ColoredBox(
              color: t.colors.role(SearchViewTokens.dividerColor),
            ),
          ),
        if (bar.filters.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: ExpressiveChromeMetrics.margin,
            ),
            child: Row(
              spacing: ChipBehavior.horizontalSpacing,
              children: bar.filters,
            ),
          ),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.query,
            builder: (context, _) =>
                bar.results?.call(context, widget.query.text) ??
                const SizedBox.shrink(),
          ),
        ),
      ],
    );
    final topInset = MediaQuery.paddingOf(context).top;
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, constraints) => ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[
            widget.progress,
            widget.back,
          ]),
          builder: (context, _) {
            final back = widget.back.value ?? _lastBack;
            if (widget.back.value != null) _lastBack = widget.back.value;
            final geometry = expressiveSearchViewGeometry(
              screen: constraints.biggest,
              collapsed: widget.collapsed,
              progress: widget.progress.value.clamp(0.0, 1.0),
              backProgress: back?.progress ?? 0,
              swipeFromLeft:
                  (back?.last.swipeEdge ?? SwipeEdge.left) == SwipeEdge.left,
              backDeltaY: back?.deltaY ?? 0,
              topInset: topInset,
              contained: contained,
            );
            // The content lays out at its expanded height and is clipped
            // to the growing frame, so nothing reflows as the view opens.
            final expanded = expressiveSearchViewGeometry(
              screen: constraints.biggest,
              collapsed: widget.collapsed,
              progress: 1,
              topInset: topInset,
              contained: contained,
            ).content;
            final contentHeight = math.max(
              geometry.content.height,
              expanded.height,
            );
            return Stack(
              children: <Widget>[
                Positioned.fromRect(
                  rect: geometry.surface,
                  child: Opacity(
                    opacity: geometry.surfaceAlpha,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            // The bar's full corner.
                            Radius.circular(geometry.corner),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: geometry.content,
                  child: Opacity(
                    opacity: geometry.contentAlpha,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: AlignmentDirectional.topStart,
                        minHeight: contentHeight,
                        maxHeight: contentHeight,
                        child: MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: content,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fromRect(rect: geometry.field, child: field),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The search view's frame at [progress] (0 collapsed, 1 expanded) and a
/// predictive back gesture's transformed [backProgress], on a [screen]
/// whose collapsed bar stood at [collapsed] (Compose's
/// `FullScreenSearchBarLayout` measure and placement, point for point): the
/// surface, the field, the content, the surface's corner radius and the
/// surface's and content's alpha.
@visibleForTesting
({
  Rect surface,
  Rect field,
  Rect content,
  double corner,
  double surfaceAlpha,
  double contentAlpha,
})
expressiveSearchViewGeometry({
  required Size screen,
  required Rect? collapsed,
  required double progress,
  double backProgress = 0,
  bool swipeFromLeft = true,
  double backDeltaY = 0,
  double topInset = 0,
  bool contained = false,
}) {
  final bounds =
      collapsed ??
      Rect.fromLTWH(
        0,
        0,
        SearchBarBehavior.minWidth,
        SearchBarTokens.containerHeight,
      );
  final collapsedWidth = bounds.width;
  final collapsedHeight = bounds.height;
  final p = progress;
  final pb = backProgress;
  final backEndWidth = math.max(
    screen.width * _predictiveBackMinScale,
    collapsedWidth,
  );
  final backEndHeight = math.max(
    screen.height * _predictiveBackMinScale,
    collapsedHeight,
  );
  final endWidth = lerpDouble(screen.width, backEndWidth, pb)!;
  final endHeight = lerpDouble(screen.height, backEndHeight, pb)!;
  final width = contained
      ? endWidth
      : lerpDouble(collapsedWidth, endWidth, p)!.clamp(0.0, screen.width);
  final height = contained
      ? endHeight
      : lerpDouble(collapsedHeight, endHeight, p)!.clamp(0.0, screen.height);

  final fieldPadding = contained
      ? SearchBarBehavior.fullScreenExpandedHorizontalPadding
      : 0.0;
  final fieldWidth = lerpDouble(collapsedWidth, width - 2 * fieldPadding, p)!;
  final topPadding =
      topInset +
      (contained
          ? SearchBarBehavior.appBarVerticalPadding
          : SearchBarBehavior.verticalPadding);
  final animatedTopPadding = lerpDouble(0, topPadding, math.min(p, 1 - pb))!;
  final bottomPadding = contained
      ? SearchBarBehavior.verticalPadding
      : lerpDouble(0, SearchBarBehavior.verticalPadding, p)!;

  const margin = SearchBarBehavior.predictiveBackMinMargin;
  // `coerceAtLeast(right - endWidth).coerceAtMost(left)`.
  final endOffsetX = math.min(
    math.max(
      swipeFromLeft ? screen.width - margin - backEndWidth : margin,
      bounds.right - backEndWidth,
    ),
    bounds.left,
  );
  final available = math.max(0.0, (screen.height - backEndHeight) / 2 - margin);
  final totalOffsetY = math.min(
    available,
    SearchBarBehavior.predictiveBackMaxOffsetY,
  );
  final relativeDeltaY = screen.height <= 0
      ? 0.0
      : backDeltaY.abs() / screen.height;
  final endOffsetY = math.min(
    lerpDouble(0, totalOffsetY, relativeDeltaY)! * backDeltaY.sign + topPadding,
    bounds.top,
  );
  final backOffsetX = lerpDouble(0, endOffsetX, pb)!;
  final offsetX = contained
      ? backOffsetX
      : lerpDouble(bounds.left, backOffsetX, p)!;
  final centerX = lerpDouble(bounds.center.dx, offsetX + width / 2, p)!;
  final offsetY = lerpDouble(0, endOffsetY, pb)!;
  final animatedOffsetY = lerpDouble(bounds.top, offsetY, p)!;

  final surfaceTop = contained ? offsetY : animatedOffsetY;
  final fieldTop = animatedOffsetY + animatedTopPadding;
  final contentTop = fieldTop + collapsedHeight + bottomPadding;
  return (
    surface: Rect.fromLTWH(offsetX, surfaceTop, width, height),
    field: Rect.fromLTWH(
      centerX - fieldWidth * 0.5,
      fieldTop,
      fieldWidth,
      collapsedHeight,
    ),
    content: Rect.fromLTWH(
      offsetX,
      contentTop,
      width,
      math.max(0.0, height - (contentTop - surfaceTop)),
    ),
    corner: SearchBarTokens.containerHeight / 2 * math.max(1 - p, pb),
    surfaceAlpha: contained ? p : 1.0,
    contentAlpha: p,
  );
}

// A styled input grows for its text, preserving the 48dp icon targets.
double _searchRowHeight(
  BuildContext context,
  ExpressiveComponentThemeData style,
  Set<WidgetState> states,
) {
  final theme = context.expressiveTheme;
  final text = TextPainter(
    text: TextSpan(
      text: 'Ag',
      style: theme.type
          .of(SearchBarTokens.inputTextFont)
          .merge(style.textStyle?.resolve(states)),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final height = math.max(
    theme.density.height(SearchBarTokens.containerHeight, floor: 48),
    text.height,
  );
  text.dispose();
  return height;
}
