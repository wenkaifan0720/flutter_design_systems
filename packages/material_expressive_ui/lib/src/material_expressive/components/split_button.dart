/// Split buttons, XS–XL: a labelled leading button and a trailing chevron
/// that opens a menu (CONTRACT §4.1 `split-button`). Owner:
/// w3-iconbuttons, with `test/split_button_test.dart` and the gallery's
/// split-button demo.
///
/// A port of Compose material3 1.5.0-alpha29's `SplitButton.kt` (wave
/// decision F1):
///
/// - [ExpressiveSplitButtonLayout] is `SplitButtonLayout`: the trailing
///   button at its own width, the leading button in the rest, both as tall
///   as the taller, `between-space` apart; the pair keeps the 48dp touch
///   target, its halves do not.
/// - [ExpressiveSplitLeadingButton] and [ExpressiveSplitTrailingButton] are
///   `SplitButtonDefaults.LeadingButton` / `TrailingButton` and their
///   `Tonal…`, `Outlined…` and `Elevated…` forms: `ButtonDefaults`' colours,
///   elevation and outline for the kind; full outer corners and the size's
///   inner corner, which tightens to the size's pressed inner corner on
///   `SplitButtonBehavior.pressMotion` (`leadingButtonShapesFor` /
///   `trailingButtonShapesFor`). The trailing button, checked, becomes a
///   circle under a pressed-opacity veil of its content colour, and centres
///   its content optically (`horizontalCenterOptically`).
/// - [ExpressiveSplitButton] composes them the way Compose's samples do:
///   the leading icon and label at `ButtonDefaults.iconSizeFor`,
///   `iconSpacingFor` and `textStyleFor` the size, the trailing chevron at
///   `trailingButtonIconSizeFor`, turning a half turn when checked, and the
///   [ExpressiveSplitButton.menu] slot shown under the pair while it is.
///
/// L and XL split buttons (96 and 136dp) are hero widgets (CONTRACT §3):
/// they assert an [ExpressiveHeroMoment] above them.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/styled_content.dart';
import '../color.dart';
import '../elevation.dart';
import '../icons.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/button_large_tokens.g.dart';
import '../internal/tokens/button_medium_tokens.g.dart';
import '../internal/tokens/button_small_tokens.g.dart';
import '../internal/tokens/button_x_large_tokens.g.dart';
import '../internal/tokens/button_x_small_tokens.g.dart';
import '../internal/tokens/elevated_button_tokens.g.dart';
import '../internal/tokens/filled_button_tokens.g.dart';
import '../internal/tokens/filled_tonal_button_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/outlined_button_tokens.g.dart';
import '../internal/tokens/split_button_large_tokens.g.dart';
import '../internal/tokens/split_button_medium_tokens.g.dart';
import '../internal/tokens/split_button_small_tokens.g.dart';
import '../internal/tokens/split_button_x_large_tokens.g.dart';
import '../internal/tokens/split_button_x_small_tokens.g.dart';
import '../motion.dart';
import '../shape.dart';
import '../states.dart';
import '../strings.dart';
import '../theme.dart';
import 'hero.dart';
import 'overlays.dart' show ExpressiveBackHandle;

/// The four split-button styles (`SplitButtonDefaults.LeadingButton` and
/// its `Tonal…`, `Outlined…`, `Elevated…` forms).
enum ExpressiveSplitButtonKind {
  /// `primary`: the highest emphasis.
  filled,

  /// `secondaryContainer`.
  tonal,

  /// An outline, no fill.
  outlined,

  /// `surfaceContainerLow`, lifted.
  elevated,
}

/// The five split-button sizes: the container height.
enum ExpressiveSplitButtonSize {
  /// 32dp by its tokens; drawn at the small size's 40dp inside the layout,
  /// as Compose draws it (the halves' `defaultMinSize`).
  extraSmall,

  /// 40dp: the default.
  small,

  /// 56dp.
  medium,

  /// 96dp: a hero size.
  large,

  /// 136dp: a hero size.
  extraLarge;

  /// Whether the size is a hero moment (L, XL): it asserts an
  /// [ExpressiveHeroMoment] above it.
  bool get isHero =>
      this == ExpressiveSplitButtonSize.large ||
      this == ExpressiveSplitButtonSize.extraLarge;
}

/// One size's tokens: `SplitButton*Tokens` and the `ButtonDefaults` ladder
/// Compose's samples size the content with.
@immutable
class _SplitMetrics {
  const _SplitMetrics({
    required this.height,
    required this.between,
    required this.inner,
    required this.innerPressed,
    required this.leadingStart,
    required this.leadingEnd,
    required this.trailingStart,
    required this.trailingEnd,
    required this.trailingIconSize,
    required this.checkedPercent,
    required this.iconSize,
    required this.iconSpacing,
    required this.textStyle,
  });

  static _SplitMetrics of(ExpressiveSplitButtonSize size) => switch (size) {
    ExpressiveSplitButtonSize.extraSmall => _xs,
    ExpressiveSplitButtonSize.small => _s,
    ExpressiveSplitButtonSize.medium => _m,
    ExpressiveSplitButtonSize.large => _l,
    ExpressiveSplitButtonSize.extraLarge => _xl,
  };

  static const _SplitMetrics _xs = _SplitMetrics(
    height: SplitButtonXSmallTokens.containerHeight,
    between: SplitButtonXSmallTokens.betweenSpace,
    inner: SplitButtonXSmallTokens.innerCornerCornerSize,
    innerPressed: SplitButtonXSmallTokens.innerPressedCornerCornerSize,
    leadingStart: SplitButtonXSmallTokens.leadingButtonLeadingSpace,
    leadingEnd: SplitButtonXSmallTokens.leadingButtonTrailingSpace,
    trailingStart: SplitButtonXSmallTokens.trailingButtonLeadingSpace,
    trailingEnd: SplitButtonXSmallTokens.trailingButtonTrailingSpace,
    trailingIconSize: SplitButtonXSmallTokens.trailingIconSize,
    checkedPercent:
        SplitButtonXSmallTokens.trailingInnerSelectedCornerCornerSizePercent,
    iconSize: ButtonXSmallTokens.iconSize,
    // ButtonDefaults.ExtraSmallIconSpacing (4dp in code).
    iconSpacing: ButtonBehavior.extraSmallIconSpacing,
    textStyle: ExpressiveTypeKey.labelLarge,
  );

  static const _SplitMetrics _s = _SplitMetrics(
    height: SplitButtonSmallTokens.containerHeight,
    between: SplitButtonSmallTokens.betweenSpace,
    inner: SplitButtonSmallTokens.innerCornerCornerSize,
    innerPressed: SplitButtonSmallTokens.innerPressedCornerCornerSize,
    leadingStart: SplitButtonSmallTokens.leadingButtonLeadingSpace,
    leadingEnd: SplitButtonSmallTokens.leadingButtonTrailingSpace,
    trailingStart: SplitButtonSmallTokens.trailingButtonLeadingSpace,
    trailingEnd: SplitButtonSmallTokens.trailingButtonTrailingSpace,
    trailingIconSize: SplitButtonSmallTokens.trailingIconSize,
    checkedPercent:
        SplitButtonSmallTokens.trailingInnerSelectedCornerCornerSizePercent,
    iconSize: ButtonSmallTokens.iconSize,
    iconSpacing: ButtonSmallTokens.iconLabelSpace,
    textStyle: ExpressiveTypeKey.labelLarge,
  );

  static const _SplitMetrics _m = _SplitMetrics(
    height: SplitButtonMediumTokens.containerHeight,
    between: SplitButtonMediumTokens.betweenSpace,
    inner: SplitButtonMediumTokens.innerCornerCornerSize,
    innerPressed: SplitButtonMediumTokens.innerPressedCornerCornerSize,
    leadingStart: SplitButtonMediumTokens.leadingButtonLeadingSpace,
    leadingEnd: SplitButtonMediumTokens.leadingButtonTrailingSpace,
    trailingStart: SplitButtonMediumTokens.trailingButtonLeadingSpace,
    trailingEnd: SplitButtonMediumTokens.trailingButtonTrailingSpace,
    trailingIconSize: SplitButtonMediumTokens.trailingIconSize,
    checkedPercent:
        SplitButtonMediumTokens.trailingInnerSelectedCornerCornerSizePercent,
    iconSize: ButtonMediumTokens.iconSize,
    iconSpacing: ButtonMediumTokens.iconLabelSpace,
    textStyle: ExpressiveTypeKey.titleMedium,
  );

  static const _SplitMetrics _l = _SplitMetrics(
    height: SplitButtonLargeTokens.containerHeight,
    between: SplitButtonLargeTokens.betweenSpace,
    inner: SplitButtonLargeTokens.innerCornerCornerSize,
    innerPressed: SplitButtonLargeTokens.innerPressedCornerCornerSize,
    leadingStart: SplitButtonLargeTokens.leadingButtonLeadingSpace,
    leadingEnd: SplitButtonLargeTokens.leadingButtonTrailingSpace,
    trailingStart: SplitButtonLargeTokens.trailingButtonLeadingSpace,
    trailingEnd: SplitButtonLargeTokens.trailingButtonTrailingSpace,
    trailingIconSize: SplitButtonLargeTokens.trailingIconSize,
    checkedPercent:
        SplitButtonLargeTokens.trailingInnerSelectedCornerCornerSizePercent,
    iconSize: ButtonLargeTokens.iconSize,
    iconSpacing: ButtonLargeTokens.iconLabelSpace,
    textStyle: ExpressiveTypeKey.headlineSmall,
  );

  static const _SplitMetrics _xl = _SplitMetrics(
    height: SplitButtonXLargeTokens.containerHeight,
    between: SplitButtonXLargeTokens.betweenSpace,
    inner: SplitButtonXLargeTokens.innerCornerCornerSize,
    innerPressed: SplitButtonXLargeTokens.innerPressedCornerCornerSize,
    leadingStart: SplitButtonXLargeTokens.leadingButtonLeadingSpace,
    leadingEnd: SplitButtonXLargeTokens.leadingButtonTrailingSpace,
    trailingStart: SplitButtonXLargeTokens.trailingButtonLeadingSpace,
    trailingEnd: SplitButtonXLargeTokens.trailingButtonTrailingSpace,
    trailingIconSize: SplitButtonXLargeTokens.trailingIconSize,
    checkedPercent:
        SplitButtonXLargeTokens.trailingInnerSelectedCornerCornerSizePercent,
    iconSize: ButtonXLargeTokens.iconSize,
    iconSpacing: ButtonXLargeTokens.iconLabelSpace,
    textStyle: ExpressiveTypeKey.headlineLarge,
  );

  final double height;
  final double between;
  final double inner;
  final double innerPressed;
  final double leadingStart;
  final double leadingEnd;
  final double trailingStart;
  final double trailingEnd;
  final double trailingIconSize;
  final double checkedPercent;
  final double iconSize;
  final double iconSpacing;
  final ExpressiveTypeKey textStyle;

  /// A half's smallest height: the size's height as the samples'
  /// `heightIn(min = size)` sets it, but never under the small height —
  /// both halves' rows carry `defaultMinSize(minHeight =
  /// SmallContainerHeight)`, which `SplitButtonLayout`'s intrinsic
  /// measure honours, so Compose draws an XS split button 40dp tall.
  double get minHeight =>
      math.max(height, SplitButtonSmallTokens.containerHeight);
}

/// The outer corner: the container shape token's (fully round).
ExpressiveCornerSize _outer(ExpressiveShapes shapes) =>
    shapes.of(SplitButtonSmallTokens.containerShape).topStart;

/// `leadingButtonShapesFor(height)`: full start corners, the size's inner
/// end corners, tightening when pressed; no checked shape.
ExpressivePressShapes _leadingShapes(
  ExpressiveShapes shapes,
  _SplitMetrics metrics,
) {
  final outer = _outer(shapes);
  ExpressiveCornerBorder at(double inner) => ExpressiveCornerBorder(
    topStart: outer,
    bottomStart: outer,
    topEnd: ExpressiveCornerSize.dp(inner),
    bottomEnd: ExpressiveCornerSize.dp(inner),
  );
  return ExpressivePressShapes(
    shape: at(metrics.inner),
    pressed: at(metrics.innerPressed),
  );
}

/// `trailingButtonShapesFor(height)`: the mirror of the leading shapes,
/// checking to a circle (`TrailingCheckedShape`).
ExpressivePressShapes _trailingShapes(
  ExpressiveShapes shapes,
  _SplitMetrics metrics,
) {
  final outer = _outer(shapes);
  ExpressiveCornerBorder at(double inner) => ExpressiveCornerBorder(
    topStart: ExpressiveCornerSize.dp(inner),
    bottomStart: ExpressiveCornerSize.dp(inner),
    topEnd: outer,
    bottomEnd: outer,
  );
  return ExpressivePressShapes(
    shape: at(metrics.inner),
    pressed: at(metrics.innerPressed),
    selected: ExpressiveCornerBorder.all(
      ExpressiveCornerSize.fraction(metrics.checkedPercent / 100),
    ),
  );
}

/// `Modifier.padding(contentPadding)` as Compose measures it: each side
/// rounded to whole device pixels (`roundToPx`), so a 12dp side at a
/// fractional density lands where Compose puts it.
EdgeInsetsDirectional _snappedPadding(
  BuildContext context,
  double start,
  double end,
) {
  final ratio = MediaQuery.devicePixelRatioOf(context);
  double snap(double value) => (value * ratio).roundToDouble() / ratio;
  return EdgeInsetsDirectional.only(start: snap(start), end: snap(end));
}

/// What a split-button half paints with.
@immutable
class _SplitPaint {
  const _SplitPaint({
    required this.container,
    required this.content,
    this.side = BorderSide.none,
    this.elevation = ExpressiveStateElevation.none,
  });

  final Color container;
  final Color content;
  final BorderSide side;
  final ExpressiveStateElevation elevation;
}

const Color _transparent = expressiveTransparent;

Color _alpha(
  ExpressiveColorScheme colors,
  ExpressiveColorRole role,
  double alpha,
) => colors.role(role).withValues(alpha: alpha);

// ButtonDefaults.buttonElevation().
const ExpressiveStateElevation _filledElevation = ExpressiveStateElevation(
  rest: FilledButtonTokens.containerElevation,
  pressed: FilledButtonTokens.pressedContainerElevation,
  focused: FilledButtonTokens.focusedContainerElevation,
  hovered: FilledButtonTokens.hoveredContainerElevation,
  disabled: FilledButtonTokens.disabledContainerElevation,
);

// ButtonDefaults.filledTonalButtonElevation(): disabled is 0 in code.
const ExpressiveStateElevation _tonalElevation = ExpressiveStateElevation(
  rest: FilledTonalButtonTokens.containerElevation,
  pressed: FilledTonalButtonTokens.pressedContainerElevation,
  focused: FilledTonalButtonTokens.focusContainerElevation,
  hovered: FilledTonalButtonTokens.hoverContainerElevation,
  disabled: ExpressiveElevationLevel.level0,
);

// ButtonDefaults.elevatedButtonElevation().
const ExpressiveStateElevation _elevatedElevation = ExpressiveStateElevation(
  rest: ElevatedButtonTokens.containerElevation,
  pressed: ElevatedButtonTokens.pressedContainerElevation,
  focused: ElevatedButtonTokens.focusedContainerElevation,
  hovered: ElevatedButtonTokens.hoveredContainerElevation,
  disabled: ElevatedButtonTokens.disabledContainerElevation,
);

/// `ButtonDefaults.buttonColors`, `filledTonalButtonColors`,
/// `outlinedButtonColors` and `elevatedButtonColors` with their elevations
/// and `outlinedButtonBorder`, as the split button's halves default to.
_SplitPaint _splitPaint(
  ExpressiveColorScheme colors,
  ExpressiveSplitButtonKind kind, {
  required bool enabled,
}) {
  switch (kind) {
    case ExpressiveSplitButtonKind.filled:
      return enabled
          ? _SplitPaint(
              container: colors.role(FilledButtonTokens.containerColor),
              content: colors.role(FilledButtonTokens.labelTextColor),
              elevation: _filledElevation,
            )
          : _SplitPaint(
              container: _alpha(
                colors,
                FilledButtonTokens.disabledContainerColor,
                FilledButtonTokens.disabledContainerOpacity,
              ),
              content: _alpha(
                colors,
                FilledButtonTokens.disabledLabelTextColor,
                FilledButtonTokens.disabledLabelTextOpacity,
              ),
              elevation: _filledElevation,
            );
    case ExpressiveSplitButtonKind.tonal:
      return enabled
          ? _SplitPaint(
              container: colors.role(FilledTonalButtonTokens.containerColor),
              content: colors.role(FilledTonalButtonTokens.labelTextColor),
              elevation: _tonalElevation,
            )
          : _SplitPaint(
              container: _alpha(
                colors,
                FilledTonalButtonTokens.disabledContainerColor,
                FilledTonalButtonTokens.disabledContainerOpacity,
              ),
              content: _alpha(
                colors,
                FilledTonalButtonTokens.disabledLabelTextColor,
                FilledTonalButtonTokens.disabledLabelTextOpacity,
              ),
              elevation: _tonalElevation,
            );
    case ExpressiveSplitButtonKind.outlined:
      final outline = colors.role(OutlinedButtonTokens.outlineColor);
      return _SplitPaint(
        container: _transparent,
        content: enabled
            ? colors.role(OutlinedButtonTokens.labelTextColor)
            : _alpha(
                colors,
                OutlinedButtonTokens.disabledLabelTextColor,
                OutlinedButtonTokens.disabledLabelTextOpacity,
              ),
        side: BorderSide(
          width: ButtonSmallTokens.outlinedOutlineWidth,
          color: enabled
              ? outline
              : outline.withValues(
                  alpha: OutlinedButtonTokens.disabledContainerOpacity,
                ),
        ),
      );
    case ExpressiveSplitButtonKind.elevated:
      return enabled
          ? _SplitPaint(
              container: colors.role(ElevatedButtonTokens.containerColor),
              content: colors.role(ElevatedButtonTokens.labelTextColor),
              elevation: _elevatedElevation,
            )
          : _SplitPaint(
              container: _alpha(
                colors,
                ElevatedButtonTokens.disabledContainerColor,
                ElevatedButtonTokens.disabledContainerOpacity,
              ),
              content: _alpha(
                colors,
                ElevatedButtonTokens.disabledLabelTextColor,
                ElevatedButtonTokens.disabledLabelTextOpacity,
              ),
              elevation: _elevatedElevation,
            );
  }
}

/// `SplitButtonLayout`: [trailing] at its own width, [leading] in what is
/// left, both as tall as the taller, [spacing] apart (the size's
/// `between-space` when null). The pair keeps Compose's 48dp touch target;
/// its halves draw at their own size.
class ExpressiveSplitButtonLayout extends StatelessWidget {
  /// A split button layout of [leading] and [trailing].
  const ExpressiveSplitButtonLayout({
    required this.leading,
    required this.trailing,
    this.size = ExpressiveSplitButtonSize.small,
    this.spacing,
    super.key,
  });

  /// The leading button: an [ExpressiveSplitLeadingButton].
  final Widget leading;

  /// The trailing button: an [ExpressiveSplitTrailingButton].
  final Widget trailing;

  /// The size whose `between-space` separates the halves.
  final ExpressiveSplitButtonSize size;

  /// The gap between the halves; the size's `between-space` when null.
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    // Read here, outside the halves' shrunk targets: the layout keeps the
    // touch target, so each half's node reaches it.
    final touchHeight = ExpressiveMinimumInteractiveSize.enforcedAt(context)
        ? HostBehavior.minimumInteractiveComponentSize
        : 0.0;
    return ExpressiveMinimumInteractiveSize(
      child: ExpressiveShrinkTapTargets(
        child: _SplitPair(
          spacing: spacing ?? _SplitMetrics.of(size).between,
          touchHeight: touchHeight,
          children: [
            _HalfTarget(touchHeight: touchHeight, child: leading),
            _HalfTarget(touchHeight: touchHeight, child: trailing),
          ],
        ),
      ),
    );
  }
}

class _SplitPair extends MultiChildRenderObjectWidget {
  const _SplitPair({
    required this.spacing,
    required this.touchHeight,
    required super.children,
  });
  final double spacing;
  final double touchHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSplitPair(spacing, touchHeight, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSplitPair renderObject,
  ) => renderObject.update(spacing, touchHeight, Directionality.of(context));
}

class _SplitPairData extends ContainerBoxParentData<RenderBox> {}

class _RenderSplitPair extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SplitPairData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SplitPairData> {
  _RenderSplitPair(this._spacing, this._touchHeight, this._direction);
  double _spacing;
  double _touchHeight;
  TextDirection _direction;

  void update(double spacing, double touchHeight, TextDirection direction) {
    if (_spacing == spacing &&
        _touchHeight == touchHeight &&
        _direction == direction) {
      return;
    }
    _spacing = spacing;
    _touchHeight = touchHeight;
    _direction = direction;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SplitPairData) {
      child.parentData = _SplitPairData();
    }
  }

  double get _naturalWidth =>
      firstChild!.getMaxIntrinsicWidth(double.infinity) +
      _spacing +
      lastChild!.getMaxIntrinsicWidth(double.infinity);

  bool _stacks(double width) => _naturalWidth > width;

  @override
  double computeMaxIntrinsicWidth(double height) => _naturalWidth;
  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    firstChild!.getMinIntrinsicWidth(height),
    lastChild!.getMinIntrinsicWidth(height),
  );
  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);
  @override
  double computeMaxIntrinsicHeight(double width) {
    if (_stacks(width)) {
      return math.max(_touchHeight, firstChild!.getMaxIntrinsicHeight(width)) +
          _spacing +
          math.max(_touchHeight, lastChild!.getMaxIntrinsicHeight(width));
    }
    final trailingWidth = lastChild!.getMaxIntrinsicWidth(double.infinity);
    return math.max(
      firstChild!.getMaxIntrinsicHeight(
        math.max(0, width - trailingWidth - _spacing),
      ),
      lastChild!.getMaxIntrinsicHeight(trailingWidth),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    Size(
      math.min(_naturalWidth, constraints.maxWidth),
      computeMaxIntrinsicHeight(constraints.maxWidth),
    ),
  );

  @override
  void performLayout() {
    final leading = firstChild!;
    final trailing = lastChild!;
    if (_stacks(constraints.maxWidth)) {
      final width = constraints.maxWidth;
      final childConstraints = BoxConstraints.tightFor(width: width);
      leading.layout(childConstraints, parentUsesSize: true);
      trailing.layout(childConstraints, parentUsesSize: true);
      final firstHeight = math.max(_touchHeight, leading.size.height);
      final lastHeight = math.max(_touchHeight, trailing.size.height);
      size = constraints.constrain(
        Size(width, firstHeight + _spacing + lastHeight),
      );
      (leading.parentData! as _SplitPairData).offset = Offset(
        0,
        (firstHeight - leading.size.height) / 2,
      );
      (trailing.parentData! as _SplitPairData).offset = Offset(
        0,
        firstHeight + _spacing + (lastHeight - trailing.size.height) / 2,
      );
      return;
    }
    // Match the native IntrinsicHeight/Row: trailing at its own width,
    // leading loose in the remainder, both stretched to the taller half.
    final height = constraints.constrainHeight(
      computeMaxIntrinsicHeight(constraints.maxWidth),
    );
    trailing.layout(
      BoxConstraints(
        maxWidth: constraints.maxWidth,
        minHeight: height,
        maxHeight: height,
      ),
      parentUsesSize: true,
    );
    leading.layout(
      BoxConstraints(
        maxWidth: math.max(
          0,
          constraints.maxWidth - trailing.size.width - _spacing,
        ),
        minHeight: height,
        maxHeight: height,
      ),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      Size(leading.size.width + _spacing + trailing.size.width, height),
    );
    final ltr = _direction == TextDirection.ltr;
    (leading.parentData! as _SplitPairData).offset = Offset(
      ltr ? 0 : size.width - leading.size.width,
      0,
    );
    (trailing.parentData! as _SplitPairData).offset = Offset(
      ltr
          ? leading.size.width + _spacing
          : size.width - leading.size.width - _spacing - trailing.size.width,
      0,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A split button's leading half (`SplitButtonDefaults.LeadingButton` and
/// its styles): [child] in a row, the size's leading padding around it,
/// the end corners tightening on press.
class ExpressiveSplitLeadingButton extends StatelessWidget {
  /// A leading button showing [child] that runs [onPressed].
  const ExpressiveSplitLeadingButton({
    required this.onPressed,
    required this.child,
    this.kind = ExpressiveSplitButtonKind.filled,
    this.style,
    this.size = ExpressiveSplitButtonSize.small,
    this.semanticLabel,
    this.focusNode,
    super.key,
  });

  /// What a tap does; null disables the half.
  final VoidCallback? onPressed;

  /// The content: an icon and a label, usually ([ExpressiveSplitButton]
  /// lays them out the way Compose's samples do).
  final Widget child;

  /// The kind.
  final ExpressiveSplitButtonKind kind;

  /// Stateful visual overrides for this half or both halves.
  final ExpressiveComponentThemeData? style;

  /// The size.
  final ExpressiveSplitButtonSize size;

  /// What a screen reader says, over the content's own text.
  final String? semanticLabel;

  /// The focus node; one is made when null.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final metrics = _SplitMetrics.of(size);
    final paint = _splitPaint(theme.colors, kind, enabled: onPressed != null);
    return ExpressivePressable(
      style: style,
      componentStyle: theme.splitButtonTheme,
      shapes: _leadingShapes(theme.shapes, metrics),
      motion: SplitButtonBehavior.pressMotion,
      color: paint.container,
      contentColor: paint.content,
      side: paint.side,
      elevation: paint.elevation,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      // Stretched to a taller trailing half (a style's minimum size), the
      // content stays on the container's centre line.
      child: Center(
        widthFactor: 1,
        child: ExpressiveStyledContent(
          minimumSize: Size(
            SplitButtonBehavior.leadingButtonMinWidth,
            metrics.minHeight,
          ),
          padding: _snappedPadding(
            context,
            metrics.leadingStart,
            metrics.leadingEnd,
          ),
          textStyle: theme.type.of(metrics.textStyle),
          iconSize: metrics.iconSize,
          child: child,
        ),
      ),
    );
  }
}

/// A split button's trailing half (`SplitButtonDefaults.TrailingButton`
/// and its styles): [child] centred optically between the size's trailing
/// padding, the start corners tightening on press. With [checked] set it
/// is a toggle: checked, it becomes a circle under a veil of its content
/// colour at the pressed opacity.
class ExpressiveSplitTrailingButton extends StatefulWidget {
  /// A trailing button showing [child] that runs [onPressed].
  const ExpressiveSplitTrailingButton({
    required this.onPressed,
    required this.child,
    this.checked,
    this.kind = ExpressiveSplitButtonKind.filled,
    this.style,
    this.size = ExpressiveSplitButtonSize.small,
    this.semanticLabel,
    this.focusNode,
    super.key,
  });

  /// What a tap does (a toggle: flip [checked]); null disables the half.
  final VoidCallback? onPressed;

  /// The content: the chevron, usually.
  final Widget child;

  /// Whether the half is checked (its menu open); null for a plain button.
  final bool? checked;

  /// The kind.
  final ExpressiveSplitButtonKind kind;

  /// Stateful visual overrides for this half or both halves.
  final ExpressiveComponentThemeData? style;

  /// The size.
  final ExpressiveSplitButtonSize size;

  /// What a screen reader says.
  final String? semanticLabel;

  /// The focus node; one is made when null.
  final FocusNode? focusNode;

  @override
  State<ExpressiveSplitTrailingButton> createState() =>
      _ExpressiveSplitTrailingButtonState();
}

class _ExpressiveSplitTrailingButtonState
    extends State<ExpressiveSplitTrailingButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final metrics = _SplitMetrics.of(widget.size);
    final enabled = widget.onPressed != null;
    final checked = widget.checked ?? false;
    final paint = _splitPaint(theme.colors, widget.kind, enabled: enabled);
    final shapes = _trailingShapes(theme.shapes, metrics);
    final content = ExpressiveStyledContent(
      minimumSize: Size(
        SplitButtonBehavior.leadingButtonMinWidth,
        metrics.minHeight,
      ),
      iconSize: metrics.trailingIconSize,
      textStyle: theme.type.of(metrics.textStyle),
      padding: _snappedPadding(
        context,
        metrics.trailingStart,
        metrics.trailingEnd,
      ),
      child: widget.child,
    );
    return ExpressivePressable(
      style: widget.style,
      componentStyle: theme.splitButtonTheme,
      shapes: shapes,
      motion: SplitButtonBehavior.pressMotion,
      color: paint.container,
      contentColor: paint.content,
      side: paint.side,
      elevation: paint.elevation,
      selected: checked,
      role: widget.checked == null
          ? ExpressivePressRole.button
          : ExpressivePressRole.toggle,
      onPressed: widget.onPressed,
      onPressedChanged: (pressed) => setState(() => _pressed = pressed),
      semanticLabel: widget.semanticLabel,
      focusNode: widget.focusNode,
      child: Stack(
        children: <Widget>[
          ConstrainedBox(
            // The height density gives the content (StyledContent's rule), so
            // the halves stand at one height at every density: a fixed 40
            // here stretched a compact leading half past its 32dp content.
            // The width stays the half's own: its target keeps 48dp.
            constraints: BoxConstraints(
              minWidth: SplitButtonBehavior.leadingButtonMinWidth,
              minHeight: theme.density.height(metrics.minHeight, floor: 0),
            ),
            // The pressable springs its shape on the same key to the same
            // target, so this spring tracks the drawn corners exactly.
            child: ExpressiveSpringShape(
              value: shapes.resolve(pressed: _pressed, selected: checked),
              motion: SplitButtonBehavior.pressMotion,
              child: content,
              builder: (context, shape, child) => _OpticalCenter(
                shape:
                    ExpressiveStyleScope.maybeOf(context)!.style.shape?.resolve(
                      ExpressiveStyleScope.maybeOf(context)!.states,
                    ) ??
                    shape,
                maxStart: metrics.trailingStart,
                maxEnd: metrics.trailingEnd,
                devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                textDirection: Directionality.of(context),
                child: child,
              ),
            ),
          ),
          if (checked)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: paint.content.withValues(
                    alpha: theme.states.pressedOpacity,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compose's `Modifier.horizontalCenterOptically`: [child] shifted toward
/// its rounder side by `SplitButtonBehavior.centerOpticallyCoefficient` of
/// the difference between its start and end corner radii, clamped to
/// [maxStart] toward the start and [maxEnd] toward the end, on the pixel
/// grid.
class _OpticalCenter extends SingleChildRenderObjectWidget {
  const _OpticalCenter({
    required this.shape,
    required this.maxStart,
    required this.maxEnd,
    required this.devicePixelRatio,
    required this.textDirection,
    super.child,
  });

  final ShapeBorder shape;
  final double maxStart;
  final double maxEnd;
  final double devicePixelRatio;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderOpticalCenter(
    shape,
    maxStart,
    maxEnd,
    devicePixelRatio,
    textDirection,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderOpticalCenter renderObject,
  ) {
    renderObject
      ..shape = shape
      ..maxStart = maxStart
      ..maxEnd = maxEnd
      ..devicePixelRatio = devicePixelRatio
      ..textDirection = textDirection;
  }
}

class _RenderOpticalCenter extends RenderProxyBox {
  _RenderOpticalCenter(
    this._shape,
    this._maxStart,
    this._maxEnd,
    this._devicePixelRatio,
    this._textDirection,
  );

  ShapeBorder _shape;
  set shape(ShapeBorder value) {
    if (value == _shape) return;
    _shape = value;
    markNeedsPaint();
  }

  double _maxStart;
  set maxStart(double value) {
    if (value == _maxStart) return;
    _maxStart = value;
    markNeedsPaint();
  }

  double _maxEnd;
  set maxEnd(double value) {
    if (value == _maxEnd) return;
    _maxEnd = value;
    markNeedsPaint();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsPaint();
  }

  /// The shift, in logical pixels, positive toward the end.
  double get _shift {
    final shape = _shape;
    if (shape is! ExpressiveCornerBorder) return 0;
    // Resolved left-to-right, left is start.
    final radii = shape.radiiOn(Offset.zero & size);
    final start = (radii.topLeft.x + radii.bottomLeft.x) / 2;
    final end = (radii.topRight.x + radii.bottomRight.x) / 2;
    final correction =
        (SplitButtonBehavior.centerOpticallyCoefficient * (start - end)).clamp(
          -_maxStart,
          _maxEnd,
        );
    return (correction * _devicePixelRatio).roundToDouble() / _devicePixelRatio;
  }

  Offset get _offset {
    final shift = _shift;
    return Offset(_textDirection == TextDirection.rtl ? -shift : shift, 0);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null) context.paintChild(child, offset + _offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: _offset,
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final offset = _offset;
    transform.translateByDouble(offset.dx, offset.dy, 0, 1);
  }
}

/// A split button: a labelled leading action and a trailing chevron that
/// opens [menu] under the pair (Compose's `SplitButtonLayout` with a
/// `LeadingButton` and a checkable `TrailingButton`, as its samples compose
/// them).
///
/// The menu's open state is [menuOpen] when the caller holds it (told
/// through [onMenuOpenChanged]), else the button's own. A tap outside the
/// menu, Escape, or the system back closes it; while it is open the back
/// is the menu's, never the page's ([ExpressiveBackHandle]: a
/// `DropdownMenu`'s focusable popup takes the back in Compose).
class ExpressiveSplitButton extends StatefulWidget {
  /// A split button labelled [label] that runs [onPressed].
  const ExpressiveSplitButton(
    this.label, {
    required this.onPressed,
    this.icon,
    this.kind = ExpressiveSplitButtonKind.filled,
    this.style,
    this.size = ExpressiveSplitButtonSize.small,
    this.menu,
    this.menuOpen,
    this.onMenuOpenChanged,
    this.menuLabel,
    this.trailingIcon = ExpressiveSymbols.keyboardArrowDown,
    super.key,
  });

  /// The leading button's label.
  final String label;

  /// The leading button's action.
  final VoidCallback? onPressed;

  /// The leading button's icon, before the label.
  final IconData? icon;

  /// The kind of both halves.
  final ExpressiveSplitButtonKind kind;

  /// Stateful visual overrides for this half or both halves.
  final ExpressiveComponentThemeData? style;

  /// The size of both halves.
  final ExpressiveSplitButtonSize size;

  /// The menu shown under the pair while it is open, handed a callback that
  /// closes it: an `ExpressiveMenu`, usually.
  final Widget Function(BuildContext context, VoidCallback close)? menu;

  /// Whether the menu is open, when the caller holds that state.
  final bool? menuOpen;

  /// Told when the trailing button opens or closes the menu.
  final ValueChanged<bool>? onMenuOpenChanged;

  /// What a screen reader says for the trailing button.
  final String? menuLabel;

  /// The trailing glyph: the chevron, turning a half turn when open.
  final IconData trailingIcon;

  /// Whether it takes input: false when onPressed is null, as in Flutter.
  bool get enabled => onPressed != null;

  /// The leading icon's size at [size] (`ButtonDefaults.iconSizeFor`).
  static double iconSizeOf(ExpressiveSplitButtonSize size) =>
      _SplitMetrics.of(size).iconSize;

  /// The trailing chevron's size at [size]
  /// (`SplitButtonDefaults.trailingButtonIconSizeFor`).
  static double trailingIconSizeOf(ExpressiveSplitButtonSize size) =>
      _SplitMetrics.of(size).trailingIconSize;

  /// The leading half's resting shape at [size]
  /// (`leadingButtonShapesFor(height).shape`), resolved from [shapes].
  static ShapeBorder leadingShapeOf(
    ExpressiveShapes shapes,
    ExpressiveSplitButtonSize size,
  ) => _leadingShapes(shapes, _SplitMetrics.of(size)).shape;

  /// The trailing half's shape at [size], resting or [checked] (the
  /// circle), resolved from [shapes] (`trailingButtonShapesFor(height)`).
  static ShapeBorder trailingShapeOf(
    ExpressiveShapes shapes,
    ExpressiveSplitButtonSize size, {
    bool checked = false,
  }) => _trailingShapes(
    shapes,
    _SplitMetrics.of(size),
  ).resolve(pressed: false, selected: checked);

  @override
  State<ExpressiveSplitButton> createState() => _ExpressiveSplitButtonState();
}

class _ExpressiveSplitButtonState extends State<ExpressiveSplitButton> {
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _pairKey = GlobalKey(debugLabel: 'ExpressiveSplitButton');
  late final ExpressiveBackHandle _back = ExpressiveBackHandle(onBack: _close);
  bool _ownOpen = false;
  bool _placeScheduled = false;

  bool get _open => widget.menuOpen ?? _ownOpen;

  @override
  void initState() {
    super.initState();
    // Always shown: the overlay child is empty while the menu is closed,
    // so opening and closing is a rebuild, never a portal toggle mid-build.
    _portal.show();
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _set(bool open) {
    if (open == _open) return;
    // Closing lets the back go at once, so a pop right after reaches the
    // page; the rebuild holds it again if a caller keeps the menu open.
    if (!open) _back.release();
    setState(() {
      if (widget.menuOpen == null) _ownOpen = open;
    });
    widget.onMenuOpenChanged?.call(open);
  }

  void _close() => _set(false);

  /// The pair's rect in [overlay]'s coordinates, or null before it is laid
  /// out (a menu held open from the first frame): then the overlay builds
  /// again after this frame, once it is.
  Rect? _anchorIn(BuildContext overlay) {
    final pair = _pairKey.currentContext?.findRenderObject();
    final theater = Overlay.maybeOf(overlay)?.context.findRenderObject();
    if (pair is RenderBox &&
        pair.hasSize &&
        pair.attached &&
        theater is RenderBox &&
        theater.hasSize) {
      return pair.localToGlobal(Offset.zero, ancestor: theater) & pair.size;
    }
    if (!_placeScheduled) {
      _placeScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _placeScheduled = false;
        if (mounted) setState(() {});
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.size.isHero) {
      assert(
        ExpressiveHeroMoment.debugCheck(
          context,
          'ExpressiveSplitButton (${widget.size.name.toUpperCase()})',
        ),
      );
    }
    final metrics = _SplitMetrics.of(widget.size);
    final open = _open && widget.enabled;
    _back.sync(context, open: open && widget.menu != null);
    final leadingContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.icon != null) ...<Widget>[
          ExpressiveIcon(widget.icon!),
          SizedBox(width: metrics.iconSpacing),
        ],
        Flexible(
          child: expressiveFaceLabel(
            Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
    final pair = ExpressiveSplitButtonLayout(
      size: widget.size,
      leading: ExpressiveSplitLeadingButton(
        onPressed: widget.onPressed,
        kind: widget.kind,
        style: widget.style,
        size: widget.size,
        child: leadingContent,
      ),
      trailing: ExpressiveSplitTrailingButton(
        onPressed: widget.enabled ? () => _set(!open) : null,
        checked: open,
        kind: widget.kind,
        style: widget.style,
        size: widget.size,
        semanticLabel:
            widget.menuLabel ?? ExpressiveLocalizations.of(context).moreOptions,
        child: ExpressiveSpringValue(
          // A half turn when open: the samples' rotating chevron.
          value: open ? 0.5 : 0,
          motion: ExpressiveMotionKey.defaultSpatial,
          builder: (context, turns, child) => RotationTransition(
            turns: AlwaysStoppedAnimation(turns),
            child: child,
          ),
          child: ExpressiveIcon(widget.trailingIcon),
        ),
      ),
    );
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        final menu = widget.menu;
        if (!open || menu == null) return const SizedBox.shrink();
        final anchor = _anchorIn(context);
        if (anchor == null) return const SizedBox.shrink();
        return _MenuLayer(
          anchor: anchor,
          onDismiss: _close,
          child: menu(context, _close),
        );
      },
      child: KeyedSubtree(key: _pairKey, child: pair),
    );
  }
}

/// The open menu: a dismissing barrier over the screen and [child] placed
/// against the pair as Compose's `DropdownMenuPositionProvider` places a
/// menu: under the pair with its end edge on the pair's end, else with its
/// start on the pair's start, else against the window edge on the pair's
/// side; above the pair when it does not fit below. Always inside the
/// window by `MenuBehavior`'s margins, so a split button at the page's start
/// never pushes its menu off the edge.
class _MenuLayer extends StatelessWidget {
  const _MenuLayer({
    required this.anchor,
    required this.onDismiss,
    required this.child,
  });

  /// The pair, in the overlay's coordinates.
  final Rect anchor;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onDismiss,
          excludeFromSemantics: true,
        ),
      ),
      Positioned.fill(
        child: CustomSingleChildLayout(
          delegate: _MenuPlacement(anchor, Directionality.of(context)),
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.escape): onDismiss,
            },
            child: FocusScope(autofocus: true, child: child),
          ),
        ),
      ),
    ],
  );
}

class _MenuPlacement extends SingleChildLayoutDelegate {
  const _MenuPlacement(this.anchor, this.textDirection);

  final Rect anchor;
  final TextDirection textDirection;

  static const _h = MenuBehavior.horizontalMargin;
  static const _v = MenuBehavior.verticalMargin;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.max(constraints.maxWidth - _h - _h, 0),
        maxHeight: math.max(constraints.maxHeight - _v - _v, 0),
      );

  @override
  Offset getPositionForChild(Size size, Size menu) {
    final a = anchor;
    final ltr = textDirection == TextDirection.ltr;
    final endToEnd = ltr ? a.right - menu.width : a.left;
    final startToStart = ltr ? a.left : a.right - menu.width;
    final windowX = a.center.dx < size.width / 2
        ? 0.0
        : size.width - menu.width;
    final windowY = a.center.dy < size.height / 2
        ? 0.0
        : size.height - menu.height;
    return Offset(
      _pick(
        <double>[endToEnd, startToStart, windowX],
        menu.width,
        size.width,
        _h,
      ),
      _pick(
        <double>[a.bottom, a.top - menu.height, windowY],
        menu.height,
        size.height,
        _v,
      ),
    );
  }

  /// `DropdownMenuPositionProvider.positioningLogic` on one axis: the first
  /// candidate inside the margins, else the last one clamped into them (or
  /// centred when the menu does not fit between them).
  static double _pick(
    List<double> candidates,
    double extent,
    double space,
    double margin,
  ) {
    for (final candidate in candidates) {
      if (candidate >= margin && candidate + extent <= space - margin) {
        return candidate;
      }
    }
    if (extent >= space - 2 * margin) return (space - extent) / 2;
    return math.min(math.max(candidates.last, margin), space - margin - extent);
  }

  @override
  bool shouldRelayout(_MenuPlacement old) =>
      anchor != old.anchor || textDirection != old.textDirection;
}

/// One half's node, as tall as the layout's touch target: Compose extends
/// each half's touch bounds to `minimumTouchTargetSize` (48dp) though it
/// draws at the size's height, and assistive technology reads those
/// bounds. The half's own node merges into this one.
class _HalfTarget extends SingleChildRenderObjectWidget {
  const _HalfTarget({required this.touchHeight, required super.child});

  /// The layout's touch target height; 0 where targets are shrunk.
  final double touchHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHalfTarget(touchHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderHalfTarget renderObject,
  ) => renderObject.touchHeight = touchHeight;
}

class _RenderHalfTarget extends RenderProxyBox {
  _RenderHalfTarget(this._touchHeight);

  double _touchHeight;

  set touchHeight(double value) {
    if (value == _touchHeight) return;
    _touchHeight = value;
    markNeedsSemanticsUpdate();
  }

  @override
  Rect get semanticBounds {
    final grow = math.max(0.0, (_touchHeight - size.height) / 2);
    return Rect.fromLTRB(0, -grow, size.width, size.height + grow);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }
}
