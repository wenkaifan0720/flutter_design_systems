/// How far a piece of work has gone, in Ledger's hand: a rule that fills, a
/// ring that closes, and the paper's placeholder lines while a page loads.
library;

import 'package:flutter/foundation.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../internal/face.dart';
import '../../theme.dart';

/// How far a piece of work has gone along a rule: the light rule its whole
/// length, the ink filling it from the reading start to [value] in Ledger's
/// one motion. With no [value] it is under way without a measure: a short
/// stroke of the ink runs the rule's length and starts again (with reduced
/// motion a third of the rule stands inked). A screen reader hears its
/// [label] and how far it is ("60%").
///
/// ```dart
/// LedgerProgressBar(value: .6, label: 'Uploading the statement')
/// ```
class LedgerProgressBar extends StatefulWidget {
  /// A rule filled to [value] (0 to 1); null runs without a measure.
  const LedgerProgressBar({required this.label, this.value, super.key})
    : assert(value == null || (value >= 0 && value <= 1));

  /// How far, 0 to 1; null: under way, no measure.
  final double? value;

  /// What is under way.
  final String label;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value, defaultValue: null))
      ..add(StringProperty('label', label));
  }

  @override
  State<LedgerProgressBar> createState() => _LedgerProgressBarState();
}

class _LedgerProgressBarState extends State<LedgerProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  // Run from build: iOS's Reduce Motion comes as a build, never as
  // didChangeDependencies (LedgerMotion.isReduced).
  void _sync() {
    final runs = widget.value == null && !LedgerMotion.isReduced(context);
    if (runs && !_run.isAnimating) {
      _run.repeat();
    } else if (!runs && _run.isAnimating) {
      _run.stop();
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final t = context.ledgerTheme;
    final v = widget.value;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      label: widget.label,
      value: v == null ? null : '${(v * 100).round()}%',
      excludeSemantics: true,
      child: SizedBox(
        height: _thick,
        width: double.infinity,
        child: v != null
            ? LedgerEase(
                value: v,
                builder: (context, at, _) => CustomPaint(
                  painter: _Rule(
                    from: 0,
                    to: at.clamp(0.0, 1.0),
                    rtl: rtl,
                    track: t.border,
                    ink: t.textPrimary,
                  ),
                ),
              )
            : LedgerMotion.isReduced(context)
            ? CustomPaint(
                painter: _Rule(
                  from: 0,
                  to: 1 / 3,
                  rtl: rtl,
                  track: t.border,
                  ink: t.textPrimary,
                ),
              )
            : AnimatedBuilder(
                animation: _run,
                builder: (context, _) {
                  final head = Curves.easeInOut.transform(_run.value) * 1.3;
                  return CustomPaint(
                    painter: _Rule(
                      from: (head - .3).clamp(0.0, 1.0),
                      to: head.clamp(0.0, 1.0),
                      rtl: rtl,
                      track: t.border,
                      ink: t.textPrimary,
                    ),
                  );
                },
              ),
      ),
    );
  }

  static const double _thick = 2;
}

class _Rule extends CustomPainter {
  _Rule({
    required this.from,
    required this.to,
    required this.rtl,
    required this.track,
    required this.ink,
  });

  final double from;
  final double to;
  final bool rtl;
  final Color track;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = track
        ..strokeWidth = 1,
    );
    double x(double f) => (rtl ? 1 - f : f) * size.width;
    if (to > from) {
      canvas.drawLine(
        Offset(x(from), y),
        Offset(x(to), y),
        Paint()
          ..color = ink
          ..strokeWidth = size.height,
      );
    }
  }

  @override
  bool shouldRepaint(_Rule old) =>
      old.from != from ||
      old.to != to ||
      old.rtl != rtl ||
      old.track != track ||
      old.ink != ink;
}

/// How far a piece of work has gone round a ring: the light ring whole, the
/// ink closing it clockwise from the top to [value]; the figure in the mono
/// inside it when [showValue]. With no [value] a quarter of the ink turns
/// round the ring (still, with reduced motion). [size] is its across. A
/// screen reader hears its [label] and how far it is.
///
/// ```dart
/// LedgerProgressRing(value: .4, label: 'Saving the budget', showValue: true)
/// ```
class LedgerProgressRing extends StatefulWidget {
  /// A ring closed to [value]; null turns without a measure.
  const LedgerProgressRing({
    required this.label,
    this.value,
    this.size = 40,
    this.showValue = false,
    super.key,
  }) : assert(value == null || (value >= 0 && value <= 1));

  /// How far, 0 to 1; null: under way, no measure.
  final double? value;

  /// What is under way.
  final String label;

  /// Its across.
  final double size;

  /// Whether the percent stands inside it.
  final bool showValue;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value, defaultValue: null))
      ..add(StringProperty('label', label))
      ..add(DoubleProperty('size', size))
      ..add(FlagProperty('showValue', value: showValue, ifTrue: 'showValue'));
  }

  @override
  State<LedgerProgressRing> createState() => _LedgerProgressRingState();
}

class _LedgerProgressRingState extends State<LedgerProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  // Run from build: iOS's Reduce Motion comes as a build, never as
  // didChangeDependencies (LedgerMotion.isReduced).
  void _sync() {
    final runs = widget.value == null && !LedgerMotion.isReduced(context);
    if (runs && !_turn.isAnimating) {
      _turn.repeat();
    } else if (!runs && _turn.isAnimating) {
      _turn.stop();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final t = context.ledgerTheme;
    final v = widget.value;
    Widget ring(double start, double sweep) => CustomPaint(
      painter: _Ring(
        start: start,
        sweep: sweep,
        track: t.border,
        ink: t.textPrimary,
      ),
    );
    return Semantics(
      label: widget.label,
      value: v == null ? null : '${(v * 100).round()}%',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: v != null
                  ? LedgerEase(
                      value: v,
                      builder: (context, at, _) => ring(0, at.clamp(0.0, 1.0)),
                    )
                  : LedgerMotion.isReduced(context)
                  ? ring(0, .25)
                  : AnimatedBuilder(
                      animation: _turn,
                      builder: (context, _) => ring(_turn.value, .25),
                    ),
            ),
            if (widget.showValue && v != null)
              Text(
                '${(v * 100).round()}',
                textScaler: TextScaler.noScaling,
                style: t.meta.medium.colored(t.textPrimary),
              ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends CustomPainter {
  _Ring({
    required this.start,
    required this.sweep,
    required this.track,
    required this.ink,
  });

  /// Where the ink starts, in turns from the top.
  final double start;

  /// How much of the ring is inked, in turns.
  final double sweep;
  final Color track;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final ringRect = r.deflate(_thick / 2);
    canvas.drawArc(
      ringRect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (sweep > 0) {
      canvas.drawArc(
        ringRect,
        -math.pi / 2 + start * 2 * math.pi,
        sweep * 2 * math.pi,
        false,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = _thick,
      );
    }
  }

  static const double _thick = 2.5;

  @override
  bool shouldRepaint(_Ring old) =>
      old.start != start ||
      old.sweep != sweep ||
      old.track != track ||
      old.ink != ink;
}

/// The paper's placeholder while a page loads: [lines] bars of the darker
/// paper in the shape of the words to come (the last one short), a slow
/// sheen passing over them, still with reduced motion; [avatar] puts a disc
/// before them, as a row's initials stand. A screen reader hears "Loading"
/// once for the whole placeholder.
///
/// ```dart
/// LedgerSkeleton(lines: 2, avatar: true)
/// ```
class LedgerSkeleton extends StatefulWidget {
  /// A placeholder of [lines] bars.
  const LedgerSkeleton({this.lines = 3, this.avatar = false, super.key})
    : assert(lines > 0);

  /// How many bars.
  final int lines;

  /// Whether a disc stands before them.
  final bool avatar;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('lines', lines))
      ..add(FlagProperty('avatar', value: avatar, ifTrue: 'avatar'));
  }

  @override
  State<LedgerSkeleton> createState() => _LedgerSkeletonState();
}

class _LedgerSkeletonState extends State<LedgerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  // Run from build: iOS's Reduce Motion comes as a build, never as
  // didChangeDependencies (LedgerMotion.isReduced).
  void _sync() {
    if (LedgerMotion.isReduced(context)) {
      _sheen.stop();
    } else if (!_sheen.isAnimating) {
      _sheen.repeat();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final t = context.ledgerTheme;
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: t.selectedFill,
          borderRadius: BorderRadius.circular(t.smallRadius / 2),
        ),
      ),
    );
    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: LedgerSpacing.s12,
      children: [
        if (widget.avatar)
          Container(
            width: _disc,
            height: _disc,
            decoration: BoxDecoration(
              color: t.selectedFill,
              shape: BoxShape.circle,
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: LedgerSpacing.s8,
            children: [
              for (var i = 0; i < widget.lines; i++)
                bar(
                  i == widget.lines - 1 && widget.lines > 1 ? .55 : 1,
                  i == 0 ? _first : _line,
                ),
            ],
          ),
        ),
      ],
    );
    return Semantics(
      label: 'Loading',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _sheen,
        child: body,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final at = _sheen.value * 2 - .5;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                t.selectedFill,
                t.surface.withValues(alpha: .7),
                t.selectedFill,
              ],
              stops: [
                (at - .2).clamp(0.0, 1.0),
                at.clamp(0.0, 1.0),
                (at + .2).clamp(0.0, 1.0),
              ],
            ).createShader(rect);
          },
          child: child,
        ),
      ),
    );
  }

  static const double _disc = 36;
  static const double _first = 14;
  static const double _line = 10;
}
