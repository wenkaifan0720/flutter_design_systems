/// The inputs: [FrostedSearchLink] and [FrostedSearchField], empty and holding
/// a query; [FrostedTextField]s with a placeholder, a value and a help line;
/// [FrostedAmountField] at its two sizes; a transfer's [FrostedPickerRow]s
/// joined by a [FrostedSwapButton]; and [FrostedNumberField] with its note. The filter
/// chips and the month switch are choices: the selection demo draws them.
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

Widget kitInputsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Inputs',
  sections: [
    kitSection(
      'Search: the way in, then the field empty and holding a query',
      children: [
        kitSpecimenSearchLink(),
        kitSpecimenSearchLinkTyped(),
        kitSpecimenSearchField(),
        kitSpecimenSearchFieldTyped(),
      ],
    ),
    kitSection(
      'Text fields: a placeholder, a value with its help line, read only',
      children: [
        kitSpecimenTextFieldName(),
        kitSpecimenTextFieldNote(),
        const FrostedTextField(label: 'Account', value: 'Checking ·· 4821'),
      ],
    ),
    kitSection(
      'Amounts: the 64 well, and the small one in a pair',
      children: [kitSpecimenAmountField(), kitSpecimenAmountFieldSmall()],
    ),
    kitSection(
      "A transfer's From and To, joined by the swap",
      children: [kitSpecimenPickers()],
    ),
    kitSection(
      'A budget stepper with its note; at its floor',
      children: [kitSpecimenStepper(), kitSpecimenStepperFloor()],
    ),
  ],
);

// --- Specimens ---

Widget kitSpecimenSearchLink() =>
    FrostedSearchLink(hint: 'Search activity', onPressed: () {});

Widget kitSpecimenSearchLinkTyped() => FrostedSearchLink(
  hint: 'Search activity',
  value: 'Blue Fern',
  onPressed: () {},
);

Widget kitSpecimenSearchField() => _Live<String>(
  '',
  (value, set) =>
      FrostedSearchField(hint: 'Search activity', value: value, onChanged: set),
);

Widget kitSpecimenSearchFieldTyped() => _Live<String>(
  'Blue Fern',
  (value, set) =>
      FrostedSearchField(hint: 'Search activity', value: value, onChanged: set),
);

Widget kitSpecimenTextFieldName() => _Live<String>(
  '',
  (value, set) => FrostedTextField(
    label: 'Name',
    hint: 'What are you saving for?',
    value: value,
    onChanged: set,
  ),
);

Widget kitSpecimenTextFieldNote() => _Live<String>(
  'November top-up',
  (value, set) => FrostedTextField(
    label: 'Note',
    helper: 'Shows on both statements',
    value: value,
    onChanged: set,
  ),
);

Widget kitSpecimenAmountField() => _Live<String>(
  '500.00',
  (value, set) =>
      FrostedAmountField(label: 'Amount', value: value, onChanged: set),
);

Widget kitSpecimenAmountFieldSmall() => _Live<String>(
  '',
  (value, set) => FrostedFieldPair(
    FrostedAmountField(
      label: 'Target',
      value: value,
      onChanged: set,
      size: FrostedAmountFieldSize.small,
    ),
    const FrostedTextField(label: 'Date', hint: 'Month and year'),
  ),
);

Widget kitSpecimenPickers() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedFormSection(
      bare: true,
      children: [
        FrostedPickerRow(
          label: 'From',
          title: 'Everyday',
          subtitle: 'Checking ·· 4821',
          leading: FrostedIconMark(LucideIcons.wallet, hue: t.hues.cyan),
          trailing: const FrostedAmount(6248.30, signed: false),
          onPressed: () {},
        ),
        const FrostedSwapButton(),
        FrostedPickerRow(
          label: 'To',
          title: 'Savings',
          subtitle: 'Savings ·· 9015',
          leading: FrostedIconMark(LucideIcons.landmark, hue: t.hues.seafoam),
          trailing: const FrostedAmount(21500, signed: false),
          onPressed: () {},
        ),
      ],
    );
  },
);

Widget kitSpecimenStepper() => _Live<int>(
  250,
  (value, set) => FrostedNumberField(
    value: value,
    onChanged: set,
    label: 'the budget',
    note: 'a month',
  ),
);

Widget kitSpecimenStepperFloor() => _Live<int>(
  0,
  (value, set) =>
      FrostedNumberField(value: value, onChanged: set, label: 'the budget'),
);

/// The account a transfer comes from.
Widget kitSpecimenSelect() => FrostedSelect<String>(
  label: 'From',
  options: const [
    FrostedSelectOption('chk', 'Everyday · 4821'),
    FrostedSelectOption('sav', 'Savings · 0937'),
  ],
  value: 'chk',
  onChanged: (_) {},
);

/// A transfer's note over two lines.
Widget kitSpecimenTextArea() => FrostedTextArea(
  label: 'Note',
  hint: 'What is it for?',
  value: 'Dinner at Blue Fern, split three ways',
  onChanged: (_) {},
);
