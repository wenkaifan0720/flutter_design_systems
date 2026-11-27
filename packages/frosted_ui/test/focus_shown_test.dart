// Focus shows as a browser's :focus-visible decides: a key shows a control's frost cleared and its rim lit, a press of a
// mouse on it hides them while it keeps the focus, and the next key shows them again.

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

final _desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

Future<void> _pump(WidgetTester t, Widget control) async {
  t.view.physicalSize = const Size(800, 600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(child: page!),
      home: FrostedScaffold(
        body: Center(child: SizedBox(width: 320, child: control)),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  final controls = <String, (Type, Widget Function())>{
    'a switch': (
      FrostedSwitch,
      () =>
          FrostedSwitch(semanticLabel: 'Wi-Fi', value: true, onChanged: (_) {}),
    ),
    'a slider': (
      FrostedSlider,
      () =>
          FrostedSlider(semanticLabel: 'Volume', value: 0.5, onChanged: (_) {}),
    ),
    'a rating': (
      FrostedRating,
      () => FrostedRating(semanticLabel: 'Rating', value: 3, onChanged: (_) {}),
    ),
  };
  for (final MapEntry(key: name, value: (type, build)) in controls.entries) {
    testWidgets('$name: a key shows its focus, a press of a mouse hides it', (
      t,
    ) async {
      await _pump(t, build());
      bool shown() => t
          .widgetList<FrostedFocusRing>(
            find.descendant(
              of: find.byType(type),
              matching: find.byType(FrostedFocusRing),
            ),
          )
          .any((r) => r.shown);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      final focus = FocusManager.instance.primaryFocus;
      expect(shown(), isTrue, reason: 'Tab brings the focus, shown');
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      final at = t.getCenter(find.byType(type));
      await mouse.addPointer(location: at);
      await mouse.down(at);
      await mouse.up();
      await t.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(focus));
      expect(shown(), isFalse, reason: 'a press of a mouse hides it');
      await t.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
      await t.pumpAndSettle();
      expect(shown(), isTrue, reason: 'the next key shows it again');
    }, variant: _desktop);
  }
}
