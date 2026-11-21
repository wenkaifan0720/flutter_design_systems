// A face set in another follows its corners: on every part's page and every
// everyday screen, at a phone's width and a desktop's, nothing painted inside
// a Studio face (a face, a fill, a clipped child) reaches past the face's
// inner contour at its corners, the outer radius less the inset. A square
// plate in a round well cuts the well's wall at its corners; this finds it.
//
// With CORNERS_OUT set to a directory, each part's page at 390 is also written
// there at twice the size (<page>_<brightness>.png) with its wells
// (<page>_<brightness>.json: each sunk face's rectangle and radius), for a
// sheet of their corners at native size.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show kLongPressTimeout;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

import '../example/lib/everyday_screens.dart';
import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/roomtone/roomtone.dart';

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

// A clip, in global coordinates.
class _Clip {
  _Clip(this.path) : bounds = path.getBounds();

  final Path path;
  final Rect bounds;

  bool contains(Offset p) => path.contains(p);
}

// A shape painted on screen, in global coordinates, and the clips round it.
class _Shape {
  _Shape(this.name, this.box, this.clips, {this.face});

  final String name;
  final RRect box;
  final List<_Clip> clips;
  final StudioFace? face;

  bool paints(Offset p) => box.contains(p) && clips.every((c) => c.contains(p));

  Rect get visible =>
      clips.fold(box.outerRect, (r, c) => r.intersect(c.bounds));
}

RRect _global(RenderBox box, BorderRadius radius) {
  final rect = MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
  return radius.toRRect(rect);
}

// Every face, fill and clip under [root], in paint order.
List<_Shape> _shapes(Element root) {
  final out = <_Shape>[];
  void walk(Element e, List<_Clip> clips) {
    final w = e.widget;
    // What is not painted: a route under an opaque one (its ticker off),
    // an offstage child.
    if ((w is TickerMode && !w.enabled) ||
        (w is Offstage && w.offstage) ||
        (w is Visibility && !w.visible) ||
        (w is Opacity && w.opacity == 0)) {
      return;
    }
    final ro = e.renderObject;
    var inner = clips;
    if (ro is RenderBox &&
        ro.hasSize &&
        ro.attached &&
        e is RenderObjectElement) {
      String? name;
      var radius = BorderRadius.zero;
      StudioFace? face;
      Path? clip;
      if (ro is RenderCustomPaint && ro.painter is StudioFacePainter) {
        face = (ro.painter! as StudioFacePainter).face;
        if (face.presence > 0.01 &&
            (face.fill.a > 0.01 || face.depth == StudioDepth.sunk)) {
          name = 'face(${face.depth.name}, r${face.radius})';
          radius = BorderRadius.circular(face.radius);
        }
      } else if (w is ColoredBox && w.color.a > 0.01) {
        name = 'ColoredBox';
      } else if (w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          ((w.decoration as BoxDecoration).color?.a ?? 0) +
                  ((w.decoration as BoxDecoration).gradient == null ? 0 : 1) +
                  ((w.decoration as BoxDecoration).image == null ? 0 : 1) >
              0.01) {
        name = 'DecoratedBox';
        final d = w.decoration as BoxDecoration;
        radius =
            d.borderRadius?.resolve(Directionality.maybeOf(e)) ??
            (d.shape == BoxShape.circle
                ? BorderRadius.circular(ro.size.shortestSide / 2)
                : BorderRadius.zero);
      } else if (ro is RenderClipRect && ro.clipBehavior != Clip.none) {
        // A clipper may clip outside the box (a focus ring's room).
        clip = Path()
          ..addRect(ro.clipper?.getClip(ro.size) ?? Offset.zero & ro.size);
      } else if (ro is RenderClipRRect && ro.clipBehavior != Clip.none) {
        clip = Path()
          ..addRRect(
            ro.clipper?.getClip(ro.size) ??
                ro.borderRadius
                    .resolve(Directionality.maybeOf(e))
                    .toRRect(Offset.zero & ro.size),
          );
      } else if (ro is RenderClipOval && ro.clipBehavior != Clip.none) {
        clip = Path()
          ..addOval(ro.clipper?.getClip(ro.size) ?? Offset.zero & ro.size);
      } else if (ro is RenderClipPath && ro.clipBehavior != Clip.none) {
        clip =
            ro.clipper?.getClip(ro.size) ??
            (Path()..addRect(Offset.zero & ro.size));
      }
      if (ro.size.width > 0 && ro.size.height > 0) {
        final g = _global(ro, radius);
        if (name != null) {
          out.add(
            _Shape(
              '$name ${e.widget.runtimeType} in ${_owner(e)}',
              g,
              clips,
              face: face,
            ),
          );
        }
        if (clip != null) {
          inner = [
            ...clips,
            _Clip(clip.transform(ro.getTransformTo(null).storage)),
          ];
        }
      }
    }
    e.visitChildren((c) => walk(c, inner));
  }

  walk(root, const []);
  return out;
}

// The nearest Studio widget that built [e], for the report.
String _owner(Element e) {
  String? found;
  e.visitAncestorElements((a) {
    final t = a.widget.runtimeType.toString();
    if (t.startsWith('Studio') &&
        t != 'StudioSurface' &&
        t != 'StudioTheme' &&
        t != 'StudioHost') {
      found = t;
      return false;
    }
    return true;
  });
  return found ?? '?';
}

// How far [s] reaches past [well]'s inner contour at its corners, in logical
// pixels (0 when it follows it), and whether a corner of it set in square
// (both insets alike) leaves more than a pixel of the well's floor at the
// corner (rounder than the well's: loose, not concentric).
({double over, bool loose}) _corners(_Shape well, _Shape s) {
  final w = well.box;
  final v = s.visible;
  const none = (over: 0.0, loose: false);
  if (v.isEmpty) return none;
  if (!w.outerRect.inflate(0.5).contains(v.topLeft) ||
      !w.outerRect.inflate(0.5).contains(v.bottomRight)) {
    return none;
  }
  var worst = 0.0;
  var loose = false;
  // tl, tr, br, bl: (corner, radius, sign x, sign y).
  final corners = [
    (w.outerRect.topLeft, w.tlRadiusX, 1.0, 1.0),
    (w.outerRect.topRight, w.trRadiusX, -1.0, 1.0),
    (w.outerRect.bottomRight, w.brRadiusX, -1.0, -1.0),
    (w.outerRect.bottomLeft, w.blRadiusX, 1.0, -1.0),
  ];
  for (final (corner, r, sx, sy) in corners) {
    if (r < 1) continue;
    final dx = sx > 0 ? v.left - corner.dx : corner.dx - v.right;
    final dy = sy > 0 ? v.top - corner.dy : corner.dy - v.bottom;
    final d = math.max(0.0, math.min(dx, dy));
    if (d >= r - 0.5) continue;
    final centre = corner.translate(sx * r, sy * r);
    final allowed = r - d;
    const step = 0.25;
    for (var i = 0.0; i < r; i += step) {
      for (var j = 0.0; j < r; j += step) {
        final p = corner.translate(sx * (i + step / 2), sy * (j + step / 2));
        if (!s.paints(p)) continue;
        final over = (p - centre).distance - allowed;
        if (over > worst) worst = over;
      }
    }
    // Set in square: the inner contour's mid-arc, a pixel in, is painted.
    if ((dx - dy).abs() < 0.5 && allowed > 1.5) {
      final mid = centre.translate(
        -sx * (allowed - 1) / math.sqrt2,
        -sy * (allowed - 1) / math.sqrt2,
      );
      if (!s.paints(mid)) loose = true;
    }
  }
  return (over: worst, loose: loose);
}

String _rect(Rect r) =>
    '(${r.left.toStringAsFixed(1)},${r.top.toStringAsFixed(1)} ${r.width.toStringAsFixed(1)}x${r.height.toStringAsFixed(1)})';

// What cuts into a well (faults), and what sits loose in one (to look at).
({List<String> faults, List<String> loose}) _audit(WidgetTester tester) {
  final shapes = _shapes(tester.binding.rootElement!);
  final faults = <String>{};
  final loose = <String>{};
  for (final (i, well) in shapes.indexed) {
    if (well.face == null) continue;
    for (final s in shapes.skip(i + 1)) {
      final c = _corners(well, s);
      final where = '${well.name} ${_rect(well.box.outerRect)}';
      if (c.over > 0.75) {
        faults.add(
          '${s.name} ${_rect(s.visible)} cuts ${c.over.toStringAsFixed(1)} px into $where',
        );
      } else if (c.loose) {
        loose.add('${s.name} ${_rect(s.visible)} sits loose in $where');
      }
    }
  }
  return (faults: faults.toList(), loose: loose.toList());
}

void _expectFollows(WidgetTester tester, String what) {
  final a = _audit(tester);
  for (final l in a.loose) {
    debugPrint('LOOSE $what: $l');
  }
  for (final l in a.faults) {
    debugPrint('FAULT $what: $l');
  }
  expect(a.faults, isEmpty, reason: a.faults.join('\n'));
}

final String? _out = Platform.environment['CORNERS_OUT'];

// The page at twice the size and its wells, into [_out].
Future<void> _record(WidgetTester tester, String name) async {
  final out = _out;
  if (out == null) return;
  final wells = [
    for (final s in _shapes(tester.binding.rootElement!))
      if (s.face?.depth == StudioDepth.sunk)
        {
          'owner': s.name,
          'l': s.box.left,
          't': s.box.top,
          'w': s.box.width,
          'h': s.box.height,
          'r': s.box.tlRadiusX,
        },
  ];
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final size = view.size;
  await tester.runAsync(() async {
    final image = await layer.toImage(Offset.zero & size, pixelRatio: 2);
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(out).createSync(recursive: true);
      File('$out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      File('$out/$name.json').writeAsStringSync(jsonEncode(wells));
    } finally {
      image.dispose();
    }
  });
}

Widget _part(int i, [Brightness brightness = Brightness.light]) => RoomtoneApp(
  initialPlace: RoomtonePlace.overview,
  initialAppearance: brightness == Brightness.dark
      ? RoomtoneAppearance.dark
      : RoomtoneAppearance.light,
  initialDirection: TextDirection.ltr,
  parts: [
    for (final page in galleryPages) (title: page.title, build: page.build),
  ],
  initialPart: i,
);

Widget _room(Brightness brightness, Widget child) => MaterialApp(
  localizationsDelegates: const [
    StudioLocalizations.delegate,
    RawWidgetsLocalizations.delegate,
  ],
  builder: (context, page) => StudioTheme(
    data: brightness == Brightness.dark
        ? StudioThemeData.dark()
        : StudioThemeData.light(),
    child: StudioHost(child: page!),
  ),
  home: Center(child: SizedBox(width: 360, child: child)),
);

void main() {
  setUpAll(_loadFonts);

  testWidgets('a square plate in a round well is found', (tester) async {
    await tester.pumpWidget(
      _room(
        Brightness.light,
        const StudioDisplay(
          padding: EdgeInsets.all(StudioMetrics.recessInset),
          child: SizedBox(
            height: 60,
            child: ColoredBox(color: Color(0xFFFFFFFF)),
          ),
        ),
      ),
    );
    expect(_audit(tester).faults, hasLength(1));
  });

  for (final (brightness, direction) in [
    (Brightness.light, TextDirection.ltr),
    (Brightness.dark, TextDirection.ltr),
    (Brightness.light, TextDirection.rtl),
  ]) {
    testWidgets('a swipe row follows its well at rest and mid-swipe by '
        '${brightness.name}, ${direction.name}', (tester) async {
      await tester.pumpWidget(
        _room(
          brightness,
          Directionality(
            textDirection: direction,
            child: StudioDisplay(
              padding: const EdgeInsets.all(StudioMetrics.recessInset),
              child: StudioSwipeRow(
                startActions: [
                  StudioSwipeAction(label: 'Played', onPressed: () {}),
                ],
                endActions: [
                  StudioSwipeAction(
                    label: 'Delete',
                    destructive: true,
                    onPressed: () {},
                  ),
                ],
                child: const SizedBox(height: 64, child: Text('Episode 11')),
              ),
            ),
          ),
        ),
      );
      _expectFollows(tester, 'swipe row at rest');
      final row = tester.getRect(find.byType(StudioSwipeRow));
      for (final dx in const [-40.0, 40.0]) {
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Episode 11')),
        );
        await gesture.moveBy(Offset(dx / 2, 0));
        await gesture.moveBy(Offset(dx / 2, 0));
        await tester.pump();
        _expectFollows(tester, 'swipe row moved $dx');
        // The uncovered key stands whole in the metal, a gap from the row's
        // outer edge: the row's clip never cuts it.
        final legend = find.text('Delete').evaluate().isNotEmpty
            ? find.text('Delete')
            : find.text('Played');
        final key = tester.getRect(
          find
              .ancestor(
                of: legend,
                matching: find.byType(AnimatedStudioSurface),
              )
              .first,
        );
        final inside = row.deflate(StudioSpacing.tight - 0.5);
        expect(
          inside.contains(key.topLeft) && inside.contains(key.bottomRight),
          isTrue,
          reason: 'key $key not whole inside the row $row at $dx',
        );
        await gesture.up();
        await tester.pumpAndSettle();
      }
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('a lifted row follows its well at the top of the list by '
        '${brightness.name}', (tester) async {
      await tester.pumpWidget(
        _room(
          brightness,
          StudioReorderableList<String>(
            items: const ['First', 'Second', 'Third'],
            labelOf: (s) => s,
            onReorder: (_, _) {},
            itemBuilder: (context, s) => Text(s),
          ),
        ),
      );
      final row = tester.getCenter(find.text('Second'));
      final list = tester.getRect(find.byType(StudioReorderableList<String>));
      // The grip: the row's first 44 px, inside the glass's 4 px lip.
      final gesture = await tester.startGesture(
        Offset(list.left + StudioMetrics.recessInset + 22, row.dy),
      );
      await tester.pump(kLongPressTimeout);
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(0, -12));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(milliseconds: 500));
      // Lifted: the row rides in the overlay with the finger (its place in
      // the list is a gap while it is away).
      expect(tester.getCenter(find.text('Second')).dy, lessThan(row.dy - 48));
      _expectFollows(tester, 'lifted row');
      await gesture.up();
      await tester.pumpAndSettle();
    });
  }

  for (final (width, brightness) in const [
    (390.0, Brightness.light),
    (390.0, Brightness.dark),
    (1440.0, Brightness.light),
  ]) {
    for (final (i, page) in galleryPages.indexed) {
      testWidgets('${page.id} at ${width.toInt()} by ${brightness.name}: '
          'faces follow their wells', (tester) async {
        tester.view.physicalSize = Size(width, 16000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_part(i, brightness));
        // A spinner never settles: let the page arrive, then read it.
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
        _expectFollows(tester, '${page.id}@${width.toInt()}');
        if (width < 600) await _record(tester, '${page.id}_${brightness.name}');
      });
    }
    if (brightness == Brightness.dark) continue;
    for (final screen in everydayScreens) {
      testWidgets(
        '${screen.id} at ${width.toInt()}: faces follow their wells',
        (tester) async {
          tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            screen.app(Brightness.light, TextDirection.ltr),
          );
          // A spinner never settles: let the page arrive, then read it.
          await tester.pump();
          await tester.pump(const Duration(seconds: 3));
          _expectFollows(tester, '${screen.id}@${width.toInt()}');
        },
      );
    }
  }
}
