/// The fields beyond the text field: a password with its eye, a memo on
/// ruled paper, an address between its add-ons, a bank's code, a payee
/// typed and suggested, and the people a bill is split with. Every one is
/// live.
library;

import 'package:material_ui/material_ui.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

const List<String> _payees = [
  'Blue Fern Café',
  'Corner Market',
  'City Water',
  'Northside Rent',
  'Harbour Books',
];

const List<String> _people = ['Maren', 'Theo', 'Ana', 'Jun', 'Priya'];

/// The tags of a split, held while the page stands.
class _Split extends StatefulWidget {
  const _Split();

  @override
  State<_Split> createState() => _SplitState();
}

class _SplitState extends State<_Split> {
  List<String> _with = const ['Maren', 'Theo'];

  @override
  Widget build(BuildContext context) => LedgerMultiSelect<String>(
    labelText: 'Split with',
    hintText: 'Add a person',
    helperText: 'Each pays an even share',
    values: _with,
    options: _people,
    onCreate: (text) => text.trim().isEmpty ? null : text.trim(),
    onChanged: (v) => setState(() => _with = v),
  );
}

/// The payee taken, held while the page stands: its list shows it chosen.
class _Payee extends StatefulWidget {
  const _Payee();

  @override
  State<_Payee> createState() => _PayeeState();
}

class _PayeeState extends State<_Payee> {
  String? _payee = 'Corner Market';

  @override
  Widget build(BuildContext context) => LedgerCombobox<String>(
    labelText: 'Payee',
    hintText: 'Who was paid',
    helperText: 'From the payees you have paid before',
    options: _payees,
    value: _payee,
    noteOf: (p) => p == 'Blue Fern Café' ? '12 visits' : null,
    onSelected: (p) => setState(() => _payee = p),
  );
}

/// A span of amounts, held while the page stands.
class _Span extends StatefulWidget {
  const _Span();

  @override
  State<_Span> createState() => _SpanState();
}

class _SpanState extends State<_Span> {
  LedgerRangeValues _span = const LedgerRangeValues(40, 180);

  @override
  Widget build(BuildContext context) => LedgerRangeSlider(
    label: 'Amount',
    values: _span,
    max: 500,
    divisions: 10,
    minGap: 50,
    format: (v) => '\$${v.round()}',
    startLabel: 'Least amount',
    endLabel: 'Most amount',
    onChanged: (v) => setState(() => _span = v),
  );
}

/// A statement's period, held while the page stands.
class _Period extends StatefulWidget {
  const _Period();

  @override
  State<_Period> createState() => _PeriodState();
}

class _PeriodState extends State<_Period> {
  LedgerDateRange? _period = LedgerDateRange(
    DateTime(2026, 10, 12),
    DateTime(2026, 10, 19),
  );

  @override
  Widget build(BuildContext context) => LedgerDateRangePicker(
    firstDate: DateTime(2026),
    lastDate: DateTime(2027, 12, 31),
    currentDate: DateTime(2026, 10, 28),
    value: _period,
    months: LedgerLayout.isWide(context) ? 2 : 1,
    onChanged: (r) => setState(() => _period = r),
  );
}

/// Receipts going up, held while the page stands.
class _Receipts extends StatefulWidget {
  const _Receipts();

  @override
  State<_Receipts> createState() => _ReceiptsState();
}

class _ReceiptsState extends State<_Receipts> {
  List<LedgerFile> _files = const [
    LedgerFile('Blue Fern Café.jpg', bytes: 182000),
    LedgerFile('October statement.pdf', bytes: 1240000, progress: .6),
    LedgerFile(
      'Scan 0042.heic',
      bytes: 14200000,
      error: 'Larger than 10 MB; take a smaller photo',
    ),
  ];

  @override
  Widget build(BuildContext context) => LedgerFileUpload(
    labelText: 'Receipts',
    files: _files,
    onPick: () {},
    onRemove: (f) => setState(
      () => _files = [
        for (final x in _files)
          if (x != f) x,
      ],
    ),
  );
}

Widget kitFieldsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'More fields',
  sections: [
    kitSection(
      'Password',
      children: const [
        LedgerPasswordField(
          labelText: 'Password',
          helperText: 'At least 12 characters',
          isRequired: true,
        ),
        LedgerPasswordField(
          labelText: 'Current password',
          errorText: 'That is not the password on the account',
        ),
        LedgerPasswordField(labelText: 'Locked', enabled: false),
      ],
    ),
    kitSection(
      'Memo, on ruled paper',
      children: const [
        LedgerTextArea(
          labelText: 'Memo',
          hintText: 'What it was for',
          helperText: 'Only you see it',
          maxLength: 280,
        ),
        LedgerTextArea(
          labelText: 'Note to the budget',
          minLines: 3,
          errorText: 'Write a line or leave it empty',
        ),
      ],
    ),
    kitSection(
      'With add-ons',
      children: [
        const LedgerInputGroup(
          labelText: 'Shop address',
          before: 'https://',
          after: '.ledger.app',
          hintText: 'your-shop',
          helperText: 'Where your receipts link to',
        ),
        const LedgerInputGroup(
          labelText: 'Weight of the parcel',
          after: 'kg',
          hintText: '0.0',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        LedgerInputGroup(
          labelText: 'Account number',
          before: 'IBAN',
          hintText: 'GB00 0000 0000',
          action: LedgerIconButton(
            LucideIcons.copy,
            semanticLabel: 'Copy the account number',
            size: LedgerIconButtonSize.small,
            tapAlignment: AlignmentDirectional.centerEnd,
            onPressed: () {},
          ),
        ),
        const LedgerInputGroup(
          labelText: 'Held',
          before: 'https://',
          hintText: 'your-shop',
          enabled: false,
        ),
      ],
    ),
    kitSection(
      'Codes',
      children: [
        LedgerCodeField(
          labelText: 'Code from your bank',
          helperText: 'Six figures, sent by text',
          onCompleted: (_) {},
        ),
        const LedgerCodeField(
          labelText: 'Card PIN',
          length: 4,
          obscureText: true,
        ),
        const LedgerCodeField(
          labelText: 'Code from your bank',
          errorText: 'That code has run out; ask for another',
        ),
      ],
    ),
    kitSection(
      'Suggested as typed',
      children: [
        const _Payee(),
        const _Split(),
        const LedgerMultiSelect<String>(
          labelText: 'Held',
          values: ['Maren'],
          onChanged: _ignore,
          enabled: false,
        ),
      ],
    ),
    kitSection(
      'Attachments',
      children: const [
        _Receipts(),
        LedgerFileUpload(labelText: 'Held', onPick: null),
      ],
    ),
    kitSection('A period', children: const [_Period()]),
    kitSection(
      'Spans',
      children: [
        const _Span(),
        LedgerRangeSlider(
          label: 'Days back',
          values: const LedgerRangeValues(7, 30),
          min: 1,
          max: 90,
          unit: 'days',
          onChanged: (_) {},
        ),
        const LedgerRangeSlider(
          label: 'Held',
          values: LedgerRangeValues(.2, .6),
          onChanged: null,
        ),
      ],
    ),
  ],
);

void _ignore(List<String> _) {}
