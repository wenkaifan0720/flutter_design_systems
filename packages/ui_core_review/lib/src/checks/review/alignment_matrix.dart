part of '../../review.dart';

/// A kind of control that shares a line with others.
enum DesignInlineControl {
  /// A button with a text label.
  button('Button'),

  /// A button that shows only an icon.
  iconButton('Icon button'),

  /// A text field, empty, showing its hint.
  textField('Text field'),

  /// A select (a dropdown button) showing its value.
  select('Select'),

  /// A search field, empty, showing its hint.
  searchField('Search field'),

  /// A segmented button or a toggle group.
  segmentedButton('Segmented button'),

  /// A stepper or a number field.
  numberField('Number field'),

  /// A chip.
  chip('Chip'),

  /// A checkbox with its label.
  labeledCheckbox('Checkbox with label'),

  /// A switch with its label.
  labeledSwitch('Switch with label'),

  /// One line of a list: its leading, title and trailing.
  listTile('List tile');

  const DesignInlineControl(this.label);

  /// What a person calls it.
  final String label;
}

/// Builds a look's control showing [label]: a button's text, a field's
/// hint, a select's value, a chip's or a list tile's title. It is given at
/// most 240 logical pixels of width, and a field takes what it is given.
typedef DesignAlignmentBuilder = Widget Function(
  BuildContext context,
  String label,
);

/// One control of a [DesignAlignmentRow]: its kind and how the look builds
/// it.
@immutable
class DesignAlignmentEntry {
  /// A [kind] of control, built by [builder].
  const DesignAlignmentEntry(this.kind, this.builder, {this.inkUnmeasured});

  /// Which kind of control it is.
  final DesignInlineControl kind;

  /// Builds the control showing the label it is given.
  final DesignAlignmentBuilder builder;

  /// Why its labels' ink cannot be measured from its pixels (a textured or
  /// gradient face, say); null: it is measured. Its box and baseline are
  /// checked either way.
  final String? inkUnmeasured;
}

/// The controls of one size that may share a line: each the same height,
/// on the same centre, with its label's capitals on that centre.
@immutable
class DesignAlignmentRow {
  /// A row of [entries] at [size].
  const DesignAlignmentRow({
    required this.size,
    required this.entries,
    this.heightExceptions = const {},
  });

  /// The size's name in the look ("small", "medium").
  final String size;

  /// The row's controls, in order.
  final List<DesignAlignmentEntry> entries;

  /// The kinds whose height differs from the row's on purpose, each with the
  /// reason (Material's 56 field beside its 40 button). Their centre and
  /// capitals are still checked.
  final Map<DesignInlineControl, String> heightExceptions;
}

/// A look's controls that share a line, row by row, and the themes they
/// are checked under. Every kind of [DesignInlineControl] is in a row or in
/// [absent] with the reason.
///
/// It reads layout boxes, and the drawn pixels where only they show it (a
/// label's and an icon's ink), so it takes the tester's `runAsync`.
@immutable
class DesignAlignmentMatrix {
  /// The matrix of [look].
  const DesignAlignmentMatrix({
    required this.look,
    required this.themes,
    required this.rows,
    this.absent = const {},
    this.label = 'TEXT',
    this.tolerance = 0.5,
    this.inkTolerance = 0.75,
    this.drawnTolerance = 0.5,
    this.pixelRatio = 3,
  });

  /// The look's name, for messages.
  final String look;

  /// The look's theme as an app's page gets it, under each density the look
  /// offers, by name ("standard", "compact"). A theme must not pin the
  /// platform: the check runs it as each platform in turn.
  final Map<String, DesignAlignmentTheme> themes;

  /// One row per size.
  final List<DesignAlignmentRow> rows;

  /// The kinds the look has no control for, each with the reason.
  final Map<DesignInlineControl, String> absent;

  /// What each control shows: capitals without descenders, so its ink runs
  /// from the baseline to the cap height.
  final String label;

  /// How far apart, in logical pixels, two heights or centres in a row, two
  /// baselines of labels of one size and style, or a control's size and
  /// place on two platforms, may be.
  final double tolerance;

  /// How far, in device pixels at [pixelRatio], a label's or a text
  /// entry's capitals may be drawn from the row's centre line.
  ///
  /// What the eye compares in a row is the capitals: a 13 px button label
  /// and a 14 px field's text sit on one line when their capitals' middles
  /// do, whatever their baselines. They are read as [DesignLabelCheck]
  /// reads them: their baseline where the engine draws it, their height the
  /// `capHeightFactor` of the [RawCapCenter] around them, else read from
  /// their flat-topped capitals' pixels. A look whose labels and entries are
  /// each wrapped in a [RawCapCenter] holds them within half a device
  /// pixel.
  final double drawnTolerance;

  /// How far, in logical pixels, an icon's ink may sit from the middle of
  /// its control, as the look laid it out (a label is held by its capitals:
  /// [drawnTolerance]).
  ///
  /// The engine draws each line of text with its baseline on a whole
  /// logical pixel from the line's top: a baseline laid out 17.47 below a
  /// label's top is drawn at 17, and one at 14.5 at 15. That moves the ink
  /// up to half a pixel from where the look put it, by an amount that
  /// changes with the font, its size and the text scale, and no layout can
  /// take it out. The check reads it from the baseline each text reports
  /// and holds only the rest to this, and a message prints it beside the
  /// offset. Where it cannot read it (a paragraph that holds widgets inline,
  /// a text of more than one line) it holds the whole drawn offset to this.
  final double inkTolerance;

  /// The scale the controls are drawn at to find their ink.
  final double pixelRatio;

  /// What is wrong with the matrix itself, one line each: a kind neither in
  /// a row nor absent, or both; a reason that is a to-do; a kind twice in
  /// one row; a row with no controls; no theme.
  List<String> get problems {
    final found = <String>[];
    if (themes.isEmpty) found.add('no theme to check under');
    final shown = <DesignInlineControl>{};
    for (final row in rows) {
      if (row.entries.isEmpty) found.add('${row.size}: no controls');
      final seen = <DesignInlineControl>{};
      for (final entry in row.entries) {
        if (!seen.add(entry.kind)) {
          found.add('${row.size}: ${entry.kind.label} more than once');
        }
        final reason = entry.inkUnmeasured;
        if (reason != null && isToDoReason(reason)) {
          found.add(
            '${row.size} · ${entry.kind.label}: "$reason" is a to-do, not '
            'a reason its ink cannot be measured',
          );
        }
      }
      shown.addAll(seen);
      row.heightExceptions.forEach((kind, reason) {
        if (!seen.contains(kind)) {
          found.add(
            '${row.size}: a height exception for ${kind.label}, which is '
            'not in the row',
          );
        } else if (isToDoReason(reason)) {
          found.add(
            '${row.size} · ${kind.label}: "$reason" is a to-do, not a '
            'reason for its height',
          );
        }
      });
    }
    for (final kind in DesignInlineControl.values) {
      final reason = absent[kind];
      if (reason == null && !shown.contains(kind)) {
        found.add('${kind.label}: in no row and not absent');
      } else if (reason != null && shown.contains(kind)) {
        found.add('${kind.label}: both in a row and absent');
      } else if (reason != null && isToDoReason(reason)) {
        found.add('${kind.label}: "$reason" is a to-do, not a reason');
      }
    }
    return found;
  }

  /// Puts the matrix on screen under each of [themes] as each of
  /// [platforms], and reports every way its controls fail to line up: in a
  /// row, a height or centre more than [tolerance] from the row's, or a
  /// baseline from that of the row's other labels of its size and style; a
  /// label's or a text entry's capitals more than [drawnTolerance] from the
  /// row's centre line as drawn (as laid out beside it); in a control, an
  /// icon's ink more than [inkTolerance] from its middle, the engine's
  /// whole-pixel baseline aside; between the first platform and each
  /// other, a control's size or place in its row more than [tolerance]
  /// apart. [problems] come first.
  ///
  /// The ink is read from drawn pixels, so a test loads the look's fonts
  /// first (with a `FontLoader`): in the test font every glyph is a solid
  /// box. It passes its tester's `pumpWidget` as [pump] and `runAsync` as
  /// [runAsync] (reading pixels takes real time):
  ///
  /// ```dart
  /// final report = await matrix.check(
  ///   pump: tester.pumpWidget,
  ///   runAsync: tester.runAsync,
  /// );
  /// report.verify();
  /// ```
  ///
  /// It sets [debugDefaultTargetPlatformOverride] for each platform and puts
  /// back the value it found.
  Future<DesignAlignmentReport> check({
    required Future<void> Function(Widget widget) pump,
    required Future<T?> Function<T>(Future<T> Function() work) runAsync,
    List<TargetPlatform> platforms = _platforms,
  }) async {
    final found = [...problems];
    var byPlatform = false;
    final before = debugDefaultTargetPlatformOverride;
    try {
      for (final MapEntry(key: name, value: theme) in themes.entries) {
        List<List<_Measured>>? first;
        for (final platform in platforms) {
          debugDefaultTargetPlatformOverride = platform;
          final keys = [
            for (final row in rows) [for (final _ in row.entries) GlobalKey()],
          ];
          await pump(
            KeyedSubtree(
              key: ValueKey((name, platform)),
              child: _Page(
                theme: theme,
                child: _Rows(matrix: this, keys: keys),
              ),
            ),
          );
          final where = '$name · ${platform.name}';
          final measured = <List<_Measured>>[];
          for (var r = 0; r < rows.length; r++) {
            final row = rows[r];
            final controls = <_Measured>[];
            for (var e = 0; e < row.entries.length; e++) {
              final probe =
                  keys[r][e].currentContext!.findRenderObject()!
                      as _RenderProbe;
              final entry = row.entries[e];
              controls.add(
                await _measure(
                  probe,
                  entry.inkUnmeasured == null ? runAsync : null,
                ),
              );
            }
            found.addAll(_rowProblems(row, controls, where));
            measured.add(controls);
          }
          if (first == null) {
            first = measured;
          } else {
            final differ = _platformProblems(
              first,
              measured,
              name,
              platforms.first,
              platform,
            );
            byPlatform |= differ.isNotEmpty;
            found.addAll(differ);
          }
        }
      }
    } finally {
      debugDefaultTargetPlatformOverride = before;
    }
    if (byPlatform) found.add(_byPlatform);
    return DesignAlignmentReport(look, found);
  }

  Future<_Measured> _measure(
    _RenderProbe probe,
    Future<T?> Function<T>(Future<T> Function() work)? runAsync,
  ) async {
    final origin = probe.localToGlobal(Offset.zero);
    final box = origin & probe.size;
    final row = probe.row;
    final inRow = origin - row.localToGlobal(Offset.zero);
    final texts = <_Text>[];
    DrawnPixels? pixels;
    if (runAsync != null) {
      pixels = await runAsync(() => DrawnPixels.of(probe, pixelRatio));
    }
    ({double drawn, double? laid})? capitals;
    String? style;
    for (final text in _textsUnder(probe)) {
      double y(double local) => text.box.localToGlobal(Offset(0, local)).dy;
      final baseline = text.baseline;
      // The engine draws the line this much lower than it is laid out (see
      // [inkTolerance]), so its ink is looked for there.
      final rounding = baseline == null || !text.oneLine
          ? 0.0
          : y((baseline + 0.5).floorToDouble()) - y(baseline);
      final rect = (text.box.localToGlobal(Offset.zero) & text.box.size).shift(
        Offset(0, rounding),
      );
      final ink = pixels?.inkRows(rect.shift(-origin));
      // Text a control does not show (a hint's other state, a faded label)
      // has no ink and counts for nothing.
      if (pixels != null && ink == null) continue;
      // The first label's (or typed text's) capitals and style.
      if (!text.icon && style == null) {
        style = _styleKey(text.box);
        capitals = _capitalsOf(probe, text.box, pixels);
      }
      texts.add(
        _Text(
          icon: text.icon,
          baseline: baseline == null ? null : y(baseline),
          ink: ink?.shift(origin.dy),
          rounding: rounding,
        ),
      );
    }
    return _Measured(
      box: box,
      inRow: inRow,
      texts: texts,
      capitals: capitals,
      style: style,
    );
  }

  // The capitals' middle of [line] in [probe] (global), as drawn and as laid
  // out; null without pixels or capitals to read.
  static ({double drawn, double? laid})? _capitalsOf(
    _RenderProbe probe,
    RenderBox line,
    DrawnPixels? pixels,
  ) {
    if (pixels == null) return null;
    final reader = _DrawnReader(probe, pixels, const {});
    final local = reader._toBoundary(_global(line));
    final c = reader._capitals(line, pixels.groundAround(local, 2));
    if (c == null) return null;
    double y(double image) =>
        probe.localToGlobal(Offset(0, image / pixels.ratio)).dy;
    final laid = c.laid;
    return (drawn: y(c.drawn), laid: laid == null ? null : y(laid));
  }

  // A label's size and style: labels that share them share a baseline.
  static String _styleKey(RenderBox line) {
    final s = lineStyle(line);
    return '${s?.fontFamily}|${s?.fontWeight}|${s?.fontStyle}|'
        '${labelFontSize(line).toStringAsFixed(2)}';
  }

  List<String> _rowProblems(
    DesignAlignmentRow row,
    List<_Measured> controls,
    String where,
  ) {
    final found = <String>[];
    String at(int i) => '${row.size} · $where · ${row.entries[i].kind.label}';
    final sized = [
      for (var i = 0; i < controls.length; i++)
        if (!row.heightExceptions.containsKey(row.entries[i].kind)) i,
    ];
    final height = _common([for (final i in sized) controls[i].box.height]);
    if (height != null) {
      for (final i in sized) {
        final h = controls[i].box.height;
        if ((h - height).abs() > tolerance) {
          found.add('${at(i)}: ${_px(h)} high, the row ${_px(height)}');
        }
      }
    }
    final centre = _common([for (final c in controls) c.box.center.dy]);
    for (var i = 0; i < controls.length; i++) {
      final c = controls[i].box.center.dy;
      if (centre != null && (c - centre).abs() > tolerance) {
        found.add(
          "${at(i)}: its centre is ${_px(c - centre, signed: true)} the row's",
        );
      }
    }
    // One baseline only among labels of one size and style.
    final byStyle = <String, Map<int, double>>{};
    for (var i = 0; i < controls.length; i++) {
      final b = controls[i].baseline;
      final k = controls[i].style;
      if (b != null && k != null) (byStyle[k] ??= {})[i] = b;
    }
    for (final group in byStyle.values) {
      if (group.length < 2) continue;
      final baseline = _common(group.values);
      group.forEach((i, b) {
        if (baseline != null && (b - baseline).abs() > tolerance) {
          found.add(
            "${at(i)}: its label's baseline is "
            "${_px(b - baseline, signed: true)} that of the row's other "
            'labels of its size and style',
          );
        }
      });
    }
    // Every label's and entry's capitals on the row's centre line.
    for (var i = 0; i < controls.length; i++) {
      final caps = controls[i].capitals;
      if (caps == null || centre == null) continue;
      final drawn = (caps.drawn - centre) * pixelRatio;
      if (drawn.abs() <= drawnTolerance) continue;
      final laid = caps.laid;
      final asLaid = laid == null
          ? ''
          : '${_onOrOff(laid - centre).replaceFirst('on it', 'on')} the '
                "row's centre line as laid out, ";
      found.add(
        "${at(i)}: its label's capitals are $asLaid"
        '${_RowReader._device(drawn)} as drawn',
      );
    }
    for (var i = 0; i < controls.length; i++) {
      final middle = controls[i].box.center.dy;
      for (final text in controls[i].texts) {
        final ink = text.ink;
        if (ink == null) continue;
        // A label read by its capitals is held above.
        if (!text.icon && controls[i].capitals != null) continue;
        final drawn = (ink.top + ink.bottom) / 2 - middle;
        // Where the look put it: the engine's whole-pixel baseline is not
        // the look's to move.
        final off = drawn - text.rounding;
        if (off.abs() > inkTolerance) {
          final what = text.icon ? 'icon' : 'label';
          found.add(
            "${at(i)}: the $what's ink ${_px(off, signed: true)} its middle"
            '${_roundingNote(text.rounding, drawn)}',
          );
        }
      }
    }
    return found;
  }

  List<String> _platformProblems(
    List<List<_Measured>> a,
    List<List<_Measured>> b,
    String theme,
    TargetPlatform pa,
    TargetPlatform pb,
  ) {
    final found = <String>[];
    for (var r = 0; r < rows.length; r++) {
      for (var e = 0; e < rows[r].entries.length; e++) {
        final x = a[r][e];
        final y = b[r][e];
        final at =
            '${rows[r].size} · $theme · ${rows[r].entries[e].kind.label}';
        final dw = (x.box.width - y.box.width).abs();
        final dh = (x.box.height - y.box.height).abs();
        if (dw > tolerance || dh > tolerance) {
          found.add(
            '$at: ${_px(x.box.width)} × ${_px(x.box.height)} as ${pa.name}, '
            '${_px(y.box.width)} × ${_px(y.box.height)} as ${pb.name}',
          );
        } else if ((x.inRow - y.inRow).distance > tolerance) {
          found.add(
            '$at: at (${_px(x.inRow.dx)}, ${_px(x.inRow.dy)}) in its row as '
            '${pa.name}, (${_px(y.inRow.dx)}, ${_px(y.inRow.dy)}) as '
            '${pb.name}',
          );
        }
        final xb = x.baseline;
        final yb = y.baseline;
        if (xb != null && yb != null) {
          final d = (yb - y.box.top) - (xb - x.box.top);
          if (d.abs() > tolerance) {
            found.add(
              '$at: its label sits ${_px(d.abs())} px '
              '${d > 0 ? 'lower' : 'higher'} in it as ${pb.name} than as '
              '${pa.name}',
            );
          }
        }
      }
    }
    return found;
  }

  // The value most of [values] share (to the nearest quarter pixel), the
  // first of them on a tie; null when there are none.
  static double? _common(Iterable<double> values) {
    final counts = <int, (int, double)>{};
    for (final v in values) {
      final k = (v * 4).round();
      final (n, first) = counts[k] ?? (0, v);
      counts[k] = (n + 1, first);
    }
    double? best;
    var most = 0;
    for (final (n, v) in counts.values) {
      if (n > most) {
        most = n;
        best = v;
      }
    }
    return best;
  }
}

/// The platforms a check runs as unless told otherwise: Android (what a
/// test runs as), iOS, and macOS (a desktop: what Material makes compact).
const List<TargetPlatform> _platforms = [
  TargetPlatform.android,
  TargetPlatform.iOS,
  TargetPlatform.macOS,
];

/// The last line of a report that found sizes changing with the platform.
const String _byPlatform =
    'Sizes that change with the platform: Material\'s '
    'ThemeData.visualDensity and materialTapTargetSize both default by '
    'platform (compact and shrink-wrapped on macOS, Windows and Linux); pin '
    'both under the look.';

/// Builds one of a look's text entries around [controller], showing [hint]
/// while it is empty.
typedef DesignTextEntryBuilder = Widget Function(
  BuildContext context,
  TextEditingController controller,
  String hint,
);

/// A look's text entries (a field, a search, a composer, a number, a select
/// you type in), checked for the one structure that keeps a line of text
/// where it belongs whatever the platform, density, text size or host theme:
/// the look's own box, the typed text's capitals on its middle, the hint on
/// the typed text's baseline, and nothing else in the editable's decoration.
///
/// What the eye compares in a row is the capitals, so the line is read by
/// them, not by its line box: their baseline where the engine draws it (on
/// a whole logical pixel below the line's top), their height the
/// [RawCapCenter]'s around the field, else the usual 0.7 of its font
/// size. A field wrapped in a [RawCapCenter] holds its capitals on its
/// middle whatever its typeface; one centred by its line box sits off by
/// the typeface's ascent and descent.
///
/// The editable is a `TextField` whose decoration is null, or collapsed with
/// every field that sizes it set (`contentPadding`, `constraints`, `isDense`,
/// `visualDensity`) so that no theme fills one in. Validation is the look's
/// own `FormField` around it: a `TextFormField` builds a decoration from the
/// theme even when given none.
///
/// Each entry is built twice, empty (its hint showing) and with [text]
/// typed, at most 480 logical pixels wide, under each of [themes] as each
/// platform. Among [themes], one whose `InputDecorationTheme` sets uneven
/// `contentPadding` and a minimum height in `constraints` finds a
/// decoration that leaves either to the theme.
///
/// It reads layout boxes and each entry's laid-out line, and no pixels.
@immutable
class DesignTextEntryCheck {
  /// The text entries of [look].
  const DesignTextEntryCheck({
    required this.look,
    required this.themes,
    required this.entries,
    this.text = 'TEXT',
    this.hint = 'HINT',
    this.tolerance = 0.5,
  });

  /// The look's name, for messages.
  final String look;

  /// The look's theme as an app's page gets it, under each density, text
  /// size or host theme to check, by name. A theme must not pin the
  /// platform: the check runs it as each platform in turn.
  final Map<String, DesignAlignmentTheme> themes;

  /// The look's text entries, by name.
  final Map<String, DesignTextEntryBuilder> entries;

  /// What is typed: capitals without descenders.
  final String text;

  /// What each entry is given to show while empty.
  final String hint;

  /// How far, in logical pixels, the typed text's capitals may sit from the
  /// middle of its box as drawn, the hint from the typed text's baseline, or
  /// an entry's size and line from where they are on the first platform.
  ///
  /// Each is read from layout (the editable's box, the baselines each text
  /// reports, the engine's whole-pixel baseline worked out from them), not
  /// from ink.
  final double tolerance;

  /// Puts every entry on screen under each of [themes] as each of
  /// [platforms], and reports each way it breaks the structure: its
  /// capitals more than [tolerance] from the middle of its box (as drawn,
  /// and as laid out beside it); its hint off the
  /// typed text's baseline; its editable's decoration carrying anything
  /// but the hint (an icon, a counter, help or error, which are the look's
  /// own widgets); its size or line moving between platforms; or a
  /// `TextFormField` in it (named once per entry).
  ///
  /// A test passes its tester's `pumpWidget` as [pump]. It sets
  /// [debugDefaultTargetPlatformOverride] for each platform, puts back the
  /// value it found, and leaves an empty tree.
  Future<DesignAlignmentReport> check({
    required Future<void> Function(Widget widget) pump,
    List<TargetPlatform> platforms = _platforms,
  }) async {
    final found = <String>[
      if (themes.isEmpty) 'no theme to check under',
      if (entries.isEmpty) 'no text entries',
    ];
    var byPlatform = false;
    final named = <String>{};
    final controllers = <TextEditingController>[];
    final before = debugDefaultTargetPlatformOverride;
    try {
      for (final MapEntry(key: theme, value: wrap) in themes.entries) {
        Map<String, _Entry>? first;
        for (final platform in platforms) {
          debugDefaultTargetPlatformOverride = platform;
          final keys = {
            for (final name in entries.keys) name: (GlobalKey(), GlobalKey()),
          };
          Widget built(String name, GlobalKey key, String typed) {
            final controller = TextEditingController(text: typed);
            controllers.add(controller);
            return _Probe(
              key: key,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Builder(
                  builder: (context) =>
                      entries[name]!(context, controller, hint),
                ),
              ),
            );
          }

          await pump(
            KeyedSubtree(
              key: ValueKey((theme, platform)),
              child: _Page(
                theme: wrap,
                child: UnconstrainedBox(
                  alignment: AlignmentDirectional.topStart,
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final MapEntry(key: name, value: (empty, typed))
                          in keys.entries)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              built(name, empty, ''),
                              const SizedBox(width: 8),
                              built(name, typed, text),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          final measured = <String, _Entry>{};
          for (final MapEntry(key: name, value: (empty, typed))
              in keys.entries) {
            final at = '$name · $theme · ${platform.name}';
            if (!named.contains(name)) {
              final widget = _decoratingIn(empty.currentContext!);
              if (widget != null) {
                named.add(name);
                found.add('$name: it is $widget');
              }
            }
            final entry = _Entry.of(
              empty.currentContext!.findRenderObject()! as _RenderProbe,
              typed.currentContext!.findRenderObject()! as _RenderProbe,
              hint: hint,
              text: text,
              decorations: _decorationsIn(empty.currentContext!),
            );
            measured[name] = entry;
            found.addAll(entry.problems(at, tolerance));
          }
          if (first == null) {
            first = measured;
          } else {
            for (final name in entries.keys) {
              final a = first[name]!;
              final b = measured[name]!;
              final at = '$name · $theme';
              final pa = platforms.first.name;
              final pb = platform.name;
              if ((a.size.width - b.size.width).abs() > tolerance ||
                  (a.size.height - b.size.height).abs() > tolerance) {
                byPlatform = true;
                found.add(
                  '$at: ${_px(a.size.width)} × ${_px(a.size.height)} as $pa, '
                  '${_px(b.size.width)} × ${_px(b.size.height)} as $pb',
                );
              }
              final la = a.baseline;
              final lb = b.baseline;
              if (la != null && lb != null && (la - lb).abs() > tolerance) {
                byPlatform = true;
                found.add(
                  '$at: its text sits ${_px((lb - la).abs())} px '
                  '${lb > la ? 'lower' : 'higher'} in its box as $pb than '
                  'as $pa',
                );
              }
            }
          }
        }
      }
    } finally {
      debugDefaultTargetPlatformOverride = before;
      await pump(const SizedBox());
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    if (byPlatform) found.add(_byPlatform);
    return DesignAlignmentReport(look, found);
  }
}

// The widgets that put a decoration on an editable whatever they are given,
// by type name (ui_core imports no Material), each with what to say of it.
const Map<String, String> _decorating = {
  'TextFormField':
      'a TextFormField, which builds a decoration from the theme even given '
      'none and writes a failed validation\'s error into it; validate in the '
      'look\'s own FormField around a TextField whose decoration is null',
};

// What [_decorating] says of the first such widget under [context], if any.
String? _decoratingIn(BuildContext context) {
  String? said;
  void visit(Element element) {
    said ??= _decorating[element.widget.runtimeType.toString()];
    if (said == null) element.visitChildElements(visit);
  }

  context.visitChildElements(visit);
  return said;
}

// The boxes that Material's InputDecorator, which draws every
// InputDecoration, lays out under [context], by its type name.
Set<RenderObject> _decorationsIn(BuildContext context) {
  final found = <RenderObject>{};
  void visit(Element element) {
    if (element.widget.runtimeType.toString() == 'InputDecorator') {
      final box = element.findRenderObject();
      if (box != null) found.add(box);
    }
    element.visitChildElements(visit);
  }

  context.visitChildElements(visit);
  return found;
}

// One text entry's measure: built empty and built typed.
class _Entry {
  _Entry({
    required this.size,
    required this.baseline,
    required this.line,
    required this.laidLine,
    required this.hintBaseline,
    required this.uneven,
    required this.extras,
    required this.editable,
  });

  // [empty] and [typed] are the same entry, without and with text.
  factory _Entry.of(
    _RenderProbe empty,
    _RenderProbe typed, {
    required String hint,
    required String text,
    required Set<RenderObject> decorations,
  }) {
    double top(_RenderProbe probe) => probe.localToGlobal(Offset.zero).dy;
    RenderEditable? editableIn(RenderObject root) {
      RenderEditable? found;
      void visit(RenderObject node) {
        if (found != null) return;
        if (node is RenderEditable) {
          found = node;
          return;
        }
        _visitShown(node, visit);
      }

      visit(root);
      return found;
    }

    final typedEditable = editableIn(typed);
    double? baseline;
    double? line;
    double? laidLine;
    if (typedEditable != null) {
      final b = _TextBox(typedEditable, icon: false).baseline;
      // Its capitals: the cap height its RawCapCenter gives, else the
      // usual one; their baseline as laid out, and where the engine draws
      // it (on a whole logical pixel below the line's top).
      final factor =
          _capCentredIn(typedEditable, typed)?.capHeightFactor ??
          typicalCapHeightFactor;
      final caps = drawnCaps(typedEditable, factor);
      double fromMiddle(double y) =>
          typedEditable.localToGlobal(Offset(0, y)).dy -
          top(typed) -
          typed.size.height / 2;
      if (b != null && caps != null) {
        baseline = typedEditable.localToGlobal(Offset(0, b)).dy - top(typed);
        final half = (caps.baseline - caps.top) / 2;
        line = fromMiddle(caps.baseline - half);
        laidLine = fromMiddle(b - half);
      }
    }
    final texts = _textsUnder(empty);
    final hintBox = texts
        .where((t) => !t.icon && t.box is RenderParagraph)
        .where((t) => (t.box as RenderParagraph).text.toPlainText() == hint)
        .firstOrNull;
    double? hintBaseline;
    final extras = <String>[];
    final emptyEditable = editableIn(empty);
    // How much more room the decoration leaves above the line than below
    // it: a theme's padding or minimum height, which a cap center around the
    // field would hide from the line but not from the box.
    double? uneven;
    if (emptyEditable != null) {
      for (
        RenderObject? up = emptyEditable.parent;
        up != null;
        up = up.parent
      ) {
        if (identical(up, empty)) break;
        if (up is RenderBox && decorations.contains(up)) {
          final outer = _global(up);
          final line = _global(emptyEditable);
          uneven = (line.top - outer.top) - (outer.bottom - line.bottom);
          break;
        }
      }
    }
    if (hintBox != null) {
      final b = hintBox.baseline;
      if (b != null) {
        hintBaseline = hintBox.box.localToGlobal(Offset(0, b)).dy - top(empty);
      }
      // The smallest box that holds the editable and its hint: anything
      // else in it that a decoration draws. What the look lays beside a
      // bare editable in that box (a reveal button in its own row) is the
      // look's, and is not named.
      bool decorated(RenderObject node) {
        for (RenderObject? n = node; n != null; n = n.parent) {
          if (decorations.contains(n)) return true;
          if (identical(n, empty)) break;
        }
        return false;
      }

      if (emptyEditable != null) {
        final around = <RenderObject>{};
        for (RenderObject? n = emptyEditable; n != null; n = n.parent) {
          around.add(n);
          if (identical(n, empty)) break;
        }
        RenderObject? shared = hintBox.box;
        while (shared != null && !around.contains(shared)) {
          shared = shared.parent;
        }
        if (shared != null) {
          for (final t in _textsUnder(shared)) {
            if (identical(t.box, hintBox.box) ||
                t.box is RenderEditable ||
                !decorated(t.box)) {
              continue;
            }
            final words = t.box is RenderParagraph
                ? (t.box as RenderParagraph).text.toPlainText()
                : '';
            extras.add(t.icon ? 'an icon' : '"$words"');
          }
        }
      }
    }
    return _Entry(
      size: typed.size,
      baseline: baseline,
      line: line,
      laidLine: laidLine,
      uneven: uneven,
      hintBaseline: hintBox == null ? null : hintBaseline ?? double.nan,
      extras: extras,
      editable: typedEditable != null,
    );
  }

  final Size size;

  // The typed text's baseline, from the top of its box.
  final double? baseline;

  // How far the typed text's capitals' middle is below the box's, as drawn
  // and as laid out.
  final double? line;
  final double? laidLine;

  // How much more room its decoration leaves above its line than below it.
  final double? uneven;

  // The hint's baseline from the top of its box; null when no hint shows.
  final double? hintBaseline;

  // What the editable's decoration carries besides the hint.
  final List<String> extras;

  final bool editable;

  List<String> problems(String at, double tolerance) {
    final hint = hintBaseline;
    final b = baseline;
    final l = line;
    return [
      if (!editable) '$at: no editable text in it',
      if (hint == null) '$at: no hint shows while it is empty',
      if (l != null && l.abs() > tolerance)
        '$at: its capitals are ${_px(l.abs())} px '
            '${l > 0 ? 'below' : 'above'} the middle of its box as drawn, '
            '${_onOrOff(laidLine ?? l)} as laid out',
      if (uneven case final u? when u.abs() > tolerance)
        '$at: its decoration leaves ${_px(u.abs())} px more room '
            '${u > 0 ? 'above' : 'below'} its line than '
            '${u > 0 ? 'below' : 'above'} it: padding or a minimum height '
            'the theme fills in',
      if (hint != null && b != null && (hint - b).abs() > tolerance)
        '$at: its hint is ${_px((hint - b).abs())} px '
            '${hint > b ? 'below' : 'above'} the typed text\'s baseline',
      if (extras.isNotEmpty)
        '$at: its decoration carries ${extras.join(', ')}; icons, a '
            'counter, help and error are the look\'s own widgets, outside it',
    ];
  }
}

// "on it", or "2 px below" or "2 px above".
String _onOrOff(double v) =>
    _px(v).replaceFirst('-', '') == '0' ? 'on it' : _px(v, signed: true);

// The cap center [box] is drawn in, below [root]; null outside one.
RenderCapCenter? _capCentredIn(RenderObject box, RenderObject root) {
  for (RenderObject? up = box.parent; up != null; up = up.parent) {
    if (up case final RenderCapCenter centred) return centred;
    if (identical(up, root)) break;
  }
  return null;
}

// What an ink message adds when the engine's whole-pixel baseline moved the
// ink [rounding] (down when positive) to [drawn] from its control's middle;
// nothing when it did not.
String _roundingNote(double rounding, double drawn) {
  if (rounding.abs() < 0.01) return '';
  final r = rounding.abs().toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  final at = _px(drawn).replaceFirst('-', '') == '0'
      ? 'on its middle'
      : _px(drawn, signed: true);
  return ' as laid out (the engine\'s whole-pixel baseline draws it $r px '
      '${rounding > 0 ? 'lower' : 'higher'}, $at)';
}

/// The matrix drawn for a person: each row at [zoom] times its size under
/// one of the look's themes, with the row's centre line (blue), each
/// control's box (grey) and each label's baseline (red) marked.
class DesignAlignmentSheet extends StatelessWidget {
  /// A sheet of [matrix].
  const DesignAlignmentSheet({
    super.key,
    required this.matrix,
    this.theme,
    this.zoom = 4,
  }) : assert(zoom > 0);

  /// The look's matrix.
  final DesignAlignmentMatrix matrix;

  /// The name of the theme to draw it under; null: the first.
  final String? theme;

  /// How many times its size a row is drawn.
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final name = theme ?? matrix.themes.keys.first;
    final wrap = matrix.themes[name]!;
    final caption = DefaultTextStyle.of(context).style;
    return wrap(
      context,
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in matrix.rows) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: Text('${row.size} · $name', style: caption),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IgnorePointer(
                  child: _Zoom(
                    zoom: zoom,
                    child: _Row(matrix: matrix, row: row),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DesignAlignmentMatrix>('matrix', matrix))
      ..add(StringProperty('theme', theme, defaultValue: null))
      ..add(DoubleProperty('zoom', zoom, defaultValue: 4));
  }
}

// Every row of the matrix, one under another, each as wide as it is.
class _Rows extends StatelessWidget {
  const _Rows({required this.matrix, required this.keys});

  final DesignAlignmentMatrix matrix;
  final List<List<GlobalKey>> keys;

  @override
  Widget build(BuildContext context) => UnconstrainedBox(
    alignment: AlignmentDirectional.topStart,
    clipBehavior: Clip.hardEdge,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var r = 0; r < matrix.rows.length; r++)
          Padding(
            padding: const EdgeInsets.all(8),
            child: _Row(matrix: matrix, row: matrix.rows[r], keys: keys[r]),
          ),
      ],
    ),
  );
}

// One row: its controls centred on one line, each in a probe.
class _Row extends StatelessWidget {
  const _Row({required this.matrix, required this.row, this.keys});

  final DesignAlignmentMatrix matrix;
  final DesignAlignmentRow row;
  final List<GlobalKey>? keys;

  @override
  Widget build(BuildContext context) => _RowBox(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var e = 0; e < row.entries.length; e++)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: _Probe(
              key: keys?[e],
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Builder(
                  builder: (context) =>
                      row.entries[e].builder(context, matrix.label),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

// Marks a row, so a probe can find it.
class _RowBox extends SingleChildRenderObjectWidget {
  const _RowBox({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderRowBox();
}

class _RenderRowBox extends RenderProxyBox {}

// Marks a control and draws it on a layer of its own, so its pixels can be
// read alone.
class _Probe extends SingleChildRenderObjectWidget {
  const _Probe({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderProbe();
}

class _RenderProbe extends RenderRepaintBoundary {
  // The row it stands in.
  RenderBox get row {
    RenderObject? node = parent;
    while (node != null && node is! _RenderRowBox) {
      node = node.parent;
    }
    return node! as RenderBox;
  }
}

// The texts under [root], in paint order: each paragraph and each field's
// text that has something in it. A glyph alone from a private-use code
// point is an icon.
List<_TextBox> _textsUnder(RenderObject root) {
  final found = <_TextBox>[];
  void visit(RenderObject node) {
    if (node is RenderParagraph && node.hasSize && !node.size.isEmpty) {
      final text = node.text.toPlainText(includeSemanticsLabels: false);
      if (text.trim().isNotEmpty) {
        found.add(_TextBox(node, icon: isIconGlyph(text)));
      }
    } else if (node is RenderEditable && node.hasSize && !node.size.isEmpty) {
      final text = node.text?.toPlainText(includeSemanticsLabels: false) ?? '';
      if (text.trim().isNotEmpty) found.add(_TextBox(node, icon: false));
    }
    _visitShown(node, visit);
  }

  visit(root);
  return found;
}

// A control's measure: its box (global), its place in its row, and its
// texts.
class _Measured {
  _Measured({
    required this.box,
    required this.inRow,
    required this.texts,
    required this.capitals,
    required this.style,
  });

  final Rect box;
  final Offset inRow;
  final List<_Text> texts;

  // Its first label's capitals' middle (global), as drawn and as laid out;
  // null when unread.
  final ({double drawn, double? laid})? capitals;

  // Its first label's size and style; null without a label.
  final String? style;

  // Its first label's baseline (global); null without a label.
  double? get baseline {
    for (final t in texts) {
      if (!t.icon && t.baseline != null) return t.baseline;
    }
    return null;
  }
}

class _Text {
  _Text({
    required this.icon,
    required this.baseline,
    required this.ink,
    required this.rounding,
  });

  final bool icon;
  final double? baseline;

  // The rows its ink covers (global, top to bottom); null when unmeasured.
  final ({double top, double bottom})? ink;

  // How far the engine draws its baseline below where it was laid out, to
  // put it on a whole pixel (negative: above); 0 where that is unknown.
  final double rounding;
}

extension on ({double top, double bottom}) {
  ({double top, double bottom}) shift(double dy) =>
      (top: top + dy, bottom: bottom + dy);
}

// Lays its child out at 1/[zoom] of the room and draws it [zoom] times its
// size, with the marks of each probe under it.
class _Zoom extends SingleChildRenderObjectWidget {
  const _Zoom({required this.zoom, required super.child});

  final double zoom;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderZoom(zoom);

  @override
  void updateRenderObject(BuildContext context, _RenderZoom renderObject) =>
      renderObject.zoom = zoom;
}

class _RenderZoom extends RenderProxyBox {
  _RenderZoom(this._zoom);

  double _zoom;

  set zoom(double value) {
    if (value == _zoom) return;
    _zoom = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child!;
    c.layout(
      BoxConstraints(
        maxWidth: constraints.maxWidth / _zoom,
        maxHeight: constraints.maxHeight / _zoom,
      ),
      parentUsesSize: true,
    );
    size = constraints.constrain(c.size * _zoom);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.scaleByDouble(_zoom, _zoom, 1, 1);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      false;

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child!;
    context.pushTransform(
      needsCompositing,
      offset,
      Matrix4.diagonal3Values(_zoom, _zoom, 1),
      (context, offset) => context.paintChild(c, offset),
    );
    final probes = <_RenderProbe>[];
    void visit(RenderObject node) {
      if (node is _RenderProbe) probes.add(node);
      _visitShown(node, visit);
    }

    _visitShown(c, visit);
    if (probes.isEmpty) return;
    final canvas = context.canvas;
    Rect boxOf(RenderBox b) {
      final r = MatrixUtils.transformRect(
        b.getTransformTo(c),
        Offset.zero & b.size,
      );
      return Rect.fromLTRB(
        r.left * _zoom,
        r.top * _zoom,
        r.right * _zoom,
        r.bottom * _zoom,
      ).shift(offset);
    }

    final boxes = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x99808080);
    final baselines = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFFE53935);
    final first = boxOf(probes.first);
    for (final probe in probes) {
      final box = boxOf(probe);
      canvas.drawRect(box.deflate(0.5), boxes);
      for (final text in _textsUnder(probe)) {
        final b = text.baseline;
        if (text.icon || b == null) continue;
        final y = boxOf(text.box).top + b * _zoom;
        canvas.drawLine(Offset(box.left, y), Offset(box.right, y), baselines);
        break;
      }
    }
    canvas.drawLine(
      Offset(offset.dx, first.center.dy),
      Offset(offset.dx + size.width, first.center.dy),
      Paint()
        ..strokeWidth = 1
        ..color = const Color(0xFF1E88E5),
    );
  }
}
