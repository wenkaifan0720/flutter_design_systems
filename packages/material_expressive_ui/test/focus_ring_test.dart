// Every focus ring is concentric with the part it marks (polish3 §2): on
// every example page and with every overlay open, each part is focused from
// the keyboard and its ring is read back from the path it paints, then held
// to the painted outline of its part: the ring's box is the part's grown by
// the ring's gap and half its stroke, each corner the part's grown by the
// same, and a square corner stays square. A row stacked flush draws it
// inward: its box the part's less half the stroke, each corner the same less.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'gallery_support.dart';
import 'overlay_fixtures.dart';
import 'shape_support.dart';

bool _isRing(Widget w) =>
    w is CustomPaint &&
    w.foregroundPainter.runtimeType.toString() == '_FocusRingPainter';

/// The node a pressable focuses: its ink's Focus, read without depending
/// on it.
FocusNode? _nodeOf(Element pressable) {
  FocusNode? node;
  void visit(Element e) {
    if (node != null) return;
    if (e.widget is Focus) {
      Element? child;
      e.visitChildren((c) => child ??= c);
      if (child != null) node = Focus.maybeOf(child!, createDependency: false);
      return;
    }
    e.visitChildren(visit);
  }

  pressable.visitChildren(visit);
  return node;
}

/// Focuses every kind of part in view, one at a time, and measures each
/// ring against its part; returns what failed.
Future<List<String>> _checkRings(WidgetTester tester, String where) async {
  final failures = <String>[];
  final kinds = <String>{};
  final view = tester.view.physicalSize / tester.view.devicePixelRatio;
  final pressables = find
      .byType(ExpressivePressable)
      .evaluate()
      .toList(growable: false);
  for (final element in pressables) {
    if (!element.mounted) continue;
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize || !box.attached) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (!(Offset.zero & view).contains(rect.center)) continue;
    final owner = ownerOf(element);
    final kind =
        '$owner ${(rect.width / 8).round()}x${(rect.height / 8).round()}';
    if (!kinds.add(kind)) continue;
    final node = _nodeOf(element);
    if (node == null || !node.canRequestFocus || node.skipTraversal) continue;
    node.requestFocus();
    // Focus may land after the first frame (the first part on a page, its
    // scope focused before): a second frame builds the ring, whose fade
    // springs from there.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final rings = find
        .descendant(
          of: find.byElementPredicate((e) => identical(e, element)),
          matching: find.byWidgetPredicate(_isRing),
        )
        .evaluate();
    if (rings.isEmpty) {
      failures.add('$where: $kind shows no ring');
    } else {
      failures.addAll(_measure(tester, rings.first, '$where: $kind'));
    }
    node.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
  }
  return failures;
}

List<String> _measure(WidgetTester tester, Element ring, String where) {
  final box = ring.renderObject! as RenderBox;
  final dynamic painter = (ring.widget as CustomPaint).foregroundPainter;
  final thickness = painter.thickness as double;
  // Outside the part by the gap and half the stroke; or, for a row stacked
  // flush (inward), inside it by half the stroke.
  final inward = painter.inward as bool;
  final out = inward
      ? -thickness / 2
      : ExpressiveFocusRing.offset + thickness / 2;
  final local =
      (painter.rect as Rect Function(Size)?)?.call(box.size) ??
      Offset.zero & box.size;
  final shape = painter.shape as ShapeBorder?;
  final origin = box.localToGlobal(Offset.zero);
  final base = local.shift(origin);

  // The ring as drawn.
  final canvas = TestRecordingCanvas();
  (painter as CustomPainter).paint(canvas, box.size);
  Rect? drawnRect;
  List<double>? drawnRadii;
  for (final call in canvas.invocations) {
    final name = call.invocation.memberName;
    final args = call.invocation.positionalArguments;
    if (name == #drawRRect) {
      final r = args.first as RRect;
      drawnRect = r.outerRect;
      drawnRadii = [r.tlRadiusX, r.trRadiusX, r.brRadiusX, r.blRadiusX];
    } else if (name == #drawPath) {
      final path = args.first as Path;
      drawnRect = path.getBounds();
      drawnRadii = measurePathCorners(path, drawnRect);
    }
  }
  if (drawnRect == null || drawnRadii == null) {
    return ['$where: the ring paints no outline'];
  }

  // The part as painted: the surface laid on the ring's base box, or else
  // the shape the ring goes round (a part with no fill of its own).
  final surface = paintedShapes(tester).where(
    (s) =>
        (s.rect.topLeft - base.topLeft).distance < .75 &&
        (s.rect.size - base.size as Offset).distance < .75,
  );
  final partRadii = surface.isNotEmpty
      ? measureCorners(surface.first.shape, Offset.zero & base.size)
      : measureCorners(shape!, Offset.zero & base.size);

  final failures = <String>[];
  final grown = local.inflate(out);
  if ((drawnRect.topLeft - grown.topLeft).distance > .5 ||
      (drawnRect.size - grown.size as Offset).distance > .5) {
    failures.add(
      '$where: ring box $drawnRect is not the part ${base.size} grown by '
      '$out',
    );
  }
  final half = math.min(drawnRect.width, drawnRect.height) / 2;
  for (var i = 0; i < 4; i++) {
    final part = partRadii[i];
    final ring = drawnRadii[i];
    final expected = part < .5
        ? 0.0
        : math.min(math.max(0.0, part + out), half);
    if ((ring - expected).abs() > 1) {
      failures.add(
        '$where: corner $i is ${ring.toStringAsFixed(1)}, the part '
        '${part.toStringAsFixed(1)} grown by $out is '
        '${expected.toStringAsFixed(1)}',
      );
    }
  }
  return failures;
}

void main() {
  setUpAll(loadExpressiveFonts);
  tearDown(() {
    kitShownTheme = null;
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  testWidgets('every focus ring is concentric with its part', (tester) async {
    final failures = <String>[];
    for (final page in galleryExamplePages) {
      await pumpGalleryPage(tester, page, 'baseline', Brightness.light);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      failures.addAll(await _checkRings(tester, page.id));
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
      expect(tester.takeException(), isNull, reason: page.id);
    }
    await forEachOverlay(
      tester,
      ExpressiveThemeData.preset('baseline', Brightness.light),
      (name) async {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        failures.addAll(await _checkRings(tester, 'overlay $name'));
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
      },
    );
    expect(failures.toSet().toList(), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 30)));
}
