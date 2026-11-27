// A colour picker with no onChanged is disabled: it dims, its area, sliders,
// hex field and swatches take no press, drag, typing or focus, and the hex
// field and the swatches tell a screen reader they are disabled.
import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Widget _host(Widget child) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(width: 320, child: child),
      ),
    ),
  ),
);

const _blue = Color(0xFF2563EB);
const _green = Color(0xFF16A34A);

String _hex(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byType(MinimalColorPicker),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

bool _inPicker(BuildContext? context) {
  var inside = false;
  context?.visitAncestorElements((element) {
    inside = element.widget is MinimalColorPicker;
    return !inside;
  });
  return inside;
}

void main() {
  testWidgets('a colour picker with no onChanged dims and takes no press, '
      'drag, typing or focus', (tester) async {
    await tester.pumpWidget(
      _host(const MinimalColorPicker(value: _blue, swatches: [_blue, _green])),
    );
    final picker = find.byType(MinimalColorPicker);
    expect(_hex(tester), '#2563EB');
    expect(
      find.descendant(
        of: picker,
        matching: find.byWidgetPredicate(
          (w) => w is Opacity && w.opacity == 0.45,
        ),
      ),
      findsWidgets,
    );

    // A drag across the area, a press on a swatch, a tap on the hex field.
    final top = tester.getTopLeft(picker);
    await tester.dragFrom(top + const Offset(40, 40), const Offset(160, 80));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('#16A34A'), warnIfMissed: false);
    await tester.pump();
    await tester.tap(
      find.descendant(of: picker, matching: find.byType(EditableText)),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(_hex(tester), '#2563EB');
    expect(_inPicker(FocusManager.instance.primaryFocus?.context), isFalse);

    // Tab finds no stop inside it.
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_inPicker(FocusManager.instance.primaryFocus?.context), isFalse);
    }

    final swatch = tester
        .getSemantics(find.bySemanticsLabel('#16A34A'))
        .getSemanticsData();
    expect(swatch.flagsCollection.isEnabled, Tristate.isFalse);
  });

  testWidgets('a colour picker with onChanged takes a swatch', (tester) async {
    final picked = <Color>[];
    await tester.pumpWidget(
      _host(
        MinimalColorPicker(
          value: _blue,
          onChanged: picked.add,
          swatches: const [_blue, _green],
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('#16A34A'));
    await tester.pump();
    expect(picked, [_green]);
  });
}
