import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/face.dart';
import '../internal/footer_band.dart';
import '../internal/grabber.dart';
import '../internal/report_height.dart';
import '../internal/side_inset.dart';
import '../theme.dart';
import 'glass.dart';
import 'sheet.dart';
import 'top_bar.dart';

/// Root of every page: the theme's backdrop, still behind the page as it
/// scrolls (the glass over it shows it passing), then the page in a column at the
/// gutter: its top bar and, the page's gap under it, the [body] (the bar is
/// the first child of the source's `.main`, whose gap of 10 on a phone and
/// 16 on the desktop stands between it and the first tile). On a phone the
/// bar is pinned over
/// the page on its frost (`.top { position: sticky }`): the page runs up
/// under the status bar and the light with it, and scrolls under the bar;
/// on the desktop the bar stands in the page and scrolls away with it.
///
/// Top contract. A [FrostedAppBar] in [topBar] takes the register its route
/// earns: a tab's title on a root (Home's greeting through
/// `FrostedAppBar.greeting`), the way back and the title on a pushed page,
/// the sheet's head on a sheet. Leave [topBar] unset and the route's own bar
/// is derived: the way back on a pushed page, the close on a sheet, nothing
/// on a root, so a page authors a bar only to add a title or controls,
/// never to draw its own back or close. `topBar: FrostedAppBar.none` is the
/// explicit opt-out.
///
/// The column. On a phone the page stands 16 in from either edge and keeps
/// 20 under its last tile; at desktop width the gutter is 32 with 40 under
/// the last tile, and the page stands right of the sidebar while its light
/// runs on under the sidebar's glass.
///
/// Bottom contract. The body reserves whatever stands over the bottom edge:
/// the safe-area inset or, on a nav root, the shell's tab bar, published as
/// [ShellInsets]; the page scrolls on under the bar's fade. In scroll mode
/// the reserve is scroll padding; with `scroll: false` it is published as
/// MediaQuery bottom padding for the page's own scrollable. A nav root never
/// owns the bottom edge: a [footer] (DERIVED: the source's acts stand in
/// the page) belongs to pushed, sheet and shell-free pages, standing on the
/// canvas with the page fading into it above.
///
/// On a sheet's card the page is the sheet: no light, the card's room, the
/// grabber on a phone, its bar as the head, the body 12 under it and the
/// footer 12 under that.
///
/// ```dart
/// FrostedScaffold(topBar: const FrostedAppBar(title: 'Spending', caption: 'October 2026'), body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: tiles))
/// ```
class FrostedScaffold extends StatefulWidget {
  /// Creates a [FrostedScaffold].
  const FrostedScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.footer,
    this.scroll = true,
    this.padding,
    this.lights = true,
  });

  /// The page's content.
  final Widget body;

  /// Usually a [FrostedAppBar]; unset derives the route's own (see above).
  final Widget? topBar;

  /// Pinned above the bottom edge: a page's one act (DERIVED: the source
  /// pins none; Review transfer ends its form in Edit and Transfer, a
  /// `FrostedButtonRow` inline after, and a page that follows the source sets
  /// its acts the same way, in its body). Gets the footer band and the
  /// safe-area inset.
  final Widget? footer;

  /// Wrap the page in a scroll view.
  final bool scroll;

  /// Override the page's room round its content (scroll mode only).
  final EdgeInsetsGeometry? padding;

  /// Whether the theme's backdrop ([FrostedThemeData.backdrop]) stands
  /// still behind the page for its glass to show; false leaves the plain
  /// ground.
  final bool lights;

  /// The band the [footer] stands in, round its content.
  static const EdgeInsets footerInsets = EdgeInsets.fromLTRB(
    FrostedChromeMetrics.gutter,
    FrostedChromeMetrics.actionBarTop,
    FrostedChromeMetrics.gutter,
    FrostedChromeMetrics.tabBarBottom,
  );

  @override
  State<FrostedScaffold> createState() => _FrostedScaffoldState();
}

class _FrostedScaffoldState extends State<FrostedScaffold> {
  /// The measured height of the pinned bar (the status bar's inset
  /// included); null until laid out.
  double? _bar;

  void _measuredBar(double height) {
    if (height != _bar) setState(() => _bar = height);
  }

  /// The bar this screen mounts: the authored one, the route's derived one
  /// when [FrostedScaffold.topBar] is unset, nothing under [FrostedAppBar.none].
  Widget? _resolveBar(BuildContext context) {
    final authored = widget.topBar;
    if (authored != null) {
      return identical(authored, FrostedAppBar.none) ? null : authored;
    }
    if (RoutePresentation.of(context) == RoutePresentation.root) return null;
    return const FrostedAppBar();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final mq = MediaQuery.of(context);
    final register = RoutePresentation.of(context);
    final bar = _resolveBar(context);
    if (register == RoutePresentation.sheet &&
        FrostedSheetShell.around(context)) {
      return _onCard(context, bar);
    }
    final footer = widget.footer;
    final shellAllowance = ShellInsets.of(context);
    assert(
      shellAllowance == 0 || footer == null,
      'a nav root never owns the bottom edge: the shell\'s tab bar stands '
      'there; move the footer to a pushed, sheet, or shell-free page',
    );
    final wide = FrostedBreakpoints.isWide(context);
    final side = FrostedSideInset.of(context);
    final top = mq.padding.top;
    // The shell's allowance already spans the device inset, as does the
    // footer's band: a max, never a sum.
    final bodyInset = footer == null ? mq.padding.bottom : 0.0;
    final reserve = math.max(bodyInset, shellAllowance);
    final room =
        widget.padding?.resolve(Directionality.of(context)) ??
        (wide ? FrostedInsets.screenWide : FrostedInsets.screen);
    // A phone's bar is pinned over the page; the desktop's stands in it.
    final pinned = !wide && bar != null;
    final barRoom = pinned
        ? (_bar ??
              top +
                  FrostedChromeMetrics.barInset * 2 +
                  FrostedChromeMetrics.barControl)
        : top;
    // `.main`'s gap between the bar and the first tile: under the pinned
    // bar's room on a phone, after the bar in the column on the desktop.
    final barGap = bar == null ? 0.0 : FrostedBreakpoints.gap(context);
    final head = <Widget>[
      if (!pinned && bar != null) ...[bar, SizedBox(height: barGap)],
    ];

    // The sidebar stands at the reading start: the left, right to left the
    // right.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget page(Widget content) => Padding(
      padding: EdgeInsetsDirectional.only(start: side),
      child: content,
    );

    Widget pinnedBar() => Positioned(
      left: 0,
      top: 0,
      right: 0,
      child: FrostedReportHeight(
        onHeight: _measuredBar,
        child: _FrostBar(
          top: top,
          child: page(
            Padding(
              padding: EdgeInsets.only(left: room.left, right: room.right),
              child: bar!,
            ),
          ),
        ),
      ),
    );

    final Widget content;
    if (widget.scroll) {
      content = LayoutBuilder(
        builder: (context, viewport) => MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  page(
                    // The page's content holds its cards to the page's
                    // margins (design6 P); the shared check reads it.
                    DesignKeylineRegion(
                      label: 'screen',
                      child: Padding(
                        padding: room.copyWith(
                          top: room.top + barRoom + (pinned ? barGap : 0),
                          bottom: room.bottom + reserve,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [...head, widget.body],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // The page's own scrollable spends the reserve.
      content = Stack(
        children: [
          Positioned.fill(
            child: page(
              DesignKeylineRegion(
                label: 'screen',
                child: Padding(
                  padding: EdgeInsets.only(
                    top: barRoom + room.top + (pinned ? barGap : 0),
                    left: room.left,
                    right: room.right,
                  ),
                  child: MediaQuery(
                    data: mq.copyWith(
                      padding: mq.padding.copyWith(top: 0, bottom: reserve),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...head,
                        Expanded(child: widget.body),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // The backdrop stands still behind the page; the page's glass reads it
    // once between them (a BackdropGroup), the bar over them reads it all.
    final stage = Stack(
      fit: StackFit.expand,
      children: [
        if (widget.lights) const FrostedBackdropView(),
        BackdropGroup(child: content),
        if (pinned) pinnedBar(),
      ],
    );

    return ColoredBox(
      color: t.colorScheme.background,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: stage),
            if (footer != null)
              FrostedBottomStand(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // The page fades into the canvas above the band.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -FrostedChromeMetrics.footerFade,
                      height: FrostedChromeMetrics.footerFade,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                t.colorScheme.background.withValues(alpha: 0),
                                t.colorScheme.background,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    ColoredBox(
                      color: t.colorScheme.background,
                      child: Padding(
                        padding: FrostedScaffold.footerInsets.copyWith(
                          left:
                              (rtl ? 0 : side) +
                              (wide
                                  ? room.left
                                  : FrostedScaffold.footerInsets.left),
                          right:
                              (rtl ? side : 0) +
                              (wide
                                  ? room.right
                                  : FrostedScaffold.footerInsets.right),
                          bottom: math.max(
                            FrostedScaffold.footerInsets.bottom,
                            // An open keyboard swallows the home-indicator
                            // region, so the footer hugs it.
                            (mq.viewPadding.bottom - mq.viewInsets.bottom)
                                .clamp(0.0, double.infinity),
                          ),
                        ),
                        child: FrostedFooterBand(child: footer),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The page as a sheet: the card's room, the grabber on a phone, the bar
  /// as the head, the body 12 under it, the footer 12 under that, scrolling
  /// as one once it outgrows the card.
  Widget _onCard(BuildContext context, Widget? bar) {
    final wide = FrostedBreakpoints.isWide(context);
    final room = FrostedSheetShell.padding(context);
    final inset = wide ? 0.0 : MediaQuery.paddingOf(context).bottom;
    final footer = widget.footer;
    final parts = <Widget>[
      if (!wide) const FrostedGrabber(),
      if (bar != null) ...[
        bar,
        const SizedBox(height: FrostedChromeMetrics.sheetBodyGap),
      ],
      if (widget.scroll) widget.body else Flexible(child: widget.body),
      if (footer != null) ...[
        const SizedBox(height: FrostedChromeMetrics.sheetFootGap),
        FrostedFooterBand(child: footer),
      ],
    ];
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: parts,
    );
    final pad = room.copyWith(bottom: room.bottom + inset);
    return Material(
      type: MaterialType.transparency,
      child: widget.scroll
          ? SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: pad,
              child: column,
            )
          : Padding(padding: pad, child: column),
    );
  }
}

/// The glass a phone's bar is pinned on: the status bar's room over the bar,
/// both on the bar's glass, edged at its foot by a hairline. The page passes
/// under it, blurred; nothing fades it out. Plumbing of the screen.
class _FrostBar extends StatelessWidget {
  const _FrostBar({required this.top, required this.child});

  final double top;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return FrostedFace(
      material: FrostedMaterial.bar,
      radius: BorderRadius.zero,
      edge: frostedLitEdge(t, t.colorScheme.border),
      edges: EdgeInsets.only(bottom: FrostedStrokes.regular),
      ring: const Color(0x00000000),
      sheen: const Color(0x00000000),
      padding: EdgeInsets.only(top: top),
      child: child,
    );
  }
}
