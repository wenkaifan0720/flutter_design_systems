part of '../../review.dart';

/// Whether a field's own parts have room and stand at one height: a date or
/// time field's segments, the button that opens its picker, and a stepper's
/// buttons beside its field.
///
/// - **Room in a segment**: each segment of a [RawDateField] or a
///   [RawTimeField] holds its text at least [segmentInset] logical px in
///   from its frame on both sides, the frame being the segment's own face
///   when it paints one, else the field's frame round all its segments, and
///   its inner edge as drawn (a border, or a ring a painter draws, is not
///   room; a shadow that fades into the fill is): `a date field "Due date":
///   its Month segment "11" holds its text 1 px from its frame on the left
///   and 1 px on the right`. Digits that touch the box round them read as
///   cramped, and at 200% text they are cut.
/// - **One row, one height**: the button that opens a date or time field's
///   picker (the control nearest the field in its row, inside its frame or
///   beside it) stands as tall as the segments' faces when each segment
///   paints one, else as the field's frame when the button is beside the
///   frame; a button inside the frame is one of the field's own parts and is
///   not held. A stepper's two buttons, beside its field, stand as tall as
///   the field's frame (a pair stacked on one side, as tall together): `a
///   stepper "Estimate": its buttons are 40 px tall beside its field, 48 px
///   tall`. Within [tolerance] logical px.
///
/// A stepper is a [RawNumberField] (its two step buttons and its field); two
/// buttons round or beside a value (one whose semantics step it or say its
/// value) or a text entry, with nothing else that acts in the box that lays
/// them out; or one node that steps or says its value, with two buttons inside
/// it and nothing else that acts (a pointer's buttons round a value a screen
/// reader reads through the node; a slider's node when words, not a track,
/// stand between them), its field what the row lays out between them. A button
/// that paints no face of its own (a bare glyph) has no height to compare and
/// is not held. A pager (two buttons round a position a screen reader hears as
/// it changes, a live region that neither steps nor takes typing) is no value
/// field and is not held either.
///
/// Faces are read as [DesignRowCheck] reads them, from what is drawn, so a
/// test loads the look's fonts first. Run it at 100% and at 200% text, as
/// laid out on a phone and on a desktop, in both directions:
///
/// ```dart
/// final report = await const DesignFieldPartsCheck(look: 'Comic').check(
///   tester.element(find.byType(SettingsScreen)),
///   runAsync: tester.runAsync,
/// );
/// report.verify();
/// ```
///
/// It reads layout boxes, and the drawn pixels where only they show it (a
/// segment's text ink, a painted frame), so it takes the tester's `runAsync`.
@immutable
class DesignFieldPartsCheck {
  /// A check for [look].
  const DesignFieldPartsCheck({
    required this.look,
    this.segmentInset = 4,
    this.tolerance = 1,
    this.pixelRatio = 3,
  });

  /// The look's name, for messages.
  final String look;

  /// The least room, in logical px, between a segment's text and its frame
  /// on each side.
  final double segmentInset;

  /// How far, in logical px, the heights of parts in one row may differ.
  final double tolerance;

  /// The scale the screen is drawn at to read its pixels.
  final double pixelRatio;

  /// Checks every date field, time field and stepper under [context] that
  /// is laid out and painted. A test passes its tester's `runAsync`
  /// (reading pixels takes real time); null reads them directly.
  Future<DesignAlignmentReport> check(
    BuildContext context, {
    Future<T?> Function<T>(Future<T> Function() work)? runAsync,
  }) async {
    if (context.findRenderObject() == null) {
      return DesignAlignmentReport(look, const []);
    }
    final marked = _markedFaces(context);
    final dates = <(RenderBox, List<RenderBox>, String)>[];
    final numbers = <(RenderBox, List<RenderBox>)>[];
    void visit(Element e) {
      final w = e.widget;
      if (w is RawDateField || w is RawTimeField) {
        final box = e.findRenderObject();
        if (box is RenderBox && _readable(box)) {
          dates.add((
            box,
            _segmentsIn(e),
            w is RawTimeField ? 'a time field' : 'a date field',
          ));
        }
        return;
      }
      if (w is RawNumberField) {
        final box = e.findRenderObject();
        if (box is RenderBox && _readable(box)) {
          numbers.add((box, _stepButtonsIn(e)));
        }
        return;
      }
      e.visitChildElements(visit);
    }

    visit(context as Element);
    final readers = <RenderRepaintBoundary, _DrawnReader>{};
    Future<_DrawnReader?> readerOf(RenderObject node) async {
      final boundary = _drawnIn(node);
      if (boundary == null) return null;
      return readers[boundary] ??= _DrawnReader(
        boundary,
        await DrawnPixels.read(boundary, pixelRatio, runAsync),
        marked,
      );
    }

    final found = <String>[];
    final held = <RenderBox>{};
    for (final (field, segments, kind) in dates) {
      held.add(field);
      final reader = await readerOf(field);
      if (reader == null || segments.isEmpty) continue;
      found.addAll(_dateField(reader, field, segments, kind));
    }
    for (final (field, buttons) in numbers) {
      held.add(field);
      final reader = await readerOf(field);
      if (reader == null || buttons.length != 2) continue;
      final value = _entryIn(field, buttons);
      if (value == null) continue;
      found.addAll(_stepper(reader, field, value, buttons));
    }
    final root = context.findRenderObject()!;
    for (final (node, value, buttons) in _steppersUnder(root, held)) {
      final reader = await readerOf(node);
      if (reader == null) continue;
      found.addAll(_stepper(reader, node, value, buttons));
    }
    return DesignAlignmentReport(look, found);
  }

  static bool _readable(RenderBox box) =>
      box.attached && box.hasSize && _isShown(box) && box.size.width >= 4;

  // A date or time field's segments: each one ui_core lays out as a
  // Semantics round its Focus (date_field.dart).
  static List<RenderBox> _segmentsIn(Element field) {
    final found = <RenderBox>[];
    void visit(Element e) {
      final w = e.widget;
      if (w is Semantics && w.child is Focus) {
        final box = e.findRenderObject();
        if (box is RenderBox && _readable(box)) found.add(box);
        return;
      }
      e.visitChildElements(visit);
    }

    field.visitChildElements(visit);
    return found;
  }

  // A number field's two step buttons (number_field.dart's _StepButton: a
  // pointer's only, so not in the semantics tree).
  static List<RenderBox> _stepButtonsIn(Element field) {
    final found = <RenderBox>[];
    void visit(Element e) {
      if (e.widget.runtimeType.toString() == '_StepButton') {
        final box = e.findRenderObject();
        if (box is RenderBox && _readable(box)) found.add(box);
        return;
      }
      e.visitChildElements(visit);
    }

    field.visitChildElements(visit);
    return found;
  }

  // The text entry in [field] outside [buttons], or its words.
  static RenderBox? _entryIn(RenderBox field, List<RenderBox> buttons) {
    RenderBox? entry;
    RenderBox? words;
    void visit(RenderObject n) {
      if (entry != null || buttons.any((b) => identical(b, n))) return;
      if (n is RenderEditable && n.hasSize) {
        entry = n;
        return;
      }
      if (n is RenderParagraph && n.hasSize && words == null) words = n;
      _visitShown(n, visit);
    }

    _visitShown(field, visit);
    return entry ?? words;
  }

  // The steppers ui_core does not lay out: two buttons round or beside a
  // value that steps or a text entry, nothing else acting in the box that
  // lays them out (the outermost such box no larger than its parts); or one
  // node that steps or says its value, with two buttons inside it and
  // nothing else that acts (a pointer's buttons, the node a screen reader
  // reads and steps), its value what the row lays out between them. Not
  // inside [held].
  List<(RenderBox, RenderBox, List<RenderBox>)> _steppersUnder(
    RenderObject root,
    Set<RenderBox> held,
  ) {
    final found = <(RenderBox, RenderBox, List<RenderBox>)>[];
    void visit(RenderObject node) {
      if (held.contains(node)) return;
      if (node is RenderSemanticsAnnotations &&
          node.hasSize &&
          _holdsValue(node) &&
          !_isPosition(node)) {
        final buttons = _partsUnder(node);
        if (buttons.length == 2 &&
            buttons.every((c) => _isButton(c) && !_isValue(c))) {
          final value = _between(node, buttons);
          // A slider's node is a stepper's when words, not a track, stand
          // between its buttons.
          if (value != null &&
              (node.properties.slider != true || _holdsWords(value)) &&
              _inOneRow(_global(value), buttons.map(_global))) {
            found.add((node, value, buttons));
            return;
          }
        }
      }
      if (node is RenderBox && node.hasSize && !_isPart(node)) {
        final controls = _partsUnder(node);
        if (controls.length == 3) {
          final values = [
            for (final c in controls)
              if (_isValue(c)) c,
          ];
          final buttons = [
            for (final c in controls)
              if (!_isValue(c) && _isButton(c)) c,
          ];
          if (values.length == 1 &&
              buttons.length == 2 &&
              !_isPosition(values.single)) {
            final parts = controls
                .map(_global)
                .reduce((a, b) => a.expandToInclude(b));
            if (parts.inflate(8).contains(_global(node).topLeft) &&
                parts.inflate(8).contains(_global(node).bottomRight) &&
                _inOneRow(_global(values.single), buttons.map(_global))) {
              found.add((node, values.single, buttons));
              return;
            }
          }
        }
      }
      _visitShown(node, visit);
    }

    visit(root);
    return found;
  }

  // A control, or a value a stepper shows: one that steps (its semantics
  // increase and decrease it) or that says its value.
  static bool _isPart(RenderObject n) =>
      _isControl(n) ||
      (n is RenderSemanticsAnnotations &&
          (n.properties.onIncrease != null ||
              n.properties.onDecrease != null ||
              (n.properties.value?.isNotEmpty ?? false)));

  // The outermost parts under [node], not counting [node].
  static List<RenderBox> _partsUnder(RenderObject node) {
    final found = <RenderBox>[];
    void visit(RenderObject n) {
      if (n is RenderBox && n.hasSize && _isPart(n)) {
        found.add(n);
        return;
      }
      _visitShown(n, visit);
    }

    _visitShown(node, visit);
    return found;
  }

  // A text entry, or a value that steps or says its value (not a thin
  // slider track).
  static bool _isValue(RenderBox c) {
    final s = _semanticsOf(c);
    if (s.entry) return true;
    if (s.slider) return c.size.height >= 24;
    return s.steps ||
        (c is RenderSemanticsAnnotations && !_isControl(c) && !s.toggle);
  }

  static bool _isButton(RenderBox c) {
    final s = _semanticsOf(c);
    return !s.entry && !s.slider && !s.toggle && !s.link && !s.tab;
  }

  // Whether [node] is a value: it steps, or says its value, and is no
  // button, entry or toggle.
  static bool _holdsValue(RenderSemanticsAnnotations node) {
    final p = node.properties;
    return (p.onIncrease != null ||
            p.onDecrease != null ||
            (p.value?.isNotEmpty ?? false)) &&
        p.button != true &&
        p.textField != true &&
        p.toggled == null &&
        p.checked == null;
  }

  // A pager's position: a value a screen reader hears as it changes (a
  // live region) that neither steps nor takes typing. A pager is no value
  // field.
  static bool _isPosition(RenderBox value) {
    final s = _semanticsOf(value);
    if (s.entry || s.steps) return false;
    var live = false;
    void visit(RenderObject n) {
      if (live) return;
      if (n is RenderSemanticsAnnotations && n.properties.liveRegion == true) {
        live = true;
        return;
      }
      n.visitChildren(visit);
    }

    visit(value);
    return live;
  }

  static bool _holdsWords(RenderObject node) {
    var found = false;
    void visit(RenderObject n) {
      if (found) return;
      if (n is RenderParagraph &&
          n.text.toPlainText(includeSemanticsLabels: false).trim().isNotEmpty) {
        found = true;
        return;
      }
      _visitShown(n, visit);
    }

    visit(node);
    return found;
  }

  // The widest box that the row holding both [buttons] (under [node]) lays
  // out between them.
  static RenderBox? _between(RenderObject node, List<RenderBox> buttons) {
    final above = <RenderObject>{};
    for (RenderObject? up = buttons[0]; up != null; up = up.parent) {
      above.add(up);
      if (identical(up, node)) break;
    }
    RenderObject? row;
    for (RenderObject? up = buttons[1]; up != null; up = up.parent) {
      if (above.contains(up)) {
        row = up;
        break;
      }
    }
    if (row == null) return null;
    final a = _global(buttons[0]).center.dx;
    final b = _global(buttons[1]).center.dx;
    final low = math.min(a, b), high = math.max(a, b);
    RenderBox? widest;
    _visitShown(row, (c) {
      if (c is! RenderBox || !c.hasSize) return;
      final r = _global(c);
      if (r.center.dx <= low || r.center.dx >= high) return;
      if (buttons.any((button) => _isWithin(button, c))) return;
      if (widest == null || r.width > _global(widest!).width) widest = c;
    });
    return widest;
  }

  // Whether [buttons] stand in [value]'s row: each crosses its middle line.
  static bool _inOneRow(Rect value, Iterable<Rect> buttons) => buttons.every(
    (b) => b.top < value.center.dy && b.bottom > value.center.dy,
  );

  // [face] less its border, where its box says how wide that is.
  static Rect _within(RenderBox box, Rect face) {
    if (box is! RenderDecoratedBox) return face;
    final d = box.decoration;
    var left = 0.0, right = 0.0;
    if (d is BoxDecoration) {
      final b = d.border;
      if (b is Border) {
        left = b.left.width;
        right = b.right.width;
      } else if (b is BorderDirectional) {
        left = b.start.width;
        right = b.end.width;
      }
    } else if (d is ShapeDecoration && d.shape is OutlinedBorder) {
      left = right = (d.shape as OutlinedBorder).side.width;
    }
    return Rect.fromLTRB(
      face.left + left,
      face.top,
      face.right - right,
      face.bottom,
    );
  }

  // The words a segment shows, global: its paragraphs' line boxes.
  static Rect? _textOf(RenderBox segment) {
    Rect? text;
    for (final p in _shownIn(segment).whereType<RenderParagraph>()) {
      final plain = p.text.toPlainText();
      if (plain.trim().isEmpty) continue;
      for (final line in p.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: plain.length),
      )) {
        final r = MatrixUtils.transformRect(
          p.getTransformTo(null),
          line.toRect(),
        );
        text = text == null ? r : text.expandToInclude(r);
      }
    }
    return text;
  }

  // The frame round a field's [parts] (none of its parts' own faces): the
  // face inside [field] that holds them all, else the nearest box round
  // [field] that paints one and is little taller.
  static ({Rect rect, RenderBox box})? _frameRound(
    _DrawnReader reader,
    RenderBox field,
    List<Rect> parts,
  ) {
    bool holds(Rect r) => parts.every((p) => r.inflate(1).contains(p.center));
    final inner = reader._face(field);
    if (inner != null && holds(inner.rect)) {
      return (rect: inner.rect, box: inner.box);
    }
    final own = _global(field);
    for (RenderObject? up = field.parent; up != null; up = up.parent) {
      if (up is! RenderBox || !up.hasSize) continue;
      final r = _global(up);
      if (r.height > own.height + 48) break;
      if (_isControl(up)) break;
      if (reader._showsFace(up) && holds(r)) return (rect: r, box: up);
    }
    return null;
  }

  // [control]'s face as [DesignRowCheck] reads it, a custom paint's by the
  // box it paints when what it draws spans most of it (a well whose fill is
  // the ground's draws only its bevel).
  static ({Rect rect, RenderBox box})? _faceOf(
    _DrawnReader reader,
    RenderBox control,
  ) {
    final f = reader._face(control);
    if (f == null) return null;
    if (f.box is RenderCustomPaint) {
      final box = _global(f.box).intersect(_global(control).inflate(0.5));
      if (f.rect.width >= box.width / 2 || f.rect.height >= box.height / 2) {
        return (rect: box, box: f.box);
      }
    }
    return (rect: f.rect, box: f.box);
  }

  // The inside of [face] at [y] (global), as drawn: in from each side past
  // what is drawn round its fill (a border, a painted ring or bevel), no
  // further than [text]; [face] less its box's border without pixels.
  static Rect _inside(
    _DrawnReader reader,
    ({Rect rect, RenderBox box}) face,
    Rect text,
  ) {
    final pixels = reader.pixels;
    if (pixels == null || reader.boundary == null) {
      return _within(face.box, face.rect);
    }
    final local = reader._toBoundary(face.rect);
    final words = reader._toBoundary(text);
    final y = words.center.dy;
    final fill = pixels
        .solidIn(
          Rect.fromLTRB(local.left, words.top, local.right, words.bottom),
        )
        .colour;
    final step = 1 / pixels.ratio;
    // In from an outer edge across a band of one colour (a border, a
    // stroke, a bevel's line): a shadow that fades into the fill changes
    // from pixel to pixel, so it is no band past its first. The outermost
    // pixel may blend the band into what is round it.
    double across(double edge, double inward, double limit) {
      double at(double x) => x + inward * step / 2;
      bool before(double x) => inward > 0 ? x < limit : x > limit;
      var x = edge;
      final outer = pixels.pixelAt(at(x), y);
      if (DrawnPixels.alike(outer, fill, by: 12)) return x;
      final band = pixels.pixelAt(at(x + inward * step), y);
      if (!DrawnPixels.alike(outer, band, by: 8)) x += inward * step;
      while (before(x)) {
        final c = pixels.pixelAt(at(x), y);
        if (DrawnPixels.alike(c, fill, by: 12) ||
            !DrawnPixels.alike(c, band, by: 8)) {
          break;
        }
        x += inward * step;
      }
      return x;
    }

    final left = across(local.left, 1, words.left);
    final right = across(local.right, -1, words.right);
    final toGlobal = reader.boundary!.getTransformTo(null);
    final inner = MatrixUtils.transformRect(
      toGlobal,
      Rect.fromLTRB(left, local.top, right, local.bottom),
    );
    final bordered = _within(face.box, face.rect);
    return Rect.fromLTRB(
      math.max(inner.left, bordered.left),
      face.rect.top,
      math.min(inner.right, bordered.right),
      face.rect.bottom,
    );
  }

  static String _px(double v) {
    final r = (v * 2).round() / 2;
    return r == r.roundToDouble() ? '${r.round()} px' : '$r px';
  }

  static String _label(RenderBox box) {
    if (box is RenderSemanticsAnnotations) {
      final l = box.properties.label;
      if (l != null && l.isNotEmpty) return '"$l"';
    }
    final n = _nameOf(box);
    final quote = n.indexOf('"');
    return quote < 0 ? '' : n.substring(quote);
  }

  Iterable<String> _dateField(
    _DrawnReader reader,
    RenderBox field,
    List<RenderBox> segments,
    String kind,
  ) sync* {
    final name = '$kind ${_label(field)}'.trimRight();
    final faces = {for (final s in segments) s: _faceOf(reader, s)};
    final frame = _frameRound(reader, field, [
      for (final s in segments) _global(s),
    ]);
    for (final s in segments) {
      final text = _textOf(s);
      if (text == null) continue;
      final own = faces[s];
      final mine = own != null && own.rect.inflate(0.5).contains(text.center);
      final round = mine ? (rect: own.rect, box: own.box) : frame;
      if (round == null) continue;
      final inside = _inside(reader, round, text);
      final left = text.left - inside.left;
      final right = inside.right - text.right;
      // Edges read from pixels are good to one pixel at the read scale.
      final slack = reader.pixels == null ? 0.01 : 1 / pixelRatio + 0.01;
      if (left < segmentInset - slack || right < segmentInset - slack) {
        final words = s is RenderSemanticsAnnotations
            ? s.properties.label
            : null;
        final seg = words == null || words.isEmpty
            ? 'a segment'
            : 'its $words segment';
        final shown = _shownIn(s)
            .whereType<RenderParagraph>()
            .map((p) => p.text.toPlainText().trim())
            .where((t) => t.isNotEmpty)
            .join(' ');
        yield '$name: $seg "$shown" holds its text ${_px(left)} from its '
            '${mine ? 'frame' : "field's frame"} on the left and ${_px(right)} '
            'on the right; a segment keeps ${_px(segmentInset)} on both sides';
      }
    }
    // The button that opens its picker.
    final button = _triggerOf(reader, field, segments);
    if (button == null) return;
    final face = _faceOf(reader, button);
    if (face == null) return;
    final buttonName = _nameOf(button);
    final segmentFaces = [
      for (final s in segments)
        if (faces[s] case final f?) f.rect,
    ];
    if (segmentFaces.length == segments.length) {
      final heights = [for (final f in segmentFaces) f.height];
      final low = heights.reduce(math.min), high = heights.reduce(math.max);
      if ((face.rect.height - low).abs() > tolerance + 0.01 ||
          (face.rect.height - high).abs() > tolerance + 0.01) {
        final tall = low == high ? _px(low) : '${_px(low)} to ${_px(high)}';
        yield '$name: its segments are $tall tall beside $buttonName, '
            '${_px(face.rect.height)} tall; one row shares one height '
            '(within ${_px(tolerance)})';
      }
      return;
    }
    if (frame == null || frame.rect.inflate(1).contains(face.rect.center)) {
      return;
    }
    if ((frame.rect.height - face.rect.height).abs() > tolerance + 0.01) {
      yield '$name: its frame is ${_px(frame.rect.height)} tall beside '
          '$buttonName, ${_px(face.rect.height)} tall; one row shares one '
          'height (within ${_px(tolerance)})';
    }
  }

  // The control nearest [field] in its row that is not one of its
  // segments: inside it, else beside it (no more than 24 px apart), in the
  // nearest box round it that holds one.
  RenderBox? _triggerOf(
    _DrawnReader reader,
    RenderBox field,
    List<RenderBox> segments,
  ) {
    final own = _global(field);
    bool ofField(RenderBox c) => segments.any(
      (s) => identical(s, c) || _isWithin(c, s) || _isWithin(s, c),
    );
    bool beside(Rect r) =>
        r.top < own.center.dy &&
        r.bottom > own.center.dy &&
        math.max(r.left - own.right, own.left - r.right) <= 24;
    RenderBox? nearest(Iterable<RenderBox> controls) {
      RenderBox? best;
      var gap = double.infinity;
      for (final c in controls) {
        if (ofField(c) || !_isButton(c) || _semanticsOf(c).steps) continue;
        final r = _global(c);
        if (!beside(r)) continue;
        final d = math.max(
          0.0,
          math.max(r.left - own.right, own.left - r.right),
        );
        if (d < gap) {
          gap = d;
          best = c;
        }
      }
      return best;
    }

    final inside = nearest(reader._controlsUnder(field));
    if (inside != null) return inside;
    // Up through a scroll view round the field (its own layers) to the row
    // that lays it out beside its button.
    for (RenderObject? up = field.parent; up != null; up = up.parent) {
      if (up is! RenderBox || !up.hasSize) continue;
      if (_global(up).height > own.height * 3 + 24) break;
      final found = nearest(
        reader._controlsUnder(up).where((c) => !_isWithin(c, field)),
      );
      if (found != null) return found;
    }
    return null;
  }

  Iterable<String> _stepper(
    _DrawnReader reader,
    RenderBox field,
    RenderBox value,
    List<RenderBox> buttons,
  ) sync* {
    final faces = [for (final b in buttons) _faceOf(reader, b)?.rect];
    if (faces.any((f) => f == null)) return;
    final buttonFaces = faces.cast<Rect>();
    // The field's frame: the face round its value that holds no button.
    final valueRect = _global(value);
    Rect? frame;
    final own = _faceOf(reader, value);
    if (own != null && own.rect.inflate(1).contains(valueRect.center)) {
      frame = own.rect;
    }
    if (frame == null) {
      // Up through the entry's own layers (an editable text's scrollable
      // and its viewport) to the first box that paints, short of a button.
      for (RenderObject? up = value.parent; up != null; up = up.parent) {
        if (up is! RenderBox || !up.hasSize) continue;
        final r = _global(up);
        if (buttonFaces.any((b) => r.contains(b.center))) break;
        if (r.height > valueRect.height + 64) break;
        // A paint no taller than the entry's line, or one that draws
        // nothing but the words (a decoration with no border), is no frame.
        if (r.height < valueRect.height + 2 || !reader._showsFace(up)) {
          continue;
        }
        if (up is RenderCustomPaint && reader._ownInk(r, value) == null) {
          continue;
        }
        frame = up is RenderCustomPaint ? (_faceOf(reader, up)?.rect ?? r) : r;
        break;
      }
    }
    if (frame == null) return;
    final f = frame;
    // Buttons inside the field's frame are its own parts.
    if (buttonFaces.any((b) => f.inflate(1).contains(b.center))) return;
    final a = buttonFaces[0], b = buttonFaces[1];
    final stacked =
        a.left < b.right &&
        b.left < a.right &&
        (a.top >= b.bottom - 1 || b.top >= a.bottom - 1);
    final name =
        'a stepper ${_label(field is RenderSemanticsAnnotations ? field : value)}'
            .trimRight();
    if (stacked) {
      final pair = a.expandToInclude(b).height;
      if ((pair - f.height).abs() > tolerance + 0.01) {
        yield '$name: its stacked buttons are ${_px(pair)} tall together '
            'beside its field, ${_px(f.height)} tall; one row shares one '
            'height (within ${_px(tolerance)})';
      }
      return;
    }
    final off = [
      for (final r in buttonFaces)
        if ((r.height - f.height).abs() > tolerance + 0.01) r.height,
    ];
    if (off.isEmpty) return;
    final low = off.reduce(math.min), high = off.reduce(math.max);
    final tall = low == high ? _px(low) : '${_px(low)} and ${_px(high)}';
    yield '$name: its buttons are $tall tall beside its field, '
        '${_px(f.height)} tall; one row shares one height (within '
        '${_px(tolerance)})';
  }
}
