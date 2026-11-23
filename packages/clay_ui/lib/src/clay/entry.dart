/// Clay's other fields: a text area, a search pill, a password, a field
/// with add-ons, a one-time code, a number between two keys, a combobox,
/// tags in a well, and the form field that labels any control.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'feedback.dart' show ClaySpinner;
import 'fonts.dart';
import 'internal/entry_parts.dart';
import 'internal/keys_shown.dart';
import 'internal/menu.dart';
import 'internal/words_fit.dart';
import 'surface.dart';
import 'text_field.dart';
import 'theme.dart';

String _words(Object option) => option.toString();

/// A small key set at a well's end (clear, show): 40 px, its glyph 18.
const ClayStyle _wellKey = ClayStyle(
  minimumSize: WidgetStatePropertyAll(Size(40, 40)),
  iconSize: WidgetStatePropertyAll(18),
);

/// Owns a controller and a focus node when the caller gives none.
mixin _OwnsEntry<W extends StatefulWidget> on State<W> {
  TextEditingController? get givenController;
  FocusNode? get givenFocusNode;

  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get controller =>
      givenController ?? (_ownController ??= TextEditingController());
  FocusNode get focusNode => givenFocusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }
}

/// A label above a field and its help or error under it, round [field],
/// read with it.
Widget _labelled({
  required String? label,
  required bool enabled,
  required Widget field,
  String? helper,
  String? error,
  FocusNode? focusNode,
}) => ClayFieldDecorator(
  labelText: label,
  helperText: helper,
  errorText: error,
  enabled: enabled,
  focusNode: focusNode,
  child: field,
);

/// A field for a few lines of words (a note, why a habit matters): the
/// text field's well, growing from [minLines] as the words run on.
///
/// ```dart
/// ClayTextArea(labelText: 'Note', hintText: 'What helps you keep it')
/// ```
class ClayTextArea extends StatelessWidget {
  /// A text area.
  const ClayTextArea({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.minLines = 3,
    this.maxLines,
    this.maxLength,
    this.style,
  });

  /// The words, when the caller reads or sets them; null: the field keeps
  /// its own.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The words above the well.
  final String? labelText;

  /// What the empty area says.
  final String? hintText;

  /// Help under the well.
  final String? helperText;

  /// What is wrong, under the well, in the danger ink.
  final String? errorText;

  /// Each change of the words.
  final ValueChanged<String>? onChanged;

  /// Whether it takes words.
  final bool enabled;

  /// Whether the words can be read and selected but not changed.
  final bool readOnly;

  /// The lines it shows when empty.
  final int minLines;

  /// The most lines it grows to before it scrolls; null: any.
  final int? maxLines;

  /// The most characters it takes; the count shows under it.
  final int? maxLength;

  /// This area's own style, over [ClayThemeData.textFieldStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) => ClayTextField(
    controller: controller,
    focusNode: focusNode,
    labelText: labelText,
    hintText: hintText,
    helperText: helperText,
    errorText: errorText,
    onChanged: onChanged,
    enabled: enabled,
    readOnly: readOnly,
    minLines: minLines,
    maxLines: maxLines == null ? null : math.max(maxLines!, minLines),
    maxLength: maxLength,
    keyboardType: TextInputType.multiline,
    textInputAction: TextInputAction.newline,
    textCapitalization: TextCapitalization.sentences,
    style: style,
  );
}

/// A search: a round-ended well with a lens at its start and a key that
/// clears it once there are words.
///
/// ```dart
/// ClaySearchField(hintText: 'Search habits', onChanged: (query) {})
/// ```
class ClaySearchField extends StatefulWidget {
  /// A search field.
  const ClaySearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.semanticLabel,
    this.style,
  });

  /// The words, when the caller reads or sets them; null: the field keeps
  /// its own.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// What the empty field says; null: "Search".
  final String? hintText;

  /// Each change of the query, and '' when it is cleared.
  final ValueChanged<String>? onChanged;

  /// Enter.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes words.
  final bool enabled;

  /// Whether it takes the focus when it first shows.
  final bool autofocus;

  /// What a screen reader calls it; null: [hintText].
  final String? semanticLabel;

  /// This field's own style, over [ClayThemeData.searchFieldStyle].
  final ClayStyle? style;

  @override
  State<ClaySearchField> createState() => _ClaySearchFieldState();
}

class _ClaySearchFieldState extends State<ClaySearchField>
    with _OwnsEntry<ClaySearchField> {
  @override
  TextEditingController? get givenController => widget.controller;
  @override
  FocusNode? get givenFocusNode => widget.focusNode;

  void _clear() {
    controller.clear();
    widget.onChanged?.call('');
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final words = RawWidgetsLocalizations.of(context);
    final hintText = widget.hintText ?? words.searchFieldLabel;
    return ClayOnFocus(
      focusNode: focusNode,
      builder: (context, focused) {
        final states = {
          if (!widget.enabled) WidgetState.disabled,
          if (focused) WidgetState.focused,
        };
        final layered = DesignStyleOf([
          widget.style,
          theme.searchFieldStyle,
        ], states);
        return ClayEntryWell(
          focusNode: focusNode,
          enabled: widget.enabled,
          face: clayEntryFace(
            theme,
            states,
            fill: layered.fill,
            edge: layered.edge,
            radius: theme.controlHeight / 2,
          ),
          leading: const Icon(LucideIcons.search),
          trailing: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => controller.text.isEmpty || !widget.enabled
                ? const SizedBox(width: ClaySpacing.small)
                : ClayIconButton.plain(
                    onPressed: _clear,
                    tooltip: words.clearButtonTooltip,
                    style: _wellKey,
                    icon: const Icon(LucideIcons.x),
                  ),
          ),
          child: ClayEntryText(
            controller: controller,
            focusNode: focusNode,
            hintText: hintText,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.search,
            semanticLabel: widget.semanticLabel ?? hintText,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            textStyle: layered.textStyle,
          ),
        );
      },
    );
  }
}

/// A password: the text field's well with a key at its end that shows and
/// hides the words, the caret staying where it was.
///
/// ```dart
/// ClayPasswordField(labelText: 'Password', onChanged: (value) {})
/// ```
class ClayPasswordField extends StatefulWidget {
  /// A password field.
  const ClayPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofillHints = const [AutofillHints.password],
    this.style,
  });

  /// The words, when the caller reads or sets them; null: the field keeps
  /// its own.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The words above the well.
  final String? labelText;

  /// What the empty field says.
  final String? hintText;

  /// Help under the well.
  final String? helperText;

  /// What is wrong, under the well.
  final String? errorText;

  /// Each change of the password.
  final ValueChanged<String>? onChanged;

  /// Enter.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes words.
  final bool enabled;

  /// What autofill may offer: a password by default; give
  /// [AutofillHints.newPassword] where one is made.
  final Iterable<String> autofillHints;

  /// This field's own style, over [ClayThemeData.textFieldStyle].
  final ClayStyle? style;

  @override
  State<ClayPasswordField> createState() => _ClayPasswordFieldState();
}

class _ClayPasswordFieldState extends State<ClayPasswordField>
    with _OwnsEntry<ClayPasswordField> {
  @override
  TextEditingController? get givenController => widget.controller;
  @override
  FocusNode? get givenFocusNode => widget.focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    return _labelled(
      label: widget.labelText,
      enabled: widget.enabled,
      helper: widget.helperText,
      error: widget.errorText,
      field: RawPasswordReveal(
        focusNode: focusNode,
        builder: (context, password) => ClayOnFocus(
          focusNode: focusNode,
          builder: (context, focused) {
            final states = {
              if (!widget.enabled) WidgetState.disabled,
              if (focused) WidgetState.focused,
              if (widget.errorText != null) WidgetState.error,
            };
            final layered = DesignStyleOf([
              widget.style,
              theme.textFieldStyle,
            ], states);
            return ClayEntryWell(
              focusNode: focusNode,
              enabled: widget.enabled,
              face: clayEntryFace(
                theme,
                states,
                fill: layered.fill,
                edge: layered.edge,
              ),
              trailing: ClayIconButton.plain(
                onPressed: widget.enabled ? password.toggle : null,
                tooltip: password.toggleLabel,
                isSelected: !password.obscured,
                style: _wellKey,
                icon: Icon(
                  password.obscured ? LucideIcons.eye : LucideIcons.eyeOff,
                ),
              ),
              child: ClayEntryText(
                controller: controller,
                focusNode: focusNode,
                hintText: widget.hintText,
                obscureText: password.obscured,
                enabled: widget.enabled,
                autofillHints: widget.autofillHints,
                keyboardType: TextInputType.visiblePassword,
                semanticLabel: widget.labelText,
                // The reveal key stands beside it: the input is the field's
                // node, which the decorator names.
                mergeSemantics: false,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                textStyle: layered.textStyle,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A field with its add-ons, one control: a unit or a prefix behind a
/// groove at the well's ends (ml, min), or a glyph, a key.
///
/// ```dart
/// ClayInputGroup(labelText: 'Goal', suffixText: 'glasses', keyboardType: TextInputType.number)
/// ```
class ClayInputGroup extends StatefulWidget {
  /// A field with add-ons.
  const ClayInputGroup({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixText,
    this.suffixText,
    this.leading,
    this.trailing,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.style,
  });

  /// The words, when the caller reads or sets them; null: the field keeps
  /// its own.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The words above the well.
  final String? labelText;

  /// What the empty field says.
  final String? hintText;

  /// Help under the well.
  final String? helperText;

  /// What is wrong, under the well.
  final String? errorText;

  /// Words at the well's start, behind a groove (https://).
  final String? prefixText;

  /// Words at the well's end, behind a groove (ml, minutes).
  final String? suffixText;

  /// A glyph at the start, inside the well.
  final Widget? leading;

  /// A key at the end, inside the well.
  final Widget? trailing;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// What the words may be.
  final List<TextInputFormatter>? inputFormatters;

  /// Each change.
  final ValueChanged<String>? onChanged;

  /// Enter.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes words.
  final bool enabled;

  /// This group's own style, over [ClayThemeData.inputGroupStyle].
  final ClayStyle? style;

  @override
  State<ClayInputGroup> createState() => _ClayInputGroupState();
}

class _ClayInputGroupState extends State<ClayInputGroup>
    with _OwnsEntry<ClayInputGroup> {
  @override
  TextEditingController? get givenController => widget.controller;
  @override
  FocusNode? get givenFocusNode => widget.focusNode;

  // The add-ons' words, as they print.
  TextStyle _addOnStyle(ClayThemeData theme) => theme.textTheme.body.copyWith(
    color: widget.enabled
        ? theme.colors.inkSecondary
        : theme.colors.inkDisabled,
  );

  // The add-ons keep their words whole: they take their own width and the
  // entry keeps at least a third of the well; where large text leaves them
  // too little, their words print smaller to fit, never cut.
  TextScaler _addOnScaler(
    BuildContext context,
    ClayThemeData theme,
    double width,
  ) {
    final style = _addOnStyle(theme);
    final texts = [?widget.prefixText, ?widget.suffixText];
    var words = 0.0;
    for (final text in texts) {
      words += clayWidestWord(context, [text], style, whole: true);
    }
    return clayScalerToFit(
      MediaQuery.textScalerOf(context),
      fontSize: style.fontSize ?? 16,
      widest: words,
      room: width * 2 / 3 - texts.length * (2 * ClaySpacing.medium + 2),
    );
  }

  Widget _addOn(
    ClayThemeData theme,
    String words, {
    required bool start,
    required double maxWidth,
    required TextScaler scaler,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!start) const ClayWellSeam(),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ClaySpacing.medium,
              ),
              child: DesignCapCenter(
                capHeightFactor: clayCapHeightFactor,
                child: Text(
                  words,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  textScaler: scaler,
                  style: _addOnStyle(theme),
                ),
              ),
            ),
          ),
          if (start) const ClayWellSeam(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    return _labelled(
      label: widget.labelText,
      enabled: widget.enabled,
      helper: widget.helperText,
      error: widget.errorText,
      field: DesignInputGroup(
        focusNode: focusNode,
        enabled: widget.enabled,
        isError: widget.errorText != null,
        builder: (context, states, child) {
          final layered = DesignStyleOf([
            widget.style,
            theme.inputGroupStyle,
          ], states);
          return SizedBox(
            height: theme.controlHeight,
            child: AnimatedClaySurface(
              face: clayEntryFace(
                theme,
                states,
                fill: layered.fill,
                edge: layered.edge,
                radius: clayRadiusOf(layered.shape, ClayRadius.control),
              ),
              child: child,
            ),
          );
        },
        child: LayoutBuilder(
          builder: (context, box) {
            final scaler = _addOnScaler(context, theme, box.maxWidth);
            return Row(
              children: [
                if (widget.prefixText != null)
                  _addOn(
                    theme,
                    widget.prefixText!,
                    start: true,
                    maxWidth: box.maxWidth * 2 / 3,
                    scaler: scaler,
                  ),
                if (widget.leading != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: ClaySpacing.regular,
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(
                        size: 20,
                        color: widget.enabled
                            ? theme.colors.inkSecondary
                            : theme.colors.inkDisabled,
                      ),
                      child: widget.leading!,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: widget.prefixText != null || widget.leading != null
                          ? ClaySpacing.medium
                          : ClaySpacing.regular,
                      end: widget.suffixText != null || widget.trailing != null
                          ? ClaySpacing.medium
                          : ClaySpacing.regular,
                    ),
                    child: ClayEntryText(
                      controller: controller,
                      focusNode: focusNode,
                      hintText: widget.hintText,
                      enabled: widget.enabled,
                      keyboardType: widget.keyboardType,
                      inputFormatters: widget.inputFormatters,
                      semanticLabel: widget.labelText,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                    ),
                  ),
                ),
                if (widget.trailing != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: ClaySpacing.tight,
                    ),
                    child: widget.trailing,
                  ),
                if (widget.suffixText != null)
                  _addOn(
                    theme,
                    widget.suffixText!,
                    start: false,
                    maxWidth: box.maxWidth * 2 / 3,
                    scaler: scaler,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A one-time code: a cup pressed into the clay for each character, the
/// next one rimmed. Paste fills them all.
///
/// ```dart
/// ClayOtpField(length: 6, onCompleted: (code) {})
/// ```
class ClayOtpField extends StatelessWidget {
  /// A code of [length] characters.
  const ClayOtpField({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.isError = false,
    this.obscureText = false,
    this.autofocus = false,
    this.semanticLabel,
    this.style,
  });

  /// How many characters.
  final int length;

  /// The code, for a caller that reads or sets it.
  final RawOtpController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Each change of the code.
  final ValueChanged<String>? onChanged;

  /// The whole code, once every cup is filled.
  final ValueChanged<String>? onCompleted;

  /// Whether it takes input.
  final bool enabled;

  /// Whether the code was wrong: every cup rimmed in the danger colour.
  final bool isError;

  /// Whether the characters are hidden.
  final bool obscureText;

  /// Whether it takes the focus when it first shows.
  final bool autofocus;

  /// What a screen reader calls it; null: "One-time code".
  final String? semanticLabel;

  /// This field's own style, over [ClayThemeData.otpFieldStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    // The cups start under the label, as every field's words do.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      child: RawOtpField(
        length: length,
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onCompleted: onCompleted,
        enabled: enabled,
        isError: isError,
        obscureText: obscureText,
        autofocus: autofocus,
        textDirection: TextDirection.ltr,
        semanticLabel: semanticLabel ?? 'One-time code',
        layoutBuilder: (context, slots) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, slot) in slots.indexed) ...[
              if (i > 0)
                SizedBox(
                  width: length == 6 && i == 3
                      ? ClaySpacing.large
                      : ClaySpacing.small,
                ),
              slot,
            ],
          ],
        ),
        slotBuilder: (context, slot) {
          final states = {
            if (!slot.enabled) WidgetState.disabled,
            if (slot.focused && slot.active) WidgetState.focused,
            if (slot.isError) WidgetState.error,
          };
          final layered = DesignStyleOf([style, theme.otpFieldStyle], states);
          return SizedBox(
            width: 44,
            height: theme.controlHeight + 8,
            child: AnimatedClaySurface(
              face: clayEntryFace(
                theme,
                states,
                fill: layered.fill,
                edge: layered.edge,
                radius: clayRadiusOf(layered.shape, ClayRadius.control - 2),
              ),
              child: Center(
                child: Text(
                  slot.obscured && slot.character.isNotEmpty
                      ? '•'
                      : slot.character,
                  style: theme.textTheme.title
                      .copyWith(
                        color: slot.enabled ? c.ink : c.inkDisabled,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )
                      .merge(layered.textStyle),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('length', length))
      ..add(FlagProperty('isError', value: isError, ifTrue: 'error'));
  }
}

/// A number between two clay keys: − and + stand raised either side of the
/// well it is typed in. Up and Down step it from the keyboard; a key held
/// repeats.
///
/// ```dart
/// ClayNumberField(value: 8, min: 1, max: 20, onChanged: (value) {}, semanticLabel: 'Glasses a day')
/// ```
class ClayNumberField extends StatelessWidget {
  /// A number field at [value].
  const ClayNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.fractionDigits = 0,
    this.width = 96,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.style,
  });

  /// The number; null for none yet.
  final double? value;

  /// The new number; null turns the field off.
  final ValueChanged<double?>? onChanged;

  /// The least it may be.
  final double? min;

  /// The most it may be.
  final double? max;

  /// How far a key or an arrow moves it.
  final double step;

  /// The places after the point it keeps.
  final int fractionDigits;

  /// The well's width between the keys.
  final double width;

  /// The words, when the caller reads or sets them.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Whether it takes the focus when it first shows.
  final bool autofocus;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// This field's own style, over [ClayThemeData.numberFieldStyle]: `fill`
  /// the well, `foreground` the keys' glyphs.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    final side = theme.controlHeight;
    return RawNumberField(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      step: step,
      fractionDigits: fractionDigits,
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      fieldBuilder: (context, field) {
        final layered = DesignStyleOf([
          style,
          theme.numberFieldStyle,
        ], field.states);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClaySpacing.small),
          child: MouseRegion(
            cursor: enabled
                ? SystemMouseCursors.text
                : SystemMouseCursors.basic,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: enabled ? field.focusNode.requestFocus : null,
              child: SizedBox(
                width: width,
                height: side,
                child: AnimatedClaySurface(
                  face: clayEntryFace(
                    theme,
                    field.states,
                    fill: layered.fill,
                    edge: layered.edge,
                    radius: clayRadiusOf(layered.shape, ClayRadius.control),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClaySpacing.small,
                    ),
                    // The field's node takes its value from here.
                    child: ListenableBuilder(
                      listenable: field.controller,
                      builder: (context, child) =>
                          Semantics(value: field.controller.text, child: child),
                      child: ClayEntryText(
                        controller: field.controller,
                        focusNode: field.focusNode,
                        enabled: enabled,
                        keyboardType: field.keyboardType,
                        inputFormatters: field.inputFormatters,
                        onEditingComplete: field.onEditingComplete,
                        textAlign: TextAlign.center,
                        minHeight: side,
                        textStyle: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()],
                        ).merge(layered.textStyle),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      buttonBuilder: (context, button) {
        final layered = DesignStyleOf([
          style,
          theme.numberFieldStyle,
        ], button.states);
        final off = button.states.contains(WidgetState.disabled);
        final pressed = button.states.contains(WidgetState.pressed);
        final hovered = button.states.contains(WidgetState.hovered);
        final ball = side - 8;
        return SizedBox.square(
          dimension: side,
          child: Center(
            child: SizedBox.square(
              dimension: ball,
              child: AnimatedClaySurface(
                face: off
                    ? ClayFace.flat(c, radius: ball / 2)
                    : ClayFace.raised(c, radius: ball / 2).copyWith(
                        press: pressed ? 1 : 0,
                        lift: hovered && !pressed ? 1 : 0,
                      ),
                child: ClayPressDepth(
                  pressed: pressed,
                  builder: (depth) => Transform.translate(
                    offset: Offset(0, depth),
                    child: Icon(
                      button.isIncrement ? LucideIcons.plus : LucideIcons.minus,
                      size: layered.iconSize ?? 20,
                      color: off
                          ? c.inkDisabled
                          : (layered.foreground ?? c.ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(DoubleProperty('min', min, defaultValue: null))
      ..add(DoubleProperty('max', max, defaultValue: null));
  }
}

/// The panel a field's options float in: the menu's clay, as wide as the
/// field.
Widget _optionPanel(BuildContext context, Widget list) {
  final c = ClayTheme.of(context).colors;
  return ClaySurface(
    face: clayMenuFace(c),
    child: Padding(padding: const EdgeInsets.all(clayMenuInset), child: list),
  );
}

Widget _nothing(BuildContext context) {
  final theme = ClayTheme.of(context);
  return Padding(
    padding: const EdgeInsets.all(ClaySpacing.medium),
    child: Text(
      RawWidgetsLocalizations.of(context).noResultsLabel,
      style: theme.textTheme.secondary,
    ),
  );
}

// A search on its way: a small spinner and its word.
Widget _searching(BuildContext context) {
  final theme = ClayTheme.of(context);
  return Padding(
    padding: const EdgeInsets.all(ClaySpacing.medium),
    child: Row(
      children: [
        const ExcludeSemantics(child: ClaySpinner(size: 16)),
        const SizedBox(width: ClaySpacing.small),
        Flexible(
          child: Text(
            RawWidgetsLocalizations.of(context).loadingLabel,
            style: theme.textTheme.secondary,
          ),
        ),
      ],
    ),
  );
}

// A search that failed: what happened, and Try again as an option row, lit
// while the keys are on it (the focus stays in the field).
Widget _failed(BuildContext context, RawSearchError error) {
  final theme = ClayTheme.of(context);
  final words = RawWidgetsLocalizations.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          ClaySpacing.medium,
          ClaySpacing.medium,
          ClaySpacing.medium,
          ClaySpacing.small,
        ),
        child: Text(
          words.searchFailedMessage,
          style: theme.textTheme.secondary,
        ),
      ),
      Semantics(
        button: true,
        label: words.retryButtonLabel,
        onTap: error.retry,
        excludeSemantics: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: error.retry,
            child: ClayMenuRow(
              label: words.retryButtonLabel,
              states: {if (error.focused) WidgetState.focused},
            ),
          ),
        ),
      ),
    ],
  );
}

/// A field that suggests as you type: the text field's well with the
/// options in a clay panel under it, as wide as the field. The pointer's
/// row and the keys' row are one row; Enter takes the lit option and keeps
/// the focus in the field.
///
/// ```dart
/// ClayCombobox<String>(labelText: 'Category', options: const ['Health', 'Mind', 'Home'], onSelected: (category) {})
/// ```
class ClayCombobox<T extends Object> extends StatelessWidget {
  /// A combobox over [options].
  const ClayCombobox({
    super.key,
    this.options = const [],
    this.search,
    this.value,
    this.onSelected,
    this.displayStringForOption,
    this.isOptionEnabled,
    this.requireSelection = false,
    this.debounceDuration,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.semanticLabel,
    this.style,
  });

  /// The options, filtered by the words typed.
  final Iterable<T> options;

  /// Finds the options for a query itself (a server's search), instead of
  /// filtering [options].
  final DesignOptionSearch<T>? search;

  /// The option taken.
  final T? value;

  /// An option taken.
  final ValueChanged<T>? onSelected;

  /// An option's words; null: its `toString`.
  final String Function(T option)? displayStringForOption;

  /// Whether an option can be taken; null: all can.
  final bool Function(T option)? isOptionEnabled;

  /// Whether the field must hold an option's words when it loses the focus.
  final bool requireSelection;

  /// How long the typing rests before [search] runs; null runs it at once.
  final Duration? debounceDuration;

  /// The words, when the caller reads or sets them.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The words above the well.
  final String? labelText;

  /// What the empty field says.
  final String? hintText;

  /// Help under the well.
  final String? helperText;

  /// What is wrong, under the well.
  final String? errorText;

  /// Whether it takes words.
  final bool enabled;

  /// What a screen reader calls it; null: [labelText].
  final String? semanticLabel;

  /// This field's own style, over [ClayThemeData.comboboxStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final words = displayStringForOption ?? _words;
    ClayKeysShown.watch();
    return _labelled(
      label: labelText,
      enabled: enabled,
      helper: helperText,
      error: errorText,
      field: RawCombobox<T>(
        options: options,
        search: search,
        value: value,
        onSelected: onSelected,
        displayStringForOption: words,
        isOptionEnabled: isOptionEnabled,
        requireSelection: requireSelection,
        controller: controller,
        focusNode: focusNode,
        // The pointer lights the row it is over; the keys' ring shows
        // after a key (ClayKeysShown), so a list a press opened marks its
        // chosen option alone, as a select's does.
        highlightFollowsPointer: false,
        semanticLabel: semanticLabel ?? labelText,
        fieldBuilder: (context, field) => ClayOnFocus(
          focusNode: field.focusNode,
          builder: (context, focused) {
            final states = {
              if (!enabled) WidgetState.disabled,
              if (focused) WidgetState.focused,
              if (errorText != null) WidgetState.error,
            };
            final layered = DesignStyleOf([style, theme.comboboxStyle], states);
            return ClayEntryWell(
              focusNode: field.focusNode,
              enabled: enabled,
              face: clayEntryFace(
                theme,
                states,
                fill: layered.fill,
                edge: layered.edge,
              ),
              // The chevron turns as the list opens, as the select's does.
              trailing: Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: ClaySpacing.medium,
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: field.isOpen ? 1 : 0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) => SizedBox.square(
                    dimension: 20,
                    child: CustomPaint(
                      painter: ClayChevronPainter(
                        enabled ? c.inkSecondary : c.inkDisabled,
                        t,
                      ),
                    ),
                  ),
                ),
              ),
              // Enter takes the lit option and keeps the focus here. The
              // input says whether its list is open.
              child: Semantics(
                expanded: field.isOpen,
                child: ClayEntryText(
                  controller: field.controller,
                  focusNode: field.focusNode,
                  hintText: hintText,
                  enabled: enabled,
                  semanticLabel: semanticLabel ?? labelText,
                  onEditingComplete: field.submit,
                  textStyle: layered.textStyle,
                ),
              ),
            );
          },
        ),
        optionBuilder: (context, option, states) => ClayMenuRow(
          label: words(option),
          states: ClayKeysShown.option(states),
          chosen: states.contains(WidgetState.selected),
        ),
        surfaceBuilder: _optionPanel,
        emptyBuilder: _nothing,
        debounceDuration: debounceDuration,
        loadingBuilder: _searching,
        errorBuilder: _failed,
      ),
    );
  }
}

/// The slot a tag or the tag input's line stands in: a finger's height, so
/// the key that removes a tag and the line itself each take a whole tap.
const double _tagSlot = 44;

/// A tag's pill: a control's height less the room round it in the well.
double _tagHeight(ClayThemeData theme) => theme.controlHeight - 14;

/// How far a tag stands in from the well's rim: the same at its start as
/// above and below it, so the pill sits evenly in the well's corner.
double _tagInset(ClayThemeData theme) =>
    (math.max(theme.controlHeight, _tagSlot) - _tagHeight(theme)) / 2;

/// Values held as small clay pills raised out of a well, with a line after
/// them that suggests and makes more. Enter, or a comma, makes the typed
/// words a tag and keeps the focus for the next.
///
/// ```dart
/// ClayTagInput<String>(labelText: 'Tags', values: const ['Morning'], onChanged: (values) {}, onCreate: (text) => text)
/// ```
class ClayTagInput<T extends Object> extends StatelessWidget {
  /// A tag input over [values].
  const ClayTagInput({
    super.key,
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.search,
    this.onCreate,
    this.displayStringForOption,
    this.isOptionEnabled,
    this.maxTags,
    this.debounceDuration,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.semanticLabel,
    this.style,
  });

  /// The tags.
  final List<T> values;

  /// The new tags; a disabled input ignores it.
  final ValueChanged<List<T>> onChanged;

  /// Suggestions, filtered by the words typed.
  final Iterable<T> options;

  /// Finds the suggestions for a query itself.
  final DesignOptionSearch<T>? search;

  /// Makes a tag of typed words; null: only suggestions become tags.
  final T? Function(String text)? onCreate;

  /// A value's words; null: its `toString`.
  final String Function(T value)? displayStringForOption;

  /// Whether a suggestion can be taken; null: all can.
  final bool Function(T option)? isOptionEnabled;

  /// The most tags it holds.
  final int? maxTags;

  /// How long the typing rests before [search] runs; null runs it at once.
  final Duration? debounceDuration;

  /// The words, when the caller reads or sets them.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The words above the well.
  final String? labelText;

  /// What the empty field says.
  final String? hintText;

  /// Help under the well.
  final String? helperText;

  /// What is wrong, under the well.
  final String? errorText;

  /// Whether it takes words.
  final bool enabled;

  /// What a screen reader calls it; null: [labelText].
  final String? semanticLabel;

  /// This input's own style, over [ClayThemeData.tagInputStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final words = displayStringForOption ?? _words;
    ClayKeysShown.watch();
    final input = RawTagInput<T>(
      values: values,
      onChanged: enabled ? onChanged : (_) {},
      options: options,
      search: search,
      onCreate: onCreate,
      displayStringForOption: words,
      isOptionEnabled: isOptionEnabled,
      maxTags: maxTags,
      controller: controller,
      focusNode: focusNode,
      // As the combobox: the pointer lights its row, the keys' ring
      // shows after a key.
      highlightFollowsPointer: false,
      semanticLabel: semanticLabel ?? labelText,
      // The typing line: its whole slot takes a tap, and alone in the well
      // its words stand where every field's do. Beside tags it is a short
      // line after the last, so the tags and the line share a row.
      fieldBuilder: (context, field) => ConstrainedBox(
        constraints: values.isEmpty
            ? const BoxConstraints(minWidth: 96)
            : const BoxConstraints(minWidth: 96, maxWidth: 168),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: enabled ? field.focusNode.requestFocus : null,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: values.isEmpty
                  ? ClaySpacing.regular - _tagInset(theme)
                  : ClaySpacing.small,
            ),
            child: SizedBox(
              height: _tagSlot,
              // Enter makes a tag and keeps the focus for the next one.
              // The input says whether its list is open. Its node is the one
              // ui_core gives the field's label, help and error, beside the
              // tags' own: it merges into that one rather than its own.
              child: Semantics(
                expanded: field.isOpen,
                child: ClayEntryText(
                  controller: field.controller,
                  focusNode: field.focusNode,
                  hintText: values.isEmpty ? hintText : null,
                  enabled: enabled,
                  semanticLabel: semanticLabel,
                  mergeSemantics: false,
                  minHeight: _tagSlot,
                  onEditingComplete: field.submit,
                ),
              ),
            ),
          ),
        ),
      ),
      optionBuilder: (context, option, states) => ClayMenuRow(
        label: words(option),
        states: ClayKeysShown.option(states),
      ),
      tagBuilder: (context, value, tag) =>
          _Tag(label: words(value), tag: tag, enabled: enabled),
      surfaceBuilder: _optionPanel,
      debounceDuration: debounceDuration,
      loadingBuilder: _searching,
      errorBuilder: _failed,
      layoutBuilder: (context, tags, field) => _TagWell(
        enabled: enabled,
        error: errorText != null,
        style: style,
        tags: tags,
        field: field,
      ),
    );
    return _labelled(
      label: labelText,
      enabled: enabled,
      helper: helperText,
      error: errorText,
      field: DefaultTextStyle.merge(
        style: TextStyle(color: c.ink),
        child: input,
      ),
    );
  }
}

class _TagWell extends StatefulWidget {
  const _TagWell({
    required this.enabled,
    required this.error,
    required this.style,
    required this.tags,
    required this.field,
  });

  final bool enabled;
  final bool error;
  final ClayStyle? style;
  final List<Widget> tags;
  final Widget field;

  @override
  State<_TagWell> createState() => _TagWellState();
}

class _TagWellState extends State<_TagWell> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final states = {
      if (!widget.enabled) WidgetState.disabled,
      if (_focused) WidgetState.focused,
      if (widget.error) WidgetState.error,
    };
    final layered = DesignStyleOf([widget.style, theme.tagInputStyle], states);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.text
            : SystemMouseCursors.basic,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: theme.controlHeight),
          child: AnimatedClaySurface(
            face: clayEntryFace(
              theme,
              states,
              fill: layered.fill,
              edge: layered.edge,
            ),
            // Each tag and the line stand in a slot a finger's height; the
            // well round them is a control's height for one row.
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _tagInset(theme),
                vertical: math.max(0, (theme.controlHeight - _tagSlot) / 2),
              ),
              child: Wrap(
                spacing: ClaySpacing.tight,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [...widget.tags, widget.field],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tag: a small clay pill raised out of the well, its words and a key
/// that removes it.
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.tag, required this.enabled});

  final String label;
  final RawTagDetails tag;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final words = RawWidgetsLocalizations.of(context);
    final height = _tagHeight(theme);
    // The pill stands in a slot a finger's height; the key that removes it
    // is the slot's whole square at the pill's end.
    return SizedBox(
      height: _tagSlot,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          SizedBox(
            height: height,
            child: AnimatedClaySurface(
              face: enabled
                  ? ClayFace.raised(
                      c,
                      color: c.risen,
                      radius: height / 2,
                    ).copyWith(
                      elevation: 0.6,
                      focus: tag.focused ? 1 : 0,
                      focusColor: c.focus,
                    )
                  : ClayFace.flat(c, radius: height / 2),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: ClaySpacing.medium,
                  end: _tagSlot - ClaySpacing.small,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: 1,
                  child: DesignCapCenter(
                    capHeightFactor: clayCapHeightFactor,
                    child: Text(
                      label,
                      style: theme.textTheme.secondary.copyWith(
                        color: enabled ? c.ink : c.inkDisabled,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: 0,
            top: 0,
            bottom: 0,
            width: _tagSlot,
            child: RawButton(
              onPressed: enabled ? tag.onDeleted : null,
              semanticLabel: '${words.tagInputDeleteLabel} $label',
              builder: (context, states, _) {
                final lit =
                    states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused) ||
                    states.contains(WidgetState.pressed);
                return Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: AnimatedClaySurface(
                      face: ClayFace.well(c, radius: 12).copyWith(
                        color: lit ? null : c.well.withValues(alpha: 0),
                        shadeOpacity: lit ? null : 0,
                        lightOpacity: lit ? null : 0,
                        focus: states.contains(WidgetState.focused) ? 1 : 0,
                        focusColor: c.focus,
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.x,
                          size: 14,
                          color: enabled ? c.inkSecondary : c.inkDisabled,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A form: [ClayFormField]s inside it are checked together, and a failed
/// submit moves the focus to the first one that is wrong.
typedef ClayForm = DesignForm;

/// Any control with its label, help and error, as one field: the label
/// above it names it to a screen reader, the error under it is announced
/// as it appears. A group of controls (a segmented choice, a number's
/// keys, chips) keeps each control's own node and tap, and the label names
/// the group ([mergeSemantics]).
///
/// ```dart
/// ClayFormField(labelText: 'Reminders', helperText: 'A nudge at its time', child: ClaySwitch(value: true, onChanged: (_) {}))
/// ```
class ClayFormField extends StatelessWidget {
  /// A field around [child].
  const ClayFormField({
    super.key,
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.enabled = true,
    this.focusNode,
    this.mergeSemantics,
    this.style,
  });

  /// The control.
  final Widget child;

  /// The words above it.
  final String? labelText;

  /// Help under it.
  final String? helperText;

  /// What is wrong, under it.
  final String? errorText;

  /// Whether it must be filled: a coral mark after the label.
  final bool isRequired;

  /// Whether it takes input.
  final bool enabled;

  /// The control's focus, which a tap on the label asks for.
  final FocusNode? focusNode;

  /// Whether the control is one node that takes the label as its name
  /// (true) or a group the label names (false); null: ui_core reads what
  /// the child brings.
  final bool? mergeSemantics;

  /// Its own style, over [ClayThemeData.formFieldStyle]: `foreground` the
  /// label, `textStyle` its words.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf(
      [style, theme.formFieldStyle],
      {if (!enabled) WidgetState.disabled},
    );
    final labelStyle = theme.textTheme.label
        .copyWith(fontSize: 14, height: 20 / 14)
        .merge(layered.textStyle)
        .copyWith(color: enabled ? layered.foreground ?? c.ink : c.inkDisabled);
    return RawInputDecorator(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      required: isRequired,
      enabled: enabled,
      focusNode: focusNode,
      mergeSemantics: mergeSemantics,
      builder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parts.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: ClaySpacing.small),
              child: DefaultTextStyle.merge(
                style: labelStyle,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: parts.label!),
                    if (isRequired)
                      Text(
                        ' *',
                        style: labelStyle.copyWith(color: c.accentInk),
                      ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: parts.control,
          ),
          if (parts.error != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                top: ClaySpacing.small,
                start: ClaySpacing.tight,
              ),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.secondary.copyWith(color: c.dangerInk),
                child: parts.error!,
              ),
            )
          else if (parts.helper != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                top: ClaySpacing.small,
                start: ClaySpacing.tight,
              ),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.secondary,
                child: parts.helper!,
              ),
            ),
        ],
      ),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('isRequired', value: isRequired, ifTrue: 'required'));
  }
}
