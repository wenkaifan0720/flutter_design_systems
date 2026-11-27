// A modal sheet's title bar, a combobox's list beside its field's focus ring, and a notice's line, its inset on a
// phone and its balloon's tail right to left.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/src/retro_desktop/internal/marks.dart';

import 'support.dart';

Widget _host(Widget home, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: RetroDesktopHost(brightness: Brightness.light, child: app!),
      ),
      home: home,
    );

void _size(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pumps a page with one key, presses it, and lets what it raised settle.
Future<void> _raise(
  WidgetTester tester,
  void Function(BuildContext context) raise, {
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    _host(
      Builder(
        builder: (context) => Center(
          child: RetroDesktopButton('Open', onPressed: () => raise(context)),
        ),
      ),
      direction: direction,
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void _sheet(BuildContext context) => showRetroDesktopBottomSheet<void>(
  context,
  builder: (_) => const RetroDesktopBottomSheet(
    title: 'Details',
    child: Text('Document details'),
  ),
);

final _inSheet = find.byType(RetroDesktopBottomSheet);

Finder _paints(String painter) => find.descendant(
  of: _inSheet,
  matching: find.byWidgetPredicate(
    (w) =>
        w is RetroDesktopPixelPaint &&
        w.painter.runtimeType.toString() == painter,
  ),
);

// The notice's drawn surface, not the room it stands in.
final _noticeFace = find.descendant(
  of: find.byType(RetroDesktopSnackBar),
  matching: find.byWidgetPredicate(
    (w) => w.runtimeType.toString() == '_RaisedSurface',
  ),
);

void main() {
  setUpAll(loadRetroDesktopFonts);

  testWidgets(
    'on a desk a modal sheet\'s title bar carries its close box alone',
    (tester) async {
      _size(tester, 1440);
      await _raise(tester, _sheet);
      final shown = tester
          .widgetList<Visibility>(
            find.descendant(
              of: _inSheet,
              matching: find.byWidgetPredicate(
                (w) => w is Visibility && w.child is RetroDesktopPixelPaint,
              ),
            ),
          )
          .where((v) => v.visible);
      expect(shown, hasLength(1), reason: 'no zoom or shade box on a sheet');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  for (final direction in TextDirection.values) {
    testWidgets('on a phone a sheet\'s stripes run to its title bar\'s end '
        '(${direction.name})', (tester) async {
      _size(tester, 390);
      await _raise(tester, _sheet, direction: direction);
      final stripes = _paints('_Stripes');
      expect(stripes, findsNWidgets(2));
      final bar = tester.getRect(
        find
            .ancestor(
              of: stripes.first,
              matching: find.byType(CustomMultiChildLayout),
            )
            .first,
      );
      final runs = [
        tester.getRect(stripes.at(0)),
        tester.getRect(stripes.at(1)),
      ]..sort((a, b) => a.left.compareTo(b.left));
      // The close box stands 2 in from the start, its stripes 6 past it; the end's run on to 2 + 6 from the end.
      final endGap = direction == TextDirection.ltr
          ? bar.right - runs.last.right
          : runs.first.left - bar.left;
      expect(endGap, closeTo(8, 1));
    });
  }

  for (final width in const [1440.0, 390.0]) {
    testWidgets('at $width a combobox\'s list clears its field\'s focus ring', (
      tester,
    ) async {
      _size(tester, width);
      await tester.pumpWidget(
        _host(
          Padding(
            padding: const EdgeInsets.all(40),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 300,
                child: RetroDesktopCombobox<String>(
                  labelText: 'Folder',
                  options: const ['Documents', 'Pictures'],
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'P');
      await tester.pumpAndSettle();
      final field = tester.getRect(
        find
            .descendant(
              of: find.byType(RetroDesktopCombobox<String>),
              matching: find.byType(RetroDesktopHighlight),
            )
            .first,
      );
      final list = tester.getRect(
        find
            .ancestor(
              of: find.text('Pictures'),
              matching: find.byWidgetPredicate(
                (w) => w.runtimeType.toString() == '_Face',
              ),
            )
            .last,
      );
      final ring = RetroDesktopTheme.of(
        tester.element(find.byType(RetroDesktopCombobox<String>)),
      ).focus;
      expect(ring.inside, isFalse);
      expect(
        list.top,
        greaterThanOrEqualTo(field.bottom + ring.gap + ring.width - .01),
        reason: 'the ring stands ${ring.gap} out and ${ring.width} wide',
      );
    });
  }

  testWidgets(
    'on a desk the date window is as wide as its month and its margins',
    (tester) async {
      _size(tester, 1440);
      await _raise(
        tester,
        (context) =>
            showRetroDesktopDatePicker(context, value: DateTime(2031, 3, 18)),
      );
      final window = tester.getRect(
        find
            .ancestor(
              of: find.byType(RetroDesktopDatePicker),
              matching: find.byWidgetPredicate(
                (w) => w.runtimeType.toString() == '_RaisedSurface',
              ),
            )
            .first,
      );
      final month = tester.getRect(find.byType(RetroDesktopDatePicker));
      // Seven 44 days in their box, and the window's margins: no empty room beside the month.
      expect(window.width, lessThan(7 * 44 + 60));
      expect(
        (month.left - window.left) - (window.right - month.right),
        closeTo(0, 1),
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('on a desk a short notice sets its words and keys on one line, '
      'as wide as they need', (tester) async {
    _size(tester, 1440);
    await _raise(
      tester,
      (context) => showRetroDesktopSnackBar(
        context,
        'Moved to Archive',
        actionLabel: 'Undo',
        onAction: () {},
      ),
    );
    final words = tester.getRect(find.text('Moved to Archive'));
    final key = tester.getRect(find.widgetWithText(RetroDesktopButton, 'Undo'));
    expect(key.center.dy, closeTo(words.center.dy, 1.5));
    expect(key.left, greaterThan(words.right));
    expect(tester.getSize(_noticeFace).width, lessThan(400));
    // The toaster stands it on the room's middle.
    expect(tester.getRect(_noticeFace).center.dx, closeTo(720, 1));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  for (final direction in TextDirection.values) {
    testWidgets('on a desk a notice laid in a column starts on its edge '
        '(${direction.name})', (tester) async {
      _size(tester, 1440);
      await tester.pumpWidget(
        _host(
          const Padding(
            padding: EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [RetroDesktopSnackBar('Moved to Archive')],
            ),
          ),
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();
      final face = tester.getRect(_noticeFace);
      expect(face.width, lessThan(400));
      if (direction == TextDirection.ltr) {
        expect(face.left, closeTo(40, 1));
      } else {
        expect(face.right, closeTo(1400, 1));
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  }

  testWidgets('a notice too long for one line keeps its keys below its words, '
      'at the end', (tester) async {
    _size(tester, 1440);
    await _raise(
      tester,
      (context) => showRetroDesktopSnackBar(
        context,
        longLine,
        actionLabel: 'Undo',
        onAction: () {},
      ),
    );
    final words = tester.getRect(find.text(longLine));
    final keys = [
      for (final e
          in find
              .descendant(
                of: _noticeFace,
                matching: find.byType(RetroDesktopButton),
              )
              .evaluate())
        tester.getRect(find.byWidget(e.widget)),
    ];
    final face = tester.getRect(_noticeFace);
    expect(keys.map((k) => k.top).reduce(math.min), greaterThan(words.bottom));
    // The last key on the line's end, as far in as the words start from the mark's side.
    expect(
      face.right - keys.map((k) => k.right).reduce(math.max),
      lessThan(words.left - face.left),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('on a phone a notice stands as far in as the page\'s window', (
    tester,
  ) async {
    _size(tester, 390);
    await _raise(
      tester,
      (context) => showRetroDesktopSnackBar(context, 'Moved to Archive'),
    );
    final face = tester.getRect(_noticeFace);
    expect(face.left, RetroDesktopSpacing.s12);
    expect(390 - face.right, RetroDesktopSpacing.s12);
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'a note\'s balloon turns its tail with the text (${direction.name})',
      (tester) async {
        _size(tester, 1440);
        await _raise(
          tester,
          (context) => showRetroDesktopSnackBar(context, 'Moved to Archive'),
          direction: direction,
        );
        final art = tester
            .widgetList<RetroDesktopPixelPaint>(
              find.descendant(
                of: find.byType(RetroDesktopSnackBar),
                matching: find.byType(RetroDesktopPixelPaint),
              ),
            )
            .map((w) => w.painter)
            .whereType<RetroDesktopArtPainter>()
            .single;
        // The tail's tip, under the balloon: towards the start of the line.
        final tip = art.rows[14].indexOf('k');
        expect(
          direction == TextDirection.ltr ? tip < 8 : tip > 8,
          isTrue,
          reason: art.rows[14],
        );
      },
    );
  }
}
