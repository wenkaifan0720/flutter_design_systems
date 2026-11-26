/// Swipe actions, headless: a row that slides aside to show actions behind
/// it. Past half the actions it stays open; a full swipe runs the action at
/// the edge. The keyboard opens a side with the arrows (the arrow toward
/// the start shows the end's actions, mirrored right to left) and focuses
/// its first action; Escape closes it, focus back in the row. A screen
/// reader gets every action as a custom action on the row. Rows in one
/// scroll view open one at a time, and its scrolling closes them.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'haptics.dart';
import 'internal/row_actions.dart';
import 'motion.dart';
import 'pressable.dart';

/// Opens and closes a [RawSwipeActions] row from outside, and says
/// whether it is open, as `flutter_slidable`'s controller does. The caller
/// makes it, gives it to one row, and disposes it; with no row it does
/// nothing.
///
/// ```dart
/// RawSwipeActions(controller: controller, endActions: [RawSwipeAction(label: 'Archive', onPressed: controller.close)], actionBuilder: (context, action, details) => Text(action.label), child: const Text('Message'))
/// ```
class RawSwipeActionsController extends ChangeNotifier {
  _RawSwipeActionsState? _row;
  bool _open = false;

  /// Whether a side of the row is open (or opening).
  bool get isOpen => _open;

  /// Opens the start side's actions, on the row's spring.
  void openStartActions() => _row?._openSide(true);

  /// Opens the end side's actions, on the row's spring.
  void openEndActions() => _row?._openSide(false);

  /// Closes the row, on its spring.
  void close() => _row?.close();

  void _set(bool open) {
    if (open == _open) return;
    _open = open;
    notifyListeners();
  }
}

// The rows in one Scrollable: one open at a time.
final Expando<Set<_RawSwipeActionsState>> _groups = Expando(
  'RawSwipeActions groups',
);

/// An action behind a row.
@immutable
class RawSwipeAction {
  /// An action [label]led, that [onPressed] runs.
  const RawSwipeAction({
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.data,
  });

  /// Its name (and its screen reader action's).
  final String label;

  /// Runs it.
  final VoidCallback onPressed;

  /// Whether it removes the row: a full swipe slides the row away first.
  final bool destructive;

  /// Anything the look needs to paint it (an icon, a colour).
  final Object? data;
}

/// What the look paints an action from.
@immutable
class RawSwipeActionDetails {
  /// The state; the row makes it.
  const RawSwipeActionDetails({
    required this.states,
    required this.reveal,
    required this.armed,
    required this.index,
    required this.count,
    required this.underlap,
  });

  /// Its pressable states.
  final Set<WidgetState> states;

  /// How far its side is open: 1 at its resting width, above 1 past it.
  final double reveal;

  /// Whether letting go now runs it (a full swipe on the edge action). Its
  /// slot widens over the rest as it arms, and narrows back as it disarms.
  final bool armed;

  /// Its place on its side: 0 at the row's edge.
  final int index;

  /// How many actions its side has.
  final int count;

  /// How far its slot runs on under the row, at its inner side: the side's
  /// innermost action's runs [RawSwipeActions.underlap], the others' none.
  /// A look keeps the action's content to the rest of the slot.
  final double underlap;
}

/// Paints an action.
typedef RawSwipeActionBuilder = Widget Function(
  BuildContext context,
  RawSwipeAction action,
  RawSwipeActionDetails details,
);

/// [child] with [startActions] behind its start edge and [endActions]
/// behind its end edge.
///
/// The frame is the look's. In a list of rows, round the group (clip the
/// list or its card), not the first and last rows: a row slides on its own,
/// so a row with rounded corners shows them where it meets its neighbour.
/// Where a row has rounded corners anyway, [underlap] runs the actions'
/// strip on under it, so its corners show the strip, not what is behind.
///
/// ```dart
/// RawSwipeActions(endActions: [RawSwipeAction(label: 'Delete', onPressed: () {}, destructive: true)], actionBuilder: (context, action, details) => Text(action.label), child: const Text('Message'))
/// ```
class RawSwipeActions extends StatefulWidget {
  /// A row of [child] with actions.
  const RawSwipeActions({
    super.key,
    required this.child,
    required this.actionBuilder,
    this.startActions = const [],
    this.endActions = const [],
    this.actionExtent = 80,
    this.fullSwipe = true,
    this.fullSwipeFraction = 0.6,
    this.onOpenChanged,
    this.initiallyOpen = false,
    this.underlap = 0,
    this.controller,
    this.closeOnScroll = true,
    this.dampingRatio = 1,
    this.stiffness = 700,
  }) : assert(actionExtent > 0 && underlap >= 0),
       assert(dampingRatio > 0 && stiffness > 0);

  /// The row.
  final Widget child;

  /// Paints an action.
  final RawSwipeActionBuilder actionBuilder;

  /// The actions a swipe toward the end shows, the first at the edge.
  final List<RawSwipeAction> startActions;

  /// The actions a swipe toward the start shows, the first at the edge.
  final List<RawSwipeAction> endActions;

  /// Each action's resting width.
  final double actionExtent;

  /// Whether a swipe past [fullSwipeFraction] of the row runs the edge
  /// action.
  final bool fullSwipe;

  /// How far a full swipe goes, as a share of the row's width.
  final double fullSwipeFraction;

  /// Called when a side opens or the row closes.
  final ValueChanged<bool>? onOpenChanged;

  /// Whether it starts with a side open: the end's actions (the start's
  /// when the end has none). A preview, or a one-time hint that the row
  /// swipes; it closes as any open row does.
  final bool initiallyOpen;

  /// How far the actions' strip runs on under the row, past where it shows:
  /// the innermost action's slot is that much wider (see
  /// [RawSwipeActionDetails.underlap]). 0: the strip stops at the row.
  final double underlap;

  /// Opens and closes it from outside; the caller's, never disposed here.
  final RawSwipeActionsController? controller;

  /// Whether the scroll view it is in scrolling closes it. Defaults to true.
  /// Rows in one scroll view open one at a time either way: opening one
  /// closes the others.
  final bool closeOnScroll;

  /// The slide's spring damping ratio (ζ). Defaults to 1.
  final double dampingRatio;

  /// The slide's spring stiffness (k). Defaults to 700.
  final double stiffness;

  @override
  State<RawSwipeActions> createState() => _RawSwipeActionsState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<RawSwipeActionBuilder>.has(
          'actionBuilder',
          actionBuilder,
        ),
      )
      ..add(
        IterableProperty<RawSwipeAction>(
          'startActions',
          startActions,
          defaultValue: const <RawSwipeAction>[],
        ),
      )
      ..add(
        IterableProperty<RawSwipeAction>(
          'endActions',
          endActions,
          defaultValue: const <RawSwipeAction>[],
        ),
      )
      ..add(DoubleProperty('actionExtent', actionExtent, defaultValue: 80))
      ..add(
        FlagProperty(
          'fullSwipe',
          value: fullSwipe,
          ifFalse: 'fullSwipe: false',
          defaultValue: true,
        ),
      )
      ..add(
        DoubleProperty(
          'fullSwipeFraction',
          fullSwipeFraction,
          defaultValue: 0.6,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<bool>>.has(
          'onOpenChanged',
          onOpenChanged,
        ),
      )
      ..add(
        FlagProperty(
          'initiallyOpen',
          value: initiallyOpen,
          ifTrue: 'initiallyOpen',
          defaultValue: false,
        ),
      )
      ..add(DoubleProperty('underlap', underlap, defaultValue: 0))
      ..add(
        DiagnosticsProperty<RawSwipeActionsController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'closeOnScroll',
          value: closeOnScroll,
          ifFalse: 'closeOnScroll: false',
          defaultValue: true,
        ),
      )
      ..add(DoubleProperty('dampingRatio', dampingRatio, defaultValue: 1))
      ..add(DoubleProperty('stiffness', stiffness, defaultValue: 700));
  }
}

class _RawSwipeActionsState extends State<RawSwipeActions>
    with TickerProviderStateMixin {
  // Offset along the reading direction: positive shows the start actions.
  late final AnimationController _offset = AnimationController.unbounded(
    vsync: this,
  );
  // How far the edge action has widened over the others as it arms, 0 to
  // 1, and where it is going.
  late final AnimationController _arm = AnimationController(vsync: this);
  bool _armedNow = false;
  final FocusNode _actionsScope = FocusNode(
    debugLabel: 'RawSwipeActions actions',
    canRequestFocus: false,
    skipTraversal: true,
  );
  final FocusNode _row = FocusNode(
    debugLabel: 'RawSwipeActions row',
    canRequestFocus: false,
    skipTraversal: true,
  );
  double _width = 0;
  bool _open = false;

  Set<_RawSwipeActionsState>? _group;
  ValueListenable<bool>? _scrolling;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._row = this;
    if (!widget.initiallyOpen) return;
    final start = widget.endActions.isEmpty;
    if ((start ? widget.startActions : widget.endActions).isEmpty) return;
    _offset.value = start ? _rest(true) : -_rest(false);
    _open = true;
    widget.controller?._set(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The scroll view it is in: its group, and its scrolling.
    final scrollable = Scrollable.maybeOf(context);
    _group?.remove(this);
    _group = scrollable == null
        ? null
        : (_groups[scrollable] ??= <_RawSwipeActionsState>{});
    _group?.add(this);
    final scrolling = scrollable?.position.isScrollingNotifier;
    if (scrolling != _scrolling) {
      _scrolling?.removeListener(_scrolled);
      _scrolling = scrolling?..addListener(_scrolled);
    }
  }

  @override
  void didUpdateWidget(RawSwipeActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._row == this) oldWidget.controller!._row = null;
      widget.controller?._row = this;
      widget.controller?._set(_open);
    }
  }

  void _scrolled() {
    if (widget.closeOnScroll &&
        (_scrolling?.value ?? false) &&
        !_dragging &&
        _offset.value != 0) {
      close();
    }
  }

  // Opening this row closes the others in its scroll view.
  void _closeOthers() {
    for (final row in [...?_group]) {
      if (row != this && row._offset.value != 0) row.close();
    }
  }

  @override
  void dispose() {
    _group?.remove(this);
    _scrolling?.removeListener(_scrolled);
    if (widget.controller?._row == this) widget.controller!._row = null;
    _offset.dispose();
    _arm.dispose();
    _actionsScope.dispose();
    _row.dispose();
    super.dispose();
  }

  double _rest(bool start) =>
      (start ? widget.startActions : widget.endActions).length *
      widget.actionExtent;

  // Runs [controller] to [to] on the row's spring, at [velocity]; under
  // Reduce Motion it is there at once. The arm widens a slot, a shorter
  // way than the slide: twice as stiff ([quick]).
  TickerFuture _spring(
    AnimationController controller,
    double to, {
    double velocity = 0,
    bool quick = false,
  }) {
    if (rawReduceMotionOf(context)) {
      controller.value = to;
      return TickerFuture.complete();
    }
    return controller.animateWith(
      rawSpringSimulation(
        const RawMotionPolicy().spatial(
          dampingRatio: widget.dampingRatio,
          stiffness: widget.stiffness * (quick ? 2 : 1),
        ),
        from: controller.value,
        to: to,
        velocity: velocity,
      ),
    );
  }

  // Widens the edge action's slot as it arms, and narrows it back.
  void _arming(bool armed) {
    if (armed == _armedNow) return;
    _armedNow = armed;
    _spring(_arm, armed ? 1.0 : 0.0, quick: true);
  }

  void _settle(double to, {double velocity = 0}) {
    _arming(false);
    final open = to != 0;
    if (open) _closeOthers();
    if (open != _open) {
      _open = open;
      widget.onOpenChanged?.call(open);
      widget.controller?._set(open);
    }
    _spring(_offset, to, velocity: velocity);
    setState(() {});
  }

  void close() => _settle(0);

  void _openSide(bool start, {bool focus = false}) {
    final actions = start ? widget.startActions : widget.endActions;
    if (actions.isEmpty) return;
    _settle(start ? _rest(true) : -_rest(false));
    if (focus) _focusFirstAction();
  }

  // Focuses the first action once it is built: the actions mount when the
  // row has left its rest, a frame or more into the slide.
  void _focusFirstAction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nodes = _actionsScope.traversalDescendants
          .where((n) => n.canRequestFocus && !n.skipTraversal)
          .toList();
      if (nodes.isNotEmpty) {
        nodes.first.requestFocus();
      } else if (_offset.isAnimating) {
        _focusFirstAction();
      }
    });
  }

  void _run(RawSwipeAction action) {
    final returnFocus = _actionsScope.hasFocus;
    close();
    if (returnFocus) _focusRow();
    action.onPressed();
  }

  void _focusRow() {
    final nodes = _row.traversalDescendants
        .where(
          (n) =>
              n.canRequestFocus &&
              !n.skipTraversal &&
              !_actionsScope.traversalDescendants.contains(n),
        )
        .toList();
    if (nodes.isNotEmpty) nodes.first.requestFocus();
  }

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  void _dragStart(DragStartDetails d) {
    _dragging = true;
    _closeOthers();
  }

  void _dragUpdate(DragUpdateDetails d) {
    var delta = d.primaryDelta ?? 0;
    if (_rtl) delta = -delta;
    var next = _offset.value + delta;
    if (widget.startActions.isEmpty && next > 0) next = 0;
    if (widget.endActions.isEmpty && next < 0) next = 0;
    final full = widget.fullSwipe ? _width : _rest(next > 0);
    next = next.clamp(-full, full);
    _offset.value = next;
    final armed = _armed(next);
    if (armed && !_armedNow) {
      RawHaptics.of(context).thresholdCrossed?.call();
    }
    _arming(armed);
  }

  void _dragEnd(DragEndDetails d) {
    _dragging = false;
    var v = d.primaryVelocity ?? 0;
    if (_rtl) v = -v;
    final x = _offset.value;
    if (x == 0) return;
    final start = x > 0;
    final rest = _rest(start);
    final actions = start ? widget.startActions : widget.endActions;
    if (_armed(x)) {
      final edge = actions.first;
      if (edge.destructive) {
        // Slid away at the fling's speed, then run.
        _spring(
          _offset,
          start ? _width : -_width,
          velocity: v,
        ).whenComplete(edge.onPressed);
        _open = false;
        widget.controller?._set(false);
      } else {
        close();
        edge.onPressed();
      }
      return;
    }
    final outward = start ? v > 300 : v < -300;
    final inward = start ? v < -300 : v > 300;
    if (outward || (!inward && x.abs() >= rest / 2)) {
      _settle(start ? rest : -rest, velocity: v);
    } else {
      _settle(0, velocity: v);
    }
  }

  bool _armed(double x) =>
      widget.fullSwipe &&
      _width > 0 &&
      x.abs() >= _width * widget.fullSwipeFraction &&
      x.abs() > _rest(x > 0);

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final toStart = _rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final toEnd = _rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    if (key == LogicalKeyboardKey.escape && _offset.value != 0) {
      final inside = _actionsScope.hasFocus;
      close();
      if (inside) _focusRow();
      return KeyEventResult.handled;
    }
    if (_actionsScope.hasFocus) return KeyEventResult.ignored;
    if (key == toStart && widget.endActions.isNotEmpty) {
      _openSide(false, focus: true);
      return KeyEventResult.handled;
    }
    if (key == toEnd && widget.startActions.isNotEmpty) {
      _openSide(true, focus: true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _actions(bool start, double x) {
    final actions = start ? widget.startActions : widget.endActions;
    final shown = start ? x > 0 : x < 0;
    final reveal = _rest(start) == 0 ? 0.0 : x.abs() / _rest(start);
    final armed = shown && _armed(x);
    final n = actions.length;
    // The edge action widens to four shares as it arms; the innermost runs
    // on under the row by the underlap.
    final shares = n + 3 * _arm.value;
    Widget slot(int i, RawSwipeAction a) => RawButton(
      onPressed: () => _run(a),
      semanticLabel: a.label,
      excludeSemantics: true,
      builder: (context, states, _) => widget.actionBuilder(
        context,
        a,
        RawSwipeActionDetails(
          states: states,
          reveal: reveal,
          armed: armed && i == 0,
          index: i,
          count: n,
          underlap: i == n - 1 ? widget.underlap : 0,
        ),
      ),
    );
    final row = Row(
      children: [
        for (final (i, a) in actions.indexed)
          if (i == n - 1)
            Expanded(child: slot(i, a))
          else
            SizedBox(
              width: x.abs() * (i == 0 ? 1 + 3 * _arm.value : 1) / shares,
              child: slot(i, a),
            ),
      ],
    );
    // The first action sits at the row's edge: reverse the end side.
    return Focus(
      focusNode: _actionsScope,
      includeSemantics: false,
      child: Directionality(
        textDirection: start == !_rtl ? TextDirection.ltr : TextDirection.rtl,
        child: row,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rtl = _rtl;
    final all = [...widget.startActions, ...widget.endActions];
    // The actions on the row's own node (see RawSwipeActionsSemantics); a
    // control in the row keeps its node, and the actions behind it, when
    // open, are nodes of their own.
    final row = RowActionsScope(
      child: RowActions(
        actions: {
          for (final a in all)
            CustomSemanticsAction(label: a.label): a.onPressed,
        },
        child: widget.child,
      ),
    );
    return Focus(
      focusNode: _row,
      includeSemantics: false,
      onKeyEvent: _key,
      child: LayoutBuilder(
        builder: (context, box) {
          _width = box.maxWidth;
          // The swipe, and the tap that closes an open row, are the
          // pointer's: a screen reader takes the actions from the row's
          // custom actions, so neither gesture adds an unlabelled node.
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            excludeFromSemantics: true,
            onHorizontalDragStart: _dragStart,
            onHorizontalDragUpdate: _dragUpdate,
            onHorizontalDragEnd: _dragEnd,
            onHorizontalDragCancel: () => _dragging = false,
            child: AnimatedBuilder(
              animation: Listenable.merge([_offset, _arm]),
              builder: (context, child) {
                final x = _offset.value;
                final dx = rtl ? -x : x;
                final behind = x == 0
                    ? null
                    : Positioned(
                        top: 0,
                        bottom: 0,
                        left: dx > 0 ? 0 : null,
                        right: dx < 0 ? 0 : null,
                        width: x.abs() + widget.underlap,
                        // Cut where the row uncovers them, at the strip's
                        // start and end only: an action's shadow still
                        // reaches past the row's top and bottom.
                        child: ClipRect(
                          clipper: const _AlongTheSwipe(),
                          child: _actions(x > 0, x),
                        ),
                      );
                // The row covers the whole area, so its visible strip
                // takes the tap that closes it.
                return Stack(
                  fit: StackFit.passthrough,
                  children: [
                    ?behind,
                    Transform.translate(
                      offset: Offset(dx, 0),
                      // While open, the row is one target that closes it,
                      // and the pointer says so.
                      child: MouseRegion(
                        cursor: x != 0
                            ? SystemMouseCursors.click
                            : MouseCursor.defer,
                        opaque: x != 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          excludeFromSemantics: true,
                          onTap: x != 0 ? close : null,
                          child: AbsorbPointer(absorbing: x != 0, child: child),
                        ),
                      ),
                    ),
                  ],
                );
              },
              child: row,
            ),
          );
        },
      ),
    );
  }
}

// The uncovered strip's clip: at its start and end only, open above and
// below by its own height, more than any shadow an action casts. Its
// approximate rect is the clip itself, so a reader of the paint clip (the
// clipped-shadow check) sees where it cuts.
/// Gives a [RawSwipeActions] row's actions to the semantics node a look's
/// row forms of its own: the row's custom actions, which a screen reader
/// offers on the row.
///
/// A row with no node of its own (words, a trailing button) needs none: the
/// swipe row is its node, its words and its actions, and the button keeps
/// its node. A row that is a [RawButton] needs none either: the button's
/// node takes them. A look's row whose own `Semantics(container: true)`
/// makes its node puts this inside that `Semantics`, round the row's
/// content, so the row's words, its tap and its actions are one node and a
/// trailing control in it keeps its own.
///
/// It takes them only when it is the row's whole content: between it and
/// the [RawSwipeActions] each widget has one child (no `Row`, `Column` or
/// `Stack`). One beside the row's words, round a trailing control, takes
/// nothing.
///
/// ```dart
/// RawSwipeActions(endActions: [RawSwipeAction(label: 'Delete', onPressed: () {})], actionBuilder: (context, action, details) => Text(action.label), child: Semantics(container: true, button: true, onTap: () {}, child: const RawSwipeActionsSemantics(child: Text('Message'))))
/// ```
class RawSwipeActionsSemantics extends StatelessWidget {
  /// Gives the node it stands in the row's actions.
  const RawSwipeActionsSemantics({super.key, required this.child});

  /// The row's content, inside its node.
  final Widget child;

  @override
  Widget build(BuildContext context) => RowActionsTarget(child: child);
}

class _AlongTheSwipe extends CustomClipper<Rect> {
  const _AlongTheSwipe();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -size.height, size.width, 2 * size.height);

  @override
  Rect getApproximateClipRect(Size size) => getClip(size);

  @override
  bool shouldReclip(_AlongTheSwipe oldClipper) => false;
}
