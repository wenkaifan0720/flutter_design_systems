// The stars: what a page's active window holds. Each reads the window around it, and draws small in an inactive window at any
// width and in the active one on a phone, unless the desktop said `whole`. So two big things on one page can't happen.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../controls.dart';
import '../frames.dart';
import '../heads.dart';
import '../layout.dart';
import '../pixels.dart';
import '../rows.dart';
import '../theme.dart';
import '../shapes.dart';
import '../component_themes.dart';

class _TilePainter extends RetroDesktopPixelPainter {
  const _TilePainter(
    this.c,
    this.step,
    this.ringPad,
    this.top,
    this.band, {
    required this.shape,
    required this.ringShape,
    this.side,
  });
  final OutlinedBorder shape, ringShape;
  final BorderSide? side;
  final RetroDesktopColors c;

  /// How far each sheet behind it stands out.
  final double step;
  final double ringPad, top, band;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final canvas = px.canvas;
    final h = px.hair, w = px.hairX;
    final face = px.snap(
      Rect.fromLTRB(0, top, s.width - 2 * step, s.height - 2 * step),
    );
    // The two sheets behind: a lighter and a darker edge, stepped out from under the face.
    for (final (n, line) in [(2.0, c.bevelDark), (1.0, c.bevelDarker)]) {
      final sheet = face.shift(Offset(n * step, n * step));
      final outline = shape.copyWith(
        side: (side ?? BorderSide(color: line, width: w)).copyWith(color: line),
      );
      canvas.drawPath(outline.getOuterPath(sheet), Paint()..color = c.paper);
      outline.paint(canvas, sheet);
    }
    canvas.save();
    canvas.clipPath(shape.getOuterPath(face));
    canvas.drawRect(face, Paint()..color = c.paper);
    final bandTo = px.y(top + band);
    px.fillExact(face.left, face.top, face.right, bandTo, c.platinumLight);
    px.fillExact(
      face.left + w,
      face.top + h,
      face.right - w,
      face.top + 2 * h,
      c.onHighlight.withValues(alpha: 0),
    );
    px.fillExact(
      face.left + w,
      face.top + h,
      face.right - w,
      face.top + 2 * h,
      const Color(0x59FFFFFF),
    );
    px.fillExact(face.left, bandTo - h, face.right, bandTo, c.outline);
    px.fillExact(
      face.right - 2 * w,
      bandTo,
      face.right - w,
      face.bottom - h,
      c.platinumDark,
    );
    px.fillExact(
      face.left + w,
      face.bottom - 2 * h,
      face.right - w,
      face.bottom - h,
      c.platinumDark,
    );
    shape
        .copyWith(
          side: side ?? BorderSide(color: c.outline, width: w),
        )
        .paint(canvas, face);
    canvas.restore();
    // Two rings holding the pad.
    for (final x in [ringPad, face.width - ringPad - 6]) {
      final ring = px.snap(Rect.fromLTWH(x, top - 5, 6, 10));
      final border = ringShape;
      canvas.drawPath(border.getOuterPath(ring), Paint()..color = c.outline);
      canvas.drawPath(
        RetroDesktopShapes.inset(border, w).getOuterPath(ring.deflate(w)),
        Paint()..color = Color.lerp(c.binderRingLight, c.binderRingDark, .5)!,
      );
    }
  }

  @override
  bool shouldRepaint(_TilePainter o) =>
      o.c != c ||
      o.step != step ||
      o.ringPad != ringPad ||
      o.top != top ||
      o.band != band ||
      o.shape != shape ||
      o.ringShape != ringShape ||
      o.side != side;
}

/// A day off a pad: the month and year on a coloured band, the day big enough to read across a room, the weekday under it,
/// with two more sheets behind and rings on top. Small in an inactive window, and on a phone unless the page is whole.
///
/// ```dart
/// RetroDesktopDayTile(month: 'NOV', year: '2026', day: '11', weekday: 'Wednesday')
/// ```
class RetroDesktopDayTile extends StatelessWidget {
  /// Creates a [RetroDesktopDayTile].
  const RetroDesktopDayTile({
    super.key,
    this.style,
    required this.month,
    required this.day,
    this.year,
    this.weekday,
  });

  /// Overrides the calendar pad's card theme; its sheets retain their offset.
  final RetroDesktopStyle? style;

  /// The month value or label displayed by this part.
  final String month;

  /// The calendar day displayed by this part.
  final String day;

  /// The calendar year displayed by this part.
  final String? year;

  /// The weekday label displayed by this part.
  final String? weekday;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) read) =>
        RetroDesktopStyle.first([style, t.cardTheme], read, const {});
    final c = t.colors.copyWith(
      paper: slot((s) => s.fill),
      text: slot((s) => s.foreground),
      textSecondary: slot((s) => s.foreground),
      outline: slot((s) => s.side)?.color ?? slot((s) => s.edge),
    );
    final shape = slot((s) => s.shape) ?? t.shapes.medium;
    final side =
        slot((s) => s.side) ??
        (slot((s) => s.edge) != null
            ? BorderSide(color: c.outline, width: t.strokes.regular)
            : null);
    final minimum = slot((s) => s.minimumSize) ?? Size.zero;
    final small = retroDesktopCompactHere(context);
    final baseW = small ? 72.0 : (t.desk ? 156.0 : 132.0);
    final figure =
        (small
                ? t.type.pixel(52, 40)
                : (t.desk ? t.type.pixel(150, 108) : t.type.pixel(120, 88)))
            .merge(slot((s) => s.textStyle))
            .copyWith(color: c.text);
    final step = small ? 2.0 : 3.0;
    final onBand = t.type.chrome
        .merge(slot((s) => s.textStyle))
        .copyWith(color: slot((s) => s.foreground) ?? c.text);
    final hasYear = !small && year != null;
    Size measureLabel(String value, double width) {
      final painter = TextPainter(
        text: TextSpan(text: value, style: onBand),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: width);
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final faceW = baseW;
    final fullLabelWidth = math.max(
      1.0,
      math.max(faceW + 2 * step, minimum.width) - 2 * step - 16,
    );

    final stacked =
        hasYear &&
        measureLabel(month, double.infinity).width +
                measureLabel(year!, double.infinity).width +
                8 >
            fullLabelWidth;
    final labelWidth = stacked || !hasYear
        ? fullLabelWidth
        : fullLabelWidth / 2;
    // A band word wider than the band (a month at twice the text size on a small tile) scales down whole, on one line,
    // as the day's figure does, rather than break inside itself ("MA" over "R").
    bool tooWide(String words) => words
        .split(RegExp(r'\s+'))
        .any((word) => measureLabel(word, double.infinity).width > labelWidth);
    double bandHeight(String words) => tooWide(words)
        ? measureLabel(words, double.infinity).height
        : measureLabel(words, labelWidth).height;
    Widget bandWords(String words) => tooWide(words)
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(words, style: onBand, maxLines: 1, softWrap: false),
          )
        : Text(words, style: onBand, softWrap: true);
    final monthHeight = bandHeight(month);
    final yearHeight = hasYear ? bandHeight(year!) : 0.0;
    final bandH = math.max(
      small ? 20.0 : 24.0,
      (stacked
              ? monthHeight + 4 + yearHeight
              : math.max(monthHeight, yearHeight)) +
          4,
    );
    const topRoom = 5.0;
    return Semantics(
      label: '${weekday ?? ''} $day $month ${year ?? ''}'.trim(),
      child: Padding(
        padding: slot((s) => s.padding) ?? EdgeInsets.zero,
        child: retroDesktopOwnSize(
          width: math.max(faceW + 2 * step, minimum.width),
          child: ExcludeSemantics(
            child: RetroDesktopPixelPaint(
              painter: _TilePainter(
                c,
                step,
                small ? 14 : 26,
                topRoom,
                bandH,
                shape: shape,
                ringShape: t.shapes.small,
                side: side,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minimum.height),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topRoom + 1,
                    left: 1,
                    right: 1 + 2 * step,
                    bottom: 1 + 2 * step,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: bandH - 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: stacked
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    bandWords(month),
                                    const SizedBox(height: 4),
                                    bandWords(year!),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: small || year == null
                                      ? MainAxisAlignment.center
                                      : MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(child: bandWords(month)),
                                    if (!small && year != null)
                                      Flexible(child: bandWords(year!)),
                                  ],
                                ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: small ? 5 : (t.desk ? 16 : 14),
                          left: 2,
                          right: 2,
                          bottom: small ? 6 : 0,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(day, style: figure, maxLines: 1),
                        ),
                      ),
                      if (!small && weekday != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
                          child: Text(
                            weekday!,
                            style: t.type.chrome
                                .merge(slot((s) => s.textStyle))
                                .copyWith(color: c.textSecondary),
                            softWrap: true,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One big reading in the system face, with its small unit raised after it. Small in an inactive window, and on a phone unless
/// the page is whole. A long reading scales down rather than break.
///
/// ```dart
/// RetroDesktopBigFigure('8', unit: '°')
/// ```
class RetroDesktopBigFigure extends StatelessWidget {
  /// Creates a [RetroDesktopBigFigure].
  const RetroDesktopBigFigure(this.value, {super.key, this.unit});

  /// The current value to display or edit.
  final String value;

  /// The unit shown beside the value.
  final String? unit;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final small = retroDesktopCompactHere(context);
    final size = small ? 64.0 : (t.desk ? 170.0 : 128.0);
    final line = small ? 52.0 : (t.desk ? 120.0 : 92.0);
    final figure = t.type
        .pixel(size, line)
        .copyWith(letterSpacing: -.02 * size);
    final rest = t.type
        .pixel(size * .5, size * .25)
        .copyWith(letterSpacing: -.02 * size);
    return Padding(
      padding: EdgeInsets.only(top: small ? 0 : 6),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.topStart,
        // A figure and its unit read left to right in every language, as
        // "11°" in a line of text does: in right to left the row had stood the
        // ring before the numeral ("°8").
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.ltr,
          children: [
            Text(value, style: figure, maxLines: 1),
            if (unit != null)
              Transform.translate(
                offset: const Offset(-2, 0),
                child: Text(unit!, style: rest, maxLines: 1),
              ),
          ],
        ),
      ),
    );
  }
}

/// The body of an active window: an object beside what it says. The object is usually a `RetroDesktopDayTile`. It stands beside a
/// small line, the page's sentence, a progress bar and a flag, with the stats under all of them on a phone and under the
/// words on a desktop. In a window of its own it needs nothing else.
///
/// ```dart
/// RetroDesktopHeroHeader(object: const RetroDesktopDayTile(month: 'NOV', day: '11'), eyebrow: 'Good morning', title: '4 left today', progress: .2, progressLabel: '1 of 5 done', stats: const [('Open', '18', null)])
/// ```
class RetroDesktopHeroHeader extends StatelessWidget {
  /// Creates a [RetroDesktopHeroHeader].
  const RetroDesktopHeroHeader({
    super.key,
    required this.object,
    required this.title,
    this.eyebrow,
    this.progress,
    this.progressLabel,
    this.flag,
    this.flagNote,
    this.stats = const [],
  });

  /// The caller-supplied object displayed in the hero.
  final Widget object;

  /// The heading displayed above the content.
  final String title;

  /// The small heading above the main title.
  final String? eyebrow;

  /// The label describing the progress value.
  final String? progressLabel;

  /// The identifying flag displayed with this item.
  final String? flag;

  /// Supporting text beside the flag.
  final String? flagNote;

  /// The completed fraction, clamped to 0–1; null omits the indicator.
  /// Non-finite values display zero progress.
  final double? progress;

  /// The statistics displayed in order.
  final List<(String, String, String?)> stats;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final words = RetroDesktopColumn(
      gap: 10,
      children: [
        if (eyebrow != null) RetroDesktopEyebrow(eyebrow!),
        RetroDesktopHeadline(title),
        if (progress != null)
          RetroDesktopLinearProgressIndicator(
            value: progress!.isFinite ? progress!.clamp(0.0, 1.0) : 0,
            label: progressLabel ?? title,
          ),
        if (flag != null || flagNote != null)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              if (flag != null) RetroDesktopFlag(flag!),
              if (flagNote != null) RetroDesktopLabel(flagNote!),
            ],
          ),
      ],
    );
    final figures = stats.isEmpty ? null : RetroDesktopStats(stats);
    // The tile holds its sheets and rings in its own box: 6 lp of the concept's gaps are inside it.
    final gap = t.desk ? 16.0 : 12.0;
    final Widget body;
    if (t.desk) {
      body = RetroDesktopBeside(
        object: object,
        gap: gap,
        child: RetroDesktopColumn(gap: 14, children: [words, ?figures]),
      );
    } else {
      body = RetroDesktopColumn(
        gap: 8,
        children: [
          RetroDesktopBeside(object: object, gap: gap, child: words),
          ?figures,
        ],
      );
    }
    return Padding(
      padding: t.desk
          ? const EdgeInsets.fromLTRB(0, 11, 0, 12)
          : const EdgeInsets.fromLTRB(0, 9, 0, 18),
      child: body,
    );
  }
}

/// The body of an active window that opens on a reading: the figure, what it means, then the readings and a sentence. All of
/// it in a row on a desktop; on a phone the sentence and readings go under.
///
/// ```dart
/// RetroDesktopFigureHero(value: '8', unit: '°', title: 'Showers', note: 'Clearing by 14:00', reads: const [('High', '11°', null)], summary: 'Dry and bright from 14:00.')
/// ```
class RetroDesktopFigureHero extends StatelessWidget {
  /// Creates a [RetroDesktopFigureHero].
  const RetroDesktopFigureHero({
    super.key,
    required this.value,
    required this.title,
    this.unit,
    this.note,
    this.reads = const [],
    this.summary,
  });

  /// The current value to display or edit.
  final String value;

  /// The heading displayed above the content.
  final String title;

  /// The unit shown beside the value.
  final String? unit;

  /// Supporting text shown with the main content.
  final String? note;

  /// An optional accessible summary in place of the generated one.
  final String? summary;

  /// The readings displayed in order.
  final List<(String, String, String?)> reads;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final small = retroDesktopCompactHere(context);
    final head = small
        ? t.type.head
        : (t.desk ? t.type.pixel(56, 50) : t.type.pixel(44, 40));
    final figure = RetroDesktopBigFigure(value, unit: unit);
    // As wide as its words: the row beside it takes the rest.
    final meaning = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(title, style: head),
        if (note != null)
          Text(
            note!,
            style: t.type.text(
              14,
              18,
              weight: FontWeight.w600,
              color: t.colors.textSecondary,
            ),
          ),
      ],
    );
    final side = RetroDesktopColumn(
      gap: 12,
      children: [
        if (reads.isNotEmpty) RetroDesktopReadings(reads),
        if (summary != null) _Summary(summary!),
      ],
    );
    final hasSide = reads.isNotEmpty || summary != null;
    if (t.desk && !small) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
        child: RetroDesktopBeside(
          object: figure,
          gap: 22,
          maxObject: .3,
          child: hasSide
              ? RetroDesktopFitRow(
                  fill: 1,
                  gap: 22,
                  fillShare: .5,
                  children: [meaning, side],
                )
              : meaning,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 14),
      child: RetroDesktopColumn(
        gap: 14,
        children: [
          RetroDesktopBeside(object: figure, gap: 14, child: meaning),
          if (hasSide) side,
        ],
      ),
    );
  }
}

/// A reading in a window that isn't the hero: the figure beside what it means. It stays this size in any window.
///
/// ```dart
/// RetroDesktopReadingHead(value: '28', title: 'Good', note: 'Main pollutant: ozone.')
/// ```
class RetroDesktopReadingHead extends StatelessWidget {
  /// Creates a [RetroDesktopReadingHead].
  const RetroDesktopReadingHead({
    super.key,
    required this.value,
    required this.title,
    this.note,
  });

  /// The current value to display or edit.
  final String value;

  /// The heading displayed above the content.
  final String title;

  /// Supporting text shown with the main content.
  final String? note;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return RetroDesktopBeside(
      object: Text(value, style: t.type.pixel(64, 52), maxLines: 1),
      gap: 14,
      child: RetroDesktopColumn(
        gap: 2,
        children: [
          Text(title, style: t.type.big),
          if (note != null)
            Text(
              note!,
              style: t.type.text(13, 18, color: t.colors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return RetroDesktopWell(
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
      child: Text(text, style: t.type.text(16, 24)),
    );
  }
}
