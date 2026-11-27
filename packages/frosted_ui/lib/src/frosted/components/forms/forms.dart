import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show
        InputBorder,
        InputDecoration,
        Material,
        MaterialType,
        TextField,
        Theme,
        VisualDensity;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../internal/css_shadow.dart';
import '../../internal/face.dart';
import '../../internal/well.dart';
import '../../internal/field_owner.dart';
import '../../internal/styled.dart';
import '../../internal/bare_field.dart';
import '../../internal/hit_slop.dart';
import '../../theme.dart';
import '../icon-button/round_button.dart';
import '../menu/menu.dart';
import '../pickers/pickers.dart' show showFrostedDatePicker;
import '../pressable/pressable.dart';
import '../../localizations.dart';
import '../../editing.dart';
import '../../internal/dim.dart';
import '../../internal/cap.dart';
import '../../internal/measure.dart' show FrostedFieldWidth;

import 'package:ui_core/ui_core.dart';

// metric: `.stepper .inp--amt { width: 3ch }`, the stepper's figure room
// (FrostedChromeMetrics names the well, not the input's width).
const int _stepperFigureChars = 3;

// metric: `.inp--amt::placeholder { color: rgba(21,21,45,.22) }`, the amount
// well's placeholder share of the ink (no FrostedThemeData role names it).
const double _amountPlaceholderOpacity = 0.22;

// metric: `.search { font: 400 16px/1 var(--font-t) }`, the search pill's
// line (FrostedChromeMetrics names the pill's height, inset and glyph).
const double _searchLine = 16;

// metric: `.search--on { background: rgba(255,255,255,.9) }`, the search
// pill's face once it holds a query, as a share of the plane.
const double _searchTypedOpacity = 0.9;

// metric: `.swap span { box-shadow: ..., 0 4px 10px -6px rgba(42,36,100,.3) }`,
// the swap disc's lift in the raised shade (FrostedThemeData.raisedShadow is the
// softer 0 2px 6px -2px at .18).
const double _swapShadowY = 4;
const double _swapShadowBlur = 10;
const double _swapShadowSpread = -6;
const double _swapShadowOpacity = 0.3;

/// A hairline ring just outside a white or glass face, taking no room, as
/// the tiles draw it.
BoxShadow _edge(FrostedThemeData t) =>
    frostedShadow(color: t.glass.edge, spread: FrostedChromeMetrics.outline);

// ---------------------------------------------------------------------------
// Text field
// ---------------------------------------------------------------------------

/// A line of text in a well: the label 8 over a 48 well, 12
/// round, 14 in at each side, the text 400 16 in the ink and the placeholder in
/// the tertiary ink, an optional help line 8 under. The page owns the text
/// through [value] and [onChanged], or hands a [controller]; with neither
/// callback nor controller the field is read only. A screen reader hears a text
/// field named [labelText].
///
/// ```dart
/// FrostedTextField(labelText: 'Name', hintText: 'What are you saving for?', value: name, onChanged: (v) => setState(() => name = v))
/// ```
class FrostedTextField extends StatefulWidget {
  /// Creates a [FrostedTextField].
  const FrostedTextField({
    required this.labelText,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.controller,
    this.focusNode,
    this.hintText,
    this.helperText,
    this.leading,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.errorText,
    this.enabled = true,
    this.obscureText = false,
    this.autofillHints,
    this.inputFormatters,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.style,
    this.textDirection,
    super.key,
  });

  /// The label over the well, and the field's spoken name.
  final String labelText;

  /// The direction the words are typed in; null follows the page. Codes,
  /// addresses and hex values read left to right in any language
  /// ([TextDirection.ltr]): under a right-to-left page "#FF7A59B3" would
  /// otherwise show as "FF7A59B3#".
  final TextDirection? textDirection;

  /// The fewest lines the well stands for; null for one.
  final int? minLines;

  /// The most lines the well grows to before it scrolls; 1 is a single
  /// line, null grows without end ([FrostedTextArea] sets several).
  final int? maxLines;

  /// What is wrong with the text: drawn under the well in the over ink, in
  /// place of [helperText], with the well's edge in the same ink.
  final String? errorText;

  /// Whether the field takes text; a disabled field stands at half strength
  /// and takes no focus.
  final bool enabled;

  /// Whether the text is hidden as it is typed (a passcode).
  final bool obscureText;

  /// What the platform's autofill may offer (`AutofillHints.email`,...).
  final Iterable<String>? autofillHints;

  /// What the text is held to as it is typed.
  final List<TextInputFormatter>? inputFormatters;

  /// The longest the text may grow, in characters.
  final int? maxLength;

  /// The text, when the page owns it.
  final String? value;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// Called with the text when the keyboard's done key is pressed; the field
  /// then lets the focus go. A field that keeps the focus after Enter takes
  /// it in [onEditingComplete] instead: never both.
  final ValueChanged<String>? onSubmitted;

  /// Takes the keyboard's done key in place of [onSubmitted], for a field
  /// that keeps the focus after Enter (an "add another" field): the focus
  /// stays where it is. In a browser, typing after Enter goes nowhere in a
  /// field that keeps the focus through [onSubmitted].
  final VoidCallback? onEditingComplete;

  /// The text's controller, when the page keeps one.
  final TextEditingController? controller;

  /// The field's focus, when the page keeps one.
  final FocusNode? focusNode;

  /// What the empty well says (What are you saving for?).
  final String? hintText;

  /// {@macro frosted.helper}
  final String? helperText;

  /// A glyph or word before the text, drawn in the tertiary ink.
  final Widget? leading;

  /// A control after the text.
  final Widget? trailing;

  /// Which keyboard it raises.
  final TextInputType? keyboardType;

  /// This field's own style, over `FrostedThemeData.components.textField`:
  /// the well's fill, the text's colour and style, the ring's colour or a
  /// whole side, an overlay, its shape ([FrostedCorners.small] by
  /// default), padding and least size, each per state (focused, error,
  /// disabled).
  ///
  /// ```dart
  /// FrostedTextField(
  ///   labelText: 'Name',
  ///   value: name,
  ///   onChanged: setName,
  ///   style: FrostedStyle(
  ///     edge: WidgetStateProperty.resolveWith(
  ///       (states) => states.contains(WidgetState.focused)
  ///           ? const Color(0xFF5B5BD6)
  ///           : null,
  ///     ),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  /// The keyboard's done key.
  final TextInputAction? textInputAction;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  @override
  State<FrostedTextField> createState() => _FrostedTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(
        EnumProperty<TextDirection>(
          'textDirection',
          textDirection,
          defaultValue: null,
        ),
      )
      ..add(IntProperty('minLines', minLines, defaultValue: null))
      ..add(IntProperty('maxLines', maxLines, defaultValue: 1))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        FlagProperty('obscureText', value: obscureText, ifTrue: 'obscureText'),
      )
      ..add(
        IterableProperty<String>(
          'autofillHints',
          autofillHints,
          defaultValue: null,
        ),
      )
      ..add(
        IterableProperty<TextInputFormatter>(
          'inputFormatters',
          inputFormatters,
          defaultValue: null,
        ),
      )
      ..add(IntProperty('maxLength', maxLength, defaultValue: null))
      ..add(StringProperty('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<FrostedStyle>('style', style, defaultValue: null),
      )
      ..add(
        EnumProperty<TextInputAction>(
          'textInputAction',
          textInputAction,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

class _FrostedTextFieldState extends State<FrostedTextField>
    with FrostedFieldOwner<FrostedTextField> {
  @override
  TextEditingController? controllerOf(FrostedTextField w) => w.controller;

  @override
  String? valueOf(FrostedTextField w) => w.value;

  @override
  FocusNode? focusNodeOf(FrostedTextField w) => w.focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // .inp { height: 48px; padding: 0 14px; border-radius: 12px;
    //   font: 400 16px/1.2 var(--font-t); color: var(--ink) }
    // .inp::placeholder { color: var(--ink-3) }
    final layers = FrostedStyleLayers(widget.style, t.components.textField);
    final style = layers
        .at({
          if (fieldFocus.hasFocus) WidgetState.focused,
          if (widget.errorText != null) WidgetState.error,
          if (!widget.enabled) WidgetState.disabled,
        })
        .words(t.textTheme.bodyLarge.line(19.2));
    final readOnly = widget.onChanged == null && widget.controller == null;
    final multi = widget.maxLines != 1;
    // The well is at least the field's height and grows with larger text;
    // one line stands on its centre by alignment. Several lines start
    // where the one line stands: half the well's room over the line.
    final line =
        MediaQuery.textScalerOf(context).scale(style.fontSize ?? 16) *
        (style.height ?? 1.2);
    final over = multi
        ? ((FrostedChromeMetrics.field - line) / 2).clamp(0.0, double.infinity)
        : 0.0;
    final maxLength = widget.maxLength;
    // The label, help and error are read on the field's one node; what is
    // drawn of them stays out of the tree.
    return RawInputDecorator(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: widget.enabled,
      focusNode: fieldFocus,
      builder: frostedFieldColumn,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: FrostedChromeMetrics.field,
        ),
        child: FrostedWell(
          layers: layers,
          focused: fieldFocus.hasFocus,
          error: widget.errorText != null,
          enabled: widget.enabled,
          padding: EdgeInsets.symmetric(
            horizontal: FrostedChromeMetrics.fieldInset,
            vertical: over,
          ),
          // The line answers taps from the well's top to its bottom.
          child: FrostedFieldRoom(
            child: Row(
              crossAxisAlignment: multi
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                if (widget.leading case final leading?) ...[
                  DefaultTextStyle.merge(
                    style: style.c(t.colorScheme.textTertiary),
                    child: IconTheme.merge(
                      data: IconThemeData(
                        size: FrostedIconSize.i18,
                        color: t.colorScheme.textTertiary,
                      ),
                      child: leading,
                    ),
                  ),
                  const SizedBox(width: FrostedSpacing.s8),
                ],
                Expanded(
                  child: FrostedFieldTarget(
                    label: widget.labelText,
                    // The field round it names the node.
                    ownNode: false,
                    child: frostedOpenEntry(
                      context,
                      Material(
                        type: MaterialType.transparency,
                        child: frostedCapCentredEntry(
                          style,
                          one: !multi,
                          TextField(
                            contextMenuBuilder: FrostedTextContextMenu.editable,
                            selectionControls: FrostedTextSelectionControls.of(
                              Theme.of(context).platform,
                            ),
                            controller: fieldController,
                            focusNode: fieldFocus,
                            textDirection: widget.textDirection,
                            autofocus: widget.autofocus,
                            readOnly: readOnly,
                            enabled: widget.enabled,
                            obscureText: widget.obscureText,
                            autofillHints: widget.autofillHints,
                            // The length is held by a formatter: a maxLength
                            // on the TextField adds a counter line under it.
                            inputFormatters: [
                              ...?widget.inputFormatters,
                              if (maxLength != null)
                                LengthLimitingTextInputFormatter(maxLength),
                            ],
                            minLines: widget.minLines,
                            maxLines: widget.maxLines,
                            onChanged: widget.onChanged,
                            onSubmitted: widget.onSubmitted,
                            onEditingComplete: widget.onEditingComplete,
                            keyboardType:
                                widget.keyboardType ??
                                (multi ? TextInputType.multiline : null),
                            textInputAction:
                                widget.textInputAction ??
                                (multi ? TextInputAction.newline : null),
                            style: style,
                            cursorColor: t.colorScheme.textPrimary,
                            decoration: _bareDecoration(
                              hint: widget.hintText,
                              hintStyle: style.c(t.colorScheme.textTertiary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // A trailing key keeps to the field's end keyline.
                // A key beside the entry (a password's reveal) keeps a node
                // of its own, so the entry's node stays the field's.
                if (widget.trailing case final trailing?) ...[
                  const SizedBox(width: FrostedSpacing.s8),
                  FrostedTargetSide(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Semantics(container: true, child: trailing),
                  ),
                ]
                // Wrong, the field shows the danger's mark at its end; the
                // message under it says what is wrong.
                else
                  _ErrorMarkSlot(
                    shown: widget.errorText != null,
                    gap: FrostedSpacing.s8,
                    mark: _errorMark(t),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A field for a few lines of text (a note, a message, a description):
/// [FrostedTextField]'s well standing [minLines] lines tall and growing to
/// [maxLines] before it scrolls, its label over it and its help or error
/// under it. Return starts a new line.
///
/// ```dart
/// FrostedTextArea(labelText: 'Notes', hintText: 'Anything the team should know', value: notes, onChanged: (v) => setState(() => notes = v))
/// ```
class FrostedTextArea extends StatelessWidget {
  /// A text area labelled [labelText].
  const FrostedTextArea({
    required this.labelText,
    this.value,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
    this.minLines = 3,
    this.maxLines = 8,
    super.key,
  });

  /// The label over the well, and the field's spoken name.
  final String labelText;

  /// The text, when the page owns it.
  final String? value;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// The text's controller, when the page keeps one.
  final TextEditingController? controller;

  /// The field's focus, when the page keeps one.
  final FocusNode? focusNode;

  /// The words in the empty well.
  final String? hintText;

  /// One line of help under the well.
  final String? helperText;

  /// What is wrong with the text, in place of [helperText].
  final String? errorText;

  /// Whether it takes text.
  final bool enabled;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// The longest the text may grow, in characters.
  final int? maxLength;

  /// The lines it stands at empty, and the most it grows to.
  final int minLines;

  /// The most lines it grows to before it scrolls.
  final int maxLines;

  @override
  Widget build(BuildContext context) => FrostedTextField(
    labelText: labelText,
    value: value,
    onChanged: onChanged,
    controller: controller,
    focusNode: focusNode,
    hintText: hintText,
    helperText: helperText,
    errorText: errorText,
    enabled: enabled,
    autofocus: autofocus,
    maxLength: maxLength,
    minLines: minLines,
    maxLines: maxLines,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(StringProperty('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(IntProperty('maxLength', maxLength, defaultValue: null))
      ..add(IntProperty('minLines', minLines, defaultValue: 3))
      ..add(IntProperty('maxLines', maxLines, defaultValue: 8));
  }
}

// ---------------------------------------------------------------------------
// Amount field
// ---------------------------------------------------------------------------

/// How large a [FrostedAmountField] stands.
enum FrostedAmountFieldSize {
  /// A 64 well, 14 round, the figure 500 40 in the display face: a page's
  /// own amount.
  regular,

  /// A 48 well, 12 round, the figure 400 16 in the text face on the centre
  /// line: an amount among a form's fields.
  small,
}

/// An amount in a well: the label 8 over a 64 well, 14 round, with the dollar
/// sign in the quiet ink (500 16 display, dropped 6) before the figure in the
/// 500 40 display face, tabular and tracked −.03em, 12 under the top; the
/// placeholder at .22 of the ink. A small [size] is a form's:
/// a 48 well, 12 round, the figure 400 16 in the text face on the centre line.
/// [centered] is a stepper's: the sign and figure together on
/// the well's centre, the figure given three characters' room. [showLabel]
/// false drops the label, keeping it as the spoken name. Takes digits and one
/// point; the page owns the text through [value] and [onChanged], or a
/// [controller]; with neither it is read only. A screen reader hears a text
/// field named [labelText].
///
/// ```dart
/// FrostedAmountField(labelText: 'Amount', value: amount, onChanged: (v) => setState(() => amount = v))
/// ```
class FrostedAmountField extends StatefulWidget {
  /// Creates a [FrostedAmountField].
  const FrostedAmountField({
    required this.labelText,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.controller,
    this.focusNode,
    this.inputFormatters,
    this.keyboardType,
    this.hintText = '0',
    this.helperText,
    this.sign = r'$',
    this.suffix,
    this.size = FrostedAmountFieldSize.regular,
    this.centered = false,
    this.showLabel = true,
    this.autofocus = false,
    super.key,
  });

  /// The label over the well, and the field's spoken name.
  final String labelText;

  /// The figure's text, when the page owns it (500.00).
  final String? value;

  /// Called as the figure changes.
  final ValueChanged<String>? onChanged;

  /// Called with the figure when the keyboard's done key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Called as Enter takes what is typed, the focus staying in the field
  /// (a number field's commit); null: none.
  final VoidCallback? onEditingComplete;

  /// What may be typed; null: figures and the decimal point.
  final List<TextInputFormatter>? inputFormatters;

  /// The keyboard it asks for; null: figures with a decimal point.
  final TextInputType? keyboardType;

  /// The figure's controller, when the page keeps one.
  final TextEditingController? controller;

  /// The field's focus, when the page keeps one.
  final FocusNode? focusNode;

  /// What the empty well shows after the sign.
  final String hintText;

  /// The currency sign before the figure, in the quiet ink; null, none (a
  /// plain number).
  final String? sign;

  /// Words after the figure, in the quiet ink (a unit: "people"); null,
  /// none.
  final String? suffix;

  /// {@macro frosted.helper}
  final String? helperText;

  /// How large the field stands: the 64 well, or the form's 48.
  final FrostedAmountFieldSize size;

  /// The sign and figure on the well's centre.
  final bool centered;

  /// Whether the [labelText] stands over the well; without it the label stays
  /// the spoken name.
  final bool showLabel;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  @override
  State<FrostedAmountField> createState() => _FrostedAmountFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(StringProperty('value', value, defaultValue: null))
      ..add(StringProperty('sign', sign, defaultValue: r'$'))
      ..add(StringProperty('suffix', suffix, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(
        IterableProperty<TextInputFormatter>(
          'inputFormatters',
          inputFormatters,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('hintText', hintText, defaultValue: '0'))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(
        EnumProperty<FrostedAmountFieldSize>(
          'size',
          size,
          defaultValue: FrostedAmountFieldSize.regular,
        ),
      )
      ..add(FlagProperty('centered', value: centered, ifTrue: 'centered'))
      ..add(
        FlagProperty(
          'showLabel',
          value: showLabel,
          ifFalse: 'showLabel: false',
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

class _FrostedAmountFieldState extends State<FrostedAmountField>
    with FrostedFieldOwner<FrostedAmountField> {
  static final _allowed = FilteringTextInputFormatter.allow(RegExp('[0-9.]'));

  @override
  TextEditingController? controllerOf(FrostedAmountField w) => w.controller;

  @override
  String? valueOf(FrostedAmountField w) => w.value;

  @override
  FocusNode? focusNodeOf(FrostedAmountField w) => w.focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final small = widget.size == FrostedAmountFieldSize.small;
    // .amount-in { align-items: flex-start; gap: 2px; height: 64px;
    //   padding: 12px 16px 0; border-radius: 14px }
    // .amount-in .cur { font: 500 16px/1 var(--font-d); color: var(--ink-q);
    //   margin-top: 6px }
    // .inp--amt { height: 40px; font: 500 40px/1 var(--font-d);
    //   letter-spacing: -.03em; font-variant-numeric: tabular-nums }
    // .amount-in--sm { height: 48px; align-items: center; padding: 0 14px;
    //   border-radius: 12px }  .amount-in--sm .cur { margin-top: 0 }
    // .amount-in--sm .inp--amt { font: 400 16px/1.2 var(--font-t) }
    final style = small
        ? t.textTheme.bodyLarge.line(19.2)
        : t.textTheme.displaySmall
              .line(FrostedChromeMetrics.amountWellFigure)
              .tracked(-0.03)
              .tabular;
    final placeholderInk = small
        ? t.colorScheme.textTertiary
        : t.colorScheme.textPrimary.withValues(
            alpha: _amountPlaceholderOpacity,
          );
    final readOnly = widget.onChanged == null && widget.controller == null;
    Widget input = FrostedFieldTarget(
      label: widget.labelText,
      // Under its shown label the decorator names the field, and the line
      // joins that node; with the label hidden, the line names it.
      ownNode: !widget.showLabel,
      child: Material(
        type: MaterialType.transparency,
        child: frostedCapCentredEntry(
          style,
          TextField(
            contextMenuBuilder: FrostedTextContextMenu.editable,
            selectionControls: FrostedTextSelectionControls.of(
              Theme.of(context).platform,
            ),
            controller: fieldController,
            focusNode: fieldFocus,
            autofocus: widget.autofocus,
            readOnly: readOnly,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onEditingComplete: widget.onEditingComplete,
            keyboardType:
                widget.keyboardType ??
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: widget.inputFormatters ?? [_allowed],
            style: style,
            cursorColor: t.colorScheme.textPrimary,
            decoration: _bareDecoration(
              hint: widget.hintText,
              hintStyle: style.c(placeholderInk),
            ),
          ),
        ),
      ),
    );
    if (widget.centered) {
      // .stepper .inp--amt { width: 3ch; text-align: left }: a ch is the
      // zero's own advance, without the figure's tracking or its tabular
      // figures (taken with them, the room stood 3.6 narrower and the
      // sign and figure 2.8 right of the source's).
      final room = TextPainter(
        text: TextSpan(
          text: '0' * _stepperFigureChars,
          style: style.copyWith(letterSpacing: 0, fontFeatures: const []),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = room.width;
      room.dispose();
      // A stepper's figure: its entry as tall as the rounds beside it
      // (48), so the row shows one top and one bottom; its capitals stay on
      // the middle.
      // Flexible: at large text the figure's room can outgrow the well, and
      // the entry then scrolls within what is left beside the sign.
      input = Flexible(
        child: _FigureFloor(
          floor: width,
          child: IntrinsicWidth(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: width,
                minHeight: FrostedChromeMetrics.stepper,
              ),
              child: input,
            ),
          ),
        ),
      );
    } else {
      input = Expanded(child: input);
    }
    // In a stepper the figure's line stands 4 lower in its 48 entry.
    final quietTop = small
        ? 0.0
        : FrostedChromeMetrics.amountWellCurrencyDrop +
              (widget.centered
                  ? (FrostedChromeMetrics.stepper -
                            FrostedChromeMetrics.amountWellFigure) /
                        2
                  : 0);
    final quiet = t.textTheme.titleMedium.display
        .line(FrostedChromeMetrics.amountWellCurrency)
        .c(t.colorScheme.textTertiary);
    final sign = widget.sign == null
        ? null
        : Padding(
            padding: EdgeInsets.only(top: quietTop),
            child: Text(
              widget.sign!,
              textScaler: TextScaler.noScaling,
              style: quiet,
            ),
          );
    // A unit after the figure, on the sign's line; words, so it grows with
    // the reader's text. It shares a narrow well with the figure rather than
    // pushing past it (a stepper's in a dialog).
    final suffix = widget.suffix == null
        ? null
        : Flexible(
            child: Padding(
              padding: EdgeInsets.only(top: quietTop),
              child: Text(
                widget.suffix!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: quiet,
              ),
            ),
          );
    // The well is at least its height and grows with larger text; the sign
    // and figure stand on its centre line by alignment, which at the
    // figure's own size is the source's 12 under the top.
    final well = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: small
            ? FrostedChromeMetrics.amountWellSmall
            : FrostedChromeMetrics.amountWell,
      ),
      child: FrostedWell(
        radius: small
            ? FrostedChromeMetrics.amountWellSmallRadius
            : FrostedChromeMetrics.amountWellRadius,
        focused: fieldFocus.hasFocus,
        padding: EdgeInsets.symmetric(
          horizontal: small
              ? FrostedChromeMetrics.amountWellSmallInset
              : FrostedChromeMetrics.amountWellInset,
        ),
        // heightFactor: given room to spare (a dialog, a tile with a
        // ceiling) the well keeps its own height rather than filling it.
        // The figure's line answers a tap anywhere in the well.
        child: FrostedFieldRoom(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            heightFactor: 1,
            // The sign before the figure, and the figure typed left to right,
            // in any language ("$500.00", never "500.00 $").
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: widget.centered
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                crossAxisAlignment: small
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                spacing: FrostedChromeMetrics.amountWellGap,
                children: [?sign, input, ?suffix],
              ),
            ),
          ),
        ),
      ),
    );
    if (!widget.showLabel && widget.helperText == null) return well;
    return RawInputDecorator(
      labelText: widget.showLabel ? widget.labelText : null,
      helperText: widget.helperText,
      focusNode: fieldFocus,
      builder: frostedFieldColumn,
      child: well,
    );
  }
}

// ---------------------------------------------------------------------------
// Text form field
// ---------------------------------------------------------------------------

/// A [FrostedTextField] in a [Form], as Material's `TextFormField` is: its
/// [validator] runs when the form validates (or as [autovalidateMode] says)
/// and what it returns stands under the well as the field's error; [onSaved]
/// hands the text over when the form saves, and resetting the form brings
/// [initialValue] back. Keep the text in a [controller] or start it at
/// [initialValue], not both.
///
/// ```dart
/// FrostedTextFormField(labelText: 'Title', validator: (v) => (v ?? '').trim().isEmpty ? 'Give the book a title' : null, onSaved: (v) => title = v!)
/// ```
class FrostedTextFormField extends FormField<String> {
  /// A text field named [labelText] that takes part in its [Form].
  FrostedTextFormField({
    required String labelText,
    this.controller,
    String? initialValue,
    FocusNode? focusNode,
    String? hintText,
    String? helperText,
    Widget? leading,
    Widget? trailing,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool autofocus = false,
    bool obscureText = false,
    Iterable<String>? autofillHints,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    int? minLines,
    int? maxLines = 1,
    this.onChanged,
    ValueChanged<String>? onFieldSubmitted,
    VoidCallback? onEditingComplete,
    TextDirection? textDirection,
    FrostedStyle? style,
    super.onSaved,
    super.validator,
    super.forceErrorText,
    super.enabled,
    AutovalidateMode? autovalidateMode,
    super.key,
  }) : assert(
         initialValue == null || controller == null,
         'Start the text in the controller or at initialValue, not both.',
       ),
       super(
         initialValue: controller?.text ?? initialValue ?? '',
         autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
         builder: (field) {
           final state = field as _FrostedTextFormFieldState;
           return FrostedTextField(
             labelText: labelText,
             controller: state._controller,
             focusNode: focusNode,
             hintText: hintText,
             helperText: helperText,
             errorText: field.errorText,
             leading: leading,
             trailing: trailing,
             keyboardType: keyboardType,
             textInputAction: textInputAction,
             autofocus: autofocus,
             obscureText: obscureText,
             autofillHints: autofillHints,
             inputFormatters: inputFormatters,
             maxLength: maxLength,
             minLines: minLines,
             maxLines: maxLines,
             enabled: field.widget.enabled,
             textDirection: textDirection,
             style: style,
             onChanged: (text) {
               field.didChange(text);
               onChanged?.call(text);
             },
             onSubmitted: onFieldSubmitted,
             onEditingComplete: onEditingComplete,
           );
         },
       );

  /// The text's controller, when the page keeps one; without it the field
  /// keeps its own, started at the initial value.
  final TextEditingController? controller;

  /// Called as the text changes, and with the initial text when the form
  /// resets.
  final ValueChanged<String>? onChanged;

  @override
  FormFieldState<String> createState() => _FrostedTextFormFieldState();
}

class _FrostedTextFormFieldState extends FormFieldState<String> {
  TextEditingController? _own;

  FrostedTextFormField get _field => widget as FrostedTextFormField;

  TextEditingController get _controller => _field.controller ?? _own!;

  @override
  void initState() {
    super.initState();
    if (_field.controller == null) {
      _own = TextEditingController(text: widget.initialValue);
    }
    _controller.addListener(_fromController);
  }

  @override
  void didUpdateWidget(covariant FrostedTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_field.controller == oldWidget.controller) return;
    (oldWidget.controller ?? _own)?.removeListener(_fromController);
    if (_field.controller == null) {
      _own = TextEditingController.fromValue(oldWidget.controller?.value);
    } else {
      _own?.dispose();
      _own = null;
      setValue(_field.controller!.text);
    }
    _controller.addListener(_fromController);
  }

  @override
  void dispose() {
    _controller.removeListener(_fromController);
    _own?.dispose();
    super.dispose();
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    if (_controller.text != value) _controller.text = value ?? '';
  }

  @override
  void reset() {
    // The text goes back first, so the controller's listener finds nothing
    // changed.
    _controller.text = widget.initialValue ?? '';
    super.reset();
    _field.onChanged?.call(_controller.text);
  }

  // Text set on the controller by the page counts as the field's value.
  void _fromController() {
    if (_controller.text != value) didChange(_controller.text);
  }
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

/// The search pill's face: 44 tall on the brighter glass with
/// its rim and hairline edge, 16 in at each side; once it holds a query,
/// the plane at .9 and the ink.
class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.typed,
    required this.child,
    this.clearing = false,
    this.focused = false,
  });

  final bool typed;

  /// Whether the clear round stands at the end, pulled 6 into the inset.
  final bool clearing;

  /// Whether the field holds focus: the edge takes the accent, as a
  /// well's does.
  final bool focused;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // .search { gap: 10px; height: 44px; padding: 0 16px;
    //   border-radius: 999px; background: var(--glass-hi);
    //   box-shadow: var(--rim), var(--edge); color: var(--ink-3);
    //   font: 400 16px/1 var(--font-t) }  .search .i { 18px }
    // .search--on { color: var(--ink); background: rgba(255,255,255,.9) }
    // .search-x { margin-right: -6px }
    // The source's 44, at least a finger's target on every platform (the
    // pill is the box a tap reaches and a screen reader outlines), growing
    // with larger text; the line stands on its centre by the row's
    // alignment.
    final height = math.max(
      FrostedChromeMetrics.search,
      FrostedBreakpoints.touchTargetOf(context),
    );
    return FrostedFocusRing(
      shown: focused,
      radius: height / 2,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: FrostedFace(
          material: FrostedMaterial.well,
          radius: BorderRadius.circular(height / 2),
          color: typed || (focused && !t.isDark)
              ? t.glass.plane.withValues(alpha: _searchTypedOpacity)
              : null,
          // By day the well wears one even lit rim all round, by night the
          // night glass's rim; holding focus the glass lights up as every
          // part's does (FrostedFocusRing, round the pill below). Never a dark
          // line.
          sheen: t.isDark ? t.glass.rim : null,
          ring: t.isDark ? null : FrostedChromeMetrics.litEdge,
          shadows: [
            if (t.isDark)
              frostedShadow(
                color: t.controlEdge,
                spread: FrostedChromeMetrics.outline,
              ),
          ],
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: FrostedChromeMetrics.searchInset,
              end: clearing
                  ? FrostedChromeMetrics.searchInset -
                        FrostedChromeMetrics.searchClearPull
                  : FrostedChromeMetrics.searchInset,
            ),
            // The line answers taps from the pill's top to its bottom.
            child: FrostedFieldRoom(
              child: Row(
                spacing: FrostedChromeMetrics.searchGap,
                children: [
                  Icon(
                    FrostedGlyphs.search,
                    size: FrostedChromeMetrics.searchGlyph,
                    color: typed
                        ? t.colorScheme.textPrimary
                        : t.colorScheme.textTertiary,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A line of search: the pill with the 18 glass
/// glyph, the query 400 16 in the ink, the placeholder in the tertiary ink;
/// once it holds a query the pill brightens and a 28 round of the wash with a
/// 14 cross clears it. The page owns the query through [value] and [onChanged],
/// or hands a [controller]. [onClear] makes the clear a link of the page's
/// (back to the plain list); without it the clear empties the field. A screen
/// reader hears a search field named [labelText] (else [hintText]) and a
/// button, [clearLabel] (Clear).
///
/// ```dart
/// FrostedSearchField(hintText: 'Search activity', value: query, onChanged: (v) => setState(() => query = v))
/// ```
class FrostedSearchField extends StatefulWidget {
  /// Creates a [FrostedSearchField].
  const FrostedSearchField({
    required this.hintText,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.labelText,
    this.autofocus = false,
    this.onClear,
    this.clearLabel,
    this.clearKey,
    super.key,
  });

  /// What the empty pill says (Search activity).
  final String hintText;

  /// The query, when the page owns it.
  final String? value;

  /// Called as the query changes.
  final ValueChanged<String>? onChanged;

  /// Called with the query when the keyboard's search key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The query's controller, when the page keeps one.
  final TextEditingController? controller;

  /// The field's focus, when the page keeps one.
  final FocusNode? focusNode;

  /// The field's spoken name; null speaks [hintText].
  final String? labelText;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// Where the clear goes instead of emptying the field: the page's own
  /// way back to the plain list.
  final VoidCallback? onClear;

  /// What a screen reader calls the clear; null says `RawWidgetsLocalizations.clearButtonTooltip` ("Clear").
  final String? clearLabel;

  /// The walkthrough key set on the clear's hit target.
  final Key? clearKey;

  @override
  State<FrostedSearchField> createState() => _FrostedSearchFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('hintText', hintText))
      ..add(StringProperty('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(ObjectFlagProperty<VoidCallback>.has('onClear', onClear))
      ..add(StringProperty('clearLabel', clearLabel, defaultValue: null))
      ..add(DiagnosticsProperty<Key>('clearKey', clearKey, defaultValue: null));
  }
}

class _FrostedSearchFieldState extends State<FrostedSearchField>
    with FrostedFieldOwner<FrostedSearchField> {
  @override
  TextEditingController? controllerOf(FrostedSearchField w) => w.controller;

  @override
  String? valueOf(FrostedSearchField w) => w.value;

  @override
  FocusNode? focusNodeOf(FrostedSearchField w) => w.focusNode;

  void _clear() {
    fieldController.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final typed = fieldController.text.isNotEmpty;
    final style = t.textTheme.bodyLarge.line(_searchLine);
    // .search-x { width: 28px; height: 28px; border-radius: 999px;
    //   background: var(--wash); color: var(--ink-2) }  .search-x .i { 14px }
    // The clear keeps to the pill's end keyline, its target growing inward.
    final clear = FrostedTargetSide(
      alignment: AlignmentDirectional.centerEnd,
      child: FrostedPressable(
        key: widget.clearKey,
        onPressed: widget.onClear ?? _clear,
        semanticLabel:
            widget.clearLabel ??
            RawWidgetsLocalizations.of(context).clearButtonTooltip,
        role: widget.onClear == null
            ? FrostedPressRole.button
            : FrostedPressRole.link,
        radius: FrostedChromeMetrics.searchClear / 2,
        child: SizedBox.square(
          dimension: FrostedChromeMetrics.searchClear,
          child: FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(FrostedChromeMetrics.searchClear / 2),
            color: t.glass.wash,
            child: Center(
              child: Icon(
                FrostedGlyphs.close,
                size: FrostedChromeMetrics.searchClearGlyph,
                color: t.colorScheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
    return _SearchPill(
      typed: typed,
      clearing: typed,
      focused: fieldFocus.hasFocus,
      // As tall as the pill, so the line's room reaches its top and bottom.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: math.max(
            FrostedChromeMetrics.search,
            FrostedBreakpoints.touchTargetOf(context),
          ),
        ),
        child: Row(
          spacing: FrostedChromeMetrics.searchGap,
          children: [
            Expanded(
              child: FrostedFieldTarget(
                label: widget.labelText ?? widget.hintText,
                child: Material(
                  type: MaterialType.transparency,
                  child: frostedCapCentredEntry(
                    style,
                    TextField(
                      contextMenuBuilder: FrostedTextContextMenu.editable,
                      selectionControls: FrostedTextSelectionControls.of(
                        Theme.of(context).platform,
                      ),
                      controller: fieldController,
                      focusNode: fieldFocus,
                      autofocus: widget.autofocus,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      textInputAction: TextInputAction.search,
                      style: style.c(t.colorScheme.textPrimary),
                      cursorColor: t.colorScheme.textPrimary,
                      decoration: _bareDecoration(
                        hint: widget.hintText,
                        hintStyle: style.c(t.colorScheme.textTertiary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (typed) clear,
          ],
        ),
      ),
    );
  }
}

/// The search pill as a way in (`<a class="search">`): the same face and
/// glyph with [hintText] in the tertiary ink, or [value], a query the
/// page already holds, in the ink on the brightened pill; one link that
/// opens the search. A null [onPressed] leaves it inert.
///
/// ```dart
/// FrostedSearchLink(hintText: 'Search activity', onPressed: () => Navigator.of(context).pushNamed('/activity/search'))
/// ```
class FrostedSearchLink extends StatelessWidget {
  /// Creates a [FrostedSearchLink].
  const FrostedSearchLink({
    required this.hintText,
    required this.onPressed,
    this.value,
    this.labelText,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// What the pill says with no query (Search activity).
  final String hintText;

  /// Opens the search; null leaves the pill inert.
  final VoidCallback? onPressed;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// A query the page already holds, shown in the ink.
  final String? value;

  /// The link's spoken name; null speaks [hintText].
  final String? labelText;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final typed = value != null && value!.isNotEmpty;
    return FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      semanticLabel: labelText ?? hintText,
      value: typed ? value : null,
      role: FrostedPressRole.link,
      radius: FrostedChromeMetrics.search / 2,
      child: _SearchPill(
        typed: typed,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: frostedCapCentred(
            Text(
              typed ? value! : hintText,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.bodyLarge
                  .line(_searchLine)
                  .c(
                    typed
                        ? t.colorScheme.textPrimary
                        : t.colorScheme.textTertiary,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('hintText', hintText))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(StringProperty('value', value, defaultValue: null))
      ..add(StringProperty('labelText', labelText, defaultValue: null));
  }
}

// ---------------------------------------------------------------------------
// Picker row and swap
// ---------------------------------------------------------------------------

/// A choice that opens a picker: the label 8 over a well at least 60 tall, 14
/// round, 10 in (14 at its end), holding the choice's mark ([leading], a
/// [FrostedIconMark]), its [title] in the body over a quiet [subtitle], what
/// the page puts at the end ([trailing], a [FrostedAmount]) and a 16 chevron
/// down. One button read as the label, the title and the subtitle; a null
/// [onPressed] leaves it inert.
///
/// ```dart
/// FrostedPickerRow(label: 'From', title: 'Everyday', subtitle: 'Checking ·· 4821', leading: FrostedIconMark(FrostedGlyphs.wallet, hue: t.hues.cyan), trailing: const FrostedAmount(6248.30, signed: false), onPressed: pickFrom)
/// ```
class FrostedPickerRow extends StatelessWidget {
  /// Creates a [FrostedPickerRow].
  const FrostedPickerRow({
    required this.label,
    required this.title,
    required this.onPressed,
    this.leading,
    this.subtitle,
    this.trailing,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The label over the well (From, To).
  final String label;

  /// The choice's name (Everyday).
  final String title;

  /// The quiet line under the title (Checking ·· 4821).
  final String? subtitle;

  /// The choice's mark, before the words.
  final Widget? leading;

  /// What stands at the end before the chevron: the account's balance.
  final Widget? trailing;

  /// What a press does (opens the picker); null leaves it inert.
  final VoidCallback? onPressed;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // .pick-r { gap: 12px; min-height: 60px; padding: 10px 14px 10px 10px;
    //   border-radius: 14px }  .pick-r .i-chevron-down { 16px; ink-3 }
    // .row-main { gap: 1px }  .row-t { font: 500 16px/1.25 var(--font-t) }
    // .row-s { font: 400 14px/1.3 var(--font-t); color: var(--ink-2) }
    final well = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FrostedChromeMetrics.picker),
      child: FrostedWell(
        radius: FrostedChromeMetrics.pickerRadius,
        padding: FrostedChromeMetrics.pickerInset,
        child: Row(
          spacing: FrostedChromeMetrics.pickerGap,
          children: [
            ?leading,
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: FrostedChromeMetrics.rowLineGap,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.titleMedium,
                  ),
                  if (subtitle case final subtitle?)
                    Text(
                      subtitle,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.bodyMedium.line(18.2),
                    ),
                ],
              ),
            ),
            ?trailing,
            Icon(
              FrostedGlyphs.chevronDown,
              size: FrostedChromeMetrics.pickerGlyph,
              color: t.colorScheme.textTertiary,
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.fieldLabelGap,
      children: [
        FrostedFieldLabel(label),
        FrostedPressable(
          focusNode: focusNode,
          autofocus: autofocus,
          onPressed: onPressed,
          semanticLabel: subtitle == null
              ? '$label: $title'
              : '$label: $title, $subtitle',
          radius: FrostedChromeMetrics.pickerRadius,
          child: well,
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

/// The arrow between a transfer's From and To: a 32 white round with its
/// hairline edge and lift, a 16 arrow down in the secondary ink, centred on the
/// 16 between the two [FrostedPickerRow]s and over both wells. It is that 16: a
/// [FrostedFormSection] puts no gap of its own round it. Frosted draws it as a
/// mark a screen reader skips; with [onPressed] it is a button named [semanticLabel]
/// that swaps the two.
///
/// ```dart
/// FrostedSwapButton()
/// ```
class FrostedSwapButton extends StatelessWidget {
  /// Creates a [FrostedSwapButton].
  const FrostedSwapButton({
    this.onPressed,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Swaps From and To; null draws the mark alone.
  final VoidCallback? onPressed;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// The button's spoken name, with [onPressed].
  final String? semanticLabel;

  /// The height the swap stands in: the form's gap, the mark's own line and its
  /// two negative margins, which come to the one gap again.
  static const double height =
      FrostedChromeMetrics.formGap -
      FrostedChromeMetrics.swapPull +
      FrostedChromeMetrics.swapLine -
      FrostedChromeMetrics.swapPull +
      FrostedChromeMetrics.formGap;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel ?? FrostedLocalizations.of(context).swap;
    final t = context.frostedTheme;
    const d = FrostedChromeMetrics.swap;
    // .swap span { width: 32px; height: 32px; background: #fff;
    //   color: var(--ink-2); box-shadow: var(--edge),
    //   0 4px 10px -6px rgba(42,36,100,.3) }  .swap .i { 16px }
    final shade = t.shadows.raised.first.color;
    Widget disc = SizedBox.square(
      dimension: d,
      child: FrostedFace(
        material: FrostedMaterial.paint,
        radius: BorderRadius.circular(d / 2),
        color: t.glass.plane,
        shadows: [
          _edge(t),
          frostedShadow(
            color: shade.withValues(alpha: _swapShadowOpacity),
            y: _swapShadowY,
            blur: _swapShadowBlur,
            spread: _swapShadowSpread,
          ),
        ],
        child: Center(
          child: Icon(
            FrostedGlyphs.arrowDown,
            size: FrostedChromeMetrics.swapGlyph,
            color: t.colorScheme.textSecondary,
          ),
        ),
      ),
    );
    disc = onPressed == null
        ? ExcludeSemantics(child: disc)
        : FrostedPressable(
            focusNode: focusNode,
            autofocus: autofocus,
            onPressed: onPressed,
            semanticLabel: label,
            radius: d / 2,
            child: disc,
          );
    return SizedBox(
      height: height,
      child: OverflowBox(
        minHeight: d,
        maxHeight: d,
        child: Center(child: disc),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}

// ---------------------------------------------------------------------------
// Stepper
// ---------------------------------------------------------------------------

/// A number you step: a 48 glass round with a minus, the number's well with its
/// figure on the centre, and a 48 round with a plus, 12 apart; an optional
/// [note] centred 8 under (a month). The figure is a plain number, with its
/// [unit] after it (2 people); with [money] it is an amount, the currency sign
/// before it (a budget's $250). The page owns [value]; each round moves it to
/// the next multiple of [step] from [min] that way (repeating while held),
/// never under [min] or over [max] (a round with nowhere to go is disabled). A
/// figure typed into the well is handed back as it is typed while it stands
/// between [min] and [max] (so a Save beside it reads it), and as it is taken
/// (Return, or the focus leaving) clamped to them; one that does not read puts
/// the value back. Up and Down in the well step too. A null [onChanged] leaves
/// it inert. A screen reader hears a text field named [labelText] that steps up
/// and down; the rounds are for the eye and the finger. ui_core's
/// [RawNumberField] is the behaviour.
///
/// ```dart
/// FrostedNumberField(value: guests, onChanged: (v) => setState(() => guests = v), labelText: 'Guests', min: 1, max: 12, step: 1, unit: (n) => n == 1 ? 'person' : 'people')
/// ```
class FrostedNumberField extends StatelessWidget {
  /// Creates a [FrostedNumberField].
  const FrostedNumberField({
    required this.value,
    required this.onChanged,
    required this.labelText,
    this.step = 10,
    this.min = 0,
    this.max,
    this.note,
    this.unit,
    this.money = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(step > 0, 'A number field steps by a positive amount.'),
       assert(
         max == null || max >= min,
         'A number field\'s max is at least its min.',
       ),
       assert(
         value >= min && (max == null || value <= max),
         'A number field\'s value lies between its min and max.',
       );

  /// The number.
  final int value;

  /// Called with the new number; null leaves it inert.
  final ValueChanged<int>? onChanged;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// What the rounds and the well are named by (the budget).
  final String labelText;

  /// How far one press moves the value.
  final int step;

  /// The floor the value never goes under.
  final int min;

  /// The ceiling, if any.
  final int? max;

  /// The quiet line centred under the stepper (a month).
  final String? note;

  /// The words after the figure for a value, in the quiet ink, so a count says
  /// what it counts (`(n) => n == 1 ? 'person' : 'people'`); read with the
  /// figure. Null, none.
  final String Function(int value)? unit;

  /// Whether the figure is an amount of money: the currency sign before it
  /// (a budget's stepper). False, a plain number.
  final bool money;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final live = onChanged != null;
    final words = unit?.call(value);
    // .stepper { gap: 12px }  .step-b { width: 48px; height: 48px }
    // .stepper .amount-in { flex: 1; justify-content: center }
    // .stepper-c { text-align: center; margin-top: -8px }
    final row = RawNumberField(
      value: value.toDouble(),
      // An emptied well takes no number: the value stands.
      onChanged: live
          ? (v) {
              if (v != null) onChanged!(v.round());
            }
          : null,
      min: min.toDouble(),
      max: max?.toDouble(),
      step: step.toDouble(),
      fractionDigits: 0,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: labelText,
      // Inert, the well dims with its rounds, as a disabled field does, and
      // shows its value alone.
      // The figure is the stepping node's value too. ui_core's field merges
      // its words into that node; Frosted's well is a node of its own (what
      // a screen reader outlines is the well), so the node is handed the
      // figure here, as Flutter asks of a node that names its next values.
      fieldBuilder: (context, field) => ListenableBuilder(
        listenable: field.controller,
        builder: (context, child) => Semantics(
          value: [live ? field.controller.text : '$value', ?words].join(' '),
          child: child,
        ),
        child: FrostedDim(
          off: !live,
          child: FrostedAmountField(
            focusNode: field.focusNode,
            labelText: labelText,
            controller: live ? field.controller : null,
            value: live ? null : '$value',
            onEditingComplete: field.onEditingComplete,
            // ui_core hands a typed figure back as it is taken; a page
            // whose Save takes no focus (a sheet's) would read the last
            // one. A whole figure within the bounds goes back as it is
            // typed too; one outside waits to be clamped as it is taken,
            // so typing 12 over a floor of 5 never snaps at the 1.
            onChanged: live
                ? (text) {
                    final read = RawWidgetsLocalizations.of(context)
                        .parseDecimal(text);
                    if (read == null || read != read.roundToDouble()) return;
                    final n = read.round();
                    if (n == value || n < min || (max != null && n > max!)) {
                      return;
                    }
                    onChanged!(n);
                  }
                : null,
            inputFormatters: field.inputFormatters,
            keyboardType: field.keyboardType,
            centered: true,
            showLabel: false,
            sign: money ? r'$' : null,
            suffix: words,
          ),
        ),
      ),
      // Each round is a disc as tall as the well its row lays it beside
      // (_StepperRow), at any text size: 48 rounds beside a 64 well stood at
      // two heights in one row.
      buttonBuilder: (context, button) => LayoutBuilder(
        builder: (context, box) => frostedIconButtonFace(
          context,
          button.isIncrement ? FrostedGlyphs.add : FrostedGlyphs.remove,
          states: button.states,
          enabled: !button.states.contains(WidgetState.disabled),
          size: FrostedIconButtonSize.large,
          diameter: box.hasBoundedHeight ? box.maxHeight : null,
          style: t.components.numberField,
        ),
      ),
      layoutBuilder: (context, field, lower, raise) =>
          _StepperRow(children: [lower, field, raise]),
    );
    if (note == null) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        const SizedBox(
          height:
              FrostedChromeMetrics.formGap -
              FrostedChromeMetrics.stepperNotePull,
        ),
        Text(
          note!,
          textAlign: TextAlign.center,
          style: t.textTheme.labelMedium.line(15.6),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('value', value))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(StringProperty('labelText', labelText))
      ..add(IntProperty('step', step, defaultValue: 10))
      ..add(IntProperty('min', min, defaultValue: 0))
      ..add(IntProperty('max', max, defaultValue: null))
      ..add(StringProperty('note', note, defaultValue: null))
      ..add(ObjectFlagProperty<Function>.has('unit', unit))
      ..add(FlagProperty('money', value: money, ifTrue: 'money'));
  }
}

/// A stepper's figure, whose least width is the three figures it always
/// shows ([floor]), whatever it holds: its row gives the well that room
/// beside its rounds, and a longer figure scrolls within it.
class _FigureFloor extends SingleChildRenderObjectWidget {
  const _FigureFloor({required this.floor, super.child});

  final double floor;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFigureFloor(floor);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFigureFloor renderObject,
  ) => renderObject.floor = floor;
}

class _RenderFigureFloor extends RenderProxyBox {
  _RenderFigureFloor(this._floor);

  double _floor;
  set floor(double value) {
    if (value == _floor) return;
    _floor = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) => _floor;
}

/// A stepper's row: its lower round, its well and its raise round, 12
/// apart, in reading order. The well takes the width the rounds leave; each
/// round is a square as tall as the well, so the three stand at one height
/// whatever the text size, unless the row is too narrow for the well's
/// three figures beside rounds that large: then the rounds give way, as
/// large as leaves them whole (never under a large icon button's), centred
/// on the well.
class _StepperRow extends MultiChildRenderObjectWidget {
  const _StepperRow({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderStepperRow(Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderStepperRow renderObject,
  ) => renderObject.direction = Directionality.of(context);
}

class _StepperRowData extends ContainerBoxParentData<RenderBox> {}

class _RenderStepperRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StepperRowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StepperRowData> {
  _RenderStepperRow(this._direction);

  static const double _gap = FrostedChromeMetrics.stepperGap;

  /// The round's side before the well is measured (a large icon button's).
  static final double _guess = FrostedIconButtonSize.large.diameter;

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StepperRowData) {
      child.parentData = _StepperRowData();
    }
  }

  RenderBox get _lower => firstChild!;
  RenderBox get _well => childAfter(firstChild!)!;
  RenderBox get _raise => lastChild!;

  double _wellWidth(double width, double round) =>
      math.max(0, width - 2 * (round + _gap));

  /// The rounds' side beside a well [tall] high in a row [width] wide.
  double _side(double width, double tall) {
    final room = (width - _well.getMinIntrinsicWidth(tall)) / 2 - _gap;
    return math.min(tall, math.max(math.min(tall, _guess), room));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _well.getMinIntrinsicHeight(_wellWidth(width, _guess));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _well.getMaxIntrinsicHeight(_wellWidth(width, _guess));

  @override
  double computeMinIntrinsicWidth(double height) =>
      _well.getMinIntrinsicWidth(height) + 2 * (height + _gap);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _well.getMaxIntrinsicWidth(height) + 2 * (height + _gap);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final width = constraints.maxWidth;
    var tall = _well
        .getDryLayout(BoxConstraints.tightFor(width: _wellWidth(width, _guess)))
        .height;
    final side = _side(width, tall);
    tall = _well
        .getDryLayout(BoxConstraints.tightFor(width: _wellWidth(width, side)))
        .height;
    return constraints.constrain(Size(width, tall));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    // The well's height decides the rounds' side, and the rounds' side the
    // well's width: measure at a large round's side, then lay the well out
    // again at its own height's (a well's height does not follow its width).
    _well.layout(
      BoxConstraints.tightFor(width: _wellWidth(width, _guess)),
      parentUsesSize: true,
    );
    var tall = _well.size.height;
    var side = _side(width, tall);
    if (side != _guess) {
      _well.layout(
        BoxConstraints.tightFor(width: _wellWidth(width, side)),
        parentUsesSize: true,
      );
      tall = _well.size.height;
      side = math.min(side, tall);
    }
    final round = BoxConstraints.tight(Size.square(side));
    _lower.layout(round);
    _raise.layout(round);
    size = constraints.constrain(Size(width, tall));
    final rtl = _direction == TextDirection.rtl;
    final start = rtl ? _raise : _lower;
    final end = rtl ? _lower : _raise;
    final drop = (tall - side) / 2;
    (start.parentData! as _StepperRowData).offset = Offset(0, drop);
    (_well.parentData! as _StepperRowData).offset = Offset(side + _gap, 0);
    (end.parentData! as _StepperRowData).offset = Offset(
      size.width - side,
      drop,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

// ---------------------------------------------------------------------------
// Select
// ---------------------------------------------------------------------------

/// One value a [FrostedSelect] offers: its [value], the [label] shown and
/// spoken, a quiet [note] at the row's end, and whether it can be chosen.
@immutable
class FrostedSelectOption<T> {
  /// An option for [value], named [label].
  const FrostedSelectOption(
    this.value,
    this.label, {
    this.note,
    this.enabled = true,
  });

  /// What choosing it hands to [FrostedSelect.onChanged].
  final T value;

  /// Its words, in the well once chosen and in the menu.
  final String label;

  /// A quiet note at the end of its menu row.
  final String? note;

  /// Whether it can be chosen; a disabled one stands faded in the menu.
  final bool enabled;
}

/// One value of a few, chosen from a menu (Material's `DropdownMenu`): the
/// [labelText] 8 over a 48 well like a text field's, the chosen option's words
/// in it (or the [hintText] in the tertiary ink) and a 16 chevron down at its
/// end; a press drops a [FrostedMenu] of the [options] from the well, the
/// chosen one checked. The [helperText] or the [errorText] (the well ringed in the
/// over ink) stands 8 under, fading out while the list drops over it. A null
/// [onChanged] leaves it faded and inert.
/// A screen reader hears a button named [labelText] with the chosen words as
/// its value.
///
/// ```dart
/// FrostedSelect<String>(labelText: 'Room', options: const [FrostedSelectOption('k', 'Kitchen'), FrostedSelectOption('s', 'Study')], value: room, onChanged: (v) => setState(() => room = v))
/// ```
class FrostedSelect<T> extends StatefulWidget {
  /// A select over [options]; a null [onChanged] disables it.
  const FrostedSelect({
    required this.options,
    this.value,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The choices, in the menu's order.
  final List<FrostedSelectOption<T>> options;

  /// The chosen value; null shows the [hintText].
  final T? value;

  /// Hands over the value chosen in the menu.
  final ValueChanged<T>? onChanged;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// The words over the well.
  final String? labelText;

  /// What the well says before anything is chosen (Select, by default).
  final String? hintText;

  /// A help line under the well.
  final String? helperText;

  /// What is wrong, under the well in place of the [helperText].
  final String? errorText;

  /// This select's own style, over `FrostedThemeData.components.textField`
  /// (a select wears a field's well): the well's fill, ring, shape,
  /// padding and least size, each per state.
  final FrostedStyle? style;

  @override
  State<FrostedSelect<T>> createState() => _FrostedSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<FrostedSelectOption<T>>('options', options))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        DiagnosticsProperty<FrostedStyle>('style', style, defaultValue: null),
      );
  }
}

class _FrostedSelectState<T> extends State<FrostedSelect<T>> {
  // Whether its list is open. The line under the well fades out with the
  // list dropping over it, so no letter of it peeks past the list's rounded
  // corner, and back in as the list goes.
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final FrostedSelect<T>(
      :options,
      :value,
      :onChanged,
      labelText: label,
      hintText: prompt,
      helperText: helper,
      errorText: error,
      :style,
    ) = widget;
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final chosen = options.where((o) => o.value == value).firstOrNull;
    final change = onChanged;
    final shown = chosen?.label ?? prompt ?? words.select;
    final wrong = error;
    final help = helper;
    Future<void> open(BuildContext anchor, ValueChanged<T> change) async {
      setState(() => _open = true);
      final picked = await FrostedMenu.show<T>(
        anchor,
        fitAnchor: true,
        semanticLabel: label ?? words.select,
        items: [
          for (final o in options)
            FrostedMenuItem<T>(
              o.value,
              o.label,
              checked: o.value == value,
              enabled: o.enabled,
              trailing: o.note == null
                  ? null
                  : Text(o.note!, style: t.textTheme.bodySmall),
            ),
        ],
      );
      if (mounted) setState(() => _open = false);
      if (picked != null && picked != value) change(picked);
    }

    final field = Builder(
      // Enter and Space open the list through the press; an arrow opens it
      // too, as a select's field does (FrostedMenu.show: by a key, the
      // chosen item takes the focus).
      builder: (anchor) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: (node, event) {
          if (change == null || _open || event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          final key = event.logicalKey;
          if (key != LogicalKeyboardKey.arrowDown &&
              key != LogicalKeyboardKey.arrowUp) {
            return KeyEventResult.ignored;
          }
          open(anchor, change);
          return KeyEventResult.handled;
        },
        child: FrostedPressable(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onPressed: change == null ? null : () => open(anchor, change),
          expanded: change == null ? null : _open,
          // Under its label the field names the press (ui_core's decorator:
          // a button's own name is not the field's, so both would be read);
          // with no label the press names itself.
          semanticLabel: label == null ? words.select : null,
          value: chosen?.label,
          radius: FrostedCorners.r12,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FrostedChromeMetrics.field,
            ),
            child: FrostedWell(
              layers: FrostedStyleLayers(style, t.components.textField),
              error: wrong != null,
              enabled: change != null,
              padding: const EdgeInsets.symmetric(
                horizontal: FrostedChromeMetrics.fieldInset,
              ),
              child: Row(
                spacing: FrostedSpacing.s8,
                children: [
                  Expanded(
                    // The press says the chosen option as its value.
                    child: ExcludeSemantics(
                      child: frostedCapCentred(
                        Text(
                          shown,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: chosen == null
                              ? t.textTheme.bodyLarge
                                    .line(19.2)
                                    .c(t.colorScheme.textTertiary)
                              : t.textTheme.bodyLarge.line(19.2),
                        ),
                      ),
                    ),
                  ),
                  // The chevron turns while the list stands open.
                  AnimatedRotation(
                    turns: _open ? .5 : 0,
                    duration: FrostedMotion.of(context).base,
                    curve: FrostedMotion.of(context).curve,
                    child: Icon(
                      FrostedGlyphs.chevronDown,
                      size: FrostedChromeMetrics.pickerGlyph,
                      color: t.colorScheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Like a text field, it takes its column's width at every size, so a
    // form's fields share one edge; alone in a row, its content's.
    return FrostedFieldWidth(
      child: RawInputDecorator(
        labelText: label,
        helperText: help,
        errorText: wrong,
        enabled: change != null,
        focusNode: widget.focusNode,
        builder: (context, parts) => frostedFieldColumn(
          context,
          parts,
          hintBuilder: (hint) => AnimatedOpacity(
            opacity: _open ? 0 : 1,
            duration: FrostedMotion.of(context).fast,
            child: hint,
          ),
        ),
        child: field,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date field
// ---------------------------------------------------------------------------

/// A day in a field's well, picked from a calendar: the label over the well,
/// the day in it as a field shows one, with its year ("Nov 9, 2026"), or the
/// [hintText] in the tertiary ink while there is none, and a calendar glyph
/// at its end. A press raises [showFrostedDatePicker] on the day, between
/// [firstDate] and [lastDate]; the day chosen comes back through
/// [onChanged], and a cancel changes nothing. A null [value] is no day yet;
/// a null [onChanged] leaves the field faded and inert. A screen reader hears
/// a button named [labelText] with the day as its value.
///
/// ```dart
/// FrostedDateField(labelText: 'Finished', value: finished, lastDate: DateTime.now(), onChanged: (day) => setState(() => finished = day))
/// ```
class FrostedDateField extends StatelessWidget {
  /// A field for a day named [labelText]; a null [onChanged] disables it.
  const FrostedDateField({
    required this.labelText,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.hintText,
    this.helperText,
    this.errorText,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The words over the well, the field's spoken name and the calendar's
  /// title.
  final String labelText;

  /// The day shown; null shows the [hintText].
  final DateTime? value;

  /// Hands over the day chosen in the calendar.
  final ValueChanged<DateTime>? onChanged;

  /// The first day the calendar offers; null leaves it open.
  final DateTime? firstDate;

  /// The last day the calendar offers; null leaves it open.
  final DateTime? lastDate;

  /// What the well says before a day is chosen ("Select a date", by
  /// default).
  final String? hintText;

  /// {@macro frosted.helper}
  final String? helperText;

  /// {@macro frosted.error}
  final String? errorText;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final day = value;
    final change = onChanged;
    Future<void> pick(ValueChanged<DateTime> change) async {
      final picked = await showFrostedDatePicker(
        context,
        initialDate: day,
        first: firstDate,
        last: lastDate,
        title: labelText,
      );
      if (picked != null && picked != day) change(picked);
    }

    final field = FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: change == null ? null : () => pick(change),
      // Under its label the field names the press; the day is its value.
      value: day == null ? null : words.shortDate(day),
      radius: FrostedCorners.r12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: FrostedChromeMetrics.field,
        ),
        child: FrostedWell(
          error: errorText != null,
          enabled: change != null,
          padding: const EdgeInsets.symmetric(
            horizontal: FrostedChromeMetrics.fieldInset,
          ),
          child: Row(
            spacing: FrostedSpacing.s8,
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: frostedCapCentred(
                    Text(
                      day == null
                          ? hintText ?? words.selectDate
                          : words.shortDate(day),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: day == null
                          ? t.textTheme.bodyLarge
                                .line(19.2)
                                .c(t.colorScheme.textTertiary)
                          : t.textTheme.bodyLarge.line(19.2),
                    ),
                  ),
                ),
              ),
              // Wrong, the mark takes the calendar's place, crossing to it.
              AnimatedSwitcher(
                duration: FrostedMotion.of(context).fast,
                child: errorText != null
                    ? KeyedSubtree(
                        key: const ValueKey<bool>(true),
                        child: _errorMark(t),
                      )
                    : Icon(
                        key: const ValueKey<bool>(false),
                        FrostedGlyphs.calendar,
                        size: FrostedChromeMetrics.pickerGlyph,
                        color: t.colorScheme.textTertiary,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
    // Its column's width, as a text field's; alone in a row, its content's.
    return FrostedFieldWidth(
      child: RawInputDecorator(
        labelText: labelText,
        helperText: helperText,
        errorText: errorText,
        enabled: change != null,
        focusNode: focusNode,
        builder: frostedFieldColumn,
        child: field,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(DiagnosticsProperty<DateTime>('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime>>.has('onChanged', onChanged),
      )
      ..add(
        DiagnosticsProperty<DateTime>(
          'firstDate',
          firstDate,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<DateTime>('lastDate', lastDate, defaultValue: null),
      )
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

// The decoration of every text entry in Frosted (kept the same in
// bare_field.dart, forms.dart and composer.dart): the hint only, and every
// field that could size or place the line set, so that no
// InputDecorationTheme above the field (its padding, isDense, its
// constraints, a fill or a border) and no platform's density moves it. The
// decorator stands exactly the line's height; the look's own well draws the
// box round it and centres the line by alignment.
// InputDecoration.collapsed alone leaves the constraints and density to the
// theme.
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

// The mark's place at a text field's end: while the field is wrong the mark
// fades in there, the entry giving it its room ([gap] and the mark's width)
// as it comes, and out as the field is put right; nothing stands there while
// it is right. Under Reduce Motion it cuts.
class _ErrorMarkSlot extends StatelessWidget {
  const _ErrorMarkSlot({
    required this.shown,
    required this.gap,
    required this.mark,
  });

  final bool shown;
  final double gap;
  final Widget mark;

  @override
  Widget build(BuildContext context) {
    final motion = FrostedMotion.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: shown ? 1 : 0),
      duration: motion.fast,
      curve: motion.curve,
      builder: (context, v, child) => switch (v) {
        <= 0 => const SizedBox.shrink(),
        >= 1 => child!,
        _ => ClipRect(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: v,
            heightFactor: 1,
            child: Opacity(opacity: v, child: child),
          ),
        ),
      },
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: gap),
        child: mark,
      ),
    );
  }
}

// A wrong field's mark at its end: the danger's glyph in its ink, silent (the
// field reads its message).
Widget _errorMark(FrostedThemeData t) => ExcludeSemantics(
  child: Icon(
    FrostedGlyphs.danger,
    size: FrostedChromeMetrics.pickerGlyph,
    color: t.colorScheme.over,
  ),
);
