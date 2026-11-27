import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/bleed.dart';
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
/// scrolls (the glass over it shows it passing), then the page in a column
/// at the gutter: its top bar and, 10 under it on a phone and 16 on a
/// desktop, the [body]. On a phone the bar is pinned over the page on its
/// frost: the page runs up under the status bar and the light with it, and
/// scrolls under the bar; on a desktop the bar stands in the page and
/// scrolls away with it.
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
/// runs on under the sidebar's glass. [maxWidth] holds the column to a
/// measure on its start edge: the bar's title and actions, the body and the
/// footer's acts all keep to it, so an act never stands a window's width
/// from what it acts on.
///
/// Bottom contract. The body keeps clear of what stands over the bottom
/// edge: the safe-area inset, or a tab bar laid over a root page.
/// [FrostedAppShell] lays its pages out above its tab bar, so they keep
/// clear of the inset alone. In scroll mode the room is scroll padding; with
/// `scroll: false` it is published as MediaQuery bottom padding for the
/// page's own scrollable. A [footer] on a page that owns the window's foot
/// (a phone's pushed page, a sheet, a shell-free page) stands on a band of
/// the bar's glass along it; where the page doesn't, it floats on a slab of
/// the tab bar's glass: 8 over [FrostedAppShell]'s tab bar on a root page,
/// and at desktop width the column's width, 12 over the window's foot.
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
    this.maxWidth,
  });

  /// The page's content.
  final Widget body;

  /// Usually a [FrostedAppBar]; unset derives the route's own (see above).
  final Widget? topBar;

  /// Pinned above the bottom edge: a page's one act. Stands on the footer's
  /// band of the bar's glass, the safe-area inset in it, with the page
  /// passing under it; over the app shell's tab bar and at desktop width on
  /// a slab of the tab bar's glass, the column's width (see above). From 600
  /// wide a [FrostedButtonRow]'s acts stand at the column's end there.
  final Widget? footer;

  /// Wrap the page in a scroll view.
  final bool scroll;

  /// Override the page's room round its content (scroll mode only).
  final EdgeInsetsGeometry? padding;

  /// Whether the theme's backdrop ([FrostedThemeData.backdrop]) stands
  /// still behind the page for its glass to show; false leaves the plain
  /// ground.
  final bool lights;

  /// The widest the page's column grows, its padding included, on its start
  /// edge: the bar, the body and the footer hold to it, the rest of a wide
  /// window left to the backdrop. Null spans the page's box (a form reads
  /// well at 720).
  final double? maxWidth;

  /// The band the [footer] stands in, round its content.
  static const EdgeInsets footerInsets = EdgeInsets.fromLTRB(
    FrostedChromeMetrics.gutter,
    FrostedChromeMetrics.actionBarTop,
    FrostedChromeMetrics.gutter,
    FrostedChromeMetrics.tabBarBottom,
  );

  @override
  State<FrostedScaffold> createState() => _FrostedScaffoldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('scroll', value: scroll, ifFalse: 'scroll: false'))
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('lights', value: lights, ifFalse: 'lights: false'))
      ..add(DoubleProperty('maxWidth', maxWidth, defaultValue: null));
  }
}

class _FrostedScaffoldState extends State<FrostedScaffold> {
  /// The measured height of the pinned bar (the status bar's inset
  /// included); null until laid out.
  double? _bar;

  void _measuredBar(double height) {
    if (height != _bar) setState(() => _bar = height);
  }

  /// The footer's band as laid out: the page's reserve under it.
  double? _foot;

  void _measuredFoot(double height) {
    if (height != _foot) setState(() => _foot = height);
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
    final measure = widget.maxWidth;
    if (measure == null) return _page(context, 0);
    // What a wide box leaves past the measure stands at the column's end.
    final side = FrostedSideInset.of(context);
    return LayoutBuilder(
      builder: (context, box) => _page(
        context,
        box.maxWidth.isFinite
            ? math.max(0.0, box.maxWidth - side - measure)
            : 0.0,
      ),
    );
  }

  /// The page, [past] left empty at its column's end.
  Widget _page(BuildContext context, double past) {
    final t = context.frostedTheme;
    final mq = MediaQuery.of(context);
    final register = RoutePresentation.of(context);
    final measured = EdgeInsetsDirectional.only(end: past);
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
    // Where the page doesn't own the window's foot (a tab bar under it, a
    // desktop's column), the footer floats on a slab.
    final barUnder = FrostedShellFoot.barUnder(
      context,
      root: register == RoutePresentation.root,
    );
    final floats = footer != null && (wide || barUnder);
    // An open keyboard swallows the home-indicator region, so the footer
    // hugs it.
    final safe = (mq.viewPadding.bottom - mq.viewInsets.bottom).clamp(
      0.0,
      double.infinity,
    );
    final slabFoot = barUnder
        ? 0.0
        : math.max(FrostedChromeMetrics.tabBarBottom, safe);
    final side = FrostedSideInset.of(context);
    final top = mq.padding.top;
    // The shell's allowance already spans the device inset: a max, never a
    // sum. A footer's band spans it too, and the page runs on under it, so
    // its height is the reserve; until it is measured (a page's first frame),
    // the standard band's.
    final reserve = footer == null
        ? math.max(mq.padding.bottom, shellAllowance)
        : _foot ??
              (floats
                  ? FrostedChromeMetrics.slabHeight + slabFoot
                  : FrostedScaffold.footerInsets.top +
                        FrostedChromeMetrics.buttonHeight +
                        math.max(
                          FrostedScaffold.footerInsets.bottom,
                          mq.viewPadding.bottom,
                        ));
    final room =
        widget.padding?.resolve(Directionality.of(context)) ??
        (wide ? FrostedInsets.screenWide : FrostedInsets.screen);
    // A phone's bar is pinned over the page; the desktop's stands in it.
    final pinned = !wide && bar != null;
    // Until the bar is measured (a page's first frame), its room is the
    // standard bar's, its foot's hairline included, so a fresh page stands
    // where it settles rather than a pixel off for one frame.
    final barRoom = pinned
        ? (_bar ??
              top +
                  FrostedChromeMetrics.barInset * 2 +
                  FrostedChromeMetrics.barControl +
                  FrostedStrokes.regular)
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
              padding: EdgeInsets.only(
                left: room.left,
                right: room.right,
              ).add(measured),
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
                    // A strip run on under the gutters (the chips, the
                    // tabs) takes a tap there.
                    FrostedBleedRoom(
                      // The page's content holds its cards to the page's
                      // margins; the shared keyline check reads it.
                      child: RawKeylineRegion(
                        label: 'screen',
                        child: Padding(
                          padding: room
                              .copyWith(
                                top: room.top + barRoom + (pinned ? barGap : 0),
                                bottom: room.bottom + reserve,
                              )
                              .add(measured),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [...head, widget.body],
                          ),
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
              FrostedBleedRoom(
                child: RawKeylineRegion(
                  label: 'screen',
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: barRoom + room.top + (pinned ? barGap : 0),
                      left: room.left,
                      right: room.right,
                    ).add(measured),
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
          ),
        ],
      );
    }

    // The footer stands over the page's foot on the bar's glass, as a phone's
    // bar over its head: the page passes under it, blurred, and rests a
    // margin over it (its measured height is the page's reserve).
    Widget footBand(Widget footer) => Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: FrostedReportHeight(
        onHeight: _measuredFoot,
        child: FrostedBottomStand(
          child: FrostedFootGlass(
            padding: FrostedScaffold.footerInsets.copyWith(
              left:
                  (rtl ? past : side) +
                  (wide ? room.left : FrostedScaffold.footerInsets.left),
              right:
                  (rtl ? side : past) +
                  (wide ? room.right : FrostedScaffold.footerInsets.right),
              bottom: math.max(FrostedScaffold.footerInsets.bottom, safe),
            ),
            child: FrostedFooterBand(child: footer),
          ),
        ),
      ),
    );

    // The footer floats on the tab bar's slab, its edges on the column's
    // (a gutter's in from the window's on a phone), the tab bar's own room
    // over the bar under it, 12 (or the system's inset) over the window's
    // foot at desktop width; the page rests a margin over it.
    Widget footSlab(Widget footer) => Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: FrostedReportHeight(
        onHeight: _measuredFoot,
        child: FrostedBottomStand(
          child: Padding(
            padding: EdgeInsets.only(
              left:
                  (rtl ? past : side) +
                  (wide ? room.left : FrostedChromeMetrics.tabBarSide),
              right:
                  (rtl ? side : past) +
                  (wide ? room.right : FrostedChromeMetrics.tabBarSide),
              bottom: slabFoot,
            ),
            child: FrostedFootSlab(child: FrostedFooterBand(child: footer)),
          ),
        ),
      ),
    );

    // The backdrop stands still behind the page; the page's glass reads it
    // once between them (a BackdropGroup), the bars over them read it all.
    final stage = Stack(
      fit: StackFit.expand,
      children: [
        if (widget.lights) const FrostedBackdropView(),
        BackdropGroup(child: content),
        if (pinned) pinnedBar(),
        if (footer != null) floats ? footSlab(footer) : footBand(footer),
      ],
    );

    return ColoredBox(
      color: t.colorScheme.background,
      child: Material(type: MaterialType.transparency, child: stage),
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
      edges: const EdgeInsets.only(bottom: FrostedStrokes.regular),
      ring: const Color(0x00000000),
      sheen: const Color(0x00000000),
      padding: EdgeInsets.only(top: top),
      child: child,
    );
  }
}
