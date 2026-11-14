/// The payment cards' faces, printed like banknotes ([LedgerCardFace]): the
/// Keel Card on its ink stock, the Everyday debit card small on its paper,
/// and the Keel Card frozen under its frost with the ink's seal pressed
/// across its corner. Every word and number is the pilot's (keel.dart).
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

Widget kitCardDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Cards',
  sections: [
    kitSection(
      'The credit card',
      children: [kitSpan(KitSpan.main, kitSpecimenCardCredit())],
    ),
    kitSection(
      'The debit card, small',
      children: [kitSpan(KitSpan.margin, kitSpecimenCardDebit())],
    ),
    kitSection(
      'Frozen',
      children: [kitSpan(KitSpan.main, kitSpecimenCardFrozen())],
    ),
    kitSection(
      'Its details, shown',
      children: [kitSpan(KitSpan.margin, kitSpecimenCardDetails())],
    ),
  ],
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// The Keel Card, ending 7730, on the ink stock.
Widget kitSpecimenCardCredit() => const LedgerCardFace(
  brand: 'Keel',
  kind: kitCardKind,
  number: kitCardNumber,
  holder: kitCardHolder,
  account: kitCardAccount,
);

/// Everyday's debit card, ending 3907: the paper stock, small, as the
/// Cards page stands it in its margin.
Widget kitSpecimenCardDebit() => const LedgerCardFace(
  brand: 'Keel',
  kind: kitDebitKind,
  number: kitDebitNumber,
  holder: kitDebitHolder,
  account: kitDebitAccount,
  stock: LedgerCardStock.debit,
  size: LedgerCardSize.small,
);

/// The Keel Card frozen today: the frost over its face, its account
/// dropped, the ink's seal across its corner.
Widget kitSpecimenCardFrozen() => const LedgerCardFace(
  brand: 'Keel',
  kind: kitCardKind,
  number: kitCardNumber,
  holder: kitCardHolder,
  account: kitCardAccount,
  frozen: true,
  seal: LedgerSeal(
    kicker: kitCardName,
    value: 'Frozen',
    foot: kitFrozenOn,
    tone: LedgerSealTone.plain,
  ),
);

/// The Keel Card's details as its sheet shows them: the whole number, its
/// expiry and CVC, and the name on it.
// expires 09/29, CVC
// 317, the owner's name as written.
Widget kitSpecimenCardDetails() => const LedgerCardDetails(
  number: kitCardNumber,
  expiry: '09/29',
  cvc: '317',
  name: 'Maren Holt',
);
