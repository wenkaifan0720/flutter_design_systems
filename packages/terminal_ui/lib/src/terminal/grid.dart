/// The cell grid: the one lattice every Terminal part is sized and placed on.
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'fonts.dart';

/// One cell of the character grid, and the arithmetic of whole cells.
///
/// A cell is one character wide (the face's advance: 600/1000 em for
/// JetBrains Mono, so 9 px at 15 px) and one line tall (24 px). Every
/// Terminal part takes a whole number of cells across ([cols]) and a whole
/// number of lines down ([lines]), so every part lines up with every other
/// on one lattice, at any text size: `context.termGrid` is the theme's grid
/// grown by the reader's text scale.
///
/// ```dart
/// final grid = context.termGrid;
/// SizedBox(width: grid.cols(12), height: grid.lines(2));
/// ```
@immutable
class TermGrid with Diagnosticable {
  /// A grid of [fontSize] words on lines [lineHeight] tall, in Terminal's
  /// face (its advance, 0.6 em). The cell's width is the face's: a theme
  /// with another face gives its grid that face's advance
  /// ([TermGrid.forFace]), so the advance is never set on its own.
  const TermGrid({this.fontSize = 15, this.lineHeight = 24})
    : assert(fontSize > 0),
      assert(lineHeight >= fontSize),
      advance = 0.6,
      _face = null;

  const TermGrid._(this.fontSize, this.lineHeight, this.advance, this._face);

  /// This grid set in [face]: its cell as wide as the face's advance, and
  /// the words [widthOf] measures set in the face and its fallbacks.
  TermGrid forFace(TermFace face) => face == _face
      ? this
      : TermGrid._(fontSize, lineHeight, face.advance, face);

  // The face [forFace] set, or null for Terminal's own.
  final TermFace? _face;

  /// The size of every word, in logical pixels.
  final double fontSize;

  /// The height of one line, in logical pixels.
  final double lineHeight;

  /// The face's advance, as a fraction of [fontSize]: one character's width.
  final double advance;

  /// One cell's width: one character.
  double get cellWidth => fontSize * advance;

  /// One cell's size.
  Size get cell => Size(cellWidth, lineHeight);

  /// The line height as a multiple of the font size: what a [TextStyle]'s
  /// `height` takes so a line of words is exactly one line of the grid.
  double get heightFactor => lineHeight / fontSize;

  /// [n] cells across, in logical pixels.
  double cols(num n) => n * cellWidth;

  /// [n] lines down, in logical pixels.
  double lines(num n) => n * lineHeight;

  /// How many whole cells fit in [width].
  int colsIn(double width) => (width / cellWidth + 1e-6).floor();

  /// How many whole lines fit in [height].
  int linesIn(double height) => (height / lineHeight + 1e-6).floor();

  /// [width] rounded up to whole cells.
  double ceilToCols(double width) =>
      cols(math.max(0, (width / cellWidth - 1e-6).ceil()));

  /// [height] rounded up to whole lines.
  double ceilToLines(double height) =>
      lines(math.max(0, (height / lineHeight - 1e-6).ceil()));

  /// [size] rounded up to whole cells and whole lines.
  Size ceil(Size size) =>
      Size(ceilToCols(size.width), ceilToLines(size.height));

  /// The width of [text] set in this grid's face, rounded up to whole
  /// cells: each character the face draws is a cell (a wide CJK glyph two; a
  /// direction mark or isolate none), and a run of letters no Terminal face
  /// draws (Arabic, the Indic scripts, Thai, ...: the platform draws them in
  /// a proportional face) is measured as it is drawn now. Where that face
  /// arrives late (the web fetches it once a word needs it), [TermTheme]
  /// builds what reads its grid again, and this measures the face that came.
  double widthOf(String text) {
    var count = 0;
    var drawn = 0.0;
    final run = StringBuffer();
    void close() {
      if (run.isEmpty) return;
      drawn += _measure(run.toString());
      run.clear();
    }

    for (final rune in text.runes) {
      if (_isFormat(rune)) {
        // A joiner or a mark inside a run shapes it; elsewhere it is nothing.
        if (run.isNotEmpty) run.writeCharCode(rune);
        continue;
      }
      if (_isProportional(rune)) {
        run.writeCharCode(rune);
        continue;
      }
      close();
      count += _isWide(rune) ? 2 : 1;
    }
    close();
    return drawn == 0 ? cols(count) : ceilToCols(cols(count) + drawn);
  }

  // [run]'s width at this grid's size, set as the theme sets its words: in
  // the face and its fallbacks, then the platform's face for the script.
  // Measured each time, never kept: on the web the script's face arrives
  // after the first frame, and a width kept from before it would stand.
  double _measure(String run) {
    final face = _face ?? TermFace.jetBrainsMono;
    final painter = TextPainter(
      text: TextSpan(
        text: run,
        style: TextStyle(
          fontFamily: face.family,
          fontFamilyFallback: face.fallback,
          package: face.package,
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  // A letter of a script no Terminal face draws: Armenian, Arabic, Syriac,
  // Thaana, N'Ko, the Indic scripts, Thai, Lao, Tibetan, Myanmar, Georgian,
  // Ethiopic and on to Mongolian, and Arabic's presentation forms. Hebrew is
  // not one: Liberation Mono, the face's fallback, draws it on the cell.
  static bool _isProportional(int rune) =>
      (rune >= 0x0530 && rune <= 0x058F) ||
      (rune >= 0x0600 && rune <= 0x10FF) ||
      (rune >= 0x1160 && rune <= 0x18AF) ||
      (rune >= 0xFB50 && rune <= 0xFDFF) ||
      (rune >= 0xFE70 && rune <= 0xFEFC);

  /// [text] whole where it fits in [width] (or [width] is unbounded), else
  /// cut to the whole characters that fit and an ellipsis (`…`), as a
  /// border's title or a window's name is cut when the line runs out.
  String fit(String text, double width) {
    if (!width.isFinite || widthOf(text) <= width) return text;
    final characters = text.characters.toList();
    for (var n = characters.length - 1; n > 0; n--) {
      final cut = '${characters.take(n).join().trimRight()}…';
      if (widthOf(cut) <= width) return cut;
    }
    return widthOf('…') <= width ? '…' : '';
  }

  static bool _isFormat(int rune) =>
      rune == 0x061C ||
      (rune >= 0x200B && rune <= 0x200F) ||
      (rune >= 0x202A && rune <= 0x202E) ||
      (rune >= 0x2060 && rune <= 0x2069) ||
      rune == 0xFEFF;

  static bool _isWide(int rune) =>
      (rune >= 0x1100 && rune <= 0x115F) ||
      (rune >= 0x2E80 && rune <= 0xA4CF) ||
      (rune >= 0xAC00 && rune <= 0xD7A3) ||
      (rune >= 0xF900 && rune <= 0xFAFF) ||
      (rune >= 0xFE30 && rune <= 0xFE4F) ||
      (rune >= 0xFF00 && rune <= 0xFF60) ||
      (rune >= 0xFFE0 && rune <= 0xFFE6) ||
      (rune >= 0x1F300 && rune <= 0x1FAFF);

  /// This grid grown by [factor]: the words, the cell and the line together.
  TermGrid scaled(double factor) => factor == 1
      ? this
      : TermGrid._(fontSize * factor, lineHeight * factor, advance, _face);

  /// The theme's grid at [context], grown by the text scale the reader
  /// chose: every cell and line grows with the words, so layouts reflow by
  /// whole cells.
  static TermGrid of(BuildContext context, TermGrid base) {
    final factor =
        MediaQuery.textScalerOf(context).scale(base.fontSize) / base.fontSize;
    return base.scaled(factor);
  }

  /// This grid with the given fields changed.
  TermGrid copyWith({double? fontSize, double? lineHeight}) => TermGrid._(
    fontSize ?? this.fontSize,
    lineHeight ?? this.lineHeight,
    advance,
    _face,
  );

  /// The grid [t] of the way from [a] to [b].
  static TermGrid lerp(TermGrid a, TermGrid b, double t) {
    if (identical(a, b)) return a;
    return TermGrid._(
      lerpDouble(a.fontSize, b.fontSize, t)!,
      lerpDouble(a.lineHeight, b.lineHeight, t)!,
      lerpDouble(a.advance, b.advance, t)!,
      t < 0.5 ? a._face : b._face,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TermGrid &&
      other.fontSize == fontSize &&
      other.lineHeight == lineHeight &&
      other.advance == advance &&
      other._face == _face;

  @override
  int get hashCode => Object.hash(fontSize, lineHeight, advance, _face);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('fontSize', fontSize, defaultValue: 15.0))
      ..add(DoubleProperty('lineHeight', lineHeight, defaultValue: 24.0))
      ..add(DoubleProperty('advance', advance, defaultValue: 0.6));
  }
}
