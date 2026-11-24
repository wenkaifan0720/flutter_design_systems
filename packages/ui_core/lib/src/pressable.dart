/// The one pressable every look's controls stand on: the behaviour Material's and Cupertino's buttons share, with no look of
/// its own. A tap and a long press; Enter and Space through the app's
/// shortcuts ([ActivateIntent], [ButtonActivateIntent]); hover, a keyboard
/// focus that shows only when the keyboard moves it; a hit area of at least
/// [RawButton.minimumSize]; one semantics node with the control's role
/// and state. Under it sit a [WidgetStatesController] and a
/// [FocusableActionDetector], and the look's builder gets the
/// `Set<WidgetState>` to resolve its styles against, as
/// [WidgetStateProperty] does.
library;

import 'dart:async';

import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kPressTimeout, kPrimaryMouseButton, kTouchSlop;
import 'package:flutter/semantics.dart'
    show
        ChildSemanticsConfigurationsResult,
        ChildSemanticsConfigurationsResultBuilder,
        SemanticsConfiguration,
        SemanticsRole,
        SemanticsValidationResult;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'internal/focus_visible.dart';
import 'semantics_proxy.dart';

/// Builds a pressable's face for its current [states] (hovered, focused,
/// pressed, disabled, selected, error). [child] is the pressable's own
/// child, passed through so a face that does not change with state is
/// built once.
typedef RawButtonBuilder = Widget Function(
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
/// or a button goes down (a touch or a stylus inside a scroll view waits
/// [kPressTimeout], so a scroll that starts on it does not light it; a mouse
/// does not drag a scroll view, so its press shows at once), and stays at least
/// [minimumPressDuration], so a quick tap, shorter than a frame's worth of
/// the press animation, still shows its press. A drag past [kTouchSlop]
/// lets it go at once: a scroll took the pointer. A long press holds it
/// until the finger lifts.
///
/// It is as large as its face, or [minimumSize]: a `RawTapTargetScope`'s
/// floors reach it only through a `TapTargetPadding` round it. A small icon
/// (16 by 16) under a touch scope stays 16 by 16 to a finger and to a
/// screen reader until it is wrapped:
///
/// ```dart
/// TapTargetPadding(
///   child: RawButton(
///     semanticLabel: 'Play',
///     onPressed: play,
///     builder: (context, states, _) => const SizedBox.square(dimension: 16),
///   ),
/// )
/// ```
///
/// ```dart
/// RawButton(onPressed: () {}, semanticLabel: 'Save', builder: (context, states, child) => Opacity(opacity: states.contains(WidgetState.pressed) ? 0.6 : 1, child: const Text('Save')))
/// ```
class RawButton extends StatefulWidget {
  /// A pressable area drawn by [builder].
  const RawButton({
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
  final RawButtonBuilder builder;

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

  /// Gives an ordinary pressable the button role. A [link], [tab],
  /// checkbox, switch or radio keeps its own role.
  final bool button;

  /// Read as a link rather than a button: it goes somewhere.
  final bool link;

  /// Read as a tab rather than a button: one of a tab bar's, showing its
  /// panel. A screen reader hears it selected or not ([semanticSelected],
  /// else [selected]); a row of them may span its bar where a button keeps
  /// to its content.
  final bool tab;

  /// A screen reader's selected flag, when the control is a choice; null
  /// leaves it out. Defaults to nothing even when [selected] is true.
  ///
  /// A toggle button (a formatting bar's Bold, a pin, a password reveal) says
  /// it here and stays a button, read as a button that is selected, as
  /// `IconButton(isSelected:)` and `SegmentedButton` are. A switch says
  /// [toggled] and a checkbox [checked] instead, and neither is a button.
  ///
  /// [toggled] is no way to say a toggle button is on: Flutter reads it as a
  /// switch everywhere (role switch on the web, a native switch on iOS,
  /// `android.widget.Switch` on Android), and no Flutter flag gives the web's
  /// `aria-pressed`. On the web a selected button is read as the current one
  /// (`aria-current`), which `ToggleButtons` avoids by saying checked; this
  /// button keeps to selected, as `IconButton` does.
  final bool? semanticSelected;

  /// A screen reader's checked flag, for a checkbox or a radio. Null leaves it out.
  final bool? checked;

  /// A checkbox partly ticked.
  final bool mixed;

  /// A screen reader's toggled flag, for a switch. Null leaves it out.
  ///
  /// A switch is not a button, so this drops the button role. A toggle button
  /// says [semanticSelected] instead and keeps it.
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
  State<RawButton> createState() => RawButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<RawButtonBuilder>.has('builder', builder))
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

/// The state of a [RawButton]: [states] is what its builder was last
/// given.
class RawButtonState extends State<RawButton> {
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
  // The focus shown as a browser's :focus-visible shows it: not after a
  // pointer's press (a dialog a click opened, its safe action focused),
  // until a key.
  late final RawFocusShown _focus;

  @override
  void initState() {
    super.initState();
    _focus = RawFocusShown((shown) => _set(WidgetState.focused, shown));
    _controller.addListener(_changed);
    _sync();
  }

  @override
  void didUpdateWidget(RawButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statesController != widget.statesController) {
      (oldWidget.statesController ?? _own)?.removeListener(_changed);
      if (widget.statesController != null) {
        _own?.dispose();
        _own = null;
      }
      _controller.addListener(_changed);
    }
    final before = Set.of(_controller.value);
    _sync();
    // A change the widget brought (selected, disabled, an error) is told to
    // the controller's listeners and onStatesChanged once the frame is
    // built, as one a pointer or the focus brings is told at once.
    if (!setEquals(before, _controller.value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.value = Set.of(_controller.value);
      });
    }
  }

  @override
  void dispose() {
    _pressDelay?.cancel();
    _hold?.cancel();
    _focus.dispose();
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
    if (_scrollMayTake(event.kind)) {
      _pressDelay = Timer(kPressTimeout, _show);
    } else {
      _show();
    }
  }

  // Whether the scroll view round the pressable can still take this pointer
  // for a drag: then the press waits kPressTimeout, as the tap recognizer's
  // tap down does while a drag may win. A mouse is not a drag device
  // (ScrollBehavior.dragDevices), so its press shows at once, as InkWell's
  // splash does.
  bool _scrollMayTake(PointerDeviceKind kind) {
    final scrollable = context.findAncestorStateOfType<ScrollableState>();
    if (scrollable == null) return false;
    final behavior =
        scrollable.widget.scrollBehavior ??
        ScrollConfiguration.of(scrollable.context);
    return behavior.dragDevices.contains(kind);
  }

  void _show() {
    _pressDelay?.cancel();
    _pressDelay = null;
    if (!mounted || _pointer == null) return;
    _heldLongEnough = false;
    _hold?.cancel();
    _hold = Timer(RawButton.minimumPressDuration, () {
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
    if (onPressed == null || !_enabled) return;
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
    if (widget.excludeSemantics) {
      face = ExcludeSemantics(child: face);
    } else if (widget.semanticLabel != null || widget.semanticValue != null) {
      face = _FaceSemantics(
        label: widget.semanticLabel,
        value: widget.semanticValue,
        child: face,
      );
    }
    Widget node = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      // Disabled, it takes no press, as an InkWell with no onTap takes none.
      onTap: widget.onPressed == null || !enabled ? null : _press,
      onLongPress: enabled ? widget.onLongPress : null,
      child: face,
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
      onShowFocusHighlight: (on) => _focus.focused(on && enabled),
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
      button:
          widget.button &&
              !widget.link &&
              !widget.tab &&
              widget.checked == null &&
              !widget.mixed &&
              widget.toggled == null &&
              !widget.inMutuallyExclusiveGroup
          ? true
          : null,
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
      onLongPress: presses && enabled ? widget.onLongPress : null,
      child: node,
    );
    return widget.excludeSemantics ? node : MergeSemantics(child: node);
  }
}

// A label or value explicitly supplied by the button already names that text.
// Keep other content, such as a subtitle that changes independently.
class _FaceSemantics extends SingleChildRenderObjectWidget {
  const _FaceSemantics({
    required this.label,
    required this.value,
    required super.child,
  });
  final String? label;
  final String? value;

  @override
  _RenderFaceSemantics createRenderObject(BuildContext context) =>
      _RenderFaceSemantics(label: label, value: value);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFaceSemantics renderObject,
  ) {
    renderObject
      ..label = label
      ..value = value;
  }
}

// What a RawButton given its own words puts round its face. A word the face
// shows that repeats the button's label or value is dropped from what a
// screen reader hears, so the button's name is read once; the face's other
// words (a subtitle) stay.
class _RenderFaceSemantics extends RenderSemanticsProxy {
  _RenderFaceSemantics({String? label, String? value}) {
    _label = label;
    _value = value;
  }

  String? get label => _label;
  String? _label;
  set label(String? value) {
    if (_label == value) return;
    _label = value;
    markNeedsSemanticsUpdate();
  }

  String? get value => _value;
  String? _value;
  set value(String? value) {
    if (_value == value) return;
    _value = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.childConfigurationsDelegate = _merge;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('value', value, defaultValue: null));
  }

  ChildSemanticsConfigurationsResult _merge(
    List<SemanticsConfiguration> children,
  ) {
    final result = ChildSemanticsConfigurationsResultBuilder();
    for (final child in children) {
      final text = child.label;
      if (text.isNotEmpty && (text == _label || text == _value)) {
        result.markAsMergeUp(child.copy()..label = '');
      } else {
        result.markAsMergeUp(child);
      }
    }
    return result.build();
  }
}
