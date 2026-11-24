/// Toasts, headless: a queue with stacking, per-toast timers that pause on
/// hover and focus, swipe and Escape to dismiss, a key that jumps focus to
/// the newest toast and back, and a live-region announcement. The look
/// paints each toast from a [RawToastDetails].
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// 0.3.0 routes
import 'internal/panes.dart';
// 0.3.0 routes end
import 'localizations.dart';
import 'motion.dart';

/// Why a toast left.
enum RawToastClosedReason {
  /// Its time ran out.
  timeout,

  /// Its action ran.
  action,

  /// It was dismissed: its close control, Escape, a screen reader's dismiss
  /// or [RawToasterState.dismiss].
  dismissed,

  /// It was swiped away.
  swiped,

  /// [RawToasterState.clear] removed it, shown or waiting.
  cleared,
}

/// What a toast says and does. The look reads the fields it paints; [data]
/// carries anything else it needs (a tone, an icon).
@immutable
class RawToast {
  /// A toast reading [message].
  const RawToast({
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

/// A shown or waiting toast, as [RawToasterState.show] returns it.
class RawToastController {
  RawToastController._(this._record);

  final _ToastRecord _record;

  /// The toast's id: its own [RawToast.id], or one the toaster made.
  Object get id => _record.id;

  /// Completes with why the toast left.
  Future<RawToastClosedReason> get closed => _record.completer.future;

  /// Dismisses it, shown or waiting.
  void dismiss() =>
      _record.owner?._close(_record, RawToastClosedReason.dismissed);
}

/// What the look's [RawToaster.toastBuilder] paints one toast from.
@immutable
class RawToastDetails {
  /// The details of [toast]; the toaster makes these.
  const RawToastDetails({
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
  final RawToast toast;

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
  /// [RawToaster.tick]; stays at 1 for a toast without a time. A look
  /// that draws it as a bar smooths it itself.
  final ValueListenable<double> remaining;

  /// Whether its time is paused (hover, focus, or a screen reader holding
  /// an action toast).
  final bool paused;

  /// Whether it is leaving (timed out, dismissed, acted on, or swiped
  /// away).
  final bool exiting;

  /// Whether the keyboard moved focus to it ([RawToaster.focusShortcut]),
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
typedef RawToastBuilder = Widget Function(
  BuildContext context,
  RawToastDetails details,
);

/// Lays out the shown toasts, oldest first.
typedef RawToastStackBuilder = Widget Function(
  BuildContext context,
  List<Widget> toasts,
);

/// Hosts toasts over [child]: put it above the app's navigator
/// (`WidgetsApp.builder`), then call [RawToaster.of] and
/// [RawToasterState.show] from anywhere below.
///
/// At most [maxVisible] show at once, oldest first; the rest wait their turn
/// in order. Each shown toast's time runs only while the stack is neither
/// hovered nor holding focus. [focusShortcut] (F6) moves focus to the newest
/// toast; Escape there dismisses it and focus goes back where it was.
///
/// ```dart
/// RawToaster(toastBuilder: (context, details) => Text(details.toast.message), child: const SizedBox())
/// ```
class RawToaster extends StatefulWidget {
  /// A toaster over [child].
  const RawToaster({
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
  }) : assert(dampingRatio > 0 && stiffness > 0),
       assert(maxVisible > 0);

  /// The app the toasts float over.
  final Widget child;

  /// Paints one toast.
  final RawToastBuilder toastBuilder;

  /// Lays out the shown toasts; null stacks them in a column, oldest first.
  final RawToastStackBuilder? stackBuilder;

  /// How many show at once; 1 is a snackbar's queue.
  final int maxVisible;

  /// Where the stack sits.
  final AlignmentGeometry alignment;

  /// Space between the stack and the screen's edge (inside the safe area),
  /// or a bar along that edge that a [RawToasterKeepClear] keeps clear.
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
  /// [RawWidgetsLocalizations.toasterRegionLabel].
  final String? regionLabel;

  /// How finely a toast's time is counted.
  final Duration tick;

  /// The nearest toaster's state.
  static RawToasterState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'No RawToaster above this context.');
    return state!;
  }

  /// The nearest toaster's state, or null.
  static RawToasterState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<RawToasterState>();

  @override
  State<RawToaster> createState() => RawToasterState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<RawToastBuilder>.has('toastBuilder', toastBuilder),
      )
      ..add(
        ObjectFlagProperty<RawToastStackBuilder>.has(
          'stackBuilder',
          stackBuilder,
        ),
      )
      ..add(IntProperty('maxVisible', maxVisible, defaultValue: 3))
      ..add(
        DiagnosticsProperty<AlignmentGeometry>(
          'alignment',
          alignment,
          defaultValue: AlignmentDirectional.bottomCenter,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: const EdgeInsets.all(16),
        ),
      )
      ..add(
        DiagnosticsProperty<BoxConstraints>(
          'constraints',
          constraints,
          defaultValue: const BoxConstraints(maxWidth: 560),
        ),
      )
      ..add(
        FlagProperty(
          'pauseOnHover',
          value: pauseOnHover,
          ifFalse: 'pauseOnHover: false',
          defaultValue: true,
        ),
      )
      ..add(
        FlagProperty(
          'pauseOnFocus',
          value: pauseOnFocus,
          ifFalse: 'pauseOnFocus: false',
          defaultValue: true,
        ),
      )
      ..add(
        DiagnosticsProperty<DismissDirection>(
          'swipeDirection',
          swipeDirection,
          defaultValue: DismissDirection.horizontal,
        ),
      )
      ..add(
        DiagnosticsProperty<ShortcutActivator>(
          'focusShortcut',
          focusShortcut,
          defaultValue: const SingleActivator(LogicalKeyboardKey.f6),
        ),
      )
      ..add(DoubleProperty('dampingRatio', dampingRatio, defaultValue: 1))
      ..add(DoubleProperty('stiffness', stiffness, defaultValue: 700))
      ..add(StringProperty('regionLabel', regionLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<Duration>(
          'tick',
          tick,
          defaultValue: const Duration(milliseconds: 100),
        ),
      );
  }
}

class _ToastRecord {
  _ToastRecord(this.id, this.toast, this.owner);

  final Object id;
  RawToast toast;
  RawToasterState? owner;
  final completer = Completer<RawToastClosedReason>();
  final focusNode = FocusNode(debugLabel: 'RawToast');
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

/// The state of a [RawToaster]: show and dismiss toasts through it.
class RawToasterState extends State<RawToaster> with TickerProviderStateMixin {
  final List<_ToastRecord> _shown = [];
  final List<_ToastRecord> _waiting = [];
  int _nextId = 0;
  bool _hovered = false;
  bool _focused = false;
  FocusNode? _returnFocus;
  // 0.3.0 routes
  // The F6 cycle the toaster's toasts are a pane of.
  final GlobalKey<PaneCycleState> _cycle = GlobalKey();
  // 0.3.0 routes end

  // What the parts kept clear cover of the toaster's top and bottom
  // edges ([RawToasterKeepClear]), each part's, and the most of them.
  final Map<Object, (double, double)> _kept = {};
  double _clearTop = 0;
  double _clearBottom = 0;

  void _keepClear(Object part, double top, double bottom) {
    if (_kept[part] == (top, bottom)) return;
    _kept[part] = (top, bottom);
    _clearChanged();
  }

  void _letGo(Object part) {
    if (_kept.remove(part) != null) _clearChanged();
  }

  void _clearChanged() {
    var top = 0.0;
    var bottom = 0.0;
    for (final (t, b) in _kept.values) {
      top = math.max(top, t);
      bottom = math.max(bottom, b);
    }
    if (top == _clearTop && bottom == _clearBottom) return;
    _clearTop = top;
    _clearBottom = bottom;
    // With nothing shown, the next toast's build reads it.
    if (!mounted || (_shown.isEmpty && _waiting.isEmpty)) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  /// How many toasts are shown, leaving ones included.
  int get shownCount => _shown.length;

  /// How many toasts wait for a place.
  int get waitingCount => _waiting.length;

  /// Whether the shown toasts' time is paused.
  bool get paused =>
      (widget.pauseOnHover && _hovered) || (widget.pauseOnFocus && _focused);

  /// Shows [toast], or queues it while [RawToaster.maxVisible] are shown.
  /// A toast whose [RawToast.id] matches one shown or waiting replaces
  /// that one in place.
  RawToastController show(RawToast toast) {
    final id = toast.id;
    if (id != null) {
      for (final record in [..._shown, ..._waiting]) {
        if (record.id == id && !record.exiting) {
          setState(() => record.toast = toast);
          if (record.shown) _restartTimer(record);
          return RawToastController._(record);
        }
      }
    }
    final record = _ToastRecord(id ?? _ToastId(_nextId++), toast, this);
    _waiting.add(record);
    _promote();
    return RawToastController._(record);
  }

  /// Dismisses the toast with [id], shown or waiting.
  void dismiss(Object id) {
    for (final record in [..._shown, ..._waiting]) {
      if (record.id == id) _close(record, RawToastClosedReason.dismissed);
    }
  }

  /// Removes every toast, shown and waiting.
  void clear() {
    for (final record in [..._waiting]) {
      _close(record, RawToastClosedReason.cleared);
    }
    for (final record in [..._shown]) {
      _close(record, RawToastClosedReason.cleared);
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
      _close(record, RawToastClosedReason.timeout);
    }
  }

  void _syncTimers() {
    for (final record in _shown) {
      _runTimer(record);
    }
  }

  void _close(_ToastRecord record, RawToastClosedReason reason) {
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
    if (reason == RawToastClosedReason.swiped) {
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
      duration: designReduceMotionOf(context) ? Duration.zero : _swipeResize,
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
    // 0.3.0 routes
    // With other panes about (a shell's), F6 cycles through them all.
    final cycle = _cycle.currentState;
    if (cycle != null && cycle.cycles) {
      cycle.move(forward: true);
      return null;
    }
    _focusNewest();
    return null;
  }

  // Focuses the newest toast, remembering where focus was; false with none.
  bool _focusNewest() {
    // 0.3.0 routes end
    final live = _shown.where((r) => !r.exiting).toList();
    if (live.isEmpty) return false;
    final current = FocusManager.instance.primaryFocus;
    final inside = live.any((r) => r.focusNode.hasFocus);
    if (!inside) _returnFocus = current;
    live.last.focusNode.requestFocus();
    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A screen reader turning on or off holds or frees action toasts.
    _syncTimers();
  }

  @override
  void didUpdateWidget(RawToaster oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimers();
    if (widget.maxVisible != oldWidget.maxVisible) _promote();
  }

  @override
  void dispose() {
    for (final record in [..._shown, ..._waiting]) {
      if (!record.completer.isCompleted) {
        record.completer.complete(RawToastClosedReason.cleared);
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
        _close(record, RawToastClosedReason.action);
      };
    }
    final details = RawToastDetails(
      toast: toast,
      index: index,
      count: _shown.length,
      animation: record.presence!,
      remaining: record.remaining,
      paused: paused || _held(record),
      exiting: record.exiting || record.swiped,
      focused: record.focused,
      dismiss: () => _close(record, RawToastClosedReason.dismissed),
      runAction: action,
    );
    Widget face = Semantics(
      container: true,
      liveRegion: true,
      onDismiss: record.exiting
          ? null
          : () => _close(record, RawToastClosedReason.dismissed),
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
          _close(record, RawToastClosedReason.dismissed);
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
        onDismissed: (_) => _close(record, RawToastClosedReason.swiped),
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
                RawWidgetsLocalizations.of(context).toasterRegionLabel,
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
        // The keys alone: no semantics node of its own, which would merge the
        // nodes of what it holds (a heading and the text under it) into one.
        includeSemantics: false,
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
    // 0.3.0 routes
    // Shown, the toasts are one of F6's panes, entered at the newest.
    stack = Pane(debugLabel: 'RawToaster', enter: _focusNewest, child: stack);
    // 0.3.0 routes end
    // The region stays mounted when empty: an unmounted MouseRegion never
    // reports its exit, and the next toast would wait out a stale hover.
    final toaster = Stack(
      children: [
        app,
        Positioned.fill(
          child: SafeArea(
            // A bar kept clear takes the safe inset on its edge.
            minimum: EdgeInsets.only(top: _clearTop, bottom: _clearBottom),
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
    // 0.3.0 routes
    // F6 and Shift+F6 cycle the panes: the toasts, and a shell's below.
    return PaneCycle(key: _cycle, child: toaster);
    // 0.3.0 routes end
  }
}

/// Keeps the nearest [RawToaster]'s toasts clear of [child]: a bar along
/// the bottom (a tab bar, a bottom app bar, a docked composer) keeps them
/// above it, and one along the top keeps them below it, as Material's
/// `Scaffold` keeps a snackbar above its bottom navigation bar. It reads how
/// much of the toaster's bottom or top edge [child] covers each frame it is
/// laid out or painted, so the toasts follow a bar that springs in or away,
/// and lets go as it leaves the tree. It lets go too while tickers are off
/// where it stands ([TickerMode]): on a route an opaque one covers, as the
/// [Overlay] turns them off there, and in a hidden branch of a shell; it
/// keeps clear again as they come back on. A route under one that is not
/// opaque (a dialog) keeps its bar in sight, and its toasts clear of it. A
/// part that reaches neither edge, or
/// both (a rail, a sidebar), keeps nothing clear. The covered edge takes
/// the place of the screen's safe inset there (a bar takes that inset
/// itself); [RawToaster.padding] stays between the bar and the toasts.
/// `DesignAdaptiveShell` keeps its bar clear, and not its rail or sidebar,
/// whatever stands above or below them.
///
/// ```dart
/// Column(
///   children: [
///     const Expanded(child: Text('Messages')),
///     RawToasterKeepClear(
///       child: SafeArea(
///         top: false,
///         child: SizedBox(height: 56, child: Text('Composer')),
///       ),
///     ),
///   ],
/// )
/// ```
class RawToasterKeepClear extends SingleChildRenderObjectWidget {
  /// Keeps the nearest toaster's toasts clear of [child].
  const RawToasterKeepClear({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderKeepClear(
    RawToaster.maybeOf(context),
    TickerMode.valuesOf(context).enabled,
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderKeepClear)
      ..toaster = RawToaster.maybeOf(context)
      ..onstage = TickerMode.valuesOf(context).enabled;
  }
}

class _RenderKeepClear extends RenderProxyBox {
  _RenderKeepClear(this._toaster, this._onstage);

  RawToasterState? _toaster;
  set toaster(RawToasterState? value) {
    if (identical(value, _toaster)) return;
    _toaster?._letGo(this);
    _toaster = value;
    _measure();
  }

  // Whether tickers are on where it stands. Off, it is out of sight (on a
  // covered route, which may still be laid out as it rebuilds): it keeps
  // nothing clear.
  bool _onstage;
  set onstage(bool value) {
    if (value == _onstage) return;
    _onstage = value;
    if (value) {
      _measure();
    } else {
      _toaster?._letGo(this);
    }
  }

  bool _measuring = false;

  // After the frame's layout and paint: where the part stands then.
  void _measure() {
    if (_measuring) return;
    _measuring = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _measuring = false;
      _report();
    });
  }

  void _report() {
    final toaster = _toaster;
    if (!_onstage) return;
    if (toaster == null || !toaster.mounted || !attached || !hasSize) return;
    final area = toaster.context.findRenderObject();
    if (area is! RenderBox || !area.hasSize || !area.attached) return;
    final rect = MatrixUtils.transformRect(
      getTransformTo(area),
      Offset.zero & size,
    );
    final height = area.size.height;
    final top = rect.top <= 0.5;
    final bottom = rect.bottom >= height - 0.5;
    toaster._keepClear(
      this,
      top && !bottom ? rect.bottom.clamp(0.0, height) : 0,
      bottom && !top ? (height - rect.top).clamp(0.0, height) : 0,
    );
  }

  @override
  void performLayout() {
    super.performLayout();
    _measure();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    _measure();
  }

  @override
  void detach() {
    _toaster?._letGo(this);
    super.detach();
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
