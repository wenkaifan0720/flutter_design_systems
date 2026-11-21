// Three faults a person saw on Studio's pages, each held here:
// - the side sheet's title and close key stand on the sheet's keylines,
//   where its body's content starts and ends;
// - a StudioAppBar's bottom (its tabs) stands in the bar's content column:
//   the first legend starts where the title does, the strip's groove ends
//   where the actions' keys do;
// - by night an unlit lamp and an unlit star still read as lamps: the edge
//   of their glass stands at 3:1 on the metal round them (WCAG's non-text
//   contrast), and a lit one is clearly brighter than an unlit one.
// Each at a phone's width and a desktop's, left to right and right to left,
// in the faces Studio ships.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : studioRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Widget _app(
  Widget home, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => Directionality(
    textDirection: direction,
    child: StudioHost(brightness: brightness, child: app!),
  ),
  home: home,
);

void _size(WidgetTester tester, Size size, {double ratio = 1}) {
  tester.view.physicalSize = size * ratio;
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.reset);
}

// Where [text]'s words are drawn, by their lines' boxes, on screen.
Rect _words(WidgetTester tester, Finder text) {
  final p = tester.renderObject<RenderParagraph>(text);
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: p.text.toPlainText().length),
  );
  var r = boxes.first.toRect();
  for (final b in boxes.skip(1)) {
    r = r.expandToInclude(b.toRect());
  }
  return MatrixUtils.transformRect(p.getTransformTo(null), r);
}

// A key's face (not its tap target round it), on screen.
Rect _face(WidgetTester tester, Finder key) => tester.getRect(
  find.descendant(of: key, matching: find.byType(AnimatedStudioSurface)).first,
);

// The edge [rect] starts on in [direction], and the one it ends on.
double _start(Rect r, TextDirection d) =>
    d == TextDirection.ltr ? r.left : r.right;
double _end(Rect r, TextDirection d) =>
    d == TextDirection.ltr ? r.right : r.left;

const _closeEnough = 0.5;

void main() {
  setUpAll(_loadFonts);
  for (final width in const [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      final at = '${width.toInt()} ${direction.name}';

      testWidgets(
        "at $at the side sheet's title and close key stand on its keylines",
        (tester) async {
          _size(tester, Size(width, width < 600 ? 844 : 900));
          await tester.pumpWidget(
            _app(
              direction: direction,
              Builder(
                builder: (context) => Center(
                  child: StudioButton(
                    'Open',
                    onPressed: () => showStudioSideSheet<void>(
                      context: context,
                      title: 'Sort and filter',
                      builder: (context) => const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [Text('Unplayed only'), Text('Newest first')],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          // The body's keylines: its content column, where the region
          // the keyline check reads stands.
          final body = tester.getRect(find.byType(DesignKeylineRegion));
          final title = _words(tester, find.text('Sort and filter'));
          final close = _face(tester, find.byType(StudioIconButton));
          expect(
            _start(title, direction),
            moreOrLessEquals(_start(body, direction), epsilon: _closeEnough),
            reason: 'the title starts on the leading keyline',
          );
          expect(
            _end(close, direction),
            moreOrLessEquals(_end(body, direction), epsilon: _closeEnough),
            reason: "the close key's face ends on the trailing keyline",
          );
          // Its words and its key share the header's centre line.
          expect(
            close.center.dy,
            moreOrLessEquals(title.center.dy, epsilon: 2),
          );
        },
      );

      testWidgets("at $at the app bar's tabs stand in its content column", (
        tester,
      ) async {
        _size(tester, Size(width, width < 600 ? 844 : 900));
        await tester.pumpWidget(
          _app(
            direction: direction,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudioAppBar(
                  title: 'Bench',
                  actions: [
                    StudioIconButton(
                      icon: const Icon(IconData(0x53)),
                      tooltip: 'Search',
                      onPressed: () {},
                    ),
                  ],
                  bottom: StudioTabBar(
                    tabs: const ['Notes', 'Chapters', 'Transcript'],
                    selectedIndex: 0,
                    onChanged: (_) {},
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final margin = StudioSpacing.pageMargin(width);
        final bar = tester.getRect(find.byType(StudioAppBar));
        final title = _words(tester, find.text('Bench'));
        final action = _face(tester, find.byType(StudioIconButton));
        // The bar's keylines: its title and its actions, at the page margin.
        expect(
          (_start(title, direction) - _start(bar, direction)).abs(),
          moreOrLessEquals(margin, epsilon: _closeEnough),
        );
        expect(
          (_end(bar, direction) - _end(action, direction)).abs(),
          moreOrLessEquals(margin, epsilon: _closeEnough),
        );
        final first = _words(tester, find.text('Notes'));
        expect(
          _start(first, direction),
          moreOrLessEquals(_start(title, direction), epsilon: _closeEnough),
          reason: 'the first legend starts where the title does',
        );
        // The strip the tabs scroll in spans the column, title to actions.
        final strip = tester.getRect(
          find
              .descendant(
                of: find.byType(StudioTabBar),
                matching: find.byType(SingleChildScrollView),
              )
              .first,
        );
        expect(
          _start(strip, direction),
          moreOrLessEquals(_start(title, direction), epsilon: _closeEnough),
        );
        expect(
          _end(strip, direction),
          moreOrLessEquals(_end(action, direction), epsilon: _closeEnough),
        );
        final groove = tester.getRect(
          find.descendant(
            of: find.byType(StudioTabBar),
            matching: find.byType(StudioGroove),
          ),
        );
        expect(
          _start(groove, direction),
          moreOrLessEquals(_start(title, direction), epsilon: _closeEnough),
          reason: "the groove starts on the bar's leading keyline",
        );
        expect(
          _end(groove, direction),
          moreOrLessEquals(_end(action, direction), epsilon: _closeEnough),
          reason: "the groove ends on the bar's trailing keyline",
        );
      });
    }
  }

  group('by night', () {
    // The metals and glass a lamp is set in.
    final housings = <String, StudioFace Function(StudioColors)>{
      'a key': (c) => c.keyFace,
      'a panel': (c) => c.panelFace,
      'the bar': (c) => StudioFace(
        fill: c.bar,
        fillLow: c.barLow,
        depth: StudioDepth.level,
        radius: 0,
        brushed: true,
      ),
      'a display': (c) => c.displayFace,
    };
    final stage = GlobalKey();

    Future<_Shot> shoot(WidgetTester tester) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(stage),
      );
      final ratio = tester.view.devicePixelRatio;
      final data = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: ratio);
        try {
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          return (image.width, bytes!);
        } finally {
          image.dispose();
        }
      });
      return _Shot(
        data!.$2,
        data.$1,
        boundary.localToGlobal(Offset.zero),
        ratio,
      );
    }

    for (final MapEntry(key: name, value: housing) in housings.entries) {
      testWidgets(
        'an unlit lamp in ${name.split(' ').last} stands 3:1, a lit one brighter',
        (tester) async {
          _size(tester, const Size(240, 120), ratio: 3);
          final unlit = GlobalKey();
          final lit = GlobalKey();
          await tester.pumpWidget(
            _app(
              brightness: Brightness.dark,
              Builder(
                builder: (context) => Align(
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                    key: stage,
                    child: StudioSurface(
                      face: housing(StudioTheme.of(context).colors)
                          .copyWith(radius: 0),
                      child: SizedBox(
                        width: 160,
                        height: 64,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            StudioLamp(key: unlit, on: false),
                            StudioLamp(key: lit, on: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final shot = await shoot(tester);
          final lamp = tester.getRect(find.byKey(unlit));
          // The metal just beside it, at its height.
          final metal = shot.at(lamp.centerLeft.translate(-4, 0));
          final edge = shot.strongest(lamp, metal);
          expect(
            studioContrast(edge, metal),
            greaterThanOrEqualTo(3),
            reason: 'an unlit lamp in $name: its edge on the metal',
          );
          // A lens's light: the mean over its glass.
          final dark = shot.light(Path()..addOval(lamp));
          final bright = shot.light(
            Path()..addOval(tester.getRect(find.byKey(lit))),
          );
          expect(
            (bright + 0.05) / (dark + 0.05),
            greaterThanOrEqualTo(2),
            reason: 'a lit lamp is clearly brighter than an unlit one',
          );
        },
      );
    }

    for (final MapEntry(key: name, value: housing) in {
      'a panel': housings['a panel']!,
      'the bar': housings['the bar']!,
    }.entries) {
      testWidgets(
        'an unlit star on ${name.split(' ').last} stands 3:1, a lit one brighter',
        (tester) async {
          _size(tester, const Size(320, 120), ratio: 3);
          await tester.pumpWidget(
            _app(
              brightness: Brightness.dark,
              Builder(
                builder: (context) => Align(
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                    key: stage,
                    child: StudioSurface(
                      face: housing(StudioTheme.of(context).colors)
                          .copyWith(radius: 0),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: StudioRating(
                          value: 2,
                          onChanged: (_) {},
                          semanticLabel: 'Rating',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final shot = await shoot(tester);
          final lenses = find.descendant(
            of: find.byType(StudioRating),
            matching: find.byType(TapTargetPadding),
          );
          expect(lenses, findsNWidgets(5));
          // A lens's star: the one sized paint in it.
          Rect starIn(int i) => tester.getRect(
            find.descendant(
              of: lenses.at(i),
              matching: find.byWidgetPredicate(
                (w) => w is CustomPaint && w.size != Size.zero,
              ),
            ),
          );
          // The third lens is unlit; its cell's corner is the metal.
          final cell = tester.getRect(lenses.at(2));
          final metal = shot.at(cell.topLeft.translate(1, 1));
          final star = starIn(2);
          final edge = shot.strongest(star.inflate(1), metal);
          expect(
            studioContrast(edge, metal),
            greaterThanOrEqualTo(3),
            reason: 'an unlit star on $name: its edge on the metal',
          );
          final lit = starIn(0);
          final dark = shot.light(_star(star.center, star.width / 2));
          final bright = shot.light(_star(lit.center, lit.width / 2));
          expect(
            (bright + 0.05) / (dark + 0.05),
            greaterThanOrEqualTo(2),
            reason: 'a lit star is clearly brighter than an unlit one',
          );
        },
      );
    }
  });
}

// A picture of the stage, read by logical points on screen.
class _Shot {
  _Shot(this.bytes, this.width, this.origin, this.ratio);

  final ByteData bytes;
  final int width;
  final Offset origin;
  final double ratio;

  Color _px(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(
      255,
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  }

  Color at(Offset p) {
    final d = (p - origin) * ratio;
    return _px(d.dx.floor(), d.dy.floor());
  }

  Iterable<Color> _within(Rect box) sync* {
    final r = Rect.fromPoints(
      (box.topLeft - origin) * ratio,
      (box.bottomRight - origin) * ratio,
    );
    for (var y = r.top.ceil(); y < r.bottom.floor(); y++) {
      for (var x = r.left.ceil(); x < r.right.floor(); x++) {
        yield _px(x, y);
      }
    }
  }

  // Within [box], the pixel that stands out most from [ground].
  Color strongest(Rect box, Color ground) {
    var edge = ground;
    for (final c in _within(box)) {
      if (studioContrast(c, ground) > studioContrast(edge, ground)) edge = c;
    }
    return edge;
  }

  // The light within [shape]: the mean relative luminance of the pixels
  // whose centres it holds.
  double light(Path shape) {
    final r = Rect.fromPoints(
      (shape.getBounds().topLeft - origin) * ratio,
      (shape.getBounds().bottomRight - origin) * ratio,
    );
    var sum = 0.0;
    var n = 0;
    for (var y = r.top.floor(); y < r.bottom.ceil(); y++) {
      for (var x = r.left.floor(); x < r.right.ceil(); x++) {
        if (!shape.contains(origin + Offset(x + 0.5, y + 0.5) / ratio)) {
          continue;
        }
        sum += _px(x, y).computeLuminance();
        n++;
      }
    }
    return sum / n;
  }
}

// A rating's star of [radius] round [centre], as Studio draws its lenses.
Path _star(Offset centre, double radius) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? radius : radius * 0.45;
    final angle = -math.pi / 2 + i * math.pi / 5;
    final p = centre + Offset(math.cos(angle), math.sin(angle)) * r;
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  return path..close();
}
