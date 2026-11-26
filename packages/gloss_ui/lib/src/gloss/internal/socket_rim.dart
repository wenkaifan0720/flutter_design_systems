import 'package:flutter/widgets.dart';

import '../theme.dart';

/// The fine rim round a socket's mouth, so an empty one (a box not ticked,
/// a dot not chosen, a step to come) reads on its ground, day and night;
/// fainter when off.
Color glossSocketRim(GlossColors c, {bool disabled = false}) {
  final light = c.brightness == Brightness.light;
  if (disabled) {
    return light ? const Color(0x1A000000) : const Color(0x1AFFFFFF);
  }
  return light ? const Color(0x33000000) : const Color(0x33FFFFFF);
}
