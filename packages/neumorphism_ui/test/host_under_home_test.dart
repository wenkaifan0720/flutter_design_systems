// A host set under an app's home rather than in its builder: the app's overlay, where a field's selection handles and
// menu build, then stands above the theme. Selecting text there must not throw: a part built in the overlay takes the
// look's default theme when none is above it (`NeumorphicTheme.of`).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

void main() {
  testWidgets(
    'selecting text in a field under a host set in home shows its handles and menu',
    (tester) async {
      final text = TextEditingController(text: 'Morgan Hale');
      addTearDown(text.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: NeumorphicTheme(
            data: NeumorphicThemeData.porcelain(),
            child: _Page(controller: text),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final editable = find.byType(EditableText);
      final word = tester.getTopLeft(editable) + const Offset(12, 8);
      await tester.tapAt(word);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(word);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        text.selection.isCollapsed,
        isFalse,
        reason: 'the word is selected',
      );
      final overlay = tester
          .state<EditableTextState>(editable)
          .selectionOverlay;
      expect(overlay?.handlesAreVisible, isTrue, reason: 'its handles show');
      expect(overlay?.toolbarIsVisible, isTrue, reason: 'its menu is open');
      // A long press drags the selection with the magnifier up.
      final press = await tester.startGesture(word);
      await tester.pump(const Duration(milliseconds: 600));
      await press.moveBy(const Offset(24, 0));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await press.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );
}

class _Page extends StatelessWidget {
  const _Page({this.controller});

  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: NeumorphicTheme.of(context).colors.ground,
    child: Center(
      child: SizedBox(
        width: 320,
        child: NeumorphicTextField(label: 'Name', controller: controller),
      ),
    ),
  );
}
