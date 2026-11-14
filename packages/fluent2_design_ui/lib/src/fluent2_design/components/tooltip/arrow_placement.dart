/// Where a tooltip's or a popover's arrow stands.
library;

/// Where the arrow of a tooltip or a popover stands this frame: written
/// by the layout that places the bubble, read when it paints. Plumbing of
/// the tooltip and the popover.
///
/// ```dart
/// Fluent2ArrowPlacement()..offset = 24
/// ```
class Fluent2ArrowPlacement {
  /// Whether the bubble stands above its control (the arrow at its foot).
  bool isAbove = true;

  /// The arrow's centre from the bubble's left edge.
  double offset = 0;
}
