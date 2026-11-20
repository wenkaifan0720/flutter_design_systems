import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Keeps an underline clear of Arabic descenders without moving the label,
/// at one depth along each line of words.
class CivicUnderlined extends StatelessWidget {
  /// Applies [style] to [child].
  const CivicUnderlined({super.key, required this.style, required this.child});

  /// The label style and its decoration.
  final TextStyle style;

  /// A label, optionally accompanied by a glyph.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ink = style.decorationColor ?? style.color;
    if (Directionality.of(context) != TextDirection.rtl ||
        ink == null ||
        style.decoration?.contains(TextDecoration.underline) != true) {
      return DefaultTextStyle.merge(style: style, child: child);
    }
    final size = MediaQuery.textScalerOf(context).scale(
      style.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 19,
    );
    return _Underline(
      ink: ink,
      thickness: size / 19 * (style.decorationThickness ?? 1),
      // The words keep their decoration, so the painter knows them from a
      // glyph, in a colour that draws nothing. Not transparent black: the
      // text engine reads that as no colour at all and draws the words' own
      // underline in their colour, through the letters, beside this one.
      child: DefaultTextStyle.merge(
        style: style.copyWith(decorationColor: const Color(0x00FFFFFF)),
        child: child,
      ),
    );
  }
}

class _Underline extends SingleChildRenderObjectWidget {
  const _Underline({
    required this.ink,
    required this.thickness,
    required super.child,
  });

  final Color ink;
  final double thickness;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderUnderline(ink, thickness);

  @override
  void updateRenderObject(BuildContext context, _RenderUnderline renderObject) {
    renderObject.update(ink, thickness);
  }
}

/// A run of anything but white space: a word, or a run of glyphs.
final _word = RegExp(r'\S+');

class _RenderUnderline extends RenderProxyBox {
  _RenderUnderline(this.ink, this.thickness);

  Color ink;
  double thickness;

  void update(Color nextInk, double nextThickness) {
    if (ink == nextInk && thickness == nextThickness) return;
    ink = nextInk;
    thickness = nextThickness;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (ink.a == 0) return;
    final canvas = context.canvas;
    final paint = Paint()..color = ink;
    void underline(RenderObject node) {
      if (node is RenderParagraph) {
        // Icons paint a paragraph too, but do not inherit the label's decoration.
        if (node.text.style?.decoration?.contains(TextDecoration.underline) !=
            true) {
          return;
        }
        // One line under each line of words, from its first word's edge to
        // its last's, as deep as its deepest word's box: clear of Arabic
        // descenders. Drawn box by box it stepped up at every space between
        // Arabic words, whose face is shallower than Noto Sans Arabic's.
        final words = [
          for (final word in _word.allMatches(node.text.toPlainText()))
            TextSelection(baseOffset: word.start, extentOffset: word.end),
        ];
        // The lines, by their foot: boxes as tall as their line share it.
        final lines = <double, _Line>{};
        for (final word in words) {
          for (final box in node.getBoxesForSelection(
            word,
            boxHeightStyle: ui.BoxHeightStyle.max,
          )) {
            (lines[box.bottom] ??= _Line(
              box.top,
              box.bottom,
            )).span(box.left, box.right);
          }
        }
        for (final word in words) {
          for (final box in node.getBoxesForSelection(word)) {
            final middle = (box.top + box.bottom) / 2;
            for (final line in lines.values) {
              if (middle >= line.top && middle <= line.foot) {
                line.reach(box.bottom);
                break;
              }
            }
          }
        }
        if (lines.isEmpty) return;
        canvas.save();
        canvas.translate(offset.dx, offset.dy);
        canvas.transform(node.getTransformTo(this).storage);
        for (final line in lines.values) {
          canvas.drawRect(
            Rect.fromLTRB(line.left, line.at, line.right, line.at + thickness),
            paint,
          );
        }
        canvas.restore();
      } else {
        node.visitChildren(underline);
      }
    }

    visitChildren(underline);
  }
}

/// A line of words under construction: its top and foot, its ends, and
/// how deep its deepest word's box reaches.
class _Line {
  _Line(this.top, this.foot);

  final double top;
  final double foot;
  double left = double.infinity;
  double right = double.negativeInfinity;
  double depth = double.negativeInfinity;

  void span(double from, double to) {
    left = math.min(left, from);
    right = math.max(right, to);
  }

  void reach(double bottom) => depth = math.max(depth, bottom);

  /// Where the line is drawn: under its deepest word, or its foot.
  double get at => depth.isFinite ? depth : foot;
}
