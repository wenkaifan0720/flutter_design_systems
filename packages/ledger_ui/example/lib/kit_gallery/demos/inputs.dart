/// What the owner sets and types: the range chips ([LedgerSegmentedControl]),
/// the register's filters ([LedgerFilters]), the switch ([LedgerSwitch]) and
/// the rows it ends ([LedgerToggleRow]), a setting's row ([LedgerSettingRow]),
/// the search ([LedgerSearchField]) as a link and live, a form's field
/// ([LedgerField]), the transfer's cheque lines ([LedgerPickLine]) and amount
/// ([LedgerChequeAmount]), and the budget's stepper ([LedgerStepper]). The
/// first section is live: every control keeps its value. Every word and figure
/// is the pilot's (keel.dart).
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitInputsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Inputs',
  sections: [
    kitSection('Live', children: [const _Live()]),
    kitSection(
      'Range chips',
      children: [kitSpan(KitSpan.main, kitSpecimenChips())],
    ),
    kitSection(
      'Filters',
      children: [kitSpan(KitSpan.full, kitSpecimenFilters())],
    ),
    kitSection('Switches', children: [kitSpecimenSwitches()]),
    // Rows that end on a control span the column, as the live rows do: the
    // switch, the value and the chevron on the column's end.
    kitSection(
      'Switch rows',
      children: [kitSpan(KitSpan.full, kitSpecimenToggles())],
    ),
    kitSection(
      'A setting',
      children: [kitSpan(KitSpan.full, kitSpecimenSettingRow())],
    ),
    kitSection(
      'Disabled, the card frozen',
      children: [
        kitSpan(
          KitSpan.full,
          LedgerRows(
            children: [
              for (final c in kitCardControls)
                LedgerToggleRow(
                  icon: c.icon,
                  title: c.label,
                  subtitle: c.sub,
                  value: c.on,
                ),
              const LedgerSettingRow(
                icon: LucideIcons.gauge,
                title: 'Monthly spending limit',
                value: kitMonthlyLimit,
                subtitle: 'Resets on the 1st',
                enabled: false,
              ),
            ],
          ),
        ),
      ],
    ),
    kitSection(
      'Settings that open nothing',
      children: [kitSpan(KitSpan.full, kitSpecimenSettingPlain())],
    ),
    kitSection(
      'Search, a link',
      children: [kitSpan(KitSpan.full, kitSpecimenSearchLink())],
    ),
    kitSection(
      'Search, typed',
      children: [kitSpan(KitSpan.full, kitSpecimenSearchTyped())],
    ),
    kitSection(
      'A field',
      children: [kitSpan(KitSpan.main, kitSpecimenField())],
    ),
    kitSection(
      'A field shown',
      children: [kitSpan(KitSpan.main, kitSpecimenFieldShown())],
    ),
    kitSection(
      "The cheque's lines",
      children: [kitSpan(KitSpan.main, kitSpecimenPickLines())],
    ),
    kitSection(
      'A choice shown',
      children: [kitSpan(KitSpan.main, kitSpecimenPickShown())],
    ),
    kitSection(
      'Read back',
      children: [
        kitSpan(
          KitSpan.main,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LedgerPickLine(
                label: 'From',
                icon: kitFrom.$1,
                name: kitFrom.$2,
                mask: kitFrom.$3,
              ),
              LedgerPickLine(
                label: 'To',
                icon: kitTo.$1,
                name: kitTo.$2,
                mask: kitTo.$3,
              ),
            ],
          ),
        ),
      ],
    ),
    kitSection(
      "The cheque's amount",
      children: [kitSpan(KitSpan.main, kitSpecimenChequeAmount())],
    ),
    kitSection(
      "The cheque's amount, as typed",
      children: [kitSpan(KitSpan.main, kitSpecimenChequeAmountTyped())],
    ),
    kitSection('The stepper', children: [kitSpecimenStepper()]),
    kitSection(
      "The add sheet's amount, without its rings",
      children: [kitSpecimenStepperAlone()],
    ),
  ],
);

/// Every control holding its own value, as a page holds it.
class _Live extends StatefulWidget {
  const _Live();

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  String _range = kitRange;
  String? _direction = 'All';
  String? _account;
  late final List<bool> _alerts = [for (final a in kitAlerts) a.on];
  num _budget = kitDiningBudget;
  final _amount = TextEditingController(
    text: kitTransferAmount.toStringAsFixed(2),
  );
  final _note = TextEditingController(text: kitTransferNote);
  final _query = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: LedgerSpacing.s16,
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: LedgerSegmentedControl(
          options: kitRanges,
          value: _range,
          onChanged: (r) => setState(() => _range = r),
        ),
      ),
      Wrap(
        spacing: LedgerSpacing.s16,
        runSpacing: LedgerSpacing.s8,
        children: [
          LedgerFilters(
            label: 'Direction',
            options: const ['All', 'Money in', 'Money out'],
            value: _direction,
            onChanged: (d) => setState(() => _direction = d),
          ),
          LedgerFilters(
            label: 'Account',
            options: const ['Keel Card', 'Everyday'],
            value: _account,
            onChanged: (a) => setState(() => _account = a),
          ),
        ],
      ),
      LedgerSearchField(
        hint: 'Search merchants and categories',
        semanticLabel: 'Search activity',
        controller: _query,
        onChanged: (_) => setState(() {}),
        onCleared: () => setState(_query.clear),
      ),
      LedgerRows(
        children: [
          for (var i = 0; i < kitAlerts.length; i++)
            LedgerToggleRow(
              icon: kitAlerts[i].icon,
              title: kitAlerts[i].label,
              subtitle: kitAlerts[i].sub,
              value: _alerts[i],
              onChanged: (on) => setState(() => _alerts[i] = on),
            ),
        ],
      ),
      LedgerChequeAmount(
        label: 'Amount',
        words: kitTransferWords,
        unit: 'dollars',
        controller: _amount,
      ),
      LedgerField(label: 'Note', controller: _note),
      LedgerStepper(
        value: _budget,
        label: 'Monthly budget',
        lowerLabel: 'Lower the budget',
        raiseLabel: 'Raise the budget',
        onChanged: (v) => setState(() => _budget = v),
      ),
    ],
  );
}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// The net worth's range, a year shown.
Widget kitSpecimenChips() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: LedgerSegmentedControl(
    options: kitRanges,
    value: kitRange,
    onChanged: (_) {},
  ),
);

/// Activity's filters: every direction shown, no account picked.
Widget kitSpecimenFilters() => Wrap(
  spacing: LedgerSpacing.s16,
  runSpacing: LedgerSpacing.s8,
  children: [
    LedgerFilters(
      label: 'Direction',
      options: const ['All', 'Money in', 'Money out'],
      value: 'All',
      onChanged: (_) {},
    ),
    LedgerFilters(
      label: 'Account',
      options: const ['Keel Card', 'Everyday'],
      value: null,
      onChanged: (_) {},
    ),
  ],
);

/// On, off, and held while the card is frozen.
Widget kitSpecimenSwitches() => kitRow([
  LedgerSwitch(value: true, semanticLabel: 'Bills', onChanged: (_) {}),
  LedgerSwitch(
    value: false,
    semanticLabel: 'Weekly summary',
    onChanged: (_) {},
  ),
  const LedgerSwitch(
    value: true,
    semanticLabel: 'Contactless',
    onChanged: null,
  ),
]);

/// The alerts, each with its switch at the end.
Widget kitSpecimenToggles() => LedgerRows(
  children: [
    for (final a in kitAlerts)
      LedgerToggleRow(
        icon: a.icon,
        title: a.label,
        subtitle: a.sub,
        value: a.on,
        onChanged: (_) {},
      ),
  ],
);

/// The Keel Card's monthly spending limit, on its leader to its value.
Widget kitSpecimenSettingRow() => LedgerRows(
  children: [
    LedgerSettingRow(
      icon: LucideIcons.gauge,
      title: 'Monthly spending limit',
      value: kitMonthlyLimit,
      subtitle: 'Resets on the 1st',
      onTap: () {},
    ),
  ],
);

/// Activity's search, a link to the search page.
Widget kitSpecimenSearchLink() => LedgerSearchField(
  hint: 'Search merchants and categories',
  semanticLabel: "Search October's activity",
  onTap: () {},
);

/// The search typed: the café's name begun, with its clear.
Widget kitSpecimenSearchTyped() => KitTyped(
  kitInsightMerchant.substring(0, kitInsightMerchant.lastIndexOf(' ')),
  (controller) => LedgerSearchField(
    hint: 'Search merchants and categories',
    semanticLabel: 'Search activity',
    controller: controller,
    onCleared: controller.clear,
  ),
);

/// The transfer's note.
Widget kitSpecimenField() => KitTyped(
  kitTransferNote,
  (controller) => LedgerField(label: 'Note', controller: controller),
);

/// The profile's preferences that open nothing: the month's start and the
/// currency, in the full ink.
Widget kitSpecimenSettingPlain() => const LedgerRows(
  children: [
    LedgerSettingRow(
      icon: LucideIcons.calendar1,
      title: 'Month starts on',
      value: 'the 1st',
      subtitle: 'Budgets and Spending follow it',
    ),
    LedgerSettingRow(
      icon: LucideIcons.circleDollarSign,
      title: 'Currency',
      value: 'USD',
      subtitle: 'US dollar',
    ),
  ],
);

/// The transfer's note, shown on its line, read only.
Widget kitSpecimenFieldShown() =>
    const LedgerField(label: 'Note', value: kitTransferNote);

/// The form's From, its choice shown with the chevron, opening nothing.
Widget kitSpecimenPickShown() => LedgerPickLine(
  label: 'From',
  icon: kitFrom.$1,
  name: kitFrom.$2,
  mask: kitFrom.$3,
  balance: kitFrom.$4,
  note: 'Available',
  showChevron: true,
);

/// The transfer's From and To, live: each account's balance and a chevron.
Widget kitSpecimenPickLines() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    LedgerPickLine(
      label: 'From',
      icon: kitFrom.$1,
      name: kitFrom.$2,
      mask: kitFrom.$3,
      balance: kitFrom.$4,
      note: 'Available',
      onTap: () {},
    ),
    LedgerPickLine(
      label: 'To',
      icon: kitTo.$1,
      name: kitTo.$2,
      mask: kitTo.$3,
      balance: kitTo.$4,
      note: 'Balance',
      onTap: () {},
    ),
  ],
);

/// The transfer's amount read back under review, and in words.
Widget kitSpecimenChequeAmount() => const LedgerChequeAmount(
  label: 'Amount',
  words: kitTransferWords,
  unit: 'dollars',
  amount: kitTransferAmount,
);

/// The form's amount, read back as its input holds it, and in words.
Widget kitSpecimenChequeAmountTyped() => const LedgerChequeAmount(
  label: 'Amount',
  words: kitTransferWords,
  unit: 'dollars',
  amount: kitTransferAmount,
  typed: true,
);

/// The add sheet's amount to add, the sum alone over its chips.
Widget kitSpecimenStepperAlone() => LedgerStepper(
  value: kitAddAmount,
  label: 'Amount to add',
  showRings: false,
  onChanged: (_) {},
);

/// Dining out's monthly budget in the edit sheet.
Widget kitSpecimenStepper() => LedgerStepper(
  value: kitDiningBudget,
  label: 'Monthly budget',
  lowerLabel: 'Lower the budget',
  raiseLabel: 'Raise the budget',
  onChanged: (_) {},
);
