/// Work under way and figures at a glance: a rule that fills, a ring that
/// closes, the paper's placeholder while a list loads, a ring of shares and
/// sparklines. The open-ended ones run when asked, so the page rests.
library;

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

/// A measured piece of work, set by its slider.
class _Measured extends StatefulWidget {
  const _Measured();

  @override
  State<_Measured> createState() => _MeasuredState();
}

class _MeasuredState extends State<_Measured> {
  double _done = .6;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: LedgerSpacing.s16,
    children: [
      LedgerProgressBar(value: _done, label: 'Uploading the statement'),
      Row(
        spacing: LedgerSpacing.s16,
        children: [
          LedgerProgressRing(
            value: _done,
            label: 'Saving the budget',
            showValue: true,
          ),
          Expanded(
            child: LedgerSlider(
              label: 'How far',
              value: _done,
              onChanged: (v) => setState(() => _done = v),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Work without a measure, run for a few seconds when asked.
class _Open extends StatefulWidget {
  const _Open();

  @override
  State<_Open> createState() => _OpenState();
}

class _OpenState extends State<_Open> {
  Timer? _timer;

  void _run() {
    _timer?.cancel();
    setState(() => _timer = Timer(const Duration(seconds: 4), _stop));
  }

  void _stop() {
    if (mounted) setState(() => _timer = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = _timer != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LedgerSpacing.s16,
      children: [
        if (running) ...[
          const LedgerProgressBar(label: 'Fetching the bank feed'),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: LedgerProgressRing(label: 'Fetching the bank feed'),
          ),
        ] else
          Text(
            'Fetched at 9:41.',
            style: context.ledgerTheme.bodySmall.colored(
              context.ledgerTheme.textSecondary,
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LedgerButton(
            running ? 'Fetching…' : 'Fetch the bank feed',
            size: LedgerButtonSize.medium,
            onPressed: running ? null : _run,
          ),
        ),
      ],
    );
  }
}

/// A list that loads again when asked: the placeholder for two seconds.
class _Loading extends StatefulWidget {
  const _Loading();

  @override
  State<_Loading> createState() => _LoadingState();
}

class _LoadingState extends State<_Loading> {
  Timer? _timer;

  void _load() {
    _timer?.cancel();
    setState(() => _timer = Timer(const Duration(seconds: 2), _done));
  }

  void _done() {
    if (mounted) setState(() => _timer = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LedgerSpacing.s16,
      children: [
        if (_timer != null) ...[
          const LedgerSkeleton(lines: 2, avatar: true),
          const LedgerSkeleton(lines: 2, avatar: true),
        ] else ...[
          for (final (who, what) in const [
            ('Blue Fern Café', 'Oct 28 · Dining out'),
            ('Corner Market', 'Oct 27 · Groceries'),
          ])
            Row(
              spacing: LedgerSpacing.s12,
              children: [
                LedgerAvatar(initials: LedgerFormat.initials(who)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(who, style: t.rowTitle.colored(t.textPrimary)),
                      Text(what, style: t.bodySmall.colored(t.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LedgerButton(
            'Load again',
            size: LedgerButtonSize.medium,
            onPressed: _timer == null ? _load : null,
          ),
        ),
      ],
    );
  }
}

Widget kitWorkingDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Under way',
  sections: [
    kitSection('Measured', children: const [_Measured()]),
    kitSection('Without a measure', children: const [_Open()]),
    kitSection('While a list loads', children: const [_Loading()]),
    kitSection(
      'Shares of October',
      children: const [
        LedgerPieChart(
          label: 'October by category',
          format: LedgerFormat.money,
          shares: [
            LedgerShare('Rent', 1150),
            LedgerShare('Groceries', 486.20),
            LedgerShare('Dining out', 336.40),
            LedgerShare('Transport', 142),
            LedgerShare('Other', 210.75),
          ],
        ),
      ],
    ),
    kitSection(
      'At a glance',
      children: [
        kitRow(const [
          LedgerSparkline(
            label: 'Everyday, 30 days',
            values: [4.2, 4.6, 4.1, 5.0, 4.8, 5.6, 6.2],
            baseline: true,
          ),
          LedgerSparkline(
            label: 'Dining out, 6 weeks',
            values: [92, 74, 110, 68, 120, 136],
          ),
          LedgerSparkline(
            label: 'Savings, 12 months',
            values: [9.1, 8.7, 8.2, 7.9, 7.4, 7.0],
          ),
        ]),
      ],
    ),
  ],
);
