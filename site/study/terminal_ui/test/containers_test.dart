import 'package:stint_terminal/stint_terminal.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../../stint_core/test/support/containers.dart';

/// A terminal frames a pane in box lines; a pane drawn inside another is a
/// frame in a frame. What a pane holds is set on its keyline instead.
void main() => checkContainers(
  look: 'Terminal',
  app: (launch, repository) =>
      StintTerminal(launch: launch, repository: repository),
  kind: (widget) => widget is TermPane ? 'pane' : null,
);
