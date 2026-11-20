/// Brutal's other ways to choose: [BrutalSlider] and [BrutalRangeSlider]
/// (a ruled track filled with ink, square raised thumbs that press into
/// their shadows while dragged), [BrutalChip] (a ruled cell that goes ink
/// when chosen), [BrutalRating] (cells on shared rules, a star in each) and
/// [BrutalFileDrop] (a box that takes files).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'internal/focus_ink.dart';
import 'surface.dart';
import 'theme.dart';

/// A thumb's side.
const double _thumb = 28;

/// The track's height.
const double _track = 12;

/// The room a thumb's tap takes, and a slider's height: a finger's target.
const double _reach = 48;

/// A slider's width where nothing bounds it (in a row).
const double _rowWidth = 200;

/// A slider's ruled track, ink from [start] to [end] (fractions from the
/// start edge).
class _Track extends StatelessWidget {
  const _Track({
    required this.start,
    required this.end,
    required this.enabled,
    required this.layers,
  });

  final double start;
  final double end;
  final bool enabled;
  final List<BrutalStyle?> layers;

  @override
  Widget build(BuildContext context) {
    final c = BrutalTheme.of(context).colors;
    final layered = DesignStyleOf(layers, {if (!enabled) WidgetState.disabled});
    final ink = layered.foreground ?? (enabled ? c.ink : c.disabled);
    final rule = layered.side?.color ?? layered.edge ?? ink;
    return SizedBox(
      height: _track,
      child: BrutalSurface(
        face: BrutalFace(
          fill: layered.fill ?? c.surface,
          border: rule,
          foreground: ink,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return Stack(
              children: [
                PositionedDirectional(
                  start: w * start,
                  width: w * (end - start).clamp(0.0, 1.0),
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(color: ink),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A slider's thumb in [states]: a square raised face that presses home
/// into its shadow while it is dragged or pressed.
Widget _thumbFace(
  BrutalColors c,
  Set<WidgetState> states,
  bool dragging,
  List<BrutalStyle?> layers,
) {
  final disabled = states.contains(WidgetState.disabled);
  final pressed = dragging || states.contains(WidgetState.pressed);
  final layered = DesignStyleOf(layers, {
    ...states,
    if (dragging) WidgetState.pressed,
  });
  return Center(
    child: SizedBox.square(
      dimension: _thumb,
      child: AnimatedBrutalSurface(
        face: BrutalFace(
          fill: layered.fill ?? c.surface,
          border:
              layered.side?.color ??
              layered.edge ??
              (disabled ? c.disabled : c.ink),
          foreground: c.ink,
          shadow: disabled ? c.ink.withValues(alpha: 0) : c.ink,
          travel: pressed && !disabled ? 1 : 0,
          focus: states.contains(WidgetState.focused)
              ? brutalFocusInk(c, c.ink)
              : c.ink.withValues(alpha: 0),
        ),
      ),
    ),
  );
}

/// One value along a ruled track: the track inks from its start to the
/// thumb, a square raised face that presses into its shadow while dragged.
/// A press on the track moves the thumb there. The arrows step it, Page Up
/// and Down by a tenth, Home and End to its ends.
///
/// A null [onChanged] disables it.
///
/// Reads [style]'s `fill` (the track's and the thumb's ground), `edge` (their
/// rules) and `foreground` (the run of ink) in its states, then
/// [BrutalThemeData.sliderStyle]'s.
///
/// ```dart
/// BrutalSlider(value: volume, semanticLabel: 'Volume', onChanged: (v) => setState(() => volume = v))
/// ```
class BrutalSlider extends StatefulWidget {
  /// A slider at [value].
  const BrutalSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChangeEnd,
    this.semanticLabel,
    this.semanticFormatterCallback,
    this.style,
  });

  /// The value.
  final double value;

  /// Called as it moves; null disables it.
  final ValueChanged<double>? onChanged;

  /// The least value.
  final double min;

  /// The most.
  final double max;

  /// How many steps it snaps to, when it snaps.
  final int? divisions;

  /// Called when a drag ends.
  final ValueChanged<double>? onChangeEnd;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// How a screen reader says a value.
  final String Function(double value)? semanticFormatterCallback;

  /// Its style, over [BrutalThemeData.sliderStyle].
  final BrutalStyle? style;

  @override
  State<BrutalSlider> createState() => _BrutalSliderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(DoubleProperty('min', min))
      ..add(DoubleProperty('max', max))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _BrutalSliderState extends State<BrutalSlider> {
  bool _pressed = false;

  /// The value the drag last set: a drag can end before the parent has
  /// built with it.
  double? _last;

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  void didUpdateWidget(BrutalSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onChanged == null) {
      _pressed = false;
      _last = null;
    }
  }

  double get _fraction => widget.max == widget.min
      ? 0
      : ((widget.value - widget.min) / (widget.max - widget.min)).clamp(
          0.0,
          1.0,
        );

  double _valueAt(double dx, double width, bool rtl) {
    final usable = width - _reach;
    var f = usable <= 0 ? 0.0 : ((dx - _reach / 2) / usable).clamp(0.0, 1.0);
    if (rtl) f = 1 - f;
    final d = widget.divisions;
    if (d != null) f = (f * d).round() / d;
    return widget.min + f * (widget.max - widget.min);
  }

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [widget.style, theme.sliderStyle];
    final enabled = widget.onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.hasBoundedWidth ? box.maxWidth : _rowWidth;
        final usable = width - _reach;
        final left = (rtl ? 1 - _fraction : _fraction) * usable;
        void set(double dx) =>
            widget.onChanged!(_last = _valueAt(dx, width, rtl));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          // A tap moves it there and ends there, as Flutter's own.
          onTapUp: enabled
              ? (d) {
                  set(d.localPosition.dx);
                  widget.onChangeEnd?.call(_last ?? widget.value);
                  _last = null;
                }
              : null,
          onHorizontalDragDown: enabled ? (_) => _setPressed(true) : null,
          onHorizontalDragCancel: enabled ? () => _setPressed(false) : null,
          onHorizontalDragStart: enabled
              ? (d) => set(d.localPosition.dx)
              : null,
          onHorizontalDragUpdate: enabled
              ? (d) => set(d.localPosition.dx)
              : null,
          onHorizontalDragEnd: enabled
              ? (_) {
                  _setPressed(false);
                  widget.onChangeEnd?.call(_last ?? widget.value);
                  _last = null;
                }
              : null,
          // The whole slider is the one control the keyboard and a screen
          // reader find, as Flutter's own; the thumb is its face.
          child: DesignValueHandle(
            value: widget.value.clamp(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            dragging: _pressed,
            minimumSize: Size(width, _reach),
            mouseCursor: enabled ? SystemMouseCursors.click : null,
            semanticLabel: widget.semanticLabel,
            semanticFormatterCallback: widget.semanticFormatterCallback,
            onChanged: widget.onChanged,
            onChangeEnd: widget.onChangeEnd,
            builder: (context, states) => SizedBox(
              height: _reach,
              width: width,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: _reach / 2,
                    right: _reach / 2,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _Track(
                        start: 0,
                        end: _fraction,
                        enabled: enabled,
                        layers: layers,
                      ),
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: 0,
                    width: _reach,
                    height: _reach,
                    child: _thumbFace(c, states, _pressed, layers),
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

/// A span on a [BrutalRangeSlider]'s track: its [start] and [end] values.
///
/// ```dart
/// const BrutalRangeValues(10, 40)
/// ```
@immutable
class BrutalRangeValues {
  /// The span from [start] to [end].
  const BrutalRangeValues(this.start, this.end);

  /// The lower end.
  final double start;

  /// The upper end.
  final double end;

  @override
  bool operator ==(Object other) =>
      other is BrutalRangeValues && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'BrutalRangeValues($start, $end)';
}

/// A span along a ruled track: ink between two square thumbs, each a
/// slider of its own to the keyboard and a screen reader. The thumb moved
/// last stands on top.
///
/// Reads [style] as [BrutalSlider] does, then
/// [BrutalThemeData.sliderStyle].
///
/// ```dart
/// BrutalRangeSlider(values: const BrutalRangeValues(10, 40), min: 0, max: 60, startLabel: 'Lowest price', endLabel: 'Highest price', onChanged: (v) => setState(() => price = v))
/// ```
class BrutalRangeSlider extends StatelessWidget {
  /// A range slider over [values].
  const BrutalRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.startLabel,
    this.endLabel,
    this.semanticFormatterCallback,
    this.style,
  });

  /// The span, as Flutter's `RangeSlider` takes it.
  final BrutalRangeValues values;

  /// Called as either end moves; null disables it.
  final ValueChanged<BrutalRangeValues>? onChanged;

  /// The least value.
  final double min;

  /// The most.
  final double max;

  /// How many steps it snaps to.
  final int? divisions;

  /// What a screen reader calls the lower thumb.
  final String? startLabel;

  /// What a screen reader calls the upper thumb.
  final String? endLabel;

  /// How a screen reader says a value.
  final String Function(double value)? semanticFormatterCallback;

  /// Its style, over [BrutalThemeData.sliderStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.sliderStyle];
    return DesignRangeSlider(
      values: DesignRangeValues(values.start, values.end),
      onChanged: onChanged == null
          ? null
          : (v) => onChanged!(BrutalRangeValues(v.start, v.end)),
      min: min,
      max: max,
      divisions: divisions,
      startLabel: startLabel,
      endLabel: endLabel,
      semanticFormatterCallback: semanticFormatterCallback,
      thumbSize: const Size.square(_reach),
      trackBuilder: (context, track) => _Track(
        start: track.start,
        end: track.end,
        enabled: track.enabled,
        layers: layers,
      ),
      thumbBuilder: (context, index, states) =>
          _thumbFace(c, states, false, layers),
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

/// A choice that stays on: words (and a glyph) in a ruled cell, flat; ink
/// with paper words while [selected]. A press goes ink too. A null
/// [onSelected] greys it. At a larger text size the cell grows with its
/// words, keeping them clear of its rules, as Material's filter chip does.
///
/// Reads [style]'s `fill` (while chosen or pressed), `foreground`, `edge`,
/// `padding`, `minimumSize` (its height), `textStyle` and `iconSize` in its
/// states, chosen among them, then [BrutalThemeData.chipStyle]'s.
///
/// ```dart
/// BrutalChip(label: 'Free', selected: free, onSelected: (on) => setState(() => free = on))
/// ```
class BrutalChip extends StatelessWidget {
  /// A chip reading [label].
  const BrutalChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.style,
  });

  /// The words.
  final String label;

  /// Whether it is on.
  final bool selected;

  /// Called with the new state; null disables it.
  final ValueChanged<bool>? onSelected;

  /// A glyph before the words.
  final IconData? icon;

  /// Its style, over [BrutalThemeData.chipStyle].
  final BrutalStyle? style;

  /// Its height at the reader's own text size; it grows with larger text.
  static const double height = 36;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    return DesignTapTarget(
      child: DesignPressable(
        onPressed: onSelected == null ? null : () => onSelected!(!selected),
        selected: selected,
        toggled: selected,
        semanticLabel: label,
        excludeSemantics: true,
        builder: (context, states, _) {
          final disabled = states.contains(WidgetState.disabled);
          final lit = selected || states.contains(WidgetState.pressed);
          final layered = DesignStyleOf(
            [style, theme.chipStyle],
            {...states, if (selected) WidgetState.selected},
          );
          final words =
              layered.foreground ??
              (disabled
                  ? (selected ? c.surface : c.disabled)
                  : lit
                  ? c.onColor(layered.fill ?? c.ink)
                  : c.ink);
          final least = layered.minimumSize?.height ?? height;
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: least),
            child: AnimatedBrutalSurface(
              stiffness: BrutalMotion.colorStiffness,
              face: BrutalFace(
                fill: lit
                    ? (layered.fill ?? (disabled ? c.disabled : c.ink))
                    : c.surface,
                border:
                    layered.side?.color ??
                    layered.edge ??
                    (disabled ? c.disabled : c.ink),
                foreground: words,
                focus: states.contains(WidgetState.focused)
                    ? brutalFocusInk(
                        c,
                        lit ? (layered.fill ?? c.ink) : c.surface,
                      )
                    : c.ink.withValues(alpha: 0),
              ),
              child: Padding(
                padding:
                    layered.padding(Directionality.of(context)) ??
                    EdgeInsets.symmetric(
                      horizontal: BrutalSpacing.medium,
                      // The words' line (20) centred between the rules: as
                      // tall as [height] at 1x, taller as the words grow.
                      vertical: math.max(
                        0,
                        (least - 20 - 2 * theme.borderWidth) / 2,
                      ),
                    ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: layered.iconSize ?? 16, color: words),
                      const SizedBox(width: BrutalSpacing.small),
                    ],
                    DesignCapCenter(
                      capHeightFactor: BrutalTheme.of(context).capHeightFactor,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: layered
                            .text(
                              theme.textTheme.label.copyWith(
                                fontSize: 14,
                                height: 20 / 14,
                              ),
                            )
                            .copyWith(color: words),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(
        FlagProperty('enabled', value: onSelected != null, ifFalse: 'disabled'),
      );
  }
}

/// A score out of [max]: cells on shared rules in one flat strip, a star in
/// each; the cells up to [value] are ink with a paper star. A null
/// [onChanged] greys it.
///
/// The behaviour is ui_core's ([DesignRating]): a tap sets the cell tapped,
/// a drag sweeps along the strip, and a pointer resting over it inks the
/// cells up to it, the score it would set. It is one tab stop: Right and Up
/// raise the score, Left and Down lower it (mirrored right to left), End
/// fills it, Home or 0 clears it, a digit sets that many. A screen reader
/// hears a slider, "Your rating, 3 of 5", and steps it.
///
/// Reads [style]'s `fill` (the strip's ground at rest, a lit cell's when
/// scored or pressed), `edge` (the rules), `foreground` (a star at rest),
/// `minimumSize` (a cell's side) and `iconSize`, then
/// [BrutalThemeData.ratingStyle]'s.
///
/// ```dart
/// BrutalRating(value: stars, semanticLabel: 'Your rating', onChanged: (v) => setState(() => stars = v))
/// ```
class BrutalRating extends StatelessWidget {
  /// A rating at [value].
  const BrutalRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 5,
    this.semanticLabel,
    this.style,
  });

  /// The score, 0 to [max].
  final int value;

  /// Called with the score set; null disables it.
  final ValueChanged<int>? onChanged;

  /// The most it can be.
  final int max;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its style, over [BrutalThemeData.ratingStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    final layers = [style, theme.ratingStyle];
    final strip = DesignStyleOf(layers, {if (!enabled) WidgetState.disabled});
    final rule =
        strip.side?.color ?? strip.edge ?? (enabled ? c.ink : c.disabled);
    final side = strip.minimumSize?.height ?? 40.0;
    // The strip's states, the same for every cell (the strip is one stop).
    var focused = false;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: DesignRating(
        value: value.toDouble(),
        itemCount: max,
        onChanged: enabled
            ? (to) {
                if (to.round() != value) onChanged!(to.round());
              }
            : null,
        semanticLabel: semanticLabel,
        itemBuilder: (context, item) {
          focused = item.states.contains(WidgetState.focused);
          final on = item.fill >= 0.5;
          final cell = DesignStyleOf(layers, {
            ...item.states.difference(const {WidgetState.focused}),
            if (on) WidgetState.selected,
          });
          final glyph =
              cell.foreground ??
              (!enabled
                  ? (on ? c.surface : c.disabled)
                  : on
                  ? c.onColor(cell.fill ?? c.ink)
                  : c.ink);
          // Each cell stands in its own target (48 under a finger), so a
          // lit cell is a block inside its rules.
          return DesignTapTarget(
            child: SizedBox.square(
              dimension: side,
              child: ColoredBox(
                color: on
                    ? (cell.fill ?? (enabled ? c.ink : c.disabled))
                    : c.ink.withValues(alpha: 0),
                child: Center(
                  child: Icon(
                    LucideIcons.star,
                    size: cell.iconSize ?? 20,
                    color: glyph,
                  ),
                ),
              ),
            ),
          );
        },
        // The rating takes keyboard focus as one control.
        layoutBuilder: (context, items) => BrutalSurface(
          face: BrutalFace(
            fill: strip.fill ?? c.surface,
            border: rule,
            foreground: c.ink,
            focus:
                focused &&
                    FocusManager.instance.highlightMode ==
                        FocusHighlightMode.traditional
                ? c.ink
                : c.ink.withValues(alpha: 0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, item) in items.indexed) ...[
                if (i > 0)
                  SizedBox(
                    width: theme.borderWidth,
                    height: side,
                    child: ColoredBox(color: rule),
                  ),
                item,
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
      ..add(IntProperty('value', value))
      ..add(IntProperty('max', max));
  }
}

/// A file a [BrutalFileDrop] holds.
@immutable
class BrutalFile {
  /// A file called [name], of [bytes].
  const BrutalFile({required this.name, required this.bytes, this.progress});

  /// Its name.
  final String name;

  /// Its size.
  final int bytes;

  /// How much of it has gone up, 0 to 1; null once it is up.
  final double? progress;
}

/// Where files go: a box in a dashed rule that a press opens the picker
/// from ([onChoose]), then a row for each file it holds, each with its size
/// (or how far up it is) and a button that takes it out ([onRemove]).
///
/// Reads [style]'s `fill` (the box at rest; pressed, it goes ink), `edge`
/// (the dashed rule and each file's), `foreground`, `padding`, `textStyle`
/// (the call to action) and `iconSize` in its states, then
/// [BrutalThemeData.fileDropStyle]'s.
///
/// ```dart
/// BrutalFileDrop(label: 'Proof of student status', hint: 'A photo or a PDF, up to 10 MB', files: files, onChoose: pick, onRemove: (f) => setState(() => files.remove(f)))
/// ```
class BrutalFileDrop extends StatelessWidget {
  /// A file box.
  const BrutalFileDrop({
    super.key,
    required this.onChoose,
    this.files = const [],
    this.onRemove,
    this.label,
    this.hint,
    this.style,
  });

  /// Opens the picker; null disables the box.
  final VoidCallback? onChoose;

  /// The files it holds.
  final List<BrutalFile> files;

  /// Takes a file out.
  final ValueChanged<BrutalFile>? onRemove;

  /// The words over the box.
  final String? label;

  /// What it takes, under the call to action.
  final String? hint;

  /// Its style, over [BrutalThemeData.fileDropStyle].
  final BrutalStyle? style;

  static String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final layers = [style, theme.fileDropStyle];
    final rest = DesignStyleOf(layers, {
      if (onChoose == null) WidgetState.disabled,
    });
    final fileRule = rest.side?.color ?? rest.edge ?? c.ink;
    final box = DesignPressable(
      onPressed: onChoose,
      semanticLabel: [
        label,
        'Choose a file',
        hint,
      ].whereType<String>().join(', '),
      excludeSemantics: true,
      builder: (context, states, _) {
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        final layered = DesignStyleOf(layers, states);
        final ink =
            layered.foreground ??
            (disabled
                ? c.disabled
                : pressed
                ? c.paper
                : c.ink);
        return CustomPaint(
          painter: _DashedRule(
            color:
                layered.side?.color ??
                layered.edge ??
                (disabled ? c.disabled : c.ink),
            fill: pressed && !disabled ? c.ink : (layered.fill ?? c.surface),
            focus: states.contains(WidgetState.focused) ? c.ink : null,
            width: theme.borderWidth,
          ),
          child: Padding(
            padding:
                layered.padding(Directionality.of(context)) ??
                const EdgeInsets.all(BrutalSpacing.large),
            child: Column(
              children: [
                Icon(
                  LucideIcons.upload,
                  size: layered.iconSize ?? 24,
                  color: ink,
                ),
                const SizedBox(height: BrutalSpacing.small),
                Text(
                  'Choose a file',
                  style: layered.text(t.label).copyWith(color: ink),
                  textAlign: TextAlign.center,
                ),
                if (hint != null) ...[
                  const SizedBox(height: BrutalSpacing.tight),
                  Text(
                    hint!,
                    style: t.secondary.copyWith(
                      color: pressed && !disabled ? c.paper : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: BrutalSpacing.small),
            child: ExcludeSemantics(
              child: Text(
                label!,
                style: t.label.copyWith(
                  fontSize: 14,
                  height: 20 / 14,
                  color: onChoose == null ? c.disabled : c.ink,
                ),
              ),
            ),
          ),
        box,
        for (final file in files) ...[
          const SizedBox(height: BrutalSpacing.small),
          BrutalSurface(
            face: BrutalFace(
              fill: rest.fill ?? c.surface,
              border: fileRule,
              foreground: c.ink,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: BrutalSpacing.medium,
                end: BrutalSpacing.tight,
                top: BrutalSpacing.tight,
                bottom: BrutalSpacing.tight,
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.file, size: 20, color: c.ink),
                  const SizedBox(width: BrutalSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.label.copyWith(
                            fontSize: 14,
                            height: 20 / 14,
                          ),
                        ),
                        Text(
                          file.progress == null
                              ? _size(file.bytes)
                              : '${(file.progress! * 100).round()}% of '
                                    '${_size(file.bytes)}',
                          style: t.secondary,
                        ),
                        if (file.progress != null) ...[
                          const SizedBox(height: BrutalSpacing.tight),
                          SizedBox(
                            height: BrutalSpacing.tight,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: FractionallySizedBox(
                                widthFactor: file.progress!.clamp(0.0, 1.0),
                                child: ColoredBox(color: c.ink),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onRemove != null)
                    DesignTapTarget(
                      child: DesignPressable(
                        onPressed: () => onRemove!(file),
                        semanticLabel: 'Remove ${file.name}',
                        builder: (context, states, _) {
                          final pressed = states.contains(WidgetState.pressed);
                          return SizedBox.square(
                            dimension: 40,
                            child: CustomPaint(
                              foregroundPainter:
                                  states.contains(WidgetState.focused)
                                  ? BrutalInsetFocusPainter(
                                      pressed ? c.paper : c.ink,
                                    )
                                  : null,
                              child: ColoredBox(
                                color: pressed
                                    ? c.ink
                                    : c.ink.withValues(alpha: 0),
                                child: Icon(
                                  LucideIcons.x,
                                  size: 20,
                                  color: pressed ? c.paper : c.ink,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('files', files.length))
      ..add(
        FlagProperty('enabled', value: onChoose != null, ifFalse: 'disabled'),
      );
  }
}

/// A box filled with [fill] in a dashed square rule (8 on, 6 off), and the
/// focus rule outside it when [focus] is given.
class _DashedRule extends CustomPainter {
  _DashedRule({
    required this.color,
    required this.fill,
    required this.width,
    this.focus,
  });

  final Color color;
  final Color fill;
  final double width;
  final Color? focus;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = fill);
    final w = width;
    final paint = Paint()..color = color;
    void run(Offset from, Offset along, double length, Offset across) {
      for (var d = 0.0; d < length; d += 14) {
        final dash = (length - d).clamp(0.0, 8.0);
        final a = from + along * d;
        canvas.drawRect(
          Rect.fromPoints(a, a + along * dash + across * w),
          paint,
        );
      }
    }

    run(Offset.zero, const Offset(1, 0), size.width, const Offset(0, 1));
    run(
      Offset(0, size.height - w),
      const Offset(1, 0),
      size.width,
      const Offset(0, 1),
    );
    run(Offset.zero, const Offset(0, 1), size.height, const Offset(1, 0));
    run(
      Offset(size.width - w, 0),
      const Offset(0, 1),
      size.height,
      const Offset(1, 0),
    );
    if (focus != null) {
      const out = BrutalMetrics.focusGap + BrutalMetrics.focusWidth / 2;
      canvas.drawRect(
        rect.inflate(out),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = BrutalMetrics.focusWidth
          ..color = focus!,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRule old) =>
      old.color != color ||
      old.fill != fill ||
      old.width != width ||
      old.focus != focus;
}
