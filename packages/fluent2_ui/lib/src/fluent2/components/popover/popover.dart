import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/arrow.dart';
import '../../internal/hit_slop.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../host.dart';
import '../pressable/pressable.dart';
import '../tooltip/arrow_placement.dart';

import 'package:ui_core/ui_core.dart';

/// A flyout's face, Fluent's Popover `appearance`: [neutral] the surface (the
/// default), [brand] the brand fill, [inverted] the dark static plane.
enum Fluent2FlyoutAppearance {
  /// The neutral surface.
  neutral,

  /// The brand surface.
  brand,

  /// The inverted surface: dark on light, light on dark.
  inverted,
}

/// A flyout's room round its content, Fluent's Popover `size`: [small] 12 (a 6
/// arrow), [medium] 16 (the default, an 8 arrow), [large] 20.
enum Fluent2FlyoutSize {
  /// 12 round its content, a 6 arrow.
  small(12, 6),

  /// 16 round its content, an 8 arrow.
  medium(16, 8),

  /// 20 round its content, an 8 arrow.
  large(20, 8);

  /// A size of these measures.
  const Fluent2FlyoutSize(this.padding, this.arrow);

  /// The room round the flyout's content.
  final double padding;

  /// The arrow's height.
  final double arrow;
}

/// The fill and the ink of a flyout's [appearance] in [t], and its edge
/// (a hairline on the dark neutral surface, as the menu draws one).
(Color, Color, Color) fluent2FlyoutFace(
  Fluent2ThemeData t,
  Fluent2FlyoutAppearance appearance,
) => switch (appearance) {
  Fluent2FlyoutAppearance.neutral => (
    t.colors.neutralBackground1,
    t.colors.neutralForeground1,
    t.isDark ? t.colors.neutralStroke2 : t.colors.transparentStroke,
  ),
  Fluent2FlyoutAppearance.brand => (
    t.colors.brandBackground,
    t.colors.neutralForegroundOnBrand,
    t.colors.transparentStroke,
  ),
  Fluent2FlyoutAppearance.inverted => (
    t.colors.neutralBackgroundStatic,
    t.colors.neutralForegroundStaticInverted,
    t.colors.transparentStroke,
  ),
};

/// Fluent 2's Popover surface (the Flyout of Fluent's desktop libraries,
/// so named beside the fields' anchored listbox holder), drawn in place: [child] in body1 on
/// the [appearance]'s face, 4 corners, the size's room round it, `shadow16`;
/// with [arrowAt] its arrow on the edge facing the control ([arrowUp]: the
/// popover hangs under it), its centre [arrowAt] from the start. Open one
/// anchored to a control with [show]. Content that teaches a control is a
/// [Fluent2TeachingPopover].
///
/// ```dart
/// Fluent2Flyout(child: Text('Shared with 4 people'))
/// ```
class Fluent2Flyout extends StatelessWidget {
  /// A flyout anchored to [child] (Fluent's Popover).
  const Fluent2Flyout({
    required this.child,
    this.appearance = Fluent2FlyoutAppearance.neutral,
    this.size = Fluent2FlyoutSize.medium,
    this.arrowAt,
    this.arrowUp = true,
    this.minWidth = 0,
    this.maxWidth = 360,
    this.radius = Fluent2Radius.medium,
    super.key,
  }) : _placement = null;

  const Fluent2Flyout._placed({
    required this.child,
    required this.appearance,
    required this.size,
    required Fluent2ArrowPlacement this._placement,
    this.minWidth = 0,
    this.maxWidth = 360,
    this.radius = Fluent2Radius.medium,
  }) : arrowAt = null,
       arrowUp = true;

  /// The anchor the flyout opens from.
  final Widget child;

  /// Fluent's `appearance`: the neutral, brand or inverted surface.
  final Fluent2FlyoutAppearance appearance;

  /// Fluent's `size`: the room round its content.
  final Fluent2FlyoutSize size;

  /// The arrow's centre from the popover's start edge; null draws none.
  final double? arrowAt;

  /// The arrow on the top edge (the popover under its control); false
  /// puts it at the foot.
  final bool arrowUp;

  /// The narrowest the flyout stands.
  final double minWidth;

  /// The widest the flyout stands.
  final double maxWidth;

  /// Its corners: Fluent's 4 (a teaching popover's 8).
  final double radius;
  final Fluent2ArrowPlacement? _placement;

  /// Opens [builder]'s content in a popover anchored to the control
  /// [context] belongs to (a [Builder] round it): above it by default
  /// (Fluent's `above`, centred), under it when there is no room, its
  /// arrow at the control unless [withArrow] is false; a tap outside or
  /// Escape dismisses it, completing with null. Focus is held inside it
  /// while open.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    Fluent2FlyoutAppearance appearance = Fluent2FlyoutAppearance.neutral,
    Fluent2FlyoutSize size = Fluent2FlyoutSize.medium,
    bool withArrow = true,
    bool preferBelow = false,
    double minWidth = 0,
    double maxWidth = 360,
    String? label,
  }) {
    final navigator = Fluent2Host.navigatorOf(context);
    final box = context.findRenderObject()! as RenderBox;
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final rect = Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    );
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    final placement = Fluent2ArrowPlacement();
    return navigator.push(
      _PopoverRoute<T>(
        anchor: rect,
        barrier: DesignLocalizations.of(context).modalBarrierDismissLabel,
        placement: placement,
        gap: withArrow ? 0 : Fluent2Spacing.xs,
        preferBelow: preferBelow,
        builder: (popContext) => themes.wrap(
          Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: label ?? Fluent2Localizations.of(context).popover,
            child: withArrow
                ? Fluent2Flyout._placed(
                    appearance: appearance,
                    size: size,
                    placement: placement,
                    minWidth: minWidth,
                    maxWidth: maxWidth,
                    child: Builder(builder: builder),
                  )
                : Fluent2Flyout(
                    appearance: appearance,
                    size: size,
                    minWidth: minWidth,
                    maxWidth: maxWidth,
                    child: Builder(builder: builder),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final (fill, ink, edge) = fluent2FlyoutFace(t, appearance);
    final surface = ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: edge),
          boxShadow: t.shadows.shadow16,
        ),
        child: Padding(
          padding: EdgeInsets.all(size.padding - 1),
          child: DefaultTextStyle.merge(
            style: t.body1.c(ink),
            child: IconTheme.merge(
              data: IconThemeData(color: ink),
              child: child,
            ),
          ),
        ),
      ),
    );
    final placed = _placement;
    final at = arrowAt;
    if (placed == null && at == null) return surface;
    return CustomPaint(
      foregroundPainter: _PopoverArrowPainter(
        placed: placed,
        at: at,
        up: arrowUp,
        rtl: Directionality.of(context) == TextDirection.rtl,
        fill: fill,
        height: size.arrow,
        corner: radius,
      ),
      child: Padding(
        padding: placed != null
            ? EdgeInsets.symmetric(vertical: size.arrow)
            : EdgeInsets.only(
                top: arrowUp ? size.arrow : 0,
                bottom: arrowUp ? 0 : size.arrow,
              ),
        child: surface,
      ),
    );
  }
}

class _PopoverArrowPainter extends CustomPainter {
  _PopoverArrowPainter({
    required this.placed,
    required this.at,
    required this.up,
    required this.rtl,
    required this.fill,
    required this.height,
    required this.corner,
  });

  /// Where the route placed it; null for one drawn in place.
  final Fluent2ArrowPlacement? placed;

  /// Drawn in place: the arrow's centre from the start edge, on the top
  /// edge when [up].
  final double? at;
  final bool up;
  final bool rtl;
  final Color fill;
  final double height;
  final double corner;

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        placed ??
        (Fluent2ArrowPlacement()
          ..isAbove = !up
          ..offset = rtl ? size.width - at! : at!);
    fluent2PaintArrow(
      canvas,
      size,
      placement: p,
      fill: fill,
      height: height,
      corner: corner,
    );
  }

  // The route's placement is written during layout, after this was made.
  @override
  bool shouldRepaint(_PopoverArrowPainter old) => true;
}

/// The route a popover rides: no scrim, dismissed by a tap outside, laid
/// above (or under) its anchor, centred on it and kept 8 inside the
/// window.
class _PopoverRoute<T> extends PopupRoute<T> {
  _PopoverRoute({
    required this.anchor,
    required this.barrier,
    required this.placement,
    required this.gap,
    required this.preferBelow,
    required this.builder,
  });

  final Rect anchor;
  final String barrier;
  final Fluent2ArrowPlacement placement;
  final double gap;
  final bool preferBelow;
  final WidgetBuilder builder;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => barrier;

  @override
  Duration get transitionDuration =>
      Fluent2Motion.of(navigator!.context, Fluent2Motion.normal);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Fluent2Motion.decelerateMid,
    ),
    child: CustomSingleChildLayout(
      delegate: _Beside(anchor, placement, gap, preferBelow),
      child: builder(context),
    ),
  );
}

class _Beside extends SingleChildLayoutDelegate {
  _Beside(this.anchor, this.placement, this.gap, this.preferBelow);

  final Rect anchor;
  final Fluent2ArrowPlacement placement;
  final double gap;
  final bool preferBelow;

  static const double _edge = Fluent2Spacing.s;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen().deflate(const EdgeInsets.all(_edge));

  @override
  Offset getPositionForChild(Size size, Size child) {
    final aboveY = anchor.top - gap - child.height;
    final belowY = anchor.bottom + gap;
    final fitsAbove = aboveY >= _edge;
    final fitsBelow = belowY + child.height <= size.height - _edge;
    final above = preferBelow
        ? fitsAbove && !fitsBelow
        : fitsAbove || !fitsBelow;
    final x = (anchor.center.dx - child.width / 2)
        .clamp(_edge, math.max(_edge, size.width - _edge - child.width))
        .toDouble();
    placement
      ..isAbove = above
      ..offset = anchor.center.dx - x;
    final y = (above ? aboveY : belowY)
        .clamp(_edge, math.max(_edge, size.height - _edge - child.height))
        .toDouble();
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_Beside old) =>
      old.anchor != anchor || old.gap != gap || old.preferBelow != preferBelow;
}

/// A teaching popover's footer button on its face: the brand popover's
/// pair inverted (the primary the light fill in the brand's words, the
/// secondary the brand fill inside a light stroke), the neutral one's
/// Fluent's own primary and secondary. Plumbing of the teaching popover.
class _TeachButton extends StatelessWidget {
  const _TeachButton(
    this.label, {
    required this.onTap,
    required this.primary,
    required this.brand,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool brand;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final radius = BorderRadius.circular(Fluent2Radius.medium);
    return Fluent2HitSlop(
      child: Fluent2Pressable(
        onPressed: onTap,
        label: label,
        radius: Fluent2Radius.medium,
        builder: (context, states) {
          final press = states.press;
          final Fluent2ButtonFace face;
          if (!brand) {
            face = Fluent2ButtonFace.of(
              t,
              primary
                  ? Fluent2ButtonAppearance.primary
                  : Fluent2ButtonAppearance.secondary,
              press,
            );
          } else if (primary) {
            // Fluent's brandForeground1 reads 2.6-3.1:1 on the light fill
            // in dark; the on-light brand words hold 5.4:1 and up.
            final ink = press.pick(
              c.brandForegroundOnLight,
              c.brandForegroundOnLightHover,
              c.brandForegroundOnLightPressed,
              c.neutralForegroundDisabled,
            );
            face = Fluent2ButtonFace(
              fill: c.neutralForegroundOnBrand,
              stroke: c.transparentStroke,
              ink: ink,
              glyph: ink,
            );
          } else {
            final base = Fluent2ButtonFace.of(
              t,
              Fluent2ButtonAppearance.primary,
              press,
            );
            face = Fluent2ButtonFace(
              fill: base.fill,
              stroke: c.neutralForegroundOnBrand,
              ink: base.ink,
              glyph: base.glyph,
            );
          }
          return Fluent2ButtonBox(
            face: face,
            radius: radius,
            height: 32,
            minWidth: 96,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.body1Strong.c(face.ink),
            ),
          );
        },
      ),
    );
  }
}

/// Fluent 2's TeachingPopover: a coach mark that teaches one control in
/// place, anchored to it by its arrow: the [title] in subtitle2, the
/// [body] in body1, then its acts at the end (the [secondaryLabel]
/// before the [primaryLabel], "Got it"), the step ("[step] of [steps]")
/// at the start of a tour, and the dismiss at the title's end. On the
/// brand fill by default, at least 320 wide, 16 round its content, 8
/// corners. It stays until an act or the dismiss closes it. Open one
/// anchored to the control with [show]; drawn in place it points with
/// [arrowAt]. Read as a dialog named by its title.
///
/// ```dart
/// Fluent2TeachingPopover(title: 'Pin your files', body: 'Pinned files stay at the top of Files for everyone on the team.', primaryLabel: 'Got it', onPrimaryPressed: close, step: 1, steps: 3)
/// ```
class Fluent2TeachingPopover extends StatelessWidget {
  /// A teaching popover: [title] and [body] with its acts.
  const Fluent2TeachingPopover({
    required this.title,
    required this.body,
    this.primaryLabel,
    this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.onDismiss,
    this.step,
    this.steps,
    this.appearance = Fluent2FlyoutAppearance.brand,
    this.arrowAt,
    this.arrowUp = true,
    this.dismissLabel,
    super.key,
  }) : _placement = null;

  const Fluent2TeachingPopover._placed({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    required this.onDismiss,
    required this.step,
    required this.steps,
    required this.appearance,
    required this.dismissLabel,
    required Fluent2ArrowPlacement this._placement,
  }) : arrowAt = null,
       arrowUp = true;

  /// The tip's title.
  final String title;

  /// The tip's words.
  final String body;

  /// The primary act's words; null is "Got it" in the app's language.
  final String? primaryLabel;

  /// Called by the primary act.
  final VoidCallback? onPrimaryPressed;

  /// The second act ("Not now", "Back"); null draws none.
  final String? secondaryLabel;

  /// Called by the second act.
  final VoidCallback? onSecondaryPressed;

  /// The dismiss at the title's end; null draws none.
  final VoidCallback? onDismiss;

  /// This step of a tour (1-based) and how many there are; null for a
  /// single tip.
  final int? step;

  /// How many steps the tour has; null for a single tip.
  final int? steps;

  /// [Fluent2FlyoutAppearance.brand] (the default) or the neutral surface.
  final Fluent2FlyoutAppearance appearance;

  /// Drawn in place: the arrow's centre from the start edge.
  final double? arrowAt;

  /// Drawn in place: the arrow on the top edge.
  final bool arrowUp;

  /// The dismiss's name; null is "Dismiss" in the app's language.
  final String? dismissLabel;
  final Fluent2ArrowPlacement? _placement;

  /// Opens a teaching popover anchored to the control [context] belongs
  /// to (a [Builder] round it), its arrow at it. An act or the dismiss
  /// closes it, completing with true for the primary act, false for the
  /// secondary and null for the dismiss; the callbacks run after it
  /// closes. A tap outside leaves it open.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String body,
    String? primaryLabel,
    VoidCallback? onPrimaryPressed,
    String? secondaryLabel,
    VoidCallback? onSecondaryPressed,
    bool dismissible = true,
    int? step,
    int? steps,
    Fluent2FlyoutAppearance appearance = Fluent2FlyoutAppearance.brand,
    bool preferBelow = true,
  }) async {
    final navigator = Fluent2Host.navigatorOf(context);
    final box = context.findRenderObject()! as RenderBox;
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final rect = Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    );
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    final placement = Fluent2ArrowPlacement();
    final result = await navigator.push(
      _TeachRoute(
        anchor: rect,
        placement: placement,
        preferBelow: preferBelow,
        barrier: Fluent2Localizations.of(context).teachingTip,
        builder: (popContext) => themes.wrap(
          Fluent2TeachingPopover._placed(
            title: title,
            body: body,
            primaryLabel: primaryLabel,
            onPrimaryPressed: () => Navigator.of(popContext).pop(true),
            secondaryLabel: secondaryLabel,
            onSecondaryPressed: secondaryLabel == null
                ? null
                : () => Navigator.of(popContext).pop(false),
            onDismiss: dismissible
                ? () => Navigator.of(popContext).pop()
                : null,
            step: step,
            steps: steps,
            appearance: appearance,
            dismissLabel: null,
            placement: placement,
          ),
        ),
      ),
    );
    if (result == true) onPrimaryPressed?.call();
    if (result == false) onSecondaryPressed?.call();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final brand = appearance == Fluent2FlyoutAppearance.brand;
    final (_, ink, _) = fluent2FlyoutFace(t, appearance);
    final quiet = brand ? ink : t.textSecondary;
    final dismiss = onDismiss;
    final words = Fluent2Localizations.of(context);
    final count = step != null && steps != null ? '$step of $steps' : null;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Fluent2Spacing.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: t.subtitle2.c(ink)),
                ),
              ),
              if (dismiss != null)
                Fluent2IconButton(
                  Fluent2Icons.dismiss,
                  label: dismissLabel ?? words.dismiss,
                  size: Fluent2ButtonSize.small,
                  appearance: Fluent2ButtonAppearance.transparent,
                  color: quiet,
                  onPressed: dismiss,
                ),
            ],
          ),
        ),
        Text(body, style: t.body1.c(ink)),
        const SizedBox(height: Fluent2Spacing.xxl),
        Row(
          children: [
            if (count != null)
              Text(
                count,
                style: t.caption1.tabular.c(quiet),
                semanticsLabel: words.stepOf(step!, steps!),
              ),
            // The acts at the end, each whole: past the row's room (a large
            // text size) they run on to a second line, never cut.
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: Fluent2Spacing.s,
                runSpacing: Fluent2Spacing.s,
                children: [
                  if (secondaryLabel != null)
                    _TeachButton(
                      secondaryLabel!,
                      onTap: onSecondaryPressed,
                      primary: false,
                      brand: brand,
                    ),
                  _TeachButton(
                    primaryLabel ?? words.gotIt,
                    onTap: onPrimaryPressed,
                    primary: true,
                    brand: brand,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
    final placed = _placement;
    final pop = placed != null
        ? Fluent2Flyout._placed(
            appearance: appearance,
            size: Fluent2FlyoutSize.medium,
            placement: placed,
            maxWidth: 360,
            radius: Fluent2Radius.xLarge,
            child: content,
          )
        : Fluent2Flyout(
            appearance: appearance,
            arrowAt: arrowAt,
            arrowUp: arrowUp,
            maxWidth: 360,
            radius: Fluent2Radius.xLarge,
            child: content,
          );
    return Semantics(
      scopesRoute: placed != null,
      namesRoute: placed != null,
      explicitChildNodes: true,
      label: title,
      child: LayoutBuilder(
        // At least 320 wide where the window has the room, at most its 360
        // even where a column stretches it: it stands at the start.
        builder: (context, box) {
          final sized = ConstrainedBox(
            constraints: BoxConstraints(minWidth: math.min(320, box.maxWidth)),
            child: pop,
          );
          // Placed by its route, it is laid out at its own size already.
          if (placed != null) return sized;
          return Align(
            alignment: AlignmentDirectional.topStart,
            widthFactor: box.hasBoundedWidth ? null : 1,
            heightFactor: 1,
            child: sized,
          );
        },
      ),
    );
  }
}

/// The route a teaching popover rides: as a popover's, but a tap outside
/// leaves it open (it stays until an act or the dismiss).
class _TeachRoute extends _PopoverRoute<bool> {
  _TeachRoute({
    required super.anchor,
    required super.placement,
    required super.preferBelow,
    required super.builder,
    required super.barrier,
  }) : super(gap: 0);

  @override
  bool get barrierDismissible => false;
}
