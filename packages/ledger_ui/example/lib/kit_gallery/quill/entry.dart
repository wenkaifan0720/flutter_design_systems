/// A new entry: a form written on the rule, its receipt drawn beside it
/// as it is filled in (from 1024), checked when it is saved.
library;

import 'package:material_ui/material_ui.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
import 'words.dart';

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

  /// [items] with their words in Quill's language.
  List<LedgerSelectItem<String>> _said(List<LedgerSelectItem<String>> items) =>
      [
        for (final i in items)
          LedgerSelectItem(value: i.value, label: context.say(i.label)),
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
      _amountError = value == null || value <= 0
          ? context.say('Enter what was paid')
          : null;
      _payeeError = _payee.text.trim().isEmpty
          ? context.say('Say who was paid')
          : null;
      _categoryError = _category == null
          ? context.say('Choose a category')
          : null;
    });
    if (_amountError != null || _payeeError != null || _categoryError != null) {
      return;
    }
    LedgerToast.show(context, context.say('Entry saved to the register'));
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
      context.say('Save entry'),
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
            label: context.say('Amount'),
            prefix: r'$',
            hint: '0.00',
            controller: _amount,
            isRequired: true,
            error: _amountError,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
          ),
          LedgerTextField(
            label: context.say('Payee'),
            hint: context.say('Who was paid'),
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
            label: context.say('Category'),
            hint: context.say('Choose one'),
            value: _category,
            items: _said(_categories),
            isRequired: true,
            error: _categoryError,
            onChanged: (v) => setState(() {
              _category = v;
              _categoryError = null;
            }),
          ),
          LedgerSelect<String>(
            label: context.say('Account'),
            value: _account,
            items: _said(_accounts),
            onChanged: (v) => setState(() => _account = v),
          ),
        ),
        _fieldGap,
        _pair(
          paired,
          LedgerSelect<String>(
            label: context.say('Day'),
            value: _day,
            items: _said(_days),
            onChanged: (v) => setState(() => _day = v),
          ),
          LedgerSelect<String>(
            label: context.say('Repeat'),
            value: _repeat,
            items: _said(_repeats),
            onChanged: (v) => setState(() => _repeat = v),
          ),
        ),
        _fieldGap,
        LedgerTextField(
          label: context.say('Note'),
          hint: context.say('What it was for'),
          controller: _note,
          maxLines: 4,
          minLines: 2,
        ),
        const LedgerGap(LedgerSpacing.s16),
        LedgerCheckbox(
          value: _keepReceipt,
          label: context.say('Keep the receipt with the entry'),
          onChanged: (v) => setState(() => _keepReceipt = v ?? false),
        ),
        LedgerCheckbox(
          value: _budgeted,
          label: context.say('Count it against the budget'),
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
              head: LedgerHead(context.say('As it will print')),
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
      topBar: LedgerTopBar(title: context.say('New entry')),
      footer: paired ? null : save,
      body: body,
    );
  }

  Widget _receipt() {
    final payee = _payee.text.trim();
    final account = context.say(
      _accounts.firstWhere((a) => a.value == _account).label,
    );
    final day = context.say(_days.firstWhere((d) => d.value == _day).label);
    // Before a payee is written the slip is a new entry under a pen, never
    // the field's label printed as a name.
    final name = payee.isEmpty ? context.say('New entry') : payee;
    return LedgerReceipt(
      kind: context.say('Quill · New entry'),
      number: '${context.say('No.')} —',
      leading: payee.isEmpty
          ? const LedgerGlyph(LucideIcons.penLine)
          : LedgerMonogram(name),
      name: name,
      subtitle: '${context.say(_category ?? 'No category')} · $account',
      figure: LedgerFigure(-(_value ?? 0)),
      seal: LedgerSeal(
        kicker: context.say(_account),
        value: context.say('Draft'),
        foot: context.sayDate(kitNow),
        tone: LedgerSealTone.plain,
      ),
      details: [
        LedgerKeyValue(context.say('Day'), day),
        LedgerKeyValue(
          context.say('Repeat'),
          context.say(_repeats.firstWhere((r) => r.value == _repeat).label),
        ),
      ],
    );
  }

  static const double _preview = 400;
}
