/// The ledger's ornaments, engraved as a banknote's are: the guilloche
/// rosette ([LedgerGuilloche]) behind a card's face and as Home's
/// watermark ([LedgerWatermark], standing as a screen's backdrop), the
/// interlaced band at a receipt's head ([LedgerGuillocheBand]), the card's
/// engraved chip ([LedgerCardChip]) and a stub's perforation
/// ([LedgerPerforation]). None says anything to a screen reader.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

Widget kitEngravingsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Engravings',
  sections: [
    kitSection('The rosette', children: [kitSpecimenGuilloche()]),
    kitSection('The band', children: [kitSpecimenGuillocheBand()]),
    kitSection('The chip', children: [kitSpecimenCardChip()]),
    kitSection('The perforation', children: [kitSpecimenPerforation()]),
    kitSection(
      "Home's watermark, behind its column",
      children: [kitSpan(KitSpan.full, kitSpecimenWatermark())],
    ),
  ],
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// The rosette at the phone card's size, in the green.
Widget kitSpecimenGuilloche() => const Align(
  alignment: AlignmentDirectional.centerStart,
  child: LedgerGuilloche(size: 320),
);

/// A receipt's band, across its slip.
Widget kitSpecimenGuillocheBand() => const LedgerGuillocheBand();

/// The chip as the debit card's paper stock engraves it, in the ink, at the
/// phone card's 42 by 32.
Widget kitSpecimenCardChip() => Builder(
  builder: (context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: LedgerCardChip(
      width: 42,
      height: 32,
      color: context.ledgerTheme.textPrimary,
    ),
  ),
);

/// A stub's row of holes, across a slip.
Widget kitSpecimenPerforation() => const LedgerPerforation();

/// Home's watermark over its masthead's corner: the rosette fading out
/// down the phone, beside the hero figure on the desktop.
Widget kitSpecimenWatermark() => const SizedBox(
  height: 480,
  child: Stack(clipBehavior: Clip.hardEdge, children: [LedgerWatermark()]),
);
