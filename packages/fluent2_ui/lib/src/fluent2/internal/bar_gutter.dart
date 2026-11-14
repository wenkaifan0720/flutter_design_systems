import 'package:flutter/widgets.dart';

/// The page's gutter at a phone's pinned top bar: the screen hands it to
/// the bar instead of padding the bar itself, and the bar stands each end
/// that far in less the room its end part keeps round what it shows, so
/// the back arrow, the avatar's face and the last glyph meet the keylines
/// the page's words use while every target stays whole.
/// Plumbing of the screen and the bar; pages never place one.
class Fluent2BarGutter extends InheritedWidget {
  /// Hands [child]'s bar the page gutter at its [start] and [end].
  const Fluent2BarGutter({
    required this.start,
    required this.end,
    required super.child,
    super.key,
  });

  /// The gutter at the bar's start and at its end.
  final double start;

  /// The gutter at the bar's end.
  final double end;

  /// The gutter round [context]'s bar; null outside a screen's pinned bar
  /// (a bar placed on its own keeps to the room it is given).
  static Fluent2BarGutter? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Fluent2BarGutter>();

  @override
  bool updateShouldNotify(Fluent2BarGutter oldWidget) =>
      start != oldWidget.start || end != oldWidget.end;
}
