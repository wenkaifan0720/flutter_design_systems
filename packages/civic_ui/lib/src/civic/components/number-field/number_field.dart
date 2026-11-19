import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/choice_face.dart';
import '../../internal/field_frame.dart';
import '../../internal/paint.dart';
import '../../theme.dart';
import '../text-field/text_field.dart';

/// A number typed or stepped: the field's well between a minus and a plus
/// in the secondary button's material, each a finger's 48 points. A step
/// press moves it by [step] and a held one repeats; the arrow keys step it,
/// Page Up and Page Down by ten steps, Home and End go to [min] and [max]
/// where there are ones. A typed number is taken when Enter is pressed or
/// the focus leaves, and kept between [min] and [max].
///
/// [value] in, [onChanged] out (null clears the field). The limits are
/// said in the [helperText], in words: a reader can't guess them.
///
/// Reads [CivicStyle] as [CivicTextField] does for the well (through
/// [CivicThemeData.textFieldStyle]); the steps read
/// [CivicThemeData.secondaryButtonStyle].
///
/// ```dart
/// CivicNumberField(
///   labelText: 'How many visitor days do you need?',
///   helperText: 'From 1 to 30 days.',
///   value: days,
///   min: 1,
///   max: 30,
///   onChanged: (value) => setState(() => days = value),
/// )
/// ```
class CivicNumberField extends StatelessWidget {
  /// A number field.
  const CivicNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.fractionDigits,
    this.labelText,
    this.helperText,
    this.errorText,
    this.widthInCharacters = 5,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(step > 0);

  /// The number shown; null, empty.
  final double? value;

  /// Called with the number as it is taken; null disables the field.
  final ValueChanged<double?>? onChanged;

  /// The least value; null, none.
  final double? min;

  /// The greatest value; null, none.
  final double? max;

  /// What a step moves by.
  final double step;

  /// The decimals a typed number keeps; null: as many as [step] has.
  final int? fractionDigits;

  /// The question.
  final String? labelText;

  /// How to answer: the limits, in words.
  final String? helperText;

  /// What to fix; null while the number is fine.
  final String? errorText;

  /// How many figures wide the well stands.
  final int widthInCharacters;

  /// The typed text, when the caller holds it.
  final TextEditingController? controller;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Overrides for the well's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final enabled = onChanged != null;
    final number = DesignNumberField(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      step: step,
      fractionDigits: fractionDigits,
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: labelText,
      // The field's node says the value beside the next and previous ones:
      // the input says whether it is enabled, so it stands in a node of its
      // own under it rather than merging.
      fieldBuilder: (context, field) => ListenableBuilder(
        listenable: field.controller,
        builder: (context, child) =>
            Semantics(value: field.controller.text, child: child),
        child: CivicTextField(
          controller: field.controller,
          focusNode: field.focusNode,
          keyboardType: field.keyboardType,
          inputFormatters: field.inputFormatters,
          onEditingComplete: field.onEditingComplete,
          widthInCharacters: widthInCharacters,
          isError: errorText != null,
          enabled: enabled,
          style: style,
        ),
      ),
      buttonBuilder: (context, button) => DesignTapTarget(
        child: SizedBox(
          width: CivicMetrics.controlHeight,
          child: CivicChoiceFace(
            states: button.states,
            styles: [t.secondaryButtonStyle],
            padding: EdgeInsets.zero,
            child: Icon(
              button.isIncrement ? LucideIcons.plus : LucideIcons.minus,
              size: 24,
            ),
          ),
        ),
      ),
      layoutBuilder: (context, field, decrement, increment) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CivicSpacing.s8,
        children: [
          decrement,
          // The field as wide as its characters: the buttons stand beside it.
          Flexible(child: IntrinsicWidth(child: field)),
          increment,
        ],
      ),
    );
    final row = Align(
      alignment: AlignmentDirectional.centerStart,
      child: number,
    );
    if (labelText == null && helperText == null && errorText == null) {
      return row;
    }
    return DesignField(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      enabled: enabled,
      mergeSemantics: false,
      builder: (context, parts) => CivicFieldFrame(parts: parts),
      child: row,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<double?>>.has('onChanged', onChanged),
      )
      ..add(DoubleProperty('min', min, defaultValue: null))
      ..add(DoubleProperty('max', max, defaultValue: null))
      ..add(DoubleProperty('step', step, defaultValue: 1))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
