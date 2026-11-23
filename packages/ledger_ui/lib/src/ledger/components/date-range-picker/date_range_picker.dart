/// A span of days chosen on Ledger's month grid, over ui_core's
/// [RawCalendarDatePicker].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/face.dart';
import '../../theme.dart';
import '../icon-button/icon_button.dart';

/// A span of days, its end null while half chosen: ui_core's
/// [RawDateRange].
typedef LedgerDateRange = RawDateRange;

/// A span of days (a statement's period, a trip's nights) chosen on the
/// month grid: over it the span read as a ledger heads a period, FROM and
/// TO in the small capitals over each date in the serif, the nights between
/// in the mono; then the month in the bar's title with its two ways on the
/// reading end, the weekdays in the mono's capitals and the days in their
/// 44 cells. The first press sets the start, the next the end: each end a
/// disc of the ink, the days between on a band of the darker paper running
/// from one to the other, today ringed; a pointer over a day draws where
/// the span would end in the band's lighter tint. The keyboard walks the
/// days (arrows, Page Up and Down for months, Home and End for the week),
/// Enter takes one. [months] shows two side by side on a desk. A screen
/// reader hears each day whole, chosen or in the span.
///
/// ```dart
/// LedgerDateRangePicker(firstDate: DateTime(2026), lastDate: DateTime(2027), value: LedgerDateRange(DateTime(2026, 10, 12), DateTime(2026, 10, 19)), onChanged: (r) {})
/// ```
class LedgerDateRangePicker extends StatefulWidget {
  /// A span picker between [firstDate] and [lastDate].
  const LedgerDateRangePicker({
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.value,
    this.currentDate,
    this.months = 1,
    this.unit = 'nights',
    super.key,
  }) : assert(months >= 1);

  /// The first day it offers.
  final DateTime firstDate;

  /// The last day it offers.
  final DateTime lastDate;

  /// The span chosen; its end null while half chosen.
  final LedgerDateRange? value;

  /// Called with the span as each end is chosen.
  final ValueChanged<LedgerDateRange>? onChanged;

  /// The day ringed as today; null: the clock's.
  final DateTime? currentDate;

  /// How many months show at once.
  final int months;

  /// What the days between are counted as ("nights", "days").
  final String unit;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('firstDate', firstDate))
      ..add(DiagnosticsProperty<DateTime>('lastDate', lastDate))
      ..add(
        DiagnosticsProperty<LedgerDateRange>(
          'value',
          value,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<LedgerDateRange>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(
        DiagnosticsProperty<DateTime>(
          'currentDate',
          currentDate,
          defaultValue: null,
        ),
      )
      ..add(IntProperty('months', months))
      ..add(StringProperty('unit', unit));
  }

  @override
  State<LedgerDateRangePicker> createState() => _LedgerDateRangePickerState();
}

class _LedgerDateRangePickerState extends State<LedgerDateRangePicker> {
  late RawCalendarController _controller = _make();

  RawCalendarController _make() => RawCalendarController(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    mode: RawCalendarMode.range,
    selectedRange: widget.value,
    currentDate: widget.currentDate,
  );

  @override
  void didUpdateWidget(LedgerDateRangePicker old) {
    super.didUpdateWidget(old);
    final held = _controller.selectedRange;
    final same =
        held?.start == widget.value?.start && held?.end == widget.value?.end;
    if (!same ||
        old.firstDate != widget.firstDate ||
        old.lastDate != widget.lastDate) {
      _controller.dispose();
      _controller = _make();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _chosen(DateTime _) {
    final range = _controller.selectedRange;
    if (range != null) widget.onChanged?.call(range);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = RawWidgetsLocalizations.of(context);
    final range = _controller.selectedRange;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Span(range: range, unit: widget.unit),
        const SizedBox(height: LedgerSpacing.s16),
        RawCalendarDatePicker(
          controller: _controller,
          months: widget.months,
          minDayWidth: LedgerLayout.minHitTarget,
          onChanged: widget.onChanged == null ? null : _chosen,
          monthsBuilder: (context, months) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: LedgerSpacing.s24,
            children: [for (final m in months) Expanded(child: m)],
          ),
          headerBuilder: (context, header) => Padding(
            padding: const EdgeInsets.only(bottom: LedgerSpacing.s12),
            child: Row(
              spacing: LedgerSpacing.s8,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      header.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.barTitle.colored(t.textPrimary),
                    ),
                  ),
                ),
                LedgerIconButton.outlined(
                  LucideIcons.chevronLeft,
                  semanticLabel: words.previousMonthTooltip,
                  size: LedgerIconButtonSize.small,
                  tapAlignment: AlignmentDirectional.centerEnd,
                  onPressed: header.previous,
                ),
                LedgerIconButton.outlined(
                  LucideIcons.chevronRight,
                  semanticLabel: words.nextMonthTooltip,
                  size: LedgerIconButtonSize.small,
                  tapAlignment: AlignmentDirectional.centerEnd,
                  onPressed: header.next,
                ),
              ],
            ),
          ),
          weekdayBuilder: (context, weekday, label) => Padding(
            padding: const EdgeInsets.only(bottom: LedgerSpacing.s4),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  style: t.tag.colored(t.textTertiary),
                ),
              ),
            ),
          ),
          dayBuilder: (context, day, states) => _Day(day: day, states: states),
        ),
      ],
    );
  }
}

/// The span read over the grid: FROM and TO over each date, the count.
class _Span extends StatelessWidget {
  const _Span({required this.range, required this.unit});

  final LedgerDateRange? range;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final r = range;
    Widget end(String label, DateTime? d) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: LedgerSpacing.s4,
        children: [
          Text(label.toUpperCase(), style: t.label.colored(t.textSecondary)),
          LedgerFace(
            style: LedgerFaceStyle(
              ink: d == null ? t.textTertiary : t.textPrimary,
            ),
            builder: (context, s, _) => Text(
              d == null ? '—' : LedgerFormat.date(d, showWeekday: true),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.figureSmall.colored(s.ink),
            ),
          ),
        ],
      ),
    );
    final nights = r?.end?.difference(r.start).inDays;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.only(bottom: LedgerSpacing.s12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.hairline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: LedgerSpacing.s16,
          children: [
            end('From', r?.start),
            end('To', r?.end),
            if (nights != null)
              Text(
                '$nights $unit'.toUpperCase(),
                style: t.meta.colored(t.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

/// One day: its figure in the mono in a 36 mark, the span's band behind.
class _Day extends StatelessWidget {
  const _Day({required this.day, required this.states});

  final RawCalendarDayDetails day;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final end = day.isRangeStart || day.isRangeEnd;
    final hovered = states.contains(WidgetState.hovered);
    final focused = states.contains(WidgetState.focused);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The band runs from the start's middle to the end's: a half band on
    // each end day, the whole cell between.
    final banded = day.inRange || day.inPreview;
    final bandColor = day.inRange ? t.selectedFill : t.hairline;
    final single = day.isRangeStart && day.isRangeEnd;
    Widget band(double mark) {
      if (!banded || single || !day.inMonth) return const SizedBox.shrink();
      final startHalf = day.isRangeStart;
      final endHalf = day.isRangeEnd || day.isPreviewEnd;
      return Align(
        alignment: startHalf
            ? (rtl ? Alignment.centerLeft : Alignment.centerRight)
            : endHalf
            ? (rtl ? Alignment.centerRight : Alignment.centerLeft)
            : Alignment.center,
        child: FractionallySizedBox(
          widthFactor: startHalf || endHalf ? .5 : 1,
          child: Container(height: mark, color: bandColor),
        ),
      );
    }

    final ink = !day.enabled
        ? t.textFaint
        : end
        ? t.textInverse
        : day.inMonth
        ? t.textPrimary
        : t.textTertiary;
    return LayoutBuilder(
      builder: (context, box) {
        final mark = LedgerChromeMetrics.calendarDayDiameter(
          box.maxWidth,
          MediaQuery.textScalerOf(context).scale(t.amount.fontSize!),
        );
        return SizedBox(
          height: (mark + 4).clamp(LedgerLayout.minHitTarget, double.infinity),
          child: Stack(
            alignment: Alignment.center,
            children: [
              band(mark),
              LedgerFace(
                style: LedgerFaceStyle(
                  ink: ink,
                  ground: BoxDecoration(
                    shape: BoxShape.circle,
                    color: end
                        ? t.surfaceInverse
                        : hovered && day.enabled
                        ? t.selectedFill
                        : null,
                    border: focused
                        ? Border.all(color: t.textPrimary, width: _ring)
                        : day.isToday && !end
                        ? Border.all(color: t.textPrimary, width: _ring)
                        : null,
                  ),
                ),
                builder: (context, s, _) => Container(
                  width: mark,
                  height: mark,
                  alignment: Alignment.center,
                  decoration: s.ground,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${day.date.day}',
                      maxLines: 1,
                      style: t.amount.colored(s.ink),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const double _ring = LedgerChromeMetrics.focusRing;
}
