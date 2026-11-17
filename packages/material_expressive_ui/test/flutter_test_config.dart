// Expressive's own tests run with hit-test warnings fatal: a tap that lands
// on something other than the widget the finder named (a label or an icon
// under a pressable's ink) fails the test instead of warning, so each test
// taps the pressable itself (support/pressable.dart). The auth kit's tests
// over Expressive's rendition run in the kit's own composed project, as the
// kit wrote them, without this file.
//
// And with leak tracking, as ui_core's and Flutter's own do: a
// ChangeNotifier, a controller, a focus node or a picture a test or the
// package makes and never disposes fails the test that made it. What the
// test helpers make (a tester's own objects) is theirs to track.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
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
/// under, as ui_core's config has it: none of its own. Telling the test
/// helpers' objects apart keeps a stack trace for every object a test makes,
/// and a walk makes enough of them to run out of memory; each part's own
/// tests keep tracking it. A walk passes it as its `experimentalLeakTesting:`.
LeakTesting get longWalkLeakTesting => LeakTesting.settings.withIgnoredAll();

/// The leak tracking a file of whole-page tests runs under (a gallery walk:
/// every page in every preset, setting or language): every object tracked,
/// the test helpers' too, without the stack trace that telling them apart
/// keeps for each one. Those stack traces grew a walk's tester by 25 MB a
/// test, past 4 GB in a quarter of one file; tracked this way it stays near
/// 1 GB, and a leak in a page still fails the test that made it. A walk's
/// file sets it as its `main` starts.
LeakTesting get pageWalkLeakTesting =>
    LeakTesting.settings.withTracked(createdByTestHelpers: true);
