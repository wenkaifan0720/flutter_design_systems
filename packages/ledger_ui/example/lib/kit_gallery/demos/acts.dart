/// The acts beyond the button: [LedgerToggleGroup] choosing one or toggling
/// many, [LedgerSplitButton] with its menu, and [LedgerKbd] printing a
/// shortcut. Every one is live.
library;

import 'package:material_ui/material_ui.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

Widget kitActsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Toggle groups, split buttons & keys',
  sections: [
    kitSection('Toggle group, one choice', children: [const _Range()]),
    kitSection('Toggle group, any number', children: [const _Columns()]),
    kitSection(
      'Split button',
      children: [
        Builder(
          builder: (context) => kitRow([
            LedgerSplitButton(
              'Export',
              onPressed: () => LedgerToast.show(context, 'October exported'),
              actions: [
                LedgerSplitAction(
                  label: 'As CSV',
                  onPressed: () => LedgerToast.show(context, 'Saved as CSV'),
                ),
                LedgerSplitAction(
                  label: 'As PDF',
                  onPressed: () => LedgerToast.show(context, 'Saved as PDF'),
                ),
                const LedgerSplitAction(label: 'To the bank', onPressed: null),
              ],
            ),
            LedgerSplitButton(
              'Reconcile',
              filled: true,
              onPressed: () => LedgerToast.show(context, 'October reconciled'),
              actions: [
                LedgerSplitAction(
                  label: 'Reconcile and close',
                  onPressed: () => LedgerToast.show(context, 'October closed'),
                ),
              ],
            ),
          ]),
        ),
      ],
    ),
    kitSection(
      'Keys',
      children: [
        kitRow(const [
          LedgerKbd(['⌘', 'K'], semanticLabel: 'Command K'),
          LedgerKbd(['Shift', 'Enter']),
          LedgerKbd(['Esc']),
        ]),
      ],
    ),
  ],
);

class _Range extends StatefulWidget {
  const _Range();

  @override
  State<_Range> createState() => _RangeState();
}

class _RangeState extends State<_Range> {
  Set<String> _range = {'Month'};

  @override
  Widget build(BuildContext context) => LedgerToggleGroup<String>(
    semanticLabel: 'Range',
    options: const ['Week', 'Month', 'Quarter', 'Year'],
    labelOf: (v) => v,
    selected: _range,
    onSelectionChanged: (next) => setState(() => _range = next),
  );
}

class _Columns extends StatefulWidget {
  const _Columns();

  @override
  State<_Columns> createState() => _ColumnsState();
}

class _ColumnsState extends State<_Columns> {
  Set<String> _shown = {'Payee', 'Amount'};

  @override
  Widget build(BuildContext context) => LedgerToggleGroup<String>(
    semanticLabel: 'Columns',
    multiSelectionEnabled: true,
    emptySelectionAllowed: true,
    options: const ['Time', 'Payee', 'Category', 'Account', 'Amount'],
    labelOf: (v) => v,
    selected: _shown,
    isEnabled: (v) => v != 'Amount',
    onSelectionChanged: (next) => setState(() => _shown = next),
  );
}
