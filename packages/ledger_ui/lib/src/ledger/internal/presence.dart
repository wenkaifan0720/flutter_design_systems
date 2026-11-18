import 'package:flutter/animation.dart';

/// A surface's presence on ui_core's springs (an overlay's, a route's)
/// clamped to 0 to 1: a spring can pass 1 before it rests, and an opacity
/// asserts outside 0 to 1.
final Animatable<double> ledgerPresence = Animatable<double>.fromCallback(
  (v) => v.clamp(0.0, 1.0),
);
