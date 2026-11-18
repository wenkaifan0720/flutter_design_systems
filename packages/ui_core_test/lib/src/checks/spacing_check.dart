part of '../alignment.dart';

/// Whether a screen keeps its spacing: one page margin that its floating
/// bars and sheets start on too, a shape inside a shape set in by one
/// inset all round with corners that follow the outer ones, and repeated
/// items standing evenly apart.
///
/// What it reads, each in a designer's words:
/// - the page margin: the inset from the screen's side that most of the
///   page's own faces and words start at (each read at its leading and its
///   trailing side, up to [marginReach] in). A bar or sheet that floats
///   over the page (a face four fifths of the screen wide or more, at its
///   foot or its head, outside the page's scroll view) starts on that
///   margin, or runs edge to edge: `the
///   bar holding "Activity" starts 12 pt in from the screen's left, the
///   page's margin is 16 pt`. The user found Frosted's tab bar 12 pt in
///   over a page 16 pt in;
/// - a shape inside a shape: a face whose outline is known (a rounded clip,
///   a decoration's radius or shape, a physical shape) set inside another
///   by a small inset (at most [hugReach], or the outer corner's radius),
///   filling most of it along one side. At a corner where it is set in on
///   both sides, the two insets are one, and its corner radius is the
///   outer one less the inset (concentric corners): `a 89 × 56 face in the
///   bar holding "Activity" stands 4 pt from its top but 8 pt from its
///   left; its corners are 14 pt round in the bar's 22 pt, 4 pt out:
///   concentric corners are 18 pt`. The user found Frosted's chosen tab's
///   plate so;
/// - repeated items (three or more of one kind and one size across, side
///   by side in a row or a column, each drawing a face: chips, cards,
///   tiles) standing evenly apart, measured by what they draw: by the gaps
///   between them, or, where they are laid out in equal cells, by their
///   pitch. Words alone (a table's cells, a calendar's days, a label over
///   its value) are set by type and by column, and are not read. Until a
///   grid is read by its rows and its columns, uneven gaps are
///   [DesignAlignmentReport.advisories] unless [failOnGaps];
///
/// and, from a look's sources ([literals]), each spacing written as a
/// number in place of a token, and each off the look's grid ([grid], else
/// the one its [DesignSpacingScope] declares, else 4).
///
/// What other checks hold is not read again: a row of controls' heights,
/// centres and capitals ([DesignRowCheck]), a region's leading and trailing
/// edges, form labels among them ([DesignKeylineCheck]), a label's or an
/// icon's centring on its capitals ([DesignLabelCheck]), and insets
/// mirrored under right to left (world_checks.dart's `expectMirrorsInRtl`).
///
/// A test pumps a screen (a phone's, where the margin shows) and checks it
/// from its root, so its bars are read with it:
///
/// ```dart
/// final report = await const DesignSpacingCheck(look: 'Comic').check(
///   tester.element(find.byType(SettingsScreen)),
///   runAsync: tester.runAsync,
/// );
/// report.verify();
/// ```
@immutable
class DesignSpacingCheck {
  /// A check for [look].
  const DesignSpacingCheck({
    required this.look,
    this.tolerance = 1,
    this.grid,
    this.marginReach = 48,
    this.hugReach = 12,
    this.tightInset = 8,
    this.failOnGaps = false,
  });

  /// The look's name, for messages.
  final String look;

  /// How far, in logical pixels, two spacings that should be one may
  /// differ.
  final double tolerance;

  /// The step every spacing token is a multiple of; null: the look's, from
  /// the [DesignSpacingScope] [literals] is given the context of, else 4
  /// ([DesignSpacing.fallback]).
  final double? grid;

  /// How far in from the screen's side a face or a word still starts on
  /// the page's margin.
  final double marginReach;

  /// The widest inset at which a face inside another is a shape in a shape
  /// rather than content set on it (the outer corner's radius when that is
  /// larger).
  final double hugReach;

  /// The inset up to which a shape in a shape keeps one inset all round:
  /// a tight fit (a plate in a bar, a thumb in a track) shows a lopsided
  /// inset, a roomier one may pad across and down apart.
  final double tightInset;

  /// Whether uneven gaps between repeated items are problems; by default
  /// they are advisories, reported and never failing: a grid is not yet
  /// read by its rows and its columns, and a calendar's weeks can read
  /// uneven.
  final bool failOnGaps;

  /// Checks the screen under [context]. A face whose corners only its
  /// pixels show (a look's own painter, marked as a [DesignKeylineFace]) is
  /// read from the screen, so a test passes its tester's `runAsync`; null
  /// reads directly, as an app does.
  Future<DesignAlignmentReport> check(
    BuildContext context, {
    Future<T?> Function<T>(Future<T> Function() work)? runAsync,
  }) async {
    final root = context.findRenderObject();
    if (root is! RenderBox || !root.hasSize) {
      return DesignAlignmentReport(look, const []);
    }
    final view = View.of(context);
    final screen = Offset.zero & (view.physicalSize / view.devicePixelRatio);
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final marked = _markedFaces(context);
    final shapes = <_Shape>[];
    final faces = <RenderBox>[];
    void visit(RenderObject node) {
      if (node is RenderBox && node.hasSize && !node.size.isEmpty) {
        if (_Shape.of(node) case final shape?) {
          shapes.add(shape);
        } else if (marked.contains(node)) {
          // A look's own face: its corners are read from its pixels.
          shapes.add(_Shape(node, _global(node), null));
        }
        if (marked.contains(node) || _paintsFace(node)) faces.add(node);
      }
      _visitShown(node, visit);
    }

    visit(root);
    final gaps = _gaps(root);
    return DesignAlignmentReport(
      look,
      [
        ..._margins(root, screen, rtl, faces),
        ...await _nested(shapes, marked, runAsync),
        if (failOnGaps) ...gaps,
      ],
      advisories: [if (!failOnGaps) ...gaps],
    );
  }

  // The page's margin, and the floating bars and sheets off it.
  List<String> _margins(
    RenderBox root,
    Rect screen,
    bool rtl,
    List<RenderBox> faces,
  ) {
    // The faces and words that stand on the page: inside no other face.
    final facesShown = [
      for (final f in faces)
        if (_global(f) case final r
            when r.overlaps(screen) && r.width < screen.width - 1)
          (f, r),
    ];
    bool insideFace(RenderBox box, Rect at) => facesShown.any(
      (f) =>
          !identical(f.$1, box) &&
          _isWithin(box, f.$1) &&
          f.$2.width < screen.width - 1,
    );
    final onPage = <(RenderBox, Rect)>[];
    void collect(RenderObject node) {
      if (node is RenderBox && node.hasSize && !node.size.isEmpty) {
        final isFace = facesShown.any((f) => identical(f.$1, node));
        if (isFace || node is RenderParagraph) {
          final r = _global(node);
          final ink = node is RenderParagraph ? _wordsInk(node) ?? r : r;
          if (!insideFace(node, r)) onPage.add((node, ink));
          if (isFace) return;
        }
      }
      _visitShown(node, collect);
    }

    collect(root);
    // A bar or sheet: a face most of the screen wide, at its foot or its
    // head, that stays put while the page scrolls under it.
    bool floats(RenderBox box, Rect r) =>
        r.width >= screen.width * .8 &&
        r.left - screen.left <= marginReach &&
        screen.right - r.right <= marginReach &&
        r.height <= screen.height / 2 &&
        (screen.bottom - r.bottom <= 48 || r.top - screen.top <= 48) &&
        !_scrolls(box, root);
    final insets = <double>[];
    for (final (box, r) in onPage) {
      if (facesShown.any((f) => identical(f.$1, box)) && floats(box, r)) {
        continue;
      }
      for (final inset in [r.left - screen.left, screen.right - r.right]) {
        if (inset > .5 && inset <= marginReach) insets.add(inset);
      }
    }
    final margin = _mode(insets, tolerance);
    if (margin == null) return const [];
    final found = <String>[];
    for (final (box, r) in onPage) {
      if (!facesShown.any((f) => identical(f.$1, box)) || !floats(box, r)) {
        continue;
      }
      final left = r.left - screen.left;
      final right = screen.right - r.right;
      final off = [
        if (left > .5 && (left - margin).abs() > tolerance) ('left', left),
        if (right > .5 && (right - margin).abs() > tolerance) ('right', right),
      ];
      if (off.isEmpty) continue;
      final what = screen.bottom - r.bottom <= 48 ? 'bar' : 'bar at the top';
      final at = off
          .map((o) => '${_px(o.$2)} pt in from the screen\'s ${o.$1}')
          .join(' and ');
      found.add(
        'the $what ${_size(r.size)}${_holding(box)} starts $at, the page\'s '
        'margin is ${_px(margin)} pt: a bar or sheet floating over the page '
        'starts on its margin, or runs edge to edge',
      );
    }
    return found;
  }

  // Shapes set in shapes, read for one inset and concentric corners.
  Future<List<String>> _nested(
    List<_Shape> shapes,
    Set<RenderBox> marked,
    Future<T?> Function<T>(Future<T> Function() work)? runAsync,
  ) async {
    final found = <String>[];
    // One shape per face drawn: a face's clip, its decoration and its mark
    // (siblings, often: a glass face's blur clipped beside its paint) are
    // one, held by the first of them, the outermost; its corners are the
    // first any of them knows.
    final kept = <_Shape>[];
    for (final s in shapes) {
      final i = kept.indexWhere((k) => _same(k.rect, s.rect));
      if (i < 0) {
        kept.add(s);
      } else if (kept[i].radii == null && s.radii != null) {
        kept[i] = _Shape(kept[i].box, kept[i].rect, s.radii);
      }
    }
    final pixels = <RenderRepaintBoundary, DrawnPixels?>{};
    Future<_Shape?> known(_Shape s) async {
      if (s.radii != null) return s;
      // A small face (a thumb, a dot) is read through its halo and the
      // rim of what it sits in: too few pixels to tell its corners.
      if (s.rect.shortestSide < 32) return null;
      final boundary = _drawnIn(s.box);
      if (boundary == null) return null;
      if (!pixels.containsKey(boundary)) {
        try {
          pixels[boundary] = await DrawnPixels.read(boundary, 3, runAsync);
        } on StateError {
          pixels[boundary] = null;
        }
      }
      final px = pixels[boundary];
      if (px == null) return null;
      final local = MatrixUtils.transformRect(
        s.box.getTransformTo(boundary),
        Offset.zero & s.box.size,
      );
      final radii = _readCorners(px, local);
      return radii == null ? null : _Shape(s.box, s.rect, radii, read: true);
    }

    for (final inner in kept) {
      _Shape? outer;
      for (final o in kept) {
        if (identical(o, inner) || _same(o.rect, inner.rect)) continue;
        if (!_isWithin(inner.box, o.box) || !_contains(o.rect, inner.rect)) {
          continue;
        }
        if (outer == null || _isWithin(o.box, outer.box)) outer = o;
      }
      if (outer == null) continue;
      if (!_hugs(inner.rect, outer)) continue;
      // Painted shapes in painted shapes only (a plate, a thumb, a well, a
      // chip in a bar): the padding round a field's line of words may
      // differ across and down.
      if (!_painted(inner, marked) || !_painted(outer, marked)) continue;
      final i = await known(inner) ?? inner;
      final o = await known(outer) ?? outer;
      final problem = _readNested(i, o);
      if (problem != null) found.add(problem);
    }
    return found;
  }

  // Whether [inner] sits in [outer] as a shape in a shape: set in by a
  // small inset at a corner, filling most of it along one side.
  bool _hugs(Rect inner, _Shape outer) {
    final o = outer.rect;
    if (inner.width < 16 || inner.height < 16) return false;
    if (inner.width < o.width * .6 && inner.height < o.height * .6) {
      return false;
    }
    // A line of words in a field is no shape in it.
    if (inner.width < o.width * .4 || inner.height < o.height * .4) {
      return false;
    }
    final reach = math.max(hugReach, outer.radii?.tl ?? 0);
    final dx = math.min(inner.left - o.left, o.right - inner.right);
    final dy = math.min(inner.top - o.top, o.bottom - inner.bottom);
    return dx > .5 && dy > .5 && dx <= reach && dy <= reach;
  }

  String? _readNested(_Shape inner, _Shape outer) {
    final i = inner.rect;
    final o = outer.rect;
    if (i.width < 16 || i.height < 16) return null;
    // Filling most of it along one side: a shape in it, not a part on it.
    if (i.width < o.width * .6 && i.height < o.height * .6) return null;
    final left = i.left - o.left;
    final top = i.top - o.top;
    final right = o.right - i.right;
    final bottom = o.bottom - i.bottom;
    final unequal = <String>{};
    final notConcentric = <String>[];
    // Corners read neither way (a fill the colour of what is round it)
    // are left out; the insets are still read.
    final ir = inner.radii;
    final or = outer.radii;
    for (final (name, dx, dy, ri, ro) in [
      ('top left', left, top, ir?.tl, or?.tl),
      ('top right', right, top, ir?.tr, or?.tr),
      ('bottom left', left, bottom, ir?.bl, or?.bl),
      ('bottom right', right, bottom, ir?.br, or?.br),
    ]) {
      final reach = math.max(hugReach, ro ?? 0);
      if (dx < -.5 || dy < -.5 || dx > reach || dy > reach) continue;
      // Flush on a side is a part of the outer face (a header, a picture
      // on a card), not a shape set in it.
      if (dx < .5 || dy < .5) continue;
      // Unequal insets show on a tight fit (a plate, a thumb, a chip in a
      // bar); a roomy one may pad across and down apart.
      if ((dx - dy).abs() > tolerance && math.min(dx, dy) <= tightInset) {
        unequal.add(
          '${_px(dy)} pt from its ${name.split(' ').first} but ${_px(dx)} pt '
          'from its ${name.split(' ').last}',
        );
      }
      if (ri == null || ro == null || ro <= 0) continue;
      final inset = math.min(dx, dy);
      // Set in by half its corner or more, the inner corner's own round
      // reads apart from the outer's: concentric no longer shows.
      if (inset > ro / 2) continue;
      final concentric = math.max(0.0, ro - inset);
      // Corners read from pixels are known to a pixel or so.
      final slack = inner.read || outer.read ? 2.0 : tolerance + .5;
      if ((ri - concentric).abs() > slack) {
        notConcentric.add(
          'its $name corner is ${_px(ri)} pt round in a ${_px(ro)} pt corner '
          '${_px(inset)} pt out: concentric, it is ${_px(concentric)} pt',
        );
      }
    }
    if (unequal.isEmpty && notConcentric.isEmpty) return null;
    final what = 'a ${_size(i.size)} shape${_holding(inner.box)}';
    final where = 'in a ${_size(o.size)} shape${_holding(outer.box)}';
    final said = [
      if (unequal.isNotEmpty)
        'it stands ${unequal.join(', and ')}: a shape in a shape keeps one '
            'inset all round',
      if (notConcentric.isNotEmpty) notConcentric.first,
    ];
    return '$what $where: ${said.join('; ')}';
  }

  // Repeated items in a row or a column, read for even spacing.
  List<String> _gaps(RenderBox root) {
    final found = <String>[];
    void visit(RenderObject node) {
      if (node is RenderFlex && node.hasSize) {
        final problem = _readFlex(node);
        if (problem != null) found.add(problem);
      }
      _visitShown(node, visit);
    }

    visit(root);
    return found;
  }

  String? _readFlex(RenderFlex flex) {
    final across = flex.direction == Axis.horizontal;
    final items = <(RenderBox, Rect, Rect, Type)>[];
    var child = flex.firstChild;
    while (child != null) {
      final data = child.parentData! as FlexParentData;
      // A blank lays out with no breadth (a spacer in a row is no taller
      // than nothing), so only its length along the line is read.
      if (child.hasSize && _isShown(child)) {
        final ink = child.size.isEmpty ? null : _inkOf(child);
        // A gap (a fixed box with nothing in it) stands between items; a
        // spacer that flexes, or an empty cell about an item's size, breaks
        // the run: the items either side are not neighbours.
        final r = _global(child);
        if (ink != null) {
          items.add((child, r, ink, _kindOf(child)));
        } else if ((data.flex ?? 0) > 0 ||
            (items.isNotEmpty &&
                (across ? r.width : r.height) >=
                    (across ? items.last.$2.width : items.last.$2.height) *
                        .5)) {
          items.add((child, r, Rect.zero, Null));
        }
      }
      child = data.nextSibling;
    }
    // The longest run of three or more of one kind.
    var best = <(RenderBox, Rect, Rect, Type)>[];
    var run = <(RenderBox, Rect, Rect, Type)>[];
    double crossOf(Rect r) => across ? r.height : r.width;
    for (final item in items) {
      if (item.$4 == Null) {
        run = [];
        continue;
      }
      // Repeated items match across the line too (chips one height, cards
      // one width); a stack of a title, a picture and a button does not.
      if (run.isNotEmpty &&
          (run.last.$4 != item.$4 ||
              (crossOf(run.last.$2) - crossOf(item.$2)).abs() > tolerance)) {
        run = [];
      }
      run.add(item);
      if (run.length > best.length) best = List.of(run);
    }
    // A header or a footer at either end of the run (a month's title over
    // its weeks) is no repeated item: an end whose length along the line is
    // a quarter off the run's middle one is left out.
    if (best.length >= 3) {
      double along(Rect r) => across ? r.width : r.height;
      final lengths = [for (final b in best) along(b.$2)]..sort();
      final middle = lengths[lengths.length ~/ 2];
      bool apart((RenderBox, Rect, Rect, Type) b) =>
          (along(b.$2) - middle).abs() > middle * .25;
      while (best.length >= 3 && apart(best.first)) {
        best = best.sublist(1);
      }
      while (best.length >= 3 && apart(best.last)) {
        best = best.sublist(0, best.length - 1);
      }
    }
    if (best.length < 3) return null;
    // Repeated items draw a face (chips, cards, tiles, buttons). Words
    // alone are set by type and by column: a label over its value, a
    // table's cells, a calendar's days, a chart's ticks.
    if (best.any((b) => _onlyWords(b.$1))) return null;
    double start(Rect r) => across ? r.left : r.top;
    double end(Rect r) => across ? r.right : r.bottom;
    double extent(Rect r) => across ? r.width : r.height;
    bool even(List<double> v) =>
        v.reduce(math.max) - v.reduce(math.min) <= tolerance;
    List<double> steps(double Function(Rect) at) => [
      for (var k = 1; k < best.length; k++) at(best[k].$3) - at(best[k - 1].$3),
    ];
    final cells = [for (final b in best) extent(b.$2)];
    if (even(cells)) {
      // Equal cells: what they draw keeps one pitch, read at its start,
      // its middle or its end.
      if (even(steps(start)) ||
          even(steps((r) => (start(r) + end(r)) / 2)) ||
          even(steps(end))) {
        return null;
      }
    }
    // Equal cells are read by what they draw; cells of different sizes (a
    // page's sections, a type ramp) by their boxes, since what each draws
    // starts and ends where its own content does.
    final read = even(cells) ? 3 : 2;
    Rect of((RenderBox, Rect, Rect, Type) item) =>
        read == 3 ? item.$3 : item.$2;
    final gaps = [
      for (var k = 1; k < best.length; k++)
        start(of(best[k])) - end(of(best[k - 1])),
    ];
    // Overlapping items (a stack of avatars) and items drawn edge to edge
    // are not spaced.
    if (gaps.any((g) => g < -.5)) return null;
    if (even(gaps)) return null;
    final names = _holding(flex);
    return 'the ${best.length} items in a ${across ? 'row' : 'column'}'
        '$names stand ${_list([for (final g in gaps) '${_px(g)} pt'])} apart: '
        'repeated items stand evenly apart';
  }

  /// Reads a look's sources ([sources]: each file's path and text, the
  /// package's `lib/`) for spacing written as numbers: an `EdgeInsets`, a
  /// gap's `SizedBox` or a flex's or grid's `spacing` given a number rather
  /// than a token, and each spacing token or number off the [grid]. A token
  /// is a declaration (`static const gap = 12;`), so the values a look
  /// names are read for the grid only.
  ///
  /// The grid is [grid], else the look's: the [DesignSpacingScope] over
  /// [context] (any element under the look's theme, such as a pumped
  /// screen's), else 4.
  ///
  /// A test reads the package's `lib/` into [sources] (with `dart:io`:
  /// each `.dart` file under `Directory('lib')`, by its path), then:
  ///
  /// ```dart
  /// const DesignSpacingCheck(look: 'Comic').literals(sources).verify();
  /// ```
  ///
  /// On the look's own grid, read from a screen under its theme:
  ///
  /// ```dart
  /// const DesignSpacingCheck(look: 'Retro').literals(
  ///   sources,
  ///   context: tester.element(find.byType(SettingsScreen)),
  /// ).verify();
  /// ```
  DesignAlignmentReport literals(
    Map<String, String> sources, {
    BuildContext? context,
  }) {
    final grid =
        this.grid ??
        (context == null ? null : DesignSpacing.maybeOf(context))?.grid ??
        DesignSpacing.fallback.grid;
    final found = <String>[];
    final declaration = RegExp(
      r'^\s*(static\s+)?(const|final)\s+([\w<>?,]+\s+)?\w+\s*=',
    );
    // A number standing for itself, not a term of a sum (`grown / 2`).
    final numberAt = RegExp(
      r'(?<![\w.])(?<![/*+\-]\s*)(\d+(?:\.\d+)?)(?![\w.])(?!\s*[/*+\-])',
    );
    final uses = [
      RegExp(
        r'EdgeInsets(?:Directional)?\.(?:all|symmetric|only|fromLTRB|fromSTEB)\(([^()]*)\)',
      ),
      RegExp(r'SizedBox\(\s*(?:width|height):\s*([0-9.]+)\s*,?\s*\)'),
      RegExp(
        r'(?:\b|run|mainAxis|crossAxis)(?:spacing|Spacing):\s*([0-9.]+)\b',
      ),
    ];
    final spacingToken = RegExp(
      r'(gap|gutter|inset|padding|margin|spacing|space|pad)\w*\s*=\s*([0-9.]+)\s*;',
      caseSensitive: false,
    );
    final entries = sources.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final MapEntry(key: path, value: text) in entries) {
      final strays = <String>[];
      final offGrid = <String>[];
      final lines = text.split('\n');
      for (final (n, line) in lines.indexed) {
        final code = line.split('//').first;
        if (code.trim().isEmpty) continue;
        final declares = declaration.hasMatch(code);
        for (final use in uses) {
          for (final m in use.allMatches(code)) {
            for (final v in numberAt.allMatches(m.group(1)!)) {
              final value = double.parse(v.group(1)!);
              if (value == 0) continue;
              final at = '${_px(value)} pt at line ${n + 1}';
              if (!declares) strays.add(at);
              if (value >= grid && value % grid > .01) offGrid.add(at);
            }
          }
        }
        // A token's own value: `static const double gap = 12;`.
        final token = declares ? spacingToken.firstMatch(code) : null;
        if (token != null) {
          final value = double.parse(token.group(2)!);
          if (value >= grid && value % grid > .01) {
            offGrid.add('${_px(value)} pt, a token, at line ${n + 1}');
          }
        }
      }
      if (strays.isEmpty && offGrid.isEmpty) continue;
      final name = path.split('/').last;
      found.add(
        [
          if (strays.isNotEmpty)
            '$name writes ${strays.length} spacing'
                '${strays.length == 1 ? '' : 's'} as numbers, not tokens '
                '(${_list(strays.take(4).toList())}'
                '${strays.length > 4 ? ', …' : ''})',
          if (offGrid.isNotEmpty)
            '${strays.isEmpty ? '$name has ' : ''}${offGrid.length} off the '
                '${_px(grid)}-pt grid (${_list(offGrid.take(4).toList())}'
                '${offGrid.length > 4 ? ', …' : ''})',
        ].join('; '),
      );
    }
    return DesignAlignmentReport(look, found);
  }
}

typedef _Radii = ({double tl, double tr, double bl, double br});

// A box whose outline the check knows: its rect and its corners' radii,
// null until read from its pixels.
class _Shape {
  _Shape(this.box, this.rect, this.radii, {this.read = false});

  final RenderBox box;
  final Rect rect;
  final _Radii? radii;

  // Whether [radii] were read from pixels.
  final bool read;

  static _Shape? of(RenderBox box) {
    final size = box.size;
    ({double tl, double tr, double bl, double br})? radii;
    ({double tl, double tr, double bl, double br}) fromRadius(
      BorderRadiusGeometry r,
    ) {
      final b = r.resolve(TextDirection.ltr);
      double cap(Radius v) =>
          math.min(math.min(v.x, v.y), size.shortestSide / 2);
      return (
        tl: cap(b.topLeft),
        tr: cap(b.topRight),
        bl: cap(b.bottomLeft),
        br: cap(b.bottomRight),
      );
    }

    ({double tl, double tr, double bl, double br})? fromShape(
      ShapeBorder shape,
    ) => switch (shape) {
      StadiumBorder() || CircleBorder() => (
        tl: size.shortestSide / 2,
        tr: size.shortestSide / 2,
        bl: size.shortestSide / 2,
        br: size.shortestSide / 2,
      ),
      RoundedRectangleBorder(:final borderRadius) ||
      RoundedSuperellipseBorder(:final borderRadius) ||
      ContinuousRectangleBorder(
        :final borderRadius,
      ) => fromRadius(borderRadius),
      _ => null,
    };

    switch (box) {
      // A clip is a shape only where it rounds: a square one cuts, unseen.
      case RenderClipRRect(:final borderRadius)
          when borderRadius != BorderRadius.zero:
        radii = fromRadius(borderRadius);
      case RenderClipRSuperellipse(:final borderRadius)
          when borderRadius != BorderRadius.zero:
        radii = fromRadius(borderRadius);
      case RenderDecoratedBox(:final decoration) when _shows(decoration):
        radii = switch (decoration) {
          BoxDecoration(shape: BoxShape.circle) => fromShape(
            const CircleBorder(),
          ),
          BoxDecoration(:final borderRadius) => fromRadius(
            borderRadius ?? BorderRadius.zero,
          ),
          ShapeDecoration(:final shape) => fromShape(shape),
          _ => null,
        };
      case RenderPhysicalShape(:final clipper?)
          when clipper is ShapeBorderClipper:
        radii = fromShape(clipper.shape);
      case RenderClipPath(:final clipper?) when clipper is ShapeBorderClipper:
        radii = fromShape(clipper.shape);
      default:
        radii = null;
    }
    if (radii == null) return null;
    return _Shape(box, _global(box), radii);
  }
}

// Whether [s] is a face drawn: a decoration, a physical shape or a marked
// face, or a rounded clip round one as large as it (a picture, a fill).
bool _painted(_Shape s, Set<RenderBox> marked) {
  final box = s.box;
  if (marked.contains(box)) return true;
  if (box is RenderDecoratedBox ||
      box is RenderPhysicalShape ||
      box is RenderPhysicalModel) {
    return true;
  }
  var found = false;
  void visit(RenderObject n) {
    if (found) return;
    if (n is RenderBox && n.hasSize && !identical(n, box)) {
      if (!_same(_global(n), s.rect)) return;
      if (_paintsFace(n) || n is RenderImage || marked.contains(n)) {
        found = true;
        return;
      }
    }
    _visitShown(n, visit);
  }

  visit(box);
  return found;
}

bool _same(Rect a, Rect b) =>
    (a.left - b.left).abs() < .5 &&
    (a.top - b.top).abs() < .5 &&
    (a.right - b.right).abs() < .5 &&
    (a.bottom - b.bottom).abs() < .5;

// The value most of [values] agree on, within [tolerance] (of those, the
// one most often exact); null when none is held by a third of them.
double? _mode(List<double> values, double tolerance) {
  if (values.length < 3) return null;
  double? best;
  var most = 0;
  var exact = 0;
  for (final v in values) {
    final n = values.where((w) => (w - v).abs() <= tolerance).length;
    final e = values.where((w) => (w - v).abs() < .05).length;
    if (n > most || (n == most && e > exact)) {
      most = n;
      exact = e;
      best = v;
    }
  }
  if (most * 3 < values.length) return null;
  return best;
}

// The corners of the face drawn at [local] (logical, in [px]'s boundary),
// read from its pixels: from each corner of its box along the diagonal to
// where its fill begins, less the edge's own width (its ring, its sheen)
// read along the straight sides. Null when its fill is not told from what
// is round it.
_Radii? _readCorners(DrawnPixels px, Rect local) {
  final m = local.shortestSide;
  if (m < 12) return null;
  int at(Offset p) {
    final x = (p.dx * px.ratio).floor().clamp(0, px.width - 1);
    final y = (p.dy * px.ratio).floor().clamp(0, px.height - 1);
    return px.bytes.getUint32((y * px.width + x) * 4);
  }

  final step = 1 / px.ratio;
  int apart(int a, int b) {
    var most = 0;
    for (var shift = 0; shift < 32; shift += 8) {
      most = math.max(
        most,
        (((a >> shift) & 0xFF) - ((b >> shift) & 0xFF)).abs(),
      );
    }
    return most;
  }

  // How far from [from] along [dir] (a unit step) before a pixel is nearer
  // [fill] than what [from] shows: none when [from] already shows the fill
  // (a square corner, a side with no ring). Half the contrast between the
  // two is the line, so a white plate on white glass is read by the few
  // levels it stands apart.
  double walk(Offset from, Offset dir, int fill) {
    final contrast = apart(at(from), fill);
    if (contrast <= 3) return 0;
    final by = math.max(2, contrast ~/ 2);
    var d = 0.0;
    while (d < m / 2 && apart(at(from + dir * d), fill) > by) {
      d += step;
    }
    return d;
  }

  final c = local.center;
  double? corner(Offset at0, double ux, double uy) {
    // Along the diagonal, each step against its own row's fill (well in
    // from the side, past any corner's round): a sheen along the top or a
    // shade along the foot is the fill's, not its outline.
    final outside = at(at0);
    final dir = Offset(ux, uy) / math.sqrt2;
    var diagonal = 0.0;
    while (diagonal < m / 2) {
      final p = at0 + dir * diagonal;
      final fill = at(Offset(at0.dx + ux * m * .5, p.dy));
      final contrast = apart(outside, fill);
      // Its fill the colour of what is round it: its corner is not told.
      if (contrast <= 3) {
        if (diagonal == 0) return null;
        break;
      }
      if (apart(at(p), fill) <= math.max(2, contrast ~/ 2)) break;
      diagonal += step;
    }
    // A fill the walk never found.
    if (diagonal >= m / 2 - .01) return null;
    // The outline's own width (a ring, a hairline), read across the side
    // at the middle row.
    final ring = walk(
      Offset(at0.dx, c.dy),
      Offset(ux, 0),
      at(Offset(at0.dx + ux * m * .3, c.dy)),
    );
    final r = (diagonal - ring) / (math.sqrt2 - 1);
    return r.clamp(0, m / 2);
  }

  final tl = corner(local.topLeft, 1, 1);
  final tr = corner(local.topRight - Offset(step, 0), -1, 1);
  final bl = corner(local.bottomLeft - Offset(0, step), 1, -1);
  final br = corner(local.bottomRight - Offset(step, step), -1, -1);
  if (tl == null || tr == null || bl == null || br == null) return null;
  // A face drawn by a painter is round alike at its four corners: three
  // that agree say how round, the fourth crossed a sheen on the way in.
  // With no three agreeing, its corners are not told.
  final all = [tl, tr, bl, br]..sort();
  for (final three in [all.sublist(0, 3), all.sublist(1)]) {
    if (three.last - three.first <= 2) {
      final r = three[1];
      return (tl: r, tr: r, bl: r, br: r);
    }
  }
  return null;
}

// Whether [box] draws words and nothing else: no face, no picture.
bool _onlyWords(RenderBox box) {
  var words = false;
  var other = false;
  void visit(RenderObject n) {
    if (other) return;
    if (n is RenderBox && (_paintsFace(n) || n is RenderImage)) {
      other = true;
      return;
    }
    if (n is RenderParagraph) words = true;
    _visitShown(n, visit);
  }

  visit(box);
  return words && !other;
}

// Whether [box] moves with a scroll view between it and [root]: any
// viewport, a SingleChildScrollView's as well as a list's.
bool _scrolls(RenderBox box, RenderObject root) {
  for (
    var up = box.parent;
    up != null && !identical(up, root);
    up = up.parent
  ) {
    if (up is RenderAbstractViewport) return true;
  }
  return false;
}

// What a paragraph's words cover, on the screen.
Rect? _wordsInk(RenderParagraph p) {
  final length = p.text.toPlainText(includeSemanticsLabels: false).length;
  if (length == 0) return null;
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: length),
  );
  if (boxes.isEmpty) return null;
  var r = boxes.first.toRect();
  for (final b in boxes.skip(1)) {
    r = r.expandToInclude(b.toRect());
  }
  return MatrixUtils.transformRect(p.getTransformTo(null), r);
}

// What [box] draws: its face, else the union of the faces, words and
// pictures in it; null when it draws nothing.
Rect? _inkOf(RenderBox box) {
  if (_paintsFace(box)) return _global(box);
  Rect? ink;
  void visit(RenderObject n) {
    if (n is! RenderBox || !n.hasSize || n.size.isEmpty) {
      _visitShown(n, visit);
      return;
    }
    Rect? here;
    if (_paintsFace(n) || n is RenderImage) {
      here = _global(n);
    } else if (n is RenderParagraph) {
      here = _wordsInk(n);
    }
    if (here != null) {
      ink = ink == null ? here : ink!.expandToInclude(here);
      return;
    }
    _visitShown(n, visit);
  }

  visit(box);
  return ink;
}

// The kind of item [box] is: the widget that made it, where tests keep
// that, else its own type.
Type _kindOf(RenderBox box) {
  final creator = box.debugCreator;
  if (creator is DebugCreator) {
    // The outermost widget of the item: the flex's child as written.
    var item = creator.element;
    final flex = box.parent;
    creator.element.visitAncestorElements((e) {
      if (e.renderObject == flex || e.findRenderObject() != box) return false;
      // Expanded and Flexible are how it is placed, not what it is.
      if (e.widget is! ParentDataWidget) item = e;
      return true;
    });
    return item.widget.runtimeType;
  }
  return box.runtimeType;
}

String _list(List<String> words) => switch (words.length) {
  0 => '',
  1 => words.single,
  _ => '${words.sublist(0, words.length - 1).join(', ')} and ${words.last}',
};
