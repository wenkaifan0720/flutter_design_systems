// Plain paintings of ui_core's value behaviours (0.3.0): a date wheel, a
// date field, a time field, a number field, a rating and charts (a line
// over time, bars, a donut, the data as a table). Every
// pixel is the example's own; the behaviours give it the keys, the states,
// the springs and what a screen reader hears. No Material, no Cupertino.
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

const Color _ink = Color(0xFF1F2328);
const Color _muted = Color(0xFF8C959F);
const Color _line = Color(0xFFD0D7DE);
const Color _accent = Color(0xFF0969DA);
const Color _band = Color(0xFFEFF2F5);
const Color _danger = Color(0xFFCF222E);
// One colour a series (or a slice).
const List<Color> _series = [
  Color(0xFF0969DA),
  Color(0xFFBF8700),
  Color(0xFF1A7F37),
  Color(0xFF8250DF),
];

final List<DesignChartSeries> _visits = [
  DesignChartSeries(
    label: 'Web',
    points: [
      for (final (m, v) in [
        (1, 820),
        (2, 1240),
        (3, 1640),
        (4, 1100),
        (5, 1380),
        (6, 1500),
      ])
        DesignChartPoint.time(DateTime(2026, m), v.toDouble()),
    ],
  ),
  DesignChartSeries(
    label: 'App',
    points: [
      for (final (m, v) in [
        (1, 300),
        (2, 420),
        (3, 610),
        (4, 700),
        (5, 980),
        (6, 1210),
      ])
        DesignChartPoint.time(DateTime(2026, m), v.toDouble()),
    ],
  ),
];

const List<DesignChartSeries> _orders = [
  DesignChartSeries(
    label: 'Orders',
    points: [
      DesignChartPoint(0, 42),
      DesignChartPoint(1, 58),
      DesignChartPoint(2, 37),
      DesignChartPoint(3, 64),
    ],
  ),
];

const List<DesignPieSlice> _spending = [
  DesignPieSlice(label: 'Rent', value: 1200),
  DesignPieSlice(label: 'Food', value: 600),
  DesignPieSlice(label: 'Travel', value: 400),
  DesignPieSlice(label: 'Fun', value: 200),
];

const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// The value behaviours, each painted plainly.
class ValuesPage extends StatefulWidget {
  /// The page.
  const ValuesPage({super.key});

  @override
  State<ValuesPage> createState() => _ValuesPageState();
}

class _ValuesPageState extends State<ValuesPage> {
  // A date as a wheel: month, day, year; the year starts at 2020.
  List<int> _date = const [10, 15, 6];
  DateTime? _due;
  DesignTimeOfDay? _start = const DesignTimeOfDay(hour: 9, minute: 30);
  double? _guests = 2;
  double _stars = 3.5;
  // The visits as a table (a screen reader's "Show data table").
  bool _visitsTable = false;

  static List<DesignWheelColumn> _dateColumns(List<int> s) => [
    DesignWheelColumn(
      itemCount: 12,
      itemLabel: (i) => _months[i],
      semanticLabel: 'Month',
    ),
    DesignWheelColumn(
      // The day count follows the month and the year.
      itemCount: DateTime(2020 + s[2], s[0] + 2, 0).day,
      itemLabel: (i) => '${i + 1}',
      semanticLabel: 'Day',
    ),
    DesignWheelColumn(
      itemCount: 11,
      itemLabel: (i) => '${2020 + i}',
      semanticLabel: 'Year',
    ),
  ];

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFFFFFFF),
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Values',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          const Text('Date'),
          const SizedBox(height: 6),
          SizedBox(
            width: 360,
            child: DesignWheelPicker(
              semanticLabel: 'Date',
              columns: _dateColumns,
              selection: _date,
              onChanged: (next) => setState(() => _date = next),
              itemExtent: MediaQuery.textScalerOf(context).scale(36),
              // A band behind the centre row, a ring when the keys are on it.
              columnBuilder: (context, details, wheel) => Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: details.itemExtent,
                    decoration: BoxDecoration(
                      color: _band,
                      borderRadius: BorderRadius.circular(6),
                      border: details.states.contains(WidgetState.focused)
                          ? Border.all(color: _accent, width: 2)
                          : null,
                    ),
                  ),
                  wheel,
                ],
              ),
              itemBuilder: (context, details) => Center(
                child: Text(
                  details.label,
                  style: TextStyle(
                    color: details.enabled ? _ink : _muted,
                    fontWeight: details.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: _line),
          const SizedBox(height: 24),
          // The field says its own name.
          const ExcludeSemantics(child: Text('Due date')),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DesignDateField(
              semanticLabel: 'Due date',
              value: _due,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030, 12, 31),
              onChanged: (day) => setState(() => _due = day),
              segmentBuilder: _segment,
              frameBuilder: _frame,
            ),
          ),
          const SizedBox(height: 24),
          // The field says its own name.
          const ExcludeSemantics(child: Text('Start time')),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DesignTimeField(
              semanticLabel: 'Start time',
              value: _start,
              onChanged: (time) => setState(() => _start = time),
              segmentBuilder: _segment,
              frameBuilder: _frame,
            ),
          ),
          const SizedBox(height: 24),
          const ExcludeSemantics(child: Text('Guests')),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DesignNumberField(
              semanticLabel: 'Guests',
              value: _guests,
              min: 1,
              max: 12,
              onChanged: (n) => setState(() => _guests = n),
              fieldBuilder: _number,
              buttonBuilder: _stepper,
              layoutBuilder: _numberBox,
            ),
          ),
          const SizedBox(height: 24),
          const ExcludeSemantics(child: Text('Stars')),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DesignRating(
              semanticLabel: 'Stars',
              value: _stars,
              allowHalf: true,
              onChanged: (v) => setState(() => _stars = v),
              itemBuilder: _star,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: ExcludeSemantics(child: Text('Visits'))),
              _Toggle(
                label: _visitsTable ? 'Show chart' : 'Show data table',
                onTap: () => setState(() => _visitsTable = !_visitsTable),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_visitsTable)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DesignChartTable(
                semanticLabel: 'Visits by month',
                xHeader: 'Month',
                xAxis: DesignChartXAxis.time,
                series: _visits,
                cellBuilder: _cell,
              ),
            )
          else
            SizedBox(
              height: 200,
              child: DesignChart(
                semanticLabel: 'Visits by month',
                series: _visits,
                xAxis: DesignChartXAxis.time,
                padding: const EdgeInsetsDirectional.fromSTEB(44, 12, 12, 24),
                onShowTable: () => setState(() => _visitsTable = true),
                builder: _lines,
              ),
            ),
          const SizedBox(height: 24),
          const ExcludeSemantics(child: Text('Orders')),
          const SizedBox(height: 6),
          const SizedBox(
            height: 180,
            child: DesignChart(
              semanticLabel: 'Orders by quarter',
              series: _orders,
              xAxis: DesignChartXAxis.band,
              categories: ['Q1', 'Q2', 'Q3', 'Q4'],
              padding: EdgeInsetsDirectional.fromSTEB(36, 12, 12, 24),
              builder: _bars,
            ),
          ),
          const SizedBox(height: 24),
          const ExcludeSemantics(child: Text('Spending')),
          const SizedBox(height: 6),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 200,
              height: 200,
              child: DesignPieChart(
                semanticLabel: 'Spending',
                slices: _spending,
                holeRadius: 0.6,
                builder: _donut,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// A segment: its text on a tint while it has the focus, its placeholder
// muted; a tap target at the floor.
Widget _segment(BuildContext context, DesignDateSegmentDetails details) {
  final focused = details.states.contains(WidgetState.focused);
  return DesignTapTarget(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: focused ? _accent : null,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        details.text,
        style: TextStyle(
          color: focused
              ? const Color(0xFFFFFFFF)
              : details.isPlaceholder
              ? _muted
              : details.states.contains(WidgetState.error)
              ? _danger
              : _ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}

// The field's box: a line, the accent while a segment has the focus, red
// out of range.
Widget _frame(BuildContext context, Set<WidgetState> states, Widget segments) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: states.contains(WidgetState.error)
              ? _danger
              : states.contains(WidgetState.focused)
              ? _accent
              : _line,
          width: states.contains(WidgetState.focused) ? 2 : 1,
        ),
      ),
      child: segments,
    );

// A number: a box with the input between a minus and a plus; the buttons
// are no tab stops and say nothing (the field itself is adjustable).
Widget _number(BuildContext context, DesignNumberFieldDetails field) =>
    SizedBox(
      width: 56,
      child: EditableText(
        controller: field.controller,
        focusNode: field.focusNode,
        keyboardType: field.keyboardType,
        inputFormatters: field.inputFormatters,
        readOnly: field.states.contains(WidgetState.disabled),
        onEditingComplete: field.onEditingComplete,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: field.states.contains(WidgetState.error) ? _danger : _ink,
          fontSize: 14,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        cursorColor: _accent,
        backgroundCursorColor: _muted,
      ),
    );

Widget _stepper(BuildContext context, DesignNumberFieldButtonDetails button) {
  final off = button.states.contains(WidgetState.disabled);
  return DesignTapTarget(
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: button.states.contains(WidgetState.pressed) ? _band : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          button.isIncrement ? '+' : '\u2212',
          style: TextStyle(fontSize: 18, color: off ? _muted : _accent),
        ),
      ),
    ),
  );
}

Widget _numberBox(
  BuildContext context,
  Widget field,
  Widget decrement,
  Widget increment,
) => Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: _line),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [decrement, field, increment],
  ),
);

// A star: an outline, filled as far as its fill reaches (from the start
// edge), darker while it previews; a tap target at the floor.
Widget _star(BuildContext context, DesignRatingItemDetails item) {
  final color = item.isPreview
      ? const Color(0xFFBF8700)
      : const Color(0xFFD4A72C);
  const style = TextStyle(fontSize: 28, height: 1);
  // The keys' focus: a line under every star.
  return Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: item.states.contains(WidgetState.focused)
              ? _accent
              : const Color(0x00000000),
          width: 2,
        ),
      ),
    ),
    child: Center(
      child: Stack(
        children: [
          Text('\u2606', style: style.copyWith(color: _muted)),
          ClipRect(
            clipper: _Fill(item.fill, Directionality.of(context)),
            child: Text('\u2605', style: style.copyWith(color: color)),
          ),
        ],
      ),
    ),
  );
}

class _Fill extends CustomClipper<Rect> {
  const _Fill(this.fill, this.direction);

  final double fill;
  final TextDirection direction;

  @override
  Rect getClip(Size size) {
    final width = size.width * fill;
    return direction == TextDirection.rtl
        ? Rect.fromLTWH(size.width - width, 0, width, size.height)
        : Rect.fromLTWH(0, 0, width, size.height);
  }

  @override
  bool shouldReclip(_Fill old) =>
      old.fill != fill || old.direction != direction;
}

// A plain tappable word: a button to a screen reader, a tap target at the
// floor.
class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DesignPressable(
    onPressed: onTap,
    semanticLabel: label,
    excludeSemantics: true,
    builder: (context, states, _) => DesignTapTarget(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: states.contains(WidgetState.pressed) ? _band : null,
          border: Border.all(
            color: states.contains(WidgetState.focused)
                ? _accent
                : const Color(0x00000000),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(label, style: const TextStyle(color: _accent)),
        ),
      ),
    ),
  );
}

// A chart's frame: a ring while the keys are on it.
Widget _ring(DesignChartDetails chart, Widget child) => DecoratedBox(
  position: DecorationPosition.foreground,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(6),
    border: chart.states.contains(WidgetState.focused)
        ? Border.all(color: _accent, width: 2)
        : null,
  ),
  child: child,
);

// The y ticks' labels down the start edge, the x ticks' along the bottom.
List<Widget> _axisLabels(DesignChartDetails chart) => [
  for (final tick in chart.yTicks)
    PositionedDirectional(
      start: 0,
      width: chart.plotArea.width > 0 ? 38 : 0,
      top: tick.position - 8,
      child: Text(
        tick.label,
        textAlign: TextAlign.end,
        style: const TextStyle(fontSize: 11, color: _muted),
      ),
    ),
  for (final tick in chart.xTicks)
    Positioned(
      left: tick.position - 30,
      width: 60,
      top: chart.plotArea.bottom + 4,
      child: Text(
        tick.label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: _muted),
      ),
    ),
];

// The picked point's readout: its series and value, above it (clear of a
// finger when a finger picked it).
Widget _readout(BuildContext context, DesignChartDetails chart) {
  final active = chart.active!;
  final at = chart.activePosition!;
  final series = chart.series[active.series];
  final value = DesignLocalizations.of(context)
      .formatDecimal(series.points[active.index].y!.round());
  final lift = chart.activeBy == PointerDeviceKind.touch ? 64.0 : 36.0;
  return Positioned(
    left: (at.dx - 50).clamp(0, math.max(0, chart.size.width - 100)),
    top: math.max(0, at.dy - lift),
    width: 100,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${series.label} $value',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Color(0xFFFFFFFF)),
      ),
    ),
  );
}

// Lines: grid lines at the y ticks, a line a series (broken at a gap), a
// dot and a rule at the picked point.
Widget _lines(BuildContext context, DesignChartDetails chart) => _ring(
  chart,
  Stack(
    children: [
      Positioned.fill(child: CustomPaint(painter: _LinesPainter(chart))),
      ..._axisLabels(chart),
      if (chart.active != null) _readout(context, chart),
    ],
  ),
);

class _LinesPainter extends CustomPainter {
  _LinesPainter(this.chart);

  final DesignChartDetails chart;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = chart.plotArea;
    final grid = Paint()
      ..color = _line
      ..strokeWidth = 1;
    for (final tick in chart.yTicks) {
      canvas.drawLine(
        Offset(plot.left, tick.position),
        Offset(plot.right, tick.position),
        grid,
      );
    }
    for (var i = 0; i < chart.series.length; i++) {
      final path = Path();
      var drawing = false;
      for (final point in chart.series[i].points) {
        final y = point.y;
        if (y == null) {
          drawing = false;
          continue;
        }
        final at = Offset(chart.x.map(point.x), chart.y.map(y));
        drawing ? path.lineTo(at.dx, at.dy) : path.moveTo(at.dx, at.dy);
        drawing = true;
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _series[i % _series.length],
      );
    }
    final active = chart.active;
    final at = chart.activePosition;
    if (active == null || at == null) return;
    canvas
      ..drawLine(Offset(at.dx, plot.top), Offset(at.dx, plot.bottom), grid)
      ..drawCircle(
        at,
        4,
        Paint()..color = _series[active.series % _series.length],
      );
  }

  @override
  bool shouldRepaint(_LinesPainter oldDelegate) => true;
}

// Bars: a bar a category, from 0 up, side by side when there are several
// series; the picked one darker.
Widget _bars(BuildContext context, DesignChartDetails chart) => _ring(
  chart,
  Stack(
    children: [
      Positioned.fill(child: CustomPaint(painter: _BarsPainter(chart))),
      ..._axisLabels(chart),
      if (chart.active != null) _readout(context, chart),
    ],
  ),
);

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.chart);

  final DesignChartDetails chart;

  @override
  void paint(Canvas canvas, Size size) {
    final x = chart.x as DesignBandScale;
    final width = x.bandwidth / math.max(1, chart.series.length);
    final base = chart.y.map(0);
    for (var i = 0; i < chart.series.length; i++) {
      final points = chart.series[i].points;
      for (var j = 0; j < points.length; j++) {
        final y = points[j].y;
        if (y == null) continue;
        final left = x.map(points[j].x) - x.bandwidth / 2 + width * i;
        final picked = chart.active == DesignChartPointRef(i, j);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTRB(left + 1, chart.y.map(y), left + width - 1, base),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          Paint()
            ..color = _series[i % _series.length].withValues(
              alpha: picked || chart.active == null ? 1 : 0.6,
            ),
        );
      }
    }
    canvas.drawLine(
      Offset(chart.plotArea.left, base),
      Offset(chart.plotArea.right, base),
      Paint()..color = _muted,
    );
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) => true;
}

// A donut: an arc a slice, the picked one wider, its name and share in the
// hole.
Widget _donut(BuildContext context, DesignPieChartDetails pie) {
  final active = pie.active;
  final l = DesignLocalizations.of(context);
  return Stack(
    children: [
      Positioned.fill(child: CustomPaint(painter: _DonutPainter(pie))),
      if (active != null)
        Center(
          child: Text(
            '${pie.slices[active].label}\n'
            '${l.formatPercent(pie.slices[active].share)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _ink),
          ),
        ),
      if (pie.states.contains(WidgetState.focused))
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accent, width: 2),
            ),
          ),
        ),
    ],
  );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.pie);

  final DesignPieChartDetails pie;

  @override
  void paint(Canvas canvas, Size size) {
    final band = pie.radius - pie.holeRadius;
    final middle = pie.holeRadius + band / 2;
    for (var i = 0; i < pie.slices.length; i++) {
      final slice = pie.slices[i];
      final picked = pie.active == i;
      canvas.drawArc(
        Rect.fromCircle(center: pie.centre, radius: middle),
        slice.startAngle,
        slice.sweepAngle,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = picked ? band : band * 0.8
          ..color = _series[i % _series.length],
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) => true;
}

// A table cell: a header bold, a figure at the end.
Widget _cell(BuildContext context, DesignChartTableCellDetails cell) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  child: Text(
    cell.text,
    textAlign: cell.column == 0 ? TextAlign.start : TextAlign.end,
    style: TextStyle(
      fontWeight: cell.isHeader ? FontWeight.w600 : FontWeight.w400,
      color: _ink,
    ),
  ),
);
