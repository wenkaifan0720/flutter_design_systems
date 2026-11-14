/// Home: what the owner is worth, the accounts that make it, and the last
/// of the register.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';
import 'quill.dart';
import 'register.dart';

class QuillHome extends StatelessWidget {
  const QuillHome({required this.onOpen, super.key});

  final ValueChanged<QuillPage> onOpen;

  @override
  Widget build(BuildContext context) {
    final wide = LedgerLayout.isWide(context);
    final worth = LedgerSection(
      head: const LedgerHead('Net worth', note: kitNetWorthChangePct),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: LedgerSpacing.s8,
        children: [
          const LedgerFigure(kitNetWorth),
          // The rise in the green, as money in is written everywhere.
          LedgerDelta(
            rise: LedgerFormat.money(kitNetWorthChange),
            words: const ['since September'],
          ),
        ],
      ),
    );
    final accounts = LedgerSection(
      head: const LedgerHead('Accounts', note: 'Balance'),
      child: LedgerRows(
        children: [
          for (final a in kitAccounts)
            LedgerRow(
              leading: LedgerGlyph(a.icon),
              title: a.name,
              value: LedgerAmount(a.amount),
              subtitle: a.subStart,
              subtitleMonospace: a.subStartMono,
              trailingSubtitle: a.subEnd,
              trailingSubtitleTone: a.subEndGreen
                  ? LedgerTone.moneyIn
                  : LedgerTone.plain,
            ),
        ],
      ),
    );
    // The last few days, about six entries (Today, Yesterday, Monday): at
    // desktop width the register's column ends near the accounts beside it.
    final days = <KitDay>[];
    for (final day in kitDays) {
      if (days.fold<int>(0, (n, d) => n + d.rows.length) >= _recentRows) break;
      days.add(day);
    }
    final recent = LedgerSection(
      head: LedgerHead(
        'Recent',
        note: 'Register',
        onTap: () => onOpen(QuillPage.register),
      ),
      child: LedgerRegister(
        heads: const ['Time', 'Payee', 'Category', 'Account', 'Amount'],
        children: [
          for (final day in days)
            LedgerDayGroup(
              day.label,
              note: day.note,
              net: day.net,
              rows: [
                for (final tx in day.rows)
                  LedgerTransactionRow(
                    title: tx.title,
                    category: tx.subtitle,
                    when: tx.time,
                    account: tx.account,
                    amount: tx.amount,
                    initials: tx.lead,
                    glyph: tx.icon,
                    pending: tx.pending,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => QuillReceiptPage(tx: tx),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
    const gap = LedgerGap(LedgerSpacing.s40);
    return LedgerScreen(
      topBar: LedgerTopBar(
        title: 'Good evening, Maren',
        meta: LedgerFormat.today(kitNow),
      ),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: recent),
                const SizedBox(width: LedgerSpacing.s56),
                SizedBox(
                  width: _side,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [worth, gap, accounts],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [worth, gap, accounts, gap, recent],
            ),
    );
  }

  static const double _side = 400;
  static const int _recentRows = 6;
}
