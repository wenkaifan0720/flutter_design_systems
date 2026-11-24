// Escape closes each modal route whose barrier does not dismiss, however the
// focus sits: on the route's own scope (nothing in it took the focus), or
// inside it; and a PopScope still refuses it.
import 'dart:async' show unawaited;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _page = ValueKey('page');

// Each route, its barrier not dismissing, holding [child].
final _routes = <String, PopupRoute<void> Function(Widget child)>{
  'dialog': (child) => RawModalDialogRoute<void>(
    barrierDismissible: false,
    builder: (context, details) => Center(child: child),
  ),
  'alert': (child) => RawModalDialogRoute<void>(
    isAlert: true,
    builder: (context, details) => Center(child: child),
  ),
  'bottom sheet': (child) => RawBottomSheetRoute<void>(
    barrierDismissible: false,
    builder: (context, details) => child,
  ),
  'side sheet': (child) => RawSideSheetRoute<void>(
    barrierDismissible: false,
    builder: (context, sheet) => child,
  ),
};

Future<(NavigatorState, PopupRoute<void>)> _open(
  WidgetTester tester,
  PopupRoute<void> Function(Widget child) make,
  Widget child,
) async {
  await tester.pumpWidget(harness(const SizedBox.expand()));
  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  final route = make(child);
  unawaited(navigator.push(route));
  await tester.pumpAndSettle();
  expect(find.byKey(_page), findsOneWidget);
  expect(route.barrierDismissible, isFalse);
  return (navigator, route);
}

// Whether the focus rests on a route's own scope (Flutter's, labelled for
// its modal scope), nothing in the route holding it.
bool _onRouteScope() {
  final focus = FocusManager.instance.primaryFocus;
  return focus is FocusScopeNode &&
      (focus.debugLabel ?? '').contains('ModalScopeState');
}

void main() {
  for (final MapEntry(key: name, value: make) in _routes.entries) {
    group(name, () {
      testWidgets('Escape closes it with nothing in it focused: the focus '
          "on the route's own scope", (tester) async {
        await _open(
          tester,
          make,
          const SizedBox(key: _page, width: 200, height: 200),
        );
        expect(_onRouteScope(), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byKey(_page), findsNothing);
      });

      testWidgets('Escape closes it with the focus inside it', (tester) async {
        await _open(
          tester,
          make,
          const Focus(
            autofocus: true,
            child: SizedBox(key: _page, width: 200, height: 200),
          ),
        );
        expect(_onRouteScope(), isFalse);
        expect(
          FocusManager.instance.primaryFocus,
          isNot(isA<FocusScopeNode>()),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byKey(_page), findsNothing);
      });

      testWidgets('a PopScope refuses Escape at the scope; Shift+Escape '
          'is not Escape', (tester) async {
        var refused = 0;
        await _open(
          tester,
          make,
          PopScope<void>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) => refused++,
            child: const SizedBox(key: _page, width: 200, height: 200),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byKey(_page), findsOneWidget);
        expect(refused, 1);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(refused, 1);
      });
    });
  }

  testWidgets('Escape at the scope of a route under another goes to the top '
      'one alone', (tester) async {
    final (navigator, under) = await _open(
      tester,
      _routes['dialog']!,
      const SizedBox(key: _page, width: 200, height: 200),
    );
    final top = _routes['side sheet']!(
      const SizedBox(key: ValueKey('top'), width: 100, height: 100),
    );
    unawaited(navigator.push(top));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('top')), findsNothing);
    expect(find.byKey(_page), findsOneWidget);
    expect(under.isCurrent, isTrue);
  });
}
