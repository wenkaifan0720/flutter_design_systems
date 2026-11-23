import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'support.dart';

Widget _app(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) =>
      RetroDesktopHost(brightness: Brightness.light, child: child!),
  home: home,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// What a screen reader hears on the part that holds the focus.
String _focusedWords(WidgetTester tester) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return '';
  final node = tester.getSemantics(
    find.byElementPredicate((element) => identical(element, focused)),
  );
  return node.getSemanticsData().label;
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final appearance in RetroDesktopAppearance.values) {
    testWidgets('a ${appearance.name} select with its third option chosen, '
        'opened from the keys, has that option focused', (tester) async {
      _phone(tester);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          RetroDesktopTheme(
            data: RetroDesktopThemeData.classic().copyWith(
              appearance: appearance,
            ),
            child: Center(
              child: SizedBox(
                width: 300,
                child: RetroDesktopSelect<String>(
                  autofocus: true,
                  labelText: 'Fruit',
                  value: 'cherry',
                  options: const [
                    RetroDesktopOption('apple', 'Apple'),
                    RetroDesktopOption('banana', 'Banana'),
                    RetroDesktopOption('cherry', 'Cherry'),
                    RetroDesktopOption('date', 'Date'),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);
      expect(_focusedWords(tester), contains('Cherry'));
      semantics.dispose();
    });
  }

  testWidgets('a date picker opens with its chosen day focused', (
    tester,
  ) async {
    _phone(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(const Center(child: Text('Trip'))));
    final context = tester.element(find.text('Trip'));
    unawaited(
      showRetroDesktopDatePicker(
        context,
        value: DateTime(2026, 3, 12),
        today: DateTime(2026, 3, 2),
      ),
    );
    await tester.pumpAndSettle();
    expect(_focusedWords(tester), contains('12'));
    expect(_focusedWords(tester), isNot(contains('2 March')));
    semantics.dispose();
  });
}
