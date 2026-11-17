/// What a page asks and commits: the dialog ([LedgerDialog]) in its three
/// kinds, the action bar ([LedgerActionBar]) docked, alone and floating, and
/// the composer ([LedgerComposer]) for messages and for an assistant. The
/// first section is live: each opens the real dialog. The words are a
/// stationery studio's books, not the pilot's.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitCommitDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Dialog & action bar',
  sections: [
    kitSection('Live', children: [const _Live()]),
    kitSection(
      'Action bar, docked',
      children: [_docked(kitSpecimenActionBarDocked())],
    ),
    kitSection(
      'Action bar, alone',
      children: [_docked(kitSpecimenActionBarAlone())],
    ),
    kitSection(
      'Action bar, floating',
      children: [kitSpecimenActionBarFloating()],
    ),
    kitSection('Composer, messages', children: [kitSpecimenComposerMessages()]),
    kitSection('Composer, drafted', children: [kitSpecimenComposerDrafted()]),
    kitSection(
      'Composer, assistant',
      children: [kitSpecimenComposerAssistant()],
    ),
  ],
);

/// A docked bar as its screen stands it: its band runs its own gutter past
/// the column at each side, so its total and its act stand on the column's
/// edges as the page's words do. On the gallery's page the band's hairline
/// is cut at the column, so it ends where the page's rules do; below the
/// hairline nothing is cut, so the act's drop falls whole past the column.
Widget _docked(Widget bar) => ClipPath(
  clipper: const _HairlineAtColumn(),
  child: KitBleed(by: LedgerChromeMetrics.gutter, child: bar),
);

/// Cuts the band's top line (its hairline) at the column's edges and leaves
/// the rest of the band, the act's drop with it, room to fall past them.
class _HairlineAtColumn extends CustomClipper<Path> {
  const _HairlineAtColumn();

  /// The band's hairline and the row it stands on.
  static const double _line = 2;

  /// How far past the column the act's drop may fall: past its blur.
  static const double _drop = 40;

  @override
  Path getClip(Size size) => Path()
    ..addRect(Rect.fromLTWH(0, 0, size.width, _line))
    ..addRect(
      Rect.fromLTRB(-_drop, _line, size.width + _drop, size.height + _drop),
    );

  // What it lets through, for a reader of its bounds (ui_core's shadow
  // check): the drop's room past the column, not the column alone.
  @override
  Rect getApproximateClipRect(Size size) =>
      Rect.fromLTRB(-_drop, 0, size.width + _drop, size.height + _drop);

  @override
  bool shouldReclip(_HairlineAtColumn oldClipper) => false;
}

/// [child] laid out [by] wider at each side than its slot, as tall as it is.
class _Live extends StatefulWidget {
  const _Live();

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  String _said = 'Nothing asked yet';
  bool _busy = false;

  Future<void> _ask(
    LedgerDialogType kind,
    String title,
    String? confirm,
  ) async {
    final yes = await LedgerDialog.show(
      context,
      title: title,
      body: _body(kind),
      type: kind,
      confirmLabel: confirm,
    );
    if (mounted) setState(() => _said = 'Answered: ${yes ?? 'dismissed'}');
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: LedgerSpacing.s12,
    children: [
      LedgerButton(
        'Archive October',
        onPressed: () =>
            _ask(LedgerDialogType.confirm, 'Archive October?', 'Archive'),
      ),
      LedgerButton(
        'Delete the entry',
        onPressed: () =>
            _ask(LedgerDialogType.destructive, 'Delete this entry?', 'Delete'),
      ),
      LedgerButton(
        'Read the notice',
        onPressed: () =>
            _ask(LedgerDialogType.acknowledge, 'Books closed', null),
      ),
      Text(_said, style: context.ledgerTheme.meta),
      LedgerActionBar(
        floating: true,
        summary: '\$1,240.00',
        detail: 'Due Nov 1',
        label: 'Pay now',
        busy: _busy,
        onTap: () {
          setState(() => _busy = true);
          Future<void>.delayed(const Duration(seconds: 1), () {
            if (mounted) setState(() => _busy = false);
          });
        },
      ),
    ],
  );
}

String _body(LedgerDialogType kind) => switch (kind) {
  LedgerDialogType.confirm =>
    'October leaves the open books and is kept, ruled and totalled, under '
        'Archive. You can bring it back.',
  LedgerDialogType.destructive =>
    'It leaves your records for good. Nothing else you have written is '
        'touched.',
  LedgerDialogType.acknowledge =>
    'The books for September are closed; entries dated in it are kept as '
        'written.',
};

/// A dialog stood in place over the scrim, as the system raises one.
Widget _scrimmed(Widget dialog) => Builder(
  builder: (context) {
    final t = context.ledgerTheme;
    return ColoredBox(
      color: t.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: t.overlay),
          Center(child: dialog),
        ],
      ),
    );
  },
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Archive, with its cancel.
Widget kitSpecimenDialogConfirm() => _scrimmed(
  LedgerDialog(
    title: 'Archive October?',
    body: _body(LedgerDialogType.confirm),
    confirmLabel: 'Archive',
    onConfirmPressed: () {},
    onCancelPressed: () {},
  ),
);

/// Delete, in the vermilion.
Widget kitSpecimenDialogDestructive() => _scrimmed(
  LedgerDialog(
    title: 'Delete this entry?',
    body: _body(LedgerDialogType.destructive),
    type: LedgerDialogType.destructive,
    onConfirmPressed: () {},
    onCancelPressed: () {},
  ),
);

/// One act, nothing to decide.
Widget kitSpecimenDialogAcknowledge() => _scrimmed(
  LedgerDialog(
    title: 'Books closed',
    body: _body(LedgerDialogType.acknowledge),
    type: LedgerDialogType.acknowledge,
    onConfirmPressed: () {},
  ),
);

/// The total beside the act, docked as a pushed page's footer.
Widget kitSpecimenActionBarDocked() => LedgerActionBar(
  summary: '\$1,240.00',
  detail: 'Due Nov 1',
  label: 'Pay now',
  onTap: () {},
);

/// The act alone, across the width.
Widget kitSpecimenActionBarAlone() => LedgerActionBar(
  label: 'Send the invoice',
  icon: LucideIcons.send,
  onTap: () {},
);

/// A composed summary on a card of its own, in a body.
Widget kitSpecimenActionBarFloating() => LedgerActionBar(
  floating: true,
  summaryContent: Builder(
    builder: (context) {
      final t = context.ledgerTheme;
      return Text('3 entries chosen', style: t.rowTitle.colored(t.textPrimary));
    },
  ),
  label: 'File them',
  icon: LucideIcons.archive,
  onTap: () {},
);

/// The message box at rest: attach at its start, voice at its end.
Widget kitSpecimenComposerMessages() => LedgerComposer(
  hint: 'Write a reply',
  onAttachPressed: () {},
  onVoicePressed: () {},
);

/// A grown draft: the send is green once there are words.
Widget kitSpecimenComposerDrafted() => KitTyped(
  'Thanks, I will send the proof tomorrow. Could you hold the paper until '
  'Friday? It is the last thing I am waiting on before the print run.',
  (controller) => LedgerComposer(
    controller: controller,
    hint: 'Write a reply',
    onAttachPressed: () {},
    onSubmitted: () {},
  ),
);

/// The ask box over its toolbar of the page's own chips.
Widget kitSpecimenComposerAssistant() => LedgerComposer(
  style: LedgerComposerStyle.assistant,
  hint: 'Ask about the books',
  onAttachPressed: () {},
  onSubmitted: () {},
  toolbar: [
    LedgerChip('This month', icon: LucideIcons.calendar, onTap: () {}),
    LedgerChip('Invoices', onTap: () {}),
  ],
);
