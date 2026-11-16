import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The step a look's spacing stands on: every padding, gap and spacing
/// token a multiple of [grid].
///
/// Most systems keep a 4 pt grid ([fallback]). A look that keeps a finer
/// one (iOS's and the classic Mac's 2 pt values: 6, 10, 14, 22) declares
/// it with a [DesignSpacingScope] round the app, in its theme, beside its
/// `DesignTapTargetScope`, and `DesignSpacingCheck` holds its sources to
/// it.
///
/// ```dart
/// DesignSpacingScope(
///   spacing: const DesignSpacing(grid: 2),
///   child: app,
/// )
/// ```
///
/// See also:
///
///  * `DesignSpacingCheck.literals`, which reads a look's sources for
///    spacing off its grid.
@immutable
class DesignSpacing with Diagnosticable {
  /// A look's spacing on a [grid] of so many logical pixels.
  const DesignSpacing({this.grid = 4})
    : assert(grid > 0, 'a spacing grid is positive');

  /// The spacing with no look's own: a 4 pt grid.
  static const DesignSpacing fallback = DesignSpacing();

  /// The step every spacing token is a multiple of.
  final double grid;

  /// The spacing in effect at [context]: the nearest [DesignSpacingScope]'s,
  /// else [fallback].
  static DesignSpacing of(BuildContext context) => maybeOf(context) ?? fallback;

  /// The nearest [DesignSpacingScope]'s spacing, or null when there is none.
  static DesignSpacing? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesignSpacingScope>()?.spacing;

  /// This with the given fields changed.
  DesignSpacing copyWith({double? grid}) =>
      DesignSpacing(grid: grid ?? this.grid);

  @override
  bool operator ==(Object other) =>
      other is DesignSpacing && other.grid == grid;

  @override
  int get hashCode => grid.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('grid', grid, defaultValue: fallback.grid));
  }
}

/// Declares the [spacing] a look's parts stand on for the subtree, as a
/// theme does; [DesignSpacing.of] reads it.
class DesignSpacingScope extends InheritedTheme {
  /// Declares [spacing] for [child].
  const DesignSpacingScope({
    super.key,
    required this.spacing,
    required super.child,
  });

  /// The spacing under it.
  final DesignSpacing spacing;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      DesignSpacingScope(spacing: spacing, child: child);

  @override
  bool updateShouldNotify(DesignSpacingScope oldWidget) =>
      spacing != oldWidget.spacing;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<DesignSpacing>('spacing', spacing));
  }
}
