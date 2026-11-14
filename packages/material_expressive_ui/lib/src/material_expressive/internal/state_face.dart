/// The face of a part whose interaction states ui_core owns.
///
/// ui_core's behaviours (`package:initial_gen_app/design_kit/...`) hand a
/// builder a `Set<WidgetState>`: hovered, pressed, focused (keyboard focus
/// only, never after a tap), selected, disabled, error. Expressive paints
/// them exactly as its own pressable does (`states.dart`): the state layer
/// of the content colour at the `StateTokens` opacity, composited into the
/// part's own container so it takes the part's exact shape, and under
/// keyboard focus the M3 focus indicator, 3dp in `secondary` 2dp out from
/// the shape, concentric with it. A change of shape springs.
library;

import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/services.dart' show TextInputAction, TextInputType;
import 'package:flutter/widgets.dart';

import '../elevation.dart';
import '../motion.dart';
import '../theme.dart';
import 'cap_label.dart';
import 'focus_ring.dart';
import 'tokens/behavior.g.dart';
import 'tokens/outlined_text_field_tokens.g.dart';

/// `md.comp.*.focus.indicator.outline.offset`: the ring's gap.
const double _ringOffset = 2;

/// `md.comp.*.focus.indicator.thickness`: the ring's stroke.
const double _ringThickness = 3;

/// [child] on [shape] filled with [color] and [states]' state layer of
/// [contentColor], ringed under keyboard focus.
class ExpressiveStateFace extends StatelessWidget {
  /// A face for [states].
  const ExpressiveStateFace({
    required this.states,
    required this.shape,
    required this.color,
    required this.contentColor,
    required this.child,
    this.side = BorderSide.none,
    this.padding,
    this.motion = ExpressiveMotionKey.fastSpatial,
    this.layers = true,
    this.focusInward = false,
    super.key,
  });

  /// The states ui_core reports.
  final Set<WidgetState> states;

  /// The part's outline; a change springs on [motion].
  final OutlinedBorder shape;

  /// The container colour (transparent for a part with none).
  final Color color;

  /// Text and icons inherit it; the state layer is drawn in it.
  final Color contentColor;

  /// What the part shows.
  final Widget child;

  /// The outline stroke, if any.
  final BorderSide side;

  /// The content's padding.
  final EdgeInsetsGeometry? padding;

  /// The spring a change of [shape] runs on.
  final ExpressiveMotionKey motion;

  /// Whether hover, focus, press and drag draw the state layer.
  final bool layers;

  /// Whether the ring stands inside the part (rows stacked flush).
  final bool focusInward;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final layer = layers ? t.states.layerOf(contentColor, states) : null;
    final fill = layer == null ? color : Color.alphaBlend(layer, color);
    final ring =
        states.contains(WidgetState.focused) &&
        !states.contains(WidgetState.disabled);
    return ExpressiveSpringShape(
      value: shape,
      motion: motion,
      builder: (context, value, _) {
        final outlined = value is OutlinedBorder ? value : shape;
        final surface = ExpressiveSurface(
          shape: outlined,
          color: fill,
          contentColor: contentColor,
          side: side,
          padding: padding,
          states: states,
          child: child,
        );
        if (!ring) return surface;
        return CustomPaint(
          foregroundPainter: _Ring(
            shape: outlined,
            color: t.colors.secondary,
            thickness: _ringThickness,
            inward: focusInward,
            gap: focusInward && color.a > 0 ? t.colors.surface : null,
            textDirection: Directionality.maybeOf(context),
          ),
          child: surface,
        );
      },
    );
  }
}

class _Ring extends CustomPainter {
  const _Ring({
    required this.shape,
    required this.color,
    required this.thickness,
    required this.inward,
    required this.textDirection,
    this.gap,
  });

  final OutlinedBorder shape;
  final Color color;
  final double thickness;
  final bool inward;

  /// The surface band between an inward ring and a filled face.
  final Color? gap;
  final TextDirection? textDirection;

  @override
  void paint(Canvas canvas, Size size) => expressivePaintFocusRing(
    canvas,
    Offset.zero & size,
    shape,
    color: color,
    thickness: thickness,
    offset: _ringOffset,
    textDirection: textDirection,
    inward: inward,
    gap: gap,
  );

  @override
  bool shouldRepaint(_Ring old) =>
      old.shape != shape ||
      old.gap != gap ||
      old.color != color ||
      old.thickness != thickness ||
      old.inward != inward ||
      old.textDirection != textDirection;
}

/// The outlined text field's container for a field ui_core frames (an
/// input group, a tag input): the extra-small corner at least 56dp tall (less
/// at a denser theme, as the text field), its
/// outline 1dp in `outline`, `onSurface` under a pointer, 2dp `primary` while
/// anything inside has focus, in `error` for [WidgetState.error], and
/// `onSurface` at 12% when disabled (`OutlinedTextFieldTokens`).
class ExpressiveFieldFrame extends StatelessWidget {
  /// A frame for [states] around [child].
  const ExpressiveFieldFrame({
    required this.states,
    required this.child,
    this.padding = const EdgeInsetsDirectional.symmetric(horizontal: 4),
    super.key,
  });

  /// Focus-within, hovered, error, disabled.
  final Set<WidgetState> states;

  /// The field and its add-ons.
  final Widget child;

  /// Inside the outline.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final error = states.contains(WidgetState.error);
    final focused = states.contains(WidgetState.focused);
    final hovered = states.contains(WidgetState.hovered);
    final Color color;
    if (states.contains(WidgetState.disabled)) {
      color = c
          .role(OutlinedTextFieldTokens.disabledOutlineColor)
          .withValues(alpha: OutlinedTextFieldTokens.disabledOutlineOpacity);
    } else if (error) {
      color = c.role(
        focused
            ? OutlinedTextFieldTokens.errorFocusOutlineColor
            : hovered
            ? OutlinedTextFieldTokens.errorHoverOutlineColor
            : OutlinedTextFieldTokens.errorOutlineColor,
      );
    } else {
      color = c.role(
        focused
            ? OutlinedTextFieldTokens.focusOutlineColor
            : hovered
            ? OutlinedTextFieldTokens.hoverOutlineColor
            : OutlinedTextFieldTokens.outlineColor,
      );
    }
    final width = focused
        ? OutlinedTextFieldTokens.focusOutlineWidth
        : OutlinedTextFieldTokens.outlineWidth;
    return ConstrainedBox(
      // As tall as the text field beside it at the theme's density (48dp
      // when compact), not a fixed 56dp that stood out among them.
      constraints: BoxConstraints(
        minHeight: t.density.height(OutlinedTextFieldTokens.containerHeight),
      ),
      child: ExpressiveSurface(
        shape: t.shapes.of(OutlinedTextFieldTokens.containerShape),
        color: const Color(0x00000000),
        contentColor: c.onSurface,
        side: BorderSide(color: color, width: width),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// The text field's input with no container of its own: `bodyLarge` in
/// `onSurface`, the placeholder in `onSurfaceVariant`, the caret in
/// `primary`, at least 48dp tall (Compose's `minimumInteractiveComponentSize`;
/// a smaller type scale centres its line in it). For a field whose frame
/// ui_core's behaviour owns.
class ExpressiveBareField extends StatelessWidget {
  /// A bare input on [controller] and [focusNode].
  const ExpressiveBareField({
    required this.controller,
    required this.focusNode,
    this.hintText,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
    this.obscureText = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.semanticLabel,
    super.key,
  });

  /// The text.
  final TextEditingController controller;

  /// The input's focus.
  final FocusNode focusNode;

  /// Shown while it is empty.
  final String? hintText;

  /// Enter.
  final ValueChanged<String>? onSubmitted;

  /// Each edit.
  final ValueChanged<String>? onChanged;

  /// Whether it takes input.
  final bool enabled;

  /// Whether the text is hidden.
  final bool obscureText;

  /// Whether it takes focus when first built.
  final bool autofocus;

  /// The keyboard.
  final TextInputType? keyboardType;

  /// The keyboard's action.
  final TextInputAction? textInputAction;

  /// What a screen reader calls it, when no label around it does.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final style = t.type.bodyLarge.copyWith(
      color: enabled ? c.onSurface : c.onSurface.withValues(alpha: 0.38),
    );
    // I3: the editable is bare (no decoration, so no InputDecorator whose
    // height density, Material defaults or a counter could change); the
    // placeholder is a sibling on the same line; the line is centred in a
    // box at least 48dp tall, so larger text grows it.
    final input = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        obscureText: obscureText,
        autofocus: autofocus,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        style: style,
        cursorColor: c.role(OutlinedTextFieldTokens.caretColor),
        decoration: null,
      ),
    );
    final hint = hintText;
    Widget field = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: HostBehavior.minimumInteractiveComponentSize,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        // The line by its capitals on the box's middle: the shift is the
        // entry's, so the hint, the typed text and the caret share it.
        child: expressiveFaceLabel(
          hint == null
              ? input
              : Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: <Widget>[
                    ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) => Visibility.maintain(
                        visible: controller.text.isEmpty,
                        child: ExcludeSemantics(
                          child: Text(
                            hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: style.copyWith(color: c.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                    input,
                  ],
                ),
        ),
      ),
    );
    // Named by its label, else by its placeholder (as a text field is): a
    // field a screen reader can only hint at has no name.
    final label = semanticLabel ?? hint;
    if (label != null) {
      // Merged, so the name lands on the field's own node: an annotation
      // above a TextField names the node around it, not the field.
      field = MergeSemantics(
        child: Semantics(
          label: label,
          hint: semanticLabel == null ? null : hint,
          textField: true,
          child: field,
        ),
      );
    }
    return field;
  }
}

/// The focus ring alone round [shape], drawn while [focused]: for a part
/// whose surface another widget draws (a chip ui_core gives focus to).
class ExpressiveFocusRingBox extends StatelessWidget {
  /// [child], ringed while [focused].
  const ExpressiveFocusRingBox({
    required this.focused,
    required this.shape,
    required this.child,
    super.key,
  });

  /// Whether the keyboard is on the part.
  final bool focused;

  /// The part's outline.
  final OutlinedBorder shape;

  /// The part.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!focused) return child;
    final t = context.expressiveTheme;
    return CustomPaint(
      foregroundPainter: _Ring(
        shape: shape,
        color: t.colors.secondary,
        thickness: _ringThickness,
        inward: false,
        textDirection: Directionality.maybeOf(context),
      ),
      child: child,
    );
  }
}
