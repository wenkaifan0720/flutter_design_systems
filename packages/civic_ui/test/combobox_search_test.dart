// A combobox that looks its answers up (CivicCombobox's search, ui_core's
// RawCombobox running it): the list says "Loading" in words while it
// looks, then the answers found; when the search fails it says so, with
// "Try again" under it, which a press or Down and Enter runs again.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:async';

import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';

/// A combobox whose search answers with what [answer] gives, called with
/// the words typed.
Future<void> _combobox(
  WidgetTester tester,
  FutureOr<Iterable<String>> Function(String words) answer,
) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      home: Padding(
        padding: const EdgeInsets.all(CivicSpacing.s20),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: 400,
            child: CivicCombobox<String>(labelText: 'Street', search: answer),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the list says it is looking, in words, then shows what it '
      'found', (tester) async {
    final found = Completer<Iterable<String>>();
    await _combobox(tester, (_) => found.future);
    await tester.enterText(find.byType(EditableText), 'Br');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Loading'), findsOneWidget);
    found.complete(const ['Bridge Street', 'Brook Lane']);
    await tester.pumpAndSettle();
    expect(find.text('Loading'), findsNothing);
    expect(find.text('Bridge Street'), findsOneWidget);
    expect(find.text('Brook Lane'), findsOneWidget);
  });

  testWidgets('a failed search says so and "Try again" runs it again, by a '
      'press or by Down and Enter', (tester) async {
    var asked = 0;
    await _combobox(tester, (_) {
      asked++;
      throw StateError('offline');
    });
    await tester.enterText(find.byType(EditableText), 'Br');
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    final before = asked;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(asked, before + 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(asked, before + 2);
  });
}
