import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A CSS `box-shadow` as Flutter draws one: CSS blurs a shadow to a
/// standard deviation of half its blur radius, Flutter's radius maps to
/// `0.57735 r + 0.5`. Plumbing of the components; pages never place one.
BoxShadow ledgerShadow({
  required Color color,
  double x = 0,
  double y = 0,
  double blur = 0,
  double spread = 0,
}) => BoxShadow(
  offset: Offset(x, y),
  blurRadius: blur <= 0 ? 0 : math.max(0, (blur / 2 - 0.5) / 0.57735),
  spreadRadius: spread,
  color: color,
);

/// The Gaussian sigma of a CSS blur of [blur] (`filter: blur()`, a
/// shadow's blur radius halved), for a [MaskFilter] or an image filter.
double ledgerSigma(double blur) => blur / 2;
