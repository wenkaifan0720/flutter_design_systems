/// What the ledger prints on its light paper ([LedgerSlip]): a
/// transaction's receipt ([LedgerReceipt]: the guilloche band, its kind and
/// number, the merchant, the engraved figure with its seal, the tear line
/// ([LedgerStub]) and its key and value lines), and a transfer drawn as a
/// cheque ([LedgerCheque]) as it is filled in, read back under review, and
/// sent with its stamp. Every word and figure is the pilot's (keel.dart).
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

Widget kitReceiptDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Receipts',
  sections: [
    kitSection(
      'A card purchase, pending',
      children: [kitSpan(KitSpan.main, kitSpecimenReceipt())],
    ),
    kitSection(
      'Money in',
      children: [kitSpan(KitSpan.main, kitSpecimenReceiptIncome())],
    ),
    kitSection(
      'The cheque, drawn',
      children: [kitSpan(KitSpan.main, kitSpecimenCheque())],
    ),
    kitSection(
      'The cheque, under review',
      children: [kitSpan(KitSpan.main, kitSpecimenChequeReview())],
    ),
    kitSection(
      'The cheque, sent',
      children: [kitSpan(KitSpan.main, kitSpecimenChequeSent())],
    ),
    kitSection(
      'A slip and its tear line',
      children: [kitSpan(KitSpan.margin, kitSpecimenSlip())],
    ),
    kitSection(
      'A page\'s own slip: the band and the head',
      children: [kitSpan(KitSpan.main, kitSpecimenSlipHead())],
    ),
  ],
);

/// A record's day as its seal stamps it: "Oct 28".
String _stamp(DateTime d) => LedgerFormat.date(d);

LedgerPickLine _from({bool balance = true, VoidCallback? onTap}) =>
    LedgerPickLine(
      label: 'From',
      icon: kitFrom.$1,
      name: kitFrom.$2,
      mask: kitFrom.$3,
      balance: balance ? kitFrom.$4 : null,
      note: balance ? 'Available' : null,
      onTap: onTap,
    );

LedgerPickLine _to({bool balance = true, VoidCallback? onTap}) =>
    LedgerPickLine(
      label: 'To',
      icon: kitTo.$1,
      name: kitTo.$2,
      mask: kitTo.$3,
      balance: balance ? kitTo.$4 : null,
      note: balance ? 'Balance' : null,
      onTap: onTap,
    );

/// The cheque's amount and note read back: no control left on it.
List<Widget> _readBack() => [
  const LedgerChequeAmount(
    label: 'Amount',
    words: kitTransferWords,
    unit: 'dollars',
    amount: kitTransferAmount,
  ),
  const LedgerRows(
    children: [
      LedgerKeyValue('Note', kitTransferNote),
      LedgerKeyValue('When', kitTransferWhen),
    ],
  ),
];

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// This morning's coffee, still pending on the Keel Card: the ink's seal,
/// and its category with the Change beside it.
Widget kitSpecimenReceipt() => LedgerReceipt(
  kind: 'Keel · Transaction',
  number: 'No. ${kitBlueFern.id.toUpperCase()}',
  leading: LedgerMonogram(kitBlueFern.title, size: LedgerMonogramSize.record),
  name: kitBlueFern.title,
  subtitle: '$kitBlueFernCategory · $kitBlueFernAccount',
  figure: LedgerFigure(kitBlueFern.amount),
  seal: LedgerSeal(
    kicker: kitBlueFern.account,
    value: 'Pending',
    foot: _stamp(kitBlueFern.at),
    tone: LedgerSealTone.plain,
  ),
  details: [
    const LedgerKeyValue('Status', 'Pending'),
    const LedgerKeyValue('Date', kitBlueFernLong),
    LedgerKeyValue('Time', kitBlueFern.time),
    const LedgerKeyValue('Card', kitBlueFernAccount),
    LedgerKeyValue(
      'Category',
      kitBlueFernCategory,
      action: LedgerButton(
        'Change',
        size: LedgerButtonSize.small,
        onPressed: () {},
      ),
    ),
  ],
);

/// The paycheck landed in Everyday: the green seal, the plus on the figure.
Widget kitSpecimenReceiptIncome() => LedgerReceipt(
  kind: 'Keel · Money in',
  number: 'No. ${kitPaycheck.id.toUpperCase()}',
  leading: LedgerMonogram(
    kitPaycheck.title,
    tone: LedgerMonogramTone.moneyIn,
    size: LedgerMonogramSize.record,
  ),
  name: kitPaycheck.title,
  subtitle: '${kitPaycheck.subtitle} · $kitPaycheckAccount',
  figure: LedgerFigure(
    kitPaycheck.amount,
    tone: LedgerFigureTone.moneyIn,
    showSign: true,
  ),
  seal: LedgerSeal(
    kicker: kitPaycheck.account,
    value: 'Received',
    foot: _stamp(kitPaycheck.at),
  ),
  details: [
    const LedgerKeyValue('Status', 'Posted'),
    const LedgerKeyValue('Date', kitPaycheckLong),
    LedgerKeyValue('Time', kitPaycheck.time),
    LedgerKeyValue('From', kitPaycheck.title),
    const LedgerKeyValue('To', kitPaycheckAccount),
  ],
);

/// The transfer as it is drawn: both accounts live with their balances,
/// the amount typed, its note, and when.
Widget kitSpecimenCheque() => KitTyped(
  kitTransferAmount.toStringAsFixed(2),
  (amount) => KitTyped(
    kitTransferNote,
    (note) => LedgerCheque(
      kind: 'Keel · Transfer',
      date: kitTransferDate,
      micr: kitMicr,
      lines: [
        _from(onTap: () {}),
        _to(onTap: () {}),
        LedgerChequeAmount(
          label: 'Amount',
          words: kitTransferWords,
          unit: 'dollars',
          controller: amount,
        ),
        LedgerField(label: 'Note', controller: note),
        LedgerField(
          label: 'When',
          child: LedgerSegmentedControl(
            options: const ['Today', 'Later'],
            value: 'Today',
            onChanged: (_) {},
          ),
        ),
      ],
    ),
  ),
);

/// The same cheque under review: read back in the ink, the balances kept.
Widget kitSpecimenChequeReview() => LedgerCheque(
  kind: 'Keel · Transfer',
  date: kitTransferDate,
  micr: kitMicr,
  lines: [_from(), _to(), ..._readBack()],
);

/// The cheque sent: the balances gone (the money has moved) and the stamp
/// pressed across it.
Widget kitSpecimenChequeSent() => LedgerCheque(
  kind: 'Keel · Transfer',
  date: kitTransferDate,
  micr: kitMicr,
  lines: [_from(balance: false), _to(balance: false), ..._readBack()],
  stamp: LedgerSeal(
    kicker: 'Keel · Transfer',
    value: 'Sent',
    foot: _stamp(kitNow),
  ),
);

/// A slip of the light paper holding a record's lines, torn off under them.
Widget kitSpecimenSlip() => LedgerSlip(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    // The lines kept off the slip's edges, as a receipt's are; the tear line
    // runs edge to edge, its notches cut from them.
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: LedgerRows(
          children: [
            const LedgerKeyValue('Status', 'Pending'),
            LedgerKeyValue('Time', kitBlueFern.time),
          ],
        ),
      ),
      const LedgerStub(),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 6),
        child: LedgerRows(
          children: [LedgerKeyValue('Card', kitBlueFernAccount)],
        ),
      ),
    ],
  ),
);

/// The new goal's form slip as the page prints it: the guilloche band,
/// then its kind and class over its first field.
// Keel · New goal, Savings, the Name field.
Widget kitSpecimenSlipHead() => LedgerSlip(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const LedgerSlipBand(),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LedgerSlipHead('Keel · New goal', 'Savings'),
            KitTyped(
              '',
              (name) => LedgerField(
                label: 'Name',
                controller: name,
                hint: 'What are you saving for?',
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
