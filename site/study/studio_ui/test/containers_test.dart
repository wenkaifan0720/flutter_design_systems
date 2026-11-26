import 'package:stint_studio/stint_studio.dart';
import 'package:studio_ui/studio_ui.dart';

import '../../stint_core/test/support/containers.dart';

/// Studio builds in two materials: a raised panel, and glass set into it.
/// Glass may sit in a panel, as an instrument's window does; nothing else
/// nests: a panel on glass, glass in glass or a panel in a panel draws a
/// second outline inside the first.
void main() => checkContainers(
  look: 'Studio',
  app: (launch, repository) =>
      StintStudio(launch: launch, repository: repository),
  kind: (widget) => switch (widget) {
    StudioPanel() => 'panel',
    StudioDisplay() => 'glass',
    _ => null,
  },
  allowed: (inner, outer) => inner == 'glass' && outer == 'panel',
  padding: (widget) => switch (widget) {
    StudioPanel(:final padding) => padding,
    StudioDisplay(:final padding) => padding,
    _ => null,
  },
);
