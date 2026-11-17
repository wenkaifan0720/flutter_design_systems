/// The ways about the book: a breadcrumb, a register's pages, a form's
/// steps, a welcome's page marks and the command palette. Every one is
/// live.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

const List<LedgerCommand> _commands = [
  LedgerCommand(label: 'New entry', group: 'Entries', shortcut: 'N'),
  LedgerCommand(label: 'Split the last entry', group: 'Entries'),
  LedgerCommand(label: 'Export October', group: 'Entries', shortcut: 'Cmd+E'),
  LedgerCommand(label: 'Go to Budgets', group: 'Places', shortcut: 'G+B'),
  LedgerCommand(label: 'Go to the Register', group: 'Places', shortcut: 'G+R'),
  LedgerCommand(label: 'Settings', group: 'Places'),
];

/// A page of a register, held while the page stands.
class _Pages extends StatefulWidget {
  const _Pages({required this.count});

  final int count;

  @override
  State<_Pages> createState() => _PagesState();
}

class _PagesState extends State<_Pages> {
  int _page = 2;

  @override
  Widget build(BuildContext context) => LedgerPagination(
    page: _page,
    pageCount: widget.count,
    onChanged: (p) => setState(() => _page = p),
  );
}

/// A form's steps, walked by its buttons.
class _Steps extends StatefulWidget {
  const _Steps();

  @override
  State<_Steps> createState() => _StepsState();
}

class _StepsState extends State<_Steps> {
  int _at = 1;
  static const _names = ['Payee', 'Amount', 'Category', 'Review'];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: LedgerSpacing.s16,
    children: [
      LedgerStepProgress(steps: _names, current: _at),
      Row(
        spacing: LedgerSpacing.s12,
        children: [
          LedgerButton(
            'Back',
            size: LedgerButtonSize.medium,
            onPressed: _at == 0 ? null : () => setState(() => _at--),
          ),
          LedgerButton.filled(
            'Next',
            size: LedgerButtonSize.medium,
            onPressed: _at == _names.length - 1
                ? null
                : () => setState(() => _at++),
          ),
        ],
      ),
    ],
  );
}

/// A welcome's page marks, held while the page stands.
class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> {
  int _at = 1;

  @override
  Widget build(BuildContext context) => LedgerPageDots(
    count: 4,
    index: _at,
    onChanged: (i) => setState(() => _at = i),
  );
}

Widget kitWayfindingDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Ways about',
  sections: [
    kitSection(
      'Breadcrumb',
      children: [
        LedgerBreadcrumb([
          LedgerCrumb('Accounts', onTap: () {}),
          LedgerCrumb('Everyday', onTap: () {}),
          const LedgerCrumb('October'),
        ]),
        LedgerBreadcrumb([
          LedgerCrumb('Budgets', onTap: () {}),
          LedgerCrumb('Household', onTap: () {}),
          LedgerCrumb('Groceries and the corner market', onTap: () {}),
          const LedgerCrumb('Week of October 26'),
        ]),
      ],
    ),
    kitSection(
      "A register's pages",
      children: const [_Pages(count: 9), _Pages(count: 4)],
    ),
    kitSection("A form's steps", children: const [_Steps()]),
    kitSection(
      'Page marks',
      children: const [_Dots(), LedgerPageDots(count: 3, index: 0)],
    ),
    kitSection(
      'The palette',
      children: [
        const LedgerCommandPalette(commands: _commands),
        Builder(
          builder: (context) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: LedgerButton(
              'Open the palette',
              size: LedgerButtonSize.medium,
              onPressed: () =>
                  showLedgerCommandPalette(context, commands: _commands),
            ),
          ),
        ),
      ],
    ),
  ],
);
