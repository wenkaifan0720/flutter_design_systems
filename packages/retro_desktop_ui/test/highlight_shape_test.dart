// ignore_for_file: avoid_relative_lib_imports
// Highlights take the part's shape: every pressable part in every specimen,
// in both appearances, focused and hovered, draws exactly one ring and
// one tint, and they follow the part's own face when it has one (the face
// claims them and draws them from its resolved outline); a part with no face
// draws them in the family's control step. The ring sits outside the outline
// at the theme's gap, concentric (inside it for parts joined to neighbours).
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/kit.dart';

import 'shape_fit_test.dart' show shapeSpecimens;
import 'support.dart';

/// Specimens whose rows are a menu's: focus is the lit row, not a ring.
const _litRows = {'kitSpecimenMenu'};

/// The look's two appearances; each brings its own corners and edges.
const appearances = <String, RetroDesktopAppearance>{
  'chisel': RetroDesktopAppearance.chisel,
  'platinum': RetroDesktopAppearance.platinum,
};

/// Each appearance's shapes, by the appearance's name.
final families = <String, RetroDesktopShapes>{
  for (final f in appearances.entries) f.key: RetroDesktopShapes.of(f.value),
};

OutlinedBorder plain(OutlinedBorder shape) =>
    shape.copyWith(side: BorderSide.none);

// Whether [shape] is one of [shapes]' outlines or concentric with one: the
// family's steps, the radio's circle, and their insets (rows and inner parts
// take their group's inner corners, square where they meet a neighbour).
bool inFamily(OutlinedBorder shape, RetroDesktopShapes shapes) {
  final value = plain(shape);
  if (value is CircleBorder) return true;
  final steps = [
    shapes.small,
    shapes.medium,
    shapes.large,
    shapes.full,
    shapes.button,
  ];
  if (value is RoundedRectangleBorder) {
    if (steps.every((s) => s is! RoundedRectangleBorder)) {
      return value.borderRadius == BorderRadius.zero &&
          steps.any((s) => s is StadiumBorder);
    }
    final most = steps
        .whereType<RoundedRectangleBorder>()
        .map((s) => s.borderRadius.resolve(TextDirection.ltr).topLeft.x)
        .reduce((a, b) => a > b ? a : b);
    final r = value.borderRadius.resolve(TextDirection.ltr);
    return [
      r.topLeft,
      r.topRight,
      r.bottomLeft,
      r.bottomRight,
    ].every((c) => c.x == c.y && c.x >= 0 && c.x <= most);
  }
  if (value is StadiumBorder) return steps.any((s) => s is StadiumBorder);
  if (value is RetroDesktopBorder) {
    final cuts = steps.whereType<RetroDesktopBorder>().map((s) => s.cut);
    if (cuts.isEmpty) return false;
    final most = cuts.reduce((a, b) => a > b ? a : b);
    return value.cut <= most;
  }
  return steps.any((s) => plain(s) == value);
}

// The highlight painters under [press] that will draw, as (painter, size,
// outline). A slider's painter draws its own, around its thumb.
List<(dynamic, Size, OutlinedBorder)> drawing(
  WidgetTester tester,
  Finder press,
) {
  final found = <(dynamic, Size, OutlinedBorder)>[];
  // The highlight is a custom paint of its own kind (it hands its painter the
  // device's grid): found as any CustomPaint, not by its exact type.
  for (final element
      in find
          .descendant(
            of: press,
            matching: find.byWidgetPredicate((w) => w is CustomPaint),
          )
          .evaluate()) {
    final widget = element.widget as CustomPaint;
    final size = (element.renderObject! as RenderBox).size;
    for (final CustomPainter? painter in [
      widget.foregroundPainter,
      widget.painter,
    ]) {
      if (painter == null) continue;
      final dynamic p = painter;
      switch (painter.runtimeType.toString()) {
        case '_HighlightPainter':
          final claim = p.skip as RetroDesktopHighlightClaim?;
          if (claim?.claimed ?? false) continue;
          found.add((p, size, p.shape as OutlinedBorder));
        case '_SliderPainter':
          found.add((p, size, p.shapeDefault as OutlinedBorder));
      }
    }
  }
  return found;
}

FocusNode? nodeOf(Element press) {
  FocusNode? found;
  void visit(Element element) {
    if (found != null) return;
    final node = Focus.maybeOf(element, createDependency: false);
    if (node != null && node.context != null) {
      var inside = false;
      node.context!.visitAncestorElements((a) {
        if (a == press) inside = true;
        return !inside;
      });
      if (inside) {
        found = node;
        return;
      }
    }
    element.visitChildElements(visit);
  }

  press.visitChildElements(visit);
  return found;
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  test('the ring is concentric: the outline grown by its gap', () {
    const rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
    );
    expect(
      RetroDesktopShapes.outset(rounded, 2),
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
    );
    expect(
      RetroDesktopShapes.outset(const StadiumBorder(), 2),
      isA<StadiumBorder>(),
    );
    expect(
      RetroDesktopShapes.outset(const RetroDesktopBorder.square(), 2),
      const RetroDesktopBorder.square(),
    );
    expect(
      (RetroDesktopShapes.outset(
        const RetroDesktopBorder.bevelled(),
        2,
      ) as RetroDesktopBorder).cut,
      greaterThan(1),
    );
    expect(
      RetroDesktopShapes.inset(rounded, 2),
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    );
  });

  for (final family in families.entries) {
    testWidgets('${family.key}: focus and hover take each part\'s shape', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final theme = RetroDesktopThemeData.classic().copyWith(
        appearance: appearances[family.key]!,
      );
      kitShownTheme = (b) =>
          RetroDesktopThemeData.classic(b)
              .copyWith(appearance: appearances[family.key]!);
      addTearDown(() => kitShownTheme = null);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(-10, -10));
      addTearDown(mouse.removePointer);
      var parts = 0, claimed = 0;
      for (final specimen in shapeSpecimens.entries) {
        if (specimen.key == 'kitSpecimenScreen') continue;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                RetroDesktopTheme(data: theme, child: child!),
            home: SingleChildScrollView(
              child: KeyedSubtree(
                key: ValueKey(specimen.key),
                child: specimen.value(),
              ),
            ),
          ),
        );
        await tester.pump();
        final presses = find.byType(RetroDesktopPressable).evaluate().toList();
        for (var i = 0; i < presses.length; i++) {
          final press = find.byType(RetroDesktopPressable).at(i);
          if (!tester.any(press)) break;
          final widget = tester.widget<RetroDesktopPressable>(press);
          if (widget.onPressed == null && widget.onLongPress == null) continue;
          final node = nodeOf(tester.element(press));
          if (node == null || !node.canRequestFocus) continue;
          final box = tester.getRect(press);
          if (box.isEmpty || box.bottom < 0 || box.top > 1600) continue;
          final why = '${specimen.key} press $i';

          node.requestFocus();
          await mouse.moveTo(box.center);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          final active = drawing(
            tester,
            press,
          ).where((p) => p.$1.ring != null).toList();
          // A menu's rows show focus and the pointer as the period's menus did: the row lit in the highlight, its
          // words inverted, no ring round it (the lit-row rule). Checked as that, by name.
          if (_litRows.contains(specimen.key)) {
            expect(active, isEmpty, reason: '$why: a lit row draws no ring');
            expect(
              find.descendant(
                of: press,
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is DecoratedBox &&
                      w.decoration is ShapeDecoration &&
                      (w.decoration as ShapeDecoration).color ==
                          theme.colors.highlight,
                ),
              ),
              findsOneWidget,
              reason: '$why: the row under the pointer is lit',
            );
            parts++;
            claimed++;
            node.unfocus();
            await mouse.moveTo(const Offset(-10, -10));
            await tester.pump();
            continue;
          }
          expect(active, hasLength(1), reason: '$why: one focus ring');
          final hovered = drawing(
            tester,
            press,
          ).where((p) => p.$1.hover != null).toList();
          expect(
            hovered.length,
            lessThanOrEqualTo(1),
            reason: '$why: one hover tint',
          );
          final (painter, size, shape) = active.single;
          final fallback =
              painter.runtimeType.toString() == '_HighlightPainter' &&
              painter.skip != null;
          if (fallback) {
            // The press drew it: no face below may fill the press, or that
            // face should have drawn it in its own outline.
            final faces = find
                .descendant(
                  of: press,
                  matching: find.byWidgetPredicate(
                    (w) => w.runtimeType.toString() == '_Face',
                  ),
                )
                .evaluate()
                .map((e) => (e.renderObject! as RenderBox).size);
            expect(
              faces.where(
                (f) =>
                    (f.width - size.width).abs() < .5 &&
                    (f.height - size.height).abs() < .5,
              ),
              isEmpty,
              reason: '$why: a face fills the part but left its highlight',
            );
          }
          expect(
            inFamily(shape, family.value),
            isTrue,
            reason: '$why: its ring follows $shape',
          );
          if (!fallback) claimed++;
          parts++;
          node.unfocus();
          await mouse.moveTo(const Offset(-10, -10));
          await tester.pump();
        }
        expect(tester.takeException(), isNull, reason: specimen.key);
      }
      debugPrint(
        'HIGHLIGHT ${family.key}: $parts pressable parts, $claimed drawn by their own face',
      );
      expect(parts, greaterThan(60));
      expect(claimed, greaterThan(parts ~/ 2));
    });
  }
}
