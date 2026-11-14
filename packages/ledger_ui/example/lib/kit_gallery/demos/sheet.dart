/// Ledger's sheets: [LedgerSheet.show] raising a sheet over the whole app
/// (off the bottom edge on a phone over the scrim, a centred dialog from
/// 1024 wide) and completing when it closes, and the same card drawn in
/// place ([LedgerSheetShell]: its head over the ink rule, its body and its
/// foot of acts). The words are the source's: the Cards page's freeze
/// dialog and the Goals page's Add money.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitSheetDemo(Brightness brightness) =>
    kitScreen(brightness: brightness, title: 'Sheet', sections: [_Raise()]);

class _Raise extends StatefulWidget {
  @override
  State<_Raise> createState() => _RaiseState();
}

class _RaiseState extends State<_Raise> {
  @override
  // Its three sections stand apart as a page's do (kitScreen's 32).
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: LedgerSpacing.s32,
    children: [
      kitSection(
        'Raised',
        children: [
          kitRow([
            LedgerButton(
              'Freeze card',
              icon: LucideIcons.snowflake,
              onPressed: () => LedgerSheet.show<void>(
                context,
                title: 'Freeze your Keel Card?',
                confirm: true,
                builder: (sheet) => const [_FreezeBody()],
                foot: (sheet) => _freezeActs(() => Navigator.of(sheet).pop()),
              ),
            ),
            LedgerButton(
              'Add money',
              icon: LucideIcons.plus,
              onPressed: () => LedgerSheet.show<void>(
                context,
                title: 'Add money',
                builder: (sheet) => const [_AddBody()],
                foot: (sheet) => [
                  LedgerButton.filled(
                    'Add ${LedgerFormat.money(110, showCents: false)} to Lisbon',
                    onPressed: () {
                      Navigator.of(sheet).pop();
                      LedgerToast.show(
                        context,
                        'Added ${LedgerFormat.money(110, showCents: false)} to '
                        'Lisbon in May',
                      );
                    },
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
      kitSection('In place', children: [_asRaised(kitSpecimenSheetAdd())]),
      kitSection(
        'A dialog with two acts',
        children: [_asRaised(kitSpecimenSheetFreeze(), confirm: true)],
      ),
    ],
  );
}

/// A card drawn in place as the raised one stands on the desktop: the
/// dialog's width (440 for a question, 480 for a task) from the column's
/// start, so the same dialog looks the same in place and raised. Under
/// 1024 the raised one spans its window, as this its column.
Widget _asRaised(Widget card, {bool confirm = false}) => Builder(
  builder: (context) => LedgerLayout.isWide(context)
      ? Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: LedgerSheet.dialogWidth(confirm: confirm),
            child: card,
          ),
        )
      : card,
);

/// The freeze dialog's acts: Cancel ringed in the ink, Freeze card in the
/// ink.
List<Widget> _freezeActs(VoidCallback close) => [
  LedgerButton('Cancel', onPressed: close),
  LedgerButton.ink(
    'Freeze card',
    icon: LucideIcons.snowflake,
    onPressed: close,
  ),
];

/// The freeze dialog's body (`.dialog-lead`, `.effects`): its lead in the
/// serif (22 on 27), then what freezing declines and what still goes
/// through, each by its ringed glyph (36, its glyph 16), 14 apart, ruled
/// in the hairline between, the words 14 on 20 in the second ink under
/// their head in the ink at 600.
class _FreezeBody extends StatelessWidget {
  const _FreezeBody();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const LedgerDialogLead(
        'Freezing stops the card, not the account.\nUnfreeze it any time.',
      ),
      LedgerEffects(
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
            // The card's autopay date (the sample data: due 2026-11-12).
            text:
                'Autopay on ${LedgerFormat.date(DateTime(2026, 11, 12))}, '
                'refunds and payments.',
          ),
        ],
      ),
    ],
  );
}

/// A ringed glyph (`.effect .glyph`): 36 round on the raised paper, ringed
/// in the rule (in the ink with [ink]), its glyph 16 in the ink.
/// Add money's body, as the Goals page raises it for Lisbon in May
/// (the sample data's add-to-goal example: 110 from Everyday): the note,
/// then what the goal holds after, joined by the dot leader, over its sum.
class _AddBody extends StatelessWidget {
  const _AddBody();

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final note = t.bodySmall.colored(t.textTertiary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: LedgerSpacing.s6,
            bottom: LedgerSpacing.s4,
          ),
          child: Text('Into Lisbon in May · held in Lisbon fund', style: note),
        ),
        // `.add-after`: margin-top 18px.
        const SizedBox(height: 18),
        LedgerSavedAfter(
          value:
              '${LedgerFormat.money(2950, showCents: false)} · '
              '${LedgerFormat.percent(2950, 4000)}%',
          ratio: 2950 / 4000,
          subtitle:
              '${LedgerFormat.money(2840, showCents: false)} saved + '
              '${LedgerFormat.money(110, showCents: false)}',
          trailingSubtitle: 'of ${LedgerFormat.money(4000, showCents: false)}',
        ),
      ],
    );
  }
}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

Widget kitSpecimenSheetAdd() => LedgerSheetShell(
  title: 'Add money',
  foot: [
    LedgerButton.filled(
      'Add ${LedgerFormat.money(110, showCents: false)} to Lisbon',
      onPressed: () {},
    ),
  ],
  children: const [_AddBody()],
);

Widget kitSpecimenSheetFreeze() => LedgerSheetShell(
  title: 'Freeze your Keel Card?',
  foot: _freezeActs(() {}),
  children: const [_FreezeBody()],
);
