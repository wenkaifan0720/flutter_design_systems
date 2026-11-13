/// What a look's app chrome is drawn from: its tabs and main action, its background and insets, the preview frame
/// and platform, the media slot and the English formats. A look's package re-exports it from its host library
/// (`<look>_host.dart`), not its main library.
library;

export 'src/chrome_data.dart';
export 'src/format.dart';
export 'src/media_slot.dart';
export 'src/preview.dart';
