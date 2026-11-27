// The measure a StudioScreen holds its parts to, for the bar over it.
import 'package:flutter/widgets.dart';

/// The widest a page's column stands on a wide window: a [StudioScreen]
/// sets it over its bar, and the bar's title and actions keep to it.
class PageMeasure extends InheritedWidget {
  /// [maxWidth] over [child].
  const PageMeasure({super.key, required this.maxWidth, required super.child});

  /// The column's widest.
  final double maxWidth;

  /// The measure over [context], if a page set one.
  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageMeasure>()?.maxWidth;

  /// [child] centred on [maxWidth], or as it is with no measure.
  static Widget hold(BuildContext context, Widget child) {
    final measure = maybeOf(context);
    if (measure == null) return child;
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: measure),
        child: child,
      ),
    );
  }

  @override
  bool updateShouldNotify(PageMeasure oldWidget) =>
      maxWidth != oldWidget.maxWidth;
}
