import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// A toaster round one pane: at a desk, a list/detail's detail holds its own
// RawToaster, as Material scopes a ScaffoldMessenger round a pane. A toast
// shown from the pane stands in it, centred on it and above its kept foot;
// the rest of the app keeps the app's toaster, which the pane's foot does
// not lift. (0.6.1's desk report: a toaster round the app centres a pane's
// toast on the window, over the list and the detail.)

final _app = GlobalKey<RawToasterState>();
final _list = GlobalKey();
final _pane = GlobalKey();
final _save = FocusNode(debugLabel: 'Save');

Widget _toastFace(BuildContext context, RawToastDetails details) => SizedBox(
  key: ValueKey('toast ${details.toast.message}'),
  height: 48,
  child: Text(details.toast.message),
);

Rect _toast(WidgetTester tester, String message) =>
    tester.getRect(find.byKey(ValueKey('toast $message')));

// 1440 by 900: a list 455 wide beside a detail pane with a toaster of its
// own round it and a foot (80) the toaster keeps clear.
Future<void> _pump(
  WidgetTester tester, {
  TextDirection textDirection = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    harness(
      Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(key: _list, width: 455),
          Expanded(
            child: RawToaster(
              toastBuilder: _toastFace,
              child: Column(
                key: _pane,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(child: SizedBox.expand()),
                  RawToasterKeepClear(
                    child: SizedBox(
                      key: const ValueKey('foot'),
                      height: 80,
                      child: Focus(focusNode: _save, child: const SizedBox()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      textDirection: textDirection,
      wrap: (context, navigator) =>
          RawToaster(key: _app, toastBuilder: _toastFace, child: navigator!),
    ),
  );
}

Future<void> _show(WidgetTester tester, GlobalKey from, String message) async {
  RawToaster.of(from.currentContext!)
      .show(RawToast(message: message, duration: null));
  await tester.pumpAndSettle();
}

void main() {
  tearDownAll(_save.dispose);

  for (final direction in TextDirection.values) {
    testWidgets("a pane's toast stands in the pane, centred on it, above its "
        'foot (${direction.name})', (tester) async {
      await _pump(tester, textDirection: direction);
      await _show(tester, _pane, 'Changes saved');
      final pane = tester.getRect(find.byKey(_pane));
      final foot = tester.getRect(find.byKey(const ValueKey('foot')));
      final toast = _toast(tester, 'Changes saved');
      expect(pane.width, 1440 - 455);
      expect(
        pane.left,
        direction == TextDirection.ltr ? 455 : 0,
        reason: 'the pane follows the reading order',
      );
      expect(toast.center.dx, moreOrLessEquals(pane.center.dx));
      expect(toast.left, greaterThanOrEqualTo(pane.left));
      expect(toast.right, lessThanOrEqualTo(pane.right));
      expect(toast.width, 560, reason: "the toaster's width cap");
      expect(toast.bottom, foot.top - 16, reason: 'above the foot it keeps');
    });
  }

  testWidgets("the rest of the app keeps the app's toaster, which the pane's "
      'foot does not lift', (tester) async {
    await _pump(tester);
    expect(RawToaster.of(_list.currentContext!), same(_app.currentState));
    expect(
      RawToaster.of(_pane.currentContext!),
      isNot(same(_app.currentState)),
    );
    await _show(tester, _list, 'Sent');
    final toast = _toast(tester, 'Sent');
    expect(toast.center.dx, 720, reason: 'centred on the window');
    expect(
      toast.bottom,
      900 - 16,
      reason:
          'the pane keeps its foot clear, '
          'not the window',
    );
    await _show(tester, _pane, 'Changes saved');
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('Changes saved'), findsOneWidget);
    expect(
      _toast(tester, 'Changes saved').center.dx,
      moreOrLessEquals(455 + (1440 - 455) / 2),
    );
  });

  testWidgets("F6 from the pane reaches the pane's toast; Escape goes back", (
    tester,
  ) async {
    await _pump(tester);
    await _show(tester, _pane, 'Changes saved');
    _save.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pump();
    final focus = FocusManager.instance.primaryFocus!;
    expect(focus.debugLabel, 'RawToast');
    expect(
      focus.rect.contains(_toast(tester, 'Changes saved').center),
      isTrue,
      reason: "the pane's toast",
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Changes saved'), findsNothing);
    expect(_save.hasFocus, isTrue);
  });
}
