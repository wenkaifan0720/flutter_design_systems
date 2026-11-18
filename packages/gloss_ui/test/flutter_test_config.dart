// Every test here runs with leak tracking, as Flutter's own do: a
// ChangeNotifier, a controller, a focus node or a picture a test or the
// package makes and never disposes fails the test that made it. What the
// test helpers make (a tester's own objects) is theirs to track.
//
// A look copies this file into its package's test/ (with
// leak_tracker_flutter_testing among its dev dependencies).
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
