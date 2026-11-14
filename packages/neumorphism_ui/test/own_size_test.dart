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
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/chart.dart' show NeumorphicChart;
import 'package:neumorphism_ui/src/neumorphism/internal/reach.dart'
    show NeumorphicFaceEdge;
import 'package:neumorphism_ui/src/neumorphism/ornaments.dart'
    show NeumorphicMark;

import 'support.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../example/lib/demo_art.dart';

/// A part with its own size. In a wider column it stands at the start (left in LTR, mirrored in RTL), unless [centred] by design.
class _Fixed {
  const _Fixed(this.size, this.build, {this.wordsCentred = false});
  final Size size;
  final Widget Function() build;

  /// The words are the art's middle: a ring's initials or figure.
  final bool wordsCentred;
}

final _fixed = <String, _Fixed>{
  'NeumorphicAvatar': _Fixed(
    const Size(40, 40),
    () => const NeumorphicAvatar('NW'),
    wordsCentred: true,
  ),
  'NeumorphicCircularProgressIndicator': _Fixed(
    const Size(28, 28),
    () => const NeumorphicCircularProgressIndicator(value: .5),
  ),
  'NeumorphicLed': _Fixed(const Size(8, 8), () => const NeumorphicLed()),
  'NeumorphicShapeMark': _Fixed(
    const Size(10, 10),
    () => const NeumorphicShapeMark(NeumorphicMarkShape.half),
  ),
  'NeumorphicMonogram': _Fixed(
    const Size(36, 36),
    () => const NeumorphicMonogram('AB'),
    wordsCentred: true,
  ),
  'NeumorphicIconWell': _Fixed(
    const Size(44, 44),
    () => const NeumorphicIconWell(NeumorphicGlyphs.house),
  ),
  'NeumorphicBrandMark': _Fixed(
    const Size(36, 36),
    () => const NeumorphicBrandMark(),
  ),
  'NeumorphicMark': _Fixed(const Size(44, 44), () => const NeumorphicMark()),
  'NeumorphicRoundButton': _Fixed(
    const Size(48, 48),
    () => const NeumorphicRoundButton(NeumorphicGlyphs.plus),
  ),
  'NeumorphicSwitch': _Fixed(
    const Size(56, 48),
    () => const NeumorphicSwitch(value: true),
  ),
  'NeumorphicRoundCheckbox': _Fixed(
    const Size(48, 48),
    () => const NeumorphicRoundCheckbox(value: true),
  ),
  'NeumorphicSendButton': _Fixed(
    const Size(48, 48),
    () => const NeumorphicSendButton(),
  ),
  'NeumorphicKnob': _Fixed(
    const Size(76, 76),
    () => const NeumorphicKnob(value: .4),
  ),
  'NeumorphicSparkline': _Fixed(
    const Size(96, 32),
    () => const NeumorphicSparkline(label: 'Steps', values: [4, 6, 5]),
  ),
  'NeumorphicMiniDial': _Fixed(
    const Size(104, 104),
    () => const NeumorphicMiniDial(value: 40, figure: '40'),
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
  'NeumorphicGableArt': _Fill(
    1200,
    () => const NeumorphicGableArt(),
    aspect: 620 / 176,
  ),
  'NeumorphicChart': _Fill(
    680,
    () => const NeumorphicChart(
      label: 'Sleep',
      series: [
        NeumorphicChartSeries('Hours', [7, null, 8]),
      ],
    ),
    aspect: null,
  ),
  // A picture crops to the box it is given, so a stretched cell can't distort it.
  'NeumorphicTwoWayBars': _Fill(
    760,
    () => const NeumorphicTwoWayBars(above: [.6, 1.1, 1.6]),
    aspect: null,
  ),
  // The charts' one measure (680), as the line chart and the step line: at 520 the bars stood short of the chart beside.
  'NeumorphicColumnBars': _Fill(
    680,
    () =>
        const NeumorphicColumnBars(values: [3, 2, 4], labels: ['A', 'B', 'C']),
    aspect: null,
  ),
  'NeumorphicStepLine': _Fill(
    680,
    () => const NeumorphicStepLine(
      readings: [(0, 1), (1, 2)],
      steps: [(0, 1), (1, 1)],
      xMax: 1,
      yMin: 0,
      yMax: 3,
    ),
    aspect: null,
  ),
  'NeumorphicPictureCard': _Fill(
    480,
    () => const NeumorphicPictureCard(slotId: 'nothing-here', title: 'A piece'),
    aspect: null,
  ),
  'NeumorphicPieChart': _Fill(
    680,
    () => const NeumorphicPieChart(
      label: 'Time',
      slices: [NeumorphicPieSlice('Work', 6), NeumorphicPieSlice('Rest', 2)],
    ),
    aspect: null,
  ),
  'NeumorphicMedia': _Fill(
    720,
    () => const NeumorphicMedia(slotId: 'nothing-here'),
    aspect: null,
  ),
};

/// Parts that paint to the size they are given, so a stretching parent only makes them wider, or that hold their fixed
/// pieces inside a row of their own. `support.dart`'s `check` holds these at both widths in the other tests.
const _flows = <String, String>{
  'NeumorphicAvatarGroup': 'its overlapping circles grow for scaled initials and fit a narrow slot together',
  'NeumorphicLinearProgressIndicator':
      'a groove painted to its available width',
  'NeumorphicRating':
      'its stars keep their size at the start of a row of their own',
  'NeumorphicSkeleton':
      'content placeholders follow available width with a bounded aspect',
  'NeumorphicBadge':
      'the count grows with text while its optional child keeps its own size',
  'NeumorphicNavigationDrawer':
      'its rail paints to the available height and its content scrolls',
  'NeumorphicDatePicker': 'calendar cells share the width and preserve 48px targets by scrolling in narrow slots',
  'NeumorphicInputOtp': 'code cells wrap as scaled digits need room',
  'NeumorphicChip': 'as wide as its words, its cross a 48 band at its end',
  'NeumorphicBottomSheet':
      'the grip is fixed, while the panel follows its viewport',
  'NeumorphicSurface': 'the one surface painter, painted to its size',
  'NeumorphicCellBank': 'a bank of equal cells the width of its column, as tall as a field, wrapping or scrolling when they need room',
  'NeumorphicCellFace': 'the chosen cell pressed in, painted to its cell',
  'NeumorphicEngraved': 'a rule the width of its column',
  'NeumorphicRuled': 'a rule the width of its column',
  'NeumorphicChoiceBox': 'paints to its size',
  'NeumorphicDayFace': 'its bump and well fill the day it is given',
  'NeumorphicSlider': 'a groove the width of its column',
  'NeumorphicProgress': 'a groove the width of its column',
  'NeumorphicStepRow': 'its dot stands in a row of its own',
  'NeumorphicNavigationBar': 'the full width of the page',
  'NeumorphicScaffold': 'the page',
  // The dials take the least of their size and their column, so they stay round on any phone: `signatures_test.dart` holds that.
  'NeumorphicDial': 'a round dial centred in its column, keys in the corners',
  'NeumorphicSpanDial':
      'a round dial centred in its column, ends in the corners',
  'NeumorphicRelief':
      'a casting the width of its column, its gable in proportion',
  'NeumorphicDayTray': 'a tray the width of its column, an hour at 90',
  'NeumorphicMonth': 'seven shares of its column',
  'NeumorphicPushGroup': 'its buttons stand in shares of its column',
  'NeumorphicShareBars': 'bars the width of their column',
  'NeumorphicLegend': 'a wrap of swatches and words',
  // Round 4: each paints its relief, rail or focus lift to the box its contents make.
  'NeumorphicTimeline': 'its rail paints the height of each stop, words beside',
  'NeumorphicMeter': 'a groove the width of its column',
  'NeumorphicSplitButton': 'two halves of one face, each painted to its half',
  'NeumorphicPanelRow': 'a row the width of its panel, pressed in when lit',
  'NeumorphicMenuBar':
      'a strip the width of its column, a pressed title painted to its cell',
  'NeumorphicToaster': 'a stack the size of the page it lays toasts over',
  'NeumorphicMultiSelect':
      'a field body the width of its column, chips wrapping inside',
  'NeumorphicRangeSlider': 'a groove the width of its column',
  'NeumorphicCarouselView':
      'a strip of slides the width of its column, its lift painted to it',
  'NeumorphicTapFace': 'its hover and focus painters follow the supplied face',
  'NeumorphicNavigationRail': 'its rail paints to the available height',
  'NeumorphicDataTable': 'rows the width of their table, pressed in when lit',
  'NeumorphicScrollArea': 'the area it is given, its lift painted to it',
  'NeumorphicResizable': 'panes sharing its box, a fixed handle between them',
  'NeumorphicSwipeActions': 'a row the width of its column, its actions behind',
  'NeumorphicColorPicker': 'its strips are grooves the width of its column, their colours laid in them',
  'NeumorphicTreeView': 'rows the width of their column, pressed in when lit',
  'NeumorphicEntrySeat': 'a band the width of its field and the control height, its line centred in it',
  'NeumorphicSearchField': 'a field the width of its column; its clear key keeps a 48 target over a slot the field\'s height',
  'NeumorphicBanner': 'a soft well the width of its column, its mark a fixed glyph beside its words',
  'NeumorphicChosenBand':
      'a chosen row\'s pressed band, painted to the row it stands behind',
};

// A part drawn through its own RenderObject shows none of these, so it adds its private widget's name.
final _drawn = RegExp(
  r'CustomPaint\(|neumorphicPaint\(|neumorphicOwnSize\(|NeumorphicFill\(|Stack\(|AspectRatio\(|'
  r'(?:SizedBox|Container)\(\s*(?:key:[^,]*,\s*)?width: (?!double\.infinity)[^,\n]+,\s*height: ',
);

/// The package moves static demo art into its example; both outputs keep it in
/// the same size and raw-paint laws.
Iterable<File> _sourceFiles() sync* {
  for (final root in ['lib/src/neumorphism', 'example/lib/demo_art']) {
    final directory = Directory(root);
    if (!directory.existsSync()) continue;
    yield* directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
  }
}

/// The public widgets whose source draws or holds a size.
Set<String> _drawnParts() {
  final found = <String>{};
  for (final file in _sourceFiles()) {
    final source = file.readAsStringSync();
    final classes = RegExp(
      r'^class (\w+)[^\n{]*\{',
      multiLine: true,
    ).allMatches(source).toList();
    for (var i = 0; i < classes.length; i++) {
      final name = classes[i][1]!;
      if (name.startsWith('_')) continue;
      final end = i + 1 < classes.length ? classes[i + 1].start : source.length;
      var body = source.substring(classes[i].start, end);
      for (var j = 0; j < classes.length; j++) {
        if (!classes[j][0]!.contains('extends State<$name>')) continue;
        final stateEnd = j + 1 < classes.length
            ? classes[j + 1].start
            : source.length;
        body += source.substring(classes[j].start, stateEnd);
      }
      final widget =
          body.contains('Widget build(') || body.contains('createState');
      if (widget && _drawn.hasMatch(body)) found.add(name);
    }
  }
  return found;
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
  final theme = NeumorphicThemeData.preset(
    NeumorphicThemeData.presets.first,
    dark ? Brightness.dark : Brightness.light,
  );
  const stretch = CrossAxisAlignment.stretch;
  return MediaQuery(
    data: MediaQueryData(size: Size(width, height)),
    child: Directionality(
      textDirection: direction,
      child: NeumorphicTheme(
        data: theme,
        // Soft shadows paint past a box on purpose: the law reads a part flat.
        child: RepaintBoundary(
          key: _stageKey,
          child: NeumorphicFlatScope(
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
    await loadNeumorphicFonts();
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
      named.difference(found),
      isEmpty,
      reason: 'gone from the library: take it out of its table',
    );
    final twice = _fixed.keys.toSet().intersection(_fills.keys.toSet());
    expect(twice, isEmpty);
  });

  test('a box of fixed size around a paint or a Stack goes through neumorphicOwnSize', () {
    final raw = RegExp(
      r'SizedBox\(\s*width: [^,\n]+,\s*height: [^,\n]+,\s*child: (?:CustomPaint|Stack)|CustomPaint\(\s*size: ',
    );
    final found = <String>[];
    for (final file in _sourceFiles()) {
      for (final m in raw.allMatches(file.readAsStringSync())) {
        found.add('${file.path}: ${m[0]!.replaceAll(RegExp(r'\s+'), ' ')}');
      }
    }
    expect(found, isEmpty);
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
                final room = width - part.size.width;
                // A part whose target is wider than its face stands its face on the start and pads its target outward
                // (design6 P, 11-12: an example starts on the edge with its drawn face, never its target).
                final edge = find.descendant(
                  of: finder,
                  matching: find.byType(NeumorphicFaceEdge),
                );
                final slop = edge.evaluate().isEmpty
                    ? 0.0
                    : tester.widget<NeumorphicFaceEdge>(edge.first).slop;
                final x = direction == TextDirection.ltr ? -slop : room + slop;
                final place = Offset(x, 0) & part.size;
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
              tags: ['goldens'],
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
          }, tags: ['goldens']);
        }
      }
    }
  });
}
