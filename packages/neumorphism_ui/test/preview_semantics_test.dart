// A preview on a page keeps the page: its app's first route puts up a modal barrier, whose semantics hide whatever was
// painted before it in the same container, so the preview's app stands in a container of its own.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets(
    "a screen reader finds the page's controls above a preview, and the preview",
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        neumorphicApp(
          Column(
            children: [
              NeumorphicButton('Above the preview', onPressed: () {}),
              const SizedBox(
                height: 480,
                child: NeumorphicPreview(child: Text('In the preview')),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Above the preview'), findsOneWidget);
      expect(find.bySemanticsLabel('In the preview'), findsOneWidget);
      semantics.dispose();
    },
  );
}
