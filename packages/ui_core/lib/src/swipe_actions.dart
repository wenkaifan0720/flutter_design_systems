/// Swipe actions, headless: a row that slides aside to show actions behind
/// it. Past half the actions it stays open; a full swipe runs the action at
/// the edge. The keyboard opens a side with the arrows (the arrow toward
/// the start shows the end's actions, mirrored right to left) and focuses
/// its first action; Escape closes it, focus back in the row. A screen
/// reader gets every action as a custom action on the row.
library;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'pressable.dart';

/// An action behind a row.
@immutable
class DesignSwipeAction {
  /// An action [label]led, that [onPressed] runs.
  const DesignSwipeAction({
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
class DesignSwipeActionDetails {
  /// The state; the row makes it.
  const DesignSwipeActionDetails({
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
  /// innermost action's runs [DesignSwipeActions.underlap], the others' none.
  /// A look keeps the action's content to the rest of the slot.
  final double underlap;
}

/// Paints an action.
typedef DesignSwipeActionBuilder = Widget Function(
  BuildContext context,
  DesignSwipeAction action,
  DesignSwipeActionDetails details,
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
/// DesignSwipeActions(endActions: [DesignSwipeAction(label: 'Delete', onPressed: () {}, destructive: true)], actionBuilder: (context, action, details) => Text(action.label), child: const Text('Message'))
/// ```
class DesignSwipeActions extends StatefulWidget {
  /// A row of [child] with actions.
  const DesignSwipeActions({
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
  });

  /// The row.
  final Widget child;

  /// Paints an action.
  final DesignSwipeActionBuilder actionBuilder;

  /// The actions a swipe toward the end shows, the first at the edge.
  final List<DesignSwipeAction> startActions;

  /// The actions a swipe toward the start shows, the first at the edge.
  final List<DesignSwipeAction> endActions;

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
  /// [DesignSwipeActionDetails.underlap]). 0: the strip stops at the row.
  final double underlap;

  @override
  State<DesignSwipeActions> createState() => _DesignSwipeActionsState();
}

class _DesignSwipeActionsState extends State<DesignSwipeActions>
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
    debugLabel: 'DesignSwipeActions actions',
    canRequestFocus: false,
    skipTraversal: true,
  );
  final FocusNode _row = FocusNode(
    debugLabel: 'DesignSwipeActions row',
    canRequestFocus: false,
    skipTraversal: true,
  );
  double _width = 0;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    if (!widget.initiallyOpen) return;
    final start = widget.endActions.isEmpty;
    if ((start ? widget.startActions : widget.endActions).isEmpty) return;
    _offset.value = start ? _rest(true) : -_rest(false);
    _open = true;
  }

  @override
  void dispose() {
    _offset.dispose();
    _arm.dispose();
    _actionsScope.dispose();
    _row.dispose();
    super.dispose();
  }

  double _rest(bool start) =>
      (start ? widget.startActions : widget.endActions).length *
      widget.actionExtent;

  // Widens the edge action's slot as it arms, and narrows it back.
  void _arming(bool armed) {
    if (armed == _armedNow) return;
    _armedNow = armed;
    final to = armed ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _arm.value = to;
    } else {
      _arm.animateTo(
        to,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _settle(double to) {
    _arming(false);
    final open = to != 0;
    if (open != _open) {
      _open = open;
      widget.onOpenChanged?.call(open);
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _offset.value = to;
    } else {
      _offset.animateTo(
        to,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
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

  void _run(DesignSwipeAction action) {
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

  void _dragUpdate(DragUpdateDetails d) {
    var delta = d.primaryDelta ?? 0;
    if (_rtl) delta = -delta;
    var next = _offset.value + delta;
    if (widget.startActions.isEmpty && next > 0) next = 0;
    if (widget.endActions.isEmpty && next < 0) next = 0;
    final full = widget.fullSwipe ? _width : _rest(next > 0);
    next = next.clamp(-full, full);
    _offset.value = next;
    _arming(_armed(next));
  }

  void _dragEnd(DragEndDetails d) {
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
        _offset
            .animateTo(
              start ? _width : -_width,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
            )
            .whenComplete(edge.onPressed);
        _open = false;
      } else {
        close();
        edge.onPressed();
      }
      return;
    }
    final outward = start ? v > 300 : v < -300;
    final inward = start ? v < -300 : v > 300;
    if (outward || (!inward && x.abs() >= rest / 2)) {
      _openSide(start);
    } else {
      close();
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
    Widget slot(int i, DesignSwipeAction a) => DesignPressable(
      onPressed: () => _run(a),
      semanticLabel: a.label,
      excludeSemantics: true,
      builder: (context, states, _) => widget.actionBuilder(
        context,
        a,
        DesignSwipeActionDetails(
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
    // The row's own words and its actions as one node; the actions behind
    // it, when open, are nodes of their own.
    final row = MergeSemantics(
      child: Semantics(
        customSemanticsActions: {
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
            onHorizontalDragUpdate: _dragUpdate,
            onHorizontalDragEnd: _dragEnd,
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
                        child: ClipRect(child: _actions(x > 0, x)),
                      );
                // The row covers the whole area, so its visible strip
                // takes the tap that closes it.
                return Stack(
                  fit: StackFit.passthrough,
                  children: [
                    ?behind,
                    Transform.translate(
                      offset: Offset(dx, 0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        excludeFromSemantics: true,
                        onTap: x != 0 ? close : null,
                        child: AbsorbPointer(absorbing: x != 0, child: child),
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
