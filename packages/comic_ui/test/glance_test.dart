// What a reader takes in at a glance: a date dialog as wide as its calendar, a list standing clear of its field, the
// chosen day's edge, words whole under a modal's screen and the page behind it darker than the dialog at night, a
// calendar's rules at one weight, and the keys' row marked.
import 'dart:ui' as ui;

import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/src/comic/raised.dart'
    show ComicRaisedFrame, ComicMenuRowFace;
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _root = Key('root');

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required Widget home,
  Brightness brightness = Brightness.light,
  bool rtl = false,
}) async {
  await tester.runAsync(comicLoadFonts);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => RepaintBoundary(
        key: _root,
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: ComicHost(
            light: ComicThemeData.offset(),
            dark: ComicThemeData.offset(Brightness.dark),
            brightness: brightness,
            child: child!,
          ),
        ),
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

// The whole app as drawn, one pixel a logical pixel.
Future<(ByteData, int)> _shot(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_root),
  );
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final width = image.width;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  image.dispose();
  return (bytes, width);
}

Color _at(ByteData b, int width, num x, num y) {
  final i = (y.floor() * width + x.floor()) * 4;
  return Color.fromARGB(
    b.getUint8(i + 3),
    b.getUint8(i),
    b.getUint8(i + 1),
    b.getUint8(i + 2),
  );
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + .05 : lb + .05) / (la > lb ? lb + .05 : la + .05);
}

bool _same(Color a, Color b) =>
    (a.r - b.r).abs() < 8 / 255 &&
    (a.g - b.g).abs() < 8 / 255 &&
    (a.b - b.b).abs() < 8 / 255;

Widget _dateOpener() => Builder(
  builder: (context) => ColoredBox(
    color: ComicTheme.of(context).colors.background,
    child: Center(
      child: ComicButton(
        'Due',
        onPressed: () => showComicDatePicker(
          context,
          value: DateTime(2026, 11, 20),
          currentDate: DateTime(2026, 11, 22),
        ),
      ),
    ),
  ),
);

// A page with the parts a screen falls on: a stroke of the lettering's ink, a caption's yellow, words, and a dialog to
// open over them.
const _stroke = Key('stroke');
Widget _screenedPage() => Builder(
  builder: (context) {
    final c = ComicTheme.of(context).colors;
    return ColoredBox(
      color: c.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ColoredBox(
                  key: _stroke,
                  color: c.text,
                  child: const SizedBox.square(dimension: 40),
                ),
                const SizedBox(width: 16),
                ColoredBox(
                  color: c.caption,
                  child: const SizedBox(width: 120, height: 40),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Due back at the desk before the festival closes.',
              style: TextStyle(color: c.text, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ComicButton(
              'Keep',
              onPressed: () => showComicDialog<void>(
                context,
                builder: (_) => const ComicDialog(
                  title: 'Keep this issue?',
                  message: 'Read it again whenever you like.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
);

Finder _day(String words) => find.bySemanticsLabel(words);

void main() {
  for (final rtl in [false, true]) {
    testWidgets(
      'at 1440 the date dialog is as wide as its calendar${rtl ? ' (RTL)' : ''}',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _pump(
            tester,
            size: const Size(1440, 900),
            rtl: rtl,
            home: _dateOpener(),
          );
          await tester.tap(find.byType(ComicButton).first);
          await tester.pumpAndSettle();
          // November 2026's first is a Sunday: the grid's last column.
          final sunday = tester.getRect(_day('November 1, 2026'));
          final choose = tester.getRect(find.byType(ComicButton).last);
          if (rtl) {
            expect(choose.left, closeTo(sunday.left, 1));
          } else {
            expect(choose.right, closeTo(sunday.right, 1));
          }
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final b in Brightness.values) {
    for (final (name, part) in <(String, Widget)>[
      (
        'date picker',
        ComicDatePicker(
          value: DateTime(2026, 11, 20),
          currentDate: DateTime(2026, 11, 22),
          onChanged: (_) {},
        ),
      ),
      (
        'range picker',
        ComicDateRangePicker(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          value: RawDateRange(DateTime(2026, 11, 9), DateTime(2026, 11, 13)),
          currentDate: DateTime(2026, 11, 22),
          onChanged: (_) {},
        ),
      ),
      (
        'wheel picker',
        ComicWheelPicker<int>(
          semanticLabel: 'Hour',
          values: const [6, 7, 8, 9, 10, 11, 12],
          value: 9,
          labelOf: (hour) => '$hour',
          onChanged: (_) {},
        ),
      ),
    ]) {
      testWidgets("a $name's chosen lamp keeps an ink contour (${b.name})", (
        tester,
      ) async {
        await _pump(
          tester,
          size: const Size(390, 844),
          brightness: b,
          home: Builder(
            builder: (context) => ColoredBox(
              color: ComicTheme.of(context).colors.background,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Align(alignment: Alignment.topCenter, child: part),
              ),
            ),
          ),
        );
        final t = ComicTheme.of(tester.element(find.byWidget(part)));
        final lamps = [
          for (final e in find.byType(DecoratedBox).evaluate())
            if ((e.widget as DecoratedBox).decoration
                case ShapeDecoration(:final color, :final shape)
                when color == t.colors.caption && shape is OutlinedBorder)
              shape,
        ];
        expect(lamps, isNotEmpty);
        for (final shape in lamps) {
          expect(
            _contrast(shape.side.color, t.colors.caption),
            greaterThanOrEqualTo(3),
          );
        }
      });
    }

    testWidgets(
      'a modal screen leaves the lettering under it whole (${b.name})',
      (tester) async {
        await _pump(
          tester,
          size: const Size(390, 844),
          brightness: b,
          home: _screenedPage(),
        );
        await tester.tap(find.byType(ComicButton).first);
        await tester.pumpAndSettle();
        final (shot, width) = await _shot(tester);
        // A stroke of the lettering's ink, wider than the screen's pitch: under the screen it prints unbroken.
        final stroke = tester.getRect(find.byKey(_stroke)).deflate(2);
        final first = _at(shot, width, stroke.left, stroke.top);
        var holes = 0;
        for (var y = stroke.top; y < stroke.bottom; y++) {
          for (var x = stroke.left; x < stroke.right; x++) {
            if (!_same(_at(shot, width, x, y), first)) holes++;
          }
        }
        expect(holes, 0);
      },
    );
  }

  testWidgets('at night the page behind a modal sits darker than the dialog', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      brightness: Brightness.dark,
      home: _screenedPage(),
    );
    final c = ComicTheme.of(tester.element(find.byKey(_stroke))).colors;
    await tester.tap(find.byType(ComicButton).first);
    await tester.pumpAndSettle();
    final (shot, width) = await _shot(tester);
    // The dialog's inked face: the nearest box round its words.
    final face = tester.getRect(
      find
          .ancestor(
            of: find.textContaining('Read it again'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    // The face's own fill, inside its border.
    final fill = _at(shot, width, face.left + 10, face.top + 10);
    expect(_same(fill, c.card), isTrue);
    // Everything around the dialog and its print, on average.
    final around = face.inflate(16);
    var sum = 0.0, n = 0;
    for (var y = 0; y < 844; y++) {
      for (var x = 0; x < 390; x++) {
        if (around.contains(Offset(x + .5, y + .5))) continue;
        sum += _at(shot, width, x, y).computeLuminance();
        n++;
      }
    }
    expect(sum / n, lessThan(fill.computeLuminance()));
    // The screen still reads, quietly: on the bare ground below the dialog its dots stand 1.2 to 1.4:1 off it.
    var low = 1.0, high = 0.0;
    for (var y = 844 - 60; y < 844; y++) {
      for (var x = 0; x < 390; x++) {
        final l = _at(shot, width, x, y).computeLuminance();
        if (l < low) low = l;
        if (l > high) high = l;
      }
    }
    expect((high + .05) / (low + .05), inInclusiveRange(1.2, 1.4));
  });

  testWidgets('the day the keys are on keeps its own edge', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      size: const Size(390, 844),
      home: Padding(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ComicDatePicker(
            value: DateTime(2026, 11, 20),
            currentDate: DateTime(2026, 11, 22),
            autofocus: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    bool edged(String day) => find
        .descendant(of: _day(day), matching: find.byType(DecoratedBox))
        .evaluate()
        .any(
          (e) => switch ((e.widget as DecoratedBox).decoration) {
            ShapeDecoration(:final OutlinedBorder shape) =>
              shape.side != BorderSide.none,
            _ => false,
          },
        );
    // The chosen day and the keys' day draw their own; a resting day's edges are the month's shared rules.
    expect(edged('November 20, 2026'), isTrue);
    expect(edged('November 21, 2026'), isTrue);
    expect(edged('November 22, 2026'), isFalse);
    semantics.dispose();
  });

  for (final rtl in [false, true]) {
    testWidgets(
      'a combobox list stands clear of its field${rtl ? ' (RTL)' : ''}',
      (tester) async {
        await _pump(
          tester,
          size: const Size(390, 844),
          rtl: rtl,
          home: Builder(
            builder: (context) => ColoredBox(
              color: ComicTheme.of(context).colors.background,
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ComicCombobox<String>(
                    labelText: 'Series',
                    options: ['Hall 1', 'Hall 2', 'Kino Arsenal', 'Main stage'],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        final field = tester.getRect(find.byType(ComicTextField));
        final list = tester.getRect(find.byType(ComicRaisedFrame).last);
        final (b, w) = await _shot(tester);
        final page = _at(b, w, 4, 4);
        // Down the middle of the field and the list: the field's rule and print, then paper, then the list's rule.
        var paper = 0;
        for (var y = field.bottom - 2; y < list.top + 2; y++) {
          if (_same(_at(b, w, field.center.dx, y), page)) paper++;
        }
        expect(paper, greaterThanOrEqualTo(3));
        // And at the field's end, where its print stands: paper there too.
        final endX = rtl ? field.left + 1 : field.right - 1;
        var paperAtEnd = 0;
        for (var y = field.bottom + 2; y < list.top + 2; y++) {
          if (_same(_at(b, w, endX, y), page)) paperAtEnd++;
        }
        expect(paperAtEnd, greaterThanOrEqualTo(2));
      },
    );
  }

  testWidgets('a combobox list opened above stands clear of its field', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      home: Builder(
        builder: (context) => ColoredBox(
          color: ComicTheme.of(context).colors.background,
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ComicCombobox<String>(
                labelText: 'Series',
                options: ['Hall 1', 'Hall 2', 'Kino Arsenal', 'Main stage'],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byType(ComicTextField));
    final list = tester.getRect(find.byType(ComicRaisedFrame).last);
    expect(list.bottom, lessThan(field.top));
    final (b, w) = await _shot(tester);
    final page = _at(b, w, 4, 4);
    // The list's print, then paper, then the lifted field's rule.
    var paper = 0;
    for (var y = list.bottom; y < field.top; y++) {
      if (_same(_at(b, w, field.center.dx, y), page)) paper++;
    }
    expect(paper, greaterThanOrEqualTo(3));
  });

  for (final (b, rtl) in [
    (Brightness.light, false),
    (Brightness.dark, false),
    (Brightness.light, true),
  ]) {
    testWidgets(
      "the keys' option carries a mark in the ink (${b.name}${rtl ? ', RTL' : ''})",
      (tester) async {
        await _pump(
          tester,
          size: const Size(390, 844),
          brightness: b,
          rtl: rtl,
          home: const Padding(
            padding: EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.topCenter,
              child: ComicCombobox<String>(
                labelText: 'Series',
                options: ['Hall 1', 'Hall 2', 'Kino Arsenal', 'Main stage'],
              ),
            ),
          ),
        );
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        Rect row(String label) => tester.getRect(
          find.byWidgetPredicate(
            (w) => w is ComicMenuRowFace && w.label == label,
          ),
        );
        final lit = row('Hall 2'), plain = row('Kino Arsenal');
        final (bytes, w) = await _shot(tester);
        // The room before the words: the lit row's mark stands there, a plain row's is bare.
        double most(Rect r) {
          final fill = _at(bytes, w, r.center.dx, r.top + 3);
          var m = 1.0;
          for (var i = 0; i < 8; i++) {
            final x = rtl ? r.right - 1 - i : r.left + i;
            for (final y in [r.center.dy - 6, r.center.dy, r.center.dy + 6]) {
              final c = _contrast(_at(bytes, w, x, y), fill);
              if (c > m) m = c;
            }
          }
          return m;
        }

        expect(most(lit), greaterThanOrEqualTo(3));
        expect(most(plain), lessThan(1.5));
      },
    );
  }

  testWidgets("a calendar's rules are one weight, inside and out", (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      home: Builder(
        builder: (context) => ColoredBox(
          color: ComicTheme.of(context).colors.background,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.topCenter,
              child: ComicDatePicker(
                value: DateTime(2026, 11, 20),
                currentDate: DateTime(2026, 11, 22),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    final semantics = tester.ensureSemantics();
    try {
      // The week of the 2nd to the 8th, a row's height under its top rule: across it, every rule it meets.
      final monday = tester.getRect(_day('November 2, 2026'));
      final sunday = tester.getRect(_day('November 8, 2026'));
      final (b, w) = await _shot(tester);
      final y = monday.top + 6;
      final ground = _at(b, w, monday.center.dx, y);
      final runs = <int>[];
      var run = 0;
      for (var x = monday.left - 3; x <= sunday.right + 3; x++) {
        if (!_same(_at(b, w, x, y), ground)) {
          run++;
        } else if (run > 0) {
          runs.add(run);
          run = 0;
        }
      }
      if (run > 0) runs.add(run);
      expect(
        runs,
        hasLength(8),
        reason: 'eight rules across seven days: $runs',
      );
      expect(runs.toSet(), hasLength(1), reason: 'one weight: $runs');
    } finally {
      semantics.dispose();
    }
  });
}
