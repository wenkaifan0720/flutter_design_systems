import 'package:flutter/widgets.dart';

import '../theme.dart';

/// Marks the desktop content layer the shell stands its pages on: a layer
/// over the window's ground, the ground seen through a half-opaque
/// `neutralBackground1`, its top-start corner rounded where it meets the
/// nav pane. A page and a pushed route paint [groundOf] so they stand on
/// it there and on the ground elsewhere. Plumbing of the shell and the
/// screen; pages never place one.
class Fluent2Layer extends InheritedWidget {
  /// Marks [child] as standing on the desktop content layer.
  const Fluent2Layer({required super.child, super.key});

  /// The layer's fill in [t].
  static Color fillOf(Fluent2ThemeData t) => Color.alphaBlend(
    t.colors.neutralBackground1.withValues(alpha: 0.5),
    t.background,
  );

  /// Whether [context] stands on the desktop content layer.
  static bool around(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Fluent2Layer>() != null;

  /// The ground a page paints at [context]: the layer's fill on it, the
  /// ground elsewhere.
  static Color groundOf(BuildContext context) {
    final t = context.fluent2Theme;
    return around(context) ? fillOf(t) : t.background;
  }

  @override
  bool updateShouldNotify(Fluent2Layer oldWidget) => false;
}
