import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/chart_look.dart';
import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// A part of a [CivicPieChart]'s whole.
@immutable
class CivicPieSlice {
  /// A slice called [label].
  const CivicPieSlice(this.label, this.value);

  /// Its name ("Resident permits").
  final String label;

  /// Its value, 0 or more; its share is its part of all of them.
  final double value;

  @override
  bool operator ==(Object other) =>
      other is CivicPieSlice && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);
}

/// The parts of a whole, as a pie beside its key: each slice in its own
/// colour and hatch (the first solid, the second striped, …), parted from
/// the next by a gap of the page, and in the key its name, its value and
/// its share in words ("Resident permits, 1,240, 62%"), so nothing rests on
/// a colour. Below 480 of room the key stands under the pie.
///
/// A pointer, a finger or the arrow keys (one tab stop, ringed in the focus
/// yellow) pick a slice: it stands out from the rest and its row of the
/// key is marked, in the action's tint behind it and a bar at its start. Under it "Show data table" folds out the figures as a table,
/// which a screen reader's "Show data table" opens too. Keep to a few
/// slices; a whole of many small parts is a table or a [CivicBarChart].
///
/// Reads [CivicStyle]'s foreground (the key's words): its `style:`, then
/// [CivicThemeData.pieChartStyle]. The slices' colours and hatches are the
/// look's.
///
/// ```dart
/// CivicPieChart(
///   title: 'Permits by kind',
///   slices: const [
///     CivicPieSlice('Resident', 1240),
///     CivicPieSlice('Visitor', 610),
///     CivicPieSlice('Business', 150),
///   ],
/// )
/// ```
class CivicPieChart extends StatefulWidget {
  /// A pie chart.
  const CivicPieChart({
    super.key,
    required this.title,
    required this.slices,
    this.summary,
    this.valueLabel,
    this.labelHeader,
    this.valueHeader,
    this.shareHeader,
    this.size = 200,
    this.focusNode,
    this.style,
  });

  /// Its name, over it and said first.
  final String title;

  /// What it shows, in a sentence under its name.
  final String? summary;

  /// The slices, clockwise from twelve o'clock (the other way right to
  /// left).
  final List<CivicPieSlice> slices;

  /// A value in words ("€1,240"); null: the reader's numbers.
  final String Function(double value)? valueLabel;

  /// The table's headers ("Kind", "Permits", "Share"); null: none.
  final String? labelHeader;

  /// The table's value column's header.
  final String? valueHeader;

  /// The table's share column's header.
  final String? shareHeader;

  /// The pie's size across, at the reader's text size of 1.
  final double size;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// Overrides for this chart's look.
  final CivicStyle? style;

  @override
  State<CivicPieChart> createState() => _CivicPieChartState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('summary', summary, defaultValue: null))
      ..add(IntProperty('slices', slices.length))
      ..add(
        ObjectFlagProperty<String Function(double value)>.has(
          'valueLabel',
          valueLabel,
        ),
      )
      ..add(StringProperty('labelHeader', labelHeader, defaultValue: null))
      ..add(StringProperty('valueHeader', valueHeader, defaultValue: null))
      ..add(StringProperty('shareHeader', shareHeader, defaultValue: null))
      ..add(DoubleProperty('size', size, defaultValue: 200))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicPieChartState extends State<CivicPieChart> {
  int? _active;

  @override
  Widget build(BuildContext context) {
    final CivicPieChart(
      :title,
      :summary,
      :slices,
      :valueLabel,
      :labelHeader,
      :valueHeader,
      :shareHeader,
      :size,
      :focusNode,
      :style,
    ) = widget;
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf([style, t.pieChartStyle], const {});
    final l = DesignLocalizations.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    String say(double v) => valueLabel?.call(v) ?? l.formatDecimal(v);
    final total = slices.fold(0.0, (sum, s) => sum + math.max(0, s.value));
    String share(double v) =>
        l.formatPercent(total == 0 ? 0 : math.max(0, v) / total);
    final looks = [
      for (var i = 0; i < slices.length; i++) CivicSeriesLook.of(t, i),
    ];
    final data = [
      for (final s in slices) DesignPieSlice(label: s.label, value: s.value),
    ];
    final across = size * scaler.scale(1).clamp(1.0, 1.5);
    Widget pie(VoidCallback showTable) => SizedBox.square(
      dimension: across,
      child: DesignPieChart(
        slices: data,
        semanticLabel: title,
        formatValue: say,
        focusNode: focusNode,
        onShowTable: showTable,
        onActiveSliceChanged: (i) {
          if (mounted && i != _active) setState(() => _active = i);
        },
        padding: const EdgeInsets.all(CivicSpacing.s8),
        builder: (context, pie) => CivicChartFocus(
          focused: pie.states.contains(WidgetState.focused),
          child: CustomPaint(
            size: pie.size,
            painter: _PiePainter(pie: pie, looks: looks, t: t),
          ),
        ),
      ),
    );
    final words = text.body.copyWith(
      color: so.foreground ?? t.textPrimary,
      fontFeatures: const [ui.FontFeature.tabularFigures()],
    );
    final key = ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: CivicSpacing.s12,
        children: [
          for (final (i, s) in slices.indexed)
            _KeyRow(
              marked: _active == i,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: CivicSeriesSample(look: looks[i], line: false),
                ),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: s.label,
                          style: TextStyle(fontWeight: text.label.fontWeight),
                        ),
                        TextSpan(
                          text:
                              '${l.listSeparator}${say(s.value)}'
                              '${l.listSeparator}${share(s.value)}',
                        ),
                      ],
                    ),
                    style: words,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
    return CivicChartFrame(
      title: title,
      summary: summary,
      chart: (showTable) => LayoutBuilder(
        builder: (context, box) => box.maxWidth < 480
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: CivicSpacing.s16,
                children: [
                  Center(child: pie(showTable)),
                  key,
                ],
              )
            : Row(
                spacing: CivicSpacing.s32,
                children: [
                  pie(showTable),
                  Flexible(child: key),
                ],
              ),
      ),
      table: CivicChartTableView(
        label: title,
        headers: [labelHeader ?? '', valueHeader ?? '', shareHeader ?? ''],
        rows: [
          for (final s in slices) [s.label, say(s.value), share(s.value)],
        ],
        missing: l.emptyValueLabel,
      ),
    );
  }
}

/// A row of the key: the slice's sample and words, marked while its slice
/// is picked (the action's tint behind it, a bar at its start).
class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.marked, required this.children});

  final bool marked;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return CivicSpringValue(
      value: marked ? 1 : 0,
      spring: CivicMotion.state,
      effects: true,
      builder: (context, on, _) {
        final a = on.clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(
              t.secondaryFill.withValues(alpha: 0),
              t.secondaryFill,
              a,
            ),
            border: BorderDirectional(
              start: BorderSide(
                color: t.action.withValues(alpha: a),
                width: CivicMetrics.bar,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              CivicSpacing.s8,
              CivicSpacing.s4,
              CivicSpacing.s8,
              CivicSpacing.s4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CivicSpacing.s12,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.pie, required this.looks, required this.t});

  final DesignPieChartDetails pie;
  final List<CivicSeriesLook> looks;
  final CivicThemeData t;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = pie.centre;
    for (final (i, s) in pie.slices.indexed) {
      if (s.sweepAngle.abs() < 0.0001) continue;
      // The picked slice stands out from the rest along its middle.
      final out = pie.active == i ? 6.0 : 0.0;
      final shift = Offset(math.cos(s.midAngle), math.sin(s.midAngle)) * out;
      final c = centre + shift;
      final box = Rect.fromCircle(center: c, radius: pie.radius);
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(box, s.startAngle, s.sweepAngle, false)
        ..close();
      civicFillHatched(
        canvas,
        path,
        looks[i].color,
        looks[i].hatch,
        t.background,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = t.background,
      );
    }
  }

  @override
  bool shouldRepaint(_PiePainter old) => old.pie != pie || old.t != t;
}
