import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:ui_core/ui_core.dart';

import 'button.dart';
import 'face.dart';
import 'lists.dart';
import 'theme.dart';

/// A date chosen from a month that opens under the field: a [RawPopover]
/// round a [RawButton] on the field's face, holding ui_core's
/// [RawCalendarDatePicker]. A month can't shrink and scroll as a list does,
/// so it opens where the whole of it fits ([RawPopoverFit.whole]), and its
/// chosen day takes the focus as it opens.
///
/// ```dart
/// TendDateField(labelText: 'Due', value: due, firstDate: DateTime(2026), lastDate: DateTime(2027), onChanged: (day) => due = day)
/// ```
class TendDateField extends StatefulWidget {
  /// A field labelled [labelText] holding [value].
  const TendDateField({
    super.key,
    required this.labelText,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  /// What the date is for, above the field.
  final String labelText;

  /// The day chosen; null: none yet.
  final DateTime? value;

  /// The earliest day offered.
  final DateTime firstDate;

  /// The latest day offered.
  final DateTime lastDate;

  /// Called with the day chosen; null turns the field off.
  final ValueChanged<DateTime>? onChanged;

  @override
  State<TendDateField> createState() => _TendDateFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(DiagnosticsProperty<DateTime>('value', value, defaultValue: null));
  }
}

class _TendDateFieldState extends State<TendDateField> {
  // The month's model: the field makes it, keeps it and disposes it.
  late RawCalendarController _calendar = _newCalendar();

  RawCalendarController _newCalendar() => RawCalendarController(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    selectedDate: widget.value,
  );

  static bool _sameDay(DateTime? a, DateTime? b) =>
      a?.year == b?.year && a?.month == b?.month && a?.day == b?.day;

  @override
  void didUpdateWidget(TendDateField old) {
    super.didUpdateWidget(old);
    if (widget.firstDate != old.firstDate || widget.lastDate != old.lastDate) {
      _calendar.dispose();
      _calendar = _newCalendar();
    } else if (!_sameDay(widget.value, _calendar.selectedDate)) {
      final value = widget.value;
      value == null ? _calendar.clear() : _calendar.select(value);
    }
  }

  @override
  void dispose() {
    _calendar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TendTheme.of(context);
    final words = RawWidgetsLocalizations.of(context);
    final change = widget.onChanged;
    final value = widget.value;
    final shown = value == null ? null : words.formatMediumDate(value);
    return RawInputDecorator(
      labelText: widget.labelText,
      enabled: change != null,
      builder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parts.label != null)
            DefaultTextStyle(
              style: theme.label.copyWith(color: theme.colors.ink),
              child: parts.label!,
            ),
          const SizedBox(height: 6),
          parts.control,
        ],
      ),
      child: RawPopover(
        semanticLabel: widget.labelText,
        // A month opens where the whole of it fits: below while below
        // holds it, else above. It keeps its own width, not its field's.
        placement: const RawPopoverPlacement(
          fit: RawPopoverFit.whole,
          matchAnchorWidth: false,
        ),
        anchorBuilder: (context, anchor) => TendFieldTrigger(
          value: shown,
          open: anchor.isOpen,
          onPressed: change == null ? null : anchor.toggle,
        ),
        overlayBuilder: (context, info) => TendListSurface(
          // Whole while a side holds it; where neither does, it takes the
          // room there is and scrolls.
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: info.maxSize.height),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  // Seven days at the touch floor, on every screen.
                  width: 7 * _day,
                  child: RawCalendarDatePicker(
                    controller: _calendar,
                    // The chosen day takes the focus as the month opens, from
                    // the keys or a pointer, ahead of the month's arrows.
                    autofocus: true,
                    onChanged: change == null
                        ? null
                        : (day) {
                            info.close();
                            change(day);
                          },
                    headerBuilder: (context, header) => Row(
                      children: [
                        TendIconButton(
                          icon: Icons.chevron_left,
                          semanticLabel: words.previousMonthTooltip,
                          onPressed: header.previous,
                        ),
                        Expanded(
                          child: Text(
                            header.label,
                            textAlign: TextAlign.center,
                            style: theme.label.copyWith(
                              color: theme.colors.ink,
                            ),
                          ),
                        ),
                        TendIconButton(
                          icon: Icons.chevron_right,
                          semanticLabel: words.nextMonthTooltip,
                          onPressed: header.next,
                        ),
                      ],
                    ),
                    dayBuilder: (context, day, states) =>
                        _tendDay(theme, day, states),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const double _day = 44;

/// A day of the month: a disc filled in ink when chosen (a state, so not in
/// the accent the screen's main action wears), ringed when it is today,
/// its rule heavier under the keyboard.
Widget _tendDay(
  TendThemeData theme,
  RawCalendarDayDetails day,
  Set<WidgetState> states,
) {
  final c = theme.colors;
  final chosen = states.contains(WidgetState.selected);
  final focused = states.contains(WidgetState.focused);
  final quiet = states.contains(WidgetState.disabled) || !day.inMonth;
  return SizedBox.square(
    dimension: _day,
    child: AnimatedTendSurface(
      face: TendFace(
        fill: chosen ? c.ink : c.surface,
        rule: focused
            ? c.ink
            : day.isToday
            ? c.rule
            : c.surface,
        ruleWidth: focused ? 2 : 1,
        foreground: chosen
            ? c.surface
            : quiet
            ? c.mutedInk
            : c.ink,
      ),
      shape: const CircleBorder(),
      child: Center(
        // The day's number in the reader's digits: Arabic-Indic in Arabic.
        child: Text(day.label, style: theme.label),
      ),
    ),
  );
}
