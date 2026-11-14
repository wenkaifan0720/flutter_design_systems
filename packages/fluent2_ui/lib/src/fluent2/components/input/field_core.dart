// The parts every Fluent 2 text control and picker shares: the controller
// and focus a field stands on, Fluent's field frame (the stroke, the
// accessible bottom stroke and the brand underline that grows on focus),
// the scope a Fluent2FormField publishes to the control it labels, the popover
// a picker opens under its field, and the listbox it holds. Plumbing of
// the inputs; never exported from the barrel, never placed by a page.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart'
    show
        InputBorder,
        InputDecoration,
        Material,
        MaterialType,
        TextField,
        VisualDensity;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/cap_label.dart';
import '../../internal/well.dart';
import '../../icons.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';
import 'context_menu.dart';

/// A field's face, Fluent's Input `appearance`: [outline] the default (the
/// surface inside a 1 stroke whose bottom is the accessible stroke),
/// [underline] the bottom stroke alone, [filledDarker] the darker neutral
/// fill (Fluent's grey, for a field on the surface), [filledLighter]
/// the surface fill (for a field on the page's grey ground). Every one
/// grows the 2 brand underline while it holds focus. The filled-darker
/// grey is laid over whatever the field stands on, so it shows on the
/// page's tinted ground too.
enum Fluent2InputAppearance {
  /// An outlined field with a stronger bottom edge.
  outline,

  /// A bottom edge alone.
  underline,

  /// A darker fill, for a field on a light surface.
  filledDarker,

  /// A lighter fill, for a field on a darker surface.
  filledLighter,
}

/// A field's size, Fluent's Input `size`: [small] 24 tall in caption1,
/// [medium] 32 in body1, [large] 40 in body2.
enum Fluent2InputSize {
  /// The small size.
  small,

  /// The medium size.
  medium,

  /// The large size.
  large,
}

/// The controller and the focus node a text control stands on: the
/// caller's when given, else its own, kept in step with the `value` the
/// page passes (a changed value from outside replaces the text; the caret
/// goes to its end).
mixin Fluent2FieldOwner<T extends StatefulWidget> on State<T> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  /// The caller's controller, if any.
  TextEditingController? controllerOf(T widget);

  /// The caller's value, when the page owns the text.
  String? valueOf(T widget);

  /// The caller's focus node, if any.
  FocusNode? focusNodeOf(T widget);

  /// The controller in use.
  TextEditingController get fieldController =>
      controllerOf(widget) ??
      (_ownController ??= TextEditingController(text: valueOf(widget) ?? ''));

  /// The focus node in use.
  FocusNode get fieldFocus =>
      focusNodeOf(widget) ?? (_ownFocus ??= FocusNode());

  void _onFocus() {
    if (mounted) setState(() {});
    onFieldFocus(fieldFocus.hasFocus);
  }

  /// Told when the field gains or loses focus.
  void onFieldFocus(bool focused) {}

  void _onText() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fieldFocus.addListener(_onFocus);
    fieldController.addListener(_onText);
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (focusNodeOf(oldWidget) != focusNodeOf(widget)) {
      (focusNodeOf(oldWidget) ?? _ownFocus)?.removeListener(_onFocus);
      fieldFocus.addListener(_onFocus);
    }
    if (controllerOf(oldWidget) != controllerOf(widget)) {
      (controllerOf(oldWidget) ?? _ownController)?.removeListener(_onText);
      fieldController.addListener(_onText);
    }
    final value = valueOf(widget);
    if (controllerOf(widget) == null &&
        value != null &&
        value != valueOf(oldWidget) &&
        value != fieldController.text) {
      fieldController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void dispose() {
    fieldFocus.removeListener(_onFocus);
    fieldController.removeListener(_onText);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }
}

/// What a `Fluent2FormField` tells the control it labels: its label (the
/// control's spoken name when it has none of its own), whether it is
/// required, and whether its validation is an error (the control's
/// stroke turns `paletteRedBorder2`).
class Fluent2FieldScope extends InheritedWidget {
  /// Tells [child] the label, the requirement and the validation of the field
  /// it stands in.
  const Fluent2FieldScope({
    required this.label,
    required this.required,
    required this.invalid,
    required super.child,
    super.key,
  });

  /// The field's label, the control's spoken name when it has none of its own.
  final String? label;

  /// Whether the field must be filled.
  final bool required;

  /// Whether the field's validation is an error.
  final bool invalid;

  /// The scope above [context], or null outside a field.
  static Fluent2FieldScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Fluent2FieldScope>();

  @override
  bool updateShouldNotify(Fluent2FieldScope oldWidget) =>
      label != oldWidget.label ||
      required != oldWidget.required ||
      invalid != oldWidget.invalid;
}

/// The geometry of a field size, Fluent's Input: [height] (24, 32, 40),
/// the room at a side with no slot ([combined]: 8, 12, 18), the root's
/// room before a slot ([root]: 6, 10, 12) and the words' room after it
/// ([inner]: 2, 2, 6), the slot glyph (16, 20, 24) and the gap between
/// slot and words (2, 2, 6).
@immutable
final class Fluent2FieldMetrics {
  const Fluent2FieldMetrics._(
    this.height,
    this.combined,
    this.root,
    this.inner,
    this.glyph,
    this.gap,
  );

  /// The field's height at this size.
  final double height;

  /// The room at a side with no slot.
  final double combined;

  /// The room before a slot.
  final double root;

  /// The room between a slot and the words.
  final double inner;

  /// A slot glyph's size.
  final double glyph;

  /// The gap between a slot and the words.
  final double gap;

  /// The metrics of a field at [size].
  static Fluent2FieldMetrics of(Fluent2InputSize size) => switch (size) {
    Fluent2InputSize.small => const Fluent2FieldMetrics._(24, 8, 6, 2, 16, 2),
    Fluent2InputSize.medium => const Fluent2FieldMetrics._(
      32,
      12,
      10,
      2,
      20,
      2,
    ),
    Fluent2InputSize.large => const Fluent2FieldMetrics._(40, 18, 12, 6, 24, 6),
  };

  /// The words' type at [size]: caption1, body1, body2.
  static TextStyle typeOf(Fluent2ThemeData t, Fluent2InputSize size) =>
      switch (size) {
        Fluent2InputSize.small => t.caption1,
        Fluent2InputSize.medium => t.body1,
        Fluent2InputSize.large => t.body2,
      };
}

/// The editing core every Fluent 2 text control writes through (the input,
/// the search box, the textarea, the combobox, the tag picker, the spin
/// button, the composer): Material's text field for its editing, selection
/// and IME, with no decoration of its own, its words and its [hint] in
/// [style] on a line box of the style's line height, the leading split
/// evenly about the face's ascent and descent as CSS leads a line; one
/// line ([maxLines] 1) stands in the middle of the height its field hands
/// it, more stand from the top.
///
/// Its decoration is bare: every field that can size a decorator is set, so no theme's density or `InputDecorationTheme` moves
/// the words.
class Fluent2FieldEditor extends StatelessWidget {
  /// An editor of [controller]'s words in [style].
  const Fluent2FieldEditor({
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.enabled,
    this.hint,
    this.hintStyle,
    this.groupId,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.minLines,
    this.maxLines = 1,
    super.key,
  });

  /// The controller that holds the words.
  final TextEditingController controller;

  /// The focus node the editor takes focus with.
  final FocusNode focusNode;

  /// The words' type in their ink.
  final TextStyle style;

  /// False puts it out of use: no focus, no editing.
  final bool enabled;

  /// What the empty field says, in [hintStyle] (the type in the
  /// placeholder's ink).
  final String? hint;

  /// The type and ink of [hint].
  final TextStyle? hintStyle;

  /// The tap region the field shares with its popover; null is the text
  /// field's own.
  final Object? groupId;

  /// Whether the words can be selected but not changed.
  final bool readOnly;

  /// Whether the words are hidden, as a password's are.
  final bool obscureText;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// Called when the editor is tapped.
  final VoidCallback? onTap;

  /// Called with the words each time the user changes them.
  final ValueChanged<String>? onChanged;

  /// Called with the words when the user submits them (the keyboard's done or
  /// Enter).
  final ValueChanged<String>? onSubmitted;

  /// The keyboard the platform shows for it; null is the text keyboard.
  final TextInputType? keyboardType;

  /// The keyboard's action button; null is the platform's choice.
  final TextInputAction? textInputAction;

  /// Formatters that check and shape the words as they are typed.
  final List<TextInputFormatter>? inputFormatters;

  /// The fewest lines it stands; null is one.
  final int? minLines;

  /// One line by default; null grows with the text.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final field = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        groupId: groupId ?? EditableText,
        enabled: enabled,
        readOnly: readOnly,
        obscureText: obscureText,
        autofocus: autofocus,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        // An address reads left to right in any page: a right-to-left
        // paragraph would carry its scheme and dots to the far end.
        textDirection:
            keyboardType == TextInputType.url ||
                keyboardType == TextInputType.emailAddress
            ? TextDirection.ltr
            : null,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        minLines: minLines,
        maxLines: maxLines,
        textAlignVertical: maxLines == 1 ? TextAlignVertical.center : null,
        style: style,
        cursorColor: t.textPrimary,
        cursorWidth: 1,
        contextMenuBuilder: Fluent2FieldContextMenu.editable,
        decoration: _bareDecoration(hint: hint, hintStyle: hintStyle),
      ),
    );
    // One line: its capitals on the line's middle, the hint's too, the
    // caret, selection and taps moving with them (ui_core's DesignCapCenter
    // around the bare TextField). A text area keeps the browser's line box.
    return maxLines == 1
        ? fluent2CapCentred(field)
        : Fluent2WebBaseline(style: style, child: field);
  }
}

/// The decoration of a bare editable: the hint and
/// nothing else, with every field a decorator sizes itself by set, so a host
/// theme cannot reach it. An unset field takes the `InputDecorationTheme`
/// around the field: a theme's `constraints` (InputDecoration.collapsed
/// leaves them unset) moved the line 20, its `contentPadding` or `isDense`
/// a few more, and the adaptive visual density (compact on macOS, Windows
/// and Linux, so in every desktop browser) put a centred line 4 below its
/// own box. The look's frame draws the box, the fill, the borders and the
/// ring, and its row the icons.
InputDecoration _bareDecoration({String? hint, TextStyle? hintStyle}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: hintStyle,
      isCollapsed: true,
      isDense: false,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      constraints: const BoxConstraints(),
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );

/// How far below a browser's baseline Flutter sets words in [style] in
/// their line box, in logical pixels (negative: above it). Both lead a line
/// as CSS does, the room the face leaves in the line height split about its
/// ascent and descent; Blink (the Chromium browsers, where Fluent's own
/// fields render) first rounds the face's ascent and its descent each to a whole
/// pixel and then floors the leaded ascent (`SimpleFontData::PlatformInit`,
/// `FontHeight::AddLeading`), where Flutter keeps the fractions. Read off
/// the face itself: Selawik's ascent and descent are 2027 and 431 of 2048,
/// so caption1 (12 on 16) stands 12.68 down its line box in Flutter and 12
/// in Blink, body1 (14 on 20) 15.46 and 15, body2 (16 on 22) 17.23 and 17,
/// subtitle1 (20 on 28) 21.79 and 22. Zero for a style with no line height
/// of its own (its words fill the line box in both).
double fluent2WebBaselineDrop(TextStyle style) {
  if (style.height == null || style.fontSize == null) return 0;
  if (_dropsHeard == null) {
    // A face that loads later measures anew.
    _dropsHeard = _drops.clear;
    PaintingBinding.instance.systemFonts.addListener(_dropsHeard!);
  }
  return _drops[style] ??= () {
    final face = TextStyle(
      fontFamily: style.fontFamily,
      fontFamilyFallback: style.fontFamilyFallback,
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      fontStyle: style.fontStyle,
      fontVariations: style.fontVariations,
      fontFeatures: style.fontFeatures,
    );
    final bare = TextPainter(
      text: TextSpan(text: 'x', style: face),
      textDirection: TextDirection.ltr,
    )..layout();
    final f = bare.computeLineMetrics().first;
    bare.dispose();
    final led = TextPainter(
      text: TextSpan(text: 'x', style: face.merge(_leadOf(style))),
      textDirection: TextDirection.ltr,
    )..layout();
    final line = led.computeLineMetrics().first;
    led.dispose();
    // Blink keeps a line height to 1/64 of a pixel.
    final height = (line.height * 64).roundToDouble() / 64;
    final ascent = f.ascent.roundToDouble();
    final descent = f.descent.roundToDouble();
    final blink = (ascent + (height - ascent - descent) / 2).floorToDouble();
    return line.baseline - blink;
  }();
}

TextStyle _leadOf(TextStyle style) => TextStyle(
  height: style.height,
  leadingDistribution: style.leadingDistribution,
);

final Map<TextStyle, double> _drops = {};
VoidCallback? _dropsHeard;

/// Sets [child], words in [style] (a field's line, a trigger's label),
/// where a browser sets them in their line box: [fluent2WebBaselineDrop]
/// higher, in paint and in hit testing; the box it takes stays its own.
class Fluent2WebBaseline extends StatelessWidget {
  /// Sets [child] where a browser would set words in [style].
  const Fluent2WebBaseline({
    required this.style,
    required this.child,
    super.key,
  });

  /// The type whose line [child] sets.
  final TextStyle style;

  /// The words, or the row that holds them.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final drop = fluent2WebBaselineDrop(style);
    if (drop == 0) return child;
    return Transform.translate(offset: Offset(0, -drop), child: child);
  }
}

/// One field face: its fill, its side strokes and its bottom stroke.
typedef Fluent2FieldFace = ({Color fill, Color side, Color bottom});

/// A field's placeholder ink: Fluent's `neutralForeground4` on a field
/// with a fill of its own, `neutralForeground3` on the underline field,
/// whose words stand on the page, and on the filled-darker field, whose
/// grey is laid over the page (the fourth ink misses 4.5:1 on the light
/// presets' ground and on that grey).
Color fluent2PlaceholderInk(
  Fluent2ThemeData t,
  Fluent2InputAppearance appearance,
) =>
    appearance == Fluent2InputAppearance.underline ||
        appearance == Fluent2InputAppearance.filledDarker
    ? t.colors.neutralForeground3
    : t.colors.neutralForeground4;

/// The face of a field in [appearance] at rest, under the pointer
/// ([hover]), focused or pressed ([active]), disabled, or invalid, as
/// Fluent's Input styles step them.
Fluent2FieldFace fluent2FieldFace(
  Fluent2ThemeData t,
  Fluent2InputAppearance appearance, {
  required bool enabled,
  bool hover = false,
  bool active = false,
  bool invalid = false,
}) {
  final c = t.colors;
  final underline = appearance == Fluent2InputAppearance.underline;
  if (!enabled) {
    return (
      fill: c.transparentBackground,
      side: underline
          ? c.transparentStroke
          : fluent2Step(t, c.neutralStrokeDisabled),
      bottom: fluent2Step(t, c.neutralStrokeDisabled),
    );
  }
  final red = t.sharedColors.paletteRedBorder2;
  switch (appearance) {
    case Fluent2InputAppearance.outline:
      if (invalid && !active) {
        return (fill: c.neutralBackground1, side: red, bottom: red);
      }
      return (
        fill: c.neutralBackground1,
        side: active
            ? c.neutralStroke1Pressed
            : hover
            ? c.neutralStroke1Hover
            : c.neutralStroke1,
        bottom: active
            ? c.neutralStrokeAccessiblePressed
            : hover
            ? c.neutralStrokeAccessibleHover
            : c.neutralStrokeAccessible,
      );
    case Fluent2InputAppearance.underline:
      return (
        fill: c.transparentBackground,
        side: c.transparentStroke,
        bottom: invalid && !active
            ? red
            : active
            ? c.neutralStrokeAccessiblePressed
            : hover
            ? c.neutralStrokeAccessibleHover
            : c.neutralStrokeAccessible,
      );
    case Fluent2InputAppearance.filledDarker:
    case Fluent2InputAppearance.filledLighter:
      // Filled darker: Fluent's grey laid over the ground the field stands
      // on, so it shows on the tinted page as on a card.
      final fill = appearance == Fluent2InputAppearance.filledDarker
          ? fluent2FieldWell(t)
          : c.neutralBackground1;
      if (invalid && !active) return (fill: fill, side: red, bottom: red);
      final stroke = hover || active
          ? c.transparentStrokeInteractive
          : c.transparentStroke;
      return (fill: fill, side: stroke, bottom: stroke);
  }
}

/// Fluent's field frame: the face's fill at the field's corner (4; none
/// for [Fluent2InputAppearance.underline], which draws its bottom stroke
/// alone), the 1 stroke with its accessible bottom, and the 2 brand
/// underline (`compoundBrandStroke`) that grows from the middle while the
/// field holds focus (in at `durationNormal`, out at `durationUltraFast`).
/// Tracks the pointer for the hover face; [child] stands inside the
/// strokes ([strokesOf]) with [padding] round it, at least [minHeight]
/// tall.
///
/// Every field reads [style], then `Fluent2ThemeData.textFieldTheme`, then
/// Fluent's own, in its states (disabled, hovered, focused, pressed, error):
/// `fill`, `edge` and `side` (the stroke all round, its bottom too),
/// `shape` (its corner radius; Fluent's accessible
/// bottom and underline follow a rounded rectangle, so an outline of
/// another kind keeps the control radius), `padding`, `minimumSize`;
/// the density moves the height and padding.
class Fluent2FieldFrame extends StatefulWidget {
  /// A frame round [child] in [appearance] and its states.
  const Fluent2FieldFrame({
    required this.appearance,
    required this.focused,
    required this.enabled,
    required this.child,
    this.invalid = false,
    this.pressed = false,
    this.minHeight = 32,
    this.padding = EdgeInsets.zero,
    this.cursor = SystemMouseCursors.text,
    this.radius,
    this.style,
    this.textNode = false,
    this.touchTarget = true,
    super.key,
  });

  /// Fluent's `appearance`: outline, underline or one of the fills.
  final Fluent2InputAppearance appearance;

  /// Whether the field holds focus (the brand underline shows).
  final bool focused;

  /// False draws the frame disabled.
  final bool enabled;

  /// Whether the field's validation is an error (its stroke turns red).
  final bool invalid;

  /// Whether the field is pressed.
  final bool pressed;

  /// The least height; under a finger the frame stands at least 48
  /// ([Fluent2Layout.touchHitTarget]) overall, its strokes drawn over its
  /// line's edges, unless [touchTarget] is false. 0 sets none.
  final double minHeight;

  /// Whether the frame is a touch target of its own: false for a part of
  /// a control that is the target as a whole (a one-time code's box).
  final bool touchTarget;

  /// Whether the frame holds a text field whose node it is: the editor's
  /// words, flags and actions gather in one node as large as the frame
  /// (unless a `Fluent2FormField` round it is that node already).
  final bool textNode;

  /// The room round [child] inside the strokes.
  final EdgeInsetsGeometry padding;

  /// The pointer's cursor over the frame.
  final MouseCursor cursor;

  /// The corner radius; null is the style's, then Fluent's control radius
  /// ([Fluent2Radius.medium]).
  final double? radius;

  /// The field's own look, over the text field theme.
  final Fluent2Style? style;

  /// The field's row: its slots and its editor.
  final Widget child;

  /// The room the strokes of a frame in [appearance] take inside it, which
  /// [padding] stands inside: the hairline at every side, at the bottom
  /// alone for [Fluent2InputAppearance.underline] (Fluent's underline field
  /// has no top, left or right border, so its words start at the root's
  /// padding from the edge and centre in the height over the stroke).
  static EdgeInsets strokesOf(Fluent2InputAppearance appearance) =>
      appearance == Fluent2InputAppearance.underline
      ? const EdgeInsets.only(bottom: Fluent2ChromeMetrics.hairline)
      : const EdgeInsets.all(Fluent2ChromeMetrics.hairline);

  @override
  State<Fluent2FieldFrame> createState() => _Fluent2FieldFrameState();
}

class _Fluent2FieldFrameState extends State<Fluent2FieldFrame> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final enabled = widget.enabled;
    final face = fluent2FieldFace(
      t,
      widget.appearance,
      enabled: enabled,
      hover: _hover,
      active: widget.focused || widget.pressed,
      invalid: widget.invalid,
    );
    final look = Fluent2StyleOf(
      [widget.style, t.textFieldTheme],
      fluent2States(
        enabled: enabled,
        hovered: _hover,
        focused: widget.focused,
        pressed: widget.pressed,
        error: widget.invalid,
      ),
    );
    final square = widget.appearance == Fluent2InputAppearance.underline;
    final radius = square
        ? 0.0
        : widget.radius ??
              fluent2CornerOf(
                look.shape,
                double.infinity,
                Fluent2Radius.medium,
              );
    final rim = look.side;
    final edge = rim?.color ?? look.edge;
    final fill = look.fill ?? face.fill;
    return fluent2EasedInks([fill, edge ?? face.side, edge ?? face.bottom], (
      context,
      inks,
    ) {
      final [fill, sideInk, bottomInk] = inks;
      final strokes = Fluent2FieldFrame.strokesOf(widget.appearance);
      final set =
          look.minimumSize?.height ??
          (widget.minHeight == 0
              ? 0.0
              // Never under 20, Fluent's smallest control, as a button.
              : t.density.height(widget.minHeight, least: 20));
      // Under a finger the frame stands a whole target tall overall, as a
      // button's and a strip's faces do, so a row shows one height; its line
      // is the whole 48 (the strokes are drawn over its top and bottom edge),
      // so a control inside it (the reveal, the clear, a stepper) takes its
      // 48 too, whatever the size, the density or the style.
      final touchLine =
          widget.minHeight > 0 &&
          widget.touchTarget &&
          Fluent2Layout.padded(context);
      final least = touchLine
          ? math.max(set, Fluent2Layout.touchHitTarget)
          : set;
      final rims = touchLine
          ? EdgeInsets.only(left: strokes.left, right: strokes.right)
          : strokes;
      final room =
          look.padding(Directionality.of(context)) ??
          t.density.padding(widget.padding.resolve(Directionality.of(context)));
      final grow = enabled && widget.focused ? 1.0 : 0.0;
      final duration = !Fluent2Motion.on(context)
          ? Duration.zero
          : widget.focused
          ? Fluent2Motion.normal
          : Fluent2Motion.ultraFast;
      final frame = MouseRegion(
        cursor: enabled ? widget.cursor : SystemMouseCursors.basic,
        onEnter: enabled ? (_) => setState(() => _hover = true) : null,
        onExit: enabled ? (_) => setState(() => _hover = false) : null,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: grow),
          duration: duration,
          curve: widget.focused
              ? Fluent2Motion.decelerateMid
              : Fluent2Motion.accelerateMid,
          builder: (context, g, child) => CustomPaint(
            painter: _FrameGround(fill, radius),
            foregroundPainter: _FrameStrokes(
              side: sideInk,
              bottom: bottomInk,
              width: rim?.width ?? Fluent2ChromeMetrics.hairline,
              thick: Fluent2Stroke.thick,
              radius: radius,
              underlineOnly: square,
              grow: g,
              brand: widget.pressed
                  ? t.colors.compoundBrandStrokePressed
                  : t.colors.compoundBrandStroke,
            ),
            child: child,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: least),
            child: Padding(padding: rims.add(room), child: widget.child),
          ),
        ),
      );
      // A text field's words, flags and actions gather in one node the
      // frame's size (Material's field is its decorator's), not the line's;
      // under a Fluent2FormField the field's own node is already the frame.
      if (!widget.textNode || Fluent2FieldScope.maybeOf(context) != null) {
        return frame;
      }
      return Semantics(container: true, child: frame);
    });
  }
}

class _FrameGround extends CustomPainter {
  const _FrameGround(this.fill, this.radius);

  final Color fill;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (fill.a == 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(math.min(radius, size.shortestSide / 2)),
      ),
      Paint()..color = fill,
    );
  }

  @override
  bool shouldRepaint(_FrameGround old) =>
      old.fill != fill || old.radius != radius;
}

class _FrameStrokes extends CustomPainter {
  const _FrameStrokes({
    required this.side,
    required this.bottom,
    required this.width,
    required this.thick,
    required this.radius,
    required this.underlineOnly,
    required this.grow,
    required this.brand,
  });

  final Color side;
  final Color bottom;
  final double width;
  final double thick;
  final double radius;
  final bool underlineOnly;
  final double grow;
  final Color brand;

  @override
  void paint(Canvas canvas, Size size) {
    final w = width;
    final radius = math.min(this.radius, size.shortestSide / 2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    if (underlineOnly) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - w, size.width, w),
        Paint()..color = bottom,
      );
    } else {
      final edge = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(w / 2),
        Radius.circular(math.max(0, radius - w / 2)),
      );
      if (side.a > 0) canvas.drawRRect(edge, stroke..color = side);
      if (bottom != side && bottom.a > 0) {
        canvas.save();
        canvas.clipRect(
          Rect.fromLTRB(
            0,
            size.height - math.max(radius, w),
            size.width,
            size.height,
          ),
        );
        canvas.drawRRect(edge, stroke..color = bottom);
        canvas.restore();
      }
    }
    if (grow <= 0) return;
    // The underline: 2 flat across, its ends rounded as the field's
    // bottom corners are, scaled from the middle.
    final r = Radius.circular(radius);
    canvas.save();
    canvas.clipRRect(
      RRect.fromLTRBAndCorners(
        0,
        size.height - math.max(thick, radius),
        size.width,
        size.height,
        bottomLeft: r,
        bottomRight: r,
      ),
    );
    final run = size.width * grow;
    canvas.drawRect(
      Rect.fromLTWH((size.width - run) / 2, size.height - thick, run, thick),
      Paint()..color = brand,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FrameStrokes old) =>
      old.side != side ||
      old.bottom != bottom ||
      old.width != width ||
      old.thick != thick ||
      old.radius != radius ||
      old.underlineOnly != underlineOnly ||
      old.grow != grow ||
      old.brand != brand;
}

/// A field-faced button (a dropdown's, a date picker's): it takes focus
/// and Enter, Space and the down arrow ([onOpen]), the pointer's hover and
/// click, and says it is a button that opens [hint]; the face is
/// [builder]'s, told whether the field is focused (the brand underline is
/// Fluent's focus indicator on a field, not a ring) and pressed.
class Fluent2FieldButton extends StatefulWidget {
  /// A field-faced button that opens what [onOpen] shows.
  const Fluent2FieldButton({
    required this.onOpen,
    required this.builder,
    required this.label,
    this.value,
    this.hint,
    this.expanded,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Called when the button is pressed or opened from the keyboard; null puts
  /// it out of use.
  final VoidCallback? onOpen;

  /// Builds the face, told whether the button is focused and pressed.
  final Widget Function(BuildContext context, bool focused, bool pressed)
  builder;

  /// What a screen reader calls the button.
  final String label;

  /// The chosen value's words, read with [label].
  final String? value;

  /// The words read while nothing is chosen.
  final String? hint;

  /// Whether what it opens is open, as a screen reader reads it; null says
  /// nothing.
  final bool? expanded;

  /// The focus node it takes focus with; null makes its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first builds.
  final bool autofocus;

  @override
  State<Fluent2FieldButton> createState() => _Fluent2FieldButtonState();
}

class _Fluent2FieldButtonState extends State<Fluent2FieldButton> {
  FocusNode? _own;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final open = widget.onOpen;
    final live = open != null;
    // A field shows its focus (the brand underline) however it came, a tap
    // or the keyboard: the focus is read here, not from the press's states.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (f) => setState(() => _focused = f),
      child: DesignPressable(
        onPressed: live
            ? () {
                _node.requestFocus();
                open();
              }
            : null,
        focusNode: _node,
        autofocus: widget.autofocus,
        onKeyEvent: live
            ? (node, event) {
                if (event is! KeyDownEvent ||
                    event.logicalKey != LogicalKeyboardKey.arrowDown) {
                  return KeyEventResult.ignored;
                }
                open();
                return KeyEventResult.handled;
              }
            : null,
        semanticLabel: widget.label,
        semanticValue: widget.value,
        semanticHint: widget.hint,
        expanded: widget.expanded,
        excludeSemantics: true,
        enableFeedback: false,
        builder: (context, states, _) =>
            widget.builder(context, _focused, states.pressed),
      ),
    );
  }
}

/// Holds a popover under (or, short of room, over) its [child]: Fluent's
/// `positioning="below-start"` with a 4 gap, as wide as the child (at
/// least [minWidth]) or [width], at most [maxHeight] tall and never past
/// the window's edge less 8; a tap outside both, or Escape, calls
/// [onDismiss]. Shown and hidden through [controller]. The popover
/// follows its anchor as the page scrolls.
class Fluent2FieldPopover extends StatefulWidget {
  /// Anchors the popover [popover] builds to [child], shown while [controller]
  /// shows it.
  const Fluent2FieldPopover({
    required this.controller,
    required this.popover,
    required this.child,
    this.onDismiss,
    this.width,
    this.minWidth = 160,
    this.maxHeight = 360,
    this.groupId,
    super.key,
  });

  /// Shows and hides the popover.
  final OverlayPortalController controller;

  /// The tap region the anchor and the popover share (a text field inside
  /// the anchor passes the same id, so a tap in the popover does not take
  /// its focus); null keeps one of the popover's own.
  final Object? groupId;

  /// Builds what the popover holds.
  final Widget Function(BuildContext context) popover;

  /// The anchor: the field the popover opens from.
  final Widget child;

  /// Called when a tap outside or Escape closes the popover.
  final VoidCallback? onDismiss;

  /// The popover's width; null is the anchor's, at least [minWidth].
  final double? width;

  /// The narrowest the popover stands.
  final double minWidth;

  /// The tallest the popover stands before it scrolls.
  final double maxHeight;

  @override
  State<Fluent2FieldPopover> createState() => _Fluent2PopoverState();
}

class _Fluent2PopoverState extends State<Fluent2FieldPopover> {
  final _link = LayerLink();
  final _anchor = GlobalKey();

  Object get _group => widget.groupId ?? this;

  @override
  Widget build(BuildContext context) => TapRegion(
    groupId: _group,
    child: CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: widget.controller,
        overlayChildBuilder: _overlay,
        child: KeyedSubtree(key: _anchor, child: widget.child),
      ),
    ),
  );

  Widget _overlay(BuildContext context) {
    final anchor = _anchor.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(this.context).context.findRenderObject() as RenderBox?;
    if (anchor == null || overlay == null || !anchor.hasSize) {
      return const SizedBox.shrink();
    }
    final origin = anchor.localToGlobal(Offset.zero, ancestor: overlay);
    final rect = origin & anchor.size;
    final screen = overlay.size;
    final media = MediaQuery.of(context);
    const edge = Fluent2Spacing.s;
    const gap = Fluent2Spacing.xs;
    final below =
        screen.height -
        math.max(media.viewInsets.bottom, media.padding.bottom) -
        rect.bottom -
        gap -
        edge;
    final above = rect.top - media.padding.top - gap - edge;
    final down = below >= math.min(widget.maxHeight, 200) || below >= above;
    final room = math.max(48.0, down ? below : above);
    final width = (widget.width ?? rect.width)
        .clamp(
          math.min(widget.minWidth, screen.width - 2 * edge),
          screen.width - 2 * edge,
        )
        .toDouble();
    final rtl = Directionality.of(this.context) == TextDirection.rtl;
    final start = rtl ? rect.right - width : rect.left;
    var dx = rtl ? rect.width - width : 0.0;
    if (start + width > screen.width - edge) {
      dx -= start + width - (screen.width - edge);
    }
    if (start + dx < edge) dx += edge - (start + dx);
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: down ? Alignment.bottomLeft : Alignment.topLeft,
        followerAnchor: down ? Alignment.topLeft : Alignment.bottomLeft,
        offset: Offset(dx, down ? gap : -gap),
        child: TapRegion(
          groupId: _group,
          onTapOutside: (_) => widget.onDismiss?.call(),
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  widget.onDismiss?.call(),
            },
            child: SizedBox(
              width: width,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: math.min(widget.maxHeight, room),
                ),
                child: widget.popover(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fluent's popover surface: `neutralBackground1` at the control corner
/// (4) in `shadow16`, a hairline of `neutralStroke2` in the dark (as the
/// menu draws it), its content clipped and [padding] round it (the
/// listbox's 4; a popover's 12).
class Fluent2PopoverSurface extends StatelessWidget {
  /// A popover's surface round [child].
  const Fluent2PopoverSurface({
    required this.child,
    this.padding = const EdgeInsets.all(Fluent2Spacing.xs),
    super.key,
  });

  /// What the surface holds.
  final Widget child;

  /// The room round [child]; null is Fluent's own.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final look = Fluent2StyleOf([t.menuTheme], const {});
    return Fluent2Plate(
      fill: look.fill ?? t.colors.neutralBackground1,
      side: fluent2Rim(
        t,
        look,
        t.isDark ? t.colors.neutralStroke2 : t.colors.transparentStroke,
      ),
      radius: BorderRadius.circular(Fluent2Radius.medium),
      shape: look.shape,
      shadows: t.shadows.shadow16,
      padding: look.padding(Directionality.of(context)) ?? padding,
      clip: true,
      child: child,
    );
  }
}

/// One option row of Fluent's listbox (`Option`): 6 over and under and 8
/// at the sides, its corners 4, the check (16) before its words while
/// [selected] (a 16 box with the brand fill when [multiselect]), a glyph,
/// the words in body1 and a [secondary] line in caption1; the hover and
/// pressed neutral fills; [active] draws the 2 `strokeFocus2` ring the
/// keyboard's active option wears. 32 tall on the desktop, 44 on a phone.
class Fluent2OptionRow extends StatelessWidget {
  /// A pressable listbox row for [label].
  const Fluent2OptionRow({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
    this.secondary,
    this.multiselect = false,
    this.highlighted = false,
    this.focusNode,
    super.key,
  });

  /// The option's words.
  final String label;

  /// Whether the option is chosen (a check mark shows).
  final bool selected;

  /// Called when the option is pressed; null draws it disabled.
  final VoidCallback? onPressed;

  /// The glyph before [label]; null shows none.
  final IconData? icon;

  /// Quieter words at the row's end; null shows none.
  final String? secondary;

  /// Whether the listbox takes several options (a check box rather than a check
  /// mark).
  final bool multiselect;

  /// Whether the keyboard's highlight is on the row.
  final bool highlighted;

  /// The focus node the row takes focus with; null makes its own.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => Fluent2Pressable(
    onPressed: onPressed,
    label: label,
    value: secondary,
    selected: selected,
    focusNode: focusNode,
    radius: Fluent2Radius.medium,
    builder: (context, states) => Fluent2OptionFace(
      label: label,
      selected: selected,
      states: states,
      icon: icon,
      secondary: secondary,
      multiselect: multiselect,
      highlighted: highlighted,
    ),
  );
}

/// The face of a listbox option for its [states]: the check, the glyph, the
/// words and the second word, the subtle fill under the pointer, the ring
/// while it is [highlighted]. Plumbing of the listboxes.
class Fluent2OptionFace extends StatelessWidget {
  /// The face of a listbox row for [label] in [states].
  const Fluent2OptionFace({
    required this.label,
    required this.selected,
    required this.states,
    this.icon,
    this.secondary,
    this.multiselect = false,
    this.highlighted = false,
    super.key,
  });

  /// The option's words.
  final String label;

  /// Whether the option is chosen.
  final bool selected;

  /// The row's states (hovered, pressed, disabled), which pick its fill and
  /// ink.
  final Set<WidgetState> states;

  /// The glyph before [label]; null shows none.
  final IconData? icon;

  /// Quieter words at the row's end; null shows none.
  final String? secondary;

  /// Whether the listbox takes several options.
  final bool multiselect;

  /// Whether the keyboard's highlight is on the row.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final wide = Fluent2Layout.popsOver(context);
    final press = states.press;
    final ink = press.pick(
      c.neutralForeground1,
      c.neutralForeground1Hover,
      c.neutralForeground1Pressed,
      c.neutralForegroundDisabled,
    );
    final Widget check;
    if (multiselect) {
      final off = press == Fluent2Press.disabled;
      check = Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected && !off
              ? c.compoundBrandBackground
              : c.transparentBackground,
          borderRadius: BorderRadius.circular(Fluent2Radius.small),
          border: Border.all(
            color: off
                ? c.neutralForegroundDisabled
                : selected
                ? c.compoundBrandBackground
                : c.neutralStrokeAccessible,
          ),
        ),
        child: selected
            ? Icon(
                Fluent2Icons.checkmark12Filled,
                size: 12,
                color: off
                    ? c.neutralForegroundDisabled
                    : c.neutralForegroundInverted,
              )
            : null,
      );
    } else {
      check = SizedBox(
        width: 16,
        child: selected
            ? Icon(Fluent2Icons.checkmark16Filled, size: 16, color: ink)
            : null,
      );
    }
    return Container(
      constraints: BoxConstraints(
        minHeight: wide
            ? Fluent2ChromeMetrics.menuItem
            : Fluent2ChromeMetrics.menuItemTouch,
      ),
      // The check stands 2 into the start room and 2 + 4 before the
      // words (Fluent's negative margin and column gap).
      padding: const EdgeInsetsDirectional.fromSTEB(
        Fluent2Spacing.sNudge,
        Fluent2Spacing.sNudge,
        Fluent2Spacing.s,
        Fluent2Spacing.sNudge,
      ),
      decoration: BoxDecoration(
        color: press.pick(
          c.transparentBackground,
          c.neutralBackground1Hover,
          c.neutralBackground1Pressed,
          c.transparentBackground,
        ),
        borderRadius: BorderRadius.circular(Fluent2Radius.medium),
      ),
      foregroundDecoration: highlighted
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(Fluent2Radius.medium),
              border: Border.all(
                color: c.strokeFocus2,
                width: Fluent2Stroke.thick,
              ),
            )
          : null,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              end: Fluent2Spacing.sNudge,
            ),
            child: check,
          ),
          if (icon != null) ...[
            Icon(icon, size: 20, color: ink),
            const SizedBox(width: Fluent2Spacing.xs),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.body1.c(ink),
            ),
          ),
          if (secondary != null) ...[
            const SizedBox(width: Fluent2Spacing.s),
            Flexible(
              child: Text(
                secondary!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.caption1.c(
                  press == Fluent2Press.disabled
                      ? c.neutralForegroundDisabled
                      : c.neutralForeground3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The listbox column: its rows 2 apart, scrolling once they outgrow the
/// popover; an [empty] line in the third ink when nothing matches.
class Fluent2ListboxColumn extends StatelessWidget {
  /// A column of listbox rows.
  const Fluent2ListboxColumn({
    required this.children,
    this.empty,
    this.controller,
    super.key,
  });

  /// The rows, in order.
  final List<Widget> children;

  /// The line when nothing matches; null is "No matches" in the app's
  /// language.
  final String? empty;

  /// The scroll controller of the column; null makes its own.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    if (children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Fluent2Spacing.s,
          vertical: Fluent2Spacing.sNudge,
        ),
        child: Text(
          empty ?? DesignLocalizations.of(context).noResultsLabel,
          style: t.body1.c(t.textTertiary),
        ),
      );
    }
    return SingleChildScrollView(
      controller: controller,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Fluent2Spacing.xxs,
        children: children,
      ),
    );
  }
}
