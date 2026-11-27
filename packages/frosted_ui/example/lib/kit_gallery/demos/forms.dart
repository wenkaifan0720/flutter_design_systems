/// Forms: [FrostedSettingsGroup]s of [FrostedSwitchRow]s and [FrostedValueRow]s
/// (one row off), [FrostedFormRow]s with a leading glyph, a value and a
/// control, and a [FrostedFormSection] of fields with a [FrostedFieldPair],
/// in its tile and bare on a sheet.
library;

import 'package:material_ui/material_ui.dart';
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
  measured: true,
  title: kitSay('Forms'),
  sections: [
    kitSection(
      kitSay(
        'A switch row on and one with no callback; a way in and a row off',
      ),
      children: [kitSpecimenSwitchRow(), kitSpecimenValueRow()],
    ),
    kitSection(
      kitSay('Settings: switches in rows, flipped by their words'),
      children: [kitSpecimenSwitchRows()],
    ),
    kitSection(
      kitSay(
        'Settings: a switch, a way in, and a limit the frozen card cannot change',
      ),
      children: [kitSpecimenValueRows()],
    ),
    kitSection(
      kitSay('Form rows: a value, a control, a way in, each with its glyph'),
      children: [
        kitSpecimenFormRowValue(),
        kitSpecimenFormRowControl(),
        kitSpecimenFormRowChevron(),
      ],
    ),
    kitSection(
      kitSay('A form in its tile: a field, a pair, the icons'),
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
    title: kitSay('Notifications'),
    children: [
      FrostedSwitchRow(
        label: kitSay('Bills'),
        note: kitSay('A few days before each is due'),
        value: values[0],
        onChanged: (v) => flip(0, v),
      ),
      FrostedSwitchRow(
        label: kitSay('Budgets'),
        note: kitSay('When a category goes over'),
        value: values[1],
        onChanged: (v) => flip(1, v),
      ),
      FrostedSwitchRow(
        label: kitSay(r'Large purchases over $200'),
        value: values[2],
        onChanged: (v) => flip(2, v),
      ),
      FrostedSwitchRow(
        label: kitSay('Weekly summary'),
        note: kitSay('Every Sunday evening'),
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
      label: kitSay('Bills'),
      note: kitSay('A few days before each is due'),
      value: true,
      onChanged: (_) {},
    ),
    FrostedSwitchRow(
      label: kitSay('Weekly summary'),
      note: kitSay('Every Sunday evening'),
      value: false,
      onChanged: null,
    ),
  ],
);

Widget kitSpecimenValueRow() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    FrostedValueRow(title: kitSay('Change passcode'), onPressed: () {}),
    FrostedValueRow(
      title: kitSay('Monthly spending limit'),
      subtitle: kitSay(r'$1,259.82 spent in October'),
      value: r'$2,000',
      enabled: false,
      onPressed: () {},
    ),
  ],
);

Widget kitSpecimenValueRows() => FrostedSettingsGroup(
  title: kitSay('Security'),
  children: [
    FrostedSwitchRow(
      label: 'Face ID',
      note: kitSay('To open the app and approve payments'),
      value: true,
      onChanged: (_) {},
    ),
    FrostedValueRow(title: kitSay('Change passcode'), onPressed: () {}),
    FrostedValueRow(
      title: kitSay('Monthly spending limit'),
      subtitle: kitSay(r'$1,259.82 spent in October'),
      value: r'$2,000',
      enabled: false,
      onPressed: () {},
    ),
  ],
);

Widget kitSpecimenFormRowValue() => FrostedSettingsGroup(
  title: kitSay('Account'),
  children: [
    FrostedFormRow(
      label: kitSay('Currency'),
      leading: LucideIcons.coins,
      value: kitSay('USD'),
      onPressed: () {},
    ),
    FrostedFormRow(
      label: kitSay('Member since'),
      leading: LucideIcons.calendar,
      // The profile's own year (controls.dart): one person, one date.
      value: kitSay('October 2023'),
    ),
  ],
);

Widget kitSpecimenFormRowControl() => FrostedSettingsGroup(
  title: kitSay('Harbor Card'),
  children: [
    FrostedFormRow(
      label: kitSay('Round-ups'),
      detail: kitSay('Save the change from Harbor Card'),
      leading: LucideIcons.piggyBank,
      trailing: FrostedSwitch(
        value: true,
        onChanged: (_) {},
        semanticLabel: kitSay('Round-ups'),
      ),
    ),
    FrostedFormRow(
      label: kitSay('Card freeze'),
      leading: LucideIcons.snowflake,
      trailing: FrostedSwitch(
        value: false,
        onChanged: (_) {},
        semanticLabel: kitSay('Card freeze'),
      ),
    ),
  ],
);

Widget kitSpecimenFormRowChevron() => FrostedSettingsGroup(
  title: kitSay('Data'),
  children: [
    FrostedFormRow(
      label: kitSay('Linked accounts'),
      leading: LucideIcons.link,
      onPressed: () {},
    ),
    FrostedFormRow(
      label: kitSay('Export statements'),
      leading: LucideIcons.download,
      onPressed: () {},
    ),
  ],
);

Widget kitSpecimenFormSection() => FrostedFormSection(
  title: kitSay('New goal'),
  children: [
    FrostedTextField(
      labelText: kitSay('Name'),
      hintText: kitSay('What are you saving for?'),
      value: kitSay('Lisbon'),
    ),
    FrostedFieldPair(
      FrostedAmountField(
        labelText: kitSay('Target'),
        value: '4200',
        size: FrostedAmountFieldSize.small,
      ),
      FrostedTextField(labelText: kitSay('Date'), value: kitSay('May 2027')),
    ),
    FrostedIconPicker(
      icons: [
        FrostedIconChoice(LucideIcons.plane, kitSay('Plane')),
        FrostedIconChoice(LucideIcons.shield, kitSay('Shield')),
        FrostedIconChoice(LucideIcons.bike, kitSay('Bike')),
        FrostedIconChoice(LucideIcons.house, kitSay('Home')),
        FrostedIconChoice(LucideIcons.car, kitSay('Car')),
        FrostedIconChoice(LucideIcons.gift, kitSay('Gift')),
      ],
      value: kitSay('Plane'),
      onChanged: (_) {},
      labelled: true,
    ),
  ],
);

Widget kitSpecimenFormBare() => FrostedFormSection(
  bare: true,
  children: [
    FrostedAmountField(labelText: kitSay('Amount'), value: '500.00'),
    FrostedTextField(
      labelText: kitSay('Note'),
      value: kitSay('November top-up'),
    ),
    FrostedSegmentedButton(
      segments: [
        FrostedButtonSegment('today', kitSay('Today')),
        FrostedButtonSegment('tomorrow', kitSay('Tomorrow')),
        FrostedButtonSegment('date', kitSay('Choose a date')),
      ],
      value: 'today',
      onChanged: (_) {},
      label: kitSay('When'),
      fill: true,
      labelled: true,
    ),
  ],
);
