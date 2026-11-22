// The menus' app-wide key count keeps the type it was published with, a
// ValueNotifier<int>, and counts each key pressed; it is no ChangeNotifier
// by descent, so a leak-tracked test that reads it first stays leak free.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/src/frosted/internal/menu_wake.dart';

void main() {
  testWidgets('the key count is a ValueNotifier that counts each key and '
      'tells its listeners', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final ValueNotifier<int> keys = FrostedLastInput.keys;
    FrostedLastInput.watch();
    final before = keys.value;
    var heard = 0;
    void hear() => heard++;
    keys.addListener(hear);
    addTearDown(() => keys.removeListener(hear));

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    expect(keys.value, before + 2);
    expect(heard, 2);
    expect(FrostedLastInput.keyed, isTrue);

    // Setting the same count tells no one; disposing leaves it counting.
    keys.value = keys.value;
    expect(heard, 2);
    keys.dispose();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    expect(keys.value, before + 3);
    expect(heard, 3);
  });
}
