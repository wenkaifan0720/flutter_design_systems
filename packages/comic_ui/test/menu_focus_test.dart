// A menu shows the keyboard's focus as every Comic part does: the row the keys stand on pops, and since rows stand
// edge to edge it pops inside its own outline, a hard print along its bottom and end, its words on the row's plain
// fill. The pointer's row wears the shade alone. A menu the pointer opened shows nothing until a key is pressed, and
// its first Tab lights the row the keys stand on rather than passing over it.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

const _items = [
  ComicMenuItem('save', 'Save'),
  ComicMenuItem('share', 'Share'),
  ComicMenuItem('print', 'Print', enabled: false),
  ComicMenuItem('delete', 'Delete'),
];

/// The menu row whose words are [label].
Finder _row(String label) => find
    .ancestor(
      of: find.descendant(
        of: find.byType(ComicMenu<String>),
        matching: find.text(label),
      ),
      matching: find.byType(ComicPressable),
    )
    .first;

/// The rows wearing the shade (the active row's, the pointer's) and the rows showing the keyboard's print, their
/// words joined by commas.
({String shaded, String printed}) _marks(WidgetTester tester) {
  final shaded = <String>[], printed = <String>[];
  for (final item in _items) {
    final marks = tester.widgetList<ComicHighlight>(
      find.descendant(
        of: _row(item.label),
        matching: find.byType(ComicHighlight),
      ),
    );
    if (marks.any((h) => h.wash && h.states.contains(WidgetState.hovered))) {
      shaded.add(item.label);
    }
    if (marks.any((h) => h.ring && h.states.contains(WidgetState.focused))) {
      printed.add(item.label);
    }
  }
  return (shaded: shaded.join(','), printed: printed.join(','));
}

Future<void> _key(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

Widget _inline({bool dark = false, ValueChanged<String>? taken}) => comicApp(
  dark: dark,
  Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ComicButton('Before', onPressed: () {}),
        const SizedBox(height: 16),
        SizedBox(
          width: 280,
          child: RepaintBoundary(
            key: const ValueKey('menu'),
            child: ComicMenu<String>(
              items: _items,
              onSelected: taken ?? (_) {},
            ),
          ),
        ),
        const SizedBox(height: 16),
        ComicButton('After', onPressed: () {}),
      ],
    ),
  ),
);

/// The relative luminance of the pixel at [i] in [rgba], as WCAG reckons it.
double _luminance(Uint8List rgba, int i) {
  double channel(int v) {
    final c = v / 255;
    return c <= .04045
        ? c / 12.92
        : math.pow((c + .055) / 1.055, 2.4).toDouble();
  }

  return .2126 * channel(rgba[i]) +
      .7152 * channel(rgba[i + 1]) +
      .0722 * channel(rgba[i + 2]);
}

Future<({Uint8List rgba, int width, int height})> _shot(
  WidgetTester tester,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('menu')),
  );
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final data = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final shot = (
    rgba: data.buffer.asUint8List(),
    width: image.width,
    height: image.height,
  );
  image.dispose();
  return shot;
}

void main() {
  setUpAll(loadComicFonts);
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(600, 600);
    view.devicePixelRatio = 1;
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
  });

  testWidgets(
    'Tab walks a menu one row at a time: the row the keys stand on is shaded and printed, a row that is off is passed',
    (tester) async {
      await tester.pumpWidget(_inline());
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_marks(tester).printed, '', reason: 'printed before the menu');
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_marks(tester), (shaded: 'Save', printed: 'Save'));
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_marks(tester), (shaded: 'Share', printed: 'Share'));
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_marks(tester), (
        shaded: 'Delete',
        printed: 'Delete',
      ), reason: 'Tab stopped on a row that is off');
      await _key(tester, LogicalKeyboardKey.tab, shift: true);
      expect(_marks(tester), (shaded: 'Share', printed: 'Share'));
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(
        _marks(tester).printed,
        isEmpty,
        reason: 'the print stayed after the focus left the menu',
      );
    },
  );

  testWidgets(
    "the pointer's row is shaded, not printed, and the next key prints the row it moves to",
    (tester) async {
      await tester.pumpWidget(_inline());
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_marks(tester), (shaded: 'Save', printed: 'Save'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(_row('Share')));
      await tester.pumpAndSettle();
      expect(_marks(tester), (
        shaded: 'Share',
        printed: '',
      ), reason: "the pointer's row took the keyboard's print");
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_marks(tester), (shaded: 'Delete', printed: 'Delete'));
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_marks(tester), (shaded: 'Share', printed: 'Share'));
    },
  );

  testWidgets(
    'a menu the pointer opened shows no row until a key: its first Tab lights the row the keys stand on and takes '
    'nothing, the next moves on, and a first Shift+Tab lights the last',
    (tester) async {
      final taken = <String>[];
      await tester.pumpWidget(
        comicApp(
          Align(
            alignment: AlignmentDirectional.topStart,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ComicMenuAnchor<String>(
                items: _items,
                onSelected: taken.add,
                builder: (context, open) => ComicButton(
                  'More',
                  key: const ValueKey('more'),
                  onPressed: open,
                ),
              ),
            ),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      Future<void> open() async {
        final more = tester.getCenter(find.byKey(const ValueKey('more')));
        await mouse.moveTo(more);
        await mouse.down(more);
        await mouse.up();
        await mouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();
      }

      await open();
      expect(_marks(tester), (shaded: '', printed: ''));
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_marks(tester), (
        shaded: 'Save',
        printed: 'Save',
      ), reason: "the first Tab passed over the row the keys stood on");
      expect(taken, isEmpty);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_marks(tester), (shaded: 'Share', printed: 'Share'));
      await _key(tester, LogicalKeyboardKey.tab, shift: true);
      expect(_marks(tester), (shaded: 'Save', printed: 'Save'));
      await _key(tester, LogicalKeyboardKey.escape);
      expect(find.byType(ComicMenu<String>), findsNothing);

      await open();
      await _key(tester, LogicalKeyboardKey.tab, shift: true);
      expect(_marks(tester), (shaded: 'Delete', printed: 'Delete'));
      expect(taken, isEmpty);
    },
  );

  // Drawn pixels: the rasterizer's, as a golden's. Tagged goldens, so Linux CI leaves them to the macOS goldens job.
  for (final dark in const [false, true]) {
    testWidgets(
      '${dark ? 'by night' : 'by day'} the print is a hard band along the row\'s bottom and end, at least a 2 px '
      'perimeter at 3:1 against the shaded row, clear of its words',
      (tester) async {
        // The mouse is connected before the menu is built, as on a desktop. The tests run as Android, where Flutter
        // shows focus only once a key is pressed or a mouse is connected when a part first builds.
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: Offset.zero);
        await tester.pumpWidget(_inline(dark: dark));
        await mouse.moveTo(tester.getCenter(_row('Share')));
        await tester.pumpAndSettle();
        final pointer = await _shot(tester);
        // The keys come back to the same row, the pointer still over it.
        await _key(tester, LogicalKeyboardKey.arrowDown);
        await _key(tester, LogicalKeyboardKey.arrowUp);
        expect(_marks(tester), (shaded: 'Share', printed: 'Share'));
        final keys = await _shot(tester);
        expect((keys.width, keys.height), (pointer.width, pointer.height));

        final origin = tester.getTopLeft(find.byKey(const ValueKey('menu')));
        final row = tester.getRect(_row('Share')).shift(-origin);
        final words = tester
            .getRect(
              find.descendant(
                of: find.byType(ComicMenu<String>),
                matching: find.text('Share'),
              ),
            )
            .shift(-origin);
        var strong = 0, inWords = 0, outside = 0;
        for (var y = 0; y < keys.height; y++) {
          for (var x = 0; x < keys.width; x++) {
            final i = (y * keys.width + x) * 4;
            if (keys.rgba[i] == pointer.rgba[i] &&
                keys.rgba[i + 1] == pointer.rgba[i + 1] &&
                keys.rgba[i + 2] == pointer.rgba[i + 2]) {
              continue;
            }
            final p = Offset(x + .5, y + .5);
            if (words.contains(p)) inWords++;
            if (!row.inflate(.5).contains(p)) outside++;
            final a = _luminance(keys.rgba, i), b = _luminance(pointer.rgba, i);
            if ((math.max(a, b) + .05) / (math.min(a, b) + .05) >= 3) {
              strong++;
            }
          }
        }
        expect(inWords, 0, reason: 'the print touched the words');
        expect(outside, 0, reason: 'the print left its row');
        // A 2 px outline round the row, as Material's focus ring, covers 2 px along all four edges.
        final perimeter = 2 * 2 * (row.width + row.height);
        expect(
          strong,
          greaterThanOrEqualTo(perimeter),
          reason: '$strong pixels at 3:1, under a 2 px perimeter ($perimeter)',
        );
      },
      tags: 'goldens',
    );
  }
}
