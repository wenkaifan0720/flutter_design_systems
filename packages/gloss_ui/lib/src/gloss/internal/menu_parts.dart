/// What Gloss's floating lists share: the porcelain panel a menu, a select's
/// list, a combobox's list or the palette stands on, and the plate a row
/// stands on when it is lit, pressed or chosen.
library;

import 'package:flutter/widgets.dart';

import '../surface.dart';
import '../theme.dart';

/// The corner of a floating list's panel.
const double glossPanelCorner = 16;

/// The inset between a floating list's panel and its rows, all round.
const double glossPanelInset = 4;

/// The raised porcelain a floating list stands on, in [c].
GlossFace glossPanelFace(GlossColors c, {double radius = glossPanelCorner}) {
  final light = c.brightness == Brightness.light;
  return GlossFace.porcelain(c, radius: radius).copyWith(
    lift: 1,
    top: light ? const Color(0xFFFFFFFF) : const Color(0xFF343A41),
    middle: light ? const Color(0xFFF8F9FA) : const Color(0xFF2C3137),
    bottom: light ? const Color(0xFFF3F5F7) : const Color(0xFF282C32),
  );
}

/// A row's plate in a floating list, in [c]: clear at rest, a pale glaze
/// when [lit] (the pointer's or the keys' row), pressed into a well under a
/// press. Concentric with the panel: its corner is the panel's less the
/// inset.
GlossFace glossRowPlate(
  GlossColors c, {
  required bool lit,
  required bool pressed,
  double? radius = glossPanelCorner - glossPanelInset,
}) {
  final light = c.brightness == Brightness.light;
  if (pressed) {
    return GlossFace.well(c, radius: radius).copyWith(lift: -0.8);
  }
  if (lit) {
    return GlossFace(
      top: light ? const Color(0xFFE9EEF2) : const Color(0xFF3A4048),
      middle: light ? const Color(0xFFE6EBF0) : const Color(0xFF373D44),
      bottom: light ? const Color(0xFFE2E8ED) : const Color(0xFF343A40),
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
