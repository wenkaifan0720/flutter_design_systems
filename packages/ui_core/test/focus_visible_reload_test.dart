// What ui_core hears focus by, over a binding that outlives it: App
// Preview draws each page with ui_core instantiated afresh (its statics
// new) over one Flutter framework, whose pointer router, keyboard and
// semantics binding live on. DesignFocusVisible.debugForget stands for that
// fresh instance. Each page watches without an assertion, and leaves
// nothing registered once it goes.
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/src/internal/focus_visible.dart';
import 'package:ui_core/ui_core.dart';

Widget _page(int page) => Directionality(
  key: ValueKey(page),
  textDirection: TextDirection.ltr,
  child: Center(
    child: RawButton(
      semanticLabel: 'Book $page',
      onPressed: () {},
      builder: (context, states, _) => const SizedBox(width: 120, height: 44),
    ),
  ),
);

Future<void> _press(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    const Offset(5, 5),
    kind: PointerDeviceKind.mouse,
  );
  await gesture.up();
  await tester.pump();
}

int get _routes => GestureBinding.instance.pointerRouter.debugGlobalRouteCount;

void main() {
  testWidgets('page after page, each with fresh statics: each draws, the '
      'input decides on each, and the last leaves no route', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final before = _routes;
    for (var page = 0; page < 4; page++) {
      DesignFocusVisible.debugForget();
      await tester.pumpWidget(_page(page));
      expect(tester.takeException(), isNull, reason: 'page $page');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(DesignFocusVisible.shown, isTrue, reason: 'page $page');
      await _press(tester);
      expect(DesignFocusVisible.shown, isFalse, reason: 'page $page');
    }
    await tester.pumpWidget(const SizedBox());
    expect(_routes, before);
  });

  testWidgets('fresh statics while the last page still stands: the new page '
      'draws beside it, and both leave no route', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final before = _routes;
    await tester.pumpWidget(Column(children: [_page(0)]));
    DesignFocusVisible.debugForget();
    await tester.pumpWidget(Column(children: [_page(0), _page(1)]));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Column(children: [_page(1)]));
    await tester.pumpWidget(const SizedBox());
    expect(_routes, before);
  });
}
