/// Toolbars: floating (horizontal and vertical) and docked, standard and
/// vibrant (CONTRACT §4.1 `toolbar`). Owner: w3-toolbar, with
/// `test/toolbar_test.dart` and the gallery's toolbar demo.
///
/// A port of Compose material3 1.5.0-alpha29 (wave decision F1):
///
/// - [ExpressiveFloatingToolbar] is `HorizontalFloatingToolbar` and
///   `VerticalFloatingToolbar`, both overloads: without a FAB (leading and
///   trailing content that expand in and shrink away on `expanded`) and
///   with one (`…WithFabLayout`: the toolbar's length springs between its
///   full intrinsic length and nothing while the FAB grows from 56 to
///   80dp). Colours are `FloatingToolbarDefaults
///   .standardFloatingToolbarColors` / `vibrantFloatingToolbarColors`
///   ([ExpressiveToolbarKind]).
/// - [ExpressiveToolbarFab] is `FloatingToolbarDefaults
///   .StandardFloatingActionButton` / `VibrantFloatingActionButton`: a FAB
///   that fills the square the toolbar gives it, in the toolbar kind's FAB
///   colours.
/// - [ExpressiveDockedToolbar] is `FlexibleBottomAppBar` (the docked
///   toolbar): edge to edge at the bottom, its actions spaced between or
///   at the fixed spacing.
/// - [ExpressiveToolbarScrollBehavior] is `FloatingToolbarDefaults
///   .exitAlwaysScrollBehavior` (and `BottomAppBarDefaults
///   .exitAlwaysScrollBehavior` for the docked toolbar): the toolbar leaves
///   the screen as content scrolls on and returns as it scrolls back,
///   snapping to shown or hidden on a spring when the scroll stops part way.
/// - [ExpressiveToolbarScrollExpansion] is `Modifier
///   .floatingToolbarVerticalNestedScroll`: `expanded` flips after the
///   content scrolls `ScrollDistanceThreshold` (40dp) either way.
///
/// With a touch-exploration screen reader on (Flutter's
/// `MediaQuery.accessibleNavigation`), a floating toolbar stays expanded and
/// ignores its scroll behaviour, and it offers an expand / collapse custom
/// action, as Compose's does. A FAB menu never sits beside a toolbar
/// (CONTRACT §3): debug builds check it with
/// [ExpressiveFabMenu.debugCheckNoMenuBeside].
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../internal/styled_content.dart';
import '../elevation.dart';
import '../motion.dart';
import '../states.dart';
import '../strings.dart';
import '../theme.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/docked_toolbar_tokens.g.dart';
import '../internal/tokens/fab_baseline_tokens.g.dart';
import '../internal/tokens/fab_medium_tokens.g.dart';
import '../internal/tokens/floating_toolbar_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import 'fab.dart' show ExpressiveFabMenu;

// ---------------------------------------------------------------------------
// Colours and positions
// ---------------------------------------------------------------------------

/// A toolbar's colours (Compose's `FloatingToolbarColors` defaults).
enum ExpressiveToolbarKind {
  /// `surfaceContainer` with `onSurface` content; the FAB beside it in
  /// `primaryContainer`.
  standard(
    FloatingToolbarTokens.standardContainerColor,
    ExpressiveColorRole.primaryContainer,
  ),

  /// `primaryContainer` with `onPrimaryContainer` content, for the one
  /// toolbar that leads the screen; the FAB beside it in
  /// `tertiaryContainer`.
  vibrant(
    FloatingToolbarTokens.vibrantContainerColor,
    ExpressiveColorRole.tertiaryContainer,
  );

  const ExpressiveToolbarKind(this.container, this.fabContainer);

  /// The toolbar's container role.
  final ExpressiveColorRole container;

  /// The adjacent FAB's container role (Compose's `fabContainerColor`).
  final ExpressiveColorRole fabContainer;
}

/// Which end of a floating toolbar its FAB sits at: the start or end of a
/// horizontal toolbar (Compose's `FloatingToolbarHorizontalFabPosition`),
/// the top or bottom of a vertical one (`…VerticalFabPosition`).
enum ExpressiveToolbarFabPosition {
  /// Before the toolbar: its start (horizontal) or top (vertical).
  start,

  /// After the toolbar: its end (horizontal) or bottom (vertical). The
  /// default on both axes, as in Compose.
  end,
}

/// How a docked toolbar spaces its actions (`BottomAppBarDefaults
/// .FlexibleHorizontalArrangement` and `.FlexibleFixedHorizontalArrangement`).
enum ExpressiveDockedToolbarArrangement {
  /// Spread across the width, the first and last at the edges' padding.
  spaceBetween,

  /// Centred, `DockedToolbarTokens.containerMaxSpacing` (32dp) apart.
  fixed,
}

/// The content colour Compose's `contentColorFor` gives [container].
Color _contentFor(BuildContext context, Color container) {
  final colors = context.expressiveTheme.colors;
  return colors.contentColorFor(container) ?? colors.onSurface;
}

/// [dp] floored to whole device pixels (Compose's `toInt()` of a pixel
/// value, and its integer division).
double _floorToPixels(double dp, double ratio) =>
    ((dp * ratio) + 1e-6).floorToDouble() / ratio;

/// [dp] rounded to whole device pixels (Compose's `roundToPx`).
double _roundToPixels(double dp, double ratio) =>
    (dp * ratio).roundToDouble() / ratio;

// ---------------------------------------------------------------------------
// Floating toolbar
// ---------------------------------------------------------------------------

/// A floating toolbar: a pill of actions that floats over the content,
/// [screenOffset] (16dp) from the screen's edge (Compose's
/// `HorizontalFloatingToolbar` / `VerticalFloatingToolbar`).
///
/// [children] are the always-shown actions (usually standard
/// `ExpressiveIconButton`s, which take the toolbar's content colour).
/// Without a [floatingActionButton], [leading] and [trailing] actions
/// expand in and shrink away as [expanded] changes. With one, the whole
/// toolbar shrinks into the FAB (which grows from 56 to 80dp) when
/// [expanded] is false; give it an [ExpressiveToolbarFab].
///
/// [scrollBehavior] lets the toolbar leave the screen as content scrolls;
/// [ExpressiveToolbarScrollExpansion] drives [expanded] from a scroll
/// instead. Never beside a FAB menu (CONTRACT §3).
class ExpressiveFloatingToolbar extends StatefulWidget {
  /// A floating toolbar of [children].
  const ExpressiveFloatingToolbar({
    required this.children,
    this.expanded = true,
    this.axis = Axis.horizontal,
    this.kind = ExpressiveToolbarKind.standard,
    this.style,
    this.leading = const <Widget>[],
    this.trailing = const <Widget>[],
    this.floatingActionButton,
    this.fabPosition = ExpressiveToolbarFabPosition.end,
    this.scrollBehavior,
    this.expandedElevation,
    this.collapsedElevation,
    this.semanticLabel,
    this.expandActionLabel,
    this.collapseActionLabel,
    super.key,
  }) : assert(
         floatingActionButton == null ||
             (leading.length == 0 && trailing.length == 0),
         'A toolbar with a FAB has no leading or trailing content: the '
         'whole toolbar collapses into the FAB.',
       );

  /// The actions always shown.
  final List<Widget> children;

  /// Whether the toolbar is expanded: [leading] and [trailing] shown, or,
  /// with a FAB, the toolbar shown beside it.
  final bool expanded;

  /// Horizontal (a row, usually at the bottom) or vertical (a column at
  /// the side).
  final Axis axis;

  /// Standard or vibrant colours.
  final ExpressiveToolbarKind kind;

  /// Stateful visual overrides; null slots fall through to the theme.
  final ExpressiveComponentThemeData? style;

  /// Actions before [children], shown only while [expanded] (no FAB).
  final List<Widget> leading;

  /// Actions after [children], shown only while [expanded] (no FAB).
  final List<Widget> trailing;

  /// The FAB beside the toolbar: an [ExpressiveToolbarFab].
  final Widget? floatingActionButton;

  /// Which end the FAB sits at.
  final ExpressiveToolbarFabPosition fabPosition;

  /// Moves the toolbar off the screen while content scrolls; see
  /// [ExpressiveToolbarScrollBehavior].
  final ExpressiveToolbarScrollBehavior? scrollBehavior;

  /// The shadow while expanded: level 0, or level 1 beside a FAB
  /// (`FloatingToolbarDefaults.ContainerExpandedElevation[WithFab]`).
  final ExpressiveElevationLevel? expandedElevation;

  /// The shadow while collapsed: level 0
  /// (`ContainerCollapsedElevation[WithFab]`).
  final ExpressiveElevationLevel? collapsedElevation;

  /// What a screen reader calls the toolbar.
  final String? semanticLabel;

  /// The custom accessibility action that expands a collapsed toolbar
  /// (Compose's `Strings.FloatingToolbarExpand`).
  final String? expandActionLabel;

  /// The custom accessibility action that collapses it.
  final String? collapseActionLabel;

  /// The container's thickness: 64dp (`FloatingToolbarTokens.containerHeight`).
  static const double containerSize = FloatingToolbarTokens.containerHeight;

  /// The distance from the screen's edge a floating toolbar keeps
  /// (`FloatingToolbarDefaults.ScreenOffset`, 16dp).
  static const double screenOffset =
      FloatingToolbarTokens.containerExternalPadding;

  @override
  State<ExpressiveFloatingToolbar> createState() =>
      _ExpressiveFloatingToolbarState();
}

class _ExpressiveFloatingToolbarState extends State<ExpressiveFloatingToolbar> {
  /// Compose's `forceCollapse`: set by the collapse custom action.
  bool _forceCollapse = false;

  Map<CustomSemanticsAction, VoidCallback> _actions(bool expanded) =>
      <CustomSemanticsAction, VoidCallback>{
        CustomSemanticsAction(
          label: expanded
              ? widget.collapseActionLabel ??
                    ExpressiveLocalizations.of(context).toolbarCollapse
              : widget.expandActionLabel ??
                    ExpressiveLocalizations.of(context).toolbarExpand,
        ): () =>
            setState(() => _forceCollapse = expanded),
      };

  @override
  Widget build(BuildContext context) {
    assert(
      ExpressiveFabMenu.debugCheckNoMenuBeside(
        context,
        'ExpressiveFloatingToolbar',
      ),
    );
    final touchExploration = MediaQuery.accessibleNavigationOf(context);
    final expanded = !_forceCollapse && (touchExploration || widget.expanded);
    final t = context.expressiveTheme;
    final container = t.colors.role(widget.kind.container);
    final content = _contentFor(context, container);
    final shape = t.shapes.of(FloatingToolbarTokens.containerShape);
    final withFab = widget.floatingActionButton != null;
    final expandedElevation =
        widget.expandedElevation ??
        (withFab
            ? ExpressiveElevationLevel.level1
            : ExpressiveElevationLevel.level0);
    final collapsedElevation =
        widget.collapsedElevation ?? ExpressiveElevationLevel.level0;

    Widget toolbar = withFab
        ? _withFab(
            context,
            expanded: expanded,
            container: container,
            content: content,
            shape: shape,
            expandedElevation: expandedElevation,
            collapsedElevation: collapsedElevation,
          )
        : _plain(
            expanded: expanded,
            container: container,
            content: content,
            shape: shape,
            elevation: expanded ? expandedElevation : collapsedElevation,
          );
    final behavior = touchExploration ? null : widget.scrollBehavior;
    if (behavior != null) {
      toolbar = _ScrollExit(
        behavior: behavior,
        docked: false,
        motion: FloatingToolbarBehavior.snapMotion,
        child: toolbar,
      );
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: toolbar,
    );
  }

  /// `HorizontalFloatingToolbarLayout` / `VerticalFloatingToolbarLayout`.
  Widget _plain({
    required bool expanded,
    required Color container,
    required Color content,
    required OutlinedBorder shape,
    required ExpressiveElevationLevel elevation,
  }) {
    final axis = widget.axis;
    final horizontal = axis == Axis.horizontal;
    return ExpressiveSurface(
      style: widget.style,
      componentStyle: context.expressiveTheme.toolbarTheme,
      padding: _floatingPadding,
      shape: shape,
      color: container,
      contentColor: content,
      shadowElevation: elevation,
      elevationMotion: FloatingToolbarBehavior.expandMotion,
      child: ConstrainedBox(
        constraints: horizontal
            ? BoxConstraints(
                minHeight: context.expressiveTheme.density.height(48),
              )
            : BoxConstraints(
                minWidth: context.expressiveTheme.density.width(48),
              ),
        child: SingleChildScrollView(
          scrollDirection: axis,
          child: Flex(
            direction: axis,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.leading.isNotEmpty)
                _Expand(
                  visible: expanded,
                  axis: axis,
                  // Leading content expands from its start and shrinks
                  // towards the end (horizontal); from and towards the
                  // bottom (vertical).
                  enter: horizontal
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.bottomCenter,
                  exit: horizontal
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.bottomCenter,
                  child: _line(axis, widget.leading),
                ),
              Semantics(
                customSemanticsActions: _actions(expanded),
                child: _line(axis, widget.children),
              ),
              if (widget.trailing.isNotEmpty)
                _Expand(
                  visible: expanded,
                  axis: axis,
                  enter: horizontal
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.topCenter,
                  exit: horizontal
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.topCenter,
                  child: _line(axis, widget.trailing),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// `HorizontalFloatingToolbarWithFabLayout` / `Vertical…`.
  Widget _withFab(
    BuildContext context, {
    required bool expanded,
    required Color container,
    required Color content,
    required OutlinedBorder shape,
    required ExpressiveElevationLevel expandedElevation,
    required ExpressiveElevationLevel collapsedElevation,
  }) {
    final axis = widget.axis;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final body = NotificationListener<ScrollNotification>(
      // The toolbar's own overflow scroll is no page scroll.
      onNotification: (_) => true,
      child: SingleChildScrollView(
        scrollDirection: axis,
        child: _line(axis, widget.children),
      ),
    );
    final theme = context.expressiveTheme;
    final resolved = theme.toolbarTheme.merge(widget.style);
    const states = <WidgetState>{};
    final supplied = resolved.shape?.resolve(states);
    final side =
        resolved.side?.resolve(states) ??
        BorderSide.none.copyWith(
          color: resolved.outline?.resolve(states),
          style: resolved.outline?.resolve(states) == null
              ? null
              : BorderStyle.solid,
        );
    final padding =
        (resolved.padding
                ?.resolve(states)
                ?.resolve(Directionality.of(context)) ??
            theme.density.padding(
              _floatingPadding.resolve(Directionality.of(context)),
            )) +
        (supplied
                ?.copyWith(side: side)
                .dimensions
                .resolve(Directionality.of(context)) ??
            EdgeInsets.zero);
    final minimum = resolved.minimumSize?.resolve(states);
    final containerSize = math.max(
      axis == Axis.horizontal ? minimum?.height ?? 0 : minimum?.width ?? 0,
      48 + (axis == Axis.horizontal ? padding.vertical : padding.horizontal),
    );
    final fab = Semantics(
      customSemanticsActions: _actions(expanded),
      child: widget.floatingActionButton,
    );
    return ExpressiveSpringValue(
      value: expanded ? 1 : 0,
      motion: FloatingToolbarBehavior.expandMotion,
      builder: (context, progress, _) => _ToolbarWithFab(
        axis: axis,
        containerSize: containerSize,
        progress: progress,
        fabPosition: widget.fabPosition,
        devicePixelRatio: ratio,
        textDirection: Directionality.of(context),
        children: <Widget>[
          _ToolbarBody(
            style: widget.style,
            shape: shape,
            color: container,
            contentColor: content,
            elevation:
                lerpDouble(
                  collapsedElevation.dp,
                  expandedElevation.dp,
                  math.min(progress, 1),
                ) ??
                0,
            child: body,
          ),
          fab,
        ],
      ),
    );
  }
}

/// `FloatingToolbarDefaults.ContentPadding`: 8dp all round.
const EdgeInsetsDirectional _floatingPadding = EdgeInsetsDirectional.fromSTEB(
  FloatingToolbarTokens.containerLeadingSpace,
  FloatingToolbarTokens.containerLeadingSpace,
  FloatingToolbarTokens.containerTrailingSpace,
  FloatingToolbarTokens.containerTrailingSpace,
);

/// A row or column of [children], centred across [axis] (Compose's
/// `Row(content = …)` inside the toolbar's centred row).
Widget _line(Axis axis, List<Widget> children) =>
    Flex(direction: axis, mainAxisSize: MainAxisSize.min, children: children);

/// `AnimatedVisibility` with `horizontal/verticalEnterTransition` and
/// `…ExitTransition`: [child] clipped to a share of its length along
/// [axis] that springs between 0 and 1, aligned to [enter] while it grows
/// and [exit] while it shrinks; gone once hidden.
class _Expand extends StatelessWidget {
  const _Expand({
    required this.visible,
    required this.axis,
    required this.enter,
    required this.exit,
    required this.child,
  });

  final bool visible;
  final Axis axis;
  final AlignmentDirectional enter;
  final AlignmentDirectional exit;
  final Widget child;

  @override
  Widget build(BuildContext context) => ExpressiveSpringValue(
    value: visible ? 1 : 0,
    motion: FloatingToolbarBehavior.expandMotion,
    child: child,
    builder: (context, share, child) {
      if (!visible && share <= 0) return const SizedBox.shrink();
      final factor = math.max(0.0, share);
      return ClipRect(
        child: Align(
          alignment: visible ? enter : exit,
          // Shrink-wrap the cross axis too: an Align without a factor
          // grows to the toolbar's loose cross-axis maximum (the whole
          // 96dp crop, not the 64dp container).
          widthFactor: axis == Axis.horizontal ? factor : 1,
          heightFactor: axis == Axis.vertical ? factor : 1,
          child: child,
        ),
      );
    },
  );
}

/// The toolbar beside a FAB: its container filled, casting [elevation]dp
/// of shadow, clipped to [shape] (the layer Compose places it with).
class _ToolbarBody extends StatelessWidget {
  const _ToolbarBody({
    required this.style,
    required this.shape,
    required this.color,
    required this.contentColor,
    required this.elevation,
    required this.child,
  });

  final ExpressiveComponentThemeData? style;
  final OutlinedBorder shape;
  final Color color;
  final Color contentColor;
  final double elevation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final theme = context.expressiveTheme;
    final resolved = theme.toolbarTheme.merge(style);
    const states = <WidgetState>{};
    final supplied = resolved.shape?.resolve(states);
    final side =
        resolved.side?.resolve(states) ??
        BorderSide.none.copyWith(color: resolved.outline?.resolve(states));
    final shape = (supplied ?? this.shape).copyWith(side: side);
    final color = Color.alphaBlend(
      resolved.overlayColor?.resolve(states) ?? expressiveTransparent,
      resolved.backgroundColor?.resolve(states) ?? this.color,
    );
    final contentColor =
        resolved.foregroundColor?.resolve(states) ?? this.contentColor;
    final padding =
        (resolved.padding?.resolve(states)?.resolve(direction) ??
            theme.density.padding(_floatingPadding.resolve(direction))) +
        (supplied == null &&
                resolved.side?.resolve(states) == null &&
                resolved.outline?.resolve(states) == null
            ? EdgeInsets.zero
            : shape.dimensions.resolve(direction));
    final minimum = resolved.minimumSize?.resolve(states);
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minimum?.width ?? 0,
        minHeight: minimum?.height ?? 0,
      ),
      child: CustomPaint(
        painter: _BodyPainter(
          shape: shape,
          color: color,
          elevation: ExpressiveElevation(context.expressiveTheme.colors),
          elevationDp: elevation,
          textDirection: direction,
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape, textDirection: direction),
          child: IconTheme.merge(
            data: IconThemeData(
              color: contentColor,
              size: resolved.iconSize?.resolve(states),
            ),
            child: DefaultTextStyle.merge(
              style: (resolved.textStyle?.resolve(states) ?? const TextStyle())
                  .copyWith(color: contentColor),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  const _BodyPainter({
    required this.shape,
    required this.color,
    required this.elevation,
    required this.elevationDp,
    required this.textDirection,
  });

  final OutlinedBorder shape;
  final Color color;
  final ExpressiveElevation elevation;
  final double elevationDp;
  final TextDirection? textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final path = shape.getOuterPath(
      Offset.zero & size,
      textDirection: textDirection,
    );
    elevation.paintShadow(canvas, path, elevationDp);
    canvas.drawPath(path, Paint()..color = color);
    shape.paint(canvas, Offset.zero & size, textDirection: textDirection);
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.shape != shape ||
      old.color != color ||
      old.elevation != elevation ||
      old.elevationDp != elevationDp ||
      old.textDirection != textDirection;
}

/// The two-child measure policy of `…FloatingToolbarWithFabLayout`: the
/// toolbar (first child) takes `progress` of its maximum intrinsic length,
/// the FAB (second) a square from 80dp collapsed to 56dp expanded, the two
/// [FloatingToolbarBehavior.toolbarToFabGap] apart at full length.
class _ToolbarWithFab extends MultiChildRenderObjectWidget {
  const _ToolbarWithFab({
    required this.axis,
    required this.containerSize,
    required this.progress,
    required this.fabPosition,
    required this.devicePixelRatio,
    required this.textDirection,
    required super.children,
  });

  final Axis axis;
  final double containerSize;
  final double progress;
  final ExpressiveToolbarFabPosition fabPosition;
  final double devicePixelRatio;
  final TextDirection textDirection;

  @override
  _RenderToolbarWithFab createRenderObject(BuildContext context) =>
      _RenderToolbarWithFab(
        axis: axis,
        containerSize: containerSize,
        progress: progress,
        fabPosition: fabPosition,
        devicePixelRatio: devicePixelRatio,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderToolbarWithFab renderObject,
  ) {
    renderObject
      ..axis = axis
      ..containerSize = containerSize
      ..progress = progress
      ..fabPosition = fabPosition
      ..devicePixelRatio = devicePixelRatio
      ..textDirection = textDirection;
  }
}

class _ToolbarWithFabParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderToolbarWithFab extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ToolbarWithFabParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ToolbarWithFabParentData> {
  _RenderToolbarWithFab({
    required this._axis,
    required this._containerSize,
    required this._progress,
    required this._fabPosition,
    required this._devicePixelRatio,
    required this._textDirection,
  });

  double _containerSize;
  set containerSize(double value) {
    if (value == _containerSize) return;
    _containerSize = value;
    markNeedsLayout();
  }

  Axis _axis;
  set axis(Axis value) {
    if (value == _axis) return;
    _axis = value;
    markNeedsLayout();
  }

  double _progress;
  set progress(double value) {
    if (value == _progress) return;
    _progress = value;
    markNeedsLayout();
  }

  ExpressiveToolbarFabPosition _fabPosition;
  set fabPosition(ExpressiveToolbarFabPosition value) {
    if (value == _fabPosition) return;
    _fabPosition = value;
    markNeedsLayout();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// `FloatingToolbarDefaults.FabSizeRange`: the baseline FAB's width to
  /// the medium FAB's.
  static const double _fabMin = FabBaselineTokens.containerWidth;
  static const double _fabMax = FabMediumTokens.containerWidth;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ToolbarWithFabParentData) {
      child.parentData = _ToolbarWithFabParentData();
    }
  }

  RenderBox get _toolbar => firstChild!;
  RenderBox get _fab => lastChild!;

  bool get _horizontal => _axis == Axis.horizontal;

  double _px(double dp) => _roundToPixels(dp, _devicePixelRatio);

  /// The toolbar's full length along the axis at the container's
  /// thickness (`maxIntrinsicWidth(height = ContainerSize)`).
  double _toolbarLength() {
    final container = _px(_containerSize);
    return _px(
      _horizontal
          ? _toolbar.getMaxIntrinsicWidth(container)
          : _toolbar.getMaxIntrinsicHeight(container),
    );
  }

  /// The layout's length along the axis: the toolbar's full length, the
  /// gap and the smallest FAB.
  double _length() =>
      _toolbarLength() +
      _px(FloatingToolbarBehavior.toolbarToFabGap) +
      _px(_fabMin);

  /// The thickness across the axis: `defaultMinSize` of the largest FAB.
  double _across(BoxConstraints constraints) => _horizontal
      ? (constraints.minHeight == 0
            ? math.min(math.max(_fabMax, _containerSize), constraints.maxHeight)
            : constraints.minHeight)
      : (constraints.minWidth == 0
            ? math.min(math.max(_fabMax, _containerSize), constraints.maxWidth)
            : constraints.minWidth);

  @override
  double computeMinIntrinsicWidth(double height) =>
      _horizontal ? _length() : _fabMax;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      computeMinIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _horizontal ? _fabMax : _length();

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final across = _across(constraints);
    return constraints.constrain(
      _horizontal ? Size(_length(), across) : Size(across, _length()),
    );
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    final ratio = _devicePixelRatio;
    // The FAB is at its smallest when the toolbar is fully expanded.
    final fabSide = _px(lerpDouble(_fabMin, _fabMax, 1 - _progress)!);
    _fab.layout(
      BoxConstraints.tight(Size.square(fabSide)),
      parentUsesSize: true,
    );

    size = computeDryLayout(constraints);
    final available =
        (_horizontal ? size.width : size.height) -
        fabSide -
        _px(FloatingToolbarBehavior.toolbarToFabGap);
    final full = math.min(_toolbarLength(), math.max(0.0, available));
    final target = math.max(0.0, _floorToPixels(full * _progress, ratio));
    final container = _px(_containerSize);
    if (_horizontal) {
      _toolbar.layout(
        BoxConstraints(
          maxWidth: math.min(target, constraints.maxWidth),
          minHeight: math.min(container, size.height),
          maxHeight: constraints.maxHeight,
        ),
        parentUsesSize: true,
      );
    } else {
      _toolbar.layout(
        BoxConstraints(
          minWidth: math.min(container, size.width),
          maxWidth: constraints.maxWidth,
          maxHeight: math.min(target, constraints.maxHeight),
        ),
        parentUsesSize: true,
      );
    }

    final atEnd = _fabPosition == ExpressiveToolbarFabPosition.end;
    final toolbar = _toolbar.size;
    final fab = _fab.size;
    Offset toolbarAt;
    Offset fabAt;
    if (_horizontal) {
      var fabX = atEnd ? size.width - fab.width : 0.0;
      var toolbarX = atEnd ? full - toolbar.width : size.width - full;
      // `placeRelative`: mirrored right to left.
      if (_textDirection == TextDirection.rtl) {
        fabX = size.width - fabX - fab.width;
        toolbarX = size.width - toolbarX - toolbar.width;
      }
      toolbarAt = Offset(
        toolbarX,
        _floorToPixels((size.height - toolbar.height) / 2, ratio),
      );
      fabAt = Offset(
        fabX,
        _floorToPixels((size.height - fab.height) / 2, ratio),
      );
    } else {
      toolbarAt = Offset(
        _floorToPixels((size.width - toolbar.width) / 2, ratio),
        atEnd ? full - toolbar.height : size.height - full,
      );
      fabAt = Offset(
        _floorToPixels((size.width - fab.width) / 2, ratio),
        atEnd ? size.height - fab.height : 0.0,
      );
    }
    (_toolbar.parentData! as _ToolbarWithFabParentData).offset = toolbarAt;
    (_fab.parentData! as _ToolbarWithFabParentData).offset = fabAt;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

// ---------------------------------------------------------------------------
// The toolbar's FAB
// ---------------------------------------------------------------------------

/// The FAB beside a floating toolbar (Compose's
/// `FloatingToolbarDefaults.StandardFloatingActionButton` and
/// `VibrantFloatingActionButton`): the FAB's shape and 24dp icon in
/// [kind]'s FAB colours, filling the square the toolbar gives it (56dp
/// expanded, 80dp collapsed), at elevation level 2 (3 while hovered).
class ExpressiveToolbarFab extends StatelessWidget {
  /// A FAB showing [icon] that runs [onPressed].
  const ExpressiveToolbarFab({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.kind = ExpressiveToolbarKind.standard,
    this.style,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The glyph: one of `ExpressiveSymbols`.
  final IconData icon;

  /// What a tap does; null disables it.
  final VoidCallback? onPressed;

  /// What a screen reader says: the act.
  final String semanticLabel;

  /// The toolbar's kind, whose FAB colours this takes (match the
  /// toolbar's).
  final ExpressiveToolbarKind kind;

  /// Stateful visual overrides; null slots fall through to the theme.
  final ExpressiveComponentThemeData? style;

  /// A tooltip message, announced as the FAB's hint.
  final String? tooltip;

  /// The focus node; one is made when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final container = t.colors.role(kind.fabContainer);
    return ExpressivePressable(
      style: style,
      componentStyle: t.floatingActionButtonTheme,
      shapes: ExpressivePressShapes.all(
        t.shapes.of(FabBaselineTokens.containerShape),
      ),
      motion: FloatingActionButtonBehavior.expandSizeMotion,
      color: container,
      contentColor: _contentFor(context, container),
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      // `FloatingActionButtonDefaults.elevation(Level2, Level2, Level2,
      // Level3)` in both toolbar FABs.
      elevation: const ExpressiveStateElevation(
        rest: ExpressiveElevationLevel.level2,
        pressed: ExpressiveElevationLevel.level2,
        focused: ExpressiveElevationLevel.level2,
        hovered: ExpressiveElevationLevel.level3,
      ),
      elevationMotion: ExpressiveMotionKey.fastEffects,
      minimumInteractiveSize: false,
      focusNode: focusNode,
      autofocus: autofocus,
      child: SizedBox.expand(
        child: ExpressiveStyledContent(
          iconSize: FabBaselineTokens.iconSize,
          child: Icon(icon),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Docked toolbar
// ---------------------------------------------------------------------------

/// The docked toolbar: a full-width bar of actions at the bottom of the
/// screen (Compose's `FlexibleBottomAppBar`), 64dp tall above the bottom
/// inset, its actions spread across it or at the fixed spacing.
///
/// For a screen's persistent actions where a floating toolbar would cover
/// content. [scrollBehavior] lets it slide away as content scrolls.
class ExpressiveDockedToolbar extends StatelessWidget {
  /// A docked toolbar of [children].
  const ExpressiveDockedToolbar({
    required this.children,
    this.kind = ExpressiveToolbarKind.standard,
    this.style,
    this.arrangement = ExpressiveDockedToolbarArrangement.spaceBetween,
    this.scrollBehavior,
    this.safeArea = true,
    this.semanticLabel,
    super.key,
  });

  /// The actions.
  final List<Widget> children;

  /// Standard (`surfaceContainer`) or vibrant (`primaryContainer`).
  final ExpressiveToolbarKind kind;

  /// Stateful visual overrides; null slots fall through to the theme.
  final ExpressiveComponentThemeData? style;

  /// How the actions are spaced.
  final ExpressiveDockedToolbarArrangement arrangement;

  /// Collapses the bar while content scrolls; see
  /// [ExpressiveToolbarScrollBehavior].
  final ExpressiveToolbarScrollBehavior? scrollBehavior;

  /// Whether the bar pads the bottom and side system insets itself
  /// (`BottomAppBarDefaults.windowInsets`).
  final bool safeArea;

  /// What a screen reader calls the toolbar.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    assert(
      ExpressiveFabMenu.debugCheckNoMenuBeside(
        context,
        'ExpressiveDockedToolbar',
      ),
    );
    final t = context.expressiveTheme;
    final container = t.colors.role(
      kind == ExpressiveToolbarKind.standard
          ? DockedToolbarTokens.containerColor
          : kind.container,
    );
    final insets = safeArea
        ? MediaQuery.paddingOf(context).copyWith(top: 0)
        : EdgeInsets.zero;
    final fixed = arrangement == ExpressiveDockedToolbarArrangement.fixed;
    Widget row = Row(
      mainAxisAlignment: fixed
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      spacing: fixed ? DockedToolbarTokens.containerMaxSpacing : 0,
      children: children,
    );
    if (safeArea) {
      row = MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeRight: true,
        removeBottom: true,
        child: row,
      );
    }
    Widget bar = ExpressiveSurface(
      style: style,
      componentStyle: t.toolbarTheme,
      padding: const EdgeInsetsDirectional.only(
        start: DockedToolbarTokens.containerLeadingSpace,
        end: DockedToolbarTokens.containerTrailingSpace,
      ),
      shape: t.shapes.of(DockedToolbarTokens.containerShape),
      color: container,
      contentColor: _contentFor(context, container),
      child: Padding(
        padding: insets,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: t.density.height(DockedToolbarTokens.containerHeight),
          ),
          child: SizedBox(width: double.infinity, child: row),
        ),
      ),
    );
    final behavior = MediaQuery.accessibleNavigationOf(context)
        ? null
        : scrollBehavior;
    if (behavior != null) {
      bar = _ScrollExit(
        behavior: behavior,
        docked: true,
        motion: DockedToolbarBehavior.snapMotion,
        child: bar,
      );
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: bar,
    );
  }
}

// ---------------------------------------------------------------------------
// Scroll behaviours
// ---------------------------------------------------------------------------

/// Moves a toolbar off the screen while its content scrolls on and back as
/// it scrolls back (Compose's `FloatingToolbarDefaults
/// .exitAlwaysScrollBehavior`; for an [ExpressiveDockedToolbar],
/// `BottomAppBarDefaults.exitAlwaysScrollBehavior`, which collapses the
/// bar's height). When the scroll stops part way, the toolbar snaps to
/// shown or hidden, whichever is nearer, on its spring.
///
/// Hand [handleScrollNotification] to a `NotificationListener` around the
/// scrolling content and the behaviour to one toolbar. Own and dispose it
/// like a controller.
class ExpressiveToolbarScrollBehavior extends ChangeNotifier {
  /// A scroll behavior that exits toward [exitDirection].
  ExpressiveToolbarScrollBehavior({this.exitDirection = AxisDirection.down});

  /// Which edge a floating toolbar leaves by (Compose's
  /// `FloatingToolbarExitDirection`); a docked toolbar always leaves by the
  /// bottom.
  final AxisDirection exitDirection;

  double _offset = 0;
  double _offsetLimit = double.negativeInfinity;
  _ScrollExitState? _client;

  /// How far the toolbar has moved off: 0 shown, [offsetLimit] gone.
  double get offset => _offset;

  /// The (negative) offset at which the toolbar is fully off the screen;
  /// negative infinity until a toolbar has been laid out.
  double get offsetLimit => _offsetLimit;

  /// How much of the way off the toolbar is, 0 to 1.
  double get collapsedFraction =>
      _offsetLimit == 0 || _offsetLimit.isInfinite ? 0 : _offset / _offsetLimit;

  void _setOffset(double value) {
    final clamped = math.min(0.0, math.max(_offsetLimit, value));
    if (clamped == _offset) return;
    _offset = clamped;
    notifyListeners();
  }

  /// Brings the toolbar fully back at once.
  void show() {
    _client?._stop();
    _setOffset(0);
  }

  /// Feeds a scroll of the content to the toolbar: pass it to a
  /// `NotificationListener<ScrollNotification>` around the scrolling
  /// content. Only the nearest vertical scrollable's notifications count;
  /// overscroll does not move the toolbar. Returns false, so the
  /// notification keeps bubbling.
  bool handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final client = _client;
    if (notification is ScrollStartNotification) {
      client?._stop();
    } else if (notification is ScrollUpdateNotification) {
      final advanced = _advanced(notification);
      if (advanced != 0) {
        client?._stop();
        client?._refreshLimit();
        // `state.offset += consumed.y`: Compose's consumed y is negative
        // while the content moves up the screen, which takes the toolbar
        // off.
        final up = notification.metrics.axisDirection == AxisDirection.up;
        _setOffset(_offset + (up ? advanced : -advanced));
      }
    } else if (notification is ScrollEndNotification) {
      client?._settle();
    }
    return false;
  }
}

/// How far the content advanced in [n] (towards its end), overscroll
/// excluded (Compose's nested scroll reports only the consumed delta).
double _advanced(ScrollUpdateNotification n) {
  final m = n.metrics;
  final delta = n.scrollDelta ?? 0;
  double clamp(double v) =>
      math.min(m.maxScrollExtent, math.max(m.minScrollExtent, v));
  return clamp(m.pixels) - clamp(m.pixels - delta);
}

/// Applies an [ExpressiveToolbarScrollBehavior] to [child]: a floating
/// toolbar translated off by the offset (Compose's `placeWithLayer`), a
/// docked one shortened by it; not keyboard-focusable while moved; the
/// snap on a spring.
class _ScrollExit extends StatefulWidget {
  const _ScrollExit({
    required this.behavior,
    required this.docked,
    required this.motion,
    required this.child,
  });

  final ExpressiveToolbarScrollBehavior behavior;
  final bool docked;
  final ExpressiveMotionKey motion;
  final Widget child;

  @override
  State<_ScrollExit> createState() => _ScrollExitState();
}

class _ScrollExitState extends State<_ScrollExit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snap = AnimationController.unbounded(
    vsync: this,
  )..addListener(() => widget.behavior._setOffset(_snap.value));

  @override
  void initState() {
    super.initState();
    widget.behavior._client = this;
  }

  @override
  void didUpdateWidget(_ScrollExit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.behavior != widget.behavior) {
      if (oldWidget.behavior._client == this) {
        oldWidget.behavior._client = null;
      }
      widget.behavior._client = this;
    }
  }

  @override
  void dispose() {
    if (widget.behavior._client == this) widget.behavior._client = null;
    _snap.dispose();
    super.dispose();
  }

  void _stop() {
    if (_snap.isAnimating) _snap.stop();
  }

  /// A floating toolbar's limit: how far it must move to leave its
  /// parent by the exit edge (Compose's `onGloballyPositioned` measure
  /// against `parentLayoutCoordinates`; the screen when it has no parent
  /// box).
  void _refreshLimit() {
    if (widget.docked || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final parent = box.parent;
    final Offset origin;
    final Size area;
    if (parent is RenderBox && parent.hasSize) {
      origin = box.localToGlobal(Offset.zero, ancestor: parent);
      area = parent.size;
    } else {
      origin = box.localToGlobal(Offset.zero);
      area = MediaQuery.sizeOf(context);
    }
    final extent = switch (widget.behavior.exitDirection) {
      AxisDirection.down => area.height - origin.dy,
      AxisDirection.up => box.size.height + origin.dy,
      AxisDirection.right => area.width - origin.dx,
      AxisDirection.left => box.size.width + origin.dx,
    };
    widget.behavior._offsetLimit = -math.max(0.0, extent);
  }

  /// `settleFloatingToolbar` / `settleAppBarBottom`: part way, spring to
  /// whichever end is nearer.
  void _settle() {
    final b = widget.behavior;
    final fraction = b.collapsedFraction;
    if (fraction < 0.01 || fraction == 1) return;
    if (b.offset < 0 && b.offset > b.offsetLimit) {
      final target = fraction < 0.5 ? 0.0 : b.offsetLimit;
      _snap.value = b.offset;
      _snap
          .animateWith(
            SpringSimulation(
              ExpressiveMotion.of(context).spring(widget.motion),
              b.offset,
              target,
              0,
            ),
          )
          // A spring lands within its tolerance: end exactly on the target,
          // as Compose's animateTo does.
          // (A stopped snap never completes.)
          .then((_) => b._setOffset(target));
    }
  }

  /// A docked toolbar can collapse its whole height.
  void _onHeight(double height) => widget.behavior._offsetLimit = -height;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.behavior,
    builder: (context, child) {
      final offset = widget.behavior.offset;
      final Widget moved;
      if (widget.docked) {
        moved = _HeightOffset(
          offset: offset,
          onHeight: _onHeight,
          child: child,
        );
      } else {
        final shift = switch (widget.behavior.exitDirection) {
          AxisDirection.down => Offset(0, -offset),
          AxisDirection.up => Offset(0, offset),
          AxisDirection.right => Offset(-offset, 0),
          AxisDirection.left => Offset(offset, 0),
        };
        moved = Transform.translate(offset: shift, child: child);
      }
      // An offscreen toolbar is not keyboard-focusable.
      return ExcludeFocus(excluding: offset != 0, child: moved);
    },
    child: widget.child,
  );
}

/// The docked toolbar's collapse: laid out at its full height, reporting
/// it, but only `height + offset` tall (its content runs off the bottom).
class _HeightOffset extends SingleChildRenderObjectWidget {
  const _HeightOffset({
    required this.offset,
    required this.onHeight,
    super.child,
  });

  final double offset;
  final ValueChanged<double> onHeight;

  @override
  _RenderHeightOffset createRenderObject(BuildContext context) =>
      _RenderHeightOffset(offset, onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeightOffset renderObject,
  ) {
    renderObject
      ..offset = offset
      ..onHeight = onHeight;
  }
}

class _RenderHeightOffset extends RenderProxyBox {
  _RenderHeightOffset(this._offset, this.onHeight);

  double _offset;
  set offset(double value) {
    if (value == _offset) return;
    _offset = value;
    markNeedsLayout();
  }

  ValueChanged<double> onHeight;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    onHeight(child.size.height);
    size = constraints.constrain(
      Size(child.size.width, math.max(0, child.size.height + _offset)),
    );
  }
}

/// Collapses and expands a floating toolbar as its content scrolls
/// (Compose's `Modifier.floatingToolbarVerticalNestedScroll`): once the
/// content advances [collapseThreshold] (40dp) the toolbar collapses; once
/// it scrolls back [expandThreshold] it expands.
///
/// Wrap the scrolling [child]; [builder] gets whether the toolbar should be
/// expanded and the child, listened to, and lays the two out (usually a
/// `Stack` with the toolbar at the bottom).
class ExpressiveToolbarScrollExpansion extends StatefulWidget {
  /// A scope that builds a toolbar with `builder`, collapsing it as [child] scrolls.
  const ExpressiveToolbarScrollExpansion({
    required this.builder,
    required this.child,
    this.initiallyExpanded = true,
    this.expandThreshold = FloatingToolbarBehavior.scrollDistanceThreshold,
    this.collapseThreshold = FloatingToolbarBehavior.scrollDistanceThreshold,
    super.key,
  });

  /// Lays out the scrolling child and the toolbar, [expanded] or not.
  final Widget Function(BuildContext context, bool expanded, Widget child)
  builder;

  /// The scrolling content whose scroll drives the toolbar.
  final Widget child;

  /// Whether the toolbar starts expanded.
  final bool initiallyExpanded;

  /// How far the content scrolls back before the toolbar expands.
  final double expandThreshold;

  /// How far the content scrolls on before the toolbar collapses.
  final double collapseThreshold;

  @override
  State<ExpressiveToolbarScrollExpansion> createState() =>
      _ExpressiveToolbarScrollExpansionState();
}

class _ExpressiveToolbarScrollExpansionState
    extends State<ExpressiveToolbarScrollExpansion> {
  late bool _expanded = widget.initiallyExpanded;
  double _contentOffset = 0;
  late double _threshold = _expanded
      ? -widget.collapseThreshold
      : widget.expandThreshold;

  bool _onScroll(ScrollUpdateNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    // Compose's scroll delta: negative while the content advances.
    final delta = -_advanced(n);
    if (delta == 0) return false;
    _contentOffset += delta;
    if (delta < 0 && _contentOffset <= _threshold) {
      _threshold = _contentOffset + widget.expandThreshold;
      if (_expanded) setState(() => _expanded = false);
    } else if (delta > 0 && _contentOffset >= _threshold) {
      _threshold = _contentOffset - widget.collapseThreshold;
      if (!_expanded) setState(() => _expanded = true);
    }
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
