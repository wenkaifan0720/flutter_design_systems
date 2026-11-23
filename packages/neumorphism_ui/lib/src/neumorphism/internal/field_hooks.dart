import 'package:flutter/widgets.dart';

/// How a form that says a field's words itself wires the text field under
/// it: the form's own parts (a combobox's input, a search field's) and kit
/// adapters, never a page. A text field reads the nearest one.
class NeumorphicFieldHooks extends InheritedWidget {
  /// Hooks for the text field in [child].
  const NeumorphicFieldHooks({
    super.key,
    this.decorate,
    this.failureLine,
    this.nameOnly = false,
    this.lines = true,
    this.expanded,
    required super.child,
  });

  /// Wraps the editable in the form's own name and hint. The field then
  /// says none of its words itself, and leaves its help out of the tree.
  final Widget Function(Widget editable)? decorate;

  /// Wraps the drawn error line, which is then no live region of its own.
  final Widget Function(Widget failure)? failureLine;

  /// Uses the field's label only as the input's name; no label is drawn
  /// above it.
  final bool nameOnly;

  /// Whether the field draws its help and error lines under it; false where the
  /// form draws them under its whole (a combobox, whose list opens at the
  /// groove). The field's node still says them.
  final bool lines;

  /// Whether the list the field opens is showing, said on the input's node;
  /// null for a field that opens none.
  final bool? expanded;

  /// The hooks round [context], or null.
  static NeumorphicFieldHooks? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NeumorphicFieldHooks>();

  @override
  bool updateShouldNotify(NeumorphicFieldHooks oldWidget) =>
      decorate != oldWidget.decorate ||
      failureLine != oldWidget.failureLine ||
      nameOnly != oldWidget.nameOnly ||
      lines != oldWidget.lines ||
      expanded != oldWidget.expanded;
}
