/// An input group and a password reveal, headless.
///
/// [RawInputGroup] makes one control of a field and its add-ons (an
/// icon, a unit, a button): one frame whose states say whether anything in
/// it has focus, a pointer over it, and whether it is disabled or wrong; a
/// tap on the frame or a plain add-on puts the caret in the field.
///
/// [RawPasswordReveal] holds whether a password shows, and the toggle's
/// label and state, keeping the field's focus and caret as it flips.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'localizations.dart';

/// Builds the group's frame around [child] (the field and its add-ons) for
/// [states]: [WidgetState.focused] while anything inside has focus,
/// [WidgetState.hovered], [WidgetState.disabled] and [WidgetState.error].
typedef RawInputGroupBuilder = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
  Widget child,
);

/// A field and its add-ons as one control.
///
/// ```dart
/// RawInputGroup(focusNode: focusNode, builder: (context, states, child) => child, child: const Text('kg'))
/// ```
class RawInputGroup extends StatefulWidget {
  /// A group around [child], whose field takes [focusNode].
  const RawInputGroup({
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
  final RawInputGroupBuilder builder;

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
  State<RawInputGroup> createState() => _DesignInputGroupState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<FocusNode>('focusNode', focusNode))
      ..add(ObjectFlagProperty<RawInputGroupBuilder>.has('builder', builder))
      ..add(
        FlagProperty(
          'enabled',
          value: enabled,
          ifFalse: 'enabled: false',
          defaultValue: true,
        ),
      )
      ..add(
        FlagProperty(
          'isError',
          value: isError,
          ifTrue: 'isError',
          defaultValue: false,
        ),
      )
      ..add(
        DiagnosticsProperty<MouseCursor>(
          'mouseCursor',
          mouseCursor,
          defaultValue: SystemMouseCursors.text,
        ),
      );
  }
}

class _DesignInputGroupState extends State<RawInputGroup> {
  bool _focused = false;
  bool _hovered = false;

  @override
  void didUpdateWidget(RawInputGroup oldWidget) {
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
/// RawPasswordController(obscured: false)
/// ```
class RawPasswordController extends ValueNotifier<bool> {
  /// Starts hidden unless [obscured] is false.
  RawPasswordController({bool obscured = true}) : super(obscured);

  /// Whether it is hidden.
  bool get obscured => value;

  /// Shows it when hidden, hides it when shown.
  void toggle() => value = !value;
}

/// What a [RawPasswordReveal]'s builder paints from.
@immutable
class RawPasswordDetails {
  /// The details of a reveal.
  const RawPasswordDetails({
    required this.obscured,
    required this.toggle,
    required this.toggleLabel,
  });

  /// Whether the password is hidden: give it to the field's `obscureText`.
  final bool obscured;

  /// Flips it: the toggle's press.
  final VoidCallback toggle;

  /// What the toggle says to a screen reader ("Show password" while hidden,
  /// "Hide password" while shown). Give the toggle
  /// `semanticSelected: !obscured`: a toggle button, read as a button that is
  /// selected while the password shows.
  final String toggleLabel;
}

/// Holds whether a password shows and gives the field and its toggle what
/// they need. The field keeps its focus and caret as it flips; with
/// [hideOnBlur] a shown password hides again when focus leaves the field.
///
/// ```dart
/// RawPasswordReveal(builder: (context, password) => Text(password.toggleLabel))
/// ```
class RawPasswordReveal extends StatefulWidget {
  /// A reveal for one password field.
  const RawPasswordReveal({
    super.key,
    required this.builder,
    this.controller,
    this.focusNode,
    this.hideOnBlur = false,
    this.showLabel,
    this.hideLabel,
  });

  /// Paints the field and its toggle.
  final Widget Function(BuildContext context, RawPasswordDetails password)
  builder;

  /// Holds whether it shows, when the caller watches it. The caller
  /// disposes it; null: the reveal makes its own and disposes it.
  final RawPasswordController? controller;

  /// The field's focus, for [hideOnBlur] and to keep focus on the field as
  /// the toggle flips it. The caller's, who disposes it; the reveal only
  /// listens to it.
  final FocusNode? focusNode;

  /// Whether a shown password hides when focus leaves the field.
  final bool hideOnBlur;

  /// The toggle's label while hidden; null:
  /// [RawWidgetsLocalizations.showPasswordLabel].
  final String? showLabel;

  /// The toggle's label while shown; null:
  /// [RawWidgetsLocalizations.hidePasswordLabel].
  final String? hideLabel;

  @override
  State<RawPasswordReveal> createState() => _DesignPasswordRevealState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, RawPasswordDetails password)
        >.has('builder', builder),
      )
      ..add(
        DiagnosticsProperty<RawPasswordController>(
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
      ..add(
        FlagProperty(
          'hideOnBlur',
          value: hideOnBlur,
          ifTrue: 'hideOnBlur',
          defaultValue: false,
        ),
      )
      ..add(StringProperty('showLabel', showLabel, defaultValue: null))
      ..add(StringProperty('hideLabel', hideLabel, defaultValue: null));
  }
}

class _DesignPasswordRevealState extends State<RawPasswordReveal> {
  RawPasswordController? _own;

  RawPasswordController get _controller =>
      widget.controller ?? (_own ??= RawPasswordController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    widget.focusNode?.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(RawPasswordReveal oldWidget) {
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
      RawPasswordDetails(
        obscured: obscured,
        toggle: _toggle,
        toggleLabel: obscured
            ? widget.showLabel ??
                  RawWidgetsLocalizations.of(context).showPasswordLabel
            : widget.hideLabel ??
                  RawWidgetsLocalizations.of(context).hidePasswordLabel,
      ),
    );
  }
}
