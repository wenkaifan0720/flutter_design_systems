/// Studio's text entry: [StudioTextField], a recessed glass window set into
/// the metal, with its label printed above it ([StudioFieldLabel]) and its
/// help or error under it ([StudioFieldMessage]).
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/field_frame.dart';
import 'surface.dart';
import 'theme.dart';
import 'internal/message_reveal.dart';

/// A field's label, printed on the metal above it: sentence case, in the
/// legend's ink.
///
/// ```dart
/// const StudioFieldLabel('Episode title')
/// ```
class StudioFieldLabel extends StatelessWidget {
  /// The label [text].
  const StudioFieldLabel(this.text, {super.key, this.enabled = true});

  /// The words.
  final String text;

  /// Whether the field it names is on; off, its print dims.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.small),
      child: Text(
        text,
        style: theme.textTheme.label.copyWith(
          fontSize: 14,
          height: 20 / 14,
          color: enabled ? theme.colors.legend : theme.colors.disabled,
        ),
      ),
    );
  }
}

/// What a field says under it: its [helper], or its [error] beside a lit
/// danger lamp. Nothing when it has neither.
///
/// ```dart
/// const StudioFieldMessage(error: 'Give the episode a title.')
/// ```
class StudioFieldMessage extends StatelessWidget {
  /// The message under a field.
  const StudioFieldMessage({super.key, this.helper, this.error});

  /// A note on what to enter.
  final String? helper;

  /// What is wrong; it takes the helper's place.
  final String? error;

  // The line grows open and fades in (and out) as the field's words come
  // and go, so the fields under it move with it and never jump.
  @override
  Widget build(BuildContext context) =>
      StudioMessageReveal(id: error, child: _line(context));

  Widget _line(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final words = error ?? helper;
    if (words == null) return const SizedBox.shrink();
    final style = theme.textTheme.caption.copyWith(
      color: error != null ? c.dangerLegend : c.legendMuted,
    );
    return Padding(
      padding: const EdgeInsets.only(top: StudioSpacing.small),
      child: Semantics(
        container: error != null,
        liveRegion: error != null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (error != null) ...[
              Padding(
                // The lamp on the first line's capitals.
                padding: EdgeInsets.only(
                  top: (style.fontSize! * style.height! - 6) / 2,
                ),
                child: StudioLamp(on: true, color: c.danger, size: 6),
              ),
              const SizedBox(width: StudioSpacing.small),
            ],
            Expanded(child: Text(words, style: style)),
          ],
        ),
      ),
    );
  }
}

/// A text field: a recessed window of glass in the metal, its words on the
/// glass. Focused, the window's rim lights and the caret glows; with an
/// [errorText], the rim lights red and the error stands under it beside a lamp.
///
/// It takes Flutter's `TextField` words: [controller] (yours to dispose; it
/// makes and disposes its own when none is given), [onChanged],
/// [onSubmitted], [obscureText], [keyboardType]. [labelText] stands above it,
/// [hintText] in it while it is empty (a format, never the label), [helperText] or
/// [errorText] under it. [enabled] false dims it.
///
/// Reads [style]'s `fill`, `foreground`, `edge` (the lit rim), `minimumSize`
/// and `textStyle`, then [StudioThemeData.textFieldStyle].
///
/// ```dart
/// StudioTextField(labelText: 'Episode title', hintText: 'Season 2, episode 4', onChanged: (v) => title = v)
/// ```
class StudioTextField extends StatefulWidget {
  /// A field.
  const StudioTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
    this.autofillHints,
    this.maxLines = 1,
    this.minLines,
    this.semanticLabel,
    this.style,
  });

  /// The words; yours to dispose.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The label above it.
  final String? labelText;

  /// What shows in it while it is empty: a format or an example.
  final String? hintText;

  /// A note under it.
  final String? helperText;

  /// What is wrong, under it in place of the helper.
  final String? errorText;

  /// A glyph at its start (a search field's lens).
  final Widget? prefixIcon;

  /// Something at its end: a unit, a key that clears it.
  final Widget? suffix;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Called when the words are submitted.
  final ValueChanged<String>? onSubmitted;

  /// Called when editing completes.
  final VoidCallback? onEditingComplete;

  /// Whether it takes words.
  final bool enabled;

  /// Whether its words can be read and selected but not changed.
  final bool readOnly;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Whether its words are hidden (a password).
  final bool obscureText;

  /// The keyboard it asks for.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// How the keyboard capitalises.
  final TextCapitalization textCapitalization;

  /// What it lets through.
  final List<TextInputFormatter>? inputFormatters;

  /// What autofill may put in it.
  final Iterable<String>? autofillHints;

  /// Its most lines; null grows with its words.
  final int? maxLines;

  /// Its fewest lines.
  final int? minLines;

  /// What a screen reader calls it, when not its [labelText].
  final String? semanticLabel;

  /// Its style, over [StudioThemeData.textFieldStyle].
  final StudioStyle? style;

  @override
  State<StudioTextField> createState() => _StudioTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', labelText, defaultValue: null))
      ..add(StringProperty('hint', hintText, defaultValue: null))
      ..add(StringProperty('error', errorText, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(IntProperty('maxLines', maxLines, defaultValue: 1));
  }
}

class _StudioTextFieldState extends State<StudioTextField> {
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
  void didUpdateWidget(StudioTextField old) {
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
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final focused = _focus.hasFocus;
    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (focused) WidgetState.focused,
      if (widget.errorText != null) WidgetState.error,
    };
    final layered = RawStyleOf([widget.style, theme.textFieldStyle], states);
    final words = layered
        .text(theme.textTheme.body)
        .copyWith(
          color:
              layered.foreground ??
              // Disabled, the words are in the disabled ink, as its label.
              (widget.enabled ? c.onDisplay : c.disabled),
        );
    final oneLine = widget.maxLines == 1;
    final rim = widget.errorText != null
        ? c.danger
        : focused
        ? c.indicator.withValues(alpha: 0.9)
        : c.indicator.withValues(alpha: 0);
    final face = layered.on(
      c.displayFace.copyWith(
        radius: theme.radiusKey,
        rim: rim,
        foreground: words.color,
        // A disabled window is unlit glass, near the metal's tone.
        fill: widget.enabled ? null : Color.lerp(c.display, c.panelLow, 0.6),
        fillLow: widget.enabled
            ? null
            : Color.lerp(c.displayLow, c.panelLow, 0.6),
      ),
    );
    final Widget entryBox = RawTextEntryBox(
      minHeight: layered.minimumSize?.height ?? theme.controlHeight,
      controller: _controller,
      maxLines: widget.maxLines,
      hint: widget.hintText == null
          ? null
          : Text(
              widget.hintText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: words.copyWith(
                color: widget.enabled ? c.onDisplayMuted : c.disabled,
              ),
            ),
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          decoration: null,
          style: words,
          cursorColor: c.indicator,
          cursorWidth: 2,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          onEditingComplete: widget.onEditingComplete,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
        ),
      ),
    );
    // A field with words of its own is framed: the frame reads them on the
    // entry's node (a key at its end, a password's reveal, keeps a node of
    // its own in it). A bare window (a combobox's, a palette's search) is a
    // node of its own.
    final error = widget.errorText;
    final framed =
        widget.labelText != null ||
        widget.helperText != null ||
        (error != null && error.isNotEmpty);
    final entry = Semantics(
      container: !framed,
      child: Semantics(
        label: widget.semanticLabel ?? widget.labelText,
        hint: widget.hintText,
        child: entryBox,
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
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedStudioSurface(
                face: face,
                stiffness: StudioMotion.lampStiffness,
                child: const SizedBox.expand(),
              ),
            ),
            IconTheme.merge(
              data: IconThemeData(color: c.onDisplayMuted, size: 20),
              child: Row(
                crossAxisAlignment: oneLine
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  if (widget.prefixIcon != null)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: StudioSpacing.medium,
                        top: oneLine ? 0 : StudioSpacing.medium,
                      ),
                      child: widget.prefixIcon,
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: StudioSpacing.medium + 2,
                      ),
                      child: oneLine
                          ? RawCapCenter(
                              capHeightFactor: theme.capHeightFactor,
                              child: entry,
                            )
                          : entry,
                    ),
                  ),
                  if (widget.suffix != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: StudioSpacing.medium,
                      ),
                      child: DefaultTextStyle(
                        style: theme.textTheme.secondary,
                        child: widget.suffix!,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (framed) {
      return StudioFieldFrame(
        labelText: widget.labelText,
        helperText: widget.helperText,
        errorText: error,
        enabled: widget.enabled,
        focusNode: _focus,
        child: box,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        box,
        StudioFieldMessage(error: error),
      ],
    );
  }
}
