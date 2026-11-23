// A navigator in a scaffold's body (a router's shell, a list-and-detail
// pane) keeps its routes' semantics nodes when a list opens over one of its
// pages: the combobox's field keeps the node path it had before the tap, so
// on the web its input is not moved, and blurred, by the tap that opened the
// list (a second tap was needed to type).
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

const _names = ['Maya Reed', 'Sam Okafor', 'Noor Haddad'];

// The ids of the semantics nodes from the root down to the text field named
// [label].
List<int> _path(String label) {
  final root = RendererBinding
      .instance
      .renderViews
      .first
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  List<int>? found;
  bool walk(SemanticsNode node, List<int> above) {
    final here = [...above, node.id];
    final data = node.getSemanticsData();
    if (data.label.contains(label) && data.flagsCollection.isTextField) {
      found = here;
      return false;
    }
    var more = true;
    node.visitChildren((child) => more = more && walk(child, here));
    return more;
  }

  walk(root, const []);
  expect(found, isNotNull, reason: 'no text field named $label');
  return found!;
}

void main() {
  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    testWidgets(
      'a combobox opened over a route of a navigator in the body keeps its '
      'node (${size.width.round()})',
      (tester) async {
        final semantics = tester.ensureSemantics();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: GlossTheme(
              data: GlossThemeData.light(),
              child: GlossScaffold(
                body: Navigator(
                  onGenerateRoute: (_) => PageRouteBuilder<void>(
                    pageBuilder: (context, _, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 320,
                          child: GlossCombobox<String>(
                            labelText: 'Assignee',
                            options: _names,
                            onSelected: (_) {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final before = _path('Assignee');
        await tester.tap(find.byType(EditableText));
        await tester.pump();
        expect(find.text('Noor Haddad'), findsOneWidget, reason: 'no list');
        expect(_path('Assignee'), before);
        final field = tester.widget<EditableText>(find.byType(EditableText));
        expect(field.focusNode.hasFocus, isTrue);
        semantics.dispose();
      },
    );
  }
}
