/// Terminal-style Flutter controls on a monospace character grid.
///
/// Load the bundled fonts with [termLoadFonts] and wrap your application in
/// [TermTheme]. [TermThemeData.dark] and [TermThemeData.light] provide the
/// night and paper palettes. [TermPane], [TermButton] and [TermScaffold]
/// share box-drawn frames, inverse selection and keyboard navigation.
library;

export 'package:ui_core/ui_core.dart';

export 'src/terminal.dart';
