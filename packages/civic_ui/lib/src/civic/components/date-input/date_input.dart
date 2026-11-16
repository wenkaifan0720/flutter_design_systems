import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../fieldset/fieldset.dart';
import '../text-field/text_field.dart';

/// Which box of a [CivicDateInput].
enum CivicDatePart {
  /// The day's box.
  day,

  /// The month's box.
  month,

  /// The year's box.
  year,
}

/// A date the reader knows (a birthday, a date on a document), as three
/// boxes sized for what they take: day, month, year, each with its own
/// label, under the question. A picker is for a date the reader chooses;
/// a date they know is quicker typed.
///
/// [errorText] says what is wrong with the date; [errorParts] names the
/// boxes to put right, which take the error edge.
///
/// Each box reads [CivicStyle] as [CivicTextField] does: [style], then
/// [CivicThemeData.textFieldStyle].
///
/// ```dart
/// CivicDateInput(
///   labelText: 'What is your date of birth?',
///   helperText: 'For example, 27 3 1987',
///   dayLabel: 'Day',
///   monthLabel: 'Month',
///   yearLabel: 'Year',
///   dayController: day,
///   monthController: month,
///   yearController: year,
/// )
/// ```
class CivicDateInput extends StatelessWidget {
  /// A date's three boxes.
  const CivicDateInput({
    super.key,
    required this.dayLabel,
    required this.monthLabel,
    required this.yearLabel,
    this.labelText,
    this.helperText,
    this.errorText,
    this.errorParts = const {},
    this.isPageHeading = false,
    this.dayController,
    this.monthController,
    this.yearController,
    this.dayFocusNode,
    this.monthFocusNode,
    this.yearFocusNode,
    this.onChanged,
    this.enabled = true,
    this.style,
  });

  /// The day box's label, in the reader's language.
  final String dayLabel;

  /// The month box's label.
  final String monthLabel;

  /// The year box's label.
  final String yearLabel;

  /// The question.
  final String? labelText;

  /// An example of the answer.
  final String? helperText;

  /// What is wrong with the date; null while it is fine.
  final String? errorText;

  /// The boxes to put right.
  final Set<CivicDatePart> errorParts;

  /// Whether the question is the page's heading.
  final bool isPageHeading;

  /// The day's words; the box's own when null.
  final TextEditingController? dayController;

  /// The month's words.
  final TextEditingController? monthController;

  /// The year's words.
  final TextEditingController? yearController;

  /// The day box's focus; an error summary's link focuses it.
  final FocusNode? dayFocusNode;

  /// The month box's focus.
  final FocusNode? monthFocusNode;

  /// The year box's focus.
  final FocusNode? yearFocusNode;

  /// Called with the box and its words as they are typed.
  final void Function(CivicDatePart part, String value)? onChanged;

  /// Whether the boxes take input.
  final bool enabled;

  /// Overrides for the boxes' look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    // Where no box is named, an error marks all three.
    final marked = errorText == null
        ? const <CivicDatePart>{}
        : errorParts.isEmpty
        ? CivicDatePart.values.toSet()
        : errorParts;
    final scaler = MediaQuery.textScalerOf(context);
    final text = context.civicText;
    final words = text.body.copyWith(
      fontSize: scaler.scale(text.body.fontSize ?? 19),
    );
    // Each box as wide as its characters, or its label where that is wider.
    double widthOf(String label, int characters) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: text.body),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      final box = CivicTextField.widthFor(characters, words);
      return (w > box ? w : box).ceilToDouble();
    }

    Widget box(
      CivicDatePart part,
      String label,
      int width,
      TextEditingController? controller,
      FocusNode? node,
      Iterable<String> autofill,
    ) => SizedBox(
      width: widthOf(label, width),
      child: CivicTextField(
        labelText: label,
        controller: controller,
        focusNode: node,
        isError: marked.contains(part),
        enabled: enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(width),
        ],
        autofillHints: autofill,
        textInputAction: part == CivicDatePart.year
            ? TextInputAction.done
            : TextInputAction.next,
        onChanged: onChanged == null ? null : (v) => onChanged!(part, v),
        style: style,
      ),
    );
    return CivicFieldset(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      isPageHeading: isPageHeading,
      direction: Axis.horizontal,
      children: [
        box(CivicDatePart.day, dayLabel, 2, dayController, dayFocusNode, const [
          AutofillHints.birthdayDay,
        ]),
        box(
          CivicDatePart.month,
          monthLabel,
          2,
          monthController,
          monthFocusNode,
          const [AutofillHints.birthdayMonth],
        ),
        box(
          CivicDatePart.year,
          yearLabel,
          4,
          yearController,
          yearFocusNode,
          const [AutofillHints.birthdayYear],
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(IterableProperty<CivicDatePart>('errorParts', errorParts))
      ..add(
        FlagProperty(
          'isPageHeading',
          value: isPageHeading,
          ifTrue: 'page heading',
        ),
      )
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
