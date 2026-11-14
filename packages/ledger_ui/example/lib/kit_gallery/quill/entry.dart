/// A new entry: a form written on the rule, its receipt drawn beside it
/// as it is filled in (from 1024), checked when it is saved.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

class QuillEntryPage extends StatefulWidget {
  const QuillEntryPage({super.key});

  @override
  State<QuillEntryPage> createState() => _QuillEntryPageState();
}

class _QuillEntryPageState extends State<QuillEntryPage> {
  final _amount = TextEditingController();
  final _payee = TextEditingController();
  final _note = TextEditingController();
  String? _category;
  String _account = 'Everyday';
  String _day = 'today';
  String _repeat = 'never';
  bool _keepReceipt = true;
  bool _budgeted = true;
  String? _amountError;
  String? _payeeError;
  String? _categoryError;

  static const _categories = [
    LedgerSelectItem(value: 'Groceries', label: 'Groceries'),
    LedgerSelectItem(value: 'Dining out', label: 'Dining out'),
    LedgerSelectItem(value: 'Transport', label: 'Transport'),
    LedgerSelectItem(value: 'Home', label: 'Home'),
    LedgerSelectItem(value: 'Health', label: 'Health'),
  ];

  static const _accounts = [
    LedgerSelectItem(value: 'Everyday', label: 'Everyday ··4821'),
    LedgerSelectItem(value: 'Keel Card', label: 'Keel Card ··7730'),
    LedgerSelectItem(value: 'Savings', label: 'Savings ··9015'),
  ];

  static const _days = [
    LedgerSelectItem(value: 'today', label: 'Today, Oct 28'),
    LedgerSelectItem(value: 'yesterday', label: 'Yesterday, Oct 27'),
    LedgerSelectItem(value: 'monday', label: 'Monday, Oct 26'),
  ];

  static const _repeats = [
    LedgerSelectItem(value: 'never', label: 'Never'),
    LedgerSelectItem(value: 'weekly', label: 'Every week'),
    LedgerSelectItem(value: 'monthly', label: 'Every month'),
  ];

  @override
  void dispose() {
    _amount.dispose();
    _payee.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(_amount.text.replaceAll(',', ''));

  void _save() {
    final value = _value;
    setState(() {
      _amountError = value == null || value <= 0 ? 'Enter what was paid' : null;
      _payeeError = _payee.text.trim().isEmpty ? 'Say who was paid' : null;
      _categoryError = _category == null ? 'Choose a category' : null;
    });
    if (_amountError != null || _payeeError != null || _categoryError != null) {
      return;
    }
    LedgerToast.show(context, 'Entry saved to the register');
    Navigator.of(context).pop();
  }

  Widget _pair(bool paired, Widget a, Widget b) => paired
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: LedgerSpacing.s24),
            Expanded(child: b),
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [a, _fieldGap, b],
        );

  static const _fieldGap = LedgerGap(LedgerSpacing.s24);

  /// The form's measure from 600: two blanks of about 300 and their gap.
  static const double _measure = 640;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = LedgerLayout.isWide(context);
    final paired = width >= LedgerNavigationFrame.railFrom;
    // On a phone the act spans the page's foot band; from 600 it ends the
    // form at its own width, as a desktop form's act does, not a bar across
    // it.
    final save = LedgerButton.filled(
      'Save entry',
      expand: !paired,
      size: LedgerButtonSize.large,
      onPressed: _save,
    );
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pair(
          paired,
          LedgerTextField(
            label: 'Amount',
            prefix: r'$',
            hint: '0.00',
            controller: _amount,
            isRequired: true,
            error: _amountError,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
          ),
          LedgerTextField(
            label: 'Payee',
            hint: 'Who was paid',
            controller: _payee,
            isRequired: true,
            error: _payeeError,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
        ),
        _fieldGap,
        _pair(
          paired,
          LedgerSelect<String>(
            label: 'Category',
            hint: 'Choose one',
            value: _category,
            items: _categories,
            isRequired: true,
            error: _categoryError,
            onChanged: (v) => setState(() {
              _category = v;
              _categoryError = null;
            }),
          ),
          LedgerSelect<String>(
            label: 'Account',
            value: _account,
            items: _accounts,
            onChanged: (v) => setState(() => _account = v),
          ),
        ),
        _fieldGap,
        _pair(
          paired,
          LedgerSelect<String>(
            label: 'Day',
            value: _day,
            items: _days,
            onChanged: (v) => setState(() => _day = v),
          ),
          LedgerSelect<String>(
            label: 'Repeat',
            value: _repeat,
            items: _repeats,
            onChanged: (v) => setState(() => _repeat = v),
          ),
        ),
        _fieldGap,
        LedgerTextField(
          label: 'Note',
          hint: 'What it was for',
          controller: _note,
          maxLines: 4,
          minLines: 2,
        ),
        const LedgerGap(LedgerSpacing.s16),
        LedgerCheckbox(
          value: _keepReceipt,
          label: 'Keep the receipt with the entry',
          onChanged: (v) => setState(() => _keepReceipt = v ?? false),
        ),
        LedgerCheckbox(
          value: _budgeted,
          label: 'Count it against the budget',
          onChanged: (v) => setState(() => _budgeted = v ?? false),
        ),
        if (paired) ...[
          const LedgerGap(LedgerSpacing.s32),
          Align(alignment: AlignmentDirectional.centerStart, child: save),
        ],
      ],
    );
    // From 600 the form keeps a form's measure, so its halves are blanks
    // (about 300), not 424 or more on a wide window.
    final measured = paired
        ? Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _measure),
              child: form,
            ),
          )
        : form;
    final Widget body;
    if (wide) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The receipt stands right after the form, not at the window's
          // far side.
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _measure),
              child: form,
            ),
          ),
          const SizedBox(width: LedgerSpacing.s56),
          SizedBox(
            width: _preview,
            child: LedgerSection(
              head: const LedgerHead('As it will print'),
              child: ListenableBuilder(
                listenable: Listenable.merge([_amount, _payee]),
                builder: (context, _) => _receipt(),
              ),
            ),
          ),
        ],
      );
    } else {
      body = measured;
    }
    return LedgerScreen.form(
      topBar: const LedgerTopBar(title: 'New entry'),
      footer: paired ? null : save,
      body: body,
    );
  }

  Widget _receipt() {
    final payee = _payee.text.trim();
    final account = _accounts.firstWhere((a) => a.value == _account).label;
    final day = _days.firstWhere((d) => d.value == _day).label;
    return LedgerReceipt(
      kind: 'Quill · New entry',
      number: 'No. —',
      leading: LedgerMonogram(payee.isEmpty ? 'Payee' : payee),
      name: payee.isEmpty ? 'Payee' : payee,
      subtitle: '${_category ?? 'No category'} · $account',
      figure: LedgerFigure(-(_value ?? 0)),
      seal: LedgerSeal(
        kicker: _account,
        value: 'Draft',
        foot: LedgerFormat.date(kitNow),
        tone: LedgerSealTone.plain,
      ),
      details: [
        LedgerKeyValue('Day', day),
        LedgerKeyValue(
          'Repeat',
          _repeats.firstWhere((r) => r.value == _repeat).label,
        ),
      ],
    );
  }

  static const double _preview = 400;
}
