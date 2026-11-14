// Check painted text against each enclosing outline, including a clear gutter.
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

Iterable<Offset> _probes(Rect r) sync* {
  // Sample the whole perimeter, so a burst valley between corners cannot hide
  // an intrusion into the four-pixel gutter.
  for (var x = r.left; x <= r.right; x += 1) {
    yield Offset(x, r.top);
    yield Offset(x, r.bottom);
  }
  for (var y = r.top; y <= r.bottom; y += 1) {
    yield Offset(r.left, y);
    yield Offset(r.right, y);
  }
  yield r.bottomRight;
}

Map<RenderBox, OutlinedBorder> _outlines(WidgetTester tester) {
  final result = <RenderBox, OutlinedBorder>{};
  for (final element in find.byType(DecoratedBox).evaluate()) {
    final decoration = (element.widget as DecoratedBox).decoration;
    if (decoration is ShapeDecoration && decoration.shape is OutlinedBorder) {
      final shape = decoration.shape as OutlinedBorder;
      // An unplated text link has a transparent decoration for state handling,
      // but paints no enclosing contour or fill.
      if ((decoration.color == null || decoration.color!.a == 0) &&
          (shape.side.style == BorderStyle.none || shape.side.width == 0)) {
        continue;
      }
      result[element.findRenderObject()! as RenderBox] = shape;
    }
  }
  for (final element in find.byType(AnimatedComicShape).evaluate()) {
    final shape = (element.widget as AnimatedComicShape).shape;
    if (shape == null) continue;
    final custom = find.descendant(
      of: find.byElementPredicate((e) => identical(e, element)),
      matching: find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            const [
              '_ActPainter',
              '_FieldPainter',
              '_BalloonPainter',
            ].contains(w.painter.runtimeType.toString()),
      ),
    );
    if (custom.evaluate().isNotEmpty) {
      result[custom.evaluate().first.findRenderObject()! as RenderBox] = shape;
    }
  }
  return result;
}

void expectComicContentClearance(WidgetTester tester, {double clearance = 4}) {
  final outlines = _outlines(tester);
  final misses = <String>[];
  final painted = <(RenderBox, String, List<Rect>)>[];
  for (final paragraph in tester.renderObjectList<RenderParagraph>(
    find.byType(RichText),
  )) {
    final text = paragraph.text.toPlainText();
    if (text.trim().isEmpty) continue;
    painted.add((
      paragraph,
      text,
      paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          )
          .map((box) => box.toRect())
          .toList(),
    ));
  }
  for (final editor
      in tester
          .stateList<EditableTextState>(find.byType(EditableText))
          .map((state) => state.renderEditable)) {
    final text = editor.text?.toPlainText() ?? '';
    if (text.trim().isEmpty) continue;
    painted.add((
      editor,
      text,
      editor
          .getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          )
          // Entered text scrolls inside the editor; offscreen glyphs
          // are clipped and are not part of its painted bounds.
          .map(
            (box) => editor.clipBehavior == Clip.none
                ? box.toRect()
                : box.toRect().intersect(editor.paintBounds),
          )
          .toList(),
    ));
  }
  for (final (paragraph, text, boxes) in painted) {
    for (
      RenderObject? parent = paragraph.parent;
      parent != null;
      parent = parent.parent
    ) {
      final shape = outlines[parent];
      if (shape == null || parent is! RenderBox) continue;
      final path = shape.getInnerPath(
        Offset.zero & parent.size,
        textDirection: TextDirection.ltr,
      );
      for (final box in boxes) {
        final bounds = MatrixUtils.transformRect(
          paragraph.getTransformTo(parent),
          box,
        ).inflate(clearance);
        if (!bounds.isFinite) {
          misses.add(
            '"$text" has a non-finite transform inside ${shape.runtimeType} ${parent.size}',
          );
          continue;
        }
        if (bounds.isEmpty) continue;
        if (_probes(bounds).any((point) => !path.contains(point))) {
          misses.add(
            '"$text" $bounds has less than $clearance px clearance from ${shape.runtimeType} ${parent.size}',
          );
        }
      }
    }
  }
  expect(misses, isEmpty, reason: misses.join('\n'));
}
