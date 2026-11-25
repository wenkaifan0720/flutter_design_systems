import 'package:flutter/painting.dart' show Color;
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

final Expando<Map<(FrostedThemeData, Color, double), Color>> _quiet = Expando();

/// The page's grounds a hue's pane stands on, by [t]'s appearance: the
/// canvas, its glass, and each under the washes at their peak; each with
/// the hue's tint over it, and the pane's haze over that.
List<Color> frostedPaneGrounds(FrostedThemeData t, FrostedHue hue) {
  final page = t.colorScheme.background.withValues(alpha: 1);
  final glass = t.glass.fill;
  final peaks = t.lights.peaksOver(page, night: t.isDark);
  return [
    for (final under in [
      page,
      Color.alphaBlend(glass, page),
      ...peaks,
      for (final peak in peaks) Color.alphaBlend(glass, peak),
    ]) ...[
      Color.alphaBlend(hue.tint, under),
      Color.alphaBlend(t.sheens.paneHaze, Color.alphaBlend(hue.tint, under)),
    ],
  ];
}

/// A hue's quieter words on its pane (a share, a note, a due day): [ink] at
/// [opacity] where that reads 4.5:1 on every ground of the pane
/// ([frostedPaneGrounds]), else the nearest tone of it that does
/// (`RawPalette.readableTone`), else the nearest tone of [ink] itself. At
/// 72% and 80% of the hue's ink the words read 3.5-4.4:1 on a pearl tint by
/// day. Plumbing of the components.
Color frostedPaneQuiet(
  FrostedThemeData t,
  FrostedHue hue,
  Color ink,
  double opacity,
) {
  final held = _quiet[hue] ??= {};
  return held[(t, ink, opacity)] ??= () {
    final grounds = frostedPaneGrounds(t, hue);
    bool reads(Color c) =>
        grounds.every((g) => RawPalette.contrastRatio(c, g) >= 4.5);
    final quiet = RawPalette.readableTone(
      ink.withValues(alpha: ink.a * opacity),
      on: grounds,
    );
    return reads(quiet) ? quiet : RawPalette.readableTone(ink, on: grounds);
  }();
}
