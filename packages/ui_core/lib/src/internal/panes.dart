/// Pane focus: F6 moves focus to the next pane (Shift+F6 the previous), as
/// on Windows, macOS and in browsers: a shell's navigation and body, a
/// list-detail's list and detail, a shown toaster. Inside ui_core; not
/// exported.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Where F6 and Shift+F6 cycle focus among the [Pane]s below. Cycles inside
/// another hand their panes to the outermost, so an app has one cycle
/// however many shells, list-details and toasters it nests.
class PaneCycle extends StatefulWidget {
  /// A cycle over [child]'s panes.
  const PaneCycle({super.key, required this.child});

  /// The app below.
  final Widget child;

  /// The cycle [context] is in, or null.
  static PaneCycleState? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PaneCycleScope>()?.state;

  @override
  State<PaneCycle> createState() => PaneCycleState();
}

/// A [PaneCycle]'s panes, and the moves between them.
class PaneCycleState extends State<PaneCycle> {
  PaneCycleState? _outer;
  final Set<PaneState> _panes = {};

  /// The outermost cycle, which holds every pane.
  PaneCycleState get root => _outer?.root ?? this;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final outer = PaneCycle.maybeOf(context);
    if (outer == _outer) return;
    // Panes registered here move to the new root.
    final moving = [..._panes];
    for (final pane in moving) {
      pane._cycle?.unregister(pane);
    }
    _outer = outer;
    for (final pane in moving) {
      pane._cycle = root..register(pane);
    }
  }

  /// Adds [pane] to the cycle.
  void register(PaneState pane) => _panes.add(pane);

  /// Takes [pane] out of the cycle.
  void unregister(PaneState pane) => _panes.remove(pane);

  /// The panes F6 lands on, in reading order: those with somewhere to put
  /// focus, a pane holding others left to them.
  List<PaneState> get stops {
    final live = [
      for (final p in root._panes)
        if (p.mounted && p._hasStops) p,
    ];
    final leaves = [
      for (final p in live)
        if (!live.any((q) => q != p && q._inside(p))) p,
    ];
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    leaves.sort((a, b) {
      final ra = a._rect;
      final rb = b._rect;
      final byTop = ra.top.compareTo(rb.top);
      if (byTop != 0 && (ra.top - rb.top).abs() >= 1) return byTop;
      return rtl ? rb.right.compareTo(ra.right) : ra.left.compareTo(rb.left);
    });
    return leaves;
  }

  /// Whether F6 has more than one pane to move between.
  bool get cycles => stops.length > 1;

  /// Moves focus to the next pane ([forward]) or the previous, from the one
  /// that holds it (from outside every pane: the first, or the last).
  /// False when there is nowhere else to go.
  bool move({required bool forward}) {
    final panes = stops;
    if (panes.isEmpty) return false;
    final focus = FocusManager.instance.primaryFocus;
    final at = panes.indexWhere((p) => p._holds(focus));
    final int to;
    if (at < 0) {
      to = forward ? 0 : panes.length - 1;
    } else {
      to = (at + (forward ? 1 : -1)) % panes.length;
      if (to == at) return false;
    }
    panes[to].enter();
    return true;
  }

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.f6): _MovePaneIntent(forward: true),
      SingleActivator(LogicalKeyboardKey.f6, shift: true): _MovePaneIntent(
        forward: false,
      ),
    },
    child: Actions(
      actions: {_MovePaneIntent: _MovePaneAction(this)},
      child: _PaneCycleScope(state: this, child: widget.child),
    ),
  );
}

class _PaneCycleScope extends InheritedWidget {
  const _PaneCycleScope({required this.state, required super.child});

  final PaneCycleState state;

  @override
  bool updateShouldNotify(_PaneCycleScope oldWidget) =>
      state != oldWidget.state;
}

class _MovePaneIntent extends Intent {
  const _MovePaneIntent({required this.forward});

  final bool forward;
}

class _MovePaneAction extends Action<_MovePaneIntent> {
  _MovePaneAction(this.cycle);

  final PaneCycleState cycle;

  // With one pane or none, the key goes on up (to a toaster's own F6).
  @override
  bool isEnabled(_MovePaneIntent intent) => cycle.mounted && cycle.cycles;

  @override
  Object? invoke(_MovePaneIntent intent) => cycle.move(forward: intent.forward);
}

/// A pane: one stop of F6. Focus lands on the node it last held, else its
/// first in reading order, or [enter] puts it there.
class Pane extends StatefulWidget {
  /// [child] as one pane.
  const Pane({super.key, required this.child, this.enter, this.debugLabel});

  /// The pane's content.
  final Widget child;

  /// Puts focus in the pane itself, true when it did (a toaster focuses its
  /// newest toast); null, or false: the pane's last focused node, else its
  /// first.
  final bool Function()? enter;

  /// What its focus node is called in a focus tree's dump.
  final String? debugLabel;

  @override
  State<Pane> createState() => PaneState();
}

/// A [Pane]'s place in its cycle.
class PaneState extends State<Pane> {
  late final FocusNode _node = FocusNode(
    debugLabel: widget.debugLabel ?? 'Pane',
    canRequestFocus: false,
    skipTraversal: true,
  );
  PaneCycleState? _cycle;
  FocusNode? _last;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_focusMoved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cycle = PaneCycle.maybeOf(context)?.root;
    if (cycle == _cycle) return;
    _cycle?.unregister(this);
    _cycle = cycle?..register(this);
  }

  @override
  void dispose() {
    _cycle?.unregister(this);
    FocusManager.instance.removeListener(_focusMoved);
    _node.dispose();
    super.dispose();
  }

  void _focusMoved() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus != _node && _holds(focus)) _last = focus;
  }

  bool _holds(FocusNode? node) =>
      node != null && (node == _node || node.ancestors.contains(_node));

  bool _inside(PaneState other) => _node.ancestors.contains(other._node);

  List<FocusNode> get _focusable => _node.traversalDescendants.toList();

  bool get _hasStops => _focusable.isNotEmpty;

  Rect get _rect {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return Rect.zero;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Puts focus in the pane.
  void enter() {
    if (widget.enter?.call() ?? false) return;
    final last = _last;
    // A node left with its widget gone is not taken back.
    if (last != null &&
        (last.context?.mounted ?? false) &&
        last.canRequestFocus &&
        _holds(last)) {
      last.requestFocus();
      return;
    }
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final nodes = _focusable
      ..sort((a, b) {
        final byTop = a.rect.top.compareTo(b.rect.top);
        if (byTop != 0 && (a.rect.top - b.rect.top).abs() >= 1) return byTop;
        return rtl
            ? b.rect.right.compareTo(a.rect.right)
            : a.rect.left.compareTo(b.rect.left);
      });
    if (nodes.isNotEmpty) nodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) =>
      Focus(focusNode: _node, includeSemantics: false, child: widget.child);
}
