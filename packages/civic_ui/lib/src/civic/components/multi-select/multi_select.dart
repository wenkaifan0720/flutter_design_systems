import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/choice_face.dart';
import '../../internal/field_frame.dart';
import '../../internal/list_option.dart';
import '../../internal/paint.dart';
import '../../internal/list_open.dart';
import '../../theme.dart';
import '../text-field/text_field.dart';

/// Several answers chosen from a long list: the answers chosen so far
/// stand over the field, each solid in the action colour with a cross
/// after its words, and the field below them suggests more as someone
/// types, in the combobox's list. Where the answers are few, checkboxes
/// show them all at once and are quicker.
///
/// A press on a chosen answer removes it. From the field, Backspace on
/// nothing typed (or Left at its start) steps back onto the answers, where
/// Backspace or Delete removes the one with the focus; a screen reader
/// offers each answer's removal as an action. [maxTags] stops the
/// suggestions once that many are chosen.
///
/// [values] in, [onChanged] out. Reads [CivicStyle] as the text field does
/// for the field (its `style:`, then [CivicThemeData.textFieldStyle]); the
/// chosen answers read [CivicThemeData.chipStyle].
///
/// ```dart
/// CivicMultiSelect<String>(
///   labelText: 'Which languages do you speak?',
///   options: languages,
///   values: spoken,
///   onChanged: (next) => setState(() => spoken = next),
/// )
/// ```
class CivicMultiSelect<T extends Object> extends StatelessWidget {
  /// A multi-select.
  const CivicMultiSelect({
    super.key,
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.search,
    this.displayStringForOption,
    this.labelText,
    this.helperText,
    this.errorText,
    this.hintText,
    this.maxTags,
    this.deleteLabel,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.style,
  });

  /// The answers chosen, in the order chosen.
  final List<T> values;

  /// Called with the answers after each is added or removed.
  final ValueChanged<List<T>> onChanged;

  /// The answers offered; the field narrows them by what is typed.
  final Iterable<T> options;

  /// Looks answers up as someone types, in place of [options].
  final RawOptionSearch<T>? search;

  /// An answer's words; null: its `toString`.
  final String Function(T option)? displayStringForOption;

  /// The question.
  final String? labelText;

  /// How to answer.
  final String? helperText;

  /// What to fix; null while the answers are fine.
  final String? errorText;

  /// Words in the empty field.
  final String? hintText;

  /// The most answers it takes.
  final int? maxTags;

  /// What a screen reader calls a chosen answer's removal; null: ui_core's
  /// words ("Remove").
  final String? deleteLabel;

  /// The field's text; the caller disposes it.
  final TextEditingController? controller;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// Whether it takes answers.
  final bool enabled;

  /// Overrides for the field's look.
  final CivicStyle? style;

  String _say(T option) =>
      displayStringForOption?.call(option) ?? option.toString();

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final input = RawTagInput<T>(
      values: values,
      onChanged: enabled ? onChanged : (_) {},
      options: options,
      search: search,
      displayStringForOption: _say,
      maxTags: maxTags,
      controller: controller,
      focusNode: focusNode,
      semanticLabel: labelText,
      deleteLabel: deleteLabel,
      optionsMaxHeight: CivicMetrics.controlHeight * 5.5,
      layoutBuilder: (context, tags, field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: CivicSpacing.s8,
        children: [
          // The chosen stand 8 apart face to face, run under run too, their
          // targets reaching into the room between (ui_core's
          // RawChipGroup): in a Wrap each target's slack stood between.
          if (tags.isNotEmpty)
            RawChipGroup(
              spacing: CivicSpacing.s8,
              runSpacing: CivicSpacing.s8,
              children: tags,
            ),
          field,
        ],
      ),
      fieldBuilder: (context, field) => CivicListOpen(
        open: field.isOpen,
        child: CivicTextField(
          controller: field.controller,
          focusNode: field.focusNode,
          hintText: hintText,
          isError: errorText != null,
          enabled: enabled,
          textInputAction: TextInputAction.done,
          onEditingComplete: field.submit,
          style: style,
        ),
      ),
      surfaceBuilder: (context, list) => Padding(
        padding: const EdgeInsets.only(top: CivicSpacing.s8),
        child: CivicOptionSurface(child: list),
      ),
      optionBuilder: (context, option, states) => CivicListOption(
        label: _say(option),
        chosen: states.contains(WidgetState.selected),
        hovered: states.contains(WidgetState.hovered),
        pressed: states.contains(WidgetState.pressed),
        focused: states.contains(WidgetState.focused),
      ),
      tagBuilder: (context, value, tag) => _Chosen(
        label: _say(value),
        tag: tag,
        enabled: enabled,
        styles: [t.chipStyle],
      ),
    );
    if (labelText == null && helperText == null && errorText == null) {
      return input;
    }
    return RawInputDecorator(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      enabled: enabled,
      builder: (context, parts) => CivicFieldFrame(parts: parts),
      child: input,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('values', values))
      ..add(IterableProperty<T>('options', options))
      ..add(ObjectFlagProperty<RawOptionSearch<T>>.has('search', search))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(IntProperty('maxTags', maxTags, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// A chosen answer: a chip's face, solid in the action colour, with a
/// cross after its words; a press removes it.
class _Chosen extends StatefulWidget {
  const _Chosen({
    required this.label,
    required this.tag,
    required this.enabled,
    required this.styles,
  });

  final String label;
  final RawTagDetails tag;
  final bool enabled;
  final List<CivicStyle?> styles;

  @override
  State<_Chosen> createState() => _ChosenState();
}

class _ChosenState extends State<_Chosen> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final text = context.civicText;
    final enabled = widget.enabled;
    final states = <WidgetState>{
      WidgetState.selected,
      if (!enabled) WidgetState.disabled,
      if (enabled && _hovered) WidgetState.hovered,
      if (enabled && _pressed) WidgetState.pressed,
      if (widget.tag.focused) WidgetState.focused,
    };
    return TapTargetPadding(
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: enabled
              ? () {
                  setState(() => _pressed = false);
                  widget.tag.onDeleted();
                }
              : null,
          child: Semantics(
            label: widget.label,
            hint: RawWidgetsLocalizations.of(context).tagInputDeleteLabel,
            excludeSemantics: true,
            child: CivicChoiceFace(
              states: states,
              styles: widget.styles,
              edge: false,
              tick: false,
              minHeight: 40,
              padding: const EdgeInsets.symmetric(
                horizontal: CivicSpacing.s12,
                vertical: CivicSpacing.s4,
              ),
              textStyle: text.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: CivicSpacing.s8,
                children: [
                  Flexible(child: Text(widget.label)),
                  const Icon(LucideIcons.x, size: 18, applyTextScaling: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
