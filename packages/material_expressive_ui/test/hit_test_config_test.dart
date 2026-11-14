import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flutter_test_config.dart makes hit-test warnings fatal here', () {
    expect(WidgetController.hitTestWarningShouldBeFatal, isTrue);
  });
}
