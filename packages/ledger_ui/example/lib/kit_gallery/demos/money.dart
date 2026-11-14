/// Money as Ledger keeps it: the engraved figure a page leads with
/// ([LedgerFigure]: the serif, its `$` hung at the cap height, its cents
/// raised and underlined like a cheque's) in each size the source sets it,
/// the ledger amount of a row ([LedgerAmount]: the mono, its cents
/// receding) in each tone, the dot leader that joins a row's words to its
/// amount ([LedgerLeaderLine]), and the statement's double-ruled total
/// ([LedgerStatementTotal]). Every amount is the pilot's (the sample data).
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

Widget kitMoneyDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Money',
  sections: [
    kitSection(
      'The engraved figure',
      children: [
        _Labelled('hero · net worth', kitSpecimenFigureNetWorth()),
        _Labelled('receipt · a paycheck', kitSpecimenFigureReceipt()),
        _Labelled('hero · past its budget', kitSpecimenFigureOver()),
        _Labelled('card · owed on the card', kitSpecimenFigureCard()),
        _Labelled('entry · under review', kitSpecimenFigureEntry()),
        _Labelled('section · October so far', kitSpecimenFigureSection()),
        const _Labelled(
          'small',
          LedgerFigure(84.25, size: LedgerFigureSize.small),
        ),
        const _Labelled(
          'whole dollars · a goal saved',
          LedgerFigure(2840, showCents: false, size: LedgerFigureSize.section),
        ),
      ],
    ),
    kitSection('Amounts in rows', children: [kitSpecimenAmounts()]),
    kitSection(
      'Amount sizes',
      children: [
        kitRow(const [
          LedgerAmount(-64.18),
          LedgerAmount(78182.56, size: LedgerAmountSize.total),
          LedgerAmount(412.36, size: LedgerAmountSize.small),
        ]),
      ],
    ),
    kitSection("A holding's today", children: [kitSpecimenAmountToday()]),
    kitSection('Leader lines', children: [kitSpecimenLeaderLines()]),
    kitSection('A statement', children: [kitSpecimenStatement()]),
  ],
);

class _Labelled extends StatelessWidget {
  const _Labelled(this.label, this.child);

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: LedgerSpacing.s4,
      children: [
        Text(label.toUpperCase(), style: t.meta.colored(t.textTertiary)),
        child,
      ],
    );
  }
}

/// Maren's accounts and their balances, the card's owed balance netted out.
const _accounts = <(String, num)>[
  ('Everyday', 6248.30),
  ('Savings', 21500.00),
  ('Lisbon fund', 2840.00),
  ('Keel Card', -1326.44),
  ('Investing', 48920.70),
];

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// A page's figures stand at the start of its column.
Widget _atStart(Widget figure) =>
    Align(alignment: AlignmentDirectional.centerStart, child: figure);

/// Home's head: the net worth.
Widget kitSpecimenFigureNetWorth() =>
    _atStart(const LedgerFigure(78182.56, size: LedgerFigureSize.hero));

/// A paycheck's receipt: money in, green, its plus.
Widget kitSpecimenFigureReceipt() => _atStart(
  const LedgerFigure(
    3412.50,
    tone: LedgerFigureTone.moneyIn,
    showSign: true,
    size: LedgerFigureSize.receipt,
  ),
);

/// Dining out's October, past its 250 budget.
Widget kitSpecimenFigureOver() => _atStart(
  const LedgerFigure(
    286.40,
    tone: LedgerFigureTone.over,
    size: LedgerFigureSize.hero,
  ),
);

/// The card's balance beside the card: what is owed on it.
Widget kitSpecimenFigureCard() =>
    _atStart(const LedgerFigure(1326.44, size: LedgerFigureSize.card));

/// The transfer under review.
Widget kitSpecimenFigureEntry() =>
    _atStart(const LedgerFigure(500, size: LedgerFigureSize.entry));

/// October's spending so far, a section's figure.
Widget kitSpecimenFigureSection() =>
    _atStart(const LedgerFigure(2486.12, size: LedgerFigureSize.section));

/// Amounts as the activity sets them, each joined to its words by the dot
/// leader: a purchase in the ink, a paycheck in the green with its plus, a
/// move between Maren's own accounts quiet, and a category past its budget
/// in the vermilion.
Widget kitSpecimenAmounts() => Builder(
  builder: (context) {
    final t = context.ledgerTheme;
    Widget line(String words, Widget amount) => Padding(
      padding: const EdgeInsets.symmetric(vertical: LedgerSpacing.s12),
      child: LedgerLeaderLine(
        start: Text(words, style: t.rowTitle),
        end: amount,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line('Blue Fern Café', const LedgerAmount.entry(-6.75)),
        line('Northwind Studio', const LedgerAmount.entry(3412.50)),
        line('To Savings', const LedgerAmount.entry(-500, moved: true)),
        line('Dining out', const LedgerAmount(286.40, tone: LedgerTone.over)),
      ],
    );
  },
);

/// Home's accounts, each balance joined to its name by the dot leader.
/// Investing's change today as a holding's line sets it: 12 on 20, green.
Widget kitSpecimenAmountToday() => _atStart(
  const LedgerAmount(
    391.37,
    size: LedgerAmountSize.today,
    tone: LedgerTone.moneyIn,
    showSign: true,
  ),
);

Widget kitSpecimenLeaderLines() => Builder(
  builder: (context) {
    final t = context.ledgerTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (name, balance) in _accounts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: LedgerSpacing.s12),
            child: LedgerLeaderLine(
              start: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.rowTitle,
              ),
              end: LedgerAmount(balance),
            ),
          ),
      ],
    );
  },
);

/// Home's accounts as a statement: each balance on its dot leader, then the
/// double rule and the net worth they sum to.
Widget kitSpecimenStatement() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    kitSpecimenLeaderLines(),
    const LedgerStatementTotal(title: 'Net worth', amount: 78182.56),
  ],
);
