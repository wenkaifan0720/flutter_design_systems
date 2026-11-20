/// A new entry: a form written on the rule, its receipt drawn beside it
/// as it is filled in (from 1024), checked when it is saved, and saved to
/// the register.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
import 'quill.dart';
import 'words.dart';

/// What [text] says was paid, read as a person writes dollars: "17.43" or
/// "17,43" (a decimal comma), "1,743.50" or "1.743,50" (grouped
/// thousands), "1,743" (a thousands comma), with or without the dollar
/// sign. Null when it does not read as dollars and cents: no digit, a
/// letter or a sign, a third decimal ("17.435") or a stray mark ("17,4,3").
double? quillAmount(String text) {
  final s = text.replaceAll(RegExp(r'[\s\u00A0$]'), '');
  if (!RegExp(r'^[\d.,]+$').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
    return null;
  }
  final at = math.max(s.lastIndexOf('.'), s.lastIndexOf(','));
  var whole = s;
  var cents = '';
  if (at >= 0) {
    final mark = s[at];
    final tail = s.substring(at + 1);
    final before = s.substring(0, at);
    // Three digits after the last mark group thousands when no other kind
    // of mark stands before it, and the mark is a comma or comes again
    // ("1,743", "1.234.567"); a lone point before three is a third decimal.
    final groups =
        tail.length == 3 &&
        !before.contains(mark == '.' ? ',' : '.') &&
        (mark == ',' || before.contains(mark));
    if (!groups) {
      if (tail.length > 2) return null;
      whole = before;
      cents = tail;
    }
  }
  if (!RegExp(r'^(\d*|\d{1,3}(,\d{3})+|\d{1,3}(\.\d{3})+)$').hasMatch(whole)) {
    return null;
  }
  final dollars = whole.replaceAll(RegExp('[.,]'), '');
  return double.parse(
    '${dollars.isEmpty ? '0' : dollars}.${cents.padRight(2, '0')}',
  );
}

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
  // Each field's fault in English, said as it is shown; null: none shown.
  // Once Save is pressed, the faults follow the fields as they change.
  bool _tried = false;
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
    LedgerSelectItem(value: 'Wren Card', label: 'Wren Card ··7730'),
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
  void initState() {
    super.initState();
    _amount.addListener(_recheck);
    _payee.addListener(_recheck);
  }

  @override
  void dispose() {
    _amount.dispose();
    _payee.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _value => quillAmount(_amount.text);

  String? get _amountFault {
    if (_amount.text.trim().isEmpty) return 'Enter what was paid';
    final value = _value;
    if (value == null) return 'Enter an amount such as 17.43';
    return value <= 0 ? 'Enter what was paid' : null;
  }

  String? get _payeeFault =>
      _payee.text.trim().isEmpty ? 'Say who was paid' : null;

  /// The faults read again as a field changes, once Save was pressed: a
  /// corrected field drops its fault at once, an emptied one shows it
  /// again. A field shows none before the first Save.
  void _recheck() {
    if (!_tried) return;
    final amount = _amountFault;
    final payee = _payeeFault;
    if (amount != _amountError || payee != _payeeError) {
      setState(() {
        _amountError = amount;
        _payeeError = payee;
      });
    }
  }

  void _save() {
    _tried = true;
    setState(() {
      _amountError = _amountFault;
      _payeeError = _payeeFault;
      _categoryError = _category == null ? 'Choose a category' : null;
    });
    if (_amountError != null || _payeeError != null || _categoryError != null) {
      return;
    }
    QuillPrefs.maybeOf(context)?.save(_entry());
    LedgerToast.show(context, context.say('Entry saved to the register'));
    Navigator.of(context).pop();
  }

  /// The entry as the register keeps it, on its day at the hour it was
  /// written.
  KitTx _entry() {
    final saved = QuillPrefs.maybeOf(context)?.saved.length ?? 0;
    final payee = _payee.text.trim();
    final back = switch (_day) {
      'yesterday' => 1,
      'monday' => 2,
      _ => 0,
    };
    final at = kitNow.subtract(Duration(days: back));
    return KitTx(
      id: 'n${saved + 1}',
      title: payee,
      lead: quillInitials(payee),
      subtitle: _category!,
      time: LedgerFormat.time(at),
      day: switch (_day) {
        'today' => 'Today',
        'yesterday' => 'Yesterday',
        _ => LedgerFormat.day(at, now: kitNow),
      },
      account: _account,
      amount: -_value!,
      at: at,
    );
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
    if (!quillSignedIn(context)) {
      return QuillSignedOutPage(title: context.say('New entry'));
    }
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
            error: _amountError == null ? null : context.say(_amountError!),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
          ),
          LedgerTextField(
            label: context.say('Payee'),
            hint: context.say('Who was paid'),
            controller: _payee,
            isRequired: true,
            error: _payeeError == null ? null : context.say(_payeeError!),
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
            error: _categoryError == null ? null : context.say(_categoryError!),
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
