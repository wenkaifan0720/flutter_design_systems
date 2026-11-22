/// Box drawing, painted on the grid: the frames, brackets, shades, braille
/// and blocks a terminal draws with its line-drawing characters. Painted
/// rather than set as glyphs, so the lines join exactly, a single line can
/// split into a double one as focus arrives, and a screen reader never reads
/// them.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../grid.dart';
import '../internal/frame_edge.dart';

/// A gap cut into a frame's top or bottom line, where its title or its
/// note stands: from `start` to `end`, in pixels from the frame's left.
typedef TermGap = ({double start, double end});

/// How far apart the two lines of a double line stand at [grid]: about a
/// third of a cell, as a font's `═` draws them.
double termDoubleGap(TermGrid grid, double stroke) =>
    math.max(stroke * 2 + 1, grid.cellWidth / 3);

/// Paints a frame through the middle of the outer cells of [size]: a
/// single line, splitting into a double one as [doubled] goes from 0 to 1,
/// with [topGaps] and [bottomGaps] cut out for the words in its borders.
class TermFramePainter extends CustomPainter {
  /// A frame in [color] on [grid].
  const TermFramePainter({
    required this.grid,
    required this.color,
    required this.stroke,
    this.doubled = 0,
    this.topGaps = const [],
    this.topGapsEndInset,
    this.topEndGaps = const [],
    this.bottomGaps = const [],
    this.bottomGapsEndInset,
    this.bottomEndGaps = const [],
    this.fill,
    this.wordGround,
    this.shadow,
    this.textDirection = TextDirection.ltr,
  });

  /// Which edge the gaps are measured from: the start edge.
  final TextDirection textDirection;

  /// The grid the frame is drawn on.
  final TermGrid grid;

  /// The line's colour.
  final Color color;

  /// One line's width.
  final double stroke;

  /// 0: a single line; 1: a double one; between, the line splitting.
  final double doubled;

  /// Where the top line breaks for the title, measured from the start edge.
  final List<TermGap> topGaps;

  /// How near the end edge [topGaps] may reach, or null: a title cut to
  /// the room it has (with an ellipsis) breaks the line only that far.
  final double? topGapsEndInset;

  /// Where the top line breaks for words at its end, measured from the end
  /// edge.
  final List<TermGap> topEndGaps;

  /// Where the bottom line breaks for a note, measured from the start edge.
  final List<TermGap> bottomGaps;

  /// How near the end edge [bottomGaps] may reach, or null.
  final double? bottomGapsEndInset;

  /// Where the bottom line breaks for words at its end, measured from the
  /// end edge.
  final List<TermGap> bottomEndGaps;

  /// The inside of the frame, out to its outer line, and the cells of the
  /// words in its borders, filled before the line, or null.
  final Color? fill;

  /// The ground beside the frame (the page's), under the words' cells past
  /// the frame's outer line, or null: [fill] stands under the whole cell.
  ///
  /// With it, the words blank what is under them as a terminal's cells do,
  /// and no tab of [fill] stands out past the line.
  final Color? wordGround;

  /// A shade one cell right and half a line down, as a raised window casts
  /// in a text-mode program, or null.
  final Color? shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = grid.cellWidth;
    final lh = grid.lineHeight;
    final mid = Rect.fromLTRB(
      cw / 2,
      lh / 2,
      size.width - cw / 2,
      size.height - lh / 2,
    );
    final half = termDoubleGap(grid, stroke) / 2 * doubled.clamp(0, 1);
    // Each line of the pair on whole pixels, each way.
    final dx = termFrameStep(mid.left, half, stroke);
    final dy = termFrameStep(mid.top, half, stroke);
    // The frame's outer edge: the fill and the shade stop at the line, so
    // the frame never stands on a slab wider than itself, over the lines
    // and words beside it.
    final outer = Rect.fromLTRB(
      mid.left - dx - stroke / 2,
      mid.top - dy - stroke / 2,
      mid.right + dx + stroke / 2,
      mid.bottom + dy + stroke / 2,
    );
    final w = size.width;
    List<TermGap> placed(List<TermGap> gaps) => [
      for (final g in gaps)
        if (textDirection == TextDirection.rtl)
          (start: w - g.end, end: w - g.start)
        else
          g,
    ];
    final top = [
      ...placed([
        for (final g in topGaps)
          topGapsEndInset == null
              ? g
              : (start: g.start, end: math.min(g.end, w - topGapsEndInset!)),
      ]),
      for (final g in topEndGaps)
        if (textDirection == TextDirection.rtl)
          g
        else
          (start: w - g.end, end: w - g.start),
    ];
    final bottom = [
      ...placed([
        for (final g in bottomGaps)
          bottomGapsEndInset == null
              ? g
              : (start: g.start, end: math.min(g.end, w - bottomGapsEndInset!)),
      ]),
      for (final g in bottomEndGaps)
        if (textDirection == TextDirection.rtl)
          g
        else
          (start: w - g.end, end: w - g.start),
    ];
    if (fill != null && wordGround != null) {
      // Past the line, the words' cells stand on the ground beside the
      // frame: they blank what is under them, with no tab of the pane's
      // own ground standing out past its line.
      final beside = Paint()..color = wordGround!;
      for (final g in top) {
        canvas.drawRect(Rect.fromLTRB(g.start, 0, g.end, outer.top), beside);
      }
      for (final g in bottom) {
        canvas.drawRect(
          Rect.fromLTRB(g.start, outer.bottom, g.end, size.height),
          beside,
        );
      }
    }
    if (shadow != null) {
      final s = Paint()..color = shadow!;
      canvas
        ..drawRect(
          Rect.fromLTRB(
            outer.right,
            outer.top + lh / 2,
            outer.right + cw,
            outer.bottom + lh / 2,
          ),
          s,
        )
        ..drawRect(
          Rect.fromLTRB(
            outer.left + cw,
            outer.bottom,
            outer.right,
            outer.bottom + lh / 2,
          ),
          s,
        );
    }
    if (fill != null) {
      canvas.drawRect(outer, Paint()..color = fill!);
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;
    if (fill != null && wordGround == null) {
      // The words cut into the line stand on the ground a whole cell tall,
      // as a terminal's cells do, over whatever is under their half past
      // the line.
      final ground = Paint()..color = fill!;
      for (final g in top) {
        canvas.drawRect(Rect.fromLTRB(g.start, 0, g.end, lh), ground);
      }
      for (final g in bottom) {
        canvas.drawRect(
          Rect.fromLTRB(g.start, size.height - lh, g.end, size.height),
          ground,
        );
      }
    }
    if (half < 0.01) {
      _rect(canvas, mid, paint, top, bottom);
    } else {
      _rect(
        canvas,
        Rect.fromLTRB(
          mid.left - dx,
          mid.top - dy,
          mid.right + dx,
          mid.bottom + dy,
        ),
        paint,
        top,
        bottom,
      );
      _rect(
        canvas,
        Rect.fromLTRB(
          mid.left + dx,
          mid.top + dy,
          mid.right - dx,
          mid.bottom - dy,
        ),
        paint,
        top,
        bottom,
      );
    }
  }

  void _rect(
    Canvas canvas,
    Rect r,
    Paint paint,
    List<TermGap> topGaps,
    List<TermGap> bottomGaps,
  ) {
    final path = Path();
    // Left, bottom and right as one run where nothing breaks them.
    _horizontal(path, r.left, r.right, r.top, topGaps);
    path
      ..moveTo(r.left, r.top)
      ..lineTo(r.left, r.bottom);
    path
      ..moveTo(r.right, r.top)
      ..lineTo(r.right, r.bottom);
    _horizontal(path, r.left, r.right, r.bottom, bottomGaps);
    canvas.drawPath(path, paint);
  }

  void _horizontal(
    Path path,
    double from,
    double to,
    double y,
    List<TermGap> gaps,
  ) {
    final sorted = [...gaps]..sort((a, b) => a.start.compareTo(b.start));
    var x = from;
    for (final gap in sorted) {
      if (gap.start > x) {
        path
          ..moveTo(x, y)
          ..lineTo(math.min(gap.start, to), y);
      }
      x = math.max(x, gap.end);
    }
    if (x < to) {
      path
        ..moveTo(x, y)
        ..lineTo(to, y);
    }
  }

  @override
  bool shouldRepaint(TermFramePainter old) =>
      old.grid != grid ||
      old.color != color ||
      old.stroke != stroke ||
      old.doubled != doubled ||
      old.fill != fill ||
      old.wordGround != wordGround ||
      old.shadow != shadow ||
      old.textDirection != textDirection ||
      !_sameGaps(old.topGaps, topGaps) ||
      !_sameGaps(old.topEndGaps, topEndGaps) ||
      old.topGapsEndInset != topGapsEndInset ||
      old.bottomGapsEndInset != bottomGapsEndInset ||
      !_sameGaps(old.bottomGaps, bottomGaps) ||
      !_sameGaps(old.bottomEndGaps, bottomEndGaps);

  static bool _sameGaps(List<TermGap> a, List<TermGap> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Paints a horizontal rule through the middle of a line, from one end to
/// the other, with [gaps] cut out.
class TermRulePainter extends CustomPainter {
  /// A rule in [color].
  const TermRulePainter({
    required this.color,
    required this.stroke,
    this.gaps = const [],
    this.doubled = 0,
    this.gap = 3,
  });

  /// The line's colour.
  final Color color;

  /// The line's width.
  final double stroke;

  /// Where it breaks.
  final List<TermGap> gaps;

  /// 0 single, 1 double.
  final double doubled;

  /// The distance between the two lines of a double rule.
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    final half = gap / 2 * doubled.clamp(0, 1);
    for (final dy in half < 0.01 ? const [0.0] : [-half, half]) {
      final path = Path();
      var x = 0.0;
      final sorted = [...gaps]..sort((a, b) => a.start.compareTo(b.start));
      for (final g in sorted) {
        if (g.start > x) {
          path
            ..moveTo(x, y + dy)
            ..lineTo(g.start, y + dy);
        }
        x = math.max(x, g.end);
      }
      if (x < size.width) {
        path
          ..moveTo(x, y + dy)
          ..lineTo(size.width, y + dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(TermRulePainter old) =>
      old.color != color ||
      old.stroke != stroke ||
      old.doubled != doubled ||
      old.gap != gap ||
      !TermFramePainter._sameGaps(old.gaps, gaps);
}

/// The shape of a bracket pair: square `[ ]` for a button and a checkbox,
/// round `( )` for a radio.
enum TermBracketShape {
  /// `[ ]`.
  square,

  /// `( )`.
  round,
}

/// Paints a bracket in the first cell and its pair in the last cell of
/// [size], each a single line splitting into a double one as [doubled]
/// goes from 0 to 1. Between them, [fill] covers the inner cells: a press,
/// a selection or a filled button, in inverse video.
///
/// The keyboard's focus is the [cursor]: a block of [cursorColor] over
/// every cell, the brackets taken in and cut out of it in [knockout]. On a
/// part already filled ([hollow]: chosen, or a filled button) the cursor
/// turns it hollow instead: the bracket cells go solid, the fill clears.
class TermBracketPainter extends CustomPainter {
  /// Brackets in [color] round the cells of [size].
  const TermBracketPainter({
    required this.grid,
    required this.color,
    required this.stroke,
    this.doubled = 0,
    this.fill,
    this.fillAmount = 1,
    this.shape = TermBracketShape.square,
    this.cursor = 0,
    this.cursorColor,
    this.knockout,
    this.hollow = false,
  });

  /// How far the keyboard's focus has come, 0 to 1.
  final double cursor;

  /// The cursor's ink (the accent); null draws none.
  final Color? cursorColor;

  /// The brackets' colour on the cursor (the ink words take on the accent).
  final Color? knockout;

  /// Whether the cursor hollows a filled part rather than covering it.
  final bool hollow;

  /// The grid.
  final TermGrid grid;

  /// The brackets' colour.
  final Color color;

  /// One line's width.
  final double stroke;

  /// 0 single, 1 double.
  final double doubled;

  /// The inverse fill between the brackets, or null.
  final Color? fill;

  /// How much of the fill shows (0 to 1): it grows from the middle line
  /// out to the full line, as a press arrives.
  final double fillAmount;

  /// Square or round.
  final TermBracketShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = grid.cellWidth;
    final lh = grid.lineHeight;
    final cy = size.height / 2;
    final height = math.min(grid.fontSize * 1.2, lh);
    final c = cursorColor == null ? 0.0 : cursor.clamp(0.0, 1.0);
    if (c > 0) {
      termPaintCursor(
        canvas,
        Rect.fromLTRB(0, cy - lh / 2, size.width, cy + lh / 2),
        cursorColor!,
        c,
        cw,
        hollow: hollow,
      );
    }
    if (fill != null && fillAmount > 0) {
      final amount = fillAmount.clamp(0.0, 1.0);
      final full = Rect.fromLTRB(cw, cy - lh / 2, size.width - cw, cy + lh / 2);
      final inner = Rect.fromCenter(
        center: full.center,
        width: full.width,
        height: ui.lerpDouble(height * 0.5, full.height, amount)!,
      );
      final shown = hollow ? 1 - c : 1.0;
      canvas.drawRect(
        inner,
        Paint()
          ..color = fill!.withValues(
            alpha: fill!.a * math.min(1, amount * 2) * shown,
          ),
      );
    }
    final paint = Paint()
      ..color = c > 0 && knockout != null
          ? Color.lerp(color, knockout, c)!
          : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.miter;
    final half = termDoubleGap(grid, stroke) / 2 * doubled.clamp(0, 1);
    final offsets = half < 0.01 ? const [0.0] : [-half, half];
    for (final d in offsets) {
      // d < 0 is the outer line: further out and taller.
      final h = height / 2 - d;
      _pair(
        canvas,
        paint,
        Offset(cw * 0.55 + d, cy),
        Offset(size.width - cw * 0.55 - d, cy),
        h,
        cw * 0.32,
      );
    }
  }

  void _pair(
    Canvas canvas,
    Paint paint,
    Offset left,
    Offset right,
    double h,
    double arm,
  ) {
    switch (shape) {
      case TermBracketShape.square:
        canvas
          ..drawPath(
            Path()
              ..moveTo(left.dx + arm, left.dy - h)
              ..lineTo(left.dx, left.dy - h)
              ..lineTo(left.dx, left.dy + h)
              ..lineTo(left.dx + arm, left.dy + h),
            paint,
          )
          ..drawPath(
            Path()
              ..moveTo(right.dx - arm, right.dy - h)
              ..lineTo(right.dx, right.dy - h)
              ..lineTo(right.dx, right.dy + h)
              ..lineTo(right.dx - arm, right.dy + h),
            paint,
          );
      case TermBracketShape.round:
        final w = arm * 2.2;
        canvas
          ..drawArc(
            Rect.fromLTRB(left.dx, left.dy - h, left.dx + w * 2, left.dy + h),
            math.pi * 0.62,
            math.pi * 0.76,
            false,
            paint,
          )
          ..drawArc(
            Rect.fromLTRB(
              right.dx - w * 2,
              right.dy - h,
              right.dx,
              right.dy + h,
            ),
            -math.pi * 0.38,
            math.pi * 0.76,
            false,
            paint,
          );
    }
  }

  @override
  bool shouldRepaint(TermBracketPainter old) =>
      old.grid != grid ||
      old.color != color ||
      old.stroke != stroke ||
      old.doubled != doubled ||
      old.fill != fill ||
      old.fillAmount != fillAmount ||
      old.shape != shape ||
      old.cursor != cursor ||
      old.cursorColor != cursorColor ||
      old.knockout != knockout ||
      old.hollow != hollow;
}

/// The cursor over [band]: a block of [color] over every cell, [amount] of
/// the way in; [hollow], the band's first and last [cellWidth] only, as the
/// cursor stands on a part already in inverse video.
void termPaintCursor(
  Canvas canvas,
  Rect band,
  Color color,
  double amount,
  double cellWidth, {
  bool hollow = false,
}) {
  final a = amount.clamp(0.0, 1.0);
  if (a <= 0) return;
  final paint = Paint()..color = color.withValues(alpha: color.a * a);
  if (!hollow || band.width <= cellWidth * 2) {
    canvas.drawRect(band, paint);
    return;
  }
  canvas
    ..drawRect(
      Rect.fromLTWH(band.left, band.top, cellWidth, band.height),
      paint,
    )
    ..drawRect(
      Rect.fromLTRB(band.right - cellWidth, band.top, band.right, band.bottom),
      paint,
    );
}

/// The cursor on a part with no brackets of its own (a row, a tab, a
/// choice in a group): the block of [termPaintCursor] over [size], and in
/// its first and last cells a pair of brackets one line tall cut out of it
/// in [knockout], the cursor's own edges, so the block never reads as a
/// chosen part's inverse video.
class TermCursorPainter extends CustomPainter {
  /// The cursor over a part [amount] focused.
  const TermCursorPainter({
    required this.grid,
    required this.amount,
    required this.color,
    required this.knockout,
    required this.stroke,
    this.hollow = false,
  });

  /// The grid.
  final TermGrid grid;

  /// How far the keyboard's focus has come, 0 to 1.
  final double amount;

  /// The cursor's ink (the accent).
  final Color color;

  /// The brackets cut out of it.
  final Color knockout;

  /// One line's width.
  final double stroke;

  /// Whether the part is in inverse video already: the cursor stands on its
  /// end cells only.
  final bool hollow;

  @override
  void paint(Canvas canvas, Size size) {
    final a = amount.clamp(0.0, 1.0);
    if (a <= 0) return;
    termPaintCursor(
      canvas,
      Offset.zero & size,
      color,
      a,
      grid.cellWidth,
      hollow: hollow,
    );
    final lh = math.min(grid.lineHeight, size.height);
    canvas.save();
    canvas.translate(0, (size.height - lh) / 2);
    TermBracketPainter(
      grid: grid,
      color: knockout.withValues(alpha: knockout.a * a),
      stroke: stroke,
    ).paint(canvas, Size(size.width, lh));
    canvas.restore();
  }

  @override
  bool shouldRepaint(TermCursorPainter old) =>
      old.grid != grid ||
      old.amount != amount ||
      old.color != color ||
      old.knockout != knockout ||
      old.stroke != stroke ||
      old.hollow != hollow;
}

/// The dots of one braille cell lit for each frame of Terminal's spinner:
/// a dot running round the cell, as `⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏` draws it. Bits follow
/// Unicode's braille order (dot 1 is bit 0).
const List<int> termSpinnerFrames = [
  0x0B, // ⠋ dots 1 2 4
  0x19, // ⠙ dots 1 4 5
  0x39, // ⠹ dots 1 4 5 6
  0x38, // ⠸ dots 4 5 6
  0x3C, // ⠼ dots 3 4 5 6
  0x34, // ⠴ dots 3 5 6
  0x26, // ⠦ dots 2 3 6
  0x27, // ⠧ dots 1 2 3 6
  0x07, // ⠇ dots 1 2 3
  0x0F, // ⠏ dots 1 2 3 4
];

/// Paints one braille cell: the eight dots, those in [bits] in [color] and
/// the rest not at all.
class TermBraillePainter extends CustomPainter {
  /// A braille cell lit by [bits].
  const TermBraillePainter({
    required this.grid,
    required this.bits,
    required this.color,
  });

  /// The grid.
  final TermGrid grid;

  /// Which of the eight dots show (Unicode's order: dots 1, 2, 3 down the
  /// left, 4, 5, 6 down the right, then 7 and 8 at the foot).
  final int bits;

  /// The dots' colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = grid.cellWidth;
    final fs = grid.fontSize;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final dx = cw * 0.22;
    final dy = fs * 0.22;
    final r = math.max(1.0, cw * 0.11);
    final paint = Paint()..color = color;
    // Dot n's column and row, in Unicode's numbering.
    const places = [
      (0, 0),
      (0, 1),
      (0, 2),
      (1, 0),
      (1, 1),
      (1, 2),
      (0, 3),
      (1, 3),
    ];
    for (var i = 0; i < 8; i++) {
      if (bits & (1 << i) == 0) continue;
      final (col, row) = places[i];
      canvas.drawCircle(
        Offset(cx + (col == 0 ? -dx : dx), cy + (row - 1.5) * dy),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TermBraillePainter old) =>
      old.bits != bits || old.color != color || old.grid != grid;
}

/// Paints a bar of block elements across [size]: [value] of it in whole
/// eighths of a cell (`█▉▊▋▌▍▎▏`) in [color], each empty cell after it a
/// dot (`·`) in [track], so the cells left can be counted, as a terminal
/// draws a progress bar.
class TermBlocksPainter extends CustomPainter {
  /// A bar [value] full.
  const TermBlocksPainter({
    required this.grid,
    required this.value,
    required this.color,
    required this.track,
    this.textDirection = TextDirection.ltr,
  });

  /// The grid.
  final TermGrid grid;

  /// How full, 0 to 1; drawn to the nearest eighth of a cell.
  final double value;

  /// The blocks' colour.
  final Color color;

  /// The shade's colour.
  final Color track;

  /// Which way it fills.
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = grid.cellWidth;
    final h = grid.fontSize;
    final top = (size.height - h) / 2;
    final eighths = (size.width / cw * 8 * value.clamp(0, 1)).round();
    final filled = eighths * cw / 8;
    final rtl = textDirection == TextDirection.rtl;
    final cells = (size.width / cw + 1e-6).floor();
    final dot = Paint()..color = track;
    final radius = grid.fontSize / 15 * 1.5;
    for (var i = (filled / cw - 1e-6).ceil(); i < cells; i++) {
      final x = cw * i + cw / 2;
      canvas.drawCircle(
        Offset(rtl ? size.width - x : x, size.height / 2),
        radius,
        dot,
      );
    }
    if (filled > 0) {
      canvas.drawRect(
        rtl
            ? Rect.fromLTWH(size.width - filled, top, filled, h)
            : Rect.fromLTWH(0, top, filled, h),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(TermBlocksPainter old) =>
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.grid != grid ||
      old.textDirection != textDirection;
}
