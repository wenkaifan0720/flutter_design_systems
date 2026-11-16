import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../internal/option.dart';
import '../../theme.dart';

/// A square box to tick, 40 points, inside a 2-point ink edge, its
/// [labelText] beside it and a [helperText] under that; the whole row takes
/// the press. A keyboard focus rings the box in yellow. Stand several in a
/// `CivicFieldset` that asks the question.
///
/// With [tristate], a null [value] shows a bar: some of a group ticked.
///
/// Reads [CivicStyle]'s fill (the box), foreground (the tick and the
/// words), edge (the box's edge) and textStyle (the words): its `style:`,
/// then [CivicThemeData.checkboxStyle]. The box's size, its square and the
/// focus ring are the look's.
///
/// ```dart
/// CivicCheckbox(
///   value: textMessages,
///   onChanged: (value) => setState(() => textMessages = value!),
///   labelText: 'Text message',
///   helperText: 'We will send a text when your permit is ready.',
/// )
/// ```
class CivicCheckbox extends StatelessWidget {
  /// A box to tick.
  const CivicCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.helperText,
    this.tristate = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(tristate || value != null);

  /// Whether it is ticked; null shows the bar when [tristate].
  final bool? value;

  /// Called with the new value on a press; null disables it.
  final ValueChanged<bool?>? onChanged;

  /// The words beside the box; null stands the box alone (name it with a
  /// `Semantics` label).
  final String? labelText;

  /// A hint under the words.
  final String? helperText;

  /// Whether a press steps through ticked, unticked and the bar.
  final bool tristate;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Overrides for this checkbox's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return CivicOptionRow(
      styles: [style, context.civicTheme.checkboxStyle],
      mark: switch (value) {
        true => CivicMark.tick,
        false => CivicMark.none,
        null => CivicMark.dash,
      },
      round: false,
      checked: value,
      labelText: labelText,
      helperText: helperText,
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: change == null
          ? null
          : () => change(switch (value) {
              false => true,
              true => tristate ? null : false,
              null => false,
            }),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('value', value))
      ..add(ObjectFlagProperty<ValueChanged<bool?>>.has('onChanged', onChanged))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(FlagProperty('tristate', value: tristate, ifTrue: 'tristate'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
