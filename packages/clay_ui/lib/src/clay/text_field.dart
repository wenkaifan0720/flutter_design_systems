/// Clay's text field: a well pressed into the ground, the words on its floor,
/// the label above it and help or an error under it.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'surface.dart';
import 'theme.dart';

/// A field's label: [text] in the label face, 8 px above its field, its
/// words over the field's own ([ClayMetrics.fieldInset] in). Over parts
/// that start at their own edge (a row of swatches, chips, a slider), set
/// [inset] false and it starts there too.
///
/// ```dart
/// const ClayFieldLabel('Habit name')
/// ```
class ClayFieldLabel extends StatelessWidget {
  /// The label [text].
  const ClayFieldLabel(
    this.text, {
    super.key,
    this.enabled = true,
    this.inset = true,
    this.style,
  });

  /// The words.
  final String text;

  /// Whether its words start where a field's do; false starts them at the
  /// edge.
  final bool inset;

  /// Whether its field is on; off greys the words.
  final bool enabled;

  /// Its own style, over [ClayThemeData.fieldLabelStyle]: `foreground` the
  /// words, `textStyle` their face.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final layered = DesignStyleOf(
      [style, theme.fieldLabelStyle],
      {if (!enabled) WidgetState.disabled},
    );
    final side = inset ? ClayMetrics.fieldInset : 0.0;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: side,
        end: side,
        bottom: ClaySpacing.small,
      ),
      child: Text(
        text,
        style: theme.textTheme.label
            .copyWith(fontSize: 14, height: 20 / 14)
            .merge(layered.textStyle)
            .copyWith(
              color: enabled
                  ? layered.foreground ?? theme.colors.ink
                  : theme.colors.inkDisabled,
            ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('text', text))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('inset', value: inset, ifFalse: 'at the edge'));
  }
}

/// What stands under a field: its [error] in the danger ink (said as it
/// appears), or else its [helper], its words under the field's own
/// ([ClayMetrics.fieldInset] in); [inset] false starts them at the edge,
/// under parts that start there.
///
/// ```dart
/// const ClayFieldMessage(helper: 'Shown on Today')
/// ```
class ClayFieldMessage extends StatelessWidget {
  /// The [helper] or the [error] under a field.
  const ClayFieldMessage({
    super.key,
    this.helper,
    this.error,
    this.inset = true,
    this.style,
  });

  /// Whether its words start where a field's do; false starts them at the
  /// edge.
  final bool inset;

  /// Help under the field.
  final String? helper;

  /// What is wrong; it replaces [helper].
  final String? error;

  /// Its own style, over [ClayThemeData.fieldMessageStyle]: `foreground`
  /// the help (an error keeps the danger ink), `textStyle` the words' face.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf(
      [this.style, theme.fieldMessageStyle],
      {if (error != null) WidgetState.error},
    );
    final style = theme.textTheme.secondary.merge(layered.textStyle);
    final side = inset ? ClayMetrics.fieldInset : 0.0;
    if (error != null) {
      return Padding(
        padding: EdgeInsetsDirectional.only(
          top: ClaySpacing.small,
          start: side,
          end: side,
        ),
        child: Semantics(
          liveRegion: true,
          child: Text(error!, style: style.copyWith(color: c.dangerInk)),
        ),
      );
    }
    if (helper != null) {
      return Padding(
        padding: EdgeInsetsDirectional.only(
          top: ClaySpacing.small,
          start: side,
          end: side,
        ),
        child: Text(
          helper!,
          style: layered.foreground == null
              ? style
              : style.copyWith(color: layered.foreground),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(FlagProperty('inset', value: inset, ifFalse: 'at the edge'));
  }
}

/// A Clay text field: a well pressed into the ground, rounded 16, the words
/// on its floor. Focus brings a 2 px rim of the focus colour up inside the
/// well's edge; an [error] rims it in the danger colour and says itself
/// under it.
///
/// The caller owns a [controller] or [focusNode] it passes; without one the
/// field makes its own and disposes it.
///
/// ```dart
/// ClayTextField(label: 'Habit name', hint: 'Drink water', onChanged: (value) {})
/// ```
class ClayTextField extends StatefulWidget {
  /// A field, [label] above it.
  const ClayTextField({
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
    this.maxLength,
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

  /// What is wrong with the words, under the field in the danger ink.
  final String? error;

  /// A glyph at the field's start (a search's lens).
  final Widget? prefixIcon;

  /// Something at the field's end, a unit most often: it ends
  /// [ClayMetrics.fieldInset] in, where the field's words would.
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

  /// The most characters it takes; its count stands under it, on free text
  /// only (a number field takes its limit without a count).
  final int? maxLength;

  /// What a screen reader calls the field, when not its [label].
  final String? semanticLabel;

  /// This field's own style, over [ClayThemeData.textFieldStyle].
  final ClayStyle? style;

  @override
  State<ClayTextField> createState() => _ClayTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('obscureText', value: obscureText, ifTrue: 'obscured'))
      ..add(IntProperty('maxLines', maxLines, defaultValue: 1))
      ..add(IntProperty('maxLength', maxLength, defaultValue: null));
  }
}

class _ClayTextFieldState extends State<ClayTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  bool _hovered = false;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
    if (widget.maxLength != null) _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(ClayTextField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_changed);
      if (widget.focusNode != null) {
        _ownFocus?.dispose();
        _ownFocus = null;
      }
      _focus.addListener(_changed);
    }
    if (old.controller != widget.controller) {
      (old.controller ?? _ownController)?.removeListener(_changed);
      if (widget.controller != null) {
        _ownController?.dispose();
        _ownController = null;
      }
      if (widget.maxLength != null) _controller.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _controller.removeListener(_changed);
    _ownFocus?.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final focused = _focus.hasFocus;
    final error = widget.error != null;
    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (focused) WidgetState.focused,
      if (_hovered && widget.enabled) WidgetState.hovered,
      if (error) WidgetState.error,
    };
    final layered = DesignStyleOf([widget.style, theme.textFieldStyle], states);
    final words = theme.textTheme.body
        .merge(layered.textStyle)
        .copyWith(color: widget.enabled ? c.ink : c.inkDisabled);
    final oneLine = widget.maxLines == 1;
    final radius = clayRadiusOf(layered.shape, ClayRadius.control);
    var face = ClayFace.well(c, color: layered.fill, radius: radius);
    face = face.copyWith(
      // Off, the well fills nearly level with the ground.
      shadeOpacity: widget.enabled ? null : face.shadeOpacity * 0.4,
      focusColor: error ? c.danger : (layered.edge ?? c.focus),
      focus: focused || error ? 1 : 0,
    );
    final entry = DesignTextEntryBox(
      minHeight: theme.controlHeight,
      controller: _controller,
      maxLines: widget.maxLines,
      hint: widget.hint == null
          ? null
          : Text(
              widget.hint!,
              maxLines: oneLine ? 1 : null,
              overflow: oneLine ? TextOverflow.ellipsis : null,
              style: words.copyWith(
                color: widget.enabled ? c.inkSecondary : c.inkDisabled,
              ),
            ),
      // One node, the field's own size: its name and its text together,
      // never spread onto what holds it.
      child: MergeSemantics(
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
              cursorColor: c.accentInk,
              cursorWidth: 2,
              cursorRadius: const Radius.circular(1),
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              autofillHints: widget.autofillHints,
              inputFormatters: [
                ...?widget.inputFormatters,
                if (widget.maxLength != null)
                  LengthLimitingTextInputFormatter(widget.maxLength),
              ],
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
      ),
    );
    final box = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: widget.enabled ? _focus.requestFocus : null,
        child: AnimatedClaySurface(
          face: face,
          child: Row(
            crossAxisAlignment: oneLine
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (widget.prefixIcon != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: ClaySpacing.regular,
                    top: oneLine ? 0 : ClaySpacing.medium,
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
                  padding:
                      layered.padding(Directionality.of(context)) ??
                      EdgeInsetsDirectional.only(
                        start: widget.prefixIcon != null
                            ? ClaySpacing.medium
                            : ClaySpacing.regular,
                        end: widget.suffix != null
                            ? ClaySpacing.small
                            : ClaySpacing.regular,
                      ),
                  child: oneLine
                      ? DesignCapCenter(
                          capHeightFactor: clayCapHeightFactor,
                          child: entry,
                        )
                      : entry,
                ),
              ),
              // The suffix's words end where the field's words would: its
              // inset from the edge matches theirs from the start.
              if (widget.suffix != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: ClayMetrics.fieldInset,
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
    // A count belongs to free text with a limit: under a number '1/2'
    // reads as a half, so a number field keeps its limit and shows none.
    final number = widget.keyboardType?.index == TextInputType.number.index;
    final count = widget.maxLength == null || number
        ? null
        : '${_controller.text.characters.length}/${widget.maxLength}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: ClayFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        box,
        if (count == null)
          ClayFieldMessage(helper: widget.helper, error: widget.error)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClayFieldMessage(
                  helper: widget.helper,
                  error: widget.error,
                ),
              ),
              Padding(
                // The count ends where the field's words do.
                padding: const EdgeInsetsDirectional.only(
                  top: ClaySpacing.small,
                  end: ClayMetrics.fieldInset,
                ),
                child: Text(count, style: theme.textTheme.secondary),
              ),
            ],
          ),
      ],
    );
  }
}
