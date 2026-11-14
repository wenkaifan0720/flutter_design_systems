/// A clock time in a row or on the page.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitTimeWheelDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Time pickers',
  sections: [
    kitSection('Time picker', children: [_LiveTime(wheel: false)]),
    kitSection('On the page', children: [_LiveTime(wheel: true)]),
  ],
);

class _LiveTime extends StatefulWidget {
  const _LiveTime({required this.wheel});

  final bool wheel;

  @override
  State<_LiveTime> createState() => _LiveTimeState();
}

class _LiveTimeState extends State<_LiveTime> {
  DateTime _at = DateTime(2026, 1, 1, 21, 30);

  @override
  Widget build(BuildContext context) {
    final picker = MinimalTimePicker(
      label: 'Remind me at',
      icon: LucideIcons.bell,
      value: _at,
      wheel: widget.wheel,
      onChanged: (v) => setState(() => _at = v),
    );
    // The row stands in a form section, as every row group on the page
    // does: a rule over it as well as its own under it.
    return widget.wheel ? picker : MinimalFormSection(children: [picker]);
  }
}

// --- catalog specimens -------------------------------------------------------

/// The compact row: a reminder at 21:30.
Widget kitSpecimenTimePickerRow() => MinimalTimePicker(
  label: 'Remind me at',
  icon: LucideIcons.bell,
  value: DateTime(2026, 1, 1, 21, 30),
  onChanged: (_) {},
);
