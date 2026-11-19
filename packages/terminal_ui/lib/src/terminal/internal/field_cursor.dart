/// The keyboard's cursor on a field that opens a choice rather than taking
/// typing (a select, a date field): its frame doubles, as every field's
/// does, and its value line stands under the cursor, as a choice's line in
/// a terminal's form does.
library;

import 'package:flutter/widgets.dart';

import '../primitives/control.dart';
import '../theme.dart';

/// [child], a field's value line, under the cursor by [focus]: a block of
/// the accent behind it, half a cell past it into the frame's padding. The
/// value's words take their colour from [inkOf].
class TermFieldCursor extends StatelessWidget {
  /// [child] under the cursor by [focus].
  const TermFieldCursor({super.key, required this.focus, required this.child});

  /// How far the keyboard's focus has come, 0 to 1.
  final double focus;

  /// The value line.
  final Widget child;

  /// The colour of words at [rest] inside the value line, under the cursor
  /// as far as it has come at [context].
  static Color inkOf(BuildContext context, Color rest) {
    final scope = context.dependOnInheritedWidgetOfExactType<_Scope>();
    return termCursorInk(TermTheme.of(context), rest, scope?.focus ?? 0);
  }

  @override
  Widget build(BuildContext context) => _Scope(
    focus: focus,
    child: TermCursorSpan(focus: focus, child: child),
  );
}

class _Scope extends InheritedWidget {
  const _Scope({required this.focus, required super.child});

  final double focus;

  @override
  bool updateShouldNotify(_Scope old) => old.focus != focus;
}
