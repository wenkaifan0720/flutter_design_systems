// A radio group shows what follows an option's words right after them (a
// palette's swatches), heard by a screen reader as the words alone, and
// hands a caller's focus node to its chosen option, so a form round it can
// move focus there.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

Future<void> _show(WidgetTester tester, Widget group) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Scaffold(body: SizedBox(width: 360, child: group)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets("an option's secondary stands right after its words", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      ApplianceRadioGroup<String>(
        options: const ['Warm', 'Mint'],
        value: 'Warm',
        labelOf: (option) => option,
        secondaryOf: (option) =>
            SizedBox(key: ValueKey(option), width: 20, height: 10),
        onChanged: (_) {},
      ),
    );
    for (final option in ['Warm', 'Mint']) {
      final words = tester.getRect(find.text(option));
      final shown = tester.getRect(find.byKey(ValueKey(option)));
      expect(shown.left, greaterThan(words.right), reason: option);
      expect(shown.left - words.right, lessThan(16), reason: option);
      expect((shown.center.dy - words.center.dy).abs(), lessThan(2));
      expect(find.bySemanticsLabel(option), findsOneWidget, reason: option);
    }
    semantics.dispose();
  });

  testWidgets("a caller's focus node lands on the chosen option", (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    String? chosen;
    Widget group() => ApplianceRadioGroup<String>(
      options: const ['Standard', 'Next day'],
      value: chosen,
      labelOf: (option) => option,
      focusNode: focus,
      onChanged: (_) {},
    );
    await _show(tester, group());
    focus.requestFocus();
    await tester.pump();
    // None chosen: the first option takes it.
    expect(focus.hasFocus, isTrue);
    expect(Focus.of(tester.element(find.text('Standard'))).hasFocus, isTrue);
    chosen = 'Next day';
    await _show(tester, group());
    focus.requestFocus();
    await tester.pump();
    expect(Focus.of(tester.element(find.text('Next day'))).hasFocus, isTrue);
  });
}
