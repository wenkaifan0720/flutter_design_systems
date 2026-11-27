// A field's selection handles and its text menu build in the app's root
// overlay, above a theme placed under `home` rather than in the app's
// builder: there MinimalTheme.of gives the standard theme rather than
// throwing, so selecting text never throws.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

void main() {
  testWidgets(
    'selecting text under a host placed under home shows its handles and '
    'menu without a throw',
    variant: const TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
    (tester) async {
      final controller = TextEditingController(text: 'Hallo Welt');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MinimalHost(
            light: MinimalThemeData.standard(),
            dark: MinimalThemeData.standard(Brightness.dark),
            child: Center(
              child: SizedBox(
                width: 320,
                child: MinimalTextField(
                  labelText: 'Name',
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // A double tap on the first word selects it: its handles and its
      // menu show.
      final word =
          tester.getTopLeft(find.byType(EditableText)) + const Offset(12, 8);
      await tester.tapAt(word);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(word);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(controller.selection.isCollapsed, isFalse);
      expect(find.text('Copy'), findsOneWidget);
    },
  );

  // Flutter keeps a focused field's handles in the overlay while hidden,
  // faded to nothing (a tap in an empty field shows none); the drop under
  // its caret hangs over the top of the field below it (New habit's name
  // over its note).
  testWidgets(
    'a focused field\'s hidden handle takes no tap meant for the field '
    'under it',
    variant: TargetPlatformVariant.only(TargetPlatform.android),
    (tester) async {
      final name = TextEditingController();
      final note = TextEditingController();
      final nameFocus = FocusNode();
      final noteFocus = FocusNode();
      addTearDown(name.dispose);
      addTearDown(note.dispose);
      addTearDown(nameFocus.dispose);
      addTearDown(noteFocus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MinimalHost(
            light: MinimalThemeData.standard(),
            dark: MinimalThemeData.standard(Brightness.dark),
            child: Center(
              child: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MinimalTextField(
                      bare: true,
                      controller: name,
                      focusNode: nameFocus,
                      hintText: 'Habit name',
                    ),
                    MinimalTextField(
                      bare: true,
                      controller: note,
                      focusNode: noteFocus,
                      hintText: 'Add a note…',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The name taken, as a person starts the form.
      await tester.tap(find.byType(EditableText).first);
      await tester.pumpAndSettle();
      expect(nameFocus.hasFocus, isTrue);
      // The handle's gesture detector: the box that takes a tap (the
      // drop it paints is turned 45° inside it).
      final handle = find.descendant(
        of: find.byWidgetPredicate(
          (w) => '${w.runtimeType}' == '_SelectionHandleOverlay',
          skipOffstage: false,
        ),
        matching: find.byType(RawGestureDetector),
        skipOffstage: false,
      );
      expect(handle, findsWidgets, reason: 'the hidden handle is built');
      final over = tester
          .getRect(handle.first)
          .intersect(tester.getRect(find.byType(EditableText).last));
      expect(over.isEmpty, isFalse, reason: 'it hangs over the note');
      await tester.tapAt(over.center);
      await tester.pumpAndSettle();
      expect(noteFocus.hasFocus, isTrue);
    },
  );

  // Minimal's Material bridge is kept per theme; it takes the platform of
  // the theme it stands under each time, never the one it was first built
  // on (the handles of the test before this one were iOS's).
  testWidgets('a field under Minimal follows the app theme\'s platform', (
    tester,
  ) async {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      late TargetPlatform seen;
      await tester.pumpWidget(
        MaterialApp(
          // No animated change from the last pump's theme.
          themeAnimationDuration: Duration.zero,
          theme: ThemeData(platform: platform),
          home: MinimalHost(
            light: MinimalThemeData.standard(),
            dark: MinimalThemeData.standard(Brightness.dark),
            child: Builder(
              builder: (context) {
                seen = Theme.of(context).platform;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(seen, platform);
    }
  });
}
