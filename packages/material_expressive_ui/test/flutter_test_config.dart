// Expressive's own tests run with hit-test warnings fatal: a tap that lands
// on something other than the widget the finder named (a label or an icon
// under a pressable's ink) fails the test instead of warning, so each test
// taps the pressable itself (support/pressable.dart). The auth kit's tests
// over Expressive's rendition run in the kit's own composed project, as the
// kit wrote them, without this file.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
  await testMain();
}
