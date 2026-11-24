part of '../../review.dart';

/// Whether the content of each [RawKeylineRegion] on a screen starts on
/// one leading keyline and ends on one trailing keyline (or on an indent
/// the region declares), and whether controls that share a row there share
/// a height and a centre line, by their faces' boxes ([DesignRowCheck] holds
/// a row's controls by their drawn outlines).
///
/// What it reads, in the reading direction (leading is the right edge in
/// right to left):
/// - a text by its lines' boxes, so a centred or an end-aligned line reads
///   where it is drawn, and side bearings do not count. A text whose lines
///   are narrower than its box (wrapped, or short in a wide box) is
///   anchored only to the side it is aligned to: its other end is ragged,
///   and a centred one is anchored to neither;
/// - an icon that starts a row by its layout box (a column of icons shares
///   a centre, not an ink edge); a bare icon that ends a row (a chevron, a
///   "more") by its ink, which is what ends on the keyline while its tap box
///   hangs out;
/// - a control by its face: a [RawKeylineFace] in it, or else the
///   largest box inside it that paints a decoration, a colour, a material, a
///   backdrop or a custom paint. A shadow outside that box never counts; a
///   custom paint (a switch's track, a checkbox in its 48 px tap box) is
///   read from what it draws itself inside its box, not the words and icons
///   over it, and where that is only part of the face (a shadow under a
///   face the colour of the ground) the control runs on to what it shows,
///   its icon by its box. A control with no face (a text button) is read by
///   what it shows;
/// - any other box that paints a face as one item at that face, whatever
///   it holds: an avatar, a chip, an inset divider, a field's well around
///   its editable, a list's or a table's well, a segmented control's track.
///   Nothing inside a face is an item of the region around it (a
///   [RawKeylineRegion] inside one is judged on its own). A face across
///   the region from side to side and at least half its height is the
///   region's ground, and what it holds is read. A `Container`'s colour
///   counts where it differs from what is around it; a box the colour of
///   what is around it is not an item, and what it holds is;
/// - a [RawKeylineFace] as one item at its box, before its pixels are
///   looked at, unless it fills the region. A look marks its face and well
///   widgets with it where their pixels cannot show them (a face the colour
///   of the ground drawn only by shadows, glass), and a picture with things
///   placed on it (a floor plan with its room keys) to have it read as one
///   box;
/// - a nested region as one item.
///
/// Ink is what differs from the colour just around the box it is read in,
/// so a face over a gradient or a picture reads as it is drawn.
///
/// Items whose extents overlap vertically share a row. An edge is judged
/// only on the side its item is anchored to: a row's first run of items (up
/// to a gap of 24 px or more) is anchored to the leading side and its last
/// run to the trailing side. A row of one run is anchored to the side it is
/// nearer, to both when it spans two thirds of the region, and to neither
/// when it is centred or touches both of the region's edges (a picture, a
/// full-bleed divider); a side it touches is not judged. A run whose end is
/// ragged is not held at that end by reaching across: a text's, a `Wrap`'s
/// run of items (chips over two lines, each keeping to its words), and a
/// group of two or more choices side by side. In a region marked
/// [RawKeylineRegion.startAligned] (a gallery section's column of
/// examples), what starts each row is held to the leading keyline however
/// it is aligned, so an example centred in its column (a stepper, a sum, a
/// line of words centred in its box) or set in from it is off.
///
/// Check a gallery's pages as well as an app's screens: a look marks each
/// gallery section's column with a start-aligned region, and its examples
/// are read as an app's cards are.
///
/// Before either check, a test loads every font family the look ships (each
/// family in the package's FontManifest.json: a family left out is drawn in
/// the test's own font, whose missing glyph stands on the baseline) and lets
/// the screen's images decode, then draws the frame they land in (a check
/// that meets a screen repainted since its last frame says so and stops):
///
/// ```dart
/// await tester.runAsync(() => Future.wait([
///   for (final e in find.byType(Image).evaluate())
///     precacheImage((e.widget as Image).image, e),
/// ]));
/// await tester.pump();
/// ```
///
/// (A `DecorationImage`'s image is decoded the same way.) Only what is
/// painted is read: an [IndexedStack]'s other children, an [Offstage]'s
/// while off stage, a fully transparent [Opacity]'s, a [Transform]'s
/// scaled to nothing, a [Visibility]'s kept state and a list's rows laid out past what it shows (its cache
/// extent, a wheel's hidden items) are laid out but not on screen, and
/// the rest of the screen is read without them.
///
/// A test pumps a screen, then:
///
/// ```dart
/// final report = await const DesignKeylineCheck(look: 'Comic').check(
///   tester.element(find.byType(SettingsScreen)),
///   runAsync: tester.runAsync,
/// );
/// report.verify();
/// ```
///
/// It reads layout boxes, and the drawn pixels where only they show it (a
/// face's painted edge), so it takes the tester's `runAsync`.
@immutable
class DesignKeylineCheck {
  /// A check for [look].
  const DesignKeylineCheck({
    required this.look,
    this.tolerance = 1,
    this.pixelRatio = 3,
  });

  /// The look's name, for messages.
  final String look;

  /// How far, in logical pixels, an edge may sit from its keyline, and the
  /// heights and centres of a row's controls from each other.
  final double tolerance;

  /// The scale faces and icons are drawn at to read their pixels.
  final double pixelRatio;

  /// Measures every [RawKeylineRegion] under [context] (the regions
  /// must be on screen, under a repaint boundary as every route is) and
  /// reports each edge off its region's keylines and each row of controls
  /// whose heights or centres differ. A test passes its tester's `runAsync`
  /// (reading pixels takes real time); null reads them directly, as an app
  /// does.
  Future<DesignAlignmentReport> check(
    BuildContext context, {
    Future<T?> Function<T>(Future<T> Function() work)? runAsync,
  }) async {
    final regions = await _measureKeylines(this, context, runAsync);
    return DesignAlignmentReport(look, [
      for (final r in regions) ...r.problems,
    ]);
  }
}

/// Draws [child] with each [RawKeylineRegion] in it outlined, its
/// keylines (leading blue, trailing green) and every edge off them (red),
/// for a look's review page. It measures after each layout of [child]
/// (reading pixels takes a moment), so the lines appear a frame late.
class DesignKeylineSheet extends StatefulWidget {
  /// A sheet over [child].
  const DesignKeylineSheet({
    super.key,
    required this.child,
    this.check = const DesignKeylineCheck(look: ''),
  });

  /// The screen.
  final Widget child;

  /// How it measures.
  final DesignKeylineCheck check;

  @override
  State<DesignKeylineSheet> createState() => _DesignKeylineSheetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<DesignKeylineCheck>(
        'check',
        check,
        defaultValue: const DesignKeylineCheck(look: ''),
      ),
    );
  }
}

class _DesignKeylineSheetState extends State<DesignKeylineSheet> {
  final _screen = GlobalKey();
  List<_KeylineRegion> _regions = const [];
  int _pass = 0;
  Size? _measured;

  void _measure() {
    final pass = ++_pass;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final screen = _screen.currentContext;
      if (!mounted || screen == null || pass != _pass) return;
      final regions = await _measureKeylines(widget.check, screen, null);
      if (mounted && pass == _pass) setState(() => _regions = regions);
    });
  }

  @override
  void initState() {
    super.initState();
    _measure();
  }

  @override
  void didUpdateWidget(DesignKeylineSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _measure();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      if (_measured != size) {
        _measured = size;
        _measure();
      }
      return CustomPaint(
        foregroundPainter: _KeylinePainter(_regions, _screen),
        child: KeyedSubtree(key: _screen, child: widget.child),
      );
    },
  );
}

class _KeylinePainter extends CustomPainter {
  _KeylinePainter(this.regions, this.screen);

  final List<_KeylineRegion> regions;
  final GlobalKey screen;

  @override
  void paint(Canvas canvas, Size size) {
    final box = screen.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    Rect local(Rect r) => r.shift(-origin);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x99808080);
    final leading = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFF1E88E5);
    final trailing = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFF43A047);
    final off = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFE53935);
    for (final r in regions) {
      final area = local(r.box);
      canvas.drawRect(area.deflate(0.5), outline);
      for (final (x, paint) in [
        for (final x in r.leadingLines) (x, leading),
        for (final x in r.trailingLines) (x, trailing),
      ]) {
        final lx = x - origin.dx;
        canvas.drawLine(Offset(lx, area.top), Offset(lx, area.bottom), paint);
      }
      for (final o in r.offenders) {
        canvas.drawRect(local(o).inflate(2), off);
      }
    }
  }

  @override
  bool shouldRepaint(_KeylinePainter oldDelegate) =>
      !identical(oldDelegate.regions, regions);
}

// One region as measured: its box, its keylines (global x), the rectangles
// of what is off them, and the problems.
class _KeylineRegion {
  _KeylineRegion(
    this.box,
    this.leadingLines,
    this.trailingLines,
    this.offenders,
    this.problems,
  );

  final Rect box;
  final List<double> leadingLines;
  final List<double> trailingLines;
  final List<Rect> offenders;
  final List<String> problems;
}

enum _ItemKind { text, icon, control, surface, region }

// What a region holds, in global coordinates. [lead] is the edge read at
// the leading side, [trail] the one read at the trailing side (an icon's
// ink there).
class _KeylineItem {
  _KeylineItem(
    this.kind,
    this.name,
    this.box, {
    Rect? trail,
    this.leads = true,
    this.trails = true,
    bool? ragged,
    this.choice = false,
  }) : trail = trail ?? box,
       ragged = ragged ?? kind == _ItemKind.text;

  // This item with its end ragged.
  _KeylineItem raggedAtEnd() => _KeylineItem(
    kind,
    name,
    box,
    trail: trail,
    leads: leads,
    trails: trails,
    ragged: true,
    choice: choice,
  );

  final _ItemKind kind;
  final String name;
  final Rect box;
  final Rect trail;

  // The sides it is anchored to: a text aligned in a box wider than its
  // lines is anchored only to the side it is aligned to (its other end is
  // ragged), a centred one to neither.
  final bool leads;
  final bool trails;

  // Whether its end is where its words end (a text, a checkbox read to the
  // end of its label), or where a wrap's run of items happens to end:
  // ragged, so not anchored by reaching across.
  final bool ragged;

  // Whether it is a choice (selected or one of a group): a run of two or
  // more, each keeping to its words, ends where its last does.
  final bool choice;
}

Future<List<_KeylineRegion>> _measureKeylines(
  DesignKeylineCheck check,
  BuildContext context,
  Future<T?> Function<T>(Future<T> Function() work)? runAsync,
) async {
  final regions = <(RawKeylineRegion, RenderBox, TextDirection)>[];
  final marked = <RenderBox>{};
  void visit(Element element) {
    final widget = element.widget;
    if (widget is RawKeylineFace) {
      final box = element.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize && _isShown(box)) {
        marked.add(box);
      }
    }
    if (widget is RawKeylineRegion) {
      final box = element.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize && _isShown(box)) {
        regions.add((
          widget,
          box,
          Directionality.maybeOf(element) ?? TextDirection.ltr,
        ));
      }
    }
    element.visitChildElements(visit);
  }

  if (context is Element) visit(context);
  final named = {for (final (w, box, _) in regions) box: w};
  final pixels = <RenderRepaintBoundary, DrawnPixels?>{};
  Future<DrawnPixels?> pixelsOf(RenderRepaintBoundary boundary) async {
    if (pixels.containsKey(boundary)) return pixels[boundary];
    return pixels[boundary] = await DrawnPixels.read(
      boundary,
      check.pixelRatio,
      runAsync,
    );
  }

  final measured = <_KeylineRegion>[];
  for (final (i, (region, box, direction)) in regions.indexed) {
    RenderObject? up = box;
    while (up != null && up is! RenderRepaintBoundary) {
      up = up.parent;
    }
    final boundary = up as RenderRepaintBoundary?;
    // A region in a boundary never painted, or painted no longer, shows
    // nothing to measure.
    if (boundary != null && !DrawnPixels.inFrame(boundary)) continue;
    final drawn = boundary == null ? null : await pixelsOf(boundary);
    measured.add(
      _KeylineReader(
        check,
        region,
        region.label ?? 'region ${i + 1}',
        box,
        direction,
        named,
        boundary,
        drawn,
        marked,
      ).read(),
    );
  }
  return measured;
}

// Reads one region.
class _KeylineReader extends _DrawnReader {
  _KeylineReader(
    this.check,
    this.region,
    this.name,
    this.box,
    this.direction,
    this.named,
    super.boundary,
    super.pixels,
    super.marked,
  ) : area = _global(box);

  final DesignKeylineCheck check;
  final RawKeylineRegion region;
  final String name;
  final RenderBox box;
  final TextDirection direction;
  final Map<RenderBox, RawKeylineRegion> named;
  final Rect area;

  double get tolerance => check.tolerance;
  bool get rtl => direction == TextDirection.rtl;

  _KeylineRegion read() {
    final items = <_KeylineItem>[];
    _collect(box, items, top: true);
    items.removeWhere((i) => !i.box.overlaps(area.inflate(tolerance)));
    final leads = <(_KeylineItem, double)>[];
    final trails = <(_KeylineItem, double)>[];
    final problems = <String>[];
    final rows = _rows(items);
    for (final row in rows) {
      _anchor(row, leads, trails);
      problems.addAll(_controlsIn(row));
    }
    final offenders = <Rect>[];
    final (leadLines, leadOff) = _keylines(leads, region.indents);
    final (trailLines, trailOff) = _keylines(trails, region.trailingIndents);
    String lines(List<double> l) => l.map((x) => '${_px(x)} px').join(' or ');
    for (final (item, inset) in leadOff) {
      offenders.add(item.box);
      problems.add(
        '$name: ${item.name} starts ${_px(inset)} px in; the leading '
        'keyline is ${lines(leadLines)} in',
      );
    }
    for (final (item, inset) in trailOff) {
      offenders.add(item.trail);
      problems.add(
        '$name: ${item.name} ends ${_px(inset)} px in; the trailing keyline '
        'is ${lines(trailLines)} in',
      );
    }
    final reason = region.mixedHeights;
    if (reason != null && isToDoReason(reason)) {
      problems.add(
        '$name: "$reason" is a to-do, not a reason its controls '
        'differ',
      );
    }
    double x(double inset, {required bool lead}) =>
        lead != rtl ? area.left + inset : area.right - inset;
    return _KeylineRegion(
      area,
      [for (final l in leadLines) x(l, lead: true)],
      [for (final l in trailLines) x(l, lead: false)],
      offenders,
      problems,
    );
  }

  // The leading inset of [r] from the region's leading edge, and the
  // trailing one.
  double _leadInset(Rect r) => rtl ? area.right - r.right : r.left - area.left;
  double _trailInset(Rect r) => rtl ? r.left - area.left : area.right - r.right;

  void _collect(
    RenderObject node,
    List<_KeylineItem> items, {
    bool top = false,
  }) {
    if (node is RenderOffstage && node.offstage) return;
    if (node is RenderOpacity && node.opacity == 0) return;
    if (node is RenderAnimatedOpacity && node.opacity.value == 0) return;
    if (_scaledAway(node)) return;
    if (node is RenderBox && node.hasSize && !top) {
      final nested = named[node];
      if (nested != null) {
        items.add(
          _KeylineItem(
            _ItemKind.region,
            nested.label ?? 'a nested region',
            _global(node),
          ),
        );
        return;
      }
      // A wrap's items (chips over two lines) keep to their own widths, so
      // each run ends where its last item does: ragged, as wrapped words
      // are, unless the wrap sets its runs at the end.
      if (node is RenderWrap &&
          node.direction == Axis.horizontal &&
          node.alignment != WrapAlignment.end) {
        final held = <_KeylineItem>[];
        _visitShown(node, (child) => _collect(child, held));
        items.addAll(held.map((i) => i.raggedAtEnd()));
        return;
      }
      if (node is RenderParagraph) {
        final item = _text(node);
        if (item != null) items.add(item);
        return;
      }
      if (node is RenderEditable) {
        final item = _editable(node);
        if (item != null) items.add(item);
        return;
      }
      if (_isControl(node)) {
        final face = _face(node);
        if (face != null) {
          final name = _nameOf(node);
          final item = face.read
              ? _grown(_ItemKind.control, name, face.rect, node)
              : _KeylineItem(_ItemKind.control, name, face.rect);
          items.add(
            _semanticsOf(node).choice
                ? _KeylineItem(
                    item.kind,
                    item.name,
                    item.box,
                    trail: item.trail,
                    ragged: item.ragged,
                    choice: true,
                  )
                : item,
          );
          return;
        }
      } else if (_showsFace(node)) {
        final r = _global(node);
        final mark = marked.contains(node);
        final own = mark || node is! RenderCustomPaint
            ? (rect: r, read: false)
            : _ownInk(r, node);
        if (own != null && !_isGround(r, marked: mark)) {
          // One item at its face, whatever it holds: a control's well, a
          // list's or a table's, a segmented control's track.
          final controls = _controlsUnder(node);
          final only = controls.length == 1 && _holdsOnly(node, controls.single)
              ? controls.single
              : null;
          final kind = only == null ? _ItemKind.surface : _ItemKind.control;
          final name = only == null ? _surfaceName(node) : _nameOf(only);
          items.add(
            own.read
                ? _grown(kind, name, own.rect, node)
                : _KeylineItem(kind, name, own.rect),
          );
          return;
        }
      }
    }
    _visitShown(node, (child) => _collect(child, items));
  }

  // Whether a face at [r] is the region's ground, under its content rather
  // than an item of it: one across the region from side to side and at
  // least half its height; one a look marked only when it fills the region.
  bool _isGround(Rect r, {required bool marked}) {
    final across = _leadInset(r) <= tolerance && _trailInset(r) <= tolerance;
    if (!marked) return across && r.height >= area.height / 2;
    return across &&
        r.top <= area.top + tolerance &&
        r.bottom >= area.bottom - tolerance;
  }

  // Whether every word [node] shows is inside [control]: its face is that
  // control's (a field's well around its editable).
  bool _holdsOnly(RenderObject node, RenderBox control) {
    final within = _global(control).inflate(1);
    for (final p in _shownIn(node)) {
      final g = _global(p);
      if (!within.contains(g.topLeft) ||
          !within.contains(g.bottomRight - const Offset(0.01, 0.01))) {
        return false;
      }
    }
    return true;
  }

  // An item whose face was read from what a custom paint draws, which may
  // be only part of it (a shadow under a face the colour of the ground):
  // grown by what [holder] shows, read as it is anywhere (words by their
  // lines, an icon by its box, a bare icon at the trailing side by its ink).
  _KeylineItem _grown(
    _ItemKind kind,
    String name,
    Rect face,
    RenderObject holder,
  ) {
    var box = face;
    var trail = face;
    for (final p in _shownIn(holder)) {
      final t = p is RenderParagraph
          ? _text(p)
          : _editable(p as RenderEditable);
      if (t == null) continue;
      box = box.expandToInclude(t.box);
      trail = trail.expandToInclude(t.trail);
    }
    // Ended by its words: its end is ragged.
    final ragged = _trailInset(trail) < _trailInset(face) - tolerance;
    return _KeylineItem(kind, name, box, trail: trail, ragged: ragged);
  }

  _KeylineItem? _text(RenderParagraph p) {
    final text = p.text.toPlainText(includeSemanticsLabels: false);
    final words = text.trimRight();
    if (words.trim().isEmpty) return null;
    if (isIconGlyph(words.trim())) {
      final r = _global(p);
      return _KeylineItem(_ItemKind.icon, 'an icon', r, trail: _ink(r));
    }
    final lines = p.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: words.length),
    );
    return _lines(p, lines, words, p.textAlign, p.textDirection);
  }

  _KeylineItem? _editable(RenderEditable e) {
    final words = (e.text?.toPlainText(includeSemanticsLabels: false) ?? '')
        .trimRight();
    if (words.trim().isEmpty) return null;
    return _lines(
      e,
      e.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: words.length),
      ),
      words,
      e.textAlign,
      e.textDirection,
    );
  }

  _KeylineItem? _lines(
    RenderBox b,
    List<TextBox> lines,
    String words,
    TextAlign align,
    TextDirection textDirection,
  ) {
    if (lines.isEmpty) return null;
    final m = b.getTransformTo(null);
    final bounds = _global(b);
    Rect? all;
    for (final l in lines) {
      // A wrapped line's last space can hang outside the box: not drawn.
      final r = MatrixUtils.transformRect(m, l.toRect()).intersect(bounds);
      if (r.width < 0 || r.height < 0) continue;
      all = all == null ? r : all.expandToInclude(r);
    }
    if (all == null) return null;
    final short = words.length > 24 ? '${words.substring(0, 23)}…' : words;
    // Lines narrower than their box are aligned in it: anchored only to the
    // side they are aligned to.
    var (left, right) = (true, true);
    if (all.width < bounds.width - tolerance) {
      final ltr = textDirection == TextDirection.ltr;
      (left, right) = switch (align) {
        TextAlign.left => (true, false),
        TextAlign.right => (false, true),
        TextAlign.center => (false, false),
        TextAlign.start || TextAlign.justify => (ltr, !ltr),
        TextAlign.end => (!ltr, ltr),
      };
    }
    final leads = rtl ? right : left;
    final trails = rtl ? left : right;
    return _KeylineItem(
      _ItemKind.text,
      '"${short.trim()}"',
      all,
      leads: leads,
      trails: trails,
      // Its end is ragged unless it is aligned to the trailing side.
      ragged: leads || !trails,
    );
  }

  static String _surfaceName(RenderBox b) {
    if (b.size.height <= 2 || b.size.width <= 2) return 'a divider';
    String? words;
    void visit(RenderObject n) {
      if (words != null) return;
      if (n is RenderParagraph) {
        final t = n.text.toPlainText(includeSemanticsLabels: false).trim();
        if (t.isNotEmpty && !isIconGlyph(t)) words = t;
      }
      _visitShown(n, visit);
    }

    visit(b);
    return words == null ? 'a surface' : 'the surface of "$words"';
  }

  // Items whose vertical extents overlap, in reading order within each.
  List<List<_KeylineItem>> _rows(List<_KeylineItem> items) {
    final sorted = [...items]..sort((a, b) => a.box.top.compareTo(b.box.top));
    final rows = <(double, double, List<_KeylineItem>)>[];
    for (final item in sorted) {
      final top = item.box.top;
      final bottom = math.max(item.box.bottom, top + 1);
      final last = rows.isEmpty ? null : rows.last;
      if (last != null && top < last.$2 - 0.5) {
        rows[rows.length - 1] = (
          last.$1,
          math.max(last.$2, bottom),
          [...last.$3, item],
        );
      } else {
        rows.add((top, bottom, [item]));
      }
    }
    return [
      for (final (_, _, row) in rows)
        row..sort((a, b) => _leadInset(a.box).compareTo(_leadInset(b.box))),
    ];
  }

  // Adds the edges [row] is judged on.
  void _anchor(
    List<_KeylineItem> row,
    List<(_KeylineItem, double)> leads,
    List<(_KeylineItem, double)> trails,
  ) {
    // Runs: items up to a gap of 24 px or more.
    final runs = <List<_KeylineItem>>[
      [row.first],
    ];
    var reach = _leadInset(row.first.box) + _width(row.first.box);
    for (final item in row.skip(1)) {
      final start = _leadInset(item.box);
      if (start - reach >= 24) {
        runs.add([item]);
      } else {
        runs.last.add(item);
      }
      reach = math.max(reach, start + _width(item.box));
    }
    _KeylineItem last(List<_KeylineItem> run) => run.reduce(
      (a, b) => _trailInset(a.trail) <= _trailInset(b.trail) ? a : b,
    );
    // A start-aligned region (a gallery section's examples) holds what
    // starts each row to its leading keyline, however it is aligned.
    final always = region.startAligned;
    void lead(_KeylineItem i) {
      final inset = _leadInset(i.box);
      if ((i.leads || always) && inset > tolerance) leads.add((i, inset));
    }

    void trail(_KeylineItem i) {
      final inset = _trailInset(i.trail);
      if (i.trails && inset > tolerance) trails.add((i, inset));
    }

    if (runs.length > 1) {
      // The first run is the leading side's when it stands on that side,
      // the last the trailing side's likewise (not a quiet button before
      // the default at the end of a row).
      final first = runs.first.first;
      final end = last(runs.last);
      final firstEnd = last(runs.first);
      if (always || _leadInset(first.box) <= _trailInset(firstEnd.trail)) {
        lead(first);
      }
      if (_trailInset(end.trail) <= _leadInset(runs.last.first.box)) {
        trail(end);
      }
      return;
    }
    final run = runs.single;
    final first = run.first;
    final end = last(run);
    final l = _leadInset(first.box);
    final t = _trailInset(end.trail);
    if (l <= tolerance && t <= tolerance) return;
    // A group of choices, each keeping to its words, ends where its last
    // does.
    final ragged =
        end.ragged || (end.choice && run.where((i) => i.choice).length >= 2);
    if (always) {
      // Centred or set at the end, it is off its column's edge.
      lead(first);
      if (area.width - l - t >= area.width * 2 / 3 && !ragged) trail(end);
      return;
    }
    if (area.width - l - t >= area.width * 2 / 3) {
      // Across the region: anchored to both sides, but for a ragged end.
      lead(first);
      if (!ragged) trail(end);
    } else if ((l - t).abs() <= math.max(tolerance, 2)) {
      return;
    } else if (l < t) {
      lead(first);
    } else {
      trail(end);
    }
  }

  static double _width(Rect r) => r.width;

  // Keylines from [edges] (insets): the first keyline the one most edges
  // sit on with [indents] (the outermost of equals); the edges off them.
  (List<double>, List<(_KeylineItem, double)>) _keylines(
    List<(_KeylineItem, double)> edges,
    List<double> indents,
  ) {
    if (edges.isEmpty) return (const [], const []);
    bool on(double inset, double base) =>
        (inset - base).abs() <= tolerance ||
        indents.any((i) => (inset - base - i).abs() <= tolerance);
    double? best;
    var most = -1;
    for (final (_, base) in edges) {
      final n = edges.where((e) => on(e.$2, base)).length;
      if (n > most || (n == most && base < best!)) {
        most = n;
        best = base;
      }
    }
    final base = best!;
    return (
      [base, for (final i in indents) base + i],
      [
        for (final e in edges)
          if (!on(e.$2, base)) e,
      ],
    );
  }

  // The problems of a row's controls: one height and one centre line.
  List<String> _controlsIn(List<_KeylineItem> row) {
    final controls = [
      for (final i in row)
        if (i.kind == _ItemKind.control) i,
    ];
    if (controls.length < 2 || region.mixedHeights != null) return const [];
    final found = <String>[];
    final tall = controls.reduce(
      (a, b) => a.box.height >= b.box.height ? a : b,
    );
    final short = controls.reduce(
      (a, b) => a.box.height < b.box.height ? a : b,
    );
    if (tall.box.height - short.box.height > tolerance) {
      found.add(
        '$name: in one row, ${tall.name} is ${_px(tall.box.height)} px high '
        'and ${short.name} ${_px(short.box.height)} px',
      );
    }
    final low = controls.reduce(
      (a, b) => a.box.center.dy >= b.box.center.dy ? a : b,
    );
    final high = controls.reduce(
      (a, b) => a.box.center.dy < b.box.center.dy ? a : b,
    );
    final apart = low.box.center.dy - high.box.center.dy;
    if (apart > tolerance) {
      found.add(
        "$name: in one row, ${low.name}'s centre is ${_px(apart)} px below "
        "${high.name}'s",
      );
    }
    return found;
  }
}
