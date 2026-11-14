// Every interaction mark takes its part's exact shape, under every corner family Customize offers. For each pressable
// part on every gallery page it hovers, presses and focuses the part, then reads the mark the look paints: a pointer
// over a part paints no mark at all; the press's wash and the focus ring take the outline the part itself paints (its
// ShapeDecoration or its painter's shape), and a frameless part (a row, a link) must still take a step of the shape
// theme. The focus ring stands concentric outside it.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_parts.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/design_review.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'gallery_support.dart';
import 'support.dart';

OutlinedBorder _bare(OutlinedBorder s) => s.copyWith(side: BorderSide.none);

/// The outline the part paints at the mark's own size, or null for a frameless part.
OutlinedBorder? _partShape(Element highlight, Size size) {
  OutlinedBorder? found;
  void visit(Element e) {
    if (found != null) return;
    final ro = e.renderObject;
    final sized =
        ro is RenderBox &&
        ro.hasSize &&
        (ro.size.width - size.width).abs() < .5 &&
        (ro.size.height - size.height).abs() < .5;
    final w = e.widget;
    if (sized && w is DecoratedBox && w.decoration is ShapeDecoration) {
      final shape = (w.decoration as ShapeDecoration).shape;
      if (shape is OutlinedBorder) found = shape;
    } else if (sized && w is CustomPaint && w.painter != null) {
      try {
        final dynamic painter = w.painter;
        final Object? shape = painter.shape;
        if (shape is OutlinedBorder) found = shape;
      } on NoSuchMethodError {
        // A painter with no outline of its own: a glyph, a chart.
      }
    }
    if (found == null && w is! ComicHighlight) e.visitChildren(visit);
  }

  highlight.visitChildren(visit);
  return found;
}

/// The look's mark on [highlight], or null when it paints none in these states.
dynamic _mark(Element highlight) {
  dynamic found;
  void visit(Element e) {
    if (found != null) return;
    final w = e.widget;
    if (w is CustomPaint &&
        w.foregroundPainter?.runtimeType.toString() == '_PressPainter') {
      found = w.foregroundPainter;
      return;
    }
    e.visitChildren(visit);
  }

  highlight.visitChildren(visit);
  return found;
}

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  test(
    'a focus ring grows a rounded corner by its gap and keeps a square one',
    () {
      final rounded = comicOutsetShape(ComicShapes.rounded(8).small, 3);
      expect(
        (rounded as RoundedRectangleBorder).borderRadius
            .resolve(TextDirection.ltr)
            .topLeft
            .x,
        11,
      );
      final square = comicOutsetShape(const ComicShapes().small, 3);
      expect(
        (square as RoundedRectangleBorder).borderRadius
            .resolve(TextDirection.ltr)
            .topLeft
            .x,
        0,
      );
      expect(comicOutsetShape(const StadiumBorder(), 3), const StadiumBorder());
    },
  );

  for (final corners in GalleryCorners.values) {
    final custom = GalleryCustom(corners: corners);
    final shapes = custom.shapes;
    final steps = {
      for (final s in [
        shapes.small,
        shapes.medium,
        shapes.large,
        shapes.capsule,
        shapes.full,
      ])
        _bare(s),
      // A grouped row's wash is concentric with its group, as an open menu's
      // rows are: the medium step less the rim and the rows' 4 px inset.
      _bare(comicInsetShape(shapes.medium, 7)),
      // A cell of a trough (tabs, pagination, the stepper): the control step
      // less the trough's 2.5 rim and the cells' 2 px inset, as its thumb is.
      _bare(comicInsetShape(shapes.small, 4.5)),
      // A half of a split button: the control step less the face's 2.5 rim
      // and the halves' 3 px inset, concentric with the face it sits in.
      _bare(comicInsetShape(shapes.small, 5.5)),
    };
    for (final page in [
      ...galleryPages,
      ...reviewPages,
      (id: 'review-corners', title: 'Corners', build: reviewCorners),
    ]) {
      testWidgets(
        '${corners.name}: every mark on ${page.id} takes its part\'s shape',
        (tester) async {
          kitShownTheme = (b) => custom.theme('offset', b);
          addTearDown(() => kitShownTheme = null);
          FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.alwaysTraditional;
          addTearDown(
            () => FocusManager.instance.highlightStrategy =
                FocusHighlightStrategy.automatic,
          );
          await pumpGalleryPage(tester, page, 'offset', Brightness.light);
          final marks = find.byType(ComicHighlight).evaluate().where((e) {
            final h = e.widget as ComicHighlight;
            return h.wash || h.ring;
          }).toList();
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          final failures = <String>[];
          var checked = 0, ringed = 0, washed = 0;
          for (final highlight in marks) {
            if (!highlight.mounted) continue;
            final widget = highlight.widget as ComicHighlight;
            final box = highlight.renderObject as RenderBox?;
            if (box == null || !box.hasSize || !box.attached) continue;
            final size = box.size;
            final part = _partShape(highlight, size);
            final drawn = _bare(widget.shape);
            final where =
                '${highlight.findAncestorWidgetOfExactType<ComicPressable>()?.label ?? highlight.toStringShort()} '
                '(${size.width.toStringAsFixed(0)}x${size.height.toStringAsFixed(0)})';
            if (part != null && _bare(part) != drawn) {
              failures.add('$where: mark $drawn on a part drawn as $part');
            } else if (part == null && !steps.contains(drawn)) {
              failures.add('$where: frameless mark $drawn is no shape step');
            }
            // Focus: the ring is painted, on this outline.
            if (widget.ring) {
              Focus.maybeOf(highlight, createDependency: false)?.requestFocus();
              await tester.pump();
              // The ring inks in on the state motion; where the focus lands a frame late, the next frame starts it.
              await tester.pump(const Duration(milliseconds: 400));
              await tester.pump(const Duration(milliseconds: 400));
              if (highlight.mounted &&
                  Focus.maybeOf(highlight, createDependency: false)?.hasFocus ==
                      true) {
                final dynamic mark = _mark(highlight);
                ringed++;
                if (mark == null || mark.ring == null) {
                  failures.add('$where: focused, but no ring');
                } else if (mark.drawn != drawn) {
                  failures.add('$where: ring on ${mark.drawn}, part $drawn');
                }
              }
              FocusManager.instance.primaryFocus?.unfocus();
              await tester.pump(const Duration(milliseconds: 400));
            }
            // Hover and press: the wash fills this outline.
            if (widget.wash && highlight.mounted && box.attached) {
              final centre = box.localToGlobal(size.center(Offset.zero));
              final view =
                  tester.view.physicalSize / tester.view.devicePixelRatio;
              if (centre.dx < 0 ||
                  centre.dy < 0 ||
                  centre.dx > view.width ||
                  centre.dy > view.height) {
                continue;
              }
              await mouse.moveTo(centre);
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 400));
              // An open menu's active row follows the pointer (polish3 §1): its
              // row takes the lamp, and the keys go on from it.
              var inMenu = false;
              if (highlight.mounted) {
                highlight.visitAncestorElements((e) {
                  inMenu = e.widget is ComicMenu<Object?>;
                  return !inMenu;
                });
              }
              if (highlight.mounted && !inMenu && _mark(highlight) != null) {
                failures.add('$where: a pointer over it painted a mark');
              }
              await mouse.moveTo(Offset.zero);
              final finger = await tester.startGesture(centre);
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 400));
              if (highlight.mounted) {
                final dynamic pressed = _mark(highlight);
                if (pressed != null) washed++;
                if (pressed != null && pressed.drawn != drawn) {
                  failures.add('$where: press wash on ${pressed.drawn}');
                }
              }
              await finger.cancel();
              await tester.pump(const Duration(milliseconds: 400));
            }
            if (widget.wash) checked++;
          }
          debugPrint(
            'highlights ${corners.name}/${page.id}: $checked parts, '
            '$ringed rings, $washed washes',
          );
          if (checked > 0) {
            expect(ringed, greaterThan(0), reason: 'no part took the focus');
            expect(washed, greaterThan(0), reason: 'no part washed on a press');
          }
          expect(failures, isEmpty, reason: failures.join('\n'));
        },
      );
    }
  }
}
