/// The screen: a page's scaffold, which derives its bar from the route's
/// register (CONTRACT §4.2 `ExpressiveScaffold`). Chrome, no vocabulary role.
/// Owner: w2-appbar.
///
/// The registers (design_kit's `RoutePresentation`):
///
/// - **root**: the large flexible bar collapsing to the small one as the
///   body scrolls (Compose's `LargeFlexibleTopAppBar` with
///   `exitUntilCollapsedScrollBehavior`), or an authored search app bar;
/// - **pushed**: the small bar with the back arrow (Material's on both
///   platforms);
/// - **sheet**: the sheet's header — close, the title and an optional
///   confirm action — on the sheet's own container (the drag handle is the
///   sheet container's, `ExpressiveSheetPage`);
/// - **full-screen dialog** (a sheet raised full screen): close, the title
///   and the confirm action, on the surface.
///
/// A page passes a [ExpressiveScaffold.title] and gets its bar; it authors an
/// `ExpressiveAppBar` only to add to it (a subtitle, actions, the confirm
/// action, a search bar) and never draws its own back or close.
///
/// The collapse runs the body in a `CustomScrollView` under a pinned
/// header: as the body scrolls the bar gives up its title row first, and a
/// scroll that stops midway snaps the bar open or shut on the
/// `AppBar.topSnapMotion` spring (Compose's `settleAppBar`). A docked bar
/// fills its colour once content passes under it.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart'
    show ChromeGround, RoutePresentation, ShellInsets;

import '../chrome_metrics.dart';
import '../internal/docked_band.dart';
import '../internal/tokens/behavior.g.dart';
import '../motion.dart';
import '../spacing.dart';
import '../theme.dart';
import 'app_bar.dart';
import 'host.dart';

/// How a scroll treats the keyboard, by platform (CONTRACT §5): on iOS and
/// macOS a drag dismisses it, as UIKit's `keyboardDismissMode` does in
/// scrolling screens; on Android it stays up until the field loses focus
/// or the system back closes it (a Compose scroll leaves the IME alone).
ScrollViewKeyboardDismissBehavior _keyboardDismiss(BuildContext context) =>
    switch (Theme.of(context).platform) {
      TargetPlatform.iOS ||
      TargetPlatform.macOS => ScrollViewKeyboardDismissBehavior.onDrag,
      _ => ScrollViewKeyboardDismissBehavior.manual,
    };

/// Root of every page: its background, the bar its route derives, a
/// scrolling body by default, and the bottom edge's chrome.
///
/// Top: when [topBar] is unset the route derives the bar from [title]
/// (see the library doc); an authored bar always wins, and
/// `topBar: ExpressiveAppBar.none` declines any. A collapsing flexible bar
/// (`large: true, collapsing: true`) collapses with the body; any other bar
/// is docked above it and fills its colour on scroll.
///
/// Bottom: [footer] (sticky actions) or [bottomNav] (a docked bar) own the
/// bottom edge and inset by the device's safe area; [floating] chrome (a
/// FAB) stands 16dp in from the bottom end, over the body, which reserves
/// room for it. A shell's branch root reserves the shell's allowance
/// (`ShellInsets`) and never owns the bottom edge itself.
///
/// ```dart
/// ExpressiveScaffold(title: 'Trips', body: Column(children: sections))
/// ```
class ExpressiveScaffold extends StatefulWidget {
  /// A screen showing [body], with an optional [title] and [topBar].
  const ExpressiveScaffold({
    required this.body,
    this.title,
    this.topBar,
    this.bottomNav,
    this.footer,
    this.floating,
    this.scroll = true,
    this.padding,
    this.fullBleed = false,
    super.key,
  }) : assert(
         footer == null || floating == null,
         'footer and floating both claim the bottom edge — pick one',
       );

  /// The page's content.
  final Widget body;

  /// The page's title: the derived bar's.
  final String? title;

  /// Usually an [ExpressiveAppBar]; unset, the route's derived bar;
  /// [ExpressiveAppBar.none], no bar.
  final Widget? topBar;

  /// A docked bar at the bottom edge (a pushed, sheet or shell-free page's;
  /// never a branch root's).
  final Widget? bottomNav;

  /// Pinned above the bottom edge (sticky actions), with the screen's
  /// horizontal margin.
  final Widget? footer;

  /// Floating chrome at the bottom end: a FAB.
  final Widget? floating;

  /// Whether the body scrolls, in [padding].
  final bool scroll;

  /// The scrolling body's padding (directional insets resolve against the
  /// ambient direction); 16dp at the sides, 8dp at the top and bottom by
  /// default.
  final EdgeInsetsGeometry? padding;

  /// Whether the body owns the top edge (a hero under the status bar); a
  /// bar then rides over it, clear at rest and filling once content passes
  /// under it, and the body reads its height (status bar included) as
  /// `MediaQuery` top padding.
  final bool fullBleed;

  /// The default body padding.
  static const EdgeInsets defaultPadding = EdgeInsets.symmetric(
    horizontal: ExpressiveChromeMetrics.margin,
    vertical: ExpressiveSpacing.s8,
  );

  @override
  State<ExpressiveScaffold> createState() => _ExpressiveScreenState();
}

class _ExpressiveScreenState extends State<ExpressiveScaffold>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  late final AnimationController _snap = AnimationController.unbounded(
    vsync: this,
  )..addListener(_snapTick);

  /// How far content has scrolled under a docked bar (≤ 0).
  double _contentOffset = 0;

  /// Whether the snap is moving the scrollable (its notifications are its
  /// own, not the reader's).
  bool _settling = false;

  @override
  void dispose() {
    _snap.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _snapTick() {
    if (_scroll.hasClients) _scroll.position.jumpTo(_snap.value);
  }

  /// The bar this screen mounts: the authored one, the route's derived one,
  /// or none.
  Widget? _resolveBar(BuildContext context) {
    final authored = widget.topBar;
    if (authored != null) {
      return identical(authored, ExpressiveAppBar.none) ? null : authored;
    }
    final title = widget.title;
    return switch (RoutePresentation.of(context)) {
      RoutePresentation.root =>
        title == null
            ? null
            : ExpressiveAppBar(title: title, large: true, collapsing: true),
      RoutePresentation.pushed => ExpressiveAppBar(title: title),
      RoutePresentation.sheet => ExpressiveAppBar(title: title),
    };
  }

  /// Compose's `settleAppBar`: a bar left between open and shut snaps to
  /// the nearer on the snap spring; within 1 % of either it stays.
  void _settle(double range) {
    if (!_scroll.hasClients || range <= 0) return;
    final pixels = _scroll.position.pixels;
    final fraction = pixels / range;
    if (fraction < _settleThreshold || fraction >= 1) return;
    final target = fraction < 0.5 ? 0.0 : range;
    _settling = true;
    _snap.value = pixels;
    _snap
        .animateWith(
          designSpringSimulation(
            ExpressiveMotion.of(context).spring(AppBarBehavior.topSnapMotion),
            from: pixels,
            to: target,
          ),
        )
        .whenCompleteOrCancel(() => _settling = false);
  }

  bool _onScroll(ScrollNotification n, {required double? range}) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _snap.stop();
      _settling = false;
    }
    if (range != null) {
      if (n is ScrollEndNotification && !_settling) _settle(range);
      return false;
    }
    final offset = -math.max(0.0, n.metrics.pixels - n.metrics.minScrollExtent);
    if (offset != _contentOffset) setState(() => _contentOffset = offset);
    return false;
  }

  /// A page on a media ground (a feed root, a pushed player) is drawn in
  /// the host's dark theme, its bar and back arrow with it
  /// ([ExpressiveMediaGround]).
  @override
  Widget build(BuildContext context) =>
      ChromeGround.of(context) == ChromeGround.media
      ? ExpressiveMediaGround(child: Builder(builder: _build))
      : _build(context);

  Widget _build(BuildContext context) {
    final t = context.expressiveTheme;
    final media = MediaQuery.of(context);
    final bar = _resolveBar(context);
    final sheet = ExpressiveAppBar.inSheet(context);
    final shellAllowance = ShellInsets.of(context);
    assert(
      shellAllowance == 0 ||
          (widget.footer == null &&
              widget.bottomNav == null &&
              widget.floating == null),
      'a branch root never owns the bottom edge — the shell\'s bar stands '
      'there; move the footer/bottomNav/floating chrome to a pushed, sheet '
      'or shell-free page',
    );

    final docked = widget.footer != null || widget.bottomNav != null;
    final bodyInset = docked ? 0.0 : media.padding.bottom;
    final floatAllowance = widget.floating != null
        ? ExpressiveChromeMetrics.fabClearance + ExpressiveChromeMetrics.margin
        : 0.0;
    final bottomReserve = math.max(bodyInset + floatAllowance, shellAllowance);
    final padding = (widget.padding ?? ExpressiveScaffold.defaultPadding)
        .resolve(Directionality.of(context));
    final scrollPadding = padding.copyWith(
      bottom: padding.bottom + bottomReserve,
    );

    final collapsing =
        widget.scroll &&
        !widget.fullBleed &&
        bar is ExpressiveAppBar &&
        bar.isFlexible &&
        bar.collapsing;

    // The screen's content is one keyline region (ui_core's keyline check;
    // it paints nothing) at the window's full width, so its cards and
    // sections are held to the page's margins; the bar stands outside it.
    Widget region(Widget child) =>
        DesignKeylineRegion(label: widget.title ?? 'screen', child: child);

    Widget content;
    if (collapsing) {
      final range = bar.collapseRangeOf(context);
      final header = _BarHeader(
        bar: bar,
        topInset: ExpressiveAppBar.topInsetOf(context),
        collapsed: bar.collapsedHeightOf(context),
        range: range,
      );
      content = NotificationListener<ScrollNotification>(
        onNotification: (n) => _onScroll(n, range: range),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: CustomScrollView(
            controller: _scroll,
            keyboardDismissBehavior: _keyboardDismiss(context),
            slivers: <Widget>[
              SliverPersistentHeader(pinned: true, delegate: header),
              SliverPadding(
                padding: scrollPadding.copyWith(left: 0, right: 0),
                sliver: SliverToBoxAdapter(
                  child: region(
                    Padding(
                      padding: EdgeInsets.only(
                        left: scrollPadding.left,
                        right: scrollPadding.right,
                      ),
                      child: widget.body,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // A full-bleed body owns the top edge and reads what stands there as
      // its top padding: the bar's full height when one rides over it, else
      // the status bar. Any other body starts below the bar (or the status
      // bar's padding) and reads none.
      final barHeight =
          ExpressiveAppBar.topInsetOf(context) +
          (bar is ExpressiveAppBar
              ? bar.collapsedHeightOf(context) + bar.collapseRangeOf(context)
              : 0.0);
      final bodyTop = !widget.fullBleed
          ? 0.0
          : bar != null
          ? barHeight
          : media.padding.top;
      final bodyMedia = media.removePadding(
        removeTop: true,
        removeBottom: true,
      );
      Widget body;
      if (widget.scroll) {
        body = MediaQuery(
          data: bodyMedia.copyWith(
            padding: bodyMedia.padding.copyWith(top: bodyTop),
          ),
          child: region(
            SingleChildScrollView(
              controller: _scroll,
              keyboardDismissBehavior: _keyboardDismiss(context),
              padding: scrollPadding,
              child: widget.body,
            ),
          ),
        );
      } else {
        // The body reserves the bottom itself (its own scrollable reads the
        // reserve as bottom padding).
        body = MediaQuery(
          data: bodyMedia.copyWith(
            padding: bodyMedia.padding.copyWith(
              top: bodyTop,
              bottom: bottomReserve,
            ),
          ),
          child: region(widget.body),
        );
      }
      body = NotificationListener<ScrollNotification>(
        onNotification: (n) => _onScroll(n, range: null),
        child: body,
      );
      final scroll = ExpressiveAppBarScroll(
        contentOffset: _contentOffset,
        overlay: widget.fullBleed,
      );
      if (bar == null) {
        content = widget.fullBleed
            ? body
            : Padding(
                padding: EdgeInsets.only(top: media.padding.top),
                child: body,
              );
        if (sheet) content = body;
      } else if (widget.fullBleed) {
        content = Stack(
          children: <Widget>[
            Positioned.fill(child: body),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ExpressiveAppBarScrollScope(scroll: scroll, child: bar),
            ),
          ],
        );
      } else {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ExpressiveAppBarScrollScope(scroll: scroll, child: bar),
            Expanded(child: body),
          ],
        );
      }
    }

    final footer = widget.footer;
    final bottomNav = widget.bottomNav;
    final route = ModalRoute.of(context);
    if (footer != null || bottomNav != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: content),
          // Measured for the route, so a toast raised on it stands above
          // the docked chrome (internal/docked_band.dart).
          ExpressiveDockedBand(
            route: route,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (footer != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      ExpressiveChromeMetrics.margin,
                      ExpressiveSpacing.s8,
                      ExpressiveChromeMetrics.margin,
                      ExpressiveSpacing.s8 + media.padding.bottom,
                    ),
                    child: footer,
                  ),
                if (bottomNav != null)
                  MediaQuery(
                    data: media.copyWith(
                      padding: media.padding.copyWith(top: 0),
                    ),
                    child: bottomNav,
                  ),
              ],
            ),
          ),
        ],
      );
    } else {
      expressiveClearDockedBand(route);
    }

    final floating = widget.floating;
    if (floating != null) {
      content = Stack(
        children: <Widget>[
          Positioned.fill(child: content),
          PositionedDirectional(
            // The safe area on the end side: the left one, right to left.
            end:
                ExpressiveChromeMetrics.fabMargin +
                (Directionality.of(context) == TextDirection.rtl
                    ? media.padding.left
                    : media.padding.right),
            bottom: ExpressiveChromeMetrics.fabMargin + media.padding.bottom,
            child: floating,
          ),
        ],
      );
    }

    return ColoredBox(
      color: sheet ? t.colors.surface.withValues(alpha: 0) : t.colors.surface,
      child: content,
    );
  }
}

/// Compose's `collapsedFraction < 0.01f`: a bar this near open does not
/// settle.
const _settleThreshold = 0.01;

/// The pinned header a collapsing bar rides in: as tall as the bar
/// expanded, down to its small row; it hands the bar how far it has
/// collapsed.
class _BarHeader extends SliverPersistentHeaderDelegate {
  _BarHeader({
    required this.bar,
    required this.topInset,
    required this.collapsed,
    required this.range,
  });

  final ExpressiveAppBar bar;
  final double topInset;
  final double collapsed;
  final double range;

  @override
  double get minExtent => topInset + collapsed;

  @override
  double get maxExtent => topInset + collapsed + range;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => MediaQuery(
    // The scroll view took the top padding; the bar stands under the
    // status bar, as the header's extent counts it.
    data: MediaQuery.of(
      context,
    ).copyWith(padding: MediaQuery.paddingOf(context).copyWith(top: topInset)),
    child: ExpressiveAppBarScrollScope(
      scroll: ExpressiveAppBarScroll(
        heightOffset: -math.min(shrinkOffset, range),
        contentOffset: -shrinkOffset,
      ),
      // The pinned header lays out at maxExtent − shrinkOffset; the bar
      // sums its own parts, which differ from that in the last bit.
      child: SizedBox(
        height: math.max(minExtent, maxExtent - shrinkOffset),
        child: bar,
      ),
    ),
  );

  @override
  bool shouldRebuild(_BarHeader oldDelegate) =>
      bar != oldDelegate.bar ||
      topInset != oldDelegate.topInset ||
      collapsed != oldDelegate.collapsed ||
      range != oldDelegate.range;
}
