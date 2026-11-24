// RawModalRoute.closeOnEscape (0.6.0): a modal route Escape leaves open,
// for a dialog that must be answered with its own controls; Back still
// pops it, and a dialog route forwards the choice.
import 'dart:async' show unawaited;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _page = ValueKey('page');

Widget _body(BuildContext context, RawModalDetails details) => const Center(
  child: Focus(
    autofocus: true,
    child: SizedBox(key: _page, width: 200, height: 200),
  ),
);

Future<NavigatorState> _open(WidgetTester tester, Route<void> route) async {
  await tester.pumpWidget(harness(const SizedBox.expand()));
  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  unawaited(navigator.push(route));
  await tester.pumpAndSettle();
  expect(find.byKey(_page), findsOneWidget);
  return navigator;
}

void main() {
  testWidgets('by default Escape closes it', (tester) async {
    await _open(tester, RawModalRoute<void>(builder: _body));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(_page), findsNothing);
  });

  testWidgets('closeOnEscape false: Escape leaves it open, Back pops it', (
    tester,
  ) async {
    final navigator = await _open(
      tester,
      RawModalRoute<void>(closeOnEscape: false, builder: _body),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(_page), findsOneWidget);
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.byKey(_page), findsNothing);
  });

  testWidgets('a dialog route forwards it', (tester) async {
    final route = RawModalDialogRoute<void>(
      closeOnEscape: false,
      builder: (context, details) => _body(context, details),
    );
    expect(route.closeOnEscape, isFalse);
    await _open(tester, route);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(_page), findsOneWidget);
    final unpushed = RawModalDialogRoute<void>(builder: _body);
    addTearDown(unpushed.dispose);
    expect(unpushed.closeOnEscape, isTrue);
  });
}
