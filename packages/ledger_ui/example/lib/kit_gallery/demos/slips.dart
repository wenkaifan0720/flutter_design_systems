/// The slips and memos the pages print on the light paper beyond the
/// receipt and the cheque: the card's statement ([LedgerStatementSlip]),
/// the spending memo ([LedgerMemo]) and a goal's memo slip
/// ([LedgerMemoSlip]), the frozen card's notice ([LedgerFrozenBanner]), the
/// transfer's done head ([LedgerDoneHead]), the split ticket
/// ([LedgerSplitTicket]), what a goal holds after the money lands
/// ([LedgerSavedAfter]) and the row summing the contributions before
/// ([LedgerBeforeRow]). Every word and figure is the pilot's (keel.dart,
/// else the source page named beside it).
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitSlipsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Slips & memos',
  sections: [
    kitSection(
      'The statement',
      children: [kitSpan(KitSpan.main, kitSpecimenStatementSlip())],
    ),
    kitSection(
      'A memo',
      children: [kitSpan(KitSpan.margin, kitSpecimenMemo())],
    ),
    kitSection(
      'A goal\'s memo slip',
      children: [kitSpan(KitSpan.margin, kitSpecimenMemoSlip())],
    ),
    kitSection(
      'The card, frozen',
      children: [kitSpan(KitSpan.main, kitSpecimenFrozenBanner())],
    ),
    kitSection(
      'Done',
      children: [kitSpan(KitSpan.main, kitSpecimenDoneHead())],
    ),
    kitSection(
      'The split ticket',
      children: [kitSpan(KitSpan.main, kitSpecimenSplitTicket())],
    ),
    kitSection(
      'Saved after',
      children: [kitSpan(KitSpan.margin, kitSpecimenSavedAfter())],
    ),
    kitSection(
      'Saved before',
      children: [kitSpan(KitSpan.main, kitSpecimenBeforeRow())],
    ),
  ],
);

/// The Keel Card's payment: due Nov 12, paid by autopay from Everyday.
KitBill get _cardBill => kitBills.firstWhere((b) => b.autopay);

/// The goal behind: Lisbon in May.
KitGoal get _lisbon => kitGoals.firstWhere((g) => g.behind);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// The Keel Card's October statement: $1,326.44 due Nov 12, autopay from
/// Everyday, and its last payment.
Widget kitSpecimenStatementSlip() => LedgerStatementSlip(
  kind: '$kitCardName · Statement',
  number: '··${kitCardNumber.last}',
  balance: _cardBill.amount,
  due: LedgerFormat.date(_cardBill.due),
  // Calendar days, as the source counts them (capture: In 15 days).
  dueNote: LedgerFormat.inDays(_cardBill.due, now: kitNow),
  details: [
    // closed today, the full balance, from Everyday.
    LedgerKeyValue('Closed', 'Today · ${LedgerFormat.date(kitNow)}'),
    const LedgerKeyValue('Autopay', 'Full balance'),
    LedgerKeyValue('Paid from', _cardBill.account),
  ],
  // the last payment, $1,180.22 on
  // Oct 12 from Everyday.
  last: LedgerRow(
    leading: const LedgerGlyph(
      LucideIcons.creditCard,
      tone: LedgerGlyphTone.move,
    ),
    title: 'Last payment',
    value: const LedgerAmount(1180.22),
    subtitle: 'Oct 12 · from Everyday',
    onTap: () {},
  ),
);

/// October's spending memo: Dining out over budget, and the café that
/// took it there.
Widget kitSpecimenMemo() => LedgerMemo(
  text: '$kitInsightCategory is\n',
  over: '${LedgerFormat.money(kitInsightOver)} over',
  textAfter: '\nbudget.',
  seal: LedgerSeal(
    kicker: kitInsightCategory.split(' ').first,
    value: 'Over',
    foot: '+${LedgerFormat.money(kitInsightOver)}',
    tone: LedgerSealTone.over,
  ),
  leading: const LedgerMonogram(
    kitInsightMerchant,
    size: LedgerMonogramSize.dense,
  ),
  note: '$kitInsightVisits visits to $kitInsightMerchant\ncame to ',
  noteAmount: LedgerFormat.money(kitInsightAmount),
  noteAfter: '.',
  onTap: () {},
);

/// Lisbon in May, behind: its note, and the two ways to add to it.
Widget kitSpecimenMemoSlip() => LedgerMemoSlip(
  label: _lisbon.status,
  note: _lisbon.note,
  actions: [
    // `.memo-acts .btn`: the compact 40.
    LedgerButton.filled(
      'Add ${LedgerFormat.money(kitAddAmount, showCents: false)}',
      size: LedgerButtonSize.medium,
      onPressed: () {},
    ),
    LedgerButton(
      'Add money',
      icon: LucideIcons.plus,
      size: LedgerButtonSize.medium,
      onPressed: () {},
    ),
  ],
);

/// The Keel Card frozen this evening: nothing cancelled, what it stops and
/// what still goes through, and Unfreeze card.
Widget kitSpecimenFrozenBanner() => LedgerFrozenBanner(
  // "Frozen today at" the page's time (capture: 7:40 PM).
  title: 'Frozen today at 7:40 PM',
  text: 'Nothing is cancelled. Unfreeze it any time.',
  effects: [
    const LedgerEffect(
      icon: LucideIcons.ban,
      title: 'Declined',
      text: 'New purchases and cash withdrawals.',
      blocking: true,
    ),
    LedgerEffect(
      icon: LucideIcons.check,
      title: 'Still goes through',
      text:
          'Autopay on ${LedgerFormat.date(_cardBill.due)}, refunds and '
          'payments.',
    ),
  ],
  actionLabel: 'Unfreeze card',
  onActionPressed: () {},
);

/// The transfer sent: $500.00 on its way to Savings.
Widget kitSpecimenDoneHead() => LedgerDoneHead(
  // "Transfer sent ·" the page's time (capture: 7:40 PM).
  meta: 'Transfer sent · 7:40 PM',
  title: '${LedgerFormat.money(kitTransferAmount)} is on its way to',
  emphasis: kitTo.$2,
);

/// The cinema split evenly: Maren paid, Jonah owes half.
// Cinema Lumen on Mon, Oct 26,
// $28.00, $14.00 each, with Jonah Reyes.
Widget kitSpecimenSplitTicket() => const LedgerSplitTicket(
  start: 'Cinema Lumen · Mon, Oct 26',
  end: 'Total \$28.00',
  mine: LedgerSplitHalf(
    name: _holderName,
    initials: 'MH',
    note: 'Your half',
    amount: 14,
  ),
  theirs: LedgerSplitHalf(
    name: 'Jonah Reyes',
    initials: 'JR',
    note: 'Owes you',
    amount: 14,
  ),
);

/// Lisbon in May after this month's $110: $2,950 of $4,000.
Widget kitSpecimenSavedAfter() {
  final after = _lisbon.saved + kitAddAmount;
  return LedgerSavedAfter(
    value:
        '${LedgerFormat.money(after, showCents: false)} · '
        '${(after / _lisbon.target * 100).round()}%',
    ratio: after / _lisbon.target,
    subtitle:
        '${LedgerFormat.money(_lisbon.saved, showCents: false)} saved + '
        '${LedgerFormat.money(kitAddAmount, showCents: false)}',
    trailingSubtitle:
        'of ${LedgerFormat.money(_lisbon.target, showCents: false)}',
  );
}

/// Lisbon's contributions before the eight shown, summed on one row.
// six contributions before Apr 1,
// +$1,390.00.
Widget kitSpecimenBeforeRow() => const LedgerBeforeRow(
  title: 'Saved before Apr 1',
  value: LedgerAmount(1390, tone: LedgerTone.moneyIn, showSign: true),
  subtitle: '6 contributions',
);

/// The holder's name as the owner writes it (`D["person"]`;
/// the card prints it in capitals: kitCardHolder).
const String _holderName = 'Maren Holt';
