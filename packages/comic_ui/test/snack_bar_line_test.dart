// A snack bar with no heading keeps its actions on the message's line while the words fit beside them, as a Material
// SnackBar does; long words with a wide action stand over the actions. On a phone the actions always stood under the
// words: "Changes saved" and its dismiss made a tall box.
import 'package:comic_ui/comic_host.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

final _page = GlobalKey();

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) async {
  await tester.runAsync(comicLoadFonts);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => Directionality(
        textDirection: direction,
        child: ComicHost(
          light: ComicThemeData.offset(),
          dark: ComicThemeData.offset(Brightness.dark),
          brightness: brightness,
          child: child!,
        ),
      ),
      home: SizedBox.expand(key: _page),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

Finder _in(Type type) => find.descendant(
  of: find.byType(ComicSnackBar),
  matching: find.byType(type),
);

void main() {
  for (final width in [390.0, 900.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('at ${width.round()} (${direction.name}) "Tasks deleted" '
          'keeps Undo and the dismiss on its line', (tester) async {
        await _pump(tester, Size(width, 844), direction: direction);
        showComicSnackBar(
          _page.currentContext!,
          'Tasks deleted',
          actionLabel: 'Undo',
          onAction: () {},
        );
        await tester.pumpAndSettle();
        final words = tester.getRect(find.text('Tasks deleted'));
        final undo = tester.getRect(_in(ComicButton));
        final dismiss = tester.getRect(_in(ComicIconButton));
        expect(
          (words.center.dy - undo.center.dy).abs(),
          lessThan(1),
          reason: 'words $words, undo $undo',
        );
        expect((dismiss.center.dy - undo.center.dy).abs(), lessThan(1));
        // The actions stand at the line's end.
        if (direction == TextDirection.ltr) {
          expect(undo.left, greaterThan(words.right));
        } else {
          expect(undo.right, lessThan(words.left));
        }
        await _close(tester);
      });
    }

    testWidgets('at ${width.round()} "Changes saved" keeps its dismiss on its '
        'line', (tester) async {
      await _pump(tester, Size(width, 844), brightness: Brightness.dark);
      showComicSnackBar(_page.currentContext!, 'Changes saved');
      await tester.pumpAndSettle();
      final words = tester.getRect(find.text('Changes saved'));
      final dismiss = tester.getRect(_in(ComicIconButton));
      expect((words.center.dy - dismiss.center.dy).abs(), lessThan(1));
      await _close(tester);
    });
  }

  testWidgets('on a phone, long words with an action stand over the actions', (
    tester,
  ) async {
    await _pump(tester, const Size(390, 844));
    const long =
        'Three tasks moved to the archive and their reminders were cleared';
    showComicSnackBar(
      _page.currentContext!,
      long,
      actionLabel: 'Undo',
      onAction: () {},
    );
    await tester.pumpAndSettle();
    final words = tester.getRect(find.text(long));
    final undo = tester.getRect(_in(ComicButton));
    expect(undo.top, greaterThanOrEqualTo(words.bottom));
    await _close(tester);
  });
}
