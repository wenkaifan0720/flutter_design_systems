import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/spring.dart';
import '../../theme.dart';

/// How far a task the reader is waiting on has come, in words and a bar:
/// its [label] over it ("Uploading proof of address"), a square-ended bar
/// in the action colour filling a track of the action's tint on a
/// hairline, and under
/// it how far in words ([valueLabel], or the share: "40%"). A new [value]
/// springs the bar to it. With no [value] it is a wait without a measure:
/// a block slides along the track (it stands still in the middle under
/// Reduce Motion), and [valueLabel] says what is happening.
///
/// It is for a wait the reader watches (a file going up); a page's own
/// steps are said in words (the page's caption), and the steps of a form
/// in a [CivicStepIndicator]. A screen reader hears a progress bar called
/// [label] (with [valueLabel]), at its share; without a measure, a wait.
///
/// Reads [CivicStyle]'s fill (the track), foreground (the bar) and
/// textStyle (the label): its `style:`, then
/// [CivicThemeData.progressBarStyle].
///
/// ```dart
/// CivicProgressBar(
///   label: 'Uploading proof of address',
///   value: 0.4,
///   valueLabel: '2 of 5 pages uploaded',
/// )
/// ```
class CivicProgressBar extends StatelessWidget {
  /// A progress bar.
  const CivicProgressBar({
    super.key,
    required this.label,
    this.value,
    this.valueLabel,
    this.style,
  });

  /// What is under way, over the bar.
  final String label;

  /// How far, 0 to 1; null: a wait without a measure.
  final double? value;

  /// How far in words, under the bar; null: the share ("40%"), or nothing
  /// for a wait without a measure.
  final String? valueLabel;

  /// Overrides for this bar's look.
  final CivicStyle? style;

  /// The bar's height.
  static const double thickness = 10;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf([style, t.progressBarStyle], const {});
    final l = RawWidgetsLocalizations.of(context);
    final v = value?.clamp(0.0, 1.0);
    final share = v == null ? null : l.formatPercent(v);
    final under = valueLabel ?? share;
    final track = so.fill ?? t.secondaryFill;
    final bar = so.foreground ?? t.action;
    // A progress bar's share is a number from 0 to 100, as the platforms
    // read it; the words go with its name.
    final heard = valueLabel == null
        ? label
        : '$label${l.listSeparator}$valueLabel';
    return Semantics(
      container: true,
      role: v == null
          ? SemanticsRole.loadingSpinner
          : SemanticsRole.progressBar,
      label: heard,
      value: v == null ? null : '${(v * 100).round()}',
      minValue: v == null ? null : '0',
      maxValue: v == null ? null : '100',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: text.label
                .copyWith(color: t.textPrimary)
                .merge(so.textStyle),
          ),
          const SizedBox(height: CivicSpacing.s8),
          SizedBox(
            height: thickness,
            child: v == null
                ? _Sliding(track: track, bar: bar, rule: t.rule)
                : CivicSpringValue(
                    value: v,
                    spring: CivicMotion.state,
                    builder: (context, at, _) => CustomPaint(
                      painter: _Bar(
                        from: 0,
                        to: at.clamp(0.0, 1.0),
                        track: track,
                        bar: bar,
                        rule: t.rule,
                        rtl: Directionality.of(context) == TextDirection.rtl,
                      ),
                    ),
                  ),
          ),
          if (under != null) ...[
            const SizedBox(height: CivicSpacing.s8),
            Text(under, style: text.body.copyWith(color: t.textSecondary)),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(DoubleProperty('value', value, defaultValue: null))
      ..add(StringProperty('valueLabel', valueLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// The block that slides along a track while there is no measure.
class _Sliding extends StatefulWidget {
  const _Sliding({required this.track, required this.bar, required this.rule});

  final Color track;
  final Color bar;
  final Color rule;

  @override
  State<_Sliding> createState() => _SlidingState();
}

class _SlidingState extends State<_Sliding>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DesignMotionPolicy.of(context).reduceMotion) {
      _run
        ..stop()
        ..value = 0.5;
    } else if (!_run.isAnimating) {
      _run.repeat();
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _run,
      builder: (context, _) {
        // A third of the track, coming in at one end and going out at the
        // other; in the middle when it stands still.
        final at = Curves.easeInOut.transform(_run.value) * (4 / 3) - 1 / 3;
        return CustomPaint(
          painter: _Bar(
            from: at,
            to: at + 1 / 3,
            track: widget.track,
            bar: widget.bar,
            rule: widget.rule,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
        );
      },
    ),
  );
}

class _Bar extends CustomPainter {
  _Bar({
    required this.from,
    required this.to,
    required this.track,
    required this.bar,
    required this.rule,
    required this.rtl,
  });

  final double from;
  final double to;
  final Color track;
  final Color bar;
  final Color rule;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    const corner = Radius.circular(2);
    final whole = Offset.zero & size;
    canvas
      ..save()
      ..clipRRect(RRect.fromRectAndRadius(whole, corner))
      ..drawRect(whole, Paint()..color = track);
    final a = from.clamp(0.0, 1.0) * size.width;
    final b = to.clamp(0.0, 1.0) * size.width;
    if (b > a) {
      canvas.drawRect(
        rtl
            ? Rect.fromLTRB(size.width - b, 0, size.width - a, size.height)
            : Rect.fromLTRB(a, 0, b, size.height),
        Paint()..color = bar,
      );
    }
    canvas
      ..restore()
      // The track's end, on a hairline, so its whole length shows.
      ..drawRRect(
        RRect.fromRectAndRadius(whole.deflate(0.5), corner),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = rule,
      );
  }

  @override
  bool shouldRepaint(_Bar old) =>
      old.from != from ||
      old.to != to ||
      old.track != track ||
      old.bar != bar ||
      old.rule != rule ||
      old.rtl != rtl;
}
