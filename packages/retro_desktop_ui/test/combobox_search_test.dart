// A combobox over a search (ui_core's loadingBuilder and errorBuilder, in the look's rows): while the search
// runs the list says it is loading; a failure says so with a "Try again" row the arrows light and Enter or a press
// runs; the options found then stand in the list.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

void main() {
  setUpAll(() async {
    await loadRetroDesktopFonts();
    await loadRetroDesktopGlyphFace();
  });

  testWidgets('a search says it is loading, says it failed, and tries again', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1024, 768)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final asked = <String>[];
    var pending = Completer<Iterable<String>>();
    String? taken;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, page) => RetroDesktopTheme(
          data: RetroDesktopThemeData.preset('classic', Brightness.light),
          child: page!,
        ),
        home: Builder(
          builder: (context) => ColoredBox(
            color: RetroDesktopTheme.of(context).colors.platinum,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: 320,
                  child: RetroDesktopCombobox<String>(
                    labelText: 'City',
                    search: (query) {
                      asked.add(query);
                      return pending.future;
                    },
                    onSelected: (city) => taken = city,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'Ber');
    await tester.pump();
    expect(find.text('Loading'), findsOneWidget, reason: 'searching');

    pending.completeError(StateError('offline'));
    await tester.pump();
    await tester.pump();
    expect(find.text("Couldn't load results"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    // Down lights "Try again" and Enter runs it: the same words searched again.
    pending = Completer<Iterable<String>>();
    final before = asked.length;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(asked.length, before + 1, reason: 'Enter tried again');
    expect(asked.last, 'Ber');
    expect(find.text('Loading'), findsOneWidget, reason: 'searching again');

    // It fails again; a press of "Try again" runs it too.
    pending.completeError(StateError('offline'));
    await tester.pump();
    await tester.pump();
    pending = Completer<Iterable<String>>();
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(asked.length, before + 2, reason: 'a press tried again');

    pending.complete(const ['Berlin', 'Bern']);
    await tester.pump();
    await tester.pump();
    expect(find.text('Berlin'), findsOneWidget, reason: 'found');
    expect(find.text('Try again'), findsNothing);
    await tester.tap(find.text('Bern'));
    await tester.pumpAndSettle();
    expect(taken, 'Bern');
  });
}
