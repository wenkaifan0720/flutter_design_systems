// Every test here runs with leak tracking, as Flutter's own do: a
// ChangeNotifier, a controller, a focus node or a picture a test or the
// package makes and never disposes fails the test that made it. What the
// test helpers make (a tester's own objects, and what the framework makes
// inside a helper's gesture, as a drag's recognizer) is theirs to track, as
// in Flutter's own config: tracked, ui_core's reorderable list and swipe
// row tests fail on the recognizer a drag makes.
//
// ui_core's template (design-kit/files/test/flutter_test_config.dart);
// look:package adds leak_tracker_flutter_testing to the dev dependencies.
// Minimal's walks of whole gallery pages and app screens take the long
// walk's (below): tracked, a file of them grew test by test to 3.4 GB in
// one process and ran two and a half times as long. Each part's own tests,
// and the apps' happy path, keep tracking; the inventory walks run in
// drip's app too, under drip's own config, and keep it.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (!kIsWeb) {
    LeakTesting.enable();
    LeakTracking.warnForUnsupportedPlatforms = false;
    LeakTesting.settings = LeakTesting.settings.withIgnored(
      createdByTestHelpers: true,
    );
  }
  await testMain();
}

/// The leak tracking a test that walks a whole gallery in one go runs
/// under: none of its own. Telling the test helpers' objects apart keeps a
/// stack trace for every object a test makes, and a walk makes enough of
/// them to run out of memory; each part's own tests keep tracking it. Pass
/// it as the walk's `experimentalLeakTesting:`, importing this file:
///
/// ```dart
/// import 'flutter_test_config.dart' show longWalkLeakTesting;
///
/// testWidgets('every page draws', (tester) async {
///   // ...
/// }, experimentalLeakTesting: longWalkLeakTesting);
/// ```
LeakTesting get longWalkLeakTesting => LeakTesting.settings.withIgnoredAll();
