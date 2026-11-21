/// Checks of what is wrong in any design, so they hold for every look:
/// behaviour and accessibility (a checkable control's role, a radio group's
/// keys, a field's semantics, a label on its face's middle, tap targets,
/// cursors, a text field's name) and breakage (words clipped or broken
/// mid-word, a shadow cut off by a clip, content overflowing its box).
///
/// Test support, nothing an app runs. Each check reports what it finds as a
/// [DesignAlignmentReport], and says in its doc whether it reads layout
/// boxes and semantics or, where only they show it, the drawn pixels. A
/// look's own grid and taste (its rows, keylines, widths and spacing) are
/// not checked here: every design is different.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show CheckedState, SemanticsInputType, Tristate;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:ui_core/ui_core.dart';

import 'internal/drawn_pixels.dart';
import 'internal/label_line.dart';

part 'checks/checkable_check.dart';
part 'checks/cursor_check.dart';
part 'checks/field_semantics_check.dart';
part 'checks/radio_group_check.dart';
part 'checks/shadow_clip_check.dart';
part 'checks/shared/reading.dart';
part 'checks/shared/shape.dart';
part 'checks/tap_target_check.dart';
part 'checks/text_field_name_check.dart';

/// Puts [child] where a look's page would have it: under the look's theme
/// and, for a Material look, a `Material`.
typedef DesignAlignmentTheme = Widget Function(
  BuildContext context,
  Widget child,
);

/// What a check found: one line per problem, and the advisories a check
/// reports without failing (a rule still learning its cases).
@immutable
class DesignAlignmentReport {
  /// A report on [look] listing [problems], and [advisories] beside them.
  const DesignAlignmentReport(
    this.look,
    this.problems, {
    this.advisories = const [],
  });

  /// The look checked.
  final String look;

  /// One line per problem, each naming the size, the theme, the platform
  /// and the control.
  final List<String> problems;

  /// One line per advisory: reported for a person to look at, never failing
  /// [verify].
  final List<String> advisories;

  /// Whether nothing is out of line.
  bool get isAligned => problems.isEmpty;

  /// Throws a [DesignAlignmentError] listing the problems, if there are any.
  /// [advisories] never throw.
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

/// Whether the words and the icon each control on a screen shows sit on
/// the middle of its face, up and down, as they are drawn, and a chosen
/// control's fill fills its cell.
///
/// It needs no list of controls. Every control on the screen (a button, a
/// link, a toggle, a field, or anything with a tap action) that draws a
/// face and holds one line of words, an icon, or both on one line is
/// checked, so a control no list names (a split button, a gallery page's
/// own) is checked too. The face is the largest box inside the control that
/// paints, not its tap box or a shadow outside it. Left out: a control
/// without a face (a text button), one whose words run to a second line or
/// that holds two lines (a title and a subtitle), one holding a text entry
/// (its words are typed, not placed), a label inside a smaller face of
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
///
/// It reads layout boxes, and the drawn pixels where only they show it (a
/// face's painted edge, a label's and an icon's ink), so it takes the tester's
/// `runAsync`.
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
  /// each density the look ships, by name ("standard", "compact"). A test
  /// passes its tester's
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
///
/// It reads each paragraph's laid-out lines, and no pixels.
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
///
/// It reads layout boxes and the clips over them, and no pixels.
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
    final cell = _toBoundary(
      _semanticsOf(control).tab
          ? MatrixUtils.transformRect(
              slot.getTransformTo(null),
              RenderTapTargetPadding.faceRectOf(slot),
            )
          : _global(slot),
    );
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
