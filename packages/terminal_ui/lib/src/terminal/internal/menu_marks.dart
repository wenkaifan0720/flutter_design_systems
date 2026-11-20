/// A menu's one current row: where the keys are, shown once the keys or the
/// pointer have moved in a menu the pointer opened, at once in one the keys
/// opened. The same for a select's list and a date field's calendar.
library;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Marks the rows of an open menu under [child] (a menu's, a split button's,
/// a menubar's): one row at a time is current, the one with the keys' focus,
/// and the pointer moving onto a row takes the focus there, so the pointer's
/// row and the keys' never read as two. A menu the pointer opened lights no
/// row until the pointer moves onto one or a key is pressed in it: ui_core
/// keeps the focus on the menu itself, so the first Down shows the first
/// row, Up the last, a letter the row it starts, and Return or Space choose
/// nothing unseen. A menu the keys opened shows its first row at once.
///
/// While the pointer moved the current row last, the row shows the
/// pointer's mark (its words in the accent), lighter than the keys' cursor;
/// the first key puts the cursor on it.
///
/// It sits between the menu's rows and whatever walks them by letters, so a
/// letter shows the row it jumps to.
///
/// A select's list and a date field's calendar take it too ([quietFirst]
/// false where something is chosen): opened by the pointer, the chosen
/// row's bar or day is all that reads current, the keys' mark showing with
/// the first key, which moves at once from the chosen one. Their pointer
/// leaves the keys where they are (the pointer's row has its own mark), so
/// only a key shows them.
class TermMenuMarks extends StatefulWidget {
  /// Marks [child]'s rows.
  const TermMenuMarks({super.key, this.quietFirst = true, required this.child});

  /// Whether, opened by the pointer, the first Down, Return or Space only
  /// shows the row the keys are on: true where nothing marks it (a menu, a
  /// select with nothing chosen); false where the chosen one does, so the
  /// first key moves from it.
  final bool quietFirst;

  /// The menu's rows.
  final Widget child;

  /// Notes from now on whether a key or a pointer's press came last, which
  /// tells a menu what opened it. A menu's anchor calls it as it builds.
  static void watchInput() => _LastInput.watch();

  /// Whether the keys' row shows in the menu round [context]; null outside
  /// a menu.
  static bool? shownOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Marks>()?.shown;

  /// Whether the pointer moved the current row of the menu round [context]
  /// last (no key since); null outside a menu.
  static bool? pointerLedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Marks>()?.pointerLed;

  /// Shows the keys' row in the menu round [context], cursor and all, as a
  /// key does. A row the pointer moves onto calls [point] instead.
  static void show(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_Marks>()?.state._show();

  /// Shows the current row in the menu round [context] as the pointer's, as
  /// the pointer moves onto a row.
  static void point(BuildContext context) => context
      .getInheritedWidgetOfExactType<_Marks>()
      ?.state
      ._show(pointer: true);

  @override
  State<TermMenuMarks> createState() => _TermMenuMarksState();
}

class _TermMenuMarksState extends State<TermMenuMarks> {
  late bool _shown = !_LastInput.pointerLast;
  bool _pointerLed = false;

  @override
  void initState() {
    super.initState();
    _LastInput.keys.add(_anyKey);
  }

  @override
  void dispose() {
    _LastInput.keys.remove(_anyKey);
    super.dispose();
  }

  void _show({bool pointer = false}) {
    if (!mounted || (_shown && _pointerLed == pointer)) return;
    setState(() {
      _shown = true;
      _pointerLed = pointer;
    });
  }

  // A key a row under it takes itself (a calendar's arrows), which never
  // reaches [_key]: shown once the key has done its work.
  void _anyKey() => scheduleMicrotask(_show);

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (_shown || event is! KeyDownEvent) return KeyEventResult.ignored;
    _show();
    if (!widget.quietFirst) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    includeSemantics: false,
    onKeyEvent: _key,
    child: _Marks(
      shown: _shown,
      pointerLed: _pointerLed,
      state: this,
      child: widget.child,
    ),
  );
}

class _Marks extends InheritedWidget {
  const _Marks({
    required this.shown,
    required this.pointerLed,
    required this.state,
    required super.child,
  });

  final bool shown;
  final bool pointerLed;
  final _TermMenuMarksState state;

  @override
  bool updateShouldNotify(_Marks old) =>
      shown != old.shown || pointerLed != old.pointerLed;
}

/// Whether a pointer's press came after the last key: the pointer opened
/// what opens now.
abstract final class _LastInput {
  static bool _routed = false;
  static bool pointerLast = false;

  /// Called on each key pressed: what shows its marks on any key. A plain
  /// set, not a notifier: it lives as long as the app.
  static final keys = <VoidCallback>{};

  static void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) pointerLast = true;
  }

  static bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      pointerLast = false;
      for (final heard in keys.toList()) {
        heard();
      }
    }
    return false;
  }

  static void watch() {
    if (!_routed) {
      _routed = true;
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    }
    // Taken off and put back, so it is there once whoever cleared the
    // keyboard's handlers (a test between its cases).
    HardwareKeyboard.instance
      ..removeHandler(_onKey)
      ..addHandler(_onKey);
  }
}
