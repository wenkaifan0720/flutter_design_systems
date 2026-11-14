import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'behavior.dart';
import 'component_themes.dart';
import 'acts.dart';
import 'internal/face.dart';
import 'frames.dart';
import 'glyphs.dart';
import 'localizations.dart';
import 'layout.dart';
import 'theme.dart';
import 'tone.dart';
import 'internal/caps.dart';
import 'internal/marks.dart';
import 'pixels.dart';

/// A semantic notice using the desktop alert window and a tone-specific glyph.
///
/// ```dart
/// RetroDesktopBanner(title: 'Saved', message: 'Your changes are ready.', tone: RetroDesktopTone.success)
/// ```
class RetroDesktopBanner extends StatelessWidget {
  /// Creates a [RetroDesktopBanner].
  const RetroDesktopBanner({
    super.key,
    required this.title,
    this.message,
    this.tone = RetroDesktopTone.info,
    this.actions = const [],
    this.onDismissed,
    this.dismissLabel,
    this.live = true,
    this.mark,
    this.style,
  });

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// Whether changes are announced as a live region.
  final bool live;

  /// An identifying glyph or caller-supplied widget.
  final Widget? mark;

  /// The heading displayed above the content.
  final String title;

  /// The message displayed to the user.
  final String? message;

  /// Overrides the accessible name of the dismiss action.
  final String? dismissLabel;

  /// The meaning conveyed by the notice and its identifying mark.
  final RetroDesktopTone tone;

  /// The actions displayed after the content.
  final List<Widget> actions;

  /// Called when the user dismisses it with its dismiss button.
  final VoidCallback? onDismissed;
  @override
  Widget build(BuildContext context) => RetroDesktopAlert(
    // In the window's content: no window's shadow.
    floating: false,
    title: title,
    style: style,
    liveRegion: live,
    mark: mark,
    body: message,
    icon: switch (tone) {
      RetroDesktopTone.info => RetroDesktopGlyphs.info,
      RetroDesktopTone.success => RetroDesktopGlyphs.circleCheck,
      RetroDesktopTone.warning => RetroDesktopGlyphs.triangleAlert,
      RetroDesktopTone.danger => RetroDesktopGlyphs.circleAlert,
    },
    actions: [
      ...actions,
      if (onDismissed != null)
        RetroDesktopButton(
          dismissLabel ??
              DesignLocalizations.of(context).modalBarrierDismissLabel,
          onPressed: onDismissed,
        ),
    ],
  );
}

/// A rectangular count mark, alone or beside another widget.
///
/// ```dart
/// RetroDesktopBadge(3, label: 'Unread messages')
/// ```
class RetroDesktopBadge extends StatelessWidget {
  /// Creates a [RetroDesktopBadge].
  const RetroDesktopBadge(
    this.count, {
    super.key,
    this.label,
    this.child,
    this.style,
  }) : assert(count >= 0);

  /// The count displayed by this part.
  final int count;

  /// The visible or accessible name of this part.
  final String? label;

  /// The widget displayed inside this part.
  final Widget? child;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final countText = RetroDesktopLocalizations.of(context).formatNumber(count);
    final badge = Semantics(
      label: label ?? countText,
      child: ExcludeSemantics(
        child: retroDesktopFace(
          states: const {WidgetState.selected},
          scale: RetroDesktopFaceScale.mark,
          component: t.badgeTheme,
          style: style,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          child: RetroDesktopCaps(Text(countText)),
        ),
      ),
    );
    if (child == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: badge,
      );
    }
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [child!, badge],
    );
  }
}

/// The busy pointer as a picture: Platinum's wristwatch, its hand going round, or Chisel's hourglass, its sand running.
/// A null [value] denotes work without a known total; with a value, the hand stands that far round (the sand that far
/// run through). Where motion is reduced, the picture stands still.
///
/// ```dart
/// RetroDesktopCircularProgressIndicator(value: .6, label: 'Upload')
/// ```
class RetroDesktopCircularProgressIndicator extends StatefulWidget {
  /// Creates a [RetroDesktopCircularProgressIndicator].
  const RetroDesktopCircularProgressIndicator({
    super.key,
    this.value,
    this.label,
    this.size = 32,
    this.style,
  }) : assert(value == null || (value >= 0 && value <= 1)),
       assert(size >= 12);

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The current value to display or edit.
  final double? value;

  /// The visible or accessible name of this part.
  final String? label;

  /// The size of the visible face; minimum interactive reach is retained.
  final double size;
  @override
  State<RetroDesktopCircularProgressIndicator> createState() =>
      _ProgressState();
}

class _ProgressState extends State<RetroDesktopCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(vsync: this);
  void _configure() {
    final duration = RetroDesktopMotion.of(context).travel;
    if (widget.value == null && duration > Duration.zero) {
      if (!_animation.isAnimating || _animation.duration != duration) {
        _animation.duration = duration;
        _animation.repeat();
      }
    } else {
      _animation.stop();
      _animation.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  @override
  void didUpdateWidget(RetroDesktopCircularProgressIndicator old) {
    super.didUpdateWidget(old);
    _configure();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) get) =>
        RetroDesktopStyle.first([widget.style, t.progressTheme], get, const {});
    final dimension = math.max(
      widget.size,
      slot((s) => s.minimumSize)?.longestSide ?? 0,
    );
    return Semantics(
      label: widget.label ?? DesignLocalizations.of(context).loadingLabel,
      value: widget.value == null
          ? null
          : RetroDesktopLocalizations.of(context).formatPercent(widget.value!),
      child: RepaintBoundary(
        child: retroDesktopOwnSize(
          width: dimension,
          height: dimension,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              // Without a total the watch's hand ticks round in twelve steps
              // and the hourglass runs its sand through and turns again.
              final turn =
                  widget.value ??
                  (t.chisel
                      ? _animation.value
                      : (_animation.value * 12).floor() / 12);
              return RetroDesktopPixelPaint(
                painter: RetroDesktopArtPainter(
                  retroDesktopBusyRows(chisel: t.chisel, progress: turn),
                  {
                    'k': const Color(0xff000000),
                    'w': slot((s) => s.fill) ?? const Color(0xffffffff),
                    'g': const Color(0xff8a8a8a),
                    'm': slot((s) => s.foreground) ?? const Color(0xff000000),
                  },
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Placeholder bars in the period's 50% grey: a checkerboard of the shadow ink (the light bevel by night), one logical
/// pixel a cell, as a screen with no grey to spare drew a dimmed thing. They stand still; nothing shimmers.
///
/// ```dart
/// RetroDesktopSkeleton(lines: 3, label: 'Loading messages')
/// ```
class RetroDesktopSkeleton extends StatelessWidget {
  /// Creates a [RetroDesktopSkeleton].
  const RetroDesktopSkeleton({
    super.key,
    this.style,
    this.lines = 3,
    this.label,
    this.width,
  }) : assert(lines > 0);

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The number of visible text or placeholder lines.
  final int lines;

  /// The visible or accessible name of this part.
  final String? label;

  /// The width in logical pixels.
  final double? width;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) get) =>
        RetroDesktopStyle.first([style, t.progressTheme], get, const {});
    // By night the checkerboard is of the light bevel: the shadow ink is lost
    // on a dark ground.
    final ink =
        slot((s) => s.fill) ??
        (t.colors.dark ? t.colors.bevelLight : t.colors.bevelDark);
    return Semantics(
      label: label ?? DesignLocalizations.of(context).loadingLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lines; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == lines - 1 ? 0 : 8 * t.density.vertical,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: i == lines - 1 ? .65 : 1,
                    child: SizedBox(
                      height: math.max(
                        12 * t.density.vertical,
                        slot((s) => s.minimumSize)?.height ?? 0,
                      ),
                      child: RetroDesktopPixelPaint(painter: _Dither(ink)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 50% checkerboard of [ink], one logical pixel a cell, on the device's grid.
class _Dither extends RetroDesktopPixelPainter {
  const _Dither(this.ink);
  final Color ink;
  @override
  void paint(RetroDesktopPixelGrid px, Size size) {
    final cells = Path();
    final across = size.width.floor(), down = size.height.floor();
    for (var y = 0; y < down; y++) {
      for (var x = y % 2; x < across; x += 2) {
        cells.addRect(px.snap(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1)));
      }
    }
    px.canvas.drawPath(cells, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_Dither old) => old.ink != ink;
}

/// A completed operation, with an arbitrary art or content slot.
///
/// ```dart
/// RetroDesktopSuccessState(title: 'All done', message: 'Your files are saved.')
/// ```
class RetroDesktopSuccessState extends StatelessWidget {
  /// Creates a [RetroDesktopSuccessState].
  const RetroDesktopSuccessState({
    super.key,
    required this.title,
    this.message,
    this.child,
    this.action,
  });

  /// The heading displayed above the content.
  final String title;

  /// The message displayed to the user.
  final String? message;

  /// The widget displayed inside this part.
  final Widget? child;

  /// An optional action shown beside the content.
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child ??
                Icon(RetroDesktopGlyphs.check, size: 40, color: t.colors.text),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: t.type.head),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: t.type.body,
                ),
              ),
            if (action != null)
              Padding(padding: const EdgeInsets.only(top: 12), child: action!),
          ],
        ),
      ),
    );
  }
}

/// An empty area with caller-owned words, optional artwork and a next action.
///
/// ```dart
/// RetroDesktopEmptyState(title: 'No documents', message: 'Create a document to get started.')
/// ```
class RetroDesktopEmptyState extends StatelessWidget {
  /// Creates a [RetroDesktopEmptyState].
  const RetroDesktopEmptyState({
    super.key,
    required this.title,
    this.message,
    this.art,
    this.action,
  });

  /// The heading displayed above the content.
  final String title;

  /// The message displayed to the user.
  final String? message;

  /// Optional caller-supplied illustration or decoration.
  final Widget? art;

  /// An optional action shown beside the content.
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (art != null)
            ExcludeSemantics(child: art!)
          else
            Icon(
              RetroDesktopGlyphs.fileText,
              size: 40,
              color: t.colors.textSecondary,
            ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: t.type.head),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: t.type.body,
              ),
            ),
          if (action != null)
            Padding(padding: const EdgeInsets.only(top: 16), child: action!),
        ],
      ),
    );
  }
}
