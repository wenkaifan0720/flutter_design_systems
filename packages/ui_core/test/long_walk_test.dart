// The long walk's leak tracking (flutter_test_config.dart's
// longWalkLeakTesting): a test that walks a whole gallery passes it and
// tracks no leaks of its own; every other test keeps the config's.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import 'flutter_test_config.dart' show longWalkLeakTesting;

void main() {
  test('a long walk tracks no leaks of its own; the other tests still do', () {
    expect(longWalkLeakTesting.ignore, isTrue);
    expect(longWalkLeakTesting.ignoredLeaks, LeakTesting.settings.ignoredLeaks);
    if (!kIsWeb) expect(LeakTesting.settings.ignore, isFalse);
  });

  testWidgets('a walk passes it as its own leak testing', (tester) async {
    await tester.pumpWidget(const SizedBox());
    expect(find.byType(SizedBox), findsOneWidget);
  }, experimentalLeakTesting: longWalkLeakTesting);
}
