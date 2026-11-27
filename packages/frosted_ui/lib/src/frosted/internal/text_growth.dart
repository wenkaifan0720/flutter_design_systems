import 'package:flutter/widgets.dart';

/// How far the reader's text size grows a part drawn round its words or a
/// glyph (a tag, a monogram, a glyph's token, a date's block): the ambient
/// [TextScaler]'s factor at a 14 px line, from 1 (a smaller text size keeps
/// the part at its own size) to 2 (the host's cap). Each such part grows its
/// face, its words and its glyph by it alike, so a row at 130% stands its
/// mark and its tag as large as its words. Plumbing of the components.
double frostedTextGrowth(BuildContext context) =>
    (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 2.0);
