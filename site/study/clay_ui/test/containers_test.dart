import 'package:clay_ui/clay_ui.dart';
import 'package:stint_clay/stint_clay.dart';

import '../../stint_core/test/support/containers.dart';

/// Clay holds a screen's things in large raised slabs on the ground. A slab
/// pressed onto another reads as a box in a box, so none may sit in
/// another. A slab is drawn at Clay's large corner; a key, a bead or a
/// state's ball is rounder or smaller, and is a part, not a slab.
void main() => checkContainers(
  look: 'Clay',
  app: (launch, repository) =>
      StintClay(launch: launch, repository: repository),
  kind: (widget) {
    final face = switch (widget) {
      ClaySurface(:final face) => face,
      AnimatedClaySurface(:final face) => face,
      _ => null,
    };
    return face != null && face.elevation > 0 && face.radius == ClayRadius.large
        ? 'slab'
        : null;
  },
);
