// A dialog on a phone: actions that don't fit side by side stack as one column at one width, the confirming one on
// top; and the date picker's month fits the dialog, all seven days across, Sunday whole.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

Future<BuildContext> _phone(
  WidgetTester tester, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  late BuildContext page;
  await tester.pumpWidget(
    comicApp(
      Builder(
        builder: (context) {
          page = context;
          return const SizedBox.expand();
        },
      ),
      direction: direction,
    ),
  );
  return page;
}

void main() {
  setUpAll(loadComicFonts);

  for (final direction in TextDirection.values) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets(
        "a phone dialog's actions stack at one width, the main one on top (${direction.name}, ${scale}x)",
        (tester) async {
          final page = await _phone(tester, direction: direction, scale: scale);
          unawaited(
            showComicDialog<void>(
              page,
              builder: (context) => ComicDialog(
                title: 'Unsaved changes',
                message: 'Keep the edits to this task?',
                actions: [
                  ComicButton('Cancel', onPressed: () {}),
                  ComicButton('Discard', onPressed: () {}),
                  ComicButton.filled('Save changes', onPressed: () {}),
                ],
              ),
            ),
          );
          await tester.pumpAndSettle();
          final keys = [
            for (final words in const ['CANCEL', 'DISCARD', 'SAVE CHANGES'])
              tester.getRect(
                find.ancestor(
                  of: find.text(words),
                  matching: find.byType(ComicButton),
                ),
              ),
          ];
          final (cancel, discard, save) = (keys[0], keys[1], keys[2]);
          expect(save.width, closeTo(discard.width, 0.5));
          expect(discard.width, closeTo(cancel.width, 0.5));
          expect(save.left, closeTo(cancel.left, 0.5));
          expect(save.top, lessThan(discard.top));
          expect(discard.top, lessThan(cancel.top));
        },
      );
    }
  }

  for (final direction in TextDirection.values) {
    testWidgets(
      "a phone's date picker shows all seven days across (${direction.name})",
      (tester) async {
        final page = await _phone(tester, direction: direction);
        unawaited(showComicDatePicker(page, value: DateTime(2026, 11, 20)));
        await tester.pumpAndSettle();
        final picker = find.byType(ComicDatePicker);
        final sideways = tester
            .stateList<ScrollableState>(
              find.descendant(of: picker, matching: find.byType(Scrollable)),
            )
            .where((s) => s.position.axis == Axis.horizontal);
        for (final s in sideways) {
          expect(s.position.maxScrollExtent, 0, reason: 'the month scrolls');
        }
        // Every day of the month stands whole inside the dialog's picker.
        final box = tester.getRect(picker);
        for (var day = 1; day <= 30; day++) {
          final at = tester.getRect(
            find.descendant(of: picker, matching: find.text('$day')).first,
          );
          expect(
            box.left <= at.left && at.right <= box.right,
            isTrue,
            reason: 'day $day at $at outside $box',
          );
        }
      },
    );
  }
}
