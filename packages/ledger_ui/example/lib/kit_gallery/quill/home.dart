/// Home: what the owner is worth, the accounts that make it, and the last
/// of the register. An account opens its sheet: its balance, its last
/// entries and the act that moves money.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';
import 'quill.dart';
import 'register.dart';
import 'words.dart';

class QuillHome extends StatelessWidget {
  const QuillHome({required this.onOpen, super.key});

  final ValueChanged<QuillPage> onOpen;

  @override
  Widget build(BuildContext context) {
    final wide = LedgerLayout.isWide(context);
    final worth = LedgerSection(
      head: LedgerHead(
        context.say('Net worth'),
        note: context.say(kitNetWorthChangePct),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: LedgerSpacing.s8,
        children: [
          const LedgerFigure(kitNetWorth),
          // The rise in the green, as money in is written everywhere.
          LedgerDelta(
            rise: LedgerFormat.money(kitNetWorthChange),
            words: [context.say('since September')],
          ),
        ],
      ),
    );
    final accounts = LedgerSection(
      head: LedgerHead(context.say('Accounts'), note: context.say('Balance')),
      child: LedgerRows(
        children: [
          for (final a in kitAccounts)
            LedgerRow(
              leading: LedgerGlyph(a.icon),
              title: context.say(a.name),
              value: LedgerAmount(a.amount),
              subtitle: context.say(a.subStart),
              subtitleMonospace: a.subStartMono,
              trailingSubtitle: context.say(a.subEnd),
              trailingSubtitleTone: a.subEndGreen
                  ? LedgerTone.moneyIn
                  : LedgerTone.plain,
              onTap: () => showQuillAccount(context, a),
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
        context.say('Recent'),
        note: context.say('Register'),
        onTap: () => onOpen(QuillPage.register),
      ),
      child: LedgerRegister(
        heads: [
          for (final h in const [
            'Time',
            'Payee',
            'Category',
            'Account',
            'Amount',
          ])
            context.say(h),
        ],
        children: [
          for (final english in days)
            if (context.sayDay(english) case final day)
              LedgerDayGroup(
                day.label,
                note: day.note,
                net: day.net,
                rows: [
                  for (final (i, tx) in day.rows.indexed)
                    LedgerTransactionRow(
                      title: tx.title,
                      category: tx.subtitle,
                      when: tx.time,
                      account: tx.account,
                      amount: tx.amount,
                      initials: tx.lead,
                      glyph: tx.icon,
                      pending: tx.pending,
                      pendingLabel: context.say('Pending'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => QuillReceiptPage(tx: english.rows[i]),
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
        title: context.say('Good evening, Maren'),
        meta: context.sayToday(kitNow),
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

/// An account's sheet: its balance in the serif over what it is, its last
/// entries (each opens its receipt), and Move money at its foot. On a phone
/// a sheet from the foot; at desktop width the sheet's dialog.
Future<void> showQuillAccount(BuildContext context, KitRow account) {
  final name = context.say(account.name);
  return LedgerSheet.show<void>(
    context,
    title: name,
    builder: (context) {
      final entries = [
        for (final day in kitDays)
          for (final tx in day.rows)
            if (tx.account == account.name) tx,
      ].take(4).toList();
      final t = context.ledgerTheme;
      return [
        // The balance stands under the sheet's own rule: a section's head
        // here would draw a second ink rule just under it.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: LedgerSpacing.s8,
          children: [
            Text(context.say(account.subStart).toUpperCase(), style: t.meta),
            LedgerFigure(account.amount),
            if (account.subEnd.isNotEmpty)
              Text(
                context.say(account.subEnd),
                style: t.bodySmall.colored(
                  account.subEndGreen ? t.moneyIn : t.textSecondary,
                ),
              ),
          ],
        ),
        if (entries.isNotEmpty) ...[
          const LedgerGap(LedgerSpacing.s32),
          LedgerSection(
            head: LedgerHead(context.say('Last entries')),
            child: LedgerRows(
              children: [
                for (final english in entries)
                  if (context.sayTx(english) case final tx)
                    LedgerRow(
                      leading: tx.icon != null
                          ? LedgerGlyph(tx.icon!)
                          : LedgerMonogram(tx.title),
                      title: tx.title,
                      // Pending as the Register marks it.
                      subtitle:
                          '${tx.day} · '
                          '${tx.pending ? context.say('Pending') : tx.subtitle}',
                      value: LedgerAmount(tx.amount),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => QuillReceiptPage(tx: english),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ];
    },
    foot: (context) => [
      LedgerButton.filled(
        context.say('Move money'),
        expand: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  );
}
