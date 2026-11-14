/// Status glyphs (backlog, todo, active, done, paused, cancelled), priority
/// glyphs (urgent, high, medium, low, none) and dot badges.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/styled.dart';
import '../theme.dart';
import 'pressable.dart';
import 'tag.dart';

/// Where a piece of work stands — the six states an issue, a habit or an
/// order moves through, each with its glyph ([MinimalStatusIcon]), its
/// default [label] and the [tone] a badge prints it in.
enum MinimalTaskStatus {
  /// Not yet planned.
  backlog('Backlog', MinimalTone.neutral),

  /// Planned, not started.
  todo('Todo', MinimalTone.neutral),

  /// Being worked on.
  active('In progress', MinimalTone.warning),

  /// Finished.
  done('Done', MinimalTone.success),

  /// Started, then put aside.
  paused('Paused', MinimalTone.neutral),

  /// Dropped.
  cancelled('Cancelled', MinimalTone.neutral);

  /// A status saying [label] in [tone].
  const MinimalTaskStatus(this.label, this.tone);

  /// The state's name, as a list or a screen reader says it.
  final String label;

  /// The tone a [MinimalStatusBadge] for this state speaks in.
  final MinimalTone tone;
}

/// The glyph of a [MinimalTaskStatus], painted at the icon stroke so it sits in a
/// row beside Lucide glyphs: a dashed ring for backlog, a ring for todo, a
/// half-filled ring for work in progress, a filled check for done, a ring
/// with two bars for paused and a filled cross for cancelled. The check and
/// the cross are cut out of their disc, so whatever row the glyph sits on
/// (a highlighted one, a table header) shows through them.
///
/// With [onPressed] the glyph is the row's quick status control (tap to mark
/// done): a checkbox-like button that announces its label and whether it
/// is [checked], and pads its hit area to 44 px.
///
/// ```dart
/// MinimalStatusIcon(MinimalTaskStatus.done, onPressed: () => toggle(habit))
/// ```
class MinimalStatusIcon extends StatelessWidget {
  /// The glyph of [status].
  const MinimalStatusIcon(
    this.status, {
    super.key,
    this.size = MinimalIconSize.i18,
    this.onPressed,
    this.semanticLabel,
    this.checked,
    this.focusNode,
    this.autofocus = false,
  });

  /// The status it shows.
  final MinimalTaskStatus status;

  /// Its size.
  final double size;

  /// Makes the glyph a control; null leaves it a mark.
  final VoidCallback? onPressed;

  /// What a screen reader announces; null takes [MinimalTaskStatus.label]. With
  /// [onPressed] the checked state is announced after it, so a label names the
  /// row (`Meditate`), not its state.
  final String? semanticLabel;

  /// Whether the control reads as checked; null takes `status ==
  /// MinimalTaskStatus.done`. Read only with [onPressed].
  final bool? checked;

  /// The glyph's colour in [t]: done in success (a filled disc, the fill
  /// colour), work in progress in the warning's ink (a thin ring and a half
  /// disc, which need the deeper cut to stand 3:1 off the ground), the
  /// waiting states in the quiet inks.
  static Color colorOf(MinimalThemeData t, MinimalTaskStatus status) =>
      switch (status) {
        MinimalTaskStatus.backlog => t.textTertiary,
        MinimalTaskStatus.todo => t.mutedForeground,
        MinimalTaskStatus.active => t.warningInk,
        MinimalTaskStatus.done => t.success,
        MinimalTaskStatus.paused => t.mutedForeground,
        MinimalTaskStatus.cancelled => t.textTertiary,
      };

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final label = semanticLabel ?? status.label;
    final glyph = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _StatusPainter(
          status,
          color: colorOf(t, status),
          stroke: t.iconStroke,
        ),
      ),
    );
    final tap = onPressed;
    if (tap == null) {
      return Semantics(label: label, excludeSemantics: true, child: glyph);
    }
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: tap,
      shape: const CircleBorder(),
      semanticLabel: label,
      checked: checked ?? status == MinimalTaskStatus.done,
      child: ExcludeSemantics(child: glyph),
    );
  }
}

class _StatusPainter extends CustomPainter {
  _StatusPainter(this.status, {required this.color, required this.stroke});

  final MinimalTaskStatus status;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    // The ring sits in Lucide's 24-unit grid (radius 10 of 24), so it lines
    // up with a circle glyph beside it.
    final unit = size.width / 24;
    final c = size.center(Offset.zero);
    final w = stroke * unit * 1.1;
    final r = 9.5 * unit;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final fill = Paint()..color = color;
    // The check and the cross clear their disc's pixels in a layer of its
    // own: a true cut-out, not a stroke in some assumed ground colour.
    final knock = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 1.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.clear;
    final ring = Rect.fromCircle(center: c, radius: r);

    switch (status) {
      case MinimalTaskStatus.backlog:
        // Twelve dashes with even gaps round the ring.
        const dashes = 12;
        const sweep = 2 * math.pi / dashes;
        for (var i = 0; i < dashes; i++) {
          canvas.drawArc(ring, i * sweep, sweep * 0.5, false, line);
        }
      case MinimalTaskStatus.todo:
        canvas.drawCircle(c, r, line);
      case MinimalTaskStatus.active:
        canvas.drawCircle(c, r, line);
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r - w * 1.6),
          -math.pi / 2,
          math.pi,
          true,
          fill,
        );
      case MinimalTaskStatus.done:
        canvas.saveLayer(Offset.zero & size, Paint());
        canvas.drawCircle(c, r + w / 2, fill);
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - 4.2 * unit, c.dy + 0.2 * unit)
            ..lineTo(c.dx - 1.2 * unit, c.dy + 3.2 * unit)
            ..lineTo(c.dx + 4.4 * unit, c.dy - 3 * unit),
          knock,
        );
        canvas.restore();
      case MinimalTaskStatus.paused:
        canvas.drawCircle(c, r, line);
        for (final dx in <double>[-2.4, 2.4]) {
          canvas.drawLine(
            c + Offset(dx * unit, -3.4 * unit),
            c + Offset(dx * unit, 3.4 * unit),
            line,
          );
        }
      case MinimalTaskStatus.cancelled:
        canvas.saveLayer(Offset.zero & size, Paint());
        canvas.drawCircle(c, r + w / 2, fill);
        const arm = 3.4;
        canvas.drawLine(
          c + const Offset(-arm, -arm) * unit,
          c + const Offset(arm, arm) * unit,
          knock,
        );
        canvas.drawLine(
          c + const Offset(arm, -arm) * unit,
          c + const Offset(-arm, arm) * unit,
          knock,
        );
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StatusPainter old) =>
      old.status != status || old.color != color || old.stroke != stroke;
}

/// How pressing a piece of work is — the five priorities an issue list
/// sorts by, each with its glyph ([MinimalPriorityIcon]) and its [label].
enum MinimalPriority {
  /// Now.
  urgent('Urgent'),

  /// Soon.
  high('High'),

  /// In its turn.
  medium('Medium'),

  /// When there is time.
  low('Low'),

  /// Not set.
  none('No priority');

  /// A priority saying [label].
  const MinimalPriority(this.label);

  /// The priority's name, as a list or a screen reader says it.
  final String label;
}

/// The glyph of a [MinimalPriority], painted to sit beside a
/// [MinimalStatusIcon] in a row: three rising bars filled to the level (high
/// three, medium two, low one, the rest faint), urgent as a filled square
/// in the destructive colour with an exclamation cut out of it, and no priority
/// as three faint dashes. The bars print in the secondary ink, so priority
/// reads by shape while status keeps the colour.
///
/// With [onPressed] the glyph is the row's quick priority control (it usually
/// opens a menu of priorities) and pads its hit area to 44 px. A screen
/// reader hears `High priority`.
///
/// ```dart
/// MinimalPriorityIcon(MinimalPriority.high)
/// ```
class MinimalPriorityIcon extends StatelessWidget {
  /// The glyph of [priority].
  const MinimalPriorityIcon(
    this.priority, {
    super.key,
    this.size = MinimalIconSize.i16,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  /// The priority it shows.
  final MinimalPriority priority;

  /// Its size.
  final double size;

  /// Makes the glyph a control; null leaves it a mark.
  final VoidCallback? onPressed;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final label = priority == MinimalPriority.none
        ? priority.label
        : '${priority.label} priority';
    // One item at its box for ui_core's keyline check: "no priority" is three
    // faint dashes whose ink it cannot find.
    final glyph = DesignKeylineFace(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _PriorityPainter(
            priority,
            ink: priority == MinimalPriority.urgent
                ? t.destructive
                : t.mutedForeground,
            faint: t.borderStrong,
          ),
        ),
      ),
    );
    final tap = onPressed;
    if (tap == null) {
      return Semantics(label: label, excludeSemantics: true, child: glyph);
    }
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: tap,
      shape: t.shapes.mark,
      semanticLabel: label,
      child: ExcludeSemantics(child: glyph),
    );
  }
}

class _PriorityPainter extends CustomPainter {
  _PriorityPainter(this.priority, {required this.ink, required this.faint});

  final MinimalPriority priority;
  final Color ink;
  final Color faint;

  @override
  void paint(Canvas canvas, Size size) {
    // A 16-unit grid: three 3-unit bars on 2-unit gaps, rising 6, 9, 12
    // units from the baseline 14.
    final unit = size.width / 16;
    switch (priority) {
      case MinimalPriority.urgent:
        final square = RRect.fromRectAndRadius(
          Rect.fromLTWH(1.5 * unit, 1.5 * unit, 13 * unit, 13 * unit),
          Radius.circular(3 * unit),
        );
        canvas.saveLayer(Offset.zero & size, Paint());
        canvas.drawRRect(square, Paint()..color = ink);
        final knock = Paint()..blendMode = BlendMode.clear;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(7 * unit, 4 * unit, 2 * unit, 5.5 * unit),
            Radius.circular(unit),
          ),
          knock,
        );
        canvas.drawCircle(Offset(8 * unit, 11.5 * unit), 1.1 * unit, knock);
        canvas.restore();
      case MinimalPriority.none:
        final dash = Paint()..color = faint;
        for (var i = 0; i < 3; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                (2 + i * 4.5) * unit,
                7.25 * unit,
                3 * unit,
                1.5 * unit,
              ),
              Radius.circular(0.75 * unit),
            ),
            dash,
          );
        }
      case MinimalPriority.high ||
          MinimalPriority.medium ||
          MinimalPriority.low:
        final level = switch (priority) {
          MinimalPriority.high => 3,
          MinimalPriority.medium => 2,
          _ => 1,
        };
        for (var i = 0; i < 3; i++) {
          final height = (6 + i * 3) * unit;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                (2 + i * 4.5) * unit,
                14 * unit - height,
                3 * unit,
                height,
              ),
              Radius.circular(unit),
            ),
            Paint()..color = i < level ? ink : faint,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_PriorityPainter old) =>
      old.priority != priority || old.ink != ink || old.faint != faint;
}

/// A small bordered status label with a leading dot — an order's `Late`,
/// `Baking`, `Ready`. The states that need attention (success, warn,
/// danger) ink their label and tint their border; the waiting ones (neutral,
/// accent) keep the ink and let the dot alone carry the colour, so a table
/// of badges reads by exception.
///
/// ```dart
/// MinimalStatusBadge('Late', tone: MinimalTone.warning)
/// ```
class MinimalStatusBadge extends StatelessWidget {
  /// A badge saying [label] in [tone].
  const MinimalStatusBadge(
    this.label, {
    super.key,
    this.tone = MinimalTone.neutral,
    this.dot = true,
  });

  /// A badge for a [MinimalTaskStatus], in its label and tone.
  MinimalStatusBadge.status(MinimalTaskStatus status, {Key? key})
    : this(status.label, key: key, tone: status.tone);

  /// What it says.
  final String label;

  /// Its dot's tone.
  final MinimalTone tone;

  /// Lead with the tone's dot.
  final bool dot;

  /// The badge's dot diameter.
  static const double dotSize = 6;

  /// The space between the dot and the label.
  static const double dotGap = 5;

  /// The badge's inset round its label.
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 7,
    vertical: 2,
  );

  /// The label's register: [MinimalThemeData.caption] medium, a step down to
  /// 11/16 so a badge sits inside a 36 px compact row.
  static TextStyle labelStyleOf(MinimalThemeData t) =>
      t.caption.copyWith(fontSize: 11, height: 16 / 11).medium;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final colors = t.tone(tone);
    final loud = switch (tone) {
      MinimalTone.success ||
      MinimalTone.warning ||
      MinimalTone.destructive => true,
      MinimalTone.neutral || MinimalTone.primary => false,
    };
    return Container(
      padding: padding,
      decoration: minimalFrame(
        t.shapes.mark,
        side: BorderSide(
          color: loud ? colors.indicator.withValues(alpha: 0.35) : t.border,
          width: t.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: colors.indicator,
                shape: BoxShape.circle,
              ),
            ),
            const MinimalGap(dotGap),
          ],
          Flexible(
            child: Text(
              label,
              style: labelStyleOf(t).c(loud ? colors.foreground : t.foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
