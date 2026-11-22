// A menu bar's item marked isDestructiveAction (Delete) sets its words in
// the danger tone, as Comic's other menus set a destructive row's; the rest
// keep the text ink.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadComicFonts);

  testWidgets("a menu bar's destructive item is set in the danger tone", (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 700);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      comicApp(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 340,
            child: ComicMenuBar(
              menus: [
                RawMenuEntry(
                  label: 'Edit',
                  children: [
                    RawMenuEntry(label: 'Copy', onPressed: () {}),
                    RawMenuEntry(
                      label: 'Delete',
                      onPressed: () {},
                      isDestructiveAction: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final colors = ComicTheme.of(tester.element(find.text('Copy'))).colors;
    Color? ink(String words) =>
        tester.widget<Text>(find.text(words).last).style?.color ??
        DefaultTextStyle.of(tester.element(find.text(words).last)).style.color;
    expect(ink('Delete'), colors.tones.danger);
    expect(ink('Copy'), isNot(colors.tones.danger));
  });
}
