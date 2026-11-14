/// Fluent's date controls: the date picker (empty, chosen, filled,
/// underline, in a field, disabled) opening its calendar, and the month
/// calendar on its own (today, a chosen day, marked days, a bounded
/// range, a report-only month), each live.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

class _Live<T> extends StatefulWidget {
  const _Live(this.initial, this.builder);

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<_Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<_Live<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

final _today = DateTime(2026, 11, 4);

final _meetings = {
  DateTime(2026, 11, 2),
  DateTime(2026, 11, 4),
  DateTime(2026, 11, 12),
  DateTime(2026, 11, 19),
  DateTime(2026, 11, 26),
};

Widget kitDateDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Date',
  sections: [
    kitSection('Date picker', children: [kitSpecimenDatePicker()]),
    kitSection(
      'Date picker, in a field',
      children: [
        _Live<DateTime?>(
          null,
          (v, set) => Fluent2FormField(
            label: 'Launch date',
            required: true,
            helper: 'The launch deck goes out the day before.',
            validationMessage: v == null ? 'Choose a launch date.' : null,
            child: Fluent2DatePicker(
              value: v,
              today: _today,
              firstDate: _today,
              onChanged: set,
            ),
          ),
        ),
      ],
    ),
    kitSection('Calendar', children: [kitSpecimenCalendar()]),
    kitSection(
      'Calendar, from today to the month\'s end, report-only',
      children: [
        Wrap(
          spacing: Fluent2Spacing.xxl,
          runSpacing: Fluent2Spacing.xxl,
          children: [
            _Live<DateTime?>(
              null,
              (v, set) => Fluent2Calendar(
                value: v,
                today: _today,
                firstDate: _today,
                lastDate: DateTime(2026, 11, 30),
                onChanged: set,
              ),
            ),
            Fluent2Calendar(
              value: null,
              today: _today,
              marks: _meetings,
              showAdjacent: false,
            ),
          ],
        ),
      ],
    ),
  ],
);

Widget kitSpecimenDatePicker() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.m,
  children: [
    _Live<DateTime?>(
      null,
      (v, set) => Fluent2DatePicker(
        label: 'Due date',
        value: v,
        today: _today,
        onChanged: set,
      ),
    ),
    _Live<DateTime?>(
      DateTime(2026, 11, 12),
      (v, set) => Fluent2DatePicker(
        label: 'Review date',
        value: v,
        today: _today,
        appearance: Fluent2InputAppearance.filledDarker,
        onChanged: set,
      ),
    ),
    Fluent2DatePicker(
      label: 'Archived on',
      value: DateTime(2026, 10, 30),
      onChanged: null,
    ),
  ],
);

Widget kitSpecimenCalendar() => _Live<DateTime?>(
  DateTime(2026, 11, 12),
  (v, set) => Fluent2Calendar(
    value: v,
    today: _today,
    marks: _meetings,
    onChanged: set,
  ),
);
