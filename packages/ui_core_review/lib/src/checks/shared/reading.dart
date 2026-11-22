part of '../../review.dart';

// [v] in pixels for a message, to a tenth; [signed]: "2 px below" or
// "2 px above".
String _px(double v, {bool signed = false}) {
  final s = v.abs().toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  if (!signed) return v < 0 ? '-$s' : s;
  return '$s px ${v > 0 ? 'below' : 'above'}';
}

// What a look's page gives its controls before the look's theme does: a
// text direction and the view's media.
class _Page extends StatelessWidget {
  const _Page({required this.theme, required this.child});

  final DesignAlignmentTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.fromView(
    view: View.of(context),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(builder: (context) => theme(context, child)),
    ),
  );
}

// A text a control shows: a label or an icon's glyph.
class _TextBox {
  _TextBox(this.box, {required this.icon});

  final RenderBox box;
  final bool icon;

  // Its first line's alphabetic baseline, from its top; null when it holds
  // widgets inline, whose layout only its own pass knows.
  double? get baseline => laidBaseline(box);

  // Whether it is one line high: the engine rounds each line's baseline
  // from that line's own top, so only a single line's rounding is its
  // first baseline's.
  bool get oneLine {
    final line = switch (box) {
      final RenderParagraph p => p.getFullHeightForCaret(
        const TextPosition(offset: 0),
      ),
      final RenderEditable e => e.preferredLineHeight,
      _ => 0.0,
    };
    return line > 0 && box.size.height < line * 1.5;
  }
}

// What the clips round [node] leave of the screen, global: each box above
// it that clips what it paints (its paint clip), and the screen's edge; up
// to the first box that scrolls (a viewport) unless [throughScrolls]. Null
// when nothing clips it.
Rect? _clipOf(RenderObject node, {required bool throughScrolls}) {
  Rect? clip;
  RenderObject child = node;
  for (var up = node.parent; up != null; up = up.parent) {
    if (!throughScrolls && up is RenderAbstractViewport) return clip;
    if (up.describeApproximatePaintClip(child) case final r?) {
      final global = MatrixUtils.transformRect(up.getTransformTo(null), r);
      clip = clip == null ? global : clip.intersect(global);
    }
    if (up.parent == null && child is RenderBox && child.hasSize) {
      final screen = _global(child);
      clip = clip == null ? screen : clip.intersect(screen);
    }
    child = up;
  }
  return clip;
}

// What [control]'s semantics say about it, from it and the boxes under it
// short of another control.
({
  bool entry,
  bool search,
  bool slider,
  bool toggle,
  bool link,
  bool tab,
  bool expanded,
  bool choice,
  bool radio,
  bool steps,
  bool disabled,
})
_semanticsOf(RenderBox control) {
  var entry = false, slider = false, toggle = false, link = false;
  var tab = false, expanded = false, choice = false, steps = false;
  var radio = false, search = false, disabled = false;
  void visit(RenderObject n) {
    if (n is RenderEditable) entry = true;
    if (n is RenderSemanticsAnnotations) {
      final p = n.properties;
      entry = entry || p.textField == true;
      search = search || p.inputType == SemanticsInputType.search;
      slider = slider || p.slider == true;
      toggle = toggle || p.toggled != null || p.checked != null;
      link = link || p.link == true;
      tab = tab || p.role == SemanticsRole.tab;
      expanded = expanded || p.expanded != null;
      choice =
          choice || p.selected != null || p.inMutuallyExclusiveGroup == true;
      radio = radio || p.inMutuallyExclusiveGroup == true;
      steps = steps || p.onIncrease != null || p.onDecrease != null;
      disabled = disabled || p.enabled == false;
    }
    n.visitChildren(visit);
  }

  visit(control);
  // A tab's role said round its pressable (a tab bar's `Semantics(role:
  // SemanticsRole.tab)` over each tab): up to the first box holding
  // another control.
  bool holdsAnother(RenderObject node) {
    var found = false;
    void look(RenderObject n) {
      if (found || identical(n, control)) return;
      if (_isControl(n)) {
        found = true;
        return;
      }
      n.visitChildren(look);
    }

    node.visitChildren(look);
    return found;
  }

  for (RenderObject? up = control.parent; !tab && up != null; up = up.parent) {
    if (_isControl(up) || holdsAnother(up)) break;
    if (up is RenderSemanticsAnnotations &&
        up.properties.role == SemanticsRole.tab) {
      tab = true;
    }
  }
  return (
    entry: entry,
    search: search,
    slider: slider,
    toggle: toggle,
    link: link,
    tab: tab,
    expanded: expanded,
    choice: choice,
    radio: radio,
    steps: steps,
    disabled: disabled,
  );
}

// The one problem a check gives when [fallback] (controls, by name) draw
// their text in the test's own font.
String _testFontProblem(List<String> fallback) {
  final n = fallback.length;
  final who = n == 1 ? '1 control draws its' : '$n controls draw their';
  return "$who text in the test's own font (solid boxes), ${fallback.first} "
      'first: load every font family the look ships (each family in its '
      'FontManifest.json) before the check';
}

// Reads controls and their faces from a drawn frame: shared by the keyline
// check and the label check.
class _DrawnReader {
  _DrawnReader(this.boundary, this.pixels, this.marked);

  final RenderRepaintBoundary? boundary;
  final DrawnPixels? pixels;

  // The boxes a look marked as faces (DesignKeylineFace): faces whatever
  // their pixels show.
  final Set<RenderBox> marked;

  // Every word, icon and text entry drawn in the boundary, global.
  late final List<(RenderBox, Rect)> _shownRects = [
    if (boundary case final b?)
      for (final p in _shownIn(b))
        if (p is RenderParagraph)
          for (final line in p.getBoxesForSelection(
            TextSelection(
              baseOffset: 0,
              extentOffset: p.text.toPlainText().length,
            ),
          ))
            (
              p,
              MatrixUtils.transformRect(p.getTransformTo(null), line.toRect()),
            )
        else
          (p, _global(p)),
  ];

  // The words, icons and text entries drawn over [r] (or under it): none of
  // them a face's own ink, whichever control holds them (a navigation
  // item's icon beside its pressable layer, not in it).
  List<Rect> _shownOver(Rect r, RenderObject holder) => [
    for (final (box, bounds) in _shownRects)
      if (bounds.overlaps(r) &&
          (_isWithin(box, holder) ||
              !_paintedOver(
                box,
                holder,
                bounds.intersect(r).center,
                separatePanels: true,
              )))
        bounds,
  ];

  Rect _toBoundary(Rect global) {
    final toGlobal = boundary!.getTransformTo(null);
    final back = Matrix4.tryInvert(toGlobal);
    return back == null ? global : MatrixUtils.transformRect(back, global);
  }

  // The contrast with its ground (DrawnPixels.outline's) at which a pixel
  // counts as a face's own ink whatever its channels, when a check reads
  // faces by contrast (the row check's floor); null reads them by colour.
  double? get _inkFloor => null;

  // What is drawn inside [global] other than what it is drawn over (the
  // commonest colour just around it), leaving out what is inside [except],
  // in global coordinates; null without pixels or ink. Given [floor], a
  // pixel reaching that contrast with the ground is drawn too.
  Rect? _ink(Rect global, {List<Rect> except = const [], double? floor}) {
    final p = pixels;
    if (p == null || boundary == null) return null;
    final local = _toBoundary(global);
    final ink = p.inkIn(
      local,
      over: p.groundAround(local, 2),
      except: [for (final r in except) _toBoundary(r)],
      floor: floor,
    );
    return ink == null
        ? null
        : MatrixUtils.transformRect(boundary!.getTransformTo(null), ink);
  }

  // Whether [n] paints a face that shows. A colored box (a Container's
  // colour) does not say its colour, so its pixels decide: it shows when
  // it is not the colour around it.
  bool _showsFace(RenderBox n) {
    if (marked.contains(n)) return true;
    if (!_paintsFace(n)) return false;
    if (!_isColoredBox(n)) return true;
    if (pixels == null || boundary == null) return true;
    return _standsOff(n);
  }

  // Whether what is drawn inside [n] stands off what is just around it,
  // their commonest colours apart: a face, whatever box paints it. A box
  // that fills its layer (a surface in a repaint boundary of its own) has
  // nothing around it in this image: it is a face when it is opaque. False
  // without pixels to read.
  bool _standsOff(RenderBox n) {
    final p = pixels;
    if (p == null || boundary == null) return false;
    final local = _toBoundary(_global(n));
    final inside = p.groundIn(local);
    final layer = Offset.zero & boundary!.size;
    if (local.inflate(0.5).contains(layer.topLeft) &&
        local.inflate(0.5).contains(layer.bottomRight)) {
      return (inside & 0xFF) > 8;
    }
    return !DrawnPixels.alike(inside, p.groundAround(local, 2));
  }

  // Whether [p] is drawn in the test's fallback font: a solid box an em
  // high across the paragraph, which no typeface's words or icon are.
  bool _testFontBox(RenderBox p, int faceColour) {
    final rect = _toBoundary(_global(p));
    final ink = pixels!.inkIn(rect, over: faceColour);
    if (ink == null || p.size.height <= 0) return false;
    // Its letters are solid boxes an em high, side by side, of one colour
    // (the words' own): not a gradient the words are drawn on, nor a fill
    // under them that differs from the face's commonest colour (a thumb).
    final em = labelFontSize(p) * rect.height / p.size.height;
    if (ink.width >= rect.width * 0.9 &&
        ink.height >= em * 0.9 &&
        pixels!.inkShare(ink, over: faceColour) >= 0.8) {
      final solid = pixels!.solidIn(ink);
      return solid.share >= 0.6 &&
          !DrawnPixels.alike(solid.colour, pixels!.groundAround(rect, 2));
    }
    // A glyph it lacks (an icon's) is a hollow square 0.75 em wide standing
    // on the baseline. An icon font's own square (an outline, a check box)
    // keeps a margin in its em, clear of the baseline.
    if (!isIconGlyph(lineText(p).trim())) return false;
    final line = _drawnBaseline(p);
    if (line == null) return false;
    final r = pixels!.ratio;
    bool near(double a, double b) => (a - b).abs() <= math.max(1.0, 0.05 * em);
    final stroke = ink.height / 8;
    return near(ink.width, 0.75 * em) &&
        near(ink.height, 0.75 * em) &&
        near(ink.bottom, line.image / r) &&
        pixels!.inkShare(ink.deflate(stroke * 1.5), over: faceColour) < 0.05 &&
        pixels!.inkShare(
              Rect.fromLTRB(ink.left, ink.top, ink.right, ink.top + stroke / 2),
              over: faceColour,
            ) >
            0.9;
  }

  // [p]'s y (its own units) in the image's pixels, from the boundary's top.
  double Function(double) _imageY(RenderBox p) {
    final m = p.getTransformTo(boundary);
    final r = pixels!.ratio;
    return (y) => MatrixUtils.transformPoint(m, Offset(0, y)).dy * r;
  }

  // [p]'s baseline as laid out and as the engine draws it: rounded to a
  // whole logical pixel below its top (in its own units), then to the
  // nearest device pixel (in the image's pixels).
  ({double laid, double local, double image})? _drawnBaseline(RenderBox p) {
    final b = laidBaseline(p);
    if (b == null) return null;
    final local = (b + 0.5).floorToDouble();
    return (laid: b, local: local, image: _imageY(p)(local).roundToDouble());
  }

  // The columns of [p]'s characters that are in [of], from [top] to
  // [bottom] in its own units, each kept clear of a neighbour's overhang,
  // in the boundary's units. Only characters on a line that starts above
  // [bottom]: a wrapped line's letters are not read in the first line's
  // pixels.
  List<Rect> _columns(RenderBox p, String of, double top, double bottom) {
    final text = lineText(p);
    final m = p.getTransformTo(boundary);
    return [
      for (var i = 0; i < text.length; i++)
        if (of.contains(text[i]))
          for (final box in lineBoxes(
            p,
            TextSelection(baseOffset: i, extentOffset: i + 1),
          ))
            if (box.top < bottom)
              MatrixUtils.transformRect(
                m,
                Rect.fromLTRB(
                  box.left + (box.right - box.left) * 0.2,
                  top,
                  box.right - (box.right - box.left) * 0.2,
                  bottom,
                ),
              ),
    ];
  }

  // The box [p]'s words are drawn in, in the boundary's units: its
  // characters' boxes together; null without any.
  Rect? _wordsBox(RenderBox p) {
    final text = lineText(p);
    if (text.isEmpty) return null;
    final boxes = lineBoxes(
      p,
      TextSelection(baseOffset: 0, extentOffset: text.length),
    );
    if (boxes.isEmpty) return null;
    var box = boxes.first.toRect();
    for (final b in boxes.skip(1)) {
      box = box.expandToInclude(b.toRect());
    }
    return MatrixUtils.transformRect(p.getTransformTo(boundary), box);
  }

  // [p]'s capitals in the image's pixels: their middle as drawn and as laid
  // out, and their height as read from its flat-topped capitals' pixels and
  // as its cap center gives it, when known. Their baseline is the engine's;
  // their height its cap center's, else read from its flat-topped capitals,
  // else the height its style shows on the screen (words in one style share
  // one cap height: an O overshoots it, a V's middle falls short), else the
  // usual one (typicalCapHeightFactor). A line of figures alone is read by
  // its figures. A line holding a widget is read from its capitals' pixels,
  // top and bottom, as drawn only. A rule drawn behind the words, running
  // on past both their sides, is not read as their top. Null when nothing
  // can be read.
  ({double drawn, double? laid, double? read, double? given})? _capitals(
    RenderBox p,
    int faceColour,
  ) {
    final ink = pixels!;
    final line = _drawnBaseline(p);
    // A rule drawn behind the words (a ruled page through an unfilled face)
    // runs on past them; their glyphs do not.
    final words = _wordsBox(p);
    if (line == null) {
      final h = p.size.height;
      final top = ink.inkTopFine(
        _columns(p, _flatTopped, 0, h),
        over: faceColour,
        label: words,
      );
      final bottom = ink.inkBottomFine(
        _columns(p, _flatBottomed, 0, h),
        over: faceColour,
        label: words,
      );
      if (top == null || bottom == null) return null;
      return (drawn: (top + bottom) / 2, laid: null, read: null, given: null);
    }
    final y = _imageY(p);
    double? topOf(String of) {
      final columns = _columns(p, of, 0, line.local);
      return columns.isEmpty
          ? null
          : ink.inkTopFine(columns, over: faceColour, label: words);
    }

    double heightAt(double factor) {
      final caps = drawnCaps(p, factor)!;
      return y(caps.baseline) - y(caps.top);
    }

    // A line of figures alone is read by its figures, which need not
    // stand at the capitals' height.
    final figures = _figuresOnly(lineText(p));
    final flat = figures ? null : topOf(_flatTopped);
    final read = flat == null ? null : line.image - flat;
    final centred = _capCentred(p);
    final given = centred == null ? null : heightAt(centred.capHeightFactor);
    final shared = given == null && read == null
        ? _styleCapFactor(p, figures: figures)
        : null;
    final height = given ?? read ?? heightAt(shared ?? typicalCapHeightFactor);
    return (
      drawn: line.image - height / 2,
      laid: y(line.laid) - height / 2,
      read: read,
      given: given,
    );
  }

  // What [control] shows, global: its own face, else its words, icons and
  // text entries, else its box. Not its touch target, which may overhang
  // what it shows (as Material pads its targets).
  Rect _shownBy(RenderBox control) {
    if (_face(control) case final face?) return face.rect;
    final shown = [for (final b in _shownIn(control)) _global(b)];
    if (shown.isEmpty) return _global(control);
    return shown.reduce((a, b) => a.expandToInclude(b));
  }

  // Whether [t] sits in a smaller face of its own inside the control (up to
  // [face], the control's face box, or [control]), less than half of [rect]
  // (the control's face): a badge, a count.
  bool _inBadge(RenderBox t, RenderBox control, RenderBox face, Rect rect) {
    final least = rect.width * rect.height / 2;
    RenderObject? up = t.parent;
    while (up != null && up != control && up != face) {
      if (up is RenderBox && up.hasSize && _showsFace(up)) {
        final r = _global(up);
        if (r.width * r.height < least) return true;
      }
      up = up.parent;
    }
    return false;
  }

  // Whether a picture under [control] (an image, a painted glyph or
  // picture, a box filled with an image) stands over or under [words]
  // (global), across them and at least half their height: words under a
  // picture (an icon tile's name) are placed there, not centred on the
  // face. A paint round the words, or a rule under them, is no picture.
  bool _byPicture(RenderBox control, Rect words) {
    var found = false;
    void visit(RenderObject n) {
      if (found) return;
      if (n is RenderParagraph || n is RenderEditable) return;
      if (n is RenderBox &&
          n.hasSize &&
          (n is RenderImage ||
              n is RenderCustomPaint ||
              (n is RenderDecoratedBox &&
                  n.decoration is BoxDecoration &&
                  (n.decoration as BoxDecoration).image != null))) {
        final r = _global(n);
        if (r.left < words.right &&
            r.right > words.left &&
            r.height >= words.height / 2 &&
            (r.bottom <= words.top + 0.5 || r.top >= words.bottom - 0.5)) {
          found = true;
          return;
        }
      }
      _visitShown(n, visit);
    }

    _visitShown(control, visit);
    return found;
  }

  // The colour words at [words] are drawn on, on [face] (both global): the
  // face's commonest colour when it is one colour; else (a gradient, a
  // pane of glass) the colour just round the words.
  int _faceGround(Rect face, Rect words) {
    final p = pixels!;
    final local = _toBoundary(face);
    if (p.solidIn(local).share >= 0.5) return p.groundIn(local);
    return p.groundAround(_toBoundary(words), 2);
  }

  // The cap height factors read from lines on this screen, by style.
  final _capFactors = <String, double?>{};

  // The height of [p]'s capitals over its font size as its style (its
  // family, weight, slant and size) shows them on this screen: read from
  // the first line in that style with a capital flat on the cap height,
  // else with a round one (an O overshoots it a little), else with any
  // capital (a V's middle meets its arms below it); null with none. Every
  // line in a style takes the one height, so words whose capitals differ
  // ("Open", "Version") are read alike. With [figures], lines of figures
  // alone, by their figures: flat-topped, else round, else any.
  double? _styleCapFactor(RenderBox p, {bool figures = false}) {
    final b = boundary;
    final ink = pixels;
    if (b == null || ink == null) return null;
    String? keyOf(RenderBox line) {
      final s = lineStyle(line);
      return s == null
          ? null
          : '${s.fontFamily}|${s.fontWeight}|${s.fontStyle}|'
                '${labelFontSize(line)}|$figures';
    }

    final key = keyOf(p);
    if (key == null) return null;
    if (_capFactors.containsKey(key)) return _capFactors[key];
    final lines = [
      for (final other in _shownIn(b))
        if (other is RenderParagraph &&
            _figuresOnly(lineText(other)) == figures &&
            keyOf(other) == key)
          other,
    ];
    double? factor;
    for (final of in figures ? _figureTiers : _capitalTiers) {
      for (final other in lines) {
        final text = lineText(other);
        if (!of.split('').any(text.contains)) continue;
        final line = _drawnBaseline(other);
        if (line == null) continue;
        final top = ink.inkTopFine(
          _columns(other, of, 0, line.local),
          over: ink.groundAround(_toBoundary(_global(other)), 2),
          label: _wordsBox(other),
        );
        if (top == null) continue;
        final y = _imageY(other);
        final em = y(line.local) - y(line.local - labelFontSize(other));
        if (em <= 0) continue;
        factor = (line.image - top) / em;
        break;
      }
      if (factor != null) break;
    }
    return _capFactors[key] = factor;
  }

  // Whether [text] shows figures and no letter: a day, a count, a price.
  static bool _figuresOnly(String text) =>
      text.contains(RegExp('[0-9]')) &&
      !text.contains(RegExp(r'\p{L}', unicode: true));

  // The middle of an icon's glyph [p] as drawn, in the image's pixels: its
  // box's middle, moved as its baseline is.
  double? _glyphMiddle(RenderBox p) {
    final line = _drawnBaseline(p);
    if (line == null) return null;
    final y = _imageY(p);
    return line.image + y(p.size.height / 2) - y(line.local);
  }

  // The cap center [p] is drawn in, inside this control; null outside one.
  RenderDesignCapCenter? _capCentred(RenderBox p) {
    RenderObject? up = p.parent;
    while (up != null && up != boundary) {
      if (up case final RenderDesignCapCenter centred) return centred;
      up = up.parent;
    }
    return null;
  }

  // Capitals whose tops are flat on the cap height across the middle of
  // their box (the columns [_columns] reads). Not those whose tops are at
  // their sides or come to a point (V, W, X, Y: their middle columns meet
  // a diagonal below the cap height), nor K, whose arm overshoots it in
  // some faces.
  static const _flatTopped = 'BDEFHILMNPRTUZ';

  // Capitals whose feet are flat on the baseline across the middle of their
  // box: not A, K or X, whose feet are at their sides.
  static const _flatBottomed = 'BDEFHILMNPRTZ';

  // The capitals a style's cap height is read from, the surest first: flat
  // on it, round over it, and the rest.
  static const _capitalTiers = [_flatTopped, 'CGOQS', 'AJKVWXY'];

  // The figures a style's figure height is read from, likewise.
  static const _figureTiers = ['57', '0235689', '14'];

  // The outermost controls under [node], not counting [node].
  List<RenderBox> _controlsUnder(RenderObject node) {
    final found = <RenderBox>[];
    void visit(RenderObject n) {
      if (n is RenderBox && _isControl(n)) {
        found.add(n);
        return;
      }
      _visitShown(n, visit);
    }

    _visitShown(node, visit);
    return found;
  }

  // A control's face. A face a look marked (the control itself, or the
  // outermost marked box inside it short of another control) whatever its
  // pixels show. Otherwise the largest box inside it that paints one,
  // wholly inside the control's box (so a shadow drawn as an offset box
  // behind it does not count) and at least a quarter of it; of two the same
  // size, the one painted last. A custom paint is read from its own pixels,
  // the words and icons drawn over it left out ([read]): one that draws
  // nothing else (a text button's empty border painter) paints no face.
  // With the box that paints it.
  ({Rect rect, RenderBox box, bool read})? _face(RenderBox control) {
    if (marked.contains(control)) {
      return (rect: _global(control), box: control, read: false);
    }
    RenderBox? mark;
    void marks(RenderObject n) {
      if (mark != null) return;
      if (n is RenderBox && n.hasSize && marked.contains(n)) {
        mark = n;
        return;
      }
      if (_isControl(n)) return;
      _visitShown(n, marks);
    }

    _visitShown(control, marks);
    final m = mark;
    if (m != null) return (rect: _global(m), box: m, read: false);

    final outer = _global(control).inflate(0.5);
    final least = outer.width * outer.height / 4;
    final found = <(Rect, RenderBox, int)>[];
    void visit(RenderObject n) {
      if (n is RenderParagraph || n is RenderEditable) return;
      if (n is RenderBox && n.hasSize && _showsFace(n)) {
        final r = _global(n);
        final inside =
            r.left >= outer.left &&
            r.top >= outer.top &&
            r.right <= outer.right &&
            r.bottom <= outer.bottom;
        if (inside && r.width * r.height >= least) {
          found.add((r, n, found.length));
        }
      }
      _visitShown(n, visit);
    }

    _visitShown(control, visit);
    // Largest first; of two the same size, the one painted last. A paint
    // that draws nothing of its own (a clear hover or focus surface) passes
    // to the next.
    found.sort((x, y) {
      final d = y.$1.width * y.$1.height - x.$1.width * x.$1.height;
      if (d.abs() > 1) return d > 0 ? 1 : -1;
      return y.$3.compareTo(x.$3);
    });
    for (final (r, b, _) in found) {
      if (b is! RenderCustomPaint) return (rect: r, box: b, read: false);
      final own = _ownInk(r, control);
      if (own != null) return (rect: own.rect, box: b, read: own.read);
    }
    return null;
  }

  // What a custom paint draws itself inside [r], the words, icons and text
  // entries under [holder] left out ([read]); [r] itself without pixels to
  // read; null when it draws nothing else (a text button's clear hover
  // surface, a face the colour of what is around it).
  ({Rect rect, bool read})? _ownInk(Rect r, RenderObject holder) {
    if (pixels == null || boundary == null) return (rect: r, read: false);
    final own = _ink(r, except: _shownOver(r, holder), floor: _inkFloor);
    return own == null ? null : (rect: own, read: true);
  }
}

// The boxes marked as faces (DesignKeylineFace) under [context].
Set<RenderBox> _markedFaces(BuildContext context) {
  final found = <RenderBox>{};
  void visit(Element element) {
    if (element.widget is DesignKeylineFace) {
      final box = element.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize && _isShown(box)) {
        found.add(box);
      }
    }
    element.visitChildElements(visit);
  }

  if (context is Element) visit(context);
  return found;
}

// The words, icons and text entries under [node].
List<RenderBox> _shownIn(RenderObject node) {
  final found = <RenderBox>[];
  void visit(RenderObject n) {
    if (n is RenderParagraph || n is RenderEditable) {
      if ((n as RenderBox).hasSize) found.add(n);
      return;
    }
    _visitShown(n, visit);
  }

  _visitShown(node, visit);
  return found;
}

// Whether [parent] paints [child]: not an Offstage's while off stage, a
// fully transparent Opacity's, a transform's that scales it to nothing (an
// empty checkbox's check at scale 0), an IndexedStack's other than the one
// it shows (Visibility keeping its state is one of the first two), a
// viewport's sliver it doesn't show, nor a list's row laid out past what
// it paints (its cache extent) or kept alive off screen, nor an overlay's
// entry kept offstage (a page under an opaque route), nor a box never laid
// out (a page built while offstage). Laid out, such a child is not on
// screen, so no check reads it; never laid out, it has no place to read.
bool _paints(RenderObject parent, RenderObject child) {
  if (child is RenderBox && !child.hasSize) return false;
  if (_isTheater(parent)) return _onstage(parent, child);
  return _paintsLaidOut(parent, child);
}

bool _paintsLaidOut(RenderObject parent, RenderObject child) =>
    switch (parent) {
      RenderViewportBase() =>
        child is! RenderSliver || (child.geometry?.visible ?? false),
      RenderSliverMultiBoxAdaptor() => _inPaintExtent(parent, child),
      RenderOffstage(:final offstage) => !offstage,
      RenderOpacity(:final opacity) => opacity > 0,
      RenderAnimatedOpacity(:final opacity) => opacity.value > 0,
      RenderTransform() when child is RenderBox => _keepsArea(parent, child),
      RenderSliverOffstage(:final offstage) => !offstage,
      RenderSliverOpacity(:final opacity) => opacity > 0,
      RenderSliverAnimatedOpacity(:final opacity) => opacity.value > 0,
      RenderIndexedStack() => _shownByStack(parent, child),
      _ => true,
    };

// Whether [transform] draws [child] with an area: a scale to nothing on
// either axis paints nothing of it.
bool _keepsArea(RenderTransform transform, RenderBox child) {
  // Its transform is placed in its own size (an alignment, an origin).
  if (!transform.hasSize) return false;
  final m = Matrix4.identity();
  transform.applyPaintTransform(child, m);
  final area = m.entry(0, 0) * m.entry(1, 1) - m.entry(0, 1) * m.entry(1, 0);
  return area.abs() > 1e-9;
}

// Whether [node] is a transform that paints nothing of its child.
bool _scaledAway(RenderObject node) =>
    node is RenderTransform &&
    node.child != null &&
    !_keepsArea(node, node.child!);

// Whether [list] paints [child]: a row it lays out and paints, as
// [RenderSliverMultiBoxAdaptor.paint] decides.
bool _inPaintExtent(RenderSliverMultiBoxAdaptor list, RenderObject child) {
  if (child is! RenderBox || !child.hasSize) return false;
  if (child.parentData case SliverMultiBoxAdaptorParentData(keptAlive: true)) {
    return false;
  }
  final at = list.childMainAxisPosition(child);
  final extent = switch (list.constraints.axis) {
    Axis.horizontal => child.size.width,
    Axis.vertical => child.size.height,
  };
  return at < list.constraints.remainingPaintExtent && at + extent > 0;
}

// The repaint boundary [node] is drawn in, when it is in the frame: none
// when nothing above it is one, or when it was never painted or is painted
// no longer (laid out where nothing paints it), so nothing under it shows.
RenderRepaintBoundary? _drawnIn(RenderObject node) {
  RenderObject? up = node;
  while (up != null && up is! RenderRepaintBoundary) {
    up = up.parent;
  }
  return up is RenderRepaintBoundary && DrawnPixels.inFrame(up) ? up : null;
}

// Whether [n] is an Overlay's: its entries behind an opaque route's are
// offstage, neither laid out nor painted.
bool _isTheater(RenderObject n) => n.runtimeType.toString() == '_RenderTheater';

// Whether [theater] has [child] on stage: the children it paints, those it
// hands a screen reader.
bool _onstage(RenderObject theater, RenderObject child) {
  var on = false;
  theater.visitChildrenForSemantics((c) {
    if (identical(c, child)) on = true;
  });
  return on;
}

bool _shownByStack(RenderIndexedStack stack, RenderObject child) {
  var i = 0;
  var shown = false;
  stack.visitChildren((c) {
    if (identical(c, child)) shown = i == stack.index;
    i++;
  });
  return shown;
}

// Visits the children [node] paints.
void _visitShown(RenderObject node, RenderObjectVisitor visit) {
  node.visitChildren((child) {
    if (_paints(node, child)) visit(child);
  });
}

// Whether [node] is painted: every box above it paints the one below.
bool _isShown(RenderObject node) {
  var child = node;
  for (var up = node.parent; up != null; up = up.parent) {
    if (!_paints(up, child)) return false;
    child = up;
  }
  return true;
}

Rect _global(RenderBox b) =>
    MatrixUtils.transformRect(b.getTransformTo(null), Offset.zero & b.size);

// Whether [front] is painted after [control] (the nearest box round both
// paints its branch later) and fills at [at], itself or a box round it on
// its branch.
bool _paintedOver(
  RenderBox control,
  RenderObject front,
  Offset at, {
  bool separatePanels = false,
}) {
  final round = <RenderObject>[];
  for (RenderObject? up = control; up != null; up = up.parent) {
    round.add(up);
  }
  RenderObject? frontTop;
  RenderObject? controlTop;
  RenderObject? common;
  for (RenderObject? up = front; up != null; up = up.parent) {
    final i = round.indexOf(up);
    if (i > 0) {
      common = up;
      controlTop = round[i - 1];
      break;
    }
    frontTop = up;
  }
  if (common == null || frontTop == null || controlTop == null) return false;
  var later = false;
  var seenControl = false;
  common.visitChildren((child) {
    if (identical(child, controlTop)) seenControl = true;
    if (identical(child, frontTop) && seenControl) later = true;
  });
  if (!later || !_isShown(front)) return false;
  // Named, independently painted panes can paint their own backgrounds in
  // custom render boxes. Text from a pane behind one is not a label in
  // the pane in front, even when their text boxes overlap on screen.
  bool namedPanel(RenderObject n) =>
      n is RenderSemanticsAnnotations &&
      n.container &&
      (n.properties.label?.isNotEmpty ?? false) &&
      !_isControl(n);
  final backPanel =
      separatePanels &&
      round.takeWhile((n) => !identical(n, common)).any(namedPanel);
  for (RenderObject? up = front; up != null; up = up.parent) {
    if (backPanel && namedPanel(up)) return true;
    if (up is RenderBox && up.hasSize && _fills(up)) {
      if (_global(up).contains(at)) return true;
    }
    if (identical(up, frontTop)) break;
  }
  return false;
}

// Whether [n] paints over the whole of its box or shape: a colour, a
// gradient, an image, a pane of glass, or a paint whose shape is not known.
// A ring alone (a focus ring's border) does not.
bool _fills(RenderObject n) => switch (n) {
  RenderDecoratedBox(
    decoration: BoxDecoration(:final color, :final gradient, :final image),
  ) ||
  RenderDecoratedBox(
    decoration: ShapeDecoration(:final color, :final gradient, :final image),
  ) => (color?.a ?? 0) > 0 || gradient != null || image != null,
  RenderPhysicalModel(:final color) ||
  RenderPhysicalShape(:final color) => color.a > 0,
  RenderBackdropFilter() || RenderImage() => true,
  RenderCustomPaint(:final painter) => painter != null,
  _ => _isColoredBox(n),
};

bool _isColoredBox(RenderObject n) =>
    n.runtimeType.toString() == '_RenderColoredBox';

bool _isControl(RenderObject n) {
  if (n is RenderSemanticsGestureHandler) {
    return n.onTap != null || n.onLongPress != null;
  }
  if (n is RenderSemanticsAnnotations) {
    final p = n.properties;
    return p.button == true ||
        p.link == true ||
        p.textField == true ||
        p.slider == true ||
        p.toggled != null ||
        p.checked != null ||
        p.onTap != null;
  }
  return false;
}

bool _paintsFace(RenderObject n) => switch (n) {
  RenderDecoratedBox(:final decoration) => _shows(decoration),
  RenderPhysicalModel(:final color, :final elevation) ||
  RenderPhysicalShape(
    :final color,
    :final elevation,
  ) => color.a > 0 || elevation > 0,
  RenderBackdropFilter() => true,
  RenderCustomPaint(:final painter, :final foregroundPainter) =>
    painter != null || foregroundPainter != null,
  _ => _isColoredBox(n),
};

bool _shows(Decoration d) => switch (d) {
  BoxDecoration(
    :final color,
    :final gradient,
    :final image,
    :final border,
    :final boxShadow,
  ) =>
    (color?.a ?? 0) > 0 ||
        gradient != null ||
        image != null ||
        _drawsBorder(border) ||
        _drawsShadow(boxShadow),
  ShapeDecoration(
    :final color,
    :final gradient,
    :final image,
    :final shadows,
    :final shape,
  ) =>
    (color?.a ?? 0) > 0 ||
        gradient != null ||
        image != null ||
        _drawsShadow(shadows) ||
        switch (shape) {
          // A clear stroke draws nothing (a subtle button's).
          OutlinedBorder(:final side) => _drawsSide(side),
          _ => shape.dimensions != EdgeInsets.zero,
        },
  _ => true,
};

// Whether [border] draws a stroke that shows on any side: a clear one, or
// none, draws nothing.
bool _drawsBorder(BoxBorder? border) => switch (border) {
  null => false,
  Border(:final top, :final right, :final bottom, :final left) => [
    top,
    right,
    bottom,
    left,
  ].any(_drawsSide),
  BorderDirectional(:final top, :final start, :final bottom, :final end) => [
    top,
    start,
    bottom,
    end,
  ].any(_drawsSide),
  _ => true,
};

// A side of width 0 draws a hairline.
bool _drawsSide(BorderSide side) =>
    side.style != BorderStyle.none && side.color.a > 0;

bool _drawsShadow(List<BoxShadow>? shadows) =>
    shadows?.any((s) => s.color.a > 0) ?? false;

String _nameOf(RenderBox control, {Set<RenderBox> skip = const {}}) {
  String? label;
  String? kind;
  void visit(RenderObject n) {
    if (label != null || skip.contains(n)) return;
    if (n is RenderSemanticsAnnotations) {
      final p = n.properties;
      if ((p.label ?? '').isNotEmpty) label = p.label;
      kind ??= p.toggled != null
          ? 'a switch'
          : p.checked != null
          ? 'a checkbox'
          : p.textField == true
          ? 'a text field'
          : p.slider == true
          ? 'a slider'
          : p.link == true
          ? 'a link'
          : p.button == true
          ? 'a button'
          : null;
    }
    if (n is RenderEditable) kind ??= 'a text field';
    if (n is RenderParagraph && label == null) {
      final t = n.text.toPlainText(includeSemanticsLabels: false).trim();
      if (t.isNotEmpty && !isIconGlyph(t)) label = t;
    }
    _visitShown(n, visit);
  }

  visit(control);
  final k = kind ?? 'a control';
  if (label == null) return k;
  final l = label!.length > 24 ? '${label!.substring(0, 23)}…' : label!;
  return '$k "$l"';
}

// Whether [node] is [ancestor] or under it.
bool _isWithin(RenderObject node, RenderObject ancestor) {
  for (RenderObject? up = node; up != null; up = up.parent) {
    if (identical(up, ancestor)) return true;
  }
  return false;
}

// What a pointer at [at] hits, innermost first.
List<HitTestEntry> _pathAt(Offset at, int viewId) {
  final result = HitTestResult();
  RendererBinding.instance.hitTestInView(result, at, viewId);
  return result.path.toList();
}

// Whether [box] is a modal barrier's: the scrim behind a sheet or a dialog.
bool _isBarrier(RenderBox box) {
  var found = false;
  final creator = box.debugCreator;
  if (creator is DebugCreator) {
    if (creator.element.widget.runtimeType.toString().contains(
      'ModalBarrier',
    )) {
      return true;
    }
    var depth = 0;
    creator.element.visitAncestorElements((e) {
      // ModalBarrier, AnimatedModalBarrier and their private parts.
      if (e.widget.runtimeType.toString().contains('ModalBarrier')) {
        found = true;
      }
      return !found && ++depth < 12;
    });
  }
  return found;
}

// ', holding "Raised"': the first words [box] holds, to find it by.
String _holding(RenderBox box) {
  String? words;
  void visit(RenderObject n) {
    if (words != null) return;
    if (n is RenderParagraph) {
      final t = n.text.toPlainText(includeSemanticsLabels: false).trim();
      if (t.isNotEmpty && !isIconGlyph(t)) words = t;
    }
    _visitShown(n, visit);
  }

  visit(box);
  if (words == null) return '';
  final w = words!.replaceAll('\n', ' ');
  return ', holding "${w.length > 28 ? '${w.substring(0, 27)}…' : w}"';
}

// Whether [outer] holds [inner].
bool _contains(Rect outer, Rect inner) =>
    inner.left >= outer.left - .01 &&
    inner.top >= outer.top - .01 &&
    inner.right <= outer.right + .01 &&
    inner.bottom <= outer.bottom + .01;

String _size(Size s) => '${_px(s.width)} × ${_px(s.height)}';
