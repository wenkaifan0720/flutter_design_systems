import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/bar_slot.dart';
import '../internal/footer_band.dart';
import '../internal/grabber.dart';
import '../internal/side_inset.dart';
import '../theme.dart';
import 'sheet.dart';
import 'top_bar.dart';

/// A page: its [body] on the paper, under the head its route earns. On a
/// phone the [topBar]'s paper strip is pinned over the page (the
/// wordmark, the bell and the avatar on a tab's page; the way back and what
/// the page is on a pushed one) and the page scrolls under it, its
/// masthead (a tab's date over its title) first; on the desktop the
/// masthead heads every page (a pushed one's with its crumb) beside the
/// sidebar. On a sheet's card the bar is the sheet's head.
///
/// The body stands in the page's room: the 24 gutter on a phone (56 on the
/// desktop), 28 under the masthead ([LedgerScreen.form]'s column 24 under
/// a phone's bar), 40 under its last section (48 on a
/// pushed page, 72 on the desktop), and over the tab bar the shell reserves
/// ([ShellInsets]). A [footer] (a review's send) stands in a band at the
/// page's foot, never on a nav root: the tab bar owns that edge. [scrollable]
/// false hands the body the room to scroll itself. Unset, the [topBar] is
/// derived ([LedgerTopBar] with the route's own exit); [LedgerTopBar.none]
/// draws no head at all. A [backdrop] (Home's [LedgerWatermark]) stands
/// behind the page's column, from under its bar, clipped to it.
///
/// ```dart
/// LedgerScreen(topBar: const LedgerTopBar(title: 'Goals', meta: 'Wednesday, October 28'), body: goals)
/// ```
///
/// ```dart
/// LedgerScreen.form(topBar: const LedgerTopBar(title: 'New entry'), footer: save, body: fields)
/// ```
class LedgerScreen extends StatelessWidget {
  /// A page.
  const LedgerScreen({
    super.key,
    required this.body,
    this.topBar,
    this.footer,
    this.scrollable = true,
    this.padding,
    this.backdrop,
  }) : _form = false;

  /// A flow step's form column (`.form-col`: the transfer, its review, done,
  /// the split, a new goal): on a phone it stands 24 under the bar, where a
  /// page's first section stands 28 (`.cell-first`); on the desktop both stand
  /// under the masthead's own 36.
  const LedgerScreen.form({
    super.key,
    required this.body,
    this.topBar,
    this.footer,
    this.scrollable = true,
    this.padding,
    this.backdrop,
  }) : _form = true;

  final bool _form;

  /// The page's content.
  final Widget body;

  /// The page's head; null derives it from the route.
  final Widget? topBar;

  /// Acts pinned at the page's foot (a pushed or sheet page only).
  final Widget? footer;

  /// Whether the screen scrolls the body (false: the body scrolls itself).
  final bool scrollable;

  /// The room round the body; null is the page's own.
  final EdgeInsetsGeometry? padding;

  /// A drawing behind the page's column (the source's `.main`, which clips
  /// it), filling it from under the bar: it places its own art.
  final Widget? backdrop;

  /// The footer band's room: 16 over its acts and 24 under them (the
  /// device's inset when larger), the gutter at its sides. DERIVED: the
  /// source stands its acts in the page.
  static const EdgeInsets footerInsets = EdgeInsets.fromLTRB(
    LedgerChromeMetrics.gutter,
    LedgerChromeMetrics.footerTop,
    LedgerChromeMetrics.gutter,
    LedgerChromeMetrics.footerFoot,
  );

  /// `.form-col { margin-top: 24px }`: a form's column under
  /// the phone's bar.
  static const double _formTop = 24;

  Widget? _resolveBar(BuildContext context) {
    final authored = topBar;
    if (authored != null) {
      return identical(authored, LedgerTopBar.none) ? null : authored;
    }
    return const LedgerTopBar();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final mq = MediaQuery.of(context);
    final register = RoutePresentation.of(context);
    final bar = _resolveBar(context);
    if (register == RoutePresentation.sheet &&
        LedgerSheetShell.around(context)) {
      return _onCard(context, bar);
    }
    final shellAllowance = ShellInsets.of(context);
    assert(
      shellAllowance == 0 || footer == null,
      'a nav root never owns the bottom edge: the shell\'s tab bar stands '
      'there; move the footer to a pushed, sheet, or shell-free page',
    );
    final wide = LedgerLayout.isWide(context);
    final side = LedgerSideInset.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final pushed = register != RoutePresentation.root;
    // The strip stands over the page on a phone; the page starts under it.
    // Beside a side bar or a rail (a tablet's) the masthead heads the page
    // instead: the side bar carries the wordmark and the owner.
    final strip = !wide && bar != null && side == 0;
    final top = mq.padding.top + (strip ? LedgerChromeMetrics.topBarHeight : 0);
    // The shell's allowance already spans the device inset, as does the
    // footer's band: a max, never a sum.
    final bodyInset = footer == null ? mq.padding.bottom : 0.0;
    final reserve = math.max(bodyInset, shellAllowance);
    final room =
        padding?.resolve(Directionality.of(context)) ??
        (wide
            ? LedgerInsets.screenWide
            : pushed
            ? LedgerInsets.screenPushed
            : LedgerInsets.screen);
    final masthead = bar == null
        ? null
        : LedgerBarSlotScope(slot: LedgerBarSlot.masthead, child: bar);
    // A phone's first section stands 28 under the masthead (a pushed page
    // has none, and starts 28 under its bar), a form's column 24
    // (`.form-col`); a page with no head starts at its top.
    final firstGap = !wide && masthead != null
        ? SizedBox(
            height: _form ? _formTop : LedgerChromeMetrics.firstSectionGap,
          )
        : null;
    Widget page(Widget content) => Padding(
      padding: EdgeInsetsDirectional.only(start: side),
      child: content,
    );
    final Widget content;
    if (scrollable) {
      content = MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: page(
            Stack(
              children: [
                if (backdrop != null)
                  Positioned(
                    left: 0,
                    top: top,
                    right: 0,
                    bottom: 0,
                    child: ClipRect(child: backdrop),
                  ),
                // The page for the keyline check: its masthead and its
                // sections on the gutter.
                DesignKeylineRegion(
                  label: 'page',
                  child: Padding(
                    padding: room.copyWith(
                      top: room.top + top,
                      bottom: room.bottom + reserve,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [?masthead, ?firstGap, body],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // The page's own scrollable spends the reserve.
      content = page(
        Padding(
          padding: EdgeInsets.only(
            top: top + room.top,
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
                ?masthead,
                ?firstGap,
                Expanded(child: body),
              ],
            ),
          ),
        ),
      );
    }
    return ColoredBox(
      color: t.background,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: content),
                  if (strip)
                    Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      child: LedgerBarSlotScope(
                        slot: LedgerBarSlot.strip,
                        child: bar,
                      ),
                    ),
                ],
              ),
            ),
            if (footer != null)
              LedgerBottomStand(
                // The band's acts stand 16 under its hairline (a Container
                // insets by the hairline, as CSS's border does).
                child: Container(
                  decoration: BoxDecoration(
                    color: t.background,
                    border: Border(top: BorderSide(color: t.hairline)),
                  ),
                  padding: footerInsets.copyWith(
                    left:
                        (rtl ? 0 : side) +
                        (wide ? room.left : footerInsets.left),
                    right:
                        (rtl ? side : 0) +
                        (wide ? room.right : footerInsets.right),
                    bottom: math.max(
                      footerInsets.bottom,
                      // An open keyboard swallows the home-indicator
                      // region, so the footer hugs it.
                      (mq.viewPadding.bottom - mq.viewInsets.bottom).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                  ),
                  child: LedgerFooterBand(child: footer!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The page as a sheet page's card draws it: the grip (on a phone), the
  /// sheet's head, the body 8 under it and the footer 20 under that.
  Widget _onCard(BuildContext context, Widget? bar) {
    final wide = LedgerLayout.isWide(context);
    final room = LedgerSheetShell.padding(context);
    final inset = wide ? 0.0 : MediaQuery.paddingOf(context).bottom;
    final parts = <Widget>[
      if (!wide) const LedgerGrabber(),
      if (bar != null) ...[
        bar,
        const SizedBox(height: LedgerChromeMetrics.sheetBodyTop),
      ],
      if (scrollable) body else Flexible(child: body),
      if (footer != null) ...[
        const SizedBox(height: LedgerChromeMetrics.sheetFootTop),
        LedgerFooterBand(child: footer!),
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
      child: scrollable
          ? SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: pad,
              child: column,
            )
          : Padding(padding: pad, child: column),
    );
  }
}
