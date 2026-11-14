/// The entries past a plain field: a password with its reveal, a field with
/// its fixed words on each side, a range of prices, files
/// to attach, a stay picked on the month, a meeting's start time, a size on
/// the wheel and a colour.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import '../kit.dart';

Widget kitEntriesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Passwords, ranges & times',
  sections: [
    kitSection('Password', children: [kitSpecimenPasswordField()]),
    kitSection(
      'Fixed words beside the field',
      children: [kitSpecimenInputGroup()],
    ),
    kitSection('A range', children: [kitSpecimenRangeSlider()]),
    kitSection('Files to attach', children: [kitSpecimenFileUpload()]),
    kitSection('A stay', children: [kitSpecimenDateRangePicker()]),
    kitSection('A time', children: [kitSpecimenTimePicker()]),
    kitSection('On the wheel', children: [kitSpecimenWheelPicker()]),
    kitSection('A colour', children: [kitSpecimenColorPicker()]),
  ],
);

Widget kitSpecimenPasswordField() => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.m,
  children: [
    Fluent2PasswordField(
      label: 'Password',
      value: 'harbor-light-42',
      onChanged: _typed,
    ),
    Fluent2PasswordField(
      label: 'New password',
      value: 'abc',
      onChanged: _typed,
      validationMessage: 'Use at least 8 characters',
    ),
  ],
);

Widget kitSpecimenInputGroup() => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.m,
  children: [
    Fluent2InputGroup(
      label: 'Website',
      prefix: 'https://',
      suffix: '.com',
      hint: 'northwind',
    ),
    Fluent2InputGroup(
      label: 'Budget',
      prefix: r'$',
      suffix: 'per month',
      hint: '0',
    ),
  ],
);

Widget kitSpecimenRangeSlider() {
  var price = const DesignRangeValues(40, 160);
  return StatefulBuilder(
    builder: (context, set) => Fluent2RangeSlider(
      label: 'Price per night',
      min: 0,
      max: 300,
      divisions: 30,
      values: price,
      valueLabel: (v) => '\$${v.round()}',
      onChanged: (v) => set(() => price = v),
    ),
  );
}

Widget kitSpecimenFileUpload() => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.m,
  children: [
    Fluent2FileUpload(
      label: 'Attachments',
      hint: 'PDF or images, up to 25 MB',
      onPressed: _choose,
    ),
    Fluent2FormField(
      validationMessage: 'Add the receipt to send the claim',
      child: Fluent2FileUpload(
        label: 'Receipt',
        onPressed: _choose,
        invalid: true,
      ),
    ),
  ],
);

void _choose() {}

void _typed(String _) {}

final _stay = DesignCalendarController(
  firstDate: DateTime(2026, 6),
  lastDate: DateTime(2026, 9, 30),
  mode: DesignCalendarMode.range,
  selectedRange: DesignDateRange(DateTime(2026, 6, 14), DateTime(2026, 6, 18)),
  currentDate: DateTime(2026, 6, 10),
);

Widget kitSpecimenDateRangePicker() =>
    Fluent2DateRangePicker(controller: _stay);

Widget kitSpecimenTimePicker() {
  Fluent2Time? start = const Fluent2Time(9, 30);
  return StatefulBuilder(
    builder: (context, set) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Fluent2Spacing.m,
      children: [
        Fluent2TimePicker(
          label: 'Starts',
          value: start,
          minuteStep: 15,
          onChanged: (v) => set(() => start = v),
        ),
        const Fluent2TimePicker(label: 'Ends', onChanged: null),
      ],
    ),
  );
}

Widget kitSpecimenWheelPicker() {
  var size = 'Medium';
  return StatefulBuilder(
    builder: (context, set) => Fluent2WheelPicker<String>(
      label: 'Size',
      items: const ['Extra small', 'Small', 'Medium', 'Large', 'Extra large'],
      value: size,
      onChanged: (v) => set(() => size = v),
    ),
  );
}

Widget kitSpecimenColorPicker() =>
    _OwnColour(builder: (colour) => Fluent2ColorPicker(controller: colour));

/// A colour controller of its own for [builder], started on the theme's
/// brand colour: one per mount, so a page in another theme starts on its
/// own.
class _OwnColour extends StatefulWidget {
  const _OwnColour({required this.builder});

  final Widget Function(DesignColorController colour) builder;

  @override
  State<_OwnColour> createState() => _OwnColourState();
}

class _OwnColourState extends State<_OwnColour> {
  DesignColorController? _colour;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colour ??= DesignColorController(
      context.fluent2Theme.colors.compoundBrandForeground1,
    );
  }

  @override
  void dispose() {
    _colour?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_colour!);
}
