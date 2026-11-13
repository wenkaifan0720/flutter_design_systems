/// Where the engine draws a one-line label's or text entry's capitals: what
/// `DesignCapCenter` places and the alignment checks read. A line is a
/// [RenderParagraph] or a [RenderEditable]. Inside ui_core; not exported.
library;

import 'package:flutter/rendering.dart';

import 'drawn_pixels.dart' show isIconGlyph;

/// A box that draws its label with the capitals on its middle
/// (`DesignCapCenter`'s), and the cap height it was given.
abstract interface class CapCentred {
  /// The label's cap height as a fraction of its font size.
  double get capHeightFactor;
}

/// The line [root] shows: its text entry's editable when it holds one (its
/// typed text, and the hint drawn on its baseline), else its first
/// paragraph, in paint order, that is not an icon's glyph; null without
/// either.
RenderBox? labelLine(RenderObject root) {
  RenderEditable? editable;
  RenderParagraph? paragraph;
  void visit(RenderObject node) {
    if (editable != null) return;
    if (node is RenderEditable && node.hasSize) {
      editable = node;
      return;
    }
    if (paragraph == null &&
        node is RenderParagraph &&
        node.hasSize &&
        !isIconGlyph(node.text.toPlainText(includeSemanticsLabels: false))) {
      paragraph = node;
    }
    node.visitChildren(visit);
  }

  visit(root);
  return editable ?? paragraph;
}

/// What [line] (a paragraph or an editable) shows, as plain text.
String lineText(RenderBox line) => switch (line) {
  RenderParagraph(:final text) => text.toPlainText(
    includeSemanticsLabels: false,
  ),
  RenderEditable(:final text) =>
    text?.toPlainText(includeSemanticsLabels: false) ?? '',
  _ => '',
};

/// The boxes [line] draws [selection] in, in its own units.
List<TextBox> lineBoxes(RenderBox line, TextSelection selection) =>
    switch (line) {
      final RenderParagraph p => p.getBoxesForSelection(selection),
      final RenderEditable e => e.getBoxesForSelection(selection),
      _ => const [],
    };

/// Whether [line] holds widgets inline, whose layout only its own pass
/// knows.
bool holdsWidgets(RenderBox line) =>
    line is RenderParagraph && line.childCount > 0;

/// Whether [line] is one line high: the engine rounds each line's baseline
/// from that line's own top, so only a single line's rounding is its first
/// baseline's. Not with widgets inline.
bool isOneLine(RenderBox line) {
  if (holdsWidgets(line)) return false;
  final height = switch (line) {
    final RenderParagraph p => p.getFullHeightForCaret(
      const TextPosition(offset: 0),
    ),
    // An editable that may wrap moves as lines come and go: not one line.
    final RenderEditable e => e.maxLines == 1 ? e.preferredLineHeight : 0.0,
    _ => 0.0,
  };
  return height > 0 && line.size.height < height * 1.5;
}

/// The cap height, as a fraction of the font size, a label is read at when
/// nothing gives its own: no cap center around it, no capital or figure in
/// it. The looks' typefaces run from 0.66 to 0.73 (Jersey 15, a pixel face,
/// 0.556).
const double typicalCapHeightFactor = 0.7;

/// The size [line]'s first words are drawn at: their font size through its
/// text scaler (an empty editable's, its style's).
double labelFontSize(RenderBox line) => switch (line) {
  final RenderParagraph p => p.textScaler.scale(_fontSize(p.text) ?? 14),
  final RenderEditable e => e.textScaler.scale(
    (e.text == null ? null : _fontSize(e.text!)) ?? 14,
  ),
  _ => 14,
};

/// [line]'s capitals, from the top of its first line to its baseline, as
/// the engine draws them, in [line]'s own units: the baseline at the
/// laid-out one rounded to a whole logical pixel below the line's top (the
/// device pixel it then lands on is at most half a device pixel off), the
/// top [capHeightFactor] of the font size above it. Null when [line] holds
/// widgets inline.
({double top, double baseline})? drawnCaps(
  RenderBox line,
  double capHeightFactor,
) {
  final b = laidBaseline(line);
  if (b == null) return null;
  final fontSize = labelFontSize(line);
  final baseline = (b + 0.5).floorToDouble();
  return (top: baseline - capHeightFactor * fontSize, baseline: baseline);
}

/// The style [line]'s first words are drawn in, its spans' styles merged
/// down to them (an empty line's own style); null without one.
TextStyle? lineStyle(RenderBox line) {
  final span = switch (line) {
    RenderParagraph(:final text) => text,
    RenderEditable(:final text) => text,
    _ => null,
  };
  if (span == null) return null;
  TextStyle? found;
  bool visit(InlineSpan s, TextStyle? inherited) {
    final own = inherited == null ? s.style : inherited.merge(s.style);
    if (s is TextSpan) {
      if (s.text?.isNotEmpty ?? false) {
        found = own;
        return false;
      }
      for (final c in s.children ?? const <InlineSpan>[]) {
        if (!visit(c, own)) return false;
      }
    }
    return true;
  }

  visit(span, null);
  return found ?? span.style;
}

/// [line]'s first baseline as laid out, from its top; null when it holds
/// widgets inline.
double? laidBaseline(RenderBox line) {
  if (holdsWidgets(line) || !line.hasSize) return null;
  return line.getDryBaseline(line.constraints, TextBaseline.alphabetic);
}

// The font size the first words of [span] are set in, unscaled (an empty
// span's own style's); null when no style gives one (the engine's default,
// 14, then applies).
double? _fontSize(InlineSpan span) {
  double? found;
  bool visit(InlineSpan s, double? inherited) {
    final own = s.style?.fontSize ?? inherited;
    if (s is TextSpan) {
      if (s.text?.isNotEmpty ?? false) {
        found = own;
        return false;
      }
      for (final c in s.children ?? const <InlineSpan>[]) {
        if (!visit(c, own)) return false;
      }
    }
    return true;
  }

  visit(span, null);
  return found ?? span.style?.fontSize;
}
