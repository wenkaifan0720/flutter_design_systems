import 'package:flutter/widgets.dart';

/// The measure a `MinimalScaffold` holds its page to, from the start edge:
/// its bar's title and actions read it, so they line up with the body.
class MinimalPageMeasure extends InheritedWidget {
  /// Publishes [maxWidth] to the page's chrome.
  const MinimalPageMeasure({
    super.key,
    required this.maxWidth,
    required super.child,
  });

  /// The widest the page's column grows, its own padding included.
  final double maxWidth;

  /// The measure round [context], or null when the page spans its box.
  static double? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MinimalPageMeasure>()
      ?.maxWidth;

  /// [child] held to [maxWidth] on the start edge, where the box it stands
  /// in is [inset] narrower than the page (its padding): whatever is past
  /// the measure becomes end padding, so a tight box stays tight. [child]
  /// itself when [maxWidth] is null.
  static Widget hold(
    Widget child, {
    required double? maxWidth,
    double inset = 0,
  }) {
    final measure = maxWidth;
    if (measure == null) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final excess = constraints.hasBoundedWidth
            ? (constraints.maxWidth + inset - measure).clamp(
                0.0,
                double.infinity,
              )
            : 0.0;
        return Padding(
          padding: EdgeInsetsDirectional.only(end: excess),
          child: child,
        );
      },
    );
  }

  @override
  bool updateShouldNotify(MinimalPageMeasure oldWidget) =>
      maxWidth != oldWidget.maxWidth;
}
