// The dials, cast from the wall: a fluted setting dial, the same dial counting a span of time, the small gauge, the knob. Each is an
// object, so each keeps its circle; no sentence ever stands on one. A dome holds a figure and two short lines at most.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../glyphs.dart';

import '../controls.dart';
import '../localizations.dart';
import '../frames.dart';
import '../internal/geometry.dart';
import '../layout.dart';
import '../theme.dart';

double _ang(double v, double lo, double hi) =>
    -135 + 270 * ((v - lo) / (hi - lo)).clamp(0.0, 1.0);

/// One tick of a dial's scale, in the 400 unit box.
typedef _Tick = ({double deg, int rank, bool on});

/// How far an instrument face's scale numerals grow with the text: they stand between ticks, and at twice the size they
/// ran into them. Its readout grows in full (see [_instrument]).
const double _faceTextScale = 1.3;

/// An instrument face: [build] runs with the text scale held at [_faceTextScale] for the scale's numerals, and is handed
/// the reader's own scaler for the readout, which grows with the text in full, as every part's words do, and stands
/// under the face where it no longer fits in it.
Widget _instrument(
  BuildContext context,
  Widget Function(BuildContext context, TextScaler reader) build,
) {
  final reader = MediaQuery.textScalerOf(context);
  return MediaQuery.withClampedTextScaling(
    maxScaleFactor: _faceTextScale,
    child: Builder(builder: (context) => build(context, reader)),
  );
}

/// [child] at the reader's own text scale, inside an instrument face.
Widget _atReader(BuildContext context, TextScaler reader, Widget child) =>
    MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: reader),
      child: child,
    );

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.c,
    required this.flat,
    required this.large,
    required this.ticks,
    required this.arcTo,
    required this.gradFrom,
    required this.gradTo,
    this.notch,
    required this.bead,
    required this.beadR,
  });
  final NeumorphicColors c;
  final bool flat, large;
  final List<_Tick> ticks;
  final double arcTo;
  final Offset gradFrom, gradTo;
  final double? notch;
  final double bead, beadR;

  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 400;
    final mid = s.center(Offset.zero);
    Rect ring(double f) =>
        Rect.fromCircle(center: mid, radius: s.width * f / 2);
    final body = ring(1),
        moat = ring(.75),
        collar = ring(.61),
        dome = ring(.52);
    double u(double small, double big) => large ? big : small;

    neumorphicPaintRaised(
      canvas,
      Path()..addOval(body),
      c,
      light: (Offset(-u(14, 24), -u(14, 24)), u(30, 54)),
      dark: (Offset(u(16, 28), u(16, 28)), u(36, 64)),
      darkColor: c.shadowDeep,
      flat: flat,
    );
    if (flat) {
      canvas.drawOval(body.deflate(.5), neumorphicStrokePaint(c.quiet, 1));
    }
    neumorphicPaintPressed(
      canvas,
      Path()..addOval(moat),
      c,
      light: (Offset(-u(8, 12), -u(8, 12)), u(16, 26)),
      dark: (Offset(u(9, 14), u(9, 14)), u(18, 28)),
      flat: flat,
    );
    if (flat) canvas.drawOval(moat, neumorphicStrokePaint(c.quiet, 1));

    Offset at(double r, double deg) =>
        neumorphicDialPoint(mid.dx, mid.dy, r * k, deg);
    for (final t in ticks) {
      // The scale gives way round where it is now: a tick beside the long one (the set point's lit tick half a
      // degree on) read as a doubled stroke, //. The set point still shows in the arc's bead and the readout.
      if (notch != null && (t.deg - notch!).abs() < 5) continue;
      final (r0, r1) = switch (t.rank) {
        2 => (176.0, 194.0),
        1 => (181.0, 192.0),
        _ => (184.0, 191.0),
      };
      final color = t.on
          ? c.pigment
          : t.rank == 2
          ? c.ink
          : c.quiet;
      canvas.drawLine(
        at(r0, t.deg),
        at(r1, t.deg),
        neumorphicStrokePaint(
          color,
          (t.on || t.rank == 2 ? 2.6 : 1.6) * k.clamp(.8, 1.2),
        ),
      );
    }

    final from = -135.0;
    final arc = neumorphicDialArc(mid.dx, mid.dy, 136 * k, from, arcTo);
    if (arcTo > from) {
      if (!flat) {
        canvas.drawPath(
          arc,
          neumorphicStrokePaint(c.pigment.withValues(alpha: .10), 30 * k),
        );
      }
      canvas.drawPath(
        arc,
        neumorphicStrokePaint(c.pigment, 14 * k)
          ..shader = _gradient(
            gradFrom.scale(k, k) + (mid - Offset(s.width / 2, s.width / 2)),
            gradTo.scale(k, k) + (mid - Offset(s.width / 2, s.width / 2)),
          ),
      );
    }
    // Where it is now: the scale's one long tick, reaching in from the scale toward the arc. A solid ink wedge there
    // read as a stray cursor, an ink body of its own (law 5), fighting the knob and the lit ticks.
    if (notch != null) {
      canvas.drawLine(
        at(162, notch!),
        at(196, notch!),
        neumorphicStrokePaint(c.ink, 3 * k.clamp(.8, 1.2)),
      );
    }

    neumorphicPaintRaised(
      canvas,
      Path()..addOval(collar),
      c,
      light: (Offset(-u(7, 11), -u(7, 11)), u(16, 24)),
      dark: (Offset(u(9, 14), u(9, 14)), u(20, 32)),
      darkColor: c.shadowDeep,
      flat: flat,
    );
    if (flat) canvas.drawOval(collar, neumorphicStrokePaint(c.quiet, 1));
    for (var i = 0; i < 80; i++) {
      final a = i * 4.5;
      final w = 1.5 * k.clamp(.75, 1.2);
      canvas.drawLine(
        at(109, a),
        at(119, a),
        neumorphicStrokePaint(c.fluteHighlight, w),
      );
      canvas.drawLine(
        at(109, a + 1.7),
        at(119, a + 1.7),
        neumorphicStrokePaint(c.fluteShadow, w),
      );
    }

    neumorphicPaintRaised(
      canvas,
      Path()..addOval(dome),
      c,
      light: (Offset(-u(4, 6), -u(4, 6)), u(10, 14)),
      lightColor: c.highlightSoft,
      dark: (Offset(u(7, 11), u(7, 11)), u(16, 24)),
      face: cssRadial(
        dome,
        .34,
        .28,
        [c.domeLight, c.domeMid, c.domeDark],
        const [0, .46, 1],
      ),
      flat: flat,
    );
    if (flat) canvas.drawOval(dome, neumorphicStrokePaint(c.quiet, 1));

    if (arcTo > from || bead >= from) {
      final b = at(136, bead);
      final box = Rect.fromCircle(center: b, radius: beadR);
      neumorphicPaintRaised(
        canvas,
        Path()..addOval(box),
        c,
        light: (const Offset(-2, -2), 4),
        lightColor: c.highlightSoft,
        dark: (const Offset(3, 3), 7),
        darkColor: c.shadowDeep,
        face: cssLinear(box, 145, [c.domeLight, c.domeMid]),
        flat: flat,
      );
      if (flat) canvas.drawOval(box, neumorphicStrokePaint(c.quiet, 1));
      canvas.drawCircle(b, beadR / 3, neumorphicFillPaint(c.pigment));
    }
  }

  Shader _gradient(Offset a, Offset b) => LinearGradient(
    colors: [c.pigmentHi, c.pigment],
  ).createShader(Rect.fromPoints(a, b), textDirection: TextDirection.ltr);

  @override
  bool shouldRepaint(_DialPainter o) =>
      o.c != c ||
      o.flat != flat ||
      o.large != large ||
      o.arcTo != arcTo ||
      o.notch != notch ||
      o.bead != bead ||
      o.beadR != beadR ||
      o.gradFrom != gradFrom ||
      o.gradTo != gradTo ||
      o.ticks.length != ticks.length ||
      !_sameTicks(o.ticks, ticks);
  bool _sameTicks(List<_Tick> a, List<_Tick> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A figure with a degree sign stands optically centred: the sign hangs out to the right, as the concept's negative margin does.
Widget _hung(String figure, TextStyle style, double hang) {
  final text = Text(figure, textAlign: TextAlign.center, style: style);
  return figure.endsWith('°') && hang != 0
      ? Transform.translate(offset: Offset(hang, 0), child: text)
      : text;
}

bool _dialWordsFit(
  BuildContext context,
  double width,
  double height,
  List<(String?, TextStyle)> words, {
  double extraWidth = 0,
  TextScaler? scaler,
}) {
  var usedHeight = 4.0;
  for (final (word, style) in words) {
    if (word == null) continue;
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler ?? MediaQuery.textScalerOf(context),
    )..layout();
    final fits = painter.width + extraWidth <= width;
    usedHeight += painter.height;
    painter.dispose();
    if (!fits) return false;
  }
  return usedHeight <= height;
}

Widget _dialReadout({
  required BuildContext context,
  required String figure,
  required TextStyle figureStyle,
  String? label,
  IconData? icon,
  required TextStyle labelStyle,
  String? sub,
  required TextStyle subStyle,
  double hang = 0,
}) {
  return Directionality(
    textDirection: Directionality.of(context),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text.rich(
            TextSpan(
              children: [
                if (icon != null)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Icon(
                        icon,
                        size: labelStyle.fontSize,
                        color: labelStyle.color,
                      ),
                    ),
                  ),
                TextSpan(text: label),
              ],
            ),
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
          const SizedBox(height: 2),
        ],
        _hung(figure, figureStyle, hang),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(sub, textAlign: TextAlign.center, style: subStyle),
        ],
      ],
    ),
  );
}

/// The hero of a page you set something on: a fluted dial on the wall, 340 on a phone, 530 on a desktop, not in a card. The pigment arc runs
/// to the [value] you've set, a long ink tick marks [now], the ticks between them are lit: what's still to come. Two round keys stand in the
/// corners a circle leaves. [compact]: on a phone a small dial beside its words, about 130 tall, for a page where this isn't the job.
///
/// ```dart
/// NeumorphicDial(value: 21.5, min: 10, max: 30, now: 21, label: 'Rising to', labelIcon: NeumorphicGlyphs.flame, figure: '21.5°', sub: 'Now 21.0°', onDecrease: () {}, onIncrease: () {})
/// ```
class NeumorphicDial extends StatelessWidget {
  /// Creates a [NeumorphicDial].
  const NeumorphicDial({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.now,
    this.step,
    this.major,
    this.label,
    this.labelIcon,
    required this.figure,
    this.sub,
    this.caption,
    this.captionDetail,
    this.onDecrease,
    this.onIncrease,
    this.compact = false,
  });

  /// What's set, on [min]..[max].
  final double value, min, max;

  /// Where it is now: the scale's long tick. None if it has no reading.
  final double? now;

  /// A tick every [step]; a heavy, labelled tick every [major]. By default forty ticks and four spans.
  final double? step, major;

  /// One or two words over the figure, and its glyph. They go to the pigment: this is what's running.
  final String? label;

  /// The glyph displayed beside the dial label.
  final IconData? labelIcon;

  /// The big figure in the dome.
  final String figure;

  /// A short line under it.
  final String? sub;

  /// A line under the dial: what this will do, and when.
  final String? caption, captionDetail;

  /// Called when the decrease key is activated; null disables that key.
  final VoidCallback? onDecrease;

  /// Called when the increase key is activated; null disables that key.
  final VoidCallback? onIncrease;

  /// Whether to use the compact arrangement.
  final bool compact;

  List<_Tick> _ticks(double lo, double hi, double st, double mj, double? n) {
    final count = ((hi - lo) / st + 1e-6).floor();
    final out = <_Tick>[];
    for (var i = 0; i <= count; i++) {
      final v = lo + i * st;
      final isMajor = ((v - lo) / mj - ((v - lo) / mj).round()).abs() < 1e-6;
      final isMid =
          !isMajor &&
          ((v - lo) / (st * 2) - ((v - lo) / (st * 2)).round()).abs() < 1e-6;
      final on =
          n != null && v >= math.min(n, value) && v <= math.max(n, value);
      out.add((
        deg: _ang(v, lo, hi),
        rank: isMajor ? 2 : (isMid ? 1 : 0),
        on: on,
      ));
    }
    return out;
  }

  @override
  // A picture with things placed on it (its keys at its foot): one item for ui_core's keyline check, at its box.
  // An instrument's face: its scale's numerals grow with the text only so far (at twice the size they ran into their
  // ticks); its readout grows in full and stands under the face where it no longer fits in it.
  Widget build(BuildContext context) =>
      DesignKeylineFace(child: _instrument(context, _build));

  Widget _build(BuildContext context, TextScaler reader) {
    final t = NeumorphicTheme.of(context);
    final lo = min;
    final hi = max > min ? max : min + 1;
    final mj = major ?? _roundSpan(hi - lo);
    final st = step ?? mj / 8;
    final v = value.clamp(lo, hi).toDouble();

    if (compact && !t.desk) {
      // The band's words at the reader's own size, as every part's are; only the small dial's figure keeps the face's
      // limit (inside the instrument the words had stayed at 1.3 while the page round them doubled).
      return _atReader(
        context,
        reader,
        NeumorphicHeroBand(
          object: MediaQuery.withClampedTextScaling(
            maxScaleFactor: _faceTextScale,
            child: NeumorphicMiniDial(
              value: v,
              min: lo,
              max: hi,
              now: now,
              figure: figure,
              live: true,
              size: 112,
            ),
          ),
          // The small dial carries the figure; its words name it and don't print it again ('4' in the dial and '4'
          // beside it). With a caption of its own, the name stands over the caption.
          overline: caption == null ? null : label,
          title: caption ?? label ?? figure,
          body: sub,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeumorphicRoundButton(
                NeumorphicGlyphs.minus,
                label: NeumorphicLocalizations.of(context).less,
                onPressed: onDecrease,
              ),
              const SizedBox(width: 10),
              NeumorphicRoundButton(
                NeumorphicGlyphs.plus,
                label: NeumorphicLocalizations.of(context).more,
                onPressed: onIncrease,
              ),
            ],
          ),
        ),
      );
    }

    final large = t.desk;
    return LayoutBuilder(
      builder: (context, box) => _whole(
        context,
        t,
        math.min(large ? 530.0 : 340.0, box.maxWidth),
        box.maxWidth,
        lo,
        hi,
        st,
        mj,
        v,
        reader,
      ),
    );
  }

  Widget _whole(
    BuildContext context,
    NeumorphicThemeData t,
    double size,
    double column,
    double lo,
    double hi,
    double st,
    double mj,
    double v,
    TextScaler reader,
  ) {
    final c = t.colors;
    final large = t.desk;
    final flat = NeumorphicFlatScope.of(context);
    final labelStyle = (large ? t.textTheme.body : t.textTheme.micro).copyWith(
      fontWeight: FontWeight.w700,
      color: c.pigmentInk,
    );
    final subStyle = (large ? t.textTheme.body : t.textTheme.micro)
        .copyWith(fontWeight: FontWeight.w600, color: c.inkTertiary)
        .tabular;
    final big = large
        ? t.textTheme.text(112, 104, weight: FontWeight.w200, tracking: -.04)
        : t.textTheme.text(64, 64, weight: FontWeight.w200, tracking: -.04);
    final numbers = (large ? t.textTheme.caption : t.textTheme.micro)
        .copyWith(fontWeight: FontWeight.w700, color: c.inkSecondary)
        .tabular;

    final inline = _dialWordsFit(
      context,
      size * .46,
      size * .46,
      [(label, labelStyle), (figure, big), (sub, subStyle)],
      extraWidth: labelIcon == null ? 0 : (labelStyle.fontSize ?? 14) + 4,
      scaler: reader,
    );
    final readout = _atReader(
      context,
      reader,
      _dialReadout(
        context: context,
        figure: figure,
        figureStyle: big,
        label: label,
        icon: labelIcon,
        labelStyle: labelStyle,
        sub: sub,
        subStyle: subStyle,
        hang: inline ? (large ? 10 : 6) : 0,
      ),
    );

    final labels = <Widget>[];
    final tickHeight = math.max(
      20.0,
      MediaQuery.textScalerOf(context).scale(20),
    );
    final tickWidth = math.max(
      60.0,
      MediaQuery.textScalerOf(context).scale(60),
    );
    final spans = ((hi - lo) / mj + 1e-6).floor();
    for (var i = 0; i <= spans; i++) {
      final val = lo + i * mj;
      final word = NeumorphicLocalizations.of(context).formatNumber(val);
      final measure = TextPainter(
        text: TextSpan(text: word, style: numbers),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      // Keep the complete label rectangle inside the circular face. The usual
      // tick radius is unchanged; small faces bring enlarged words inward.
      final halfDiagonal =
          math.sqrt(
            measure.width * measure.width + measure.height * measure.height,
          ) /
          2;
      final labelRadius = math.min(
        160 * size / 400,
        math.max(0.0, size / 2 - halfDiagonal - 1),
      );
      measure.dispose();
      final p = neumorphicDialPoint(
        size / 2,
        size / 2,
        labelRadius,
        _ang(val, lo, hi),
      );
      labels.add(
        Positioned(
          left: p.dx - tickWidth / 2,
          top: p.dy - tickHeight / 2,
          width: tickWidth,
          height: tickHeight,
          child: Center(child: Text(word, maxLines: 1, style: numbers)),
        ),
      );
    }

    final dial = Directionality(
      textDirection: TextDirection.ltr,
      child: neumorphicOwnSize(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DialPainter(
                  c: c,
                  flat: flat,
                  large: large,
                  ticks: _ticks(lo, hi, st, mj, now),
                  arcTo: _ang(v, lo, hi),
                  gradFrom: const Offset(60, 330),
                  gradTo: const Offset(250, 60),
                  notch: now == null ? null : _ang(now!, lo, hi),
                  bead: _ang(v, lo, hi),
                  beadR: 12,
                ),
              ),
            ),
            ...labels,
            if (inline)
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(size * .27),
                  child: Center(child: readout),
                ),
              ),
          ],
        ),
      ),
    );

    final keySize = large ? 72.0 : 52.0;
    final keyIcon = large ? 28.0 : 20.0;
    // The keys belong to the dial: in a very wide column they stay beside it, not out at the column's edges. Where the
    // column is narrow they would sit on the plate's rim; they drop under its foot until a key's own radius of ground
    // shows between them and the plate.
    final stageWidth = math.min(column, size + 2 * keySize);
    final k = keySize / 2;
    final across = stageWidth / 2 - k;
    final reach = size / 2 + 2 * k;
    final drop = math.max(
      0.0,
      math.sqrt(math.max(0.0, reach * reach - across * across)) -
          (size / 2 - k),
    );
    final stage = Center(
      heightFactor: 1,
      child: SizedBox(
        width: stageWidth,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: drop),
              child: Center(heightFactor: 1, child: dial),
            ),
            // The keys stand by the scale's ends, less by its low end and more by its high: the scale turns clockwise
            // in any reading direction (a dial is not mirrored), so they do not swap in right to left.
            Positioned(
              left: 0,
              bottom: 0,
              child: NeumorphicRoundButton(
                NeumorphicGlyphs.minus,
                size: keySize,
                iconSize: keyIcon,
                label: NeumorphicLocalizations.of(context).less,
                onPressed: onDecrease,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: NeumorphicRoundButton(
                NeumorphicGlyphs.plus,
                size: keySize,
                iconSize: keyIcon,
                label: NeumorphicLocalizations.of(context).more,
                onPressed: onIncrease,
              ),
            ),
          ],
        ),
      ),
    );
    return NeumorphicColumn(
      gap: large ? 28 : 24,
      children: [
        stage,
        if (!inline) readout,
        if (caption != null) _Say(say: caption!, note: captionDetail),
      ],
    );
  }
}

/// A scale for a dial that wasn't given one: the smallest 1, 2 or 5 times a power of ten that makes at most six spans, so 40 to 90 reads 40, 50, 60 and never 52.5.
double _roundSpan(double range) {
  final want = range / 6;
  final unit = math.pow(10, (math.log(want) / math.ln10).floor()).toDouble();
  for (final k in const [1.0, 2.0, 5.0]) {
    if (k * unit >= want - 1e-9) return k * unit;
  }
  return 10 * unit;
}

class _Say extends StatelessWidget {
  const _Say({required this.say, this.note, this.noteMark});
  final String say;
  final String? note;
  final Widget? noteMark;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          say,
          textAlign: TextAlign.center,
          style: t.textTheme.value.tabular,
        ),
        const SizedBox(height: 2),
        if (note != null)
          noteMark == null
              ? Text(
                  note!,
                  textAlign: TextAlign.center,
                  style: t.textTheme.caption.tabular,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    noteMark!,
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        note!,
                        textAlign: TextAlign.center,
                        style: t.textTheme.caption.tabular,
                      ),
                    ),
                  ],
                ),
      ],
    );
  }
}

/// The same dial counting a span of time: what's on now. 240 on a phone, 300 on a desktop. A tick a minute; the arc to where you are; the
/// minutes still to come lit in the pigment. The span's two ends stand in the corners a circle leaves. [compact]: on a phone a small
/// dial beside its words, about 130 tall, so the page's own job shows on the first screen.
///
/// ```dart
/// NeumorphicSpanDial(start: '12:30', end: '13:15', elapsed: 35, total: 45, tag: '13:05', figure: '10', unit: 'min left', title: 'A thing that is on now', note: 'A place')
/// ```
class NeumorphicSpanDial extends StatelessWidget {
  /// Creates a [NeumorphicSpanDial].
  const NeumorphicSpanDial({
    super.key,
    required this.start,
    required this.end,
    required this.elapsed,
    required this.total,
    this.tag,
    required this.figure,
    this.unit,
    this.title,
    this.note,
    this.noteMark,
    this.compact = false,
  });

  /// The formatted start of the time span.
  final String start;

  /// The formatted end of the time span.
  final String end;

  /// How far along, of [total]: minutes, or any unit.
  final double elapsed, total;

  /// A short line over the figure, in the pigment: the time now.
  final String? tag;

  /// The formatted value to display.
  final String figure;

  /// Under the figure: 'min left'.
  final String? unit;

  /// What the span is, under the dial.
  final String? title, note;

  /// A shape mark before [note].
  final Widget? noteMark;

  /// Whether to use the compact arrangement.
  final bool compact;
  @override
  Widget build(BuildContext context) => _instrument(context, _build);

  Widget _build(BuildContext context, TextScaler reader) {
    final t = NeumorphicTheme.of(context);
    final whole = total > 0 ? total : 1.0;
    final gone = elapsed.clamp(0, whole).toDouble();
    if (compact && !t.desk) {
      // The band's words at the reader's own size, as every part's are; only the small dial's figure keeps the face's
      // limit (inside the instrument the words had stayed at 1.3 while the page round them doubled).
      return _atReader(
        context,
        reader,
        NeumorphicHeroBand(
          object: MediaQuery.withClampedTextScaling(
            maxScaleFactor: _faceTextScale,
            child: NeumorphicMiniDial(
              value: gone,
              min: 0,
              max: whole,
              figure: figure,
              live: true,
              size: 112,
            ),
          ),
          overline: tag,
          title: title ?? figure,
          body: unit == null ? note : '$figure $unit, $start to $end',
        ),
      );
    }
    final large = t.desk;
    return LayoutBuilder(
      builder: (context, box) => _whole(
        context,
        t,
        math.min(large ? 300.0 : 240.0, box.maxWidth),
        whole,
        gone,
        reader,
      ),
    );
  }

  Widget _whole(
    BuildContext context,
    NeumorphicThemeData t,
    double size,
    double whole,
    double gone,
    TextScaler reader,
  ) {
    final c = t.colors;
    final large = t.desk;
    final flat = NeumorphicFlatScope.of(context);
    final n = whole <= 120 ? whole.round() : 60;
    final each = whole / n;
    final ticks = <_Tick>[
      for (var m = 0; m <= n; m++)
        (
          deg: -135 + 270 * m / n,
          rank: (m % 15 == 0) ? 2 : (m % 5 == 0 ? 1 : 0),
          on: m * each >= gone,
        ),
    ];
    final tagStyle = (large ? t.textTheme.caption : t.textTheme.micro)
        .copyWith(fontWeight: FontWeight.w700, color: c.pigmentInk)
        .tabular;
    final subStyle = (large ? t.textTheme.caption : t.textTheme.micro).copyWith(
      fontWeight: FontWeight.w600,
      color: c.inkTertiary,
    );
    final big = large
        ? t.textTheme.text(64, 62, weight: FontWeight.w200, tracking: -.04)
        : t.textTheme.text(48, 48, weight: FontWeight.w200, tracking: -.04);
    final ends = t.textTheme.micro
        .copyWith(fontWeight: FontWeight.w700, color: c.inkSecondary)
        .tabular;
    final inline = _dialWordsFit(context, size * .46, size * .46, [
      (tag, tagStyle),
      (figure, big),
      (unit, subStyle),
    ], scaler: reader);
    final readout = _atReader(
      context,
      reader,
      _dialReadout(
        context: context,
        figure: figure,
        figureStyle: big,
        label: tag,
        labelStyle: tagStyle,
        sub: unit,
        subStyle: subStyle,
      ),
    );
    final deg = -135 + 270 * gone / whole;
    final dial = Directionality(
      textDirection: TextDirection.ltr,
      child: neumorphicOwnSize(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DialPainter(
                  c: c,
                  flat: flat,
                  large: false,
                  ticks: ticks,
                  arcTo: deg,
                  gradFrom: const Offset(60, 330),
                  gradTo: const Offset(330, 160),
                  bead: deg,
                  beadR: 9,
                ),
              ),
            ),
            if (inline)
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(size * .27),
                  child: Center(child: readout),
                ),
              ),
          ],
        ),
      ),
    );
    final stage = Center(
      heightFactor: 1,
      child: SizedBox(
        width: size,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              dial,
              Positioned(
                left: 0,
                bottom: 0,
                child: Text(start, maxLines: 1, style: ends),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Text(end, maxLines: 1, style: ends),
              ),
            ],
          ),
        ),
      ),
    );
    return NeumorphicColumn(
      gap: large ? 20 : 18,
      children: [
        stage,
        if (!inline) readout,
        if (title != null) _Say(say: title!, note: note, noteMark: noteMark),
      ],
    );
  }
}

class _MiniPainter extends CustomPainter {
  _MiniPainter(this.c, this.flat, this.to, this.tick, this.live);
  final NeumorphicColors c;
  final bool flat, live;
  final double to;
  final double? tick;
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 120;
    final mid = s.center(Offset.zero);
    neumorphicPaintPressed(
      canvas,
      Path()..addOval(Offset.zero & s),
      c,
      light: (const Offset(-5, -5), 11),
      dark: (const Offset(5, 5), 11),
      flat: flat,
    );
    if (flat) {
      canvas.drawOval(Offset.zero & s, neumorphicStrokePaint(c.quiet, 1));
    }
    canvas.drawPath(
      neumorphicDialArc(mid.dx, mid.dy, 49 * k, -135, to),
      neumorphicStrokePaint(live ? c.pigment : c.inkSecondary, 8 * k),
    );
    if (tick != null) {
      canvas.drawLine(
        neumorphicDialPoint(mid.dx, mid.dy, 41.5 * k, tick!),
        neumorphicDialPoint(mid.dx, mid.dy, 56.5 * k, tick!),
        neumorphicStrokePaint(c.ink, 2.6 * k),
      );
    }
    final dome = Rect.fromCircle(center: mid, radius: s.width * .31);
    neumorphicPaintRaised(
      canvas,
      Path()..addOval(dome),
      c,
      light: (const Offset(-3, -3), 7),
      lightColor: c.highlightSoft,
      dark: (const Offset(4, 4), 10),
      face: cssRadial(
        dome,
        .34,
        .28,
        [c.domeLight, c.domeMid, c.domeDark],
        const [0, .5, 1],
      ),
      flat: flat,
    );
    if (flat) canvas.drawOval(dome, neumorphicStrokePaint(c.quiet, 1));
  }

  @override
  bool shouldRepaint(_MiniPainter o) =>
      o.c != c ||
      o.flat != flat ||
      o.to != to ||
      o.tick != tick ||
      o.live != live;
}

/// The small dial, by itself: a moat, an arc in it to what's set, an ink tick at the reading, a dome with the figure. 104 by default. [live]: the arc
/// is in the pigment, for the one that's running. Off, it's ink.
///
/// ```dart
/// NeumorphicMiniDial(value: 21.5, min: 10, max: 30, now: 21, figure: '21.0°', live: true)
/// ```
class NeumorphicMiniDial extends StatelessWidget {
  /// Creates a [NeumorphicMiniDial].
  const NeumorphicMiniDial({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.now,
    required this.figure,
    this.live = false,
    this.size = 104,
  });

  /// The current value on the dial scale.
  final double value;

  /// The lower bound of the dial scale.
  final double min;

  /// The upper bound of the dial scale.
  final double max;

  /// An optional reference marker on the dial scale.
  final double? now;

  /// The formatted value to display.
  final String figure;

  /// Whether to emphasize the active state with the pigment colour.
  final bool live;

  /// The diameter of the dial face in logical pixels.
  final double size;
  @override
  Widget build(BuildContext context) => _instrument(context, _build);

  Widget _build(BuildContext context, TextScaler reader) {
    final t = NeumorphicTheme.of(context);
    final hi = max > min ? max : min + 1;
    final style = t.textTheme.text(
      20,
      24,
      weight: FontWeight.w600,
      tracking: -.01,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = math.min(size, constraints.maxWidth);
        final inline = _dialWordsFit(context, diameter * .58, diameter * .58, [
          (figure, style),
        ], scaler: reader);
        return neumorphicOwnSize(
          width: diameter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: diameter,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: CustomPaint(
                        painter: _MiniPainter(
                          t.colors,
                          NeumorphicFlatScope.of(context),
                          _ang(value, min, hi),
                          now == null ? null : _ang(now!, min, hi),
                          live,
                        ),
                      ),
                    ),
                    if (inline)
                      Padding(
                        padding: EdgeInsets.all(diameter * .21),
                        child: Center(
                          child: _atReader(
                            context,
                            reader,
                            _hung(figure, style, 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!inline) ...[
                const SizedBox(height: 6),
                _atReader(context, reader, _hung(figure, style, 0)),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// One reading of a few, on the wall: the small dial, a name and a state under it. Set three in a `NeumorphicGridOf` straight into the wall, no slab.
///
/// ```dart
/// NeumorphicGauge(value: 21.5, min: 10, max: 30, now: 21, figure: '21.0°', name: 'A zone', note: 'Rising to 21.5°', noteIcon: NeumorphicGlyphs.flame, live: true)
/// ```
class NeumorphicGauge extends StatelessWidget {
  /// Creates a [NeumorphicGauge].
  const NeumorphicGauge({
    super.key,
    this.focusNode,
    this.autofocus = false,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.now,
    required this.figure,
    required this.name,
    this.note,
    this.noteIcon,
    this.live = false,
    this.onPressed,
  });

  /// The current value on the gauge scale.
  final double value;

  /// The lower bound of the gauge scale.
  final double min;

  /// The upper bound of the gauge scale.
  final double max;

  /// An optional reference marker on the gauge scale.
  final double? now;

  /// The formatted value to display.
  final String figure;

  /// The name displayed for this item.
  final String name;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// The glyph displayed beside the supporting note.
  final IconData? noteIcon;

  /// Whether to emphasize the active state with the pigment colour.
  final bool live;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  // Its name and note stand under its small dial and grow with the text in full; the dial holds its own face.
  Widget build(BuildContext context) => _build(context);

  Widget _build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final noteStyle = t.textTheme.micro.copyWith(
      color: live ? c.pigmentInk : c.inkTertiary,
    );
    // Its own width where it is given room (a row, a wrap), so its face and ring hug the dial; a grid cell's tight
    // width still centres it.
    final tile = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          widthFactor: 1,
          heightFactor: 1,
          child: NeumorphicMiniDial(
            value: value,
            min: min,
            max: max,
            now: now,
            figure: figure,
            live: live,
            size: t.desk ? 120 : 104,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          style: t.textTheme.text(14, 18, weight: FontWeight.w700),
        ),
        if (note != null) ...[
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                if (noteIcon != null)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Icon(noteIcon, size: 14, color: noteStyle.color),
                    ),
                  ),
                TextSpan(text: note),
              ],
            ),
            textAlign: TextAlign.center,
            style: noteStyle,
          ),
        ],
      ],
    );
    return onPressed == null
        ? tile
        : NeumorphicTap(
            focusNode: focusNode,
            autofocus: autofocus,
            onPressed: onPressed,
            label: name,
            child: tile,
          );
  }
}

class _KnobPainter extends CustomPainter {
  _KnobPainter(this.c, this.flat, this.value);
  final NeumorphicColors c;
  final bool flat;
  final double value;
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 120;
    final mid = s.center(Offset.zero);
    for (var i = 0; i < 11; i++) {
      final a = -135.0 + 27 * i;
      final on = i / 10 <= value + 1e-9;
      canvas.drawLine(
        neumorphicDialPoint(mid.dx, mid.dy, 52 * k, a),
        neumorphicDialPoint(mid.dx, mid.dy, 57 * k, a),
        neumorphicStrokePaint(on ? c.pigment : c.quiet, 2),
      );
    }
    final cap = Rect.fromCircle(center: mid, radius: s.width * .34);
    neumorphicPaintRaised(
      canvas,
      Path()..addOval(cap),
      c,
      light: (const Offset(-3, -3), 7),
      dark: (const Offset(4, 4), 9),
      face: cssRadial(
        cap,
        .34,
        .28,
        [c.domeLight, c.domeMid, c.domeDark],
        const [0, .5, 1],
      ),
      flat: flat,
    );
    if (flat) canvas.drawOval(cap, neumorphicStrokePaint(c.quiet, 1));
    final a = -135 + 270 * value;
    // The pointer stands on the cap, 4 in from its rim: at .3 of the width it straddled the rim, half on the cap.
    final at = neumorphicDialPoint(mid.dx, mid.dy, cap.width / 2 - 3.5 - 4, a);
    canvas.drawCircle(at, 3.5, neumorphicFillPaint(c.pigment));
  }

  @override
  bool shouldRepaint(_KnobPainter o) =>
      o.c != c || o.flat != flat || o.value != value;
}

/// A round knob, 76: a level you turn, on a scale of ticks that light as it goes.
///
/// ```dart
/// NeumorphicKnob(value: .38)
/// ```
class NeumorphicKnob extends StatelessWidget {
  /// Creates a [NeumorphicKnob].
  const NeumorphicKnob({super.key, required this.value});

  /// 0 to 1.
  final double value;
  @override
  Widget build(BuildContext context) {
    final c = NeumorphicTheme.of(context).colors;
    return neumorphicOwnSize(
      width: 76,
      height: 76,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: CustomPaint(
          painter: _KnobPainter(
            c,
            NeumorphicFlatScope.of(context),
            value.clamp(0, 1).toDouble(),
          ),
        ),
      ),
    );
  }
}

/// A knob with its name and its figure beside it.
///
/// ```dart
/// NeumorphicKnobRow(value: .38, label: 'Level', figure: '38%')
/// ```
class NeumorphicKnobRow extends StatelessWidget {
  /// Creates a [NeumorphicKnobRow].
  const NeumorphicKnobRow({
    super.key,
    required this.value,
    required this.label,
    required this.figure,
  });

  /// The normalized knob setting, from zero to one.
  final double value;

  /// The text identifying this item or control.
  final String label;

  /// The formatted value to display.
  final String figure;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return NeumorphicFitRow(
      fill: 1,
      gap: NeumorphicTheme.of(context).desk ? 12 : 10,
      shrink: true,
      children: [
        NeumorphicKnob(value: value),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.textTheme.micro),
            Text(figure, style: t.textTheme.value.tabular),
          ],
        ),
      ],
    );
  }
}

/// A signature's compact form: the object beside its words, straight into the wall, about 130 tall on a phone. The stars draw one with `compact: true`.
///
/// ```dart
/// NeumorphicHeroBand(object: NeumorphicMiniDial(value: 40, figure: '40'), overline: 'Now', title: 'A title', body: 'A line about it')
/// ```
class NeumorphicHeroBand extends StatelessWidget {
  /// Creates a [NeumorphicHeroBand].
  const NeumorphicHeroBand({
    super.key,
    required this.object,
    required this.title,
    this.overline,
    this.body,
    this.trailing,
  });

  /// The featured dial, illustration or other supplied widget.
  final Widget object;

  /// The primary heading.
  final String title;

  /// Short text displayed above the main heading.
  final String? overline;

  /// Supporting text below the title.
  final String? body;

  /// Optional content after the text block.
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120),
      child: NeumorphicBeside(
        object: object,
        gap: 18,
        minWords: 130,
        maxObject: .5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (overline != null)
              Text(
                overline!,
                style: t.textTheme.micro.copyWith(
                  fontWeight: FontWeight.w700,
                  color: t.colors.pigmentInk,
                ),
              ),
            Text(title, style: t.textTheme.value),
            if (body != null) Text(body!, style: t.textTheme.caption.tabular),
            if (trailing != null) ...[const SizedBox(height: 10), trailing!],
          ],
        ),
      ),
    );
  }
}
