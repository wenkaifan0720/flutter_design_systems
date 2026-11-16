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

import 'dart:async';

import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kPressTimeout, kPrimaryMouseButton, kTouchSlop;
import 'package:flutter/semantics.dart'
    show SemanticsRole, SemanticsValidationResult;
import 'package:flutter/foundation.dart';
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
/// [WidgetState.pressed] comes from the pointer itself, as soon as a finger
/// or a button goes down (after [kPressTimeout] inside a scroll view, so a
/// scroll that starts on it does not light it), and stays at least
/// [minimumPressDuration], so a quick tap, shorter than a frame's worth of
/// the press animation, still shows its press. A drag past [kTouchSlop]
/// lets it go at once: a scroll took the pointer. A long press holds it
/// until the finger lifts.
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

  /// Its focus node, when the caller moves focus itself.
  ///
  /// {@template design.focusNode}
  /// A focus node given is the caller's, who disposes it: the part never
  /// does. Given none, the part makes its own and disposes it.
  /// {@endtemplate}
  final FocusNode? focusNode;

  /// {@template design.autofocus}
  /// Whether it takes focus when it first appears, as [Focus.autofocus]
  /// does: one part on a route asks for it.
  /// {@endtemplate}
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

  /// The least time [WidgetState.pressed] stays in the states once a
  /// press shows, however quick the tap: long enough for a look's press
  /// animation to be seen.
  static const Duration minimumPressDuration = kPressTimeout;

  @override
  State<DesignPressable> createState() => DesignPressableState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<DesignPressableBuilder>.has('builder', builder))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(ObjectFlagProperty<VoidCallback>.has('onLongPress', onLongPress))
      ..add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: null))
      ..add(
        FlagProperty(
          'selected',
          value: selected,
          ifTrue: 'selected',
          defaultValue: false,
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
        DiagnosticsProperty<WidgetStatesController>(
          'statesController',
          statesController,
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
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      )
      ..add(
        DiagnosticsProperty<MouseCursor>(
          'mouseCursor',
          mouseCursor,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Size>(
          'minimumSize',
          minimumSize,
          defaultValue: Size.zero,
        ),
      )
      ..add(
        DiagnosticsProperty<Map<ShortcutActivator, Intent>>(
          'shortcuts',
          shortcuts,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Map<Type, Action<Intent>>>(
          'actions',
          actions,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<
          KeyEventResult Function(FocusNode node, KeyEvent event)
        >.has('onKeyEvent', onKeyEvent),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<Set<WidgetState>>>.has(
          'onStatesChanged',
          onStatesChanged,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(StringProperty('semanticValue', semanticValue, defaultValue: null))
      ..add(StringProperty('semanticHint', semanticHint, defaultValue: null))
      ..add(
        FlagProperty(
          'button',
          value: button,
          ifFalse: 'button: false',
          defaultValue: true,
        ),
      )
      ..add(
        FlagProperty('link', value: link, ifTrue: 'link', defaultValue: false),
      )
      ..add(FlagProperty('tab', value: tab, ifTrue: 'tab', defaultValue: false))
      ..add(
        DiagnosticsProperty<bool>(
          'semanticSelected',
          semanticSelected,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<bool>('checked', checked, defaultValue: null))
      ..add(
        FlagProperty(
          'mixed',
          value: mixed,
          ifTrue: 'mixed',
          defaultValue: false,
        ),
      )
      ..add(DiagnosticsProperty<bool>('toggled', toggled, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('expanded', expanded, defaultValue: null))
      ..add(
        FlagProperty(
          'inMutuallyExclusiveGroup',
          value: inMutuallyExclusiveGroup,
          ifTrue: 'inMutuallyExclusiveGroup',
          defaultValue: false,
        ),
      )
      ..add(
        FlagProperty(
          'excludeSemantics',
          value: excludeSemantics,
          ifTrue: 'excludeSemantics',
          defaultValue: false,
        ),
      )
      ..add(
        FlagProperty(
          'enableFeedback',
          value: enableFeedback,
          ifFalse: 'enableFeedback: false',
          defaultValue: true,
        ),
      );
  }
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

  // The pointer pressing it, from its down to its up or cancel.
  int? _pointer;
  Offset? _downAt;
  // Shows the press once a finger has held still in a scroll view.
  Timer? _pressDelay;
  // Lets the press go once it has shown for minimumPressDuration.
  Timer? _hold;
  // Whether the press has shown long enough to be let go.
  bool _heldLongEnough = false;
  // Whether the pointer lifted while the press still had to show.
  bool _lifted = false;

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
    _pressDelay?.cancel();
    _hold?.cancel();
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
      if (!_presses || !_enabled) WidgetState.pressed,
      if (!widget.selected) WidgetState.selected,
      if (!widget.isError) WidgetState.error,
    });
    if (!_presses || !_enabled) _forget();
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

  // The pointer's press, from the pointer itself rather than the tap
  // recognizer, whose tap down comes with its tap up when the tap is quicker
  // than kPressTimeout and anything else wants the pointer (a scroll view,
  // a long press): the face would never be built pressed.
  void _down(PointerDownEvent event) {
    if (_pointer != null || !_presses || !_enabled) return;
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons != kPrimaryMouseButton) {
      return;
    }
    _pointer = event.pointer;
    _downAt = event.position;
    _lifted = false;
    if (context.findAncestorStateOfType<ScrollableState>() != null) {
      _pressDelay = Timer(kPressTimeout, _show);
    } else {
      _show();
    }
  }

  void _show() {
    _pressDelay?.cancel();
    _pressDelay = null;
    if (!mounted || _pointer == null) return;
    _heldLongEnough = false;
    _hold?.cancel();
    _hold = Timer(DesignPressable.minimumPressDuration, () {
      _heldLongEnough = true;
      if (_lifted) _forget();
    });
    _set(WidgetState.pressed, true);
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    if ((event.position - _downAt!).distance > kTouchSlop) _forget();
  }

  void _up(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _lifted = true;
    // A quick tap in a scroll view lifts before its press showed: show it
    // now, for its least time.
    if (_pressDelay != null) _show();
    if (_heldLongEnough) _forget();
  }

  void _cancel(PointerCancelEvent event) {
    if (event.pointer == _pointer) _forget();
  }

  // Lets the press go, and the pointer.
  void _forget() {
    _pressDelay?.cancel();
    _pressDelay = null;
    _hold?.cancel();
    _hold = null;
    _pointer = null;
    _downAt = null;
    _lifted = false;
    if (mounted && _controller.value.contains(WidgetState.pressed)) {
      _controller.update(WidgetState.pressed, false);
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
        (presses && enabled ? SystemMouseCursors.click : MouseCursor.defer);
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
      onTap: widget.onPressed == null ? null : _press,
      onLongPress: widget.onLongPress,
      child: widget.excludeSemantics ? ExcludeSemantics(child: face) : face,
    );
    // The press from the pointer, beside the recognizers rather than in
    // their arena (as forui's FTappable does), so a tap quicker than
    // kPressTimeout still shows it.
    node = Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: presses && enabled ? _down : null,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: node,
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
