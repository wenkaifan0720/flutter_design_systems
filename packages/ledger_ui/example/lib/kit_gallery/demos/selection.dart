/// What a person picks and settles: the filter chips ([LedgerChip] in its
/// [LedgerChipRow]), the check ([LedgerCheck]), the slider ([LedgerSlider]) and
/// the tabs ([LedgerTabs]). The first section is live: every control keeps
/// its value. The words are a stationery studio's books, not the pilot's.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitSelectionDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Selection',
  sections: [
    kitSection('Live', children: [const _Live()]),
    kitSection('Chips at rest', children: [kitSpecimenChipRest()]),
    kitSection('The chosen chip', children: [kitSpecimenChipSelected()]),
    kitSection('Checks at rest', children: [kitSpecimenCheckRest()]),
    kitSection('Checks, done and open', children: [kitSpecimenCheckSelected()]),
    kitSection('A slider', children: [kitSpecimenSliderContinuous()]),
    kitSection('A stepped slider', children: [kitSpecimenSliderStepped()]),
    kitSection('Tabs that fit', children: [kitSpecimenTabsFit()]),
    kitSection('Tabs that scroll', children: [kitSpecimenTabsScroll()]),
  ],
);

class _Live extends StatefulWidget {
  const _Live();

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  String _filter = 'Open';
  bool _done = false;
  double _weight = 120;
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: LedgerSpacing.s16,
    children: [
      LedgerChipRow(
        label: 'Show',
        children: [
          for (final f in _filters)
            LedgerChip(
              f,
              selected: f == _filter,
              onTap: () => setState(() => _filter = f),
            ),
        ],
      ),
      Row(
        spacing: LedgerSpacing.s12,
        children: [
          LedgerCheck(
            value: _done,
            label: 'Order the cotton paper',
            onChanged: (v) => setState(() => _done = v),
          ),
          // The words tick it too, as a line on a list is ticked; the check
          // already speaks them.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: () => setState(() => _done = !_done),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ExcludeSemantics(
                  child: _Words('Order the cotton paper', struck: _done),
                ),
              ),
            ),
          ),
        ],
      ),
      LedgerSlider(
        label: 'Paper weight',
        value: _weight,
        min: 80,
        max: 200,
        unit: 'gsm',
        onChanged: (v) => setState(() => _weight = v),
      ),
      LedgerTabs(
        tabs: _sections,
        selectedIndex: _tab,
        counts: const [12, 3, null],
        onSelected: (i) => setState(() => _tab = i),
      ),
    ],
  );
}

const List<String> _filters = ['All', 'Open', 'Paid', 'Late'];
const List<String> _sections = ['Entries', 'Notes', 'Files'];
const List<String> _more = [
  'Overview',
  'Entries',
  'Invoices',
  'Notes',
  'Files',
  'People',
  'History',
];

/// A line of words beside a control.
class _Words extends StatelessWidget {
  const _Words(this.text, {this.struck = false});

  final String text;
  final bool struck;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Text(
      text,
      style: t.rowTitle
          .colored(struck ? t.textTertiary : t.textPrimary)
          .copyWith(
            decoration: struck ? TextDecoration.lineThrough : null,
            decorationColor: t.textTertiary,
          ),
    );
  }
}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// The invoices' filters at rest, one with its glyph.
Widget kitSpecimenChipRest() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: LedgerChipRow(
    label: 'Show',
    children: [
      LedgerChip('All', onTap: () {}),
      LedgerChip('Open', icon: LucideIcons.clock, onTap: () {}),
      LedgerChip('Paid', onTap: () {}),
      LedgerChip('Late', onTap: () {}),
    ],
  ),
);

/// The chosen filter with its count.
Widget kitSpecimenChipSelected() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: LedgerChipRow(
    label: 'Show',
    children: [
      LedgerChip('All', onTap: () {}),
      LedgerChip('Open', selected: true, count: 4, onTap: () {}),
      LedgerChip('Paid', onTap: () {}),
    ],
  ),
);

/// A checklist at rest: nothing done yet.
Widget kitSpecimenCheckRest() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: LedgerSpacing.s12,
  children: [
    for (final item in const ['Order the cotton paper', 'Mix the walnut ink'])
      Row(
        spacing: LedgerSpacing.s12,
        children: [
          LedgerCheck(value: false, label: item, onChanged: (_) {}),
          Expanded(child: _Words(item)),
        ],
      ),
  ],
);

/// A checklist with its first line done, struck through.
Widget kitSpecimenCheckSelected() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: LedgerSpacing.s12,
  children: [
    Row(
      spacing: LedgerSpacing.s12,
      children: [
        LedgerCheck(value: true, label: 'Reconcile October', onChanged: (_) {}),
        const Expanded(child: _Words('Reconcile October', struck: true)),
      ],
    ),
    Row(
      spacing: LedgerSpacing.s12,
      children: [
        LedgerCheck(
          value: false,
          label: 'Post the invoices',
          onChanged: (_) {},
        ),
        const Expanded(child: _Words('Post the invoices')),
      ],
    ),
  ],
);

/// A continuous value under its label: the paper's weight.
Widget kitSpecimenSliderContinuous() => LedgerSlider(
  label: 'Paper weight',
  value: 120,
  min: 80,
  max: 200,
  unit: 'gsm',
  onChanged: (_) {},
);

/// A stepped value on a ticked track: pages written a day.
Widget kitSpecimenSliderStepped() => LedgerSlider(
  label: 'Pages a day',
  value: 15,
  min: 0,
  max: 50,
  divisions: 10,
  onChanged: (_) {},
);

/// A record's sections, with their counts, filling the width.
Widget kitSpecimenTabsFit() => LedgerTabs(
  tabs: _sections,
  selectedIndex: 0,
  counts: const [12, 3, null],
  onSelected: (_) {},
);

/// More sections than fit, scrolling, the chosen one in view.
Widget kitSpecimenTabsScroll() =>
    LedgerTabs(tabs: _more, selectedIndex: 2, onSelected: (_) {});
