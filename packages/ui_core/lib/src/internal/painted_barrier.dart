import 'package:flutter/widgets.dart';

import '../barrier.dart';

/// [barrier], a route's own uncoloured one (it takes the taps and says the
/// label), over [paint]'s painting, which is only seen.
Widget paintedBarrier(
  RawBarrierBuilder paint,
  Animation<double> animation,
  Widget barrier,
) => Stack(
  fit: StackFit.expand,
  children: [
    IgnorePointer(
      child: ExcludeSemantics(
        child: Builder(builder: (context) => paint(context, animation)),
      ),
    ),
    barrier,
  ],
);
