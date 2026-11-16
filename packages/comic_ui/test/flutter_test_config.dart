// Every test here runs with leak tracking, as Flutter's own do: a
// ChangeNotifier, a controller, a focus node or a picture a test or the
// package makes and never disposes fails the test that made it.
//
// Copied from ui_core's template (its test/flutter_test_config.dart), less its
// `withIgnored(createdByTestHelpers: true)`: telling a test helper's objects
// apart keeps every tracked object's creation stack, which took one test
// file's process to 2.5 GB on macOS (0.66 GB without it) and past 7 GB under
// Linux's emulation, where the kernel killed it. Comic's tests pass without it.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (!kIsWeb) {
    LeakTesting.enable();
    LeakTracking.warnForUnsupportedPlatforms = false;
  }
  await testMain();
}
