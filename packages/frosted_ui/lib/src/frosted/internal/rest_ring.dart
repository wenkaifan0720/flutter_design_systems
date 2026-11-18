import 'dart:ui' show Color;

import '../theme.dart';

/// The ring a control wears where nothing else says it is there or what
/// state it is in ([FrostedThemeData.controlEdge]): an empty check, a radio,
/// a menu's check, an empty star, an off switch, a field's edge, the chosen
/// segment, tab or link. The theme's strong hairline, deepened toward its
/// quiet ink (and past it toward the ink, if it must) until it reads 3:1 on
/// the page, the surface, the wash and every glass over any backdrop (WCAG
/// 1.4.11, a control's boundary). Opaque, so it reads the same on glass.
/// Plumbing of the components.
Color frostedRestRing(FrostedThemeData t) => t.controlEdge;

/// The share past 3:1 the ring keeps, so a ring drawn anti-aliased on a
/// wash still clears it.
const double _target = 3.2;

/// [frostedRestRing] from the colours it reads: the page's [background], its
/// [surface] and [surfaceAlt] (the wash), the strong hairline
/// [borderStrong], the quiet ink [textTertiary] and the ink [textPrimary],
/// and the grounds of every [glass] (`FrostedMaterials.grounds`).
/// [FrostedThemeData.controlEdge] keeps it per theme, so a copy of the theme
/// draws its ring with no theme of the package's. Plumbing of the theme.
Color frostedRestRingOn({
  required Color background,
  required Color surface,
  required Color surfaceAlt,
  required Color borderStrong,
  required Color textTertiary,
  required Color textPrimary,
  required List<Color> glass,
}) {
  final page = background.withValues(alpha: 1);
  final grounds = [
    page,
    Color.alphaBlend(surface, page),
    Color.alphaBlend(surfaceAlt, page),
    ...glass,
  ];
  final from = Color.alphaBlend(borderStrong, grounds[1]);
  final quiet = Color.alphaBlend(textTertiary, grounds[1]);
  final ink = Color.alphaBlend(textPrimary, grounds[1]);
  for (final (a, b) in [(from, quiet), (quiet, ink)]) {
    for (var i = 0; i <= 40; i++) {
      final ring = Color.lerp(a, b, i / 40)!;
      if (grounds.every((g) => _contrast(ring, g) >= _target)) return ring;
    }
  }
  return ink;
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return la > lb ? (la + .05) / (lb + .05) : (lb + .05) / (la + .05);
}
