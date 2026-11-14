/// WCAG 2 contrast, the measure a theme's colour pairs are held to
/// (CONTRACT §2 "Color"): [expressiveContrastRatio] of two colours, and
/// [ExpressiveContrast.contrastShortfalls] of a whole scheme. Shared by
/// Expressive's own colour tests and an example app's tests of its own
/// themes and colours (docs/architecture/example-apps-plan.md §4.1), so
/// every theme is read against one definition.
library;

import 'package:flutter/widgets.dart';

import 'color.dart';

/// WCAG 2's contrast ratio of two opaque colours: from 1 (the same
/// luminance) to 21 (black on white), whichever is lighter.
double expressiveContrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// The pairs a scheme is held to, read together.
extension ExpressiveContrast on ExpressiveColorScheme {
  /// Every pair that reads below its floor, by name (`content on primary`,
  /// `onSurfaceVariant on surfaceContainerHighest`, `outline on surface`)
  /// with its ratio; empty when every pair holds.
  ///
  /// The pairs: each role's content colour as Compose pairs them
  /// ([ExpressiveColorScheme.contentColorFor]) and `onSurfaceVariant` on
  /// `surfaceContainerHighest`, held to [content]; `outline` on `surface`,
  /// a boundary, held to [boundary]. The defaults are the 2025 spec's at
  /// contrast 0 (4.5:1 and 3:1); at contrast 1 every pair reaches 7:1.
  Map<String, double> contrastShortfalls({
    double content = 4.5,
    double boundary = 3,
  }) {
    final shortfalls = <String, double>{};
    void hold(String name, Color foreground, Color background, double floor) {
      final ratio = expressiveContrastRatio(foreground, background);
      if (ratio < floor) shortfalls[name] = ratio;
    }

    for (final background in ExpressiveColorRole.values) {
      final color = role(background);
      final onColor = contentColorFor(color);
      if (onColor == null) continue;
      hold('content on ${background.name}', onColor, color, content);
    }
    hold(
      'onSurfaceVariant on surfaceContainerHighest',
      onSurfaceVariant,
      surfaceContainerHighest,
      content,
    );
    hold('outline on surface', outline, surface, boundary);
    return shortfalls;
  }
}
