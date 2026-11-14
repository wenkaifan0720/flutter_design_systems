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
Color frostedRestRing(FrostedThemeData t) => _rings[t] ??= _ring(t);

final Expando<Color> _rings = Expando<Color>('frostedRestRing');

/// The share past 3:1 the ring keeps, so a ring drawn anti-aliased on a
/// wash still clears it.
const double _target = 3.2;

Color _ring(FrostedThemeData t) {
  final page = t.colorScheme.background.withValues(alpha: 1);
  final grounds = [
    page,
    Color.alphaBlend(t.colorScheme.surface, page),
    Color.alphaBlend(t.colorScheme.surfaceAlt, page),
    ...t.materials.grounds(),
  ];
  final from = Color.alphaBlend(t.colorScheme.borderStrong, grounds[1]);
  final quiet = Color.alphaBlend(t.colorScheme.textTertiary, grounds[1]);
  final ink = Color.alphaBlend(t.colorScheme.textPrimary, grounds[1]);
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
