/// The label of the [ComicFormField] a control stands in, so the control does not say it a second time.
library;

import 'package:flutter/widgets.dart';

/// Set by a form field around its control: the field's [label], and whether the control is read in the field's own
/// node ([merged]) or keeps its nodes as a group does.
class ComicFieldLabel extends InheritedWidget {
  /// Marks [child] as the control of a field labelled [label].
  const ComicFieldLabel({
    super.key,
    required this.label,
    required this.merged,
    required super.child,
  });

  /// The field's label, as it is drawn and read.
  final String label;

  /// Whether the control is read in the field's node.
  final bool merged;

  /// [name], or null when the field around [context] already says it: a control read in the field's node, or a
  /// [group]'s own name, that repeats the field's label.
  static String? unsaid(
    BuildContext context,
    String? name, {
    bool group = false,
  }) {
    if (name == null) return null;
    final field = context.dependOnInheritedWidgetOfExactType<ComicFieldLabel>();
    if (field == null || !(field.merged || group)) return name;
    return name.trim().toLowerCase() == field.label.trim().toLowerCase()
        ? null
        : name;
  }

  @override
  bool updateShouldNotify(ComicFieldLabel oldWidget) =>
      oldWidget.label != label || oldWidget.merged != merged;
}
