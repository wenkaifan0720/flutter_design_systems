/// The choices: [FrostedSegmentedButton] as a range and as a form's field;
/// [FrostedFilterChipGroup] scoping Activity; [FrostedSwitch] on, off, disabled and
/// read only; [FrostedQuickAmounts] with one chosen; [FrostedIconPicker] in two
/// rows; [FrostedMonthSwitch] with its earlier month and the later step off;
/// Home's [FrostedQuickActions]; and Move's [FrostedActionTiles].
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// A control that keeps the value its callback hands back, as a page does.
class _Live<T> extends StatefulWidget {
  const _Live(this.initial, this.builder, {super.key});

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

const _ranges = [
  FrostedButtonSegment('1m', '1M'),
  FrostedButtonSegment('3m', '3M'),
  FrostedButtonSegment('1y', '1Y'),
  FrostedButtonSegment('all', 'All'),
];

const _whens = [
  FrostedButtonSegment('today', 'Today'),
  FrostedButtonSegment('tomorrow', 'Tomorrow'),
  FrostedButtonSegment('date', 'Choose a date'),
];

const _amounts = [
  FrostedQuickAmount(100, 'A month'),
  FrostedQuickAmount(200, 'Two months'),
  FrostedQuickAmount(1160, 'The rest'),
];

const _goalIcons = [
  FrostedIconChoice(LucideIcons.plane, 'Plane'),
  FrostedIconChoice(LucideIcons.shield, 'Shield'),
  FrostedIconChoice(LucideIcons.bike, 'Bike'),
  FrostedIconChoice(LucideIcons.house, 'Home'),
  FrostedIconChoice(LucideIcons.car, 'Car'),
  FrostedIconChoice(LucideIcons.gift, 'Gift'),
  FrostedIconChoice(LucideIcons.heart, 'Heart'),
  FrostedIconChoice(LucideIcons.laptop, 'Laptop'),
  FrostedIconChoice(LucideIcons.graduationCap, 'Study'),
  FrostedIconChoice(LucideIcons.palmtree, 'Holiday'),
  FrostedIconChoice(LucideIcons.pawPrint, 'Pet'),
  FrostedIconChoice(LucideIcons.sparkles, 'Something else'),
];

Widget kitSelectionDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Selection',
  sections: [
    kitSection(
      "Segmented: a range, and a form's When (filling its field on a phone)",
      children: [kitSpecimenSegmentedRange(), kitSpecimenSegmentedFill()],
    ),
    kitSection(
      'Filters, running under the gutters on a phone',
      children: [kitSpecimenFilterChips(), kitSpecimenFilterChipsFrozen()],
    ),
    kitSection(
      'Switches: on, off, disabled, read only',
      children: [kitSpecimenSwitches()],
    ),
    kitSection(
      "A goal's quick amounts, the first chosen; frozen",
      children: [kitSpecimenQuickAmounts(), kitSpecimenQuickAmountsFrozen()],
    ),
    kitSection(
      "A goal's icons, six to a row, the plane chosen",
      children: [kitSpecimenIconPicker()],
    ),
    kitSection(
      'The month switch: the later step off at the latest month',
      children: [kitSpecimenMonthSwitch(), kitSpecimenMonthSwitchBetween()],
    ),
    kitSection("Home's quick actions", children: [kitSpecimenQuickActions()]),
    kitSection(
      "Move's ways to move money",
      children: [kitSpecimenActionTiles()],
    ),
  ],
);

// --- Specimens ---

Widget kitSpecimenSegmentedRange() => _Live<String>(
  '1y',
  (value, set) => FrostedSegmentedButton(
    segments: _ranges,
    value: value,
    onChanged: set,
    label: 'Range',
  ),
);

Widget kitSpecimenSegmentedFill() => _Live<String>(
  'today',
  (value, set) => FrostedSegmentedButton(
    segments: _whens,
    value: value,
    onChanged: set,
    label: 'When',
    fill: true,
    labelled: true,
  ),
);

Widget kitSpecimenSwitches() => kitRow([
  _Live<bool>(
    true,
    (value, set) => FrostedSwitch(value: value, onChanged: set, label: 'Bills'),
  ),
  _Live<bool>(
    false,
    (value, set) =>
        FrostedSwitch(value: value, onChanged: set, label: 'Weekly summary'),
  ),
  const FrostedSwitch(value: true, onChanged: null, label: 'Contactless'),
  const FrostedSwitch(
    value: true,
    onChanged: null,
    label: 'Auto-save',
    readOnly: true,
  ),
]);

Widget kitSpecimenQuickAmounts() => _Live<num?>(
  100,
  (value, set) =>
      FrostedQuickAmounts(options: _amounts, value: value, onChanged: set),
);

Widget kitSpecimenQuickAmountsFrozen() =>
    const FrostedQuickAmounts(options: _amounts, value: 200, onChanged: null);

Widget kitSpecimenIconPicker() => _Live<String?>(
  'Plane',
  (value, set) =>
      FrostedIconPicker(icons: _goalIcons, value: value, onChanged: set),
);

Widget kitSpecimenQuickActions() => FrostedQuickActions([
  FrostedQuickAction(LucideIcons.arrowLeftRight, 'Transfer', onPressed: () {}),
  FrostedQuickAction(LucideIcons.receipt, 'Pay a bill', onPressed: () {}),
  FrostedQuickAction(LucideIcons.piggyBank, 'Add to goal', onPressed: () {}),
  FrostedQuickAction(LucideIcons.split, 'Split', onPressed: () {}),
]);

Widget kitSpecimenActionTiles() => FrostedActionTiles([
  FrostedActionTile(
    LucideIcons.arrowLeftRight,
    'Transfer',
    note: 'Your accounts',
    onPressed: () {},
  ),
  FrostedActionTile(
    LucideIcons.receipt,
    'Pay a bill',
    note: '6 in November',
    tail: r'$2,541.40',
    onPressed: () {},
  ),
  FrostedActionTile(
    LucideIcons.piggyBank,
    'Add to goal',
    note: 'Lisbon in May',
    tail: r'$110 behind',
    onPressed: () {},
  ),
  FrostedActionTile(
    LucideIcons.split,
    'Split',
    note: 'Cinema Lumen',
    tail: r'$28.00',
    onPressed: () {},
  ),
], label: 'Ways to move money');

// --- Activity's scope chips and Spending's month switch (controls.dart) ---

const _scopes = [
  FrostedFilterOption('all', 'All'),
  FrostedFilterOption('in', 'Money in'),
  FrostedFilterOption('out', 'Money out'),
  FrostedFilterOption('card', 'Harbor Card'),
  FrostedFilterOption('every', 'Everyday'),
];

Widget kitSpecimenFilterChips() => _Live<String>(
  'all',
  (value, set) =>
      FrostedFilterChipGroup(options: _scopes, value: value, onChanged: set),
);

Widget kitSpecimenFilterChipsFrozen() => const FrostedFilterChipGroup(
  options: _scopes,
  value: 'card',
  onChanged: null,
);

Widget kitSpecimenMonthSwitch() => FrostedMonthSwitch(
  month: 'October 2026',
  previous: 'September',
  onEarlier: () {},
  onLater: null,
  onOpen: (_) {},
);

Widget kitSpecimenMonthSwitchBetween() => FrostedMonthSwitch(
  month: 'August 2026',
  previous: 'July',
  onEarlier: () {},
  onLater: () {},
  onOpen: (_) {},
);
