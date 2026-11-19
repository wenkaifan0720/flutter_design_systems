// A toast never runs off the screen. At twice the text on a phone held
// sideways, a long toast, or one leaving as the next comes, is taller than
// the room: the toasts scroll, the newest in sight at the foot, and nothing
// overflows.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const _long =
    'Your settings are saved. We will send a reminder 30 days before your '
    'permit ends, by email and by text, to the address and number you gave.';

void main() {
  testWidgets('toasts taller than the screen scroll, the newest in sight', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late BuildContext page;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(844, 390),
          textScaler: TextScaler.linear(2),
        ),
        child: MaterialApp(
          builder: (context, child) => CivicHost(child: child!),
          home: CivicScreen(
            body: Builder(
              builder: (context) {
                page = context;
                return const Text('Your permit');
              },
            ),
          ),
        ),
      ),
    );
    CivicToast.show(page, _long);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    // The next comes as the first leaves.
    CivicToast.show(page, 'Saved');
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    }
    final newest = tester.getRect(find.text('Saved'));
    expect(newest.top, greaterThanOrEqualTo(0));
    expect(newest.bottom, lessThanOrEqualTo(390));
    await tester.pump(const Duration(seconds: 10));
  });
}
