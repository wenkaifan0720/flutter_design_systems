part of '../../review.dart';

/// Checks that the controls sharing a row line up as a person sees them:
/// by their drawn outlines, not their boxes.
///
/// A control's box is not always what a person sees as its outline. A glass
/// button whose outer ring barely stands off a light dialog reads 146 by 44
/// beside a filled one of 150 by 48: the same boxes, so [DesignKeylineCheck]
/// passes them, and a row whose tops, bottoms and sides do not match. This
/// check reads each control's outline from the drawn pixels, inside its face
/// (the box [DesignLabelCheck] and [DesignKeylineCheck] read, so a shadow
/// outside it never counts): the outermost rows and columns holding a pixel
/// whose contrast with what is just around the face reaches
/// [contrastFloor], words and icons left out (its own, and any drawn over
/// it from beside it: a navigation item's icon over its pressed-state
/// layer). For a rectangular bevel, the check also compares its light and
/// dark rim colours. This preserves the full outline when one rim is close
/// to the background. A face no pixel of which
/// reaches the floor (a fill a hue apart from its ground, a pane of glass)
/// is read by its box, as is one a look marks with [RawKeylineFace].
/// Controls of one kind touching side by side in one track drawn round
/// them (a segmented control's segments, a joined strip's buttons: a fill
/// or a stroke all round, no more than 8 px round them, holding nothing
/// else; a table header's rule under its headings is no track) are read by
/// the track's outline.
///
/// A row is the controls that one box lays out side by side: a dialog's
/// actions, a split button's halves, a search field and its button, an app
/// bar's icons, and each run of a wrap (chips over two lines). Across a
/// row, held to [tolerance] device pixels as drawn, and each problem given
/// as laid out and as drawn:
/// - one top and one bottom, among the controls with a face of their own
///   each more than half as high as the tallest (a checkbox beside a button
///   is not one of them). The control most of them agree with (of two, the
///   taller) is the one the others are held to, and one drawn smaller is
///   named, whatever the reason: `a button "Cancel" beside a button "OK":
///   its top is level with theirs as laid out, 6 device px below as drawn`.
///   A bevel (a face lit along two sides and shaded along the other two)
///   has no single painted edge to read, so beside one the row is held as
///   laid out: `its bottom is 2 px above theirs as laid out`.
/// - every control's capitals (its label's, a text entry's typed text or
///   hint) on the row's centre line, that control's middle: `a button "OK"
///   beside a button "Cancel": the capitals of "OK" are 1 px below the row's
///   centre line as laid out, 3 device px below as drawn`. Words over or
///   under other words (a card's title over its body) or under a picture
///   (an icon tile's name, a label under a painted glyph) are placed, not
///   centred, and are not held to it.
/// - a control with no face of its own has no outline to compare: an icon
///   button drawn as a bare glyph, a text button, a navigation destination
///   whose indicator holds only its icon, an icon whose badge is the only
///   face in it, a tab whose face shows only the line under it, a text
///   entry whose only paint round it draws nothing (an input decorator
///   with no border). A face
///   holds what its control shows (a text entry's line, else its label and
///   every icon), and what is drawn of it holds its middle. Such a control
///   is read by its label's
///   capitals (its words beside its icon, or alone), else by its icon's
///   middle, on the centre line: `a button beside a button "OK": its icon
///   is 1 px below the row's centre line as laid out, 2 device px below as
///   drawn`. In a row of only these, the centre line is the one most of
///   them agree with.
/// - equal sides, where the row is laid out with equal sides on its surface
///   (the nearest face around it, else the screen), across it or centred on
///   it: `a row of a button "Cancel" and a button "OK": its sides are 24 px
///   in as laid out, 26 px on the left and 24 px on the right as drawn`.
///
/// A text field's own parts (its entry and the toggle, clear button or
/// switch inside its face, read by what they show, not by touch targets
/// that may overhang it) are one field, not a row; a control whose middle
/// is outside the image (scrolled out of its strip), that a clip round it
/// hides in part (a week scrolled in its strip, its weekend past the
/// strip's edge), or that another surface covers, wholly or in part (a
/// window in front of it, a later layer of a stack: what a pointer at its
/// middle or an edge's reaches is painted after it, and fills), is not
/// read. A row
/// inside a region that says why its controls may differ in height or
/// centre ([RawKeylineRegion.mixedHeights]: a gallery's ladder of one
/// control per size) is not held; a to-do there is named. To free one row
/// only, put the region round that row.
///
/// Before the check, a test loads the look's fonts and lets the screen's
/// images decode, as [DesignLabelCheck] shows. Only what is painted is read.
/// A test pumps a screen (a gallery page, an app screen, a dialog) and
/// checks it from its root, the app round the page, so its bars are read
/// with it (a gallery's own bar, an app's top bar and navigation):
///
/// ```dart
/// final report = await const DesignRowCheck(look: 'Comic').check(
///   tester.element(find.byType(SettingsScreen)),
///   runAsync: tester.runAsync,
/// );
/// report.verify();
/// ```
///
/// It reads layout boxes, and the drawn pixels where only they show it (a
/// face's painted edge, a fill that differs from the page), so it takes the
/// tester's `runAsync`.
@immutable
class DesignRowCheck {
  /// A check for [look].
  const DesignRowCheck({
    required this.look,
    this.contrastFloor = 1.25,
    this.tolerance = 0.5,
    this.pixelRatio = 3,
  });

  /// The look's name, for messages.
  final String look;

  /// The contrast with what is around a face (WCAG's ratio of relative
  /// luminances, 1 to 21) a drawn pixel needs to count as part of its
  /// outline: below it, a person sees the pixel as the ground.
  final double contrastFloor;

  /// How far, in device pixels at [pixelRatio], the drawn tops, bottoms and
  /// sides of a row may differ.
  final double tolerance;

  /// The scale the screen is drawn at to read its pixels.
  final double pixelRatio;

  /// Checks every row of controls under [context] (on screen, under a
  /// repaint boundary as every route is). A test passes its tester's
  /// `runAsync` (reading pixels takes real time); null reads them directly.
  Future<DesignAlignmentReport> check(
    BuildContext context, {
    Future<T?> Function<T>(Future<T> Function() work)? runAsync,
  }) async {
    final root = context.findRenderObject();
    if (root == null) return DesignAlignmentReport(look, const []);
    final marked = _markedFaces(context);
    final finder = _DrawnReader(null, null, marked);
    // Each box that lays out two or more controls side by side, with them:
    // the outermost such box, as a row's own parts are not rows of it.
    final rows = <(RenderObject, List<RenderBox>)>[];
    void visit(RenderObject node) {
      if (_isControl(node)) return;
      final children = <RenderObject>[];
      _visitShown(node, children.add);
      if (children.length < 2) {
        if (children.isNotEmpty) visit(children.first);
        return;
      }
      final held = <RenderBox>[];
      var groups = 0;
      for (final child in children) {
        final under = child is RenderBox && child.hasSize && _isControl(child)
            ? [child]
            : finder._controlsUnder(child);
        if (under.isNotEmpty) groups++;
        held.addAll(under);
      }
      if (groups >= 2 && _sideBySide(held)) {
        rows.add((node, held));
        return;
      }
      // A wrap's runs (chips over two lines): each run of two or more
      // controls side by side is a row.
      if (node is RenderWrap && groups >= 2) {
        final runs = [
          for (final run in _runsOf(held))
            if (_sideBySide(run)) run,
        ];
        if (runs.isNotEmpty) {
          for (final run in runs) {
            rows.add((node, run));
          }
          return;
        }
      }
      children.forEach(visit);
    }

    visit(root);
    final regions = _regionBoxes(context);
    final viewId = View.maybeOf(context)?.viewId;
    final readers = <RenderRepaintBoundary, _RowReader>{};
    Future<_RowReader> read(RenderRepaintBoundary boundary) async =>
        readers[boundary] ??= _RowReader(
          this,
          boundary,
          await DrawnPixels.read(boundary, pixelRatio, runAsync),
          marked,
        );
    final found = <String>[];
    final fallback = <String>[];
    final toDo = <RawKeylineRegion>{};
    for (final (node, controls) in rows) {
      // A region that says why its controls differ is not held.
      if (_regionOf(node, regions)
          case RawKeylineRegion(:final mixedHeights?) && final region) {
        if (isToDoReason(mixedHeights) && toDo.add(region)) {
          found.add(
            '${_rowOf(controls)}: "$mixedHeights" is a to-do, not a reason '
            'its controls differ',
          );
        }
        continue;
      }
      final boundary = _drawnIn(node);
      if (boundary == null) continue;
      // A control another surface covers (a window in front of it, a later
      // layer of a stack) shows that surface where it lies: not read.
      // A check can also start above the app's View (the binding's root).
      // Resolve the view which actually paints this row in that case.
      int? rowView = viewId;
      for (
        RenderObject? up = node;
        rowView == null && up != null;
        up = up.parent
      ) {
        if (up is RenderView) rowView = up.flutterView.viewId;
      }
      final shown = [
        for (final c in controls)
          if (rowView == null || !_covered(c, rowView)) c,
      ];
      if (shown.length < 2) continue;
      var reader = await read(boundary);
      // A row drawn in a layer of its own, clear where it stands (a section
      // in a repaint boundary over the page), is read in the layer round
      // it, where what lies under it is drawn too: what a person sees. Read
      // against the clear, a face's black edge is no edge.
      while (reader._clearUnder(node)) {
        final parent = reader.boundary!.parent;
        final up = parent == null ? null : _drawnIn(parent);
        if (up == null) break;
        reader = await read(up);
      }
      found.addAll(reader.problems(node, shown));
      fallback.addAll(reader.fallback);
      reader.fallback.clear();
    }
    if (fallback.isNotEmpty) {
      return DesignAlignmentReport(look, [_testFontProblem(fallback)]);
    }
    return DesignAlignmentReport(look, found);
  }

  // "a row of a button "Cancel" and a button "OK"".
  static String _rowOf(List<RenderBox> controls) {
    final sorted = [...controls]
      ..sort((a, b) => _global(a).left.compareTo(_global(b).left));
    final names = [for (final c in sorted) _nameOf(c)];
    return switch (names.length) {
      2 => 'a row of ${names[0]} and ${names[1]}',
      3 => 'a row of ${names[0]}, ${names[1]} and ${names[2]}',
      _ =>
        'a row of ${names.length} controls from ${names.first} to '
            '${names.last}',
    };
  }

  // [controls] as the runs a wrap lays them out in, top to bottom: each run
  // the controls that start above the bottom of the first in it.
  static List<List<RenderBox>> _runsOf(List<RenderBox> controls) {
    final sorted = [...controls]
      ..sort((a, b) => _global(a).top.compareTo(_global(b).top));
    final runs = <List<RenderBox>>[];
    for (final c in sorted) {
      final top = _global(c).top;
      if (runs.isNotEmpty && top < _global(runs.last.first).bottom - 0.5) {
        runs.last.add(c);
      } else {
        runs.add([c]);
      }
    }
    return runs;
  }

  // Whether [controls] stand side by side: none over another across, each
  // two sharing at least half the shorter one's height.
  static bool _sideBySide(List<RenderBox> controls) {
    if (controls.length < 2) return false;
    final boxes = [for (final c in controls) _global(c)]
      ..sort((a, b) => a.left.compareTo(b.left));
    for (var i = 0; i < boxes.length; i++) {
      final a = boxes[i];
      if (i > 0 && boxes[i - 1].right > a.left + 0.5) return false;
      for (final b in boxes.skip(i + 1)) {
        final shared = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
        if (shared < math.min(a.height, b.height) / 2) return false;
      }
    }
    return true;
  }
}

// The boxes of the DesignKeylineRegions under [context], with them.
Map<RenderBox, RawKeylineRegion> _regionBoxes(BuildContext context) {
  final found = <RenderBox, RawKeylineRegion>{};
  void visit(Element element) {
    if (element.widget case final RawKeylineRegion region) {
      final box = element.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize && _isShown(box)) {
        // Of two round one box, the inner.
        found[box] = region;
      }
    }
    element.visitChildElements(visit);
  }

  if (context is Element) visit(context);
  return found;
}

// The nearest of [regions] round [node] (or [node]'s own); null outside
// all of them.
RawKeylineRegion? _regionOf(
  RenderObject node,
  Map<RenderBox, RawKeylineRegion> regions,
) {
  for (RenderObject? up = node; up != null; up = up.parent) {
    if (regions[up] case final region?) return region;
  }
  return null;
}

// Whether another surface covers [control], wholly or in part: its middle
// or the middle of an edge (2 px in). There, what a pointer reaches first
// is outside it and round it, painted after it, and fills (a window in
// front, a later layer of a stack). What lies behind it (a ground under a
// control that takes no pointer), or round it, is no cover; nor is what
// takes the pointer in front and paints nothing (a barrier with no colour).
bool _covered(RenderBox control, int viewId) {
  final box = _global(control);
  final inset = box.deflate(math.min(2, box.shortestSide / 4));
  return [
    box.center,
    inset.centerLeft,
    inset.topCenter,
    inset.centerRight,
    inset.bottomCenter,
  ].any((at) => _coveredAt(control, at, viewId));
}

bool _coveredAt(RenderBox control, Offset at, int viewId) {
  for (final entry in _pathAt(at, viewId)) {
    final target = entry.target;
    if (target is! RenderObject) continue;
    if (_isWithin(target, control)) return false;
    if (_isWithin(control, target)) continue;
    return _paintedOver(control, target, at);
  }
  return false;
}

// Whether [n] paints round what it holds rather than a rule along one side
// (a table header's line under its headings): a fill, or a stroke on every
// side. A paint whose shape is not known (a custom paint, a coloured box)
// is taken to.
bool _paintsRound(RenderObject n) => switch (n) {
  RenderDecoratedBox(
    decoration: BoxDecoration(
      :final color,
      :final gradient,
      :final image,
      :final border,
    ),
  ) =>
    (color?.a ?? 0) > 0 ||
        gradient != null ||
        image != null ||
        switch (border) {
          Border(:final top, :final right, :final bottom, :final left) => [
            top,
            right,
            bottom,
            left,
          ].every(_drawsSide),
          BorderDirectional(
            :final top,
            :final start,
            :final bottom,
            :final end,
          ) =>
            [top, start, bottom, end].every(_drawsSide),
          null => false,
          _ => true,
        },
  _ => true,
};

// Reads one row of controls by their drawn outlines.
// A control in a row with a face of its own: its face as laid out and its
// outline as drawn, the box that paints the face ([box]), and whether its
// outline is a bevel, its box standing for its drawn edges (global).
typedef _RowFace = ({
  RenderBox control,
  Rect laid,
  Rect drawn,
  Rect box,
  bool bevel,
});

// A control's middle as the eye reads it, in the image's pixels, as drawn
// and as laid out when known, what it is ("its icon is"), and whether it is
// an icon over or under the control's words (held to the row's other such
// icons, not to its centre line).
typedef _Middle = ({
  RenderBox control,
  double drawn,
  double? laid,
  String what,
  bool stacked,
});

class _RowReader extends _DrawnReader {
  _RowReader(this.check, super.boundary, super.pixels, super.marked);

  final DesignRowCheck check;

  // Each control whose text is drawn in the test's fallback font, by name.
  final fallback = <String>[];

  double get _ratio => check.pixelRatio;

  // A face the look paints itself is read to every pixel a person tells
  // from the ground, as its outline is: by night a raised face's black
  // bottom and right edges (#050507 on #2e2f36) stand off at 1.5 to 1,
  // though their channels are near the ground's.
  @override
  double? get _inkFloor => check.contrastFloor;

  // Whether [controls], the row in [node], are one text field's own parts:
  // its entry and the toggle, clear button or switch inside its face. One
  // face holds what they all show (a part's own face, else its words and
  // icons; not its touch target, which may overhang the field as
  // Material's do): the row's node or one under it (a field that lays out
  // its own parts), or one round it close (a card round a field and a
  // button stands off it by its padding).
  bool _oneField(RenderObject node, List<RenderBox> controls) {
    if (!controls.any((c) => _semanticsOf(c).entry)) return false;
    final all = [for (final c in controls) _shownBy(c)];
    bool holdsAll(RenderBox f) {
      final r = _global(f).inflate(1);
      return all.every(
        (a) => r.contains(a.topLeft) && r.contains(a.bottomRight),
      );
    }

    bool isFace(RenderObject n) =>
        n is RenderBox && n.hasSize && (marked.contains(n) || _showsFace(n));
    var under = false;
    void visit(RenderObject n) {
      if (under) return;
      if (isFace(n) && holdsAll(n as RenderBox)) {
        under = true;
        return;
      }
      _visitShown(n, visit);
    }

    visit(node);
    if (under) return true;
    final rowHeight = node is RenderBox && node.hasSize
        ? node.size.height
        : 0.0;
    for (RenderObject? up = node.parent; up != null; up = up.parent) {
      if (identical(up, boundary)) break;
      if (!isFace(up)) continue;
      return (up as RenderBox).size.height <= rowHeight + 12 && holdsAll(up);
    }
    return false;
  }

  // Whether the layer this reads is clear where [node]'s row stands: most
  // of the surface under it not drawn on at all, so what lies under it is
  // in a layer round this one.
  bool _clearUnder(RenderObject node) {
    final p = pixels;
    if (p == null || boundary == null) return false;
    final solid = p.solidIn(_toBoundary(_surface(node)));
    return solid.share >= 0.25 && (solid.colour & 0xFF) <= 8;
  }

  List<String> problems(RenderObject node, List<RenderBox> controls) {
    // A text field's own parts are one field, not a row.
    if (_oneField(node, controls)) return const [];
    final surface = _surface(node);
    // What the row's controls are drawn on: the surface's colour where most
    // of it is one (a shadow just around a face is not); else what is just
    // around each face (a gradient, a pane of glass).
    final solid = pixels?.solidIn(_toBoundary(surface));
    final ground = solid != null && solid.share >= 0.25 ? solid.colour : null;
    final faces = <_RowFace>[];
    final faceless = <RenderBox>[];
    final bound = boundary;
    final image = bound == null || pixels == null
        ? null
        : MatrixUtils.transformRect(
            bound.getTransformTo(null),
            Offset.zero & bound.size,
          ).inflate(0.5);
    for (final c in controls) {
      // Its middle outside the image (scrolled out of its strip): nothing
      // of it to read.
      if (image != null && !image.contains(_global(c).center)) continue;
      // Partly hidden by a clip round it (a week scrolled in its strip, its
      // weekend past the strip's edge): what shows is not its outline.
      if (_clipOf(c, throughScrolls: true) case final clip?) {
        final shown = _shownBy(c);
        final room = clip.inflate(0.5);
        if (!room.contains(shown.topLeft) ||
            !room.contains(shown.bottomRight)) {
          continue;
        }
      }
      final face = _trackOf(c) ?? _face(c) ?? _well(c, node);
      // No face of its own, or one that holds only part of what it shows (a
      // badge, an indicator under its icon): no outline to compare.
      if (face == null || !_holdsWhatItShows(face.rect, c)) {
        faceless.add(c);
        continue;
      }
      final box = face.read ? _global(face.box) : face.rect;
      if (face.read && _hasBevel(box, ground)) {
        faces.add((control: c, laid: box, drawn: box, box: box, bevel: true));
        continue;
      }
      if (face.read &&
          ground != null &&
          pixels!.hasRaisedOutline(
            _toBoundary(box),
            over: ground,
            floor: check.contrastFloor,
          )) {
        // The ground-coloured fill meets the cast at the paint box's edge.
        // Its neighbour still has its own measured outline.
        faces.add((control: c, laid: box, drawn: box, box: box, bevel: false));
        continue;
      }
      final drawn = marked.contains(face.box)
          ? null
          : _outline(box, c, face.read ? null : face.box, ground);
      // What shows of it is a mark on it, its middle left out (a tab's
      // indicator line, a badge, a sliver of a state layer): no face.
      if (drawn != null && !drawn.inflate(1).contains(face.rect.center)) {
        faceless.add(c);
        continue;
      }
      faces.add((
        control: c,
        laid: face.rect,
        drawn: drawn ?? face.rect,
        box: box,
        bevel: false,
      ));
    }
    final tallest = faces.isEmpty
        ? 0.0
        : faces.map((f) => f.laid.height).reduce(math.max);
    final row = [
      for (final f in faces)
        if (f.laid.height > tallest / 2) f,
    ]..sort((a, b) => a.laid.left.compareTo(b.laid.left));
    faceless.sort((a, b) => _global(a).left.compareTo(_global(b).left));
    if (row.length + faceless.length < 2) return const [];

    bool level(double a, double b) => (a - b).abs() * _ratio <= check.tolerance;
    // The control most of the row agrees with, top and bottom; of two, the
    // taller as drawn.
    int agreeing(Rect r) => row
        .where(
          (f) => level(f.drawn.top, r.top) && level(f.drawn.bottom, r.bottom),
        )
        .length;
    final held = row.isEmpty
        ? null
        : row.reduce((a, b) {
            final d = agreeing(b.drawn) - agreeing(a.drawn);
            if (d != 0) return d > 0 ? b : a;
            return b.drawn.height > a.drawn.height + 0.01 ? b : a;
          });
    final found = <String>[];
    if (held != null) {
      final theirs = _nameOf(held.control);
      for (final f in row) {
        if (identical(f, held)) continue;
        final who = '${_nameOf(f.control)} beside $theirs';
        // A bevel's box stands for its drawn edges, so beside one the row
        // is held as laid out.
        final bevel = f.bevel || held.bevel;
        for (final (edge, laid, drawn) in [
          ('top', f.box.top - held.box.top, f.drawn.top - held.drawn.top),
          (
            'bottom',
            f.box.bottom - held.box.bottom,
            f.drawn.bottom - held.drawn.bottom,
          ),
        ]) {
          if (bevel) {
            if (laid.abs() * _ratio <= check.tolerance) continue;
            found.add('$who: its $edge is ${_laidAgainst(laid)} as laid out');
            continue;
          }
          if (drawn.abs() * _ratio <= check.tolerance) continue;
          found.add(
            '$who: its $edge is ${_laidAgainst(laid)} as laid out, '
            '${_device(drawn * _ratio)} as drawn',
          );
        }
      }
    }

    found.addAll(_middlesIn(row, held, faceless));

    if (row.length >= 2) {
      final first = row.first;
      final last = row.last;
      // A control with no face past either end leaves the sides unread.
      final outside = faceless.any(
        (c) =>
            _global(c).right <= first.laid.left + 0.5 ||
            _global(c).left >= last.laid.right - 0.5,
      );
      final laidLeft = first.laid.left - surface.left;
      final laidRight = surface.right - last.laid.right;
      if (!outside && (laidLeft - laidRight).abs() <= 0.5) {
        final left = first.drawn.left - surface.left;
        final right = surface.right - last.drawn.right;
        if ((left - right).abs() * _ratio > check.tolerance) {
          final sides = (laidLeft - laidRight).abs() * _ratio <= check.tolerance
              ? '${_px(laidLeft)} px in'
              : '${_px(laidLeft)} px in on the left and ${_px(laidRight)} px '
                    'on the right';
          found.add(
            '${_rowName(row)}: its sides are $sides as laid out, '
            '${_px(left)} px on the left and ${_px(right)} px on the right '
            'as drawn',
          );
        }
      }
    }
    return found;
  }

  // The track [control] is drawn in with the controls beside it (a
  // segmented control's segments, a joined strip's buttons): the nearest
  // box round it that shows a face drawn round them (a fill, or a stroke
  // all round: not a table header's rule under its headings), no more than
  // 8 px round two or more controls of one kind side by side, each
  // touching the next, and holding nothing else (no other control, no
  // words or icons but theirs). Its outline is theirs to compare with a
  // row's other controls. Null otherwise.
  ({Rect rect, RenderBox box, bool read})? _trackOf(RenderBox control) {
    for (RenderObject? up = control.parent; up != null; up = up.parent) {
      if (identical(up, boundary)) return null;
      if (up is! RenderBox || !up.hasSize) continue;
      if (_isControl(up)) return null;
      final under = _controlsUnder(up);
      if (under.length < 2) continue;
      // One kind: a checkbox beside two buttons is not a set of segments.
      final kinds = {for (final c in under) _nameOf(c).split(' "').first};
      if (kinds.length > 1) return null;
      final boxes = [for (final c in under) _global(c)]
        ..sort((a, b) => a.left.compareTo(b.left));
      for (var i = 1; i < boxes.length; i++) {
        final (a, b) = (boxes[i - 1], boxes[i]);
        final overlap = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
        if (b.left - a.right > 2 ||
            b.left < a.right - 0.5 ||
            overlap < math.min(a.height, b.height) / 2) {
          return null;
        }
      }
      final shown = _shownIn(up).every((b) {
        final c = _global(b).center;
        return boxes.any((r) => r.inflate(0.5).contains(c));
      });
      if (!shown) return null;
      // A track hugs what it holds (a few pixels round them), where a card
      // or a dialog stands well off its actions.
      final all = boxes.reduce((a, b) => a.expandToInclude(b));
      final r = _global(up);
      if (all.left - r.left > 8 ||
          all.top - r.top > 8 ||
          r.right - all.right > 8 ||
          r.bottom - all.bottom > 8) {
        return null;
      }
      if (_showsFace(up) && _paintsRound(up)) {
        return (rect: r, box: up, read: !_paintsFace(up));
      }
    }
    return null;
  }

  // Whether [face] (global) holds what [control] shows: a text entry's
  // line; else its label, and every icon whole. A badge, or an indicator
  // under an icon, holds part of it only.
  bool _holdsWhatItShows(Rect face, RenderBox control) {
    final area = face.inflate(1);
    bool holds(RenderBox b) => area.contains(_global(b).center);
    final shown = _shownIn(control);
    final entry = shown.whereType<RenderEditable>().firstOrNull;
    if (entry != null) return holds(entry);
    final line = _lineOf(control, face);
    if (line != null && !holds(line)) return false;
    for (final b in shown) {
      if (b is! RenderParagraph || !isIconGlyph(lineText(b).trim())) continue;
      final g = _global(b);
      if (!area.contains(g.topLeft) || !area.contains(g.bottomRight)) {
        return false;
      }
    }
    return true;
  }

  // What the eye compares in a row against its centre line ([held]'s
  // middle, as laid out and as drawn; in a row of controls with no face,
  // the middle most of them agree with): each control's capitals (its
  // label's, or its text entry's typed text or hint), or, for a control
  // with no face and no words, its icon's middle. Icons over or under their
  // words (navigation destinations, a swiped row's actions) are held to
  // one another, the middle most of them agree with, not to the centre
  // line: a selected destination's face round its icon and words does not
  // move its neighbours' icons.
  List<String> _middlesIn(
    List<_RowFace> row,
    _RowFace? held,
    List<RenderBox> faceless,
  ) {
    final p = pixels;
    if (p == null) return const [];
    final readings = <_Middle>[];
    for (final f in row) {
      final read = _middleOf(f.control, f.laid, faceless: false);
      if (read != null) readings.add(read);
    }
    for (final c in faceless) {
      final read = _middleOf(c, _global(c), faceless: true);
      if (read != null) readings.add(read);
    }
    final level = [
      for (final r in readings)
        if (!r.stacked) r,
    ];
    final icons = [
      for (final r in readings)
        if (r.stacked) r,
    ];
    final others = [...row.map((f) => f.control), ...faceless];
    final found = <String>[];

    // Each of [among] off [centre] by more than the tolerance, named.
    void hold(
      List<_Middle> among,
      double centreDrawn,
      double centreLaid,
      RenderBox centreOf,
    ) {
      for (final r in among) {
        final drawn = r.drawn - centreDrawn;
        if (drawn.abs() <= check.tolerance) continue;
        final beside = identical(r.control, centreOf)
            ? others.firstWhere((o) => !identical(o, r.control))
            : centreOf;
        final laid = r.laid;
        final asLaid = laid == null
            ? ''
            : '${_onOrOff((laid - centreLaid) / p.ratio).replaceFirst('on it', 'on')}'
                  " the row's centre line as laid out, ";
        found.add(
          '${_nameOf(r.control)} beside ${_nameOf(beside)}: ${r.what} '
          '$asLaid${_device(drawn)} as drawn',
        );
      }
    }

    // The reading most of [among] agree with.
    _Middle mostOf(List<_Middle> among) {
      int agreeing(double m) =>
          among.where((r) => (r.drawn - m).abs() <= check.tolerance).length;
      return among.reduce(
        (a, b) => agreeing(b.drawn) > agreeing(a.drawn) ? b : a,
      );
    }

    // The held control's own words against its own face are the label
    // check's: with nothing else level to read, the row holds nothing.
    if (held != null && level.any((r) => !identical(r.control, held.control))) {
      hold(
        level,
        _toBoundary(held.drawn).center.dy * p.ratio,
        _toBoundary(held.laid).center.dy * p.ratio,
        held.control,
      );
    } else if (level.length >= 2) {
      final most = mostOf(level);
      hold(level, most.drawn, most.laid ?? most.drawn, most.control);
    }
    if (icons.length >= 2) {
      final most = mostOf(icons);
      hold(icons, most.drawn, most.laid ?? most.drawn, most.control);
    }
    return found;
  }

  // The middle [control] is read by, in the image's pixels, as drawn and as
  // laid out when known: its line's capitals (a badge's count is not its
  // line), read against what they are drawn on; or its icon's middle when
  // its words are over or under the icon (a navigation destination's label
  // under it: stacked), or, for a control with no face of its own
  // ([faceless]), when it shows an icon and no words. Null when none can be
  // read, or when the line is far from [face]'s middle or over or under
  // other words (placed there, not centred: a card's title, over its
  // body).
  _Middle? _middleOf(RenderBox control, Rect face, {required bool faceless}) {
    final p = pixels!;
    final line = _lineOf(control, face);
    final glyph = _shownIn(control)
        .whereType<RenderParagraph>()
        .where((b) => isIconGlyph(lineText(b).trim()))
        .firstOrNull;
    // Words beside the icon: on its middle and clear of it (a badge's count
    // sits on the icon's corner).
    final beside =
        line != null &&
        (glyph == null ||
            ((_global(line).center.dy - _global(glyph).center.dy).abs() <=
                    _global(glyph).height / 4 &&
                (_global(line).left >= _global(glyph).right - 0.5 ||
                    _global(line).right <= _global(glyph).left + 0.5)));
    if (beside) {
      if (!isOneLine(line)) return null;
      // Words over or under a picture (an icon tile's name, a destination's
      // label under its painted glyph) are placed, not centred.
      if (_byPicture(control, _global(line))) return null;
      final l = _global(line);
      final stacked = _shownIn(control).any((b) {
        if (identical(b, line) || b is! RenderParagraph) return false;
        if (isIconGlyph(lineText(b).trim())) return false;
        final r = _global(b);
        return r.left < l.right &&
            r.right > l.left &&
            (r.top >= l.bottom - 0.5 || r.bottom <= l.top + 0.5);
      });
      if (stacked) return null;
      // What the words are drawn on is read inside the control's own box:
      // a segment's words on the thumb sliding under it, not on the track
      // it is read by.
      final own = face.intersect(_global(control));
      final faceColour = _groundUnder(line, control, own.isEmpty ? face : own);
      if (_testFontBox(line, faceColour)) {
        fallback.add(_nameOf(control));
        return null;
      }
      final caps = _capitals(line, faceColour);
      if (caps == null) return null;
      final middle = _toBoundary(face).center.dy * p.ratio;
      if ((caps.drawn - middle).abs() / p.ratio > face.height / 4) return null;
      final words = lineText(line).trim();
      final short = words.length > 24 ? '${words.substring(0, 23)}…' : words;
      return (
        control: control,
        drawn: caps.drawn,
        laid: caps.laid,
        what: 'the capitals of "$short" are',
        stacked: false,
      );
    }
    // An icon over or under the words (a navigation destination's, a swiped
    // row's action), with a face or not; or, with no face, an icon alone.
    final stacked = line != null;
    if (glyph == null || (!faceless && !stacked)) return null;
    final drawn = _glyphMiddle(glyph);
    if (drawn == null) return null;
    return (
      control: control,
      drawn: drawn,
      laid: _toBoundary(_global(glyph)).center.dy * p.ratio,
      what: 'its icon is',
      stacked: stacked,
    );
  }

  // The face around [control] when it has none of its own (a text field's
  // well, drawn around its editable line): the nearest box between it and
  // [row] that shows one and holds no other control. A custom paint that
  // draws nothing of its own (an input decorator with no border) is not
  // one.
  ({Rect rect, RenderBox box, bool read})? _well(
    RenderBox control,
    RenderObject row,
  ) {
    for (RenderObject? up = control.parent; up != null; up = up.parent) {
      if (identical(up, row)) return null;
      if (up is! RenderBox || !up.hasSize) continue;
      if (_controlsUnder(up).length > 1) return null;
      if (!_showsFace(up)) continue;
      if (up is! RenderCustomPaint) {
        return (rect: _global(up), box: up, read: false);
      }
      final own = _ownInk(_global(up), up);
      if (own != null) return (rect: own.rect, box: up, read: own.read);
    }
    return null;
  }

  // The line a control shows: its text entry's typed text, else its first
  // label (a hint while the entry is empty) on [face] (global), else its
  // first label (a field's label over its face is its own, not its line);
  // a badge's count on a face of its own much smaller than [face] (else the
  // control's box) left out; null without one.
  RenderBox? _lineOf(RenderBox control, [Rect? face]) {
    final lines = _shownIn(control);
    for (final l in lines) {
      if (l is RenderEditable && lineText(l).trim().isNotEmpty) return l;
    }
    final rect = face ?? _global(control);
    final on = face?.inflate(1);
    RenderBox? first;
    for (final l in lines) {
      final text = lineText(l).trim();
      if (l is RenderParagraph &&
          text.isNotEmpty &&
          !isIconGlyph(text) &&
          !_inBadge(l, control, control, rect)) {
        if (on == null || on.contains(_global(l).center)) return l;
        first ??= l;
      }
    }
    return first;
  }

  // The outline drawn inside [face] (global) and inside the shape [box]
  // paints, the words, icons and text entries under [control] left out,
  // against [ground] (else what is just around the face); null without
  // pixels, or when nothing in it stands off its ground.
  Rect? _outline(Rect face, RenderBox control, RenderBox? box, int? ground) {
    final p = pixels;
    final b = boundary;
    if (p == null || b == null) return null;
    final local = _toBoundary(face);
    final shape = box == null ? null : _shapeOf(box);
    final o = p.outline(
      local,
      over: ground ?? p.groundAround(local, 2),
      floor: check.contrastFloor,
      // Words and icons, with the ink that reaches past their boxes: the
      // control's own and any drawn over the face.
      except: [
        for (final t in _shownIn(control)) _toBoundary(_global(t)).inflate(2),
        for (final t in _shownOver(face, control)) _toBoundary(t).inflate(2),
      ],
      shape: shape?.transform(box!.getTransformTo(b).storage),
    );
    return o == null
        ? null
        : MatrixUtils.transformRect(b.getTransformTo(null), o);
  }

  bool _hasBevel(Rect box, int? ground) {
    final p = pixels;
    if (p == null || boundary == null) return false;
    final local = _toBoundary(box);
    return p.hasBevel(
      local,
      over: ground ?? p.groundAround(local, 2),
      floor: check.contrastFloor,
    );
  }

  // [drawn], the outline read inside [face] (both global), out to [face]'s
  // edge on each side it stops short of over a band of the face itself. A
  // band painted in the face's own fill (the commonest colour inside
  // [drawn]) is the face round a frame drawn inside it, however faint that
  // fill is against its ground ([ground], else what is just around
  // [face]). A lit band is the face too: a face lit from one corner (a
  // groove under a light from the top left) shows its far sides in a
  // highlight too faint to stand off, lighter than its ground. A darker
  // band of another colour (a shadow cast inside the box) stays out.
  Rect _litTo(Rect face, Rect drawn, {int? ground}) {
    final p = pixels;
    if (p == null || boundary == null) return drawn;
    final over = ground ?? p.groundAround(_toBoundary(face), 2);
    final fill = p.solidIn(_toBoundary(drawn)).colour;
    bool lit(Rect band) {
      final local = _toBoundary(band);
      return p.paintedIn(local, colour: fill, over: over) ||
          p.lit(local, over: over);
    }

    var (left, top, right, bottom) = (
      drawn.left,
      drawn.top,
      drawn.right,
      drawn.bottom,
    );
    if (drawn.left - face.left > 0.5 &&
        lit(Rect.fromLTRB(face.left, drawn.top, drawn.left, drawn.bottom))) {
      left = face.left;
    }
    if (face.right - drawn.right > 0.5 &&
        lit(Rect.fromLTRB(drawn.right, drawn.top, face.right, drawn.bottom))) {
      right = face.right;
    }
    if (drawn.top - face.top > 0.5 &&
        lit(Rect.fromLTRB(drawn.left, face.top, drawn.right, drawn.top))) {
      top = face.top;
    }
    if (face.bottom - drawn.bottom > 0.5 &&
        lit(
          Rect.fromLTRB(drawn.left, drawn.bottom, drawn.right, face.bottom),
        )) {
      bottom = face.bottom;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  // The shape [face] paints in, in its own coordinates: its decoration's,
  // or its physical shape's; null for a face of another kind (a custom
  // paint, a backdrop), read by its box.
  static Path? _shapeOf(RenderBox face) {
    final box = Offset.zero & face.size;
    try {
      return switch (face) {
        RenderDecoratedBox(:final decoration) => decoration.getClipPath(
          box,
          TextDirection.ltr,
        ),
        RenderPhysicalShape(:final clipper) => clipper?.getClip(face.size),
        RenderPhysicalModel(:final shape, :final borderRadius) =>
          shape == BoxShape.circle
              ? (Path()..addOval(box))
              : (Path()
                  ..addRRect((borderRadius ?? BorderRadius.zero).toRRect(box))),
        _ => null,
      };
    } on UnsupportedError {
      return null;
    }
  }

  // The surface a row is laid out on: the nearest face around it, else its
  // repaint boundary (the screen).
  Rect _surface(RenderObject node) {
    for (RenderObject? up = node; up != null; up = up.parent) {
      if (up is RenderBox && up.hasSize) {
        if (identical(up, boundary)) return _global(up);
        if (!_isControl(up) && _showsFace(up)) return _global(up);
      }
    }
    return _global(boundary!);
  }

  static String _rowName(List<_RowFace> row) {
    final names = [for (final f in row) _nameOf(f.control)];
    return switch (names.length) {
      2 => 'a row of ${names[0]} and ${names[1]}',
      3 => 'a row of ${names[0]}, ${names[1]} and ${names[2]}',
      _ =>
        'a row of ${names.length} controls from ${names.first} to '
            '${names.last}',
    };
  }

  // "level with theirs", "2 px below theirs".
  static String _laidAgainst(double v) => _px(v).replaceFirst('-', '') == '0'
      ? 'level with theirs'
      : '${_px(v, signed: true)} theirs';

  static String _device(double v) {
    final s = v.abs().toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
    return '$s device px ${v > 0 ? 'below' : 'above'}';
  }
}

// What the row check reads of the drawn ground under a label.
extension on _DrawnReader {
  // The colour [line]'s words are drawn on: the one colour most of the
  // innermost box round them, inside [control], is, when it paints a face
  // at least twice their size in one colour and that colour shows just
  // round the words (a badge's pill, a swiped row's surface over its
  // action); else the commonest inside [face] (global). A layer of glass or
  // a gradient is no one colour, and one under a sheen does not show: both
  // are passed by.
  int _groundUnder(RenderBox line, RenderBox control, Rect face) {
    final p = pixels!;
    final l = _global(line);
    final around = p.groundAround(_toBoundary(l), 2);
    for (RenderObject? up = line.parent; up != null; up = up.parent) {
      if (identical(up, control) || identical(up, boundary)) break;
      if (up is! RenderBox || !up.hasSize || !_showsFace(up)) continue;
      final r = _global(up);
      if (r.width * r.height < 2 * l.width * l.height) continue;
      final solid = p.solidIn(_toBoundary(r));
      if (solid.share >= 0.5 && DrawnPixels.alike(solid.colour, around)) {
        return solid.colour;
      }
    }
    return _faceGround(face, l);
  }
}
