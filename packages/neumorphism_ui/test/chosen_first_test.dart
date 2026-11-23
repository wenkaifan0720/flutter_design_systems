import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

import 'support.dart';

Widget _app(Widget home) => WidgetsApp(
  color: const Color(0xffeeeeee),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  builder: (context, child) =>
      NeumorphicHost(brightness: Brightness.light, child: child!),
  home: home,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The words of the key that holds the focus.
String? _focusedLabel() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  final own = context.widget;
  if (own is NeumorphicTap) return own.label;
  return context.findAncestorWidgetOfExactType<NeumorphicTap>()?.label;
}

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets('a select with its third option chosen, opened from the keys, '
      'has that option focused', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        Center(
          child: NeumorphicSelect<String>(
            autofocus: true,
            labelText: 'Fruit',
            value: 'cherry',
            options: const [
              NeumorphicMenuItem('apple', 'Apple'),
              NeumorphicMenuItem('banana', 'Banana'),
              NeumorphicMenuItem('cherry', 'Cherry'),
              NeumorphicMenuItem('date', 'Date'),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_focusedLabel(), contains('Cherry'));
  });

  testWidgets("a date picker opens with its chosen day focused", (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app(const Center(child: Text('Trip'))));
    final context = tester.element(find.text('Trip'));
    final chosen = DateTime(2026, 3, 12);
    final words = NeumorphicLocalizations.of(context).formatFullDate(chosen);
    unawaited(
      showNeumorphicDatePicker(
        context,
        value: chosen,
        currentDate: DateTime(2026, 3, 2),
      ),
    );
    await tester.pumpAndSettle();
    expect(_focusedLabel(), startsWith(words));
  });
}
