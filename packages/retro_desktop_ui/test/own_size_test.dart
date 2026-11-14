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
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    this.reach = false,
    this.centred = false,
  });
  final Size size;
  final Widget Function() build;

  /// It presses, so the Android test host reserves 48 lp, with its art centered in that target.
  final bool reach;

  /// The words are the art's middle: a monogram's initials.
  final bool wordsCentred;

  /// It is a glyph: across a stretching parent it stands on the middle of the room it is handed, as an [Icon]'s glyph
  /// does (a back button's face gave the triangle more room than the mark, and it sat in the room's top corner).
  final bool centred;
}

final _fixed = <String, _Fixed>{
  'RetroDesktopAvatar': _Fixed(
    const Size(40, 40),
    () => const RetroDesktopAvatar('AC'),
    wordsCentred: true,
  ),
  'RetroDesktopCircularProgressIndicator': _Fixed(
    const Size(32, 32),
    () => const RetroDesktopCircularProgressIndicator(value: .5),
  ),
  'RetroDesktopFolderArt': _Fixed(
    const Size(56, 44),
    () => const RetroDesktopFolderArt(),
  ),
  'RetroDesktopFilePageArt': _Fixed(
    const Size(44, 52),
    () => const RetroDesktopFilePageArt(),
  ),
  'RetroDesktopSystemMark': _Fixed(
    const Size(16, 16),
    () => const RetroDesktopSystemMark(),
  ),
  'RetroDesktopDeskArt': _Fixed(
    const Size(48, 48),
    () => const RetroDesktopDeskArt(RetroDesktopDeskMark.floppy),
  ),
  // A button's face height, square: beside a button it shows a button's
  // height (one line of words, the density's padding, the rim).
  'RetroDesktopIconButton': _Fixed(
    const Size(40, 40),
    () => const RetroDesktopIconButton(LucideIcons.plus, label: 'Add'),
    reach: true,
  ),
  'RetroDesktopTriangleMark': _Fixed(
    const Size(12, 12),
    () => const RetroDesktopTriangleMark(AxisDirection.down),
    centred: true,
  ),
  // Off: its tick breaks out of the box on purpose, as the concept's does.
  'RetroDesktopCheckbox': _Fixed(
    const Size(18, 18),
    () => const RetroDesktopCheckbox(value: false, label: 'Option'),
    reach: true,
  ),

  'RetroDesktopPriority': _Fixed(
    const Size(11, 12),
    () => const RetroDesktopPriority(1),
  ),
  'RetroDesktopMonogram': _Fixed(
    const Size(26, 19),
    () => const RetroDesktopMonogram('AC'),
    wordsCentred: true,
  ),
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
  'RetroDesktopMedia': _Fill(
    1200,
    () => const RetroDesktopMedia(slotId: 'nothing-here'),
    aspect: null,
  ),
};

/// Parts that paint to the size they are given, so a stretching parent only makes them wider, or that hold their fixed
/// pieces inside a row of their own. `support.dart`'s `check` holds these at both widths in the other tests.
const _flows = <String, String>{
  'RetroDesktopNumberField': 'as wide as the longest value its range allows, its two buttons keeping their targets; it shrinks only in a narrower slot',
  'RetroDesktopSelect':
      'its value keeps the popup face within the available width',
  'RetroDesktopBadge': 'aligns to the count and wraps beside its child',
  'RetroDesktopBeaconArt': 'scales the example drawing to the supplied slot',
  'RetroDesktopChart':
      'fills the plot width and reserves the requested plot height',
  'RetroDesktopDisclosure': 'fills its row and grows to its expanded child',
  'RetroDesktopPageDots':
      'wraps its target-sized pages inside the available width',
  'RetroDesktopPicture': 'fits its image inside the requested aspect ratio',
  'RetroDesktopSlider': 'fills its track width with a target-height face',
  'RetroDesktopSurface': 'fills the caller constraints around its child',
  'RetroDesktopToolbar': 'wraps controls within its plate',

  'RetroDesktopNavigationBar': 'the full width of the page',
  'RetroDesktopDeskStrip': 'hugs its items, its ends drawn to its size',
  'RetroDesktopScaffold': 'the whole page',
  'RetroDesktopAppBar': 'the full width of the page',
  'RetroDesktopPictureCard':
      'paints to its size, the picture in a RetroDesktopFill',
  'RetroDesktopObjectArt':
      'the middle of the room it is given, in whole pixel steps',
  'RetroDesktopButton': 'as wide as its words, by the hugging law below',
  'RetroDesktopPopupButton': 'as wide as its words, by the hugging law below',
  'RetroDesktopTextField': 'paints to its size',
  'RetroDesktopFlag': 'as wide as its words, by the hugging law below',
  'RetroDesktopKbd': 'as wide as its words, by the hugging law below',
  'RetroDesktopChip': 'as wide as its words, by the hugging law below',
  'RetroDesktopLinearProgressIndicator': 'a bar the width of its column',
  'RetroDesktopChoiceBox': 'paints to its size',
  'RetroDesktopTabBar': 'the width of its window',
  'RetroDesktopWindow': 'paints to its size',
  'RetroDesktopWell': 'paints to its size',
  'RetroDesktopToolRule': 'a rule the height of its bar',
  'RetroDesktopWindowShade': 'paints to its size',
  'RetroDesktopAlert': 'paints to its size',
  'RetroDesktopDescriptionList': 'its leaders fill a column of their own',
  'RetroDesktopStats': 'a rule the width of its column',
  'RetroDesktopHighlight': 'paints to the size of the part it rings',
  'RetroDesktopPagination':
      'one line of target-sized pages, folding to the width it is given',
  'RetroDesktopRating': 'target-sized stars that wrap within the width',
  'RetroDesktopFileUpload': 'fills its column; its list grows with the files',
  'RetroDesktopSparkline': 'its own width and height through retroDesktopOwnSize, scaled down to fit',
  'RetroDesktopReadings': 'rules the height of their cells',
  'RetroDesktopMeasures': 'cells in a grid, painted to their size',
  'RetroDesktopThumbGauge': 'a bar the width of its column',
  'RetroDesktopMonthGrid': 'cells take their share of the width',
  'RetroDesktopLegend': 'marks in a wrap, each in a row of its own',
  'RetroDesktopPixelSky': 'the width of its strip, cut to the columns',
  'RetroDesktopHourStrip': 'the width of its window',
  'RetroDesktopRangeShape': 'the width of its window, its cap held inside',
  'RetroDesktopHatchBars': 'the width of its window',
  'RetroDesktopDayBars': 'columns take their share of the width',
  'RetroDesktopScaleBar': 'a bar the width of its column',
  'RetroDesktopSpanBar': 'a bar the width of its column',
  'RetroDesktopListTable': 'the width of its window',
  'RetroDesktopTable': 'the width of its window',
  'RetroDesktopFolderGrid': 'tiles take their share of the width',
  'RetroDesktopFileGrid': 'tiles take their share of the width',
  'RetroDesktopTreeBars': 'bars take the middle of each row',
  'RetroDesktopChecklist': 'rows paint to their size',
  'RetroDesktopReorderableListView':
      'rows paint to their size; a drag\'s outline is the dragged row\'s',
  'RetroDesktopDayTile':
      'a tile of its own width, holding its sheets and rings',
  'RetroDesktopScrollArea': 'fills what it is given, the bar beside the view',
  'RetroDesktopResizable': 'fills what it is given, the panes share it',
  'RetroDesktopTimeline': 'a rail the height of each entry',
  'RetroDesktopTag': 'as wide as its words',
  'RetroDesktopRangeSlider': 'fills its track width with a target-height face',
  'RetroDesktopColorPicker': 'fills its column, the area at its own height',
  'RetroDesktopInputOtp': 'boxes share the column, 36 wide at most',
  'RetroDesktopSkeleton': 'bars the width of their column, the last two-thirds; the checkerboard painted to their size',
};

final _drawn = RegExp(
  // _gripWithRing: the sliders' painted grip at its own 16 by 24.
  r'CustomPaint\(|RetroDesktopPixelPaint\(|retroDesktopFace\(|retroDesktopOwnSize\(|RetroDesktopFill\(|Stack\(|AspectRatio\(|_gripWithRing\(|'
  r'(?:SizedBox|Container)\(\s*(?:key:[^,]*,\s*)?width: (?!double\.infinity)[^,\n]+,\s*height: ',
);

/// The public widgets whose source draws or holds a size.
Set<String> _drawnParts() {
  final found = <String>{};
  final files = [
    for (final dir in ['lib/src/retro_desktop', 'example/lib/demo_art'])
      if (Directory(dir).existsSync())
        ...Directory(dir).listSync(recursive: true).whereType<File>(),
  ];
  for (final file in files) {
    if (!file.path.endsWith('.dart')) continue;
    final source = file.readAsStringSync();
    final classes = RegExp(
      r'^class (\w+)[^{]*\{',
      multiLine: true,
    ).allMatches(source).toList();
    for (var i = 0; i < classes.length; i++) {
      final name = classes[i][1]!;
      if (name.startsWith('_')) continue;
      final end = i + 1 < classes.length ? classes[i + 1].start : source.length;
      var body = source.substring(classes[i].start, end);
      // Stateful controls paint in their State class, not in createState.
      for (var j = 0; j < classes.length; j++) {
        if (!RegExp('extends\\s+State<$name(?:<[^>]+>)?>')
            .hasMatch(classes[j][0]!)) {
          continue;
        }
        final stateEnd = j + 1 < classes.length
            ? classes[j + 1].start
            : source.length;
        body += source.substring(classes[j].start, stateEnd);
      }
      final widget =
          body.contains('Widget build(') || body.contains('createState');
      if (widget && (_drawn.hasMatch(body) || _handsOff(name, body, source))) {
        found.add(name);
      }
    }
  }
  return found;
}

// A public part that draws through a private widget of its own file: its custom paint (a highlight's), or its own
// faces, named for it (a button's _PlainButton, _DefaultButton, _ExtraButton), when one of those draws.
bool _handsOff(String part, String body, String source) {
  final kind = part.replaceFirst('RetroDesktop', '');
  final classes = RegExp(
    r'^class (_\w+)[^{]*\{',
    multiLine: true,
  ).allMatches(source).toList();
  final all = RegExp(
    r'^class \w+',
    multiLine: true,
  ).allMatches(source).toList();
  for (final c in classes) {
    final name = c[1]!;
    if (!RegExp('\\b${RegExp.escape(name)}\\(').hasMatch(body)) continue;
    final next = all.where((m) => m.start > c.start).firstOrNull;
    final own = source.substring(c.start, next?.start ?? source.length);
    if (own.contains('extends CustomPaint')) return true;
    if (name.endsWith(kind) && _drawn.hasMatch(own)) return true;
  }
  return false;
}

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
  final theme = RetroDesktopThemeData.preset(
    RetroDesktopThemeData.presets.first,
    dark ? Brightness.dark : Brightness.light,
  );
  const stretch = CrossAxisAlignment.stretch;
  return MediaQuery(
    data: MediaQueryData(size: Size(width, height)),
    child: Directionality(
      textDirection: direction,
      child: RetroDesktopTheme(
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
    await loadRetroDesktopFonts();
  });

  test('every part that draws or holds a size is named in a table', () {
    final found = _drawnParts();
    // The catalog installs these host adapters beneath the look; the standalone
    // package intentionally excludes kit dependencies. Their viewport sizing,
    // keyboard insets and long-content scrolling are held by the kit contract.
    final kitFlows = Directory('lib/src/retro_desktop/kit_parts').existsSync()
        ? const {
            'RetroDesktopKitScreen': 'fills the viewport, scrolls its body and reserves keyboard insets',
            'RetroDesktopKitMainScreen': 'fills the viewport width and scrolls its content above shell insets',
          }
        : const <String, String>{};
    final named = {
      ..._fixed.keys,
      ..._fills.keys,
      ..._flows.keys,
      ...kitFlows.keys,
    };
    expect(
      found.difference(named),
      isEmpty,
      reason: 'a new part: add it to a table above',
    );
    expect(
      named.difference(found),
      isEmpty,
      reason: 'gone from the library: take it out of its table',
    );
    final twice = _fixed.keys.toSet().intersection(_fills.keys.toSet());
    expect(twice, isEmpty);
  });

  test('a box of fixed size around a paint or a Stack goes through retroDesktopOwnSize', () {
    final raw = RegExp(
      r'SizedBox\(\s*width: [^,\n]+,\s*height: [^,\n]+,\s*child: (?:CustomPaint|RetroDesktopPixelPaint|Stack)|CustomPaint\(\s*size: ',
    );
    final found = <String>[];
    for (final file in Directory(
      'lib/src/retro_desktop',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final m in raw.allMatches(file.readAsStringSync())) {
        found.add('${file.path}: ${m[0]!.replaceAll(RegExp(r'\s+'), ' ')}');
      }
    }
    expect(found, isEmpty);
  });

  // No fixed size, but no bar across a column either: Gilt's first review passed every gate with a part ballooned by a
  // section's stretch, because no page put it there.
  group('a part that hugs its words', () {
    final hugs = <String, Widget>{
      'RetroDesktopButton (isDefaultAction)': RetroDesktopButton(
        'A word',
        isDefaultAction: true,
        onPressed: () {},
      ),
      'RetroDesktopButton': RetroDesktopButton('A word', onPressed: () {}),
      'RetroDesktopPopupButton': const RetroDesktopPopupButton('A word'),
      'RetroDesktopKbd': const RetroDesktopKbd('Ctrl K'),
      'RetroDesktopChip': const RetroDesktopChip('A word'),
      'RetroDesktopFlag': const RetroDesktopFlag('A word'),
    };
    for (final MapEntry(key: name, value: part) in hugs.entries) {
      for (final parent in const [_Parent.column, _Parent.row]) {
        testWidgets('$name in a stretching ${parent.name}', (tester) async {
          await _pump(
            tester,
            _stage(parent, TextDirection.ltr, part, 1440, 400),
            1440,
            400,
          );
          expect(tester.takeException(), isNull);
          final painted = await _painted(tester);
          expect(painted, isNotNull);
          expect(painted!.width, lessThan(200));
          expect(painted.height, lessThan(60));
        }, tags: const ['goldens']);
      }
    }
  });

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
                      (b.size.width - part.size.width).abs() < .01 &&
                      (b.size.height - part.size.height).abs() < .01,
                );
                final problems = <String>[];
                if (box.isEmpty) {
                  problems.add(
                    'no box of its declared ${part.size}: ${boxes.first.size}',
                  );
                }
                final reach = part.reach
                    ? Offset(
                        math.max(0, (48 - part.size.width) / 2),
                        math.max(0, (48 - part.size.height) / 2),
                      )
                    : Offset.zero;
                final room = width - part.size.width;
                final across = part.centred && parent == _Parent.column;
                final x = across
                    ? room / 2
                    : direction == TextDirection.ltr
                    ? reach.dx
                    : room - reach.dx;
                final y = part.centred && parent == _Parent.row
                    ? (height - part.size.height) / 2
                    : reach.dy;
                final place = Offset(x, y) & part.size;
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
              tags: const ['goldens'],
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
          }, tags: const ['goldens']);
        }
      }
    }
  });
}
