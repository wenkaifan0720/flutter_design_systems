/// A clock time: the date picker in its time mode.
library;

import 'package:flutter/widgets.dart';

import 'date_picker.dart';

/// A clock time — a reminder, an opening hour, a quiet-hours end: the
/// [MinimalDatePicker] in its time mode. `compact` (the default) is a form
/// row whose mono value opens two scrolling columns, hours and minutes, in
/// a popover (or a sheet that commits on Done, with [confirmSelection]);
/// `wheel` stands the columns on the page. Minimal prints the 24-hour clock
/// unless [use24HourFormat] is false.
///
/// The time is a [DateTime]'s hour and minute, as [MinimalDatePicker]'s time
/// mode takes it: a change keeps [value]'s date and sets its clock.
///
/// ```dart
/// MinimalTimePicker(label: 'Remind me at', value: remindAt, onChanged: (v) => setState(() => remindAt = v))
/// ```
class MinimalTimePicker extends StatelessWidget {
  /// A picker of a time of day, showing [value].
  const MinimalTimePicker({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.wheel = false,
    this.use24HourFormat = true,
    this.confirmSelection = false,
    this.icon,
  });

  /// What it picks.
  final String label;

  /// The time it shows: its hour and minute.
  final DateTime value;

  /// Called with [value]'s date at the chosen hour and minute; null disables
  /// the picker.
  final ValueChanged<DateTime>? onChanged;

  /// Stand the hour and minute columns on the page rather than a row that
  /// opens them.
  final bool wheel;

  /// Whether it prints the 24-hour clock.
  final bool use24HourFormat;

  /// Raise the columns in a sheet that commits only on Done.
  final bool confirmSelection;

  /// A glyph before the row's label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return MinimalDatePicker(
      label: label,
      value: value,
      mode: MinimalDatePickerMode.time,
      presentation: wheel
          ? MinimalDatePickerPresentation.wheel
          : MinimalDatePickerPresentation.compact,
      use24HourFormat: use24HourFormat,
      confirmSelection: confirmSelection,
      icon: icon,
      onChanged: change == null
          ? null
          : (d) => change(
              DateTime(value.year, value.month, value.day, d.hour, d.minute),
            ),
    );
  }
}
