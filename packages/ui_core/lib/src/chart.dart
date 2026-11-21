/// Charts, headless: the scales, the picking of a point (a pointer, a
/// finger, the keys, a screen reader), the words a screen reader hears and
/// the spring a data change runs on. The look draws every mark, axis, grid
/// line and readout from the details it is handed.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'chart_scale.dart';
import 'date_field.dart' show RawTimeOfDay;
import 'internal/announce.dart';
import 'localizations.dart';
import 'motion.dart';

/// A point of a [DesignChartSeries]: [x] and [y], or a gap where [y] is
/// null.
@immutable
class DesignChartPoint {
  /// A point at [x] (a number, or on a band axis a category's index).
  const DesignChartPoint(this.x, this.y);

  /// A point at a time: [x] holds its milliseconds since the epoch.
  DesignChartPoint.time(DateTime x, this.y)
    : x = x.millisecondsSinceEpoch.toDouble();

  /// Where it stands along x.
  final double x;

  /// Its value; null, a gap.
  final double? y;

  @override
  bool operator ==(Object other) =>
      other is DesignChartPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'DesignChartPoint($x, $y)';
}

/// A named run of points, in order along x.
@immutable
class DesignChartSeries {
  /// A series called [label].
  const DesignChartSeries({required this.label, required this.points});

  /// Its name, as a legend and a screen reader say it ("Revenue").
  final String label;

  /// Its points, in order along x.
  final List<DesignChartPoint> points;

  @override
  bool operator ==(Object other) =>
      other is DesignChartSeries &&
      other.label == label &&
      listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(label, Object.hashAll(points));

  @override
  String toString() => 'DesignChartSeries($label, ${points.length} points)';
}

/// What a [DesignChart]'s x values are.
enum DesignChartXAxis {
  /// Numbers ([DesignLinearScale]).
  linear,

  /// Times, as milliseconds since the epoch ([DesignTimeScale]).
  time,

  /// Categories, by index ([DesignBandScale]): bars.
  band,
}

/// A point of a chart: the [index]th point of the [series]th series.
@immutable
class DesignChartPointRef {
  /// A reference to a point.
  const DesignChartPointRef(this.series, this.index);

  /// The series, by its place in [DesignChart.series].
  final int series;

  /// The point, by its place in its series.
  final int index;

  @override
  bool operator ==(Object other) =>
      other is DesignChartPointRef &&
      other.series == series &&
      other.index == index;

  @override
  int get hashCode => Object.hash(series, index);

  @override
  String toString() => 'DesignChartPointRef($series, $index)';
}

/// A [DesignChart] as its look draws it.
@immutable
class DesignChartDetails {
  /// The chart's details.
  const DesignChartDetails({
    required this.size,
    required this.plotArea,
    required this.x,
    required this.y,
    required this.xTicks,
    required this.yTicks,
    required this.series,
    required this.active,
    required this.activePosition,
    required this.activeBy,
    required this.states,
  });

  /// The chart's whole size.
  final Size size;

  /// Where the marks go: the size, less [DesignChart.padding].
  final Rect plotArea;

  /// The x scale, ranged to [plotArea]'s width: right to left when the
  /// reader's direction is.
  final DesignScale x;

  /// The y scale, ranged to [plotArea]'s height, its least value at the
  /// bottom.
  final DesignLinearScale y;

  /// The x axis's ticks, labelled.
  final List<DesignScaleTick> xTicks;

  /// The y axis's ticks, labelled.
  final List<DesignScaleTick> yTicks;

  /// The values as drawn now: between the old data and the new while a
  /// change springs.
  final List<DesignChartSeries> series;

  /// The point a pointer, a finger or the keys picked; null, none.
  final DesignChartPointRef? active;

  /// Where [active] stands: the readout's anchor.
  final Offset? activePosition;

  /// What picked [active]: a touch puts its readout clear of the finger;
  /// null, the keys or a screen reader.
  final PointerDeviceKind? activeBy;

  /// The chart's states: [WidgetState.focused] while the keys are on it,
  /// [WidgetState.hovered].
  final Set<WidgetState> states;

  /// Where [point] stands, as drawn (a gap at the y scale's least value).
  Offset positionOf(DesignChartPointRef point) {
    final p = series[point.series].points[point.index];
    return Offset(x.map(p.x), y.map(p.y ?? y.min));
  }
}

/// Draws a chart from its details.
typedef DesignChartBuilder = Widget Function(
  BuildContext context,
  DesignChartDetails details,
);

/// Formats a value for labels, readouts and speech.
typedef DesignChartFormat = String Function(double value);

// The smallest step between neighbouring x values: how finely a time axis's
// points are told apart.
double _xGapOf(List<DesignChartSeries> series) {
  var gap = double.infinity;
  for (final s in series) {
    for (var i = 1; i < s.points.length; i++) {
      final d = (s.points[i].x - s.points[i - 1].x).abs();
      if (d > 0) gap = math.min(gap, d);
    }
  }
  return gap;
}

// An x value in words: [format]'s, or the reader's number, a category's
// name, or a date as fine as [gap] needs.
String _xText(
  double x,
  RawWidgetsLocalizations l, {
  required DesignChartXAxis axis,
  required List<String>? categories,
  required DesignChartFormat? format,
  required double gap,
}) {
  if (format != null) return format(x);
  switch (axis) {
    case DesignChartXAxis.linear:
      return l.formatDecimal(x);
    case DesignChartXAxis.band:
      final i = x.round();
      return categories != null && i >= 0 && i < categories.length
          ? categories[i]
          : l.formatDecimal(i + 1);
    case DesignChartXAxis.time:
      final at = DateTime.fromMillisecondsSinceEpoch(x.round());
      const day = 86400000;
      if (gap.isInfinite) return l.formatFullDate(at);
      if (gap >= 365 * day) return l.formatYear(at);
      if (gap >= 28 * day) return l.formatMonthYear(at);
      if (gap >= day) return l.formatFullDate(at);
      return '${l.formatShortMonthDay(at)}${l.listSeparator}'
          '${l.formatTimeOfDay(RawTimeOfDay.fromDateTime(at))}';
  }
}

/// A cartesian chart (line, area, bars, a sparkline): the look draws
/// [series] from the scales and ticks in [builder]'s details; the chart
/// picks points, says them, and springs from one set of data to the next.
///
/// Picking: a mouse shows the point nearest it along x (bars: the band
/// under it), its series the nearest by y, and leaving clears it; a finger
/// scrubs with a horizontal drag (a list still scrolls vertically) and
/// lifting clears it; a tap holds the point until a tap elsewhere. Keys (a
/// single tab stop): Left and Right the previous and next point along x as
/// drawn (mirrored right to left), Up and Down the series above and below
/// at that x, Home and End the first and last, Escape lets go; leaving the
/// chart lets go too.
///
/// A screen reader hears [semanticLabel], then the data in a sentence ("2
/// series, 12 points, Jan 2026 to Dec 2026, lowest 820, highest 1,640";
/// [semanticSummary] overrides it), or the picked point ("Mar 2026,
/// Revenue: 1,240"); increase and decrease step through the points, series
/// after series, each said, and "Show data table" ([onShowTable]) offers a
/// [DesignChartTable].
///
/// The chart fills the width it is given (300 when unbounded) and the
/// height (half its width when unbounded).
///
/// ```dart
/// DesignChart(semanticLabel: 'Revenue', series: const [DesignChartSeries(label: 'Revenue', points: [DesignChartPoint(0, 820), DesignChartPoint(1, 1240)])], builder: (context, chart) => CustomPaint(size: chart.size))
/// ```
class DesignChart extends StatefulWidget {
  /// A chart of [series].
  const DesignChart({
    super.key,
    required this.series,
    required this.builder,
    required this.semanticLabel,
    this.xAxis = DesignChartXAxis.linear,
    this.categories,
    this.padding = EdgeInsets.zero,
    this.yIncludesZero = true,
    this.tickCount = 5,
    this.formatX,
    this.formatY,
    this.semanticSummary,
    this.onActivePointChanged,
    this.onShowTable,
    this.focusNode,
    this.autofocus = false,
    this.dampingRatio = 1,
    this.stiffness = 400,
  });

  /// The data, each series in order along x.
  final List<DesignChartSeries> series;

  /// Draws the chart.
  final DesignChartBuilder builder;

  /// The chart's name, said first ("Revenue by month").
  final String semanticLabel;

  /// What the x values are. Defaults to numbers.
  final DesignChartXAxis xAxis;

  /// A band axis's category names, by index; null: their numbers.
  final List<String>? categories;

  /// The room kept round the plot for the look's axes and labels; start
  /// and end follow the reader's direction.
  final EdgeInsetsGeometry padding;

  /// Whether the y scale reaches 0. Defaults to true (bars and areas
  /// stand on it).
  final bool yIncludesZero;

  /// About how many ticks each axis has.
  final int tickCount;

  /// The x values' labels, readout and speech; null: the scale's own (the
  /// reader's numbers, dates, or [categories]).
  final DesignChartFormat? formatX;

  /// The y values' labels, readout and speech; null: the reader's numbers.
  final DesignChartFormat? formatY;

  /// What a screen reader hears of the data; null: a sentence built from
  /// it.
  final String? semanticSummary;

  /// Called as the picked point changes (null: none), for a readout
  /// elsewhere or a linked chart.
  final ValueChanged<DesignChartPointRef?>? onActivePointChanged;

  /// Shows the data as a table: offered to a screen reader as "Show data
  /// table". Null: not offered.
  final VoidCallback? onShowTable;

  /// The chart's focus; null: its own. A node given is never disposed
  /// here.
  final FocusNode? focusNode;

  /// Whether the chart takes focus when it first shows.
  final bool autofocus;

  /// The damping of the spring a data change runs on (critically damped,
  /// 1, under Reduce Motion). Defaults to 1.
  final double dampingRatio;

  /// The stiffness of that spring. Defaults to 400.
  final double stiffness;

  @override
  State<DesignChart> createState() => _DesignChartState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<DesignChartBuilder>.has('builder', builder))
      ..add(
        IterableProperty<String>('categories', categories, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: EdgeInsets.zero,
        ),
      )
      ..add(
        FlagProperty(
          'yIncludesZero',
          value: yIncludesZero,
          ifFalse: 'y not from 0',
          defaultValue: true,
        ),
      )
      ..add(IntProperty('tickCount', tickCount, defaultValue: 5))
      ..add(ObjectFlagProperty<DesignChartFormat>.has('formatX', formatX))
      ..add(ObjectFlagProperty<DesignChartFormat>.has('formatY', formatY))
      ..add(
        StringProperty('semanticSummary', semanticSummary, defaultValue: null),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<DesignChartPointRef?>>.has(
          'onActivePointChanged',
          onActivePointChanged,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onShowTable', onShowTable))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('dampingRatio', dampingRatio, defaultValue: 1))
      ..add(DoubleProperty('stiffness', stiffness, defaultValue: 400))
      ..add(IntProperty('series', series.length))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(EnumProperty<DesignChartXAxis>('xAxis', xAxis))
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

// The data's extent: x, and y widened to nice ticks.
@immutable
class _Domain {
  const _Domain(this.xMin, this.xMax, this.yMin, this.yMax);

  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  static _Domain lerp(_Domain a, _Domain b, double t) => _Domain(
    lerpDouble(a.xMin, b.xMin, t)!,
    lerpDouble(a.xMax, b.xMax, t)!,
    lerpDouble(a.yMin, b.yMin, t)!,
    lerpDouble(a.yMax, b.yMax, t)!,
  );
}

// The pointer, key and screen reader handling both charts share. A pick
// is a point (a cartesian chart) or a slice (a pie).
mixin _Picking<W extends StatefulWidget> on State<W> {
  FocusNode? _ownNode;
  bool _hovered = false;
  // A tap's pick, held until a tap elsewhere.
  bool _held = false;
  // A finger (or a mouse button) scrubbing.
  bool _dragging = false;
  PointerDeviceKind? _pointer;
  PointerDeviceKind? get _activeBy => _pointer;
  set _activeBy(PointerDeviceKind? value) {
    if ((_pointer == null) != (value == null)) {
      if (value == null) {
        FocusManager.instance.removeLateKeyEventHandler(_dismissPointerPick);
      } else {
        FocusManager.instance.addLateKeyEventHandler(_dismissPointerPick);
      }
    }
    _pointer = value;
  }

  // A focused control or a menu gets first use of Escape. A pointer pick
  // can then be dismissed without sending keyboard focus to the chart.
  KeyEventResult _dismissPointerPick(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        _activeBy == null ||
        !mounted) {
      return KeyEventResult.ignored;
    }
    for (var route = ModalRoute.of(context); route != null;) {
      if (!route.isCurrent) return KeyEventResult.ignored;
      final navigator = route.navigator;
      route = navigator == null ? null : ModalRoute.of(navigator.context);
    }
    clearPick();
    return KeyEventResult.handled;
  }

  FocusNode? get givenNode;
  FocusNode get _node => givenNode ?? (_ownNode ??= FocusNode());

  bool get hasPick;

  void clearPick();

  void initPicking() => _node.addListener(_focusChanged);

  void updatePicking(FocusNode? oldNode) {
    if (oldNode == givenNode) return;
    (oldNode ?? _ownNode)?.removeListener(_focusChanged);
    _node.addListener(_focusChanged);
  }

  void disposePicking() {
    _activeBy = null;
    _node.removeListener(_focusChanged);
    _ownNode?.dispose();
  }

  void _focusChanged() {
    if (!mounted) return;
    // The keys' pick goes with the keys.
    if (!_node.hasFocus && hasPick && _activeBy == null) {
      clearPick();
    } else {
      setState(() {});
    }
  }

  Set<WidgetState> get pickingStates => {
    if (_node.hasFocus) WidgetState.focused,
    if (_hovered) WidgetState.hovered,
  };

  Widget picking({
    required Widget child,
    required String label,
    required String value,
    required bool autofocus,
    required void Function(Offset local, PointerDeviceKind kind) pick,
    required KeyEventResult Function(LogicalKeyboardKey key) onKey,
    required VoidCallback? onNext,
    required VoidCallback? onPrevious,
    required String? nextValue,
    required String? previousValue,
    required VoidCallback? onShowTable,
  }) {
    final l = RawWidgetsLocalizations.of(context);
    // A drag ends: a finger's pick goes with it, a mouse's stays as a hover.
    void letGo() {
      if (!_dragging) return;
      _dragging = false;
      if (!(_hovered && _activeBy == PointerDeviceKind.mouse)) clearPick();
    }

    return Semantics(
      container: true,
      label: label,
      value: value,
      increasedValue: nextValue,
      decreasedValue: previousValue,
      onIncrease: onNext,
      onDecrease: onPrevious,
      customSemanticsActions: onShowTable == null
          ? null
          : {CustomSemanticsAction(label: l.chartShowTableLabel): onShowTable},
      child: Focus(
        focusNode: _node,
        autofocus: autofocus,
        onKeyEvent: (_, event) =>
            event is KeyDownEvent || event is KeyRepeatEvent
            ? onKey(event.logicalKey)
            : KeyEventResult.ignored,
        child: TapRegion(
          onTapOutside: (_) {
            if (!_held) return;
            _held = false;
            clearPick();
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onHover: (event) {
              if (!_held) pick(event.localPosition, PointerDeviceKind.mouse);
            },
            onExit: (_) {
              setState(() => _hovered = false);
              if (_activeBy == PointerDeviceKind.mouse) clearPick();
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTapUp: (details) {
                if (details.kind == PointerDeviceKind.mouse) return;
                pick(details.localPosition, details.kind);
                _held = hasPick;
              },
              onHorizontalDragStart: (details) {
                _held = false;
                _dragging = true;
                pick(
                  details.localPosition,
                  details.kind ?? PointerDeviceKind.touch,
                );
              },
              onHorizontalDragUpdate: (details) => pick(
                details.localPosition,
                _activeBy ?? PointerDeviceKind.touch,
              ),
              onHorizontalDragEnd: (_) => letGo(),
              onHorizontalDragCancel: letGo,
              child: ExcludeSemantics(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesignChartState extends State<DesignChart>
    with SingleTickerProviderStateMixin, _Picking<DesignChart> {
  late final AnimationController _motion = AnimationController.unbounded(
    vsync: this,
    value: 1,
  )..addListener(() => setState(() {}));
  // What a change springs from: the series and the extent as drawn.
  List<DesignChartSeries> _from = const [];
  _Domain? _fromDomain;
  DesignChartPointRef? _active;
  // The last layout, for picking.
  DesignChartDetails? _details;

  @override
  FocusNode? get givenNode => widget.focusNode;

  @override
  bool get hasPick => _active != null;

  @override
  void clearPick() => _setActive(null, null);

  @override
  void initState() {
    super.initState();
    initPicking();
  }

  @override
  void didUpdateWidget(DesignChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    updatePicking(oldWidget.focusNode);
    if (listEquals(oldWidget.series, widget.series) &&
        oldWidget.xAxis == widget.xAxis &&
        oldWidget.yIncludesZero == widget.yIncludesZero &&
        oldWidget.tickCount == widget.tickCount) {
      return;
    }
    final t = _motion.value;
    _from = _drawn(t, oldWidget);
    _fromDomain = _drawnDomain(t, oldWidget);
    _motion.value = 0;
    unawaited(
      _motion.springTo(
        1,
        DesignMotionPolicy.of(context).spatial(
          dampingRatio: widget.dampingRatio,
          stiffness: widget.stiffness,
        ),
      ),
    );
    final a = _active;
    if (a != null && !_live(a)) {
      _active = null;
      _activeBy = null;
      _held = false;
      widget.onActivePointChanged?.call(null);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    disposePicking();
    super.dispose();
  }

  bool _live(DesignChartPointRef ref) =>
      ref.series >= 0 &&
      ref.series < widget.series.length &&
      ref.index >= 0 &&
      ref.index < widget.series[ref.series].points.length &&
      widget.series[ref.series].points[ref.index].y != null;

  static int _bands(DesignChart w) =>
      w.categories?.length ??
      w.series.fold(0, (n, s) => math.max(n, s.points.length));

  static _Domain _domainOf(DesignChart w) {
    var xMin = double.infinity;
    var xMax = double.negativeInfinity;
    var yMin = double.infinity;
    var yMax = double.negativeInfinity;
    for (final s in w.series) {
      for (final p in s.points) {
        xMin = math.min(xMin, p.x);
        xMax = math.max(xMax, p.x);
        final y = p.y;
        if (y == null) continue;
        yMin = math.min(yMin, y);
        yMax = math.max(yMax, y);
      }
    }
    if (w.xAxis == DesignChartXAxis.band) {
      xMin = 0;
      xMax = math.max(0, _bands(w) - 1).toDouble();
    }
    if (xMin > xMax) {
      xMin = 0;
      xMax = 1;
    }
    if (yMin > yMax) {
      yMin = 0;
      yMax = 1;
    }
    final y = DesignLinearScale.nice(
      min: yMin,
      max: yMax,
      start: 0,
      end: 1,
      tickCount: w.tickCount,
      includeZero: w.yIncludesZero,
    );
    return _Domain(xMin, xMax, y.min, y.max);
  }

  _Domain _drawnDomain(double t, DesignChart w) {
    final to = _domainOf(w);
    final from = _fromDomain;
    if (from == null || t >= 1) return to;
    return _Domain.lerp(from, to, t);
  }

  // The series as drawn at [t] of the spring towards [w]'s: each point from
  // where it was drawn; a new one, or one out of a gap, from the baseline.
  List<DesignChartSeries> _drawn(double t, DesignChart w) {
    if (t >= 1 || _from.isEmpty) return w.series;
    final domain = _domainOf(w);
    final baseline = 0.0.clamp(domain.yMin, domain.yMax);
    return [
      for (var i = 0; i < w.series.length; i++)
        DesignChartSeries(
          label: w.series[i].label,
          points: [
            for (var j = 0; j < w.series[i].points.length; j++)
              if ((
                    i < _from.length && j < _from[i].points.length
                        ? _from[i].points[j]
                        : null,
                    w.series[i].points[j],
                  )
                  case (final from, final to))
                to.y == null
                    ? to
                    : DesignChartPoint(
                        lerpDouble(from?.x ?? to.x, to.x, t)!,
                        lerpDouble(from?.y ?? baseline, to.y, t),
                      ),
          ],
        ),
    ];
  }

  // ---- Words.

  String _xLabel(double x, RawWidgetsLocalizations l) => _xText(
    x,
    l,
    axis: widget.xAxis,
    categories: widget.categories,
    format: widget.formatX,
    gap: _xGapOf(widget.series),
  );

  String _yLabel(double y, RawWidgetsLocalizations l) =>
      widget.formatY?.call(y) ?? l.formatDecimal(y);

  String _pointLabel(DesignChartPointRef ref, RawWidgetsLocalizations l) {
    final s = widget.series[ref.series];
    final p = s.points[ref.index];
    return l.chartPointLabel(_xLabel(p.x, l), s.label, _yLabel(p.y!, l));
  }

  String _summary(RawWidgetsLocalizations l) {
    final given = widget.semanticSummary;
    if (given != null) return given;
    final xs = <double>{};
    var yMin = double.infinity;
    var yMax = double.negativeInfinity;
    for (final s in widget.series) {
      for (final p in s.points) {
        final y = p.y;
        if (y == null) continue;
        xs.add(p.x);
        yMin = math.min(yMin, y);
        yMax = math.max(yMax, y);
      }
    }
    final parts = [l.chartSeriesCountLabel(widget.series.length)];
    if (xs.isNotEmpty) {
      final sorted = xs.toList()..sort();
      parts.addAll([
        l.chartPointCountLabel(sorted.length),
        l.chartRangeLabel(_xLabel(sorted.first, l), _xLabel(sorted.last, l)),
        l.chartExtremesLabel(_yLabel(yMin, l), _yLabel(yMax, l)),
      ]);
    }
    return parts.join(l.listSeparator);
  }

  // ---- Picking.

  void _setActive(
    DesignChartPointRef? ref,
    PointerDeviceKind? by, {
    bool say = false,
  }) {
    if (ref == null) _held = false;
    final changed = ref != _active;
    if (!changed && by == _activeBy) return;
    setState(() {
      _active = ref;
      _activeBy = ref == null ? null : by;
    });
    if (!changed) return;
    widget.onActivePointChanged?.call(ref);
    if (say && ref != null) {
      designAnnounce(
        context,
        _pointLabel(ref, RawWidgetsLocalizations.of(context)),
      );
    }
  }

  DesignChartPointRef? _nearest(Offset at) {
    final d = _details;
    if (d == null) return null;
    final x = d.x;
    final band = x is DesignBandScale ? x.indexAt(at.dx) : null;
    if (x is DesignBandScale && band == null) return null;
    DesignChartPointRef? best;
    var bestDx = double.infinity;
    var bestDy = double.infinity;
    for (var i = 0; i < widget.series.length; i++) {
      final points = d.series[i].points;
      for (var j = 0; j < points.length; j++) {
        final y = points[j].y;
        if (y == null) continue;
        if (band != null && points[j].x.round() != band) continue;
        final dx = (x.map(points[j].x) - at.dx).abs();
        final dy = (d.y.map(y) - at.dy).abs();
        if (dx < bestDx - 0.5 || (dx <= bestDx + 0.5 && dy < bestDy)) {
          best = DesignChartPointRef(i, j);
          bestDx = math.min(dx, bestDx);
          bestDy = dy;
        }
      }
    }
    return best;
  }

  // The live point [way] (1 after, -1 before) [from] in its series; [from]'s
  // index may be one past either end.
  DesignChartPointRef? _along(DesignChartPointRef from, int way) {
    final points = widget.series[from.series].points;
    for (var j = from.index + way; j >= 0 && j < points.length; j += way) {
      if (points[j].y != null) return DesignChartPointRef(from.series, j);
    }
    return null;
  }

  // The first (or last) live point of [series], or of the next series that
  // has one.
  DesignChartPointRef? _end(int series, {required bool last}) {
    for (var i = series; i < widget.series.length; i++) {
      final length = widget.series[i].points.length;
      final found = _along(
        DesignChartPointRef(i, last ? length : -1),
        last ? -1 : 1,
      );
      if (found != null) return found;
    }
    return null;
  }

  // Through every point, series after series: a screen reader's steps.
  DesignChartPointRef? _stepThrough(int way) {
    final a = _active;
    final next = a == null ? null : _along(a, way);
    if (next != null) return next;
    final from = a == null ? (way > 0 ? -1 : widget.series.length) : a.series;
    for (var i = from + way; i >= 0 && i < widget.series.length; i += way) {
      final length = widget.series[i].points.length;
      final found = _along(DesignChartPointRef(i, way > 0 ? -1 : length), way);
      if (found != null) return found;
    }
    return null;
  }

  // The series above (or below, [way] -1) [from] at its x: the nearest
  // greater (or lesser) value; ties by series order.
  DesignChartPointRef? _across(DesignChartPointRef from, int way) {
    final here = widget.series[from.series].points[from.index];
    final y0 = here.y!;
    DesignChartPointRef? best;
    double? bestY;
    for (var i = 0; i < widget.series.length; i++) {
      if (i == from.series) continue;
      final points = widget.series[i].points;
      for (var j = 0; j < points.length; j++) {
        final y = points[j].y;
        if (y == null || points[j].x != here.x) continue;
        final beyond = way > 0
            ? (y > y0 || (y == y0 && i > from.series))
            : (y < y0 || (y == y0 && i < from.series));
        if (beyond && (bestY == null || (way > 0 ? y < bestY : y > bestY))) {
          best = DesignChartPointRef(i, j);
          bestY = y;
        }
      }
    }
    return best;
  }

  KeyEventResult _onKey(LogicalKeyboardKey key) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final a = _active;
    DesignChartPointRef? to;
    if (key == LogicalKeyboardKey.escape) {
      if (a == null) return KeyEventResult.ignored;
      clearPick();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowLeft) {
      final way = (key == LogicalKeyboardKey.arrowRight) != rtl ? 1 : -1;
      to = a == null ? _end(0, last: way < 0) : _along(a, way) ?? a;
    } else if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      final way = key == LogicalKeyboardKey.arrowUp ? 1 : -1;
      to = a == null ? _end(0, last: false) : _across(a, way) ?? a;
    } else if (key == LogicalKeyboardKey.home ||
        key == LogicalKeyboardKey.end) {
      to = _end(a?.series ?? 0, last: key == LogicalKeyboardKey.end);
    } else {
      return KeyEventResult.ignored;
    }
    if (to != null) _setActive(to, null, say: true);
    return KeyEventResult.handled;
  }

  DesignChartDetails _layout(Size size, RawWidgetsLocalizations l) {
    final t = _motion.value;
    final domain = _drawnDomain(t, widget);
    final direction = Directionality.of(context);
    final rtl = direction == TextDirection.rtl;
    final plot = widget.padding
        .resolve(direction)
        .deflateRect(Offset.zero & size);
    final xStart = rtl ? plot.right : plot.left;
    final xEnd = rtl ? plot.left : plot.right;
    final DesignScale x = switch (widget.xAxis) {
      DesignChartXAxis.linear => DesignLinearScale(
        min: domain.xMin,
        max: domain.xMax,
        start: xStart,
        end: xEnd,
      ),
      DesignChartXAxis.time => DesignTimeScale(
        min: DateTime.fromMillisecondsSinceEpoch(domain.xMin.round()),
        max: DateTime.fromMillisecondsSinceEpoch(domain.xMax.round()),
        start: xStart,
        end: xEnd,
      ),
      DesignChartXAxis.band => DesignBandScale(
        count: _bands(widget),
        start: xStart,
        end: xEnd,
        labels: widget.categories,
      ),
    };
    final y = DesignLinearScale(
      min: domain.yMin,
      max: domain.yMax,
      start: plot.bottom,
      end: plot.top,
    );
    List<DesignScaleTick> labelled(
      List<DesignScaleTick> ticks,
      DesignChartFormat? format,
    ) => format == null
        ? ticks
        : [
            for (final tick in ticks)
              DesignScaleTick(
                value: tick.value,
                position: tick.position,
                label: format(tick.value),
              ),
          ];
    final series = _drawn(t, widget);
    final a = _active;
    final p = a == null ? null : series[a.series].points[a.index];
    return DesignChartDetails(
      size: size,
      plotArea: plot,
      x: x,
      y: y,
      xTicks: labelled(x.ticks(l, count: widget.tickCount), widget.formatX),
      yTicks: labelled(y.ticks(l, count: widget.tickCount), widget.formatY),
      series: series,
      active: a,
      activePosition: p == null ? null : Offset(x.map(p.x), y.map(p.y!)),
      activeBy: _activeBy,
      states: pickingStates,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = RawWidgetsLocalizations.of(context);
    final a = _active;
    final next = _stepThrough(1);
    final previous = _stepThrough(-1);
    return picking(
      label: widget.semanticLabel,
      value: a == null ? _summary(l) : _pointLabel(a, l),
      autofocus: widget.autofocus,
      pick: (at, kind) => _setActive(_nearest(at), kind),
      onKey: _onKey,
      onNext: next == null ? null : () => _setActive(next, null, say: true),
      onPrevious: previous == null
          ? null
          : () => _setActive(previous, null, say: true),
      nextValue: next == null ? null : _pointLabel(next, l),
      previousValue: previous == null ? null : _pointLabel(previous, l),
      onShowTable: widget.onShowTable,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 300.0;
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : width / 2;
          final details = _details = _layout(Size(width, height), l);
          return SizedBox.fromSize(
            size: details.size,
            child: widget.builder(context, details),
          );
        },
      ),
    );
  }
}

/// A slice of a [DesignPieChart]: a [label] and its [value].
@immutable
class DesignPieSlice {
  /// A slice.
  const DesignPieSlice({required this.label, required this.value});

  /// Its name ("Rent").
  final String label;

  /// Its value, 0 or more; its share is its part of all of them.
  final double value;

  @override
  bool operator ==(Object other) =>
      other is DesignPieSlice && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => 'DesignPieSlice($label, $value)';
}

/// A slice as drawn.
@immutable
class DesignPieSliceDetails {
  /// A slice's details.
  const DesignPieSliceDetails({
    required this.label,
    required this.value,
    required this.share,
    required this.startAngle,
    required this.sweepAngle,
  });

  /// Its name.
  final String label;

  /// Its value as drawn now (springing).
  final double value;

  /// Its part of the whole, 0 to 1.
  final double share;

  /// Where it starts, in [Canvas.drawArc]'s radians (0 at three o'clock,
  /// clockwise): the first slice at twelve o'clock.
  final double startAngle;

  /// How far it runs: clockwise, or counter-clockwise (negative) right to
  /// left.
  final double sweepAngle;

  /// Its middle, in the same radians.
  double get midAngle => startAngle + sweepAngle / 2;
}

/// A [DesignPieChart] as its look draws it.
@immutable
class DesignPieChartDetails {
  /// The pie's details.
  const DesignPieChartDetails({
    required this.size,
    required this.centre,
    required this.radius,
    required this.holeRadius,
    required this.slices,
    required this.active,
    required this.activePosition,
    required this.activeBy,
    required this.states,
  });

  /// The chart's whole size.
  final Size size;

  /// The pie's centre.
  final Offset centre;

  /// Its radius.
  final double radius;

  /// The hole's radius (a donut's), in the same units; 0, none.
  final double holeRadius;

  /// The slices, in order.
  final List<DesignPieSliceDetails> slices;

  /// The slice a pointer, a finger or the keys picked; null, none.
  final int? active;

  /// The middle of [active]'s rim: the readout's anchor.
  final Offset? activePosition;

  /// What picked [active]: a touch puts its readout clear of the finger;
  /// null, the keys or a screen reader.
  final PointerDeviceKind? activeBy;

  /// The chart's states: [WidgetState.focused], [WidgetState.hovered].
  final Set<WidgetState> states;
}

/// Draws a pie chart from its details.
typedef DesignPieChartBuilder = Widget Function(
  BuildContext context,
  DesignPieChartDetails details,
);

/// A pie or donut: the look draws [slices] from the angles in [builder]'s
/// details; the chart picks a slice, says it, and springs from one set of
/// values to the next.
///
/// A pointer or a finger picks the slice under it (by angle, inside the
/// radius and outside the hole), as [DesignChart] picks a point. Keys (one
/// tab stop): Right and Down the next slice, Left and Up the previous
/// (Left and Right mirrored right to left), Home and End the first and
/// last, Escape lets go. A screen reader hears [semanticLabel], then "4
/// slices, lowest 120, highest 1,200" ([semanticSummary] overrides it) or
/// the picked slice ("40%, Rent: 1,200"), and steps through the slices.
///
/// The pie fills the width it is given (300 when unbounded) and the
/// height (as tall as wide when unbounded).
///
/// ```dart
/// DesignPieChart(semanticLabel: 'Spending', slices: const [DesignPieSlice(label: 'Rent', value: 1200), DesignPieSlice(label: 'Food', value: 600)], builder: (context, pie) => CustomPaint(size: pie.size))
/// ```
class DesignPieChart extends StatefulWidget {
  /// A pie of [slices].
  const DesignPieChart({
    super.key,
    required this.slices,
    required this.builder,
    required this.semanticLabel,
    this.padding = EdgeInsets.zero,
    this.holeRadius = 0,
    this.formatValue,
    this.semanticSummary,
    this.onActiveSliceChanged,
    this.onShowTable,
    this.focusNode,
    this.autofocus = false,
    this.dampingRatio = 1,
    this.stiffness = 400,
  }) : assert(holeRadius >= 0 && holeRadius < 1);

  /// The slices, clockwise from twelve o'clock (counter-clockwise right to
  /// left).
  final List<DesignPieSlice> slices;

  /// Draws the pie.
  final DesignPieChartBuilder builder;

  /// The chart's name, said first ("Spending").
  final String semanticLabel;

  /// The room kept round the pie for the look's labels.
  final EdgeInsetsGeometry padding;

  /// A donut's hole, as a fraction of the radius: a pointer in it picks
  /// nothing. Defaults to 0, a pie.
  final double holeRadius;

  /// The values' readout and speech; null: the reader's numbers.
  final DesignChartFormat? formatValue;

  /// What a screen reader hears of the data; null: a sentence built from
  /// it.
  final String? semanticSummary;

  /// Called as the picked slice changes (null: none).
  final ValueChanged<int?>? onActiveSliceChanged;

  /// Shows the data as a table: offered to a screen reader as "Show data
  /// table". Null: not offered.
  final VoidCallback? onShowTable;

  /// The chart's focus; null: its own. A node given is never disposed
  /// here.
  final FocusNode? focusNode;

  /// Whether the chart takes focus when it first shows.
  final bool autofocus;

  /// The damping of the spring a data change runs on (critically damped,
  /// 1, under Reduce Motion). Defaults to 1.
  final double dampingRatio;

  /// The stiffness of that spring. Defaults to 400.
  final double stiffness;

  @override
  State<DesignPieChart> createState() => _DesignPieChartState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<DesignPieChartBuilder>.has('builder', builder))
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: EdgeInsets.zero,
        ),
      )
      ..add(
        ObjectFlagProperty<DesignChartFormat>.has('formatValue', formatValue),
      )
      ..add(
        StringProperty('semanticSummary', semanticSummary, defaultValue: null),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<int?>>.has(
          'onActiveSliceChanged',
          onActiveSliceChanged,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onShowTable', onShowTable))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('dampingRatio', dampingRatio, defaultValue: 1))
      ..add(DoubleProperty('stiffness', stiffness, defaultValue: 400))
      ..add(IntProperty('slices', slices.length))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(DoubleProperty('holeRadius', holeRadius, defaultValue: 0))
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

class _DesignPieChartState extends State<DesignPieChart>
    with SingleTickerProviderStateMixin, _Picking<DesignPieChart> {
  late final AnimationController _motion = AnimationController.unbounded(
    vsync: this,
    value: 1,
  )..addListener(() => setState(() {}));
  // The values a change springs from, as drawn.
  List<double> _from = const [];
  int? _active;
  DesignPieChartDetails? _details;

  @override
  FocusNode? get givenNode => widget.focusNode;

  @override
  bool get hasPick => _active != null;

  @override
  void clearPick() => _setActive(null, null);

  @override
  void initState() {
    super.initState();
    initPicking();
  }

  @override
  void didUpdateWidget(DesignPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    updatePicking(oldWidget.focusNode);
    if (listEquals(oldWidget.slices, widget.slices)) return;
    _from = _drawn(_motion.value, oldWidget);
    _motion.value = 0;
    unawaited(
      _motion.springTo(
        1,
        DesignMotionPolicy.of(context).spatial(
          dampingRatio: widget.dampingRatio,
          stiffness: widget.stiffness,
        ),
      ),
    );
    final a = _active;
    if (a != null && !_live(a)) {
      _active = null;
      _activeBy = null;
      _held = false;
      widget.onActiveSliceChanged?.call(null);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    disposePicking();
    super.dispose();
  }

  static double _value(DesignPieSlice s) => math.max(0, s.value);

  bool _live(int i) =>
      i >= 0 && i < widget.slices.length && _value(widget.slices[i]) > 0;

  // The values as drawn at [t] of the spring towards [w]'s; a new slice
  // grows from nothing.
  List<double> _drawn(double t, DesignPieChart w) => [
    for (var i = 0; i < w.slices.length; i++)
      t >= 1
          ? _value(w.slices[i])
          : lerpDouble(
              i < _from.length ? _from[i] : 0,
              _value(w.slices[i]),
              t,
            )!,
  ];

  // ---- Words.

  String _valueLabel(double v, RawWidgetsLocalizations l) =>
      widget.formatValue?.call(v) ?? l.formatDecimal(v);

  String _sliceLabel(int i, RawWidgetsLocalizations l) {
    final total = widget.slices.fold(0.0, (sum, s) => sum + _value(s));
    final s = widget.slices[i];
    return l.chartPointLabel(
      l.formatPercent(total == 0 ? 0 : _value(s) / total),
      s.label,
      _valueLabel(_value(s), l),
    );
  }

  String _summary(RawWidgetsLocalizations l) {
    final given = widget.semanticSummary;
    if (given != null) return given;
    final parts = [l.chartSliceCountLabel(widget.slices.length)];
    if (widget.slices.isNotEmpty) {
      final values = widget.slices.map(_value);
      parts.add(
        l.chartExtremesLabel(
          _valueLabel(values.reduce(math.min), l),
          _valueLabel(values.reduce(math.max), l),
        ),
      );
    }
    return parts.join(l.listSeparator);
  }

  // ---- Picking.

  void _setActive(int? i, PointerDeviceKind? by, {bool say = false}) {
    if (i == null) _held = false;
    final changed = i != _active;
    if (!changed && by == _activeBy) return;
    setState(() {
      _active = i;
      _activeBy = i == null ? null : by;
    });
    if (!changed) return;
    widget.onActiveSliceChanged?.call(i);
    if (say && i != null) {
      designAnnounce(
        context,
        _sliceLabel(i, RawWidgetsLocalizations.of(context)),
      );
    }
  }

  int? _sliceAt(Offset at) {
    final d = _details;
    if (d == null) return null;
    final offset = at - d.centre;
    final distance = offset.distance;
    if (distance > d.radius || distance < d.holeRadius) return null;
    // Clockwise from twelve o'clock, 0 to 2π; mirrored right to left.
    var angle = math.atan2(offset.dx, -offset.dy);
    if (angle < 0) angle += 2 * math.pi;
    if (Directionality.of(context) == TextDirection.rtl) {
      angle = (2 * math.pi - angle) % (2 * math.pi);
    }
    var start = 0.0;
    for (var i = 0; i < d.slices.length; i++) {
      final end = start + d.slices[i].share * 2 * math.pi;
      if (d.slices[i].share > 0 && angle >= start && angle < end) return i;
      start = end;
    }
    return null;
  }

  // The live slice [way] (1 after, -1 before) [from]; [from] may be one past
  // either end.
  int? _step(int from, int way) {
    for (var i = from + way; i >= 0 && i < widget.slices.length; i += way) {
      if (_live(i)) return i;
    }
    return null;
  }

  KeyEventResult _onKey(LogicalKeyboardKey key) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final a = _active;
    final n = widget.slices.length;
    int? to;
    if (key == LogicalKeyboardKey.escape) {
      if (a == null) return KeyEventResult.ignored;
      clearPick();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      final forward =
          key == LogicalKeyboardKey.arrowDown ||
          (key == LogicalKeyboardKey.arrowRight) != rtl &&
              key != LogicalKeyboardKey.arrowUp;
      final way = forward ? 1 : -1;
      to = a == null ? _step(way > 0 ? -1 : n, way) : _step(a, way) ?? a;
    } else if (key == LogicalKeyboardKey.home) {
      to = _step(-1, 1);
    } else if (key == LogicalKeyboardKey.end) {
      to = _step(n, -1);
    } else {
      return KeyEventResult.ignored;
    }
    if (to != null) _setActive(to, null, say: true);
    return KeyEventResult.handled;
  }

  DesignPieChartDetails _layout(Size size) {
    final direction = Directionality.of(context);
    final rtl = direction == TextDirection.rtl;
    final area = widget.padding
        .resolve(direction)
        .deflateRect(Offset.zero & size);
    final radius = math.max(0.0, math.min(area.width, area.height) / 2);
    final values = _drawn(_motion.value, widget);
    final total = values.fold(0.0, (sum, v) => sum + v);
    final slices = <DesignPieSliceDetails>[];
    var done = 0.0;
    for (var i = 0; i < values.length; i++) {
      final share = total == 0 ? 0.0 : values[i] / total;
      final sign = rtl ? -1 : 1;
      slices.add(
        DesignPieSliceDetails(
          label: widget.slices[i].label,
          value: values[i],
          share: share,
          startAngle: -math.pi / 2 + sign * done * 2 * math.pi,
          sweepAngle: sign * share * 2 * math.pi,
        ),
      );
      done += share;
    }
    final a = _active;
    final mid = a == null ? null : slices[a].midAngle;
    return DesignPieChartDetails(
      size: size,
      centre: area.center,
      radius: radius,
      holeRadius: radius * widget.holeRadius,
      slices: slices,
      active: a,
      activePosition: mid == null
          ? null
          : area.center + Offset(math.cos(mid), math.sin(mid)) * radius,
      activeBy: _activeBy,
      states: pickingStates,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = RawWidgetsLocalizations.of(context);
    final a = _active;
    final n = widget.slices.length;
    final next = a == null ? _step(-1, 1) : _step(a, 1);
    final previous = a == null ? _step(n, -1) : _step(a, -1);
    return picking(
      label: widget.semanticLabel,
      value: a == null ? _summary(l) : _sliceLabel(a, l),
      autofocus: widget.autofocus,
      pick: (at, kind) => _setActive(_sliceAt(at), kind),
      onKey: _onKey,
      onNext: next == null ? null : () => _setActive(next, null, say: true),
      onPrevious: previous == null
          ? null
          : () => _setActive(previous, null, say: true),
      nextValue: next == null ? null : _sliceLabel(next, l),
      previousValue: previous == null ? null : _sliceLabel(previous, l),
      onShowTable: widget.onShowTable,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 300.0;
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : width;
          final details = _details = _layout(Size(width, height));
          return SizedBox.fromSize(
            size: details.size,
            child: widget.builder(context, details),
          );
        },
      ),
    );
  }
}

/// A cell of a [DesignChartTable].
@immutable
class DesignChartTableCellDetails {
  /// A cell's details.
  const DesignChartTableCellDetails({
    required this.row,
    required this.column,
    required this.text,
    required this.isHeader,
  });

  /// Its row: 0 the headers, the data from 1.
  final int row;

  /// Its column: 0 the x values (or the slices' names).
  final int column;

  /// What it says; empty where a series has no value at that x.
  final String text;

  /// Whether it heads a column.
  final bool isHeader;
}

/// Paints a cell of a [DesignChartTable].
typedef DesignChartTableCellBuilder = Widget Function(
  BuildContext context,
  DesignChartTableCellDetails cell,
);

/// A chart's data as a table, the alternative an app shows instead of the
/// chart (a screen reader's "Show data table"): a row per x value, a
/// column per series ([DesignChartTable.new]), or a row per slice with its
/// value and share ([DesignChartTable.slices]). A screen reader reads a
/// table, its column headers and cells, a missing value as "Empty";
/// [cellBuilder] paints each cell, and the columns are as wide as their
/// widest cell.
///
/// ```dart
/// DesignChartTable(series: const [DesignChartSeries(label: 'Revenue', points: [DesignChartPoint(0, 820)])], cellBuilder: (context, cell) => Text(cell.text))
/// ```
class DesignChartTable extends StatelessWidget {
  /// A table of [series]: x values down, series across.
  const DesignChartTable({
    super.key,
    required List<DesignChartSeries> this.series,
    required this.cellBuilder,
    this.xAxis = DesignChartXAxis.linear,
    this.categories,
    this.formatX,
    this.formatY,
    this.xHeader = '',
    this.semanticLabel,
  }) : slices = null,
       valueHeader = '',
       shareHeader = '';

  /// A table of [slices]: name, value and share.
  const DesignChartTable.slices({
    super.key,
    required List<DesignPieSlice> this.slices,
    required this.cellBuilder,
    DesignChartFormat? formatValue,
    this.xHeader = '',
    this.valueHeader = '',
    this.shareHeader = '',
    this.semanticLabel,
  }) : series = null,
       xAxis = DesignChartXAxis.linear,
       categories = null,
       formatX = null,
       formatY = formatValue;

  /// The series, for [DesignChartTable.new].
  final List<DesignChartSeries>? series;

  /// The slices, for [DesignChartTable.slices].
  final List<DesignPieSlice>? slices;

  /// Paints each cell.
  final DesignChartTableCellBuilder cellBuilder;

  /// What the x values are, as [DesignChart.xAxis].
  final DesignChartXAxis xAxis;

  /// A band axis's category names, as [DesignChart.categories].
  final List<String>? categories;

  /// The x values' words, as [DesignChart.formatX].
  final DesignChartFormat? formatX;

  /// The values' words, as [DesignChart.formatY] (a slice's value, as
  /// [DesignPieChart.formatValue]).
  final DesignChartFormat? formatY;

  /// The first column's header ("Month"); empty by default.
  final String xHeader;

  /// A slices table's value column header; empty by default.
  final String valueHeader;

  /// A slices table's share column header; empty by default.
  final String shareHeader;

  /// The table's name, said first; null: none.
  final String? semanticLabel;

  List<List<String>> _rows(RawWidgetsLocalizations l) {
    String y(double v) => formatY?.call(v) ?? l.formatDecimal(v);
    final slices = this.slices;
    if (slices != null) {
      final total = slices.fold(0.0, (sum, s) => sum + math.max(0, s.value));
      return [
        [xHeader, valueHeader, shareHeader],
        for (final s in slices)
          [
            s.label,
            y(s.value),
            l.formatPercent(total == 0 ? 0 : math.max(0, s.value) / total),
          ],
      ];
    }
    final series = this.series!;
    final xs = {
      for (final s in series)
        for (final p in s.points) p.x,
    }.toList()..sort();
    final gap = _xGapOf(series);
    return [
      [xHeader, for (final s in series) s.label],
      for (final x in xs)
        [
          _xText(
            x,
            l,
            axis: xAxis,
            categories: categories,
            format: formatX,
            gap: gap,
          ),
          for (final s in series)
            switch (s.points.where((p) => p.x == x).firstOrNull?.y) {
              final double v => y(v),
              null => '',
            },
        ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = RawWidgetsLocalizations.of(context);
    final rows = _rows(l);
    Widget cell(int row, int column) {
      final text = rows[row][column];
      final header = row == 0;
      return Semantics(
        container: true,
        role: header ? SemanticsRole.columnHeader : SemanticsRole.cell,
        label: text.isEmpty && !header ? l.emptyValueLabel : text,
        child: ExcludeSemantics(
          child: cellBuilder(
            context,
            DesignChartTableCellDetails(
              row: row,
              column: column,
              text: text,
              isHeader: header,
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          for (var r = 0; r < rows.length; r++)
            TableRow(
              children: [for (var c = 0; c < rows[r].length; c++) cell(r, c)],
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<DesignChartTableCellBuilder>.has(
          'cellBuilder',
          cellBuilder,
        ),
      )
      ..add(
        EnumProperty<DesignChartXAxis>(
          'xAxis',
          xAxis,
          defaultValue: DesignChartXAxis.linear,
        ),
      )
      ..add(
        IterableProperty<String>('categories', categories, defaultValue: null),
      )
      ..add(ObjectFlagProperty<DesignChartFormat>.has('formatX', formatX))
      ..add(ObjectFlagProperty<DesignChartFormat>.has('formatY', formatY))
      ..add(StringProperty('xHeader', xHeader, defaultValue: ''))
      ..add(StringProperty('valueHeader', valueHeader, defaultValue: ''))
      ..add(StringProperty('shareHeader', shareHeader, defaultValue: ''))
      ..add(IntProperty('series', series?.length, defaultValue: null))
      ..add(IntProperty('slices', slices?.length, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}
