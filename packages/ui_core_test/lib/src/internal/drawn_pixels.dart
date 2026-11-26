/// What the alignment and keyline checks read from a drawn frame. Internal
/// to ui_core_test's checks; not exported.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/rendering.dart';

/// A repaint boundary's pixels, drawn at [ratio] times its size, and the
/// colour most of them are: the face behind what is drawn on it.
class DrawnPixels {
  DrawnPixels._(this.width, this.height, this.ratio, this.bytes)
    : ground = _commonest(bytes, 0, 0, width, height, width);

  /// Draws [boundary] at [ratio] and reads it back. Takes real time: a test
  /// calls it under its tester's `runAsync`.
  static Future<DrawnPixels> of(
    RenderRepaintBoundary boundary,
    double ratio,
  ) async {
    final image = await boundary.toImage(pixelRatio: ratio);
    try {
      final data = await image.toByteData();
      return DrawnPixels._(image.width, image.height, ratio, data!);
    } finally {
      image.dispose();
    }
  }

  /// Whether [boundary] is in the frame: painted, its layer still in the
  /// tree the screen is composited from. One laid out where nothing paints
  /// it (a list's row past what the list shows, a part under a transparent
  /// opacity) never painted, or is painted no longer: nothing under it is on
  /// screen to read. Known only in a debug build (a test's); true otherwise.
  static bool inFrame(RenderRepaintBoundary boundary) {
    var shown = true;
    assert(() {
      shown = boundary.debugLayer?.attached ?? false;
      return true;
    }());
    return shown;
  }

  /// Reads [boundary] at [ratio] as [of] does, through [runAsync] (a
  /// tester's) when given. A boundary that repainted since the last frame
  /// (an image that decoded) is refused before reading, outside [runAsync],
  /// which would swallow the error.
  static Future<DrawnPixels> read(
    RenderRepaintBoundary boundary,
    double ratio,
    Future<T?> Function<T>(Future<T> Function() work)? runAsync,
  ) async {
    var unpainted = false;
    assert(() {
      unpainted = boundary.debugNeedsPaint;
      return true;
    }());
    if (unpainted) {
      throw StateError(
        'The screen changed while it was being read: something on it '
        'repainted after the last frame, most often an image that finished '
        'decoding. Decode the screen\'s images and pump before the check, '
        'as its documentation shows.',
      );
    }
    Future<DrawnPixels> draw() => of(boundary, ratio);
    final got = runAsync == null ? await draw() : await runAsync(draw);
    if (got == null) {
      throw StateError(
        'The screen could not be read: drawing it failed (the test reports '
        'why).',
      );
    }
    return got;
  }

  /// The image's size in pixels.
  final int width;

  /// The image's height in pixels.
  final int height;

  /// Pixels per logical pixel.
  final double ratio;

  /// The pixels, RGBA, row by row.
  final ByteData bytes;

  /// The commonest colour of the whole image.
  final int ground;

  final _solids = <(int, int, int, int), ({int colour, double share})>{};

  /// The commonest colour inside [rect] (logical, from the boundary's top
  /// left): the face of a card or a section.
  int groundIn(Rect rect) {
    final (left, top, right, bottom) = _span(rect);
    if (right <= left || bottom <= top) return ground;
    return _commonest(bytes, left, top, right, bottom, width);
  }

  /// The commonest colour inside [rect] (logical, from the boundary's top
  /// left) and the share of its pixels in it, 0 to 1: a surface of one
  /// colour, when that share is large.
  ({int colour, double share}) solidIn(Rect rect) {
    final bounds = _span(rect);
    if (_solids[bounds] case final cached?) return cached;
    final (left, top, right, bottom) = bounds;
    final all = (right - left) * (bottom - top);
    if (all <= 0) return (colour: ground, share: 0);
    final counts = <int, int>{};
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        final c = _at(x, y);
        counts[c] = (counts[c] ?? 0) + 1;
      }
    }
    final most = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    return _solids[bounds] = (colour: most.key, share: most.value / all);
  }

  /// The commonest colour inside [rect] (logical, from the boundary's top
  /// left), leaving out what is inside any of [except], colours a few steps
  /// apart counted together (a gentle gradient is one colour): the
  /// commonest of the commonest such run, and the share of the pixels read
  /// that are in it. Null when every pixel is left out.
  ({int colour, double share})? solidOutside(Rect rect, List<Rect> except) {
    final (left, top, right, bottom) = _span(rect);
    final holes = [for (final r in except) _span(r)];
    final runs = <int, int>{};
    final counts = <int, int>{};
    var all = 0;
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        if (_inAny(holes, x, y)) continue;
        final c = _at(x, y);
        runs[c & _run] = (runs[c & _run] ?? 0) + 1;
        counts[c] = (counts[c] ?? 0) + 1;
        all++;
      }
    }
    if (all == 0) return null;
    final run = runs.entries.reduce((a, b) => b.value > a.value ? b : a);
    final most = counts.entries
        .where((e) => e.key & _run == run.key)
        .reduce((a, b) => b.value > a.value ? b : a);
    return (colour: most.key, share: run.value / all);
  }

  // The channel bits colours a few steps apart share.
  static const _run = 0xE0E0E0E0;

  /// The commonest colour of each line of pixels across [rect] (logical,
  /// from the boundary's top left): each row with [rows], else each column,
  /// leaving out what is inside any of [except]. A line left out whole is
  /// read whole. A pixel [within] says no to (past a round face's shape) is
  /// not read; a line with none it keeps yields nothing.
  Iterable<int> lineGrounds(
    Rect rect, {
    required bool rows,
    List<Rect> except = const [],
    bool Function(int x, int y)? within,
  }) sync* {
    final (left, top, right, bottom) = _span(rect);
    final holes = [for (final r in except) _span(r)];
    final (lines, across) = rows
        ? ((top, bottom), (left, right))
        : ((left, right), (top, bottom));
    for (var a = lines.$1; a < lines.$2; a++) {
      final kept = <int, int>{};
      final whole = <int, int>{};
      for (var b = across.$1; b < across.$2; b++) {
        final (x, y) = rows ? (b, a) : (a, b);
        if (within != null && !within(x, y)) continue;
        final c = _at(x, y);
        whole[c] = (whole[c] ?? 0) + 1;
        if (!_inAny(holes, x, y)) kept[c] = (kept[c] ?? 0) + 1;
      }
      final counts = kept.isEmpty ? whole : kept;
      if (counts.isEmpty) continue;
      yield counts.entries.reduce((x, y) => y.value > x.value ? y : x).key;
    }
  }

  // Whether pixel [x], [y] is inside any of [holes] (in this image's
  // pixels).
  static bool _inAny(List<(int, int, int, int)> holes, int x, int y) {
    for (final (l, t, r, b) in holes) {
      if (x >= l && x < r && y >= t && y < b) return true;
    }
    return false;
  }

  /// The pixel at [x], [y] (logical, from the boundary's top left), RGBA;
  /// the image's [ground] outside it.
  int pixelAt(double x, double y) {
    final px = (x * ratio).floor(), py = (y * ratio).floor();
    if (px < 0 || py < 0 || px >= width || py >= height) return ground;
    return _at(px, py);
  }

  /// The commonest colour in a band [by] logical pixels wide around [rect]
  /// (logical, from the boundary's top left): what [rect] is drawn over,
  /// read where it is, so a gradient or a card under it counts. The
  /// image's [ground] when the band is outside the image.
  int groundAround(Rect rect, double by) {
    final (left, top, right, bottom) = _span(rect);
    final (l, t, r, b) = _span(rect.inflate(by));
    final counts = <int, int>{};
    for (var y = t; y < b; y++) {
      for (var x = l; x < r; x++) {
        if (x >= left && x < right && y >= top && y < bottom) continue;
        final c = _at(x, y);
        counts[c] = (counts[c] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return ground;
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  /// The smallest rectangle (logical, from the boundary's top left) holding
  /// the fill of [colour] that [rect] stands on: the pixels of that colour
  /// in the band a pixel round [rect], and every pixel reached from them a
  /// small step at a time (a gradient, a sheen), none further from [colour]
  /// than a quarter of a channel, without leaving [within]. What stands on
  /// the fill (words, an icon) is gone round, not through. Null when no
  /// pixel round [rect] is that colour.
  Rect? fillRound(Rect rect, Rect within, {required int colour}) {
    final (l, t, r, b) = _span(within);
    if (r <= l || b <= t) return null;
    final w = r - l;
    final seen = Uint8List(w * (b - t));
    final queue = <int>[];
    void seed(int x, int y) {
      if (x < l || x >= r || y < t || y >= b) return;
      final i = (y - t) * w + (x - l);
      if (seen[i] != 0 || !alike(_at(x, y), colour)) return;
      seen[i] = 1;
      queue.add(i);
    }

    final (il, it, ir, ib) = _span(rect);
    for (var x = il - 1; x <= ir; x++) {
      seed(x, it - 1);
      seed(x, ib);
    }
    for (var y = it; y < ib; y++) {
      seed(il - 1, y);
      seed(ir, y);
    }
    if (queue.isEmpty) return null;
    var minX = r, minY = b, maxX = l - 1, maxY = t - 1;
    for (var k = 0; k < queue.length; k++) {
      final i = queue[k];
      final x = l + i % w, y = t + i ~/ w;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
      final here = _at(x, y);
      for (final (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]) {
        if (nx < l || nx >= r || ny < t || ny >= b) continue;
        final j = (ny - t) * w + (nx - l);
        if (seen[j] != 0) continue;
        final c = _at(nx, ny);
        if (!alike(c, here, by: 10) || !alike(c, colour, by: 64)) continue;
        seen[j] = 1;
        queue.add(j);
      }
    }
    return Rect.fromLTRB(
      minX / ratio,
      minY / ratio,
      (maxX + 1) / ratio,
      (maxY + 1) / ratio,
    );
  }

  /// Whether two RGBA pixels look the same: no channel more than [by]
  /// apart.
  static bool alike(int a, int b, {int by = 8}) {
    for (var shift = 0; shift < 32; shift += 8) {
      if ((((a >> shift) & 0xFF) - ((b >> shift) & 0xFF)).abs() > by) {
        return false;
      }
    }
    return true;
  }

  /// The rows of [rect] (logical, from the boundary's top left) where
  /// something other than [over] (the image's [ground] by default) is
  /// drawn, in logical pixels; null when nothing is.
  ({double top, double bottom})? inkRows(Rect rect, {int? over}) {
    final face = over ?? ground;
    final (left, top, right, bottom) = _span(rect);
    int? first;
    int? last;
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        if (_differs(_at(x, y), face)) {
          first ??= y;
          last = y;
          break;
        }
      }
    }
    if (first == null) return null;
    return (top: first / ratio, bottom: (last! + 1) / ratio);
  }

  /// The smallest rectangle (logical, from the boundary's top left) holding
  /// what is drawn inside [rect] other than [over] (the image's [ground] by
  /// default), leaving out what is inside any of [except]; null when
  /// nothing is. A pixel is drawn when a channel stands more than [by] off
  /// [over]'s (a quarter of a channel's range by default, so an edge pixel
  /// a glyph barely touches is not). Given a contrast [floor] (as [outline]
  /// reads one), a pixel that reaches it is drawn too, however near [over]
  /// its channels are: a black edge on a dark ground. A pixel [within] says
  /// no to (past a round face's shape) is not read.
  Rect? inkIn(
    Rect rect, {
    int? over,
    List<Rect> except = const [],
    double? floor,
    bool Function(int x, int y)? within,
    int by = 64,
  }) {
    final face = over ?? ground;
    final faceLuminance = _luminance(face);
    bool drawnOn(int c) {
      if (!alike(c, face, by: by)) return true;
      if (floor == null) return false;
      final l = _luminance(c);
      return (math.max(l, faceLuminance) + 0.05) /
              (math.min(l, faceLuminance) + 0.05) >=
          floor;
    }

    final (left, top, right, bottom) = _span(rect);
    final holes = [for (final r in except) _span(r)];
    bool out(int x, int y) {
      for (final (l, t, r, b) in holes) {
        if (x >= l && x < r && y >= t && y < b) return true;
      }
      return false;
    }

    int? first;
    int? last;
    var minX = right;
    var maxX = left - 1;
    for (var y = top; y < bottom; y++) {
      var drawn = false;
      for (var x = left; x < right; x++) {
        if (within != null && !within(x, y)) continue;
        if (drawnOn(_at(x, y)) && !out(x, y)) {
          drawn = true;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
        }
      }
      if (drawn) {
        first ??= y;
        last = y;
      }
    }
    if (first == null) return null;
    final ink = Rect.fromLTRB(
      minX / ratio,
      first / ratio,
      (maxX + 1) / ratio,
      (last! + 1) / ratio,
    ).intersect(rect);
    return ink.isEmpty ? null : ink;
  }

  /// The top of what is drawn inside [rects] (logical, from the boundary's
  /// top left) other than [over], in this image's pixels and to a fraction
  /// of one: the first row drawn on, less the share of that row the ink
  /// covers (how far its pixel is from [over], against the furthest any
  /// pixel inside [rects] is: the ink's own colour). The highest of
  /// [rects]' tops; null when nothing stands out from [over].
  ///
  /// Each row is read from the ground [rects] are drawn on, the row of them
  /// nearest [over]: a face lit a little where its words are (a sheen, a
  /// gradient under them) is ground, not a faint ink across the whole row
  /// that would read as the glyphs' top.
  ///
  /// Given the [label] [rects] belong to (logical, from the boundary's top
  /// left), a row drawn on just past both its sides, every pixel there at
  /// least half as far from [over] as the row is inside [rects], is passed
  /// over: a rule drawn behind the label (a ruled page through an unfilled
  /// face), not its glyphs.
  ///
  /// With [edge], each row is read from its own commonest colour across
  /// [rects]: a band a face draws along its edge (an outline, a sheen, a
  /// gradient down it) is ground where it is drawn, and words drawn into it
  /// stand off it; and a pixel [within] says no to (past a round face's
  /// shape: the page in its corners) is neither ground nor ink.
  double? inkTopFine(
    List<Rect> rects, {
    required int over,
    Rect? label,
    bool edge = false,
    bool Function(int x, int y)? within,
  }) {
    assert(edge || within == null, 'within reads rows from their own ground');
    final spans = [for (final r in rects) _span(r)];
    final (ink, far) = edge
        ? _rowGroundedInk(spans, within)
        : _groundedInk(spans, over, label);
    if (far < 64) return null;
    double? best;
    for (final span in spans) {
      for (var y = span.$2; y < span.$4; y++) {
        final most = ink(span, y);
        // A sixteenth of the ink is where a glyph's edge starts.
        if (most * 16 > far) {
          final edge = y + 1 - most / far;
          if (best == null || edge < best) best = edge;
          break;
        }
      }
    }
    return best;
  }

  /// The bottom of what is drawn inside [rects] (logical, from the
  /// boundary's top left) other than [over], in this image's pixels and to
  /// a fraction of one, read as [inkTopFine] reads a top, a rule behind
  /// [label] passed over likewise, and each row read from its own ground
  /// likewise with [edge] (and [within] likewise): the lowest of [rects]'
  /// bottoms; null when nothing stands out from [over].
  double? inkBottomFine(
    List<Rect> rects, {
    required int over,
    Rect? label,
    bool edge = false,
    bool Function(int x, int y)? within,
  }) {
    assert(edge || within == null, 'within reads rows from their own ground');
    final spans = [for (final r in rects) _span(r)];
    final (ink, far) = edge
        ? _rowGroundedInk(spans, within)
        : _groundedInk(spans, over, label);
    if (far < 64) return null;
    double? best;
    for (final span in spans) {
      for (var y = span.$4 - 1; y >= span.$2; y--) {
        final most = ink(span, y);
        if (most * 16 > far) {
          final edge = y + most / far;
          if (best == null || edge > best) best = edge;
          break;
        }
      }
    }
    return best;
  }

  /// The colour (RGBA) of the image's pixel at [x], [y]; the image's
  /// [ground] outside it (an edge read a hair past the image's, as a face
  /// as large as the boundary is).
  int colourAt(int x, int y) =>
      x < 0 || y < 0 || x >= width || y >= height ? ground : _at(x, y);

  /// Whether [c] lies between colours [a] and [b], each channel within
  /// [by] of the span between theirs: a blend of the two (an outline's
  /// softened edge over the face it lies on).
  static bool between(int c, int a, int b, {int by = 8}) {
    for (var shift = 0; shift < 32; shift += 8) {
      final (v, x, y) = (
        (c >> shift) & 0xFF,
        (a >> shift) & 0xFF,
        (b >> shift) & 0xFF,
      );
      if (v < math.min(x, y) - by || v > math.max(x, y) + by) return false;
    }
    return true;
  }

  /// Which pixels of [rect] (logical) lie on a face its own painter draws
  /// round, with no shape to read it from: in each row, from where the face
  /// starts past [left] (the colour beyond its left edge, read in from that
  /// edge) and its softened edge or an outline round it (what is neither
  /// [face] nor that colour, up to [outline] logical pixels) to where it
  /// ends likewise before [right], and [inset] logical pixels in from those.
  /// A row whose face starts within a pixel of its box's edge (a straight
  /// side) is kept to that edge. Null when neither side is given.
  bool Function(int x, int y)? faceRuns(
    Rect rect, {
    required int face,
    int? left,
    int? right,
    required double inset,
    double outline = 8,
  }) {
    if (left == null && right == null) return null;
    final (l, t, r, b) = _span(rect);
    final step = (inset * ratio).ceil();
    final most = (outline * ratio).ceil();
    final runs = <int, (int, int)>{};
    // How far in from [from] (stepping by [by]) the face starts in row [y].
    int? start(int y, int from, int by, int past) {
      var x = from;
      bool inside(int x) => x >= l && x < r;
      while (inside(x) && alike(_at(x, y), past, by: 16)) {
        x += by;
      }
      if ((x - from).abs() <= 1) return null;
      final edge = x;
      while (inside(x) &&
          (x - edge).abs() < most &&
          !alike(_at(x, y), face, by: 16) &&
          !alike(_at(x, y), past, by: 16)) {
        x += by;
      }
      return x + by * step;
    }

    (int, int) runOf(int y) => runs[y] ??= (
      left == null ? l : start(y, l, 1, left) ?? l,
      right == null ? r - 1 : start(y, r - 1, -1, right) ?? r - 1,
    );
    return (x, y) {
      if (y < t || y >= b) return true;
      final (lo, hi) = runOf(y);
      return x >= lo && x <= hi;
    };
  }

  // How far each row of a span is drawn from that row's commonest colour
  // across [spans] (its ground there: a face's outline, a sheen, a
  // gradient), with the furthest any row is. A pixel [within] says no to
  // is neither ground nor ink. A span's row is read against the spans near
  // it (16 logical pixels either side): a gradient across a wide face is
  // ground where it is drawn, not ink at its far end.
  (int Function((int, int, int, int) span, int y), int) _rowGroundedInk(
    List<(int, int, int, int)> spans,
    bool Function(int x, int y)? within,
  ) {
    final reach = 16 * ratio;
    final near = {
      for (final s in spans)
        s: [
          for (final o in spans)
            if (o.$1 < s.$3 + reach && o.$3 > s.$1 - reach) o,
        ],
    };
    final grounds = <((int, int, int, int), int), int>{};
    int groundOf((int, int, int, int) span, int y) =>
        grounds[(span, y)] ??= () {
          final counts = <int, int>{};
          for (final (l, t, r, b) in near[span]!) {
            if (y < t || y >= b) continue;
            for (var x = l; x < r; x++) {
              if (within != null && !within(x, y)) continue;
              final c = _at(x, y);
              counts[c] = (counts[c] ?? 0) + 1;
            }
          }
          if (counts.isEmpty) return ground;
          return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
        }();

    int ink((int, int, int, int) span, int y) {
      final g = groundOf(span, y);
      var most = 0;
      for (var x = span.$1; x < span.$3; x++) {
        if (within != null && !within(x, y)) continue;
        most = math.max(most, _distance(_at(x, y), g));
      }
      return most;
    }

    var far = 0;
    for (final span in spans) {
      for (var y = span.$2; y < span.$4; y++) {
        far = math.max(far, ink(span, y));
      }
    }
    return (ink, far);
  }

  // [_rowInk] read from the ground [spans] are drawn on: less the ink of
  // their row nearest [over] (a sheen under words, a face lit a little
  // there, is no ink) when that row is ground (within a quarter of the
  // ink), with the furthest any row is from that ground.
  (int Function((int, int, int, int) span, int y), int) _groundedInk(
    List<(int, int, int, int)> spans,
    int over,
    Rect? label,
  ) {
    final raw = _rowInk(over, label);
    var far = 0;
    var floor = 255;
    for (final span in spans) {
      for (var y = span.$2; y < span.$4; y++) {
        final most = raw(span, y);
        far = math.max(far, most);
        floor = math.min(floor, most);
      }
    }
    // No row of ground (every row inked, as in a box cut to the glyphs):
    // read from [over], as drawn.
    if (floor * 4 > far) floor = 0;
    return ((span, y) => math.max(0, raw(span, y) - floor), far - floor);
  }

  // How far from [over] a row of a span (in this image's pixels) is drawn:
  // its furthest pixel, or none when a rule behind [label] (logical) draws
  // it: every pixel just past both of [label]'s sides, from a tenth to a
  // third of its height out, at least half as far from [over]. Unread past
  // the image's edge.
  int Function((int, int, int, int) span, int y) _rowInk(
    int over,
    Rect? label,
  ) {
    int most((int, int, int, int) span, int y) {
      var most = 0;
      for (var x = span.$1; x < span.$3; x++) {
        most = math.max(most, _distance(_at(x, y), over));
      }
      return most;
    }

    if (label == null) return most;
    final (near, out) = (label.height / 10, label.height / 3);
    final (leftFrom, leftTo) = (
      ((label.left - out) * ratio).floor(),
      ((label.left - near) * ratio).floor(),
    );
    final (rightFrom, rightTo) = (
      ((label.right + near) * ratio).ceil(),
      ((label.right + out) * ratio).ceil(),
    );
    if (leftFrom < 0 ||
        rightTo > width ||
        leftTo - leftFrom < 2 ||
        rightTo - rightFrom < 2) {
      return most;
    }
    int least(int from, int to, int y) {
      var least = 255;
      for (var x = from; x < to; x++) {
        least = math.min(least, _distance(_at(x, y), over));
      }
      return least;
    }

    final behind = <int, int>{};
    return (span, y) {
      final inside = most(span, y);
      if (inside == 0) return 0;
      final rule = behind[y] ??= math.min(
        least(leftFrom, leftTo, y),
        least(rightFrom, rightTo, y),
      );
      return rule * 2 >= inside ? 0 : inside;
    };
  }

  /// The outline of what is drawn inside [rect] (logical, from the
  /// boundary's top left) as a person sees it: bounded by the outermost rows
  /// and columns holding a pixel whose contrast with [over] (their relative
  /// luminances, each plus 0.05, the lighter over the darker) reaches
  /// [floor], leaving out what is inside any of [except] and, given a
  /// [shape] (logical, from the boundary's top left), every pixel whose
  /// middle is outside it: a shadow showing past a rounded corner. Each edge
  /// is read
  /// to a fraction of a pixel: a pixel the edge only partly covers counts
  /// for its share of the edge's own colour just inside it, and a faint band
  /// outside the edge (a ring with no contrast) does not. Null when no pixel
  /// reaches [floor].
  Rect? outline(
    Rect rect, {
    required int over,
    required double floor,
    List<Rect> except = const [],
    Path? shape,
  }) {
    final (left, top, right, bottom) = _span(rect);
    final w = right - left;
    final h = bottom - top;
    if (w <= 0 || h <= 0) return null;
    final holes = [for (final r in except) _span(r)];
    final ground = _luminance(over);
    final rowMost = List<int>.filled(h, 0);
    final colMost = List<int>.filled(w, 0);
    final rowOff = List<bool>.filled(h, false);
    final colOff = List<bool>.filled(w, false);
    for (var y = 0; y < h; y++) {
      final py = top + y;
      final (from, to) = _inside(shape, py, left, right);
      for (var x = from - left; x < to - left; x++) {
        final px = left + x;
        var hole = false;
        for (final (l, t, r, b) in holes) {
          if (px >= l && px < r && py >= t && py < b) {
            hole = true;
            break;
          }
        }
        if (hole) continue;
        final c = _at(px, py);
        final d = _distance(c, over);
        if (d == 0) continue;
        if (d > rowMost[y]) rowMost[y] = d;
        if (d > colMost[x]) colMost[x] = d;
        final l = _luminance(c);
        final ratio =
            (math.max(l, ground) + 0.05) / (math.min(l, ground) + 0.05);
        if (ratio >= floor) {
          rowOff[y] = true;
          colOff[x] = true;
        }
      }
    }
    final first = rowOff.indexOf(true);
    if (first < 0) return null;
    final ink = Rect.fromLTRB(
      (left + _edge(colMost, colOff.indexOf(true), 1)) / ratio,
      (top + _edge(rowMost, first, 1)) / ratio,
      (left + _edge(colMost, colOff.lastIndexOf(true), -1)) / ratio,
      (top + _edge(rowMost, rowOff.lastIndexOf(true), -1)) / ratio,
    ).intersect(rect);
    return ink.isEmpty ? null : ink;
  }

  // The pixels of row [py] from [left] to [right] whose middles are inside
  // [shape]: the first, and one past the last. The whole span without a
  // shape; none when the span's middle is not inside it. A face's shape is
  // convex (a rounded rectangle, a stadium, a circle), so each end is found
  // by halving. A pixel the edge crosses counts when it is mostly the
  // face's, read for its share by the edge's reading; one mostly outside
  // (a shadow past a rounded corner) does not.
  (int, int) _inside(Path? shape, int py, int left, int right) {
    if (shape == null) return (left, right);
    final y = (py + 0.5) / ratio;
    bool at(int px) => shape.contains(Offset((px + 0.5) / ratio, y));

    final mid = (left + right) ~/ 2;
    if (!at(mid)) return (mid, mid);
    var lo = left;
    var hi = mid;
    while (lo < hi) {
      final m = (lo + hi) ~/ 2;
      if (at(m)) {
        hi = m;
      } else {
        lo = m + 1;
      }
    }
    final from = lo;
    lo = mid;
    hi = right;
    while (lo < hi) {
      final m = (lo + hi) ~/ 2;
      if (at(m)) {
        lo = m + 1;
      } else {
        hi = m;
      }
    }
    return (from, lo);
  }

  // Where an edge falls, in pixels from the start of [most] (each line's
  // furthest pixel from the ground), given [i], the outermost line that
  // stands off, read going [inward] (1: a top or a left edge; -1: a bottom
  // or a right one). [i] and the line outside it count for their share of
  // the edge's colour (the furthest of [i] and the two lines inside it); the
  // line outside only when the one beyond it is clear by comparison, so a
  // faint band is not taken for a partly covered pixel.
  static double _edge(List<int> most, int i, int inward) {
    var far = 0;
    for (var k = 0; k < 3; k++) {
      final j = i + k * inward;
      if (j >= 0 && j < most.length) far = math.max(far, most[j]);
    }
    double share(int j) =>
        j < 0 || j >= most.length ? 0 : math.min(1, most[j] / far);
    final outside = share(i - inward);
    final beyond = share(i - 2 * inward);
    final covered = share(i) + (beyond * 4 < outside ? outside : 0);
    return inward > 0 ? i + 1 - covered : i + covered;
  }

  // Each 8-bit sRGB channel value, linear.
  static final List<double> _linear = [
    for (var i = 0; i < 256; i++)
      i / 255 <= 0.04045
          ? i / 255 / 12.92
          : math.pow((i / 255 + 0.055) / 1.055, 2.4).toDouble(),
  ];

  // An RGBA pixel's relative luminance (WCAG's), 0 to 1.
  static double _luminance(int c) =>
      0.2126 * _linear[(c >> 24) & 0xFF] +
      0.7152 * _linear[(c >> 16) & 0xFF] +
      0.0722 * _linear[(c >> 8) & 0xFF];

  /// Whether [face] is painted in its ground's colour, with a light cast
  /// immediately outside two edges and a dark cast outside their opposites.
  /// The transition into the fill identifies the face's edge on all four
  /// sides, even when the fill itself has no contrast against [over].
  bool hasRaisedOutline(Rect face, {required int over, required double floor}) {
    final image = Offset.zero & Size(width / ratio, height / ratio);
    if (face.shortestSide < 12 ||
        !image.contains(face.inflate(1).topLeft) ||
        !image.contains(face.inflate(1).bottomRight)) {
      return false;
    }
    final ground = _luminance(over);
    bool opposite(int a, int b) {
      if (alike(a, over, by: 2) || alike(b, over, by: 2)) return false;
      final first = _luminance(a), second = _luminance(b);
      final dark = math.min(first, second), light = math.max(first, second);
      return dark < ground &&
          light > ground &&
          (light + 0.05) / (dark + 0.05) >= floor;
    }

    for (final fraction in [0.25, 0.5, 0.75]) {
      final x = face.left + face.width * fraction;
      final y = face.top + face.height * fraction;
      if (!alike(pixelAt(x, face.top + 0.5), over, by: 2) ||
          !alike(pixelAt(x, face.bottom - 0.5), over, by: 2) ||
          !alike(pixelAt(face.left + 0.5, y), over, by: 2) ||
          !alike(pixelAt(face.right - 0.5, y), over, by: 2) ||
          !opposite(
            pixelAt(x, face.top - 0.5),
            pixelAt(x, face.bottom + 0.5),
          ) ||
          !opposite(
            pixelAt(face.left - 0.5, y),
            pixelAt(face.right + 0.5, y),
          )) {
        return false;
      }
    }
    return true;
  }

  /// Whether the rectangular face has a light top and left rim and a dark
  /// bottom and right rim. The two colours contrast across the bevel even
  /// when the dark rim is close to the surrounding [over] colour.
  bool hasBevel(Rect face, {required int over, required double floor}) {
    if (face.shortestSide < 12 ||
        face.left < 1 ||
        face.top < 1 ||
        face.right + 1 >= width / ratio ||
        face.bottom + 1 >= height / ratio) {
      return false;
    }
    int at(double x, double y) => _at((x * ratio).floor(), (y * ratio).floor());
    final light = at(face.center.dx, face.top + 0.5);
    final dark = at(face.center.dx, face.bottom - 0.5);
    final high = _luminance(light), low = _luminance(dark);
    if (alike(dark, over) ||
        low >= _luminance(over) ||
        (high + 0.05) / (low + 0.05) < floor) {
      return false;
    }
    for (final fraction in [0.25, 0.5, 0.75]) {
      final x = face.left + face.width * fraction;
      final y = face.top + face.height * fraction;
      // Both halves of the rim must have the same sharp edge. A flat fill
      // casting a dark shadow has no brighter rim just inside its top.
      if (!alike(at(x, face.top + 0.5), light) ||
          !alike(at(face.left + 0.5, y), light) ||
          !alike(at(x, face.bottom - 0.5), dark) ||
          !alike(at(face.right - 0.5, y), dark) ||
          !alike(at(x, face.bottom + 0.5), over) ||
          !alike(at(face.right + 0.5, y), over) ||
          high <= _luminance(at(x, face.top + 3))) {
        return false;
      }
    }
    return true;
  }

  /// Whether [rect] (logical, from the boundary's top left) is drawn mostly
  /// lighter than [over]: a face's highlight (a groove's lit side, too faint
  /// to stand off), not a shadow cast from it, which is darker. False when
  /// it is all [over].
  bool lit(Rect rect, {required int over}) {
    final (left, top, right, bottom) = _span(rect);
    final ground = _luminance(over);
    var lighter = 0;
    var darker = 0;
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        final c = _at(x, y);
        if (_distance(c, over) < 3) continue;
        if (_luminance(c) > ground) {
          lighter++;
        } else {
          darker++;
        }
      }
    }
    return lighter > 2 * darker;
  }

  /// Whether [rect] (logical, from the boundary's top left) is painted in
  /// [colour], a colour other than [over], however faintly it differs: nine
  /// in ten of the pixels wholly inside it alike [colour]. A face's own fill
  /// round a frame drawn inside it. False when no pixel is wholly inside
  /// [rect].
  bool paintedIn(Rect rect, {required int colour, required int over}) {
    if (alike(colour, over, by: 2)) return false;
    final left = math.max(0, (rect.left * ratio - 1e-6).ceil());
    final top = math.max(0, (rect.top * ratio - 1e-6).ceil());
    final right = math.min(width, (rect.right * ratio + 1e-6).floor());
    final bottom = math.min(height, (rect.bottom * ratio + 1e-6).floor());
    if (right <= left || bottom <= top) return false;
    var painted = 0;
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        if (alike(_at(x, y), colour)) painted++;
      }
    }
    return painted * 10 >= (right - left) * (bottom - top) * 9;
  }

  /// How much of [rect] (logical, from the boundary's top left) is drawn in
  /// something other than [over]: 0 to 1.
  double inkShare(Rect rect, {required int over}) {
    final (left, top, right, bottom) = _span(rect);
    final all = (right - left) * (bottom - top);
    if (all <= 0) return 0;
    var drawn = 0;
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        if (_differs(_at(x, y), over)) drawn++;
      }
    }
    return drawn / all;
  }

  // The most any channel (alpha too: the image is premultiplied) of two
  // RGBA pixels differs.
  static int _distance(int a, int b) {
    var most = 0;
    for (var shift = 0; shift < 32; shift += 8) {
      most = math.max(
        most,
        (((a >> shift) & 0xFF) - ((b >> shift) & 0xFF)).abs(),
      );
    }
    return most;
  }

  // Include every pixel the rectangle touches. A measured rectangle can use
  // only the part of an edge pixel inside the original logical bounds.
  (int, int, int, int) _span(Rect rect) => (
    (rect.left * ratio).floor().clamp(0, width),
    (rect.top * ratio).floor().clamp(0, height),
    (rect.right * ratio).ceil().clamp(0, width),
    (rect.bottom * ratio).ceil().clamp(0, height),
  );

  int _at(int x, int y) => bytes.getUint32((y * width + x) * 4);

  static int _commonest(
    ByteData bytes,
    int left,
    int top,
    int right,
    int bottom,
    int width,
  ) {
    final counts = <int, int>{};
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        final c = bytes.getUint32((y * width + x) * 4);
        counts[c] = (counts[c] ?? 0) + 1;
      }
    }
    var ground = 0;
    var most = -1;
    counts.forEach((c, n) {
      if (n > most) {
        most = n;
        ground = c;
      }
    });
    return ground;
  }

  // Whether two RGBA pixels differ by more than a quarter of a channel's
  // range: an edge pixel a glyph barely touches is not ink.
  static bool _differs(int a, int b) => !alike(a, b, by: 64);
}

/// Whether [reason] is a to-do rather than a reason: empty, or "TODO",
/// "not built yet" and the like.
bool isToDoReason(String reason) =>
    reason.trim().isEmpty ||
    RegExp(
      r'\b(todo|tbd|wip|fixme|coming soon)\b|\bnot (yet )?(built|done|implemented|ready|ported)\b|\bnot \w+ yet\b',
      caseSensitive: false,
    ).hasMatch(reason);
