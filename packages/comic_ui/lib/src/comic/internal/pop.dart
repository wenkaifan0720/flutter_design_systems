// A focused part that cannot lift off its row pops inside it.
import 'package:flutter/widgets.dart';

import '../theme.dart' show ComicTheme;

/// Marks [child] as a row standing edge to edge with its neighbours (a tree's row, a swipe row's plate): a focus pop
/// there cannot lift over them, so the part's print shows inside its outline instead.
class PopInside extends InheritedWidget {
  /// Creates a [PopInside].
  const PopInside({super.key, required super.child});

  /// Whether [context] stands inside a [PopInside].
  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PopInside>() != null;

  @override
  bool updateShouldNotify(PopInside oldWidget) => false;
}

/// How far a part lifts up and to the start under the keyboard's focus, off its print, in logical pixels, at a theme's
/// depth of 1.
const double comicFocusLift = 2;

/// Wraps the list a person types for in a focused field (a combobox's, a multi-select's): the field's face stands
/// [comicFocusLift] toward the start while it has the focus, and the list starts on the face as drawn, its words on
/// the field's. It keeps its height: the face's print stands under the face.
Widget comicListOnLiftedField(BuildContext field, Widget list) {
  if (PopInside.of(field)) return list;
  final end = Directionality.maybeOf(field) == TextDirection.rtl ? -1.0 : 1.0;
  return Transform.translate(
    offset: Offset(-end * comicFocusLift * ComicTheme.of(field).depth, 0),
    child: list,
  );
}
