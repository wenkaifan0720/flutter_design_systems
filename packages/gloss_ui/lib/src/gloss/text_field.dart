/// Gloss's text field: a well pressed into the porcelain, the words on its
/// floor, the label above it and help or an error under it.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'surface.dart';
import 'theme.dart';

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
      child: Text(
        text,
        style: theme.textTheme.label.copyWith(
          fontSize: 14,
          height: 20 / 14,
          color: enabled ? theme.colors.ink : theme.colors.inkDisabled,
        ),
      ),
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

/// What stands under a field: its [error] in ruby (said as it appears), or
/// else its [helper].
///
/// ```dart
/// const GlossFieldMessage(helper: 'As it shows on the recipe')
/// ```
class GlossFieldMessage extends StatelessWidget {
  /// The [helper] or the [error] under a field.
  const GlossFieldMessage({super.key, this.helper, this.error});

  /// Help under the field.
  final String? helper;

  /// What is wrong; it replaces [helper].
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final style = theme.textTheme.secondary;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: GlossSpacing.small),
        child: Semantics(
          liveRegion: true,
          child: Text(error!, style: style.copyWith(color: c.danger)),
        ),
      );
    }
    if (helper != null) {
      return Padding(
        padding: const EdgeInsets.only(top: GlossSpacing.small),
        child: Text(helper!, style: style),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null));
  }
}

/// A Gloss text field: a well pressed into the page, rounded 12, the words
/// on its floor. Focus rings it in jade, outside and concentric; an [error]
/// rims it in ruby and says itself under it.
///
/// The caller owns a [controller] or [focusNode] it passes; without one the
/// field makes its own and disposes it.
///
/// ```dart
/// GlossTextField(label: 'Name', hint: 'Your name', onChanged: (value) {})
/// ```
class GlossTextField extends StatefulWidget {
  /// A field, [label] above it.
  const GlossTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
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
  final String? label;

  /// A format or an example in the empty field; never the label.
  final String? hint;

  /// Help under the field.
  final String? helper;

  /// What is wrong with the words, under the field in ruby.
  final String? error;

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

  /// What a screen reader calls the field, when not its [label].
  final String? semanticLabel;

  /// This field's own style, over [GlossThemeData.textFieldStyle].
  final GlossStyle? style;

  @override
  State<GlossTextField> createState() => _GlossTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
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
      if (widget.error != null) WidgetState.error,
    };
    final layered = DesignStyleOf([widget.style, theme.textFieldStyle], states);
    final words = theme.textTheme.body
        .merge(layered.textStyle)
        .copyWith(color: widget.enabled ? c.ink : c.inkDisabled);
    final oneLine = widget.maxLines == 1;
    var face = GlossFace.well(c, radius: GlossMetrics.fieldRadius);
    if (layered.fill != null) face = face.glazed(layered.fill!);
    face = face.copyWith(
      foreground: words.color,
      edge: widget.error != null ? c.danger : layered.edge,
      lift: widget.enabled ? -1 : -0.45,
      focus: focused
          ? (widget.error != null ? c.danger : c.focus)
          : c.focus.withValues(alpha: 0),
    );
    final entry = DesignTextEntryBox(
      minHeight: theme.controlHeight,
      controller: _controller,
      maxLines: widget.maxLines,
      hint: widget.hint == null
          ? null
          : Text(
              widget.hint!,
              // A field of several lines wraps its hint as it wraps words.
              maxLines: widget.maxLines == 1 ? 1 : null,
              overflow: widget.maxLines == 1 ? TextOverflow.ellipsis : null,
              style: words.copyWith(color: c.inkSecondary),
            ),
      child: Semantics(
        label: widget.semanticLabel ?? widget.label,
        hint: widget.hint,
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
        child: AnimatedGlossSurface(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: GlossSpacing.regular,
                  ),
                  child: oneLine
                      ? DesignCapCenter(
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
                    style: theme.textTheme.secondary,
                    child: widget.suffix!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: GlossFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        box,
        GlossFieldMessage(helper: widget.helper, error: widget.error),
      ],
    );
  }
}
