part of '../../review.dart';

/// The controls [DesignWidthCheck] holds to the width of what they show.
enum DesignWidthKind {
  /// A button: a face around one line of words, an icon, or both.
  button('a button', 'buttons'),

  /// A select's closed face: a control that opens a list of choices.
  select('a select', 'selects'),

  /// A segmented control: two or more choices side by side, one chosen.
  segmentedControl('a segmented control', 'segmented controls'),

  /// A stepper: a value between a step down and a step up.
  stepper('a stepper', 'steppers'),

  /// Choices side by side, each a face of its own (choice chips, choice
  /// cards, a toggle group's buttons apart, icon tiles), one or more chosen.
  choiceGroup('a group of choices', 'groups of choices'),

  /// Tabs side by side (`SemanticsRole.tab`), one chosen.
  tabBar('a tab bar', 'tab bars');

  const DesignWidthKind(this.label, this.plural);

  /// How messages name one.
  final String label;

  /// How messages name them all.
  final String plural;
}

/// A width a look allows one kind of control, from [DesignWidthCheck.from]
/// up, with the reason: what a look declares when it means a control wider
/// than [DesignWidthCheck.maxWidth].
@immutable
class DesignWidthLimit {
  /// At most [maxWidth] wide, because of [reason].
  const DesignWidthLimit(this.maxWidth, this.reason);

  /// The widest it may be, in logical pixels.
  final double maxWidth;

  /// Why: a reason, never a to-do.
  final String reason;
}

/// Whether a screen's controls keep to the width of what they show, and a
/// list opened from a field to the field's.
///
/// On a wide screen, a select, a button, a stepper or a segmented control
/// stretched across its column reads as a banner, not a control: the closed
/// face of a dropdown spanning a 1440 page was the fault across looks. From
/// [from] (600) logical pixels wide up, each is held to the width of its
/// content and its own padding (what it takes laid out on its own: its
/// face's intrinsic width), or, when it is wider (a cell of a form's grid, a
/// face of a set width), to [maxWidth] (320). A group of choices and a tab
/// bar are held to [maxWidth] or the room their items take, whichever is
/// wider: each item its content and padding and 40 px more (a minimum
/// width, a folder tab's flare), and the gaps between them; so chips, tabs
/// of a scrollable bar and folder tabs that keep to their words pass, and
/// three words spread over a 1440 column do not. Free text entries, search
/// fields and bars, tables, sliders, list rows, a tab alone, and a control
/// holding more than one line of words may span, and are not read.
///
/// - **Which controls**: read from what the screen shows, with no markers:
///   a control (a box whose semantics take a press, as [DesignLabelCheck]
///   finds them) with a face of its own around one line of words, an icon,
///   or both is a button; one that anchors a [RawPopover] (or a
///   Material dropdown or menu), or whose semantics carry an expanded state,
///   is a select. Two or more tabs side by side (`SemanticsRole.tab` on
///   each control, inside it, or round it alone, as a tab bar says it) are
///   a tab bar, measured from its first tab to its last. Two or more
///   choices side by side (each chosen or not, or toggled) are a segmented
///   control when they are radios (in a mutually exclusive group) or touch
///   inside one face of their own that shows nothing else; else, each
///   showing words or a glyph on a face of its own, a group of choices
///   (choice chips, choice cards, a toggle group's buttons apart, icon
///   tiles), measured by their faces; choices with no face each, or a
///   glyph over their words (a navigation bar's destinations), are read one
///   by one, and a chart's bars, choices on a surface that shows more than
///   them, are none of these. Two icon controls round a value (its words,
///   and a unit beside them), or a control that steps up and down, are a
///   stepper. Two buttons round a heading (a calendar's month, a pushed
///   page's title: `Semantics(header: true)` on it, or on a box round the
///   group holding no other control) are a header, not a stepper. A
///   segmented control or a stepper is measured by the face around it, else
///   by the box laying it out.
/// - **Rows and search, not held**: a row of a list or a section spans it.
///   It is an item of a list as wide as it (Flutter's own
///   `SemanticsRole.listItem`, under a `SemanticsRole.list`, which is how a
///   look says so); else, its words at its leading side, one of a stack of
///   rows as wide as it no more than 4 px apart (a list, an open
///   disclosure's rows) or with only a heading between (words marked
///   `Semantics(header: true)`: a palette's or a menu's groups), or a
///   section's one row, edge to edge across the
///   face it is in, with a glyph or a value at its trailing end; or, but
///   for a select, one so laid out with words between it and any control
///   as wide as it (a row between paragraphs). A search
///   bar says it is one with `SemanticsInputType.search` on the control or
///   a box round it no larger.
/// - **Held, as drawn**: a control is out when its drawn width (its outline,
///   as [DesignRowCheck] reads it, so a ring drawn inside its box counts
///   where it is drawn) is more than [tolerance] past the larger of the two:
///   `a select "Category": 1180 px wide as laid out, 1180 as drawn; its
///   content and padding take 164 (at most 320 from 600 wide)`; `a tab bar
///   "Today": 1376 px wide as laid out, 1376 as drawn; its 3 tabs' content
///   and padding take 186, 306 with 40 a tab and the gaps (at most 320 from
///   600 wide)`.
/// - **Words that wrap**: a button or a select whose one line of words
///   wraps onto two, though on one line it would take no more than
///   [maxWidth], is narrower than its content, whatever its width: `a
///   button "Open the command palette": its words wrap onto 2 lines in 152
///   px; on one line they take 214 (from 600 wide buttons keep their words
///   on one line)`.
/// - **A form's fields, held as a column**: a select (a date field among
///   them), a segmented control or a group of choices with another field
///   over or under it on the same leading and trailing edges (a text entry,
///   or another of these) is a field of a form, and takes the form's
///   column, as Material's fields and a look's text fields do. The bound is
///   the column's: [formWidth] (720), so a form keeps to a measure and no
///   field runs the width of a desktop window: `a select "Shelf": a field
///   of a form, 1392 px wide as laid out, 1392 as drawn (a form keeps to 720
///   from 600 wide)`. One alone, with no field on its edges (a toolbar's
///   filter), keeps to its content as above. A text entry's face is the one
///   inside it or the well drawn round it, read in the layer its field is
///   drawn on: an entry drawn in a repaint boundary no larger than its
///   field (Flutter's TextField paints its EditableText in one) is read in
///   the layer round it, with its form's other fields.
/// - **A look's own limit**: [limits] gives a kind another width, with the
///   reason (`DesignWidthLimit(400, 'the sign-in card's one act spans its
///   400 card')`); a reason that is a to-do fails.
///
/// [checkList] holds a list opened from a field (a select, a combobox, a
/// menu from a form field), with the list open, at any width: at least as
/// wide as the field and no wider than the larger of the field and its
/// widest item, starting on its leading edge, its words on the field's words
/// or [listWordsIndent] in from them. The list's edges are read as drawn
/// against the page under it, also when the list is drawn in a layer of its
/// own size (a [RawPopover]'s surface), whose own pixels hold
/// nothing round it.
///
/// Before the check, a test loads the look's fonts and lets the screen's
/// images decode, as [DesignLabelCheck] shows. A test pumps each gallery
/// page and app screen at 600, 1024, 1440 and 1920 wide and checks it; for
/// each field that opens a list, at 390 and 1440, it taps the field, lets
/// the list open, and checks the list:
///
/// ```dart
/// const widths = DesignWidthCheck(look: 'Comic');
/// (await widths.check(
///   tester.element(find.byType(SettingsScreen)),
///   runAsync: tester.runAsync,
/// )).verify();
/// (await widths.checkList(
///   tester.element(find.byKey(fieldKey)),
///   runAsync: tester.runAsync,
/// )).verify();
/// ```
///
/// It reads layout boxes, and the drawn pixels where only they show it (a
/// field's or a menu's painted surface), so it takes the tester's `runAsync`.
@immutable
class DesignWidthCheck {
  /// A check for [look].
  const DesignWidthCheck({
    required this.look,
    this.from = 600,
    this.maxWidth = 320,
    this.formWidth = 720,
    this.limits = const {},
    this.listWordsIndent = 0,
    this.tolerance = 1,
    this.contrastFloor = 1.25,
    this.pixelRatio = 1,
  });

  /// The look's name, for messages.
  final String look;

  /// The screen width, in logical pixels, from which [check] holds the
  /// controls' widths; on a narrower screen a control may span its column.
  final double from;

  /// The widest a control may be when the width of its content and padding
  /// does not need more, in logical pixels.
  final double maxWidth;

  /// The widest a form's column of fields may be, in logical pixels: a
  /// field of a form takes the column, and the column keeps to this.
  final double formWidth;

  /// Another width for a kind of control, with the reason.
  final Map<DesignWidthKind, DesignWidthLimit> limits;

  /// How far, in logical pixels toward the trailing edge, a list's words
  /// stand in from the words of the field that opened it: 0 when they line
  /// up; the width of a check column when the look's list sets one before
  /// its words.
  final double listWordsIndent;

  /// How far, in logical pixels, a width or an edge may be off.
  final double tolerance;

  /// The contrast with what is around a face a drawn pixel needs to count
  /// as part of its outline, as [DesignRowCheck.contrastFloor].
  final double contrastFloor;

  /// The scale the screen is drawn at to read its pixels.
  final double pixelRatio;

  DesignRowCheck get _drawn => DesignRowCheck(
    look: look,
    contrastFloor: contrastFloor,
    pixelRatio: pixelRatio,
  );

  /// Checks every button, select, stepper, segmented control, group of
  /// choices and tab bar under [context] (on screen, under a repaint
  /// boundary), when the screen is at least [from] wide. A test passes its tester's `runAsync` (reading
  /// pixels takes real time); null reads them directly.
  Future<DesignAlignmentReport> check(
    BuildContext context, {
    Future<T?> Function<T>(Future<T> Function() work)? runAsync,
  }) async {
    final found = <String>[
      for (final MapEntry(key: kind, value: limit) in limits.entries)
        if (isToDoReason(limit.reason))
          'a limit for ${kind.plural}: "${limit.reason}" is a to-do, not a '
              'reason',
    ];
    final root = context.findRenderObject();
    final screen = MediaQuery.maybeSizeOf(context)?.width;
    if (root == null || (screen != null && screen < from)) {
      return DesignAlignmentReport(look, found);
    }
    final marked = _markedFaces(context);
    final anchors = _anchorBoxes(context);
    final finder = _DrawnReader(null, null, marked);
    final items =
        <
          ({
            RenderBox box,
            RenderBox? control,
            List<RenderBox> held,
            DesignWidthKind kind,
          })
        >[];
    final controls = <RenderBox>[];
    void visit(RenderObject node) {
      if (node is RenderBox && node.hasSize && _isControl(node)) {
        // A modal barrier (a tap outside a dialog closes it) takes taps and
        // may be named ('Dismiss'), but it is the screen round the dialog,
        // no button: no width to hold.
        if (_isBarrier(node)) return;
        controls.add(node);
        final kind =
            _kindOf(node, anchors) ??
            (_wrappedWords(node) == null ? null : DesignWidthKind.button);
        if (kind != null) {
          items.add((box: node, control: node, held: [node], kind: kind));
        }
        return;
      }
      // Two or more controls side by side: a segmented control or a
      // stepper, measured whole.
      final held = <RenderBox>[];
      var groups = 0;
      _visitShown(node, (child) {
        final under = [
          for (final c
              in child is RenderBox && child.hasSize && _isControl(child)
                  ? [child]
                  : finder._controlsUnder(child))
            if (!_isBarrier(c)) c,
        ];
        if (under.isNotEmpty) groups++;
        held.addAll(under);
      });
      if (node is RenderBox &&
          node.hasSize &&
          groups >= 2 &&
          DesignRowCheck._sideBySide(held)) {
        final kind = _groupKind(finder, node, held);
        if (kind != null) {
          items.add((box: node, control: null, held: held, kind: kind));
          return;
        }
      }
      _visitShown(node, visit);
    }

    visit(root);
    final readers = <RenderRepaintBoundary, _RowReader>{};
    Future<_RowReader?> readerFor(RenderObject node) async {
      final boundary = _drawnIn(node);
      if (boundary == null) return null;
      if (readers[boundary] case final r?) return r;
      final pixels = await DrawnPixels.read(boundary, pixelRatio, runAsync);
      return readers[boundary] = _RowReader(_drawn, boundary, pixels, marked);
    }

    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    // A form's fields, by the face each shows (laid out, and as drawn): its
    // text entries, and its selects, segmented controls and groups of
    // choices.
    final fields = <({RenderRepaintBoundary? boundary, Rect laid})>[];
    final formFields = <int, ({Rect laid, Rect drawn})>{};
    for (final c in controls) {
      if (!_semanticsOf(c).entry) continue;
      // Its face: one inside it, or the well drawn round it.
      Rect faceOf(_RowReader r) =>
          (r._face(c) ?? r._well(c, root))?.rect ?? _global(c);
      var reader = await readerFor(c);
      // An entry's face is read in the layer round it when the boundary it
      // is drawn in is no larger than the field: Flutter's TextField paints
      // its EditableText in a repaint boundary of its own, the face round it
      // on the page; a field may be drawn whole in a boundary its own size.
      // Its form's other fields are on the page.
      while (reader != null) {
        final boundary = reader.boundary;
        if (boundary == null) break;
        final field = faceOf(reader).inflate(tolerance);
        final drawn = _global(boundary);
        if (drawn.left < field.left ||
            drawn.top < field.top ||
            drawn.right > field.right ||
            drawn.bottom > field.bottom) {
          break;
        }
        final parent = boundary.parent;
        final up = parent == null ? null : _drawnIn(parent);
        if (up == null) break;
        reader = await readerFor(up);
      }
      if (reader == null) continue;
      fields.add((boundary: reader.boundary, laid: faceOf(reader)));
    }
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (!_formKinds.contains(item.kind)) continue;
      final reader = await readerFor(item.box);
      if (reader == null) continue;
      final ({Rect laid, Rect drawn})? field;
      if (item.kind == DesignWidthKind.choiceGroup) {
        final m = _itemsWidth(reader, item.held, tabs: false);
        field = m == null ? null : (laid: m.laid, drawn: m.drawn);
      } else {
        final face = item.control == null
            ? _groupFace(reader, item.box, item.held)
            : reader._face(item.control!);
        field = face == null
            ? null
            : (
                laid: face.rect,
                drawn: marked.contains(face.box)
                    ? face.rect
                    : reader._outline(
                            face.rect,
                            item.control ?? item.box,
                            face.read ? null : face.box,
                            null,
                          ) ??
                          face.rect,
              );
      }
      if (field == null) continue;
      fields.add((boundary: reader.boundary, laid: field.laid));
      formFields[i] = field;
    }
    // Whether [field] has another field over or under it, on its edges.
    bool inForm(RenderRepaintBoundary? boundary, Rect field) => fields.any(
      (f) =>
          f.boundary == boundary &&
          f.laid != field &&
          (f.laid.left - field.left).abs() <= tolerance &&
          (f.laid.right - field.right).abs() <= tolerance &&
          (f.laid.top >= field.bottom - tolerance ||
              f.laid.bottom <= field.top + tolerance),
    );
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final reader = await readerFor(item.box);
      if (reader == null) continue;
      if (formFields[i] case final field?
          when inForm(reader.boundary, field.laid)) {
        if (field.laid.width <= formWidth + tolerance ||
            field.drawn.width <= formWidth + tolerance) {
          continue;
        }
        found.add(
          '${_kindName(item.kind, item.control ?? item.held.first)}: a field '
          'of a form, ${_px(field.laid.width)} px wide as laid out, '
          '${_px(field.drawn.width)} as drawn (a form keeps to '
          '${_px(formWidth)} from ${_px(from)} wide)',
        );
        continue;
      }
      if (item.control case final control?
          when _isListRow(
            reader,
            control,
            controls,
            rtl,
            select: item.kind == DesignWidthKind.select,
          )) {
        continue;
      }
      if (item.kind == DesignWidthKind.choiceGroup ||
          item.kind == DesignWidthKind.tabBar) {
        final tabs = item.kind == DesignWidthKind.tabBar;
        final m = _itemsWidth(reader, item.held, tabs: tabs);
        if (m == null) {
          // Choices with no face each of their own (a navigation bar's
          // destinations): each read on its own.
          if (!tabs) {
            for (final c in item.held) {
              if (_kindOf(c, anchors) case final kind?) {
                items.add((box: c, control: c, held: [c], kind: kind));
              }
            }
          }
          continue;
        }
        final limit = limits[item.kind]?.maxWidth ?? maxWidth;
        final allowed = math.max(m.room, limit);
        if (m.laid.width <= allowed + tolerance ||
            m.drawn.width <= allowed + tolerance) {
          continue;
        }
        final what = tabs ? 'tab' : 'choice';
        found.add(
          '${_kindName(item.kind, item.held.first)}: '
          '${_px(m.laid.width)} px wide as laid out, ${_px(m.drawn.width)} as '
          "drawn; its ${m.count} ${what}s' content and padding take "
          '${_px(m.content)}, ${_px(m.room)} with ${_px(_itemRoom)} a $what '
          'and the gaps (at most ${_px(limit)} from ${_px(from)} wide)',
        );
        continue;
      }
      // A button whose words wrap: narrower than its content, whatever its
      // width.
      if (item.control case final control?
          when item.kind == DesignWidthKind.button ||
              item.kind == DesignWidthKind.select) {
        if (_wrappedWords(control) case final p?) {
          final line = p.getFullHeightForCaret(const TextPosition(offset: 0));
          final lines = line > 0 ? (p.size.height / line).round() : 2;
          found.add(
            '${_kindName(item.kind, control)}: its words wrap onto $lines '
            'lines in ${_px(p.size.width)} px; on one line they take '
            '${_px(p.getMaxIntrinsicWidth(double.infinity))} (from '
            '${_px(from)} wide ${item.kind.plural} keep their words on one '
            'line)',
          );
          continue;
        }
      }
      final face = item.control == null
          ? _groupFace(reader, item.box, item.held)
          : reader._face(item.control!);
      if (face == null) continue;
      // A group's content is at least its controls' own, side by side (a
      // face painted behind them holds none of it).
      final own = item.control != null
          ? null
          : item.held.fold<double?>(0, (sum, c) {
              final w = _contentWidth(c, c.size.height);
              return sum == null || w == null ? null : sum + w;
            });
      final faceWidth = _contentWidth(face.box, face.box.size.height);
      final natural = faceWidth == null && own == null
          ? null
          : math.max(faceWidth ?? 0, own ?? 0);
      final limit = limits[item.kind]?.maxWidth ?? maxWidth;
      final allowed = math.max(natural ?? 0, limit);
      if (face.rect.width <= allowed + tolerance) continue;
      final drawn = marked.contains(face.box)
          ? face.rect
          : reader._outline(
                  face.rect,
                  item.control ?? item.box,
                  face.read ? null : face.box,
                  null,
                ) ??
                face.rect;
      if (drawn.width <= allowed + tolerance) continue;
      final takes = natural == null
          ? ''
          : '; its content and padding take ${_px(natural)}';
      found.add(
        '${_kindName(item.kind, item.control ?? item.box)}: '
        '${_px(face.rect.width)} px wide as laid out, ${_px(drawn.width)} as '
        'drawn$takes (at most ${_px(limit)} from ${_px(from)} wide)',
      );
    }
    return DesignAlignmentReport(look, found);
  }

  /// Checks the list opened from [field] (a select, a combobox, a menu from
  /// a form field: the widget the test pressed to open it), with the list
  /// open: at least as wide as the field and no wider than the larger of
  /// the field and its widest item with the list's padding (`a list opened
  /// from a select "Period": 1180 px wide as laid out, wider than the field
  /// (343) and its widest item with its padding (126)`), starting on its
  /// leading edge, and
  /// its first item's words on the field's words, or [listWordsIndent] in
  /// from them, each as laid out and as drawn. The list is the face nearest
  /// the field, above or below it, that holds two or more controls one over
  /// another (by what they show, not touch targets that overhang it); or a
  /// popup, whatever it holds (one row, a "no matches" note): a layer drawn
  /// over the field's page (a menu's route, an overlay portal's child), or
  /// a box drawn straight into the overlay, read as laid out (with no
  /// repaint boundary above it to read). A combobox's field is its text
  /// entry and the toggle beside it: the face around both, the entry's
  /// words. A multi-select's groove holding chosen chips before its entry
  /// is its field, held by width and leading edge; its words move with what
  /// is chosen, so the list's words are not held to them. A disabled field
  /// opens nothing, so it has nothing to check.
  Future<DesignAlignmentReport> checkList(
    BuildContext field, {
    Future<T?> Function<T>(Future<T> Function() work)? runAsync,
  }) async {
    final box = field.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return DesignAlignmentReport(look, ['no field to check']);
    }
    final rtl = Directionality.maybeOf(field) == TextDirection.rtl;
    final marked = _markedFaces(field);
    final finder = _DrawnReader(null, null, marked);
    // The field's controls: one for a select; a combobox's text entry and
    // the toggle beside it, the entry's words the field's and the face
    // around both the field's.
    final controls = _isControl(box) ? [box] : finder._controlsUnder(box);
    if (controls.isEmpty
        ? _semanticsOf(box).disabled
        : controls.every((c) => _semanticsOf(c).disabled)) {
      // A disabled field opens nothing: there is no list to check.
      return DesignAlignmentReport(look, const []);
    }
    final control =
        controls.where((c) => _semanticsOf(c).entry).firstOrNull ??
        controls.firstOrNull ??
        box;
    final whole = controls.length > 1 ? box : control;
    var root = box as RenderObject;
    while (root.parent != null) {
      root = root.parent!;
    }
    final readers = <RenderRepaintBoundary, _RowReader>{};
    Future<_RowReader?> readerFor(RenderObject node) async {
      final boundary = _drawnIn(node);
      if (boundary == null) return null;
      if (readers[boundary] case final r?) return r;
      final pixels = await DrawnPixels.read(boundary, pixelRatio, runAsync);
      return readers[boundary] = _RowReader(_drawn, boundary, pixels, marked);
    }

    final fieldReader = await readerFor(control);
    if (fieldReader == null) return DesignAlignmentReport(look, const []);
    // What a field or its list stands on is the page under it. One drawn
    // in a repaint boundary of its own size (RawPopover draws
    // its surface in one; a padded ListView, each child) has none of the
    // page round its edges in its own image, where the band round it is
    // clear or its own colour: the ground is read from the page's, the
    // boundary the field is drawn in or the nearest round it that holds a
    // ring round [laid].
    Future<int?> groundUnder(_RowReader own, Rect laid) async {
      final ring = laid.inflate(2);
      bool holds(RenderBox b) {
        final r = _global(b);
        return r.left <= ring.left &&
            r.top <= ring.top &&
            r.right >= ring.right &&
            r.bottom >= ring.bottom;
      }

      int? opaqueGround(_RowReader reader) {
        final color = reader.pixels?.groundAround(reader._toBoundary(laid), 2);
        return color != null && (color & 0xFF) == 0xFF ? color : null;
      }

      if (own.boundary case final b? when holds(b)) {
        final ground = opaqueGround(own);
        if (ground != null) return ground;
      }
      for (
        RenderObject? up = fieldReader.boundary;
        up != null;
        up = up.parent
      ) {
        if (up is! RenderRepaintBoundary || !up.hasSize || !holds(up)) {
          continue;
        }
        final page = await readerFor(up);
        if (page == null) continue;
        final ground = opaqueGround(page);
        if (ground != null) return ground;
      }
      return null;
    }

    // A text field with no toggle (an autocomplete's field view): its face is
    // drawn round its entry, not in it (a label over it, a helper under it).
    final entryOnly =
        controls.length == 1 &&
        !identical(control, box) &&
        _semanticsOf(control).entry;
    final fieldFace = controls.length > 1
        ? fieldReader._face(box)
        : (entryOnly ? fieldReader._face(box) : null) ??
              fieldReader._face(control) ??
              fieldReader._well(control, root);
    // A face read from its own ink stops short on its lit sides as its
    // outline does (_litTo): read to its box there.
    final fieldLaid = fieldFace == null
        ? _global(whole)
        : fieldFace.read
        ? fieldReader._litTo(_global(fieldFace.box), fieldFace.rect)
        : fieldFace.rect;
    // A side lit from a corner reads short as drawn (a groove's highlight,
    // too faint to stand off): read to its box there (_litTo).
    // A field drawn in a repaint boundary its own size (a padded ListView's
    // child) is read against the page round it: in its own image the band
    // round it is clear, and its own rule was read as ground (an outline 2
    // in on each side of a 2 px rule).
    final fieldGround = fieldFace == null
        ? null
        : await groundUnder(fieldReader, fieldLaid);
    final fieldOutline = fieldFace == null
        ? null
        : fieldReader._outline(
            fieldLaid,
            whole,
            fieldFace.read ? null : fieldFace.box,
            fieldGround,
          );
    final fieldDrawn = fieldOutline == null
        ? fieldLaid
        : fieldReader._litTo(fieldLaid, fieldOutline, ground: fieldGround);
    var top = field as Element;
    field.visitAncestorElements((e) {
      top = e;
      return true;
    });
    final anchors = _anchorBoxes(top);
    // Named by what the field shows, its toggle's words ("Show
    // suggestions") left out.
    final name = _kindName(
      controls.any((c) => _kindOf(c, anchors) == DesignWidthKind.select)
          ? DesignWidthKind.select
          : _kindOf(control, anchors) ?? DesignWidthKind.button,
      whole,
      skip: {
        for (final c in controls)
          if (!identical(c, control)) c,
      },
    );
    final list = await _listFrom(root, box, fieldLaid, finder, (n) async {
      final reader = await readerFor(n);
      return reader != null && reader._standsOff(n);
    });
    if (list == null) {
      return DesignAlignmentReport(look, ['no list open from $name']);
    }
    // A list with no repaint boundary above it (drawn straight into the
    // overlay) is read as laid out.
    final listReader = await readerFor(list);
    final listLaid = _global(list);
    final listGround = listReader == null
        ? null
        : await groundUnder(listReader, listLaid);
    final listOutline = listReader?._outline(listLaid, list, list, listGround);
    final listRead = listOutline == null
        ? null
        : listReader!._litTo(listLaid, listOutline, ground: listGround);
    final listDrawn = listRead ?? listLaid;
    String drawnAs(String v) => listReader == null ? '' : ', $v as drawn';
    // The field as the list is held to it: as drawn when the list is read
    // as drawn, else as laid out, the one measure on both.
    final fieldSeen = listRead == null ? fieldLaid : fieldDrawn;
    final who = 'a list opened from $name';
    final found = <String>[];
    if (listDrawn.width < fieldSeen.width - tolerance) {
      found.add(
        '$who: ${_px(listLaid.width)} px wide as laid out'
        '${drawnAs(_px(listDrawn.width))}, narrower than the field '
        '(${_px(fieldLaid.width)}, ${_px(fieldDrawn.width)} as drawn)',
      );
    }
    // Toward the trailing edge, positive.
    double lead(Rect r) => rtl ? -r.right : r.left;
    final items = finder._controlsUnder(list)
      ..sort((a, b) => _global(a).top.compareTo(_global(b).top));
    // No wider than it needs, as drawn (a list laid out with room round its
    // face for its shadow is as wide as its face): the larger of the field
    // and its widest item's content, with the list's own padding round it
    // (as far in from its trailing edge as from its leading one).
    double? needs;
    for (final item in items) {
      final content = _contentWidth(item, item.size.height);
      if (content == null) {
        needs = null;
        break;
      }
      final inset = math.max(0.0, lead(_global(item)) - lead(listLaid));
      needs = math.max(needs ?? 0, content + 2 * inset);
    }
    if (needs != null &&
        listDrawn.width >
            math.max(math.max(fieldLaid.width, fieldDrawn.width), needs) +
                tolerance) {
      found.add(
        '$who: ${_px(listLaid.width)} px wide as laid out'
        '${drawnAs(_px(listDrawn.width))}, wider than the field '
        '(${_px(fieldLaid.width)}) and its widest item with its padding '
        '(${_px(needs)}): a list is the field\'s width, or as wide as its '
        'widest item past it, never wider',
      );
    }
    final laidIn = lead(listLaid) - lead(fieldLaid);
    final drawnIn = lead(listDrawn) - lead(fieldSeen);
    if (drawnIn.abs() > tolerance) {
      found.add(
        "$who: its leading edge is ${_inFrom(laidIn)} the field's as laid "
        'out${drawnAs(_inFrom(drawnIn))}',
      );
    }
    // Chosen values shown before the entry (a multi-select's chips in its
    // groove): the field's words move with what is chosen, so the list's
    // are not held to them. A chip is a control holding its words, or a
    // tag's words beside a remove button that shows none (an x), on the
    // entry's row.
    final entry = _global(control);
    final entryLead = lead(entry);
    bool before(Rect r) => lead(r) < entryLead - tolerance;
    bool onEntryRow(Rect r) => r.top < entry.bottom && r.bottom > entry.top;
    final inControls = {for (final c in controls) ..._wordsOf(c)};
    final tagWords = _wordsOf(whole).any((w) {
      final r = _global(w);
      return !inControls.contains(w) && before(r) && onEntryRow(r);
    });
    final chipsFirst = controls.any((c) {
      if (identical(c, control)) return false;
      final r = _global(c);
      return before(r) &&
          (_wordsOf(c).isNotEmpty || (tagWords && onEntryRow(r)));
    });
    final fieldWords = chipsFirst ? null : _wordsStart(control, rtl);
    final listWords = items.isEmpty ? null : _wordsStart(items.first, rtl);
    if (fieldWords != null && listWords != null) {
      final words = (rtl ? -1 : 1) * (listWords - fieldWords);
      if ((words - listWordsIndent).abs() > tolerance) {
        final stated = listWordsIndent == 0
            ? ''
            : ' (the look states ${_px(listWordsIndent)} in)';
        found.add(
          "$who: its words are ${_inFrom(words)} the field's words$stated",
        );
      }
    }
    return DesignAlignmentReport(look, found);
  }

  // "12 px in from", "4 px out past", "on".
  static String _inFrom(double v) {
    if (_px(v).replaceFirst('-', '') == '0') return 'on';
    return v > 0 ? '${_px(v)} px in from' : '${_px(-v)} px out past';
  }

  // The width [box]'s content and padding take laid out on their own, a
  // width set on the face itself (a SizedBox, a Container's width) left
  // out. Null when it can't say (a layout builder inside it).
  static double? _contentWidth(RenderBox box, double height) {
    try {
      return switch (box) {
        RenderConstrainedBox(:final child) =>
          child == null ? 0 : _contentWidth(child, height),
        RenderPadding(:final padding, :final textDirection, :final child) =>
          () {
            final p = padding.resolve(textDirection);
            final inner = child == null
                ? 0.0
                : _contentWidth(child, math.max(0, height - p.vertical));
            return inner == null ? null : p.horizontal + inner;
          }(),
        RenderProxyBox(:final child?) => _contentWidth(child, height),
        RenderPositionedBox(:final child?) => _contentWidth(child, height),
        _ => box.getMaxIntrinsicWidth(height),
      };
    } on Object {
      return null;
    }
  }

  // The kinds a form's field may be: each takes the form's column.
  static const _formKinds = {
    DesignWidthKind.select,
    DesignWidthKind.segmentedControl,
    DesignWidthKind.choiceGroup,
  };

  // The kind of a single [control], or null for one that may span (a text
  // entry, a search bar, a slider, a toggle, a link, a list row of more than
  // one line, a tab) or that shows no face of its own.
  static DesignWidthKind? _kindOf(RenderBox control, Set<RenderBox> anchors) {
    final s = _semanticsOf(control);
    if (s.entry ||
        s.search ||
        _searchRound(control) ||
        s.slider ||
        s.toggle ||
        s.link ||
        s.tab) {
      return null;
    }
    final lines = [
      for (final p in _shownIn(control))
        if (p is RenderParagraph &&
            !isIconGlyph(p.text.toPlainText(includeSemanticsLabels: false)))
          p,
    ];
    if (lines.length > 1 || lines.any((p) => !isOneLine(p))) return null;
    if (s.expanded || _anchored(control, anchors)) {
      return DesignWidthKind.select;
    }
    if (s.steps) return DesignWidthKind.stepper;
    return DesignWidthKind.button;
  }

  // The one paragraph of words [control] shows when it wraps them onto more
  // than one line though, on one, they fit [maxWidth] (a button narrower
  // than its words: "Open the command palette" over two lines); null when
  // its words keep to one line, run over [maxWidth] on one (a sentence), or
  // break where its text does. A control that may hold more than one line
  // (a text entry, a toggle's or a link's words) has none.
  RenderParagraph? _wrappedWords(RenderBox control) {
    final s = _semanticsOf(control);
    if (s.entry || s.search || s.slider || s.toggle || s.link || s.tab) {
      return null;
    }
    final lines = [
      for (final p in _shownIn(control))
        if (p is RenderParagraph &&
            !isIconGlyph(p.text.toPlainText(includeSemanticsLabels: false)))
          p,
    ];
    if (lines.length != 1) return null;
    final p = lines.single;
    final text = p.text.toPlainText(includeSemanticsLabels: false);
    if (p.maxLines == 1 || isOneLine(p) || text.contains('\n')) return null;
    final limit = limits[DesignWidthKind.button]?.maxWidth ?? maxWidth;
    return p.getMaxIntrinsicWidth(double.infinity) <= limit ? p : null;
  }

  // Whether a box round [control], no larger than it, says it is a search
  // (SemanticsInputType.search).
  static bool _searchRound(RenderBox control) {
    final own = _global(control);
    for (var up = control.parent; up is RenderBox; up = up.parent) {
      if (!up.hasSize) break;
      final r = _global(up);
      if ((r.width - own.width).abs() > 0.5 ||
          (r.height - own.height).abs() > 0.5) {
        break;
      }
      if (up is RenderSemanticsAnnotations &&
          up.properties.inputType == SemanticsInputType.search) {
        return true;
      }
    }
    return false;
  }

  // Whether [control] is a row of a list or a section, which spans it and
  // is not held: an item of a list (SemanticsRole.listItem, or inside a
  // SemanticsRole.list) as wide as it; or, its words at its leading side,
  // one of a stack of rows as wide as it with no more than 4 px or only a
  // heading between (a list, an open disclosure's rows, a palette's
  // groups), or alone edge to edge across the
  // face it is in (a section's one row), with something at its trailing
  // end (a value, a glyph); or, no [select], so laid out with words between
  // it and any control as wide as it (a row between paragraphs).
  static bool _isListRow(
    _DrawnReader reader,
    RenderBox control,
    List<RenderBox> controls,
    bool rtl, {
    required bool select,
  }) {
    final box = _global(control);
    bool sameWidth(Rect r) =>
        (r.left - box.left).abs() <= 1 && (r.right - box.right).abs() <= 1;
    for (RenderObject? up = control; up != null; up = up.parent) {
      if (identical(up, reader.boundary)) break;
      if (up is RenderSemanticsAnnotations &&
          (up.properties.role == SemanticsRole.listItem ||
              up.properties.role == SemanticsRole.list) &&
          sameWidth(_global(up))) {
        return true;
      }
    }
    if (!_atLead(control, box, rtl)) return false;
    for (final other in controls) {
      if (identical(other, control)) continue;
      final r = _global(other);
      if (!sameWidth(r)) continue;
      final gap = r.top >= box.center.dy
          ? r.top - box.bottom
          : box.top - r.bottom;
      if (gap >= -0.5 && gap <= 4) return true;
      // A heading apart (a palette's or a menu's groups).
      if (gap > 4 && _headingBetween(control, box, r, controls)) {
        return true;
      }
    }
    if (!_atTrail(control, box, rtl)) return false;
    final section = _sectionOf(reader, control);
    if (section != null && sameWidth(_global(section))) return true;
    // Elsewhere, alone (a row between paragraphs): a row by how it lays out
    // what it shows, its words leading and a glyph or a value trailing,
    // where a button centres its words. Never a select, whose value and
    // chevron lie the same way; never one of a stack of controls as wide
    // as it with only space between (rows apart, held as buttons).
    if (select) return false;
    List<Rect>? words;
    for (final other in controls) {
      if (identical(other, control)) continue;
      final r = _global(other);
      if (!sameWidth(r)) continue;
      final Rect between;
      if (r.top >= box.bottom) {
        between = Rect.fromLTRB(box.left, box.bottom, box.right, r.top);
      } else if (r.bottom <= box.top) {
        between = Rect.fromLTRB(box.left, r.bottom, box.right, box.top);
      } else {
        continue;
      }
      words ??= [
        for (final w in _shownIn(reader.boundary ?? control)) _global(w),
      ];
      if (!words.any((w) => w.overlaps(between))) return false;
    }
    return true;
  }

  // Whether all that stands between rows [a] and [b] (global), one over the
  // other, is a heading: words marked `Semantics(header: true)`, no control.
  static bool _headingBetween(
    RenderBox control,
    Rect a,
    Rect b,
    List<RenderBox> controls,
  ) {
    final between = b.top >= a.bottom
        ? Rect.fromLTRB(a.left, a.bottom, a.right, b.top)
        : Rect.fromLTRB(a.left, b.bottom, a.right, a.top);
    if (between.height <= 0) return false;
    for (final c in controls) {
      if (_global(c).intersect(between).height > 0.5) return false;
    }
    var heading = false;
    // The words under the nearest box round the gap: each row may be drawn
    // in a repaint boundary of its own (a list's rows are), the heading in
    // another.
    RenderObject root = control;
    final gap = between.deflate(0.5);
    for (RenderObject? up = control.parent; up != null; up = up.parent) {
      root = up;
      if (up is RenderBox &&
          up.hasSize &&
          _global(up).inflate(0.5).contains(gap.topLeft) &&
          _global(up).inflate(0.5).contains(gap.bottomRight)) {
        break;
      }
    }
    for (final w in _shownIn(root)) {
      final r = _global(w);
      if (r.intersect(between).height <= 0.5 || r.width <= 0) continue;
      if (r.left < between.left - 0.5 || r.right > between.right + 0.5) {
        return false;
      }
      var marked = false;
      for (RenderObject? up = w; up != null; up = up.parent) {
        if (up is RenderBox && up.hasSize) {
          final u = _global(up);
          if (u.top < between.top - 0.5 || u.bottom > between.bottom + 0.5) {
            break;
          }
        }
        if (up case RenderSemanticsAnnotations(:final properties)
            when properties.header == true) {
          marked = true;
          break;
        }
      }
      if (!marked) return false;
      heading = true;
    }
    return heading;
  }

  // Whether [control]'s words start at its leading side: within a quarter
  // of its width (laid out at [box]) from its leading edge.
  static bool _atLead(RenderBox control, Rect box, bool rtl) {
    final start = _wordsStart(control, rtl);
    if (start == null) return false;
    final inset = rtl ? box.right - start : start - box.left;
    return inset <= box.width / 4;
  }

  // Whether [control] (laid out at [box]) shows something besides its first
  // words at its trailing end: a value or a glyph in its trailing half,
  // within a quarter of its width from that edge.
  static bool _atTrail(RenderBox control, Rect box, bool rtl) {
    final first = labelLine(control);
    for (final b in _shownIn(control)) {
      if (identical(b, first)) continue;
      final r = _global(b);
      final inTrailingHalf = rtl
          ? r.right <= box.center.dx
          : r.left >= box.center.dx;
      final inset = rtl ? r.left - box.left : box.right - r.right;
      if (inTrailingHalf && inset <= box.width / 4) return true;
    }
    return false;
  }

  // The face [control] is in, short of its own: the nearest box round it
  // that shows a face (by its paint or its pixels) and holds more than it;
  // null on the screen itself.
  static RenderBox? _sectionOf(_DrawnReader reader, RenderBox control) {
    final own = _global(control);
    for (RenderObject? up = control.parent; up != null; up = up.parent) {
      if (identical(up, reader.boundary)) return null;
      if (up is! RenderBox || !up.hasSize || _isControl(up)) continue;
      if (!reader._showsFace(up) && !reader._standsOff(up)) continue;
      final more =
          reader._controlsUnder(up).length > 1 ||
          _shownIn(up).any((b) {
            final c = _global(b).center;
            return !own.contains(c);
          });
      if (more) return up;
    }
    return null;
  }

  // The kind of controls [held] side by side in [node]: tabs, a tab bar;
  // choices (chosen or toggled; none a glyph over its words, a navigation
  // bar's destination) that are radios, or touch with one face round them
  // all, a segmented control; other choices showing words or a
  // glyph, a group of choices (held only when each shows a face of its
  // own: chips, choice cards, icon tiles; not a navigation bar's
  // destinations or a chart's bars); two icon controls round a value (its
  // words, a unit beside them), a stepper; else null (read one by one).
  static DesignWidthKind? _groupKind(
    _DrawnReader finder,
    RenderBox node,
    List<RenderBox> held,
  ) {
    final each = [for (final c in held) _semanticsOf(c)];
    if (each.any((s) => s.entry || s.slider || s.link)) return null;
    if (each.every((s) => s.tab)) return DesignWidthKind.tabBar;
    if (each.any((s) => s.tab)) return null;
    if (each.every((s) => s.choice || s.toggle)) {
      // A glyph over its words: a navigation bar's destination, read on its
      // own.
      if (held.any(_glyphOverWords)) return null;
      if (each.every((s) => s.radio)) return DesignWidthKind.segmentedControl;
      final boxes = [for (final c in held) _global(c)]
        ..sort((a, b) => a.left.compareTo(b.left));
      var touching = true;
      for (var i = 1; i < boxes.length && touching; i++) {
        touching = boxes[i].left - boxes[i - 1].right <= 2;
      }
      if (touching && _sharedFace(finder, node, held)) {
        return DesignWidthKind.segmentedControl;
      }
      if (held.every(
        (c) =>
            _wordsOf(c).isNotEmpty ||
            _shownIn(c).any(
              (b) => b is RenderParagraph && isIconGlyph(lineText(b).trim()),
            ),
      )) {
        return DesignWidthKind.choiceGroup;
      }
      return null;
    }
    final words = _wordsOf(node);
    if (held.length == 2 &&
        held.every((c) => _wordsOf(c).isEmpty) &&
        words.isNotEmpty) {
      final a = _global(held[0]);
      final b = _global(held[1]);
      final between = words.every((w) {
        final x = _global(w).center.dx;
        return x > math.min(a.right, b.right) && x < math.max(a.left, b.left);
      });
      // Two buttons round a heading (a calendar's month, a pushed page's
      // title) are a header, not a stepper.
      if (between && !words.any((w) => _inHeader(finder, node, held, w))) {
        return DesignWidthKind.stepper;
      }
    }
    return null;
  }

  // Whether [control] stands a glyph over its words (a navigation bar's
  // destination).
  static bool _glyphOverWords(RenderBox control) {
    final shown = _shownIn(control).whereType<RenderParagraph>().toList();
    final glyphs = [
      for (final p in shown)
        if (isIconGlyph(lineText(p).trim())) _global(p),
    ];
    if (glyphs.isEmpty) return false;
    return shown.any((p) {
      if (isIconGlyph(lineText(p).trim())) return false;
      final w = _global(p);
      return glyphs.any(
        (g) => g.bottom <= w.top + 0.5 && g.left < w.right && g.right > w.left,
      );
    });
  }

  // How far past its content and padding each choice of a group or tab of
  // a tab bar may stand before the group is held: a minimum width, a
  // folder tab's flare.
  static const _itemRoom = 40.0;

  // A group of choices or a tab bar as measured: from its first item's
  // leading edge to its last's trailing edge as laid out and as drawn, and
  // the room its items take (each its content and padding and [_itemRoom],
  // and the gaps between them). Each choice by its own face (its content
  // that of the face or the control, the wider: a face painted behind what
  // it shows holds none of it), each tab by its box; null when a choice
  // shows no face of its own or a width can't be said.
  static ({Rect laid, Rect drawn, double content, double room, int count})?
  _itemsWidth(_RowReader reader, List<RenderBox> held, {required bool tabs}) {
    final items = <({Rect laid, Rect drawn, double content})>[];
    for (final c in held) {
      final RenderBox box;
      final Rect laid;
      var drawn = _global(c);
      if (tabs) {
        box = c;
        laid = drawn;
      } else {
        final face = reader._face(c);
        if (face == null) return null;
        box = face.box;
        laid = face.rect;
        drawn = reader.marked.contains(face.box)
            ? face.rect
            : reader._outline(
                    face.rect,
                    c,
                    face.read ? null : face.box,
                    null,
                  ) ??
                  face.rect;
      }
      // What it shows and its padding: its face's content, or the
      // control's where the face is painted behind it (a stack's face with
      // no child of its own).
      final widths = [
        _contentWidth(box, box.size.height),
        if (!identical(box, c)) _contentWidth(c, c.size.height),
      ].whereType<double>();
      if (widths.isEmpty) return null;
      items.add((laid: laid, drawn: drawn, content: widths.reduce(math.max)));
    }
    items.sort((a, b) => a.laid.left.compareTo(b.laid.left));
    var content = 0.0, gaps = 0.0;
    for (var i = 0; i < items.length; i++) {
      content += items[i].content;
      if (i > 0) {
        gaps += math.max(0, items[i].laid.left - items[i - 1].laid.right);
      }
    }
    return (
      laid: items.map((i) => i.laid).reduce((a, b) => a.expandToInclude(b)),
      drawn: items.map((i) => i.drawn).reduce((a, b) => a.expandToInclude(b)),
      content: content,
      room: content + items.length * _itemRoom + gaps,
      count: items.length,
    );
  }

  // Whether [words], between [held] under [node], are a heading or stand
  // in a header: marked `Semantics(header: true)` on them, or on a box round
  // the group that holds no other control.
  static bool _inHeader(
    _DrawnReader finder,
    RenderBox node,
    List<RenderBox> held,
    RenderBox words,
  ) {
    var above = false;
    for (RenderObject? up = words; up != null; up = up.parent) {
      if (above && finder._controlsUnder(up).length != held.length) break;
      if (up case RenderSemanticsAnnotations(:final properties)
          when properties.header == true) {
        return true;
      }
      if (identical(up, node)) above = true;
    }
    return false;
  }

  // Whether one box from [node] down, holding all of [held] and nothing
  // else, paints a face round them (a segmented control's ring or track):
  // no other control, and no words or icons but theirs (a chart's surface,
  // with its title over its bars, is not one).
  static bool _sharedFace(
    _DrawnReader finder,
    RenderBox node,
    List<RenderBox> held,
  ) {
    final all = held.map(_global).reduce((a, b) => a.expandToInclude(b));
    final rects = [for (final c in held) _global(c).inflate(0.5)];
    bool onlyTheirs(RenderBox face) => _shownIn(face).every((b) {
      final r = _global(b);
      return rects.any((c) => c.contains(r.center));
    });
    var found = false;
    void visit(RenderObject n) {
      if (found || _isControl(n)) return;
      if (n is RenderBox && n.hasSize && _paintsFace(n)) {
        final r = _global(n).inflate(0.5);
        if (r.contains(all.topLeft) &&
            r.contains(all.bottomRight) &&
            finder._controlsUnder(n).length == held.length &&
            onlyTheirs(n)) {
          found = true;
          return;
        }
      }
      _visitShown(n, visit);
    }

    for (RenderObject? up = node; up != null; up = up.parent) {
      if (up is! RenderBox || !up.hasSize || _isControl(up)) break;
      if (finder._controlsUnder(up).length != held.length) break;
      if (!onlyTheirs(up)) break;
      if (_paintsFace(up)) return true;
    }
    visit(node);
    return found;
  }

  // A group's face: from [node] down, while one box holds all of [held],
  // the innermost that shows a face, else the innermost that holds them. A
  // box that covers them but holds none (a layer of seams painted over the
  // whole group) is not theirs.
  static ({Rect rect, RenderBox box, bool read})? _groupFace(
    _RowReader reader,
    RenderBox node,
    List<RenderBox> held,
  ) {
    final all = held.map(_global).reduce((a, b) => a.expandToInclude(b));
    bool holds(RenderObject n) =>
        n is RenderBox &&
        n.hasSize &&
        _global(n).inflate(0.5).contains(all.topLeft) &&
        _global(n).inflate(0.5).contains(all.bottomRight) &&
        reader._controlsUnder(n).length == held.length;
    RenderBox tightest = node;
    RenderBox? face = reader._showsFace(node) ? node : null;
    for (;;) {
      final inside = <RenderObject>[];
      _visitShown(tightest, (c) {
        if (holds(c)) inside.add(c);
      });
      if (inside.length != 1 || _isControl(inside.single)) break;
      tightest = inside.single as RenderBox;
      if (reader._showsFace(tightest)) face = tightest;
    }
    // A face drawn round the group from above it (a ring, a track), that
    // holds nothing else.
    if (face == null) {
      for (RenderObject? up = tightest.parent; up != null; up = up.parent) {
        if (up is! RenderBox || !up.hasSize || _isControl(up)) break;
        if (reader._controlsUnder(up).length != held.length) break;
        if (reader._showsFace(up)) {
          face = up;
          break;
        }
      }
    }
    final f = face ?? tightest;
    return (rect: _global(f), box: f, read: false);
  }

  // The words [node] shows (paragraphs that are not icons, editables).
  static List<RenderBox> _wordsOf(RenderObject node) => [
    for (final p in _shownIn(node))
      if (p is RenderEditable ||
          (p is RenderParagraph &&
              !isIconGlyph(p.text.toPlainText(includeSemanticsLabels: false))))
        p,
  ];

  // Where [control]'s words start, global x of their leading edge: the
  // leading end of its line's first row, or an empty entry's caret. Not
  // its first character's: words in the other direction (Latin words in a
  // right-to-left layout) start theirs at the row's far end.
  static double? _wordsStart(RenderBox control, bool rtl) {
    final line = labelLine(control);
    if (line == null) return null;
    final boxes = lineBoxes(
      line,
      TextSelection(
        baseOffset: 0,
        extentOffset: math.max(1, lineText(line).length),
      ),
    );
    double x;
    if (boxes.isNotEmpty) {
      final first = boxes.first;
      final row = [
        for (final b in boxes)
          if (b.top < first.bottom && b.bottom > first.top) b,
      ];
      x = rtl
          ? row.map((b) => b.right).reduce(math.max)
          : row.map((b) => b.left).reduce(math.min);
      // An entry keeps its caret's margin (a 1 px gap and the caret's width)
      // clear at its right edge, which is where a right-to-left entry's words
      // start: measured from the text's own box, as no look sets it.
      if (rtl && line is RenderEditable) x += 1 + line.cursorWidth;
    } else if (line is RenderEditable) {
      x = line.getLocalRectForCaret(const TextPosition(offset: 0)).left;
    } else {
      return null;
    }
    return MatrixUtils.transformPoint(
      line.getTransformTo(null),
      Offset(x, 0),
    ).dx;
  }

  // The list open from the field [box] (laid out at [field]): the outermost
  // face, outside the field, that holds two or more controls one over
  // another (by what they show) and starts within 32 px above or below it;
  // of several, the nearest. A face is a box that paints one or that a look
  // marked, else one whose own pixels stand off what is around it
  // ([standsOff]: a surface a look paints with a render box of its own). A
  // popup (a layer drawn over the field's page) is a list whatever it
  // holds.
  static Future<RenderBox?> _listFrom(
    RenderObject root,
    RenderBox box,
    Rect field,
    _DrawnReader finder,
    Future<bool> Function(RenderBox) standsOff,
  ) async {
    // The layer [n] is drawn in: the box an overlay holds it in (a route's
    // page, a menu's route, an overlay portal's child); null outside one.
    RenderObject? layerOf(RenderObject n) {
      for (RenderObject? up = n; up != null; up = up.parent) {
        if (up.parent?.runtimeType.toString() == '_RenderTheater') return up;
      }
      return null;
    }

    bool inside(RenderObject n, RenderObject outer) {
      for (var up = n.parent; up != null; up = up.parent) {
        if (identical(up, outer)) return true;
      }
      return false;
    }

    final fieldLayer = layerOf(box);
    var pastField = false;
    // Whether [n] is a popup: drawn straight into the overlay, with no
    // repaint boundary above it (nothing on a route's page is); or in a
    // layer drawn after, over, the field's page. A layer that holds the
    // field's page (a navigation frame's own route, its side bar drawn after
    // its navigator) is not over it: what stands in it is the page's chrome.
    bool overlaid(RenderObject n) {
      var bare = true;
      for (RenderObject? up = n; up != null && bare; up = up.parent) {
        if (up is RenderRepaintBoundary) bare = false;
      }
      if (bare) return true;
      if (!pastField || fieldLayer == null) return false;
      final layer = layerOf(n);
      return layer != null &&
          !identical(layer, fieldLayer) &&
          !inside(box, layer);
    }

    // In paint order, so a box comes before the boxes inside it; each with
    // whether it is a popup, as the visit found it (a later layer only once
    // the field has been passed).
    final held = <RenderBox>[];
    final popup = <RenderBox, bool>{};
    void visit(RenderObject n) {
      if (identical(n, box)) {
        pastField = true;
        return;
      }
      if (n is RenderBox && n.hasSize && !_isControl(n)) {
        final r = _global(n);
        // Up to 32 from the field, or over its edge by a rule's width (a
        // list that shares the field's rule, laid out with a negative gap),
        // and across from it: a button beside the field's column (a
        // dialog's) is no list of the field's.
        final near =
            r.left < field.right - 1 &&
            r.right > field.left + 1 &&
            ((r.top >= field.bottom - _sharedRule &&
                    r.top - field.bottom <= 32) ||
                (r.bottom <= field.top + _sharedRule &&
                    field.top - r.bottom <= 32));
        if (near && overlaid(n)) {
          held.add(n);
          popup[n] = true;
        } else if (near) {
          // One over another by what they show, not by touch targets that
          // overhang it.
          final items = [
            for (final c in finder._controlsUnder(n)) finder._shownBy(c),
          ]..sort((a, b) => a.top.compareTo(b.top));
          var stacked = items.length >= 2;
          for (var i = 1; i < items.length && stacked; i++) {
            stacked = items[i].top >= items[i - 1].bottom - 1;
          }
          if (stacked) {
            held.add(n);
            popup[n] = false;
          }
        }
      }
      _visitShown(n, visit);
    }

    visit(root);
    final found = <RenderBox>[];
    // A face that paints one or that a look marked first; then a box whose
    // pixels stand off, round no face found (a wrapper laying a list out
    // over the page stands off by the list in it).
    for (final n in held) {
      if (popup[n]! || found.any((f) => inside(n, f))) continue;
      if (_paintsFace(n) || finder.marked.contains(n)) found.add(n);
    }
    for (final n in held) {
      if (popup[n]! ||
          found.any((f) => inside(n, f) || inside(f, n) || identical(f, n))) {
        continue;
      }
      if (await standsOff(n)) found.add(n);
    }
    // A popup, whatever it holds (a "no matches" note is one too): its
    // outermost box near the field. Its face is the outermost box in it
    // that paints one and holds every control it does (not an item's
    // highlight), however much room the popup's layout gives it (an
    // autocomplete's options box is as tall as the screen below the field);
    // one holding none (a note) covers a quarter of the popup at least.
    // Else that outermost box (a look's own painter, with no pixels above
    // it to read).
    final popups = <RenderBox>[];
    for (final n in held) {
      if (!popup[n]! || popups.any((o) => inside(n, o))) continue;
      popups.add(n);
    }
    for (final o in popups) {
      final all = finder._controlsUnder(o).length;
      final least = all > 0 ? 0.0 : o.size.width * o.size.height / 4;
      RenderBox? face;
      void faceIn(RenderObject n) {
        if (face != null || _isControl(n)) return;
        if (n is RenderBox &&
            n.hasSize &&
            n.size.width * n.size.height >= least &&
            (_paintsFace(n) || finder.marked.contains(n)) &&
            finder._controlsUnder(n).length == all) {
          face = n;
          return;
        }
        _visitShown(n, faceIn);
      }

      faceIn(o);
      found.add(face ?? o);
    }
    if (found.isEmpty) return null;
    double gap(RenderBox n) {
      final r = _global(n);
      return math.min(
        (r.top - field.bottom).abs(),
        (field.top - r.bottom).abs(),
      );
    }

    return found.reduce((a, b) => gap(b) < gap(a) ? b : a);
  }

  // [control] named as [kind]: 'a select "Category"'; the boxes in [skip]
  // left out of the name.
  static String _kindName(
    DesignWidthKind kind,
    RenderBox control, {
    Set<RenderBox> skip = const {},
  }) {
    final name = _nameOf(control, skip: skip);
    final quote = name.indexOf('"');
    return quote < 0 ? kind.label : '${kind.label} ${name.substring(quote)}';
  }

  // Whether [control] is, or is the one control in, an anchor of a list.
  static bool _anchored(RenderBox control, Set<RenderBox> anchors) {
    for (RenderObject? up = control; up != null; up = up.parent) {
      if (up is RenderBox && anchors.contains(up)) return true;
      if (up is RenderRepaintBoundary) break;
    }
    return false;
  }
}

// The boxes under [context] that anchor a list: a RawPopover's
// anchor, a Material dropdown's or menu's.
Set<RenderBox> _anchorBoxes(BuildContext context) {
  const material = [
    'DropdownButton',
    'DropdownMenu',
    'PopupMenuButton',
    'MenuAnchor',
  ];
  final found = <RenderBox>{};
  void visit(Element element) {
    final w = element.widget;
    final name = w.runtimeType.toString();
    if (w is RawPopover ||
        material.any((m) => name == m || name.startsWith('$m<'))) {
      final box = element.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize) found.add(box);
    }
    element.visitChildElements(visit);
  }

  if (context is Element) visit(context);
  return found;
}

// How far a list opened from a field may lie over the field's edge and
// still be the list: the width of a rule they share.
const double _sharedRule = 6;
