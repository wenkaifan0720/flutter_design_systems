/// Gloss's text field: a well pressed into the porcelain, the words on its
/// floor, the label above it and help or an error under it.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/entry_parts.dart';
import 'internal/field_frame.dart';
import 'internal/glaze_state.dart';
import 'theme.dart';
import 'internal/corners.dart';

/// A field's label: [text] in the label face, 8 px above its field.
///
/// ```dart
/// const GlossFieldLabel('Servings')
/// ```
class GlossFieldLabel extends StatelessWidget {
  /// The label [text].
  const GlossFieldLabel(this.text, {super.key, this.enabled = true});

  /// The words.
  final String text;

  /// Whether its field is on; off greys the words.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: GlossSpacing.small),
      child: Text(text, style: glossFieldLabelStyle(theme, enabled: enabled)),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('text', text))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

/// What stands under a field: its [errorText] in ruby (said as it appears), or
/// else its [helperText].
///
/// ```dart
/// const GlossFieldMessage(helperText: 'As it shows on the recipe')
/// ```
class GlossFieldMessage extends StatelessWidget {
  /// The [helperText] or the [errorText] under a field.
  const GlossFieldMessage({super.key, this.helperText, this.errorText});

  /// Help under the field.
  final String? helperText;

  /// What is wrong; it replaces [helperText].
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final style = theme.textTheme.secondary;
    if (errorText != null) {
      return Padding(
        padding: const EdgeInsets.only(top: GlossSpacing.small),
        child: Semantics(
          liveRegion: true,
          child: Text(errorText!, style: style.copyWith(color: c.danger)),
        ),
      );
    }
    if (helperText != null) {
      return Padding(
        padding: const EdgeInsets.only(top: GlossSpacing.small),
        child: Text(helperText!, style: style),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null));
  }
}

/// A Gloss text field: a well pressed into the page, rounded 12, the words
/// on its floor. Focus catches the light on its inner bevel. The [errorText]
/// message appears in ruby below the well.
///
/// The caller owns a [controller] or [focusNode] it passes; without one the
/// field makes its own and disposes it.
///
/// ```dart
/// GlossTextField(labelText: 'Name', hintText: 'Your name', onChanged: (value) {})
/// ```
class GlossTextField extends StatefulWidget {
  /// A field, [labelText] above it.
  const GlossTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.semanticLabel,
    this.style,
  });

  /// The words; the field makes its own when null.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The label above the field.
  final String? labelText;

  /// A format or an example in the empty field; never the label.
  final String? hintText;

  /// Help under the field.
  final String? helperText;

  /// What is wrong with the words, under the field in ruby.
  final String? errorText;

  /// A glyph at the field's start (a search's lens).
  final Widget? prefixIcon;

  /// Something at the field's end: a unit, a key.
  final Widget? suffix;

  /// Whether the words are hidden (a password).
  final bool obscureText;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// How the words are capitalised as they are typed.
  final TextCapitalization textCapitalization;

  /// What autofill may put here.
  final Iterable<String>? autofillHints;

  /// Rules on what may be typed.
  final List<TextInputFormatter>? inputFormatters;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field takes words.
  final bool enabled;

  /// Whether the words can be read and selected but not changed.
  final bool readOnly;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// The most lines it grows to; 1 for one line, null for any.
  final int? maxLines;

  /// The fewest lines it shows.
  final int? minLines;

  /// What a screen reader calls the field, when not its [labelText].
  final String? semanticLabel;

  /// This field's own style, over [GlossThemeData.textFieldStyle].
  final GlossStyle? style;

  @override
  State<GlossTextField> createState() => _GlossTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('obscureText', value: obscureText, ifTrue: 'obscured'))
      ..add(IntProperty('maxLines', maxLines, defaultValue: 1));
  }
}

class _GlossTextFieldState extends State<GlossTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(GlossTextField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_changed);
      if (widget.focusNode != null) {
        _ownFocus?.dispose();
        _ownFocus = null;
      }
      _focus.addListener(_changed);
    }
    if (old.controller != widget.controller && widget.controller != null) {
      _ownController?.dispose();
      _ownController = null;
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _ownFocus?.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final focused = _focus.hasFocus;
    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (focused) WidgetState.focused,
      if (widget.errorText != null) WidgetState.error,
    };
    final layered = RawStyleOf([widget.style, theme.textFieldStyle], states);
    final words = theme.textTheme.body
        .merge(layered.textStyle)
        .copyWith(color: widget.enabled ? c.ink : c.inkDisabled);
    final oneLine = widget.maxLines == 1;
    // The well every Gloss field is typed in: lit jade from inside when
    // focused, rimmed in ruby while its error shows (as the search,
    // password and other fields are).
    final face = glossEntryFace(
      theme,
      states,
      fill: layered.fill,
      edge: layered.edge,
      radius: glossCorner(theme, RawCorner.small),
    );
    final entry = RawTextEntryBox(
      minHeight: theme.controlHeight,
      controller: _controller,
      maxLines: widget.maxLines,
      hint: widget.hintText == null
          ? null
          : Text(
              widget.hintText!,
              // A field of several lines wraps its hint as it wraps words.
              maxLines: widget.maxLines == 1 ? 1 : null,
              overflow: widget.maxLines == 1 ? TextOverflow.ellipsis : null,
              style: words.copyWith(color: c.inkSecondary),
            ),
      child: Semantics(
        label: widget.semanticLabel ?? widget.labelText,
        hint: widget.hintText,
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            decoration: null,
            style: words,
            cursorColor: c.jadeInk,
            cursorWidth: 2,
            cursorRadius: const Radius.circular(1),
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            autofillHints: widget.autofillHints,
            inputFormatters: widget.inputFormatters,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
          ),
        ),
      ),
    );
    final box = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: widget.enabled ? _focus.requestFocus : null,
        child: GlazePointerSurface(
          enabled: widget.enabled,
          face: face,
          child: Row(
            crossAxisAlignment: oneLine
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (widget.prefixIcon != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: GlossSpacing.medium,
                    top: oneLine ? 0 : GlossSpacing.medium,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      size: 20,
                      color: widget.enabled ? c.inkSecondary : c.inkDisabled,
                    ),
                    child: widget.prefixIcon!,
                  ),
                ),
              Expanded(
                child: Padding(
                  // After a glyph the words start as close as in the
                  // search field's well.
                  padding: EdgeInsetsDirectional.only(
                    start: widget.prefixIcon == null
                        ? GlossSpacing.regular
                        : GlossSpacing.small,
                    end: GlossSpacing.regular,
                  ),
                  child: oneLine
                      ? RawCapCenter(
                          capHeightFactor: glossCapHeightFactor,
                          child: entry,
                        )
                      : entry,
                ),
              ),
              if (widget.suffix != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: GlossSpacing.medium,
                  ),
                  child: DefaultTextStyle(
                    style: glossAffixStyle(theme, enabled: widget.enabled),
                    // Its words stand on the value's line, as the value's
                    // capitals stand mid-well.
                    child: oneLine
                        ? RawCapCenter(
                            capHeightFactor: glossCapHeightFactor,
                            child: widget.suffix!,
                          )
                        : widget.suffix!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return GlossFieldFrame(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: widget.enabled,
      child: box,
    );
  }
}

/// A [GlossTextField] in a [Form] (a [GlossForm]), as Material's
/// `TextFormField` is: its [validator] runs when the form validates (or as
/// [autovalidateMode] says) and what it returns stands under the well as the
/// field's error, its rim in ruby; [onSaved] hands the words over when the
/// form saves, and resetting the form brings [initialValue] back. Keep the
/// words in a [controller] or start them at [initialValue], not both.
///
/// ```dart
/// GlossTextFormField(labelText: 'Title', validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the title' : null, onSaved: (v) => title = v!)
/// ```
class GlossTextFormField extends FormField<String> {
  /// A text field, [labelText] above it, that takes part in its [Form].
  GlossTextFormField({
    this.controller,
    String? initialValue,
    FocusNode? focusNode,
    String? labelText,
    String? hintText,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffix,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Iterable<String>? autofillHints,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    bool autofocus = false,
    int? maxLines = 1,
    int? minLines,
    this.onChanged,
    ValueChanged<String>? onFieldSubmitted,
    GlossStyle? style,
    super.onSaved,
    super.validator,
    super.forceErrorText,
    super.enabled,
    AutovalidateMode? autovalidateMode,
    super.key,
  }) : assert(
         initialValue == null || controller == null,
         'Start the words in the controller or at initialValue, not both.',
       ),
       super(
         initialValue: controller?.text ?? initialValue ?? '',
         autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
         builder: (field) {
           final state = field as _GlossTextFormFieldState;
           return GlossTextField(
             controller: state._controller,
             focusNode: focusNode,
             labelText: labelText,
             hintText: hintText,
             helperText: helperText,
             errorText: field.errorText,
             prefixIcon: prefixIcon,
             suffix: suffix,
             obscureText: obscureText,
             keyboardType: keyboardType,
             textInputAction: textInputAction,
             textCapitalization: textCapitalization,
             autofillHints: autofillHints,
             inputFormatters: inputFormatters,
             enabled: field.widget.enabled,
             readOnly: readOnly,
             autofocus: autofocus,
             maxLines: maxLines,
             minLines: minLines,
             style: style,
             onChanged: (text) {
               field.didChange(text);
               onChanged?.call(text);
             },
             onSubmitted: onFieldSubmitted,
           );
         },
       );

  /// The words' controller, when the page keeps one; without it the field
  /// keeps its own, started at the initial value.
  final TextEditingController? controller;

  /// Called as the words change, and with the initial words when the form
  /// resets.
  final ValueChanged<String>? onChanged;

  @override
  FormFieldState<String> createState() => _GlossTextFormFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      );
  }
}

class _GlossTextFormFieldState extends FormFieldState<String> {
  TextEditingController? _own;

  GlossTextFormField get _field => widget as GlossTextFormField;

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
  void didUpdateWidget(covariant GlossTextFormField oldWidget) {
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
    // The words go back first, so the controller's listener finds nothing
    // changed.
    _controller.text = widget.initialValue ?? '';
    super.reset();
    _field.onChanged?.call(_controller.text);
  }

  // Words set on the controller by the page count as the field's value.
  void _fromController() {
    if (_controller.text != value) didChange(_controller.text);
  }
}
