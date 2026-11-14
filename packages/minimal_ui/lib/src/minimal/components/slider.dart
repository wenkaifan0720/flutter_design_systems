import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../internal/field.dart';
import '../internal/styled.dart';
import '../theme.dart';

/// Continuous or stepped adjustment on a thin track: a 4 px hairline-weight
/// track filled with the accent up to a 16 px ringed thumb, under a label
/// line that prints the value in mono. Use a [MinimalNumberField] when the
/// exact
/// small integer matters.
///
/// Tap anywhere on the track or drag the thumb; under the keyboard the arrow
/// keys step it (a tenth of the range, or one division), Home and End jump
/// to the ends, and the thumb wears the 2 px focus ring. [divisions] snaps
/// the value and ticks the track (up to 20 ticks). [format] prints a value's
/// figure (`20`, `70%`) and [unit] the word that follows it (`pages`): the
/// figure in mono, the word in Geist, and a screen reader hears both
/// (`20 pages`) for the current value AND for the one a step will reach.
/// With a [unit] and neither [format] nor [valueLabel] the figure is the
/// value rounded. A fixed
/// [valueLabel] can only name the current value, so prefer [format]; with
/// none of the three, the value prints nothing and announces as a
/// percentage. A null [onChanged] disables it. The touch strip is 44 tall
/// whatever the track paints.
///
/// [style] dresses one slider, `components.slider` every one, resolved with
/// [WidgetState.pressed], [WidgetState.focused] and [WidgetState.disabled]:
/// fill (the track up to the thumb, and the thumb's ring), edge (the track
/// beyond it), foreground (the thumb's face), overlay (the halo while
/// held) and shape (the track's outline; a capsule unset). The thumb is a
/// disc whatever `shapes` says; `t.focusWidth` is its focus ring.
///
/// ```dart
/// MinimalSlider(label: 'Daily reading goal', value: pages, min: 10, max: 50, divisions: 8, unit: 'pages', onChanged: setPages)
/// ```
class MinimalSlider extends StatefulWidget {
  /// A slider setting [value].
  const MinimalSlider({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.valueLabel,
    this.format,
    this.unit,
    this.leadingIcon,
    this.trailingIcon,
    this.showLabel = true,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : assert(min < max),
       assert(divisions == null || divisions > 0),
       assert(value >= min && value <= max);

  /// What the slider sets: printed over the track unless [showLabel] is
  /// false, and always announced.
  final String label;

  /// Whether the label prints over the track.
  final bool showLabel;

  /// The value it shows.
  final double value;

  /// Null disables the slider.
  final ValueChanged<double>? onChanged;

  /// The value when a drag or a key press settles.
  final ValueChanged<double>? onChangeEnd;

  /// The least value.
  final double min;

  /// The greatest value.
  final double max;

  /// How many steps the track has; null for any value.
  final int? divisions;

  /// The current value's figure (`10`, `70%`), printed in mono, [unit]
  /// after it. Ignored when [format] is given.
  final String? valueLabel;

  /// How any value's figure prints (`(v) => '${(v * 100).round()}%'`), in
  /// mono on the line and in the same units to a screen reader, including
  /// the value an increase or decrease will reach. Figures and symbols
  /// only: a word goes in [unit].
  final String Function(double value)? format;

  /// The word after the figure (`pages`, `min`), printed in the body face
  /// and announced with every value.
  final String? unit;

  /// Glyphs at the track's ends (a quiet speaker, a loud one).
  final IconData? leadingIcon;

  /// A glyph after the track.
  final IconData? trailingIcon;

  /// This slider's style, over `components.slider`.
  final MinimalStyle? style;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  State<MinimalSlider> createState() => _MinimalSliderState();
}

const double _thumb = 16;
const double _track = 4;
const double _strip = MinimalLayout.minHitTarget;

/// A division tick: a dot that reads on the 4 px track in every preset.
const double _tickRadius = 1.5;

class _MinimalSliderState extends State<MinimalSlider> {
  bool _down = false;
  bool _focus = false;

  /// The value while a gesture holds the thumb.
  double? _drag;

  double get _span => widget.max - widget.min;

  double _quantize(double v) {
    var f = ((v - widget.min) / _span).clamp(0.0, 1.0);
    final divisions = widget.divisions;
    if (divisions != null) f = (f * divisions).round() / divisions;
    return widget.min + f * _span;
  }

  double get _step => _span / (widget.divisions ?? 10);

  void _change(double v) {
    final next = _quantize(v);
    if (next == (_drag ?? widget.value)) return;
    if (widget.divisions != null) HapticFeedback.selectionClick();
    setState(() => _drag = next);
    widget.onChanged?.call(next);
  }

  void _end() {
    final v = _drag ?? widget.value;
    setState(() {
      _down = false;
      _drag = null;
    });
    widget.onChangeEnd?.call(v);
  }

  void _cancel() => setState(() {
    _down = false;
    _drag = null;
  });

  /// A keyboard or assistive step: changes and settles at once.
  void _adjust(double delta) {
    final next = _quantize(widget.value + delta);
    if (next == widget.value) return;
    widget.onChanged?.call(next);
    widget.onChangeEnd?.call(next);
  }

  String _percent(double v) => '${((v - widget.min) / _span * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final enabled = widget.onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final v = _drag ?? widget.value;
    final f = ((v - widget.min) / _span).clamp(0.0, 1.0);
    final unit = widget.unit;
    final so = MinimalStyleOf([
      widget.style,
      t.components.slider,
    ], minimalStates(enabled: enabled, pressed: _down, focused: _focus));
    // A unit with no figure of the caller's prints the value rounded.
    final format =
        widget.format ??
        (unit != null && widget.valueLabel == null
            ? (double at) => '${at.round()}'
            : null);
    final valueLabel = format != null ? format(v) : widget.valueLabel;
    // What a screen reader hears for a value, in the line's units. A fixed
    // valueLabel names only the current value, so a step ahead repeats it
    // rather than switch units mid-announcement.
    String spoken(double at) {
      final figure = format?.call(at) ?? widget.valueLabel;
      if (figure == null) return _percent(at);
      return unit == null ? figure : '$figure $unit';
    }

    final track = LayoutBuilder(
      builder: (context, c) {
        final travel = (c.maxWidth - _thumb).clamp(1.0, double.infinity);
        double at(double x) {
          final along = ((x - _thumb / 2) / travel).clamp(0.0, 1.0);
          return widget.min + (rtl ? 1 - along : along) * _span;
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled
              ? (d) {
                  setState(() => _down = true);
                  _change(at(d.localPosition.dx));
                }
              : null,
          onTapUp: enabled ? (_) => _end() : null,
          onTapCancel: _cancel,
          onHorizontalDragStart: enabled
              ? (d) {
                  setState(() => _down = true);
                  _change(at(d.localPosition.dx));
                }
              : null,
          onHorizontalDragUpdate: enabled
              ? (d) => _change(at(d.localPosition.dx))
              : null,
          onHorizontalDragEnd: enabled ? (_) => _end() : null,
          onHorizontalDragCancel: _cancel,
          child: CustomPaint(
            size: Size(c.maxWidth, _strip),
            painter: _TrackPainter(
              fraction: f,
              rtl: rtl,
              divisions: widget.divisions,
              track: so.edge ?? t.border,
              fill: so.fill ?? t.primary,
              tick: t.textTertiary,
              thumb: so.foreground ?? t.card,
              halo: _down
                  ? so.overlay ?? t.primary.withValues(alpha: 0.16)
                  : null,
              ring: _focus ? t.ring : null,
              ringWidth: t.focusWidth,
              slot: so.shape ?? t.shapes.pill,
            ),
          ),
        );
      },
    );

    final leading = widget.leadingIcon;
    final trailing = widget.trailingIcon;
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showLabel)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: t.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (valueLabel != null) ...[
                const MinimalGap(MinimalSpacing.s8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: valueLabel,
                        style: t.monoValue.c(t.mutedForeground),
                      ),
                      if (unit != null)
                        TextSpan(
                          text: ' $unit',
                          style: t.body.c(t.mutedForeground),
                        ),
                    ],
                  ),
                  maxLines: 1,
                ),
              ],
            ],
          ),
        SizedBox(
          height: _strip,
          child: Row(
            children: [
              if (leading != null) ...[
                MinimalIcon(leading, size: MinimalIconSize.i16),
                const MinimalGap(MinimalSpacing.s12),
              ],
              Expanded(child: track),
              if (trailing != null) ...[
                const MinimalGap(MinimalSpacing.s12),
                MinimalIcon(trailing, size: MinimalIconSize.i16),
              ],
            ],
          ),
        ),
      ],
    );

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: enabled,
      onShowFocusHighlight: (on) => setState(() => _focus = on),
      // A slider drags: the open hand, closed while it holds the thumb.
      mouseCursor: !enabled
          ? SystemMouseCursors.basic
          : _down
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowRight): _Step(_Key.right),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _Step(_Key.left),
        SingleActivator(LogicalKeyboardKey.arrowUp): _Step(_Key.up),
        SingleActivator(LogicalKeyboardKey.arrowDown): _Step(_Key.down),
        SingleActivator(LogicalKeyboardKey.home): _Step(_Key.home),
        SingleActivator(LogicalKeyboardKey.end): _Step(_Key.end),
      },
      actions: <Type, Action<Intent>>{
        _Step: CallbackAction<_Step>(
          onInvoke: (intent) {
            if (!enabled) return null;
            switch (intent.key) {
              case _Key.right:
                _adjust(rtl ? -_step : _step);
              case _Key.left:
                _adjust(rtl ? _step : -_step);
              case _Key.up:
                _adjust(_step);
              case _Key.down:
                _adjust(-_step);
              case _Key.home:
                _adjust(widget.min - widget.value);
              case _Key.end:
                _adjust(widget.max - widget.value);
            }
            return null;
          },
        ),
      },
      child: Semantics(
        container: true,
        slider: true,
        enabled: enabled,
        label: widget.label,
        // The reader announces the value a step reaches BEFORE the parent
        // rebuilds, so it must be in the same units as the value itself.
        value: spoken(v),
        increasedValue: spoken(_quantize(v + _step)),
        decreasedValue: spoken(_quantize(v - _step)),
        onIncrease: enabled && v < widget.max ? () => _adjust(_step) : null,
        onDecrease: enabled && v > widget.min ? () => _adjust(-_step) : null,
        child: ExcludeSemantics(
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.45,
            duration: MinimalMotion.fast,
            child: body,
          ),
        ),
      ),
    );
  }
}

enum _Key { right, left, up, down, home, end }

class _Step extends Intent {
  const _Step(this.key);

  final _Key key;
}

/// The track, its fill, the division ticks and the thumb, in one pass.
class _TrackPainter extends CustomPainter {
  const _TrackPainter({
    required this.fraction,
    required this.rtl,
    required this.divisions,
    required this.track,
    required this.fill,
    required this.tick,
    required this.thumb,
    required this.halo,
    required this.ring,
    required this.ringWidth,
    required this.slot,
  });

  final double fraction;
  final bool rtl;
  final int? divisions;
  final Color track;
  final Color fill;
  final Color tick;
  final Color thumb;

  /// The pressed halo around the thumb, while a finger holds it.
  final Color? halo;

  /// The keyboard focus ring around the thumb.
  final Color? ring;

  /// The ring's width: `t.focusWidth`.
  final double ringWidth;

  /// The track's outline; null, a capsule.
  final OutlinedBorder? slot;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final travel = size.width - _thumb;
    double x(double f) => _thumb / 2 + (rtl ? 1 - f : f) * travel;
    final cx = x(fraction);
    const r = Radius.circular(_track / 2);
    void bar(double left, double right, Color colour) {
      final paint = Paint()..color = colour;
      final shape = slot;
      if (shape == null) {
        canvas.drawRRect(
          RRect.fromLTRBR(left, cy - _track / 2, right, cy + _track / 2, r),
          paint,
        );
      } else {
        canvas.drawPath(
          shape.getOuterPath(
            Rect.fromLTRB(left, cy - _track / 2, right, cy + _track / 2),
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          ),
          paint,
        );
      }
    }

    bar(0, size.width, track);
    bar(rtl ? cx : 0.0, rtl ? size.width : cx, fill);

    final n = divisions;
    if (n != null && n <= 20) {
      for (var i = 1; i < n; i++) {
        final f = i / n;
        // The fill already says how far the value reaches: a tick on it
        // would only speckle the accent, so ticks mark the rest alone.
        if (f <= fraction) continue;
        canvas.drawCircle(Offset(x(f), cy), _tickRadius, Paint()..color = tick);
      }
    }

    final centre = Offset(cx, cy);
    if (halo != null) {
      canvas.drawCircle(centre, _thumb / 2 + 4, Paint()..color = halo!);
    }
    canvas.drawCircle(centre, _thumb / 2, Paint()..color = thumb);
    canvas.drawCircle(
      centre,
      _thumb / 2 - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = fill,
    );
    if (ring != null) {
      canvas.drawCircle(
        centre,
        _thumb / 2 + 2 + ringWidth / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringWidth
          ..color = ring!,
      );
    }
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.fraction != fraction ||
      old.rtl != rtl ||
      old.divisions != divisions ||
      old.track != track ||
      old.fill != fill ||
      old.tick != tick ||
      old.thumb != thumb ||
      old.halo != halo ||
      old.ring != ring ||
      old.ringWidth != ringWidth ||
      old.slot != slot;
}
