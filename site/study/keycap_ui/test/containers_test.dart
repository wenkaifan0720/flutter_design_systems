import 'package:keycap_ui/keycap_ui.dart';
import 'package:stint_keycap/stint_keycap.dart';

import '../../stint_core/test/support/containers.dart';

/// Keycap cuts its containers into the case as page wells: a group of rows,
/// a card, the timer's window. A well is a hole in the plate, so none may
/// be cut into another; a field's or a chart's small well is a control, not
/// a container.
void main() => checkContainers(
  look: 'Keycap',
  app: (launch, repository) =>
      StintKeycap(launch: launch, repository: repository),
  kind: (widget) => widget is KeycapWell && widget.page ? 'well' : null,
  padding: (widget) => widget is KeycapWell ? widget.padding : null,
);
