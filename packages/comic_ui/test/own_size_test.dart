// A part with its own size keeps it, and a part that fills its width stays in proportion, whatever its parent asks. A
// stretching Column or Row hands tight constraints, which a SizedBox can't refuse: the fob ballooned to the column's width
// and painted over its neighbours, and a monogram's ring stayed at the left while its letters went to the column's centre.
// The gallery's sections stretch, and so does what a unit writes. Every part that draws or holds a size is enumerated from
// the source, so a new one fails here until it is named in a table.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/src/comic/press.dart' show ComicStateDecoration;

import 'support.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../example/lib/demo_art.dart';

/// A part with its own size. In a wider column it stands at the start (left in LTR, mirrored in RTL).
class _Fixed {
  const _Fixed(
    this.size,
    this.build, {
    this.wordsCentred = false,
    this.faceWide = false,
  });
  final Size size;
  final Widget Function() build;

  /// The words are the art's middle: a burst's figure, a ring's initials.
  final bool wordsCentred;

  /// A press with a least target of [size]: as tall as its target, as wide as its drawn face (no wider than the
  /// target), the target's sides standing outward beside the face, so the face starts on its parent's start.
  final bool faceWide;
}

final _fixed = <String, _Fixed>{
  'ComicAvatar': _Fixed(
    const Size(40, 40),
    () => const ComicAvatar('NW'),
    wordsCentred: true,
  ),
  'ComicAvatarGroup': _Fixed(
    const Size(90, 36),
    () => const ComicAvatarGroup([
      ComicFace('NW'),
      ComicFace('AK'),
      ComicFace('JR'),
    ]),
  ),
  'ComicCircularProgressIndicator': _Fixed(
    const Size(32, 32),
    () => const ComicCircularProgressIndicator(value: .5),
  ),
  'ComicSwitch': _Fixed(
    const Size(48, 48),
    () => const ComicSwitch(value: true),
  ),
  'ComicSendButton': _Fixed(
    const Size(48, 48),
    () => const ComicSendButton(),
    faceWide: true,
  ),
  'ComicSparkline': _Fixed(
    const Size(96, 28),
    () => const ComicSparkline(label: 'Sales', values: [3, 5, 4, 8, 6, 9]),
  ),
  'ComicCheckbox': _Fixed(
    const Size(48, 48),
    () => const ComicCheckbox(label: 'Keep issue', value: true),
    faceWide: true,
  ),
  'ComicBackButton': _Fixed(
    const Size(48, 48),
    () => const ComicBackButton(),
    faceWide: true,
  ),
  'ComicIconButton': _Fixed(
    const Size(48, 48),
    () => const ComicIconButton(Icons.add, label: 'Add'),
    faceWide: true,
  ),
  'ComicPerson': _Fixed(
    const Size(36, 36),
    () => const ComicPerson(initials: 'AC'),
    wordsCentred: true,
  ),
  'ComicMark': _Fixed(
    const Size(104, 104),
    () => const ComicMark(ComicMarks.mug),
  ),
  'ComicPop': _Fixed(
    const Size(48, 42),
    () => const ComicPop('5', width: 48, height: 42),
  ),
  'ComicBurst': _Fixed(
    const Size(146, 124),
    () => const ComicBurst(number: '23', width: 146, height: 124, tilt: 0),
  ),
  // The 56 face and its print, 4 down and to the end.
};

/// A part that fills the width it is given, up to [maxWidth], and past that stands in the middle of the column. Its art, if
/// it has one, keeps [aspect].
class _Fill {
  const _Fill(this.maxWidth, this.build, {required this.aspect});
  final double maxWidth;
  final Widget Function() build;
  final double? aspect;
}

final _fills = <String, _Fill>{
  // A picture crops to the box it is given, so a stretched cell can't distort it.
  'ComicMedia': _Fill(
    1200,
    () => const ComicMedia(slotId: 'nothing-here'),
    aspect: null,
  ),
};

/// Parts that paint to the size they are given, so a stretching parent only makes them wider, or that hold their fixed
/// pieces inside a row of their own. `support.dart`'s `check` holds these at both widths in the other tests.
const _flows = <String, String>{
  'ComicChart': 'the plot fills width; axis labels and legend stand outside its own height',
  'ComicPageDots': 'a wrapping row of caption marks, each in its full target',
  'ComicSkeleton': 'the placeholder fills available width when none is given',
  'ComicStars':
      'a row of small drawings, each its own size, standing at the start',
  'ComicNavigationBar': 'the full width of the page',
  'ComicNavigationRail':
      'the full height of its column, at the rail\'s own width',
  'ComicHighlight':
      'paints the wash and ring to the part it wraps, at that part\'s size',
  'ComicRating':
      'a row of stars, each in its own target, standing at the start',
  'ComicTier': 'its panels share a row the width it is given',
  'ComicPanelStack': 'panels in a column, sharing the height',
  'ComicBalloon': 'hugs its words up to the width; fill: takes it. The path is drawn to its size',
  'ComicThought': 'hugs its words; the cloud paints to its size',
  'ComicBenDay': 'paints to its size',
  'ComicCoverPrint': 'paints to its size',
  'ComicActionLines': 'paints to its size',
  'ComicDrawing': 'scales its art into what it is given, by its fit',
  'ComicLineup': 'a row of shares, the width of its column',
  'ComicCover': 'a panel the width of its column',
  'ComicSplash': 'a panel the width of its column',
  'ComicBar': 'paints to its size, its height its own',
  'ComicFlow': 'three cells, the middle one painted to its size',
  'ComicShares': 'paints to its size, its height its own',
  'ComicUnits': 'a share of the row per column',
  'ComicPieChart': 'its pie holds its own size in a row of its own',
  'ComicProgressCells': 'a share of the row per cell',
  'ComicSegments': 'a bar the width of its column; a number that does not fit its block goes to the key under the bar and its scale',
  'ComicArtBand': 'paints to its size',
  'ComicEventPanel': 'a panel the width of its column',
  'ComicStepPanel': 'a panel the width of its column',
  'ComicVoicePanel': 'a panel the width of its column',
  'ComicChapterPanel': 'a panel the width of its column',
  'ComicRangeSlider':
      'a track the width of its column; its two thumbs hold their own size',
  'ComicWheelPicker':
      'a drum the width of its column, its rows\' height its own',
  'ComicResizable':
      'two panes share the size it is given; the grip holds its own',
  'ComicReorderableListView':
      'rows the width of its column, each grip its own size',
  'ComicDivider': 'a rule the length it is given',
  'ComicTimeline': 'entries the width of its column, each mark and rule painted beside its words',
  'ComicTreeView':
      'rows the width of its column; the keyboard\'s ring laid inside its row',
  'ComicChip': 'hugs its words; a stretching column widens its face, a remove cross at the face\'s end (held below)',
};

// A part drawn through its own RenderObject shows none of these; its laws are in print_test.dart.
final _drawn = RegExp(
  r'CustomPaint\(|comicPaint\(|comicOwnSize\(|ComicFill\(|Stack\(|AspectRatio\(|'
  r'(?:SizedBox|Container)\(\s*(?:key:[^,]*,\s*)?width: (?!double\.infinity)[^,\n]+,\s*height: ',
);

/// The public widgets whose source draws or holds a size.
Set<String> _drawnParts() {
  final found = <String>{};
  final libraries = [
    Directory('lib/src/comic'),
    // Packaged demo art lives in the example and is still part of this census.
    if (Directory('example/lib/demo_art').existsSync())
      Directory('example/lib/demo_art'),
  ];
  for (final file
      in libraries
          .expand((library) => library.listSync(recursive: true))
          .whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    final source = file.readAsStringSync();
    final classes = RegExp(
      r'^class (\w+)[^\n{]*\{',
      multiLine: true,
    ).allMatches(source).toList();
    for (var i = 0; i < classes.length; i++) {
      final name = classes[i][1]!;
      if (name.startsWith('_')) continue;
      final end = i + 1 < classes.length ? classes[i + 1].start : source.length;
      final body = source.substring(classes[i].start, end);
      final widget =
          body.contains('Widget build(') || body.contains('createState');
      if (widget && _drawn.hasMatch(body)) found.add(name);
    }
  }
  return found;
}

/// In `_fixed` though their source shows no size: it's held by the private class or the part they're built from.
// ComicChart's plot is painted by its State, which the source scan doesn't attribute to the widget; support.dart's
// `check` and painting_test hold it.
const _heldElsewhere = {
  'ComicBackButton',
  'ComicBurst',
  'ComicChart',
  'ComicSendButton',
};

enum _Parent { column, row, expanded }

const _stageKey = ValueKey('stage');

Widget _stage(
  _Parent parent,
  TextDirection direction,
  Widget part,
  double width,
  double height, {
  bool dark = false,
}) {
  final theme = ComicTheme.preset(
    ComicThemeData.presets.first,
    dark ? Brightness.dark : Brightness.light,
  );
  const stretch = CrossAxisAlignment.stretch;
  return MediaQuery(
    data: MediaQueryData(size: Size(width, height)),
    child: Directionality(
      textDirection: direction,
      child: ComicTheme(
        data: theme,
        child: RepaintBoundary(
          key: _stageKey,
          child: switch (parent) {
            _Parent.column => Column(
              crossAxisAlignment: stretch,
              children: [part],
            ),
            _Parent.row => Row(crossAxisAlignment: stretch, children: [part]),
            _Parent.expanded => Row(
              crossAxisAlignment: stretch,
              children: [Expanded(child: part)],
            ),
          },
        ),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget stage,
  double width,
  double height,
) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(stage);
  await tester.pump();
}

/// The stage as pixels, with nothing behind the part.
Future<(int, int, Uint8List)> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stageKey),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final out = (image.width, image.height, bytes!.buffer.asUint8List());
    image.dispose();
    return out;
  }))!;
}

/// The smallest rectangle holding everything the stage painted, or null if it painted nothing.
Future<Rect?> _painted(WidgetTester tester) async {
  final (w, h, px) = await _pixels(tester);
  var (l, t, r, b) = (w, h, -1, -1);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (px[(y * w + x) * 4 + 3] <= 8) continue;
      l = math.min(l, x);
      r = math.max(r, x);
      t = math.min(t, y);
      b = math.max(b, y);
    }
  }
  return r < 0
      ? null
      : Rect.fromLTRB(l.toDouble(), t.toDouble(), r + 1.0, b + 1.0);
}

Rect _global(RenderBox b) =>
    MatrixUtils.transformRect(b.getTransformTo(null), Offset.zero & b.size);

/// The render boxes under the part, outermost first.
List<RenderBox> _boxes(Finder part) =>
    collectAllElementsFrom(part.evaluate().single, skipOffstage: false)
        .map((e) => e.renderObject)
        .whereType<RenderBox>()
        .where((b) => b.hasSize)
        .toList();

bool _holds(Rect outer, Rect inner, double slack) =>
    inner.left >= outer.left - slack &&
    inner.top >= outer.top - slack &&
    inner.right <= outer.right + slack &&
    inner.bottom <= outer.bottom + slack;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  test('every part that draws or holds a size is named in a table', () {
    final found = _drawnParts();
    final named = {..._fixed.keys, ..._fills.keys, ..._flows.keys};
    expect(
      found.difference(named),
      isEmpty,
      reason: 'a new part: add it to a table above',
    );
    expect(
      named.difference(found).difference(_heldElsewhere),
      isEmpty,
      reason: 'gone from the library: take it out of its table',
    );
    final twice = _fixed.keys.toSet().intersection(_fills.keys.toSet());
    expect(twice, isEmpty);
  });

  test(
    'a box of fixed size around a paint or a Stack goes through comicOwnSize',
    () {
      final raw = RegExp(
        r'SizedBox\(\s*width: [^,\n]+,\s*height: [^,\n]+,\s*child: (?:CustomPaint|Stack)|CustomPaint\(\s*size: ',
      );
      final found = <String>[];
      for (final file in Directory(
        'lib/src/comic',
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        for (final m in raw.allMatches(file.readAsStringSync())) {
          found.add('${file.path}: ${m[0]!.replaceAll(RegExp(r'\s+'), ' ')}');
        }
      }
      expect(found, isEmpty);
    },
  );

  group('a part with its own size', () {
    for (final MapEntry(key: name, value: part) in _fixed.entries) {
      for (final parent in const [_Parent.column, _Parent.row]) {
        for (final width in const [320.0, 1440.0]) {
          for (final direction
              in width == 1440
                  ? TextDirection.values
                  : const [TextDirection.ltr]) {
            testWidgets(
              '$name in a stretching ${parent.name} at $width ${direction.name}',
              (tester) async {
                const height = 400.0;
                await _pump(
                  tester,
                  _stage(parent, direction, part.build(), width, height),
                  width,
                  height,
                );
                expect(tester.takeException(), isNull);
                final finder = find.byWidgetPredicate(
                  (w) => w.runtimeType.toString() == name,
                );
                final boxes = _boxes(finder);
                final box = boxes.where(
                  (b) =>
                      (part.faceWide
                          ? b.size.width <= part.size.width + .01
                          : (b.size.width - part.size.width).abs() < .01) &&
                      (b.size.height - part.size.height).abs() < .01,
                );
                final problems = <String>[];
                if (box.isEmpty) {
                  problems.add(
                    'no box of its declared ${part.size}: ${boxes.first.size}',
                  );
                }
                final own = part.faceWide && box.isNotEmpty
                    ? box.first.size
                    : part.size;
                final room = width - own.width;
                final x = direction == TextDirection.ltr ? 0.0 : room;
                final place = Offset(x, 0) & own;
                final at = place;
                if (box.isNotEmpty) {
                  final rect = _global(box.first);
                  if ((rect.topLeft - place.topLeft).distance > .5) {
                    problems.add(
                      'at ${rect.topLeft}, not the start of its parent, ${place.topLeft}',
                    );
                  }
                }
                for (final words in boxes.whereType<RenderParagraph>()) {
                  final rect = _global(words);
                  if (!_holds(at, rect, 1)) {
                    problems.add('words at $rect outside its art $at');
                  }
                  if (part.wordsCentred &&
                      (rect.center.dx - at.center.dx).abs() > 1.5) {
                    problems.add(
                      'words centred at ${rect.center.dx}, its art at ${at.center.dx}',
                    );
                  }
                }
                final painted = await _painted(tester);
                if (painted == null) {
                  problems.add('paints nothing');
                } else if (!_holds(at, painted, 1.5)) {
                  problems.add('paints $painted outside its box $at');
                }
                expect(problems, isEmpty);
              },
              // What it paints is read from the drawn pixels: the rasterizer's, as a golden's (Linux CI leaves it
              // to macOS).
              tags: 'goldens',
            );
          }
        }
      }
    }
  });

  group('a part that fills its width', () {
    for (final MapEntry(key: name, value: part) in _fills.entries) {
      for (final parent in _Parent.values) {
        for (final width in const [320.0, 1440.0]) {
          testWidgets('$name in a stretching ${parent.name} at $width', (
            tester,
          ) async {
            const height = 900.0;
            await _pump(
              tester,
              _stage(parent, TextDirection.ltr, part.build(), width, height),
              width,
              height,
            );
            expect(tester.takeException(), isNull);
            final finder = find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == name,
            );
            final problems = <String>[];
            final most = math.min(part.maxWidth, width);
            final painted = await _painted(tester);
            if (painted == null) {
              problems.add('paints nothing');
            } else {
              if (painted.width > most + 3) {
                problems.add('paints ${painted.width} wide, its limit $most');
              }
              if (part.aspect != null && painted.bottom > height - 1) {
                problems.add('paints to the foot of a $height stage: $painted');
              }
            }
            final art = _boxes(finder).whereType<RenderCustomPaint>().toList();
            if (part.aspect != null) {
              if (art.isEmpty) {
                problems.add('no art to read');
              } else {
                final rect = _global(art.first);
                final ratio = rect.width / rect.height;
                if ((ratio - part.aspect!).abs() > part.aspect! * .02) {
                  problems.add(
                    'art ${rect.size}, aspect $ratio, not ${part.aspect}',
                  );
                }
                if (rect.width > most + .5) {
                  problems.add('art ${rect.width} wide, its limit $most');
                }
                if (parent != _Parent.row && width > part.maxWidth) {
                  final mid = rect.center.dx, want = width / 2;
                  if ((mid - want).abs() > 1) {
                    problems.add('centred at $mid, not $want');
                  }
                }
              }
            }
            expect(problems, isEmpty);
          }, tags: 'goldens'); // what it paints, from the drawn pixels
        }
      }
    }
  });

  // A removable chip's face takes a stretching column's width, as the plain chip's does, and its cross and the cross's
  // press go with the face's end, never to the column's end with the face hugging its words at the start (11-12).
  for (final width in const [320.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'a removable chip in a stretching column at $width ${direction.name}',
        (tester) async {
          const height = 400.0;
          await _pump(
            tester,
            _stage(
              _Parent.column,
              direction,
              ComicChip('History', onDeleted: () {}),
              width,
              height,
            ),
            width,
            height,
          );
          expect(tester.takeException(), isNull);
          final face = tester.getRect(
            find
                .descendant(
                  of: find.byType(ComicChip),
                  matching: find.byType(ComicStateDecoration),
                )
                .first,
          );
          final glyph = tester.getRect(find.byIcon(ComicGlyphs.x));
          final press = tester.getRect(
            find.descendant(
              of: find.byType(ComicChip),
              matching: find.byType(ComicPressable),
            ),
          );
          final problems = <String>[
            if ((face.width - width).abs() > .5)
              'the face $face, not the column\'s width $width',
            if (!_holds(face, glyph, .5))
              'the cross $glyph outside its face $face',
            if ((direction == TextDirection.ltr
                    ? face.right - glyph.right
                    : glyph.left - face.left) >
                24)
              'the cross $glyph away from its face\'s end $face',
            if ((press.center.dx - glyph.center.dx).abs() > 2.5 ||
                (press.center.dy - face.center.dy).abs() > .5)
              'the press $press off the cross $glyph',
          ];
          expect(problems, isEmpty);
        },
      );
    }
  }
}
