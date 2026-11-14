/// Forms: [FrostedSettingsGroup]s of [FrostedSwitchRow]s and [FrostedValueRow]s
/// (one row off), [FrostedFormRow]s with a leading glyph, a value and a
/// control, and a [FrostedFormSection] of fields with a [FrostedFieldPair],
/// in its tile and bare on a sheet.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The notifications a page keeps, flipped by their rows.
/// Switches that keep the values their rows hand back, as a settings page
/// does; [builder] draws the group from them.
class _Toggles extends StatefulWidget {
  const _Toggles({required this.initial, required this.builder});

  final List<bool> initial;
  final Widget Function(List<bool> values, void Function(int, bool) flip)
  builder;

  @override
  State<_Toggles> createState() => _TogglesState();
}

class _TogglesState extends State<_Toggles> {
  late var _values = List<bool>.of(widget.initial);

  @override
  Widget build(BuildContext context) => widget.builder(
    _values,
    (i, v) => setState(() => _values = List<bool>.of(_values)..[i] = v),
  );
}

Widget kitFormsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Forms',
  sections: [
    kitSection(
      'A switch row on and one with no callback; a way in and a row off',
      children: [kitSpecimenSwitchRow(), kitSpecimenValueRow()],
    ),
    kitSection(
      'Settings: switches in rows, flipped by their words',
      children: [kitSpecimenSwitchRows()],
    ),
    kitSection(
      'Settings: a switch, a way in, and a limit the frozen card cannot change',
      children: [kitSpecimenValueRows()],
    ),
    kitSection(
      'Form rows: a value, a control, a way in, each with its glyph',
      children: [
        kitSpecimenFormRowValue(),
        kitSpecimenFormRowControl(),
        kitSpecimenFormRowChevron(),
      ],
    ),
    kitSection(
      'A form in its tile: a field, a pair, the icons',
      children: [kitSpecimenFormSection()],
    ),
    kitSection(
      "A form bare on a sheet's body",
      children: [kitSpecimenFormBare()],
    ),
  ],
);

// --- Specimens ---

Widget kitSpecimenSwitchRows() => _Toggles(
  initial: const [true, true, true, false],
  builder: (values, flip) => FrostedSettingsGroup(
    title: 'Notifications',
    children: [
      FrostedSwitchRow(
        label: 'Bills',
        note: 'A few days before each is due',
        value: values[0],
        onChanged: (v) => flip(0, v),
      ),
      FrostedSwitchRow(
        label: 'Budgets',
        note: 'When a category goes over',
        value: values[1],
        onChanged: (v) => flip(1, v),
      ),
      FrostedSwitchRow(
        label: r'Large purchases over $200',
        value: values[2],
        onChanged: (v) => flip(2, v),
      ),
      FrostedSwitchRow(
        label: 'Weekly summary',
        note: 'Every Sunday evening',
        value: values[3],
        onChanged: (v) => flip(3, v),
      ),
    ],
  ),
);

Widget kitSpecimenSwitchRow() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    FrostedSwitchRow(
      label: 'Bills',
      note: 'A few days before each is due',
      value: true,
      onChanged: (_) {},
    ),
    const FrostedSwitchRow(
      label: 'Weekly summary',
      note: 'Every Sunday evening',
      value: false,
      onChanged: null,
    ),
  ],
);

Widget kitSpecimenValueRow() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    FrostedValueRow(title: 'Change passcode', onPressed: () {}),
    FrostedValueRow(
      title: 'Monthly spending limit',
      subtitle: r'$1,259.82 spent in October',
      value: r'$2,000',
      enabled: false,
      onPressed: () {},
    ),
  ],
);

Widget kitSpecimenValueRows() => FrostedSettingsGroup(
  title: 'Security',
  children: [
    FrostedSwitchRow(
      label: 'Face ID',
      note: 'To open the app and approve payments',
      value: true,
      onChanged: (_) {},
    ),
    FrostedValueRow(title: 'Change passcode', onPressed: () {}),
    FrostedValueRow(
      title: 'Monthly spending limit',
      subtitle: r'$1,259.82 spent in October',
      value: r'$2,000',
      enabled: false,
      onPressed: () {},
    ),
  ],
);

Widget kitSpecimenFormRowValue() => FrostedSettingsGroup(
  title: 'Account',
  children: [
    FrostedFormRow(
      label: 'Currency',
      leading: LucideIcons.coins,
      value: 'USD',
      onPressed: () {},
    ),
    const FrostedFormRow(
      label: 'Member since',
      leading: LucideIcons.calendar,
      // The profile's own year (controls.dart): one person, one date (round 11).
      value: 'October 2023',
    ),
  ],
);

Widget kitSpecimenFormRowControl() => FrostedSettingsGroup(
  title: 'Harbor Card',
  children: [
    FrostedFormRow(
      label: 'Round-ups',
      detail: 'Save the change from Harbor Card',
      leading: LucideIcons.piggyBank,
      trailing: FrostedSwitch(
        value: true,
        onChanged: (_) {},
        label: 'Round-ups',
      ),
    ),
    FrostedFormRow(
      label: 'Card freeze',
      leading: LucideIcons.snowflake,
      trailing: FrostedSwitch(
        value: false,
        onChanged: (_) {},
        label: 'Card freeze',
      ),
    ),
  ],
);

Widget kitSpecimenFormRowChevron() => FrostedSettingsGroup(
  title: 'Data',
  children: [
    FrostedFormRow(
      label: 'Linked accounts',
      leading: LucideIcons.link,
      onPressed: () {},
    ),
    FrostedFormRow(
      label: 'Export statements',
      leading: LucideIcons.download,
      onPressed: () {},
    ),
  ],
);

Widget kitSpecimenFormSection() => FrostedFormSection(
  title: 'New goal',
  children: [
    const FrostedTextField(
      label: 'Name',
      hint: 'What are you saving for?',
      value: 'Lisbon',
    ),
    const FrostedFieldPair(
      FrostedAmountField(
        label: 'Target',
        value: '4200',
        size: FrostedAmountFieldSize.small,
      ),
      FrostedTextField(label: 'Date', value: 'May 2027'),
    ),
    FrostedIconPicker(
      icons: const [
        FrostedIconChoice(LucideIcons.plane, 'Plane'),
        FrostedIconChoice(LucideIcons.shield, 'Shield'),
        FrostedIconChoice(LucideIcons.bike, 'Bike'),
        FrostedIconChoice(LucideIcons.house, 'Home'),
        FrostedIconChoice(LucideIcons.car, 'Car'),
        FrostedIconChoice(LucideIcons.gift, 'Gift'),
      ],
      value: 'Plane',
      onChanged: (_) {},
      labelled: true,
    ),
  ],
);

Widget kitSpecimenFormBare() => FrostedFormSection(
  bare: true,
  children: [
    const FrostedAmountField(label: 'Amount', value: '500.00'),
    const FrostedTextField(label: 'Note', value: 'November top-up'),
    FrostedSegmentedButton(
      segments: const [
        FrostedButtonSegment('today', 'Today'),
        FrostedButtonSegment('tomorrow', 'Tomorrow'),
        FrostedButtonSegment('date', 'Choose a date'),
      ],
      value: 'today',
      onChanged: (_) {},
      label: 'When',
      fill: true,
      labelled: true,
    ),
  ],
);
