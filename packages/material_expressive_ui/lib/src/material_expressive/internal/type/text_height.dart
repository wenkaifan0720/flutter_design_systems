/// How an Expressive type style's first and last lines take their height,
/// as Compose lays them out. Internal (w1-type's slot; w1-parity measured
/// it against the oracle's `type/*` scenes). The `text` role and anything
/// else that sets a type-scale style in a `Text` lays it out through
/// [expressiveTextLayout] (the style and `textHeightBehavior` to pass).
///
/// Compose sets every Material style with `LineHeightStyle(Alignment.Center,
/// Trim.None)`. Where the style's line height is at least the font's own
/// height, that is Flutter's `height` with [TextLeadingDistribution.even]
/// on every line, first and last included (the default behaviour). Where
/// the line height is shorter than Roboto Flex's ascent + descent (display
/// large 57/64 and display medium 45/52), `LineHeightStyleSpan` does not
/// trim the font: the first line keeps the font's full ascent and the last
/// line its full descent, so a two-line display large is 344 px tall at
/// DPR 2.625, not 2 × 168. Flutter's equivalent is not applying the height
/// to the first ascent and the last descent.
library;

import 'package:flutter/widgets.dart';

import 'font_metrics.g.dart';

/// [style] and the text-height behaviour that lay it out as Compose does:
/// unchanged with the default behaviour when its line height covers Roboto
/// Flex's height, else the font's own ascent over the first line and
/// descent under the last. Scale-free: text scaling multiplies the size and
/// the line height alike.
///
/// In the second case the style's leading is distributed proportionally:
/// Flutter 3.47's paragraph ignores `applyHeightToFirstAscent` and
/// `applyHeightToLastDescent` under [TextLeadingDistribution.even]
/// (measured: a two-line display medium stays 104 dp tall). Proportional
/// leading moves only the boundary between inner lines, never a baseline,
/// so the result matches Compose's centred split (the oracle's
/// `type/display-*` scenes hold it to 0.2 dp).
(TextStyle, TextHeightBehavior) expressiveTextLayout(TextStyle style) {
  final height = style.height;
  const font =
      ExpressiveRobotoFlexMetrics.ascent +
      ExpressiveRobotoFlexMetrics.descent +
      ExpressiveRobotoFlexMetrics.lineGap;
  if (height == null || height >= font) return (style, _applied);
  return (
    style.copyWith(leadingDistribution: TextLeadingDistribution.proportional),
    _fontEdges,
  );
}

const TextHeightBehavior _applied = TextHeightBehavior(
  leadingDistribution: TextLeadingDistribution.even,
);

const TextHeightBehavior _fontEdges = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);
