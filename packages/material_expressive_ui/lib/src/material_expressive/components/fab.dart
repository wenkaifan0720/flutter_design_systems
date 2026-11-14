/// Floating action buttons (CONTRACT §4.1 `fab`; the shell's action is `shell_action.dart`'s):
/// ports of Compose material3 1.5.0-alpha29's `FloatingActionButton.kt` and
/// `FloatingActionButtonMenu.kt`.
///
/// - [ExpressiveFloatingActionButton]: `FloatingActionButton`, `MediumFloatingActionButton`
///   and `LargeFloatingActionButton` (56, 80, 96dp; the 40dp small FAB is
///   skipped, §4.1) in six colour styles ([ExpressiveFabColor]).
/// - [ExpressiveFloatingActionButton.extended]: `Small`/`Medium`/`LargeExtendedFloatingActionButton`
///   with `expanded`, its width and label springing between the labelled pill
///   and the bare FAB; [ExpressiveFabScrollExpansion] collapses it while the
///   page scrolls down.
/// - [ExpressiveFabMenu]: `FloatingActionButtonMenu` with its
///   `ToggleFloatingActionButton` (the FAB morphs into the round close button)
///   and 2–5 [ExpressiveFabMenuItem]s that stagger in. A hero widget (§3):
///   it asserts an [ExpressiveHeroMoment] above it and 2–5 items, and never opens
///   from an extended FAB. [ExpressiveFabMenu.countOn] and
///   [ExpressiveFabMenu.debugCheckNoMenuBeside] let a toolbar or rail assert
///   the "no FAB menu beside a toolbar or rail" rule.
/// - `ExpressiveShellAction` (`shell_action.dart`): the shell's action, the design kit's
///   [ShellAction] plus `menu:`; as a widget, it draws any spec.
///
/// Geometry, colours, shapes, elevation and springs come from the generated
/// tokens (`FabBaselineTokens`, `FabMediumTokens`, `FabLargeTokens`,
/// `ExtendedFab*Tokens`, `FabPrimaryContainerTokens`, `FabMenuBaselineTokens`)
/// and the behaviour constants (`FloatingActionButtonBehavior`,
/// `FloatingActionButtonMenuBehavior`). Owner: w2-fab.
library;

import 'dart:math' as math;

import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../color.dart';
import '../component_themes.dart';
import '../elevation.dart';
import '../internal/cap_label.dart';
import '../internal/styled_content.dart';
import '../icons.dart';
import '../motion.dart';
import '../shape.dart';
import '../states.dart';
import '../theme.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/extended_fab_large_tokens.g.dart';
import '../internal/tokens/extended_fab_medium_tokens.g.dart';
import '../internal/tokens/extended_fab_primary_tokens.g.dart';
import '../internal/tokens/extended_fab_small_tokens.g.dart';
import '../internal/tokens/fab_baseline_tokens.g.dart';
import '../internal/tokens/fab_large_tokens.g.dart';
import '../internal/tokens/fab_medium_tokens.g.dart';
import '../internal/tokens/fab_menu_baseline_tokens.g.dart';
import '../internal/tokens/fab_primary_container_tokens.g.dart';
import '../internal/tokens/fab_secondary_container_tokens.g.dart';
import '../internal/tokens/filled_button_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/scrim_tokens.g.dart';
import 'hero.dart';
import 'overlays.dart' show ExpressiveBackHandle;

// ---------------------------------------------------------------------------
// Styles and sizes
// ---------------------------------------------------------------------------

/// A FAB's colour style: Material's three container styles and the three
/// vibrant ones.
enum ExpressiveFabColor {
  /// `primaryContainer` / `onPrimaryContainer` (Compose's default,
  /// `FabPrimaryContainerTokens`).
  primaryContainer(
    FabPrimaryContainerTokens.containerColor,
    FabPrimaryContainerTokens.iconColor,
  ),

  /// `secondaryContainer` / `onSecondaryContainer`
  /// (`FabSecondaryContainerTokens`).
  secondaryContainer(
    FabSecondaryContainerTokens.containerColor,
    FabSecondaryContainerTokens.iconColor,
  ),

  /// `tertiaryContainer` / `onTertiaryContainer`.
  tertiaryContainer(
    ExpressiveColorRole.tertiaryContainer,
    ExpressiveColorRole.onTertiaryContainer,
  ),

  /// Vibrant `primary` / `onPrimary`.
  primary(ExpressiveColorRole.primary, ExpressiveColorRole.onPrimary),

  /// Vibrant `secondary` / `onSecondary`.
  secondary(ExpressiveColorRole.secondary, ExpressiveColorRole.onSecondary),

  /// Vibrant `tertiary` / `onTertiary`.
  tertiary(ExpressiveColorRole.tertiary, ExpressiveColorRole.onTertiary);

  const ExpressiveFabColor(this.container, this.content);

  /// The container's colour role.
  final ExpressiveColorRole container;

  /// The icon's and label's colour role (Compose's `contentColorFor`).
  final ExpressiveColorRole content;
}

/// A FAB's container and content: [color]'s roles, or, with no action, the
/// filled button's disabled ink (`onSurface` at 10% and 38%). Compose's FAB
/// has no disabled look and keeps its colours; a FAB an app disables here
/// reads as disabled, at the same size.
(Color, Color) _fabInk(
  ExpressiveColorScheme colors,
  ExpressiveFabColor color, {
  required bool enabled,
}) => enabled
    ? (colors.role(color.container), colors.role(color.content))
    : (
        colors
            .role(FilledButtonTokens.disabledContainerColor)
            .withValues(alpha: FilledButtonTokens.disabledContainerOpacity),
        colors
            .role(FilledButtonTokens.disabledLabelTextColor)
            .withValues(alpha: FilledButtonTokens.disabledLabelTextOpacity),
      );

/// A FAB's size. The plain FAB is 56, 80 or 96dp square; the extended FAB is
/// that tall (Compose's small, medium and large extended FABs).
enum ExpressiveFabSize {
  /// 56dp: `FloatingActionButton` / `SmallExtendedFloatingActionButton`.
  standard,

  /// 80dp: `MediumFloatingActionButton` / `MediumExtendedFloatingActionButton`.
  medium,

  /// 96dp: `LargeFloatingActionButton` / `LargeExtendedFloatingActionButton`.
  large,
}

/// The FAB's elevation by state (`FloatingActionButtonDefaults.elevation`
/// and `.loweredElevation`).
ExpressiveStateElevation _elevation({required bool lowered}) => lowered
    ? const ExpressiveStateElevation(
        rest: ExtendedFabPrimaryTokens.loweredContainerElevation,
        pressed: ExtendedFabPrimaryTokens.loweredPressedContainerElevation,
        focused: ExtendedFabPrimaryTokens.loweredFocusContainerElevation,
        hovered: ExtendedFabPrimaryTokens.loweredHoverContainerElevation,
        disabled: ExpressiveElevationLevel.level0,
      )
    : const ExpressiveStateElevation(
        rest: FabPrimaryContainerTokens.containerElevation,
        pressed: FabPrimaryContainerTokens.pressedContainerElevation,
        focused: FabPrimaryContainerTokens.focusedContainerElevation,
        hovered: FabPrimaryContainerTokens.hoveredContainerElevation,
        disabled: ExpressiveElevationLevel.level0,
      );

/// The spring a FAB's shadow changes on. Compose animates FAB elevation on
/// `ElevationDefaults`' tweens; Expressive runs springs only (F10), so the
/// shadow runs the fast effects spring.
const ExpressiveMotionKey _elevationMotion = ExpressiveMotionKey.fastEffects;

/// The plain FAB's geometry per size.
({double side, double icon, ExpressiveShapeKey shape}) _fabGeometry(
  ExpressiveFabSize size,
) => switch (size) {
  ExpressiveFabSize.standard => (
    side: FabBaselineTokens.containerHeight,
    icon: FabBaselineTokens.iconSize,
    shape: FabBaselineTokens.containerShape,
  ),
  ExpressiveFabSize.medium => (
    side: FabMediumTokens.containerHeight,
    icon: FabMediumTokens.iconSize,
    shape: FloatingActionButtonBehavior.mediumShape,
  ),
  ExpressiveFabSize.large => (
    side: FabLargeTokens.containerHeight,
    icon: FloatingActionButtonBehavior.largeIconSize,
    shape: FabLargeTokens.containerShape,
  ),
};

/// The extended FAB's geometry per size (`FloatingActionButton.kt`'s
/// private `*ExtendedFab*` values).
({
  double height,
  double icon,
  double leading,
  double trailing,
  double gap,
  ExpressiveShapeKey shape,
  ExpressiveTypeKey text,
})
_extendedGeometry(ExpressiveFabSize size) => switch (size) {
  ExpressiveFabSize.standard => (
    height: ExtendedFabSmallTokens.containerHeight,
    icon: ExtendedFabSmallTokens.iconSize,
    leading: ExtendedFabSmallTokens.leadingSpace,
    trailing: ExtendedFabSmallTokens.trailingSpace,
    gap: ExtendedFabSmallTokens.iconLabelSpace,
    shape: ExtendedFabSmallTokens.containerShape,
    // `SmallExtendedFabTextStyle = TypographyKeyTokens.TitleMedium`.
    text: ExpressiveTypeKey.titleMedium,
  ),
  ExpressiveFabSize.medium => (
    height: ExtendedFabMediumTokens.containerHeight,
    icon: ExtendedFabMediumTokens.iconSize,
    leading: ExtendedFabMediumTokens.leadingSpace,
    trailing: ExtendedFabMediumTokens.trailingSpace,
    gap: FloatingActionButtonBehavior.mediumExtendedFabIconPadding,
    shape: FloatingActionButtonBehavior.mediumExtendedFabShape,
    // `MediumExtendedFabTextStyle = TypographyKeyTokens.TitleLarge`.
    text: ExpressiveTypeKey.titleLarge,
  ),
  ExpressiveFabSize.large => (
    height: ExtendedFabLargeTokens.containerHeight,
    icon: ExtendedFabLargeTokens.iconSize,
    leading: ExtendedFabLargeTokens.leadingSpace,
    trailing: ExtendedFabLargeTokens.trailingSpace,
    gap: FloatingActionButtonBehavior.largeExtendedFabIconPadding,
    shape: ExtendedFabLargeTokens.containerShape,
    // `LargeExtendedFabTextStyle = TypographyKeyTokens.HeadlineSmall`.
    text: ExpressiveTypeKey.headlineSmall,
  ),
};

// ---------------------------------------------------------------------------
// FAB
// ---------------------------------------------------------------------------

/// The floating action button: the screen's one primary act, an icon on a
/// 56, 80 or 96dp rounded square (Compose's `FloatingActionButton`,
/// `MediumFloatingActionButton`, `LargeFloatingActionButton`).
///
/// One FAB per screen; in a shell, give the act to the shell
/// (`ExpressiveShellAction`) rather than placing a FAB yourself.
class ExpressiveFloatingActionButton extends StatelessWidget {
  /// A floating action button showing [icon] that runs [onPressed].
  const ExpressiveFloatingActionButton({
    required this.icon,
    required this.onPressed,
    this.style,
    this.semanticLabel,
    this.size = ExpressiveFabSize.standard,
    this.color = ExpressiveFabColor.primaryContainer,
    this.lowered = false,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : label = null,
       expanded = true,
       mark = null;

  /// An extended FAB (Flutter's `FloatingActionButton.extended`): the icon and a label on a pill 56, 80 or 96dp tall
  /// (Compose's `Small`/`Medium`/`LargeExtendedFloatingActionButton` with
  /// `expanded`). When [expanded] turns false the width springs down to the
  /// plain FAB's square and the label fades (`FloatingActionButtonBehavior`
  /// `expandSizeMotion`, `expandOpacityMotion`); [ExpressiveFabScrollExpansion]
  /// drives it from a scroll.
  const ExpressiveFloatingActionButton.extended({
    required this.icon,
    required String this.label,
    required this.onPressed,
    this.style,
    this.expanded = true,
    this.size = ExpressiveFabSize.standard,
    this.color = ExpressiveFabColor.primaryContainer,
    this.lowered = false,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    this.mark,
    super.key,
  }) : semanticLabel = null;

  /// The glyph: one of [ExpressiveSymbols].
  final IconData icon;

  /// What a tap does; null disables it: the filled button's disabled ink
  /// (Compose's FAB has no disabled look of its own), at the same size.
  final VoidCallback? onPressed;

  /// An extended FAB's act, printed beside the icon and always announced
  /// (collapsed too); null for a plain FAB.
  final String? label;

  /// Whether an extended FAB's label shows; false springs it down to the
  /// plain FAB's square.
  final bool expanded;

  /// An app's own mark drawn in an extended FAB's icon place (a brand or a
  /// persona's mark, not a glyph): laid out in the icon's square, in the
  /// FAB's content colour through the ambient `IconTheme`. [icon] still
  /// names the act's glyph for a system that cannot draw the mark.
  final Widget? mark;

  /// Stateful visual overrides before the FAB theme.
  final ExpressiveComponentThemeData? style;

  /// What a screen reader says: the act (`New message`).
  final String? semanticLabel;

  /// The size: 56, 80 or 96dp.
  final ExpressiveFabSize size;

  /// The colour style.
  final ExpressiveFabColor color;

  /// Whether the FAB sits low (`loweredElevation`: level 1 rather than 3),
  /// for a FAB over a surface that already floats.
  final bool lowered;

  /// A tooltip message, announced as the FAB's hint.
  final String? tooltip;

  /// The focus node; one is made when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    if (label != null) return _buildExtended(context);
    final t = context.expressiveTheme;
    final g = _fabGeometry(size);
    final (container, content) = _fabInk(
      t.colors,
      color,
      enabled: onPressed != null,
    );
    return ExpressivePressable(
      style: style,
      componentStyle: t.floatingActionButtonTheme,
      shapes: ExpressivePressShapes.all(t.shapes.of(g.shape)),
      motion: FloatingActionButtonBehavior.expandSizeMotion,
      color: container,
      contentColor: content,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      elevation: _elevation(lowered: lowered),
      elevationMotion: _elevationMotion,
      tonalElevation: FabPrimaryContainerTokens.containerElevation,
      focusNode: focusNode,
      autofocus: autofocus,
      child: ExpressiveStyledContent(
        minimumSize: Size.square(g.side),
        iconSize: g.icon,
        child: Icon(icon),
      ),
    );
  }

  Widget _buildExtended(BuildContext context) {
    final t = context.expressiveTheme;
    final g = _extendedGeometry(size);
    final (container, content) = _fabInk(
      t.colors,
      color,
      enabled: onPressed != null,
    );
    return ExpressivePressable(
      style: style,
      componentStyle: t.floatingActionButtonTheme,
      shapes: ExpressivePressShapes.all(t.shapes.of(g.shape)),
      motion: FloatingActionButtonBehavior.expandSizeMotion,
      color: container,
      contentColor: content,
      onPressed: onPressed,
      semanticLabel: label,
      tooltip: tooltip,
      elevation: _elevation(lowered: lowered),
      elevationMotion: _elevationMotion,
      tonalElevation: FabPrimaryContainerTokens.containerElevation,
      focusNode: focusNode,
      autofocus: autofocus,
      child: _ExpandTransition(
        expanded: expanded,
        builder: (context, width, alpha) {
          // Compose drops the label once the collapse has settled.
          final collapsed = !expanded && width == 0 && alpha == 0;
          return _ExtendedWidth(
            progress: width,
            minWidth: g.height,
            child: ExpressiveStyledContent(
              minimumSize: Size.square(g.height),
              iconSize: g.icon,
              textStyle: t.type.of(g.text),
              padding: EdgeInsetsDirectional.only(
                start: g.leading,
                end: g.trailing,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (mark case final mark?)
                    // Decoration: the FAB announces its label, not the mark.
                    ExcludeSemantics(
                      child: SizedBox.square(dimension: g.icon, child: mark),
                    )
                  else
                    Icon(icon),
                  if (!collapsed)
                    Flexible(
                      child: ExcludeSemantics(
                        child: Opacity(
                          opacity: alpha.clamp(0.0, 1.0),
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(start: g.gap),
                            child: expressiveFaceLabel(
                              Text(
                                label!,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Extended FAB
// ---------------------------------------------------------------------------

/// Where a Compose transition's `animateFloat` stops: its spring's default
/// visibility threshold for a `Float` (animation-core's
/// `Spring.DefaultDisplacementThreshold`), in the 0–1 progress units both
/// of the extended FAB's springs run in. The kit's finer default would run
/// the tail four frames past Compose's settle.
final Tolerance _transitionTolerance = Tolerance(
  distance: 1 / 100,
  velocity: designSpringTolerance.velocity,
);

/// The FAB menu's stagger spring as Compose runs it: an `Int` animation
/// with `visibilityThreshold = 1` (one item). Compose ends a spring at the
/// settle time it estimates for that threshold, in whole milliseconds
/// (truncated), and then reports the target; the stagger's effects spring
/// is critically damped, so that estimate is the moment it comes within
/// one item of its target. This runs the same spring and ends it at the
/// same whole millisecond.
class _StaggerSimulation extends Simulation {
  _StaggerSimulation(
    SpringDescription spring,
    double from,
    double to,
    double velocity,
  ) : _spring = designSpringSimulation(
        spring,
        from: from,
        to: to,
        velocity: velocity,
      ),
      _to = to {
    const step = Duration.millisecondsPerSecond;
    var ms = 0;
    while (!_spring.isDone(ms / step) &&
        (_spring.x((ms + 1) / step) - to).abs() > _staggerThreshold) {
      ms++;
    }
    _settle = ms / step;
  }

  /// One item.
  static const double _staggerThreshold = 1;

  final SpringSimulation _spring;
  final double _to;
  late final double _settle;

  @override
  double x(double time) => time >= _settle ? _to : _spring.x(time);

  @override
  double dx(double time) => time >= _settle ? 0 : _spring.dx(time);

  @override
  bool isDone(double time) => time >= _settle;
}

/// The extended FAB's `updateTransition` on `expanded`: the width progress
/// on [FloatingActionButtonBehavior.expandSizeMotion] and the label alpha on
/// [FloatingActionButtonBehavior.expandOpacityMotion], both 0 (collapsed)
/// to 1 (expanded), settling where Compose's do ([_transitionTolerance]).
class _ExpandTransition extends StatefulWidget {
  const _ExpandTransition({required this.expanded, required this.builder});

  final bool expanded;
  final Widget Function(BuildContext context, double width, double alpha)
  builder;

  @override
  State<_ExpandTransition> createState() => _ExpandTransitionState();
}

class _ExpandTransitionState extends State<_ExpandTransition>
    with TickerProviderStateMixin {
  late final AnimationController _width = AnimationController.unbounded(
    vsync: this,
    value: widget.expanded ? 1 : 0,
  );
  late final AnimationController _alpha = AnimationController.unbounded(
    vsync: this,
    value: widget.expanded ? 1 : 0,
  );
  late final Listenable _both = Listenable.merge([_width, _alpha]);

  @override
  void didUpdateWidget(_ExpandTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded == oldWidget.expanded) return;
    final motion = ExpressiveMotion.of(context);
    final target = widget.expanded ? 1.0 : 0.0;
    _width.springTo(
      target,
      motion.spring(FloatingActionButtonBehavior.expandSizeMotion),
      tolerance: _transitionTolerance,
    );
    _alpha.springTo(
      target,
      motion.spring(FloatingActionButtonBehavior.expandOpacityMotion),
      tolerance: _transitionTolerance,
    );
  }

  @override
  void dispose() {
    _width.dispose();
    _alpha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _both,
    builder: (context, _) =>
        widget.builder(context, _width.value, _alpha.value),
  );
}

/// Compose's extended-FAB measure policy: the content is laid out at its
/// natural width and placed at the start; the FAB is
/// `lerp(minWidth, naturalWidth, progress)` wide (the surface clips the
/// rest).
class _ExtendedWidth extends SingleChildRenderObjectWidget {
  const _ExtendedWidth({
    required this.progress,
    required this.minWidth,
    required super.child,
  });

  final double progress;
  final double minWidth;

  @override
  _RenderExtendedWidth createRenderObject(BuildContext context) =>
      _RenderExtendedWidth(progress, minWidth, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderExtendedWidth renderObject,
  ) {
    renderObject
      ..progress = progress
      ..minWidth = minWidth
      ..textDirection = Directionality.of(context);
  }
}

class _RenderExtendedWidth extends RenderShiftedBox {
  _RenderExtendedWidth(this._progress, this._minWidth, this._textDirection)
    : super(null);

  double _progress;
  set progress(double value) {
    if (value == _progress) return;
    _progress = value;
    markNeedsLayout();
  }

  double _minWidth;
  set minWidth(double value) {
    if (value == _minWidth) return;
    _minWidth = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  double _widthFor(double natural) =>
      math.max(0, _minWidth + (natural - _minWidth) * _progress);

  @override
  double computeMinIntrinsicWidth(double height) =>
      _widthFor(child?.getMaxIntrinsicWidth(height) ?? 0);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _widthFor(child?.getMaxIntrinsicWidth(height) ?? 0);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final natural = child.getDryLayout(
      BoxConstraints(
        maxWidth: constraints.maxWidth,
        maxHeight: constraints.maxHeight,
      ),
    );
    return constraints.constrain(
      Size(_widthFor(natural.width), natural.height),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(
      BoxConstraints(
        maxWidth: constraints.maxWidth,
        maxHeight: constraints.maxHeight,
      ),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      Size(_widthFor(child.size.width), child.size.height),
    );
    final dy = (size.height - child.size.height) / 2;
    final dx = _textDirection == TextDirection.rtl
        ? size.width - child.size.width
        : 0.0;
    (child.parentData! as BoxParentData).offset = Offset(dx, dy);
  }
}

/// Collapses an extended FAB while the page scrolls down and expands it
/// when the page scrolls up or returns to its top (Material's extended FAB
/// guidance; Compose's samples derive `expanded` from the list state).
///
/// Wrap the scrolling [child]; [builder] gets whether the FAB should be
/// expanded and the child, listened to, and lays the two out (usually a
/// `Stack` with the FAB at the bottom end).
class ExpressiveFabScrollExpansion extends StatefulWidget {
  /// A scope that builds an extended FAB with `builder`, collapsing it as [child] scrolls.
  const ExpressiveFabScrollExpansion({
    required this.builder,
    required this.child,
    super.key,
  });

  /// Lays out the scrolling child and the FAB, [expanded] or not.
  final Widget Function(BuildContext context, bool expanded, Widget child)
  builder;

  /// The scrolling content whose scroll drives the FAB.
  final Widget child;

  @override
  State<ExpressiveFabScrollExpansion> createState() =>
      _ExpressiveFabScrollExpansionState();
}

class _ExpressiveFabScrollExpansionState
    extends State<ExpressiveFabScrollExpansion> {
  bool _expanded = true;

  bool _onScroll(ScrollUpdateNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final delta = n.scrollDelta ?? 0;
    final expanded = n.metrics.pixels <= n.metrics.minScrollExtent
        ? true
        : delta > 0
        ? false
        : delta < 0
        ? true
        : _expanded;
    if (expanded != _expanded) setState(() => _expanded = expanded);
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _expanded,
    NotificationListener<ScrollUpdateNotification>(
      onNotification: _onScroll,
      child: widget.child,
    ),
  );
}

// ---------------------------------------------------------------------------
// FAB menu
// ---------------------------------------------------------------------------

/// One act in an [ExpressiveFabMenu]: an icon and a label on a pill.
@immutable
class ExpressiveFabMenuItem {
  /// A menu item showing [icon] and [label] that runs [onPressed].
  const ExpressiveFabMenuItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.style,
    this.key,
  });

  /// Visual overrides before the menu's item style and FAB theme.
  final ExpressiveComponentThemeData? style;

  /// The glyph: one of [ExpressiveSymbols].
  final IconData icon;

  /// The act (`Photo`, `Voice note`).
  final String label;

  /// What a tap does, run with the menu's context; the menu then closes.
  final void Function(BuildContext context) onPressed;

  /// A key set on the item's hit target (a walkthrough's).
  final Key? key;
}

/// The FAB menu's colour family: the toggle morphs from the container colour
/// to the vibrant one as it opens; the items wear the container colour
/// (`ToggleFloatingActionButtonDefaults.containerColor`,
/// `FloatingActionButtonMenuItem`).
enum ExpressiveFabMenuColor {
  /// `primaryContainer` → `primary`; items `primaryContainer`.
  primary(
    ExpressiveColorRole.primaryContainer,
    ExpressiveColorRole.onPrimaryContainer,
    ExpressiveColorRole.primary,
    ExpressiveColorRole.onPrimary,
  ),

  /// `secondaryContainer` → `secondary`; items `secondaryContainer`.
  secondary(
    ExpressiveColorRole.secondaryContainer,
    ExpressiveColorRole.onSecondaryContainer,
    ExpressiveColorRole.secondary,
    ExpressiveColorRole.onSecondary,
  ),

  /// `tertiaryContainer` → `tertiary`; items `tertiaryContainer`.
  tertiary(
    ExpressiveColorRole.tertiaryContainer,
    ExpressiveColorRole.onTertiaryContainer,
    ExpressiveColorRole.tertiary,
    ExpressiveColorRole.onTertiary,
  ),

  /// Vibrant `primary` throughout: the closed toggle, the open one and the
  /// items (Compose's `ToggleFloatingActionButton(containerColor =
  /// containerColor(primary, primary))` with `FloatingActionButtonMenuItem(
  /// containerColor = primary)`). For a page whose surfaces sit too close
  /// to the containers for the toggle to stand out at rest.
  vibrant(
    ExpressiveColorRole.primary,
    ExpressiveColorRole.onPrimary,
    ExpressiveColorRole.primary,
    ExpressiveColorRole.onPrimary,
  );

  const ExpressiveFabMenuColor(
    this.container,
    this.onContainer,
    this.open,
    this.onOpen,
  );

  /// The closed toggle's and the items' container role.
  final ExpressiveColorRole container;

  /// Their content role.
  final ExpressiveColorRole onContainer;

  /// The open toggle's container role.
  final ExpressiveColorRole open;

  /// The open toggle's icon role.
  final ExpressiveColorRole onOpen;
}

/// The FAB menu: a FAB that opens into 2–5 related acts stacked above it
/// (Compose's `FloatingActionButtonMenu` + `ToggleFloatingActionButton`).
/// Opening morphs the FAB into the round close button (size, corner, colour
/// and glyph on `FloatingActionButtonMenuBehavior.toggleMotion`) and the
/// items stagger in from the one nearest the button (`staggerMotion`; each
/// item's width and opacity on `itemWidthMotion`, `itemAlphaMotion`).
///
/// A hero moment (CONTRACT §3): it must sit inside an [ExpressiveHeroMoment], holds
/// 2–5 items (Material allows 6; §3 caps it at 5), never opens from an
/// extended FAB (its button is always the toggle FAB), and never sits beside
/// a toolbar or rail. Debug builds assert the first two; the toolbar and the
/// rail check the last with [debugCheckNoMenuBeside].
///
/// Uncontrolled by default (starts closed, or [initiallyExpanded]); pass
/// [expanded] with [onExpandedChanged] to control it. An item's tap closes
/// the menu, and so does the system back: while the menu is open the back
/// is its own, never the page's (Compose's sample hangs a
/// `BackHandler(fabMenuExpanded)` on it; [ExpressiveBackHandle]).
class ExpressiveFabMenu extends StatefulWidget {
  /// A FAB menu showing [icon] that opens into [items].
  const ExpressiveFabMenu({
    required this.icon,
    required this.items,
    this.semanticLabel,
    this.closeIcon = ExpressiveSymbols.close,
    this.expanded,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
    this.size = ExpressiveFabSize.standard,
    this.color = ExpressiveFabMenuColor.primary,
    this.alignment = CrossAxisAlignment.end,
    this.padded = true,
    this.overlayItems = false,
    this.scrim = false,
    this.buttonKey,
    this.style,
    this.itemStyle,
    super.key,
  }) : assert(
         alignment == CrossAxisAlignment.start ||
             alignment == CrossAxisAlignment.center ||
             alignment == CrossAxisAlignment.end,
         'A FAB menu aligns its items start, center or end.',
       ),
       assert(
         !scrim || overlayItems,
         'A FAB menu dims the screen only when its items open in the '
         'overlay (overlayItems: true).',
       );

  /// Visual overrides for the toggle before the FAB theme.
  final ExpressiveComponentThemeData? style;

  /// Visual overrides shared by the menu's text pills.
  final ExpressiveComponentThemeData? itemStyle;

  /// The closed toggle's glyph (`add`, `edit`).
  final IconData icon;

  /// The acts, top to bottom: 2–5.
  final List<ExpressiveFabMenuItem> items;

  /// What a screen reader says for the toggle (`Create`).
  final String? semanticLabel;

  /// The open toggle's glyph.
  final IconData closeIcon;

  /// Whether the menu is open, when controlled.
  final bool? expanded;

  /// Whether an uncontrolled menu starts open.
  final bool initiallyExpanded;

  /// Told when the toggle or an item asks to open or close the menu.
  final ValueChanged<bool>? onExpandedChanged;

  /// The closed toggle's size (56, 80 or 96dp); open, it is always the 56dp
  /// close button.
  final ExpressiveFabSize size;

  /// The colour family.
  final ExpressiveFabMenuColor color;

  /// How the items and the toggle align: end (Compose's default), center or
  /// start.
  final CrossAxisAlignment alignment;

  /// Whether the menu keeps Compose's own padding (16dp either side and
  /// below the toggle). False when its parent already places it 16dp in
  /// from the edges, as the shell does.
  final bool padded;

  /// Whether the items open in the route's overlay, anchored above the
  /// toggle, rather than in the menu's own box. True, the menu's box stays
  /// the closed toggle's size however far it is open: what the shell's
  /// action needs, since the shell measures the band its action stands in
  /// (Compose's Scaffold never pads the content for its FAB slot). The items
  /// still sit 8dp above the toggle and stay hit-testable.
  final bool overlayItems;

  /// Whether the open menu dims the screen behind it: the scrim role at
  /// the scrim's opacity (`ScrimTokens`), fading on the toggle's spring,
  /// with a tap on it closing the menu. Compose's menu draws none; an app
  /// adds one (Keep's M3 Expressive menu does) where the items would
  /// otherwise sit on busy, tinted content. Needs [overlayItems]: the
  /// toggle then rides the overlay too, above the scrim, while the menu's
  /// own box keeps the closed toggle's size.
  final bool scrim;

  /// A key set on the toggle's hit target (a walkthrough's).
  final Key? buttonKey;

  /// Test hook (the oracle's scenes): wraps each part of every menu —
  /// `toggle`, `item-<i>` and `item-<i>-label` — so a scene can tag it.
  /// Null outside tests.
  @visibleForTesting
  static Widget Function(String part, Widget child)? debugPartWrapper;

  static final Expando<int> _menusByRoute = Expando<int>('ExpressiveFabMenu');
  static int _unrouted = 0;

  /// How many FAB menus are mounted on [route] now (null counts the menus
  /// outside any route): what a toolbar or rail reads to keep the "no FAB
  /// menu beside a toolbar or rail" rule (CONTRACT §3).
  static int countOn(Route<Object?>? route) =>
      route == null ? _unrouted : (_menusByRoute[route] ?? 0);

  /// Asserts, in debug builds, that no FAB menu shares a screen with
  /// [widget] (a toolbar or rail's name): none on [context]'s route, and,
  /// while that route is its navigator's first page, none on the route that
  /// holds the navigator (the shell's action stands on the shell's route,
  /// over every branch root; a page pushed in a branch covers the shell's
  /// chrome, so it stops there). Checked after the frame, so the order the
  /// two are built in does not matter; a violation is reported through
  /// [FlutterError.reportError]. Call it from the toolbar's or rail's
  /// `build`: `assert(ExpressiveFabMenu.debugCheckNoMenuBeside(context,
  /// 'ExpressiveFloatingToolbar'));`. Always true in release.
  static bool debugCheckNoMenuBeside(BuildContext context, String widget) {
    assert(() {
      bool menuBeside() {
        var scope = context;
        while (scope.mounted) {
          final route = ModalRoute.of(scope);
          if (countOn(route) > 0) return true;
          if (route == null || !route.isFirst) return false;
          final navigator = scope.findAncestorStateOfType<NavigatorState>();
          if (navigator == null) return false;
          scope = navigator.context;
        }
        return false;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || !menuBeside()) return;
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('$widget sits beside an ExpressiveFabMenu.'),
              ErrorDescription(
                'A FAB menu never shares a screen with a toolbar or a '
                'navigation rail (CONTRACT §3).',
              ),
              ErrorHint(
                'Use a plain ExpressiveFloatingActionButton, or move the acts into the '
                'toolbar.',
              ),
            ]),
            library: 'expressive',
          ),
        );
      });
      return true;
    }());
    return true;
  }

  @override
  State<ExpressiveFabMenu> createState() => _ExpressiveFabMenuState();
}

class _ExpressiveFabMenuState extends State<ExpressiveFabMenu>
    with TickerProviderStateMixin {
  late bool _own = widget.initiallyExpanded;
  bool get _expanded => widget.expanded ?? _own;

  /// The toggle's progress, 0 closed → 1 open (`checkedProgress`).
  late final AnimationController _toggle = AnimationController.unbounded(
    vsync: this,
    value: _expanded ? 1 : 0,
  );

  /// How many items, counted from the bottom, are shown (Compose's
  /// `staggerAnim`, an `Int` animation: the value truncates).
  late final AnimationController _stagger = AnimationController.unbounded(
    vsync: this,
    value: _expanded ? widget.items.length.toDouble() : 0,
  );

  final List<AnimationController> _widths = <AnimationController>[];
  final List<AnimationController> _alphas = <AnimationController>[];
  final List<double> _targets = <double>[];
  final List<FocusNode> _itemFocus = <FocusNode>[];
  final Set<int> _pending = <int>{};
  bool _startScheduled = false;
  Route<Object?>? _route;
  bool _registered = false;

  /// [ExpressiveFabMenu.overlayItems]: the toggle's anchor, and the portal
  /// that keeps the items in the overlay (shown for the menu's life; it
  /// draws nothing while every item is hidden).
  final LayerLink _anchor = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();

  late final ExpressiveBackHandle _back = ExpressiveBackHandle(
    onBack: () => _request(false),
  );

  int get _shown => _stagger.value.truncate().clamp(0, widget.items.length);

  @override
  void initState() {
    super.initState();
    _syncItems();
    _stagger.addListener(_staggered);
    _portal.show();
  }

  void _syncItems() {
    final n = widget.items.length;
    final shown = _shown;
    while (_widths.length < n) {
      final i = _widths.length;
      final visible = i >= n - shown ? 1.0 : 0.0;
      _widths.add(AnimationController.unbounded(vsync: this, value: visible));
      _alphas.add(AnimationController.unbounded(vsync: this, value: visible));
      _targets.add(visible);
      _itemFocus.add(FocusNode(debugLabel: 'ExpressiveFabMenu item $i'));
    }
    while (_widths.length > n) {
      _widths.removeLast().dispose();
      _alphas.removeLast().dispose();
      _targets.removeLast();
      _itemFocus.removeLast().dispose();
    }
  }

  /// Springs each item to shown or hidden as the stagger passes it
  /// (`MenuItemRuler`: an item shows once the stagger reaches it). Compose
  /// reads the ruler in the item's placement and launches its `animateTo`
  /// in a coroutine, which starts on the next frame; the springs here start
  /// on the frame after the stagger crosses too.
  void _staggered() {
    final n = widget.items.length;
    final shown = _shown;
    for (var i = 0; i < n; i++) {
      final target = i >= n - shown ? 1.0 : 0.0;
      if (_targets[i] == target) continue;
      _targets[i] = target;
      _pending.add(i);
    }
    if (_pending.isEmpty || _startScheduled) return;
    _startScheduled = true;
    WidgetsBinding.instance.scheduleFrameCallback((_) {
      _startScheduled = false;
      if (mounted) _startItems();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _startItems() {
    final motion = ExpressiveMotion.of(context);
    for (final i in _pending) {
      if (i >= _widths.length) continue;
      _widths[i].springTo(
        _targets[i],
        motion.spring(FloatingActionButtonMenuBehavior.itemWidthMotion),
        tolerance: _transitionTolerance,
      );
      _alphas[i].springTo(
        _targets[i],
        motion.spring(FloatingActionButtonMenuBehavior.itemAlphaMotion),
        tolerance: _transitionTolerance,
      );
    }
    _pending.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_registered && route == _route) return;
    _unregister();
    _route = route;
    if (route == null) {
      ExpressiveFabMenu._unrouted++;
    } else {
      ExpressiveFabMenu._menusByRoute[route] =
          (ExpressiveFabMenu._menusByRoute[route] ?? 0) + 1;
    }
    _registered = true;
  }

  void _unregister() {
    if (!_registered) return;
    final route = _route;
    if (route == null) {
      ExpressiveFabMenu._unrouted--;
    } else {
      ExpressiveFabMenu._menusByRoute[route] =
          (ExpressiveFabMenu._menusByRoute[route] ?? 1) - 1;
    }
    _registered = false;
  }

  @override
  void didUpdateWidget(ExpressiveFabMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _syncItems();
      _staggered();
    }
    final was = oldWidget.expanded ?? _own;
    if (widget.expanded != null && widget.expanded != was) {
      _run(widget.expanded!);
    }
  }

  @override
  void dispose() {
    _back.dispose();
    _unregister();
    _stagger.removeListener(_staggered);
    _toggle.dispose();
    _stagger.dispose();
    for (final c in <AnimationController>[..._widths, ..._alphas]) {
      c.dispose();
    }
    for (final f in _itemFocus) {
      f.dispose();
    }
    super.dispose();
  }

  void _run(bool expanded) {
    final motion = ExpressiveMotion.of(context);
    // Compose's thresholds: `animateFloatAsState`'s default 0.01 for the
    // toggle, and `visibilityThreshold = 1` (one item) for the stagger
    // ([_StaggerSimulation]).
    _toggle.springTo(
      expanded ? 1 : 0,
      motion.spring(FloatingActionButtonMenuBehavior.toggleMotion),
      tolerance: _transitionTolerance,
    );
    _stagger.animateWith(
      _StaggerSimulation(
        motion.spring(FloatingActionButtonMenuBehavior.staggerMotion),
        _stagger.value,
        expanded ? widget.items.length.toDouble() : 0,
        _stagger.velocity,
      ),
    );
  }

  void _request(bool expanded) {
    if (expanded == _expanded) return;
    // Closing lets the back go at once, so a pop right after reaches the
    // page; the rebuild holds it again if a caller keeps the menu open.
    if (!expanded) _back.release();
    setState(() {
      if (widget.expanded == null) _own = expanded;
    });
    if (widget.expanded == null) _run(expanded);
    widget.onExpandedChanged?.call(expanded);
  }

  @override
  Widget build(BuildContext context) {
    assert(ExpressiveHeroMoment.debugCheck(context, 'ExpressiveFabMenu'));
    _back.sync(context, open: _expanded);
    assert(() {
      final n = widget.items.length;
      if (n < 2 || n > 5) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('An ExpressiveFabMenu holds 2–5 items, not $n.'),
          ErrorDescription(
            'CONTRACT §3 bans a FAB menu of one item (use a plain FAB) or '
            'of more than five (Material allows six; Expressive caps it at '
            'five).',
          ),
        ]);
      }
      return true;
    }());
    final t = context.expressiveTheme;
    final horizontal = widget.padded
        ? FloatingActionButtonMenuBehavior.paddingHorizontal
        : 0.0;
    final bottom = widget.padded
        ? FloatingActionButtonMenuBehavior.buttonPaddingBottom
        : 0.0;
    final button = _button(t);
    // Compose spaces the items by `FabMenuItemSpacingVertical.roundToPx()`:
    // whole device pixels.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final spacing =
        (FabMenuBaselineTokens.listItemBetweenSpace * dpr).roundToDouble() /
        dpr;
    Widget items() => FocusTraversalGroup(
      child: Semantics(
        // Compose reads the items before the toggle
        // (`traversalIndex = -0.9f`).
        sortKey: const OrdinalSortKey(-0.9),
        explicitChildNodes: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.alignment,
          children: <Widget>[
            for (var i = 0; i < widget.items.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              _item(t, i),
            ],
          ],
        ),
      ),
    );
    final itemMotion = Listenable.merge(<Listenable>[..._widths, ..._alphas]);
    if (widget.overlayItems) {
      final (Alignment target, Alignment follower) = switch (widget.alignment) {
        CrossAxisAlignment.start => (Alignment.topLeft, Alignment.bottomLeft),
        CrossAxisAlignment.center => (
          Alignment.topCenter,
          Alignment.bottomCenter,
        ),
        _ => (Alignment.topRight, Alignment.bottomRight),
      };
      final rtl = Directionality.of(context) == TextDirection.rtl;
      Alignment flip(Alignment a) => rtl ? Alignment(-a.x, a.y) : a;
      final followItems = Align(
        alignment: AlignmentDirectional.topStart,
        child: CompositedTransformFollower(
          link: _anchor,
          showWhenUnlinked: false,
          targetAnchor: flip(target),
          followerAnchor: flip(follower),
          offset: const Offset(
            0,
            -FabMenuBaselineTokens.closeButtonBetweenSpace,
          ),
          child: AnimatedBuilder(
            animation: itemMotion,
            builder: (context, _) => _alphas.any((a) => a.value != 0)
                ? items()
                : const SizedBox.shrink(),
          ),
        ),
      );
      final scrim = widget.scrim;
      return Padding(
        padding: EdgeInsetsDirectional.only(
          start: horizontal,
          end: horizontal,
          bottom: bottom,
        ),
        child: CompositedTransformTarget(
          link: _anchor,
          child: OverlayPortal(
            controller: _portal,
            overlayChildBuilder: (context) => !scrim
                ? followItems
                : Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      _scrim(t),
                      followItems,
                      // Above the scrim, the toggle stands where its box
                      // holds its place.
                      Align(
                        alignment: AlignmentDirectional.topStart,
                        child: CompositedTransformFollower(
                          link: _anchor,
                          showWhenUnlinked: false,
                          child: button,
                        ),
                      ),
                    ],
                  ),
            child: scrim ? SizedBox.fromSize(size: _boxSize) : button,
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: horizontal,
        end: horizontal,
        bottom: bottom,
      ),
      child: AnimatedBuilder(
        animation: itemMotion,
        builder: (context, button) {
          // Compose keeps every item laid out (a hidden one zero wide) but
          // clips the column to zero height until an item shows.
          final anyVisible = _alphas.any((a) => a.value != 0);
          // Compose clamps the menu to its constraints and scrolls the
          // items when they do not fit.
          return LayoutBuilder(
            builder: (context, constraints) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: widget.alignment,
              children: <Widget>[
                if (anyVisible) ...<Widget>[
                  if (constraints.hasBoundedHeight)
                    Flexible(
                      child: SingleChildScrollView(
                        primary: false,
                        child: items(),
                      ),
                    )
                  else
                    items(),
                  const SizedBox(
                    height: FabMenuBaselineTokens.closeButtonBetweenSpace,
                  ),
                ] else
                  ClipRect(
                    child: SizedBox(
                      height: 0,
                      child: OverflowBox(
                        fit: OverflowBoxFit.deferToChild,
                        alignment: AlignmentDirectional.topCenter,
                        minHeight: 0,
                        maxHeight: double.infinity,
                        child: items(),
                      ),
                    ),
                  ),
                button!,
              ],
            ),
          );
        },
        child: button,
      ),
    );
  }

  /// The closed toggle's box: what the menu's own box keeps while the
  /// toggle rides the overlay ([ExpressiveFabMenu.scrim]).
  Size get _boxSize {
    final t = context.expressiveTheme;
    final visual = t.floatingActionButtonTheme.merge(widget.style);
    final states = <WidgetState>{if (_expanded) WidgetState.selected};
    final geometry = _fabGeometry(widget.size);
    final shape = visual.shape?.resolve(states);
    final outline = visual.outline?.resolve(states);
    final side =
        visual.side?.resolve(states) ??
        BorderSide.none.copyWith(
          color: outline,
          style: outline == null ? null : BorderStyle.solid,
        );
    final inset =
        shape
            ?.copyWith(side: side)
            .dimensions
            .resolve(Directionality.of(context)) ??
        EdgeInsets.all(side.strokeInset);
    final padding = (visual.padding?.resolve(states) ?? EdgeInsets.zero)
        .resolve(Directionality.of(context));
    final icon = visual.iconSize?.resolve(states) ?? geometry.icon;
    final minimum = visual.minimumSize?.resolve(states);
    return Size(
      math.max(
        minimum?.width ?? t.density.width(geometry.side),
        icon + inset.horizontal + padding.horizontal,
      ),
      math.max(
        minimum?.height ?? t.density.height(geometry.side),
        icon + inset.vertical + padding.vertical,
      ),
    );
  }

  /// [ExpressiveFabMenu.scrim]: the scrim role at `ScrimTokens`' opacity,
  /// following the toggle's progress (so it fades in and out with the
  /// morph), taking a tap as a close while the menu is open and letting
  /// every pointer through once it is closing.
  Widget _scrim(ExpressiveThemeData t) => AnimatedBuilder(
    animation: _toggle,
    builder: (context, _) {
      final shown = _toggle.value.clamp(0.0, 1.0);
      if (shown == 0 && !_expanded) return const SizedBox.shrink();
      final expanded = _expanded;
      return IgnorePointer(
        ignoring: !expanded,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: () => _request(false),
          child: ColoredBox(
            color: t.colors
                .role(ScrimTokens.containerColor)
                .withValues(alpha: ScrimTokens.containerOpacity * shown),
          ),
        ),
      );
    },
  );

  Widget _item(ExpressiveThemeData t, int i) {
    final item = widget.items[i];
    final alpha = _alphas[i].value;
    final visible = alpha != 0;
    final align = switch (widget.alignment) {
      CrossAxisAlignment.start => AlignmentDirectional.centerStart,
      CrossAxisAlignment.center => AlignmentDirectional.center,
      _ => AlignmentDirectional.centerEnd,
    };
    final label = _debugWrap(
      'item-$i-label',
      expressiveFaceLabel(
        Text(
          item.label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    final pill = ExpressivePressable(
      key: item.key,
      style: (widget.itemStyle ?? const ExpressiveComponentThemeData()).merge(
        item.style,
      ),
      componentStyle: t.floatingActionButtonTheme,
      shapes: ExpressivePressShapes.all(
        t.shapes.of(FabMenuBaselineTokens.listItemContainerShape),
      ),
      motion: FloatingActionButtonMenuBehavior.itemWidthMotion,
      color: t.colors.role(widget.color.container),
      contentColor: t.colors.role(widget.color.onContainer),
      // Compose's items provide LocalMinimumInteractiveComponentSize 0.
      minimumInteractiveSize: false,
      focusNode: _itemFocus[i],
      semanticLabel: item.label,
      onPressed: visible
          ? () {
              item.onPressed(context);
              _request(false);
            }
          : null,
      // The pill is its content's width times the item's width progress,
      // the content aligned to the menu's side and clipped by the pill. A
      // hidden item is zero wide and Compose does not place its content
      // (its nodes sit at the item's origin); nothing of it is painted.
      child: !visible
          ? SizedBox(
              width: 0,
              height: FabMenuBaselineTokens.listItemContainerHeight,
              child: OverflowBox(
                alignment: AlignmentDirectional.topStart,
                minWidth: 0,
                minHeight: 0,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: label,
              ),
            )
          : Align(
              alignment: align,
              widthFactor: math.max(0, _widths[i].value),
              child: ExpressiveStyledContent(
                minimumSize: const Size.square(
                  FabMenuBaselineTokens.listItemContainerHeight,
                ),
                padding: const EdgeInsetsDirectional.only(
                  start: FabMenuBaselineTokens.listItemLeadingSpace,
                  end: FabMenuBaselineTokens.listItemTrailingSpace,
                ),
                textStyle: t.type.of(ExpressiveTypeKey.titleMedium),
                iconSize: FabMenuBaselineTokens.listItemIconSize,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(item.icon),
                    const SizedBox(
                      width: FabMenuBaselineTokens.listItemIconLabelSpace,
                    ),
                    Flexible(child: ExcludeSemantics(child: label)),
                  ],
                ),
              ),
            ),
    );
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: Opacity(
          opacity: alpha.clamp(0.0, 1.0),
          child: _debugWrap('item-$i', pill),
        ),
      ),
    );
  }

  Widget _button(ExpressiveThemeData t) {
    final (double side, double corner, double icon) = switch (widget.size) {
      ExpressiveFabSize.standard => (
        FabBaselineTokens.containerHeight,
        FloatingActionButtonMenuBehavior.toggleInitialCornerRadius,
        FabBaselineTokens.iconSize,
      ),
      ExpressiveFabSize.medium => (
        FabMediumTokens.containerHeight,
        FloatingActionButtonMenuBehavior.toggleMediumInitialCornerRadius,
        FabMediumTokens.iconSize,
      ),
      ExpressiveFabSize.large => (
        FabLargeTokens.containerHeight,
        FloatingActionButtonMenuBehavior.toggleLargeInitialCornerRadius,
        FloatingActionButtonMenuBehavior.toggleLargeInitialIconSize,
      ),
    };
    const openSide = FabMenuBaselineTokens.closeButtonContainerHeight;
    const openCorner = FabMenuBaselineTokens.closeButtonContainerHeight * 0.5;
    const openIcon = FabMenuBaselineTokens.closeButtonIconSize;
    final expanded = _expanded;
    // The pressable springs the corner and the colours to their targets on
    // the toggle's own spring (the curve [_toggle] runs); the size and the
    // glyph follow [_toggle] here.
    final button = ExpressivePressable(
      key: widget.buttonKey,
      style: widget.style,
      componentStyle: t.floatingActionButtonTheme,
      shapes: ExpressivePressShapes.all(
        ExpressiveCornerBorder.all(
          ExpressiveCornerSize.dp(expanded ? openCorner : corner),
        ),
      ),
      motion: FloatingActionButtonMenuBehavior.toggleMotion,
      colorMotion: FloatingActionButtonMenuBehavior.toggleMotion,
      color: t.colors.role(
        expanded ? widget.color.open : widget.color.container,
      ),
      contentColor: t.colors.role(
        expanded ? widget.color.onOpen : widget.color.onContainer,
      ),
      elevation: const ExpressiveStateElevation.all(
        FabPrimaryContainerTokens.containerElevation,
      ),
      role: ExpressivePressRole.toggle,
      selected: expanded,
      semanticLabel: widget.semanticLabel,
      onPressed: () => _request(!expanded),
      child: AnimatedBuilder(
        animation: _toggle,
        builder: (context, _) {
          final p = _toggle.value;
          final s = math.max(0.0, side + (openSide - side) * p);
          final i = math.max(0.0, icon + (openIcon - icon) * p);
          return ExpressiveStyledContent(
            minimumSize: Size.square(s),
            iconSize: i,
            child: Icon(p > 0.5 ? widget.closeIcon : widget.icon),
          );
        },
      ),
    );
    // Compose keeps the closed size's box and aligns the morphing button to
    // its top end. Tab or Down from the open toggle moves into the items.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        final into =
            (event.logicalKey == LogicalKeyboardKey.tab &&
                !HardwareKeyboard.instance.isShiftPressed) ||
            event.logicalKey == LogicalKeyboardKey.arrowDown;
        if (_expanded &&
            event is KeyDownEvent &&
            into &&
            _itemFocus.isNotEmpty) {
          _itemFocus.first.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: _boxSize.width,
          minHeight: _boxSize.height,
        ),
        child: Align(
          widthFactor: 1,
          heightFactor: 1,
          alignment: AlignmentDirectional.topEnd,
          child: _debugWrap('toggle', button),
        ),
      ),
    );
  }

  static Widget _debugWrap(String part, Widget child) {
    final wrap = ExpressiveFabMenu.debugPartWrapper;
    return wrap == null ? child : wrap(part, child);
  }
}
