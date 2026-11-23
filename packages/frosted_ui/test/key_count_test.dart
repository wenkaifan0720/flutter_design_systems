// The menus' app-wide key count is a ValueListenable<int> that counts each
// key pressed and tells its listeners; it is no ChangeNotifier, so a
// leak-tracked test that reads it first stays leak free.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/src/frosted/internal/menu_wake.dart';

void main() {
  testWidgets('the key count counts each key and tells its listeners', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final ValueListenable<int> keys = FrostedLastInput.keys;
    expect(keys, isNot(isA<ChangeNotifier>()));
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

    keys.removeListener(hear);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    expect(keys.value, before + 3);
    expect(heard, 2);
  });
}
