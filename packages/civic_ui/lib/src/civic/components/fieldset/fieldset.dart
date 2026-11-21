import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/field_frame.dart';
import '../../internal/option.dart';
import '../../theme.dart';
import '../checkbox/checkbox.dart';

/// A question answered by more than one control: its [labelText] (the
/// legend) names the group to a screen reader, its [helperText] says how to
/// answer, its [errorText] says what to fix and stands the whole group on
/// the error rule. Checkboxes, the three boxes of a date, an address's
/// lines stand in it. [isPageHeading] makes the legend the page's heading.
/// In an app its checkboxes stand on a card, each a row, as a radio group's
/// answers do.
///
/// ```dart
/// CivicFieldset(
///   labelText: 'How would you like to be contacted?',
///   helperText: 'Select all that apply.',
///   children: [
///     CivicCheckbox(value: email, onChanged: setEmail, labelText: 'Email'),
///     CivicCheckbox(value: post, onChanged: setPost, labelText: 'Post'),
///   ],
/// )
/// ```
class CivicFieldset extends StatelessWidget {
  /// A group of controls under one question.
  const CivicFieldset({
    super.key,
    required this.children,
    this.labelText,
    this.helperText,
    this.errorText,
    this.isPageHeading = false,
    this.direction = Axis.vertical,
  });

  /// The controls.
  final List<Widget> children;

  /// The question: the group's name.
  final String? labelText;

  /// How to answer.
  final String? helperText;

  /// What to fix; null while the answers are fine.
  final String? errorText;

  /// Whether the legend is the page's heading.
  final bool isPageHeading;

  /// Whether the controls stand down the page or along it: a date's boxes
  /// stand along it, wrapping when the line is full.
  final Axis direction;

  @override
  Widget build(BuildContext context) => RawInputDecorator(
    labelText: labelText,
    helperText: helperText,
    errorText: errorText,
    builder: (context, parts) => CivicFieldFrame(
      parts: parts,
      isPageHeading: isPageHeading,
      isLegend: true,
    ),
    child: direction == Axis.vertical
        ? children.isNotEmpty &&
                  children.every((c) => c is CivicCheckbox) &&
                  CivicCardScope.cards(context)
              ? CivicOptionCard(children: children)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  spacing: CivicSpacing.s4,
                  children: children,
                )
        : Wrap(
            spacing: CivicSpacing.s16,
            runSpacing: CivicSpacing.s16,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: children,
          ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        FlagProperty(
          'isPageHeading',
          value: isPageHeading,
          ifTrue: 'page heading',
        ),
      )
      ..add(
        EnumProperty<Axis>('direction', direction, defaultValue: Axis.vertical),
      );
  }
}
