/// Keycap's feedback: what the app says about itself. [KeycapProgressBar]
/// and [KeycapMeter] fill a slot cut into the case; [KeycapSpinner] turns
/// in its own small groove; [KeycapSkeleton] holds a place while it loads;
/// [KeycapBanner] says something on a well of the page; [KeycapStatusView]
/// and [KeycapEmptyState] fill a screen that has nothing else to show.
/// None of it is a key: none of it is pressed.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'cap.dart';
import 'theme.dart';

/// Repeats [builder] with a phase from 0 to 1 every [period], or holds
/// [still] when the platform asks for less motion.
class _Turning extends StatefulWidget {
  const _Turning({
    required this.period,
    required this.builder,
    this.still = 0.25,
  });

  final Duration period;
  final double still;
  final Widget Function(BuildContext context, double phase) builder;

  @override
  State<_Turning> createState() => _TurningState();
}

class _TurningState extends State<_Turning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final calm = MediaQuery.disableAnimationsOf(context);
    if (calm) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => widget.builder(
      context,
      MediaQuery.disableAnimationsOf(context) ? widget.still : _c.value,
    ),
  );
}

/// A slot cut into the case, [height] tall, with a bar of accent plastic
/// lying in it. Shared by the progress bar and the meter.
class _Slot extends StatelessWidget {
  const _Slot({
    required this.height,
    required this.fill,
    required this.color,
    this.start = 0,
  });

  final double height;
  final double start;
  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = KeycapTheme.of(context).colors;
    final r = height / 2;
    return SizedBox(
      height: height,
      child: KeycapWell(
        radius: BorderRadius.circular(r),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final from = (start.clamp(0.0, 1.0)) * w;
            final to = ((start + fill).clamp(0.0, 1.0)) * w;
            if (to - from <= 0) return const SizedBox.expand();
            return Stack(
              children: [
                PositionedDirectional(
                  start: from,
                  width: math.max(to - from, height),
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(r),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(color, const Color(0xFFFFFFFF), 0.12)!,
                          color,
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Color.lerp(color, c.shadow, 0.3)!,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// How far a job has gone: a slot cut into the case with a bar of accent
/// plastic lying in it, filling from the start. With no [value] the bar
/// travels the slot, slowly, while the job's length is unknown (still under
/// Reduce Motion). A screen reader hears the percentage.
///
/// ```dart
/// KeycapProgressBar(value: 0.4, semanticLabel: 'Exporting')
/// ```
class KeycapProgressBar extends StatelessWidget {
  /// A progress bar at [value] (0 to 1), or travelling when null.
  const KeycapProgressBar({
    super.key,
    this.value,
    this.semanticLabel,
    this.style,
  });

  /// How far it has gone, 0 to 1; null while unknown.
  final double? value;

  /// What it is the progress of.
  final String? semanticLabel;

  /// Overrides, over [KeycapThemeData.progressStyle]: [DesignStyle.fill]
  /// the bar's plastic, [DesignStyle.minimumSize] the slot's height.
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final layered = DesignStyleOf([style, theme.progressStyle], const {});
    final h = layered.minimumSize?.height ?? 8;
    final color = layered.fill ?? theme.colors.accent.top;
    final v = value;
    final words = DesignLocalizations.of(context);
    return Semantics(
      label: semanticLabel,
      value: v == null ? words.loadingLabel : '${(v * 100).round()}%',
      child: v == null
          ? _Turning(
              period: const Duration(milliseconds: 1600),
              still: 0.35,
              builder: (context, t) {
                // The bar eases across the slot and back in, a third long.
                final eased = Curves.easeInOut.transform(t);
                return _Slot(
                  height: h,
                  start: -0.33 + eased * 1.33,
                  fill: 0.33,
                  color: color,
                );
              },
            )
          : TweenAnimationBuilder<double>(
              tween: Tween(end: v.clamp(0.0, 1.0)),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              builder: (context, f, _) =>
                  _Slot(height: h, fill: f, color: color),
            ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('value', value, defaultValue: null));
  }
}

/// A small turning arc in its own groove: something is on its way. Under
/// Reduce Motion it holds still. A screen reader hears "Loading" (or
/// [semanticLabel]).
///
/// ```dart
/// const KeycapSpinner()
/// ```
class KeycapSpinner extends StatelessWidget {
  /// A spinner [size] across.
  const KeycapSpinner({
    super.key,
    this.size = 20,
    this.value,
    this.semanticLabel,
    this.color,
  });

  /// Its diameter.
  final double size;

  /// How far a job has gone, 0 to 1, drawn as the arc's length; null while
  /// unknown (it turns).
  final double? value;

  /// What a screen reader hears.
  final String? semanticLabel;

  /// The arc's colour; the accent when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([theme.progressStyle], const {});
    final arc = color ?? layered.fill ?? c.accent.top;
    final stroke = math.max(2.0, size / 8);
    final v = value;
    return Semantics(
      label: semanticLabel ?? DesignLocalizations.of(context).loadingLabel,
      value: v == null ? null : '${(v * 100).round()}%',
      child: SizedBox.square(
        dimension: size,
        child: v != null
            ? CustomPaint(
                painter: _Ring(
                  start: 0,
                  sweep: v.clamp(0.0, 1.0),
                  track: c.well,
                  arc: arc,
                  stroke: stroke,
                ),
              )
            : _Turning(
                period: const Duration(milliseconds: 1100),
                builder: (context, t) => CustomPaint(
                  painter: _Ring(
                    start: t,
                    sweep: 0.28,
                    track: c.well,
                    arc: arc,
                    stroke: stroke,
                  ),
                ),
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
    required this.arc,
    required this.stroke,
  });

  final double start;
  final double sweep;
  final Color track;
  final Color arc;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2 + start * 2 * math.pi,
      sweep * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = arc,
    );
  }

  @override
  bool shouldRepaint(_Ring old) =>
      old.start != start ||
      old.sweep != sweep ||
      old.track != track ||
      old.arc != arc ||
      old.stroke != stroke;
}

/// A known amount out of a whole (storage used, a goal's words): its
/// [label] and its figure over a slot filled that far. Past [high] the bar
/// is moulded in the danger plastic. Unlike a progress bar it is not a job
/// under way; it does not move.
///
/// ```dart
/// KeycapMeter(label: 'Storage', value: 0.72, valueLabel: '7.2 of 10 GB')
/// ```
class KeycapMeter extends StatelessWidget {
  /// A meter at [value] (0 to 1).
  const KeycapMeter({
    super.key,
    required this.label,
    required this.value,
    this.valueLabel,
    this.high,
    this.style,
  });

  /// What it measures.
  final String label;

  /// How full, 0 to 1.
  final double value;

  /// The amount in words ("7.2 of 10 GB"); the percentage when null.
  final String? valueLabel;

  /// Past this the bar turns to the danger plastic; never when null.
  final double? high;

  /// Overrides, over [KeycapThemeData.progressStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.progressStyle], const {});
    final v = value.clamp(0.0, 1.0);
    final over = high != null && v > high!;
    final figure = valueLabel ?? '${(v * 100).round()}%';
    return Semantics(
      label: label,
      value: figure,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The name at the start and the figure at the end; the figure
          // goes under the name when large text leaves no room beside it.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: KeycapSpacing.medium,
            runSpacing: KeycapSpacing.tight,
            children: [
              Text(
                label,
                style: theme.textTheme.secondary.copyWith(
                  color: c.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                figure,
                style: theme.textTheme.figure.copyWith(
                  color: over ? c.dangerInk : c.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: KeycapSpacing.small),
          _Slot(
            height: layered.minimumSize?.height ?? 10,
            fill: v,
            color: over ? c.danger.top : layered.fill ?? c.accent.top,
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(DoubleProperty('value', value));
  }
}

/// A place held while its content loads: a shallow well the shape of what
/// is coming (a line of words, a row, a picture), its floor breathing
/// slowly (still under Reduce Motion). A screen reader passes it by; say
/// "Loading" once for the whole region.
///
/// ```dart
/// const KeycapSkeleton(height: 16, width: 180)
/// ```
class KeycapSkeleton extends StatelessWidget {
  /// A placeholder [width] by [height]; the line's width when [width] is
  /// null.
  const KeycapSkeleton({super.key, this.width, this.height = 16, this.radius});

  /// A placeholder for [lines] lines of words, the last one shorter.
  static Widget lines(int lines, {double lineHeight = 16}) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < lines; i++) ...[
        if (i > 0) const SizedBox(height: KeycapSpacing.small),
        FractionallySizedBox(
          widthFactor: i == lines - 1 && lines > 1 ? 0.6 : 1,
          child: KeycapSkeleton(height: lineHeight),
        ),
      ],
    ],
  );

  /// Its width.
  final double? width;

  /// Its height.
  final double height;

  /// Its corners; a third of its height (at most the well's) when null.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final c = KeycapTheme.of(context).colors;
    final r = radius ?? math.min(height / 3, KeycapMetrics.wellRadius);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: _Turning(
          period: const Duration(milliseconds: 2400),
          still: 0,
          builder: (context, t) {
            final breath = (1 - math.cos(t * 2 * math.pi)) / 2;
            // The floor deepens and comes back, never past the case's
            // colour (by night a pressed well is lighter than the case),
            // and the well's edge holds its shape while it does.
            final deep = Color.alphaBlend(c.wellShade, c.well);
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(c.well, deep, breath * 0.8),
                borderRadius: BorderRadius.circular(r),
                border: Border.all(color: c.edge),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// What a [KeycapBanner] or a [KeycapStatusView] says: its glyph and ink.
enum KeycapTone {
  /// Something to know.
  info,

  /// Something went well.
  success,

  /// Something to watch.
  warning,

  /// Something went wrong.
  danger,
}

(IconData, Color) _toneOf(KeycapTone tone, KeycapColors c) => switch (tone) {
  KeycapTone.info => (LucideIcons.info, c.accentInk),
  KeycapTone.success => (LucideIcons.circleCheck, c.success),
  KeycapTone.warning => (LucideIcons.triangleAlert, c.ink),
  KeycapTone.danger => (LucideIcons.circleAlert, c.dangerInk),
};

/// A message on the page, in a well of its own: its glyph and words in the
/// [tone]'s ink, a [title] over a [message], and its actions printed under
/// them (or at the end, from 600 wide). [onDismissed] adds a small close
/// key. Announced as it appears.
///
/// ```dart
/// KeycapBanner(tone: KeycapTone.danger, title: 'Sync failed', message: 'Your last 3 notes are only on this device.', actions: [KeycapButton.text(onPressed: retry, child: const Text('Try again'))])
/// ```
class KeycapBanner extends StatelessWidget {
  /// A banner.
  const KeycapBanner({
    super.key,
    required this.title,
    this.message,
    this.tone = KeycapTone.info,
    this.actions = const [],
    this.onDismissed,
    this.style,
  });

  /// Its headline.
  final String title;

  /// More words under it.
  final String? message;

  /// What kind of news it is.
  final KeycapTone tone;

  /// What can be done about it: printed keys (`KeycapButton.text`) or one
  /// key.
  final List<Widget> actions;

  /// Puts it away; no close key when null.
  final VoidCallback? onDismissed;

  /// Overrides, over [KeycapThemeData.bannerStyle]: [DesignStyle.fill] its
  /// floor.
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.bannerStyle], const {});
    final (icon, ink) = _toneOf(tone, c);
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final words = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.body.copyWith(
            color: c.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: KeycapSpacing.tight / 2),
            child: Text(message!, style: theme.textTheme.secondary),
          ),
      ],
    );
    final acts = actions.isEmpty
        ? null
        : Wrap(
            spacing: KeycapSpacing.small,
            runSpacing: KeycapSpacing.small,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          );
    return Semantics(
      container: true,
      liveRegion: true,
      child: KeycapWell(
        floor: layered.fill,
        padding: const EdgeInsetsDirectional.fromSTEB(
          KeycapSpacing.regular,
          KeycapSpacing.medium,
          KeycapSpacing.small,
          KeycapSpacing.medium,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: KeycapSpacing.hairline),
              child: Icon(icon, size: 20, color: ink),
            ),
            const SizedBox(width: KeycapSpacing.medium),
            Expanded(
              child: wide && acts != null
                  ? Row(
                      children: [
                        Expanded(child: words),
                        const SizedBox(width: KeycapSpacing.medium),
                        acts,
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        words,
                        if (acts != null) ...[
                          const SizedBox(height: KeycapSpacing.small),
                          acts,
                        ],
                      ],
                    ),
            ),
            if (onDismissed != null)
              KeycapIconButton(
                icon: const Icon(LucideIcons.x),
                semanticLabel: DesignLocalizations.of(context).closeButtonLabel,
                onPressed: onDismissed,
                style: const KeycapStyle(
                  minimumSize: WidgetStatePropertyAll(Size.square(36)),
                  iconSize: WidgetStatePropertyAll(16),
                ),
              )
            else
              const SizedBox(width: KeycapSpacing.small),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(EnumProperty<KeycapTone>('tone', tone));
  }
}

/// What a [KeycapStatusView] shows.
enum KeycapStatus {
  /// Loading: a spinner over the words.
  loading,

  /// Nothing here yet.
  empty,

  /// Something went wrong.
  error,

  /// Done.
  success,
}

/// A screen, or a region of one, with nothing to show but its state:
/// loading, empty, failed, done. A glyph printed on the floor of a small
/// square well, a [title], a [message], and at most one [action] key
/// under them, centred. A failure is announced.
///
/// ```dart
/// KeycapStatusView(status: KeycapStatus.error, title: 'Sync failed', message: 'Check your connection.', action: KeycapButton(onPressed: retry, child: const Text('Try again')))
/// ```
class KeycapStatusView extends StatelessWidget {
  /// A status view.
  const KeycapStatusView({
    super.key,
    required this.status,
    required this.title,
    this.message,
    this.icon,
    this.action,
    this.secondaryAction,
  });

  /// What it shows.
  final KeycapStatus status;

  /// Its headline.
  final String title;

  /// More words.
  final String? message;

  /// The glyph; the status's own when null.
  final IconData? icon;

  /// The one thing to do about it: a key.
  final Widget? action;

  /// A lesser thing to do: a printed key (`KeycapButton.text`).
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final (glyph, ink) = switch (status) {
      KeycapStatus.loading => (null, c.inkMuted),
      KeycapStatus.empty => (LucideIcons.inbox, c.inkMuted),
      KeycapStatus.error => (LucideIcons.cloudOff, c.dangerInk),
      KeycapStatus.success => (LucideIcons.circleCheck, c.success),
    };
    final mark = SizedBox.square(
      dimension: 64,
      child: KeycapWell(
        radius: BorderRadius.circular(KeycapMetrics.panelRadius),
        child: Center(
          child: status == KeycapStatus.loading && icon == null
              ? const KeycapSpinner(size: 28)
              : Icon(icon ?? glyph, size: 28, color: ink),
        ),
      ),
    );
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: mark),
        const SizedBox(height: KeycapSpacing.regular),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.heading.copyWith(color: c.ink),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: KeycapSpacing.small),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.body.copyWith(color: c.inkMuted),
            ),
          ),
        if (action != null || secondaryAction != null) ...[
          const SizedBox(height: KeycapSpacing.large),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: KeycapSpacing.small,
            runSpacing: KeycapSpacing.small,
            children: [?action, ?secondaryAction],
          ),
        ],
      ],
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(KeycapSpacing.large),
          child: Semantics(
            container: true,
            liveRegion: status == KeycapStatus.error,
            child: body,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<KeycapStatus>('status', status))
      ..add(StringProperty('title', title));
  }
}

/// A list or a screen with nothing in it yet: a glyph in a small well, a
/// [title] saying what will be here, a [message] saying how, and the one
/// [action] that starts it. [KeycapStatusView] at [KeycapStatus.empty].
///
/// ```dart
/// KeycapEmptyState(icon: LucideIcons.notebookPen, title: 'No notes yet', message: 'Notes you write show here.', action: KeycapButton.accent(onPressed: write, child: const Text('New note')))
/// ```
class KeycapEmptyState extends StatelessWidget {
  /// An empty state.
  const KeycapEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.action,
  });

  /// What will be here.
  final String title;

  /// How it gets here.
  final String? message;

  /// The glyph; an empty tray when null.
  final IconData? icon;

  /// The one thing to do: a key.
  final Widget? action;

  @override
  Widget build(BuildContext context) => KeycapStatusView(
    status: KeycapStatus.empty,
    title: title,
    message: message,
    icon: icon,
    action: action,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
  }
}
