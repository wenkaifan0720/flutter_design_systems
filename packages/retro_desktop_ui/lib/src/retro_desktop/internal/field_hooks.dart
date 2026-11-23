import 'package:flutter/widgets.dart';

/// How a form that says a field's words itself wires the text field under
/// it: the look's own fields (a search field's input, a code field's) and kit
/// adapters, never a page. A text field reads the nearest one.
class RetroDesktopFieldHooks extends InheritedWidget {
  /// Hooks for the text field in [child].
  const RetroDesktopFieldHooks({
    super.key,
    this.decorate,
    this.failureLine,
    this.nameOnly = false,
    required super.child,
  });

  /// Wraps the editable in the form's own name and hint. The field then says
  /// none of its words itself.
  final Widget Function(Widget editable)? decorate;

  /// Wraps the drawn error line, which is then no live region of its own.
  final Widget Function(Widget failure)? failureLine;

  /// Draws the label while leaving its accessible name to [decorate].
  final bool nameOnly;

  /// The hooks round [context], or null.
  static RetroDesktopFieldHooks? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RetroDesktopFieldHooks>();

  @override
  bool updateShouldNotify(RetroDesktopFieldHooks oldWidget) =>
      decorate != oldWidget.decorate ||
      failureLine != oldWidget.failureLine ||
      nameOnly != oldWidget.nameOnly;
}
