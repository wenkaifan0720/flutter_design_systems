/// Keycap's text field: a small well cut into the case, the words set on its
/// floor. Focus lights a band inside the well's edge; the well stays a well.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'cap.dart';
import 'internal/small_key.dart';
import 'theme.dart';

/// The words over a field, printed on the case.
///
/// ```dart
/// const KeycapFieldLabel('Title')
/// ```
class KeycapFieldLabel extends StatelessWidget {
  /// A label reading [text].
  const KeycapFieldLabel(this.text, {super.key, this.enabled = true});

  /// The label's words.
  final String text;

  /// Whether the field it names is on.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: KeycapSpacing.small),
      child: Text(
        text,
        style: theme.textTheme.secondary.copyWith(
          color: enabled ? theme.colors.ink : theme.colors.inkDisabled,
          fontWeight: FontWeight.w500,
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

/// The line under a field: what is wrong ([error], announced as it
/// appears), else a [helper].
///
/// ```dart
/// const KeycapFieldMessage(error: 'Give the folder a name.')
/// ```
class KeycapFieldMessage extends StatelessWidget {
  /// A message under a field.
  const KeycapFieldMessage({super.key, this.helper, this.error});

  /// Help with the field.
  final String? helper;

  /// What is wrong with what was entered; an empty string marks the field
  /// wrong without words.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final style = theme.textTheme.secondary;
    final error = this.error;
    if (error != null) {
      if (error.isEmpty) return const SizedBox.shrink();
      final line = (style.fontSize ?? 14) * (style.height ?? 1);
      return Padding(
        padding: const EdgeInsets.only(top: KeycapSpacing.small),
        child: Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: line,
                child: Center(
                  child: Icon(
                    LucideIcons.circleAlert,
                    size: 16,
                    color: theme.colors.dangerInk,
                  ),
                ),
              ),
              const SizedBox(width: KeycapSpacing.small),
              Expanded(
                child: Text(
                  error,
                  style: style.copyWith(color: theme.colors.dangerInk),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (helper != null) {
      return Padding(
        padding: const EdgeInsets.only(top: KeycapSpacing.small),
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

/// A text field: a well cut into the case, as tall as a key, with a
/// [label] over it and a [helper] or an [error] under it. Its words are
/// centred on their capitals; focus lights a band inside the well's edge
/// (the danger colour while [error] is set).
///
/// ```dart
/// KeycapTextField(label: 'Title', controller: title, onChanged: rename)
/// ```
class KeycapTextField extends StatefulWidget {
  /// A text field.
  const KeycapTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.semanticLabel,
    this.leading,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.autofillHints,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.style,
  });

  /// The words; the field keeps its own when null.
  final TextEditingController? controller;

  /// The field's focus node.
  final FocusNode? focusNode;

  /// The words over the field.
  final String? label;

  /// The words in an empty field.
  final String? hint;

  /// Help under the field.
  final String? helper;

  /// What is wrong, under the field.
  final String? error;

  /// The field's name for a screen reader, when there is no [label].
  final String? semanticLabel;

  /// A glyph at the field's start (a search field's).
  final Widget? leading;

  /// A glyph or a short word at the field's end.
  final Widget? trailing;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Called when the reader submits.
  final ValueChanged<String>? onSubmitted;

  /// Called when the reader finishes editing.
  final VoidCallback? onEditingComplete;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// How the keyboard capitalises.
  final TextCapitalization textCapitalization;

  /// Whether the words are hidden (a password).
  final bool obscureText;

  /// What autofill may offer.
  final Iterable<String>? autofillHints;

  /// Rules for what may be entered.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the field is on.
  final bool enabled;

  /// Whether the words can be read and selected but not changed.
  final bool readOnly;

  /// Whether the field takes focus when it first appears.
  final bool autofocus;

  /// The most lines the field grows to; null for no limit.
  final int? maxLines;

  /// The fewest lines it shows.
  final int? minLines;

  /// Overrides for the well, over [KeycapThemeData.textFieldStyle]:
  /// [DesignStyle.fill] its floor, [DesignStyle.foreground] its words,
  /// [DesignStyle.textStyle] their style, [DesignStyle.minimumSize] its
  /// height.
  final KeycapStyle? style;

  @override
  State<KeycapTextField> createState() => _KeycapTextFieldState();

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

class _KeycapTextFieldState extends State<KeycapTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'KeycapTextField'));

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(KeycapTextField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_changed);
      _focus.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final focused = _focus.hasFocus;
    final wrong = widget.error != null;
    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (focused) WidgetState.focused,
      if (wrong) WidgetState.error,
    };
    final layered = DesignStyleOf([widget.style, theme.textFieldStyle], states);
    final words = theme.textTheme.body
        .merge(layered.textStyle)
        .copyWith(
          color: layered.foreground ?? (widget.enabled ? c.ink : c.inkDisabled),
        );
    final oneLine = widget.maxLines == 1;
    final height = layered.minimumSize?.height ?? theme.controlHeight;
    final Widget editable = DesignTextEntryBox(
      minHeight: height,
      controller: _controller,
      maxLines: widget.maxLines,
      hint: widget.hint == null
          ? null
          : Text(
              widget.hint!,
              // A text area's hint wraps over its lines, as its words do.
              maxLines: oneLine ? 1 : widget.maxLines,
              overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
              style: words.copyWith(
                color: widget.enabled ? c.inkMuted : c.inkDisabled,
              ),
            ),
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          decoration: null,
          style: words,
          cursorColor: c.accent.top,
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
    final named = Semantics(
      container: true,
      child: Semantics(
        label: widget.semanticLabel ?? widget.label,
        hint: widget.hint,
        child: editable,
      ),
    );
    final pad = KeycapSpacing.medium + theme.density.paddingDelta / 2;
    final Widget well = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: widget.enabled ? _focus.requestFocus : null,
        child: KeycapWell(
          radius: BorderRadius.circular(KeycapMetrics.fieldRadius),
          floor:
              layered.fill ??
              (widget.enabled ? null : Color.lerp(c.well, c.ground, 0.6)),
          rim: focused
              ? (wrong ? c.dangerInk : c.focus)
              : wrong
              ? c.dangerInk.withValues(alpha: 0.55)
              : null,
          rimWidth: focused ? KeycapMetrics.focusWidth : 1,
          clip: false,
          child: Row(
            crossAxisAlignment: oneLine
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (widget.leading != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: pad,
                    top: oneLine ? 0 : pad,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      size: 20,
                      color: widget.enabled ? c.inkMuted : c.inkDisabled,
                    ),
                    child: widget.leading!,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: oneLine
                      ? DesignCapCenter(
                          capHeightFactor: theme.capHeightFactor,
                          child: named,
                        )
                      : named,
                ),
              ),
              if (widget.trailing != null)
                Padding(
                  // A small key at the end sits in the well with equal room
                  // round it, its corners concentric with the well's.
                  padding: EdgeInsetsDirectional.only(
                    end: switch (widget.trailing) {
                      final KeycapSmallKey key when oneLine =>
                        (height - key.side) / 2,
                      _ => pad,
                    },
                  ),
                  child: DefaultTextStyle(
                    style: theme.textTheme.secondary,
                    child: IconTheme.merge(
                      data: IconThemeData(size: 20, color: c.inkMuted),
                      child: widget.trailing!,
                    ),
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
            child: KeycapFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        well,
        KeycapFieldMessage(helper: widget.helper, error: widget.error),
      ],
    );
  }
}
