/// The one pressable every look's controls stand on: the behaviour Material's and Cupertino's buttons share, with no look of
/// its own. A tap and a long press; Enter and Space through the app's
/// shortcuts ([ActivateIntent], [ButtonActivateIntent]); hover, a keyboard
/// focus that shows only when the keyboard moves it; a hit area of at least
/// [DesignPressable.minimumSize]; one semantics node with the control's role
/// and state. Under it sit a [WidgetStatesController] and a
/// [FocusableActionDetector], and the look's builder gets the
/// `Set<WidgetState>` to resolve its styles against, as
/// [WidgetStateProperty] does.
library;

import 'package:flutter/semantics.dart'
    show SemanticsRole, SemanticsValidationResult;
import 'package:flutter/widgets.dart';

/// Builds a pressable's face for its current [states] (hovered, focused,
/// pressed, disabled, selected, error). [child] is the pressable's own
/// child, passed through so a face that does not change with state is
/// built once.
typedef DesignPressableBuilder = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
);

/// Makes any widget a control (press, focus, hover and what a screen
/// reader hears), with no look of its own.
///
/// [onPressed] null and [enabled] null: disabled (no focus, no hover, a
/// screen reader hears it dimmed, [WidgetState.disabled] in the states).
/// [enabled] true with [onPressed] null: waiting (busy): it keeps its focus,
/// its look and its tap for a screen reader, and a press does nothing, so a
/// control that is working changes neither its node nor its actions.
///
/// [WidgetState.focused] is in the states only while the focus should show
/// (the keyboard moved it, not a tap), so a look draws its ring from it
/// directly.
///
/// ```dart
/// DesignPressable(onPressed: () {}, semanticLabel: 'Save', builder: (context, states, child) => Opacity(opacity: states.contains(WidgetState.pressed) ? 0.6 : 1, child: const Text('Save')))
/// ```
class DesignPressable extends StatefulWidget {
  /// A pressable area drawn by [builder].
  const DesignPressable({
    super.key,
    required this.builder,
    this.child,
    this.onPressed,
    this.onLongPress,
    this.enabled,
    this.selected = false,
    this.isError = false,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.minimumSize = Size.zero,
    this.shortcuts,
    this.actions,
    this.onKeyEvent,
    this.onStatesChanged,
    this.semanticLabel,
    this.semanticValue,
    this.semanticHint,
    this.button = true,
    this.link = false,
    this.tab = false,
    this.semanticSelected,
    this.checked,
    this.mixed = false,
    this.toggled,
    this.expanded,
    this.inMutuallyExclusiveGroup = false,
    this.excludeSemantics = false,
    this.enableFeedback = true,
  });

  /// Draws the face for the current states.
  final DesignPressableBuilder builder;

  /// Passed to [builder] untouched.
  final Widget? child;

  /// What a press does (a tap, Enter, Space, a screen reader's tap).
  final VoidCallback? onPressed;

  /// What a long press does, when anything.
  final VoidCallback? onLongPress;

  /// Whether it takes focus and reports enabled. Null: whether it has
  /// [onPressed] or [onLongPress]. True with neither: waiting.
  final bool? enabled;

  /// [WidgetState.selected]: the chosen one of a set, or toggled on.
  final bool selected;

  /// [WidgetState.error]: what it holds is wrong. The node says so
  /// ([SemanticsValidationResult.invalid]).
  final bool isError;

  /// The states, when the caller watches or drives them itself. The
  /// caller's, who disposes it; null: the pressable makes its own and
  /// disposes it.
  final WidgetStatesController? statesController;

  /// Its focus node, when the caller moves focus itself. The caller's, who
  /// disposes it; null: the pressable's [Focus] makes its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// The pointer over it. Null: a click where it presses, else the one
  /// under it. A [WidgetStateMouseCursor] resolves against the states.
  final MouseCursor? mouseCursor;

  /// The least area that takes a tap, the face centred in it (44 by 44 for
  /// a face drawn smaller than a finger).
  final Size minimumSize;

  /// More keys while it has focus, beside Enter and Space (arrows on a
  /// radio group).
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// More actions, beside [ActivateIntent] and [ButtonActivateIntent].
  final Map<Type, Action<Intent>>? actions;

  /// Keys the shortcuts do not cover, while it or what it holds has focus.
  final KeyEventResult Function(FocusNode node, KeyEvent event)? onKeyEvent;

  /// Called whenever the states change, after the face is rebuilt.
  final ValueChanged<Set<WidgetState>>? onStatesChanged;

  /// What a screen reader calls it. Null: the words inside it.
  final String? semanticLabel;

  /// What it holds, read after the name ("3 of 5").
  final String? semanticValue;

  /// What pressing it does, when the name does not say.
  final String? semanticHint;

  /// Its role: a button (the default), a [link] or a [tab].
  final bool button;

  /// Read as a link rather than a button: it goes somewhere.
  final bool link;

  /// Read as a tab rather than a button: one of a tab bar's, showing its
  /// panel. A screen reader hears it selected or not ([semanticSelected],
  /// else [selected]); a row of them may span its bar where a button keeps
  /// to its content.
  final bool tab;

  /// A screen reader's selected flag, when the control is a choice; null
  /// leaves it out. Defaults to nothing even when [selected] is true: a
  /// pressed toggle says [toggled], a checkbox [checked].
  final bool? semanticSelected;

  /// A screen reader's checked flag, for a checkbox or a radio. Null leaves it out.
  final bool? checked;

  /// A checkbox partly ticked.
  final bool mixed;

  /// A screen reader's toggled flag, for a switch. Null leaves it out.
  final bool? toggled;

  /// A screen reader's expanded flag, for a disclosure. Null leaves it out.
  final bool? expanded;

  /// One of a set where only one is chosen: a radio.
  final bool inMutuallyExclusiveGroup;

  /// Whether to drop the face's own semantics, so only [semanticLabel] is
  /// read. Otherwise the face's words merge into the one node.
  final bool excludeSemantics;

  /// Whether a tap plays the platform's tap feedback.
  final bool enableFeedback;

  @override
  State<DesignPressable> createState() => DesignPressableState();
}

/// The state of a [DesignPressable]: [states] is what its builder was last
/// given.
class DesignPressableState extends State<DesignPressable> {
  WidgetStatesController? _own;

  WidgetStatesController get _controller =>
      widget.statesController ?? (_own ??= WidgetStatesController());

  /// The states the face was last built for.
  Set<WidgetState> get states => Set.unmodifiable(_controller.value);

  bool get _enabled =>
      widget.enabled ??
      (widget.onPressed != null || widget.onLongPress != null);

  bool get _presses => widget.onPressed != null || widget.onLongPress != null;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    _sync();
  }

  @override
  void didUpdateWidget(DesignPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statesController != widget.statesController) {
      (oldWidget.statesController ?? _own)?.removeListener(_changed);
      if (widget.statesController != null) {
        _own?.dispose();
        _own = null;
      }
      _controller.addListener(_changed);
    }
    _sync();
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    widget.onStatesChanged?.call(states);
  }

  /// Brings the given states in line with the widget, during build-time
  /// updates: no listener runs a setState mid-build.
  void _sync() {
    final c = _controller;
    final v = c.value;
    v.removeAll(<WidgetState>{
      if (_enabled) WidgetState.disabled,
      if (!_enabled) ...{WidgetState.hovered, WidgetState.focused},
      if (!_presses) WidgetState.pressed,
      if (!widget.selected) WidgetState.selected,
      if (!widget.isError) WidgetState.error,
    });
    v.addAll(<WidgetState>{
      if (!_enabled) WidgetState.disabled,
      if (widget.selected) WidgetState.selected,
      if (widget.isError) WidgetState.error,
    });
  }

  void _set(WidgetState state, bool on) {
    if (_controller.value.contains(state) != on) {
      _controller.update(state, on);
    }
  }

  void _press() {
    final onPressed = widget.onPressed;
    if (onPressed == null) return;
    if (widget.enableFeedback) Feedback.forTap(context);
    onPressed();
  }

  /// A waiting control's press: nothing, until it has somewhere to go.
  void _wait() {}

  Object? _activate(Intent _) {
    _press();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final presses = _presses;
    final current = states;
    final cursor =
        widget.mouseCursor ??
        (widget.onPressed != null
            ? SystemMouseCursors.click
            : MouseCursor.defer);
    Widget face = widget.builder(context, current, widget.child);
    if (widget.minimumSize != Size.zero) {
      face = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.minimumSize.width,
          minHeight: widget.minimumSize.height,
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: face),
      );
    }
    Widget node = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTapDown: widget.onPressed == null
          ? null
          : (_) => _set(WidgetState.pressed, true),
      onTapUp: widget.onPressed == null
          ? null
          : (_) => _set(WidgetState.pressed, false),
      onTapCancel: widget.onPressed == null
          ? null
          : () => _set(WidgetState.pressed, false),
      onTap: widget.onPressed == null ? null : _press,
      onLongPress: widget.onLongPress,
      child: widget.excludeSemantics ? ExcludeSemantics(child: face) : face,
    );
    // Hover from the pointer itself, as InkWell does: FocusableActionDetector
    // shows a hover only in the traditional highlight mode, so a mouse on a
    // touch-first platform would never light the face.
    node = MouseRegion(
      onEnter: (_) => _set(WidgetState.hovered, _enabled),
      onExit: (_) => _set(WidgetState.hovered, false),
      child: node,
    );
    node = FocusableActionDetector(
      enabled: enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: WidgetStateProperty.resolveAs<MouseCursor>(cursor, current),
      shortcuts: widget.shortcuts,
      onShowFocusHighlight: (on) => _set(WidgetState.focused, on && enabled),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _activate),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: _activate,
        ),
        ...?widget.actions,
      },
      child: node,
    );
    if (widget.onKeyEvent != null) {
      node = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: widget.onKeyEvent,
        child: node,
      );
    }
    node = Semantics(
      container: true,
      label: widget.semanticLabel,
      value: widget.semanticValue,
      hint: widget.semanticHint,
      button: widget.button && !widget.link && !widget.tab ? true : null,
      link: widget.link ? true : null,
      role: widget.tab ? SemanticsRole.tab : null,
      // A tab says whether it is the chosen one.
      selected:
          widget.semanticSelected ?? (widget.tab ? widget.selected : null),
      checked: widget.checked,
      mixed: widget.mixed ? true : null,
      toggled: widget.toggled,
      expanded: widget.expanded,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup ? true : null,
      enabled: enabled,
      validationResult: widget.isError
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      onTap: !enabled
          ? null
          : widget.onPressed != null
          ? _press
          : _wait,
      onLongPress: presses ? widget.onLongPress : null,
      child: node,
    );
    return widget.excludeSemantics ? node : MergeSemantics(child: node);
  }
}
