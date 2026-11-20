/// State layers, focus outlines and input frames for composite controls.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/services.dart' show TextInputAction, TextInputType;
import 'package:flutter/widgets.dart';

import '../elevation.dart';
import '../motion.dart';
import '../spacing.dart';
import '../states.dart' show ExpressiveFocusRing;
import '../theme.dart';
import 'cap_label.dart';
import 'focus_ring.dart';
import 'reach.dart';
import 'tokens/behavior.g.dart';
import 'tokens/outlined_text_field_tokens.g.dart';
import 'word_scope.dart';

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
    this.focusLayer = true,
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

  /// Whether keyboard focus also lays the focus state layer under the ring.
  /// A list's row shows the keys' place by the ring alone, as Material's web
  /// list and menu items do, so it never reads as the pointer's fill.
  final bool focusLayer;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final layer = layers
        ? t.states.layerOf(
            contentColor,
            focusLayer
                ? states
                : (<WidgetState>{...states}..remove(WidgetState.focused)),
          )
        : null;
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
            thickness: ExpressiveFocusRing.thickness,
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
    this.faceHeight,
  });

  final OutlinedBorder shape;
  final Color color;
  final double thickness;
  final bool inward;

  /// The face's height inside the painted box, centred; all of it if null.
  final double? faceHeight;

  /// The surface band between an inward ring and a filled face.
  final Color? gap;
  final TextDirection? textDirection;

  @override
  void paint(Canvas canvas, Size size) => expressivePaintFocusRing(
    canvas,
    Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width,
      height: math.min(size.height, faceHeight ?? size.height),
    ),
    shape,
    color: color,
    thickness: thickness,
    offset: ExpressiveFocusRing.offset,
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
      old.faceHeight != faceHeight ||
      old.textDirection != textDirection;
}

/// An outlined frame for an input group or a tag field.
class ExpressiveFieldFrame extends StatelessWidget {
  /// A frame for [states] around [child].
  const ExpressiveFieldFrame({
    required this.states,
    required this.child,
    this.shape,
    this.padding = const EdgeInsetsDirectional.symmetric(
      horizontal: ExpressiveSpacing.s4,
    ),
    super.key,
  });

  /// Focus-within, hovered, error, disabled.
  final Set<WidgetState> states;

  /// The field and its add-ons.
  final Widget child;

  /// Inside the outline.
  final EdgeInsetsGeometry padding;

  /// The field outline. Defaults to the theme's outlined text field shape.
  final OutlinedBorder? shape;

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
        shape: shape ?? t.shapes.of(OutlinedTextFieldTokens.containerShape),
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
    this.onEditingComplete,
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

  /// Enter, in a field that gives the focus up.
  final ValueChanged<String>? onSubmitted;

  /// Enter, in a field that keeps the focus (a multi-select's): never with
  /// [onSubmitted], whose restart of the text input a browser types into no
  /// more.
  final VoidCallback? onEditingComplete;

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
    // The placeholder and editable share a centered line. The minimum height
    // keeps the whole field tappable while allowing larger text to increase
    // its height.
    final input = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        contextMenuBuilder: expressiveContextMenu,
        obscureText: obscureText,
        autofocus: autofocus,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        onEditingComplete: onEditingComplete,
        onChanged: onChanged,
        style: style,
        cursorColor: c.role(OutlinedTextFieldTokens.caretColor),
        decoration: null,
      ),
    );
    final hint = hintText;
    Widget field = ExpressiveLineReach(
      minHeight: HostBehavior.minimumInteractiveComponentSize,
      fillWidth: false,
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
    this.faceHeight,
    super.key,
  });

  /// The part's visible height, centred in [child]'s box, when its box is
  /// taller (a chip's 48dp touch target round its 32dp face): the ring
  /// follows the face, not the target.
  final double? faceHeight;

  /// Whether the keyboard is on the part.
  final bool focused;

  /// The part's outline.
  final OutlinedBorder shape;

  /// The part.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return ExpressiveSpringColor(
      value: t.colors.secondary.withValues(alpha: focused ? 1 : 0),
      motion: ExpressiveMotionKey.fastEffects,
      child: child,
      builder: (context, color, child) => CustomPaint(
        foregroundPainter: _Ring(
          shape: shape,
          color: color,
          thickness: ExpressiveFocusRing.thickness,
          inward: false,
          textDirection: Directionality.maybeOf(context),
          faceHeight: faceHeight,
        ),
        child: child,
      ),
    );
  }
}
