import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/bar_gutter.dart';
import '../internal/footer_band.dart';
import '../internal/layer.dart';
import '../internal/report_height.dart';
import '../internal/side_inset.dart';
import '../theme.dart';
import 'acrylic.dart';
import 'sheet.dart';
import 'top_bar.dart';

/// Root of every page: the ground (the page's ground on a phone, the content layer
/// on the desktop), its top bar and the [body] in a column at the gutter.
/// On a phone the bar is pinned over the page on the acrylic with a hairline
/// under it, and the page scrolls under it; on the desktop the bar stands
/// in the page and scrolls away with it, spanning the layer (its title on
/// the column's start, its commands and the account's bell and avatar at
/// the layer's end, as an app's head does), and the column under it runs
/// at most 1120 wide from the layer's start.
///
/// Top contract. A [Fluent2AppBar] in [topBar] takes the register its route
/// earns: a tab's title on a root, the way back and the title on a pushed
/// page, the sheet's head on a sheet. Leave [topBar] unset and the route's
/// own bar is derived: the way back on a pushed page, the close on a sheet,
/// nothing on a root, so a page authors a bar only to add a title or
/// commands, never to draw its own back or close.
/// `topBar: Fluent2AppBar.none` is the explicit opt-out.
///
/// The column. On a phone the page stands 16 in from either edge and keeps
/// 24 under its last part; on the desktop the gutter is 24 with 40 under
/// it.
///
/// Bottom contract. The body reserves whatever stands over the bottom
/// edge: the safe-area inset or, on a nav root, the shell's tab bar,
/// published as [ShellInsets]. In scroll mode the reserve is scroll
/// padding; with `scroll: false` it is published as MediaQuery bottom
/// padding for the page's own scrollable. A nav root never owns the bottom
/// edge: a [footer] (the page's acts, a primary button with its secondary)
/// belongs to pushed, sheet and shell-free pages, standing in a band of
/// the surface over a hairline.
///
/// On a sheet's card the page is the sheet: the card's room, the handle on
/// a phone, its bar as the head, the body 8 under it and the footer 16
/// under that.
///
/// ```dart
/// Fluent2Scaffold(topBar: const Fluent2AppBar(title: 'Files'), body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sections))
/// ```
class Fluent2Scaffold extends StatefulWidget {
  /// A page: [topBar] over [body].
  const Fluent2Scaffold({
    super.key,
    required this.body,
    this.topBar,
    this.footer,
    this.scroll = true,
    this.padding,
  });

  /// The page's content.
  final Widget body;

  /// Usually a [Fluent2AppBar]; unset derives the route's own (see above).
  final Widget? topBar;

  /// Pinned above the bottom edge: the page's acts. Gets the footer band
  /// and the safe-area inset.
  final Widget? footer;

  /// Wrap the page in a scroll view.
  final bool scroll;

  /// Override the page's room round its content.
  final EdgeInsetsGeometry? padding;

  /// The room round a page's content at [context]: the gutter at the
  /// sides, the foot under the last part.
  static EdgeInsets insetsOf(BuildContext context) =>
      Fluent2Layout.isWide(context)
      ? const EdgeInsets.fromLTRB(
          Fluent2ChromeMetrics.gutterWide,
          0,
          Fluent2ChromeMetrics.gutterWide,
          Fluent2ChromeMetrics.pageBottomWide,
        )
      : const EdgeInsets.fromLTRB(
          Fluent2ChromeMetrics.gutter,
          Fluent2Spacing.s,
          Fluent2ChromeMetrics.gutter,
          Fluent2ChromeMetrics.pageBottom,
        );

  @override
  State<Fluent2Scaffold> createState() => _Fluent2ScreenState();
}

class _Fluent2ScreenState extends State<Fluent2Scaffold> {
  double? _bar;

  void _measuredBar(double height) {
    if (height != _bar) setState(() => _bar = height);
  }

  Widget? _resolveBar(BuildContext context) {
    final authored = widget.topBar;
    if (authored != null) {
      return identical(authored, Fluent2AppBar.none) ? null : authored;
    }
    if (RoutePresentation.of(context) == RoutePresentation.root) return null;
    return const Fluent2AppBar();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final mq = MediaQuery.of(context);
    final register = RoutePresentation.of(context);
    final bar = _resolveBar(context);
    if (register == RoutePresentation.sheet &&
        Fluent2SheetShell.around(context)) {
      return _onCard(context, bar);
    }
    final footer = widget.footer;
    final shellAllowance = ShellInsets.of(context);
    assert(
      shellAllowance == 0 || footer == null,
      'a nav root never owns the bottom edge: the shell\'s tab bar stands '
      'there; move the footer to a pushed, sheet, or shell-free page',
    );
    final wide = Fluent2Layout.isWide(context);
    final side = Fluent2SideInset.of(context);
    final top = mq.padding.top;
    final bodyInset = footer == null ? mq.padding.bottom : 0.0;
    final reserve = math.max(bodyInset, shellAllowance);
    final direction = Directionality.of(context);
    final room = (widget.padding ?? Fluent2Scaffold.insetsOf(context)).resolve(
      direction,
    );
    // The room on the reading start and end sides.
    final ltr = direction == TextDirection.ltr;
    final roomStart = ltr ? room.left : room.right;
    final roomEnd = ltr ? room.right : room.left;
    final pinned = !wide && bar != null;
    final barRoom = pinned
        ? (_bar ?? top + Fluent2ChromeMetrics.barHeight + 1)
        : top;
    final ground = Fluent2Layer.groundOf(context);
    // On the desktop the bar spans the layer over the column: its ends on
    // the layer's gutters, never stopped at the column's 1120.
    final head = !pinned && bar != null
        ? Padding(
            padding: EdgeInsetsDirectional.only(
              start: side + roomStart,
              end: roomEnd,
            ),
            child: bar,
          )
        : null;

    Widget column(Widget content) {
      final inner = Padding(
        padding: EdgeInsetsDirectional.only(start: side),
        child: content,
      );
      if (!wide) return inner;
      return Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                Fluent2ChromeMetrics.pageMaxWidth + room.left + room.right,
          ),
          child: inner,
        ),
      );
    }

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
              child: Padding(
                padding: EdgeInsets.only(top: room.top + barRoom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ?head,
                    column(
                      Padding(
                        padding: room.copyWith(
                          top: 0,
                          bottom: room.bottom + reserve,
                        ),
                        child: _held(widget.body),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      content = Padding(
        padding: EdgeInsets.only(top: barRoom + room.top),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?head,
            Expanded(
              child: column(
                Padding(
                  padding: EdgeInsets.only(left: room.left, right: room.right),
                  child: MediaQuery(
                    data: mq.copyWith(
                      padding: mq.padding.copyWith(top: 0, bottom: reserve),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [Expanded(child: _held(widget.body))],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final stage = pinned
        ? Stack(
            fit: StackFit.expand,
            children: [
              content,
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                child: Fluent2ReportHeight(
                  onHeight: _measuredBar,
                  child: Fluent2BarBand(
                    top: top,
                    // The look's own bar stands its ends by what they show;
                    // another bar keeps the gutter less 4.
                    child: bar is Fluent2AppBar
                        ? Padding(
                            padding: EdgeInsetsDirectional.only(start: side),
                            child: Fluent2BarGutter(
                              start: roomStart,
                              end: roomEnd,
                              child: bar,
                            ),
                          )
                        : Padding(
                            padding: EdgeInsetsDirectional.only(
                              start: side + roomStart - Fluent2Spacing.xs,
                              end: roomEnd - Fluent2Spacing.xs,
                            ),
                            child: bar,
                          ),
                  ),
                ),
              ),
            ],
          )
        : content;

    return ColoredBox(
      color: ground,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: stage),
            if (footer != null)
              Fluent2BottomStand(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.colors.neutralBackground1,
                    border: Border(
                      top: BorderSide(color: t.colors.neutralStroke2),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      side + roomStart,
                      Fluent2Spacing.m,
                      roomEnd,
                      math.max(
                        Fluent2Spacing.m,
                        (mq.viewPadding.bottom - mq.viewInsets.bottom).clamp(
                          0.0,
                          double.infinity,
                        ),
                      ),
                    ),
                    child: Fluent2FooterBand(child: footer),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The screen's content as one keyline region: its sections, cards and
  /// fields start on one line and end on another (the keyline check).
  Widget _held(Widget body) => DesignKeylineRegion(
    label: switch (widget.topBar) {
      Fluent2AppBar(:final title?) => title,
      _ => 'Screen',
    },
    child: body,
  );

  Widget _onCard(BuildContext context, Widget? bar) {
    final wide = Fluent2Layout.isWide(context);
    final room = Fluent2SheetShell.padding(context);
    final inset = wide ? 0.0 : MediaQuery.paddingOf(context).bottom;
    final footer = widget.footer;
    final parts = <Widget>[
      if (!wide) const Fluent2SheetHandle(),
      if (bar != null) ...[
        bar,
        const SizedBox(height: Fluent2ChromeMetrics.sheetBodyGap),
      ],
      if (widget.scroll)
        _held(widget.body)
      else
        Flexible(child: _held(widget.body)),
      if (footer != null) ...[
        const SizedBox(height: Fluent2ChromeMetrics.sheetFootGap),
        Fluent2FooterBand(child: footer),
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

/// The band a phone's bar is pinned in: the status bar's room over the
/// bar, both on the acrylic, a hairline under them. Plumbing of the screen.
class Fluent2BarBand extends StatelessWidget {
  /// The band a phone bar [child] is pinned in, [top] tall above it.
  const Fluent2BarBand({required this.top, required this.child, super.key});

  /// The status bar's room over the bar.
  final double top;

  /// The bar.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Fluent2Acrylic(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.colors.neutralStroke2)),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: top),
          child: child,
        ),
      ),
    );
  }
}
