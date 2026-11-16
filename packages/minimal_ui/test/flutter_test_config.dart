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
// Minimal's gallery walks are a test per page, and its inventory walks run
// in drip's app too, under drip's own config: none takes the long walk's.
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
