part of '../alignment.dart';

/// Whether each control's label keeps clear of the edges of its face.
///
/// A face (a filled or outlined button, chip, tab or tile) holds its label
/// with room round it. Material's and Cupertino's controls keep at least
/// 4 px between their label's ink and their face's edges at every text size
/// from 1x to 3x (a `FilledButton`'s foot at 2x, under its descenders, and
/// a `SegmentedButton`'s side at 3x the least), and 6 px up to 1.3x. A face
/// drawn round its label alone (a `DecoratedBox` inside a [RawControlBox],
/// which centres it on the box's height, so the face hugs the line) has the
/// label's ink at its edges:
/// `a button "Apply": the ink of "Apply" is 1.3 px from the foot of its face
/// and 3.3 px from its top, closer than 4 px: pad the label inside the face`.
///
/// It holds each line of words a face shows, on a face that is filled (a
/// colour, a gradient, glass, a custom paint, a [RawKeylineFace]) or
/// outlined on every side; an underline, a rule on one side or a shadow
/// alone holds nothing in. Not a text entry's words (they scroll under its
/// edges), nor an icon, nor a count in a smaller face of its own, nor words
/// over or under a picture. Up and down it reads the ink of the label's
/// Latin letters and figures, descenders and ascenders with them (a
/// script's marks above and below, an accent, reach past where Latin
/// letters stand); side to side, the ink of all its words. The face's own
/// painting is not ink: a gradient or a sheen under the words is ground, and
/// a band drawn on past both their sides (a bevel along the edge) is passed
/// over, as [DesignLabelCheck] reads a label, and so is a band along the
/// face's edge across all their letters (its outline) that the face parts
/// from them. On a round face (a circle, a pill's ends, a clip's path) what
/// shows past its curve inside its box (the page in its corners, its
/// outline round the curve) is not ink either. The room is counted from the
/// face's outer edge, its outline with it: words drawn into an outline touch
/// it. Words across a face's top or foot by more than a quarter of their
/// line (a legend on a frame's outline) are the frame's, not held in by it,
/// and a face less than half their em high (a band drawn through them)
/// holds nothing in. Only the edges a face shows are read: an edge that
/// runs on into the face's colour (a text button on its page, a row on its
/// card, a field on the panel it is part of, a key drawn on past the box of
/// the tab over it) holds nothing in. A face its own painter draws reaches
/// the edge of the box that paints it where its painting runs on unbroken
/// to that edge (a ball's rim shaded toward the page, darker by night or
/// lighter by day), and words drawn over that rim are read there as over
/// the rest of the face; a soft shadow inside that box, fading into the
/// page, is not the face. One it draws only a little off what is round it,
/// out to every edge of its box (a plate a few levels off its page, or
/// outlined in a tone near it), is that box, not the stronger ink drawn on
/// it (a chevron, an avatar's ball, a key), and the ink a label's letters
/// draw past their line's box (a script's marks and tails) is the label's.
/// Only a face the screen shows whole is read; one a scroll or a clip cuts,
/// or that a box painted after it covers right across (a bar over an
/// avatar a list scrolls under it), is read when it comes into view. It
/// reads the drawn pixels. A test passes its tester's `runAsync`:
///
/// ```dart
/// final report = await const DesignFaceInsetCheck(look: 'Comic').check(
///   tester.element(find.byType(SettingsScreen)),
///   runAsync: tester.runAsync,
/// );
/// report.verify();
/// ```
@immutable
class DesignFaceInsetCheck {
  /// A check for [look].
  const DesignFaceInsetCheck({
    required this.look,
    this.minimum = 4,
    this.pixelRatio = 3,
  });

  /// The look's name, for messages.
  final String look;

  /// The least room, in logical pixels, a label's ink keeps from each edge
  /// of its face (a device pixel's half less is let pass): 4, the least
  /// Material's and Cupertino's controls keep.
  final double minimum;

  /// The scale the screen is drawn at to read its pixels.
  final double pixelRatio;

  /// Checks every control under [context] (on screen, under a repaint
  /// boundary as every route is). A test passes its tester's `runAsync`
  /// (reading pixels takes real time); null reads them directly.
  Future<DesignAlignmentReport> check(
    BuildContext context, {
    Future<T?> Function<T>(Future<T> Function() work)? runAsync,
  }) async {
    final root = context.findRenderObject();
    if (root == null) return DesignAlignmentReport(look, const []);
    final marked = _markedFaces(context);
    final (:held, marks: _, :entries) = _controlsIn(root);
    final pixels = <RenderRepaintBoundary, DrawnPixels>{};
    final labels = DesignLabelCheck(look: look, pixelRatio: pixelRatio);
    final found = <String>[];
    final fallback = <String>[];
    for (final MapEntry(key: control, value: texts) in held.entries) {
      if (texts.isEmpty || entries.contains(control)) continue;
      final boundary = _drawnIn(control);
      if (boundary == null) continue;
      final drawn = pixels[boundary] ??= await DrawnPixels.read(
        boundary,
        pixelRatio,
        runAsync,
      );
      final reader = _FaceReader(labels, boundary, drawn, marked);
      found.addAll(reader._insets(control, texts, minimum));
      fallback.addAll(reader.fallback);
    }
    if (fallback.isNotEmpty) {
      return DesignAlignmentReport(look, [_testFontProblem(fallback)]);
    }
    return DesignAlignmentReport(look, found);
  }
}

extension on _LabelReader {
  // Each of [texts] on [control]'s face, filled or outlined all round, whose
  // ink comes closer than [minimum] to one of the face's edges.
  List<String> _insets(
    RenderBox control,
    List<RenderBox> texts,
    double minimum,
  ) {
    final face = _face(control);
    if (face == null || !_holdsIn(face.box)) return const [];
    final rim = face.read ? _withRim(control, face.box, face.rect) : null;
    final faceRect = rim?.rect ?? face.rect;
    // Only a face the screen shows whole: one a scroll or a clip cuts, or
    // past the screen's edge, is read when a walk brings it into view. A
    // face read from its pixels shows only up to the cut, so it is cut too
    // where it ends at the clip and the box it is painted in runs on past.
    final clip = _clipOf(control, throughScrolls: true);
    if (clip != null &&
        _cutBy(
          clip.inflate(0.5),
          faceRect,
          face.read ? _paintedIn(control, face.box, faceRect) : faceRect,
        )) {
      return const [];
    }
    final shown = [
      for (final t in texts)
        if (t is RenderParagraph &&
            !isIconGlyph(_LabelReader._plain(t)) &&
            _onFace(t, faceRect) &&
            !_inBadge(t, control, face.box, faceRect) &&
            !_byPicture(control, _global(t)) &&
            !_thinFor(t, faceRect) &&
            !_acrossEdge(t, faceRect))
          t,
    ];
    if (shown.isEmpty) return const [];
    final p = pixels!;
    final f = _toBoundary(faceRect);
    // Read inside the face's own stroke, where a label is drawn.
    final inner = _strokeOf(face.box).deflateRect(f);
    final boxes = [for (final t in shown) _toBoundary(_global(t))];
    // Where its words' letters stand: each line's own box (a short line
    // centred over a longer one leaves the face beside it).
    final lines = [
      for (final t in shown)
        for (final b in lineBoxes(
          t,
          TextSelection(baseOffset: 0, extentOffset: lineText(t).length),
        ))
          MatrixUtils.transformRect(t.getTransformTo(boundary), b.toRect()),
    ];
    // The face's own colour, read inside its stroke round its words' lines
    // (words drawn in solid boxes over most of it are not its colour; the
    // whole face when they cover it): its commonest colour there when it is
    // one colour; else (a gradient, a pane of glass) the colour just round
    // the words, on the face.
    final all = _toBoundary(
      shown.map(_global).reduce((a, b) => a.expandToInclude(b)),
    );
    final rest =
        p.solidOutside(inner, lines) ?? p.solidOutside(inner, const []);
    final faceColour = switch (rest) {
      null => _faceGround(
        _strokeOf(face.box).deflateRect(faceRect),
        shown.map(_global).reduce((a, b) => a.expandToInclude(b)),
      ),
      (:final colour, :final share) when share >= 0.5 => colour,
      (:final colour, share: _) =>
        p.solidOutside(all.inflate(2).intersect(inner), [all])?.colour ??
            colour,
    };
    // Its stroke: where its decoration says, else as its pixels show (an
    // outline its own painter draws); its words are read inside it.
    final stroke = _strokeRead(face.box, f, faceColour);
    final held = stroke.deflateRect(f);
    // Where it is drawn along each row, when it is drawn round inside its
    // box (a circle, a pill's ends, filled or outlined): what shows past it
    // there (the page in its corners) is not one of the edges it shows.
    final strokes = _strokeOf(face.box);
    final inset =
        math.max(
          math.max(strokes.left, strokes.right),
          math.max(strokes.top, strokes.bottom),
        ) +
        1;
    final pastLeft = p.solidOutside(_pastLeft(f), const [])?.colour;
    final pastRight = p.solidOutside(_pastRight(f), const [])?.colour;
    // A side its painter draws (its fill, or an outline round it, at the
    // box's edge on the face's middle row, unlike what is past it), read
    // in from what is past it; a side that runs on into what is past it
    // is not.
    int? drawn(int? past, {required bool left}) {
      if (past == null) return null;
      final y = (f.center.dy * p.ratio).floor();
      final x = ((left ? f.left : f.right) * p.ratio).floor() - (left ? 0 : 1);
      final at = [x, x + (left ? 1 : -1)];
      return at.any((x) => !DrawnPixels.alike(p.colourAt(x, y), past, by: 16))
          ? past
          : null;
    }

    final sideLeft = drawn(pastLeft, left: true);
    final sideRight = drawn(pastRight, left: false);
    final edges = p.faceRuns(
      f,
      face: faceColour,
      left: sideLeft,
      right: sideRight,
      inset: inset,
    );
    // The edges the face shows: where the line it draws along the edge (its
    // colour, an outline, a bevel), or the face a little further in (past a
    // rim of the page's colour), stands off what is just past it. An edge
    // that runs on into the face's colour (a text button on its page, a row
    // on its card, a field on the panel it is part of, a gradient drawn on
    // past its box) holds nothing in there; a face that shows none is not
    // read. The screen's own edge is an edge.
    bool shows(Rect edge, Rect inward, Rect past, {required bool rows}) {
      final beyond = p.solidOutside(past, const [])?.colour;
      if (beyond == null) return true;
      bool off(Rect line) => p
          .lineGrounds(line, rows: rows, except: boxes, within: edges)
          .any((c) => !DrawnPixels.alike(c, beyond, by: 4));
      return off(edge) || off(inward);
    }

    final showsTop = shows(
      Rect.fromLTRB(f.left, f.top, f.right, f.top + 1),
      Rect.fromLTRB(f.left, f.top + 3, f.right, f.top + 4),
      Rect.fromLTRB(f.left, f.top - 2, f.right, f.top - 1),
      rows: true,
    );
    final showsFoot = shows(
      Rect.fromLTRB(f.left, f.bottom - 1, f.right, f.bottom),
      Rect.fromLTRB(f.left, f.bottom - 4, f.right, f.bottom - 3),
      Rect.fromLTRB(f.left, f.bottom + 1, f.right, f.bottom + 2),
      rows: true,
    );
    final showsLeft = shows(
      Rect.fromLTRB(f.left, f.top, f.left + 1, f.bottom),
      Rect.fromLTRB(f.left + 3, f.top, f.left + 4, f.bottom),
      _pastLeft(f),
      rows: false,
    );
    final showsRight = shows(
      Rect.fromLTRB(f.right - 1, f.top, f.right, f.bottom),
      Rect.fromLTRB(f.right - 4, f.top, f.right - 3, f.bottom),
      _pastRight(f),
      rows: false,
    );
    if (!showsTop && !showsFoot && !showsLeft && !showsRight) {
      return const [];
    }
    // Its words are read inside its own shape, where that is not its box (a
    // circle, a pill's ends, a clip's path): what shows past it inside the
    // box (the page in its corners, its outline round a curve) is neither
    // its colour nor ink. One its own painter draws round (no shape to read
    // it from) is read inside the run it paints along each row, past an
    // outline round it there too (an outlined face on a page of its colour).
    // Over a rim it runs on to its box's edge with, its face is what
    // stands off what is round it there.
    final read = _overRim(
      _shapeOf(face.box, stroke, f, ink: faceColour) ??
          p.faceRuns(
            f,
            face: faceColour,
            left: sideLeft,
            right: sideRight,
            inset: inset,
          ),
      rim == null ? f : _toBoundary(face.rect),
      f,
      round: rim?.round,
      inset: inset,
    );
    final name = _nameOf(control);
    for (final t in shown) {
      if (_testFontBox(t, faceColour) || _testFontLetter(t, faceColour)) {
        fallback.add(name);
        return const [];
      }
    }
    final least = minimum - 0.5 / p.ratio;
    final found = <String>[];
    for (final t in shown) {
      final words = _wordsBox(t);
      if (words == null) continue;
      // Side to side, inside the strokes over and under the words but up to
      // the face's edge: words drawn into its outline at a side touch it.
      final side = p.inkIn(
        words.intersect(Rect.fromLTRB(f.left, held.top, f.right, held.bottom)),
        over: faceColour,
        within: read,
      );
      if (side == null) continue;
      // Up and down, its Latin letters' and figures' ink, inside the line
      // it is laid out on and the face, read as DesignLabelCheck reads a
      // label's capitals: a sheen or a gradient on the face is ground, a
      // band drawn on past both sides of the words (a bevel along the face's
      // edge, a rule behind them) is not their ink, nor is a band along the
      // face's edge across all their letters (its outline) that the face
      // parts from them.
      final own = _toBoundary(_global(t)).intersect(held);
      final columns = [
        for (final c in _columns(t, _latin, 0, t.size.height))
          if (Rect.fromLTRB(c.left, own.top, c.right, own.bottom)
              case final column when !column.isEmpty)
            column,
      ];
      // (The fine readers answer in the image's pixels.)
      final topPx = columns.isEmpty || !showsTop
          ? null
          : p.inkTopFine(
              columns,
              over: faceColour,
              label: words,
              edge: true,
              within: read,
            );
      final bottomPx = columns.isEmpty || !showsFoot
          ? null
          : p.inkBottomFine(
              columns,
              over: faceColour,
              label: words,
              edge: true,
              within: read,
            );
      final top = topPx == null ? null : topPx / p.ratio;
      final bottom = bottomPx == null ? null : bottomPx / p.ratio;
      final room = <(String, double)>[
        if (top != null) ('top', top - f.top),
        if (bottom != null) ('foot', f.bottom - bottom),
        if (showsLeft) ('left side', side.left - f.left),
        if (showsRight) ('right side', f.right - side.right),
      ];
      final short = [
        for (final (edge, gap) in room)
          if (gap < least) (edge, gap),
      ]..sort((a, b) => a.$2.compareTo(b.$2));
      if (short.isEmpty) continue;
      final at = [
        for (final (i, (edge, gap)) in short.indexed)
          '${_px(math.max(gap, 0))} px from ${i == 0 ? 'the $edge of its face' : 'its $edge'}',
      ].join(' and ');
      found.add(
        '$name: the ink of "${_LabelReader._short(_LabelReader._plain(t))}" is $at, closer than '
        '${_px(minimum)} px: pad the label inside the face',
      );
    }
    // Only a face the screen shows whole: one a box painted after it covers
    // right across is read when it comes clear (read last, as it walks the
    // whole frame).
    if (found.isNotEmpty && _coveredAcross(control, face.box, faceRect)) {
      return const [];
    }
    return found;
  }

  // Whether a box painted after [control], outside it, covers [face] (the
  // box that paints it, with [read], the face read from it) right across but
  // not whole (a bar a list scrolls an avatar half under): what shows of the
  // face ends at that box's edge, not its own.
  bool _coveredAcross(RenderBox control, RenderBox face, Rect read) {
    final whole = _global(face).expandToInclude(read);
    var covered = false;
    void visit(RenderObject n) {
      if (covered || identical(n, control)) return;
      if (n is RenderBox && n.hasSize && _hides(n)) {
        final r = _global(n);
        final over = r.intersect(whole);
        final across =
            (over.left <= whole.left + 0.5 &&
                over.right >= whole.right - 0.5) ||
            (over.top <= whole.top + 0.5 && over.bottom >= whole.bottom - 0.5);
        final all =
            r.left <= whole.left + 0.5 &&
            r.top <= whole.top + 0.5 &&
            r.right >= whole.right - 0.5 &&
            r.bottom >= whole.bottom - 0.5;
        if (over.width > 0.5 &&
            over.height > 0.5 &&
            across &&
            !all &&
            _paintedOver(control, n, over.center)) {
          covered = true;
          return;
        }
      }
      _visitShown(n, visit);
    }

    if (boundary case final b?) visit(b);
    return covered;
  }

  // Whether [t]'s words are drawn in the test's fallback font, read letter
  // by letter (words wrapped, or narrower than the box they are laid out
  // in): one of its first Latin letters or figures drawn as a solid box,
  // filling its place across and an em down, which no typeface draws.
  bool _testFontLetter(RenderParagraph t, int faceColour) {
    final p = pixels!;
    if (t.size.height <= 0) return false;
    final text = lineText(t);
    final em =
        labelFontSize(t) * _toBoundary(_global(t)).height / t.size.height;
    final toBoundary = t.getTransformTo(boundary);
    var read = 0;
    for (var i = 0; i < text.length && read < 8; i++) {
      if (!_latin.contains(text[i])) continue;
      read++;
      final boxes = lineBoxes(
        t,
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      if (boxes.isEmpty) continue;
      final place = MatrixUtils.transformRect(toBoundary, boxes.first.toRect());
      final ink = p.inkIn(place, over: faceColour);
      if (ink != null &&
          ink.width >= place.width * 0.9 &&
          ink.height >= em * 0.9 &&
          p.inkShare(ink, over: faceColour) >= 0.9) {
        return true;
      }
    }
    return false;
  }

  // [read], the face its own painter draws in [box] as its pixels show it
  // ([_face]: where they stand well off what is round it), with a rim it
  // shades or lights toward that colour (a clay ball's shade at its end and
  // foot by night, its lit start by day): in some row (or column) every
  // pixel from [read]'s edge out to the edge of the box it is painted in
  // ([_paintedIn]) stands off what is round it, so the face runs on to that
  // box's edge there. A soft shadow a painter casts inside its box, faded
  // into what is round it before the box's edge, is not the face. With the
  // colour round that box.
  ({Rect rect, int round}) _withRim(
    RenderBox control,
    RenderBox box,
    Rect read,
  ) {
    final p = pixels!;
    final whole = _toBoundary(_paintedIn(control, box, read));
    final f = _toBoundary(read);
    final round = p.groundAround(whole, 2);
    int px(double v) => (v * p.ratio).round();
    bool off(int x, int y) =>
        !DrawnPixels.alike(p.colourAt(x, y), round, by: 16);
    // Whether, in one of the lines [across], every pixel from [from] to [to]
    // (stepping by [by]) stands off what is round the face: along rows when
    // [rows], else along columns. False when [read] already reaches the box.
    bool reaches(
      int from,
      int to,
      int by,
      List<int> across, {
      required bool rows,
    }) {
      if ((to - from) * by < 0) return false;
      for (final a in across) {
        var x = from;
        while (rows ? off(x, a) : off(a, x)) {
          if (x == to) return true;
          x += by;
        }
      }
      return false;
    }

    final (l, t, r, b) = (px(f.left), px(f.top), px(f.right), px(f.bottom));
    final rows = [for (var y = t; y < b; y++) y];
    final columns = [for (var x = l; x < r; x++) x];
    final local = Rect.fromLTRB(
      reaches(l - 1, px(whole.left), -1, rows, rows: true)
          ? whole.left
          : f.left,
      reaches(t - 1, px(whole.top), -1, columns, rows: false)
          ? whole.top
          : f.top,
      reaches(r, px(whole.right) - 1, 1, rows, rows: true)
          ? whole.right
          : f.right,
      reaches(b, px(whole.bottom) - 1, 1, columns, rows: false)
          ? whole.bottom
          : f.bottom,
    );
    return (
      rect: local == f
          ? read
          : MatrixUtils.transformRect(boundary!.getTransformTo(null), local),
      round: round,
    );
  }

  // [read], widened over the rim [_withRim] read a face to (from [inner],
  // where its own colour shows, out to [f], its box's edge; both in the
  // boundary's logical pixels): along each row of a rim at its top or foot,
  // and each column of one at its side, the face is drawn where it stands
  // off [round], the colour round it, read [inset] in from where it starts
  // and ends. Words drawn on a ball's shaded foot are on its face, and their
  // ink is read there. [read] alone where the face has no rim.
  bool Function(int x, int y)? _overRim(
    bool Function(int x, int y)? read,
    Rect inner,
    Rect f, {
    required int? round,
    required double inset,
  }) {
    if (read == null || round == null || inner == f) return read;
    final p = pixels!;
    final step = (inset * p.ratio).ceil();
    final (l, t, r, b) = (
      (f.left * p.ratio).floor(),
      (f.top * p.ratio).floor(),
      (f.right * p.ratio).ceil(),
      (f.bottom * p.ratio).ceil(),
    );
    final (il, it, ir, ib) = (
      (inner.left * p.ratio).ceil(),
      (inner.top * p.ratio).ceil(),
      (inner.right * p.ratio).floor(),
      (inner.bottom * p.ratio).floor(),
    );
    bool off(int x, int y) =>
        !DrawnPixels.alike(p.colourAt(x, y), round, by: 16);
    // The first and last of [from]..[to] (stepping by one) where [at] is
    // off, each [step] further in; an empty run where none is.
    (int, int) runOf(int from, int to, bool Function(int i) at) {
      var lo = from;
      while (lo < to && !at(lo)) {
        lo++;
      }
      var hi = to - 1;
      while (hi >= lo && !at(hi)) {
        hi--;
      }
      return hi < lo ? (1, 0) : (lo + step, hi - step);
    }

    final rows = <int, (int, int)>{};
    final columns = <int, (int, int)>{};
    return (x, y) {
      if (read(x, y)) return true;
      if (x < l || x >= r || y < t || y >= b) return false;
      if (y < it || y >= ib) {
        final (lo, hi) = rows[y] ??= runOf(l, r, (x) => off(x, y));
        return x >= lo && x <= hi;
      }
      if (x < il || x >= ir) {
        final (lo, hi) = columns[x] ??= runOf(t, b, (y) => off(x, y));
        return y >= lo && y <= hi;
      }
      return false;
    };
  }

  // The box [read] is painted in, in global coordinates: the smallest box
  // in [control] (short of another control) that paints a face and holds
  // [read] whole (a ball on a row, or drawn over it, whose own plate draws
  // nothing that stands off), else [face]'s own.
  Rect _paintedIn(RenderBox control, RenderBox face, Rect read) {
    var best = _global(face);
    bool holds(Rect r) =>
        read.left >= r.left - 0.5 &&
        read.top >= r.top - 0.5 &&
        read.right <= r.right + 0.5 &&
        read.bottom <= r.bottom + 0.5;
    void visit(RenderObject n) {
      if (n is RenderParagraph || n is RenderEditable || _isControl(n)) return;
      if (n is RenderBox && n.hasSize && _showsFace(n)) {
        final r = _global(n);
        if (holds(r) && r.width * r.height < best.width * best.height) {
          best = r;
        }
      }
      _visitShown(n, visit);
    }

    _visitShown(control, visit);
    return best;
  }

  // Whether [c] is a stroke's softened edge over a face: a blend of the
  // face's colour and the stroke's, like neither.
  static bool _softened(int c, int face, int stroke) =>
      DrawnPixels.between(c, face, stroke) &&
      !DrawnPixels.alike(c, face, by: 4) &&
      !DrawnPixels.alike(c, stroke, by: 4);

  // The strips just past [f]'s left and right sides.
  static Rect _pastLeft(Rect f) =>
      Rect.fromLTRB(f.left - 2, f.top, f.left - 1, f.bottom);
  static Rect _pastRight(Rect f) =>
      Rect.fromLTRB(f.right + 1, f.top, f.right + 2, f.bottom);

  // Whether [face] is too thin to hold [t]'s words: less than half their
  // em high (a band drawn through them, a marker under them).
  bool _thinFor(RenderParagraph t, Rect face) {
    if (t.size.height <= 0) return true;
    final em = labelFontSize(t) * _global(t).height / t.size.height;
    return face.height < em / 2;
  }

  // Whether [t]'s words sit across one of [face]'s edges by design (a
  // legend on a frame's outline, in a gap cut for it; a day's number on a
  // range's band, centred on the day's circle at its end): more than a
  // quarter of their line past that edge, the opposite edge clear inside.
  bool _acrossEdge(RenderParagraph t, Rect face) {
    final words = _global(t);
    final (high, wide) = (words.height / 4, words.width / 4);
    return (face.top - words.top > high && words.bottom < face.bottom) ||
        (words.bottom - face.bottom > high && words.top > face.top) ||
        (face.left - words.left > wide && words.right < face.right) ||
        (words.right - face.right > wide && words.left > face.left);
  }

  // Which of the image's pixels inside [f] (the face's box, in the
  // boundary's logical pixels) lie inside the face's own shape, where that
  // is not its box: the shape [face], a box round it its size, or a box its
  // size inside it draws or clips to (a decoration's circle or rounded
  // corners, a clip's rounded rect, oval or path), held [stroke] and a
  // pixel more inside it, so its outline round a curve is left out too.
  // Each row is one run, read as far in from the box's edges: along a
  // straight edge every pixel is kept (the stroke, and words drawn into it,
  // are read as before). Where a straight top or foot starts to curve, the
  // stroke's softened edge over the face's colour [ink] is left out too.
  // Null when the face is its box.
  bool Function(int x, int y)? _shapeOf(
    RenderBox face,
    EdgeInsets stroke,
    Rect f, {
    required int ink,
  }) {
    final p = pixels!;
    final own = _global(face);
    bool same(RenderBox b) {
      final r = _global(b);
      return (r.left - own.left).abs() <= 1 &&
          (r.top - own.top).abs() <= 1 &&
          (r.right - own.right).abs() <= 1 &&
          (r.bottom - own.bottom).abs() <= 1;
    }

    final tests = <bool Function(Offset)>[];
    void add(RenderBox b) {
      final contains = _shapeTest(b);
      final back = Matrix4.tryInvert(b.getTransformTo(boundary));
      if (contains == null || back == null) return;
      tests.add((o) => contains(MatrixUtils.transformPoint(back, o)));
    }

    for (RenderObject? n = face; n is RenderBox && same(n); n = n.parent) {
      add(n);
      if (_isControl(n)) break;
    }
    void visit(RenderObject n) {
      if (n is RenderParagraph || n is RenderEditable || _isControl(n)) return;
      if (n is RenderBox && n.hasSize && same(n)) add(n);
      _visitShown(n, visit);
    }

    _visitShown(face, visit);
    if (tests.isEmpty) return null;
    final d =
        math.max(
          math.max(stroke.left, stroke.right),
          math.max(stroke.top, stroke.bottom),
        ) +
        1;
    final inside = f.deflate(d + 0.25);
    if (inside.isEmpty) return null;
    const rays = [
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, 1),
      Offset(0, -1),
      Offset(0.7071, 0.7071),
      Offset(-0.7071, 0.7071),
      Offset(0.7071, -0.7071),
      Offset(-0.7071, -0.7071),
    ];
    bool held(Offset o) =>
        tests.every((test) => rays.every((r) => test(o + r * d)));
    bool shape(Offset o) => tests.every((test) => test(o));
    final s = d - 1;
    bool past(Offset o) =>
        tests.every((test) => rays.every((r) => test(o + r * s)));
    // Along a straight top (or foot), the columns where the face starts to
    // curve away from it (a round corner, a pill's end) within a stroke of
    // that line: there its outline dips a fraction of a pixel below the
    // stroke along the straight part, so in rows above the stroke's inner
    // curve and a pixel of its softening, a blend of the stroke's colour and
    // the face's is not ink; words there, and under it, are read as before.
    // The limit is the edge itself where nothing is.
    final tops = <int, double>{};
    final foots = <int, double>{};
    // The colour of the stroke along the straight top (or foot), at its
    // middle; the page's just past it when there is no stroke.
    final strokes = <bool, int>{};
    int strokeAt({required bool top}) => strokes[top] ??= p.colourAt(
      (f.center.dx * p.ratio).floor(),
      ((top
                  ? f.top + s / 2 - (s == 0 ? 1 : 0)
                  : f.bottom - s / 2 + (s == 0 ? 1 : 0)) *
              p.ratio)
          .floor(),
    );
    double curve(int x, {required bool top}) => (top ? tops : foots)[x] ??= () {
      final edge = top ? f.top : f.bottom;
      final inward = top ? 1e-3 : -1e-3;
      final cx = (x + 0.5) / p.ratio;
      final mid = f.center.dy;
      if (!shape(Offset(f.center.dx - 2, edge + inward)) ||
          !shape(Offset(f.center.dx + 2, edge + inward)) ||
          !shape(Offset(cx, mid)) ||
          shape(Offset(cx, edge + inward))) {
        return edge;
      }
      double search(bool Function(Offset) holds) {
        var (a, b) = (mid, edge);
        for (var i = 0; i < 12; i++) {
          final m = (a + b) / 2;
          if (holds(Offset(cx, m))) {
            a = m;
          } else {
            b = m;
          }
        }
        return a;
      }

      if ((search(shape) - edge).abs() >= s + 1 / p.ratio) return edge;
      final inner = search(past);
      return top ? inner + 1 / p.ratio : inner - 1 / p.ratio;
    }();
    final runs = <int, (double, double)>{};
    (double, double) runOf(int y) => runs[y] ??= () {
      final cy = ((y + 0.5) / p.ratio).clamp(inside.top, inside.bottom);
      bool at(double x) => held(Offset(x, cy));
      final mid = inside.center.dx;
      // A row whose middle is not inside (a ring, a notch) is kept whole.
      if (!at(mid)) return (double.negativeInfinity, double.infinity);
      double toward(double outside) {
        var (a, b) = (mid, outside);
        for (var i = 0; i < 10; i++) {
          final m = (a + b) / 2;
          if (at(m)) {
            a = m;
          } else {
            b = m;
          }
        }
        return a;
      }

      return (
        at(inside.left) ? double.negativeInfinity : toward(inside.left),
        at(inside.right) ? double.infinity : toward(inside.right),
      );
    }();
    return (x, y) {
      final cy = (y + 0.5) / p.ratio;
      if (cy < inside.top) {
        if (cy < curve(x, top: true) &&
            _softened(p.colourAt(x, y), ink, strokeAt(top: true))) {
          return false;
        }
      } else if (cy > inside.bottom) {
        if (cy > curve(x, top: false) &&
            _softened(p.colourAt(x, y), ink, strokeAt(top: false))) {
          return false;
        }
      }
      final (lo, hi) = runOf(y);
      final cx = ((x + 0.5) / p.ratio).clamp(inside.left, inside.right);
      return cx >= lo && cx <= hi;
    };
  }

  // Whether a point (in [b]'s own logical pixels) is inside the shape [b]
  // draws or clips to; null when that is its box.
  static bool Function(Offset)? _shapeTest(RenderBox b) {
    final size = b.size;
    final box = Offset.zero & size;
    bool Function(Offset) within(bool Function(Offset) test) =>
        (o) => box.contains(o) && test(o);
    bool Function(Offset) oval(Rect r) => (o) {
      if (r.isEmpty) return false;
      final dx = (o.dx - r.center.dx) / (r.width / 2);
      final dy = (o.dy - r.center.dy) / (r.height / 2);
      return dx * dx + dy * dy <= 1;
    };
    return switch (b) {
      RenderDecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: null,
        ),
      ) =>
        null,
      RenderDecoratedBox(:final decoration, :final configuration) => within(
        (o) => decoration.hitTest(
          size,
          o,
          textDirection: configuration.textDirection,
        ),
      ),
      RenderClipRRect(
        :final clipper,
        :final borderRadius,
        :final textDirection,
      ) =>
        within(
          (clipper?.getClip(size) ??
                  borderRadius.resolve(textDirection).toRRect(box))
              .contains,
        ),
      RenderClipRSuperellipse(
        :final clipper,
        :final borderRadius,
        :final textDirection,
      ) =>
        within(
          (clipper?.getClip(size) ??
                  borderRadius.resolve(textDirection).toRSuperellipse(box))
              .contains,
        ),
      RenderClipOval(:final clipper) => within(
        oval(clipper?.getClip(size) ?? box),
      ),
      RenderClipPath(:final clipper?) => within(clipper.getClip(size).contains),
      RenderPhysicalShape(:final clipper?) => within(
        clipper.getClip(size).contains,
      ),
      RenderPhysicalModel(shape: BoxShape.circle) => within(
        oval(
          Rect.fromCircle(center: box.center, radius: size.shortestSide / 2),
        ),
      ),
      RenderPhysicalModel(:final borderRadius?) => within(
        borderRadius.toRRect(box).contains,
      ),
      _ => null,
    };
  }

  // The stroke [box], a control's face, draws round its edge, where its
  // decoration says; none where it does not (a face read from its pixels).
  EdgeInsets _strokeOf(RenderBox box) => switch (box) {
    RenderDecoratedBox(:final decoration) => switch (decoration) {
      BoxDecoration(:final border?) => border.dimensions.resolve(
        TextDirection.ltr,
      ),
      ShapeDecoration(:final shape) => shape.dimensions.resolve(
        TextDirection.ltr,
      ),
      _ => EdgeInsets.zero,
    },
    _ => EdgeInsets.zero,
  };

  // The stroke [box], a control's face at [f], draws round its edge: where
  // its decoration says; for a face its own painter draws (no decoration
  // to say), what its pixels show: the fewest from any side's middle in to
  // its colour [face], up to 3 px (none when every side runs that far: no
  // outline stands off it).
  EdgeInsets _strokeRead(RenderBox box, Rect f, int face) {
    if (box is RenderDecoratedBox) return _strokeOf(box);
    final p = pixels!;
    final most = (3 * p.ratio).ceil();
    int run(int x, int y, int dx, int dy) {
      for (var i = 0; i < most; i++) {
        final c = p.colourAt(x + dx * i, y + dy * i);
        if (DrawnPixels.alike(c, face, by: 16)) return i;
      }
      return most;
    }

    final cx = (f.center.dx * p.ratio).floor();
    final cy = (f.center.dy * p.ratio).floor();
    final least = [
      run(cx, (f.top * p.ratio).floor(), 0, 1),
      run(cx, (f.bottom * p.ratio).ceil() - 1, 0, -1),
      run((f.left * p.ratio).floor(), cy, 1, 0),
      run((f.right * p.ratio).ceil() - 1, cy, -1, 0),
    ].reduce(math.min);
    return least >= most ? EdgeInsets.zero : EdgeInsets.all(least / p.ratio);
  }

  // Whether [box], a control's face, holds a label in: filled, or outlined
  // on every side. A face read from its pixels (a custom paint, glass, a
  // colour box that stands off) and a marked one are faces whatever they
  // draw.
  bool _holdsIn(RenderBox box) {
    if (marked.contains(box)) return true;
    return switch (box) {
      RenderDecoratedBox(:final decoration) => switch (decoration) {
        BoxDecoration(:final color, :final gradient, :final border) =>
          (color?.a ?? 0) > 0 || gradient != null || _drawsRound(border),
        ShapeDecoration(:final color, :final gradient, :final shape) =>
          (color?.a ?? 0) > 0 ||
              gradient != null ||
              (shape is OutlinedBorder && _drawsSide(shape.side)),
        _ => true,
      },
      RenderPhysicalModel(:final color) ||
      RenderPhysicalShape(:final color) => color.a > 0,
      _ => true,
    };
  }
}

// Reads a control's face for [DesignFaceInsetCheck]: as the label check
// reads it, what a custom paint draws itself read more closely ([_ownInk]).
class _FaceReader extends _LabelReader {
  _FaceReader(super.check, super.boundary, super.pixels, super.marked);

  // What a custom paint draws itself inside [r], the words, icons and text
  // entries under [holder] left out, and their words' ink past their line
  // boxes with them (a script's marks and tails over and under its line, an
  // italic's overhang). A paint whose commonest colour stands less than an
  // ink's step off what is round it, and that draws, however faintly, to
  // within [_faintReach] of every edge of its box (a plate a few levels off
  // its page, its rim shaded back to it, or outlined in a tone near it), is
  // that face, not the stronger ink drawn on it (a chevron, an avatar's
  // ball, a checkbox's key). Null when it draws nothing else.
  @override
  ({Rect rect, bool read})? _ownInk(Rect r, RenderObject holder) {
    final p = pixels;
    final b = boundary;
    if (p == null || b == null) return super._ownInk(r, holder);
    final local = _toBoundary(r);
    final lines = _shownOver(r, holder);
    final except = [for (final w in lines) _toBoundary(w)];
    final ground = p.groundAround(local, 2);
    final within = _pastLines(lines, ground);
    Rect? drawn(int by) =>
        p.inkIn(local, over: ground, except: except, within: within, by: by);
    final fill = p.solidOutside(local, except)?.colour;
    var own = fill != null && DrawnPixels.alike(fill, ground, by: 64)
        ? drawn(2)
        : null;
    if (own != null &&
        (own.left - local.left > _faintReach ||
            own.top - local.top > _faintReach ||
            local.right - own.right > _faintReach ||
            local.bottom - own.bottom > _faintReach)) {
      own = null;
    }
    own ??= drawn(64);
    return own == null
        ? null
        : (
            rect: MatrixUtils.transformRect(b.getTransformTo(null), own),
            read: true,
          );
  }

  // How far in from its box's edges a faint face may start: a rim shaded
  // back to the colour round it.
  static const double _faintReach = 3;

  // Which of the image's pixels a paint's own ink is read in, round [lines]
  // (the words, icons and text entries over it, global): not, in reach of a
  // line of words (half an em over and under it, a quarter past its ends),
  // one drawn in its words' colour or between that and [ground] (their
  // marks, tails and overhang past the line's box). Null with no words.
  bool Function(int x, int y)? _pastLines(List<Rect> lines, int ground) {
    final p = pixels!;
    final reach = <(int, int, int, int, List<int>)>[];
    for (final (box, bounds) in _shownRects) {
      if (box is! RenderParagraph ||
          box.size.height <= 0 ||
          !lines.contains(bounds)) {
        continue;
      }
      final em = labelFontSize(box) * _global(box).height / box.size.height;
      final zone = _toBoundary(
        Rect.fromLTRB(
          bounds.left - em / 4,
          bounds.top - em / 2,
          bounds.right + em / 4,
          bounds.bottom + em / 2,
        ),
      );
      final inks = <int>[];
      box.text.visitChildren((span) {
        if (span.style?.color case final c?) inks.add(_over(c, ground));
        return true;
      });
      if (inks.isEmpty) continue;
      reach.add((
        (zone.left * p.ratio).floor(),
        (zone.top * p.ratio).floor(),
        (zone.right * p.ratio).ceil(),
        (zone.bottom * p.ratio).ceil(),
        inks,
      ));
    }
    if (reach.isEmpty) return null;
    return (x, y) {
      for (final (l, t, r, b, inks) in reach) {
        if (x < l || x >= r || y < t || y >= b) continue;
        final c = p.colourAt(x, y);
        if (inks.any((ink) => DrawnPixels.between(c, ground, ink))) {
          return false;
        }
      }
      return true;
    };
  }

  // [colour] laid over [ground] (an RGBA pixel), as an RGBA pixel.
  static int _over(Color colour, int ground) {
    final under = Color.fromARGB(
      0xFF,
      (ground >> 24) & 0xFF,
      (ground >> 16) & 0xFF,
      (ground >> 8) & 0xFF,
    );
    final c = Color.alphaBlend(colour, under);
    int channel(double v) => (v * 255).round() & 0xFF;
    return channel(c.r) << 24 | channel(c.g) << 16 | channel(c.b) << 8 | 0xFF;
  }
}

// Whether [clip] cuts the face [read] (global): [read] runs past it, or
// ends at one of its edges where [box], the box it is painted in, runs on
// past that edge (what shows of a face read from its pixels stops at the
// cut: an avatar a list's foot cuts reads as ending there).
bool _cutBy(Rect clip, Rect read, Rect box) =>
    clip.intersect(read) != read ||
    (read.left <= clip.left + 1 && box.left < clip.left) ||
    (read.top <= clip.top + 1 && box.top < clip.top) ||
    (read.right >= clip.right - 1 && box.right > clip.right) ||
    (read.bottom >= clip.bottom - 1 && box.bottom > clip.bottom);

// Whether [n] hides what it is painted over where it paints: an opaque
// fill, a gradient, an image, a paint whose fill the check cannot read; not
// a clear or translucent colour, nor a pane of glass.
bool _hides(RenderObject n) => switch (n) {
  RenderDecoratedBox(
    decoration: BoxDecoration(:final color, :final gradient, :final image),
  ) ||
  RenderDecoratedBox(
    decoration: ShapeDecoration(:final color, :final gradient, :final image),
  ) => (color?.a ?? 0) == 1 || gradient != null || image != null,
  RenderPhysicalModel(:final color) ||
  RenderPhysicalShape(:final color) => color.a == 1,
  RenderBackdropFilter() => false,
  _ => _fills(n),
};

// Latin letters and figures, whose ink a face's room up and down is read by.
const _latin = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

// Whether [border] draws a stroke on every side.
bool _drawsRound(BoxBorder? border) => switch (border) {
  null => false,
  Border(:final top, :final right, :final bottom, :final left) => [
    top,
    right,
    bottom,
    left,
  ].every(_drawsSide),
  BorderDirectional(:final top, :final start, :final bottom, :final end) => [
    top,
    start,
    bottom,
    end,
  ].every(_drawsSide),
  _ => true,
};
