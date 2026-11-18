import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Keeps an underline clear of Arabic descenders without moving the label.
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
        final text = node.text.toPlainText();
        if (text.isEmpty) return;
        final boxes = node.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: text.length),
        );
        canvas.save();
        canvas.translate(offset.dx, offset.dy);
        canvas.transform(node.getTransformTo(this).storage);
        for (final box in boxes) {
          canvas.drawRect(
            Rect.fromLTRB(
              box.left,
              box.bottom,
              box.right,
              box.bottom + thickness,
            ),
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
