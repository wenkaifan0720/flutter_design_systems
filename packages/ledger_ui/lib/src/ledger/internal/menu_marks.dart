import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Starts telling a key from the pointer, app-wide, for the menus'
/// one current row ([LedgerMenuMarks]): a control that opens a menu calls
/// it as it builds, before the keys that open the menu come.
void ledgerWatchInput() => _LastInput.watch();

/// Whether a key came after the pointer last moved or pressed, app-wide.
/// A pointer leaves the keyboard's highlight on in Flutter, so a menu a
/// click opened would show its first row (ui_core focuses it) as the
/// keyboard's; this tells the two apart. A move counts as well as a press:
/// on the web with its semantics on, a click reaches the app as a tap of
/// the semantics, with no press, but the pointer still moved to it.
abstract final class _LastInput {
  static bool _routed = false;
  static bool keys = false;

  static void watch() {
    if (!_routed) {
      _routed = true;
      GestureBinding.instance.pointerRouter.addGlobalRoute(_pointer);
    }
    // Again each time: a keyboard's handlers can be cleared (a test does
    // between its cases); removing one not there does nothing.
    HardwareKeyboard.instance
      ..removeHandler(_key)
      ..addHandler(_key);
  }

  static void _pointer(PointerEvent event) {
    if (event is PointerDownEvent ||
        event is PointerHoverEvent ||
        event is PointerMoveEvent) {
      keys = false;
    }
  }

  static bool _key(KeyEvent event) {
    if (event is KeyDownEvent) keys = true;
    return false;
  }
}

/// Which row of one menu is lit, and by what.
class _Marks extends ChangeNotifier {
  _Marks(this.region);

  final FocusNode region;
  final Set<FocusNode> rows = {};
  FocusNode? lit;
  bool byKeys = false;

  // The row a pointer asked to hold the focus: its focus is the pointer's.
  FocusNode? asked;

  FocusNode? get held {
    final primary = FocusManager.instance.primaryFocus;
    return rows.contains(primary) ? primary : null;
  }

  void keysOn(FocusNode? row) {
    if (row == null || (lit == row && byKeys)) return;
    lit = row;
    byKeys = true;
    notifyListeners();
  }

  void point(FocusNode row, {required bool enabled}) {
    final next = enabled ? row : null;
    if (lit == next && (next == null || !byKeys)) return;
    lit = next;
    byKeys = false;
    // The keys go on from the pointer's row once they are in the menu; a
    // menu standing in a page does not take the focus from a field.
    if (next != null && region.hasFocus && !next.hasPrimaryFocus) {
      asked = next;
      next.requestFocus();
    }
    notifyListeners();
  }

  void leave(FocusNode row) {
    if (lit != row || byKeys) return;
    lit = null;
    notifyListeners();
  }

  void clear() {
    if (lit == null) return;
    lit = null;
    byKeys = false;
    notifyListeners();
  }
}

class _MarksScope extends InheritedNotifier<_Marks> {
  const _MarksScope({required _Marks marks, required super.child})
    : super(notifier: marks);

  static _Marks? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MarksScope>()?.notifier;
}

/// An open menu's rows with one current row among them: the row the
/// pointer or the keys moved to last, marked as that one moved it (the
/// pointer's underline, the keyboard's double rule, [LedgerMenuRow]) and
/// no other, so a pointer resting on one row and the keys on another
/// never read as two. A pointer moving onto a row moves the keys there
/// too while they are in the menu. A menu a pointer opened lights none
/// until the pointer or the keys move: Down, Enter or Space then lights
/// the row the keys hold (the first) rather than pass or press it unseen.
class LedgerMenuMarks extends StatefulWidget {
  /// [child]'s rows, one current.
  const LedgerMenuMarks({required this.child, super.key});

  /// The menu's rows, each a [LedgerMenuRow].
  final Widget child;

  @override
  State<LedgerMenuMarks> createState() => _LedgerMenuMarksState();
}

class _LedgerMenuMarksState extends State<LedgerMenuMarks> {
  final FocusNode _region = FocusNode(debugLabel: 'Ledger menu');
  late final _Marks _marks = _Marks(_region);

  static final Set<LogicalKeyboardKey> _lights = {
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
  };

  static final Set<LogicalKeyboardKey> _moves = {
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.home,
    LogicalKeyboardKey.end,
    LogicalKeyboardKey.pageDown,
    LogicalKeyboardKey.pageUp,
    LogicalKeyboardKey.tab,
  };

  @override
  void initState() {
    super.initState();
    _LastInput.watch();
  }

  @override
  void dispose() {
    _marks.dispose();
    _region.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final held = _marks.held;
    if (held == null) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (_marks.lit == null && _lights.contains(key)) {
      _marks.keysOn(held);
      return KeyEventResult.handled;
    }
    if (_moves.contains(key)) {
      // Once the keys have moved (or stood at an end), their row is lit.
      SchedulerBinding.instance
        ..addPostFrameCallback((_) {
          if (mounted && _region.hasFocus) _marks.keysOn(_marks.held);
        })
        ..ensureVisualUpdate();
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _region,
    canRequestFocus: false,
    skipTraversal: true,
    includeSemantics: false,
    onKeyEvent: _key,
    onFocusChange: (on) {
      if (!on && _marks.byKeys) _marks.clear();
    },
    child: _MarksScope(marks: _marks, child: widget.child),
  );
}

/// A row of a [LedgerMenuMarks] menu: [builder] gets the pressable's
/// [states] with its hover and focus replaced by the one current row's
/// mark (hovered while the pointer lit it, focused while the keys did).
/// Under no [LedgerMenuMarks], [states] as they are.
class LedgerMenuRow extends StatefulWidget {
  /// The row whose pressable is [states].
  const LedgerMenuRow({
    required this.states,
    required this.enabled,
    required this.builder,
    super.key,
  });

  /// The pressable's states.
  final Set<WidgetState> states;

  /// Whether the row can be lit.
  final bool enabled;

  /// The row's face for its marked states.
  final Widget Function(BuildContext context, Set<WidgetState> states) builder;

  @override
  State<LedgerMenuRow> createState() => _LedgerMenuRowState();
}

class _LedgerMenuRowState extends State<LedgerMenuRow> {
  FocusNode? _node;
  _Marks? _marks;

  void _wire(_Marks? marks, FocusNode? node) {
    if (node != _node || marks != _marks) {
      _node?.removeListener(_focused);
      _marks?.rows.remove(_node);
      _node = node;
      _marks = marks;
      if (marks != null && node != null) {
        node.addListener(_focused);
        marks.rows.add(node);
      }
    }
  }

  void _focused() {
    final node = _node;
    final marks = _marks;
    if (node == null || marks == null || !node.hasPrimaryFocus) return;
    if (marks.asked == node) {
      marks.asked = null;
      return;
    }
    if (_LastInput.keys && widget.enabled) marks.keysOn(node);
  }

  @override
  void dispose() {
    _wire(null, null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marks = _MarksScope.maybeOf(context);
    final node = Focus.maybeOf(context, createDependency: false);
    _wire(marks, node);
    if (marks == null || node == null) {
      return widget.builder(context, widget.states);
    }
    final lit = widget.enabled && marks.lit == node;
    final states = <WidgetState>{
      for (final s in widget.states)
        if (s != WidgetState.hovered && s != WidgetState.focused) s,
      if (lit) marks.byKeys ? WidgetState.focused : WidgetState.hovered,
    };
    return MouseRegion(
      // A move, not an entry: a menu opening under a resting pointer lights
      // nothing.
      onHover: (_) => marks.point(node, enabled: widget.enabled),
      onExit: (_) => marks.leave(node),
      child: widget.builder(context, states),
    );
  }
}
