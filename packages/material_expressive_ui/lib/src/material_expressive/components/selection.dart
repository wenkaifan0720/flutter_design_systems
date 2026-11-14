/// Selection controls: the checkbox (indeterminate and error included), the
/// radio button and its group, and the switch with its thumb icon (CONTRACT
/// §4.1 `checkbox`, `radio-group`, `switch`), each with a labelled row.
/// Owner: w3-selection.
///
/// Ports of Compose material3 1.5.0-alpha29's `Checkbox.kt`
/// (`TriStateCheckbox`, flag `isCheckboxStylingFixEnabled` off, the jar's
/// default), `RadioButton.kt` and `Switch.kt`: geometry and colours from the
/// generated `CheckboxTokens`, `RadioButtonTokens`, `SwitchTokens` and the
/// behaviour constants (`CheckboxBehavior`, `RadioButtonBehavior`,
/// `SwitchBehavior`), motion on the motion keys Compose names.
///
/// As in Flutter's Material and Cupertino controls, a null `onChanged` (a
/// radio's `onPressed`) disables the control at its full size: disabled
/// colours, the 48dp target kept, nothing reported. The bare mark a labelled row puts inside
/// itself (no touch target, no ripple, no focus: the row is the one
/// toggleable surface, Compose's `onCheckedChange = null`) is its own
/// constructor: [ExpressiveCheckbox.mark], [ExpressiveRadio.mark],
/// [ExpressiveSwitch.mark].
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:ui_core/ui_core.dart';

import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/list_item_shapes.dart';
import '../internal/reach.dart';
import '../internal/styled_content.dart';
import '../styling.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/checkbox_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/list_tokens.g.dart';
import '../internal/tokens/radio_button_tokens.g.dart';
import '../internal/tokens/switch_tokens.g.dart';
import '../motion.dart';
import '../spacing.dart';
import '../states.dart';
import '../theme.dart';

/// Nothing: the fill of a container Compose leaves `Color.Transparent`.
const Color _clear = expressiveTransparent;

/// The pressable a control sits in: Compose's `toggleable`/`selectable` with
/// an unbounded ripple of the state layer's radius, the 48dp touch target,
/// and no container of its own. The ripple is the ambient content colour
/// (`LocalContentColor`, `onSurface` on a surface), as Compose's
/// `ripple()` draws it when no colour is given.
Widget _controlPressable({
  required BuildContext context,
  required double stateLayerSize,
  required VoidCallback? onPressed,
  required Widget Function(BuildContext, Set<WidgetState>) builder,
  required ExpressiveComponentThemeData style,
  bool selected = false,
  FocusNode? focusNode,
  bool autofocus = false,
  OutlinedBorder? shape,
}) {
  final t = context.expressiveTheme;
  return ExpressivePressable(
    // The halo's shape: the shape scale's full step (a circle, or a
    // square under an app's square scale) unless the part is round by
    // meaning.
    shapes: ExpressivePressShapes.all(shape ?? t.shapes.full),
    motion: ExpressiveMotionKey.fastSpatial,
    color: _clear,
    contentColor: t.colors.onSurface,
    bounded: false,
    rippleRadius: stateLayerSize / 2,
    role: ExpressivePressRole.none,
    focusNode: focusNode,
    autofocus: autofocus,
    onPressed: onPressed,
    selected: selected,
    style: ExpressiveComponentThemeData(overlayColor: style.overlayColor),
    child: Builder(
      builder: (context) =>
          builder(context, ExpressiveStyleScope.maybeOf(context)!.states),
    ),
  );
}

// ---------------------------------------------------------------------------
// Checkbox
// ---------------------------------------------------------------------------

/// A Material 3 checkbox (Compose `Checkbox` and `TriStateCheckbox`): a
/// 20dp box, 2dp in from its 24dp bounds, that fills and draws its check on
/// the default spatial spring, and gathers the check into a dash when
/// [value] is null (indeterminate; only when [tristate]).
///
/// A tap reports the next value: unchecked → checked → unchecked; from
/// indeterminate, checked (Compose's "select all" pattern). [isError]
/// draws the error colours (`CheckboxTokens` `*Error*`); disabled wins.
///
/// ```dart
/// ExpressiveCheckbox(value: done, onChanged: (v) => setState(() => done = v))
/// ```
class ExpressiveCheckbox extends StatefulWidget {
  /// A checkbox showing [value], reporting a change through [onChanged].
  const ExpressiveCheckbox({
    required this.value,
    this.onChanged,
    this.tristate = false,
    this.isError = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
    super.key,
  }) : _markEnabled = true,
       _isMark = false,
       assert(tristate || value != null, 'null value needs tristate');

  /// The box alone, for a row that takes the tap itself (as
  /// [ExpressiveCheckboxRow] does): no touch target, no ripple, no focus,
  /// only the box at its 24dp with its states' colours. [enabled] false
  /// draws it disabled, for a disabled row.
  const ExpressiveCheckbox.mark({
    required this.value,
    this.tristate = false,
    bool enabled = true,
    this.isError = false,
    this.semanticLabel,
    this.style,
    super.key,
  }) : onChanged = null,
       focusNode = null,
       autofocus = false,
       _markEnabled = enabled,
       _isMark = true,
       assert(tristate || value != null, 'null value needs tristate');

  final bool _isMark;
  final bool _markEnabled;

  /// Stateful visual overrides for this control or labelled row.
  final ExpressiveComponentThemeData? style;

  /// Checked (true), unchecked (false) or indeterminate (null, [tristate]).
  final bool? value;

  /// Told the next value on a tap; null disables the box at its full size,
  /// as Flutter's `Checkbox` does. For a box inside a row that takes the
  /// tap, use [ExpressiveCheckbox.mark].
  final ValueChanged<bool>? onChanged;

  /// Whether [value] may be null (Compose's `TriStateCheckbox`).
  final bool tristate;

  /// Whether it is enabled: it has [onChanged]; a [ExpressiveCheckbox.mark]
  /// as its row says.
  bool get enabled => _isMark ? _markEnabled : onChanged != null;

  /// Whether to draw the error colours.
  final bool isError;

  /// What a screen reader says for the box on its own.
  final String? semanticLabel;

  /// The focus node; one is made when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  @override
  State<ExpressiveCheckbox> createState() => _ExpressiveCheckboxState();
}

class _ExpressiveCheckboxState extends State<ExpressiveCheckbox>
    with TickerProviderStateMixin {
  late final AnimationController _draw = AnimationController.unbounded(
    vsync: this,
    value: widget.value == false ? 0 : 1,
  );
  late final AnimationController _gravitation = AnimationController.unbounded(
    vsync: this,
    value: widget.value == null ? 1 : 0,
  );

  @override
  void didUpdateWidget(ExpressiveCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    final from = oldWidget.value;
    final to = widget.value;
    if (from == to) return;
    // Compose's transitions: from Off the check draws on the default
    // spatial spring and the dash snaps to place; to Off the check stays
    // and fades with the box (its colour goes clear); between checked and
    // indeterminate the points gather or part on the spring.
    if (to == false) return;
    final spring = ExpressiveMotion.of(context)
        .spring(CheckboxBehavior.checkMotion);
    final gravitation = to == null ? 1.0 : 0.0;
    if (from == false) {
      _draw.value = 0;
      _draw.springTo(1, spring);
      _gravitation.value = gravitation;
    } else {
      _gravitation.springTo(gravitation, spring);
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    _gravitation.dispose();
    super.dispose();
  }

  void _toggle() => widget.onChanged?.call(widget.value != true);

  /// Enabled: [ExpressiveCheckbox.enabled], and a handler unless a mark.
  bool get _enabled =>
      widget.enabled && (widget._isMark || widget.onChanged != null);

  Widget _mark(BuildContext context, Set<WidgetState> interaction) {
    final t = context.expressiveTheme;
    final states = <WidgetState>{
      ...interaction,
      if (!_enabled) WidgetState.disabled,
      if (widget.value != false) WidgetState.selected,
      if (widget.isError) WidgetState.error,
    };
    final style = t.checkboxTheme.merge(widget.style);
    final c = context.expressiveTheme.colors;
    final state = widget.value;
    final enabled = _enabled;
    final on = state != false;
    final error = widget.isError && enabled;
    final selectedDisabled = c
        .role(CheckboxTokens.selectedDisabledContainerColor)
        .withValues(alpha: CheckboxTokens.selectedDisabledContainerOpacity);

    // CheckboxColors.checkmarkColor(state) (flag off: the same enabled or
    // not), boxColor(enabled, state), borderColor(enabled, state).
    final Color tokenCheck = on
        ? c.role(
            error
                ? CheckboxTokens.selectedErrorIconColor
                : CheckboxTokens.selectedIconColor,
          )
        : _clear;
    Color box;
    Color border;
    if (enabled) {
      final checked = c.role(
        error
            ? CheckboxTokens.selectedErrorContainerColor
            : CheckboxTokens.selectedContainerColor,
      );
      box = on ? checked : _clear;
      border = on
          ? checked
          : c.role(
              error
                  ? CheckboxTokens.unselectedErrorOutlineColor
                  : CheckboxTokens.unselectedOutlineColor,
            );
    } else {
      box = on ? selectedDisabled : _clear;
      border = on
          ? selectedDisabled
          : c
                .role(CheckboxTokens.unselectedDisabledOutlineColor)
                .withValues(
                  alpha: CheckboxTokens.unselectedDisabledContainerOpacity,
                );
    }
    final check = style.foregroundColor?.resolve(states) ?? tokenCheck;
    box = style.backgroundColor?.resolve(states) ?? box;
    border =
        style.side?.resolve(states)?.color ??
        style.outline?.resolve(states) ??
        border;
    final shape = style.shape?.resolve(states);
    final inset =
        shape
            ?.copyWith(
              side: BorderSide(
                width:
                    style.side?.resolve(states)?.width ??
                    CheckboxBehavior.strokeWidth,
              ),
            )
            .dimensions
            .resolve(Directionality.of(context)) ??
        EdgeInsets.zero;
    final glyphSize =
        style.iconSize?.resolve(states) ?? CheckboxBehavior.boxSize;
    final minimum = style.minimumSize?.resolve(states) ?? Size.zero;
    final markSize = Size(
      math.max(minimum.width, glyphSize + inset.horizontal),
      math.max(minimum.height, glyphSize + inset.vertical),
    );
    // Box in on the default effects spring, box out on the fast one; no
    // animation between enabled and disabled (a new spring per state).
    final colorMotion = on
        ? CheckboxBehavior.boxInColorMotion
        : CheckboxBehavior.boxOutColorMotion;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final stroke =
        ((style.side?.resolve(states)?.width ?? CheckboxBehavior.strokeWidth) *
                dpr)
            .floorToDouble() /
        dpr;

    Widget painted = ExpressiveSpringColor(
      value: check,
      motion: colorMotion,
      builder: (context, check, _) => ExpressiveSpringColor(
        key: ValueKey<bool>(enabled),
        value: box,
        motion: colorMotion,
        builder: (context, box, _) => ExpressiveSpringColor(
          key: ValueKey<bool>(enabled),
          value: border,
          motion: colorMotion,
          builder: (context, border, _) => AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_draw, _gravitation]),
            builder: (context, _) => CustomPaint(
              size: markSize,
              painter: _CheckboxPainter(
                box: box,
                border: border,
                check: check,
                draw: _draw.value,
                gravitation: _gravitation.value,
                stroke: stroke,
                radius: CheckboxBehavior.cornerRadius,
                shape: shape,
                inset: inset,
              ),
            ),
          ),
        ),
      ),
    );
    painted = Padding(
      padding:
          style.padding?.resolve(states) ??
          t.density.padding(const EdgeInsets.all(CheckboxBehavior.boxPadding)),
      child: painted,
    );
    painted = Semantics(
      checked: state == true,
      mixed: state == null ? true : null,
      enabled: enabled,
      label: widget.semanticLabel,
      child: painted,
    );
    return painted;
  }

  @override
  Widget build(BuildContext context) {
    if (widget._isMark) return _mark(context, const {});
    return _controlPressable(
      context: context,
      stateLayerSize: CheckboxTokens.stateLayerSize,
      onPressed: _enabled ? _toggle : null,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      selected: widget.value != false,
      style: context.expressiveTheme.checkboxTheme.merge(widget.style),
      builder: _mark,
    );
  }
}

/// Compose's `drawBox` and `drawCheck` (flag off).
class _CheckboxPainter extends CustomPainter {
  _CheckboxPainter({
    required this.box,
    required this.border,
    required this.check,
    required this.draw,
    required this.gravitation,
    required this.stroke,
    required this.radius,
    this.shape,
    this.inset = EdgeInsets.zero,
  });

  final Color box;
  final Color border;
  final Color check;
  final double draw;
  final double gravitation;
  final double stroke;
  final double radius;
  final OutlinedBorder? shape;
  final EdgeInsets inset;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final half = stroke / 2;
    if (shape != null) {
      canvas.drawPath(
        shape!.getOuterPath(Offset.zero & size),
        Paint()..color = box,
      );
      shape!
          .copyWith(
            side: BorderSide(color: border, width: stroke),
          )
          .paint(canvas, Offset.zero & size);
    } else if (box == border) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
        Paint()..color = box,
      );
    } else {
      final inner = width - stroke * 2;
      final outline = width - stroke;
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(stroke, stroke, inner, inner),
            Radius.circular(math.max(0, radius - stroke)),
          ),
          Paint()..color = box,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(half, half, outline, outline),
            Radius.circular(math.max(0, radius - half)),
          ),
          Paint()
            ..color = border
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke,
        );
    }
    final fraction = draw.clamp(0.0, 1.0);
    if (fraction <= 0 || check.a == 0) return;
    final content = inset.deflateRect(Offset.zero & size);
    final glyph = math.min(content.width, content.height);
    final origin = content.center - Offset(glyph / 2, glyph / 2);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    const center = CheckboxBehavior.checkCenter;
    double gravitate(double a) => a + (center - a) * gravitation;
    final path = Path()
      ..moveTo(
        glyph * CheckboxBehavior.checkLeftX,
        glyph * gravitate(CheckboxBehavior.checkLeftY),
      )
      ..lineTo(
        glyph * gravitate(CheckboxBehavior.checkCrossX),
        glyph * gravitate(CheckboxBehavior.checkCrossY),
      )
      ..lineTo(
        glyph * CheckboxBehavior.checkRightX,
        glyph * gravitate(CheckboxBehavior.checkRightY),
      );
    // PathMeasure.getSegment(0, length × fraction) over the one contour.
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * fraction),
      Paint()
        ..color = check
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.square,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CheckboxPainter old) =>
      old.box != box ||
      old.border != border ||
      old.check != check ||
      old.draw != draw ||
      old.gravitation != gravitation ||
      old.stroke != stroke ||
      old.radius != radius ||
      old.shape != shape ||
      old.inset != inset;
}

// ---------------------------------------------------------------------------
// Radio button and group
// ---------------------------------------------------------------------------

/// A Material 3 radio button (Compose `RadioButton`): a 20dp ring whose
/// 12dp dot grows on the fast spatial spring when [selected], its colour
/// on the default effects spring.
///
/// ```dart
/// ExpressiveRadio(selected: plan == 'monthly', onPressed: () => setState(() => plan = 'monthly'))
/// ```
class ExpressiveRadio extends StatelessWidget {
  /// A radio button, on when [selected].
  const ExpressiveRadio({
    required this.selected,
    this.onPressed,
    this.enabled = true,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
    super.key,
  }) : _isMark = false;

  /// The ring alone, for a row that takes the tap itself (as
  /// [ExpressiveRadioRow] does): no touch target, no ripple, no focus,
  /// only the ring at its 20dp with its states' colours. [enabled] false
  /// draws it disabled, for a disabled row.
  const ExpressiveRadio.mark({
    required this.selected,
    this.enabled = true,
    this.semanticLabel,
    this.style,
    super.key,
  }) : onPressed = null,
       focusNode = null,
       autofocus = false,
       _isMark = true;

  final bool _isMark;

  /// Stateful visual overrides for this control or labelled row.
  final ExpressiveComponentThemeData? style;

  /// Whether this option is the group's selection.
  final bool selected;

  /// What a tap does (select this option); null disables the radio at its
  /// full size, as Flutter's `Radio` does. For a ring inside a row that
  /// takes the tap, use [ExpressiveRadio.mark].
  final VoidCallback? onPressed;

  /// Whether the radio takes input; disabled colours when false, at the
  /// same size (its 48dp target stays), as with a null [onPressed].
  final bool enabled;

  /// What a screen reader says for the radio on its own.
  final String? semanticLabel;

  /// The focus node; one is made when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Enabled: [enabled], and a handler unless a mark.
  bool get _enabled => enabled && (_isMark || onPressed != null);

  Widget _mark(BuildContext context, Set<WidgetState> interaction) {
    final t = context.expressiveTheme;
    final enabled = _enabled;
    final states = <WidgetState>{
      ...interaction,
      if (!enabled) WidgetState.disabled,
      if (selected) WidgetState.selected,
    };
    final resolved = t.radioTheme.merge(style);
    final shape = resolved.shape?.resolve(states);
    final inset =
        shape
            ?.copyWith(
              side: BorderSide(
                width:
                    resolved.side?.resolve(states)?.width ??
                    RadioButtonBehavior.strokeWidth,
              ),
            )
            .dimensions
            .resolve(Directionality.of(context)) ??
        EdgeInsets.zero;
    final glyphSize =
        resolved.iconSize?.resolve(states) ?? RadioButtonTokens.iconSize;
    final minimum = resolved.minimumSize?.resolve(states) ?? Size.zero;
    final markSize = Size(
      math.max(minimum.width, glyphSize + inset.horizontal),
      math.max(minimum.height, glyphSize + inset.vertical),
    );
    final c = context.expressiveTheme.colors;
    // RadioButtonColors.radioColor(enabled, selected).
    Color color;
    if (enabled) {
      color = c.role(
        selected
            ? RadioButtonTokens.selectedIconColor
            : RadioButtonTokens.unselectedIconColor,
      );
    } else if (selected) {
      color = c
          .role(RadioButtonTokens.disabledSelectedIconColor)
          .withValues(alpha: RadioButtonTokens.disabledSelectedIconOpacity);
    } else {
      color = c
          .role(RadioButtonTokens.disabledUnselectedIconColor)
          .withValues(alpha: RadioButtonTokens.disabledUnselectedIconOpacity);
    }
    color = resolved.foregroundColor?.resolve(states) ?? color;
    final side =
        resolved.side?.resolve(states) ??
        BorderSide(
          color: resolved.outline?.resolve(states) ?? color,
          width: RadioButtonBehavior.strokeWidth,
        );
    Widget ring(Color color) => ExpressiveSpringValue(
      value: selected ? RadioButtonBehavior.dotSize / 2 : 0,
      motion: RadioButtonBehavior.dotMotion,
      builder: (context, dot, _) => CustomPaint(
        size: markSize,
        painter: _RadioPainter(
          color: color,
          dotRadius: dot,
          stroke: side.width,
          outline: side.color,
          fill: resolved.backgroundColor?.resolve(states) ?? _clear,
          shape: shape,
          inset: inset,
        ),
      ),
    );
    // Colour springs while enabled; disabled snaps (Compose's
    // rememberUpdatedState).
    Widget painted = enabled
        ? ExpressiveSpringColor(
            value: color,
            motion: RadioButtonBehavior.colorMotion,
            builder: (context, color, _) => ring(color),
          )
        : ring(color);
    // The ring is drawn inset in its slot (the padding and the painter's
    // inset): marked, the checks read the radio by its slot, as they read a
    // leading icon by its box.
    painted = DesignKeylineFace(
      child: Padding(
        padding:
            resolved.padding?.resolve(states) ??
            t.density.padding(
              const EdgeInsets.all(RadioButtonBehavior.padding),
            ),
        child: painted,
      ),
    );
    painted = Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: true,
      enabled: enabled,
      label: semanticLabel,
      child: painted,
    );
    return painted;
  }

  @override
  Widget build(BuildContext context) {
    if (_isMark) return _mark(context, const {});
    return _controlPressable(
      context: context,
      stateLayerSize: RadioButtonTokens.stateLayerSize,
      onPressed: _enabled ? onPressed : null,
      focusNode: focusNode,
      autofocus: autofocus,
      selected: selected,
      style: context.expressiveTheme.radioTheme.merge(style),
      // A radio is a circle in every family, so it never reads as a
      // checkbox; its halo is a circle too.
      shape: const CircleBorder(),
      builder: _mark,
    );
  }
}

class _RadioPainter extends CustomPainter {
  _RadioPainter({
    required this.color,
    required this.dotRadius,
    required this.stroke,
    required this.outline,
    required this.fill,
    this.shape,
    this.inset = EdgeInsets.zero,
  });

  final Color color;
  final double dotRadius;
  final double stroke;
  final Color outline;
  final Color fill;
  final OutlinedBorder? shape;
  final EdgeInsets inset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (shape != null) {
      canvas.drawPath(
        shape!.getOuterPath(Offset.zero & size),
        Paint()..color = fill,
      );
      shape!
          .copyWith(
            side: BorderSide(color: outline, width: stroke),
          )
          .paint(canvas, Offset.zero & size);
    } else {
      canvas.drawCircle(center, size.width / 2, Paint()..color = fill);
      canvas.drawCircle(
        center,
        size.width / 2 - stroke / 2,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }
    if (dotRadius > 0) {
      canvas.drawCircle(
        center,
        math.max(
          0,
          math.min(
            dotRadius - stroke / 2,
            inset.deflateRect(Offset.zero & size).shortestSide / 2,
          ),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RadioPainter old) =>
      old.color != color ||
      old.dotRadius != dotRadius ||
      old.stroke != stroke ||
      old.outline != outline ||
      old.fill != fill ||
      old.shape != shape ||
      old.inset != inset;
}

/// One option of an [ExpressiveRadioGroup].
@immutable
class ExpressiveRadioOption<T> {
  /// An option standing for [value], labelled [label].
  const ExpressiveRadioOption({
    required this.value,
    required this.label,
    this.supportingText,
    this.enabled = true,
  });

  /// What choosing the option selects.
  final T value;

  /// The option's label.
  final String label;

  /// A second line under the label.
  final String? supportingText;

  /// Whether the option can be chosen.
  final bool enabled;
}

/// A Material 3 radio group: its options as [ExpressiveRadioRow]s, one of
/// them [value], each row the whole touch target (Compose's
/// `Modifier.selectableGroup()` over `Modifier.selectable` rows, the
/// pattern Material's guidance gives).
///
/// ```dart
/// ExpressiveRadioGroup<String>(value: plan, onChanged: (v) => setState(() => plan = v), options: const [ExpressiveRadioOption(value: 'monthly', label: 'Monthly'), ExpressiveRadioOption(value: 'yearly', label: 'Yearly')])
/// ```
class ExpressiveRadioGroup<T> extends StatelessWidget {
  /// A radio group of [options] with [value] chosen.
  const ExpressiveRadioGroup({
    required this.options,
    required this.value,
    this.onChanged,
    this.semanticLabel,
    this.contentPadding,
    this.style,
    super.key,
  });

  /// Stateful visual overrides for this control or labelled row.
  final ExpressiveComponentThemeData? style;

  /// Each row's [ExpressiveRadioRow.contentPadding]: [EdgeInsets.zero]
  /// puts each radio's ring on the group's start edge, for a group in a
  /// padded column.
  final EdgeInsetsGeometry? contentPadding;

  /// The options, top to bottom.
  final List<ExpressiveRadioOption<T>> options;

  /// The selected option's value; none selected when no option has it.
  final T? value;

  /// Told the chosen option's value; null disables the group.
  final ValueChanged<T>? onChanged;

  /// Whether it takes input: false when onChanged is null, as in Flutter.
  bool get enabled => onChanged != null;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: semanticLabel,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final option in options)
          ExpressiveRadioRow(
            style: style,
            contentPadding: contentPadding,
            label: option.label,
            supportingText: option.supportingText,
            selected: option.value == value,
            enabled: enabled && option.enabled,
            onPressed: onChanged == null
                ? null
                : () => onChanged!(option.value),
          ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Switch
// ---------------------------------------------------------------------------

/// A Material 3 switch (Compose `Switch`): a 52 × 32dp track whose thumb
/// grows from 16dp to 24dp when checked (or when it carries an icon) and to
/// 28dp while pressed — at once, as Compose snaps it — then moves and
/// resizes on the fast spatial spring (`SwitchBehavior.thumbMotion`).
///
/// [checkedIcon] and [uncheckedIcon] are the thumb's content in each state
/// (Compose's `thumbContent`): an `Icon`, given the 16dp size
/// (`SwitchDefaults.IconSize`) and the switch's icon colour.
///
/// ```dart
/// ExpressiveSwitch(value: alerts, onChanged: (v) => setState(() => alerts = v), checkedIcon: const Icon(ExpressiveSymbols.check))
/// ```
class ExpressiveSwitch extends StatefulWidget {
  /// A switch showing [value], reporting a change through [onChanged].
  const ExpressiveSwitch({
    required this.value,
    this.onChanged,
    this.checkedIcon,
    this.uncheckedIcon,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
    super.key,
  }) : _markEnabled = true,
       _isMark = false;

  /// The switch alone, for a row that takes the tap itself (as
  /// [ExpressiveSwitchRow] does): no touch target, no ripple, no focus, no
  /// drag, only the 52 x 32dp track and thumb with its states' colours.
  /// [enabled] false draws it disabled, for a disabled row.
  const ExpressiveSwitch.mark({
    required this.value,
    bool enabled = true,
    this.checkedIcon,
    this.uncheckedIcon,
    this.semanticLabel,
    this.style,
    super.key,
  }) : onChanged = null,
       focusNode = null,
       autofocus = false,
       _markEnabled = enabled,
       _isMark = true;

  final bool _isMark;
  final bool _markEnabled;

  /// Stateful visual overrides for this control or labelled row.
  final ExpressiveComponentThemeData? style;

  /// Whether the switch is on.
  final bool value;

  /// Told the next value on a tap or a drag across; null disables the
  /// switch at its full size, as Flutter's `Switch` does. For a switch
  /// inside a row that takes the tap, use [ExpressiveSwitch.mark].
  final ValueChanged<bool>? onChanged;

  /// Whether it is enabled: it has [onChanged]; a [ExpressiveSwitch.mark]
  /// as its row says.
  bool get enabled => _isMark ? _markEnabled : onChanged != null;

  /// The thumb's content while on: an icon, sized 16dp and coloured by
  /// the switch (Compose's `thumbContent`).
  final Widget? checkedIcon;

  /// The thumb's content while off.
  final Widget? uncheckedIcon;

  /// What a screen reader says for the switch on its own.
  final String? semanticLabel;

  /// The focus node; one is made when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  @override
  State<ExpressiveSwitch> createState() => _ExpressiveSwitchState();
}

/// The thumb's geometry along the track (Compose's `ThumbNode.measure`),
/// in dp.
abstract final class _Thumb {
  static const double width = SwitchTokens.trackWidth;
  static const double height = SwitchTokens.trackHeight;
  static const double outline = SwitchTokens.trackOutlineWidth;
  static const double diameter = SwitchTokens.selectedHandleWidth;
  static const double uncheckedDiameter = SwitchTokens.unselectedHandleWidth;
  static const double pressedDiameter = SwitchTokens.pressedHandleWidth;

  /// `ThumbPadding`.
  static double get padding => (height - diameter) / 2;

  /// `maxBound`: the checked thumb's start.
  static double get maxBound => (width - diameter) - padding;

  /// The thumb's diameter.
  static double size({
    required bool pressed,
    required bool checked,
    required bool hasContent,
  }) {
    if (pressed) return pressedDiameter;
    return hasContent || checked ? diameter : uncheckedDiameter;
  }

  /// The thumb's start offset for a thumb of [size].
  static double offset({
    required bool pressed,
    required bool checked,
    required double size,
  }) {
    if (pressed) return checked ? maxBound - outline : outline;
    return checked ? maxBound : (height - size) / 2;
  }
}

class _ExpressiveSwitchState extends State<ExpressiveSwitch>
    with TickerProviderStateMixin {
  final WidgetStatesController _states = WidgetStatesController();
  late final AnimationController _offset;
  late final AnimationController _size;
  bool _pressed = false;
  Set<WidgetState> _visualStates = {};
  double? _drag;

  bool get _interactive => widget.onChanged != null && widget.enabled;

  bool get _hasContent =>
      (widget.value ? widget.checkedIcon : widget.uncheckedIcon) != null;

  bool get _held => _pressed || _pointerDown || _drag != null;

  /// A finger or button down on the switch: pressed at once, as Compose's
  /// press interaction (the ink's own tap waits out the drag in the arena).
  bool _pointerDown = false;

  void _pointer(bool down) {
    if (down == _pointerDown || !mounted) return;
    setState(() => _pointerDown = down);
    _retarget();
  }

  @override
  void initState() {
    super.initState();
    final size = _targetSize;
    _size = AnimationController.unbounded(vsync: this, value: size);
    _offset = AnimationController.unbounded(
      vsync: this,
      value: _targetOffset(size),
    );
    _states.addListener(_statesChanged);
  }

  double get _targetSize => _Thumb.size(
    pressed: _held,
    checked: widget.value,
    hasContent: _hasContent,
  );

  double _targetOffset(double size) =>
      _Thumb.offset(pressed: _held, checked: widget.value, size: size);

  /// Moves the thumb to where its state puts it: at once while pressed or
  /// dragged (Compose's `SnapSpec`), else on the fast spatial spring.
  void _retarget() {
    final size = _targetSize;
    final offset = _drag ?? _targetOffset(size);
    if (_held) {
      _size.value = size;
      _offset.value = offset;
      return;
    }
    final spring = ExpressiveMotion.of(context)
        .spring(SwitchBehavior.thumbMotion);
    if (_size.value != size) _size.springTo(size, spring);
    if (_offset.value != offset) _offset.springTo(offset, spring);
  }

  void _statesChanged() {
    final pressed = _states.value.contains(WidgetState.pressed);
    final visual = _states.value
        .where(
          (s) =>
              s == WidgetState.pressed ||
              s == WidgetState.hovered ||
              s == WidgetState.focused,
        )
        .toSet();
    if (!mounted || setEquals(visual, _visualStates)) return;
    setState(() {
      _pressed = pressed;
      _visualStates = visual;
    });
    _retarget();
  }

  @override
  void didUpdateWidget(ExpressiveSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive) {
      _pressed = false;
      _pointerDown = false;
      _drag = null;
    }
    _retarget();
  }

  @override
  void dispose() {
    _states
      ..removeListener(_statesChanged)
      ..dispose();
    _offset.dispose();
    _size.dispose();
    super.dispose();
  }

  void _toggle() => widget.onChanged?.call(!widget.value);

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  double get _low => _Thumb.outline;

  double get _high => _Thumb.maxBound - _Thumb.outline;

  void _dragStart(DragStartDetails _) {
    setState(() => _drag = widget.value ? _high : _low);
    _retarget();
  }

  void _dragUpdate(DragUpdateDetails details) {
    final delta = _rtl ? -details.delta.dx : details.delta.dx;
    setState(() => _drag = ((_drag ?? _low) + delta).clamp(_low, _high));
    _retarget();
  }

  void _dragEnd(DragEndDetails _) {
    final drag = _drag;
    if (drag == null) return;
    final next = drag > (_low + _high) / 2;
    setState(() => _drag = null);
    if (next != widget.value) {
      widget.onChanged?.call(next);
    } else {
      _retarget();
    }
  }

  void _dragCancel() {
    setState(() => _drag = null);
    _retarget();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final checked = widget.value;
    // Enabled: [ExpressiveSwitch.enabled], and a handler unless a mark.
    final enabled =
        widget.enabled && (widget._isMark || widget.onChanged != null);
    final states = <WidgetState>{
      ..._visualStates,
      if (!enabled) WidgetState.disabled,
      if (checked) WidgetState.selected,
      if (_drag != null) WidgetState.dragged,
    };
    final style = t.switchTheme.merge(widget.style);
    Color disabled(ExpressiveColorRole role, double alpha) =>
        Color.alphaBlend(c.role(role).withValues(alpha: alpha), c.surface);
    // SwitchColors: thumb, track, border, icon by (enabled, checked).
    // Compose draws them as given: no colour animation.
    final Color thumb;
    Color track;
    Color border;
    Color icon;
    if (enabled) {
      thumb = c.role(
        checked
            ? SwitchTokens.selectedHandleColor
            : SwitchTokens.unselectedHandleColor,
      );
      track = c.role(
        checked
            ? SwitchTokens.selectedTrackColor
            : SwitchTokens.unselectedTrackColor,
      );
      border = checked
          ? _clear
          : c.role(SwitchTokens.unselectedFocusTrackOutlineColor);
      icon = c.role(
        checked
            ? SwitchTokens.selectedIconColor
            : SwitchTokens.unselectedIconColor,
      );
    } else if (checked) {
      thumb = disabled(
        SwitchTokens.disabledSelectedHandleColor,
        SwitchTokens.disabledSelectedHandleOpacity,
      );
      track = disabled(
        SwitchTokens.disabledSelectedTrackColor,
        SwitchTokens.disabledTrackOpacity,
      );
      border = _clear;
      icon = disabled(
        SwitchTokens.disabledSelectedIconColor,
        SwitchTokens.disabledSelectedIconOpacity,
      );
    } else {
      thumb = disabled(
        SwitchTokens.disabledUnselectedHandleColor,
        SwitchTokens.disabledUnselectedHandleOpacity,
      );
      track = disabled(
        SwitchTokens.disabledUnselectedTrackColor,
        SwitchTokens.disabledTrackOpacity,
      );
      border = disabled(
        SwitchTokens.disabledUnselectedTrackOutlineColor,
        SwitchTokens.disabledTrackOpacity,
      );
      icon = disabled(
        SwitchTokens.disabledUnselectedIconColor,
        SwitchTokens.disabledUnselectedIconOpacity,
      );
    }
    final glyph = checked ? widget.checkedIcon : widget.uncheckedIcon;
    track = style.backgroundColor?.resolve(states) ?? track;
    border = style.outline?.resolve(states) ?? border;
    icon = style.foregroundColor?.resolve(states) ?? icon;
    final side =
        style.side?.resolve(states) ??
        BorderSide(color: border, width: _Thumb.outline);
    final customShape = style.shape?.resolve(states);
    final trackShape = customShape ?? t.shapes.of(SwitchTokens.trackShape);
    final inset =
        customShape
            ?.copyWith(side: side)
            .dimensions
            .resolve(Directionality.of(context)) ??
        EdgeInsets.zero;
    final minimum = style.minimumSize?.resolve(states) ?? Size.zero;
    final trackSize = Size(
      math.max(
        minimum.width,
        math.max(
          t.density.width(_Thumb.width),
          _Thumb.pressedDiameter + inset.horizontal + 16,
        ),
      ),
      math.max(
        minimum.height,
        math.max(
          t.density.height(_Thumb.height),
          _Thumb.pressedDiameter + inset.vertical,
        ),
      ),
    );
    final nativeThumb = t.shapes.of(SwitchTokens.handleShape);
    OutlinedBorder thumbShape(Rect rect) {
      if (customShape == null) return nativeThumb;
      final outer = customShape is ExpressiveContentBorder
          ? customShape.outline
          : customShape;
      final gap = math.max(0.0, (trackSize.height - rect.height) / 2);
      if (outer is RoundedRectangleBorder) {
        final radius = outer.borderRadius.resolve(Directionality.of(context));
        Radius inner(Radius r) =>
            Radius.elliptical(math.max(0, r.x - gap), math.max(0, r.y - gap));
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: inner(radius.topLeft),
            topRight: inner(radius.topRight),
            bottomLeft: inner(radius.bottomLeft),
            bottomRight: inner(radius.bottomRight),
          ),
        );
      }
      return outer;
    }

    final rtl = _rtl;

    // Compose's ThumbNode measures and places the thumb in whole device
    // pixels, truncating its animated size and offset (`toInt()`), and
    // centres it vertically rounded (`Alignment.CenterStart`).
    final dpr = MediaQuery.devicePixelRatioOf(context);
    Rect thumbRect(Size box) {
      final size = (_size.value * dpr).truncateToDouble();
      final baseSize = _size.value;
      final span = (_Thumb.width - baseSize);
      final fraction = span <= 0 ? 0.0 : _offset.value / span;
      final safe = rtl ? inset.right : inset.left;
      final travel = math.max(0.0, box.width - baseSize - inset.horizontal);
      final start =
          (customShape == null && box.width == _Thumb.width
              ? _offset.value
              : safe + fraction * travel) *
          dpr;
      final pixelStart = start.truncateToDouble();
      final width = box.width * dpr;
      final left = rtl ? width - pixelStart - size : pixelStart;
      final top = ((box.height * dpr - size) / 2).roundToDouble();
      return Rect.fromLTWH(left / dpr, top / dpr, size / dpr, size / dpr);
    }

    final Widget visual = SizedBox(
      width: trackSize.width,
      height: trackSize.height,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: track,
          shape: trackShape.copyWith(side: side),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_offset, _size]),
          builder: (context, _) => CustomSingleChildLayout(
            delegate: _ThumbLayout(thumbRect),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: thumb,
                shape: thumbShape(thumbRect(trackSize)),
              ),
              child: glyph == null
                  ? const SizedBox.expand()
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(ExpressiveSpacing.s4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: IconTheme.merge(
                            data: IconThemeData(
                              size:
                                  style.iconSize?.resolve(states) ??
                                  SwitchTokens.selectedIconSize,
                              color: icon,
                            ),
                            child: glyph,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );

    // A stretching parent (a form's column) keeps the switch its own size,
    // at the start under its label: forced wide, the track, the thumb's
    // travel, its halo and the ring all took the parent's width. Inside the
    // semantics, so the switch's own node still says what it is.
    Widget own(Widget child) => Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: child,
    );
    if (widget._isMark) {
      return Semantics(
        toggled: checked,
        enabled: enabled,
        label: widget.semanticLabel,
        child: own(
          Padding(
            padding: style.padding?.resolve(states) ?? EdgeInsets.zero,
            child: visual,
          ),
        ),
      );
    }
    return MergeSemantics(
      child: Semantics(
        container: true,
        toggled: checked,
        enabled: enabled,
        label: widget.semanticLabel,
        child: own(
          Listener(
            onPointerDown: _interactive ? (_) => _pointer(true) : null,
            onPointerUp: (_) => _pointer(false),
            onPointerCancel: (_) => _pointer(false),
            child: GestureDetector(
              onHorizontalDragStart: _interactive ? _dragStart : null,
              onHorizontalDragUpdate: _interactive ? _dragUpdate : null,
              onHorizontalDragEnd: _interactive ? _dragEnd : null,
              onHorizontalDragCancel: _interactive ? _dragCancel : null,
              // Press feedback is the pressable's ink alone, over the thumb
              // (Compose's thumb carries its `indication` before its
              // `background`): `ripple(bounded = false, radius =
              // StateLayerSize / 2)` centred on the thumb while the toggleable
              // is the whole switch.
              child: ExpressivePressable(
                style: ExpressiveComponentThemeData(
                  overlayColor: style.overlayColor,
                ),
                selected: checked,
                shapes: ExpressivePressShapes.all(trackShape),
                motion: SwitchBehavior.thumbMotion,
                color: _clear,
                contentColor: c.onSurface,
                bounded: false,
                rippleRadius: SwitchTokens.stateLayerSize / 2,
                inkRect: thumbRect,
                role: ExpressivePressRole.none,
                focusNode: widget.focusNode,
                autofocus: widget.autofocus,
                statesController: _states,
                onPressed: _interactive ? _toggle : null,
                child: Padding(
                  padding: style.padding?.resolve(states) ?? EdgeInsets.zero,
                  child: visual,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Places the thumb at the rect its springs give.
class _ThumbLayout extends SingleChildLayoutDelegate {
  _ThumbLayout(this.rectOf);

  final Rect Function(Size box) rectOf;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.tight(rectOf(constraints.biggest).size);

  @override
  Offset getPositionForChild(Size size, Size childSize) => rectOf(size).topLeft;

  @override
  bool shouldRelayout(_ThumbLayout oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// Labelled rows
// ---------------------------------------------------------------------------

/// The row a labelled control lives in (Material's guidance for Compose:
/// `Modifier.toggleable`/`selectable` on a full-width row, the control
/// inside with no handler of its own): one line of `ListTokens`' height,
/// the list's start and end space, the label in `bodyLarge`. Its highlight
/// is the interactive list item's ([ExpressiveListTile]'s
/// `ListItemShapes`): 4dp corners at rest, 12dp hovered, 16dp focused and
/// pressed, never a square over the row.
class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.label,
    required this.control,
    required this.role,
    required this.selected,
    required this.enabled,
    required this.onPressed,
    this.supportingText,
    this.controlLeads = true,
    this.contentPadding,
    this.controlInset = 0,
    this.style,
    required this.focusNode,
    required this.autofocus,
  });

  final String label;
  final String? supportingText;
  final Widget control;

  /// The row's start and end space ([ExpressiveRadioRow.contentPadding]).
  final EdgeInsetsGeometry? contentPadding;

  /// How far the control's visible mark sits inside its own box (its
  /// padding), so a [contentPadding] measures to the mark, not the box.
  final double controlInset;
  final ExpressivePressRole role;
  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;
  final bool controlLeads;
  final ExpressiveComponentThemeData? style;

  /// The focus node of its press target; null lets the target keep its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final row = _row(context);
    final padding = contentPadding;
    if (padding == null) return row;
    final direction = Directionality.of(context);
    final p = padding.resolve(direction);
    final (padStart, padEnd) = direction == TextDirection.ltr
        ? (p.left, p.right)
        : (p.right, p.left);
    final lead = controlLeads ? controlInset : 0.0;
    final trail = controlLeads ? 0.0 : controlInset;
    // The row keeps the list's space inside it; it reaches past its edges
    // by what the padding leaves of that space, and pads by any beyond it.
    final start = ListTokens.itemLeadingSpace + lead - padStart;
    final end = ListTokens.itemTrailingSpace + trail - padEnd;
    final reach = ExpressiveReach(
      start: math.max(0, start),
      end: math.max(0, end),
      child: row,
    );
    return start >= 0 && end >= 0
        ? reach
        : Padding(
            padding: EdgeInsetsDirectional.only(
              start: math.max(0, -start),
              end: math.max(0, -end),
            ),
            child: reach,
          );
  }

  Widget _row(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    // Disabled text: onSurface at the disabled content opacity.
    Color muted(Color color) => enabled
        ? color
        : c.onSurface.withValues(
            alpha: CheckboxTokens.unselectedDisabledContainerOpacity,
          );
    Widget headline(ExpressiveStyleScope scope) => Text(
      label,
      style: t.type
          .of(ExpressiveTypeKey.bodyLarge)
          .merge(scope.style.textStyle?.resolve(scope.states))
          .copyWith(
            color:
                scope.style.foregroundColor?.resolve(scope.states) ??
                muted(c.onSurface),
          ),
    );
    // A one-line row's label by its capitals on the row's middle, as a
    // list row's one-line headline is.
    Widget text(ExpressiveStyleScope scope) => supportingText == null
        ? expressiveFaceLabel(headline(scope))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: t.type
                    .of(ExpressiveTypeKey.bodyLarge)
                    .merge(scope.style.textStyle?.resolve(scope.states))
                    .copyWith(
                      color:
                          scope.style.foregroundColor?.resolve(scope.states) ??
                          muted(c.onSurface),
                    ),
              ),
              if (supportingText != null)
                Text(
                  supportingText!,
                  style: t.type
                      .of(ExpressiveTypeKey.bodyMedium)
                      .merge(scope.style.textStyle?.resolve(scope.states))
                      .copyWith(
                        color:
                            scope.style.foregroundColor?.resolve(
                              scope.states,
                            ) ??
                            muted(c.onSurfaceVariant),
                      ),
                ),
            ],
          );
    return ExpressivePressable(
      focusNode: focusNode,
      autofocus: autofocus,
      style: style,
      componentStyle: t.listTileTheme,
      // ListItemShapes.shapeForInteraction, as ExpressiveListTile: no
      // selected shape (a checked control is not a selected item).
      shapes: expressiveListItemPressShapes(t.shapes),
      motion: ListItemBehavior.shapeMotion,
      // A list item's ring, inside the row (ExpressiveListTile).
      focusInward: true,
      color: _clear,
      contentColor: c.onSurface,
      role: role,
      selected: selected,
      onPressed: enabled ? onPressed : null,
      child: Builder(
        builder: (context) {
          final scope = ExpressiveStyleScope.maybeOf(context)!;
          return ExpressiveStyledContent(
            minimumSize: const Size(0, ListTokens.itemOneLineContainerHeight),
            padding: const EdgeInsetsDirectional.only(
              start: ListTokens.itemLeadingSpace,
              end: ListTokens.itemTrailingSpace,
            ),
            center: false,
            keylineSides: true,
            child: Row(
              spacing: ExpressiveSpacing.s16,
              children: [
                if (controlLeads) control,
                Expanded(child: text(scope)),
                if (!controlLeads) control,
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A checkbox with its label, the whole row the touch target.
///
/// ```dart
/// ExpressiveCheckboxRow(label: 'Email me receipts', value: receipts, onChanged: (v) => setState(() => receipts = v))
/// ```
class ExpressiveCheckboxRow extends StatelessWidget {
  /// A checkbox row labelled [label].
  const ExpressiveCheckboxRow({
    required this.label,
    required this.value,
    this.onChanged,
    this.supportingText,
    this.tristate = false,
    this.enabled = true,
    this.isError = false,
    this.contentPadding,
    this.style,
    super.key,
    this.focusNode,
    this.autofocus = false,
  });

  /// Stateful visual overrides for this control or labelled row.
  final ExpressiveComponentThemeData? style;

  /// The row's start and end space around its control and words, as
  /// `ListTile.contentPadding`: the list's own (16 and 24dp, the row a
  /// full-width list's) when null. [EdgeInsets.zero] puts the control's mark
  /// on the start (or, for a switch, the end) edge, so a row in a padded
  /// column lines up with the fields and buttons above it, while its
  /// highlight and touch area reach past the edges into the column's margin
  /// by the list's space. Only the horizontal sides are read.
  final EdgeInsetsGeometry? contentPadding;

  /// The row's label.
  final String label;

  /// A second line under the label.
  final String? supportingText;

  /// Checked, unchecked or (with [tristate]) indeterminate (null).
  final bool? value;

  /// Told the next value on a tap; null disables the row (as Flutter's
  /// `CheckboxListTile`).
  final ValueChanged<bool>? onChanged;

  /// Whether [value] may be null.
  final bool tristate;

  /// Whether the row takes input.
  final bool enabled;

  /// Whether the box draws the error colours.
  final bool isError;

  /// The focus node of its press target; null lets the target keep its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => _ControlRow(
    focusNode: focusNode,
    autofocus: autofocus,
    style: style,
    label: label,
    supportingText: supportingText,
    role: ExpressivePressRole.checkbox,
    selected: value == true,
    enabled: enabled && onChanged != null,
    contentPadding: contentPadding,
    controlInset: context.expressiveTheme.density
        .padding(const EdgeInsets.all(CheckboxBehavior.boxPadding))
        .left,
    onPressed: onChanged == null ? null : () => onChanged!(value != true),
    control: ExpressiveCheckbox.mark(
      value: value,
      tristate: tristate,
      enabled: enabled && onChanged != null,
      isError: isError,
    ),
  );
}

/// A radio button with its label, the whole row the touch target: one row
/// of an [ExpressiveRadioGroup].
///
/// ```dart
/// ExpressiveRadioRow(label: 'Monthly', selected: plan == 'monthly', onPressed: () => setState(() => plan = 'monthly'))
/// ```
class ExpressiveRadioRow extends StatelessWidget {
  /// A radio row labelled [label], on when [selected].
  const ExpressiveRadioRow({
    required this.label,
    required this.selected,
    this.onPressed,
    this.supportingText,
    this.enabled = true,
    this.contentPadding,
    this.style,
    super.key,
    this.focusNode,
    this.autofocus = false,
  });

  /// Stateful visual overrides for this control or labelled row.
  final ExpressiveComponentThemeData? style;

  /// The row's start and end space around its control and words, as
  /// `ListTile.contentPadding`: the list's own (16 and 24dp, the row a
  /// full-width list's) when null. [EdgeInsets.zero] puts the control's mark
  /// on the start (or, for a switch, the end) edge, so a row in a padded
  /// column lines up with the fields and buttons above it, while its
  /// highlight and touch area reach past the edges into the column's margin
  /// by the list's space. Only the horizontal sides are read.
  final EdgeInsetsGeometry? contentPadding;

  /// The row's label.
  final String label;

  /// A second line under the label.
  final String? supportingText;

  /// Whether this option is selected.
  final bool selected;

  /// What a tap does (select this option); null disables the row (as
  /// Flutter's `RadioListTile`).
  final VoidCallback? onPressed;

  /// Whether the row takes input.
  final bool enabled;

  /// The focus node of its press target; null lets the target keep its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => _ControlRow(
    focusNode: focusNode,
    autofocus: autofocus,
    style: style,
    label: label,
    supportingText: supportingText,
    role: ExpressivePressRole.radio,
    selected: selected,
    enabled: enabled && onPressed != null,
    contentPadding: contentPadding,
    controlInset: context.expressiveTheme.density
        .padding(const EdgeInsets.all(RadioButtonBehavior.padding))
        .left,
    onPressed: onPressed,
    control: ExpressiveRadio.mark(
      selected: selected,
      enabled: enabled && onPressed != null,
    ),
  );
}

/// A switch with its label before it, the whole row the touch target (the
/// settings-row pattern: label at the start, switch at the end).
///
/// ```dart
/// ExpressiveSwitchRow(label: 'Wi-Fi calling', value: calling, onChanged: (v) => setState(() => calling = v))
/// ```
class ExpressiveSwitchRow extends StatelessWidget {
  /// A switch row labelled [label].
  const ExpressiveSwitchRow({
    required this.label,
    required this.value,
    this.onChanged,
    this.supportingText,
    this.enabled = true,
    this.checkedIcon,
    this.uncheckedIcon,
    this.contentPadding,
    this.style,
    super.key,
    this.focusNode,
    this.autofocus = false,
  });

  /// Stateful visual overrides for this control or labelled row.
  final ExpressiveComponentThemeData? style;

  /// The row's start and end space around its control and words, as
  /// `ListTile.contentPadding`: the list's own (16 and 24dp, the row a
  /// full-width list's) when null. [EdgeInsets.zero] puts the control's mark
  /// on the start (or, for a switch, the end) edge, so a row in a padded
  /// column lines up with the fields and buttons above it, while its
  /// highlight and touch area reach past the edges into the column's margin
  /// by the list's space. Only the horizontal sides are read.
  final EdgeInsetsGeometry? contentPadding;

  /// The row's label.
  final String label;

  /// A second line under the label.
  final String? supportingText;

  /// Whether the switch is on.
  final bool value;

  /// Told the next value on a tap; null disables the row (as Flutter's
  /// `SwitchListTile`).
  final ValueChanged<bool>? onChanged;

  /// Whether the row takes input.
  final bool enabled;

  /// The thumb's content while on: an icon, sized 16dp and coloured by
  /// the switch (Compose's `thumbContent`).
  final Widget? checkedIcon;

  /// The thumb's content while off.
  final Widget? uncheckedIcon;

  /// The focus node of its press target; null lets the target keep its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => _ControlRow(
    focusNode: focusNode,
    autofocus: autofocus,
    style: style,
    label: label,
    supportingText: supportingText,
    role: ExpressivePressRole.toggle,
    selected: value,
    enabled: enabled && onChanged != null,
    controlLeads: false,
    contentPadding: contentPadding,
    onPressed: onChanged == null ? null : () => onChanged!(!value),
    control: ExpressiveSwitch.mark(
      value: value,
      enabled: enabled && onChanged != null,
      checkedIcon: checkedIcon,
      uncheckedIcon: uncheckedIcon,
    ),
  );
}
