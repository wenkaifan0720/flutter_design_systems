import 'package:flutter/widgets.dart';

/// The controller and the focus node a text control stands on: the caller's
/// when given, else its own, kept in step with the `value` the page passes
/// (a changed value from outside replaces the text; the caret goes to its
/// end). Plumbing of the text controls; pages never see it.
mixin FrostedFieldOwner<T extends StatefulWidget> on State<T> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  /// The caller's controller, if any.
  TextEditingController? controllerOf(T widget);

  /// The caller's value, when the page owns the text.
  String? valueOf(T widget);

  /// The caller's focus node, if any.
  FocusNode? focusNodeOf(T widget);

  /// The controller in use.
  TextEditingController get fieldController =>
      controllerOf(widget) ??
      (_ownController ??= TextEditingController(text: valueOf(widget) ?? ''));

  /// The focus node in use.
  FocusNode get fieldFocus =>
      focusNodeOf(widget) ?? (_ownFocus ??= FocusNode());

  /// Whether focus moved: rebuild so the outline follows it.
  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fieldFocus.addListener(_onFocus);
    fieldController.addListener(_onText);
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (focusNodeOf(oldWidget) != focusNodeOf(widget)) {
      (focusNodeOf(oldWidget) ?? _ownFocus)?.removeListener(_onFocus);
      fieldFocus.addListener(_onFocus);
    }
    if (controllerOf(oldWidget) != controllerOf(widget)) {
      (controllerOf(oldWidget) ?? _ownController)?.removeListener(_onText);
      fieldController.addListener(_onText);
    }
    final value = valueOf(widget);
    if (controllerOf(widget) == null &&
        value != null &&
        value != valueOf(oldWidget) &&
        value != fieldController.text) {
      fieldController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void dispose() {
    fieldFocus.removeListener(_onFocus);
    fieldController.removeListener(_onText);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }
}
