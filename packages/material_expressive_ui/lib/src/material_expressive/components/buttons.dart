/// Buttons: the common buttons — filled, tonal, outlined, elevated and text;
/// XS–XL; round or square; toggle — that change shape on press; standard and
/// connected button groups, the connected group standing in for segmented
/// buttons; and the inline text link (CONTRACT §4.1 `button`, `button-group`,
/// `segmented-control`, `link`; §4.2 `ExpressiveButton`). Owner: w3-buttons,
/// with `test/buttons_test.dart` and the gallery's buttons demo.
///
/// A port of Compose material3 1.5.0-alpha29 (wave decision F1):
///
/// - [ExpressiveButton]'s five are `Button`, `FilledTonalButton`, `OutlinedButton`,
///   `ElevatedButton` and `TextButton` with `ButtonDefaults`' size ladder
///   (`contentPaddingFor`, `iconSizeFor`, `iconSpacingFor`, `textStyleFor`,
///   `shapesFor`): XS 32, S 40, M 56, L 96, XL 136dp. The shape springs to
///   the size's pressed shape on `ButtonBehavior.pressMotion` (an effects
///   spring: the press never bounces). Flutter's classes hold the five:
///   [ExpressiveFilledButton] (and its `.tonal`), [ExpressiveOutlinedButton],
///   [ExpressiveElevatedButton] and [ExpressiveTextButton].
/// - [ExpressiveToggleButton] is `ToggleButton`, `ElevatedToggleButton`,
///   `FilledTonalToggleButton` and `OutlinedToggleButton`: checked colours,
///   and the round button checking to the size's square shape (a square one
///   to the round), on `ToggleButtonBehavior.shapeMotion`.
/// - [ExpressiveButtonGroup] is `ButtonGroup`'s measure policy: the pressed
///   button widens by `ButtonGroupBehavior.expandedRatio` of its width and
///   its neighbours give way, on `ButtonGroupBehavior.motion`.
/// - [ExpressiveSegmentedButton] is the connected button group: a
///   `ButtonGroup` of toggle buttons with `ButtonGroupDefaults.connected*`
///   shapes — full outer corners, small inner corners that tighten on press
///   and round out when checked.
/// - [ExpressiveLink] is a link inside running text.
///
/// L and XL buttons are hero widgets (CONTRACT §3): they assert an
/// [ExpressiveHeroMoment] above them.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../color.dart';
import '../component_themes.dart';
import '../elevation.dart';
import '../icons.dart';
import '../internal/cap_label.dart';
import '../internal/choice_width.dart';
import '../internal/state_face.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/button_group_large_tokens.g.dart';
import '../internal/tokens/button_group_medium_tokens.g.dart';
import '../internal/tokens/button_group_small_tokens.g.dart';
import '../internal/tokens/button_group_x_large_tokens.g.dart';
import '../internal/tokens/button_group_x_small_tokens.g.dart';
import '../internal/tokens/button_large_tokens.g.dart';
import '../internal/tokens/button_medium_tokens.g.dart';
import '../internal/tokens/button_small_tokens.g.dart';
import '../internal/tokens/button_x_large_tokens.g.dart';
import '../internal/tokens/button_x_small_tokens.g.dart';
import '../internal/tokens/connected_button_group_large_tokens.g.dart';
import '../internal/tokens/connected_button_group_medium_tokens.g.dart';
import '../internal/tokens/connected_button_group_small_tokens.g.dart';
import '../internal/tokens/connected_button_group_x_large_tokens.g.dart';
import '../internal/tokens/connected_button_group_x_small_tokens.g.dart';
import '../internal/tokens/elevated_button_tokens.g.dart';
import '../internal/tokens/filled_button_tokens.g.dart';
import '../internal/tokens/filled_tonal_button_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/outlined_button_tokens.g.dart';
import '../internal/tokens/text_button_tokens.g.dart';
import '../internal/tokens/tonal_button_tokens.g.dart';
import '../internal/width_probe.dart';
import '../motion.dart';
import '../shape.dart';
import '../spacing.dart';
import '../states.dart';
import '../strings.dart';
import '../theme.dart';
import 'hero.dart';
import 'loading.dart';

/// Material's five common-button styles.
enum ExpressiveButtonKind {
  /// The highest emphasis: `primary` (Compose `Button`).
  filled,

  /// Secondary emphasis: `secondaryContainer` (`FilledTonalButton`).
  tonal,

  /// Medium emphasis: an outline, no fill (`OutlinedButton`).
  outlined,

  /// A tonal surface with a shadow (`ElevatedButton`).
  elevated,

  /// The lowest emphasis: a label in `primary` (`TextButton`).
  text,
}

/// Material's five button sizes, by container height. [large] and
/// [extraLarge] are hero sizes (CONTRACT §3).
enum ExpressiveButtonSize {
  /// 32dp (`ButtonDefaults.ExtraSmallContainerHeight`).
  extraSmall,

  /// 40dp, the default (`ButtonDefaults.MinHeight`).
  small,

  /// 56dp (`ButtonDefaults.MediumContainerHeight`).
  medium,

  /// 96dp, a hero (`ButtonDefaults.LargeContainerHeight`).
  large,

  /// 136dp, a hero (`ButtonDefaults.ExtraLargeContainerHeight`).
  extraLarge;

  /// The container height, in dp.
  double get height => _ButtonMetrics.of(this).height;

  /// Whether the size is a hero moment (L, XL): it asserts an
  /// [ExpressiveHeroMoment] above it.
  bool get isHero => this == large || this == extraLarge;
}

/// A button's shape family at rest.
enum ExpressiveButtonShape {
  /// Fully round corners (the default).
  round,

  /// The size's square corner (12dp at XS/S, 16 at M, 28 at L/XL).
  square,
}

/// The toggle buttons' styles (Compose has no text toggle button).
enum ExpressiveToggleButtonKind {
  /// `ToggleButton`: `surfaceContainer`, checked `primary`.
  filled,

  /// `ElevatedToggleButton`: `surfaceContainerLow` with a shadow, checked
  /// `primary`.
  elevated,

  /// `FilledTonalToggleButton`: `secondaryContainer`, checked `secondary`.
  tonal,

  /// `OutlinedToggleButton`: an outline, checked `inverseSurface`.
  outlined,
}

/// A toggle button's colours in place of its style's (Compose's
/// `ToggleButtonDefaults.toggleButtonColors(...)`): each one left null
/// keeps the style's. Disabled colours are always the style's.
@immutable
class ExpressiveToggleButtonColors {
  /// Colours for a toggle button, each left null keeping the style's own.
  const ExpressiveToggleButtonColors({
    this.container,
    this.content,
    this.checkedContainer,
    this.checkedContent,
  });

  /// The container while unchecked.
  final Color? container;

  /// The label and icon while unchecked.
  final Color? content;

  /// The container while checked.
  final Color? checkedContainer;

  /// The label and icon while checked.
  final Color? checkedContent;
}

/// A common button (CONTRACT §4.1 `button`): a label, optionally with a
/// leading and a trailing icon, in one of Material's five styles and five
/// sizes, round or square, that changes shape on press. The five are
/// Flutter's classes, which share this base as Flutter's share
/// `ButtonStyleButton`: [ExpressiveFilledButton] (and
/// [ExpressiveFilledButton.tonal]), [ExpressiveOutlinedButton],
/// [ExpressiveElevatedButton] and [ExpressiveTextButton]. Disabled when
/// [onPressed] is null.
///
/// ```dart
/// ExpressiveFilledButton('Save', onPressed: save);
/// ExpressiveFilledButton.tonal(
///   'Share',
///   size: ExpressiveButtonSize.large,
///   onPressed: share,
/// );
/// ```
abstract class ExpressiveButton extends StatelessWidget {
  const ExpressiveButton._(
    this.label, {
    required this.kind,
    this.onPressed,
    this.style,
    this.busy = false,
    this.size = ExpressiveButtonSize.small,
    this.shape = ExpressiveButtonShape.round,
    this.icon,
    this.leading,
    this.trailingIcon,
    this.child,
    this.expand = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(
         icon == null || leading == null,
         'a button leads with an icon or a leading widget, not both',
       );

  /// The Material style the button paints.
  final ExpressiveButtonKind kind;

  /// The label: an action's meaning, wrapping to two lines before it
  /// ellipsizes.
  final String label;

  /// What a tap does; the button is disabled when null.
  final VoidCallback? onPressed;

  /// Waiting on its own action: the label gives way to a loading indicator
  /// in the label's colour, the button keeps its size and its colours, and a
  /// press does nothing. It keeps its focus, and a screen reader hears its
  /// label and that it is loading. (Compose has no busy button; M3
  /// Expressive's loading indicator is its wait under five seconds.)
  final bool busy;

  /// Stateful visual overrides before the component theme.
  final ExpressiveComponentThemeData? style;

  /// The size: its height, padding, icon, type and pressed shape.
  final ExpressiveButtonSize size;

  /// Round or square at rest.
  final ExpressiveButtonShape shape;

  /// A leading icon (one of `ExpressiveSymbols`).
  final IconData? icon;

  /// A widget before the label, for the one thing an icon cannot say.
  final Widget? leading;

  /// A trailing icon.
  final IconData? trailingIcon;

  /// The label as a widget, in place of [label]'s text (Compose's content
  /// slot): it inherits the size's text style and the content colour.
  /// [label] stays the button's name for assistive technology.
  final Widget? child;

  /// Fill the available width (a sticky bottom action).
  final bool expand;

  /// What a screen reader says instead of [label].
  final String? semanticLabel;

  /// The focus node; one is made when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    if (size.isHero) {
      assert(
        ExpressiveHeroMoment.debugCheck(context, '$runtimeType (${size.name})'),
      );
    }
    final theme = context.expressiveTheme;
    final enabled = onPressed != null;
    // Every style takes its size's padding: Expressive's button is Compose's
    // `shapes` overload (it morphs on press), whose default content padding
    // is `ButtonDefaults.contentPaddingFor(MinHeight)` for the text button
    // too — not the shape-less `TextButton`'s `TextButtonContentPadding`.
    final metrics = _ButtonMetrics.of(size);
    final paint = _buttonPaint(theme.colors, kind, enabled: enabled || busy)
        .themed(
          theme.buttonTheme,
          expressiveComponentStates(enabled: enabled || busy),
        );
    final rest = switch (shape) {
      ExpressiveButtonShape.round => metrics.roundShape,
      ExpressiveButtonShape.square => metrics.squareShape,
    };
    final button = ExpressivePressable(
      style: style,
      componentStyle: theme.buttonTheme,
      shapes: ExpressivePressShapes(
        shape: theme.shapes.of(rest),
        pressed: theme.shapes.of(metrics.pressedShape),
      ),
      motion: ButtonBehavior.pressMotion,
      color: paint.container,
      contentColor: paint.content,
      side: paint.side,
      elevation: paint.elevation,
      onPressed: onPressed,
      busy: busy,
      onPressedChanged: ExpressiveButtonGroup.pressedHandlerOf(context),
      semanticLabel: busy
          ? '${semanticLabel ?? label}, '
                '${ExpressiveLocalizations.of(context).loading}'
          : semanticLabel,
      focusNode: focusNode,
      autofocus: autofocus,
      // A [semanticLabel] is said instead of the visible words, not as well.
      child: ExcludeSemantics(
        excluding: semanticLabel != null,
        child: _busy(
          busy,
          metrics.iconSize,
          paint.content,
          _ButtonContent(
            metrics: metrics,
            minWidth: ButtonBehavior.minWidth,
            expand: expand,
            textStyle: theme.type
                .of(metrics.textStyle)
                .copyWith(color: paint.content),
            label: label,
            content: child,
            leading: icon != null ? ExpressiveIcon(icon!) : leading,
            trailing: trailingIcon == null
                ? null
                : ExpressiveIcon(trailingIcon!),
          ),
        ),
      ),
    );
    // Expanded, it fills a phone's column; from [ExpressiveSelect.wideFrom]
    // it keeps to a control's width at its column's start.
    return expand ? expressiveChoiceWidth(context, button) : button;
  }
}

/// Material's filled button (Compose `Button`, Flutter's `FilledButton`):
/// the highest emphasis, in `primary`; [ExpressiveFilledButton.tonal] is
/// the tonal button in `secondaryContainer`.
class ExpressiveFilledButton extends ExpressiveButton {
  /// A filled button.
  const ExpressiveFilledButton(
    super.label, {
    super.onPressed,
    super.style,
    super.busy = false,
    super.size = ExpressiveButtonSize.small,
    super.shape = ExpressiveButtonShape.round,
    super.icon,
    super.leading,
    super.trailingIcon,
    super.child,
    super.expand = false,
    super.semanticLabel,
    super.focusNode,
    super.autofocus = false,
    super.key,
  }) : super._(kind: ExpressiveButtonKind.filled);

  /// A tonal button (Compose `FilledTonalButton`, Flutter's
  /// `FilledButton.tonal`).
  const ExpressiveFilledButton.tonal(
    super.label, {
    super.onPressed,
    super.style,
    super.busy = false,
    super.size = ExpressiveButtonSize.small,
    super.shape = ExpressiveButtonShape.round,
    super.icon,
    super.leading,
    super.trailingIcon,
    super.child,
    super.expand = false,
    super.semanticLabel,
    super.focusNode,
    super.autofocus = false,
    super.key,
  }) : super._(kind: ExpressiveButtonKind.tonal);

  /// A [style] that paints the button [backgroundColor] under
  /// [foregroundColor] while it is enabled, as `FilledButton.styleFrom`
  /// does; disabled, it keeps Material's disabled colours. A destructive
  /// act's button, say, in the scheme's `error` and `onError`:
  ///
  /// ```dart
  /// final c = context.expressiveTheme.colors;
  /// ExpressiveFilledButton(
  ///   'Delete',
  ///   style: ExpressiveFilledButton.styleFrom(
  ///     backgroundColor: c.error,
  ///     foregroundColor: c.onError,
  ///   ),
  ///   onPressed: delete,
  /// );
  /// ```
  static ExpressiveComponentThemeData styleFrom({
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    WidgetStateProperty<Color?>? enabled(Color? color) => color == null
        ? null
        : WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? null : color,
          );
    return ExpressiveComponentThemeData(
      backgroundColor: enabled(backgroundColor),
      foregroundColor: enabled(foregroundColor),
    );
  }
}

/// Material's outlined button (`OutlinedButton`): medium emphasis, an
/// outline and no fill.
class ExpressiveOutlinedButton extends ExpressiveButton {
  /// An outlined button.
  const ExpressiveOutlinedButton(
    super.label, {
    super.onPressed,
    super.style,
    super.busy = false,
    super.size = ExpressiveButtonSize.small,
    super.shape = ExpressiveButtonShape.round,
    super.icon,
    super.leading,
    super.trailingIcon,
    super.child,
    super.expand = false,
    super.semanticLabel,
    super.focusNode,
    super.autofocus = false,
    super.key,
  }) : super._(kind: ExpressiveButtonKind.outlined);
}

/// Material's elevated button (`ElevatedButton`): a tonal surface with a
/// shadow, for a button that must stand off a patterned background.
class ExpressiveElevatedButton extends ExpressiveButton {
  /// An elevated button.
  const ExpressiveElevatedButton(
    super.label, {
    super.onPressed,
    super.style,
    super.busy = false,
    super.size = ExpressiveButtonSize.small,
    super.shape = ExpressiveButtonShape.round,
    super.icon,
    super.leading,
    super.trailingIcon,
    super.child,
    super.expand = false,
    super.semanticLabel,
    super.focusNode,
    super.autofocus = false,
    super.key,
  }) : super._(kind: ExpressiveButtonKind.elevated);
}

/// Material's text button (`TextButton`): the lowest emphasis, a label in
/// `primary` on no container, at its size's padding.
class ExpressiveTextButton extends ExpressiveButton {
  /// A text button.
  const ExpressiveTextButton(
    super.label, {
    super.onPressed,
    super.style,
    super.busy = false,
    super.size = ExpressiveButtonSize.small,
    super.shape = ExpressiveButtonShape.round,
    super.icon,
    super.leading,
    super.trailingIcon,
    super.child,
    super.expand = false,
    super.semanticLabel,
    super.focusNode,
    super.autofocus = false,
    super.key,
  }) : super._(kind: ExpressiveButtonKind.text);
}

/// [content] as it is, or — [busy] — held at its size, unseen, under a
/// loading indicator [dimension] across in [color].
Widget _busy(bool busy, double dimension, Color color, Widget content) => !busy
    ? content
    : Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Visibility.maintain(visible: false, child: content),
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: dimension,
              child: FittedBox(child: ExpressiveLoadingIndicator(color: color)),
            ),
          ),
        ],
      );

/// A toggle button (Compose `ToggleButton` and its elevated, tonal and
/// outlined forms): a button that is on or off. Checked, it takes the
/// checked colours and its shape morphs — round to the size's square,
/// square to round — on `ToggleButtonBehavior.shapeMotion`.
///
/// Disabled when [onChanged] is null.
class ExpressiveToggleButton extends StatelessWidget {
  /// A toggle button labelled [label], on when [value].
  const ExpressiveToggleButton({
    required this.value,
    required this.onChanged,
    required this.label,
    this.kind = ExpressiveToggleButtonKind.filled,
    this.style,
    this.size = ExpressiveButtonSize.small,
    this.shape = ExpressiveButtonShape.round,
    this.icon,
    this.child,
    this.colors,
    this.shapes,
    this.expand = false,
    this.semanticLabel,
    this.focusNode,
    super.key,
  }) : _role = ExpressivePressRole.toggle,
       _inSegments = false;

  const ExpressiveToggleButton._segment({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.kind,
    required this.style,
    required this.size,
    required this.icon,
    required this.shapes,
    required this._role,
  }) : shape = ExpressiveButtonShape.round,
       child = null,
       colors = null,
       expand = false,
       semanticLabel = null,
       focusNode = null,
       _inSegments = true;

  /// Whether the button is on.
  final bool value;

  /// Told the new state on a tap; the button is disabled when null.
  final ValueChanged<bool>? onChanged;

  /// The label.
  final String label;

  /// The kind.
  final ExpressiveToggleButtonKind kind;

  /// Stateful visual overrides before the component theme.
  final ExpressiveComponentThemeData? style;

  /// The size.
  final ExpressiveButtonSize size;

  /// Round or square at rest; it checks to the other.
  final ExpressiveButtonShape shape;

  /// A leading icon, drawn filled while checked.
  final IconData? icon;

  /// The label as a widget, in place of [label]'s text (Compose's content
  /// slot; a player's play/pause glyph): it inherits the size's text kind,
  /// icon size and the content colour. [label] stays the button's name for
  /// assistive technology.
  final Widget? child;

  /// Colours in place of the kind's (Compose's `colors`).
  final ExpressiveToggleButtonColors? colors;

  /// Shapes in place of the size's (a connected group's position shapes).
  final ExpressivePressShapes? shapes;

  /// Fill the available width.
  final bool expand;

  /// What a screen reader says instead of [label].
  final String? semanticLabel;

  /// The focus node; one is made when null.
  final FocusNode? focusNode;

  final ExpressivePressRole _role;

  /// A segment of a segmented button: themed by
  /// [ExpressiveThemeData.segmentedButtonTheme], not the button theme.
  final bool _inSegments;

  @override
  Widget build(BuildContext context) {
    if (size.isHero) {
      assert(
        ExpressiveHeroMoment.debugCheck(
          context,
          'ExpressiveToggleButton (${size.name.toUpperCase()})',
        ),
      );
    }
    final theme = context.expressiveTheme;
    final enabled = onChanged != null;
    final metrics = _ButtonMetrics.of(size);
    final styled =
        _togglePaint(
          theme.colors,
          kind,
          enabled: enabled,
          checked: value,
        ).themed(
          _inSegments ? theme.segmentedButtonTheme : theme.buttonTheme,
          expressiveComponentStates(enabled: enabled, selected: value),
        );
    final colors = this.colors;
    final paint = colors == null || !enabled
        ? styled
        : _Paint(
            container:
                (value ? colors.checkedContainer : colors.container) ??
                styled.container,
            content:
                (value ? colors.checkedContent : colors.content) ??
                styled.content,
            side: styled.side,
            elevation: styled.elevation,
          );
    final shapes =
        this.shapes ??
        ExpressivePressShapes(
          shape: theme.shapes.of(switch (shape) {
            ExpressiveButtonShape.round => metrics.roundShape,
            ExpressiveButtonShape.square => metrics.squareShape,
          }),
          pressed: metrics.togglePressedShape(theme.shapes),
          selected: theme.shapes.of(switch (shape) {
            ExpressiveButtonShape.round => metrics.checkedFromRound,
            ExpressiveButtonShape.square => metrics.checkedFromSquare,
          }),
        );
    final content = _ButtonContent(
      metrics: metrics,
      minWidth: 0,
      expand: expand,
      textStyle: theme.type
          .of(metrics.textStyle)
          .copyWith(color: paint.content),
      label: label,
      content: child,
      leading: icon == null ? null : ExpressiveIcon(icon!, selected: value),
    );
    final onPressed = enabled ? () => onChanged!(!value) : null;
    final groupHandler = ExpressiveButtonGroup.pressedHandlerOf(context);
    // The outline springs its width on a spatial spring and its colour on
    // an effects spring (ToggleButton.kt animateBorderStrokeAsState).
    final button = ExpressiveSpringValue(
      value: paint.side.width,
      motion: ToggleButtonBehavior.borderWidthMotion,
      builder: (context, width, _) => ExpressiveSpringColor(
        value: paint.side.color,
        motion: ToggleButtonBehavior.borderColorMotion,
        builder: (context, color, _) => ExpressivePressable(
          style: style,
          componentStyle:
              (_inSegments ? theme.segmentedButtonTheme : theme.buttonTheme)
                  .merge(
                    colors == null || !enabled
                        ? null
                        : ExpressiveComponentThemeData(
                            backgroundColor: WidgetStatePropertyAll(
                              value
                                  ? colors.checkedContainer
                                  : colors.container,
                            ),
                            foregroundColor: WidgetStatePropertyAll(
                              value ? colors.checkedContent : colors.content,
                            ),
                          ),
                  ),
          shapes: shapes,
          motion: ToggleButtonBehavior.shapeMotion,
          color: paint.container,
          contentColor: paint.content,
          side: width <= 0
              ? BorderSide.none
              : BorderSide(color: color, width: width),
          elevation: paint.elevation,
          selected: value,
          role: _role,
          onPressed: onPressed,
          onPressedChanged: groupHandler,
          semanticLabel: semanticLabel,
          focusNode: focusNode,
          // A segment stands 2dp from the next, which would paint over a
          // ring outside it: the ring stands inside, as the toggle group's.
          focusInward: _inSegments,
          // A segment's face is marked on the face itself (an unchosen
          // tonal one is faint on the page), not on its 48dp target.
          markFace: _inSegments,
          child: content,
        ),
      ),
    );
    // Expanded, it fills a phone's column; from [ExpressiveSelect.wideFrom]
    // it keeps to a control's width at its column's start.
    return expand ? expressiveChoiceWidth(context, button) : button;
  }
}

/// A standard button group (Compose `ButtonGroup`): related buttons in a
/// row, the size's gap apart. Pressing one widens it by [expandedRatio] of
/// its width and squeezes its neighbours (each by at most
/// `ButtonGroupBehavior.compressionLimit`) on the group's spatial spring; a
/// quick tap still plays the widening out to
/// `ButtonGroupBehavior.releaseThreshold` before it springs back.
///
/// Every Expressive button, toggle button, icon button and icon toggle
/// button in [children] joins the squish; another pressable joins by
/// passing [pressedHandlerOf] as its `onPressedChanged`.
class ExpressiveButtonGroup extends StatefulWidget {
  /// A button group of [children] in a row, sized by [size].
  const ExpressiveButtonGroup({
    required this.children,
    this.size = ExpressiveButtonSize.small,
    this.expand = false,
    this.weights,
    this.expandedRatio = ButtonGroupBehavior.expandedRatio,
    super.key,
  }) : _spacing = null,
       assert(weights == null || weights.length == children.length);

  const ExpressiveButtonGroup._connected({
    required this.children,
    required this.size,
    required this.expand,
    required double this._spacing,
  }) : weights = null,
       expandedRatio = ButtonGroupBehavior.expandedRatio;

  /// The buttons, start to end.
  final List<Widget> children;

  /// The size of the buttons in the group: the gap between them
  /// (`ButtonGroup*Tokens.BetweenSpace`).
  final ExpressiveButtonSize size;

  /// Share the available width equally between the buttons (Compose's
  /// `Modifier.weight(1f)` on each); otherwise each takes its own width.
  final bool expand;

  /// The buttons' shares of the width (`Modifier.weight`), 0 for a button
  /// that takes its own width; overrides [expand].
  final List<double>? weights;

  /// How much a pressed button widens, as a share of its width.
  final double expandedRatio;

  final double? _spacing;

  /// The press callback a pressable inside a group reports to (null outside
  /// one): pass it as `ExpressivePressable.onPressedChanged`.
  static ValueChanged<bool>? pressedHandlerOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_GroupSlot>()?.onPressedChanged;

  @override
  State<ExpressiveButtonGroup> createState() => _ExpressiveButtonGroupState();
}

class _ExpressiveButtonGroupState extends State<ExpressiveButtonGroup>
    with TickerProviderStateMixin {
  final List<AnimationController> _press = <AnimationController>[];
  final List<VoidCallback?> _pendingRelease = <VoidCallback?>[];

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ExpressiveButtonGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    while (_press.length < widget.children.length) {
      _press.add(AnimationController.unbounded(vsync: this));
      _pendingRelease.add(null);
    }
    while (_press.length > widget.children.length) {
      _press.removeLast().dispose();
      _pendingRelease.removeLast();
    }
  }

  /// Whether the group is in the tree: a member's press that is cancelled
  /// as the group leaves it (a pointer held down while the route is torn
  /// down) must not look the motion up from a deactivated context.
  bool _active = true;

  @override
  void activate() {
    super.activate();
    _active = true;
  }

  @override
  void deactivate() {
    _active = false;
    super.deactivate();
  }

  @override
  void dispose() {
    for (final controller in _press) {
      controller.dispose();
    }
    super.dispose();
  }

  /// EnlargeOnPressNode: a press springs the progress to 1; a release waits
  /// until the progress has passed the threshold, then springs it to 0.
  void _pressedChanged(int index, bool pressed) {
    if (!mounted || !_active || index >= _press.length) return;
    final controller = _press[index];
    final spring = ExpressiveMotion.of(context)
        .spring(ButtonGroupBehavior.motion);
    final pending = _pendingRelease[index];
    if (pending != null) {
      controller.removeListener(pending);
      _pendingRelease[index] = null;
    }
    if (pressed) {
      controller.springTo(1, spring);
      return;
    }
    if (controller.value > ButtonGroupBehavior.releaseThreshold ||
        !controller.isAnimating) {
      controller.springTo(0, spring);
      return;
    }
    void wait() {
      if (controller.value > ButtonGroupBehavior.releaseThreshold) {
        controller.removeListener(wait);
        _pendingRelease[index] = null;
        controller.springTo(0, spring);
      }
    }

    _pendingRelease[index] = wait;
    controller.addListener(wait);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.children.length;
    final weights =
        widget.weights ?? List<double>.filled(count, widget.expand ? 1 : 0);
    final group = _GroupLayout(
      spacing: widget._spacing ?? _groupSpacing(widget.size),
      weights: weights,
      progress: List<Animation<double>>.of(_press),
      expandedRatio: widget.expandedRatio,
      textDirection: Directionality.of(context),
      children: <Widget>[
        for (var i = 0; i < count; i++)
          _GroupSlot(
            onPressedChanged: (pressed) => _pressedChanged(i, pressed),
            child: widget.children[i],
          ),
      ],
    );
    // Expanded, it fills a phone's column; from [ExpressiveSelect.wideFrom]
    // it keeps to a control's width at its column's start.
    return widget.expand
        ? expressiveChoiceWidth(context, group, fitContent: true)
        : group;
  }
}

double _groupSpacing(ExpressiveButtonSize size) => switch (size) {
  ExpressiveButtonSize.extraSmall => ButtonGroupXSmallTokens.betweenSpace,
  ExpressiveButtonSize.small => ButtonGroupSmallTokens.betweenSpace,
  ExpressiveButtonSize.medium => ButtonGroupMediumTokens.betweenSpace,
  ExpressiveButtonSize.large => ButtonGroupLargeTokens.betweenSpace,
  ExpressiveButtonSize.extraLarge => ButtonGroupXLargeTokens.betweenSpace,
};

class _GroupSlot extends InheritedWidget {
  const _GroupSlot({required this.onPressedChanged, required super.child});

  final ValueChanged<bool> onPressedChanged;

  @override
  bool updateShouldNotify(_GroupSlot oldWidget) => false;
}

/// One option of an [ExpressiveSegmentedButton] (Material's `ButtonSegment`).
@immutable
class ExpressiveButtonSegment<T> {
  /// A segment standing for [value], labelled [label].
  const ExpressiveButtonSegment(
    this.value,
    this.label, {
    this.icon,
    this.enabled = true,
  });

  /// What choosing the segment selects.
  final T value;

  /// The segment's label.
  final String label;

  /// A leading icon, drawn filled while selected.
  final IconData? icon;

  /// Whether the segment can be chosen.
  final bool enabled;
}

/// The segmented button (CONTRACT §4.1 `segmented-control`; Compose's
/// `SingleChoiceSegmentedButtonRow`, Material's `SegmentedButton`): Material 3
/// Expressive's connected button group, which replaces segmented buttons —
/// two to five toggle buttons joined 2dp apart, the outer corners full and
/// the inner ones small; a press tightens the inner corners and widens the
/// segment, and a selected segment rounds out fully. It picks one: [value]
/// is the chosen segment's, and each segment is a radio button to assistive
/// technology. [ExpressiveMultiChoiceSegmentedButton] picks several.
///
/// Disabled when [onChanged] is null.
///
/// ```dart
/// ExpressiveSegmentedButton<int>(segments: [ExpressiveButtonSegment(0, 'Day'), ExpressiveButtonSegment(1, 'Week')], value: range, onChanged: setRange)
/// ```
class ExpressiveSegmentedButton<T> extends StatelessWidget {
  /// A segmented button of [segments] with [value]'s segment chosen.
  const ExpressiveSegmentedButton({
    required this.segments,
    required this.value,
    required this.onChanged,
    this.kind = ExpressiveToggleButtonKind.filled,
    this.style,
    this.size = ExpressiveButtonSize.small,
    this.expand = true,
    super.key,
  });

  /// The options, start to end.
  final List<ExpressiveButtonSegment<T>> segments;

  /// The chosen segment's value; none is chosen when it matches none.
  final T? value;

  /// Told the value of the segment chosen; the button is disabled when null.
  /// Choosing the chosen segment again tells nothing.
  final ValueChanged<T>? onChanged;

  /// The segments' toggle-button kind.
  final ExpressiveToggleButtonKind kind;

  /// Stateful visual overrides before the component theme.
  final ExpressiveComponentThemeData? style;

  /// The size (`ConnectedButtonGroup*Tokens`).
  final ExpressiveButtonSize size;

  /// Share the available width equally (Compose's samples weight each
  /// segment 1); otherwise each segment takes its own width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return _ConnectedSegments<T>(
      segments: segments,
      isSelected: (segment) => segment == value,
      onToggle: onChanged == null
          ? null
          : (segment) {
              if (segment != value) onChanged(segment);
            },
      role: ExpressivePressRole.radio,
      kind: kind,
      style: style,
      size: size,
      expand: expand,
    );
  }
}

/// The multi-choice segmented button (CONTRACT §4.1 `segmented-control`,
/// `multi`; Compose's `MultiChoiceSegmentedButtonRow`): the connected group
/// of [ExpressiveSegmentedButton] whose segments are independent toggles,
/// [value] the set chosen.
///
/// Disabled when [onChanged] is null.
///
/// ```dart
/// ExpressiveMultiChoiceSegmentedButton<String>(segments: [ExpressiveButtonSegment('wifi', 'Wi-Fi'), ExpressiveButtonSegment('pool', 'Pool')], value: amenities, onChanged: setAmenities)
/// ```
class ExpressiveMultiChoiceSegmentedButton<T> extends StatelessWidget {
  /// A segmented button of [segments] with [value]'s segments chosen.
  const ExpressiveMultiChoiceSegmentedButton({
    required this.segments,
    required this.value,
    required this.onChanged,
    this.emptySelectionAllowed = false,
    this.kind = ExpressiveToggleButtonKind.filled,
    this.style,
    this.size = ExpressiveButtonSize.small,
    this.expand = true,
    super.key,
  });

  /// The options, start to end.
  final List<ExpressiveButtonSegment<T>> segments;

  /// The chosen segments' values.
  final Set<T> value;

  /// Told the new set; the button is disabled when null.
  final ValueChanged<Set<T>>? onChanged;

  /// Whether the last chosen segment may be let go.
  final bool emptySelectionAllowed;

  /// The segments' toggle-button kind.
  final ExpressiveToggleButtonKind kind;

  /// Stateful visual overrides before the component theme.
  final ExpressiveComponentThemeData? style;

  /// The size (`ConnectedButtonGroup*Tokens`).
  final ExpressiveButtonSize size;

  /// Share the available width equally (Compose's samples weight each
  /// segment 1); otherwise each segment takes its own width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return _ConnectedSegments<T>(
      segments: segments,
      isSelected: value.contains,
      onToggle: onChanged == null
          ? null
          : (segment) {
              final next = Set<T>.of(value);
              if (!next.remove(segment)) {
                next.add(segment);
              } else if (next.isEmpty && !emptySelectionAllowed) {
                return;
              }
              onChanged(next);
            },
      role: ExpressivePressRole.toggle,
      kind: kind,
      style: style,
      size: size,
      expand: expand,
    );
  }
}

/// The connected row both segmented buttons draw.
class _ConnectedSegments<T> extends StatelessWidget {
  const _ConnectedSegments({
    required this.segments,
    required this.isSelected,
    required this.onToggle,
    required this.role,
    required this.kind,
    required this.style,
    required this.size,
    required this.expand,
  });

  final List<ExpressiveButtonSegment<T>> segments;
  final bool Function(T value) isSelected;
  final ValueChanged<T>? onToggle;
  final ExpressivePressRole role;
  final ExpressiveToggleButtonKind kind;

  /// Stateful visual overrides before the component theme.
  final ExpressiveComponentThemeData? style;
  final ExpressiveButtonSize size;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    assert(segments.isNotEmpty, 'a segmented button has segments');
    final connected = _ConnectedMetrics.of(size);
    final count = segments.length;
    final onToggle = this.onToggle;
    return ExpressiveButtonGroup._connected(
      size: size,
      expand: expand,
      spacing: connected.between,
      children: <Widget>[
        // Each segment marks its own drawn face (markFace): an unchosen
        // tonal one is faint on the page.
        for (var i = 0; i < count; i++)
          ExpressiveToggleButton._segment(
            value: isSelected(segments[i].value),
            onChanged: onToggle == null || !segments[i].enabled
                ? null
                : (_) => onToggle(segments[i].value),
            label: segments[i].label,
            icon: segments[i].icon,
            kind: kind,
            style: style,
            size: size,
            shapes: connected.shapes(first: i == 0, last: i == count - 1),
            role: role,
          ),
      ],
    );
  }
}

/// A link in running text (CONTRACT §4.1 `link`): its words in `primary`,
/// underlined, with the pressable's state layers and ripple. Place it in a
/// paragraph with [span].
///
/// Disabled when [onPressed] is null.
class ExpressiveLink extends StatelessWidget {
  /// A link reading [text] that runs [onPressed].
  const ExpressiveLink(
    this.text, {
    required this.onPressed,
    this.style,
    this.semanticLabel,
    super.key,
    this.focusNode,
    this.autofocus = false,
  });

  /// [text] as a link inside a `Text.rich` paragraph, on its baseline.
  static InlineSpan span(
    String text, {
    required VoidCallback? onPressed,
    TextStyle? style,
    String? semanticLabel,
  }) => WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: ExpressiveLink(
      text,
      onPressed: onPressed,
      style: style,
      semanticLabel: semanticLabel,
    ),
  );

  /// The link's words.
  final String text;

  /// What a tap does; the link is disabled when null.
  final VoidCallback? onPressed;

  /// Merged over the running text's style.
  final TextStyle? style;

  /// What a screen reader says instead of [text].
  final String? semanticLabel;

  /// The focus node of its press target; null lets the target keep its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final colors = theme.colors;
    final color = onPressed == null
        ? _alpha(
            colors,
            TextButtonTokens.disabledLabelColor,
            TextButtonTokens.disabledLabelOpacity,
          )
        : colors.role(ButtonBehavior.textButtonContentColor);
    final textStyle = DefaultTextStyle.of(context).style
        .merge(style)
        .copyWith(
          color: color,
          decoration: TextDecoration.underline,
          decorationColor: color,
        );
    return ExpressivePressable(
      focusNode: focusNode,
      autofocus: autofocus,
      shapes: ExpressivePressShapes.all(theme.shapes.extraSmall),
      motion: ButtonBehavior.pressMotion,
      color: _transparent,
      contentColor: color,
      role: ExpressivePressRole.link,
      minimumInteractiveSize: false,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: Text(text, style: textStyle),
    );
  }
}

// ---------------------------------------------------------------------------
// Metrics and paint.

/// Compose's `Color.Transparent`.
const Color _transparent = expressiveTransparent;

/// One size's geometry: `ButtonDefaults.*For(height)`.
@immutable
class _ButtonMetrics {
  const _ButtonMetrics({
    required this.height,
    required this.start,
    required this.end,
    required this.top,
    required this.bottom,
    required this.iconSize,
    required this.iconSpacing,
    required this.textStyle,
    required this.roundShape,
    required this.squareShape,
    required this.pressedShape,
    required this.checkedFromRound,
    required this.checkedFromSquare,
  });

  static _ButtonMetrics of(ExpressiveButtonSize size) => switch (size) {
    ExpressiveButtonSize.extraSmall => _xs,
    ExpressiveButtonSize.small => _s,
    ExpressiveButtonSize.medium => _m,
    ExpressiveButtonSize.large => _l,
    ExpressiveButtonSize.extraLarge => _xl,
  };

  // ExtraSmallContentPadding (hard-coded in Compose beside a TODO).
  static const _ButtonMetrics _xs = _ButtonMetrics(
    height: ButtonXSmallTokens.containerHeight,
    start: ButtonBehavior.extraSmallContentPaddingStart,
    end: ButtonBehavior.extraSmallContentPaddingEnd,
    top: ButtonBehavior.extraSmallContentPaddingTop,
    bottom: ButtonBehavior.extraSmallContentPaddingBottom,
    iconSize: ButtonXSmallTokens.iconSize,
    iconSpacing: ButtonBehavior.extraSmallIconSpacing,
    textStyle: ExpressiveTypeKey.labelLarge,
    roundShape: ButtonXSmallTokens.containerShapeRound,
    squareShape: ButtonXSmallTokens.containerShapeSquare,
    pressedShape: ButtonXSmallTokens.pressedContainerShape,
    checkedFromRound: ButtonXSmallTokens.selectedContainerShapeSquare,
    checkedFromSquare: ButtonXSmallTokens.selectedContainerShapeRound,
  );

  // getSmallContentPadding on a touch screen.
  static const _ButtonMetrics _s = _ButtonMetrics(
    height: ButtonSmallTokens.containerHeight,
    start: ButtonSmallTokens.leadingSpace,
    end: ButtonSmallTokens.trailingSpace,
    top: ButtonBehavior.smallVerticalPadding,
    bottom: ButtonBehavior.smallVerticalPadding,
    iconSize: ButtonSmallTokens.iconSize,
    iconSpacing: ButtonSmallTokens.iconLabelSpace,
    textStyle: ExpressiveTypeKey.labelLarge,
    roundShape: ButtonSmallTokens.containerShapeRound,
    squareShape: ButtonSmallTokens.containerShapeSquare,
    pressedShape: ButtonSmallTokens.pressedContainerShape,
    checkedFromRound: ToggleButtonBehavior.checkedShape,
    checkedFromSquare: ButtonSmallTokens.selectedContainerShapeRound,
  );

  static const _ButtonMetrics _m = _ButtonMetrics(
    height: ButtonMediumTokens.containerHeight,
    start: ButtonMediumTokens.leadingSpace,
    end: ButtonMediumTokens.trailingSpace,
    top: ButtonBehavior.mediumVerticalPadding,
    bottom: ButtonBehavior.mediumVerticalPadding,
    iconSize: ButtonMediumTokens.iconSize,
    iconSpacing: ButtonMediumTokens.iconLabelSpace,
    textStyle: ExpressiveTypeKey.titleMedium,
    roundShape: ButtonMediumTokens.containerShapeRound,
    squareShape: ButtonMediumTokens.containerShapeSquare,
    pressedShape: ButtonMediumTokens.pressedContainerShape,
    checkedFromRound: ButtonMediumTokens.selectedContainerShapeSquare,
    checkedFromSquare: ButtonMediumTokens.selectedContainerShapeRound,
  );

  static const _ButtonMetrics _l = _ButtonMetrics(
    height: ButtonLargeTokens.containerHeight,
    start: ButtonLargeTokens.leadingSpace,
    end: ButtonLargeTokens.trailingSpace,
    top: ButtonBehavior.largeVerticalPadding,
    bottom: ButtonBehavior.largeVerticalPadding,
    iconSize: ButtonLargeTokens.iconSize,
    iconSpacing: ButtonLargeTokens.iconLabelSpace,
    textStyle: ExpressiveTypeKey.headlineSmall,
    roundShape: ButtonLargeTokens.containerShapeRound,
    squareShape: ButtonLargeTokens.containerShapeSquare,
    pressedShape: ButtonLargeTokens.pressedContainerShape,
    checkedFromRound: ButtonLargeTokens.selectedContainerShapeSquare,
    checkedFromSquare: ButtonLargeTokens.selectedContainerShapeRound,
  );

  // ExtraLargeContentPadding.
  static const _ButtonMetrics _xl = _ButtonMetrics(
    height: ButtonXLargeTokens.containerHeight,
    start: ButtonXLargeTokens.leadingSpace,
    end: ButtonXLargeTokens.trailingSpace,
    top: ButtonBehavior.extraLargeVerticalPadding,
    bottom: ButtonBehavior.extraLargeVerticalPadding,
    iconSize: ButtonXLargeTokens.iconSize,
    iconSpacing: ButtonXLargeTokens.iconLabelSpace,
    textStyle: ExpressiveTypeKey.headlineLarge,
    roundShape: ButtonXLargeTokens.containerShapeRound,
    squareShape: ButtonXLargeTokens.containerShapeSquare,
    pressedShape: ButtonXLargeTokens.pressedContainerShape,
    checkedFromRound: ButtonXLargeTokens.selectedContainerShapeSquare,
    checkedFromSquare: ButtonXLargeTokens.selectedContainerShapeRound,
  );

  final double height;
  final double start;
  final double end;
  final double top;
  final double bottom;
  final double iconSize;
  final double iconSpacing;
  final ExpressiveTypeKey textStyle;
  final ExpressiveShapeKey roundShape;
  final ExpressiveShapeKey squareShape;
  final ExpressiveShapeKey pressedShape;
  final ExpressiveShapeKey checkedFromRound;
  final ExpressiveShapeKey checkedFromSquare;

  /// A toggle button's pressed shape: the small size presses to
  /// `ToggleButtonBehavior.pressedShape` (6dp), the others to the size's
  /// token.
  OutlinedBorder togglePressedShape(ExpressiveShapes shapes) =>
      identical(this, _s)
      ? const ExpressiveCornerBorder.all(
          ExpressiveCornerSize.dp(ToggleButtonBehavior.pressedShape),
        )
      : shapes.of(pressedShape);
}

/// A connected group's geometry at one size (`ConnectedButtonGroup*Tokens`).
@immutable
class _ConnectedMetrics {
  const _ConnectedMetrics(this.between, this.inner, this.pressedInner);

  static _ConnectedMetrics of(ExpressiveButtonSize size) => switch (size) {
    ExpressiveButtonSize.extraSmall => const _ConnectedMetrics(
      ConnectedButtonGroupXSmallTokens.betweenSpace,
      ConnectedButtonGroupXSmallTokens.innerCornerCornerSize,
      ConnectedButtonGroupXSmallTokens.pressedInnerCornerCornerSize,
    ),
    ExpressiveButtonSize.small => const _ConnectedMetrics(
      ConnectedButtonGroupSmallTokens.betweenSpace,
      ConnectedButtonGroupSmallTokens.innerCornerCornerSize,
      ConnectedButtonGroupSmallTokens.pressedInnerCornerCornerSize,
    ),
    ExpressiveButtonSize.medium => const _ConnectedMetrics(
      ConnectedButtonGroupMediumTokens.betweenSpace,
      ConnectedButtonGroupMediumTokens.innerCornerCornerSize,
      ConnectedButtonGroupMediumTokens.pressedInnerCornerCornerSize,
    ),
    ExpressiveButtonSize.large => const _ConnectedMetrics(
      ConnectedButtonGroupLargeTokens.betweenSpace,
      ConnectedButtonGroupLargeTokens.innerCornerCornerSize,
      ConnectedButtonGroupLargeTokens.pressedInnerCornerCornerSize,
    ),
    ExpressiveButtonSize.extraLarge => const _ConnectedMetrics(
      ConnectedButtonGroupXLargeTokens.betweenSpace,
      ConnectedButtonGroupXLargeTokens.innerCornerCornerSize,
      ConnectedButtonGroupXLargeTokens.pressedInnerCornerCornerSize,
    ),
  };

  /// Fully round (`ShapeDefaults.CornerFull`, `ShapeTokens.CornerFull`).
  static const ExpressiveCornerSize _full = ExpressiveCornerSize.fraction(0.5);

  final double between;
  final double inner;
  final double pressedInner;

  /// `ButtonGroupDefaults.connected{Leading,Middle,Trailing}ButtonShapes`
  /// for a segment that is [first] and/or [last] in its group.
  ExpressivePressShapes shapes({required bool first, required bool last}) {
    ExpressiveCornerBorder at(double corner) {
      final innerSize = ExpressiveCornerSize.dp(corner);
      return ExpressiveCornerBorder(
        topStart: first ? _full : innerSize,
        bottomStart: first ? _full : innerSize,
        topEnd: last ? _full : innerSize,
        bottomEnd: last ? _full : innerSize,
      );
    }

    return ExpressivePressShapes(
      shape: at(inner),
      pressed: at(pressedInner),
      selected: const ExpressiveCornerBorder.all(_full),
    );
  }
}

/// What a button paints with in one state.
@immutable
class _Paint {
  const _Paint({
    required this.container,
    required this.content,
    this.side = BorderSide.none,
    this.elevation = ExpressiveStateElevation.none,
  });

  final Color container;
  final Color content;
  final BorderSide side;
  final ExpressiveStateElevation elevation;

  /// This with [theme]'s slots for [states] over it; the outline recoloured
  /// where there is one.
  _Paint themed(ExpressiveComponentThemeData theme, Set<WidgetState> states) {
    if (theme.isEmpty) return this;
    return _Paint(
      container: ExpressiveComponentThemeData.resolve(
        theme.backgroundColor,
        states,
        container,
      ),
      content: ExpressiveComponentThemeData.resolve(
        theme.foregroundColor,
        states,
        content,
      ),
      side: side.style == BorderStyle.none || side.width <= 0
          ? side
          : side.copyWith(
              color: ExpressiveComponentThemeData.resolve(
                theme.outline,
                states,
                side.color,
              ),
            ),
      elevation: elevation,
    );
  }
}

Color _alpha(
  ExpressiveColorScheme colors,
  ExpressiveColorRole role,
  double alpha,
) => colors.role(role).withValues(alpha: alpha);

/// `ButtonDefaults.outlinedButtonBorder(enabled)`: the small size's width
/// at every size, as Compose draws it.
BorderSide _outline(ExpressiveColorScheme colors, {required bool enabled}) =>
    BorderSide(
      width: ButtonSmallTokens.outlinedOutlineWidth,
      color: enabled
          ? colors.role(OutlinedButtonTokens.outlineColor)
          : _alpha(
              colors,
              OutlinedButtonTokens.outlineColor,
              OutlinedButtonTokens.disabledContainerOpacity,
            ),
    );

const ExpressiveStateElevation _filledElevation = ExpressiveStateElevation(
  rest: FilledButtonTokens.containerElevation,
  pressed: FilledButtonTokens.pressedContainerElevation,
  focused: FilledButtonTokens.focusedContainerElevation,
  hovered: FilledButtonTokens.hoveredContainerElevation,
  disabled: FilledButtonTokens.disabledContainerElevation,
);

// FilledTonalButtonDefaults: its disabled elevation is 0 in code.
const ExpressiveStateElevation _tonalElevation = ExpressiveStateElevation(
  rest: FilledTonalButtonTokens.containerElevation,
  pressed: FilledTonalButtonTokens.pressedContainerElevation,
  focused: FilledTonalButtonTokens.focusContainerElevation,
  hovered: FilledTonalButtonTokens.hoverContainerElevation,
  disabled: ExpressiveElevationLevel.level0,
);

const ExpressiveStateElevation _elevatedElevation = ExpressiveStateElevation(
  rest: ElevatedButtonTokens.containerElevation,
  pressed: ElevatedButtonTokens.pressedContainerElevation,
  focused: ElevatedButtonTokens.focusedContainerElevation,
  hovered: ElevatedButtonTokens.hoveredContainerElevation,
  disabled: ElevatedButtonTokens.disabledContainerElevation,
);

/// `ButtonDefaults.*ButtonColors`, `*Elevation` and the outlined border.
_Paint _buttonPaint(
  ExpressiveColorScheme colors,
  ExpressiveButtonKind style, {
  required bool enabled,
}) {
  switch (style) {
    case ExpressiveButtonKind.filled:
      if (!enabled) {
        return _Paint(
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
      }
      return _Paint(
        container: colors.role(FilledButtonTokens.containerColor),
        content: colors.role(FilledButtonTokens.labelTextColor),
        elevation: _filledElevation,
      );
    case ExpressiveButtonKind.tonal:
      return enabled
          ? _Paint(
              container: colors.role(FilledTonalButtonTokens.containerColor),
              content: colors.role(FilledTonalButtonTokens.labelTextColor),
              elevation: _tonalElevation,
            )
          : _Paint(
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
    case ExpressiveButtonKind.outlined:
      return _Paint(
        container: _transparent,
        content: enabled
            ? colors.role(OutlinedButtonTokens.labelTextColor)
            : _alpha(
                colors,
                OutlinedButtonTokens.disabledLabelTextColor,
                OutlinedButtonTokens.disabledLabelTextOpacity,
              ),
        side: _outline(colors, enabled: enabled),
      );
    case ExpressiveButtonKind.elevated:
      return enabled
          ? _Paint(
              container: colors.role(ElevatedButtonTokens.containerColor),
              content: colors.role(ElevatedButtonTokens.labelTextColor),
              elevation: _elevatedElevation,
            )
          : _Paint(
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
    case ExpressiveButtonKind.text:
      return _Paint(
        container: _transparent,
        content: enabled
            ? colors.role(ButtonBehavior.textButtonContentColor)
            : _alpha(
                colors,
                TextButtonTokens.disabledLabelColor,
                TextButtonTokens.disabledLabelOpacity,
              ),
      );
  }
}

/// `ToggleButtonDefaults.colors()` and its elevated, tonal and outlined
/// forms, with their elevations and the outlined border.
_Paint _togglePaint(
  ExpressiveColorScheme colors,
  ExpressiveToggleButtonKind style, {
  required bool enabled,
  required bool checked,
}) {
  switch (style) {
    case ExpressiveToggleButtonKind.filled:
      if (!enabled) {
        return _Paint(
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
      }
      return _Paint(
        container: colors.role(
          checked
              ? FilledButtonTokens.selectedContainerColor
              : FilledButtonTokens.unselectedContainerColor,
        ),
        content: colors.role(
          checked
              ? FilledButtonTokens.selectedPressedLabelTextColor
              : FilledButtonTokens.unselectedPressedLabelTextColor,
        ),
        elevation: _filledElevation,
      );
    case ExpressiveToggleButtonKind.elevated:
      if (!enabled) {
        return _Paint(
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
      return _Paint(
        container: colors.role(
          checked
              ? ElevatedButtonTokens.selectedContainerColor
              : ElevatedButtonTokens.unselectedContainerColor,
        ),
        content: colors.role(
          checked
              ? ElevatedButtonTokens.selectedPressedLabelTextColor
              : ElevatedButtonTokens.unselectedPressedLabelTextColor,
        ),
        elevation: _elevatedElevation,
      );
    case ExpressiveToggleButtonKind.tonal:
      if (!enabled) {
        return _Paint(
          container: _alpha(
            colors,
            TonalButtonTokens.disabledContainerColor,
            TonalButtonTokens.disabledContainerOpacity,
          ),
          content: _alpha(
            colors,
            TonalButtonTokens.disabledLabelTextColor,
            TonalButtonTokens.disabledLabelTextOpacity,
          ),
          elevation: _tonalElevation,
        );
      }
      return _Paint(
        container: colors.role(
          checked
              ? TonalButtonTokens.selectedContainerColor
              : TonalButtonTokens.unselectedContainerColor,
        ),
        content: colors.role(
          checked
              ? TonalButtonTokens.selectedLabelTextColor
              : TonalButtonTokens.unselectedLabelTextColor,
        ),
        elevation: _tonalElevation,
      );
    case ExpressiveToggleButtonKind.outlined:
      if (!enabled) {
        return _Paint(
          container: _alpha(
            colors,
            OutlinedButtonTokens.disabledOutlineColor,
            OutlinedButtonTokens.disabledContainerOpacity,
          ),
          content: _alpha(
            colors,
            OutlinedButtonTokens.disabledLabelTextColor,
            OutlinedButtonTokens.disabledLabelTextOpacity,
          ),
          side: checked ? BorderSide.none : _outline(colors, enabled: false),
        );
      }
      return _Paint(
        container: checked
            ? colors.role(OutlinedButtonTokens.selectedContainerColor)
            : _transparent,
        content: colors.role(
          checked
              ? OutlinedButtonTokens.selectedLabelTextColor
              : OutlinedButtonTokens.unselectedLabelTextColor,
        ),
        side: checked ? BorderSide.none : _outline(colors, enabled: true),
      );
  }
}

// ---------------------------------------------------------------------------
// Layout.

/// A button's content: `Row(Modifier.defaultMinSize(…).padding(…))` — the
/// minimum size, the padding, and the icons beside a label that wraps to
/// two lines before it ellipsizes.
class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.metrics,
    required this.minWidth,
    required this.expand,
    required this.textStyle,
    required this.label,
    this.content,
    this.leading,
    this.trailing,
  });

  final _ButtonMetrics metrics;
  final double minWidth;
  final bool expand;
  final TextStyle textStyle;
  final String label;
  final Widget? content;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scope = ExpressiveStyleScope.maybeOf(context);
    final style = scope?.style;
    final states = scope?.states ?? const <WidgetState>{};
    final density = context.expressiveTheme.density;
    final minimum = style?.minimumSize?.resolve(states);
    final actualTextStyle = style?.textStyle?.resolve(states) ?? textStyle;
    final foreground = style?.foregroundColor?.resolve(states);
    final actualIconSize = style?.iconSize?.resolve(states) ?? metrics.iconSize;
    final ownPadding = EdgeInsetsDirectional.fromSTEB(
      metrics.start,
      metrics.top,
      metrics.end,
      metrics.bottom,
    ).resolve(Directionality.of(context));
    final padding =
        (style?.padding?.resolve(states) ?? density.padding(ownPadding)).add(
          scope?.inset ?? EdgeInsets.zero,
        );
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minimum?.width ?? minWidth,
        minHeight: minimum?.height ?? density.height(metrics.height),
      ),
      child: _ButtonPadding(
        padding: padding,
        // In a group, a press widens one button and narrows its neighbours
        // (ButtonGroup.kt): a narrowed button gives up its own padding, down
        // to the floor, before its label would wrap.
        squishFloor: context.getInheritedWidgetOfExactType<_GroupSlot>() == null
            ? null
            : _ButtonPadding.floor,
        child: IconTheme.merge(
          data: IconThemeData(size: actualIconSize, color: foreground),
          child: _ButtonRow(
            gap: metrics.iconSpacing,
            hasLeading: leading != null,
            textDirection: Directionality.of(context),
            children: <Widget>[
              ?leading,
              if (this.content case final slot?)
                Semantics(
                  label: label,
                  child: ExcludeSemantics(
                    // A label's own content (a count that rolls, a word that
                    // swaps) is the label: centred by its capitals too.
                    child: DefaultTextStyle.merge(
                      style: actualTextStyle.copyWith(color: foreground),
                      child: expressiveFaceLabel(slot),
                    ),
                  ),
                )
              else
                expressiveFaceLabel(
                  Text(
                    label,
                    style: actualTextStyle.copyWith(color: foreground),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    // A wrapped label is as wide as its longest line, so
                    // the icon stays beside it and the pair centres.
                    textWidthBasis: TextWidthBasis.longestLine,
                  ),
                ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
    if (expand) {
      content = SizedBox(width: double.infinity, child: content);
    }
    return ExpressiveFillProbedWidth(child: content);
  }
}

/// A button's padding. With a [squishFloor] (a button in a group), a width
/// too narrow for the content at its own width comes out of the horizontal
/// padding first, each side down to [squishFloor], so a neighbour narrowed
/// by a press keeps its label on one line; past that, the content narrows
/// as under [Padding].
class _ButtonPadding extends SingleChildRenderObjectWidget {
  const _ButtonPadding({
    required this.padding,
    required this.squishFloor,
    super.child,
  });

  /// The least padding a squished side keeps.
  static const double floor = ExpressiveSpacing.s4;

  final EdgeInsetsGeometry padding;
  final double? squishFloor;

  @override
  _RenderButtonPadding createRenderObject(BuildContext context) =>
      _RenderButtonPadding(padding, squishFloor, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderButtonPadding renderObject,
  ) {
    renderObject
      ..padding = padding
      ..textDirection = Directionality.of(context)
      ..squishFloor = squishFloor;
  }
}

class _RenderButtonPadding extends RenderPadding {
  _RenderButtonPadding(
    EdgeInsetsGeometry padding,
    this._squishFloor,
    TextDirection textDirection,
  ) : super(padding: padding, textDirection: textDirection);

  double? _squishFloor;
  set squishFloor(double? value) {
    if (value == _squishFloor) return;
    _squishFloor = value;
    markNeedsLayout();
  }

  /// The padding at [constraints]: the own padding, its horizontal sides
  /// given up toward the floor as far as the content needs.
  EdgeInsets _paddingAt(BoxConstraints constraints) {
    final own = padding.resolve(textDirection);
    final child = this.child;
    final floor = _squishFloor;
    if (child == null || floor == null || !constraints.hasBoundedWidth) {
      return own;
    }
    final natural = child.getMaxIntrinsicWidth(double.infinity);
    final deficit = natural - (constraints.maxWidth - own.horizontal);
    final leftRoom = math.max(0.0, own.left - floor);
    final rightRoom = math.max(0.0, own.right - floor);
    final room = leftRoom + rightRoom;
    if (deficit <= 0 || room <= 0) return own;
    final take = math.min(deficit, room);
    return EdgeInsets.fromLTRB(
      own.left - take * leftRoom / room,
      own.top,
      own.right - take * rightRoom / room,
      own.bottom,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    final p = _paddingAt(constraints);
    if (child == null) {
      return constraints.constrain(Size(p.horizontal, p.vertical));
    }
    final inner = child.getDryLayout(constraints.deflate(p));
    return constraints.constrain(
      Size(p.horizontal + inner.width, p.vertical + inner.height),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null || _squishFloor == null) {
      super.performLayout();
      return;
    }
    final p = _paddingAt(constraints);
    child.layout(constraints.deflate(p), parentUsesSize: true);
    (child.parentData! as BoxParentData).offset = Offset(p.left, p.top);
    size = constraints.constrain(
      Size(p.horizontal + child.size.width, p.vertical + child.size.height),
    );
  }
}

class _RowParentData extends ContainerBoxParentData<RenderBox> {}

/// Icons at their size beside a label that takes the width left: a row
/// whose label wraps under a bounded width and stays on one line under an
/// unbounded one, with intrinsic sizes (a group measures its buttons).
class _ButtonRow extends MultiChildRenderObjectWidget {
  const _ButtonRow({
    required this.gap,
    required this.hasLeading,
    required this.textDirection,
    required super.children,
  });

  final double gap;
  final bool hasLeading;
  final TextDirection textDirection;

  @override
  _RenderButtonRow createRenderObject(BuildContext context) =>
      _RenderButtonRow(gap, hasLeading, textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderButtonRow renderObject) {
    renderObject
      ..gap = gap
      ..hasLeading = hasLeading
      ..textDirection = textDirection;
  }
}

class _RenderButtonRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RowParentData> {
  _RenderButtonRow(this._gap, this._hasLeading, this._textDirection);

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  bool _hasLeading;
  set hasLeading(bool value) {
    if (value == _hasLeading) return;
    _hasLeading = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RowParentData) {
      child.parentData = _RowParentData();
    }
  }

  RenderBox get _label => getChildrenAsList()[_hasLeading ? 1 : 0];

  Iterable<RenderBox> get _icons {
    final label = _label;
    return getChildrenAsList().where((child) => child != label);
  }

  double get _gaps => _icons.length * _gap;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _icons.fold<double>(0, (w, c) => w + c.getMaxIntrinsicWidth(height)) +
      _gaps +
      _label.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      getChildrenAsList().fold<double>(
        0,
        (w, c) => w + c.getMaxIntrinsicWidth(height),
      ) +
      _gaps;

  @override
  double computeMinIntrinsicHeight(double width) => getChildrenAsList()
      .fold<double>(0, (h, c) => math.max(h, c.getMinIntrinsicHeight(width)));

  @override
  double computeMaxIntrinsicHeight(double width) => getChildrenAsList()
      .fold<double>(0, (h, c) => math.max(h, c.getMaxIntrinsicHeight(width)));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final loose = constraints.loosen();
    var iconsWidth = 0.0;
    var height = 0.0;
    for (final icon in _icons) {
      final size = dry
          ? icon.getDryLayout(loose)
          : (icon..layout(loose, parentUsesSize: true)).size;
      iconsWidth += size.width;
      height = math.max(height, size.height);
    }
    final labelConstraints = BoxConstraints(
      maxWidth: constraints.hasBoundedWidth
          ? math.max(0, constraints.maxWidth - iconsWidth - _gaps)
          : double.infinity,
      maxHeight: loose.maxHeight,
    );
    final label = _label;
    final labelSize = dry
        ? label.getDryLayout(labelConstraints)
        : (label..layout(labelConstraints, parentUsesSize: true)).size;
    height = math.max(height, labelSize.height);
    return constraints.constrain(
      Size(iconsWidth + _gaps + labelSize.width, height),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void performLayout() {
    size = _layout(constraints, dry: false);
    final children = getChildrenAsList();
    final contentWidth =
        children.fold<double>(0, (w, c) => w + c.size.width) + _gaps;
    final ordered = _textDirection == TextDirection.ltr
        ? children
        : children.reversed.toList();
    var x = (size.width - contentWidth) / 2;
    for (final child in ordered) {
      (child.parentData! as _RowParentData).offset = Offset(
        x,
        (size.height - child.size.height) * 0.5,
      );
      x += child.size.width + _gap;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

class _GroupParentData extends ContainerBoxParentData<RenderBox> {}

/// `ButtonGroupMeasurePolicy` (without the overflow menu): each button at
/// its own width or its weight's share, spaced; then each pressed button's
/// growth taken from its neighbours.
class _GroupLayout extends MultiChildRenderObjectWidget {
  const _GroupLayout({
    required this.spacing,
    required this.weights,
    required this.progress,
    required this.expandedRatio,
    required this.textDirection,
    required super.children,
  });

  final double spacing;
  final List<double> weights;
  final List<Animation<double>> progress;
  final double expandedRatio;
  final TextDirection textDirection;

  @override
  _RenderGroup createRenderObject(BuildContext context) => _RenderGroup(
    spacing: spacing,
    weights: weights,
    progress: progress,
    expandedRatio: expandedRatio,
    textDirection: textDirection,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderGroup renderObject) {
    renderObject
      ..spacing = spacing
      ..weights = weights
      ..progress = progress
      ..expandedRatio = expandedRatio
      ..textDirection = textDirection;
  }
}

class _RenderGroup extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GroupParentData> {
  _RenderGroup({
    required this._spacing,
    required this._weights,
    required this._progress,
    required this._expandedRatio,
    required this._textDirection,
  });

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  List<double> _weights;
  set weights(List<double> value) {
    if (listEquals(value, _weights)) return;
    _weights = value;
    markNeedsLayout();
  }

  List<Animation<double>> _progress;
  set progress(List<Animation<double>> value) {
    if (listEquals(value, _progress)) return;
    if (attached) {
      for (final p in _progress) {
        p.removeListener(markNeedsLayout);
      }
      for (final p in value) {
        p.addListener(markNeedsLayout);
      }
    }
    _progress = value;
    markNeedsLayout();
  }

  double _expandedRatio;
  set expandedRatio(double value) {
    if (value == _expandedRatio) return;
    _expandedRatio = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (final p in _progress) {
      p.addListener(markNeedsLayout);
    }
  }

  @override
  void detach() {
    for (final p in _progress) {
      p.removeListener(markNeedsLayout);
    }
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GroupParentData) {
      child.parentData = _GroupParentData();
    }
  }

  double _weightOf(int index) => index < _weights.length ? _weights[index] : 0;

  double get _spacingTotal => math.max(0, childCount - 1) * _spacing;

  @override
  double computeMinIntrinsicWidth(double height) =>
      computeMaxIntrinsicWidth(height);

  /// Its own widths, and room enough that each weighted child's share of
  /// what is left is its own width: an expanded group shares its width by
  /// weight, so its widest segment, not their sum, sets what it needs.
  @override
  double computeMaxIntrinsicWidth(double height) {
    final children = getChildrenAsList();
    var fixed = 0.0;
    var totalWeight = 0.0;
    for (var i = 0; i < children.length; i++) {
      final weight = _weightOf(i);
      if (weight > 0) {
        totalWeight += weight;
      } else {
        fixed += children[i].getMaxIntrinsicWidth(height);
      }
    }
    var shared = 0.0;
    for (var i = 0; i < children.length; i++) {
      final weight = _weightOf(i);
      if (weight <= 0) continue;
      shared = math.max(
        shared,
        children[i].getMaxIntrinsicWidth(height) * totalWeight / weight,
      );
    }
    return fixed + shared + _spacingTotal;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _intrinsicHeight(width, (child, w) => child.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _intrinsicHeight(width, (child, w) => child.getMaxIntrinsicHeight(w));

  double _intrinsicHeight(
    double width,
    double Function(RenderBox child, double width) heightOf,
  ) {
    final children = getChildrenAsList();
    final c = BoxConstraints(maxWidth: width);
    final widths = _baseWidths(children, c);
    final rows = _rows(widths, c);
    var height = 0.0;
    for (final row in rows) {
      height += row.fold<double>(
        0,
        (h, i) => math.max(h, heightOf(children[i], widths[i])),
      );
    }
    return height + (rows.length - 1) * _runSpacing;
  }

  /// The gap between rows, when the buttons flow onto more than one.
  double get _runSpacing => math.max(_spacing, 8);

  /// The rows the buttons stand in: one, or, when even their narrowest
  /// (each label broken only between its words) is too wide, as many as
  /// their own widths need, each from the start edge. A row is a list of
  /// child indices; [widths] are capped at the width on the way.
  List<List<int>> _rows(List<double> widths, BoxConstraints c) {
    final all = [for (var i = 0; i < widths.length; i++) i];
    if (!c.hasBoundedWidth) return [all];
    final total = widths.fold<double>(0, (a, b) => a + b) + _spacingTotal;
    if (total <= c.maxWidth + 0.01) return [all];
    final rows = <List<int>>[];
    var row = <int>[];
    var x = 0.0;
    for (final i in all) {
      widths[i] = math.min(widths[i], c.maxWidth);
      if (row.isNotEmpty && x + _spacing + widths[i] > c.maxWidth + 0.01) {
        rows.add(row);
        row = <int>[];
        x = 0;
      }
      x += (row.isEmpty ? 0 : _spacing) + widths[i];
      row.add(i);
    }
    rows.add(row);
    // An expanded group's rows each fill the width, shared by weight.
    for (final row in rows) {
      final weight = row.fold<double>(0, (a, i) => a + _weightOf(i));
      final spare = c.maxWidth - _rowWidth(row, widths);
      if (weight <= 0 || spare <= 0) continue;
      for (final i in row) {
        widths[i] += spare * _weightOf(i) / weight;
      }
    }
    return rows;
  }

  /// The resting widths: own widths, weights' shares of what is left, and,
  /// when own widths do not fit, each narrowed toward its narrowest (its
  /// label broken only between words), in proportion to what it can give.
  /// When even the narrowest do not fit, own widths stand, and [_rows] flows
  /// them onto more rows (Compose moves what does not fit into an overflow
  /// menu instead; a label is never broken inside a word).
  List<double> _baseWidths(List<RenderBox> children, BoxConstraints c) {
    final widths = List<double>.filled(children.length, 0);
    var fixed = 0.0;
    var totalWeight = 0.0;
    for (var i = 0; i < children.length; i++) {
      final weight = _weightOf(i);
      if (weight > 0) {
        totalWeight += weight;
      } else {
        widths[i] = children[i].getMaxIntrinsicWidth(c.maxHeight);
        fixed += widths[i];
      }
    }
    final target = c.hasBoundedWidth ? c.maxWidth : c.minWidth;
    if (totalWeight > 0) {
      final left = math.max(0, target - fixed - _spacingTotal);
      var fits = true;
      for (var i = 0; i < children.length; i++) {
        final weight = _weightOf(i);
        if (weight <= 0) continue;
        widths[i] = left * weight / totalWeight;
        if (c.hasBoundedWidth &&
            widths[i] + 0.01 < children[i].getMinIntrinsicWidth(c.maxHeight)) {
          fits = false;
        }
      }
      if (fits) return widths;
      // A share too narrow for a word of its label: every button at its own
      // width, narrowed or flowed onto rows as an unweighted group's are
      // ([_rows] fills each row by weight again).
      for (var i = 0; i < children.length; i++) {
        if (_weightOf(i) <= 0) continue;
        widths[i] = children[i].getMaxIntrinsicWidth(c.maxHeight);
        fixed += widths[i];
      }
    }
    if (c.hasBoundedWidth && fixed > 0 && fixed + _spacingTotal > c.maxWidth) {
      final room = math.max(0.0, c.maxWidth - _spacingTotal);
      final narrowest = [
        for (final child in children) child.getMinIntrinsicWidth(c.maxHeight),
      ];
      final floor = narrowest.fold<double>(0, (a, b) => a + b);
      final give = fixed - floor;
      if (floor <= room && give > 0) {
        final k = (fixed - room) / give;
        for (var i = 0; i < widths.length; i++) {
          widths[i] -= (widths[i] - math.min(narrowest[i], widths[i])) * k;
        }
      }
    }
    return widths;
  }

  /// The expand and compress logic of button groups (ButtonGroup.kt): a
  /// pressed middle button takes half its growth from each neighbour, an
  /// end button all of it from its one neighbour.
  /// [widths] are one row's; [index] maps them to the children (and their
  /// press progress).
  void _squish(List<double> widths, List<int> index) {
    final n = widths.length;
    if (n < 2) return;
    const limit = ButtonGroupBehavior.compressionLimit;
    for (var i = 0; i < n; i++) {
      final at = index[i];
      final p = at < _progress.length ? _progress[at].value : 0.0;
      if (p == 0) continue;
      double growth;
      if (i > 0 && i < n - 1) {
        final target = p * math.min(_expandedRatio * widths[i] / 2, limit);
        final left = math.min(target, widths[i - 1]);
        final right = math.min(target, widths[i + 1]);
        widths[i - 1] -= left;
        widths[i + 1] -= right;
        growth = left + right;
      } else {
        final neighbour = i == 0 ? 1 : n - 2;
        final target = p * math.min(_expandedRatio * widths[i], limit);
        growth = math.min(target, widths[neighbour]);
        widths[neighbour] -= growth;
      }
      widths[i] += growth;
    }
  }

  BoxConstraints _childConstraints(
    double width,
    BoxConstraints c, {
    bool oneRow = true,
  }) => BoxConstraints(
    minWidth: width,
    maxWidth: width,
    minHeight: oneRow ? c.minHeight : 0,
    maxHeight: c.maxHeight,
  );

  double _rowWidth(List<int> row, List<double> widths) =>
      row.fold<double>(0, (a, i) => a + widths[i]) +
      math.max(0, row.length - 1) * _spacing;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final children = getChildrenAsList();
    final widths = _baseWidths(children, constraints);
    final rows = _rows(widths, constraints);
    var main = 0.0;
    var height = (rows.length - 1) * _runSpacing;
    for (final row in rows) {
      main = math.max(main, _rowWidth(row, widths));
      height += row.fold<double>(
        0,
        (h, i) => math.max(
          h,
          children[i]
              .getDryLayout(
                _childConstraints(
                  widths[i],
                  constraints,
                  oneRow: rows.length == 1,
                ),
              )
              .height,
        ),
      );
    }
    return constraints.constrain(Size(main, height));
  }

  @override
  void performLayout() {
    final children = getChildrenAsList();
    final widths = _baseWidths(children, constraints);
    final rows = _rows(widths, constraints);
    var main = 0.0;
    final heights = <double>[];
    for (final row in rows) {
      main = math.max(main, _rowWidth(row, widths));
      final own = [for (final i in row) widths[i]];
      _squish(own, row);
      var height = 0.0;
      for (var k = 0; k < row.length; k++) {
        final child = children[row[k]];
        child.layout(
          _childConstraints(own[k], constraints, oneRow: rows.length == 1),
          parentUsesSize: true,
        );
        height = math.max(height, child.size.height);
      }
      heights.add(height);
    }
    size = constraints.constrain(
      Size(
        main,
        heights.fold<double>(0, (a, b) => a + b) +
            (rows.length - 1) * _runSpacing,
      ),
    );
    var y = 0.0;
    for (var r = 0; r < rows.length; r++) {
      var x = 0.0;
      for (final i in rows[r]) {
        final child = children[i];
        final left = _textDirection == TextDirection.ltr
            ? x
            : size.width - x - child.size.width;
        (child.parentData! as _GroupParentData).offset = Offset(
          left,
          y + (heights[r] - child.size.height) * 0.5,
        );
        x += child.size.width + _spacing;
      }
      y += heights[r] + _runSpacing;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

// ---------------------------------------------------------------------------
// The toggle group
// ---------------------------------------------------------------------------

/// A row of toggles that is one control (shadcn's `ToggleGroup`, drawn as
/// Compose's connected `ButtonGroup` of toggle buttons): segments 2dp
/// apart, the outer corners full and the inner ones small, a pressed
/// segment's inner corners tighter and a selected one rounded out fully on
/// the toggle's spring, in the toggle button's colours. Keyboard and
/// semantics are ui_core's `DesignToggleGroup`: Tab reaches the group once,
/// at its chosen segment, the arrow keys move along it (mirrored right to
/// left), Home and End go to its ends, Space and Enter press; one choice is
/// a radio group to a screen reader. Each segment draws the state layer in
/// its own shape and, under keyboard focus, the focus ring round it.
///
/// [ExpressiveToggleGroup] picks one ([value]); [ExpressiveToggleGroup.multiple]
/// toggles each segment on its own ([values]), as a formatting bar's bold,
/// italic and underline do. With [showLabels] false a segment shows its
/// icon alone and keeps its label for assistive technology.
///
/// ```dart
/// ExpressiveToggleGroup<String>(label: 'View', segments: const [ExpressiveButtonSegment('list', 'List', icon: ExpressiveSymbols.list), ExpressiveButtonSegment('grid', 'Grid', icon: ExpressiveSymbols.gridView)], value: view, onChanged: setView)
/// ```
class ExpressiveToggleGroup<T> extends StatelessWidget {
  /// A toggle group of [segments], [value]'s chosen.
  const ExpressiveToggleGroup({
    required this.segments,
    required this._value,
    required this._onChanged,
    this.label,
    this.kind = ExpressiveToggleButtonKind.filled,
    this.size = ExpressiveButtonSize.small,
    this.showLabels = true,
    this.selectFollowsFocus = false,
    super.key,
  }) : _values = null,
       _onChangedMany = null;

  /// A toggle group whose segments each toggle on their own, [values] on.
  const ExpressiveToggleGroup.multiple({
    required this.segments,
    required Set<T> this._values,
    required ValueChanged<Set<T>>? onChanged,
    this.label,
    this.kind = ExpressiveToggleButtonKind.filled,
    this.size = ExpressiveButtonSize.small,
    this.showLabels = true,
    super.key,
  }) : _onChangedMany = onChanged,
       _value = null,
       _onChanged = null,
       selectFollowsFocus = false;

  /// The segments, start to end.
  final List<ExpressiveButtonSegment<T>> segments;

  /// What the group is called to assistive technology.
  final String? label;

  /// The segments' toggle-button kind.
  final ExpressiveToggleButtonKind kind;

  /// The size (`ConnectedButtonGroup*Tokens`).
  final ExpressiveButtonSize size;

  /// Whether segments show their labels; icons alone when false.
  final bool showLabels;

  /// Whether the arrow keys choose as they move (one choice only).
  final bool selectFollowsFocus;

  final T? _value;
  final ValueChanged<T>? _onChanged;
  final Set<T>? _values;
  final ValueChanged<Set<T>>? _onChangedMany;

  bool get _multiple => _values != null;

  ExpressiveButtonSegment<T> _segment(T value) =>
      segments.firstWhere((segment) => segment.value == value);

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final metrics = _ButtonMetrics.of(size);
    final connected = _ConnectedMetrics.of(size);
    final values = <T>[for (final segment in segments) segment.value];
    final single = _onChanged;
    final many = _onChangedMany;
    final ValueChanged<Set<T>>? onChanged = _multiple
        ? many
        : single == null
        ? null
        : (next) {
            if (next.isNotEmpty) single(next.first);
          };
    return DesignToggleGroup<T>(
      options: values,
      selected: _multiple
          ? _values!
          : <T>{if (_value != null && values.contains(_value)) _value as T},
      multiSelectionEnabled: _multiple,
      emptySelectionAllowed: _multiple,
      selectFollowsFocus: selectFollowsFocus,
      isEnabled: (value) => _segment(value).enabled,
      labelOf: (value) => _segment(value).label,
      semanticLabel: label,
      minimumSize: const Size(48, 48),
      onSelectionChanged: onChanged,
      layoutBuilder: (context, items) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0) SizedBox(width: connected.between),
            items[i],
          ],
        ],
      ),
      itemBuilder: (context, value, states) {
        final index = values.indexOf(value);
        final segment = segments[index];
        final shapes = connected.shapes(
          first: index == 0,
          last: index == values.length - 1,
        );
        final selected = states.contains(WidgetState.selected);
        final enabled = !states.contains(WidgetState.disabled);
        final paint = _togglePaint(
          t.colors,
          kind,
          enabled: enabled,
          checked: selected,
        );
        final shape = states.contains(WidgetState.pressed)
            ? shapes.pressed ?? shapes.shape
            : selected
            ? shapes.selected ?? shapes.shape
            : shapes.shape;
        final icon = segment.icon;
        return ExpressiveStateFace(
          states: states,
          shape: shape,
          color: paint.container,
          contentColor: paint.content,
          side: paint.side,
          motion: ToggleButtonBehavior.shapeMotion,
          // The segments stand 2dp apart, and the next one paints over a
          // ring outside this one: the ring stands inside, as on rows
          // stacked flush.
          focusInward: true,
          child: _ButtonContent(
            metrics: metrics,
            minWidth: 0,
            expand: false,
            textStyle: t.type
                .of(metrics.textStyle)
                .copyWith(color: paint.content),
            label: segment.label,
            content: showLabels || icon == null
                ? null
                : ExpressiveIcon(icon, selected: selected),
            leading: !showLabels || icon == null
                ? null
                : ExpressiveIcon(icon, selected: selected),
          ),
        );
      },
    );
  }
}
