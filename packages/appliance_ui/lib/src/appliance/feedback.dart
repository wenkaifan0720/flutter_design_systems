/// Appliance's feedback: [ApplianceProgressBar] (a slot lit as far as the
/// work has gone), [ApplianceProgressRing] (a dial's ring lit round),
/// [ApplianceSkeleton] (unlit plates where words will be),
/// [ApplianceStatusView] (a whole page's outcome, under its lamp) and
/// [ApplianceMeter] (a needle over a printed scale).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/spring_value.dart';
import 'material.dart';
import 'theme.dart';

/// Whether the platform asks for less motion.
bool _still(BuildContext context) => MediaQuery.disableAnimationsOf(context);

/// A progress bar: a dark slot cut in the panel, lit in the signal colour
/// as far as the work has gone. With no [value] a lit run sweeps along it
/// (it stands still, half lit, under Reduce Motion).
///
/// ```dart
/// ApplianceProgressBar(value: 0.4, semanticLabel: 'Uploading')
/// ```
class ApplianceProgressBar extends StatefulWidget {
  /// A bar at [value] (0 to 1), or sweeping when null.
  const ApplianceProgressBar({
    super.key,
    this.value,
    this.semanticLabel,
    this.height = 6,
    this.style,
  }) : assert(value == null || (value >= 0 && value <= 1));

  /// How far, 0 to 1; null while unknown.
  final double? value;

  /// What is under way, for a screen reader.
  final String? semanticLabel;

  /// The slot's height.
  final double height;

  /// Its style: `fill` (the slot) and `foreground` (its light), over
  /// [ApplianceThemeData.progressStyle].
  final ApplianceStyle? style;

  @override
  State<ApplianceProgressBar> createState() => _ApplianceProgressBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('value', value, defaultValue: null));
  }
}

class _ApplianceProgressBarState extends State<ApplianceProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(ApplianceProgressBar old) {
    super.didUpdateWidget(old);
    _run();
  }

  void _run() {
    final sweeping = widget.value == null && !_still(context);
    if (sweeping && !_sweep.isAnimating) {
      _sweep.repeat();
    } else if (!sweeping && _sweep.isAnimating) {
      _sweep.stop();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([widget.style, theme.progressStyle], const {});
    final value = widget.value;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      label: widget.semanticLabel,
      value: value == null ? null : '${(value * 100).round()}%',
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _sweep,
          builder: (context, _) => CustomPaint(
            painter: _SlotBarPainter(
              slot: layered.fill ?? c.slot,
              light: layered.foreground ?? c.signal,
              shade: c.highlight,
              from: value == null
                  ? (_still(context) ? 0 : _sweep.value * 1.4 - 0.4)
                  : 0,
              to: value ?? (_still(context) ? 0.5 : _sweep.value * 1.4),
              rtl: rtl,
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotBarPainter extends CustomPainter {
  _SlotBarPainter({
    required this.slot,
    required this.light,
    required this.shade,
    required this.from,
    required this.to,
    required this.rtl,
  });

  final Color slot;
  final Color light;
  final Color shade;
  final double from;
  final double to;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    final whole = RRect.fromRectAndRadius(Offset.zero & size, r);
    canvas
      ..drawRRect(whole, Paint()..color = slot)
      // The slot's lower lip catches the light.
      ..drawLine(
        Offset(r.x, size.height - 0.5),
        Offset(size.width - r.x, size.height - 0.5),
        Paint()
          ..color = shade.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    final inset = math.min(1.0, size.shortestSide / 2);
    final inside = (Offset.zero & size).deflate(inset);
    final a = from.clamp(0.0, 1.0) * inside.width;
    final b = to.clamp(0.0, 1.0) * inside.width;
    if (b - a <= 0) return;
    final lit = rtl
        ? Rect.fromLTRB(
            inside.right - b,
            inside.top,
            inside.right - a,
            inside.bottom,
          )
        : Rect.fromLTRB(
            inside.left + a,
            inside.top,
            inside.left + b,
            inside.bottom,
          );
    canvas
      ..save()
      ..clipRRect(whole)
      ..drawRRect(
        RRect.fromRectAndRadius(lit, Radius.circular(inside.height / 2)),
        Paint()..color = light,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_SlotBarPainter old) =>
      old.from != from ||
      old.to != to ||
      old.slot != slot ||
      old.light != light ||
      old.rtl != rtl;
}

/// A progress ring: a dial's dark ring, lit round in the signal colour as
/// far as the work has gone; with no [value] a lit arc turns in it (still,
/// a quarter lit, under Reduce Motion).
///
/// ```dart
/// ApplianceProgressRing(value: 0.7, semanticLabel: 'Saving')
/// ```
class ApplianceProgressRing extends StatefulWidget {
  /// A ring at [value] (0 to 1), or turning when null.
  const ApplianceProgressRing({
    super.key,
    this.value,
    this.semanticLabel,
    this.size = 32,
    this.stroke = 4,
    this.style,
  }) : assert(value == null || (value >= 0 && value <= 1));

  /// How far, 0 to 1; null while unknown.
  final double? value;

  /// What is under way, for a screen reader.
  final String? semanticLabel;

  /// Its diameter.
  final double size;

  /// The ring's width.
  final double stroke;

  /// Its style: `fill` (the dark ring) and `foreground` (its lit arc), over
  /// [ApplianceThemeData.progressStyle].
  final ApplianceStyle? style;

  @override
  State<ApplianceProgressRing> createState() => _ApplianceProgressRingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('value', value, defaultValue: null));
  }
}

class _ApplianceProgressRingState extends State<ApplianceProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(ApplianceProgressRing old) {
    super.didUpdateWidget(old);
    _run();
  }

  void _run() {
    final turning = widget.value == null && !_still(context);
    if (turning && !_turn.isAnimating) {
      _turn.repeat();
    } else if (!turning && _turn.isAnimating) {
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
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([widget.style, theme.progressStyle], const {});
    final value = widget.value;
    return Semantics(
      label: widget.semanticLabel,
      value: value == null ? null : '${(value * 100).round()}%',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _turn,
          builder: (context, _) => CustomPaint(
            painter: _RingPainter(
              slot: layered.fill ?? c.slot,
              light: layered.foreground ?? c.signal,
              stroke: widget.stroke,
              start: value == null ? _turn.value * 2 * math.pi : 0,
              sweep: value == null ? math.pi / 2 : value * 2 * math.pi,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.slot,
    required this.light,
    required this.stroke,
    required this.start,
    required this.sweep,
  });

  final Color slot;
  final Color light;
  final double stroke;
  final double start;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = slot
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (sweep <= 0) return;
    canvas.drawArc(
      rect.deflate(0.75),
      start - math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = light
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke - 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.start != start ||
      old.sweep != sweep ||
      old.slot != slot ||
      old.light != light;
}

/// A skeleton: unlit plates pressed into the panel where words and
/// pictures will stand, breathing slowly while they load (still under
/// Reduce Motion). Give it the shape the content will take.
///
/// ```dart
/// const ApplianceSkeleton(width: 160, height: 14)
/// ```
class ApplianceSkeleton extends StatefulWidget {
  /// A plate [width] by [height] (null: as wide as it is let).
  const ApplianceSkeleton({
    super.key,
    this.width,
    required this.height,
    this.circle = false,
    this.style,
  });

  /// Its width; null fills the width.
  final double? width;

  /// Its height.
  final double height;

  /// Whether it is round (an avatar's place).
  final bool circle;

  /// Its style: `fill` (the unlit plate), over
  /// [ApplianceThemeData.progressStyle].
  final ApplianceStyle? style;

  @override
  State<ApplianceSkeleton> createState() => _ApplianceSkeletonState();
}

class _ApplianceSkeletonState extends State<ApplianceSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final plate =
        RawStyleOf([widget.style, theme.progressStyle], const {}).fill ??
        c.trough;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              plate,
              c.well,
              Curves.easeInOut.transform(_breath.value) * 0.45,
            ),
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.circle
                ? null
                : BorderRadius.circular(
                    math.min(ApplianceSpacing.tight, widget.height / 2),
                  ),
            border: Border(
              top: BorderSide(color: c.seamShade.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ),
    );
  }
}

/// What an [ApplianceStatusView] reports.
enum ApplianceStatus {
  /// It worked: the lamp lit green.
  success,

  /// It failed: the lamp lit red.
  error,

  /// Something to know: the lamp lit in the signal colour.
  info,

  /// Still working: the ring turning.
  working,
}

/// A status view: a whole page's outcome. A large lamp (or a turning ring
/// while it works) in a sunk bezel, a heading, what happened, and the keys
/// that go on from it.
///
/// ```dart
/// ApplianceStatusView(status: ApplianceStatus.error, title: 'Payment failed', message: 'Your card was declined. Nothing was taken.')
/// ```
class ApplianceStatusView extends StatelessWidget {
  /// A [status] report.
  const ApplianceStatusView({
    super.key,
    required this.status,
    required this.title,
    this.message,
    this.actions = const [],
    this.style,
  });

  /// What it reports.
  final ApplianceStatus status;

  /// The heading.
  final String title;

  /// What happened.
  final String? message;

  /// Keys that go on from it, the main one first.
  final List<Widget> actions;

  /// Its style: `fill` (the sunk bezel) and `foreground` (the lamp), over
  /// [ApplianceThemeData.displayStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final layered = RawStyleOf([style, theme.displayStyle], const {});
    final lamp =
        layered.foreground ??
        switch (status) {
          ApplianceStatus.success => c.ready,
          ApplianceStatus.error => c.danger,
          ApplianceStatus.info => c.signal,
          ApplianceStatus.working => c.signal,
        };
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 64,
            child: ApplianceSurface(
              face: ApplianceFace.well(
                c,
                fill: layered.fill ?? c.trough,
              ).copyWith(radius: BorderRadius.circular(32)),
              child: Center(
                child: status == ApplianceStatus.working
                    ? const ApplianceProgressRing(size: 36)
                    : ApplianceLamp(lit: true, size: 22, color: lamp),
              ),
            ),
          ),
          const SizedBox(height: ApplianceSpacing.regular),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: t.heading.copyWith(color: c.print),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: ApplianceSpacing.small),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ApplianceMetrics.readingWidth,
              ),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: t.body.copyWith(color: c.printMuted),
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: ApplianceSpacing.large),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: ApplianceSpacing.small,
              runSpacing: ApplianceSpacing.small,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<ApplianceStatus>('status', status))
      ..add(StringProperty('title', title));
  }
}

/// A meter: a needle over a printed scale in a small window, as a gauge on
/// a panel reads. The scale's last stretch from [high] is printed red;
/// the needle swings to a new reading on the lamp's spring.
///
/// ```dart
/// ApplianceMeter(value: 0.62, label: 'Storage', valueText: '6.2 of 10 GB')
/// ```
class ApplianceMeter extends StatelessWidget {
  /// A meter reading [value] (0 to 1).
  const ApplianceMeter({
    super.key,
    required this.value,
    required this.label,
    this.valueText,
    this.high = 0.85,
    this.width = 160,
    this.style,
  }) : assert(value >= 0 && value <= 1),
       assert(high > 0 && high <= 1);

  /// The reading, 0 to 1.
  final double value;

  /// What it measures.
  final String label;

  /// The reading in words ("6.2 of 10 GB"); the percentage otherwise.
  final String? valueText;

  /// Where the red stretch begins, 0 to 1.
  final double high;

  /// The window's width.
  final double width;

  /// Its style: `fill` (the window) and `foreground` (the needle), over
  /// [ApplianceThemeData.displayStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final words = valueText ?? '${(value * 100).round()}%';
    final layered = RawStyleOf([style, theme.displayStyle], const {});
    return Semantics(
      label: label,
      value: words,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: width,
              height: width * 0.58,
              child: ApplianceSurface(
                face: ApplianceFace.well(c, fill: layered.fill ?? c.well),
                child: Padding(
                  padding: const EdgeInsets.all(ApplianceSpacing.small),
                  child: ApplianceSpringValue(
                    value: value,
                    spring: ApplianceMotion.lamp,
                    builder: (context, v, _) => CustomPaint(
                      painter: _GaugePainter(
                        value: v,
                        high: high,
                        print: c.print,
                        muted: c.printMuted,
                        danger: c.danger,
                        needle: layered.foreground ?? c.signal,
                        hub: c.metalDark,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: ApplianceSpacing.small),
            Text(label, style: t.legend.copyWith(color: c.printMuted)),
            Text(words, style: t.figure.copyWith(color: c.print)),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(StringProperty('label', label));
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.high,
    required this.print,
    required this.muted,
    required this.danger,
    required this.needle,
    required this.hub,
  });

  final double value;
  final double high;
  final Color print;
  final Color muted;
  final Color danger;
  final Color needle;
  final Color hub;

  static const double _from = math.pi * 1.15;
  static const double _sweep = math.pi * 0.7;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height * 0.98);
    final r = math.min(size.width / 2, size.height) * 0.92;
    final arc = Rect.fromCircle(center: centre, radius: r);
    // The scale: a fine arc, its red stretch, and ticks every tenth.
    canvas
      ..drawArc(
        arc,
        _from,
        _sweep * high,
        false,
        Paint()
          ..color = muted
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      )
      ..drawArc(
        arc,
        _from + _sweep * high,
        _sweep * (1 - high),
        false,
        Paint()
          ..color = danger
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    for (var i = 0; i <= 10; i++) {
      final a = _from + _sweep * i / 10;
      final long = i % 5 == 0;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        centre + dir * r,
        centre + dir * (r - (long ? 9 : 5)),
        Paint()
          ..color = i / 10 >= high ? danger : print
          ..strokeWidth = long ? 1.6 : 1,
      );
    }
    // The needle, and its hub.
    final a = _from + _sweep * value.clamp(0.0, 1.0);
    final dir = Offset(math.cos(a), math.sin(a));
    canvas
      ..drawLine(
        centre,
        centre + dir * (r - 4),
        Paint()
          ..color = needle
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(centre, 5, Paint()..color = hub);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value ||
      old.high != high ||
      old.print != print ||
      old.needle != needle;
}
