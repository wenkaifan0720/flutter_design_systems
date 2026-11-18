// A Fluent2Preview's app stands in a semantics container of its own: the route
// under it stands a modal barrier, which would hide from a screen reader the
// heading an app places above the preview, and the page before that.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

void main() {
  testWidgets('a heading above a preview stays with a screen reader', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            Text('Screens'),
            Expanded(
              child: Fluent2Preview(
                child: Fluent2Scaffold(
                  topBar: Fluent2AppBar(title: 'Files'),
                  body: SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel('Screens'), findsOneWidget);
    expect(find.bySemanticsLabel('Files'), findsWidgets);
    semantics.dispose();
  });
}
