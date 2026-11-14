/// What the ledger tells its owner: a notification's row ([LedgerNoteRow]:
/// its glyph, its title on the leader to when, its words under it; an
/// unread one on the green wash, tagged New) and one line of what an act
/// does ([LedgerEffect]: what freezing the card stops, ringed in the ink,
/// and what still goes through). Every word is the pilot's (keel.dart).
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitNoticeDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Notices',
  sections: [
    kitSection(
      'Unread, under its head',
      children: [kitSpan(KitSpan.main, kitSpecimenNoteUnread())],
    ),
    kitSection(
      'Earlier',
      children: [kitSpan(KitSpan.main, kitSpecimenNoteRows())],
    ),
    kitSection(
      'What freezing does',
      children: [kitSpan(KitSpan.margin, kitSpecimenEffects())],
    ),
    kitSection(
      'Effects, a hairline between',
      children: [kitSpan(KitSpan.margin, kitSpecimenEffectsRuled())],
    ),
  ],
);

LedgerNoteRow _note(KitNote n) => LedgerNoteRow(
  icon: n.icon,
  title: n.title,
  body: n.body,
  when: n.when,
  unread: n.unread,
  onTap: () {},
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// The one unread notification: the rent due in four days.
Widget kitSpecimenNoteUnread() => LedgerSection(
  head: LedgerHead(
    'New',
    note: '${kitNotes.where((n) => n.unread).length} unread',
  ),
  child: LedgerRows(
    children: <LedgerNoteRow>[
      for (final n in kitNotes.where((n) => n.unread)) _note(n),
    ],
  ),
);

/// The notifications already read, newest first.
Widget kitSpecimenNoteRows() => LedgerRows(
  children: <LedgerNoteRow>[
    for (final n in kitNotes.where((n) => !n.unread)) _note(n),
  ],
);

/// What freezing the Keel Card stops, and what still goes through: the
/// card's autopay on its due day.
Widget kitSpecimenEffects() {
  final autopay = kitBills.firstWhere((b) => b.autopay);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
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
            'Autopay on ${LedgerFormat.date(autopay.due)}, refunds and '
            'payments.',
      ),
    ],
  );
}

/// The same two effects as the freeze dialog stands them: 6 under its
/// lead, a hairline between them.
Widget kitSpecimenEffectsRuled() {
  final autopay = kitBills.firstWhere((b) => b.autopay);
  return LedgerEffects(
    children: [
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
            'Autopay on ${LedgerFormat.date(autopay.due)}, refunds and '
            'payments.',
      ),
    ],
  );
}
