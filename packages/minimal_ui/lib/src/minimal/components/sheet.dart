import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/centred_sheet_route.dart';
import '../internal/kit_paint.dart';
import '../internal/sheet_header.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button.dart';
import 'icon_button.dart';
import 'pressable.dart';

/// One action in a sheet's footer row — `Cancel` beside `Create habit`.
///
/// [isDefaultAction] is the confirming one: the accent button. The other is the
/// bordered secondary. A null [onPressed] DISMISSES the sheet, which is what a
/// Cancel does.
///
/// ```dart
/// MinimalSheetAction('Create habit', onPressed: create, isDefaultAction: true)
/// ```
@immutable
class MinimalSheetAction {
  /// An action saying [label].
  const MinimalSheetAction(
    this.label, {
    this.onPressed,
    this.isDefaultAction = false,
    this.enabled = true,
  });

  /// What it says.
  final String label;

  /// What the button performs; dismissing the sheet when null.
  final VoidCallback? onPressed;

  /// The confirming register: the accent button rather than the bordered
  /// one.
  final bool isDefaultAction;

  /// False shows the action dimmed and inert (a Create that waits for a
  /// name) — a null [onPressed] would dismiss instead.
  final bool enabled;
}

/// A sheet card's footer line — what [MinimalBottomSheet] prints under its
/// hairline, for a sheet PAGE (a [MinimalScaffold] in a [MinimalSheetPage]) to
/// pass as its `footer:`: the [accessory] (a "create another"
/// `MinimalSwitch(showLabel: true)`, a hint) at the leading edge, the
/// [leading] secondary and [trailing] confirming actions at the trailing
/// one. When the two do not share a line — a long label, a larger text
/// scale — they stack, each keeping its own edge. An action with no
/// `onPressed` dismisses the sheet.
///
/// ```dart
/// MinimalScaffold(topBar: const MinimalAppBar(title: 'New habit'), footer: MinimalSheetFooter(accessory: MinimalSwitch(value: another, onChanged: setAnother, label: 'Create another', showLabel: true), leading: const MinimalSheetAction('Cancel'), trailing: MinimalSheetAction('Create habit', onPressed: create, isDefaultAction: true)), body: form)
/// ```
class MinimalSheetFooter extends StatelessWidget {
  /// A sheet's footer line.
  const MinimalSheetFooter({
    super.key,
    this.accessory,
    this.leading,
    this.trailing,
  });

  /// What stands at its leading edge: a "create another" switch.
  final Widget? accessory;

  /// The secondary action.
  final MinimalSheetAction? leading;

  /// The confirming action.
  final MinimalSheetAction? trailing;

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
    final trailing = this.trailing;
    Widget action(MinimalSheetAction a) => MinimalButton(
      a.label,
      variant: a.isDefaultAction
          ? MinimalButtonVariant.primary
          : MinimalButtonVariant.secondary,
      onPressed: !a.enabled
          ? null
          : a.onPressed ?? () => Navigator.of(context).maybePop(),
    );
    return _footer(
      accessory: accessory,
      // Two long labels at a large text scale stack as well, the
      // confirming one lowest.
      actions: OverflowBar(
        spacing: MinimalSpacing.s8,
        overflowSpacing: MinimalSpacing.s8,
        overflowAlignment: OverflowBarAlignment.end,
        children: [
          if (leading != null) action(leading),
          if (trailing != null) action(trailing),
        ],
      ),
    );
  }

  /// The footer line: the accessory at the leading edge and the actions at
  /// the trailing one, or, when both do not fit, the two stacked — the
  /// accessory keeping the leading edge, the actions under it at the
  /// trailing one. The line hugs its 32 px buttons, so it hands their (and
  /// a switch's) 44 px targets on.
  static Widget _footer({required Widget? accessory, required Widget actions}) {
    if (accessory == null) {
      return MinimalHitTarget(
        child: Align(alignment: AlignmentDirectional.centerEnd, child: actions),
      );
    }
    return MinimalHitTarget(child: _FooterLine(children: [accessory, actions]));
  }
}

/// The sheet card itself — Minimal's compact modal card: the surface on a
/// 1 px border at the theme's sheet radius, a large soft shadow, a header
/// band (the context pill, the title, the close `x`), the content, and a
/// footer row of actions over a hairline. [showMinimalBottomSheet] presents
/// this
/// same widget modally; compose it statically for an anchored panel or a
/// gallery frame.
///
/// `floating: true` is the modal card's register (inset from the screen by
/// [MinimalChromeMetrics.sheetInset], rounded on every corner); the default is
/// the edge-attached drawer, full width and rounded at the top. Raised from
/// the bottom of a wide window, either stands centred, at most
/// [centredWidth] wide ([widthCap]).
///
/// [style] dresses one card, `components.bottomSheet` every one: fill, edge
/// or side and shape (else `shapes.large`; the drawer keeps its top
/// corners only). The header, the actions and the content keep their own.
///
/// ```dart
/// MinimalBottomSheet(title: 'New habit', subtitle: 'Habits', floating: true, trailing: const MinimalSheetAction('Create habit', isDefaultAction: true), child: form)
/// ```
class MinimalBottomSheet extends StatelessWidget {
  /// A sheet card around [child].
  const MinimalBottomSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.safe = false,
    this.floating = false,
    this.closable = true,
    this.leading,
    this.trailing,
    this.accessory,
    this.style,
  });

  /// What the sheet is: after a [subtitle] pill, the header's quiet crumb;
  /// alone, in the ink at medium weight.
  final String? title;

  /// What the sheet acts in (a project, a team), printed as the header's
  /// pill before the title.
  final String? subtitle;

  /// The sheet's content.
  final Widget child;

  /// Apply the bottom safe-area inset inside the card: the drawer's, which
  /// stands on the screen's own bottom edge.
  final bool safe;

  /// Whether it is the inset modal card, rather than the full-width drawer.
  final bool floating;

  /// Draw the header's close `x`, which pops the route the card stands in.
  final bool closable;

  /// The footer's actions, right-aligned in reading order: the secondary
  /// [leading] then the confirming [trailing]. A card with neither and no
  /// [accessory] keeps no footer.
  final MinimalSheetAction? leading;

  /// The footer's confirming action.
  final MinimalSheetAction? trailing;

  /// The footer's leading-edge slot, beside the actions: a "create another"
  /// toggle (`MinimalSwitch(showLabel: true)`), a hint, at its own width.
  /// When it and the actions do not fit one line — a long label, a larger
  /// text scale — the actions drop under it rather than squeezing either,
  /// the accessory keeping the leading edge.
  final Widget? accessory;

  /// This card's style, over `components.bottomSheet`.
  final MinimalStyle? style;

  /// The card's outline: [style]'s, else `components.bottomSheet`'s, else
  /// `shapes.large`; the drawer ([floating] false) keeps its top corners
  /// only.
  static OutlinedBorder shapeOf(
    MinimalThemeData t, {
    required bool floating,
    MinimalStyle? style,
  }) {
    final shape =
        MinimalStyleOf([style, t.components.bottomSheet], const {}).shape ??
        t.shapes.large;
    return floating ? shape : _topOnly(shape);
  }

  /// The card's decoration, shared by the shell and a sheet page's card:
  /// the surface, a rim all round, [shapeOf]'s outline and the large
  /// shadow.
  static Decoration card(
    MinimalThemeData t, {
    required bool floating,
    MinimalStyle? style,
  }) {
    final so = MinimalStyleOf([style, t.components.bottomSheet], const {});
    return minimalFrame(
      shapeOf(t, floating: floating, style: style),
      fill: so.fill ?? t.card,
      side: so.rim(t.border, t.rim),
      shadows: t.shadowLg,
    );
  }

  /// [child] in the card: [card]'s decoration, clipped to [shapeOf]'s
  /// outline. What a sheet page and a kit's own sheet stand in.
  static Widget frame(
    MinimalThemeData t, {
    required bool floating,
    required Widget child,
    MinimalStyle? style,
  }) => DecoratedBox(
    decoration: card(t, floating: floating, style: style),
    child: minimalClip(
      shapeOf(t, floating: floating, style: style),
      child: MinimalGroundFill(
        fill:
            MinimalStyleOf([style, t.components.bottomSheet], const {}).fill ??
            t.card,
        child: child,
      ),
    ),
  );

  /// [shape] with its bottom corners squared: the drawer's, which stands on
  /// the screen's bottom edge.
  static OutlinedBorder _topOnly(OutlinedBorder shape) {
    BorderRadius top(BorderRadiusGeometry r) {
      final c = r.resolve(TextDirection.ltr);
      return BorderRadius.only(topLeft: c.topLeft, topRight: c.topRight);
    }

    return switch (shape) {
      final RoundedRectangleBorder s => s.copyWith(
        borderRadius: top(s.borderRadius),
      ),
      final BeveledRectangleBorder s => s.copyWith(
        borderRadius: top(s.borderRadius),
      ),
      final ContinuousRectangleBorder s => s.copyWith(
        borderRadius: top(s.borderRadius),
      ),
      final RoundedSuperellipseBorder s => s.copyWith(
        borderRadius: top(s.borderRadius),
      ),
      _ => shape,
    };
  }

  /// The motion both presenting paths run: a hard decelerate up, a quick
  /// accelerate away — and nothing at all with [MinimalMotion.animate] off
  /// (and, through [motionOf], under the platform's reduce-motion setting).
  static AnimationStyle get motion => MinimalMotion.animate
      ? const AnimationStyle(
          duration: MinimalChromeMetrics.sheetIn,
          curve: Curves.easeOutCubic,
          reverseDuration: MinimalChromeMetrics.sheetOut,
          reverseCurve: Curves.easeInCubic,
        )
      : AnimationStyle.noAnimation;

  /// [motion] as the presenting [context] sees it: nothing at all under the
  /// platform's reduce-motion setting too.
  static AnimationStyle motionOf(BuildContext context) =>
      context.minimalStill ? AnimationStyle.noAnimation : motion;

  /// Where a floating card stands above the bottom edge: the sheet margin,
  /// or the home indicator's band when that is taller.
  static double bottomGap(BuildContext context) => math.max(
    MinimalChromeMetrics.sheetInset,
    MediaQuery.paddingOf(context).bottom,
  );

  /// The tallest a card may grow on the presenting screen: everything
  /// below the status bar's band and [MinimalChromeMetrics.sheetTopGap], less
  /// the gap it stands on.
  static double cap(BuildContext context, {required bool floating}) =>
      MediaQuery.sizeOf(context).height -
      MediaQuery.paddingOf(context).top -
      MinimalChromeMetrics.sheetTopGap -
      (floating ? bottomGap(context) : 0);

  /// The modal route a declared sheet page rides: the same card
  /// [showMinimalBottomSheet] presents, carrying one whole page — a
  /// [MinimalScaffold], whose derived bar
  /// prints the card's header and whose close pops this route. The card
  /// rides as low as the page is tall, up to [cap], and no wider than
  /// [widthCap], centred. Model-authored code
  /// presents its own pickers with [showMinimalBottomSheet] and never builds
  /// this route.
  static ModalRoute<T> pageRoute<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool floating = true,
  }) {
    final t = context.minimalTheme;
    // Measured on the presenting screen, not inside the route: the modal
    // layer strips the top inset and would report none.
    final gap = floating ? bottomGap(context) : 0.0;
    final maxHeight = cap(context, floating: floating);
    return ModalBottomSheetRoute<T>(
      settings: settings,
      backgroundColor: const Color(0x00000000),
      elevation: 0,
      modalBarrierColor: t.overlay,
      isScrollControlled: true,
      constraints: widthCap(floating: floating),
      sheetAnimationStyle: motionOf(context),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: floating ? MinimalChromeMetrics.sheetInset : 0,
          right: floating ? MinimalChromeMetrics.sheetInset : 0,
          bottom: gap + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: _PageCard(floating: floating, child: builder(sheetContext)),
        ),
      ),
    );
  }

  /// The widest a sheet card stands: a sheet page centred in a wide window
  /// ([centredRoute]), and a sheet rising from the bottom of one
  /// ([widthCap]). A dialog (340) and a side sheet (380) stay narrower; a
  /// sheet carries a form.
  static const double centredWidth = 560;

  /// The width a card rising from the bottom edge may take: [centredWidth],
  /// plus the floating card's side margins. Its route centres it under
  /// that, so on a wide window the card stands in the middle rather than
  /// spanning the window; a phone is narrower and sees no change.
  static BoxConstraints widthCap({required bool floating}) => BoxConstraints(
    maxWidth:
        centredWidth + (floating ? 2 * MinimalChromeMetrics.sheetInset : 0),
  );

  /// Whether a sheet page raised in a window [width] wide stands as a
  /// centred card rather than rising from the bottom edge: from
  /// [MinimalLayout.expanded], where the shell stands its tabs in a rail.
  static bool centresAt(double width) => width >= MinimalLayout.expanded;

  /// The route a declared sheet page rides in a wide window: [pageRoute]'s
  /// card, every corner rounded, centred over the dimmed page at most
  /// [centredWidth] wide, fading in and out as a dialog does (none at all
  /// when motion is off). The scrim and Escape dismiss it. A
  /// [MinimalSheetPage] takes it by itself where [centresAt] says so.
  static Route<T> centredRoute<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    final t = context.minimalTheme;
    final still = context.minimalStill;
    return MinimalCentredSheetRoute<T>(
      settings: settings,
      barrierColor: t.overlay,
      barrierLabel: MinimalLocalizations.of(context).dismiss,
      transitionDuration: still ? Duration.zero : MinimalChromeMetrics.fadeIn,
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation.drive(CurveTween(curve: MinimalMotion.out)),
        child: child,
      ),
      pageBuilder: (routeContext, _, _) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(MinimalSpacing.s48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: centredWidth),
              child: _PageCard(floating: true, child: builder(routeContext)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final leading = this.leading;
    final trailing = this.trailing;
    final accessory = this.accessory;
    final hasFooter = leading != null || trailing != null || accessory != null;

    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinimalChromeMetrics.sheetPad,
      ),
      child: child,
    );

    // Bounded (a modal card under its cap), the content takes what the
    // header and footer leave and scrolls inside; composed in a scrolling
    // body, the card is simply as tall as it is.
    Widget column(bool bounded) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MinimalGap(MinimalSpacing.s4),
        MinimalSheetHeader(
          title: title,
          scope: subtitle,
          close: closable
              ? MinimalIconButton(
                  LucideIcons.x,
                  label: MinimalLocalizations.of(context).close,
                  variant: MinimalIconButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
        ),
        if (bounded) Flexible(child: body) else body,
        if (hasFooter)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MinimalChromeMetrics.sheetPad,
              MinimalSpacing.s16,
              MinimalChromeMetrics.sheetPad,
              MinimalSpacing.s12,
            ),
            child: Container(
              padding: const EdgeInsets.only(top: MinimalSpacing.s12),
              decoration: BoxDecoration(border: Border(top: t.rule)),
              child: MinimalSheetFooter(
                accessory: accessory,
                leading: leading,
                trailing: trailing,
              ),
            ),
          )
        else
          const MinimalGap(MinimalChromeMetrics.sheetPad),
      ],
    );

    // The shell supplies its own transparent Material, so a static card
    // composed outside any Scaffold still gives its text Material's
    // defaults. It paints nothing and takes no shape.
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        decoration: card(t, floating: floating, style: style),
        child: SafeArea(
          top: false,
          bottom: safe,
          child: LayoutBuilder(
            builder: (context, constraints) =>
                column(constraints.hasBoundedHeight),
          ),
        ),
      ),
    );
  }
}

/// Present a transient modal sheet from a control — a picker, a filter, a
/// short create form — over the whole app, on the root navigator. A page
/// declared as a sheet is raised by [MinimalSheetPage] instead, and its close
/// is derived.
///
/// The card rises from the bottom over [MinimalChromeMetrics.sheetIn] on a
/// dimmed page, rides as low as its content is tall, and lifts with the
/// keyboard so a sheet that edits never hides its own field. On a window
/// wider than [MinimalBottomSheet.centredWidth] it stands centred at that
/// width, as a dialog does, rather than spanning the window. Drag it down or
/// tap the scrim to dismiss. `floating: false` presents the edge-attached
/// drawer instead.
///
/// ```dart
/// await showMinimalBottomSheet<void>(context, title: 'New habit', subtitle: 'Habits', trailing: MinimalSheetAction('Create habit', onPressed: create, isDefaultAction: true), builder: (context) => form);
/// ```
Future<T?> showMinimalBottomSheet<T>(
  BuildContext context, {
  String? title,
  String? subtitle,
  required WidgetBuilder builder,
  bool floating = true,
  MinimalSheetAction? leading,
  MinimalSheetAction? trailing,
  Widget? accessory,
}) {
  final t = context.minimalTheme;
  final gap = floating ? MinimalBottomSheet.bottomGap(context) : 0.0;
  final maxHeight = MinimalBottomSheet.cap(context, floating: floating);
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: const Color(0x00000000),
    elevation: 0,
    barrierColor: t.overlay,
    isScrollControlled: true,
    useRootNavigator: true,
    sheetAnimationStyle: MinimalBottomSheet.motionOf(context),
    // The cap applies to the card inside its bottom gap, exactly as
    // [pageRoute] applies it, so a shown card and a sheet page of the same
    // content stand the same height. On a wide window the card stands
    // centred, at most [MinimalBottomSheet.centredWidth] wide.
    constraints: MinimalBottomSheet.widthCap(floating: floating),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: floating ? MinimalChromeMetrics.sheetInset : 0,
        right: floating ? MinimalChromeMetrics.sheetInset : 0,
        bottom: gap + MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: MinimalBottomSheet(
          title: title,
          subtitle: subtitle,
          leading: leading,
          trailing: trailing,
          accessory: accessory,
          floating: floating,
          safe: !floating,
          child: SingleChildScrollView(child: builder(sheetContext)),
        ),
      ),
    ),
  );
}

/// The card a sheet page stands in: [MinimalBottomSheet.card]'s decoration,
/// clipped to its corners, with the page drawing its own header. The
/// floating card has already stood clear of the home indicator, so the page
/// inside sees no bottom inset; the drawer keeps it.
class _PageCard extends StatelessWidget {
  const _PageCard({required this.floating, required this.child});

  final bool floating;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MinimalBottomSheet.frame(
      context.minimalTheme,
      floating: floating,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: floating,
        child: child,
      ),
    );
  }
}

/// The sheet footer's two slots — the accessory and the actions — on one
/// line, the accessory at the leading edge and the actions at the trailing
/// one; when both do not fit, stacked, each keeping its own edge.
class _FooterLine extends MultiChildRenderObjectWidget {
  const _FooterLine({required super.children});

  static const double _gap = MinimalSpacing.s12;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFooterLine(Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderFooterLine render) {
    render.textDirection = Directionality.of(context);
  }
}

class _FooterLineParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderFooterLine extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FooterLineParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FooterLineParentData> {
  _RenderFooterLine(this._textDirection);

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FooterLineParentData) {
      child.parentData = _FooterLineParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var widest = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      widest = math.max(widest, child.getMinIntrinsicWidth(height));
    }
    return widest;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var total = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (total > 0) total += _FooterLine._gap;
      total += child.getMaxIntrinsicWidth(height);
    }
    return total;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _measure(BoxConstraints(maxWidth: width), dry: true).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _measure(constraints, dry: true);

  @override
  void performLayout() {
    size = _measure(constraints, dry: false);
  }

  Size _measure(BoxConstraints constraints, {required bool dry}) {
    final loose = constraints.loosen();
    final sizes = <Size>[
      for (var child = firstChild; child != null; child = childAfter(child))
        dry
            ? child.getDryLayout(loose)
            : (child..layout(loose, parentUsesSize: true)).size,
    ];
    if (sizes.isEmpty) return constraints.smallest;
    final rtl = _textDirection == TextDirection.rtl;
    final together =
        sizes.fold<double>(0, (sum, s) => sum + s.width) +
        _FooterLine._gap * (sizes.length - 1);
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : together;
    final line = together <= width;
    final height = line
        ? sizes.map((s) => s.height).reduce(math.max)
        : sizes.fold<double>(0, (sum, s) => sum + s.height) +
              _FooterLine._gap * (sizes.length - 1);
    if (!dry) {
      var y = 0.0;
      var i = 0;
      for (var child = firstChild; child != null; child = childAfter(child)) {
        final s = sizes[i];
        // The first slot keeps the leading edge, the last the trailing one.
        final leading = i == 0;
        final x = leading == !rtl ? 0.0 : width - s.width;
        final data = child.parentData! as _FooterLineParentData;
        data.offset = Offset(x, line ? (height - s.height) / 2 : y);
        y += s.height + _FooterLine._gap;
        i += 1;
      }
    }
    return constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
