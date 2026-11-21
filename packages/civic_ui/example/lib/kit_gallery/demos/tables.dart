// Facts in columns: a plain table, and one whose columns sort, whose rows
// tick (with what can be done to them over it) and whose pages follow
// under it.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitTablesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Tables',
  intro:
      'Numbers line up at the end of their column. A column that sorts '
      'says so with an arrow; its name is a link.',
  sections: const [_Fees(), _Permits()],
);

typedef _Fee = ({String permit, String year, String month});

const List<_Fee> _fees = [
  (permit: 'Resident permit', year: '€60', month: '€6'),
  (permit: 'Electric vehicle', year: '€30', month: '€3'),
  (permit: 'Second permit', year: '€120', month: '€12'),
];

class _Fees extends StatefulWidget {
  const _Fees();

  @override
  State<_Fees> createState() => _FeesState();
}

class _FeesState extends State<_Fees> {
  final _rows = RawDataTableController<_Fee>(
    rows: _fees,
    columns: const [
      RawDataColumn(id: 'permit', label: 'Permit'),
      RawDataColumn(id: 'year', label: 'A year', numeric: true),
      RawDataColumn(id: 'month', label: 'A month', numeric: true),
    ],
  );

  @override
  void dispose() {
    _rows.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Table',
    children: [
      CivicTable<_Fee>(
        caption: 'Permit fees',
        controller: _rows,
        cellBuilder: (context, fee, column) => Text(switch (column.id) {
          'year' => fee.year,
          'month' => fee.month,
          _ => fee.permit,
        }),
      ),
    ],
  );
}

typedef _Permit = ({String reg, String zone, int days});

const List<_Permit> _permits = [
  (reg: 'BR21 KLM', zone: 'B', days: 212),
  (reg: 'BR19 XTP', zone: 'B', days: 31),
  (reg: 'MV70 OAK', zone: 'A', days: 340),
  (reg: 'LT68 RWE', zone: 'C', days: 5),
  (reg: 'BR22 HNA', zone: 'D', days: 88),
  (reg: 'CY17 PDQ', zone: 'A', days: 150),
  (reg: 'BR20 JUV', zone: 'C', days: 61),
];

class _Permits extends StatefulWidget {
  const _Permits();

  @override
  State<_Permits> createState() => _PermitsState();
}

class _PermitsState extends State<_Permits> {
  final _rows = RawDataTableController<_Permit>(
    rows: _permits,
    pageSize: 4,
    columns: [
      RawDataColumn(id: 'reg', label: 'Vehicle', sortKey: (p) => p.reg),
      RawDataColumn(id: 'zone', label: 'Zone', sortKey: (p) => p.zone),
      RawDataColumn(
        id: 'days',
        label: 'Days left',
        numeric: true,
        sortKey: (p) => p.days,
      ),
    ],
  );

  @override
  void dispose() {
    _rows.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Sorting, ticking and pages',
    caption: 'Tick a row: what can be done to the ticked rows shows over it.',
    children: [
      ListenableBuilder(
        listenable: _rows,
        builder: (context, _) => CivicActionBar(
          count: _rows.selectedCount,
          onClear: _rows.clearSelection,
          actions: [
            CivicButton.secondary(
              expand: false,
              onPressed: () {},
              child: const Text('Renew'),
            ),
            CivicButton.secondary(
              expand: false,
              onPressed: () {},
              isDestructiveAction: true,
              child: const Text('Cancel permits'),
            ),
          ],
        ),
      ),
      CivicTable<_Permit>(
        caption: 'Permits you manage',
        controller: _rows,
        selectable: true,
        cellBuilder: (context, permit, column) => Text(switch (column.id) {
          'zone' => 'Zone ${permit.zone}',
          'days' => '${permit.days}',
          _ => permit.reg,
        }),
      ),
    ],
  );
}
