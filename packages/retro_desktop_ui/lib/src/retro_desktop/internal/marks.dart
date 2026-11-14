// The period's own pictures for an alert and for work in progress, drawn in whole cells on the device's grid: the note
// balloon, the caution triangle and the stop sign an alert box opened with, and the wristwatch (Platinum) or the
// hourglass (Chisel) the pointer turned into while the machine was busy. They are pictures in their own inks (the alert
// inks of [RetroDesktopIllustrationColors]), as the period's icons were, not glyphs in the text colour.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../glyphs.dart';
import '../pixels.dart';
import '../theme.dart';
import '../tone.dart';

/// Draws [rows] (one character a cell, `.` empty) in [inks], centred in its box, in whole cells where the box allows.
class RetroDesktopArtPainter extends RetroDesktopPixelPainter {
  /// Creates a [RetroDesktopArtPainter].
  const RetroDesktopArtPainter(this.rows, this.inks);

  /// The picture, one string a row, one character a cell.
  final List<String> rows;

  /// The colour each character stands for; a character without one is left empty.
  final Map<String, Color> inks;

  @override
  void paint(RetroDesktopPixelGrid px, Size size) {
    final n = rows.length;
    final across = rows.fold<int>(0, (m, r) => math.max(m, r.length));
    final fit = math.min(size.width / across, size.height / n);
    final cell = fit >= 1 ? fit.floorToDouble() : fit;
    final ox = ((size.width - cell * across) / 2).roundToDouble();
    final oy = ((size.height - cell * n) / 2).roundToDouble();
    for (var y = 0; y < n; y++) {
      final row = rows[y];
      var x = 0;
      while (x < row.length) {
        final ink = inks[row[x]];
        var end = x + 1;
        while (end < row.length && row[end] == row[x]) {
          end++;
        }
        if (ink != null) {
          px.fill(
            Rect.fromLTRB(
              ox + x * cell,
              oy + y * cell,
              ox + end * cell,
              oy + (y + 1) * cell,
            ),
            ink,
          );
        }
        x = end;
      }
    }
  }

  @override
  bool shouldRepaint(RetroDesktopArtPainter old) {
    if (old.rows.length != rows.length || old.inks.length != inks.length) {
      return true;
    }
    for (var i = 0; i < rows.length; i++) {
      if (old.rows[i] != rows[i]) {
        return true;
      }
    }
    for (final MapEntry(:key, :value) in inks.entries) {
      if (old.inks[key] != value) {
        return true;
      }
    }
    return false;
  }
}

const _caution = [
  '.......kk.......',
  '......kyyk......',
  '......kyyk......',
  '.....kyyyyk.....',
  '.....kykkyk.....',
  '....kyykkyyk....',
  '....kyykkyyk....',
  '...kyyykkyyyk...',
  '...kyyykkyyyk...',
  '..kyyyyyyyyyyk..',
  '..kyyyykkyyyyk..',
  '.kyyyyykkyyyyyk.',
  '.kyyyyyyyyyyyyk.',
  'kyyyyyyyyyyyyyyk',
  'kkkkkkkkkkkkkkkk',
  '................',
];

const _note = [
  '..kkkkkkkkkkkk..',
  '.kwwwwwwwwwwwwk.',
  'kwwwwwwbbwwwwwwk',
  'kwwwwwwbbwwwwwwk',
  'kwwwwwwwwwwwwwwk',
  'kwwwwwbbbwwwwwwk',
  'kwwwwwwbbwwwwwwk',
  'kwwwwwwbbwwwwwwk',
  'kwwwwwwbbwwwwwwk',
  'kwwwwwbbbbwwwwwk',
  '.kwwwwwwwwwwwwk.',
  '..kkkwwkkkkkkk..',
  '....kwwk........',
  '...kwwk.........',
  '...kkk..........',
  '................',
];

const _done = [
  '..kkkkkkkkkkkk..',
  '.kwwwwwwwwwwwwk.',
  'kwwwwwwwwwwwwwwk',
  'kwwwwwwwwwwwbbwk',
  'kwwwwwwwwwwbbwwk',
  'kwwbbwwwwwbbwwwk',
  'kwwwbbwwwbbwwwwk',
  'kwwwwbbwbbwwwwwk',
  'kwwwwwbbbwwwwwwk',
  'kwwwwwwbwwwwwwwk',
  '.kwwwwwwwwwwwwk.',
  '..kkkwwkkkkkkk..',
  '....kwwk........',
  '...kwwk.........',
  '...kkk..........',
  '................',
];

// The stop sign: Platinum's octagon, Chisel's disc, a white cross on red.
List<String> _stop(bool octagon) => [
  for (var y = 0; y < 16; y++)
    [
      for (var x = 0; x < 16; x++)
        () {
          final dx = (x + .5 - 8).abs(), dy = (y + .5 - 8).abs();
          bool inside(double r) => octagon
              ? dx <= r && dy <= r && dx + dy <= r * 1.42
              : dx * dx + dy * dy <= r * r;
          if (!inside(7.6)) {
            return '.';
          }
          if (!inside(6.6)) {
            return 'k';
          }
          if ((dx - dy).abs() < .9 && dx < 4) {
            return 'w';
          }
          return 'r';
        }(),
    ].join(),
];

final _stopOctagon = _stop(true);
final _stopDisc = _stop(false);

/// The picture an alert of [tone] opens with, [size] square: the note balloon (information), the balloon with a tick
/// (success), the caution triangle (warning) or the stop sign (danger), in [t]'s appearance and alert inks.
Widget retroDesktopAlertArt(
  RetroDesktopThemeData t,
  RetroDesktopTone tone, {
  double size = 32,
}) {
  final rows = switch (tone) {
    RetroDesktopTone.info => _note,
    RetroDesktopTone.success => _done,
    RetroDesktopTone.warning => _caution,
    RetroDesktopTone.danger => t.chisel ? _stopDisc : _stopOctagon,
  };
  final inks = t.colors.illustration;
  return ExcludeSemantics(
    child: RetroDesktopPixelPaint(
      painter: RetroDesktopArtPainter(rows, {
        'k': const Color(0xff000000),
        'w': const Color(0xffffffff),
        'y': inks.caution,
        'r': inks.stop,
        'b': inks.note,
      }),
      child: SizedBox.square(dimension: size),
    ),
  );
}

/// The tone an alert glyph stands for, or null for any other glyph: an alert given one of these opens with its picture.
RetroDesktopTone? retroDesktopToneOfGlyph(IconData icon) =>
    icon == RetroDesktopGlyphs.info
    ? RetroDesktopTone.info
    : icon == RetroDesktopGlyphs.circleCheck
    ? RetroDesktopTone.success
    : icon == RetroDesktopGlyphs.triangleAlert
    ? RetroDesktopTone.warning
    : icon == RetroDesktopGlyphs.circleAlert
    ? RetroDesktopTone.danger
    : null;

const _watch = [
  '.....kkkkkk.....',
  '.....kggggk.....',
  '....kkkkkkkk....',
  '...kwwwwwwwwk...',
  '..kwwwwwwwwwwk..',
  '.kwwwwwwwwwwwwk.',
  '.kwwwwwwwwwwwwk.',
  '.kwwwwwwwwwwwwkk',
  '.kwwwwwwwwwwwwkk',
  '.kwwwwwwwwwwwwk.',
  '.kwwwwwwwwwwwwk.',
  '..kwwwwwwwwwwk..',
  '...kwwwwwwwwk...',
  '....kkkkkkkk....',
  '.....kggggk.....',
  '.....kkkkkk.....',
];

const _glass = [
  '.kkkkkkkkkkkkkk.',
  '.kggggggggggggk.',
  '.kkkkkkkkkkkkkk.',
  '..kwwwwwwwwwwk..',
  '..kwwwwwwwwwwk..',
  '...kwwwwwwwwk...',
  '....kwwwwwwk....',
  '.....kwwwwk.....',
  '.....kwwwwk.....',
  '....kwwwwwwk....',
  '...kwwwwwwwwk...',
  '..kwwwwwwwwwwk..',
  '..kwwwwwwwwwwk..',
  '.kkkkkkkkkkkkkk.',
  '.kggggggggggggk.',
  '.kkkkkkkkkkkkkk.',
];

/// The busy pointer as a picture, at [progress] (0 to 1) of its turn: Platinum's wristwatch, its long hand swept that
/// far round from twelve, or Chisel's hourglass, that much of its sand run through.
List<String> retroDesktopBusyRows({
  required bool chisel,
  required double progress,
}) {
  final p = progress.clamp(0.0, 1.0);
  final rows = [for (final r in chisel ? _glass : _watch) r.split('')];
  void put(int x, int y, String ink) {
    if (y >= 0 &&
        y < rows.length &&
        x >= 0 &&
        x < rows[y].length &&
        rows[y][x] == 'w') {
      rows[y][x] = ink;
    }
  }

  if (!chisel) {
    // The short hand stands at ten, the long one sweeps; both from the face's middle.
    void hand(double turn, double length, String ink) {
      final a = turn * 2 * math.pi;
      for (var r = 0.0; r <= length; r += .5) {
        put(
          (7.5 + r * math.sin(a)).floor(),
          (7.5 - r * math.cos(a)).floor(),
          ink,
        );
      }
    }

    hand(10 / 12, 2.6, 'k');
    hand(p, 4.6, 'm');
  } else {
    // The sand rests on the neck above and piles from the foot below; a grain falls through while it runs.
    const top = [7, 6, 5, 4, 3], foot = [12, 11, 10, 9, 8];
    const grains = 24;
    final below = (grains * p).round(), above = grains - below;
    void pour(List<int> order, int count) {
      var left = count;
      for (final y in order) {
        final cells = [
          for (var x = 0; x < 16; x++)
            if (rows[y][x] == 'w') x,
        ]..sort((a, b) => (a - 7.5).abs().compareTo((b - 7.5).abs()));
        for (final x in cells) {
          if (left == 0) {
            return;
          }
          rows[y][x] = 'm';
          left--;
        }
      }
    }

    pour(top, above);
    pour(foot, below);
    if (above > 0 && below < grains) {
      put(7, 8, 'm');
      put(8, 9, 'm');
    }
  }
  return [for (final r in rows) r.join()];
}
