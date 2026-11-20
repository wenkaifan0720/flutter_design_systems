/// Keycap's sliders and dials: [KeycapSlider] and [KeycapRangeSlider] (a
/// small cap riding in a slot cut into the case), [KeycapRating] (stars
/// printed on the case) and [KeycapWheelPicker] (columns turning in a
/// well, the chosen row on a plate across them).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'cap.dart';
import 'internal/spring_value.dart';
import 'theme.dart';

// The ui_core types these parts' APIs take, through the look's barrel.
export 'package:ui_core/ui_core.dart' show DesignRangeValues;
export 'package:ui_core/ui_core.dart' show DesignWheelColumn;

/// The width a slider's cap takes to a finger.
const double _reach = 44;

/// A slider cap's size: a small key, taller than wide.
const Size _capSize = Size(24, 28);

/// The slot's height.
const double _slot = 8;

String _plain(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

/// The slot a slider's cap rides in: a groove cut into the case, the
/// stretch from [start] to [end] (fractions from the start edge) lit by a
/// bar of accent plastic lying in it, with [ticks] notches.
class _SlotPainter extends CustomPainter {
  _SlotPainter({
    required this.colors,
    required this.start,
    required this.end,
    required this.enabled,
    required this.rtl,
    required this.ticks,
    required this.fill,
  });

  final KeycapColors colors;
  final double start;
  final double end;
  final bool enabled;
  final bool rtl;
  final int ticks;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final c = colors;
    final y = size.height / 2;
    final slot = Rect.fromLTWH(0, y - _slot / 2, size.width, _slot);
    const r = Radius.circular(_slot / 2);
    final groove = RRect.fromRectAndRadius(slot, r);
    canvas.drawRRect(
      groove,
      Paint()..color = enabled ? c.well : Color.lerp(c.well, c.ground, 0.6)!,
    );
    // The plate's thickness along the groove's top inside edge.
    canvas
      ..save()
      ..clipRRect(groove)
      ..drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRRect(groove)
          ..addRRect(groove.shift(const Offset(0, KeycapMetrics.plateDepth))),
        Paint()..color = c.wellShade,
      )
      ..restore();
    // The lip along its bottom edge.
    canvas.drawLine(
      Offset(slot.left + _slot / 2, slot.bottom + 0.5),
      Offset(slot.right - _slot / 2, slot.bottom + 0.5),
      Paint()
        ..color = c.wellLip
        ..strokeWidth = 1,
    );
    var a = start * size.width;
    var b = end * size.width;
    if (rtl) (a, b) = (size.width - b, size.width - a);
    if (b - a > 0.5) {
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTRB(a, slot.top, b, slot.bottom),
        r,
      );
      canvas.drawRRect(
        bar,
        Paint()..color = enabled ? fill : Color.lerp(fill, c.ground, 0.6)!,
      );
    }
    if (ticks > 1) {
      final tick = Paint()
        ..color = c.inkMuted.withValues(alpha: enabled ? 0.55 : 0.3)
        ..strokeWidth = 1;
      for (var i = 0; i <= ticks; i++) {
        final x = (_slot / 2) + (size.width - _slot) * i / ticks;
        canvas.drawLine(
          Offset(x, slot.bottom + 4),
          Offset(x, slot.bottom + 7),
          tick,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SlotPainter old) =>
      old.start != start ||
      old.end != end ||
      old.enabled != enabled ||
      old.rtl != rtl ||
      old.ticks != ticks ||
      old.fill != fill ||
      old.colors != colors;
}

/// The small cap riding a slider's slot: down while it is held.
class _Cap extends StatelessWidget {
  const _Cap({required this.states, required this.held});

  final Set<WidgetState> states;
  final bool held;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final face = keycapKeyFace(theme, KeycapKind.alpha, {
      ...states,
      if (held) WidgetState.pressed,
    }, radius: 6);
    return SizedBox.fromSize(
      size: _capSize,
      child: AnimatedKeycapCap(
        face: face,
        walls: KeycapMetrics.walls(_capSize.height),
        child: Center(
          child: SizedBox(
            width: 2,
            height: 10,
            child: ColoredBox(color: face.legend.withValues(alpha: 0.7)),
          ),
        ),
      ),
    );
  }
}

/// A slider: a small key riding in a slot cut into the case, the slot lit
/// by a bar of accent plastic up to it. Drag the key, or tap the slot to
/// send it there; the arrows step it (by [divisions], else a hundredth).
/// With [divisions] at most 20 the slot is notched. Built on ui_core's
/// `DesignValueHandle`.
///
/// ```dart
/// KeycapSlider(value: size, min: 12, max: 24, divisions: 6, semanticLabel: 'Text size', onChanged: (v) => setState(() => size = v))
/// ```
class KeycapSlider extends StatefulWidget {
  /// A slider at [value].
  const KeycapSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.semanticLabel,
    this.valueText,
    this.onChangeStart,
    this.onChangeEnd,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(min < max, 'min is less than max');

  /// Where the key is.
  final double value;

  /// Called as it moves; null turns the slider off.
  final ValueChanged<double>? onChanged;

  /// The least value.
  final double min;

  /// The most.
  final double max;

  /// How many steps the slot has; smooth when null.
  final int? divisions;

  /// Its name, for a screen reader.
  final String? semanticLabel;

  /// The value in words, for a screen reader ("16 pt").
  final String Function(double value)? valueText;

  /// Called as a drag starts.
  final ValueChanged<double>? onChangeStart;

  /// Called as it ends.
  final ValueChanged<double>? onChangeEnd;

  /// The key's focus node.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// Overrides, over [KeycapThemeData.sliderStyle]: [DesignStyle.fill] the
  /// bar's plastic.
  final KeycapStyle? style;

  @override
  State<KeycapSlider> createState() => _KeycapSliderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(DoubleProperty('min', min))
      ..add(DoubleProperty('max', max))
      ..add(IntProperty('divisions', divisions, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _KeycapSliderState extends State<KeycapSlider> {
  bool _dragging = false;

  double _snap(double v) {
    final d = widget.divisions;
    final clamped = v.clamp(widget.min, widget.max).toDouble();
    if (d == null) return clamped;
    final step = (widget.max - widget.min) / d;
    return widget.min + ((clamped - widget.min) / step).round() * step;
  }

  double _at(double dx, double width, bool rtl) {
    final usable = width - _reach;
    var f = usable <= 0 ? 0.0 : (dx - _reach / 2) / usable;
    f = f.clamp(0.0, 1.0);
    if (rtl) f = 1 - f;
    return _snap(widget.min + f * (widget.max - widget.min));
  }

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([widget.style, theme.sliderStyle], const {});
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final enabled = widget.onChanged != null;
    final span = widget.max - widget.min;
    final fraction = ((widget.value - widget.min) / span).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth.isFinite ? box.maxWidth : 240.0;
        void drag(double dx) => widget.onChanged?.call(_at(dx, width, rtl));
        return MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The key's handle is the slider to a screen reader.
            excludeFromSemantics: true,
            dragStartBehavior: DragStartBehavior.down,
            onTapDown: enabled ? (d) => drag(d.localPosition.dx) : null,
            onHorizontalDragStart: enabled
                ? (d) {
                    setState(() => _dragging = true);
                    widget.onChangeStart?.call(widget.value);
                    drag(d.localPosition.dx);
                  }
                : null,
            onHorizontalDragUpdate: enabled
                ? (d) => drag(d.localPosition.dx)
                : null,
            onHorizontalDragEnd: enabled
                ? (_) {
                    setState(() => _dragging = false);
                    widget.onChangeEnd?.call(widget.value);
                  }
                : null,
            child: SizedBox(
              width: width,
              height: theme.controlHeight,
              child: KeycapSpringValue(
                value: fraction,
                spring: _dragging ? KeycapMotion.press : KeycapMotion.release,
                builder: (context, f, _) {
                  final x = _reach / 2 + (rtl ? 1 - f : f) * (width - _reach);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: _reach / 2 - _capSize.width / 2,
                        right: _reach / 2 - _capSize.width / 2,
                        top: 0,
                        bottom: 0,
                        child: CustomPaint(
                          painter: _SlotPainter(
                            colors: c,
                            start: 0,
                            end: f,
                            enabled: enabled,
                            rtl: rtl,
                            fill: layered.fill ?? c.accent.top,
                            ticks:
                                widget.divisions != null &&
                                    widget.divisions! <= 20
                                ? widget.divisions!
                                : 0,
                          ),
                        ),
                      ),
                      Positioned(
                        left: x - _reach / 2,
                        top: 0,
                        width: _reach,
                        height: theme.controlHeight,
                        child: DesignValueHandle(
                          value: widget.value
                              .clamp(widget.min, widget.max)
                              .toDouble(),
                          onChanged: widget.onChanged == null
                              ? null
                              : (v) => widget.onChanged!(_snap(v)),
                          min: widget.min,
                          max: widget.max,
                          divisions: widget.divisions,
                          step: widget.divisions == null ? span / 100 : null,
                          dragging: _dragging,
                          semanticLabel: widget.semanticLabel,
                          semanticFormatterCallback: widget.valueText ?? _plain,
                          focusNode: widget.focusNode,
                          autofocus: widget.autofocus,
                          minimumSize: Size(_reach, theme.controlHeight),
                          builder: (context, states) => Center(
                            child: _Cap(
                              states: states,
                              held:
                                  _dragging ||
                                  states.contains(WidgetState.pressed),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A range: two small keys riding one slot, the stretch between them lit
/// by a bar of accent plastic. Each key steps on its own; they keep
/// [minGap] apart. Built on ui_core's `DesignRangeSlider`.
///
/// ```dart
/// KeycapRangeSlider(values: const DesignRangeValues(200, 800), min: 0, max: 1000, onChanged: (v) => setState(() => words = v))
/// ```
class KeycapRangeSlider extends StatelessWidget {
  /// A range slider over [values].
  const KeycapRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.minGap = 0,
    this.startLabel,
    this.endLabel,
    this.semanticFormatterCallback,
    this.onChangeStart,
    this.onChangeEnd,
    this.style,
  });

  /// The range.
  final DesignRangeValues values;

  /// Called as it changes; null turns it off.
  final ValueChanged<DesignRangeValues>? onChanged;

  /// The least value.
  final double min;

  /// The most.
  final double max;

  /// How many steps the slot has; smooth when null.
  final int? divisions;

  /// The least room between the keys.
  final double minGap;

  /// The lower key's name, for a screen reader.
  final String? startLabel;

  /// The upper key's.
  final String? endLabel;

  /// A value in words, for a screen reader.
  final String Function(double value)? semanticFormatterCallback;

  /// Called as a drag starts.
  final ValueChanged<DesignRangeValues>? onChangeStart;

  /// Called as it ends.
  final ValueChanged<DesignRangeValues>? onChangeEnd;

  /// Overrides, over [KeycapThemeData.sliderStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.sliderStyle], const {});
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      height: theme.controlHeight,
      child: DesignRangeSlider(
        values: values,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        minGap: minGap,
        startLabel: startLabel,
        endLabel: endLabel,
        semanticFormatterCallback: semanticFormatterCallback ?? _plain,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
        thumbSize: Size(_reach, theme.controlHeight),
        trackBuilder: (context, track) => SizedBox(
          height: theme.controlHeight,
          child: CustomPaint(
            painter: _SlotPainter(
              colors: c,
              start: track.start,
              end: track.end,
              enabled: track.enabled,
              rtl: rtl,
              fill: layered.fill ?? c.accent.top,
              ticks: divisions != null && divisions! <= 20 ? divisions! : 0,
            ),
          ),
        ),
        thumbBuilder: (context, index, states) => Center(
          child: _Cap(
            states: states,
            held:
                states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.dragged),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('start', values.start))
      ..add(DoubleProperty('end', values.end))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

/// A rating: stars printed on the case, the chosen ones filled in the
/// accent's ink, the rest outlined. A tap sets the star tapped; a drag
/// sweeps; the arrows step it; a pointer over them previews, in a lighter
/// ink, what a tap would set. [readOnly] shows a rating that cannot be
/// changed. Built on ui_core's `DesignRating`.
///
/// ```dart
/// KeycapRating(value: 4, onChanged: (v) => setState(() => stars = v), semanticLabel: 'Rate this template')
/// ```
class KeycapRating extends StatelessWidget {
  /// A rating at [value].
  const KeycapRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.itemCount = 5,
    this.allowHalf = false,
    this.readOnly = false,
    this.size = 28,
    this.semanticLabel,
    this.style,
  });

  /// How many stars are filled.
  final double value;

  /// Called with the new value; null turns it off.
  final ValueChanged<double>? onChanged;

  /// How many stars.
  final int itemCount;

  /// Whether a half star can be set.
  final bool allowHalf;

  /// Whether it only shows.
  final bool readOnly;

  /// A star's size.
  final double size;

  /// Its name, for a screen reader.
  final String? semanticLabel;

  /// Overrides, over [KeycapThemeData.sliderStyle]: [DesignStyle.fill] the
  /// filled stars' ink.
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.sliderStyle], const {});
    final on = layered.fill ?? c.accentInk;
    return DesignRating(
      value: value,
      onChanged: onChanged,
      itemCount: itemCount,
      allowHalf: allowHalf,
      readOnly: readOnly,
      semanticLabel: semanticLabel,
      layoutBuilder: (context, items) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const SizedBox(width: KeycapSpacing.tight),
            item,
          ],
        ],
      ),
      itemBuilder: (context, d) {
        final off = d.states.contains(WidgetState.disabled);
        final ink = off
            ? c.inkDisabled
            : d.isPreview
            ? Color.lerp(on, c.ground, 0.4)!
            : on;
        final empty = off ? c.inkDisabled : c.inkMuted;
        final focused = d.states.contains(WidgetState.focused);
        final star = SizedBox.square(
          dimension: size,
          child: Stack(
            children: [
              Icon(LucideIcons.star, size: size, color: empty),
              if (d.fill > 0)
                ClipRect(
                  clipper: _Part(d.fill, Directionality.of(context)),
                  child: _FilledStar(size: size, color: ink),
                ),
            ],
          ),
        );
        return Padding(
          padding: const EdgeInsets.all(KeycapSpacing.hairline),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KeycapMetrics.smallKeyRadius),
              border: Border.all(
                color: focused ? c.focus : c.focus.withValues(alpha: 0),
                width: KeycapMetrics.focusWidth,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(KeycapSpacing.tight),
              child: star,
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(IntProperty('itemCount', itemCount));
  }
}

class _FilledStar extends StatelessWidget {
  const _FilledStar({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      CustomPaint(size: Size.square(size), painter: _StarFill(color)),
      Icon(LucideIcons.star, size: size, color: color),
    ],
  );
}

class _StarFill extends CustomPainter {
  _StarFill(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Lucide's star, on its 24 grid, filled.
    final s = size.width / 24;
    final p = Path()
      ..moveTo(12 * s, 2.5 * s)
      ..lineTo(14.9 * s, 8.6 * s)
      ..lineTo(21.5 * s, 9.4 * s)
      ..lineTo(16.6 * s, 14 * s)
      ..lineTo(17.9 * s, 20.6 * s)
      ..lineTo(12 * s, 17.3 * s)
      ..lineTo(6.1 * s, 20.6 * s)
      ..lineTo(7.4 * s, 14 * s)
      ..lineTo(2.5 * s, 9.4 * s)
      ..lineTo(9.1 * s, 8.6 * s)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarFill old) => old.color != color;
}

class _Part extends CustomClipper<Rect> {
  _Part(this.fill, this.direction);

  final double fill;
  final TextDirection direction;

  @override
  Rect getClip(Size size) => direction == TextDirection.rtl
      ? Rect.fromLTRB(size.width * (1 - fill), 0, size.width, size.height)
      : Rect.fromLTRB(0, 0, size.width * fill, size.height);

  @override
  bool shouldReclip(_Part old) =>
      old.fill != fill || old.direction != direction;
}

/// Columns of choices turning in a well (an hour and its minutes, a day of
/// a month), the chosen row on a plate of modifier plastic across them. A
/// fling settles on a row; Up and Down step; each column is one tab stop.
/// Built on ui_core's `DesignWheelPicker`.
///
/// ```dart
/// KeycapWheelPicker(columns: (s) => [DesignWheelColumn(itemCount: 24, itemLabel: (i) => '$i'.padLeft(2, '0'), semanticLabel: 'Hour', looping: true)], selection: [hour], onChanged: (s) => setState(() => hour = s.first))
/// ```
class KeycapWheelPicker extends StatelessWidget {
  /// A wheel picker.
  const KeycapWheelPicker({
    super.key,
    required this.columns,
    required this.selection,
    required this.onChanged,
    this.visibleItemCount = 5,
    this.semanticLabel,
    this.separator,
    this.separatedColumns,
  });

  /// The columns for a selection.
  final List<DesignWheelColumn> Function(List<int> selection) columns;

  /// The row chosen in each column.
  final List<int> selection;

  /// Called with the whole selection; null turns it off.
  final ValueChanged<List<int>>? onChanged;

  /// How many rows show.
  final int visibleItemCount;

  /// Its name, for a screen reader.
  final String? semanticLabel;

  /// Printed between the columns (":" between hours and minutes).
  final String? separator;

  /// How many of the first columns [separator] joins; every column when
  /// null. 2 joins hours and minutes and leaves a day period's column
  /// apart, a gap before it.
  final int? separatedColumns;

  /// A row's height.
  static const double rowHeight = 40;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final plate = Color.lerp(
      c.well,
      c.modifier.top,
      c.brightness == Brightness.light ? 0.45 : 0.9,
    )!;
    // A row grows with its words; the wheel shows as many rows.
    final row = KeycapMetrics.grown(
      context,
      rowHeight,
      theme.textTheme.figure.copyWith(fontSize: 18),
    );
    final height = row * visibleItemCount;
    return SizedBox(
      height: height + 2 * KeycapSpacing.tight,
      child: KeycapWell(
        padding: const EdgeInsets.all(KeycapSpacing.tight),
        child: Stack(
          children: [
            // The plate across the chosen row, concentric with the well.
            Positioned(
              left: 0,
              right: 0,
              top: (height - row) / 2,
              height: row,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: plate,
                  borderRadius: BorderRadius.circular(
                    KeycapMetrics.wellRadius - KeycapSpacing.tight,
                  ),
                ),
              ),
            ),
            DesignWheelPicker(
              columns: columns,
              selection: selection,
              onChanged: onChanged,
              itemExtent: row,
              visibleItemCount: visibleItemCount,
              semanticLabel: semanticLabel,
              diameterRatio: 1.6,
              squeeze: 1.1,
              layoutBuilder: separator == null
                  ? null
                  : (context, cols) => Row(
                      children: [
                        for (final (i, col) in cols.indexed) ...[
                          if (i > 0 &&
                              separatedColumns != null &&
                              i >= separatedColumns!)
                            const SizedBox(width: KeycapSpacing.small)
                          else if (i > 0)
                            ExcludeSemantics(
                              child: Text(
                                separator!,
                                style: theme.textTheme.figure.copyWith(
                                  fontSize: 18,
                                  color: c.ink,
                                ),
                              ),
                            ),
                          Expanded(child: col),
                        ],
                      ],
                    ),
              columnBuilder: (context, d, wheel) {
                final focused = d.states.contains(WidgetState.focused);
                return DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      KeycapMetrics.wellRadius - KeycapSpacing.tight,
                    ),
                    border: Border.all(
                      color: focused ? c.focus : c.focus.withValues(alpha: 0),
                      width: KeycapMetrics.focusWidth,
                    ),
                  ),
                  child: wheel,
                );
              },
              itemBuilder: (context, d) => Center(
                child: Text(
                  d.label,
                  maxLines: 1,
                  style: theme.textTheme.figure.copyWith(
                    fontSize: 18,
                    fontWeight: d.selected ? FontWeight.w600 : FontWeight.w400,
                    color: !d.enabled
                        ? c.inkDisabled
                        : d.selected
                        ? c.ink
                        : c.inkMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<int>('selection', selection));
  }
}
