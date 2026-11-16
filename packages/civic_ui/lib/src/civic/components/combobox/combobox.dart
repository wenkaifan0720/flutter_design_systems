import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/list_option.dart';
import '../../internal/paint.dart';
import '../../theme.dart';
import '../text-field/text_field.dart';

/// One answer from a long list, found by typing: a [CivicTextField] whose
/// words narrow the [options] in a list under the box, floating on a
/// hairline and a soft shadow, as a select's list is: the chosen row on
/// the inset rule in the action colour, bold and ticked, a row under the
/// pointer grey. The arrow keys walk the list, the row reached lies on the
/// yellow plate, Enter or a press takes it, Escape closes the list; after
/// Enter the box keeps the focus, and typing goes on in it. A screen reader
/// hears the row reached and how many matched. When nothing
/// matches the list says so ("No results").
///
/// Use it where a select would hold too many answers to scan (a country,
/// a street, a school); use [CivicRadioGroup] for a few.
///
/// The box reads [CivicStyle] as [CivicTextField] does: [style], then
/// [CivicThemeData.textFieldStyle]. The list is the look's, as the
/// select's is.
///
/// ```dart
/// CivicCombobox<String>(
///   labelText: 'Street',
///   options: streets,
///   onSelected: (value) => setState(() => street = value),
/// )
/// ```
class CivicCombobox<T extends Object> extends StatelessWidget {
  /// A box that finds an answer from [options].
  const CivicCombobox({
    super.key,
    required this.options,
    this.displayStringForOption,
    this.value,
    this.onSelected,
    this.labelText,
    this.helperText,
    this.errorText,
    this.hintText,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.style,
  });

  /// The answers.
  final Iterable<T> options;

  /// An answer's words; null says its `toString`.
  final String Function(T option)? displayStringForOption;

  /// The answer chosen, ticked in the list.
  final T? value;

  /// Called with an answer as it is chosen.
  final ValueChanged<T>? onSelected;

  /// What the box asks.
  final String? labelText;

  /// How to answer.
  final String? helperText;

  /// What to fix; null while the answer is fine.
  final String? errorText;

  /// Shown in the box while it is empty.
  final String? hintText;

  /// The words typed; the combobox's own when null, and never disposed
  /// when given.
  final TextEditingController? controller;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// Whether it takes input.
  final bool enabled;

  /// Overrides for the box's look.
  final CivicStyle? style;

  String _say(T option) =>
      displayStringForOption?.call(option) ?? option.toString();

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    return DesignCombobox<T>(
      options: options,
      displayStringForOption: _say,
      value: value,
      onSelected: onSelected,
      controller: controller,
      focusNode: focusNode,
      semanticLabel: labelText,
      optionsMaxHeight: _listMost,
      fieldBuilder: (context, field) => CivicTextField(
        controller: field.controller,
        focusNode: field.focusNode,
        labelText: labelText,
        helperText: helperText,
        errorText: errorText,
        hintText: hintText,
        enabled: enabled,
        textInputAction: TextInputAction.done,
        // The return key takes the lit answer and the field keeps the
        // focus: taken in onEditingComplete, with no onSubmitted, so
        // Flutter never restarts the field's text input (in a browser the
        // restarted input would take no more typing).
        onEditingComplete: field.submit,
        style: style,
      ),
      surfaceBuilder: (context, list) => Padding(
        padding: const EdgeInsets.only(top: CivicSpacing.s8),
        child: DecoratedBox(
          decoration: civicFloating(
            face: t.background,
            hairline: t.rule,
            dark: t.isDark,
          ),
          child: Padding(
            padding: const EdgeInsets.all(CivicMetrics.edge - 1),
            child: list,
          ),
        ),
      ),
      emptyBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CivicSpacing.s12,
          vertical: CivicSpacing.s12,
        ),
        child: Text(
          DesignLocalizations.of(context).noResultsLabel,
          style: text.body.copyWith(color: t.textSecondary),
        ),
      ),
      optionBuilder: (context, option, states) => CivicListOption(
        label: _say(option),
        chosen: states.contains(WidgetState.selected),
        hovered: states.contains(WidgetState.hovered),
        pressed: states.contains(WidgetState.pressed),
        focused: states.contains(WidgetState.focused),
      ),
    );
  }

  /// The tallest the list stands: five rows and a half, so a reader sees
  /// there is more.
  static const double _listMost = CivicMetrics.controlHeight * 5.5;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('options', options))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
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
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
