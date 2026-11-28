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

import 'internal/kept_clear.dart';
import 'internal/panes.dart';
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
  /// runs ([MediaQueryData.accessibleNavigation], which the web turns on
  /// with its semantics), as Material's does; one without an action still
  /// leaves after its time.
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
/// hovered (a pointer moved onto it; one it rises under, resting on the key
/// just pressed, does not count) nor holding focus. [focusShortcut] (F6)
/// moves focus to the newest toast; Escape there dismisses it and focus goes
/// back where it was.
///
/// At a desk a pane can hold a toaster of its own, as Material scopes a
/// `ScaffoldMessenger` round a pane: round a list/detail's detail, its
/// toasts stand in that pane, centred on it and above the parts it keeps
/// clear ([RawToasterKeepClear] keeps a part clear of the nearest toaster),
/// rather than centred on the window over both panes. [RawToaster.of] from
/// inside the pane finds the pane's; the rest of the app keeps the app's,
/// which the pane's kept parts do not lift.
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

  /// Whether a pointer moved over the stack pauses every shown toast's time.
  final bool pauseOnHover;

  /// Whether focus in the stack pauses every shown toast's time.
  final bool pauseOnFocus;

  /// Which way a toast swipes away; [DismissDirection.none] turns it off.
  final DismissDirection swipeDirection;

  /// The key that moves focus to the newest toast; null for none.
  final ShortcutActivator? focusShortcut;

  /// The presence spring's damping ratio (ζ); critically damped under
  /// Reduce Motion ([RawMotionPolicy]).
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
  // The F6 cycle the toaster's toasts are a pane of.
  final GlobalKey<PaneCycleState> _cycle = GlobalKey();

  // Where the parts kept clear stand in the toaster ([RawToasterKeepClear]),
  // each part's rect in a box [_keptSize] large, and the bands they keep
  // clear along its edges ([_keptBands]); [_area] carries the top and bottom
  // bands to the surfaces opened below.
  final Map<Object, _KeptPart> _kept = {};
  Size _keptSize = Size.zero;
  EdgeInsets _clear = EdgeInsets.zero;
  final KeptClear _area = KeptClear();

  void _keepClear(Object part, _KeptPart kept, RenderBox area) {
    _area.box = area;
    if (_kept[part] == kept && _keptSize == area.size) return;
    _kept[part] = kept;
    _keptSize = area.size;
    _clearChanged();
  }

  void _letGo(Object part) {
    if (_kept.remove(part) != null) _clearChanged();
  }

  void _clearChanged() {
    final parts = _kept.values.toList();
    final clear = _keptBands(parts, _keptSize);
    _area.update(
      top: clear.top,
      bottom: clear.bottom,
      floor: _keptBands(parts, _keptSize, floor: true).bottom,
    );
    if (clear == _clear) return;
    _clear = clear;
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
    if (!changed) return;
    _remeasure();
    setState(() {});
  }

  // Reads where each kept part stands now, before a toast shows: a part that
  // moved with no layout or paint of its own (its page in a repaint boundary
  // under a transform) still says where it stood.
  void _remeasure() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) return;
    for (final part in _kept.keys.toList()) {
      if (part is _RenderKeepClear) part._report();
    }
  }

  SpringDescription _spring() => RawMotionPolicy.of(context)
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
      duration: rawReduceMotionOf(context) ? Duration.zero : _swipeResize,
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
    _area.dispose();
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
    // A pointer moved over the stack pauses it, as Radix's toast viewport
    // pauses on a pointer's move: a toast that rises under a resting pointer
    // (on the key just pressed) is not hovered, and runs its time.
    stack = MouseRegion(
      onHover: (_) {
        if (_hovered) return;
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
    Widget app = KeptClearScope(area: _area, child: widget.child);
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
    // Shown, the toasts are one of F6's panes, entered at the newest.
    stack = Pane(debugLabel: 'RawToaster', enter: _focusNewest, child: stack);
    // The region stays mounted when empty: an unmounted MouseRegion never
    // reports its exit, and the next toast would wait out a stale hover.
    final toaster = Stack(
      children: [
        app,
        Positioned.fill(
          child: SafeArea(
            // A part kept clear takes the safe inset on its edge.
            minimum: _clear,
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
    // F6 and Shift+F6 cycle the panes: the toasts, and a shell's below.
    return PaneCycle(key: _cycle, child: toaster);
  }
}

/// The edge of a [RawToaster] a part kept clear stands along
/// ([RawToasterKeepClear.edge]).
enum RawKeepClearEdge {
  /// The top: the toasts stand below it.
  top,

  /// The bottom: the toasts stand above it.
  bottom,

  /// The start in reading order (the left in left-to-right text): the toasts
  /// stand beside it, centred on what is left.
  start,

  /// The end in reading order.
  end,
}

/// Keeps the nearest [RawToaster]'s toasts clear of [child]: a bar along
/// the bottom (a tab bar, a bottom app bar, a docked composer) keeps them
/// above it, and one along the top keeps them below it, as Material's
/// `Scaffold` keeps a snackbar above its bottom navigation bar. With an
/// [edge] it keeps them off that edge whatever it reaches: a rail or a
/// sidebar along the start keeps them beside it, so they centre on the page
/// rather than the window. It reads where [child] stands in the toaster each
/// frame it is laid out or painted, and while its route moves (a page
/// pushed over it, or popped back to it), so the toasts follow a bar that
/// springs in or away, and lets go as it leaves the tree. It lets go too
/// while tickers are off where it stands ([TickerMode]): on a route an
/// opaque one covers, as the [Overlay] turns them off there, and in a hidden
/// branch of a shell; it keeps clear again as they come back on. A route
/// under one that is not opaque (a dialog) keeps its bar in sight, and its
/// toasts clear of it.
///
/// Without an [edge], a part that stands on one kept clear along the bottom
/// (its bottom on that one's top, the two overlapping across), as a page's
/// foot stands on a status line or a tab bar, keeps the toasts above both,
/// as `Scaffold` keeps a snackbar above its footer buttons and those above
/// its bottom navigation bar; chains of bars and feet stack, and along the
/// top a part hanging under a kept top bar keeps top toasts below both. A
/// part that floats over the band with a gap, or reaches neither edge with
/// nothing kept under or over it, keeps nothing clear; so does a part
/// reaching both edges, or both bands. The covered edge takes the place of
/// the screen's safe inset there (a bar takes that inset itself);
/// [RawToaster.padding] stays between the band and the toasts.
///
/// A surface opened over the page (a popover, a menu, a select's list)
/// prefers the side of its anchor where it stays clear of the parts kept
/// clear along the top and bottom: a calendar under a date field near a
/// phone's tab bar opens above the field when it fits there. Where neither
/// side holds it, it may cover them. `RawAdaptiveShell` keeps its bar clear
/// along the bottom, its top header along the top and its rail or sidebar
/// along the start.
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
  const RawToasterKeepClear({super.key, this.edge, super.child});

  /// The edge it stands along; null: the top or the bottom, read from where
  /// it stands.
  final RawKeepClearEdge? edge;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderKeepClear(
    RawToaster.maybeOf(context),
    TickerMode.valuesOf(context).enabled,
    edge,
    Directionality.maybeOf(context) ?? TextDirection.ltr,
    ModalRoute.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderKeepClear)
      ..toaster = RawToaster.maybeOf(context)
      ..onstage = TickerMode.valuesOf(context).enabled
      ..edge = edge
      ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr
      ..route = ModalRoute.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      EnumProperty<RawKeepClearEdge>('edge', edge, defaultValue: null),
    );
  }
}

// The side of the toaster a part is kept along, resolved from its edge.
enum _Side { top, bottom, left, right }

@immutable
class _KeptPart {
  const _KeptPart(this.rect, this.side, {this.raised = false});

  final Rect rect;

  // Null: read from where it stands.
  final _Side? side;

  // Whether it stands on a popup (a sheet's own foot), not on a page.
  final bool raised;

  @override
  bool operator ==(Object other) =>
      other is _KeptPart &&
      other.rect == rect &&
      other.side == side &&
      other.raised == raised;

  @override
  int get hashCode => Object.hash(rect, side, raised);
}

class _RenderKeepClear extends RenderProxyBox {
  _RenderKeepClear(
    this._toaster,
    this._onstage,
    this._edge,
    this._textDirection,
    this._route,
  );

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

  RawKeepClearEdge? _edge;
  set edge(RawKeepClearEdge? value) {
    if (value == _edge) return;
    _edge = value;
    _measure();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    _measure();
  }

  // Its route, whose transitions move it under a transform that may lay out
  // and paint nothing in it (a page sits in a repaint boundary).
  ModalRoute<Object?>? _route;
  set route(ModalRoute<Object?>? value) {
    if (identical(value, _route)) return;
    if (attached) _listen(_route, false);
    _route = value;
    if (attached) _listen(value, true);
  }

  void _listen(ModalRoute<Object?>? route, bool on) {
    for (final animation in [route?.animation, route?.secondaryAnimation]) {
      if (on) {
        animation?.addListener(_measure);
      } else {
        animation?.removeListener(_measure);
      }
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
    final ltr = _textDirection == TextDirection.ltr;
    final side = switch (_edge) {
      null => null,
      RawKeepClearEdge.top => _Side.top,
      RawKeepClearEdge.bottom => _Side.bottom,
      RawKeepClearEdge.start => ltr ? _Side.left : _Side.right,
      RawKeepClearEdge.end => ltr ? _Side.right : _Side.left,
    };
    toaster._keepClear(
      this,
      _KeptPart(rect, side, raised: _route is PopupRoute),
      area,
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
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _listen(_route, true);
  }

  @override
  void detach() {
    _listen(_route, false);
    _toaster?._letGo(this);
    super.detach();
  }
}

// The bands along the edges of a toaster [size] large that the parts kept
// clear keep its toasts out of. A part with an edge of its own makes a band
// along that edge to its far side. A part without one, reaching the top or
// the bottom and not the other, makes a band to its far side; a part
// reaching neither that stands on a part of the bottom band (its bottom on
// that one's top, the two overlapping across) joins the band, as Material's
// Scaffold keeps a snackbar above its footer buttons and those above its
// navigation bar; along the top, one hanging under a part of the top band
// joins that. Chains repeat. A part that would join both (a rail between a
// kept top bar and a kept status line), like a part reaching both edges,
// keeps nothing clear.
//
// With [floor], the band a sheet stands on: the bottom band's bars, those
// reaching the bottom edge (with an edge of their own or not), and the feet
// chained on them; a part with an edge that floats over them (a key), and a
// part on a popup (a sheet's own foot), are left out.
EdgeInsets _keptBands(
  List<_KeptPart> allParts,
  Size size, {
  bool floor = false,
}) {
  final parts = floor
      ? [
          for (final p in allParts)
            if (!p.raised) p,
        ]
      : allParts;
  final height = size.height;
  bool meets(double a, double b) => (a - b).abs() <= 0.5;
  bool across(Rect a, Rect b) =>
      math.min(a.right, b.right) - math.max(a.left, b.left) > 0.5;
  bool atTop(Rect r) => r.top <= 0.5;
  bool atBottom(Rect r) => r.bottom >= height - 0.5;
  // The parts of the bottom band ([bottom]) or the top one, [skip] aside.
  Set<int> band({required bool bottom, Set<int> skip = const {}}) {
    final reached = {
      for (var i = 0; i < parts.length; i++)
        if (switch (parts[i].side) {
          null =>
            bottom
                ? atBottom(parts[i].rect) && !atTop(parts[i].rect)
                : atTop(parts[i].rect) && !atBottom(parts[i].rect),
          _Side.bottom => bottom && (!floor || atBottom(parts[i].rect)),
          _Side.top => !bottom,
          _Side.left || _Side.right => false,
        })
          i,
    };
    for (var grew = true; grew;) {
      grew = false;
      for (var i = 0; i < parts.length; i++) {
        final r = parts[i].rect;
        if (parts[i].side != null) continue;
        if (reached.contains(i) || skip.contains(i)) continue;
        if (atTop(r) || atBottom(r)) continue;
        if (reached.any((j) {
          final kept = parts[j].rect;
          return across(r, kept) &&
              (bottom ? meets(r.bottom, kept.top) : meets(r.top, kept.bottom));
        })) {
          reached.add(i);
          grew = true;
        }
      }
    }
    return reached;
  }

  var low = band(bottom: true);
  var high = band(bottom: false);
  final both = low.intersection(high);
  if (both.isNotEmpty) {
    low = band(bottom: true, skip: both);
    high = band(bottom: false, skip: both);
  }
  var top = 0.0;
  var bottom = 0.0;
  for (final i in high) {
    top = math.max(top, parts[i].rect.bottom.clamp(0.0, height));
  }
  for (final i in low) {
    bottom = math.max(bottom, (height - parts[i].rect.top).clamp(0.0, height));
  }
  var left = 0.0;
  var right = 0.0;
  for (final part in parts) {
    if (part.side == _Side.left) {
      left = math.max(left, part.rect.right.clamp(0.0, size.width));
    } else if (part.side == _Side.right) {
      right = math.max(
        right,
        (size.width - part.rect.left).clamp(0.0, size.width),
      );
    }
  }
  return EdgeInsets.fromLTRB(left, top, right, bottom);
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
