/// Text fields: filled, outlined and the expressive rounded and tonal forms,
/// label inside or cut out, secure, multi-line; segmented code fields; the
/// error supporting text (CONTRACT §4.1 `text-field`, `text-area`,
/// `code-input`, `field-error`). Owner: w3-textfields.
///
/// A port of Compose's `TextField` and `OutlinedTextField` (material3
/// 1.5.0-alpha29): the decoration is `CommonDecorationBox` and its two
/// measure policies (`internal/TextFieldImpl.kt`), measured and placed the
/// way `TextFieldMeasurePolicy` (filled, label inside) and
/// `OutlinedTextFieldMeasurePolicy` (outlined, label in the outline's
/// cutout) do; the colours are `TextFieldDefaults.colors()` /
/// `tonalColors()` and their outlined twins, from the generated
/// `FilledTextFieldTokens`, `OutlinedTextFieldTokens` and
/// `TextFieldBehavior`. The label moves on the fast spatial spring, the
/// placeholder and affixes fade and every colour changes on the effects
/// springs, the indicator or outline thickens on the fast spatial spring.
///
/// Under the decoration, Flutter's text-editing core does the editing — the
/// primitive Compose's `BasicTextField` is to its decorator — with no
/// decoration of its own: text handles, the edit menu, the caret and the
/// selection gestures follow the platform (Android's on Android, iOS's on
/// iOS; CONTRACT §5).
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart'
    show AdaptiveTextSelectionToolbar, Material, MaterialType, TextField;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../component_themes.dart';
import '../icons.dart';
import '../internal/cap_label.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/filled_text_field_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/outlined_text_field_tokens.g.dart';
import '../internal/tokens/small_icon_button_tokens.g.dart';
import '../motion.dart';
import '../spacing.dart';
import '../states.dart';
import '../strings.dart';
import '../theme.dart';

/// A text field's container: Compose's two text fields.
enum ExpressiveTextFieldKind {
  /// `TextField`: a filled container with an active indicator along its
  /// bottom edge, the label inside.
  filled,

  /// `OutlinedTextField`: an outline, the label minimized into a cutout in
  /// it.
  outlined,
}

/// Where a text field's label rests once minimized (Compose's
/// `TextFieldLabelPosition`).
enum ExpressiveLabelPosition {
  /// Inside the container, above the input (`Inside`): a filled field's,
  /// and a tonal field's.
  inside,

  /// In a cutout across the outline's top edge (`Cutout`): an outlined
  /// field's.
  cutout,
}

/// A single-line text field (Compose's `TextField` and `OutlinedTextField`;
/// `SecureTextField` and `OutlinedSecureTextField` when [secure]).
///
/// [style] picks the container, [rounded] Expressive's rounded shape
/// (`TextFieldDefaults.roundedShape`) and [tonal] its tonal colours
/// (`TextFieldDefaults.tonalColors()`). The [label] rests inside the field
/// while it is empty and unfocused and moves to its minimized place — the
/// top of a filled field, the outline's cutout — on focus or input.
/// [helperText] sits under the field; [errorText] replaces it in the
/// error colours and puts the field in error (an empty one keeps
/// [helperText]'s line, in the error colours). A
/// [maxLength] adds the counter at the supporting line's end.
///
/// The field keeps Compose's minimum size (280 × 56dp) where its parent
/// leaves it free, and stretches where its parent stretches it.
class ExpressiveTextField extends StatefulWidget {
  /// A single-line text field.
  const ExpressiveTextField({
    this.controller,
    this.focusNode,
    this.kind = ExpressiveTextFieldKind.filled,
    this.style,
    this.rounded = false,
    this.tonal = false,
    this.label,
    this.labelPosition,
    this.alwaysMinimizeLabel = false,
    this.hintText,
    this.leading,
    this.trailing,
    this.prefix,
    this.suffix,
    this.helperText,
    this.errorText,
    this.maxLength,
    this.obscureText = false,
    this.revealable = true,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.semanticLabel,
    super.key,
  }) : _singleLine = true,
       _minLines = null,
       _maxLines = 1;

  const ExpressiveTextField._multiline({
    required this._minLines,
    required this._maxLines,
    required this.controller,
    required this.focusNode,
    required this.kind,
    required this.style,
    required this.rounded,
    required this.tonal,
    required this.label,
    required this.labelPosition,
    required this.alwaysMinimizeLabel,
    required this.hintText,
    required this.leading,
    required this.trailing,
    required this.helperText,
    required this.errorText,
    required this.maxLength,
    required this.enabled,
    required this.readOnly,
    required this.autofocus,
    required this.textInputAction,
    required this.textCapitalization,
    required this.inputFormatters,
    required this.onChanged,
    required this.onSubmitted,
    required this.onEditingComplete,
    required this.onTap,
    required this.semanticLabel,
  }) : _singleLine = false,
       prefix = null,
       suffix = null,
       obscureText = false,
       revealable = false,
       keyboardType = TextInputType.multiline,
       autofillHints = null;

  /// The text; the field keeps its own when null.
  final TextEditingController? controller;

  /// The focus node; the field makes its own when null.
  final FocusNode? focusNode;

  /// Filled or outlined.
  final ExpressiveTextFieldKind kind;

  /// Stateful visual overrides before the component theme.
  final ExpressiveComponentThemeData? style;

  /// Expressive's rounded container (`TextFieldDefaults.roundedShape`)
  /// instead of the style's own.
  final bool rounded;

  /// Expressive's tonal colours (`tonalColors()`): a filled field on
  /// `surfaceContainer` with no indicator, an outlined one on `onPrimary`
  /// with an `outlineVariant` outline.
  final bool tonal;

  /// The label: inside the field when it is empty and unfocused, minimized
  /// otherwise.
  final String? label;

  /// Where the label rests once minimized; null is the style's own —
  /// inside a filled or tonal field, in an outlined field's cutout.
  final ExpressiveLabelPosition? labelPosition;

  /// Whether the label stays minimized even when the field is empty and
  /// unfocused (Compose's label position with `alwaysMinimize = true`).
  final bool alwaysMinimizeLabel;

  /// Shown while the field is empty and its label minimized.
  final String? hintText;

  /// The leading icon (an `Icon` or `ExpressiveIcon`), in the field's icon
  /// colour at 24dp, centred in a 48dp touch target.
  final Widget? leading;

  /// The trailing icon or icon button, like [leading]. A [obscureText] field
  /// that is [revealable] puts its visibility toggle here when this is null.
  final Widget? trailing;

  /// Text before the input (`$`, `+1`), shown with the input.
  final String? prefix;

  /// Text after the input (`kg`, `.com`), shown with the input.
  final String? suffix;

  /// The line under the field: help, a format, a hint of what goes here.
  final String? helperText;

  /// What is wrong with the input, as `InputDecoration.errorText`: shown
  /// instead of [helperText] in the error colours, and puts the field in
  /// error. An empty one puts it in error and keeps [helperText]'s line.
  final String? errorText;

  /// The most characters the field takes; shows the counter.
  final int? maxLength;

  /// Obscures the input (`SecureTextField`): no suggestions, no
  /// autocorrect, the input shown as dots.
  final bool obscureText;

  /// Whether a [obscureText] field has a visibility toggle.
  final bool revealable;

  /// Whether the field takes input; a disabled field is dimmed and skipped
  /// by focus.
  final bool enabled;

  /// Whether the text can be selected and copied but not edited.
  final bool readOnly;

  /// Whether the field takes focus when first built.
  final bool autofocus;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// How the keyboard capitalizes.
  final TextCapitalization textCapitalization;

  /// What autofill may fill the field with.
  final Iterable<String>? autofillHints;

  /// Formatters every edit runs through.
  final List<TextInputFormatter>? inputFormatters;

  /// Told the text on every edit.
  final ValueChanged<String>? onChanged;

  /// Told the text when the keyboard's action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Told when editing completes (the action key), before [onSubmitted].
  final VoidCallback? onEditingComplete;

  /// Told on a tap on the field (a read-only field that opens a picker).
  final GestureTapCallback? onTap;

  /// What a screen reader calls the field; [label], then [hintText],
  /// when null.
  final String? semanticLabel;

  final bool _singleLine;
  final int? _minLines;
  final int? _maxLines;

  @override
  State<ExpressiveTextField> createState() => _ExpressiveTextFieldState();
}

/// A multi-line text field that grows with its content (Compose's
/// `TextField` and `OutlinedTextField` with `singleLine = false`): the same
/// containers, colours and label motion as [ExpressiveTextField], its
/// label and input aligned to the top.
class ExpressiveTextArea extends StatelessWidget {
  /// A multi-line text field.
  const ExpressiveTextArea({
    this.controller,
    this.focusNode,
    this.kind = ExpressiveTextFieldKind.filled,
    this.style,
    this.rounded = false,
    this.tonal = false,
    this.label,
    this.labelPosition,
    this.alwaysMinimizeLabel = false,
    this.hintText,
    this.leading,
    this.trailing,
    this.helperText,
    this.errorText,
    this.maxLength,
    this.minLines = 3,
    this.maxLines,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  /// See [ExpressiveTextField.controller].
  final TextEditingController? controller;

  /// See [ExpressiveTextField.focusNode].
  final FocusNode? focusNode;

  /// See [ExpressiveTextField.style].
  final ExpressiveTextFieldKind kind;

  /// Stateful visual overrides before the component theme.
  final ExpressiveComponentThemeData? style;

  /// See [ExpressiveTextField.rounded].
  final bool rounded;

  /// See [ExpressiveTextField.tonal].
  final bool tonal;

  /// See [ExpressiveTextField.label].
  final String? label;

  /// See [ExpressiveTextField.labelPosition].
  final ExpressiveLabelPosition? labelPosition;

  /// See [ExpressiveTextField.alwaysMinimizeLabel].
  final bool alwaysMinimizeLabel;

  /// See [ExpressiveTextField.hintText].
  final String? hintText;

  /// See [ExpressiveTextField.leading].
  final Widget? leading;

  /// See [ExpressiveTextField.trailing].
  final Widget? trailing;

  /// See [ExpressiveTextField.helperText].
  final String? helperText;

  /// See [ExpressiveTextField.errorText].
  final String? errorText;

  /// See [ExpressiveTextField.maxLength].
  final int? maxLength;

  /// The lines the area shows when empty.
  final int? minLines;

  /// The lines it grows to before it scrolls; unbounded when null.
  final int? maxLines;

  /// See [ExpressiveTextField.enabled].
  final bool enabled;

  /// See [ExpressiveTextField.readOnly].
  final bool readOnly;

  /// See [ExpressiveTextField.autofocus].
  final bool autofocus;

  /// The keyboard's action key; a new line when null.
  final TextInputAction? textInputAction;

  /// See [ExpressiveTextField.textCapitalization].
  final TextCapitalization textCapitalization;

  /// See [ExpressiveTextField.inputFormatters].
  final List<TextInputFormatter>? inputFormatters;

  /// See [ExpressiveTextField.onChanged].
  final ValueChanged<String>? onChanged;

  /// Told the text when the keyboard's action key is pressed: a
  /// [textInputAction] other than a new line (Compose's `KeyboardActions`,
  /// which a multi-line field takes too).
  final ValueChanged<String>? onSubmitted;

  /// Told when the keyboard's action key completes editing, before
  /// [onSubmitted]; Flutter's default (let go of focus, or move it for
  /// Next and Previous) when null.
  final VoidCallback? onEditingComplete;

  /// See [ExpressiveTextField.onTap].
  final GestureTapCallback? onTap;

  /// See [ExpressiveTextField.semanticLabel].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => ExpressiveTextField._multiline(
    minLines: minLines,
    maxLines: maxLines,
    controller: controller,
    focusNode: focusNode,
    kind: kind,
    style: style,
    rounded: rounded,
    tonal: tonal,
    label: label,
    labelPosition: labelPosition,
    alwaysMinimizeLabel: alwaysMinimizeLabel,
    hintText: hintText,
    leading: leading,
    trailing: trailing,
    helperText: helperText,
    errorText: errorText,
    maxLength: maxLength,
    enabled: enabled,
    readOnly: readOnly,
    autofocus: autofocus,
    textInputAction: textInputAction,
    textCapitalization: textCapitalization,
    inputFormatters: inputFormatters,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    onEditingComplete: onEditingComplete,
    onTap: onTap,
    semanticLabel: semanticLabel,
  );
}

/// The message under an input that says what is wrong (the error
/// supporting text of Compose's text fields): `bodySmall` in the `error`
/// role, inset like a field's supporting text, announced when it appears.
/// A text field shows its own through `errorText`; this is the same line
/// for a control that has none (a code input, a group of choices).
class ExpressiveFieldError extends StatelessWidget {
  /// An error showing [message].
  const ExpressiveFieldError(this.message, {this.inset = true, super.key});

  /// What is wrong, and how to fix it.
  final String message;

  /// Whether the line is inset like a field's supporting text (16dp at the
  /// sides, 4dp above); flush when false.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final text = Text(
      message,
      style: t.type
          .of(FilledTextFieldTokens.supportingFont)
          .copyWith(
            color: t.colors.role(FilledTextFieldTokens.errorSupportingColor),
          ),
    );
    return Semantics(
      liveRegion: true,
      child: inset
          ? Padding(
              padding: const EdgeInsetsDirectional.only(
                start: TextFieldBehavior.padding,
                top: TextFieldBehavior.supportingTopPadding,
                end: TextFieldBehavior.padding,
              ),
              child: text,
            )
          : text,
    );
  }
}

/// Segmented entry for a short fixed-length code — a one-time code, a PIN
/// (`code-input`, for the auth kit): one cell per character, each a text
/// field container, painted on ui_core's `DesignOtpField`. It is one input
/// under the cells, so a paste or the platform's one-time-code autofill
/// fills every cell, backspace steps back a cell, and a long press or a
/// secondary click offers Paste. The next cell to fill shows the focused
/// outline; a screen reader hears one field, its length, and when the code
/// is wrong.
///
/// Compose has no code input: the cells are Expressive's, built from the
/// text field's tokens (the 56dp container, the field's shape, outline or
/// indicator and colours, `headlineSmall` characters).
class ExpressiveInputOtp extends StatefulWidget {
  /// A code input of [length] cells.
  const ExpressiveInputOtp({
    this.length = 6,
    this.controller,
    this.focusNode,
    this.kind = ExpressiveTextFieldKind.outlined,
    this.style,
    this.rounded = false,
    this.numeric = true,
    this.obscure = false,
    this.enabled = true,
    this.autofocus = false,
    this.isError = false,
    this.errorText,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
    this.onEditingComplete,
    this.textInputAction = TextInputAction.done,
    this.inputFormatters = const <TextInputFormatter>[],
    this.autofillHints = const <String>[AutofillHints.oneTimeCode],
    this.semanticLabel,
    super.key,
  }) : assert(length > 0, 'a code has at least one character');

  /// How many characters the code has: one cell each.
  final int length;

  /// The code, read and written here (a form's or the kit contract's
  /// controller); the input keeps its own when null. The caller disposes it.
  final TextEditingController? controller;

  /// The focus node; the input makes its own when null.
  final FocusNode? focusNode;

  /// Outlined cells (the default) or filled ones.
  final ExpressiveTextFieldKind kind;

  /// Stateful visual overrides before the component theme.
  final ExpressiveComponentThemeData? style;

  /// Expressive's rounded cells.
  final bool rounded;

  /// Whether the code is digits only (the number keyboard).
  final bool numeric;

  /// Whether the characters are shown as dots (a PIN).
  final bool obscure;

  /// Whether the input takes input.
  final bool enabled;

  /// Whether the input takes focus when first built.
  final bool autofocus;

  /// Whether the code is wrong, without a message of its own.
  final bool isError;

  /// What is wrong with the code: shown under the cells
  /// ([ExpressiveFieldError]), and puts them in error.
  final String? errorText;

  /// Told the code on every edit.
  final ValueChanged<String>? onChanged;

  /// Told the code when its last cell is filled.
  final ValueChanged<String>? onCompleted;

  /// Told the code when the keyboard's action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Called when the action key is pressed; null lets go of the focus, as
  /// any one-line input does.
  final VoidCallback? onEditingComplete;

  /// The keyboard's action key.
  final TextInputAction textInputAction;

  /// The caller's formatters, run before the code's own filter and length,
  /// which have the last word.
  final List<TextInputFormatter> inputFormatters;

  /// What autofill may offer; a one-time code by default.
  final Iterable<String> autofillHints;

  /// What a screen reader calls the input.
  final String? semanticLabel;

  @override
  State<ExpressiveInputOtp> createState() => _ExpressiveCodeInputState();
}

// --- Colours -----------------------------------------------------------------

/// One element's colour in each state (Compose's `TextFieldColors` quads).
@immutable
class _StateColor {
  const _StateColor(
    this.focused,
    this.unfocused,
    this.disabled,
    this.error, {
    this.slot,
  });

  const _StateColor.all(Color color, {required this.disabled})
    : slot = null,
      focused = color,
      unfocused = color,
      error = color;

  final Color focused;
  final Color unfocused;
  final Color disabled;
  final Color error;

  final WidgetStateProperty<Color?>? slot;

  /// Resolve [slot] against the complete state set at paint time.
  _StateColor themed(WidgetStateProperty<Color?>? slot) => slot == null
      ? this
      : _StateColor(focused, unfocused, disabled, error, slot: slot);

  /// Compose's resolution order: disabled, then error, then focus.
  Color resolve({
    required bool enabled,
    required bool isError,
    required bool focused,
    Set<WidgetState> extraStates = const {},
  }) {
    final override = slot?.resolve({
      ...extraStates,
      if (!enabled) WidgetState.disabled,
      if (isError) WidgetState.error,
      if (focused) WidgetState.focused,
    });
    if (override != null) return override;
    if (!enabled) return disabled;
    if (isError) return error;
    return focused ? this.focused : unfocused;
  }
}

/// A field's colours: `TextFieldDefaults.colors()` / `tonalColors()` and
/// `OutlinedTextFieldDefaults.colors()` / `tonalColors()`.
@immutable
class _FieldColors {
  const _FieldColors({
    required this.text,
    required this.container,
    required this.indicator,
    required this.leading,
    required this.trailing,
    required this.label,
    required this.placeholder,
    required this.supporting,
    required this.prefix,
    required this.suffix,
    required this.cursor,
    required this.errorCursor,
  });

  /// The style's colours under the text field theme: its container slot
  /// over the container, its outline slot over the indicator line or the
  /// outline (where the style draws one: the tonal filled field draws
  /// none).
  factory _FieldColors.of(
    ExpressiveThemeData theme,
    ExpressiveTextFieldKind style, {
    required bool tonal,
  }) {
    final colors = tonal
        ? _tonal(theme, style)
        : switch (style) {
            ExpressiveTextFieldKind.filled => _filled(theme),
            ExpressiveTextFieldKind.outlined => _outlined(theme),
          };
    final slots = theme.textFieldTheme;
    if (slots.isEmpty) return colors;
    final indicator = tonal && style == ExpressiveTextFieldKind.filled
        ? colors.indicator
        : colors.indicator.themed(slots.outline);
    return _FieldColors(
      text: colors.text.themed(slots.foregroundColor),
      container: colors.container.themed(slots.backgroundColor),
      indicator: indicator,
      leading: colors.leading.themed(slots.foregroundColor),
      trailing: colors.trailing.themed(slots.foregroundColor),
      label: colors.label.themed(slots.foregroundColor),
      placeholder: colors.placeholder.themed(slots.foregroundColor),
      supporting: colors.supporting,
      prefix: colors.prefix.themed(slots.foregroundColor),
      suffix: colors.suffix.themed(slots.foregroundColor),
      cursor: colors.cursor,
      errorCursor: colors.errorCursor,
    );
  }

  /// `TextFieldDefaults.tonalColors()` and
  /// `OutlinedTextFieldDefaults.tonalColors()` (roles stated in Compose's
  /// code until tokens state them; the ones that differ from the default
  /// colours are `TextFieldBehavior`'s).
  static _FieldColors _tonal(
    ExpressiveThemeData theme,
    ExpressiveTextFieldKind style,
  ) {
    final c = theme.colors;
    const disabled = FilledTextFieldTokens.disabledInputOpacity;
    final outlined = style == ExpressiveTextFieldKind.outlined;
    final container = c.role(
      outlined
          ? TextFieldBehavior.tonalOutlinedContainerColor
          : TextFieldBehavior.tonalContainerColor,
    );
    final variant = c.onSurfaceVariant;
    final variantDisabled = variant.withValues(alpha: disabled);
    final onBackground = c.role(TextFieldBehavior.tonalFocusedTextColor);
    final outline = c.role(TextFieldBehavior.tonalOutlineColor);
    final clear = c.surface.withAlpha(0);
    return _FieldColors(
      text: _StateColor(
        onBackground,
        c.onSurface,
        c.onSurface.withValues(alpha: disabled),
        onBackground,
      ),
      container: _StateColor(
        container,
        container,
        container.withValues(alpha: container.a * disabled),
        c.role(TextFieldBehavior.tonalErrorContainerColor),
      ),
      indicator: outlined
          ? _StateColor(outline, outline, outline, c.error)
          : _StateColor.all(clear, disabled: clear),
      leading: _StateColor.all(variant, disabled: variantDisabled),
      trailing: _StateColor(variant, variant, variantDisabled, c.error),
      label: _StateColor(
        variant,
        variant,
        variant.withValues(alpha: FilledTextFieldTokens.disabledLabelOpacity),
        c.error,
      ),
      placeholder: _StateColor.all(variant, disabled: variantDisabled),
      supporting: _StateColor(
        onBackground,
        onBackground,
        onBackground.withValues(
          alpha: FilledTextFieldTokens.disabledSupportingOpacity,
        ),
        c.error,
      ),
      prefix: _StateColor(onBackground, variant, variantDisabled, variant),
      suffix: _StateColor(onBackground, variant, variantDisabled, variant),
      cursor: c.primary,
      errorCursor: c.error,
    );
  }

  /// `TextFieldDefaults.colors()`.
  static _FieldColors _filled(ExpressiveThemeData theme) {
    final c = theme.colors;
    Color role(ExpressiveColorRole r, [double opacity = 1]) =>
        opacity == 1 ? c.role(r) : c.role(r).withValues(alpha: opacity);
    // Compose paints the container token in every state, disabled too.
    final container = role(FilledTextFieldTokens.containerColor);
    return _FieldColors(
      text: _StateColor(
        role(FilledTextFieldTokens.focusInputColor),
        role(FilledTextFieldTokens.inputColor),
        role(
          FilledTextFieldTokens.disabledInputColor,
          FilledTextFieldTokens.disabledInputOpacity,
        ),
        role(FilledTextFieldTokens.errorInputColor),
      ),
      container: _StateColor.all(container, disabled: container),
      indicator: _StateColor(
        role(FilledTextFieldTokens.focusActiveIndicatorColor),
        role(FilledTextFieldTokens.activeIndicatorColor),
        role(
          FilledTextFieldTokens.disabledActiveIndicatorColor,
          FilledTextFieldTokens.disabledActiveIndicatorOpacity,
        ),
        role(FilledTextFieldTokens.errorActiveIndicatorColor),
      ),
      leading: _StateColor(
        role(FilledTextFieldTokens.focusLeadingIconColor),
        role(FilledTextFieldTokens.leadingIconColor),
        role(
          FilledTextFieldTokens.disabledLeadingIconColor,
          FilledTextFieldTokens.disabledLeadingIconOpacity,
        ),
        role(FilledTextFieldTokens.errorLeadingIconColor),
      ),
      trailing: _StateColor(
        role(FilledTextFieldTokens.focusTrailingIconColor),
        role(FilledTextFieldTokens.trailingIconColor),
        role(
          FilledTextFieldTokens.disabledTrailingIconColor,
          FilledTextFieldTokens.disabledTrailingIconOpacity,
        ),
        role(FilledTextFieldTokens.errorTrailingIconColor),
      ),
      label: _StateColor(
        role(FilledTextFieldTokens.focusLabelColor),
        role(FilledTextFieldTokens.labelColor),
        role(
          FilledTextFieldTokens.disabledLabelColor,
          FilledTextFieldTokens.disabledLabelOpacity,
        ),
        role(FilledTextFieldTokens.errorLabelColor),
      ),
      placeholder: _StateColor.all(
        role(FilledTextFieldTokens.inputPlaceholderColor),
        disabled: role(
          FilledTextFieldTokens.disabledInputColor,
          FilledTextFieldTokens.disabledInputOpacity,
        ),
      ),
      supporting: _StateColor(
        role(FilledTextFieldTokens.focusSupportingColor),
        role(FilledTextFieldTokens.supportingColor),
        role(
          FilledTextFieldTokens.disabledSupportingColor,
          FilledTextFieldTokens.disabledSupportingOpacity,
        ),
        role(FilledTextFieldTokens.errorSupportingColor),
      ),
      prefix: _StateColor.all(
        role(FilledTextFieldTokens.inputPrefixColor),
        disabled: role(
          FilledTextFieldTokens.inputPrefixColor,
          FilledTextFieldTokens.disabledInputOpacity,
        ),
      ),
      suffix: _StateColor.all(
        role(FilledTextFieldTokens.inputSuffixColor),
        disabled: role(
          FilledTextFieldTokens.inputSuffixColor,
          FilledTextFieldTokens.disabledInputOpacity,
        ),
      ),
      cursor: role(FilledTextFieldTokens.caretColor),
      errorCursor: role(FilledTextFieldTokens.errorFocusCaretColor),
    );
  }

  /// `OutlinedTextFieldDefaults.colors()`.
  static _FieldColors _outlined(ExpressiveThemeData theme) {
    final c = theme.colors;
    Color role(ExpressiveColorRole r, [double opacity = 1]) =>
        opacity == 1 ? c.role(r) : c.role(r).withValues(alpha: opacity);
    // The outlined tokens name no container: Compose's is transparent.
    final clear = c.surface.withAlpha(0);
    return _FieldColors(
      text: _StateColor(
        role(OutlinedTextFieldTokens.focusInputColor),
        role(OutlinedTextFieldTokens.inputColor),
        role(
          OutlinedTextFieldTokens.disabledInputColor,
          OutlinedTextFieldTokens.disabledInputOpacity,
        ),
        role(OutlinedTextFieldTokens.errorInputColor),
      ),
      container: _StateColor.all(clear, disabled: clear),
      indicator: _StateColor(
        role(OutlinedTextFieldTokens.focusOutlineColor),
        role(OutlinedTextFieldTokens.outlineColor),
        role(
          OutlinedTextFieldTokens.disabledOutlineColor,
          OutlinedTextFieldTokens.disabledOutlineOpacity,
        ),
        role(OutlinedTextFieldTokens.errorOutlineColor),
      ),
      leading: _StateColor(
        role(OutlinedTextFieldTokens.focusLeadingIconColor),
        role(OutlinedTextFieldTokens.leadingIconColor),
        role(
          OutlinedTextFieldTokens.disabledLeadingIconColor,
          OutlinedTextFieldTokens.disabledLeadingIconOpacity,
        ),
        role(OutlinedTextFieldTokens.errorLeadingIconColor),
      ),
      trailing: _StateColor(
        role(OutlinedTextFieldTokens.focusTrailingIconColor),
        role(OutlinedTextFieldTokens.trailingIconColor),
        role(
          OutlinedTextFieldTokens.disabledTrailingIconColor,
          OutlinedTextFieldTokens.disabledTrailingIconOpacity,
        ),
        role(OutlinedTextFieldTokens.errorTrailingIconColor),
      ),
      label: _StateColor(
        role(OutlinedTextFieldTokens.focusLabelColor),
        role(OutlinedTextFieldTokens.labelColor),
        role(
          OutlinedTextFieldTokens.disabledLabelColor,
          OutlinedTextFieldTokens.disabledLabelOpacity,
        ),
        role(OutlinedTextFieldTokens.errorLabelColor),
      ),
      placeholder: _StateColor.all(
        role(OutlinedTextFieldTokens.inputPlaceholderColor),
        disabled: role(
          OutlinedTextFieldTokens.disabledInputColor,
          OutlinedTextFieldTokens.disabledInputOpacity,
        ),
      ),
      supporting: _StateColor(
        role(OutlinedTextFieldTokens.focusSupportingColor),
        role(OutlinedTextFieldTokens.supportingColor),
        role(
          OutlinedTextFieldTokens.disabledSupportingColor,
          OutlinedTextFieldTokens.disabledSupportingOpacity,
        ),
        role(OutlinedTextFieldTokens.errorSupportingColor),
      ),
      prefix: _StateColor.all(
        role(OutlinedTextFieldTokens.inputPrefixColor),
        disabled: role(
          OutlinedTextFieldTokens.inputPrefixColor,
          OutlinedTextFieldTokens.disabledInputOpacity,
        ),
      ),
      suffix: _StateColor.all(
        role(OutlinedTextFieldTokens.inputSuffixColor),
        disabled: role(
          OutlinedTextFieldTokens.inputSuffixColor,
          OutlinedTextFieldTokens.disabledInputOpacity,
        ),
      ),
      cursor: role(OutlinedTextFieldTokens.caretColor),
      errorCursor: role(OutlinedTextFieldTokens.errorFocusCaretColor),
    );
  }

  final _StateColor text;
  final _StateColor container;
  final _StateColor indicator;
  final _StateColor leading;
  final _StateColor trailing;
  final _StateColor label;
  final _StateColor placeholder;
  final _StateColor supporting;
  final _StateColor prefix;
  final _StateColor suffix;
  final Color cursor;
  final Color errorCursor;
}

/// The container's shape: the style's token, or Expressive's rounded one.
OutlinedBorder _shapeOf(
  ExpressiveThemeData theme,
  ExpressiveTextFieldKind style, {
  required bool rounded,
}) => theme.shapes.of(
  rounded
      ? TextFieldBehavior.roundedShape
      : switch (style) {
          ExpressiveTextFieldKind.filled =>
            FilledTextFieldTokens.containerShape,
          ExpressiveTextFieldKind.outlined =>
            OutlinedTextFieldTokens.containerShape,
        },
);

/// The indicator's (filled) or the outline's (outlined) thickness.
double _indicatorWidthOf(ExpressiveTextFieldKind style, {required bool on}) =>
    switch (style) {
      ExpressiveTextFieldKind.filled =>
        on
            ? FilledTextFieldTokens.focusActiveIndicatorHeight
            : FilledTextFieldTokens.activeIndicatorHeight,
      ExpressiveTextFieldKind.outlined =>
        on
            ? OutlinedTextFieldTokens.focusOutlineWidth
            : OutlinedTextFieldTokens.outlineWidth,
    };

/// Half the minimized label's line height (Compose's
/// `minimizedLabelHalfHeight`: `bodySmall`'s line height, which scales as
/// sp).
double _minimizedLabelHalfHeight(BuildContext context) {
  final small = context.expressiveTheme.type.of(
    FilledTextFieldTokens.supportingFont,
  );
  final lineHeight = small.fontSize! * small.height!;
  return MediaQuery.textScalerOf(context).scale(lineHeight) / 2;
}

// --- The text field ----------------------------------------------------------

/// Compose's `InputPhase`.
enum _Phase { focused, unfocusedEmpty, unfocusedNotEmpty }

class _ExpressiveTextFieldState extends State<ExpressiveTextField>
    with TickerProviderStateMixin {
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;
  bool _revealed = false;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  bool _hovered = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  late _Phase _phase = _phaseNow;

  bool get _showExpandedLabel =>
      widget.label != null && !widget.alwaysMinimizeLabel;

  _Phase get _phaseNow {
    if (_focusNode.hasFocus) return _Phase.focused;
    return _controller.text.isEmpty
        ? _Phase.unfocusedEmpty
        : _Phase.unfocusedNotEmpty;
  }

  double _labelTarget(_Phase phase) => switch (phase) {
    _Phase.focused || _Phase.unfocusedNotEmpty => 1,
    _Phase.unfocusedEmpty => _showExpandedLabel ? 0 : 1,
  };

  double _placeholderTarget(_Phase phase) => switch (phase) {
    _Phase.focused => 1,
    _Phase.unfocusedEmpty => _showExpandedLabel ? 0 : 1,
    _Phase.unfocusedNotEmpty => 0,
  };

  double _affixTarget(_Phase phase) => switch (phase) {
    _Phase.focused || _Phase.unfocusedNotEmpty => 1,
    _Phase.unfocusedEmpty => _showExpandedLabel ? 0 : 1,
  };

  late final AnimationController _label = AnimationController.unbounded(
    vsync: this,
    value: _labelTarget(_phase),
  );
  late final AnimationController _placeholder = AnimationController.unbounded(
    vsync: this,
    value: _placeholderTarget(_phase),
  );
  late final AnimationController _affix = AnimationController.unbounded(
    vsync: this,
    value: _affixTarget(_phase),
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    _focusNode.addListener(_update);
  }

  @override
  void didUpdateWidget(ExpressiveTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_update);
      if (widget.controller != null) {
        _ownController?.dispose();
        _ownController = null;
      }
      _controller.addListener(_update);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_update);
      if (widget.focusNode != null) {
        _ownFocusNode?.dispose();
        _ownFocusNode = null;
      }
      _focusNode.addListener(_update);
    }
    if (oldWidget.label != widget.label ||
        oldWidget.alwaysMinimizeLabel != widget.alwaysMinimizeLabel) {
      _phase = _phaseNow;
      _label.value = _labelTarget(_phase);
      _placeholder.value = _placeholderTarget(_phase);
      _affix.value = _affixTarget(_phase);
    } else {
      _settle();
    }
  }

  void _update() {
    if (!mounted) return;
    setState(_settle);
  }

  /// Moves to the phase focus and text now say, springing the label, the
  /// placeholder and the affixes (Compose's `updateTransition` legs).
  void _settle() {
    final next = _phaseNow;
    if (next == _phase) return;
    final from = _phase;
    _phase = next;
    final motion = ExpressiveMotion.of(context);
    _label.springTo(
      _labelTarget(next),
      motion.spring(TextFieldBehavior.labelMotion),
    );
    final slow =
        (from == _Phase.unfocusedEmpty && next == _Phase.focused) ||
        (from == _Phase.unfocusedNotEmpty && next == _Phase.unfocusedEmpty);
    _placeholder.springTo(
      _placeholderTarget(next),
      motion.spring(
        slow ? TextFieldBehavior.slowFadeMotion : TextFieldBehavior.fadeMotion,
      ),
    );
    _affix.springTo(
      _affixTarget(next),
      motion.spring(TextFieldBehavior.fadeMotion),
    );
  }

  @override
  void dispose() {
    (widget.controller ?? _ownController)?.removeListener(_update);
    (widget.focusNode ?? _ownFocusNode)?.removeListener(_update);
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    _label.dispose();
    _placeholder.dispose();
    _affix.dispose();
    super.dispose();
  }

  /// A tap on the decoration outside the input focuses it, as a tap
  /// anywhere on Compose's decorated `BasicTextField` does.
  // A tap on the decoration (padding, label, a decorative icon) acts like a
  // tap on the text: it focuses the field if needed and always reports
  // [ExpressiveTextField.onTap], so a read-only anchor (an exposed dropdown)
  // reopens its menu while it keeps focus.
  void _focusFromDecoration() {
    if (!widget.enabled) return;
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final type = theme.type;
    final enabled = widget.enabled;
    final isError = widget.errorText != null;
    final focused = _focusNode.hasFocus;
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (isError) WidgetState.error,
      if (focused) WidgetState.focused,
      if (_hovered) WidgetState.hovered,
    };
    final styled = theme.textFieldTheme.merge(widget.style);
    final colors = _FieldColors.of(
      theme.copyWith(textFieldTheme: styled),
      widget.kind,
      tonal: widget.tonal,
    );
    final customShape = styled.shape?.resolve(states);
    final shape =
        customShape ?? _shapeOf(theme, widget.kind, rounded: widget.rounded);
    final side = styled.side?.resolve(states);
    final width =
        side?.width ?? _indicatorWidthOf(widget.kind, on: focused && enabled);
    final inset = customShape != null || side != null
        ? shape
              .copyWith(side: BorderSide(width: width))
              .dimensions
              .resolve(Directionality.of(context))
        : EdgeInsets.zero;
    Color resolve(_StateColor c) => c.resolve(
      enabled: enabled,
      isError: isError,
      focused: focused,
      extraStates: states,
    );
    final outlined = widget.kind == ExpressiveTextFieldKind.outlined;
    // A pointer over an enabled, unfocused field: M3's hover tokens (Compose's
    // TextFieldColors has none), as ExpressiveFieldFrame's outline. The
    // indicator or outline turns `onSurface` (`onErrorContainer` in error)
    // and a filled field's container takes the hover state layer. A tonal
    // field, or a theme slot for the outline, fill or overlay, keeps its own.
    final hoverFace = _hovered && enabled && !focused && !widget.tonal;
    final hoverIndicator =
        hoverFace && side?.color == null && colors.indicator.slot == null
        ? theme.colors.role(
            outlined
                ? (isError
                      ? OutlinedTextFieldTokens.errorHoverOutlineColor
                      : OutlinedTextFieldTokens.hoverOutlineColor)
                : (isError
                      ? FilledTextFieldTokens.errorHoverActiveIndicatorColor
                      : FilledTextFieldTokens.hoverActiveIndicatorColor),
          )
        : null;
    final hoverLayer =
        hoverFace &&
            !outlined &&
            colors.container.slot == null &&
            styled.overlayColor?.resolve(states) == null
        ? theme.states.layerOf(theme.colors.onSurface, const <WidgetState>{
            WidgetState.hovered,
          })
        : null;
    final hasLabel = widget.label != null;
    // Compose's defaults: Inside for TextField, Cutout for OutlinedTextField;
    // tonal colours are meant for Inside (`tonalColors()`'s doc).
    final position =
        widget.labelPosition ??
        (outlined && !widget.tonal && customShape == null
            ? ExpressiveLabelPosition.cutout
            : ExpressiveLabelPosition.inside);
    final cutout = hasLabel && position == ExpressiveLabelPosition.cutout;
    final labelInside = hasLabel && !cutout;
    final showToggle =
        widget.obscureText && widget.revealable && widget.trailing == null;
    final hasTrailing = widget.trailing != null || showToggle;

    // Compose's contentPaddingWithLabel / contentPaddingWithoutLabel.
    const pad = TextFieldBehavior.padding;
    final vertical = labelInside ? TextFieldBehavior.labelVerticalPadding : pad;
    // Density moves the field's height, not where its words start (as
    // Flutter's InputDecorator): they stay on the keyline a section
    // header's and a list row's words share.
    final contentPadding =
        (styled.padding?.resolve(states)?.resolve(Directionality.of(context)) ??
            theme.density
                .padding(
                  EdgeInsets.symmetric(horizontal: pad, vertical: vertical),
                )
                .copyWith(left: pad, right: pad)) +
        inset;
    // `textFieldHorizontalIconPadding`: the 24dp icon inside its touch
    // target (none where touch targets are shrunk).
    final iconPadding = ExpressiveMinimumInteractiveSize.enforcedAt(context)
        ? (HostBehavior.minimumInteractiveComponentSize -
                  FilledTextFieldTokens.leadingIconSize) /
              2
        : 0.0;
    final startPadding = widget.leading != null
        ? math.max(contentPadding.left - iconPadding, 0.0)
        : contentPadding.left;
    final endPadding = hasTrailing
        ? math.max(contentPadding.right - iconPadding, 0.0)
        : contentPadding.right;
    final halfLabel = _minimizedLabelHalfHeight(context);

    final bodyLarge = type
        .of(FilledTextFieldTokens.inputFont)
        .merge(styled.textStyle?.resolve(states));
    final bodySmall = type.of(FilledTextFieldTokens.supportingFont);
    final labelLarge = type.of(FilledTextFieldTokens.labelFont);
    final text = _controller.text;

    Widget iconSlot(Widget icon, Color color) => IconTheme.merge(
      data: IconThemeData(
        color: color,
        size:
            styled.iconSize?.resolve(states) ??
            FilledTextFieldTokens.leadingIconSize,
      ),
      child: ExpressiveMinimumInteractiveSize(child: icon),
    );

    // Compose's text-line boxes: at least 24dp tall, content centred, the
    // start and end padding unless an affix takes it.
    Widget line(
      Widget child, {
      double start = 0,
      double end = 0,
      double minHeight = TextFieldBehavior.minTextLineHeight,
    }) => Padding(
      padding: EdgeInsetsDirectional.only(start: start, end: end),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          // A one-line field's lines (the entry, its hint, affixes and
          // label) by their capitals on the line's middle; the caret, the
          // hint and taps move with the entry.
          child: widget._singleLine ? expressiveFaceLabel(child) : child,
        ),
      ),
    );
    final textStart = widget.prefix == null ? startPadding : 0.0;
    final textEnd = widget.suffix == null ? endPadding : 0.0;

    // A one-line read-only field (a select's, a date's) shows a value too
    // long for it with an ellipsis while it is not focused, as its other
    // one-line text does; the entry stays laid out under it (its semantics,
    // taps, and selection once focused), drawn clear. The tree keeps one
    // shape either way, so focus never rebuilds the entry.
    final ellipsizes =
        widget.readOnly && widget._singleLine && !widget.obscureText;
    final shown = ellipsizes && !_focusNode.hasFocus && text.isNotEmpty;
    final textColour = resolve(colors.text);
    // The pointer's cursor over the whole field, its container and label
    // too, as Material's TextField shows it: the text cursor where it takes
    // typing, the click cursor over a read-only field that opens something
    // (a select's, a date's); a disabled field defers to what it stands on.
    final MouseCursor cursor = !enabled
        ? MouseCursor.defer
        : widget.readOnly && widget.onTap != null
        ? SystemMouseCursors.click
        : SystemMouseCursors.text;
    Widget entry = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: null,
        style: bodyLarge.copyWith(
          color: shown ? textColour.withValues(alpha: 0) : textColour,
        ),
        cursorColor: isError ? colors.errorCursor : colors.cursor,
        keyboardType:
            widget.keyboardType ??
            (widget.obscureText ? TextInputType.visiblePassword : null),
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        obscureText: widget.obscureText && !_revealed,
        autocorrect: !widget.obscureText,
        enableSuggestions: !widget.obscureText,
        minLines: widget._minLines,
        maxLines: widget._maxLines,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        enabled: enabled,
        readOnly: widget.readOnly,
        mouseCursor: enabled ? cursor : null,
        autofocus: widget.autofocus,
        autofillHints: widget.autofillHints,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onEditingComplete,
        onTap: widget.onTap,
      ),
    );
    if (ellipsizes) {
      entry = Stack(
        children: <Widget>[
          entry,
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  // A RichText, with the entry's strut: the entry's glyphs
                  // where the entry draws them, and finders still find the
                  // value once (in the entry).
                  child: RichText(
                    text: TextSpan(
                      text: shown ? text : '',
                      style: bodyLarge.copyWith(color: textColour),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    strutStyle: StrutStyle.fromTextStyle(bodyLarge),
                    textScaler: MediaQuery.textScalerOf(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final input = _InputNode(
      label: widget.semanticLabel ?? widget.label ?? widget.hintText,
      invalid: isError,
      textDirection: Directionality.of(context),
      child: line(entry, start: textStart, end: textEnd),
    );

    Widget? placeholder;
    if (widget.hintText != null && text.isEmpty) {
      placeholder = _Faded(
        opacity: _placeholder,
        child: line(
          Text(
            widget.hintText!,
            maxLines: widget._singleLine ? 1 : null,
            overflow: widget._singleLine ? TextOverflow.ellipsis : null,
            style: bodyLarge.copyWith(color: resolve(colors.placeholder)),
          ),
          start: textStart,
          end: textEnd,
        ),
      );
    }

    Widget? affix(String? value, _StateColor color, {required bool isPrefix}) {
      if (value == null) return null;
      return _Faded(
        opacity: _affix,
        child: line(
          Text(value, style: bodyLarge.copyWith(color: resolve(color))),
          start: isPrefix ? startPadding : TextFieldBehavior.affixPadding,
          end: isPrefix ? TextFieldBehavior.affixPadding : endPadding,
        ),
      );
    }

    Widget? label;
    if (hasLabel) {
      label = IgnorePointer(
        child: ExcludeSemantics(
          child: ExpressiveSpringColor(
            value: resolve(colors.label),
            motion: TextFieldBehavior.fadeMotion,
            builder: (context, color, _) => AnimatedBuilder(
              animation: _label,
              builder: (context, _) {
                final p = _label.value;
                return line(
                  Text(
                    widget.label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle.lerp(
                      labelLarge,
                      bodySmall,
                      p,
                    )!.copyWith(color: color),
                  ),
                  start: labelInside ? startPadding : 0,
                  end: labelInside ? endPadding : 0,
                  minHeight: lerpDouble(
                    TextFieldBehavior.minTextLineHeight,
                    TextFieldBehavior.minFocusedLabelLineHeight,
                    p,
                  )!,
                );
              },
            ),
          ),
        ),
      );
    }

    final error = widget.errorText;
    final supportingLine = error == null || error.isEmpty
        ? widget.helperText
        : error;
    Widget? supporting;
    if (supportingLine != null || widget.maxLength != null) {
      final style = bodySmall.copyWith(color: resolve(colors.supporting));
      supporting = Padding(
        padding: const EdgeInsetsDirectional.only(
          start: TextFieldBehavior.padding,
          top: TextFieldBehavior.supportingTopPadding,
          end: TextFieldBehavior.padding,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: TextFieldBehavior.minSupportingTextLineHeight,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: supportingLine == null
                    ? const SizedBox.shrink()
                    // A disabled field's supporting line is the field's
                    // (Compose's decoration box, in its disabled node).
                    : Semantics(
                        liveRegion: error != null && error.isNotEmpty,
                        enabled: enabled ? null : false,
                        child: Text(supportingLine, style: style),
                      ),
              ),
              if (widget.maxLength != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: TextFieldBehavior.padding,
                  ),
                  child: Text(
                    '${text.characters.length}/${widget.maxLength}',
                    style: style,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    var trailing = widget.trailing;
    if (showToggle) {
      trailing = _RevealToggle(
        revealed: _revealed,
        enabled: enabled,
        color: resolve(colors.trailing),
        onChanged: (value) => setState(() => _revealed = value),
      );
    }

    final leading = widget.leading;
    Widget field = ExpressiveSpringColor(
      value: Color.alphaBlend(
        styled.overlayColor?.resolve(states) ??
            hoverLayer ??
            expressiveTransparent,
        resolve(colors.container),
      ),
      motion: TextFieldBehavior.fadeMotion,
      builder: (context, containerColor, _) => ExpressiveSpringColor(
        // A disabled field's indicator snaps (Compose's `snap()`).
        key: ValueKey<bool>(enabled),
        value: side?.color ?? hoverIndicator ?? resolve(colors.indicator),
        motion: TextFieldBehavior.fadeMotion,
        builder: (context, indicatorColor, _) => ExpressiveSpringValue(
          key: ValueKey<bool>(enabled),
          value:
              side?.width ??
              _indicatorWidthOf(widget.kind, on: focused && enabled),
          motion: TextFieldBehavior.indicatorWidthMotion,
          builder: (context, width, _) => AnimatedBuilder(
            animation: _label,
            // The face is drawn here, not by a box the keyline and label
            // checks recognise, and a filled one is faint against the page:
            // marked, the field is one item at its face (its supporting
            // text inside the same width).
            builder: (context, _) => DesignKeylineFace(
              child: _FieldLayout(
                outlined: outlined,
                cutout: cutout,
                singleLine: widget._singleLine,
                labelProgress: _label.value,
                contentPadding: contentPadding,
                minimumSize:
                    styled.minimumSize?.resolve(states) ??
                    Size(
                      TextFieldBehavior.minWidth,
                      theme.density.height(TextFieldBehavior.minHeight),
                    ),
                iconPadding: iconPadding,
                minimizedLabelHalfHeight: halfLabel,
                shape: shape,
                containerColor: containerColor,
                indicatorColor: indicatorColor,
                indicatorWidth: math.max(width, 0),
                textDirection: Directionality.of(context),
                leading: leading == null
                    ? null
                    : iconSlot(leading, resolve(colors.leading)),
                trailing: trailing == null
                    ? null
                    : iconSlot(trailing, resolve(colors.trailing)),
                prefix: affix(widget.prefix, colors.prefix, isPrefix: true),
                suffix: affix(widget.suffix, colors.suffix, isPrefix: false),
                label: label,
                placeholder: placeholder,
                input: input,
                supporting: supporting,
              ),
            ),
          ),
        ),
      ),
    );
    field = GestureDetector(
      onTap: _focusFromDecoration,
      excludeFromSemantics: true,
      child: field,
    );
    // `topPaddingForLabelCutout`: room above the outline for the label.
    if (cutout) {
      field = Padding(
        padding: EdgeInsets.only(top: halfLabel),
        child: field,
      );
    }
    return MouseRegion(
      cursor: cursor,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: field,
    );
  }
}

/// The input's node, as large as the field's container: Compose's text
/// field is one node over its decorated box (`BasicTextField`'s
/// `decorationBox`), so assistive technology and touch-target checks read
/// the container, not the line of text. It carries the field's label and
/// validity.
class _InputNode extends SingleChildRenderObjectWidget {
  const _InputNode({
    required this.label,
    required this.invalid,
    required this.textDirection,
    required super.child,
  });

  final String? label;
  final bool invalid;
  final TextDirection textDirection;

  @override
  _RenderInputNode createRenderObject(BuildContext context) =>
      _RenderInputNode(label, invalid, textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderInputNode renderObject,
  ) => renderObject
    ..label = label
    ..invalid = invalid
    ..textDirection = textDirection;
}

class _RenderInputNode extends RenderProxyBox {
  _RenderInputNode(this._label, this._invalid, this._textDirection);

  String? _label;
  set label(String? value) {
    if (value == _label) return;
    _label = value;
    markNeedsSemanticsUpdate();
  }

  bool _invalid;
  set invalid(bool value) {
    if (value == _invalid) return;
    _invalid = value;
    markNeedsSemanticsUpdate();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  /// The field's container in this box's coordinates, set by the field's
  /// layout.
  Rect? _container;
  set container(Rect value) {
    if (value == _container) return;
    _container = value;
    markNeedsSemanticsUpdate();
  }

  @override
  Rect get semanticBounds =>
      _container?.expandToInclude(super.semanticBounds) ?? super.semanticBounds;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    // Not a boundary: where a control around the field merges it (a
    // select's), the field's words stay that control's.
    super.describeSemanticsConfiguration(config);
    config.validationResult = _invalid
        ? SemanticsValidationResult.invalid
        : SemanticsValidationResult.none;
    final label = _label;
    if (label != null) {
      config
        ..label = label
        ..textDirection = _textDirection;
    }
  }
}

/// [child] at [opacity]'s value, gone (and silent) at zero: Compose drops
/// a transparent placeholder or affix (b/261061240).
class _Faded extends StatelessWidget {
  const _Faded({required this.opacity, required this.child});

  final Animation<double> opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: opacity,
    builder: (context, child) {
      final value = opacity.value.clamp(0.0, 1.0);
      return IgnorePointer(
        child: value <= 0
            ? const SizedBox.shrink()
            : Opacity(opacity: value, child: child),
      );
    },
    child: child,
  );
}

/// A secure field's visibility toggle: a standard icon button (40dp,
/// round, pressed morph) flipping between `visibility` and
/// `visibility_off`.
class _RevealToggle extends StatelessWidget {
  const _RevealToggle({
    required this.revealed,
    required this.enabled,
    required this.color,
    required this.onChanged,
  });

  final bool revealed;
  final bool enabled;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final shapes = context.expressiveTheme.shapes;
    // The 40dp button keeps its 48dp target (an `IconButton` in Compose's
    // trailing slot): the size is the face's, inside the press.
    return ExpressivePressable(
      shapes: ExpressivePressShapes(
        shape: shapes.of(SmallIconButtonTokens.containerShapeRound),
        pressed: shapes.of(SmallIconButtonTokens.pressedContainerShape),
      ),
      motion: ExpressiveMotionKey.fastSpatial,
      color: color.withAlpha(0),
      contentColor: color,
      role: ExpressivePressRole.toggle,
      selected: revealed,
      semanticLabel: revealed
          ? ExpressiveLocalizations.of(context).hidePassword
          : ExpressiveLocalizations.of(context).showPassword,
      onPressed: enabled ? () => onChanged(!revealed) : null,
      child: SizedBox.square(
        dimension: SmallIconButtonTokens.containerHeight,
        child: Center(
          child: Icon(
            revealed
                ? ExpressiveSymbols.visibilityOff
                : ExpressiveSymbols.visibility,
            size: SmallIconButtonTokens.iconSize,
            color: color,
          ),
        ),
      ),
    );
  }
}

// --- The decoration's layout -------------------------------------------------

/// The decoration's slots (Compose's layout ids).
enum _Slot {
  leading,
  trailing,
  prefix,
  suffix,
  label,
  placeholder,
  input,
  supporting,
}

/// Compose's `InsideTextFieldLayout` / `CutoutTextFieldLayout` with its
/// container: one render object that measures and places the slots as
/// `TextFieldMeasurePolicy` / `OutlinedTextFieldMeasurePolicy` do, and
/// paints the container (its fill, the filled indicator or the outline and
/// its cutout) under them.
class _FieldLayout
    extends SlottedMultiChildRenderObjectWidget<_Slot, RenderBox> {
  const _FieldLayout({
    required this.outlined,
    required this.cutout,
    required this.singleLine,
    required this.labelProgress,
    required this.contentPadding,
    required this.minimumSize,
    required this.iconPadding,
    required this.minimizedLabelHalfHeight,
    required this.shape,
    required this.containerColor,
    required this.indicatorColor,
    required this.indicatorWidth,
    required this.textDirection,
    required this.input,
    this.leading,
    this.trailing,
    this.prefix,
    this.suffix,
    this.label,
    this.placeholder,
    this.supporting,
  });

  final bool outlined;
  final bool cutout;
  final bool singleLine;
  final double labelProgress;
  final EdgeInsets contentPadding;
  final Size minimumSize;
  final double iconPadding;
  final double minimizedLabelHalfHeight;
  final OutlinedBorder shape;
  final Color containerColor;
  final Color indicatorColor;
  final double indicatorWidth;
  final TextDirection textDirection;
  final Widget input;
  final Widget? leading;
  final Widget? trailing;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? label;
  final Widget? placeholder;
  final Widget? supporting;

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => switch (slot) {
    _Slot.leading => leading,
    _Slot.trailing => trailing,
    _Slot.prefix => prefix,
    _Slot.suffix => suffix,
    _Slot.label => label,
    _Slot.placeholder => placeholder,
    _Slot.input => input,
    _Slot.supporting => supporting,
  };

  @override
  _RenderField createRenderObject(BuildContext context) =>
      _RenderField().._configure(this);

  @override
  void updateRenderObject(BuildContext context, _RenderField renderObject) =>
      renderObject._configure(this);
}

/// Where one layout pass (dry or real) put everything.
class _Placement {
  _Placement(this.size, this.height, this.label);

  /// The whole field, supporting text included.
  final Size size;

  /// The container's height: the field without its supporting text.
  final double height;

  /// The label's measured size, for the outline's cutout.
  final Size label;

  final Map<_Slot, Offset> offsets = <_Slot, Offset>{};
}

class _RenderField extends RenderBox
    with SlottedContainerRenderObjectMixin<_Slot, RenderBox> {
  bool _outlined = false;
  bool _cutout = false;
  bool _singleLine = true;
  double _labelProgress = 0;
  EdgeInsets _padding = EdgeInsets.zero;
  Size _minimumSize = const Size(
    TextFieldBehavior.minWidth,
    TextFieldBehavior.minHeight,
  );
  double _iconPadding = 0;
  double _halfLabel = 0;
  OutlinedBorder _shape = const RoundedRectangleBorder();
  Color? _containerColor;
  Color? _indicatorColor;
  double _indicatorWidth = 0;
  TextDirection _textDirection = TextDirection.ltr;

  _Placement? _placement;

  void _configure(_FieldLayout w) {
    final relayout =
        w.outlined != _outlined ||
        w.cutout != _cutout ||
        w.singleLine != _singleLine ||
        w.labelProgress != _labelProgress ||
        w.contentPadding != _padding ||
        w.minimumSize != _minimumSize ||
        w.iconPadding != _iconPadding ||
        w.minimizedLabelHalfHeight != _halfLabel ||
        w.textDirection != _textDirection;
    final repaint =
        w.shape != _shape ||
        w.containerColor != _containerColor ||
        w.indicatorColor != _indicatorColor ||
        w.indicatorWidth != _indicatorWidth;
    _outlined = w.outlined;
    _cutout = w.cutout;
    _singleLine = w.singleLine;
    _labelProgress = w.labelProgress;
    _padding = w.contentPadding;
    _minimumSize = w.minimumSize;
    _iconPadding = w.iconPadding;
    _halfLabel = w.minimizedLabelHalfHeight;
    _shape = w.shape;
    _containerColor = w.containerColor;
    _indicatorColor = w.indicatorColor;
    _indicatorWidth = w.indicatorWidth;
    _textDirection = w.textDirection;
    if (relayout) {
      markNeedsLayout();
    } else if (repaint) {
      markNeedsPaint();
    }
  }

  static const List<_Slot> _paintOrder = <_Slot>[
    _Slot.leading,
    _Slot.trailing,
    _Slot.prefix,
    _Slot.placeholder,
    _Slot.input,
    _Slot.suffix,
    _Slot.label,
    _Slot.supporting,
  ];

  @override
  Iterable<RenderBox> get children => <RenderBox>[
    for (final slot in _paintOrder) ?childForSlot(slot),
  ];

  /// Compose's `defaultMinSize(MinWidth, MinHeight)`: the minimum size where
  /// the parent leaves the field free.
  BoxConstraints _withMinSize(BoxConstraints c) => c.copyWith(
    minWidth: c.minWidth == 0
        ? math.min<double>(_minimumSize.width, c.maxWidth)
        : c.minWidth,
    minHeight: c.minHeight == 0
        ? math.min<double>(_minimumSize.height, c.maxHeight)
        : c.minHeight,
  );

  static double _less(double value, double amount) =>
      value.isInfinite ? value : math.max(0, value - amount);

  /// `EasingEmphasizedAccelerateCubicBezier.transform(t)`: the cubic
  /// Bézier through (0,0), (x1,y1), (x2,y2), (1,1), solved for x = [t]. A
  /// layout mapping of the label's spring-driven progress, not a timing
  /// curve.
  static double _emphasizedAccelerate(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    const x1 = TextFieldBehavior.labelHeightEasingX1;
    const y1 = TextFieldBehavior.labelHeightEasingY1;
    const x2 = TextFieldBehavior.labelHeightEasingX2;
    const y2 = TextFieldBehavior.labelHeightEasingY2;
    double bezier(double a, double b, double s) {
      final r = 1 - s;
      return 3 * a * r * r * s + 3 * b * r * s * s + s * s * s;
    }

    var lo = 0.0;
    var hi = 1.0;
    var s = t;
    for (var i = 0; i < 32; i++) {
      s = (lo + hi) / 2;
      if (bezier(x1, x2, s) < t) {
        lo = s;
      } else {
        hi = s;
      }
    }
    return bezier(y1, y2, s);
  }

  /// Measures and places every slot under [incoming], laying the children
  /// out with [layoutChild] (a real or a dry layout).
  _Placement _measure(BoxConstraints incoming, ChildLayouter layoutChild) {
    final c = _withMinSize(incoming);
    final p = _labelProgress;
    final loose = c.loosen();
    final top = _padding.top;
    final bottom = _padding.bottom;
    final horizontal = _padding.horizontal;
    Size sizeOf(_Slot slot, BoxConstraints constraints) {
      final child = childForSlot(slot);
      return child == null ? Size.zero : layoutChild(child, constraints);
    }

    BoxConstraints beside(double occupied) =>
        loose.copyWith(maxWidth: _less(loose.maxWidth, occupied));

    var occupied = 0.0;
    final leading = sizeOf(_Slot.leading, loose);
    occupied += leading.width;
    final trailing = sizeOf(_Slot.trailing, beside(occupied));
    occupied += trailing.width;
    final prefix = sizeOf(_Slot.prefix, beside(occupied));
    occupied += prefix.width;
    final suffix = sizeOf(_Slot.suffix, beside(occupied));
    occupied += suffix.width;

    // The label: beside the icons inside a filled field; in an outlined
    // one, beside them while expanded and across the padded width once
    // minimized.
    final labelOffset = _cutout
        ? lerpDouble(occupied + horizontal, horizontal, p)!
        : occupied;
    final label = sizeOf(
      _Slot.label,
      loose.copyWith(
        maxWidth: _less(loose.maxWidth, labelOffset),
        maxHeight: _less(loose.maxHeight, bottom),
      ),
    );

    final supportingChild = childForSlot(_Slot.supporting);
    final supportingReserve = supportingChild == null
        ? 0.0
        : supportingChild.getMinIntrinsicHeight(c.minWidth);

    // The input: Compose measures it at the field's minimum width less what
    // is beside it, and lets it grow with its text; Flutter's editing core
    // always fills its width, so a field left free keeps its minimum width
    // and scrolls its text instead.
    final inputTop = _cutout
        ? math.max(label.height / 2, top)
        : top + label.height;
    final inputWidth = math.max(0.0, c.minWidth - occupied);
    final inputMaxHeight = _less(
      c.maxHeight,
      inputTop + bottom + supportingReserve,
    );
    final input = sizeOf(
      _Slot.input,
      BoxConstraints(
        minWidth: inputWidth,
        maxWidth: inputWidth,
        maxHeight: inputMaxHeight,
      ),
    );
    final placeholder = sizeOf(
      _Slot.placeholder,
      BoxConstraints(maxWidth: inputWidth, maxHeight: inputMaxHeight),
    );
    final occupiedVertically = math.max(
      math.max(leading.height, trailing.height),
      math.max(input.height, placeholder.height) + inputTop + bottom,
    );

    // calculateWidth.
    final affixes = prefix.width + suffix.width;
    final text = math.max(input.width, placeholder.width) + affixes;
    final double width;
    if (_cutout) {
      final middle = math.max(text, lerpDouble(label.width, 0, p)!);
      width = c.constrainWidth(
        math.max(
          leading.width + middle + trailing.width,
          (label.width + horizontal) * p,
        ),
      );
    } else {
      width = c.constrainWidth(
        leading.width + math.max(text, label.width) + trailing.width,
      );
    }

    final supporting = sizeOf(
      _Slot.supporting,
      BoxConstraints(
        minWidth: width,
        maxWidth: width,
        maxHeight: _less(loose.maxHeight, occupiedVertically),
      ),
    );

    // calculateHeight.
    final inputField = <double>[
      input.height,
      placeholder.height,
      prefix.height,
      suffix.height,
      lerpDouble(label.height, 0, p)!,
    ].reduce(math.max);
    final double middle;
    if (_cutout) {
      final actualTop = lerpDouble(top, math.max(top, label.height / 2), p)!;
      middle = actualTop + inputField + bottom;
    } else {
      // The label's allowance: a baseline height while it overlaps the
      // input, so the field keeps its height through the animation.
      final allowance = label.height > 0
          ? math.max(_halfLabel * 2, label.height * _emphasizedAccelerate(p))
          : 0.0;
      middle = top + bottom + allowance + inputField;
    }
    final totalHeight = c.constrainHeight(
      math.max(math.max(leading.height, trailing.height), middle) +
          supporting.height,
    );
    final height = totalHeight - supporting.height;

    final placement = _Placement(Size(width, totalHeight), height, label);
    final offsets = placement.offsets;
    final rtl = _textDirection == TextDirection.rtl;
    // A start-relative x (Compose's `placeRelative`) as a left edge.
    double x(double start, double childWidth) =>
        rtl ? width - start - childWidth : start;
    double centred(double childHeight) => (height - childHeight) / 2;

    offsets[_Slot.leading] = Offset(
      x(0, leading.width),
      centred(leading.height),
    );
    offsets[_Slot.trailing] = Offset(
      x(width - trailing.width, trailing.width),
      centred(trailing.height),
    );
    final textX = leading.width + prefix.width;
    final suffixX = width - trailing.width - suffix.width;

    void placeText(double Function(double childHeight) y) {
      offsets[_Slot.prefix] = Offset(
        x(leading.width, prefix.width),
        y(prefix.height),
      );
      offsets[_Slot.input] = Offset(x(textX, input.width), y(input.height));
      offsets[_Slot.placeholder] = Offset(
        x(textX, placeholder.width),
        y(placeholder.height),
      );
      offsets[_Slot.suffix] = Offset(
        x(suffixX, suffix.width),
        y(suffix.height),
      );
    }

    final hasLabel = childForSlot(_Slot.label) != null;
    if (_cutout) {
      final padStart = rtl ? _padding.right : _padding.left;
      if (hasLabel) {
        final startY = _singleLine ? centred(label.height) : top;
        final endY = -(label.height / 2);
        // Start alignment: the expanded label rests after the leading icon
        // and its padding; the minimized one at the outline's start
        // padding.
        final startX = leading.width > 0
            ? leading.width + math.max(padStart - _iconPadding, 0)
            : padStart;
        offsets[_Slot.label] = Offset(
          x(lerpDouble(startX, padStart, p)!, label.width),
          lerpDouble(startY, endY, p)!,
        );
      }
      placeText(
        (h) => math.max(_singleLine ? centred(h) : top, label.height / 2),
      );
    } else if (hasLabel) {
      final startY = _singleLine ? centred(label.height) : top + _halfLabel;
      offsets[_Slot.label] = Offset(
        x(leading.width, label.width),
        lerpDouble(startY, top, p)!,
      );
      final textY = top + label.height;
      placeText((_) => textY);
    } else {
      placeText((h) => _singleLine ? centred(h) : top);
    }
    offsets[_Slot.supporting] = Offset(0, height);
    return placement;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _measure(constraints, ChildLayoutHelper.dryLayoutChild).size;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _intrinsicWidth((child) => child.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _intrinsicWidth((child) => child.getMaxIntrinsicWidth(double.infinity));

  double _intrinsicWidth(double Function(RenderBox child) measure) {
    double w(_Slot slot) {
      final child = childForSlot(slot);
      return child == null ? 0 : measure(child);
    }

    final affixes = w(_Slot.prefix) + w(_Slot.suffix);
    final middle = <double>[
      w(_Slot.input) + affixes,
      w(_Slot.placeholder) + affixes,
      w(_Slot.label),
    ].reduce(math.max);
    return math.max(
      TextFieldBehavior.minWidth,
      w(_Slot.leading) + middle + w(_Slot.trailing),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) => _measure(
    BoxConstraints(maxWidth: width),
    ChildLayoutHelper.dryLayoutChild,
  ).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void performLayout() {
    final placement = _measure(constraints, ChildLayoutHelper.layoutChild);
    for (final slot in _Slot.values) {
      final child = childForSlot(slot);
      if (child == null) continue;
      (child.parentData! as BoxParentData).offset =
          placement.offsets[slot] ?? Offset.zero;
    }
    _placement = placement;
    size = placement.size;
    final input = childForSlot(_Slot.input);
    if (input is _RenderInputNode) {
      input.container = _container.shift(
        -(input.parentData! as BoxParentData).offset,
      );
    }
  }

  Rect get _container =>
      Offset.zero & Size(size.width, _placement?.height ?? size.height);

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final rect = _container.shift(offset);
    final outer = _shape.getOuterPath(rect, textDirection: _textDirection);
    canvas.save();
    // Compose's `outlineCutout`: the container is drawn less a gap for the
    // minimized label across its top edge.
    final label = (_placement?.label ?? Size.zero) * _labelProgress;
    if (_cutout && label.width > 0) {
      const inner = TextFieldBehavior.cutoutPadding;
      final rtl = _textDirection == TextDirection.rtl;
      final space = rect.width - _padding.horizontal;
      final aligned = rtl ? space - label.width : 0.0;
      final halfWidth = label.width / 2;
      final halfHeight = label.height / 2;
      final centre = rect.left + _padding.left + aligned + halfWidth;
      final gap = Rect.fromLTRB(
        math.max(centre - halfWidth - inner, rect.left),
        rect.top - halfHeight,
        math.min(centre + halfWidth + inner, rect.right),
        rect.top + halfHeight,
      );
      // The gap as an even-odd hole, not Path.combine(difference): the web
      // renderer leaves a difference uncut, and the outline ran through the
      // label there.
      canvas.clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(rect.inflate(_indicatorWidth + label.height))
          ..addRect(gap),
      );
    }
    final fill = _containerColor;
    if (fill != null && fill.a > 0) {
      canvas.drawPath(outer, Paint()..color = fill);
    }
    final stroke = _indicatorColor;
    if (_indicatorWidth > 0 && stroke != null && stroke.a > 0) {
      if (_outlined) {
        // The outline inside the container's edge (Compose's
        // `Modifier.border`).
        _shape
            .copyWith(
              side: BorderSide(
                color: stroke,
                width: _indicatorWidth,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            )
            .paint(canvas, rect, textDirection: _textDirection);
      } else {
        // The indicator: a strip along the bottom edge, clipped to the
        // container's shape (Compose's `IndicatorLineNode`). A clip, not
        // Path.combine(intersect): the web renderer leaves a combined path
        // uncut, and the strip ran on past rounded corners.
        canvas
          ..save()
          ..clipPath(outer)
          ..drawRect(
            Rect.fromLTRB(
              rect.left,
              rect.bottom - _indicatorWidth,
              rect.right,
              rect.bottom,
            ),
            Paint()..color = stroke,
          )
          ..restore();
      }
    }
    canvas.restore();
    for (final child in children) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestSelf(Offset position) => _container.contains(position);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children.toList().reversed) {
      final hit = result.addWithPaintOffset(
        offset: (child.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}

// --- The code input ----------------------------------------------------------

class _ExpressiveCodeInputState extends State<ExpressiveInputOtp> {
  late DesignOtpController _code = _makeCode();

  /// ui_core's code over the caller's controller, when there is one (a
  /// form's, the kit contract's), so the code is read and written there.
  DesignOtpController _makeCode() => DesignOtpController(
    length: widget.length,
    allowed: widget.numeric ? RegExp(r'\d') : RegExp(r'\S'),
    text: widget.controller,
  );

  @override
  void didUpdateWidget(ExpressiveInputOtp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.length != widget.length ||
        oldWidget.numeric != widget.numeric) {
      final old = _code;
      _code = _makeCode();
      // Once the field has moved its listeners onto the new code.
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final styled = theme.textFieldTheme
        .merge(theme.inputOtpTheme)
        .merge(widget.style);
    final colors = _FieldColors.of(
      theme.copyWith(textFieldTheme: styled),
      widget.kind,
      tonal: false,
    );
    final enabled = widget.enabled;
    final isError = widget.isError || widget.errorText != null;
    final outlined = widget.kind == ExpressiveTextFieldKind.outlined;
    final glyph = theme.type.headlineSmall;

    Widget cell(DesignOtpSlot slot) {
      final on = slot.focused && slot.active;
      final states = <WidgetState>{
        if (!enabled) WidgetState.disabled,
        if (isError) WidgetState.error,
        if (on) WidgetState.focused,
      };
      final customShape = styled.shape?.resolve(states);
      final shape =
          customShape ?? _shapeOf(theme, widget.kind, rounded: widget.rounded);
      final side = styled.side?.resolve(states);
      final padding =
          (styled.padding
                  ?.resolve(states)
                  ?.resolve(Directionality.of(context)) ??
              EdgeInsets.zero) +
          (customShape != null || side != null
              ? shape
                    .copyWith(
                      side: BorderSide(
                        width:
                            side?.width ??
                            _indicatorWidthOf(widget.kind, on: on && enabled),
                      ),
                    )
                    .dimensions
                    .resolve(Directionality.of(context))
              : EdgeInsets.zero);
      final minimum = styled.minimumSize?.resolve(states);
      Color resolve(_StateColor c) => c.resolve(
        enabled: enabled,
        isError: isError,
        focused: on,
        extraStates: states,
      );
      final character = slot.filled ? slot.character : null;
      return ExpressiveSpringColor(
        value: side?.color ?? resolve(colors.indicator),
        motion: TextFieldBehavior.fadeMotion,
        builder: (context, indicatorColor, _) => ExpressiveSpringValue(
          value:
              side?.width ?? _indicatorWidthOf(widget.kind, on: on && enabled),
          motion: TextFieldBehavior.indicatorWidthMotion,
          builder: (context, width, _) => CustomPaint(
            painter: _CellPainter(
              outlined: outlined,
              shape: shape,
              containerColor: Color.alphaBlend(
                styled.overlayColor?.resolve(states) ?? expressiveTransparent,
                resolve(colors.container),
              ),
              indicatorColor: indicatorColor,
              indicatorWidth: math.max(width, 0),
              textDirection: Directionality.of(context),
            ),
            child: SizedBox(
              width: minimum?.width ?? ExpressiveSpacing.s48,
              height:
                  minimum?.height ??
                  theme.density.height(OutlinedTextFieldTokens.containerHeight),
              child: Padding(
                padding: padding,
                child: Center(
                  child: character == null
                      ? null
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            slot.obscured ? '•' : character,
                            style: glyph
                                .merge(styled.textStyle?.resolve(states))
                                .copyWith(color: resolve(colors.text)),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ui_core's code field: one input under the cells (a paste or the
    // platform's one-time-code autofill fills every cell, backspace steps
    // back, the caret stays at the end), its name, length and error on one
    // node, and Paste on a long press or a secondary click, in Material's
    // adaptive toolbar as Expressive's text fields offer it.
    final field = DesignOtpField(
      controller: _code,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: enabled,
      isError: isError,
      obscureText: widget.obscure,
      keyboardType: widget.numeric ? TextInputType.number : TextInputType.text,
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      semanticLabel:
          widget.semanticLabel ??
          ExpressiveLocalizations.of(context).codeInput(widget.length),
      onChanged: widget.onChanged,
      onCompleted: widget.onCompleted,
      contextMenuBuilder: (context, anchors, items) =>
          AdaptiveTextSelectionToolbar.buttonItems(
            anchors: anchors,
            buttonItems: items,
          ),
      slotBuilder: (context, slot) => cell(slot),
      // A code reads left to right in every language (the field lays its
      // cells out left to right under a right-to-left page too). The cells
      // share the row: the code spans its field's width, as the actions
      // under it do.
      layoutBuilder: (context, slots) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 0; i < slots.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: ExpressiveSpacing.s8),
            Expanded(child: slots[i]),
          ],
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        field,
        if (widget.errorText != null) ExpressiveFieldError(widget.errorText!),
      ],
    );
  }
}

/// A code cell's container: the field's fill and its indicator or outline.
class _CellPainter extends CustomPainter {
  const _CellPainter({
    required this.outlined,
    required this.shape,
    required this.containerColor,
    required this.indicatorColor,
    required this.indicatorWidth,
    required this.textDirection,
  });

  final bool outlined;
  final OutlinedBorder shape;
  final Color containerColor;
  final Color indicatorColor;
  final double indicatorWidth;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = shape.getOuterPath(rect, textDirection: textDirection);
    if (containerColor.a > 0) {
      canvas.drawPath(outer, Paint()..color = containerColor);
    }
    if (indicatorWidth <= 0 || indicatorColor.a <= 0) return;
    if (outlined) {
      shape
          .copyWith(
            side: BorderSide(
              color: indicatorColor,
              width: indicatorWidth,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          )
          .paint(canvas, rect, textDirection: textDirection);
    } else {
      // Clipped, not Path.combine(intersect), which the web renderer
      // leaves uncut (see the field's own indicator).
      canvas
        ..save()
        ..clipPath(outer)
        ..drawRect(
          Rect.fromLTRB(
            rect.left,
            rect.bottom - indicatorWidth,
            rect.right,
            rect.bottom,
          ),
          Paint()..color = indicatorColor,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_CellPainter old) =>
      old.outlined != outlined ||
      old.shape != shape ||
      old.containerColor != containerColor ||
      old.indicatorColor != indicatorColor ||
      old.indicatorWidth != indicatorWidth ||
      old.textDirection != textDirection;
}

// ---------------------------------------------------------------------------
// The password field
// ---------------------------------------------------------------------------

/// A password field: [ExpressiveTextField] with its text hidden and the
/// eye after it (the secure text field's own toggle, a 40dp round icon
/// button in `onSurfaceVariant`, `error` in error) that shows and hides it.
/// The reveal is ui_core's `DesignPasswordReveal`: the toggle is named
/// "Show password" or "Hide password" and reads as a toggle, and with
/// [hideOnBlur] the text hides again when the field loses focus. Autofill
/// offers saved passwords.
///
/// ```dart
/// ExpressivePasswordField(label: 'Password', controller: password)
/// ```
class ExpressivePasswordField extends StatelessWidget {
  /// A password field.
  const ExpressivePasswordField({
    this.controller,
    this.focusNode,
    this.kind = ExpressiveTextFieldKind.filled,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.hideOnBlur = false,
    this.autofillHints = const <String>[AutofillHints.password],
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  /// The text; one is made when null.
  final TextEditingController? controller;

  /// The field's focus.
  final FocusNode? focusNode;

  /// Filled or outlined.
  final ExpressiveTextFieldKind kind;

  /// The label.
  final String? label;

  /// Shown while it is empty.
  final String? hintText;

  /// A line under the field.
  final String? helperText;

  /// What is wrong, under the field in `error`.
  final String? errorText;

  /// Whether it takes input.
  final bool enabled;

  /// Whether it takes focus when first built.
  final bool autofocus;

  /// Whether the text hides again when the field loses focus.
  final bool hideOnBlur;

  /// What autofill offers.
  final Iterable<String> autofillHints;

  /// The keyboard's action.
  final TextInputAction? textInputAction;

  /// Each edit.
  final ValueChanged<String>? onChanged;

  /// Enter.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final strings = ExpressiveLocalizations.of(context);
    final error = errorText != null;
    return DesignPasswordReveal(
      focusNode: focusNode,
      hideOnBlur: hideOnBlur,
      showLabel: strings.showPassword,
      hideLabel: strings.hidePassword,
      builder: (context, password) => ExpressiveTextField(
        controller: controller,
        focusNode: focusNode,
        kind: kind,
        label: label,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        enabled: enabled,
        autofocus: autofocus,
        obscureText: password.obscured,
        revealable: false,
        autofillHints: autofillHints,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        trailing: _RevealToggle(
          revealed: !password.obscured,
          enabled: enabled,
          color: !enabled
              ? t.colors.onSurface.withValues(alpha: 0.38)
              : error
              ? t.colors.error
              : t.colors.onSurfaceVariant,
          onChanged: (_) => password.toggle(),
        ),
      ),
    );
  }
}
