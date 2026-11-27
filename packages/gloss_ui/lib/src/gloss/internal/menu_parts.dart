/// What Gloss's floating lists share: the porcelain panel a menu, a select's
/// list, a combobox's list or the palette stands on, and the plate a row
/// stands on when it is lit, pressed or chosen.
library;

import 'package:flutter/widgets.dart';

import '../surface.dart';
import '../theme.dart';

/// The corner of a floating list's panel in Gloss's own shapes: the default
/// scheme's medium step.
@Deprecated(
  'Read the theme\'s corner, GlossTheme.of(context).shapeScheme.corners.medium, '
  'which follows a theme\'s shapeScheme. Removed in 0.7.0.',
)
const double glossPanelCorner = 16;

/// The inset between a floating list's panel and its rows, all round.
const double glossPanelInset = 4;

/// The raised porcelain a floating list stands on, in [c], its corner
/// [radius]: a floating list's is the theme's medium step
/// (`glossCorner(theme, RawCorner.medium)`); left out, Gloss's own, 16.
GlossFace glossPanelFace(GlossColors c, {double radius = 16}) {
  final light = c.brightness == Brightness.light;
  return GlossFace.porcelain(c, radius: radius).copyWith(
    lift: 1,
    top: light ? const Color(0xFFFFFFFF) : const Color(0xFF343A41),
    middle: light ? const Color(0xFFF8F9FA) : const Color(0xFF2C3137),
    bottom: light ? const Color(0xFFF3F5F7) : const Color(0xFF282C32),
  );
}

/// A row's plate in a floating list, in [c]: clear at rest, a pale glaze
/// when [lit] (the pointer's or the keys' row), by day as by night, deep
/// enough to tell from the rows beside it at a glance; pressed into a well
/// under a press. Concentric with the panel: its corner [radius] is the
/// panel's less [glossPanelInset]; left out, Gloss's own panel's, 12.
GlossFace glossRowPlate(
  GlossColors c, {
  required bool lit,
  required bool pressed,
  double? radius = 16 - glossPanelInset,
}) {
  final light = c.brightness == Brightness.light;
  if (pressed) {
    return GlossFace.well(c, radius: radius).copyWith(lift: -0.8);
  }
  if (lit) {
    return GlossFace(
      top: light ? const Color(0xFFDFE5EA) : const Color(0xFF4E545C),
      middle: light ? const Color(0xFFDBE2E8) : const Color(0xFF4A5058),
      bottom: light ? const Color(0xFFD7DEE4) : const Color(0xFF464C54),
      foreground: c.ink,
      radius: radius,
    );
  }
  final clear = c.well.withValues(alpha: 0);
  return GlossFace(
    top: clear,
    middle: clear,
    bottom: clear,
    foreground: c.ink,
    radius: radius,
  );
}
