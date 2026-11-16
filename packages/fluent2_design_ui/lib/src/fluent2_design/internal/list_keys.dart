/// The keys of an open list of options (a select's popover or sheet, a
/// menu), as Fluent's listbox and menu take them: Down and Up move to the
/// next and the previous option at once, wrapping round, past the options
/// out of use; Home and End go to the first and the last; a typed letter
/// goes to the next option whose words start with it, and letters typed
/// within a second of each other spell the start of one. Enter and Space
/// press the option in focus (its own press), and Escape is the list's own.
/// However the focus lands on an option (the list opening on it, its keys,
/// Tab), the option stands wholly in the list's view, as Fluent's listbox
/// keeps its active option in view.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The option [Fluent2ListKeys] puts the focus on as a list opens: the
/// chosen one ([chosen], an index) when it is in use, else the first in use.
int fluent2FirstFocus(List<bool> enabled, int chosen) {
  if (chosen >= 0 && chosen < enabled.length && enabled[chosen]) return chosen;
  final first = enabled.indexOf(true);
  return first < 0 ? 0 : first;
}

/// [child], a list of options each holding one of [nodes], with the keys of
/// an open list: [labels] are the options' words, [enabled] whether each is
/// in use.
class Fluent2ListKeys extends StatefulWidget {
  /// The keys of the list in [child].
  const Fluent2ListKeys({
    required this.nodes,
    required this.labels,
    required this.enabled,
    required this.child,
    super.key,
  });

  /// The options' focus nodes, in order.
  final List<FocusNode> nodes;

  /// The options' words, in order.
  final List<String> labels;

  /// Whether each option is in use.
  final List<bool> enabled;

  /// The list.
  final Widget child;

  @override
  State<Fluent2ListKeys> createState() => _Fluent2ListKeysState();
}

class _Fluent2ListKeysState extends State<Fluent2ListKeys> {
  // The letters typed so far and when the last one came.
  String _typed = '';
  Duration? _typedAt;

  static const _typingPause = Duration(seconds: 1);

  int get _at => widget.nodes.indexWhere((n) => n.hasFocus);

  bool _usable(int i) =>
      i >= 0 && i < widget.enabled.length && widget.enabled[i];

  void _focus(int i) => widget.nodes[i].requestFocus();

  // The option the focus last landed on in this open list; none until the
  // list opens on one.
  FocusNode? _shown;

  @override
  void initState() {
    super.initState();
    _listen(widget.nodes);
  }

  @override
  void didUpdateWidget(Fluent2ListKeys old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.nodes, widget.nodes)) {
      _unlisten(old.nodes);
      _listen(widget.nodes);
    }
  }

  @override
  void dispose() {
    _unlisten(widget.nodes);
    super.dispose();
  }

  void _listen(List<FocusNode> nodes) {
    for (final node in nodes) {
      node.addListener(_landed);
    }
  }

  // A node the list's owner has disposed takes this as well.
  void _unlisten(List<FocusNode> nodes) {
    for (final node in nodes) {
      node.removeListener(_landed);
    }
  }

  // The focus on a new option: as the list opens, mid-list (as far as the
  // list scrolls), so a chosen option near the end shows with its
  // neighbours; after, scrolled the least way that shows it whole.
  void _landed() {
    for (final node in widget.nodes) {
      if (!node.hasPrimaryFocus || identical(node, _shown)) continue;
      final opening = _shown == null;
      _shown = node;
      _reveal(node, centre: opening);
      return;
    }
  }

  void _reveal(FocusNode node, {required bool centre}) {
    final option = node.context;
    if (option == null || !option.mounted) return;
    final box = option.findRenderObject();
    final scrollable = Scrollable.maybeOf(option);
    final frame = scrollable?.context.findRenderObject();
    // Only the list's own scroll: never a page's round the field it opened
    // from.
    if (box == null || !box.attached || frame == null || !_inside(box, frame)) {
      return;
    }
    final position = scrollable!.position;
    if (centre) {
      unawaited(position.ensureVisible(box, alignment: 0.5));
      return;
    }
    unawaited(
      position.ensureVisible(
        box,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      ),
    );
    unawaited(
      position.ensureVisible(
        box,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ),
    );
  }

  static bool _inside(RenderObject box, RenderObject frame) {
    for (RenderObject? o = box.parent; o != null; o = o.parent) {
      if (identical(o, frame)) return true;
    }
    return false;
  }

  // The next option in use from [from], [step] at a time, round the list.
  int? _next(int from, int step) {
    final n = widget.nodes.length;
    for (var k = 1; k <= n; k++) {
      final i = ((from + step * k) % n + n) % n;
      if (_usable(i)) return i;
    }
    return null;
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (widget.nodes.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final at = _at;
    int? to;
    if (key == LogicalKeyboardKey.arrowDown) {
      to = _next(at < 0 ? -1 : at, 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      to = _next(at < 0 ? 0 : at, -1);
    } else if (key == LogicalKeyboardKey.home) {
      to = _next(-1, 1);
    } else if (key == LogicalKeyboardKey.end) {
      to = _next(0, -1);
    } else {
      return _letter(event, at);
    }
    if (to != null) _focus(to);
    return KeyEventResult.handled;
  }

  KeyEventResult _letter(KeyEvent event, int at) {
    final keys = HardwareKeyboard.instance;
    final char = event.character;
    if (char == null ||
        char.isEmpty ||
        keys.isControlPressed ||
        keys.isMetaPressed ||
        keys.isAltPressed ||
        char.codeUnitAt(0) < 0x20 ||
        char.codeUnitAt(0) == 0x7f) {
      return KeyEventResult.ignored;
    }
    // The key's own time; a key made up in code carries none, and takes the
    // frame's.
    final now = event.timeStamp != Duration.zero
        ? event.timeStamp
        : SchedulerBinding.instance.currentSystemFrameTimeStamp;
    final last = _typedAt;
    final going = last != null && now - last < _typingPause;
    // A space starts nothing: it presses the option, unless it is spelling.
    if (char == ' ' && !going) return KeyEventResult.ignored;
    _typed = (going ? _typed : '') + char.toLowerCase();
    _typedAt = now;
    // The same letter again steps through the options starting with it;
    // more letters keep the option they still spell.
    final one = _typed.split('').every((c) => c == _typed[0]);
    final prefix = one ? _typed[0] : _typed;
    final n = widget.nodes.length;
    final from = at < 0 ? 0 : (one || !going ? at + 1 : at);
    for (var k = 0; k < n; k++) {
      final i = (from + k) % n;
      if (_usable(i) &&
          widget.labels[i].toLowerCase().trimLeft().startsWith(prefix)) {
        _focus(i);
        break;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: _key,
    child: widget.child,
  );
}
