/// Whether a look's controls line up where they share a line: in a row of
/// controls of one size, one height, one vertical centre, and every label's
/// and text entry's capitals on that centre (what the eye compares; one
/// baseline only among labels of one size and style); each icon's ink
/// centred in its control; and the same sizes and places on every platform
/// the look runs on.
///
/// Test and review support, nothing an app runs. A look fills a
/// [DesignAlignmentMatrix] with its own controls, one [DesignAlignmentRow]
/// per size; its tests call [DesignAlignmentMatrix.check] and its review page
/// shows a [DesignAlignmentSheet]. Its tests also give each of its text
/// entries to a [DesignTextEntryCheck].
///
/// What keeps a line straight, for a look's author:
/// - one control height per size and density, taken by every control that
///   can share a line;
/// - content centred in a box of that height, rather than padding added to
///   a line height;
/// - even leading ([TextLeadingDistribution.even]) on control labels, so a
///   label's line box is centred on its glyphs;
/// - a row that centres its controls, never one that aligns them to the
///   bottom or the top;
/// - a theme under the look that pins its density. Material's
///   `ThemeData.visualDensity` is compact on desktop unless the theme says
///   otherwise, and a test runs as Android, so no test sees it;
/// - a text entry that is a `TextField` (validated by the look's own
///   `FormField`, never a `TextFormField`) inside the look's own box, its
///   decoration null or collapsed with `contentPadding`, `constraints`,
///   `isDense` and `visualDensity` all set, its one line centred by
///   alignment, and its icons, counter, help and error the look's own
///   widgets beside or under the box: a decoration field left unset is
///   filled from the platform and the host theme.
library;

import 'dart:math' as math;
import 'dart:ui' show SemanticsInputType;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'anchored_overlay.dart' show DesignAnchoredOverlay;
import 'cap_center.dart';
import 'internal/drawn_pixels.dart';
import 'internal/label_line.dart';
import 'keyline_region.dart';

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

/// Puts [child] where a look's page would have it: under the look's theme
/// and, for a Material look, a `Material`.
typedef DesignAlignmentTheme = Widget Function(
  BuildContext context,
  Widget child,
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
  /// `capHeightFactor` of the [DesignCapCenter] around them, else read from
  /// their flat-topped capitals' pixels. A look whose labels and entries are
  /// each wrapped in a [DesignCapCenter] holds them within half a device
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
/// [DesignCapCenter]'s around the field, else the usual 0.7 of its font
/// size. A field wrapped in a [DesignCapCenter] holds its capitals on its
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
      // Its capitals: the cap height its DesignCapCenter gives, else the
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
CapCentred? _capCentredIn(RenderObject box, RenderObject root) {
  for (RenderObject? up = box.parent; up != null; up = up.parent) {
    if (up case final CapCentred centred) return centred;
    if (identical(up, root)) break;
  }
  return null;
}

// [v] in pixels for a message, to a tenth; [signed]: "2 px below" or
// "2 px above".
String _px(double v, {bool signed = false}) {
  final s = v.abs().toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  if (!signed) return v < 0 ? '-$s' : s;
  return '$s px ${v > 0 ? 'below' : 'above'}';
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

/// What [DesignAlignmentMatrix.check] found: one line per problem.
@immutable
class DesignAlignmentReport {
  /// A report on [look] listing [problems].
  const DesignAlignmentReport(this.look, this.problems);

  /// The look checked.
  final String look;

  /// One line per problem, each naming the size, the theme, the platform
  /// and the control.
  final List<String> problems;

  /// Whether nothing is out of line.
  bool get isAligned => problems.isEmpty;

  /// Throws a [DesignAlignmentError] listing the problems, if there are any.
  void verify() {
    if (problems.isNotEmpty) throw DesignAlignmentError(look, problems);
  }
}

/// A look's controls out of line, as [DesignAlignmentReport.verify] throws
/// it.
class DesignAlignmentError extends Error {
  /// An error listing [problems].
  DesignAlignmentError(this.look, this.problems);

  /// The look whose controls they are.
  final String look;

  /// One line per problem.
  final List<String> problems;

  @override
  String toString() =>
      '$look alignment: ${problems.length} problem(s)\n${problems.join('\n')}';
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
  });

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

// A text a control shows: a label or an icon's glyph.
class _TextBox {
  _TextBox(this.box, {required this.icon});

  final RenderBox box;
  final bool icon;

  // Its first line's alphabetic baseline, from its top; null when it holds
  // widgets inline, whose layout only its own pass knows.
  double? get baseline {
    final b = box;
    if (b is RenderParagraph && b.childCount > 0) return null;
    return b.getDryBaseline(b.constraints, TextBaseline.alphabetic);
  }

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

/// Whether the content of each [DesignKeylineRegion] on a screen starts on
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
/// - a control by its face: a [DesignKeylineFace] in it, or else the
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
///   [DesignKeylineRegion] inside one is judged on its own). A face across
///   the region from side to side and at least half its height is the
///   region's ground, and what it holds is read. A `Container`'s colour
///   counts where it differs from what is around it; a box the colour of
///   what is around it is not an item, and what it holds is;
/// - a [DesignKeylineFace] as one item at its box, before its pixels are
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
/// [DesignKeylineRegion.startAligned] (a gallery section's column of
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

  /// Measures every [DesignKeylineRegion] under [context] (the regions
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

/// Draws [child] with each [DesignKeylineRegion] in it outlined, its
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

/// Whether the words and the icon each control on a screen shows sit on
/// the middle of its face, up and down, as they are drawn, and a chosen
/// control's fill fills its cell.
///
/// It needs no list of controls. Every control on the screen (a button, a
/// link, a toggle, a field, or anything with a tap action) that draws a
/// face and holds one line of words, an icon, or both on one line is
/// checked, so a control no [DesignAlignmentMatrix] row names (a split
/// button, a gallery page's own) is checked too. The face is read as
/// [DesignKeylineCheck] reads it: the largest box inside the control that
/// paints, not its tap box or a shadow outside it. Left out: a control
/// without a face (a text button), one whose words run to a second line or
/// that holds two lines (a title and a subtitle), one holding a text entry
/// ([DesignTextEntryCheck] checks those), a label inside a smaller face of
/// its own within the control (a badge), and a label more than a quarter
/// of its face's height from its middle, which is placed there, not
/// centred (a tappable card's title).
///
/// A label is read by its capitals, never its ink's bounds, so its
/// descenders ("Spending", "Light") do not count: its baseline where the
/// engine draws it, and their height from the [DesignCapCenter] around it,
/// else read from its capitals flat on the cap height (B, E, H; not V or
/// Y, whose middles meet their arms below it), else the height its style
/// shows on the screen (every line in one family, weight, slant and size
/// takes the one height, read from its first line with a flat-topped
/// capital, else a round one, else any), else the usual cap height (0.7 of
/// its font size). A line of figures alone (a day, a count) is read by its
/// figures likewise, which need not stand at the capitals' height. An icon is
/// read by its ink, and so is a painted mark that starts the row of a
/// control's words (what a custom paint holding no words draws before
/// them: a way back's triangle), which is never placed, however far off: `a
/// button "Back": its painted mark, before its words, is 6 px above the
/// middle of its face as drawn`. Each middle is set against the face's (a
/// face drawn as a rule along one side, a list row's foot, lays its content
/// out inside
/// the rule: its middle is that of the band inside it), but for a label
/// beside a text entry of more than one line (a note field, a composer that
/// grows), which stands on the entry's first line: it is set against the
/// capitals of that line, read as a label's are. Words over or under a
/// picture on the face (an icon tile's name under its image or painted
/// glyph) are placed there, not centred, and are not read. The engine draws
/// a line's baseline on a whole pixel, which moves it up to half a pixel
/// from where it was laid out; the check holds what was laid out to
/// [tolerance] and names both: `a button "Share": the label "Share" is 0.5
/// px above the middle of its face as laid out, 1 px above as drawn`. A line
/// holding a widget (a shortcut's key) is read from its capitals' pixels, top
/// and bottom, and held as drawn, the engine's rounding allowed.
///
/// A chosen control's ground fills the cell a person sees, not a marker
/// behind its words. A control chosen (selected, toggled on or checked)
/// among controls of its kind beside or over it, none of which shows a face
/// of its own unchosen (a toggle group's cells in a trough, a drawer's
/// destinations), has for its cell the slot the layout holding them gives
/// it (a drawer's row, however tight its pressable). Its fill is the colour
/// its words stand on (its own, or drawn over it from beside it in the
/// slot), where that differs from what is round the cell, read out to where
/// the colour ends (a gradient or a sheen followed, words and icons gone
/// round). It may stand short of the cell's width or height by a quarter of
/// the cell's height (a thumb's inset in its track), and a mark as wide as
/// it is tall (a calendar day's round mark) is the cell the eye sees: `a
/// switch "Bold": its chosen fill is 61 by 20 px in its cell of 110 by 44;
/// the chosen ground fills the cell, to 11 px short`. Chips and cards,
/// whose unchosen faces are their cells, and a tab's line or a navigation
/// bar's mark beside its words, which no fill holds, are not read.
///
/// Before the check, a test loads every font family the look ships (each
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
/// A control whose text is drawn in the test's own font (its letters solid
/// boxes of the words' one colour; a gradient under real words is not
/// that) fails the whole check once, with that reason, instead of with an
/// offset for each.
///
/// A test pumps a screen (a gallery page, an app screen), then:
///
/// ```dart
/// final report = await const DesignLabelCheck(look: 'Comic').check(
///   tester.element(find.byType(SettingsScreen)),
///   runAsync: tester.runAsync,
/// );
/// report.verify();
/// ```
///
/// Run it under every density the look ships (standard and compact): a
/// control can be centred under one and not the other. A split button whose
/// trailing half keeps a 40 px minimum while compact density takes the
/// leading half's content to 32 sits that label 4 px above its face's
/// middle, and only under compact. [checkDensities] pumps the screen under
/// each and names the density with each problem:
///
/// ```dart
/// final report = await const DesignLabelCheck(look: 'Comic').checkDensities(
///   densities: densities,
///   screen: (context) => const SettingsScreen(),
///   pump: tester.pumpWidget,
///   runAsync: tester.runAsync,
/// );
/// report.verify();
/// ```
@immutable
class DesignLabelCheck {
  /// A check for [look].
  const DesignLabelCheck({
    required this.look,
    this.tolerance = 0.75,
    this.drawnTolerance,
    this.pixelRatio = 3,
  });

  /// The look's name, for messages.
  final String look;

  /// How far, in logical pixels, a label's or an icon's ink may sit from
  /// its face's middle as laid out (the engine's whole-pixel baseline
  /// aside).
  final double tolerance;

  /// How far, in device pixels at [pixelRatio], a one-line label's capitals
  /// may be drawn from its face's middle; null (the default): not held.
  ///
  /// The capitals are read as the engine draws them: their baseline where
  /// the engine puts it (rounded to a whole logical pixel below the line's
  /// top, then to the nearest device pixel), their height the
  /// `capHeightFactor` of the [DesignCapCenter] around the label or, outside
  /// one, read from the pixels of its capitals flat on the cap height (B, E,
  /// H and the like: a round one overshoots it, a V's or a Y's middle meets
  /// its arms below it). Where both are known and
  /// differ by more than twice this plus a device pixel (an engine that
  /// hints snaps the capitals' top to the pixel grid), the factor is named
  /// as wrong. A label
  /// is then held by its capitals instead of its ink, so its descenders do
  /// not count; one with neither (no cap center, no flat-topped capital) is
  /// held by its ink, as without this. An icon beside it is held against its
  /// capitals: its box's middle, moved by its own baseline's roundings, to
  /// this plus half a device pixel, as each goes to a whole device pixel on
  /// its own.
  ///
  /// A look turns it on once its faces wrap their labels in
  /// [DesignCapCenter], which draws them within half a device pixel: 0.5.
  final double? drawnTolerance;

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
    // Each control, with the words and icons it holds itself (not those of
    // a control inside it).
    final held = <RenderBox, List<RenderBox>>{};
    // Each control's painted marks: what a custom paint holding no words
    // draws in it (a way back's triangle, a chevron drawn, not set).
    final marks = <RenderBox, List<RenderBox>>{};
    final entries = <RenderBox>{};
    void visit(RenderObject node, RenderBox? owner) {
      if (node is RenderOffstage && node.offstage) return;
      if (node is RenderOpacity && node.opacity == 0) return;
      if (node is RenderAnimatedOpacity && node.opacity.value == 0) return;
      if (_scaledAway(node)) return;
      var mine = owner;
      if (node is RenderBox && node.hasSize && _isControl(node)) {
        mine = node;
        held[node] = [];
        marks[node] = [];
      }
      if (mine != null && node is RenderEditable) entries.add(mine);
      if (mine != null && node is RenderParagraph && node.hasSize) {
        final text = node.text.toPlainText(includeSemanticsLabels: false);
        if (text.trim().isNotEmpty && !node.size.isEmpty) held[mine]!.add(node);
      }
      if (mine != null &&
          node is RenderCustomPaint &&
          (node.painter != null || node.foregroundPainter != null) &&
          node.hasSize &&
          !node.size.isEmpty &&
          _shownIn(node).isEmpty) {
        marks[mine]!.add(node);
      }
      _visitShown(node, (child) => visit(child, mine));
    }

    visit(root, null);
    final pixels = <RenderRepaintBoundary, DrawnPixels>{};
    final found = <String>[];
    final fallback = <String>[];
    for (final MapEntry(key: control, value: texts) in held.entries) {
      if (entries.contains(control)) continue;
      final chosen = _LabelReader._chosen(control);
      if (texts.isEmpty && !chosen) continue;
      final boundary = _drawnIn(control);
      if (boundary == null) continue;
      final drawn = pixels[boundary] ??= await DrawnPixels.read(
        boundary,
        pixelRatio,
        runAsync,
      );
      final reader = _LabelReader(this, boundary, drawn, marked);
      if (chosen) found.addAll(reader.chosenFill(control));
      if (texts.isNotEmpty) {
        found.addAll(reader.problems(control, texts, marks[control]!));
      }
      fallback.addAll(reader.fallback);
    }
    if (fallback.isNotEmpty) {
      return DesignAlignmentReport(look, [_testFontProblem(fallback)]);
    }
    return DesignAlignmentReport(look, found);
  }

  /// Puts [screen] on screen under each of [densities] and checks it as
  /// [check] does, each problem led by the density's name:
  /// `compact · a button "Share": the label "Share" is 4 px above …`.
  ///
  /// [densities] holds the look's theme as an app's page gets it under
  /// each density the look ships, by name ("standard", "compact"), as
  /// [DesignAlignmentMatrix.themes] does. A test passes its tester's
  /// `pumpWidget` as [pump] and `runAsync` as [runAsync] (reading pixels
  /// takes real time).
  Future<DesignAlignmentReport> checkDensities({
    required Map<String, DesignAlignmentTheme> densities,
    required WidgetBuilder screen,
    required Future<void> Function(Widget widget) pump,
    required Future<T?> Function<T>(Future<T> Function() work) runAsync,
  }) async {
    final found = <String>[if (densities.isEmpty) 'no density to check under'];
    for (final MapEntry(key: name, value: theme) in densities.entries) {
      final key = GlobalKey();
      await pump(
        KeyedSubtree(
          key: ValueKey(name),
          child: _Page(
            theme: theme,
            child: RepaintBoundary(
              key: key,
              child: Builder(builder: screen),
            ),
          ),
        ),
      );
      final report = await check(key.currentContext!, runAsync: runAsync);
      found.addAll([for (final problem in report.problems) '$name · $problem']);
    }
    return DesignAlignmentReport(look, found);
  }
}

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
/// layer). A face no pixel of which
/// reaches the floor (a fill a hue apart from its ground, a pane of glass)
/// is read by its box, as is one a look marks with [DesignKeylineFace].
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
/// is outside the image (scrolled out of its strip), or that a clip round it
/// hides in part (a week scrolled in its strip, its weekend past the
/// strip's edge), is not read. A row
/// inside a region that says why its controls may differ in height or
/// centre ([DesignKeylineRegion.mixedHeights]: a gallery's ladder of one
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
      final held = <RenderBox>[];
      var groups = 0;
      _visitShown(node, (child) {
        final under = child is RenderBox && child.hasSize && _isControl(child)
            ? [child]
            : finder._controlsUnder(child);
        if (under.isNotEmpty) groups++;
        held.addAll(under);
      });
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
      _visitShown(node, visit);
    }

    visit(root);
    final regions = _regionBoxes(context);
    final pixels = <RenderRepaintBoundary, DrawnPixels>{};
    final found = <String>[];
    final fallback = <String>[];
    final toDo = <DesignKeylineRegion>{};
    for (final (node, controls) in rows) {
      // A region that says why its controls differ is not held.
      if (_regionOf(node, regions)
          case DesignKeylineRegion(:final mixedHeights?) && final region) {
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
      final drawn = pixels[boundary] ??= await DrawnPixels.read(
        boundary,
        pixelRatio,
        runAsync,
      );
      final reader = _RowReader(this, boundary, drawn, marked);
      found.addAll(reader.problems(node, controls));
      fallback.addAll(reader.fallback);
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
///   or both is a button; one that anchors a [DesignAnchoredOverlay] (or a
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
/// - **A look's own limit**: [limits] gives a kind another width, with the
///   reason (`DesignWidthLimit(400, 'the sign-in card's one act spans its
///   400 card')`); a reason that is a to-do fails.
///
/// [checkList] holds a list opened from a field (a select, a combobox, a
/// menu from a form field), with the list open, at any width: at least as
/// wide as the field, starting on its leading edge, its words on the field's
/// words or [listWordsIndent] in from them.
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
@immutable
class DesignWidthCheck {
  /// A check for [look].
  const DesignWidthCheck({
    required this.look,
    this.from = 600,
    this.maxWidth = 320,
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
        final under = child is RenderBox && child.hasSize && _isControl(child)
            ? [child]
            : finder._controlsUnder(child);
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
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final reader = await readerFor(item.box);
      if (reader == null) continue;
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
  /// open: at least as wide as the field, starting on its leading edge, and
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
    final fieldFace = controls.length > 1
        ? fieldReader._face(box)
        : fieldReader._face(control) ?? fieldReader._well(control, root);
    final fieldLaid = fieldFace?.rect ?? _global(whole);
    final fieldDrawn = fieldFace == null
        ? fieldLaid
        : fieldReader._outline(
                fieldLaid,
                whole,
                fieldFace.read ? null : fieldFace.box,
                null,
              ) ??
              fieldLaid;
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
    final listRead = listReader?._outline(listLaid, list, list, null);
    final listDrawn = listRead ?? listLaid;
    String drawnAs(String v) => listReader == null ? '' : ', $v as drawn';
    final who = 'a list opened from $name';
    final found = <String>[];
    if (listDrawn.width < fieldDrawn.width - tolerance) {
      found.add(
        '$who: ${_px(listLaid.width)} px wide as laid out'
        '${drawnAs(_px(listDrawn.width))}, narrower than the field '
        '(${_px(fieldLaid.width)}, ${_px(fieldDrawn.width)} as drawn)',
      );
    }
    // Toward the trailing edge, positive.
    double lead(Rect r) => rtl ? -r.right : r.left;
    final laidIn = lead(listLaid) - lead(fieldLaid);
    final drawnIn = lead(listDrawn) - lead(fieldDrawn);
    if (drawnIn.abs() > tolerance) {
      found.add(
        "$who: its leading edge is ${_inFrom(laidIn)} the field's as laid "
        'out${drawnAs(_inFrom(drawnIn))}',
      );
    }
    // Chosen values shown before the entry (a multi-select's chips in its
    // groove): the field's words move with what is chosen, so the list's
    // are not held to them.
    final entryLead = lead(_global(control));
    final chipsFirst = controls.any(
      (c) =>
          !identical(c, control) &&
          _wordsOf(c).isNotEmpty &&
          lead(_global(c)) < entryLead - tolerance,
    );
    final fieldWords = chipsFirst ? null : _wordsStart(control, rtl);
    final items = finder._controlsUnder(list)
      ..sort((a, b) => _global(a).top.compareTo(_global(b).top));
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

  // Where [control]'s words start, global x of their leading edge: its
  // line's first character, or an empty entry's caret.
  static double? _wordsStart(RenderBox control, bool rtl) {
    final line = labelLine(control);
    if (line == null) return null;
    final boxes = lineBoxes(
      line,
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );
    double x;
    if (boxes.isNotEmpty) {
      x = rtl ? boxes.first.right : boxes.first.left;
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

    final fieldLayer = layerOf(box);
    var pastField = false;
    // Whether [n] is a popup: drawn straight into the overlay, with no
    // repaint boundary above it (nothing on a route's page is); or in a
    // layer drawn after, over, the field's page.
    bool overlaid(RenderObject n) {
      var bare = true;
      for (RenderObject? up = n; up != null && bare; up = up.parent) {
        if (up is RenderRepaintBoundary) bare = false;
      }
      if (bare) return true;
      if (!pastField || fieldLayer == null) return false;
      final layer = layerOf(n);
      return layer != null && !identical(layer, fieldLayer);
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
        final near =
            (r.top >= field.bottom - 1 && r.top - field.bottom <= 32) ||
            (r.bottom <= field.top + 1 && field.top - r.bottom <= 32);
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
    bool inside(RenderObject n, RenderObject outer) {
      for (var up = n.parent; up != null; up = up.parent) {
        if (identical(up, outer)) return true;
      }
      return false;
    }

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

/// Whether every word on a screen stands whole on one line: none broken
/// across two.
///
/// A paragraph that wraps breaks its lines between words. A word wider than
/// the box it is given is broken where the box ends, "Groce" over "ries",
/// which a reader takes for two words: a tile squeezed into a measure, a
/// phone preview given the width beside a side bar. Each word (a run of
/// letters and figures between spaces, hyphens, dashes and slashes, where a
/// line may break) is read by its glyphs' boxes, and one drawn on two lines
/// is named: `the words "Spending this month": "Spending" is broken across
/// two lines as "Spendin" and "g" (it needs 71 px, its box is 64)`. A text
/// held to one line breaks none ([DesignClipCheck] reads one cut short), and
/// only what is painted is read.
///
/// A test pumps a screen (a gallery page, an app screen) at each width it
/// runs at, then:
///
/// ```dart
/// const DesignWordBreakCheck(look: 'Comic')
///     .check(tester.element(find.byType(SettingsScreen)))
///     .verify();
/// ```
@immutable
class DesignWordBreakCheck {
  /// A check for [look].
  const DesignWordBreakCheck({required this.look});

  /// The look's name, for messages.
  final String look;

  /// Checks every paragraph under [context] that is laid out and painted.
  DesignAlignmentReport check(BuildContext context) {
    final root = context.findRenderObject();
    if (root == null) return DesignAlignmentReport(look, const []);
    final found = <String>[];
    void visit(RenderObject node) {
      if (node is RenderParagraph && node.hasSize && !node.size.isEmpty) {
        found.addAll(_brokenIn(node));
      }
      _visitShown(node, visit);
    }

    visit(root);
    return DesignAlignmentReport(look, found);
  }

  // Each word [p] draws on more than one line.
  static List<String> _brokenIn(RenderParagraph p) {
    if (p.maxLines == 1) return const [];
    final text = p.text.toPlainText(includeSemanticsLabels: false);
    if (text.trim().isEmpty || isIconGlyph(text)) return const [];
    // The top of the line the character at [i] is drawn on; null when it
    // draws nothing (past the last line shown).
    double? lineOf(int i) => p
        .getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1))
        .firstOrNull
        ?.top;
    final found = <String>[];
    for (final word in RegExp(r'[^\s\-‐‑–—/]+').allMatches(text)) {
      // A widget inline is no word.
      if (word[0]!.contains('￼')) continue;
      final boxes = p.getBoxesForSelection(
        TextSelection(baseOffset: word.start, extentOffset: word.end),
      );
      if (boxes.length < 2) continue;
      final first = boxes.first;
      final height = boxes.map((b) => b.bottom - b.top).reduce(math.min);
      if (!boxes.any((b) => (b.top - first.top).abs() > height / 2)) continue;
      final top = lineOf(word.start);
      var at = word.end;
      for (var i = word.start + 1; i < word.end; i++) {
        final line = lineOf(i);
        if (line != null && top != null && (line - top).abs() > height / 2) {
          at = i;
          break;
        }
      }
      final needs = boxes.fold(0.0, (w, b) => w + b.right - b.left);
      final whole = text.replaceAll('\n', ' ').trim();
      found.add(
        'the words "${whole.length > 40 ? '${whole.substring(0, 39)}…' : whole}": '
        '"${word[0]}" is broken across two lines as '
        '"${text.substring(word.start, at)}" and '
        '"${text.substring(at, word.end)}" (it needs ${_px(needs)} px, its '
        'box is ${_px(p.size.width)})',
      );
    }
    return found;
  }
}

/// Whether everything on a screen shows whole: no control and no line of
/// words cut by a clip.
///
/// A box that clips what it holds (a card's rounded clip, a popover's frame,
/// a `ClipRect`, a stack that clips what overflows it, the screen's edge)
/// cuts whatever stands partly past it: a month whose Saturday is cut in a
/// 320 px room, a label whose last letters fall past its button's edge.
/// Each control is read by what it shows (its face, else its words and
/// icons) against the clips round it, each line of words by its glyphs
/// against the clips round it and its own: one partly past a clip, by more
/// than [tolerance], is named, `a button "Sat" is cut at its right by 22
/// px: 26 of its 48 px across show`. What stands wholly past a clip is
/// hidden, not cut (a closed disclosure's rows). A clip that scrolls (a
/// list, a carousel, a strip scrolled sideways) shows the rest when
/// scrolled, and what it holds is read only against the clips inside it. A
/// text whose words run past its last line with no ellipsis is cut short:
/// an ellipsis says it was shortened, and is not read.
///
/// A test pumps a screen (a gallery page, an app screen) at each width it
/// runs at, then:
///
/// ```dart
/// const DesignClipCheck(look: 'Comic')
///     .check(tester.element(find.byType(SettingsScreen)))
///     .verify();
/// ```
@immutable
class DesignClipCheck {
  /// A check for [look].
  const DesignClipCheck({required this.look, this.tolerance = 0.5});

  /// The look's name, for messages.
  final String look;

  /// How far, in logical pixels, what shows may stand past a clip.
  final double tolerance;

  /// Checks every control and every line of words under [context] that is
  /// laid out and painted.
  DesignAlignmentReport check(BuildContext context) {
    final root = context.findRenderObject();
    if (root == null) return DesignAlignmentReport(look, const []);
    final reader = _DrawnReader(null, null, _markedFaces(context));
    final found = <String>[];
    final cut = <RenderBox>{};
    void visit(RenderObject node, RenderBox? control) {
      var mine = control;
      // A control inside one already named is cut with it.
      if (node is RenderBox &&
          node.hasSize &&
          _isControl(node) &&
          (control == null || !cut.contains(control))) {
        mine = node;
        if (_cutAt(reader._shownBy(node), _clipRound(node)) case final sides?) {
          cut.add(node);
          found.add('${_nameOf(node)} is cut $sides');
        }
      }
      if (node is RenderParagraph &&
          node.hasSize &&
          !node.size.isEmpty &&
          (mine == null || !cut.contains(mine))) {
        found.addAll(_textCut(node));
      }
      _visitShown(node, (child) => visit(child, mine));
    }

    visit(root, null);
    return DesignAlignmentReport(look, found);
  }

  // Where [shown] stands past [clip], "at its right by 22 px: 26 of its 48
  // px across show" ([its] the possessive); null when it shows whole or not
  // at all. [high] is how far it may stand past the clip's top or bottom.
  String? _cutAt(Rect shown, Rect? clip, {String its = 'its', double? high}) {
    if (clip == null || shown.isEmpty) return null;
    final seen = shown.intersect(clip);
    if (seen.width <= 0 || seen.height <= 0) return null;
    final sides = [
      for (final (side, by, past) in [
        ('left', clip.left - shown.left, tolerance),
        ('top', clip.top - shown.top, high ?? tolerance),
        ('right', shown.right - clip.right, tolerance),
        ('bottom', shown.bottom - clip.bottom, high ?? tolerance),
      ])
        if (by > past) '$side by ${_px(by)} px',
    ];
    if (sides.isEmpty) return null;
    final across = seen.width < shown.width - tolerance;
    final (part, whole, way) = across
        ? (seen.width, shown.width, 'across')
        : (seen.height, shown.height, 'high');
    return 'at $its ${sides.join(' and $its ')}: ${_px(part)} of $its '
        '${_px(whole)} px $way show';
  }

  // A paragraph's words cut by a clip round it, by its own clip (a text
  // that overflows a box it clips to), or short of their end.
  List<String> _textCut(RenderParagraph p) {
    final text = p.text.toPlainText(includeSemanticsLabels: false);
    if (text.trim().isEmpty) return const [];
    final icon = isIconGlyph(text);
    final short = text.replaceAll('\n', ' ').trim();
    final (words, are, its) = icon
        ? ('an icon', 'is', 'its')
        : (
            'the words "${short.length > 24 ? '${short.substring(0, 23)}…' : short}"',
            'are',
            'their',
          );
    final ellipsis = p.overflow == TextOverflow.ellipsis;
    if (p.didExceedMaxLines && !ellipsis && !icon) {
      return ['$words run past their last line and are cut short there'];
    }
    final boxes = p.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    );
    if (boxes.isEmpty) return const [];
    final lines = MatrixUtils.transformRect(
      p.getTransformTo(null),
      boxes.map((b) => b.toRect()).reduce((a, b) => a.expandToInclude(b)),
    );
    var clip = _clipRound(p);
    if (!ellipsis && p.overflow != TextOverflow.visible) {
      final own = _global(p);
      clip = clip == null ? own : clip.intersect(own);
    }
    // A line's box stands past its glyphs by its leading: a clip that takes
    // a quarter of a line or less off its top or bottom cuts no ink.
    final line = boxes.map((b) => b.bottom - b.top).reduce(math.min);
    final sides = _cutAt(
      lines,
      clip,
      its: its,
      high: math.max(tolerance, line / 4),
    );
    return sides == null ? const [] : ['$words $are cut $sides'];
  }

  // The clips round [node] up to the first that scrolls: what a viewport
  // holds is read only against the clips inside it.
  static Rect? _clipRound(RenderObject node) =>
      _clipOf(node, throughScrolls: false);
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

// The boxes under [context] that anchor a list: a DesignAnchoredOverlay's
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
    if (w is DesignAnchoredOverlay ||
        material.any((m) => name == m || name.startsWith('$m<'))) {
      final box = element.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize) found.add(box);
    }
    element.visitChildElements(visit);
  }

  if (context is Element) visit(context);
  return found;
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
  final regions = <(DesignKeylineRegion, RenderBox, TextDirection)>[];
  final marked = <RenderBox>{};
  void visit(Element element) {
    final widget = element.widget;
    if (widget is DesignKeylineFace) {
      final box = element.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize && _isShown(box)) {
        marked.add(box);
      }
    }
    if (widget is DesignKeylineRegion) {
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
  late final List<Rect> _shownRects = [
    if (boundary case final b?)
      for (final p in _shownIn(b)) _global(p),
  ];

  // The words, icons and text entries drawn over [r] (or under it): none of
  // them a face's own ink, whichever control holds them (a navigation
  // item's icon beside its pressable layer, not in it).
  List<Rect> _shownOver(Rect r) => [
    for (final s in _shownRects)
      if (s.overlaps(r)) s,
  ];

  Rect _toBoundary(Rect global) {
    final toGlobal = boundary!.getTransformTo(null);
    final back = Matrix4.tryInvert(toGlobal);
    return back == null ? global : MatrixUtils.transformRect(back, global);
  }

  // What is drawn inside [global] other than what it is drawn over (the
  // commonest colour just around it), leaving out what is inside [except],
  // in global coordinates; null without pixels or ink.
  Rect? _ink(Rect global, {List<Rect> except = const []}) {
    final p = pixels;
    if (p == null || boundary == null) return null;
    final local = _toBoundary(global);
    final ink = p.inkIn(
      local,
      over: p.groundAround(local, 2),
      except: [for (final r in except) _toBoundary(r)],
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
  CapCentred? _capCentred(RenderBox p) {
    RenderObject? up = p.parent;
    while (up != null && up != boundary) {
      if (up case final CapCentred centred) return centred;
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
    final own = _ink(
      r,
      except: [for (final p in _shownIn(holder)) _global(p), ..._shownOver(r)],
    );
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

// The boxes of the DesignKeylineRegions under [context], with them.
Map<RenderBox, DesignKeylineRegion> _regionBoxes(BuildContext context) {
  final found = <RenderBox, DesignKeylineRegion>{};
  void visit(Element element) {
    if (element.widget case final DesignKeylineRegion region) {
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
DesignKeylineRegion? _regionOf(
  RenderObject node,
  Map<RenderBox, DesignKeylineRegion> regions,
) {
  for (RenderObject? up = node; up != null; up = up.parent) {
    if (regions[up] case final region?) return region;
  }
  return null;
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
// it paints (its cache extent) or kept alive off screen. Laid out, such a
// child is not on screen, so no check reads it.
bool _paints(RenderObject parent, RenderObject child) => switch (parent) {
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
  final DesignKeylineRegion region;
  final String name;
  final RenderBox box;
  final TextDirection direction;
  final Map<RenderBox, DesignKeylineRegion> named;
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

// Reads one control's labels against its face.
class _LabelReader extends _DrawnReader {
  _LabelReader(this.check, super.boundary, super.pixels, super.marked);

  final DesignLabelCheck check;

  // Each control whose text is drawn in the test's fallback font, by name.
  final fallback = <String>[];

  List<String> problems(
    RenderBox control,
    List<RenderBox> texts, [
    List<RenderBox> marks = const [],
  ]) {
    final face = _face(control);
    if (face == null) return const [];
    final faceRect = face.rect;
    final shown = [
      for (final t in texts)
        if (_onFace(t, faceRect) && !_inBadge(t, control, face.box, faceRect))
          _TextBox(t, icon: isIconGlyph(_plain(t))),
    ];
    if (shown.isEmpty || shown.any((t) => !t.oneLine)) return const [];
    // One line: the texts share a row.
    final boxes = [for (final t in shown) _global(t.box)];
    final top = boxes.map((b) => b.top).reduce(math.max);
    final bottom = boxes.map((b) => b.bottom).reduce(math.min);
    if (bottom <= top) return const [];
    final p = pixels!;
    final faceColour = _faceGround(
      faceRect,
      boxes.reduce((a, b) => a.expandToInclude(b)),
    );
    final name = _nameOf(control);
    // Drawn in the test font, no offset means anything.
    for (final t in shown) {
      if (t.box case final RenderParagraph paragraph
          when _testFontBox(paragraph, faceColour)) {
        fallback.add(name);
        return const [];
      }
    }
    // What the label is held to, in the image's pixels, as drawn and as
    // laid out: its face's middle, or, beside a text entry of more than one
    // line (a note field), the capitals of the entry's first line, which a
    // label beside it stands on.
    var middleDrawn = _toBoundary(_band(face)).center.dy * p.ratio;
    var middleLaid = middleDrawn;
    var against = 'the middle of its face';
    final entry = _growingEntryBeside(
      control,
      boxes.reduce((a, b) => a.expandToInclude(b)),
    );
    if (entry != null) {
      final first = _capitals(entry, faceColour);
      if (first == null) return const [];
      middleDrawn = first.drawn;
      middleLaid = first.laid ?? first.drawn;
      against = 'the capitals of the first line of the text entry beside it';
    }
    final found = <String>[];
    final drawnTolerance = check.drawnTolerance;
    final measured = <_TextBox>{};
    ({_TextBox text, double middle})? caps;
    for (final t in shown) {
      if (t.icon || t.box is! RenderParagraph) continue;
      // Words over or under a picture (an icon tile's name) are placed.
      if (_byPicture(control, _global(t.box))) continue;
      final c = _capitals(t.box as RenderParagraph, faceColour);
      if (c == null) continue;
      measured.add(t);
      caps ??= (text: t, middle: c.drawn);
      final words = '"${_short(_plain(t.box))}"';
      final drawn = c.drawn - middleDrawn;
      // Far from the middle, it is placed, not centred (a card's title).
      if (drawn.abs() / p.ratio > faceRect.height / 4) continue;
      if (drawnTolerance != null) {
        final (read, given) = (c.read, c.given);
        // A cap height that moves the middle more than the tolerance, beyond
        // the pixel a hinting engine may snap the capitals' top by.
        if (read != null &&
            given != null &&
            (read - given).abs() > 2 * drawnTolerance + 1) {
          found.add(
            '$name: the capitals of $words are drawn '
            '${read.toStringAsFixed(1)} device px high; its DesignCapCenter\'s '
            'capHeightFactor gives ${given.toStringAsFixed(1)}',
          );
        }
        if (drawn.abs() > drawnTolerance) {
          found.add(
            '$name: the capitals of $words are drawn ${_devicePx(drawn)} '
            '$against',
          );
        }
        continue;
      }
      final d = drawn / p.ratio;
      final laid = c.laid;
      if (laid == null) {
        // A widget inline: how much of the offset is the engine's rounding
        // (up to half a logical and half a device pixel) is not known.
        if (d.abs() <= check.tolerance + 0.5 + 0.5 / p.ratio) continue;
        found.add(
          '$name: the label $words is ${_px(d, signed: true)} $against as '
          'drawn, more than the engine\'s rounding of a line holding a '
          'widget',
        );
        continue;
      }
      final laidOut = (laid - middleLaid) / p.ratio;
      if (laidOut.abs() <= check.tolerance) continue;
      found.add(
        '$name: the label $words is ${_against(laidOut, against)} as laid '
        'out, '
        '${_zero(d) ? 'on it' : _px(d, signed: true)} as drawn',
      );
    }
    if (drawnTolerance != null && caps != null) {
      for (final t in shown) {
        if (!t.icon || t.box is! RenderParagraph) continue;
        final m = _glyphMiddle(t.box as RenderParagraph);
        if (m == null) continue;
        final off = m - caps.middle;
        if (off.abs() <= drawnTolerance + 0.5) continue;
        found.add(
          '$name: its icon is drawn ${_devicePx(off)} the capitals of '
          '"${_short(_plain(caps.text.box))}"',
        );
      }
    }
    // Icons, and words whose capitals cannot be read, by their ink.
    final toGlobal = boundary!.getTransformTo(null);
    final middle = MatrixUtils.transformPoint(
      toGlobal,
      Offset(0, middleLaid / p.ratio),
    ).dy;
    for (final t in shown) {
      if (measured.contains(t)) continue;
      if (!t.icon && _byPicture(control, _global(t.box))) continue;
      final box = t.box;
      double y(double local) => box.localToGlobal(Offset(0, local)).dy;
      final baseline = t.baseline;
      final rounding = baseline == null
          ? 0.0
          : y((baseline + 0.5).floorToDouble()) - y(baseline);
      final rect = _global(box).shift(Offset(0, rounding));
      final rows = p.inkRows(_toBoundary(rect), over: faceColour);
      if (rows == null) continue;
      final ink = MatrixUtils.transformRect(
        toGlobal,
        Rect.fromLTRB(0, rows.top, 1, rows.bottom),
      );
      final drawn = ink.center.dy - middle;
      final laidOut = drawn - rounding;
      // Far from the middle, it is placed, not centred (a card's title).
      if (laidOut.abs() <= check.tolerance ||
          laidOut.abs() > faceRect.height / 4) {
        continue;
      }
      final what = t.icon ? 'its icon' : 'the label "${_short(_plain(box))}"';
      found.add(
        '$name: $what is ${_against(laidOut, against)} as laid out, '
        '${_zero(drawn) ? 'on it' : _px(drawn, signed: true)} as drawn',
      );
    }
    found.addAll(
      _leadingMarks(
        control,
        face,
        marks,
        shown,
        faceColour,
        middle,
        caps,
        against,
      ),
    );
    return found;
  }

  // A painted mark that starts the row of [control]'s words (a way back's
  // triangle before "Back"), held as an icon there is: its ink's middle on
  // the words' capitals within the drawn tolerance and half a device pixel,
  // else on [middle] (global, as laid out) within the tolerance. However
  // far off, it starts their row and is never placed. A mark as large as
  // half the face is the face, not a mark on it.
  List<String> _leadingMarks(
    RenderBox control,
    ({Rect rect, RenderBox box, bool read}) face,
    List<RenderBox> marks,
    List<_TextBox> shown,
    int faceColour,
    double middle,
    ({_TextBox text, double middle})? caps,
    String against,
  ) {
    final words = [
      for (final t in shown)
        if (!t.icon && t.box is RenderParagraph) t.box as RenderParagraph,
    ];
    if (marks.isEmpty || words.isEmpty) return const [];
    final p = pixels!;
    final rtl = words.first.textDirection == TextDirection.rtl;
    final line = words.map(_global).reduce((a, b) => a.expandToInclude(b));
    final half = face.rect.width * face.rect.height / 2;
    final name = _nameOf(control);
    final found = <String>[];
    for (final mark in marks) {
      if (identical(mark, face.box)) continue;
      final r = _global(mark);
      if (r.width * r.height >= half) continue;
      final leads = rtl
          ? r.left >= line.right - 0.5
          : r.right <= line.left + 0.5;
      if (!leads || !face.rect.inflate(0.5).overlaps(r)) continue;
      final rows = p.inkRows(_toBoundary(r), over: faceColour);
      if (rows == null) continue;
      final drawnTolerance = check.drawnTolerance;
      if (drawnTolerance != null && caps != null) {
        final off = (rows.top + rows.bottom) / 2 * p.ratio - caps.middle;
        if (off.abs() <= drawnTolerance + 0.5) continue;
        found.add(
          '$name: its painted mark, before its words, is drawn '
          '${_devicePx(off)} the capitals of "${_short(_plain(caps.text.box))}"',
        );
        continue;
      }
      final ink = MatrixUtils.transformRect(
        boundary!.getTransformTo(null),
        Rect.fromLTRB(0, rows.top, 1, rows.bottom),
      );
      final off = ink.center.dy - middle;
      if (off.abs() <= check.tolerance) continue;
      found.add(
        '$name: its painted mark, before its words, is '
        '${_px(off, signed: true)} $against as drawn',
      );
    }
    return found;
  }

  // A chosen control's fill behind its words, held to its cell. Among
  // controls of its kind beside or over it none of which, unchosen, shows a
  // face of its own (a toggle group's cells in a trough, a drawer's
  // destinations), the cell a person sees is its slot: the box the layout
  // holding them gives it (a drawer's row, however tight its pressable).
  // The fill is the colour its words stand on (its own, or drawn over it
  // from beside it in the slot) where it differs from what is round the slot,
  // read out to where that colour ends; it may stand short of the slot's
  // width or height by a quarter of its height at most.
  List<String> chosenFill(RenderBox control) {
    if (!_chosen(control)) return const [];
    String kindOf(RenderBox c) => _nameOf(c).split(' "').first;
    final kind = kindOf(control);
    List<RenderBox>? others;
    RenderBox? slot;
    RenderObject below = control;
    for (RenderObject? up = control.parent; up != null; up = up.parent) {
      if (identical(up, boundary)) return const [];
      final under = _controlsUnder(up);
      if (under.length >= 2) {
        others = [
          for (final c in under)
            if (!identical(c, control) && kindOf(c) == kind && !_chosen(c)) c,
        ];
        slot = below is RenderBox && below.hasSize ? below : control;
        break;
      }
      below = up;
    }
    if (others == null || others.isEmpty || slot == null) return const [];
    if (others.any((c) => _face(c) != null)) return const [];
    final words = <Rect>[];
    void visit(RenderObject n) {
      if (!identical(n, control) && _isControl(n)) return;
      if (n is RenderParagraph &&
          n.hasSize &&
          !isIconGlyph(_plain(n)) &&
          _plain(n).trim().isNotEmpty &&
          isOneLine(n)) {
        words.add(_global(n));
      }
      _visitShown(n, visit);
    }

    visit(slot);
    if (words.isEmpty) return const [];
    final p = pixels!;
    final cell = _toBoundary(_global(slot));
    final on = _toBoundary(words.reduce((a, b) => a.expandToInclude(b)));
    // What the words stand on: the commonest colour in their own box (a
    // marker may be no taller than their line).
    final fill = p.groundIn(on);
    if (DrawnPixels.alike(fill, p.groundAround(cell, 2), by: 16)) {
      return const [];
    }
    final reach = p.fillRound(on, cell, colour: fill);
    if (reach == null) return const [];
    final round = reach.inflate(1);
    if (!round.contains(on.topLeft) || !round.contains(on.bottomRight)) {
      return const [];
    }
    // A mark as wide as it is tall (a calendar day's round mark) is the
    // cell the eye sees in a grid of figures.
    if ((reach.width - reach.height).abs() <= 2) return const [];
    final slack = cell.height / 4;
    if (cell.width - reach.width <= slack &&
        cell.height - reach.height <= slack) {
      return const [];
    }
    return [
      '${_nameOf(control)}: its chosen fill is ${_px(reach.width)} by '
          '${_px(reach.height)} px in its cell of ${_px(cell.width)} by '
          '${_px(cell.height)}; the chosen ground fills the cell, to '
          '${_px(slack)} px short',
    ];
  }

  // Whether [control] says it is chosen: selected, toggled on or checked,
  // on it or a box under it short of another control.
  static bool _chosen(RenderBox control) {
    var chosen = false;
    void visit(RenderObject n) {
      if (chosen) return;
      if (!identical(n, control) && _isControl(n)) return;
      if (n case RenderSemanticsAnnotations(:final properties)
          when properties.selected == true ||
              properties.toggled == true ||
              properties.checked == true) {
        chosen = true;
        return;
      }
      n.visitChildren(visit);
    }

    visit(control);
    return chosen;
  }

  static String _devicePx(double v) {
    final s = v.abs().toStringAsFixed(1);
    return '$s device px ${v > 0 ? 'below' : 'above'}';
  }

  static bool _zero(double v) => _px(v).replaceFirst('-', '') == '0';

  // What the eye centres a label in on [face] (global): its box, less a
  // rule drawn along one side only (a list row's foot), which a box
  // decoration lays its child out inside of and is not part of the band.
  Rect _band(({Rect rect, RenderBox box, bool read}) face) {
    final box = face.box;
    if (face.read || box is! RenderDecoratedBox || !box.hasSize) {
      return face.rect;
    }
    final d = box.decoration;
    if (d is! BoxDecoration || box.position != DecorationPosition.background) {
      return face.rect;
    }
    final edges = d.padding.resolve(TextDirection.ltr);
    if ((edges.top - edges.bottom).abs() < 0.01 || box.size.height <= 0) {
      return face.rect;
    }
    final r = face.rect;
    final s = r.height / box.size.height;
    return Rect.fromLTRB(
      r.left,
      r.top + edges.top * s,
      r.right,
      r.bottom - edges.bottom * s,
    );
  }

  static String _against(double v, String what) =>
      _zero(v) ? 'on $what' : '${_px(v, signed: true)} $what';

  // The text entry of more than one line under [control] beside [label]
  // (global): level with it, to one side. Null without one.
  RenderEditable? _growingEntryBeside(RenderBox control, Rect label) {
    RenderEditable? found;
    void visit(RenderObject n) {
      if (found != null) return;
      if (n is RenderEditable && n.hasSize && n.maxLines != 1) {
        final r = _global(n);
        if (r.top < label.bottom &&
            r.bottom > label.top &&
            (r.left >= label.right || r.right <= label.left)) {
          found = n;
          return;
        }
      }
      _visitShown(n, visit);
    }

    _visitShown(control, visit);
    return found;
  }

  static String _plain(RenderBox b) => b is RenderParagraph
      ? b.text.toPlainText(includeSemanticsLabels: false).trim()
      : '';

  static String _short(String s) =>
      s.length > 24 ? '${s.substring(0, 23)}…' : s;

  // Whether [t]'s middle is on the face.
  bool _onFace(RenderBox t, Rect face) => face.contains(_global(t).center);
}

// Reads one row of controls by their drawn outlines.
// A control in a row with a face of its own: its face as laid out and its
// outline as drawn (global).
typedef _RowFace = ({RenderBox control, Rect laid, Rect drawn});

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
      final drawn = marked.contains(face.box)
          ? null
          : _outline(face.rect, c, face.read ? null : face.box, ground);
      // What shows of it is a mark on it, its middle left out (a tab's
      // indicator line, a badge, a sliver of a state layer): no face.
      if (drawn != null && !drawn.inflate(1).contains(face.rect.center)) {
        faceless.add(c);
        continue;
      }
      faces.add((control: c, laid: face.rect, drawn: drawn ?? face.rect));
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
        for (final (edge, laid, drawn) in [
          ('top', f.laid.top - held.laid.top, f.drawn.top - held.drawn.top),
          (
            'bottom',
            f.laid.bottom - held.laid.bottom,
            f.drawn.bottom - held.drawn.bottom,
          ),
        ]) {
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
        for (final t in _shownOver(face)) _toBoundary(t).inflate(2),
      ],
      shape: shape?.transform(box!.getTransformTo(b).storage),
    );
    return o == null
        ? null
        : MatrixUtils.transformRect(b.getTransformTo(null), o);
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
