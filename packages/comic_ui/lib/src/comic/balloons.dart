// What people say and what numbers shout: balloons, thought clouds, bursts and stamps. Each shape is drawn from the words it
// holds, one path for body and tail, so a tail can't come away from a balloon whatever the words do.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/geometry.dart';
import 'layout.dart';
import 'theme.dart';
import 'component_themes.dart';
import 'styled.dart';

/// Where a balloon's tail leaves it. `bottomStart` and `bottomEnd` hang under it, `side` points back at a speaker standing at
/// its start, `top` rises from it, `none` is a caption in a balloon's shape.
enum ComicTail {
  /// Points below the body toward the reading-order start.
  bottomStart,

  /// Points below the body toward the reading-order end.
  bottomEnd,

  /// Points from the reading-order start edge.
  side,

  /// Points above the body.
  top,

  /// Draws the body without a tail.
  none,
}

/// How far past the body a tail reaches, when a tail takes room.
const double _tailBelow = 19, _tailSide = 19;

/// A balloon's whole outline for a body of [w] by [h]: rounded body and tail, one path. [at] places the tail's tip: how far along
/// its edge, 0 to 1, or the usual distance from the start if null. A tail's base stays on the straight of the edge.
Path comicBalloonPath(
  double w,
  double h,
  ComicTail tail,
  double radius, {
  double? at,
  bool rtl = false,
  double scale = 1,
}) {
  final r = math.min(radius, math.min(w, h) / 2);
  final body = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h).deflate(1.25),
        Radius.circular(math.max(0, r - 1.25)),
      ),
    );
  if (tail == ComicTail.none) return body;
  final t = Path();
  double mx(double x) => rtl ? w - x : x;
  if (tail == ComicTail.side) {
    // The concept's left tail, its top a little under the top corner, held inside the body.
    final dy = math.max(0.0, math.min(14.5, h - 26)) - 14.5;
    double y(double v) => v + dy;
    double sx(double v) => mx(v < 1.25 ? 1.25 + (v - 1.25) * scale : v);
    t
      ..moveTo(sx(5), y(19))
      ..lineTo(sx(1.25), y(19))
      ..cubicTo(sx(-4), y(21.5), sx(-11), y(20.5), sx(-18), y(16))
      ..cubicTo(sx(-14), y(25.5), sx(-6), y(32.5), sx(1.25), y(36))
      ..lineTo(sx(5), y(36))
      ..close();
    return Path.combine(PathOperation.union, body, t);
  }
  final up = tail == ComicTail.top;
  final baseY = up ? 1.25 : h - 1.25;
  double ty(double v) => up ? baseY - v * scale : baseY + v * scale;
  final span = 30 * scale;
  final lean = tail == ComicTail.bottomEnd;
  final room = math.max(0.0, w - span);
  var a = at != null
      ? (at * w - 1.5 * scale).clamp(0.0, room)
      : (lean ? room - 26.5 * scale : 26.5 * scale).clamp(0.0, room);
  // Past the corner's curve a tail's base would stand clear of the body.
  final least = math.min(r * .4, room);
  a = a.clamp(least, math.max(room - r * .4, least));
  double tx(double v) {
    final x = lean ? a + (span - v * scale) : a + v * scale;
    return mx(x);
  }

  t
    ..moveTo(tx(5), up ? baseY + 4 : baseY - 4)
    ..lineTo(tx(5), ty(0))
    ..cubicTo(tx(6.6), ty(4.75), tx(6), ty(11.75), tx(1.5), ty(18.75))
    ..cubicTo(tx(11), ty(14.75), tx(18), ty(6.75), tx(21), ty(0))
    ..lineTo(tx(21), up ? baseY + 4 : baseY - 4)
    ..close();
  return Path.combine(PathOperation.union, body, t);
}

class _BalloonPainter extends CustomPainter {
  _BalloonPainter(
    this.fill,
    this.line,
    this.tail,
    this.radius,
    this.at,
    this.rtl,
    this.room,
    this.width,
    this.tailScale, {
    this.shape,
  });
  final OutlinedBorder? shape;
  final Color fill, line;
  final ComicTail tail;
  final double radius, width, tailScale;
  final double? at;
  final bool rtl, room;
  @override
  void paint(Canvas canvas, Size s) {
    final outline = shape;
    if (outline != null) {
      final p = outline.getOuterPath(
        Offset.zero & s,
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      );
      canvas.drawPath(p, fillPaint(fill));
      canvas.drawPath(p, strokePaint(line, width));
      return;
    }
    final side = room && tail == ComicTail.side ? _tailSide : 0.0;
    final below = room && tail == ComicTail.bottomStart
        ? _tailBelow * tailScale
        : room && tail == ComicTail.bottomEnd
        ? _tailBelow * tailScale
        : 0.0;
    final above = room && tail == ComicTail.top ? _tailBelow * tailScale : 0.0;
    final w = s.width - side, h = s.height - below - above;
    final p = comicBalloonPath(
      w,
      h,
      tail,
      radius,
      at: at,
      rtl: rtl,
      scale: tailScale,
    );
    canvas.save();
    canvas.translate(rtl ? 0 : side, above);
    canvas.drawPath(p, fillPaint(fill));
    canvas.drawPath(p, strokePaint(line, width)..strokeJoin = StrokeJoin.round);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BalloonPainter o) =>
      o.fill != fill ||
      o.line != line ||
      o.tail != tail ||
      o.radius != radius ||
      o.at != at ||
      o.rtl != rtl ||
      o.room != room ||
      o.tailScale != tailScale ||
      o.width != width ||
      o.shape != shape;
}

/// A speech balloon: paper at any hour, its words in caps, a by-line under them. It sizes itself to its words at any width,
/// and the tail is part of its outline, so no words can part them. It hugs its words at its column's start; [fill] takes the
/// column instead. [room] counts the tail in its size (take it off where a speaker stands in the gap). [tailAt] points the
/// tail, 0 to 1 along its edge.
///
/// ```dart
/// ComicBalloon('Bringing the first-aid kit.', by: 'Pat, 09:20')
/// ```
class ComicBalloon extends StatelessWidget {
  /// Creates a [ComicBalloon].
  const ComicBalloon(
    this.words, {
    super.key,
    this.style,
    this.by,
    this.tail = ComicTail.bottomStart,
    this.tailAt,
    this.room = true,
    this.fill = false,
    this.small = false,
    this.child,
  });

  /// Optional appearance; null preserves the joined balloon drawing.
  final ComicStyle? style;

  /// [words]: the words displayed in this composition. [by]: the attribution printed with the words.
  final String? words, by;

  /// The edge and direction of the speech tail.
  final ComicTail tail;

  /// The fractional position of the tail along its edge.
  final double? tailAt;

  /// [room]: reserves layout space for the balloon's tail. [fill]: whether or how the component fills its available space. [small]: uses the smaller visual treatment.
  final bool room, fill, small;

  /// Other things to say than words: stars over a line, say. Words go in caps on their own.
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final look = ComicStyleOf([style], const {}),
        rim = comicRim(t, ComicStyleOf([style], const {}), c.outline);
    final textStyle = t.type.balloon
        .merge(look.textStyle)
        .copyWith(
          fontSize: small ? 13 : null,
          color: look.foreground ?? c.onPaper,
        );
    final inset = small
        ? const EdgeInsetsDirectional.fromSTEB(14.5, 11.5, 14.5, 12.5)
        : const EdgeInsetsDirectional.fromSTEB(18.5, 13.5, 18.5, 14.5);
    final byStyle = t.type.text(
      12,
      1.25,
      weight: FontWeight.w800,
      color: c.onPaperSecondary,
      tracking: .05,
    );
    // A plain column: a balloon hugs its words, and a stretching column would blow it out to the room it stands in.
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (words != null)
          Text(words!.toUpperCase(), style: textStyle.leading(1.35)),
        ?child,
        if (by != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(by!.toUpperCase(), style: byStyle),
          ),
      ],
    );
    final extra = !room
        ? EdgeInsetsDirectional.zero
        : switch (tail) {
            ComicTail.side => const EdgeInsetsDirectional.only(
              start: _tailSide,
            ),
            ComicTail.top => const EdgeInsetsDirectional.only(top: _tailBelow),
            ComicTail.none => EdgeInsetsDirectional.zero,
            _ => const EdgeInsetsDirectional.only(bottom: _tailBelow),
          };
    final shape = AnimatedComicShape(
      shape: look.shape,
      builder: (context, outline) => CustomPaint(
        painter: _BalloonPainter(
          look.fill ?? c.paper,
          rim.color,
          tail,
          small ? 20 : 24,
          tailAt,
          rtl,
          room,
          rim.width,
          1,
          shape: outline,
        ),
        child: Padding(
          padding: (look.padding(Directionality.of(context)) ?? inset).add(
            outline?.dimensions ?? extra,
          ),
          child: DefaultTextStyle.merge(style: textStyle, child: content),
        ),
      ),
    );
    return fill
        ? shape
        : Align(
            alignment: AlignmentDirectional.topStart,
            widthFactor: 1,
            heightFactor: 1,
            child: shape,
          );
  }
}

class _CloudPainter extends CustomPainter {
  _CloudPainter(this.fill, this.line, this.rx, this.ry, this.trail, this.rtl);
  final Color fill, line;
  final double rx, ry;
  final int trail; // -1 start, 1 end, 0 none
  final bool rtl;

  static const double _bump = 8.6;
  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final cy = rx > 0 ? ry + _bump + 2.5 + 1 : s.height / 2;
    // Ramanujan's perimeter: enough bumps to scallop it evenly, at any size.
    final h = math.pow(rx - ry, 2) / math.pow(rx + ry, 2);
    final perimeter =
        math.pi * (rx + ry) * (1 + 3 * h / (10 + math.sqrt(4 - 3 * h)));
    final k = math.max(9, (perimeter / 15).round());
    final bumps = Path()
      ..addOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 2 * rx, height: 2 * ry),
      );
    for (var i = 0; i < k; i++) {
      final a = 2 * math.pi * i / k;
      bumps.addOval(
        Rect.fromCircle(
          center: Offset(cx + rx * math.cos(a), cy + ry * math.sin(a)),
          radius: _bump,
        ),
      );
    }
    final stroke = strokePaint(line, 5);
    canvas.drawPath(bumps, stroke);
    if (trail != 0) {
      final dir = (trail > 0) != rtl ? 1.0 : -1.0;
      final x0 = cx + dir * rx * .48, y0 = cy + ry + _bump + 2;
      for (final (dx, dy, r) in const [
        (0.0, 3.0, 5.2),
        (7.0, 13.0, 3.6),
        (11.0, 21.0, 2.4),
      ]) {
        final o = Offset(x0 + dir * dx, y0 + dy);
        canvas.drawCircle(o, r, stroke..strokeWidth = 2.5);
        canvas.drawCircle(o, r, fillPaint(fill));
      }
      stroke.strokeWidth = 5;
    }
    canvas.drawPath(bumps, fillPaint(fill));
  }

  @override
  bool shouldRepaint(_CloudPainter o) =>
      o.fill != fill ||
      o.line != line ||
      o.rx != rx ||
      o.ry != ry ||
      o.trail != trail ||
      o.rtl != rtl;
}

/// A thought: a scalloped cloud grown from its words, three bubbles trailing to a side. It keeps to its column, wrapping its
/// words to stay on the page, and stands at the column's start.
///
/// ```dart
/// ComicThought('Who has the tent?')
/// ```
class ComicThought extends StatelessWidget {
  /// Creates a [ComicThought].
  const ComicThought(
    this.words, {
    super.key,
    this.trailEnd = false,
    this.trail = true,
    this.style,
  });

  /// The words displayed in this composition.
  final String words;

  /// The bubbles go to the end, not the start.
  final bool trailEnd;

  /// Whether the thought cloud includes its trailing circles.
  final bool trail;

  /// The words' style, if a few big words want one: three dots in the lettering face, say.
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final words0 = style == null ? words.toUpperCase() : words;
    final text =
        style ??
        t.type.text(
          14,
          1.2,
          weight: FontWeight.w800,
          color: c.onPaper,
          tracking: .03,
        );
    return LayoutBuilder(
      builder: (context, box) {
        const bump = 8.6 + 2.5 + 1;
        final most = box.hasBoundedWidth ? box.maxWidth : 320.0;
        final room = math.max(
          40.0,
          math.min((most - 2 * bump - 28) / 1.35, 260.0),
        );
        final tp = TextPainter(
          text: TextSpan(text: words0, style: text),
          textDirection: Directionality.of(context),
          textAlign: TextAlign.center,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: room);
        final w = tp.width, h = tp.height;
        tp.dispose();
        final rx = w / 2 * 1.35 + 14, ry = h / 2 * 1.35 + 12;
        final tall = 2 * ry + 2 * bump + (trail ? 26 : 0);
        return comicOwnSize(
          width: 2 * (rx + bump),
          height: tall,
          child: CustomPaint(
            painter: _CloudPainter(
              c.paper,
              c.outline,
              rx,
              ry,
              trail ? (trailEnd ? 1 : -1) : 0,
              Directionality.of(context) == TextDirection.rtl,
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: trail ? 26 : 0),
              child: Center(
                child: SizedBox(
                  width: w + 1,
                  child: Text(words0, textAlign: TextAlign.center, style: text),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A line laid out for a burst, with its place in the block.
class _Line {
  _Line(this.painter, this.y);
  final TextPainter painter;
  final double y;
}

/// The lines of a burst fitted into its star: laid out once, scaled down whole until no corner of any line crosses the star's
/// edge. So a number of any length fits, and never clips.
class ComicBurstFit {
  ComicBurstFit._(this._lines, this.height, this.scale);
  final List<_Line> _lines;

  /// [height]: the allocated height in logical pixels. [scale]: the scale applied to the fitted drawing.
  final double height, scale;

  /// Creates a [ComicBurstFit].
  factory ComicBurstFit(
    Path star,
    Offset centre,
    List<(String, TextStyle, double)> rows,
    TextDirection dir,
  ) {
    final lines = <_Line>[];
    var y = 0.0;
    for (final (text, style, after) in rows) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: dir,
        textAlign: TextAlign.center,
      )..layout();
      lines.add(_Line(tp, y));
      y += tp.height + after;
    }
    final fit = ComicBurstFit._(lines, y, 1);
    return ComicBurstFit._(lines, y, fit._fit(star, centre));
  }

  /// Whether every line's ink, at [k], stands inside [star].
  bool holds(Path star, Offset centre, double k) {
    for (final l in _lines) {
      final size = l.painter.text!.style!.fontSize!;
      // The glyphs' box inside the line's: a line box leaves room over and under the caps.
      final insetY = size * .12, insetX = size * .02;
      final w = l.painter.width / 2 - insetX;
      final top = l.y - height / 2 + insetY;
      final bottom = l.y + l.painter.height - height / 2 - insetY;
      for (final (x, y) in [(-w, top), (w, top), (-w, bottom), (w, bottom)]) {
        if (!star.contains(centre + Offset(x, y) * k)) return false;
      }
    }
    return true;
  }

  double _fit(Path star, Offset centre) {
    var k = 1.0;
    for (var i = 0; i < 80 && !holds(star, centre, k); i++) {
      k *= .96;
    }
    return k;
  }

  /// Paints the fitted lines around [centre] on [canvas].
  void paint(Canvas canvas, Offset centre) {
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(scale);
    for (final l in _lines) {
      l.painter.paint(canvas, Offset(-l.painter.width / 2, l.y - height / 2));
    }
    canvas.restore();
  }

  /// Releases the laid-out text painters.
  void dispose() {
    for (final l in _lines) {
      l.painter.dispose();
    }
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.front,
    required this.back,
    required this.line,
    required this.rows,
    required this.tilt,
    required this.seed,
    required this.plate,
    required this.spikes,
    required this.stroke,
    required this.dir,
    this.inner = .72,
  });
  final Color front, line;
  final Color? back;
  final List<(String, TextStyle, double)> rows;
  final double tilt, plate, stroke, inner;
  final int seed, spikes;
  final TextDirection dir;
  @override
  void paint(Canvas canvas, Size s) {
    final pts = burstPoints(
      s.width - plate,
      s.height - plate,
      spikes: spikes,
      seed: seed,
      inner: inner,
    );
    final star = polyPath(pts);
    final c = Offset((s.width - plate) / 2, (s.height - plate) / 2);
    canvas.save();
    canvas.translate(s.width / 2, s.height / 2);
    canvas.rotate(tilt * math.pi / 180);
    canvas.translate(-s.width / 2, -s.height / 2);
    final edge = strokePaint(line, stroke)..strokeJoin = StrokeJoin.miter;
    if (back != null) {
      final behind = star.shift(Offset(plate, plate));
      canvas.drawPath(behind, fillPaint(back!));
      canvas.drawPath(behind, edge);
    }
    canvas.drawPath(star, fillPaint(front));
    canvas.drawPath(star, edge);
    final fit = ComicBurstFit(star, c, rows, dir);
    fit.paint(canvas, c);
    fit.dispose();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BurstPainter o) =>
      o.front != front ||
      o.back != back ||
      o.line != line ||
      o.tilt != tilt ||
      o.seed != seed ||
      o.plate != plate ||
      o.stroke != stroke ||
      o.inner != inner ||
      o.spikes != spikes ||
      o.dir != dir ||
      !_sameRows(o.rows, rows);
  static bool _sameRows(
    List<(String, TextStyle, double)> a,
    List<(String, TextStyle, double)> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A screen's one burst. `ComicScaffold` holds this: the first `ComicBurst` under it takes the place, and any other draws itself
/// as a flat stamp and says so in the log.
///
/// ```dart
/// ComicBurstLedger(child: ComicBurst(number: '12'))
/// ```
class ComicBurstLedger extends StatefulWidget {
  /// Creates a [ComicBurstLedger].
  const ComicBurstLedger({super.key, required this.child});

  /// Content placed inside this widget.
  final Widget child;
  @override
  State<ComicBurstLedger> createState() => _ComicBurstLedgerState();
}

class _ComicBurstLedgerState extends State<ComicBurstLedger> {
  final _Ledger _ledger = _Ledger();
  @override
  Widget build(BuildContext context) =>
      _LedgerScope(_ledger, child: widget.child);
}

class _LedgerScope extends InheritedWidget {
  const _LedgerScope(this.ledger, {required super.child});
  final _Ledger ledger;
  @override
  bool updateShouldNotify(_LedgerScope old) => old.ledger != ledger;
}

class _Ledger {
  Object? holder;
}

/// The one number a screen shouts: a jagged star with a hard back plate, a number in it, a word over and under. It fits any
/// number, scaling its words down whole, and it can't clip. One per screen: a second under the same `ComicScaffold` comes out as
/// a flat `ComicStamp`, with a line in the log. For small repeatable counts use `ComicPop`, and for a status `ComicStamp`.
///
/// ```dart
/// ComicBurst(number: '23', over: 'In', under: 'days!')
/// ```
class ComicBurst extends StatefulWidget {
  /// Creates a [ComicBurst].
  const ComicBurst({
    super.key,
    required this.number,
    this.over,
    this.under,
    this.large = false,
    this.width,
    this.height,
    this.wordSize,
    this.numberSize,
    this.tilt = -8,
    this.seed = 3,
  });

  /// The number printed in the figure.
  final String number;

  /// [over]: the words above the main figure. [under]: the words below the main figure.
  final String? over, under;

  /// A splash's size: 142 by 122 on a phone, 262 by 216 on a desktop. Otherwise 146 by 124 and 214 by 184.
  final bool large;

  /// [width]: the allocated width in logical pixels. [height]: the allocated height in logical pixels. [wordSize]: the supporting word size in logical pixels. [numberSize]: the main numeral size in logical pixels.
  final double? width, height, wordSize, numberSize;

  /// The drawing's rotation in degrees.
  final double tilt;

  /// Moves the jags. Same seed, same star.
  final int seed;
  @override
  State<ComicBurst> createState() => _ComicBurstState();
}

class _ComicBurstState extends State<ComicBurst> {
  _Ledger? _ledger;

  void _claim() {
    final ledger = context
        .getInheritedWidgetOfExactType<_LedgerScope>()
        ?.ledger;
    if (!identical(ledger, _ledger) && _ledger?.holder == this) {
      _ledger!.holder = null;
    }
    _ledger = ledger;
    ledger?.holder ??= this;
  }

  bool get _flat => _ledger != null && _ledger!.holder != this;

  @override
  void dispose() {
    if (_ledger?.holder == this) _ledger!.holder = null;
    super.dispose();
  }

  // A jagged star's ink never reaches its box's edges: the keyline check takes the figure by its box.
  @override
  Widget build(BuildContext context) =>
      DesignKeylineFace(child: Builder(builder: _figure));

  Widget _figure(BuildContext context) {
    _claim();
    final w = widget;
    final t = ComicTheme.of(context);
    final c = t.colors;
    final words = [w.over, w.number, w.under].whereType<String>().join(' ');
    if (_flat) {
      debugPrint(
        'ComicBurst: "$words" is a second burst on this screen, so it draws as a stamp. One per screen: use ComicPop for a small count.',
      );
      return ComicStamp(words);
    }
    final bw =
        w.width ??
        (w.large ? (t.desk ? 262.0 : 142.0) : (t.desk ? 214.0 : 146.0));
    final bh =
        w.height ??
        (w.large ? (t.desk ? 216.0 : 122.0) : (t.desk ? 184.0 : 124.0));
    final ws =
        w.wordSize ??
        (w.large ? (t.desk ? 32.0 : 20.0) : (t.desk ? 20.0 : 16.0));
    final ns =
        w.numberSize ??
        (w.large ? (t.desk ? 110.0 : 58.0) : (t.desk ? 56.0 : 36.0));
    final word = t.type.letter(
      ws,
      lineHeight: .9,
      color: c.onCaption,
      tracking: .04,
    );
    final figure = t.type.letter(
      ns,
      lineHeight: w.large ? .82 : .86,
      color: c.onCaption,
      tracking: .04,
    );
    final rows = <(String, TextStyle, double)>[
      if (w.over != null) (w.over!.toUpperCase(), word, 1),
      (w.number.toUpperCase(), figure, 2),
      if (w.under != null) (w.under!.toUpperCase(), word, 0),
    ];
    return comicOwnSize(
      width: bw,
      height: bh,
      child: Semantics(
        label: words,
        child: CustomPaint(
          painter: _BurstPainter(
            front: c.caption,
            back: c.drama,
            line: c.outline,
            rows: rows,
            tilt: w.tilt,
            seed: w.seed,
            plate: 5,
            spikes: 14,
            stroke: 3.4,
            dir: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

/// A small count that pops off its row: the leader of a poll, a score. Any number of them, since each is only a count. Any
/// number fits.
///
/// ```dart
/// ComicPop('4', width: 40, height: 34)
/// ```
class ComicPop extends StatelessWidget {
  /// Creates a [ComicPop].
  const ComicPop(
    this.number, {
    super.key,
    this.width = 48,
    this.height = 42,
    this.size = 24,
    this.seed = 7,
    this.tilt = 0,
    this.isCurrentUser = false,
    this.plate = false,
  });

  /// The number printed in the figure.
  final String number;

  /// [width]: the allocated width in logical pixels. [height]: the allocated height in logical pixels. [size]: the visual size in logical pixels. [tilt]: the drawing's rotation in degrees.
  final double width, height, size, tilt;

  /// The seed that keeps the drawing repeatable.
  final int seed;

  /// A hard drama plate behind it, for a figure that sums up a panel.
  final bool plate;

  /// It's yours: the act's fill.
  final bool isCurrentUser;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final letters = isCurrentUser ? c.onPrimary : c.onCaption;
    return comicOwnSize(
      width: width,
      height: height,
      child: Semantics(
        label: number,
        child: CustomPaint(
          painter: _BurstPainter(
            front: isCurrentUser ? c.primary : c.caption,
            back: plate ? c.drama : null,
            line: c.outline,
            rows: [
              (
                number,
                t.type.letter(
                  size,
                  lineHeight: 1,
                  color: letters,
                  tracking: .03,
                ),
                0,
              ),
            ],
            tilt: tilt,
            seed: seed,
            plate: plate ? 3 : 0,
            spikes: plate ? 11 : 10,
            stroke: plate ? 2.6 : 2.2,
            inner: .76,
            dir: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

/// A rubber stamp: a word or two on paper, tilted, in the lettering. For a status, not a count: Paid, Sold out, In the lead.
/// It hugs its word at its column's start.
///
/// ```dart
/// ComicStamp('Paid')
/// ```
class ComicStamp extends StatelessWidget {
  /// Creates a [ComicStamp].
  const ComicStamp(this.word, {super.key, this.tilt = -7, this.tight = false});

  /// The word printed by this label.
  final String word;

  /// The drawing's rotation in degrees.
  final double tilt;

  /// The size for a bar's end.
  final bool tight;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Transform.rotate(
        angle: tilt * math.pi / 180,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: c.paper,
            shape: t.shapes.small.copyWith(
              side: BorderSide(color: c.outline, width: tight ? 2 : 2.5),
            ),
          ),
          child: Padding(
            padding: tight
                ? const EdgeInsets.fromLTRB(7, 4, 7, 3)
                : const EdgeInsets.fromLTRB(10.5, 5.5, 10.5, 4.5),
            child: Text(
              word.toUpperCase(),
              style: t.type.letter(
                16,
                lineHeight: 1,
                color: c.onPaper,
                tracking: .08,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
