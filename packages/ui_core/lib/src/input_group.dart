/// An input group and a password reveal, headless.
///
/// [DesignInputGroup] makes one control of a field and its add-ons (an
/// icon, a unit, a button): one frame whose states say whether anything in
/// it has focus, a pointer over it, and whether it is disabled or wrong; a
/// tap on the frame or a plain add-on puts the caret in the field.
///
/// [DesignPasswordReveal] holds whether a password shows, and the toggle's
/// label and state, keeping the field's focus and caret as it flips.
library;

import 'package:flutter/widgets.dart';

import 'localizations.dart';

/// Builds the group's frame around [child] (the field and its add-ons) for
/// [states]: [WidgetState.focused] while anything inside has focus,
/// [WidgetState.hovered], [WidgetState.disabled] and [WidgetState.error].
typedef DesignInputGroupBuilder = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
  Widget child,
);

/// A field and its add-ons as one control.
///
/// ```dart
/// DesignInputGroup(focusNode: focusNode, builder: (context, states, child) => child, child: const Text('kg'))
/// ```
class DesignInputGroup extends StatefulWidget {
  /// A group around [child], whose field takes [focusNode].
  const DesignInputGroup({
    super.key,
    required this.focusNode,
    required this.builder,
    required this.child,
    this.enabled = true,
    this.isError = false,
    this.mouseCursor = SystemMouseCursors.text,
  });

  /// The field's focus: a tap on the frame or a plain add-on requests it.
  /// The caller's, who disposes it; the group only listens to and requests
  /// it.
  final FocusNode focusNode;

  /// Draws the frame.
  final DesignInputGroupBuilder builder;

  /// The field and its add-ons, laid out by the look.
  final Widget child;

  /// Whether it takes input; a disabled group ignores taps and keeps no
  /// focus.
  final bool enabled;

  /// Whether what it holds is wrong ([WidgetState.error]).
  final bool isError;

  /// The pointer over the frame.
  final MouseCursor mouseCursor;

  @override
  State<DesignInputGroup> createState() => _DesignInputGroupState();
}

class _DesignInputGroupState extends State<DesignInputGroup> {
  bool _focused = false;
  bool _hovered = false;

  @override
  void didUpdateWidget(DesignInputGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && widget.focusNode.hasFocus) {
      widget.focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final states = <WidgetState>{
      if (_focused && widget.enabled) WidgetState.focused,
      if (_hovered && widget.enabled) WidgetState.hovered,
      if (!widget.enabled) WidgetState.disabled,
      if (widget.isError) WidgetState.error,
    };
    Widget group = widget.builder(context, states, widget.child);
    group = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: group,
    );
    group = GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      // A tap the add-ons do not take (their own buttons win the arena)
      // puts the caret in the field.
      onTap: widget.enabled ? widget.focusNode.requestFocus : null,
      child: group,
    );
    group = MouseRegion(
      cursor: widget.enabled ? widget.mouseCursor : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: group,
    );
    if (!widget.enabled) group = ExcludeFocus(child: group);
    return group;
  }
}

/// Whether a password shows: true while it is hidden.
///
/// The caller makes it (a State's field, say), keeps it across rebuilds
/// and disposes it; a widget it is given to only listens to it.
///
/// ```dart
/// DesignPasswordController(obscured: false)
/// ```
class DesignPasswordController extends ValueNotifier<bool> {
  /// Starts hidden unless [obscured] is false.
  DesignPasswordController({bool obscured = true}) : super(obscured);

  /// Whether it is hidden.
  bool get obscured => value;

  /// Shows it when hidden, hides it when shown.
  void toggle() => value = !value;
}

/// What a [DesignPasswordReveal]'s builder paints from.
@immutable
class DesignPasswordDetails {
  /// The details of a reveal.
  const DesignPasswordDetails({
    required this.obscured,
    required this.toggle,
    required this.toggleLabel,
  });

  /// Whether the password is hidden: give it to the field's `obscureText`.
  final bool obscured;

  /// Flips it: the toggle's press.
  final VoidCallback toggle;

  /// What the toggle says to a screen reader ("Show password" while hidden,
  /// "Hide password" while shown); give the toggle `toggled: !obscured`.
  final String toggleLabel;
}

/// Holds whether a password shows and gives the field and its toggle what
/// they need. The field keeps its focus and caret as it flips; with
/// [hideOnBlur] a shown password hides again when focus leaves the field.
///
/// ```dart
/// DesignPasswordReveal(builder: (context, password) => Text(password.toggleLabel))
/// ```
class DesignPasswordReveal extends StatefulWidget {
  /// A reveal for one password field.
  const DesignPasswordReveal({
    super.key,
    required this.builder,
    this.controller,
    this.focusNode,
    this.hideOnBlur = false,
    this.showLabel,
    this.hideLabel,
  });

  /// Paints the field and its toggle.
  final Widget Function(BuildContext context, DesignPasswordDetails password)
  builder;

  /// Holds whether it shows, when the caller watches it. The caller
  /// disposes it; null: the reveal makes its own and disposes it.
  final DesignPasswordController? controller;

  /// The field's focus, for [hideOnBlur] and to keep focus on the field as
  /// the toggle flips it. The caller's, who disposes it; the reveal only
  /// listens to it.
  final FocusNode? focusNode;

  /// Whether a shown password hides when focus leaves the field.
  final bool hideOnBlur;

  /// The toggle's label while hidden; null:
  /// [DesignLocalizations.showPasswordLabel].
  final String? showLabel;

  /// The toggle's label while shown; null:
  /// [DesignLocalizations.hidePasswordLabel].
  final String? hideLabel;

  @override
  State<DesignPasswordReveal> createState() => _DesignPasswordRevealState();
}

class _DesignPasswordRevealState extends State<DesignPasswordReveal> {
  DesignPasswordController? _own;

  DesignPasswordController get _controller =>
      widget.controller ?? (_own ??= DesignPasswordController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    widget.focusNode?.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(DesignPasswordReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _own)?.removeListener(_changed);
      _controller.addListener(_changed);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_focusChanged);
      widget.focusNode?.addListener(_focusChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    widget.focusNode?.removeListener(_focusChanged);
    _own?.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  void _focusChanged() {
    final node = widget.focusNode!;
    if (widget.hideOnBlur && !node.hasFocus && !_controller.obscured) {
      _controller.value = true;
    }
  }

  void _toggle() {
    final node = widget.focusNode;
    final had = node?.hasFocus ?? false;
    _controller.toggle();
    if (had && !node!.hasFocus) node.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final obscured = _controller.obscured;
    return widget.builder(
      context,
      DesignPasswordDetails(
        obscured: obscured,
        toggle: _toggle,
        toggleLabel: obscured
            ? widget.showLabel ??
                  DesignLocalizations.of(context).showPasswordLabel
            : widget.hideLabel ??
                  DesignLocalizations.of(context).hidePasswordLabel,
      ),
    );
  }
}
