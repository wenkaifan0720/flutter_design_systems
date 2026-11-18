/// Studio's feedback, all light behind glass: [StudioProgressBar] (a row of
/// lit segments in a readout), [StudioSpinner] (lamps chasing round a
/// ring), [StudioLampRing] (a ring lit as far as a fraction),
/// [StudioSkeleton] (glass breathing where content will be), [StudioStatusView]
/// (an empty or failed pane, with its way on) and [StudioBanner] (a notice
/// across the page, its lamp lit).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'surface.dart';
import 'theme.dart';

bool _still(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// How far something has got: a dark readout window with a row of
/// segments, lit from the start as far as [value]. With no [value] it
/// waits: a short lit run sweeps back and forth.
///
/// ```dart
/// StudioProgressBar(value: 0.4, semanticLabel: 'Uploading')
/// ```
class StudioProgressBar extends StatefulWidget {
  /// A bar at [value] (0 to 1), or waiting when null.
  const StudioProgressBar({
    super.key,
    this.value,
    this.semanticLabel,
    this.segments = 24,
    this.color,
  });

  /// How far, 0 to 1; null while it cannot say.
  final double? value;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// How many segments.
  final int segments;

  /// The segments' light; the indicator when null.
  final Color? color;

  @override
  State<StudioProgressBar> createState() => _StudioProgressBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('value', value, defaultValue: null));
  }
}

class _StudioProgressBarState extends State<StudioProgressBar>
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
  void didUpdateWidget(StudioProgressBar old) {
    super.didUpdateWidget(old);
    _run();
  }

  void _run() {
    final wait = widget.value == null && !_still(context);
    if (wait && !_sweep.isAnimating) {
      _sweep.repeat(reverse: true);
    } else if (!wait && _sweep.isAnimating) {
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
    final c = StudioTheme.of(context).colors;
    final value = widget.value;
    return Semantics(
      label: widget.semanticLabel,
      value: value == null ? null : '${(value * 100).round()}%',
      child: SizedBox(
        height: 14,
        child: StudioSurface(
          face: c.readoutFace.copyWith(radius: 4),
          child: Padding(
            padding: const EdgeInsets.all(StudioMetrics.lip),
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _sweep,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _SegmentsPainter(
                    segments: widget.segments,
                    value: value,
                    sweep: _sweep.value,
                    lit: widget.color ?? c.indicator,
                    off: c.lampOff.withValues(alpha: 0.35),
                    rtl: Directionality.of(context) == TextDirection.rtl,
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

class _SegmentsPainter extends CustomPainter {
  _SegmentsPainter({
    required this.segments,
    required this.value,
    required this.sweep,
    required this.lit,
    required this.off,
    required this.rtl,
  });

  final int segments;
  final double? value;
  final double sweep;
  final Color lit;
  final Color off;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 2.0;
    final w = (size.width - gap * (segments - 1)) / segments;
    final run = math.max(3, segments ~/ 5);
    final from = value == null ? (sweep * (segments - run)).round() : 0;
    final to = value == null
        ? from + run
        : (value!.clamp(0, 1) * segments).round();
    final glow = Paint()
      ..color = lit.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (var i = 0; i < segments; i++) {
      final at = rtl ? segments - 1 - i : i;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(at * (w + gap), 0, w, size.height),
        const Radius.circular(1.5),
      );
      final on = i >= from && i < to;
      if (on) canvas.drawRRect(r, glow);
      canvas.drawRRect(r, Paint()..color = on ? lit : off);
    }
  }

  @override
  bool shouldRepaint(_SegmentsPainter old) =>
      old.value != value ||
      old.sweep != sweep ||
      old.lit != lit ||
      old.off != off ||
      old.segments != segments ||
      old.rtl != rtl;
}

/// A ring of small lamps lit as far round as [lit] (0 to 1): a fraction
/// shown as a ring, or a pull's progress.
///
/// ```dart
/// StudioLampRing(lit: 0.6, size: 32, semanticLabel: 'Exported')
/// ```
class StudioLampRing extends StatelessWidget {
  /// A ring lit to [lit].
  const StudioLampRing({
    super.key,
    required this.lit,
    this.size = 32,
    this.lamps = 10,
    this.semanticLabel,
  });

  /// How far round it is lit, 0 to 1.
  final double lit;

  /// Its diameter.
  final double size;

  /// How many lamps round it.
  final int lamps;

  /// What a screen reader calls it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return Semantics(
      label: semanticLabel,
      value: '${(lit * 100).round()}%',
      child: CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(
          lamps: lamps,
          head: (lit.clamp(0, 1) * lamps).round(),
          trail: 0,
          lit: c.indicator,
          off: c.lampOff,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('lit', lit));
  }
}

/// Waiting: a ring of small lamps with the light chasing round it, a
/// fading trail behind. With motion reduced, the ring holds one lamp lit.
///
/// ```dart
/// const StudioSpinner(size: 24, semanticLabel: 'Loading')
/// ```
class StudioSpinner extends StatefulWidget {
  /// A spinner [size] across.
  const StudioSpinner({super.key, this.size = 32, this.semanticLabel});

  /// Its diameter.
  final double size;

  /// What a screen reader calls it.
  final String? semanticLabel;

  @override
  State<StudioSpinner> createState() => _StudioSpinnerState();
}

class _StudioSpinnerState extends State<StudioSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still(context)) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    const lamps = 8;
    return Semantics(
      label: widget.semanticLabel,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _turn,
          builder: (context, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: _RingPainter(
              lamps: lamps,
              head: (_turn.value * lamps).floor() + 1,
              trail: 3,
              lit: c.indicator,
              off: c.lampOff,
              chase: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.lamps,
    required this.head,
    required this.trail,
    required this.lit,
    required this.off,
    this.chase = false,
  });

  final int lamps;
  final int head;
  final int trail;
  final Color lit;
  final Color off;
  final bool chase;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final dot = math.max(2.0, r * 0.22);
    final centre = size.center(Offset.zero);
    for (var i = 0; i < lamps; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / lamps;
      final p = centre + Offset(math.cos(angle), math.sin(angle)) * (r - dot);
      double strength;
      if (chase) {
        final behind = (head - 1 - i) % lamps;
        strength = behind <= trail ? 1 - behind / (trail + 1) : 0;
      } else {
        strength = i < head ? 1 : 0;
      }
      if (strength > 0) {
        canvas.drawCircle(
          p,
          dot * 1.6,
          Paint()
            ..color = lit.withValues(alpha: 0.35 * strength)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
      canvas.drawCircle(
        p,
        dot,
        Paint()..color = Color.lerp(off, lit, strength)!,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.head != head ||
      old.trail != trail ||
      old.lit != lit ||
      old.off != off ||
      old.lamps != lamps ||
      old.chase != chase;
}

/// Where content will be: dark unlit glass in its shape, its light slowly
/// rising and falling while it waits. With motion reduced it stays still.
///
/// ```dart
/// const StudioSkeleton(width: 200, height: 16)
/// ```
class StudioSkeleton extends StatefulWidget {
  /// A [width] × [height] block (a line of words, a cover).
  const StudioSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = StudioRadii.small,
  });

  /// Its width; its column's when null.
  final double? width;

  /// Its height.
  final double height;

  /// Its corners.
  final double radius;

  @override
  State<StudioSkeleton> createState() => _StudioSkeletonState();
}

class _StudioSkeletonState extends State<StudioSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still(context)) {
      _breathe.stop();
    } else if (!_breathe.isAnimating) {
      _breathe.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _breathe,
            builder: (context, _) => DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                color: Color.lerp(
                  c.displayLow,
                  c.display,
                  Curves.easeInOut.transform(_breathe.value),
                ),
                border: Border.all(color: c.displayLine),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _StatusKind { empty, error, loading }

/// A pane of glass with nothing to show, or that failed: the state's glyph
/// lit in a round readout window, a title, a line on why, and the way on as
/// a key. [StudioStatusView.error]
/// lights a red lamp beside the title; [StudioStatusView.loading] shows a
/// spinner and no key.
///
/// ```dart
/// StudioStatusView.error(title: 'Upload failed', message: 'The connection dropped at 64%.', actionLabel: 'Try again', onAction: retry)
/// ```
class StudioStatusView extends StatelessWidget {
  /// Nothing here yet.
  const StudioStatusView({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  }) : _kind = _StatusKind.empty;

  /// Something failed.
  const StudioStatusView.error({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  }) : _kind = _StatusKind.error;

  /// Still coming.
  const StudioStatusView.loading({super.key, required this.title, this.message})
    : icon = null,
      actionLabel = null,
      onAction = null,
      _kind = _StatusKind.loading;

  /// What it says first.
  final String title;

  /// A line on why, or what to do.
  final String? message;

  /// The glyph in the dish.
  final Widget? icon;

  /// The way on's legend.
  final String? actionLabel;

  /// The way on.
  final VoidCallback? onAction;

  final _StatusKind _kind;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final error = _kind == _StatusKind.error;
    return Semantics(
      container: true,
      liveRegion: error,
      // What it says is read on glass (law 2), never on the bare metal.
      child: StudioSurface(
        face: c.displayFace,
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 72,
                child: StudioSurface(
                  // A round readout window, the state's glyph lit behind it:
                  // warm white, or red for a failure.
                  // By night a smoked window, so it parts from the dark
                  // glass it is set in.
                  face: c.readoutFace.copyWith(
                    radius: 36,
                    fill: c.brightness == Brightness.dark
                        ? Color.lerp(c.readout, c.onDisplay, 0.12)
                        : null,
                    fillLow: c.brightness == Brightness.dark
                        ? Color.lerp(c.readoutLow, c.onDisplay, 0.07)
                        : null,
                  ),
                  child: Center(
                    child: _kind == _StatusKind.loading
                        ? const StudioSpinner(size: 32)
                        : IconTheme.merge(
                            data: IconThemeData(
                              size: StudioIconSizes.huge,
                              color: error
                                  ? (c.brightness == Brightness.dark
                                        ? c.danger
                                        : Color.lerp(
                                            c.danger,
                                            const Color(0xFFFFFFFF),
                                            0.3,
                                          )!)
                                  : c.onReadout.withValues(alpha: 0.8),
                            ),
                            child:
                                icon ??
                                Icon(
                                  error
                                      ? LucideIcons.triangleAlert
                                      : LucideIcons.inbox,
                                ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: StudioSpacing.regular),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error) ...[
                    StudioLamp(on: true, color: c.danger, size: 8),
                    const SizedBox(width: StudioSpacing.small),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.title.copyWith(color: c.onDisplay),
                    ),
                  ),
                ],
              ),
              if (message != null) ...[
                const SizedBox(height: StudioSpacing.small),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.secondary.copyWith(
                      color: c.onDisplayMuted,
                    ),
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: StudioSpacing.large),
                StudioButton(
                  actionLabel!,
                  icon: error ? const Icon(LucideIcons.rotateCw) : null,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(EnumProperty<_StatusKind>('kind', _kind));
  }
}

/// A notice across the page: a strip of glass with a lamp at its start
/// (the indicator for news, red with [danger]), its words, and an action
/// and a close key at its end.
///
/// ```dart
/// StudioBanner(message: 'A new version of the mix is ready.', actionLabel: 'Listen', onAction: listen, onClose: dismiss)
/// ```
class StudioBanner extends StatelessWidget {
  /// A banner saying [message].
  const StudioBanner({
    super.key,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
    this.onClose,
    this.danger = false,
    this.closeLabel = 'Close',
  });

  /// What it says.
  final String message;

  /// A heavier line before it.
  final String? title;

  /// Its action's legend.
  final String? actionLabel;

  /// Its action.
  final VoidCallback? onAction;

  /// Puts it away; null for no close key.
  final VoidCallback? onClose;

  /// Whether it warns.
  final bool danger;

  /// The close key's name.
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return Semantics(
      container: true,
      liveRegion: true,
      child: StudioSurface(
        // Words are read on glass (law 2): the strip is a display's.
        face: c.displayFace,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: StudioSpacing.regular,
            end: StudioSpacing.small,
            top: StudioSpacing.small,
            bottom: StudioSpacing.small,
          ),
          child: Row(
            children: [
              StudioLamp(on: true, color: danger ? c.danger : null, size: 8),
              const SizedBox(width: StudioSpacing.medium),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: StudioSpacing.small,
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (title != null)
                          TextSpan(
                            text: '$title  ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        TextSpan(text: message),
                      ],
                    ),
                    style: theme.textTheme.body.copyWith(color: c.onDisplay),
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: StudioSpacing.small),
                StudioButton.text(actionLabel!, onPressed: onAction),
              ],
              if (onClose != null)
                StudioIconButton(
                  icon: const Icon(LucideIcons.x),
                  tooltip: closeLabel,
                  onPressed: onClose,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(FlagProperty('danger', value: danger, ifTrue: 'danger'));
  }
}
