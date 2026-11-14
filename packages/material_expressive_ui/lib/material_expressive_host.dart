/// Material Expressive's host layer, for an app that shows the look's screens in a shell of its own: the scaffold every
/// look shares (`package:ui_core/host.dart`: its tabs, its main action, its background and insets, the
/// preview frame and platform) and Material Expressive's own part of it. An app that draws its screens from
/// `package:material_expressive_ui/material_expressive_ui.dart` does not need this library; the look's own chrome, gallery and tests import it
/// beside that one.
library;

export 'package:ui_core/host.dart';

export 'src/material_expressive/artwork.dart';
export 'src/material_expressive/chrome_metrics.dart';
export 'src/material_expressive/components/host.dart';
export 'src/material_expressive/components/page.dart';
export 'src/material_expressive/components/preview.dart';
export 'src/material_expressive/components/sheet_page.dart';
export 'src/material_expressive/components/shell_action.dart';
export 'src/material_expressive/components/shell_insets.dart';
export 'src/material_expressive/components/shell_scaffold.dart';
export 'src/material_expressive/format.dart';
export 'src/material_expressive/inventory.dart';
