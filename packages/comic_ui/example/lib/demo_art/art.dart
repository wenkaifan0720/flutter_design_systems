// The drawn things: plain shapes in ink, read from compact strings so a page never hand-draws. A drawing's colours are the
// print run's, so every preset and mode recolours it. `ComicMark` is an object by name, `ComicBust` a head and shoulders.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'art_data.dart';

import 'package:comic_ui/comic_parts.dart';

class _Op {
  const _Op(
    this.fill,
    this.stroke,
    this.width,
    this.join,
    this.cap,
    this.alpha,
    this.path,
  );
  final String? fill, stroke;
  final double width, alpha;
  final StrokeJoin join;
  final StrokeCap cap;
  final Path path;
}

class _Art {
  const _Art(this.box, this.ops);
  final Rect box;
  final List<_Op> ops;

  static final Map<String, _Art> _cache = {};

  /// Parsed once a string, whatever number of times it is drawn.
  static _Art of(String data) => _cache[data] ??= _parse(data);

  static _Art _parse(String data) {
    final lines = data.split('\n');
    final v = lines.first.split(' ').map(double.parse).toList();
    final ops = <_Op>[];
    for (final line in lines.skip(1)) {
      if (line.isEmpty) continue;
      final bar = line.indexOf('|');
      final h = line.substring(0, bar).split(' ');
      ops.add(
        _Op(
          h[0] == '-' ? null : h[0],
          h[1] == '-' ? null : h[1],
          double.parse(h[2]),
          switch (h[3]) {
            'r' => StrokeJoin.round,
            'b' => StrokeJoin.bevel,
            _ => StrokeJoin.miter,
          },
          switch (h[4]) {
            'r' => StrokeCap.round,
            's' => StrokeCap.square,
            _ => StrokeCap.butt,
          },
          double.parse(h[5]),
          _path(line.substring(bar + 1)),
        ),
      );
    }
    return _Art(Rect.fromLTWH(v[0], v[1], v[2], v[3]), ops);
  }

  static final RegExp _token = RegExp(
    r'[MmLlHhVvCcQqTtAaZzOR]|-?(?:\d+\.?\d*|\.\d+)(?:[eE]-?\d+)?',
  );

  static Path _path(String d) {
    final p = Path();
    final t = _token.allMatches(d).map((m) => m[0]!).toList();
    var i = 0;
    double n() => double.parse(t[i++]);
    var x = 0.0, y = 0.0, cx = 0.0, cy = 0.0;
    var cmd = 'M';
    var quad = false;
    bool isCmd(String s) => RegExp(r'^[A-Za-z]$').hasMatch(s);
    while (i < t.length) {
      if (isCmd(t[i])) cmd = t[i++];
      final rel = cmd.toLowerCase() == cmd;
      switch (cmd.toUpperCase()) {
        case 'M':
          x = (rel ? x : 0) + n();
          y = (rel ? y : 0) + n();
          p.moveTo(x, y);
          cmd = rel ? 'l' : 'L';
          quad = false;
        case 'L':
          x = (rel ? x : 0) + n();
          y = (rel ? y : 0) + n();
          p.lineTo(x, y);
          quad = false;
        case 'H':
          x = (rel ? x : 0) + n();
          p.lineTo(x, y);
          quad = false;
        case 'V':
          y = (rel ? y : 0) + n();
          p.lineTo(x, y);
          quad = false;
        case 'C':
          final b = rel ? x : 0.0, c = rel ? y : 0.0;
          final a1 = b + n(), a2 = c + n(), a3 = b + n(), a4 = c + n();
          x = b + n();
          y = c + n();
          p.cubicTo(a1, a2, a3, a4, x, y);
          quad = false;
        case 'Q':
          final b = rel ? x : 0.0, c = rel ? y : 0.0;
          cx = b + n();
          cy = c + n();
          x = b + n();
          y = c + n();
          p.quadraticBezierTo(cx, cy, x, y);
          quad = true;
        case 'T':
          cx = quad ? 2 * x - cx : x;
          cy = quad ? 2 * y - cy : y;
          x = (rel ? x : 0) + n();
          y = (rel ? y : 0) + n();
          p.quadraticBezierTo(cx, cy, x, y);
          quad = true;
        case 'A':
          final rx = n(), ry = n(), rot = n(), large = n(), sweep = n();
          x = (rel ? x : 0) + n();
          y = (rel ? y : 0) + n();
          p.arcToPoint(
            Offset(x, y),
            radius: Radius.elliptical(rx, ry),
            rotation: rot,
            largeArc: large != 0,
            clockwise: sweep != 0,
          );
          quad = false;
        case 'Z':
          p.close();
          quad = false;
        case 'O':
          final ax = n(), ay = n(), rx = n(), ry = n();
          p.addOval(
            Rect.fromCenter(
              center: Offset(ax, ay),
              width: 2 * rx,
              height: 2 * ry,
            ),
          );
        case 'R':
          final ax = n(), ay = n(), w = n(), h = n();
          p.addRect(Rect.fromLTWH(ax, ay, w, h));
      }
    }
    return p;
  }
}

Color? _ink(String name, ComicColors c, bool onNight) => switch (name) {
  'line' => c.outline,
  'paper' => c.paper,
  'caption' => c.caption,
  'act' => c.primary,
  'shade' => c.shade,
  'drama' => c.drama,
  'tint' => c.shadeTint,
  'ray' => c.ray,
  'coverDot' => c.coverDot,
  'coverDotSecondary' => c.coverDotSecondary,
  'sky' => c.sky,
  'skyDot' => c.skyDot,
  'sun' => c.sun,
  'sunDot' => c.sunDot,
  'hill' => c.hill,
  'lake' => c.lake,
  'lakeDot' => c.lakeDot,
  'pine' => c.pine,
  'snow' => c.snow,
  'flake' => c.flake,
  'window' => c.window,
  'smoke' => c.smoke,
  'wood' => c.wood,
  'chili' => c.chili,
  'check' => c.check,
  'shadow' => c.shadow,
  'potDot' => c.potDot,
  'amber' => c.amber,
  'nightLine' => onNight ? c.paper : c.nightLine,
  'onPaper' => c.onPaper,
  'onPaperSecondary' => c.onPaperSecondary,
  'highlight' => c.highlight,
  'white' => const Color(0xFFFFFFFF),
  'freckle' => ComicSkin.freckle,
  'skin0' => ComicSkin.tones[0],
  'skin1' => ComicSkin.tones[1],
  'skin2' => ComicSkin.tones[2],
  'skin3' => ComicSkin.tones[3],
  'skin4' => ComicSkin.tones[4],
  'skin5' => ComicSkin.tones[5],
  'shade0' => ComicSkin.shades[0],
  'shade1' => ComicSkin.shades[1],
  'shade2' => ComicSkin.shades[2],
  'shade3' => ComicSkin.shades[3],
  'shade4' => ComicSkin.shades[4],
  'shade5' => ComicSkin.shades[5],
  _ => null,
};

class _ArtPainter extends CustomPainter {
  _ArtPainter(
    this.art,
    this.c,
    this.fit,
    this.alignment,
    this.onNight,
    this.clip, {
    this.flat = false,
  });
  final _Art art;
  final ComicColors c;
  final BoxFit fit;
  final Alignment alignment;
  final bool onNight;
  final Rect? clip;

  /// No face halftone: what a small head wants, which at that size is only mud.
  final bool flat;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final box = clip ?? art.box;
    final sx = size.width / box.width, sy = size.height / box.height;
    final s = fit == BoxFit.cover ? math.max(sx, sy) : math.min(sx, sy);
    final dx = (size.width - box.width * s) * (alignment.x + 1) / 2;
    final dy = (size.height - box.height * s) * (alignment.y + 1) / 2;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(dx, dy);
    canvas.scale(s);
    canvas.translate(-box.left, -box.top);
    for (final op in art.ops) {
      if (flat &&
          (op.fill?.startsWith('shade') ?? false) &&
          op.fill != 'shade') {
        continue;
      }
      if (op.fill != null) {
        final fill = _ink(op.fill!, c, onNight);
        if (fill != null && fill.a > 0) {
          canvas.drawPath(
            op.path,
            fillPaint(op.alpha < 1 ? fill.withValues(alpha: op.alpha) : fill),
          );
        }
      }
      if (op.stroke != null) {
        final stroke = _ink(op.stroke!, c, onNight);
        if (stroke != null && stroke.a > 0) {
          canvas.drawPath(
            op.path,
            strokePaint(stroke, op.width)
              ..strokeJoin = op.join
              ..strokeCap = op.cap,
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArtPainter o) =>
      o.art != art ||
      o.c != c ||
      o.fit != fit ||
      o.alignment != alignment ||
      o.onNight != onNight ||
      o.clip != clip ||
      o.flat != flat;
}

/// A drawing from its compact string, to the box it is given. [fit] `contain` shows it all and `cover` crops, as an SVG's
/// `slice` does. [onNight] lets its loose lines read on a night ground. A page doesn't write these strings: use `ComicMark`.
///
/// ```dart
/// ComicDrawing(comicMarkData(ComicMarks.mug))
/// ```
class ComicDrawing extends StatelessWidget {
  /// Creates a [ComicDrawing].
  const ComicDrawing(
    this.data, {
    super.key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.onNight = false,
    this.viewBox,
    this.flat = false,
  });

  /// The value installed or rendered by this object.
  final String data;

  /// How the image or drawing fits its allocated bounds.
  final BoxFit fit;

  /// Where content stands within its available space.
  final AlignmentGeometry alignment;

  /// Uses light loose-line ink against a night ground.
  final bool onNight;

  /// A part of the drawing to frame, in its own units.
  final Rect? viewBox;

  /// Leave off the fine halftone on a face.
  final bool flat;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _ArtPainter(
        _Art.of(data),
        ComicTheme.of(context).colors,
        fit,
        alignment.resolve(Directionality.maybeOf(context)),
        onNight,
        viewBox,
        flat: flat,
      ),
      size: Size.infinite,
    ),
  );
}

/// An object, drawn. For a plan, a place, a memory or a step, when you have no picture.
enum ComicMarks {
  /// A drawing of mug.
  mug,

  /// A drawing of pin.
  pin,

  /// A drawing of pumpkin.
  pumpkin,

  /// A drawing of moon.
  moon,

  /// A drawing of guitar.
  guitar,

  /// A drawing of tomato.
  tomato,

  /// A drawing of tent.
  tent,

  /// A drawing of dice.
  dice,

  /// A drawing of pint.
  pint,

  /// A drawing of peak.
  peak,

  /// A drawing of clapper.
  clapper,

  /// A drawing of cake.
  cake,

  /// A drawing of cabin.
  cabin,

  /// A drawing of rucksack.
  rucksack,

  /// A drawing of pan.
  pan,

  /// A drawing of pepper.
  pepper,

  /// A drawing of jars.
  jars,

  /// A drawing of pour.
  pour,

  /// A drawing of simmer.
  simmer,

  /// A drawing of bar.
  bar,

  /// A drawing of tins.
  tins,
}

const Map<ComicMarks, String> _marks = {
  ComicMarks.mug: comicArtMug,
  ComicMarks.pin: comicArtPin,
  ComicMarks.pumpkin: comicArtPumpkin,
  ComicMarks.moon: comicArtMoon,
  ComicMarks.guitar: comicArtGuitar,
  ComicMarks.tomato: comicArtTomato,
  ComicMarks.tent: comicArtTent,
  ComicMarks.dice: comicArtDice,
  ComicMarks.pint: comicArtPint,
  ComicMarks.peak: comicArtPeak,
  ComicMarks.clapper: comicArtClapper,
  ComicMarks.cake: comicArtCake,
  ComicMarks.cabin: comicArtCabin,
  ComicMarks.rucksack: comicArtRucksack,
  ComicMarks.pan: comicArtPan,
  ComicMarks.pepper: comicArtPepper,
  ComicMarks.jars: comicArtJars,
  ComicMarks.pour: comicArtPour,
  ComicMarks.simmer: comicArtSimmer,
  ComicMarks.bar: comicArtBar,
  ComicMarks.tins: comicArtTins,
};

/// The string behind a mark, for a band that draws it to its own box.
String comicMarkData(ComicMarks mark) => _marks[mark]!;

/// An object drawn in ink at [size] by [size]. It keeps its size and stands at its column's start. It has no data: choose
/// it by what the thing is.
///
/// ```dart
/// ComicMark(ComicMarks.cake, size: 82)
/// ```
class ComicMark extends StatelessWidget {
  /// Creates a [ComicMark].
  const ComicMark(
    this.mark, {
    super.key,
    this.size = 104,
    this.onNight = false,
  });

  /// An optional caller-supplied graphic.
  final ComicMarks mark;

  /// Its height. A drawing wider than it's tall, a step's scene, takes the width that goes with it.
  final double size;

  /// It stands on a night ground (`ComicArtBand` ground 4): its loose lines take paper.
  final bool onNight;
  @override
  Widget build(BuildContext context) => comicOwnSize(
    width:
        size *
        _Art.of(_marks[mark]!).box.width /
        _Art.of(_marks[mark]!).box.height,
    height: size,
    child: Semantics(
      image: true,
      label: mark.name,
      child: ComicDrawing(_marks[mark]!, onNight: onNight),
    ),
  );
}

/// A drawn head and shoulders, by what you see. Not anyone. Use `ComicPortrait(cropped: true)` for a small head, or
/// `ComicPortrait.seeded(name)` to have one picked.
enum ComicBust {
  /// A fictional portrait with puffed hair.
  puff,

  /// A fictional portrait with a bob haircut.
  bob,

  /// A fictional portrait with spiked hair.
  spikes,

  /// A fictional portrait with a quiff.
  quiff,

  /// A fictional portrait with a topknot.
  topknot,

  /// A fictional portrait wearing a beanie.
  beanie,
}

const Map<ComicBust, String> _busts = {
  ComicBust.puff: comicArtPuff,
  ComicBust.bob: comicArtBob,
  ComicBust.spikes: comicArtSpikes,
  ComicBust.quiff: comicArtQuiff,
  ComicBust.topknot: comicArtTopknot,
  ComicBust.beanie: comicArtBeanie,
};

/// The string behind a bust.
String comicBustData(ComicBust bust) => _busts[bust]!;

/// A fictional portrait supplied by the gallery, usable in any widget picture slot.
///
/// ```dart
/// ComicPerson(portrait: ComicPortrait(ComicBust.bob, cropped: true))
/// ```
class ComicPortrait extends StatelessWidget {
  /// Creates a [ComicPortrait].
  const ComicPortrait(this.bust, {super.key, this.cropped = false})
    : name = null;

  /// Picks the same fictional drawing for the same name.
  const ComicPortrait.seeded(this.name, {super.key, this.cropped = false})
    : bust = null;

  /// The fictional drawing selected for this portrait.
  final ComicBust? bust;

  /// The displayed name of this record or person.
  final String? name;

  /// Shows the head rather than the full portrait.
  final bool cropped;
  @override
  Widget build(BuildContext context) => ComicDrawing(
    comicBustData(bust ?? comicBustFor(name!)),
    viewBox: cropped ? const Rect.fromLTWH(12, 9, 76, 76) : null,
    flat: cropped,
  );
}

/// Picks a bust by a name's own letters, so a name keeps its drawing between runs.
ComicBust comicBustFor(String name) {
  var h = 0;
  for (final u in name.codeUnits) {
    h = (h * 31 + u) & 0x7FFFFFFF;
  }
  return ComicBust.values[h % ComicBust.values.length];
}
