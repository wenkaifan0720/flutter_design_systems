// Numbers, inked: bars of dots, a vote, a flow true to its amounts, stacked shares, a pie, counted units. Every part takes plain
// numbers and says nothing about what they count: a figure's words are the page's.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import '../balloons.dart';
import '../internal/geometry.dart';
import '../heads.dart';
import '../layout.dart';
import '../people.dart';
import '../print.dart';
import '../theme.dart';
import '../styled.dart';

/// Which ink fills a bar. `dots` the group's halftone, `lead` the lamp with drama dots, `you` the flat act.
enum ComicBarFill {
  /// Halftone dots on the secondary tint.
  dots,

  /// The emphasized solid ink.
  leading,

  /// The viewer's action color.
  currentUser,
}

(Color, Color?) _barInks(ComicBarFill ink, ComicColors c) => switch (ink) {
  ComicBarFill.dots => (c.shadeTint, c.shade),
  ComicBarFill.leading => (c.caption, c.lampDot),
  ComicBarFill.currentUser => (c.primary, null),
};

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.share,
    required this.fill,
    required this.dot,
    required this.track,
    required this.line,
    required this.edge,
    required this.pitch,
    required this.radius,
    required this.dpr,
    required this.rtl,
    required this.shape,
  });
  final OutlinedBorder shape;
  final double share, edge, pitch, radius, dpr;
  final Color fill, track, line;
  final Color? dot;
  final bool rtl;
  @override
  void paint(Canvas canvas, Size s) {
    final inner = (Offset.zero & s).deflate(edge);
    final inside = comicInsetShape(shape, edge).getOuterPath(inner);
    canvas.drawPath(inside, fillPaint(track));
    canvas.save();
    canvas.clipPath(inside);
    final w = inner.width * share.clamp(0, 1);
    if (w > 0) {
      final part = rtl
          ? Rect.fromLTWH(inner.right - w, inner.top, w, inner.height)
          : Rect.fromLTWH(inner.left, inner.top, w, inner.height);
      canvas.drawRect(part, fillPaint(fill));
      if (dot != null) {
        ComicScreenGrid(pitch, radius, dpr).paint(canvas, part, dot!);
      }
      if (share < 1) {
        final x = rtl ? part.left + edge / 2 : part.right - edge / 2;
        canvas.drawLine(
          Offset(x, inner.top),
          Offset(x, inner.bottom),
          strokePaint(line, edge),
        );
      }
    }
    canvas.restore();
    shape
        .copyWith(
          side: BorderSide(color: line, width: edge),
        )
        .paint(canvas, Offset.zero & s);
  }

  @override
  bool shouldRepaint(_BarPainter o) =>
      o.share != share ||
      o.fill != fill ||
      o.dot != dot ||
      o.track != track ||
      o.line != line ||
      o.dpr != dpr ||
      o.rtl != rtl ||
      o.pitch != pitch ||
      o.radius != radius ||
      o.shape != shape ||
      o.edge != edge;
}

/// A bar in a box: its fill true to [value] of [of], its dots on whole device pixels. [height] up from 18. It takes the width it's
/// given. A zero value is a bare track; a value past the whole fills it. Words go beside it, not on it, unless a `ComicStamp`:
/// give it a [label] and it stands under its own head, the label at the start and its [figure] (the value if left out)
/// at the end, read together.
///
/// ```dart
/// ComicBar(value: 5, of: 6, ink: ComicBarFill.leading, label: 'Pages inked', figure: '5 of 6')
/// ```
class ComicBar extends StatelessWidget {
  /// Creates a [ComicBar].
  const ComicBar({
    super.key,
    required this.value,
    required this.of,
    this.ink = ComicBarFill.dots,
    this.height = 22,
    this.stamp,
    this.label,
    this.figure,
  });

  /// What the bar measures, in its head at the start.
  final String? label;

  /// The figure in its head at the end; the value if left out. Shown only with a [label].
  final String? figure;

  /// [value]: the current value represented by the control or record. [of]: the total used to normalize the displayed value.
  final num value, of;

  /// The ink treatment used by this figure.
  final ComicBarFill ink;

  /// The allocated height in logical pixels.
  final double height;

  /// A word on it: stands just past the fill, or inside it if the track has no room.
  final String? stamp;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final (fill, dot) = _barInks(ink, c);
    final share = of <= 0 ? 0.0 : (value / of).clamp(0.0, 1.0).toDouble();
    final dense = height <= 18;
    final big = height >= 28;
    final bar = CustomPaint(
      painter: _BarPainter(
        share: share,
        fill: fill,
        dot: dot,
        track: c.track,
        line: c.nightLine,
        edge: dense ? 2 : 2.5,
        pitch: big ? 11 : 8,
        radius: big ? 2.6 : 1.8,
        dpr: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
        rtl: Directionality.of(context) == TextDirection.rtl,
        shape: t.shapes.capsule,
      ),
    );
    if (label != null) {
      return LimitedBox(
        maxWidth: 240,
        child: MergeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.type.text(
                        14,
                        1.2,
                        weight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    figure ?? '$value',
                    textAlign: TextAlign.end,
                    style: t.type.data,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ComicBar(
                value: value,
                of: of,
                ink: ink,
                height: height,
                stamp: stamp,
              ),
            ],
          ),
        ),
      );
    }
    return LimitedBox(
      maxWidth: 240,
      child: SizedBox(
        height: height,
        child: stamp == null
            ? SizedBox.expand(child: bar)
            : LayoutBuilder(
                builder: (context, box) {
                  final word = ComicStamp(stamp!, tight: true);
                  final x = box.maxWidth * share;
                  final inside = box.maxWidth - x < 66;
                  return Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.expand,
                    children: [
                      bar,
                      PositionedDirectional(
                        start: inside ? null : x + 4,
                        end: inside ? box.maxWidth - x + 5 : null,
                        top: 0,
                        bottom: 0,
                        child: Center(widthFactor: 1, child: word),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// A row of a bar list: a head or a word, a name, its bar, its figure.
class ComicBarEntry {
  /// Creates a [ComicBarEntry].
  const ComicBarEntry(
    this.label,
    this.value, {
    this.figure,
    this.leading,
    this.suffix,
    this.isCurrentUser = false,
    this.isLeading = false,
  });

  /// The visible or spoken name of the component.
  final String label;

  /// The current value represented by the control or record.
  final num value;

  /// A small thing right after the label, as a star after a score.
  final Widget? suffix;

  /// The figure's words; the value if left out.
  final String? figure;

  /// A `ComicPerson(size: 28)`, usually.
  final Widget? leading;

  /// [isCurrentUser]: marks content that belongs to the current viewer. [isLeading]: whether this entry receives the leading emphasis.
  final bool isCurrentUser, isLeading;
}

/// A ranked list of bars on one scale: a roll call, a rating's spread, the top of anything. [of] is the whole; the largest if
/// left out. An empty list draws nothing.
///
/// ```dart
/// ComicBarList(of: 27, entries: const [ComicBarEntry('Sam', 25), ComicBarEntry('You', 24, isCurrentUser: true)])
/// ```
class ComicBarList extends StatelessWidget {
  /// Creates a [ComicBarList].
  const ComicBarList({
    super.key,
    required this.entries,
    this.of,
    this.labelWidth,
  });

  /// The entries displayed in order.
  final List<ComicBarEntry> entries;

  /// The total used to normalize the displayed value.
  final num? of;

  /// The names' column: 52 on a phone and 60 on a desktop unless you set it.
  final double? labelWidth;
  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final t = ComicTheme.of(context);
    final whole =
        of ?? entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final hasHead = entries.any((e) => e.leading != null);
    return ComicColumn(
      children: [
        for (final e in entries)
          Padding(
            padding: EdgeInsets.symmetric(vertical: t.desk ? 6 : 5),
            child: Row(
              children: [
                if (hasHead) ...[
                  SizedBox(width: t.desk ? 30 : 28, child: e.leading),
                  const SizedBox(width: 8),
                ],
                SizedBox(
                  width: labelWidth ?? (t.desk ? 60 : 52),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          e.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.type.text(
                            14,
                            1.2,
                            weight: FontWeight.w700,
                            color: e.isCurrentUser
                                ? t.colors.primaryText
                                : t.colors.text,
                          ),
                        ),
                      ),
                      if (e.suffix != null) ...[
                        const SizedBox(width: 2),
                        e.suffix!,
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ComicBar(
                    value: e.value,
                    of: whole,
                    height: 18,
                    ink: e.isCurrentUser
                        ? ComicBarFill.currentUser
                        : e.isLeading
                        ? ComicBarFill.leading
                        : ComicBarFill.dots,
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: t.desk ? 26 : 24),
                  child: Text(
                    e.figure ?? '${e.value}',
                    textAlign: TextAlign.end,
                    style: t.type.data,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One option of a [ComicTally].
class ComicVote {
  /// Creates a [ComicVote].
  const ComicVote(
    this.label, {
    required this.count,
    this.note,
    this.people = const [],
    this.isLeading = false,
    this.stamp,
  });

  /// The visible or spoken name of the component.
  final String label;

  /// [note]: secondary explanatory text. [stamp]: an optional stamped label beside the chart.
  final String? note, stamp;

  /// The count printed in the main figure.
  final int count;

  /// People displayed beside this content.
  final List<ComicPerson> people;

  /// In front: its count pops off a burst, and its bar takes the lamp.
  final bool isLeading;
}

/// A question said out loud, its options with bars true to their counts and the people behind them, and who's still to answer.
/// Stands in a panel. [of] is how many could answer. It reads for any vote, ranking or tally of people.
///
/// ```dart
/// ComicTally(question: 'Which weekend?', subtitle: '5 of 6 voted', of: 6, options: const [ComicVote('The first', count: 5, isLeading: true, stamp: 'Leads'), ComicVote('The second', count: 2)], waiting: 'Waiting on one', yours: 'You picked 1')
/// ```
class ComicTally extends StatelessWidget {
  /// Creates a [ComicTally].
  const ComicTally({
    super.key,
    this.question,
    this.subtitle,
    required this.of,
    required this.options,
    this.waitingPeople = const [],
    this.waiting,
    this.yours,
    this.yoursIcon,
  });

  /// [question]: the question heading the tally. [subtitle]: secondary information printed with the entry. [waiting]: the number of people who have not answered. [yours]: the viewer's response or share.
  final String? question, subtitle, waiting, yours;

  /// The total used to normalize the displayed value.
  final int of;

  /// Choices available to the user.
  final List<ComicVote> options;

  /// People who have not answered yet.
  final List<ComicPerson> waitingPeople;

  /// The glyph identifying the viewer's response.
  final IconData? yoursIcon;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    return ComicColumn(
      children: [
        if (question != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ComicLetters(question!, style: t.type.question),
          ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              subtitle!,
              style: t.type.text(
                14,
                1.35,
                weight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
          ),
        for (var i = 0; i < options.length; i++)
          ComicGrow(
            child: _Option(
              options[i],
              of,
              first: i == 0 && (question != null || subtitle == null),
              people: options.any((o) => o.people.isNotEmpty),
            ),
          ),
        if (waiting != null || yours != null)
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.divider, width: 2)),
            ),
            // The note takes what the answer leaves it, and the answer stays whole on its line.
            child: ComicFitRow(
              fill: waitingPeople.isEmpty ? 0 : 1,
              gap: 10,
              fillShare: .4,
              children: [
                if (waitingPeople.isNotEmpty)
                  ComicPeople(waitingPeople, max: 3),
                Text(waiting ?? '', style: t.type.small),
                if (yours != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (yoursIcon != null) ...[
                        Icon(yoursIcon, size: 14, color: c.primaryText),
                        const SizedBox(width: 3),
                      ],
                      Flexible(
                        child: Text(
                          yours!.toUpperCase(),
                          style: t.type.text(
                            12,
                            1.3,
                            weight: FontWeight.w800,
                            tracking: .05,
                            color: c.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option(this.o, this.of, {required this.first, required this.people});
  final ComicVote o;
  final int of;
  final bool first, people;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final name = Text(o.label, style: t.type.title);
    final note = o.note == null
        ? null
        : Text(
            o.note!,
            style: t.type.small.copyWith(color: c.textSecondary, height: 1.5),
          );
    // A word of a note follows the name, whole. A longer one has a line of its own.
    final label = note == null
        ? name
        : o.note!.length <= 12
        ? Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [name, note],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [name, note],
          );
    // The count's plate is bigger than its row and stands out over the row's top and end, as a stamp would.
    final count = comicOwnSize(
      width: 36,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            top: -6,
            end: -4,
            width: 40,
            height: 34,
            child: o.isLeading
                ? OverflowBox(
                    maxWidth: 48,
                    maxHeight: 42,
                    child: ComicPop('${o.count}', seed: 2),
                  )
                : Center(
                    child: Text(
                      '${o.count}',
                      style: t.type.letter(
                        24,
                        lineHeight: 1,
                        tracking: .03,
                        color: c.text,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
    return Container(
      alignment: AlignmentDirectional.bottomStart,
      padding: const EdgeInsets.only(top: 9, bottom: 10),
      decoration: first
          ? null
          : BoxDecoration(
              border: Border(top: BorderSide(color: c.divider, width: 2)),
            ),
      child: ComicColumn(
        children: [
          Row(
            children: [
              Expanded(child: label),
              const SizedBox(width: 8),
              count,
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ComicBar(
                  value: o.count,
                  of: of,
                  height: 28,
                  ink: o.isLeading ? ComicBarFill.leading : ComicBarFill.dots,
                  stamp: o.stamp,
                ),
              ),
              if (people) ...[
                const SizedBox(width: 8),
                // One width in every option: bars are only true to their counts if they're all the same length.
                SizedBox(
                  width: 134,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    heightFactor: 1,
                    child: ComicPeople(o.people, max: 5),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One source of a [ComicFlow].
class ComicFlowFrom {
  /// Creates a [ComicFlowFrom].
  const ComicFlowFrom(
    this.name,
    this.amount, {
    this.figure,
    this.person,
    this.isCurrentUser = false,
  });

  /// The displayed name of this record or person.
  final String name;

  /// The amount represented by this entry.
  final num amount;

  /// How the amount reads; the number if left out.
  final String? figure;

  /// The person associated with this content.
  final ComicPerson? person;

  /// Marks content that belongs to the current viewer.
  final bool isCurrentUser;
}

class _FlowArt extends CustomPainter {
  _FlowArt({
    required this.rows,
    required this.stack,
    required this.fill,
    required this.you,
    required this.line,
    required this.mine,
    required this.rtl,
  });
  final List<(double, double)> rows; // (row height, ribbon height)
  final double stack;
  final Color fill, you, line;
  final List<bool> mine;
  final bool rtl;
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    double x(double v) => rtl ? w - v : v;
    final edge = strokePaint(line, 1.8);
    final tall = rows.fold<double>(0, (a, r) => a + r.$1);
    var y = (s.height - tall) / 2;
    var at = (s.height - stack) / 2;
    for (var i = 0; i < rows.length; i++) {
      final (rh, b) = rows[i];
      final y0 = y + (rh - b) / 2, y1 = y0 + b;
      final s0 = at, s1 = at + b;
      final p = Path()
        ..moveTo(x(0), y0)
        ..cubicTo(x(w * .55), y0, x(w * .45), s0, x(w), s0)
        ..lineTo(x(w), s1)
        ..cubicTo(x(w * .45), s1, x(w * .55), y1, x(0), y1)
        ..close();
      canvas.drawPath(p, fillPaint(mine[i] ? you : fill));
      canvas.drawPath(p, edge);
      at = s1;
      y += rh;
    }
  }

  @override
  bool shouldRepaint(_FlowArt o) =>
      o.stack != stack ||
      o.fill != fill ||
      o.you != you ||
      o.line != line ||
      o.rtl != rtl ||
      !listEquals(o.rows, rows) ||
      !listEquals(o.mine, mine);
}

/// Many amounts flowing into one, as ribbons drawn to scale: each ribbon's width is its amount, and they stack to the total, so
/// a reader sees who gives most. It can be money, hours or tonnes: [figure] words are yours. It keeps to any width, and any
/// number of rows scales to its height limit. No rows draws nothing.
///
/// ```dart
/// ComicFlow(into: 'Sam', intoPerson: const ComicPerson(initials: 'SD', size: 64), intoFigure: '+€317', from: const [ComicFlowFrom('You', 19, figure: '€19', isCurrentUser: true), ComicFlowFrom('Alex', 133, figure: '€133')])
/// ```
class ComicFlow extends StatelessWidget {
  /// Creates a [ComicFlow].
  const ComicFlow({
    super.key,
    required this.from,
    required this.into,
    this.intoFigure,
    this.intoPerson,
    this.perUnit,
  });

  /// The sources represented by the flow.
  final List<ComicFlowFrom> from;

  /// The flow's destination label.
  final String into;

  /// The figure printed at the flow's destination.
  final String? intoFigure;

  /// The person displayed at the flow's destination.
  final ComicPerson? intoPerson;

  /// Pixels per unit of amount, if you want them exact; else the largest stack is held near 165 tall.
  final double? perUnit;
  @override
  Widget build(BuildContext context) {
    if (from.isEmpty) return const SizedBox.shrink();
    final t = ComicTheme.of(context);
    final c = t.colors;
    final total = from.fold<num>(0, (a, b) => a + b.amount).toDouble();
    final k = perUnit ?? (total <= 0 ? 1.0 : 165 / total);
    const gap = 14.0;
    double textHeight(String words, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: words, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final nameStyle = t.type.text(14, 1.1, weight: FontWeight.w800);
    final destinationStyle = t.type.text(14, 1.25, weight: FontWeight.w800);
    final rows = [
      for (final f in from)
        (
          math.max(
            math.max(
              50.0,
              math.max(
                f.person?.size ?? 0,
                textHeight(f.name, nameStyle) +
                    textHeight(f.figure ?? '${f.amount}', t.type.data),
              ),
            ),
            f.amount * k + gap,
          ),
          f.amount * k,
        ),
    ];
    final rowsHeight = rows.fold<double>(0, (a, r) => a + r.$1);
    final stack = total * k;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final figureSize = t.desk ? 28.0 : 24.0;
    final popW = t.desk ? 136.0 : 118.0, popH = t.desk ? 84.0 : 76.0;
    final roundel = intoPerson?.size ?? 0.0;
    final rightHeight =
        (intoPerson == null ? 0.0 : roundel + 4) +
        math.max(18, textHeight(into, destinationStyle)) +
        (intoFigure == null ? 0.0 : popH);
    final height = math.max(rowsHeight, rightHeight);
    return _ThreeCells(
      leftWidth: t.desk ? 130 : 112,
      rightWidth: t.desk ? 110 : 92,
      height: height,
      left: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < from.length; i++)
            SizedBox(
              height: rows[i].$1,
              child: Row(
                children: [
                  if (from[i].person != null) ...[
                    from[i].person!,
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          from[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: nameStyle,
                        ),
                        Text(
                          from[i].figure ?? '${from[i].amount}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.type.data.copyWith(
                            color: from[i].isCurrentUser
                                ? c.primaryText
                                : c.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      middle: CustomPaint(
        painter: _FlowArt(
          rows: rows,
          stack: stack,
          fill: c.shade,
          you: c.primary,
          line: c.nightLine,
          mine: [for (final f in from) f.isCurrentUser],
          rtl: rtl,
        ),
      ),
      right: Row(
        children: [
          // The ribbons' end stands on a bar on a desktop; a phone hasn't the room.
          if (t.desk) ...[
            Container(
              width: 14,
              height: math.max(stack, 1),
              color: c.nightLine,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (intoPerson != null) ...[
                  intoPerson!,
                  const SizedBox(height: 4),
                ],
                Text(
                  into,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: destinationStyle,
                ),
                if (intoFigure != null)
                  SizedBox(
                    height: popH,
                    // The figure is wider than its column on purpose: the burst stands over the ribbons' end.
                    child: OverflowBox(
                      maxWidth: popW,
                      maxHeight: popH,
                      child: ComicPop(
                        intoFigure!,
                        width: popW,
                        height: popH,
                        size: figureSize,
                        seed: 14,
                        plate: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeCells extends StatelessWidget {
  const _ThreeCells({
    required this.leftWidth,
    required this.rightWidth,
    required this.height,
    required this.left,
    required this.middle,
    required this.right,
  });
  final double leftWidth, rightWidth, height;
  final Widget left, middle, right;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: leftWidth, child: left),
        Expanded(child: middle),
        SizedBox(width: rightWidth, child: right),
      ],
    ),
  );
}

/// Which ink fills a share: `lamp` paid or done, `dots` an estimate, `denseDots` a heavier one, `dramaDots` the odd one out.
enum ComicShareFill {
  /// The warm narration fill.
  lamp,

  /// Halftone dots on the secondary tint.
  dots,

  /// A denser halftone pattern.
  denseDots,

  /// The dramatic ink in halftone dots.
  dramaDots,
}

/// One part of a [ComicShares].
class ComicShare {
  /// Creates a [ComicShare].
  const ComicShare(this.label, this.amount, {this.figure, this.note, this.ink});

  /// The visible or spoken name of the component.
  final String label;

  /// The amount represented by this entry.
  final num amount;

  /// [figure]: the primary printed figure. [note]: secondary explanatory text.
  final String? figure, note;

  /// Its ink. Left out, it takes the next one by order, so parts never look alike by accident.
  final ComicShareFill? ink;

  @override
  bool operator ==(Object other) =>
      other is ComicShare &&
      other.label == label &&
      other.amount == amount &&
      other.figure == figure &&
      other.note == note &&
      other.ink == ink;

  @override
  int get hashCode => Object.hash(label, amount, figure, note, ink);
}

ComicShareFill _shareInk(List<ComicShare> parts, int i) =>
    parts[i].ink ?? ComicShareFill.values[i % ComicShareFill.values.length];

class _SharesPainter extends CustomPainter {
  _SharesPainter(this.parts, this.c, this.dpr, this.rtl);
  final List<ComicShare> parts;
  final ComicColors c;
  final double dpr;
  final bool rtl;
  @override
  void paint(Canvas canvas, Size s) {
    final total = parts.fold<num>(0, (a, b) => a + b.amount);
    final inner = (Offset.zero & s).deflate(3);
    canvas.drawRect(inner, fillPaint(c.card));
    if (total > 0) {
      var at = 0.0;
      for (var i = 0; i < parts.length; i++) {
        final w = inner.width * parts[i].amount / total;
        final left = rtl ? inner.right - at - w : inner.left + at;
        final r = Rect.fromLTWH(left, inner.top, w, inner.height);
        _paintShareInk(canvas, r, _shareInk(parts, i), c, dpr);
        if (i > 0) {
          final x = rtl ? r.right : r.left;
          canvas.drawLine(
            Offset(x, inner.top),
            Offset(x, inner.bottom),
            strokePaint(c.nightLine, 2.5),
          );
        }
        at += w;
      }
    }
    canvas.drawRect(
      (Offset.zero & s).deflate(1.5),
      strokePaint(c.nightLine, 3),
    );
  }

  @override
  bool shouldRepaint(_SharesPainter o) =>
      !listEquals(o.parts, parts) || o.c != c || o.dpr != dpr || o.rtl != rtl;
}

void _paintShareInk(
  Canvas canvas,
  Rect r,
  ComicShareFill ink,
  ComicColors c,
  double dpr,
) {
  switch (ink) {
    case ComicShareFill.lamp:
      canvas.drawRect(r, fillPaint(c.caption));
    case ComicShareFill.dots:
      canvas.drawRect(r, fillPaint(c.card));
      ComicScreenGrid(7, 1.6, dpr).paint(canvas, r, c.shade);
    case ComicShareFill.denseDots:
      canvas.drawRect(r, fillPaint(c.card));
      ComicScreenGrid(7, 2.4, dpr).paint(canvas, r, c.shade);
    case ComicShareFill.dramaDots:
      canvas.drawRect(r, fillPaint(c.card));
      ComicScreenGrid(7, 1.6, dpr).paint(canvas, r, c.drama);
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.ink, this.c, this.dpr);
  final ComicShareFill ink;
  final ComicColors c;
  final double dpr;
  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.save();
    canvas.clipRect(r);
    _paintShareInk(canvas, r, ink, c, dpr);
    canvas.restore();
    canvas.drawRect(r.deflate(1), strokePaint(c.nightLine, 2));
  }

  @override
  bool shouldRepaint(_SwatchPainter o) =>
      o.ink != ink || o.c != c || o.dpr != dpr;
}

/// A whole split into parts: a stacked bar true to its amounts, a scale of what's done against what's left, and a key with each
/// part's words. [done] is the number to mark on the scale. A budget, a schedule, a storage meter. No parts draws nothing.
///
/// ```dart
/// ComicShares(stamp: 'Paid', parts: const [ComicShare('Rent', 540, figure: '€540', ink: ComicShareFill.lamp), ComicShare('Food', 156, figure: '€156')])
/// ```
class ComicShares extends StatelessWidget {
  /// Creates a [ComicShares].
  const ComicShares({
    super.key,
    required this.parts,
    this.stamp,
    this.scaleStart,
    this.scaleEnd,
    this.scaleNote,
  });

  /// The parts represented by the chart.
  final List<ComicShare> parts;

  /// A word stamped over the bar's first part.
  final String? stamp;

  /// The words under the bar's start and end, if it wants a scale.
  final String? scaleStart, scaleEnd, scaleNote;
  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) return const SizedBox.shrink();
    final t = ComicTheme.of(context);
    final c = t.colors;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final total = parts.fold<num>(0, (a, b) => a + b.amount);
    final scaleStyle = t.type.text(
      12,
      1.2,
      weight: FontWeight.w800,
      color: c.textSecondary,
      tracking: .04,
    );
    return ComicColumn(
      children: [
        SizedBox(
          height: 54,
          child: LayoutBuilder(
            builder: (context, box) {
              final share = total <= 0 ? 0.0 : parts.first.amount / total;
              return Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _SharesPainter(
                      parts,
                      c,
                      dpr,
                      Directionality.of(context) == TextDirection.rtl,
                    ),
                  ),
                  if (stamp != null)
                    PositionedDirectional(
                      start: 3,
                      width: math.max(0.0, (box.maxWidth - 6) * share),
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ComicStamp(stamp!),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (scaleStart != null || scaleEnd != null || scaleNote != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ComicFitRow(
              fill: 1,
              fillShare: .34,
              children: [
                Text(scaleStart ?? '', style: scaleStyle),
                Text(
                  scaleNote ?? '',
                  style: scaleStyle,
                  textAlign: TextAlign.center,
                ),
                Text(
                  scaleEnd ?? '',
                  style: scaleStyle,
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        for (var i = 0; i < parts.length; i++)
          _KeyRow(
            parts[i],
            first: i == 0,
            swatch: CustomPaint(
              painter: _SwatchPainter(_shareInk(parts, i), c, dpr),
            ),
          ),
      ],
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow(this.part, {required this.first, required this.swatch});
  final ComicShare part;
  final bool first;
  final Widget swatch;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: first
            ? null
            : Border(top: BorderSide(color: c.divider, width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7.5),
        child: Row(
          children: [
            SizedBox(width: 18, height: 18, child: swatch),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    part.label,
                    style: t.type.text(14, 1.25, weight: FontWeight.w700),
                  ),
                  if (part.note != null)
                    Text(
                      part.note!,
                      style: t.type.text(
                        12,
                        1.3,
                        weight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(part.figure ?? '${part.amount}', style: t.type.number(24)),
          ],
        ),
      ),
    );
  }
}

/// One column of [ComicUnits].
class ComicUnitColumn {
  /// Creates a [ComicUnitColumn].
  const ComicUnitColumn(this.label, this.count, {this.now = false});

  /// The visible or spoken name of the component.
  final String label;

  /// The count printed in the main figure.
  final int count;

  /// The current one: lit by the lamp.
  final bool now;
}

class _UnitPainter extends CustomPainter {
  _UnitPainter(this.fill, this.dot, this.line, this.dpr);
  final Color fill, dot, line;
  final double dpr;
  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.drawRect(r, fillPaint(fill));
    ComicScreenGrid(
      6,
      1.3,
      dpr,
      staggered: false,
      rowFactor: 1,
    ).paint(canvas, r.deflate(2).shift(const Offset(1, 1)), dot);
    canvas.drawRect(r.deflate(1), strokePaint(line, 2));
  }

  @override
  bool shouldRepaint(_UnitPainter o) =>
      o.fill != fill || o.dot != dot || o.line != line || o.dpr != dpr;
}

/// Counts drawn as stacks of little inked boxes, one a thing: how many plans a month, how many cups a day. Up to about 14 columns
/// at 390. The stacks scale so the tallest fits. An empty list draws nothing.
///
/// ```dart
/// ComicUnits(const [ComicUnitColumn('Oct', 2), ComicUnitColumn('Nov', 3, now: true)])
/// ```
class ComicUnits extends StatelessWidget {
  /// Creates a [ComicUnits].
  const ComicUnits(this.columns, {super.key});

  /// The number or specification of columns in the layout.
  final List<ComicUnitColumn> columns;
  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) return const SizedBox.shrink();
    final t = ComicTheme.of(context);
    final c = t.colors;
    final tall = t.desk ? 162.0 : 118.0;
    final most = columns.map((e) => e.count).reduce(math.max);
    // Past the height, boxes shrink, then lose their gaps, then a box is a line: the tallest column always fits.
    final roomy = most <= 0 ? 26.0 : (tall - 3 * (most - 1)) / most;
    final gapBetween = roomy >= 4 ? 3.0 : 1.0;
    final unit = math.max(
      1.0,
      math.min(
        t.desk ? 36.0 : 26.0,
        most <= 0 ? 26.0 : (tall - gapBetween * (most - 1)) / most,
      ),
    );
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final label = t.type.text(
      11,
      1.2,
      weight: FontWeight.w800,
      color: c.textSecondary,
      tracking: .03,
    );
    return ComicEqualRow(
      flex: List.filled(columns.length, 1),
      gap: t.desk ? 8 : 4,
      children: [
        for (final col in columns)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: tall,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.bottomCenter,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < col.count; i++) ...[
                          if (i > 0) SizedBox(height: gapBetween),
                          SizedBox(
                            height: unit,
                            child: CustomPaint(
                              painter: _UnitPainter(
                                col.now ? c.caption : c.shadeTint,
                                col.now ? c.lampDot : c.shade,
                                c.nightLine,
                                dpr,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(col.label.toUpperCase(), maxLines: 1, style: label),
              ),
              Text(
                '${col.count}',
                textAlign: TextAlign.center,
                style: t.type.data,
              ),
            ],
          ),
      ],
    );
  }
}

/// A slice of a [ComicPieChart].
class ComicSlice {
  /// Creates a [ComicSlice].
  const ComicSlice(this.label, this.amount, {this.figure, this.share});

  /// The visible or spoken name of the component.
  final String label;

  /// The amount represented by this entry.
  final num amount;

  /// [figure]: the primary printed figure. [share]: the amount or share represented by this entry.
  final String? figure, share;

  @override
  bool operator ==(Object other) =>
      other is ComicSlice &&
      other.label == label &&
      other.amount == amount &&
      other.figure == figure &&
      other.share == share;

  @override
  int get hashCode => Object.hash(label, amount, figure, share);
}

class _PiePainter extends CustomPainter {
  _PiePainter(this.slices, this.c, this.dpr);
  final List<ComicSlice> slices;
  final ComicColors c;
  final double dpr;
  @override
  void paint(Canvas canvas, Size s) {
    // The ring's radius, and the room round it for the first slice's pull (7) and the rim.
    const r = 82.0, room = 9.0, cx = r + room, cy = r + room;
    final k = s.width / (2 * (r + room));
    canvas.save();
    canvas.scale(k);
    final total = slices.fold<num>(0, (a, b) => a + b.amount);
    if (total <= 0) {
      canvas.drawCircle(const Offset(cx, cy), r, fillPaint(c.track));
      canvas.drawCircle(const Offset(cx, cy), r, strokePaint(c.nightLine, 3.4));
      canvas.restore();
      return;
    }
    final inks = c.series;
    var a = -math.pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final sweep = 2 * math.pi * slices[i].amount / total;
      final mid = a + sweep / 2;
      final off = i == 0 ? 7.0 : 0.0;
      final o = Offset(cx + off * math.cos(mid), cy + off * math.sin(mid));
      final box = Rect.fromCircle(center: o, radius: r);
      final p = Path();
      if (sweep >= 2 * math.pi - 1e-6) {
        p.addOval(box);
      } else {
        p
          ..moveTo(o.dx, o.dy)
          ..arcTo(box, a, sweep, false)
          ..close();
      }
      canvas.drawPath(p, fillPaint(inks[i % inks.length]));
      canvas.drawPath(
        p,
        strokePaint(c.nightLine, 3.4)..strokeJoin = StrokeJoin.round,
      );
      a += sweep;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PiePainter o) =>
      !listEquals(o.slices, slices) || o.c != c || o.dpr != dpr;
}

/// An inked pie with its largest slice pulled out, a figure in the middle, and a key of what each slice is. It keeps its size and
/// stands at its column's start on a phone. Four slices read best; up to six get their own inks. All zero draws an empty ring.
///
/// ```dart
/// ComicPieChart(centre: '417', unit: 'kcal', slices: const [ComicSlice('Carbs', 200, figure: '200', share: '48%'), ComicSlice('Fat', 99, figure: '99', share: '24%')])
/// ```
class ComicPieChart extends StatelessWidget {
  /// Creates a [ComicPieChart].
  const ComicPieChart({
    super.key,
    required this.slices,
    this.centre,
    this.unit,
  });

  /// The slices represented by the pie.
  final List<ComicSlice> slices;

  /// [centre]: content displayed at the center of the figure. [unit]: the unit printed beside the value.
  final String? centre, unit;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    // The pie's box holds its ring, its rim and the first slice's pull and nothing more, so the ring starts on the
    // column's edge; the ring is drawn as large as before.
    final size = t.desk ? 146.0 : 128.0;
    final inks = c.series;
    final pie = comicOwnSize(
      width: size,
      height: size,
      alignment: AlignmentDirectional.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PiePainter(
                slices,
                c,
                MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
              ),
            ),
          ),
          if (centre != null)
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.paper,
                shape: BoxShape.circle,
                border: Border.all(color: c.nightLine, width: 3),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centre!.toUpperCase(),
                        style: t.type.letter(
                          24,
                          lineHeight: 1,
                          color: c.onPaper,
                          tracking: .02,
                        ),
                      ),
                      if (unit != null)
                        Text(
                          unit!.toUpperCase(),
                          style: t.type.text(
                            11,
                            1,
                            weight: FontWeight.w800,
                            color: c.onPaper,
                            tracking: .06,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    final labelStyle = t.type.text(14, 1.25, weight: FontWeight.w700);
    final shareStyle = t.type.text(
      12,
      1.2,
      weight: FontWeight.w700,
      color: c.textSecondary,
    );
    double textWidth(String words, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: words, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final shareWidth = slices.fold<double>(
      32,
      (width, slice) =>
          math.max(width, textWidth(slice.share ?? '', shareStyle)),
    );
    final legendWidth = slices.fold<double>(
      0,
      (width, slice) => math.max(
        width,
        16 +
            8 +
            textWidth(slice.label, labelStyle) +
            8 +
            textWidth(slice.figure ?? '${slice.amount}', t.type.data) +
            (slice.share == null ? 0 : 5 + shareWidth),
      ),
    );
    final key = ComicColumn(
      children: [
        for (var i = 0; i < slices.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: ShapeDecoration(
                    color: inks[i % inks.length],
                    shape: t.shapes.small.copyWith(
                      side: BorderSide(color: c.nightLine, width: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(slices[i].label, style: labelStyle)),
                const SizedBox(width: 8),
                Text(
                  slices[i].figure ?? '${slices[i].amount}',
                  style: t.type.data,
                ),
                if (slices[i].share != null) ...[
                  const SizedBox(width: 5),
                  SizedBox(
                    width: shareWidth,
                    child: Text(
                      slices[i].share!,
                      textAlign: TextAlign.end,
                      style: shareStyle,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) {
        final beside =
            t.desk &&
            (!box.hasBoundedWidth || box.maxWidth >= size + 14 + legendWidth);
        return beside
            ? Row(
                children: [
                  pie,
                  const SizedBox(width: 14),
                  Expanded(child: key),
                ],
              )
            : ComicColumn(
                gap: 12,
                children: [
                  Center(heightFactor: 1, child: pie),
                  key,
                ],
              );
      },
    );
  }
}

/// A span of time or a run of steps, each block as wide as its amount, numbered in the lettering: a timeline. The [long] block
/// wears the lamp. Under each amount its own number, unless you give [labels]. A block too narrow for its number with air
/// both sides leaves it out of the bar, to the key under the bar and its scale: its swatch, its number and its amount, in order. A number is
/// never squeezed, laid over a rule or left loose under the bar. No parts draws nothing.
///
/// ```dart
/// ComicSegments(const [8, 5, 2, 5, 45, 5], long: 4)
/// ```
class ComicSegments extends StatelessWidget {
  /// Creates a [ComicSegments].
  const ComicSegments(
    this.amounts, {
    super.key,
    this.long,
    this.labels,
    this.scaleStart,
    this.scaleEnd,
    this.scaleNote,
  });

  /// The amounts represented in order.
  final List<num> amounts;

  /// Uses the wider form of the composition.
  final int? long;

  /// Labels corresponding to the displayed entries.
  final List<String>? labels;

  /// The words under its start, its end and its middle.
  final String? scaleStart, scaleEnd, scaleNote;

  /// The room a number keeps from the rules each side of it, in the bar.
  static const double air = 4;

  /// The rule between two blocks.
  static const double _rule = 2.5;

  String _label(int i) =>
      labels != null && i < labels!.length ? labels![i] : '${i + 1}';

  @override
  Widget build(BuildContext context) {
    if (amounts.isEmpty) return const SizedBox.shrink();
    final t = ComicTheme.of(context);
    final c = t.colors;
    final total = amounts.fold<num>(0, (a, b) => a + b);
    final flex = [
      for (final a in amounts)
        total <= 0 ? 1 : math.max(1, (1000 * a / total).round()),
    ];
    final flexSum = flex.fold<int>(0, (a, b) => a + b);
    final scale = t.type.text(
      12,
      1.2,
      weight: FontWeight.w800,
      color: c.textSecondary,
      tracking: .04,
    );
    TextStyle inBar(int i) => t.type.letter(
      16,
      lineHeight: 1,
      color: i == long ? c.onCaption : c.onPaper,
    );
    final under = t.type.letter(13, lineHeight: 1, color: c.text);
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    double widthOf(String words, TextStyle style) {
      final p = TextPainter(
        text: TextSpan(text: words, style: style),
        textDirection: dir,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = p.width;
      p.dispose();
      return w;
    }

    return LayoutBuilder(
      builder: (context, box) {
        // The bar's border and padding take 3 + 3 each side; the blocks share the rest by their amounts, as the Row lays them.
        final inner = math.max(0.0, box.maxWidth - 12);
        final widths = [for (final f in flex) inner * f / flexSum];
        final fits = [
          for (var i = 0; i < amounts.length; i++)
            widths[i] - (i == 0 ? 0 : _rule) >=
                widthOf(_label(i), inBar(i)) + 2 * air,
        ];
        // A number left out of the bar goes to the key under it, with the
        // block's own swatch and amount, so it is read in order rather than
        // found loose under a sliver.
        final left = [
          for (var i = 0; i < amounts.length; i++)
            if (!fits[i]) i,
        ];
        String amount(num a) =>
            a == a.roundToDouble() ? a.round().toString() : a.toString();
        return ComicColumn(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 6),
              height: 30,
              decoration: ShapeDecoration(
                color: c.unlit,
                shape: ComicTheme.of(context).shapes.capsule
                    .copyWith(side: BorderSide(color: c.nightLine, width: 3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                // The parts sit inside the track's own outline, concentric with it.
                child: ClipPath(
                  clipper: ShapeBorderClipper(
                    shape: comicInsetShape(
                      ComicTheme.of(context).shapes.capsule,
                      6,
                    ),
                    textDirection: Directionality.of(context),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < amounts.length; i++)
                        Expanded(
                          flex: flex[i],
                          child: _Segment(
                            lit: i == long,
                            first: i == 0,
                            label: fits[i] ? _label(i) : null,
                            style: inBar(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (scaleStart != null || scaleEnd != null || scaleNote != null)
              ComicFitRow(
                fill: 1,
                fillShare: .34,
                children: [
                  Text(scaleStart ?? '', style: scale),
                  Text(
                    scaleNote ?? '',
                    style: scale,
                    textAlign: TextAlign.center,
                  ),
                  Text(scaleEnd ?? '', style: scale, textAlign: TextAlign.end),
                ],
              ),
            // The key comes after the scale, which belongs to the bar's ends.
            if (left.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    for (final i in left)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: ShapeDecoration(
                              color: i == long ? c.caption : c.unlit,
                              shape: t.shapes.small.copyWith(
                                side: BorderSide(
                                  color: c.nightLine,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(_label(i), maxLines: 1, style: under),
                          const SizedBox(width: 6),
                          Text(amount(amounts[i]), maxLines: 1, style: scale),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One block of a [ComicSegments], with its number only when the number fits with air.
class _Segment extends StatelessWidget {
  const _Segment({
    required this.lit,
    required this.first,
    required this.label,
    required this.style,
  });
  final bool lit, first;
  final String? label;
  final TextStyle style;
  @override
  Widget build(BuildContext context) {
    final c = ComicTheme.of(context).colors;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: lit ? c.caption : c.unlit,
        border: first
            ? null
            : BorderDirectional(
                start: BorderSide(
                  color: c.nightLine,
                  width: ComicSegments._rule,
                ),
              ),
      ),
      child: label == null ? null : Text(label!, maxLines: 1, style: style),
    );
  }
}

class _CellPainter extends CustomPainter {
  _CellPainter(this.fill, this.dot, this.dpr);
  final Color fill;
  final Color? dot;
  final double dpr;
  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.drawRect(r, fillPaint(fill));
    if (dot != null) {
      ComicScreenGrid(
        6,
        1.3,
        dpr,
        staggered: false,
        rowFactor: 1,
      ).paint(canvas, r, dot!);
    }
  }

  @override
  bool shouldRepaint(_CellPainter o) =>
      o.fill != fill || o.dot != dot || o.dpr != dpr;
}

/// Progress cell by cell: [completed] lit, [started] dotted, the rest empty, of [total]. Eight to twenty read best. It takes its column's
/// width.
///
/// ```dart
/// ComicProgressCells(total: 8, completed: 4, started: 2)
/// ```
class ComicProgressCells extends StatelessWidget {
  /// Creates a [ComicProgressCells].
  const ComicProgressCells({
    super.key,
    required this.total,
    required this.completed,
    this.started = 0,
  });

  /// [total]: the total represented by the composition. [completed]: whether the step or task is complete. [started]: whether this step has begun.
  final int total, completed, started;
  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    final c = ComicTheme.of(context).colors;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    return ComicEqualRow(
      flex: List.filled(total, 1),
      gap: 4,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            height: 16,
            decoration: ShapeDecoration(
              shape: ComicTheme.of(context).shapes.small
                  .copyWith(side: BorderSide(color: c.nightLine, width: 2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: ClipPath(
                clipper: ShapeBorderClipper(
                  shape: comicInsetShape(
                    ComicTheme.of(context).shapes.small,
                    4,
                  ),
                  textDirection: Directionality.of(context),
                ),
                child: CustomPaint(
                  painter: _CellPainter(
                    i < completed
                        ? c.caption
                        : i < completed + started
                        ? c.shadeTint
                        : c.unlit,
                    i >= completed && i < completed + started ? c.shade : null,
                    dpr,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
