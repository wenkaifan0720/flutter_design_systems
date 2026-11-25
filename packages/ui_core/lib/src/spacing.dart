import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The step a look's spacing stands on: every padding, gap and spacing
/// token a multiple of [grid].
///
/// Most systems keep a 4 pt grid ([fallback]). A look that keeps a finer
/// one (iOS's and the classic Mac's 2 pt values: 6, 10, 14, 22) declares
/// it with a [RawSpacingScope] round the app, in its theme, beside its
/// `RawTapTargetScope`.
///
/// ```dart
/// RawSpacingScope(
///   spacing: const RawSpacing(grid: 2),
///   child: app,
/// )
/// ```
@immutable
class RawSpacing with Diagnosticable {
  /// A look's spacing on a [grid] of so many logical pixels.
  const RawSpacing({this.grid = 4})
    : assert(grid > 0, 'a spacing grid is positive');

  /// The spacing with no look's own: a 4 pt grid.
  static const RawSpacing fallback = RawSpacing();

  /// The step every spacing token is a multiple of.
  final double grid;

  /// The spacing in effect at [context]: the nearest [RawSpacingScope]'s,
  /// else [fallback].
  static RawSpacing of(BuildContext context) => maybeOf(context) ?? fallback;

  /// The nearest [RawSpacingScope]'s spacing, or null when there is none.
  static RawSpacing? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RawSpacingScope>()?.spacing;

  /// This with the given fields changed.
  RawSpacing copyWith({double? grid}) => RawSpacing(grid: grid ?? this.grid);

  @override
  bool operator ==(Object other) => other is RawSpacing && other.grid == grid;

  @override
  int get hashCode => grid.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('grid', grid, defaultValue: fallback.grid));
  }
}

/// Declares the [spacing] a look's parts stand on for the subtree, as a
/// theme does; [RawSpacing.of] reads it.
class RawSpacingScope extends InheritedTheme {
  /// Declares [spacing] for [child].
  const RawSpacingScope({
    super.key,
    required this.spacing,
    required super.child,
  });

  /// The spacing under it.
  final RawSpacing spacing;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      RawSpacingScope(spacing: spacing, child: child);

  @override
  bool updateShouldNotify(RawSpacingScope oldWidget) =>
      spacing != oldWidget.spacing;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<RawSpacing>('spacing', spacing));
  }
}
