import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/page_foot.dart';
import '../theme.dart';
import 'shell_frame.dart';
import 'states.dart';
import 'top_bar.dart';
import 'route_chrome.dart';

/// Root of every Minimal screen: the ground, the safe areas, a scrolling
/// body by default, and chrome the route derives ([MinimalRouteChrome]).
///
/// Top contract: the page authors its [topBar] — a [MinimalAppBar], whose
/// register the route decides — or has none. A pushed page or a sheet page
/// that authors none still gets a bare [MinimalAppBar], because its way out
/// is the route's, never the page's. The bar is docked in the layout over
/// its own permanent hairline; content scrolls below it, never under it.
///
/// Bottom contract: screen-edge chrome occupies the bottom only through this
/// widget's slots. In scroll mode the body reserves the occluded height (the
/// safe-area inset, the shell's bar, or a floating control's allowance) in
/// its scroll padding; with `scroll: false` that allowance is published to
/// the body as MediaQuery bottom padding, so an inner scrollable reserves
/// it itself. A nav root never owns the bottom edge — the shell's bar
/// stands there — so [footer] and [floating] belong to pushed, sheet and
/// shell-free pages. A [footer] is docked on the ground over a hairline and
/// insets by the true device safe area.
///
/// In a sheet the screen is as tall as its content (up to the card's cap):
/// the card, not the screen, is the surface.
///
/// ```dart
/// MinimalScaffold(topBar: MinimalAppBar(title: 'Today', subtitle: 'Fri 28 Aug'), padding: EdgeInsets.zero, body: Column(children: rows))
/// ```
class MinimalScaffold extends StatelessWidget {
  /// A page around [body].
  const MinimalScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.footer,
    this.floating,
    this.scroll = true,
    this.padding,
    this.fullBleed = false,
  }) : assert(
         footer == null || floating == null,
         'footer and floating both claim the bottom edge — pick one',
       );

  /// The page's content.
  final Widget body;

  /// Usually a [MinimalAppBar]. Unset, a root has no bar and a pushed or
  /// sheet page gets the bare derived one.
  final Widget? topBar;

  /// Docked above the bottom edge (a sticky action, a [MinimalActionBar]).
  /// Gets the gutter and the footer's own hairline.
  final Widget? footer;

  /// A control floating over the body's bottom-trailing corner, the gutter
  /// in from the edge and [MinimalChromeMetrics.floatingGap] above the safe
  /// area. Content scrolls beneath it; the body reserves
  /// [MinimalChromeMetrics.floatingAllowance] for it.
  final Widget? floating;

  /// Wrap the body in a scroll view with [padding].
  final bool scroll;

  /// The body padding in scroll mode; [MinimalInsets.screen] by default. A
  /// list whose rows run edge to edge passes `EdgeInsets.zero`.
  final EdgeInsetsGeometry? padding;

  /// The body owns the top edge and runs behind the status bar (a hero, a
  /// canvas). A bar over it docks under the status bar as usual, and the
  /// body reads the occluded height as MediaQuery top padding.
  final bool fullBleed;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final mq = MediaQuery.of(context);
    final register = MinimalRouteChrome.of(context);
    final footer = this.footer;
    final bar =
        topBar ??
        (register == MinimalRouteChrome.root ? null : const MinimalAppBar());

    // The shell paints the nav bar itself and asks each nav root to reserve
    // its height through MinimalShellInsets. A nav root never owns the bottom
    // edge, and the assert is the teacher.
    final shellAllowance = MinimalShellInsets.of(context);
    assert(
      shellAllowance == 0 || (footer == null && floating == null),
      'a nav root never owns the bottom edge — the shell\'s bar stands '
      'there; move the footer or floating control to a pushed, sheet, or '
      'shell-free page',
    );

    final inSheet = register == MinimalRouteChrome.sheet;
    // Marked, so a toast shown from the page stands clear of its act.
    final Widget? footerBar;
    if (footer == null) {
      footerBar = null;
    } else if (inSheet) {
      // The card's own footer: the hairline inset to the card's padding,
      // exactly as a [MinimalBottomSheet] draws it.
      footerBar = MinimalPageFoot(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MinimalChromeMetrics.sheetPad,
            0,
            MinimalChromeMetrics.sheetPad,
            MinimalSpacing.s12,
          ),
          child: Container(
            padding: const EdgeInsets.only(top: MinimalSpacing.s12),
            decoration: BoxDecoration(border: Border(top: t.rule)),
            child: footer,
          ),
        ),
      );
    } else {
      footerBar = MinimalPageFoot(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            MinimalChromeMetrics.gutter,
            MinimalSpacing.s12,
            MinimalChromeMetrics.gutter,
            MinimalSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: t.background,
            border: Border(top: t.rule),
          ),
          child: Padding(
            // The true device inset, less whatever an open keyboard already
            // covers.
            padding: EdgeInsets.only(
              bottom: (mq.viewPadding.bottom - mq.viewInsets.bottom).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: footer,
          ),
        ),
      );
    }

    if (inSheet && !fullBleed) {
      return _SheetScreen(
        bar: bar,
        scroll: scroll,
        padding: (padding ?? _sheetPadding).resolve(Directionality.of(context)),
        footer: footerBar,
        body: body,
      );
    }

    // Ambient inset reaches the body only when no footer consumes it. The
    // shell's allowance and a floating control's are measured from the
    // display edge and already span the device inset, so they REPLACE the
    // ambient inset rather than stacking on it.
    final bodyInset = footer == null ? mq.padding.bottom : 0.0;
    final floatAllowance = floating != null
        ? mq.padding.bottom + MinimalChromeMetrics.floatingAllowance
        : shellAllowance;
    final bottomReserve = math.max(bodyInset, floatAllowance);

    final barHeight = bar == null ? 0.0 : MinimalChromeMetrics.barHeight;
    final pageBody = fullBleed
        ? MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(top: mq.padding.top + barHeight),
            ),
            child: body,
          )
        : body;

    final basePad = (padding ?? MinimalInsets.screen).resolve(
      Directionality.of(context),
    );
    // A loading or error state that IS the page has nothing to scroll: it
    // takes the height under the bar, so it stands in the middle of the
    // glass rather than at the top of an unbounded scroll view.
    final whole = body is MinimalLoadingState || body is MinimalErrorState;
    final Widget content;
    if (scroll && !whole) {
      content = MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: basePad.copyWith(bottom: basePad.bottom + bottomReserve),
          child: pageBody,
        ),
      );
    } else {
      content = Padding(
        // Whatever the reserve is not already published below as the
        // allowance an inner scrollable consumes itself.
        padding: EdgeInsets.only(bottom: bottomReserve - floatAllowance),
        child: MediaQuery(
          data: mq.copyWith(
            padding: mq.padding.copyWith(bottom: floatAllowance),
          ),
          child: pageBody,
        ),
      );
    }

    // The page under its bar is one keyline region: what stands on it
    // starts on the gutter and ends on it (ui_core's keyline check).
    final region = DesignKeylineRegion(
      label: 'MinimalScaffold',
      child: content,
    );

    final Widget frame;
    if (fullBleed) {
      frame = Stack(
        children: [
          Positioned.fill(child: region),
          if (bar != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ColoredBox(
                color: t.background,
                child: Padding(
                  padding: EdgeInsets.only(top: mq.padding.top),
                  child: bar,
                ),
              ),
            ),
        ],
      );
    } else {
      frame = SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?bar,
            Expanded(child: region),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: t.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: frame),
                ?footerBar,
              ],
            ),
          ),
          if (floating != null)
            PositionedDirectional(
              end: MinimalChromeMetrics.gutter,
              bottom: mq.padding.bottom + MinimalChromeMetrics.floatingGap,
              child: floating!,
            ),
        ],
      ),
    );
  }

  static const EdgeInsets _sheetPadding = EdgeInsets.fromLTRB(
    MinimalChromeMetrics.sheetPad,
    MinimalSpacing.s4,
    MinimalChromeMetrics.sheetPad,
    MinimalChromeMetrics.sheetPad,
  );
}

/// A screen standing in a sheet card: the header, the body and the footer
/// stacked as tall as they are, the body scrolling once the card reaches
/// its cap. The card is the surface, so the screen paints no ground.
class _SheetScreen extends StatelessWidget {
  const _SheetScreen({
    required this.bar,
    required this.scroll,
    required this.padding,
    required this.footer,
    required this.body,
  });

  final Widget? bar;
  final bool scroll;
  final EdgeInsets padding;
  final Widget? footer;
  final Widget body;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bar != null) ...[const MinimalGap(MinimalSpacing.s4), bar!],
        Flexible(
          child: scroll
              ? SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: padding,
                  child: body,
                )
              : Padding(padding: padding, child: body),
        ),
        ?footer,
      ],
    ),
  );
}
