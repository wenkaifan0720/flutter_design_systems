/// Appliance's text entry: [ApplianceTextField], a sunken well with the
/// caret in signal orange; its [ApplianceFieldLabel] above and its
/// [ApplianceFieldMessage] (help, or an error beside a red fault lamp)
/// below, which the select shares.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'material.dart';
import 'theme.dart';

/// The words over a field: printed on the panel, 14 px medium, 8 px above
/// the well.
///
/// ```dart
/// const ApplianceFieldLabel('Display name')
/// ```
class ApplianceFieldLabel extends StatelessWidget {
  /// A label reading [text].
  const ApplianceFieldLabel(this.text, {super.key, this.enabled = true});

  /// The words.
  final String text;

  /// Whether the field is live; a disabled field's label greys.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: ApplianceSpacing.small),
      child: Text(
        text,
        style: theme.textTheme.secondary.copyWith(
          color: enabled ? theme.colors.print : theme.colors.printDisabled,
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

/// What stands under a field: its [error] beside a lit red fault lamp,
/// announced as it appears, or else its [helper]; nothing when neither.
///
/// ```dart
/// const ApplianceFieldMessage(error: 'Enter a postcode')
/// ```
class ApplianceFieldMessage extends StatelessWidget {
  /// A field's message.
  const ApplianceFieldMessage({super.key, this.helper, this.error});

  /// Help under the field.
  final String? helper;

  /// What is wrong; an empty string marks the well alone.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final style = theme.textTheme.secondary;
    final error = this.error;
    if (error != null) {
      if (error.isEmpty) return const SizedBox.shrink();
      final lineHeight = (style.fontSize ?? 14) * (style.height ?? 1);
      return Padding(
        padding: const EdgeInsets.only(top: ApplianceSpacing.small),
        child: Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: lineHeight,
                child: Center(
                  child: ApplianceLamp(lit: true, color: theme.colors.danger),
                ),
              ),
              const SizedBox(width: ApplianceSpacing.small),
              Expanded(
                child: Text(
                  error,
                  style: style.copyWith(color: theme.colors.danger),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (helper != null) {
      return Padding(
        padding: const EdgeInsets.only(top: ApplianceSpacing.small),
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

/// A text field: a sunken well in the panel, the words printed in it, the
/// caret in signal orange. Focused, the well keeps its own fill and an
/// orange bezel lights round it; with an [error], its rim and the message
/// under it turn red.
///
/// It is a bare `TextField` (no decoration) in the look's own box, one line
/// centred by its capitals, so it stands level with a key or a select
/// beside it at every density and on every platform.
///
/// A tap anywhere in the well focuses the words. [enabled] false greys it
/// and takes it out of the focus order.
///
/// Reads [style]'s `fill`, `foreground`, `edge`, `minimumSize` (the well's
/// height) and `textStyle` in its states, then
/// [ApplianceThemeData.textFieldStyle]'s.
///
/// ```dart
/// ApplianceTextField(label: 'Postcode', hint: 'e.g. EH3 9DR', controller: postcode)
/// ```
class ApplianceTextField extends StatefulWidget {
  /// A text field.
  const ApplianceTextField({
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

  /// The words' controller; without one the field keeps its own. One you
  /// give is yours to dispose.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The words over the well.
  final String? label;

  /// What the well says while it is empty: a format, never the label.
  final String? hint;

  /// Help under the well.
  final String? helper;

  /// What is wrong, under the well beside a red lamp.
  final String? error;

  /// The field's name for a screen reader, when [label] is not shown.
  final String? semanticLabel;

  /// A glyph at the well's start (a search's lens).
  final Widget? leading;

  /// What stands at the well's end (a unit, a clear key).
  final Widget? trailing;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action key submits the words.
  final ValueChanged<String>? onSubmitted;

  /// Called when editing completes.
  final VoidCallback? onEditingComplete;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// Whether the keyboard starts words or sentences in capitals.
  final TextCapitalization textCapitalization;

  /// Whether the words are hidden (a password).
  final bool obscureText;

  /// What the platform may fill in.
  final Iterable<String>? autofillHints;

  /// Formatters run on every change.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the field takes words.
  final bool enabled;

  /// Whether the words can be selected but not changed.
  final bool readOnly;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// The most lines; 1 centres one line in the well.
  final int? maxLines;

  /// The fewest lines the well shows.
  final int? minLines;

  /// The well's style, over [ApplianceThemeData.textFieldStyle].
  final ApplianceStyle? style;

  @override
  State<ApplianceTextField> createState() => _ApplianceTextFieldState();

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

class _ApplianceTextFieldState extends State<ApplianceTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'ApplianceTextField'));

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(ApplianceTextField old) {
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
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final focused = _focus.hasFocus;
    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (focused) WidgetState.focused,
      if (widget.error != null) WidgetState.error,
    };
    final layered = DesignStyleOf([widget.style, theme.textFieldStyle], states);
    final words = layered
        .text(theme.textTheme.body)
        .copyWith(
          color:
              layered.foreground ??
              (widget.enabled ? c.print : c.printDisabled),
        );
    final oneLine = widget.maxLines == 1;
    final face = layered.on(
      ApplianceFace.well(c).copyWith(
        lift: widget.enabled ? -1 : -0.5,
        foreground: words.color,
        edge: widget.error != null ? c.danger : null,
        focus: focused
            ? (widget.error != null ? c.danger : c.focus)
            : c.focus.withValues(alpha: 0),
      ),
    );
    final height = layered.minimumSize?.height ?? theme.controlHeight;
    final Widget editable = DesignTextEntryBox(
      minHeight: height,
      controller: _controller,
      maxLines: widget.maxLines,
      hint: widget.hint == null
          ? null
          : Text(
              widget.hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: words.copyWith(color: c.printMuted),
            ),
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          decoration: null,
          style: words,
          cursorColor: c.signal,
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
    final Widget well = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: widget.enabled ? _focus.requestFocus : null,
        child: AnimatedApplianceSurface(
          face: face,
          child: Row(
            crossAxisAlignment: oneLine
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (widget.leading != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: ApplianceSpacing.medium,
                    top: oneLine ? 0 : ApplianceSpacing.medium,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      size: 20,
                      color: widget.enabled ? c.printMuted : c.printDisabled,
                    ),
                    child: widget.leading!,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ApplianceSpacing.medium,
                  ),
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
                  padding: const EdgeInsetsDirectional.only(
                    end: ApplianceSpacing.medium,
                  ),
                  child: DefaultTextStyle(
                    style: theme.textTheme.secondary,
                    child: IconTheme.merge(
                      data: IconThemeData(size: 20, color: c.printMuted),
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
            child: ApplianceFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        well,
        ApplianceFieldMessage(helper: widget.helper, error: widget.error),
      ],
    );
  }
}
