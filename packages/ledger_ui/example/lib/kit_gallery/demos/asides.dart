/// What stands beside or over a page for a moment: a side sheet of filters,
/// an action sheet of a receipt's acts, a popover's working-out, a tooltip
/// on a glyph, and notices in the page's flow. Every one is live.
library;

import 'package:material_ui/material_ui.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitAsidesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Asides',
  sections: const [_Raised(), _Notices()],
);

/// The sheets and slips that open from a control, and what they answered.
class _Raised extends StatefulWidget {
  const _Raised();

  @override
  State<_Raised> createState() => _RaisedState();
}

class _RaisedState extends State<_Raised> {
  String _said = 'Nothing chosen yet.';

  Future<void> _filters() async {
    final applied = await showLedgerSideSheet<bool>(
      context,
      title: 'Filters',
      builder: (context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LedgerSpacing.s16,
        children: [
          LedgerSegmentedControl(options: ['All', 'In', 'Out'], value: 'All'),
          Text('Everyday, Savings and the Keel Card.'),
        ],
      ),
      foot: (context) => [
        LedgerButton.filled(
          'Apply',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (mounted) {
      setState(
        () => _said = applied == true ? 'Filters applied.' : 'Filters left.',
      );
    }
  }

  Future<void> _receipt() async {
    final act = await showLedgerActionSheet<String>(
      context,
      title: 'Receipt',
      message: 'Corner Market, Oct 27, \$64.18',
      acts: const [
        LedgerSheetAct(
          'Replace the photo',
          value: 'Replaced',
          icon: LucideIcons.camera,
        ),
        LedgerSheetAct(
          'Download',
          value: 'Downloaded',
          icon: LucideIcons.download,
        ),
        LedgerSheetAct(
          'Delete',
          value: 'Deleted',
          icon: LucideIcons.trash2,
          destructive: true,
        ),
      ],
    );
    if (mounted) setState(() => _said = act == null ? 'Cancelled.' : '$act.');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return kitSection(
      'Raised from a control',
      children: [
        kitRow([
          LedgerButton(
            'Filters',
            icon: LucideIcons.slidersHorizontal,
            size: LedgerButtonSize.medium,
            onPressed: _filters,
          ),
          LedgerButton(
            'Receipt',
            icon: LucideIcons.receipt,
            size: LedgerButtonSize.medium,
            onPressed: _receipt,
          ),
          LedgerPopover(
            semanticLabel: 'How Safe to spend is worked out',
            title: 'Safe to spend',
            anchor: (context, a) => LedgerButton.text(
              'How is this worked out?',
              size: LedgerButtonSize.medium,
              onPressed: a.toggle,
            ),
            child: const Text(
              'Your balance less the bills due before payday and what you '
              'set aside for goals.',
            ),
          ),
          LedgerTooltip(
            message: 'Export as CSV',
            child: LedgerIconButton.outlined(
              LucideIcons.download,
              semanticLabel: 'Export',
              onPressed: () => setState(() => _said = 'Exported.'),
            ),
          ),
        ]),
        Text(_said, style: t.bodySmall.colored(t.textSecondary)),
      ],
    );
  }
}

/// Notices in the page's flow, one of each tone; the closable one goes.
class _Notices extends StatefulWidget {
  const _Notices();

  @override
  State<_Notices> createState() => _NoticesState();
}

class _NoticesState extends State<_Notices> {
  bool _shown = true;

  @override
  Widget build(BuildContext context) => kitSection(
    'In the page',
    children: [
      LedgerBanner(
        title: 'Your October statement is ready',
        text: 'Every entry from Oct 1 to Oct 31, with the month\'s totals.',
        actionLabel: 'Open',
        onAction: () {},
      ),
      const LedgerBanner(
        title: 'The transfer to Savings cleared',
        tone: LedgerBannerTone.done,
      ),
      const LedgerBanner(
        title: 'Rent is due before payday',
        text: '\$1,150.00 on Nov 1; payday is Nov 3.',
        tone: LedgerBannerTone.mind,
      ),
      if (_shown)
        LedgerBanner(
          title: 'Your card was declined at Blue Fern Café',
          text: 'The card is frozen. Unfreeze it to pay with it again.',
          tone: LedgerBannerTone.wrong,
          onDismiss: () => setState(() => _shown = false),
        )
      else
        LedgerButton.text(
          'Show the declined notice again',
          size: LedgerButtonSize.medium,
          onPressed: () => setState(() => _shown = true),
        ),
    ],
  );
}
