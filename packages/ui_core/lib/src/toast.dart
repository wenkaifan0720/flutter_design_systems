/// Toasts, headless: a queue with stacking, per-toast timers that pause on
/// hover and focus, swipe and Escape to dismiss, a key that jumps focus to
/// the newest toast and back, and a live-region announcement. The look
/// paints each toast from a [DesignToastDetails].
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'localizations.dart';
import 'motion.dart';

/// Why a toast left.
enum DesignToastClosedReason {
  /// Its time ran out.
  timeout,

  /// Its action ran.
  action,

  /// It was dismissed: its close control, Escape, a screen reader's dismiss
  /// or [DesignToasterState.dismiss].
  dismissed,

  /// It was swiped away.
  swiped,

  /// [DesignToasterState.clear] removed it, shown or waiting.
  cleared,
}

/// What a toast says and does. The look reads the fields it paints; [data]
/// carries anything else it needs (a tone, an icon).
@immutable
class DesignToast {
  /// A toast reading [message].
  const DesignToast({
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
    this.duration = const Duration(seconds: 4),
    this.id,
    this.data,
  });

  /// The text, and what a screen reader announces.
  final String message;

  /// A heading above [message], when it has one.
  final String? title;

  /// The action's label ("Undo"), when it has one.
  final String? actionLabel;

  /// What the action does. The toast closes after it runs.
  final VoidCallback? onAction;

  /// How long it stays once shown, while not paused. Null: until dismissed.
  /// A toast with an action stays until dismissed while a screen reader
  /// runs ([MediaQueryData.accessibleNavigation]), as Material's does.
  final Duration? duration;

  /// Showing a toast with the [id] of one already shown or waiting replaces
  /// it in place, its time restarted.
  final Object? id;

  /// Anything else the look paints from.
  final Object? data;

  /// Whether it carries an action.
  bool get hasAction => actionLabel != null && onAction != null;
}

/// A shown or waiting toast, as [DesignToasterState.show] returns it.
class DesignToastHandle {
  DesignToastHandle._(this._record);

  final _ToastRecord _record;

  /// The toast's id: its own [DesignToast.id], or one the toaster made.
  Object get id => _record.id;

  /// Completes with why the toast left.
  Future<DesignToastClosedReason> get closed => _record.completer.future;

  /// Dismisses it, shown or waiting.
  void dismiss() =>
      _record.owner?._close(_record, DesignToastClosedReason.dismissed);
}

/// What the look's [DesignToaster.toastBuilder] paints one toast from.
@immutable
class DesignToastDetails {
  /// The details of [toast]; the toaster makes these.
  const DesignToastDetails({
    required this.toast,
    required this.index,
    required this.count,
    required this.animation,
    required this.remaining,
    required this.paused,
    required this.exiting,
    required this.focused,
    required this.dismiss,
    required this.runAction,
  });

  /// The toast.
  final DesignToast toast;

  /// Its place among the shown toasts, oldest first (0).
  final int index;

  /// How many toasts are shown.
  final int count;

  /// 0 to 1 as it enters, 1 to 0 as it leaves; on a spring, so it can
  /// overshoot 1 (never under Reduce Motion): clamp it before an
  /// `Opacity`, which asserts outside 0 to 1. A swiped toast goes to 0 as
  /// its slot closes, so a stack that places toasts by it moves the others
  /// up with it.
  final Animation<double> animation;

  /// The share of its time left, 1 to 0, in steps of
  /// [DesignToaster.tick]; stays at 1 for a toast without a time. A look
  /// that draws it as a bar smooths it itself.
  final ValueListenable<double> remaining;

  /// Whether its time is paused (hover, focus, or a screen reader holding
  /// an action toast).
  final bool paused;

  /// Whether it is leaving (timed out, dismissed, acted on, or swiped
  /// away).
  final bool exiting;

  /// Whether the keyboard moved focus to it ([DesignToaster.focusShortcut]),
  /// for its focus ring.
  final bool focused;

  /// Dismisses it: for its close control.
  final VoidCallback dismiss;

  /// Runs its action and closes it; null when it has none.
  final VoidCallback? runAction;

  /// Whether it is the newest shown.
  bool get isNewest => index == count - 1;
}

/// Paints one toast.
typedef DesignToastBuilder = Widget Function(
  BuildContext context,
  DesignToastDetails details,
);

/// Lays out the shown toasts, oldest first.
typedef DesignToastStackBuilder = Widget Function(
  BuildContext context,
  List<Widget> toasts,
);

/// Hosts toasts over [child]: put it above the app's navigator
/// (`WidgetsApp.builder`), then call [DesignToaster.of] and
/// [DesignToasterState.show] from anywhere below.
///
/// At most [maxVisible] show at once, oldest first; the rest wait their turn
/// in order. Each shown toast's time runs only while the stack is neither
/// hovered nor holding focus. [focusShortcut] (F6) moves focus to the newest
/// toast; Escape there dismisses it and focus goes back where it was.
///
/// ```dart
/// DesignToaster(toastBuilder: (context, details) => Text(details.toast.message), child: const SizedBox())
/// ```
class DesignToaster extends StatefulWidget {
  /// A toaster over [child].
  const DesignToaster({
    super.key,
    required this.child,
    required this.toastBuilder,
    this.stackBuilder,
    this.maxVisible = 3,
    this.alignment = AlignmentDirectional.bottomCenter,
    this.padding = const EdgeInsets.all(16),
    this.constraints = const BoxConstraints(maxWidth: 560),
    this.pauseOnHover = true,
    this.pauseOnFocus = true,
    this.swipeDirection = DismissDirection.horizontal,
    this.focusShortcut = const SingleActivator(LogicalKeyboardKey.f6),
    this.dampingRatio = 1,
    this.stiffness = 700,
    this.regionLabel,
    this.tick = const Duration(milliseconds: 100),
  }) : assert(maxVisible > 0);

  /// The app the toasts float over.
  final Widget child;

  /// Paints one toast.
  final DesignToastBuilder toastBuilder;

  /// Lays out the shown toasts; null stacks them in a column, oldest first.
  final DesignToastStackBuilder? stackBuilder;

  /// How many show at once; 1 is a snackbar's queue.
  final int maxVisible;

  /// Where the stack sits.
  final AlignmentGeometry alignment;

  /// Space between the stack and the screen's edge (inside the safe area).
  final EdgeInsetsGeometry padding;

  /// The stack's size limits.
  final BoxConstraints constraints;

  /// Whether a pointer over the stack pauses every shown toast's time.
  final bool pauseOnHover;

  /// Whether focus in the stack pauses every shown toast's time.
  final bool pauseOnFocus;

  /// Which way a toast swipes away; [DismissDirection.none] turns it off.
  final DismissDirection swipeDirection;

  /// The key that moves focus to the newest toast; null for none.
  final ShortcutActivator? focusShortcut;

  /// The presence spring's damping ratio (ζ); critically damped under
  /// Reduce Motion ([DesignMotionPolicy]).
  final double dampingRatio;

  /// The presence spring's stiffness (k).
  final double stiffness;

  /// What a screen reader calls the stack while it holds a toast; an empty
  /// stack is silent, so no screen stops on it. Null:
  /// [DesignLocalizations.toasterRegionLabel].
  final String? regionLabel;

  /// How finely a toast's time is counted.
  final Duration tick;

  /// The nearest toaster's state.
  static DesignToasterState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'No DesignToaster above this context.');
    return state!;
  }

  /// The nearest toaster's state, or null.
  static DesignToasterState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<DesignToasterState>();

  @override
  State<DesignToaster> createState() => DesignToasterState();
}

class _ToastRecord {
  _ToastRecord(this.id, this.toast, this.owner);

  final Object id;
  DesignToast toast;
  DesignToasterState? owner;
  final completer = Completer<DesignToastClosedReason>();
  final focusNode = FocusNode(debugLabel: 'DesignToast');
  AnimationController? presence;
  // The clock: a periodic tick while it runs, counted into [elapsed]. Not a
  // Ticker, which would draw a frame every vsync for the whole duration,
  // and not a stopwatch, which a test's fake clock cannot drive.
  Timer? ticker;
  Duration elapsed = Duration.zero;
  final remaining = ValueNotifier<double>(1);
  bool shown = false;
  bool exiting = false;
  // Swiped out and its slot closing; it leaves when the slot has.
  bool swiped = false;
  bool focused = false;

  void dispose() {
    ticker?.cancel();
    presence?.dispose();
    remaining.dispose();
    focusNode.dispose();
  }
}

class _JumpToToastIntent extends Intent {
  const _JumpToToastIntent();
}

/// The state of a [DesignToaster]: show and dismiss toasts through it.
class DesignToasterState extends State<DesignToaster>
    with TickerProviderStateMixin {
  final List<_ToastRecord> _shown = [];
  final List<_ToastRecord> _waiting = [];
  int _nextId = 0;
  bool _hovered = false;
  bool _focused = false;
  FocusNode? _returnFocus;

  /// How many toasts are shown, leaving ones included.
  int get shownCount => _shown.length;

  /// How many toasts wait for a place.
  int get waitingCount => _waiting.length;

  /// Whether the shown toasts' time is paused.
  bool get paused =>
      (widget.pauseOnHover && _hovered) || (widget.pauseOnFocus && _focused);

  /// Shows [toast], or queues it while [DesignToaster.maxVisible] are shown.
  /// A toast whose [DesignToast.id] matches one shown or waiting replaces
  /// that one in place.
  DesignToastHandle show(DesignToast toast) {
    final id = toast.id;
    if (id != null) {
      for (final record in [..._shown, ..._waiting]) {
        if (record.id == id && !record.exiting) {
          setState(() => record.toast = toast);
          if (record.shown) _restartTimer(record);
          return DesignToastHandle._(record);
        }
      }
    }
    final record = _ToastRecord(id ?? _ToastId(_nextId++), toast, this);
    _waiting.add(record);
    _promote();
    return DesignToastHandle._(record);
  }

  /// Dismisses the toast with [id], shown or waiting.
  void dismiss(Object id) {
    for (final record in [..._shown, ..._waiting]) {
      if (record.id == id) _close(record, DesignToastClosedReason.dismissed);
    }
  }

  /// Removes every toast, shown and waiting.
  void clear() {
    for (final record in [..._waiting]) {
      _close(record, DesignToastClosedReason.cleared);
    }
    for (final record in [..._shown]) {
      _close(record, DesignToastClosedReason.cleared);
    }
  }

  void _promote() {
    if (!mounted) return;
    var changed = false;
    // A leaving toast keeps its place until it is gone.
    while (_waiting.isNotEmpty && _shown.length < widget.maxVisible) {
      final record = _waiting.removeAt(0);
      record.presence = AnimationController.unbounded(vsync: this);
      record.shown = true;
      _shown.add(record);
      record.presence!.springTo(1, _spring());
      _restartTimer(record);
      changed = true;
    }
    if (changed) setState(() {});
  }

  SpringDescription _spring() => DesignMotionPolicy.of(context)
      .spatial(dampingRatio: widget.dampingRatio, stiffness: widget.stiffness);

  bool _held(_ToastRecord record) {
    final duration = record.toast.duration;
    if (duration == null) return true;
    final reader = MediaQuery.maybeAccessibleNavigationOf(context) ?? false;
    return reader && record.toast.hasAction;
  }

  void _restartTimer(_ToastRecord record) {
    record.ticker?.cancel();
    record.ticker = null;
    record.elapsed = Duration.zero;
    record.remaining.value = 1;
    _runTimer(record);
  }

  void _runTimer(_ToastRecord record) {
    if (!record.shown ||
        record.exiting ||
        record.swiped ||
        paused ||
        _held(record)) {
      record.ticker?.cancel();
      record.ticker = null;
      return;
    }
    record.ticker ??= Timer.periodic(widget.tick, (_) => _onTick(record));
  }

  void _onTick(_ToastRecord record) {
    final duration = record.toast.duration;
    if (duration == null || record.exiting) return;
    record.elapsed += widget.tick;
    final left = 1 - record.elapsed.inMicroseconds / duration.inMicroseconds;
    record.remaining.value = left.clamp(0.0, 1.0);
    if (record.elapsed >= duration) {
      record.ticker?.cancel();
      record.ticker = null;
      _close(record, DesignToastClosedReason.timeout);
    }
  }

  void _syncTimers() {
    for (final record in _shown) {
      _runTimer(record);
    }
  }

  void _close(_ToastRecord record, DesignToastClosedReason reason) {
    if (record.completer.isCompleted) return;
    record.completer.complete(reason);
    if (_waiting.remove(record)) {
      record.owner = null;
      record.dispose();
      return;
    }
    if (!_shown.contains(record) || !mounted) return;
    final hadFocus = record.focusNode.hasFocus;
    record.exiting = true;
    record.ticker?.cancel();
    record.ticker = null;
    if (reason == DesignToastClosedReason.swiped) {
      // A dismissed Dismissible must leave the tree in this frame.
      _remove(record);
    } else {
      setState(() {});
      record.presence!.springTo(0, _spring()).whenComplete(() {
        if (mounted && _shown.contains(record)) _remove(record);
      });
    }
    if (hadFocus) _restoreFocus();
  }

  // Its swipe has carried it out, and its slot starts to close: it leaves
  // as any toast does, its animation going to 0 as the slot closes.
  void _swipedOut(_ToastRecord record) {
    if (record.exiting || record.swiped) return;
    record.ticker?.cancel();
    record.ticker = null;
    setState(() => record.swiped = true);
    record.presence!.animateTo(
      0,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : _swipeResize,
      curve: _swipeResizeCurve,
    );
  }

  // Dismissible's own: its slot closes over this, on this curve.
  static const _swipeResize = Duration(milliseconds: 300);
  static const _swipeResizeCurve = Interval(0.4, 1, curve: Curves.ease);

  void _remove(_ToastRecord record) {
    setState(() => _shown.remove(record));
    record.owner = null;
    // Disposed after this frame: its presence may still be read.
    WidgetsBinding.instance.addPostFrameCallback((_) => record.dispose());
    _promote();
  }

  void _restoreFocus() {
    final target = _returnFocus;
    _returnFocus = null;
    if (target != null && target.context != null && target.canRequestFocus) {
      target.requestFocus();
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Object? _jump(_JumpToToastIntent intent) {
    final live = _shown.where((r) => !r.exiting).toList();
    if (live.isEmpty) return null;
    final current = FocusManager.instance.primaryFocus;
    final inside = live.any((r) => r.focusNode.hasFocus);
    if (!inside) _returnFocus = current;
    live.last.focusNode.requestFocus();
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A screen reader turning on or off holds or frees action toasts.
    _syncTimers();
  }

  @override
  void didUpdateWidget(DesignToaster oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimers();
    if (widget.maxVisible != oldWidget.maxVisible) _promote();
  }

  @override
  void dispose() {
    for (final record in [..._shown, ..._waiting]) {
      if (!record.completer.isCompleted) {
        record.completer.complete(DesignToastClosedReason.cleared);
      }
      record.dispose();
    }
    super.dispose();
  }

  Widget _toast(BuildContext context, _ToastRecord record, int index) {
    final toast = record.toast;
    VoidCallback? action;
    if (toast.hasAction) {
      action = () {
        if (record.exiting) return;
        toast.onAction!();
        _close(record, DesignToastClosedReason.action);
      };
    }
    final details = DesignToastDetails(
      toast: toast,
      index: index,
      count: _shown.length,
      animation: record.presence!,
      remaining: record.remaining,
      paused: paused || _held(record),
      exiting: record.exiting || record.swiped,
      focused: record.focused,
      dismiss: () => _close(record, DesignToastClosedReason.dismissed),
      runAction: action,
    );
    Widget face = Semantics(
      container: true,
      liveRegion: true,
      onDismiss: record.exiting
          ? null
          : () => _close(record, DesignToastClosedReason.dismissed),
      child: widget.toastBuilder(context, details),
    );
    face = Focus(
      focusNode: record.focusNode,
      onFocusChange: (focused) {
        if (record.focused == focused || !mounted) return;
        setState(() => record.focused = focused);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _close(record, DesignToastClosedReason.dismissed);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: face,
    );
    if (record.exiting) {
      face = IgnorePointer(child: ExcludeFocus(child: face));
    }
    if (widget.swipeDirection != DismissDirection.none && !record.exiting) {
      face = Dismissible(
        key: ValueKey<Object>(record.id),
        direction: widget.swipeDirection,
        resizeDuration: _swipeResize,
        confirmDismiss: (_) async {
          _swipedOut(record);
          return true;
        },
        onDismissed: (_) => _close(record, DesignToastClosedReason.swiped),
        child: face,
      );
    }
    return KeyedSubtree(key: ObjectKey(record), child: face);
  }

  @override
  Widget build(BuildContext context) {
    final toasts = [
      for (var i = 0; i < _shown.length; i++) _toast(context, _shown[i], i),
    ];
    Widget stack =
        widget.stackBuilder?.call(context, toasts) ??
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: toasts,
        );
    stack = Semantics(
      container: true,
      explicitChildNodes: true,
      label: _shown.isEmpty
          ? null
          : widget.regionLabel ??
                DesignLocalizations.of(context).toasterRegionLabel,
      child: stack,
    );
    stack = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (focused) {
        if (_focused == focused) return;
        setState(() => _focused = focused);
        _syncTimers();
      },
      child: stack,
    );
    stack = MouseRegion(
      onEnter: (_) {
        _hovered = true;
        setState(() {});
        _syncTimers();
      },
      onExit: (_) {
        _hovered = false;
        setState(() {});
        _syncTimers();
      },
      child: stack,
    );
    Widget app = widget.child;
    final shortcut = widget.focusShortcut;
    if (shortcut != null) {
      app = Shortcuts(
        shortcuts: {shortcut: const _JumpToToastIntent()},
        child: Actions(
          actions: {
            _JumpToToastIntent: CallbackAction<_JumpToToastIntent>(
              onInvoke: _jump,
            ),
          },
          child: app,
        ),
      );
    }
    // The region stays mounted when empty: an unmounted MouseRegion never
    // reports its exit, and the next toast would wait out a stale hover.
    return Stack(
      children: [
        app,
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: widget.padding,
              child: Align(
                alignment: widget.alignment,
                child: ConstrainedBox(
                  constraints: widget.constraints,
                  child: stack,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastId {
  const _ToastId(this.n);

  final int n;

  @override
  bool operator ==(Object other) => other is _ToastId && other.n == n;

  @override
  int get hashCode => n.hashCode;

  @override
  String toString() => 'toast#$n';
}
