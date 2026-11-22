// The comment box's model pill shows the caller's words while onModel is
// set; with no onModel there is no pill.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

Widget _host(Widget child) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Center(child: SizedBox(width: 360, child: child)),
  ),
);

final Finder _pill = find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == '_ModelPill',
);

void main() {
  testWidgets('a model and onModel show the pill in the given words', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      _host(
        MinimalComposer(
          style: MinimalComposerStyle.assistant,
          model: 'Team only',
          onModel: () => opened += 1,
          onSend: (_) {},
        ),
      ),
    );
    expect(_pill, findsOneWidget);
    await tester.tap(find.text('Team only'));
    expect(opened, 1);
  });

  testWidgets('a model with no onModel shows no pill', (tester) async {
    await tester.pumpWidget(
      _host(
        MinimalComposer(
          style: MinimalComposerStyle.assistant,
          model: 'Team only',
          onSend: (_) {},
        ),
      ),
    );
    expect(_pill, findsNothing);
    expect(find.text('Team only'), findsNothing);
  });
}
