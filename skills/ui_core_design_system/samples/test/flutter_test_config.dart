import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

// Every test runs with leak tracking, as Flutter's own do: a controller, a
// focus node or a notifier the design makes and never disposes fails the test.
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
