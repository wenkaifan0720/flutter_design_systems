import 'package:flutter/widgets.dart';

/// Paints a modal part's barrier in place of its barrier colour: a look's
/// own screen over the page behind (Ben-Day dots, a blur, a grain).
///
/// [animation] is the route's, 0 (closed) to 1 (open), for the look's own
/// fade. The painting is only seen: the barrier under it still takes the
/// taps that dismiss and says its label to a screen reader.
typedef RawBarrierBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
);
