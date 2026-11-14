/// What the chrome is built of: [LedgerButton] in its four kinds (the green
/// primary, the ink, the ringed secondary and the quiet), each enabled and
/// disabled, and two sharing a sheet's foot; [LedgerIconButton] bare and
/// ringed (the way back, the close) and [LedgerBell] with its unread dot;
/// the owner's [LedgerAvatar]; the brand ([LedgerBrandMark],
/// [LedgerWordmark]); and the [LedgerSeal] in its three inks. The words are
/// the source's.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitControlsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Controls',
  sections: [
    kitSection(
      'Buttons',
      children: [
        kitSpecimenButtonPrimary(),
        kitSpecimenButtonInk(),
        kitSpecimenButtonSecondary(),
        kitSpecimenButtonQuiet(),
      ],
    ),
    kitSection(
      "A memo's acts, compact",
      children: [kitSpecimenButtonCompact()],
    ),
    kitSection(
      'Disabled',
      children: [
        // One size to a row: a row of controls shows one top and one bottom.
        kitRow(const [
          LedgerButton.filled('Continue', onPressed: null),
          LedgerButton.ink('Freeze card', onPressed: null),
          LedgerButton('Cancel', onPressed: null),
        ]),
        kitRow(const [
          LedgerButton('Change', size: LedgerButtonSize.small, onPressed: null),
        ]),
      ],
    ),
    kitSection(
      "Two sharing a sheet's foot",
      children: [
        // As a confirm sheet's card holds them on the desktop: its 440 less
        // its sides, from the column's start (a phone's card is narrower).
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  LedgerSheet.dialogWidth(confirm: true) -
                  2 * LedgerChromeMetrics.dialogPad,
            ),
            child: LedgerSheetShell.footOf([
              LedgerButton('Cancel', onPressed: () {}),
              LedgerButton.ink(
                'Freeze card',
                icon: LucideIcons.snowflake,
                onPressed: () {},
              ),
            ]),
          ),
        ),
      ],
    ),
    kitSection('Icon buttons', children: [kitSpecimenIconButtons()]),
    kitSection(
      'Icon buttons, disabled',
      children: [
        kitRow(const [
          LedgerIconButton.outlined(
            LucideIcons.chevronLeft,
            semanticLabel: 'Back to Home',
            size: LedgerIconButtonSize.small,
            onPressed: null,
          ),
          LedgerIconButton(
            LucideIcons.bell,
            semanticLabel: 'Notifications',
            onPressed: null,
          ),
        ]),
      ],
    ),
    kitSection('The owner', children: [kitSpecimenAvatar()]),
    kitSection('The brand', children: [kitSpecimenBrand()]),
    kitSection('Seals', children: [kitSpecimenSeals()]),
    kitSection('Seal sizes', children: [kitSpecimenSealSizes()]),
  ],
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// The transfer's Continue, across its column, its arrow after the words.
Widget kitSpecimenButtonPrimary() => LedgerButton.filled(
  'Continue',
  icon: LucideIcons.arrowRight,
  iconAfter: true,
  expand: true,
  onPressed: () {},
);

/// The freeze dialog's firm act.
Widget kitSpecimenButtonInk() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: LedgerButton.ink(
    'Freeze card',
    icon: LucideIcons.snowflake,
    onPressed: () {},
  ),
);

/// Clear filters, as the empty search holds it.
Widget kitSpecimenButtonSecondary() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: LedgerButton('Clear filters', icon: LucideIcons.x, onPressed: () {}),
);

/// A category's Edit budget, as it stands at the end of its section's head.
Widget kitSpecimenButtonQuiet() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: LedgerButton(
    'Edit budget',
    size: LedgerButtonSize.small,
    icon: LucideIcons.pencil,
    onPressed: () {},
  ),
);

/// A goal behind its memo's acts (`.memo-acts`): its Add and Add money,
/// compact at 40.
Widget kitSpecimenButtonCompact() => Wrap(
  spacing: LedgerSpacing.s10,
  runSpacing: LedgerSpacing.s10,
  children: [
    LedgerButton.filled(
      'Add ${LedgerFormat.money(kitAddAmount, showCents: false)}',
      size: LedgerButtonSize.medium,
      onPressed: () {},
    ),
    LedgerButton(
      'Add money',
      size: LedgerButtonSize.medium,
      icon: LucideIcons.plus,
      onPressed: () {},
    ),
  ],
);

/// The way back and a sheet's close, ringed; the phone's bell bare and the
/// desktop's ringed, each wearing the unread dot. One size to a row.
Widget kitSpecimenIconButtons() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: LedgerSpacing.s16,
  children: [
    Row(
      spacing: LedgerSpacing.s16,
      children: [
        LedgerIconButton.outlined(
          LucideIcons.chevronLeft,
          semanticLabel: 'Back to Home',
          size: LedgerIconButtonSize.small,
          onPressed: () {},
        ),
        LedgerIconButton.outlined(
          LucideIcons.x,
          semanticLabel: 'Close',
          size: LedgerIconButtonSize.small,
          onPressed: () {},
        ),
      ],
    ),
    Row(
      spacing: LedgerSpacing.s16,
      children: [
        LedgerBell(unread: 1, onPressed: () {}),
        LedgerBell.outlined(unread: 1, onPressed: () {}),
      ],
    ),
  ],
);

Widget kitSpecimenAvatar() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: LedgerAvatar(
    initials: 'MH',
    label: 'Profile and settings',
    onTap: () {},
  ),
);

/// The ruled globe, and the wordmark as the phone's bar and the sidebar
/// head the app.
Widget kitSpecimenBrand() => const Row(
  spacing: LedgerSpacing.s24,
  children: [
    LedgerBrandMark(),
    LedgerWordmark('Keel'),
    LedgerWordmark('Keel', size: LedgerWordmarkSize.large),
  ],
);

/// The seal in its three inks, as the source presses them: October within
/// its budget (92% of 2,700 spent), Dining out over by 36.40, and the
/// empty search.
Widget kitSpecimenSeals() => Wrap(
  spacing: LedgerSpacing.s16,
  runSpacing: LedgerSpacing.s16,
  children: [
    LedgerSeal(
      kicker: LedgerFormat.month(kitNow),
      value: 'Within\nbudget',
      foot: '${LedgerFormat.percent(kitSpent, kitBudget)}% spent',
    ),
    // The month as a whole is within its budget; the one category over it
    // names itself, as the seal sizes' does.
    LedgerSeal(
      kicker: kitInsightCategory.split(' ').first,
      value: 'Over',
      foot: '+${LedgerFormat.money(kitOverBy)}',
      tone: LedgerSealTone.over,
    ),
    const LedgerSeal(
      kicker: 'Search',
      value: 'No\nentries',
      foot: 'October',
      tone: LedgerSealTone.plain,
    ),
  ],
);

/// The seal at each size it is pressed: beside a receipt's figure, on a
/// memo slip, as a sent transfer's stamp, and on the member's card.
Widget kitSpecimenSealSizes() => Wrap(
  spacing: LedgerSpacing.s16,
  runSpacing: LedgerSpacing.s16,
  crossAxisAlignment: WrapCrossAlignment.end,
  // Smallest to largest.
  children: [
    LedgerSeal(
      kicker: kitInsightCategory.split(' ').first,
      value: 'Over',
      foot: '+${LedgerFormat.money(kitInsightOver)}',
      tone: LedgerSealTone.over,
      size: LedgerSealSize.memo,
    ),
    LedgerSeal(
      kicker: 'Keel',
      value: 'Member',
      foot: 'Since ${kitMaren.meta!.split(' ').last}',
      size: LedgerSealSize.member,
    ),
    LedgerSeal(
      kicker: kitBlueFern.account,
      value: 'Pending',
      foot: LedgerFormat.date(kitBlueFern.at),
      tone: LedgerSealTone.plain,
      size: LedgerSealSize.receipt,
    ),
    LedgerSeal(
      kicker: 'Keel · Transfer',
      value: 'Sent',
      foot: LedgerFormat.date(kitNow),
      size: LedgerSealSize.stamp,
    ),
  ],
);
