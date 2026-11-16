/// The rows of an open list as the keys walk them: the row the keys start
/// on, and a typed letter's jump.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../primitives/menu.dart';

/// Walks the rows under [child] that take the focus (a menu's, a select's)
/// by typed letters: a letter takes the focus to the next row whose words
/// start with it, round to the first; the same letter again goes on to the
/// one after; letters typed close together, to the row their run starts.
/// With [initial], that row (counted among those that take the focus) has
/// the focus once the list is up. A row's words are its [TermMenuRow]'s
/// label, or else its first text's. Wherever the focus goes among the rows
/// (the chosen one as the list comes up, an arrow past the end and round, a
/// letter's jump), a long list scrolls just enough to show that row.
class TermTypeAhead extends StatefulWidget {
  /// Walks [child]'s rows by letters.
  const TermTypeAhead({super.key, this.initial, required this.child});

  /// The row the focus goes to when the list comes up (the chosen one),
  /// among the rows that take it; null leaves it where the list puts it
  /// (its first row).
  final int? initial;

  /// The list.
  final Widget child;

  @override
  State<TermTypeAhead> createState() => _TermTypeAheadState();
}

class _TermTypeAheadState extends State<TermTypeAhead> {
  final _node = FocusNode(
    debugLabel: 'TermTypeAhead',
    canRequestFocus: false,
    skipTraversal: true,
  );
  var _typed = '';
  Timer? _pause;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_reveal);
    final first = widget.initial;
    if (first != null) {
      // After the list's own move of the focus to its first row, which also
      // waits for the frame that builds it to end.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final rows = _rows();
        if (first < rows.length) rows[first].requestFocus();
      });
    }
  }

  // The row with the focus, in view: scrolled no further than it takes, so
  // a row below comes up to the list's foot and one above down to its top.
  void _reveal() {
    final row = FocusManager.instance.primaryFocus;
    if (row == null ||
        identical(row, _node) ||
        !row.ancestors.contains(_node)) {
      return;
    }
    final context = row.context;
    if (context == null || !context.mounted) return;
    for (final policy in const [
      ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    ]) {
      Scrollable.ensureVisible(context, alignmentPolicy: policy);
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_reveal);
    _pause?.cancel();
    _node.dispose();
    super.dispose();
  }

  // The rows that take the focus, in order: what the arrows walk.
  List<FocusNode> _rows() => _node.traversalDescendants
      .where((n) => n.canRequestFocus && !n.skipTraversal)
      .toList();

  static String _words(FocusNode row) {
    final context = row.context;
    if (context == null) return '';
    String? found;
    void visit(Element e) {
      if (found != null) return;
      final w = e.widget;
      if (w is TermMenuRow) {
        found = w.label;
      } else if (w is Text) {
        found = w.data ?? w.textSpan?.toPlainText() ?? '';
      } else {
        e.visitChildren(visit);
      }
    }

    visit(context as Element);
    return found ?? '';
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final letter = event.character;
    final keys = HardwareKeyboard.instance;
    // Space and Return press a row, as anywhere; a shortcut is no letter.
    if (letter == null ||
        letter.trim().isEmpty ||
        letter.codeUnitAt(0) < 0x20 ||
        letter.codeUnitAt(0) == 0x7f ||
        keys.isControlPressed ||
        keys.isMetaPressed ||
        keys.isAltPressed) {
      return KeyEventResult.ignored;
    }
    _pause?.cancel();
    _pause = Timer(const Duration(milliseconds: 700), () => _typed = '');
    _typed += letter.toLowerCase();
    final rows = _rows();
    final n = rows.length;
    final here = rows.indexWhere((x) => x.hasPrimaryFocus);
    // One letter, or the same one again: the next row it starts. A run of
    // letters: the row it starts, this one first.
    final same = _typed.split('').every((c) => c == _typed[0]);
    final words = same ? _typed[0] : _typed;
    final from = same ? here + 1 : math.max(here, 0);
    for (var k = 0; k < n; k++) {
      final row = rows[(from + k) % n];
      if (_words(row).trimLeft().toLowerCase().startsWith(words)) {
        row.requestFocus();
        break;
      }
    }
    // A letter that starts no row is still the list's: it never reaches the
    // page under it.
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _node,
    includeSemantics: false,
    onKeyEvent: _onKey,
    child: widget.child,
  );
}
