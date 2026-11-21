/// Clay's sliding and rating choices: a ball rolled along a groove (a
/// slider, or two for a range), stars pressed into the clay or raised out of
/// it, and the tray files are chosen into.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'feedback.dart' show ClayProgressBar;
import 'fonts.dart';
import 'internal/entry_parts.dart' show ClayOnFocus;
import 'surface.dart';
import 'theme.dart';

/// The ball a slider rolls: 28 across, in a slot a finger's height.
const double _ball = 28;

/// How tall a slider stands: a finger's height.
const double _slot = 44;

/// The groove's depth across.
const double _groove = 12;

/// A slider's groove, the run up to [end] (from [start]) raised in [fill].
class _Groove extends StatelessWidget {
  const _Groove({
    required this.start,
    required this.end,
    required this.fill,
    required this.enabled,
  });

  final double start;
  final double end;
  final Color fill;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = ClayTheme.of(context).colors;
    return SizedBox(
      height: _groove,
      child: ClaySurface(
        // Halfway to an off control's groove, as the progress bar's: its
        // length reads by day and by night.
        face: ClayFace.well(
          c,
          color: Color.lerp(c.well, c.track, enabled ? 0.45 : 0.2),
          radius: _groove / 2,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final a = (start.clamp(0.0, 1.0) * w);
            final b = (end.clamp(0.0, 1.0) * w);
            if (b - a < 1) return const SizedBox.shrink();
            return Stack(
              children: [
                PositionedDirectional(
                  start: a,
                  width: b - a,
                  top: 0,
                  bottom: 0,
                  child: ClaySurface(
                    face: ClayFace.raised(
                      c,
                      color: enabled ? fill : c.inkDisabled,
                      radius: _groove / 2,
                    ).copyWith(shadowOpacity: 0),
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

/// A slider's ball: [ClayColors.knob] raised over the groove, pressed while
/// held, rimmed under focus.
ClayFace _ballFace(
  ClayColors c,
  Set<WidgetState> states, {
  required bool dragging,
  required Color fill,
  Color? ball,
}) {
  if (states.contains(WidgetState.disabled)) {
    return ClayFace.flat(c, color: c.knobDisabled, radius: _ball / 2);
  }
  final colour = ball ?? c.knob;
  return ClayFace.raised(c, color: colour, radius: _ball / 2).copyWith(
    press: dragging || states.contains(WidgetState.pressed) ? 1 : 0,
    lift: states.contains(WidgetState.hovered) && !dragging ? 1 : 0,
    focus: states.contains(WidgetState.focused) ? 1 : 0,
    focusColor: c.focus,
    // Its shadow takes the groove's hue, as the switch's ball does.
    shade: Color.lerp(c.shadeOf(colour), c.shadeOf(fill), 0.5),
  );
}

/// A slider: a white clay ball rolled along a groove, the run behind it
/// raised in coral. Arrows step it; a tap on the groove sets it there.
///
/// ```dart
/// ClaySlider(value: 0.6, onChanged: (value) {}, semanticLabel: 'Volume')
/// ```
class ClaySlider extends StatefulWidget {
  /// A slider at [value], between [min] and [max].
  const ClaySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticLabel,
    this.semanticFormatterCallback,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(min < max);

  /// Where the ball sits.
  final double value;

  /// The new value as the ball moves; null turns the slider off.
  final ValueChanged<double>? onChanged;

  /// The groove's start.
  final double min;

  /// The groove's end.
  final double max;

  /// How many steps it snaps to; null: any value.
  final int? divisions;

  /// A drag begun.
  final ValueChanged<double>? onChangeStart;

  /// A drag ended.
  final ValueChanged<double>? onChangeEnd;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// How a screen reader says the value.
  final String Function(double value)? semanticFormatterCallback;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Whether it takes the focus when it first shows.
  final bool autofocus;

  /// This slider's own style, over [ClayThemeData.sliderStyle]: `fill` the
  /// run, `foreground` the ball.
  final ClayStyle? style;

  @override
  State<ClaySlider> createState() => _ClaySliderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(DoubleProperty('min', min))
      ..add(DoubleProperty('max', max));
  }
}

class _ClaySliderState extends State<ClaySlider> {
  bool _dragging = false;

  double _snap(double v) {
    final clamped = v.clamp(widget.min, widget.max);
    final d = widget.divisions;
    if (d == null || d <= 0) return clamped;
    final unit = (widget.max - widget.min) / d;
    return widget.min + ((clamped - widget.min) / unit).round() * unit;
  }

  double _valueAt(Offset local, double width) {
    final usable = width - _ball;
    var x = ((local.dx - _ball / 2) / usable).clamp(0.0, 1.0);
    if (Directionality.of(context) == TextDirection.rtl) x = 1 - x;
    return _snap(widget.min + x * (widget.max - widget.min));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final enabled = widget.onChanged != null;
    final layered = DesignStyleOf(
      [widget.style, theme.sliderStyle],
      {if (!enabled) WidgetState.disabled},
    );
    final fill = layered.fill ?? c.accent;
    final fraction = ((widget.value - widget.min) / (widget.max - widget.min))
        .clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, box) {
        // A slider spans what holds it, as a bar does.
        final width = box.hasBoundedWidth ? box.maxWidth : 240.0;
        final usable = width - _ball;
        void start(Offset at) {
          setState(() => _dragging = true);
          widget.onChangeStart?.call(widget.value);
          final v = _valueAt(at, width);
          if (v != widget.value) widget.onChanged?.call(v);
        }

        void end() {
          setState(() => _dragging = false);
          widget.onChangeEnd?.call(widget.value);
        }

        return SizedBox(
          width: width,
          height: _slot,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onHorizontalDragStart: enabled
                ? (d) => start(d.localPosition)
                : null,
            onHorizontalDragUpdate: enabled
                ? (d) {
                    final v = _valueAt(d.localPosition, width);
                    if (v != widget.value) widget.onChanged?.call(v);
                  }
                : null,
            onHorizontalDragEnd: enabled ? (_) => end() : null,
            onTapDown: enabled ? (d) => start(d.localPosition) : null,
            onTapUp: enabled ? (_) => end() : null,
            onTapCancel: enabled ? end : null,
            child: MouseRegion(
              cursor: enabled
                  ? (_dragging
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.click)
                  : SystemMouseCursors.basic,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  PositionedDirectional(
                    start: _ball / 2 - _groove / 2,
                    end: _ball / 2 - _groove / 2,
                    top: (_slot - _groove) / 2,
                    child: _Groove(
                      start: 0,
                      end: (fraction * usable + _groove) / (usable + _groove),
                      fill: fill,
                      enabled: enabled,
                    ),
                  ),
                  PositionedDirectional(
                    start: fraction * usable,
                    top: (_slot - _ball) / 2,
                    child: DesignValueHandle(
                      value: widget.value,
                      min: widget.min,
                      max: widget.max,
                      divisions: widget.divisions,
                      onChanged: enabled
                          ? (v) => widget.onChanged!(_snap(v))
                          : null,
                      onChangeStart: widget.onChangeStart,
                      onChangeEnd: widget.onChangeEnd,
                      dragging: _dragging,
                      semanticLabel: widget.semanticLabel,
                      semanticFormatterCallback:
                          widget.semanticFormatterCallback,
                      focusNode: widget.focusNode,
                      autofocus: widget.autofocus,
                      minimumSize: const Size(_ball, _ball),
                      builder: (context, states) => SizedBox.square(
                        dimension: _ball,
                        child: AnimatedClaySurface(
                          face: _ballFace(
                            c,
                            states,
                            dragging: _dragging,
                            fill: fill,
                            ball: layered.foreground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A range's two ends.
typedef ClayRangeValues = RawRangeValues;

/// A range slider: two clay balls on one groove, the run between them
/// raised in coral. They never cross; a press on the groove moves the
/// nearer.
///
/// ```dart
/// ClayRangeSlider(values: const ClayRangeValues(6, 9), min: 5, max: 12, divisions: 7, onChanged: (values) {})
/// ```
class ClayRangeSlider extends StatelessWidget {
  /// A range slider over [values].
  const ClayRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.minGap = 0,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticFormatterCallback,
    this.startLabel,
    this.endLabel,
    this.style,
  });

  /// The range's two ends.
  final ClayRangeValues values;

  /// The new range as a ball moves; null turns the slider off.
  final ValueChanged<ClayRangeValues>? onChanged;

  /// The groove's start.
  final double min;

  /// The groove's end.
  final double max;

  /// How many steps it snaps to; null: any value.
  final int? divisions;

  /// How near the two ends may come.
  final double minGap;

  /// A drag begun.
  final ValueChanged<ClayRangeValues>? onChangeStart;

  /// A drag ended.
  final ValueChanged<ClayRangeValues>? onChangeEnd;

  /// How a screen reader says each end.
  final String Function(double value)? semanticFormatterCallback;

  /// What a screen reader calls the lower ball; null: the words' own.
  final String? startLabel;

  /// What a screen reader calls the upper ball.
  final String? endLabel;

  /// This slider's own style, over [ClayThemeData.sliderStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    final layered = DesignStyleOf(
      [style, theme.sliderStyle],
      {if (!enabled) WidgetState.disabled},
    );
    final fill = layered.fill ?? c.accent;
    return RawRangeSlider(
      values: values,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      minGap: minGap,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
      semanticFormatterCallback: semanticFormatterCallback,
      startLabel: startLabel,
      endLabel: endLabel,
      // A ball's width across, as the single slider's: the balls stop with
      // their edges on the column's, so a range lines up with the fields
      // and sliders above and below it. The track takes every press.
      thumbSize: const Size(_ball, _slot),
      // The track runs between the balls' centres at the ends; the groove
      // reaches half its own height past each, so a ball at an end rests
      // on its rounded end, as the single slider's does.
      trackBuilder: (context, track) => SizedBox(
        height: _groove,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -_groove / 2,
              right: -_groove / 2,
              top: 0,
              bottom: 0,
              child: _Groove(
                start: track.start,
                end: track.end,
                fill: fill,
                enabled: track.enabled,
              ),
            ),
          ],
        ),
      ),
      thumbBuilder: (context, index, states) {
        return Center(
          child: SizedBox.square(
            dimension: _ball,
            child: AnimatedClaySurface(
              face: _ballFace(
                c,
                states,
                dragging: false,
                fill: fill,
                ball: layered.foreground,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A rating: five stars pressed into the clay, those given raised out of
/// it in warm coral. Half stars when [allowHalf]; a pointer over them shows
/// what a tap would give.
///
/// ```dart
/// ClayRating(value: 4, onChanged: (value) {}, semanticLabel: 'How the week felt')
/// ```
class ClayRating extends StatefulWidget {
  /// A rating at [value] of [itemCount].
  const ClayRating({
    super.key,
    required this.value,
    this.onChanged,
    this.itemCount = 5,
    this.allowHalf = false,
    this.readOnly = false,
    this.size = 28,
    this.semanticLabel,
    this.focusNode,
    this.style,
  });

  /// How many stars are given.
  final double value;

  /// A new rating; null turns it off.
  final ValueChanged<double>? onChanged;

  /// How many stars there are.
  final int itemCount;

  /// Whether half a star can be given.
  final bool allowHalf;

  /// Whether it only shows a rating.
  final bool readOnly;

  /// A star's size; each stands in a finger's square.
  final double size;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// This rating's own style, over [ClayThemeData.ratingStyle]: `fill` the
  /// stars given.
  final ClayStyle? style;

  @override
  State<ClayRating> createState() => _ClayRatingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(IntProperty('itemCount', itemCount));
  }
}

class _ClayRatingState extends State<ClayRating> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final enabled = widget.onChanged != null || widget.readOnly;
    final slot = widget.size < 44 ? 44.0 : widget.size;
    return RawRating(
      value: widget.value,
      onChanged: widget.onChanged,
      itemCount: widget.itemCount,
      allowHalf: widget.allowHalf,
      readOnly: widget.readOnly,
      focusNode: _focus,
      semanticLabel:
          widget.semanticLabel ??
          RawWidgetsLocalizations.of(context).ratingLabel,
      layoutBuilder: (context, items) => ClayOnFocus(
        focusNode: _focus,
        // The focus rims the whole row, as one control.
        builder: (context, focused) => AnimatedClaySurface(
          face: ClayFace.flat(c, radius: slot / 2).copyWith(
            color: c.ground.withValues(alpha: 0),
            shadowOpacity: 0,
            lightOpacity: 0,
            shadeOpacity: 0,
            focus: focused && !widget.readOnly ? 1 : 0,
            focusColor: c.focus,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: items),
        ),
      ),
      itemBuilder: (context, item) {
        final layered = DesignStyleOf([
          widget.style,
          theme.ratingStyle,
        ], item.states);
        final fill = enabled ? (layered.fill ?? c.accent) : c.inkDisabled;
        return SizedBox(
          width: widget.readOnly ? widget.size + 4 : slot,
          height: widget.readOnly ? widget.size + 4 : slot,
          child: Center(
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _StarPainter(
                fill: item.fill,
                color: item.isPreview ? Color.lerp(fill, c.clay, 0.35)! : fill,
                shade: c.shadeOf(fill),
                cup: Color.lerp(c.well, c.track, enabled ? 0.55 : 0.25)!,
                light: c.light,
                rtl: Directionality.of(context) == TextDirection.rtl,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A five-pointed star with soft points: a cup in [cup] where it is not
/// given; [color] raised over it up to [fill], lit from above, its shadow
/// under it.
class _StarPainter extends CustomPainter {
  _StarPainter({
    required this.fill,
    required this.color,
    required this.shade,
    required this.cup,
    required this.light,
    required this.rtl,
  });

  final double fill;
  final Color color;
  final Color shade;
  final Color cup;
  final Color light;
  final bool rtl;

  Path _star(Size size) {
    final r = size.shortestSide / 2;
    final centre = Offset(size.width / 2, size.height / 2 + r * 0.06);
    const inner = 0.48;
    final points = <Offset>[];
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final d = i.isEven ? r : r * inner;
      points.add(centre + Offset(d * math.cos(angle), d * math.sin(angle)));
    }
    // Round each point by cutting it with a short curve.
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final prev = points[(i + points.length - 1) % points.length];
      final next = points[(i + 1) % points.length];
      final t = i.isEven ? 0.16 : 0.08;
      final a = Offset.lerp(p, prev, t)!;
      final b = Offset.lerp(p, next, t)!;
      if (i == 0) {
        path.moveTo(a.dx, a.dy);
      } else {
        path.lineTo(a.dx, a.dy);
      }
      path.quadraticBezierTo(p.dx, p.dy, b.dx, b.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final star = _star(size);
    // The cup: pressed in, darker at its top lip.
    canvas.drawPath(star, Paint()..color = cup);
    canvas.save();
    canvas.clipPath(star);
    canvas.drawPath(
      star.shift(const Offset(0, 1.5)),
      Paint()
        ..color = shade.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
    final f = fill.clamp(0.0, 1.0);
    if (f <= 0) return;
    canvas.save();
    final w = size.width * f;
    canvas.clipRect(
      rtl
          ? Rect.fromLTWH(size.width - w, 0, w, size.height)
          : Rect.fromLTWH(0, 0, w, size.height),
    );
    // The raised star: its shadow under it, then its clay lit from above.
    canvas.drawPath(
      star.shift(const Offset(0, 1.5)),
      Paint()
        ..color = shade.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    final bounds = star.getBounds();
    canvas.drawPath(
      star,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, light, 0.22)!, color],
        ).createShader(bounds),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.fill != fill ||
      old.color != color ||
      old.cup != cup ||
      old.shade != shade ||
      old.rtl != rtl;
}

/// One file in a [ClayFileDrop]: its name, its size and, while it goes up,
/// how far it has gone.
@immutable
class ClayFile {
  /// A file named [name] of [bytes].
  const ClayFile({required this.name, required this.bytes, this.progress});

  /// Its name.
  final String name;

  /// Its size in bytes.
  final int bytes;

  /// How far its upload has gone, 0 to 1; null once it is up.
  final double? progress;
}

String _size(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// The tray files are chosen into: a broad well with a key that opens the
/// picker, and the files chosen listed under it, each with its progress
/// while it goes up and a key that takes it out.
///
/// ```dart
/// ClayFileDrop(label: 'Photo', hint: 'A picture for this habit, up to 5 MB', onChoose: () {})
/// ```
class ClayFileDrop extends StatelessWidget {
  /// A file tray.
  const ClayFileDrop({
    super.key,
    required this.onChoose,
    this.files = const [],
    this.onRemove,
    this.label,
    this.hint,
    this.chooseLabel = 'Choose files',
    this.style,
  });

  /// Opens the platform's picker; null turns the tray off.
  final VoidCallback? onChoose;

  /// The files chosen.
  final List<ClayFile> files;

  /// Takes a file out; null: files stay.
  final ValueChanged<ClayFile>? onRemove;

  /// The words above the tray.
  final String? label;

  /// What the tray says: what it takes.
  final String? hint;

  /// The key's words.
  final String chooseLabel;

  /// This tray's own style, over [ClayThemeData.fileDropStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final enabled = onChoose != null;
    final layered = DesignStyleOf(
      [style, theme.fileDropStyle],
      {if (!enabled) WidgetState.disabled},
    );
    final words = RawWidgetsLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: ClaySpacing.small),
            child: Text(
              label!,
              style: theme.textTheme.label.copyWith(
                fontSize: 14,
                height: 20 / 14,
                color: enabled ? c.ink : c.inkDisabled,
              ),
            ),
          ),
        ClaySurface(
          face: ClayFace.well(
            c,
            color: layered.fill,
            radius: clayRadiusOf(layered.shape, ClayRadius.large),
          ),
          child: Padding(
            padding: const EdgeInsets.all(ClaySpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.upload,
                  size: 28,
                  color: enabled ? c.inkSecondary : c.inkDisabled,
                ),
                if (hint != null) ...[
                  const SizedBox(height: ClaySpacing.small),
                  Text(
                    hint!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.secondary,
                  ),
                ],
                const SizedBox(height: ClaySpacing.regular),
                ClayButton(
                  chooseLabel,
                  onPressed: onChoose,
                  icon: const Icon(LucideIcons.paperclip),
                ),
              ],
            ),
          ),
        ),
        for (final file in files)
          Padding(
            padding: const EdgeInsets.only(top: ClaySpacing.small),
            child: Semantics(
              container: true,
              child: Row(
                children: [
                  Icon(LucideIcons.file, size: 20, color: c.inkSecondary),
                  const SizedBox(width: ClaySpacing.medium),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DesignCapCenter(
                                capHeightFactor: clayCapHeightFactor,
                                child: Text(
                                  file.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.body,
                                ),
                              ),
                            ),
                            const SizedBox(width: ClaySpacing.small),
                            Text(
                              _size(file.bytes),
                              style: theme.textTheme.secondary,
                            ),
                          ],
                        ),
                        if (file.progress != null) ...[
                          const SizedBox(height: ClaySpacing.tight + 2),
                          ClayProgressBar(
                            value: file.progress!,
                            height: 6,
                            semanticLabel: file.name,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onRemove != null)
                    ClayIconButton.plain(
                      onPressed: () => onRemove!(file),
                      tooltip: '${words.deleteButtonTooltip} ${file.name}',
                      icon: const Icon(LucideIcons.x),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
