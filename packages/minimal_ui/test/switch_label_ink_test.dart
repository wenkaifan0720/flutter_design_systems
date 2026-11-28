// A labelled switch prints its words in the ink, on or off: the quiet ink
// beside an off switch read as a disabled row. Disabled, the
// words take the quiet ink.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Widget _app(Widget child) => MaterialApp(
  builder: (context, app) =>
      MinimalHost(brightness: Brightness.light, child: app!),
  home: Scaffold(body: Center(child: child)),
);

Color? _ink(WidgetTester tester) =>
    tester.widget<Text>(find.text('Favourite')).style?.color;

void main() {
  for (final on in [false, true]) {
    testWidgets('the words take the ink when ${on ? 'on' : 'off'}', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MinimalSwitch(
            value: on,
            label: 'Favourite',
            showLabel: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final t = MinimalTheme.of(tester.element(find.text('Favourite')));
      expect(_ink(tester), t.foreground);
    });
  }

  testWidgets('disabled, the words take the quiet ink', (tester) async {
    await tester.pumpWidget(
      _app(
        const MinimalSwitch(value: false, label: 'Favourite', showLabel: true),
      ),
    );
    await tester.pumpAndSettle();
    final t = MinimalTheme.of(tester.element(find.text('Favourite')));
    expect(_ink(tester), t.mutedForeground);
  });
}
