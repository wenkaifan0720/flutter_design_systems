// How crowded labels thin: a chart's steps along its foot, its figures up
// its scale.

/// The stride (every label, every other, every third...) at which [n]
/// labels in a row stand evenly with room between them: the least at which
/// [fits] holds, so as many stand as there is room for, then widened as far
/// as it keeps as many, so they reach as near the far end as they can (a
/// week with room for two keeps Mon and Sun, not Mon and Sat; a scale, 0
/// and its top). Null when not even the first fits alone.
int? glossLabelStride(int n, bool Function(int every) fits) {
  for (var every = 1; every <= (n < 1 ? 1 : n); every++) {
    if (!fits(every)) continue;
    // Kept: the first, then every [every]th up to the last.
    final kept = (n - 1) ~/ every + 1;
    if (kept > 1) {
      for (var wide = (n - 1) ~/ (kept - 1); wide > every; wide--) {
        if (fits(wide)) return wide;
      }
    }
    return every;
  }
  return null;
}
