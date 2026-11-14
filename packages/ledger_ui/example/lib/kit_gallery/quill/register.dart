/// The Register: every entry by day under a filter; each opens its receipt.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

/// An entry's receipt, as the register's record prints it.
Widget quillReceipt(KitTx tx) => LedgerReceipt(
  kind: tx.income ? 'Quill · Money in' : 'Quill · Entry',
  number: 'No. ${tx.id.toUpperCase()}',
  leading: tx.icon != null
      ? LedgerGlyph(tx.icon!, size: LedgerGlyphSize.record)
      : LedgerMonogram(tx.title, size: LedgerMonogramSize.record),
  name: tx.title,
  subtitle: '${tx.subtitle} · ${tx.account}',
  figure: LedgerFigure(tx.amount, showSign: tx.income),
  seal: LedgerSeal(
    kicker: tx.account,
    value: tx.pending ? 'Pending' : (tx.income ? 'Received' : 'Posted'),
    foot: LedgerFormat.date(tx.at),
    tone: tx.pending ? LedgerSealTone.plain : LedgerSealTone.success,
  ),
  details: [
    LedgerKeyValue('Status', tx.pending ? 'Pending' : 'Posted'),
    LedgerKeyValue('Day', '${tx.day}, ${tx.time}'),
    LedgerKeyValue('Account', tx.account),
    LedgerKeyValue('Category', tx.subtitle),
  ],
);

const List<String> _filters = ['All', 'Money in', 'Money out', 'Pending'];

bool _shows(String filter, KitTx tx) => switch (filter) {
  'Money in' => tx.income,
  'Money out' => !tx.income && !tx.moved,
  'Pending' => tx.pending,
  _ => true,
};

class QuillRegister extends StatefulWidget {
  const QuillRegister({super.key});

  @override
  State<QuillRegister> createState() => _QuillRegisterState();
}

class _QuillRegisterState extends State<QuillRegister> {
  String _filter = _filters.first;

  void _open(KitTx tx) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => QuillReceiptPage(tx: tx)));

  @override
  Widget build(BuildContext context) {
    final days = [
      for (final d in kitDays)
        if (d.rows.where((tx) => _shows(_filter, tx)).toList() case final rows
            when rows.isNotEmpty)
          LedgerDayGroup(
            d.label,
            note: d.note,
            net: d.net,
            rows: [
              for (final tx in rows)
                LedgerTransactionRow(
                  title: tx.title,
                  category: tx.subtitle,
                  when: tx.time,
                  account: tx.account,
                  amount: tx.amount,
                  initials: tx.lead,
                  glyph: tx.icon,
                  pending: tx.pending,
                  onTap: () => _open(tx),
                ),
            ],
          ),
    ];
    return LedgerScreen(
      topBar: LedgerTopBar(
        title: 'Register',
        meta: '$kitActivityCount entries in $kitMonthName',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LedgerFilters(
            label: 'Show',
            options: _filters,
            value: _filter,
            onChanged: (f) => setState(() => _filter = f ?? _filters.first),
          ),
          const LedgerGap(LedgerSpacing.s24),
          if (days.isEmpty)
            const LedgerEmptyState(
              title: 'Nothing here',
              body: 'No entry matches this filter.',
            )
          else
            LedgerRegister(
              heads: const ['Time', 'Payee', 'Category', 'Account', 'Amount'],
              children: days,
            ),
        ],
      ),
    );
  }
}

/// One entry's record: its receipt at the slip's measure.
class QuillReceiptPage extends StatelessWidget {
  const QuillReceiptPage({required this.tx, super.key});

  final KitTx tx;

  @override
  Widget build(BuildContext context) => LedgerScreen(
    topBar: LedgerTopBar(title: tx.title, meta: tx.day),
    body: Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _measure),
        child: quillReceipt(tx),
      ),
    ),
  );

  static const double _measure = 480;
}
