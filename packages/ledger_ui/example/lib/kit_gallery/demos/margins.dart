/// What a ledger keeps in its margins: rules between parts, a count on a
/// control, detail folded under a line, a record's timeline and a picture.
/// Every one is live.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitMarginsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Margins',
  sections: [
    kitSection(
      'Rules',
      children: const [
        LedgerDivider(),
        LedgerDivider(strong: true),
        LedgerDivider(total: true),
        LedgerDivider(label: 'Earlier'),
      ],
    ),
    kitSection(
      'Counts',
      children: [
        kitRow([
          LedgerBadge(
            count: 3,
            child: LedgerIconButton.outlined(
              LucideIcons.inbox,
              semanticLabel: 'Inbox',
              tapAlignment: AlignmentDirectional.centerStart,
              onPressed: () {},
            ),
          ),
          LedgerBadge(
            count: 120,
            urgent: true,
            label: 'to file',
            child: LedgerIconButton.outlined(
              LucideIcons.fileText,
              semanticLabel: 'Receipts',
              onPressed: () {},
            ),
          ),
          LedgerBadge(
            child: LedgerIconButton.outlined(
              LucideIcons.bell,
              semanticLabel: 'Notifications',
              onPressed: () {},
            ),
          ),
        ]),
      ],
    ),
    kitSection(
      'Folded',
      children: const [
        LedgerDisclosure(
          title: 'Fees',
          note: r'$2.40',
          child: Text(
            'A card fee of \$1.90 and a foreign exchange fee of 50¢.',
          ),
        ),
        LedgerDisclosure(
          title: 'Terms of the transfer',
          initiallyOpen: true,
          child: Text(
            'It arrives in one to two working days. A transfer sent after '
            '6 pm leaves the next working morning.',
          ),
        ),
      ],
    ),
    kitSection(
      "A transfer's way",
      children: const [
        LedgerTimeline(
          entries: [
            LedgerTimelineEntry(
              when: 'Oct 26 · 9:41',
              title: 'Sent',
              note: 'From Everyday to Northside Rent',
            ),
            LedgerTimelineEntry(when: 'Oct 27 · 6:02', title: 'Cleared'),
            LedgerTimelineEntry(
              when: 'Oct 28',
              title: 'Posting',
              note: 'Usually by noon',
              state: LedgerTimelineState.current,
            ),
            LedgerTimelineEntry(
              when: 'Oct 29',
              title: 'In their account',
              state: LedgerTimelineState.upcoming,
            ),
          ],
        ),
      ],
    ),
    kitSection(
      'A receipt, its photo still to come',
      children: const [
        SizedBox(
          width: 240,
          child: LedgerMedia(caption: 'Corner Market, Oct 27'),
        ),
      ],
    ),
  ],
);
