/// The Screen · Orders gallery group: a bakery's back office on Friday
/// morning, standing as a nav root over its own tab bar — the day's KPI
/// strip (revenue with its week's sparkline, orders, the late ones in the
/// warn ink), the Open · Ready · Done count filters (live: they switch the
/// orders), and the orders: on a phone a list (the customer, the number,
/// the items and the slot, the stage's badge), from a tablet up the table
/// with its pinned header (mono order numbers, quantities, due times with
/// the overdue ones toned, status badges, the picked-up orders faded). A
/// row opens its order — a page on a phone, a side sheet beside the table
/// — whose one action moves it on (Mark ready, Mark picked up), with an
/// undo. The range menu beside the title picks the day.
library;

import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
import '../kit_words.dart';

Widget kitScreenOrdersDemo(Brightness brightness) => kitSurface(
  brightness: brightness,
  child: MinimalPreview(
    light: kitTheme(Brightness.light),
    dark: kitTheme(Brightness.dark),
    brightness: brightness,
    tabs: _tabs,
    child: const KitOrdersPage(),
  ),
);

List<MinimalNavItem> get _tabs => [
  MinimalNavItem(LucideIcons.receiptText, ar('Orders', 'الطلبات')),
  MinimalNavItem(LucideIcons.croissant, ar('Products', 'المنتجات')),
  MinimalNavItem(LucideIcons.users, ar('Customers', 'العملاء')),
  MinimalNavItem(LucideIcons.chartNoAxesColumn, ar('Reports', 'التقارير')),
];

/// Where an order stands: waiting for the oven, in it, on the shelf,
/// collected — or overdue before it was ever baked.
enum _Stage {
  queued('Queued', 'في الانتظار', MinimalTone.neutral),
  late('Late', 'متأخر', MinimalTone.warning),
  baking('Baking', 'في الفرن', MinimalTone.primary),
  ready('Ready', 'جاهز', MinimalTone.success),
  pickedUp('Picked up', 'استُلم', MinimalTone.neutral);

  const _Stage(this.english, this.arabic, this.tone);

  final String english;
  final String arabic;
  final MinimalTone tone;

  /// The stage's name in the gallery's language.
  String get label => ar(english, arabic);
}

/// One order: its number, who it is for, how many items, when it is due,
/// where it stands and whether its slot has already passed (it is 09:48).
typedef _Order = ({
  int id,
  String customer,
  int qty,
  String due,
  _Stage stage,
  bool overdue,
});

_Order _order(
  int id,
  String customer,
  int qty,
  String due,
  _Stage stage, {
  bool overdue = false,
}) => (
  id: id,
  customer: customer,
  qty: qty,
  due: due,
  stage: stage,
  overdue: overdue,
);

/// Not yet on the shelf: two past their slot, two in the oven, two
/// waiting their turn.
List<_Order> get _open => [
  _order(
    1047,
    ar('Hanna Berg', 'هند البرغوثي'),
    3,
    '09:30',
    _Stage.late,
    overdue: true,
  ),
  _order(
    1048,
    ar('Liv Sande', 'لينا سعادة'),
    4,
    '09:40',
    _Stage.late,
    overdue: true,
  ),
  _order(1046, ar('Oskar Lind', 'عمر الخطيب'), 1, '09:50', _Stage.baking),
  _order(1045, ar('Café Morgen', 'مقهى الصباح'), 24, '10:00', _Stage.baking),
  _order(
    1042,
    ar('Studio North', 'استوديو الشمال'),
    12,
    '11:00',
    _Stage.queued,
  ),
  _order(1041, ar('Mara Quintero', 'مريم القنطار'), 2, '11:15', _Stage.queued),
];

/// On the shelf, waiting for their customers. Only an order that is not
/// ready by its slot is late, so the strip's two late orders are the two
/// open ones above.
List<_Order> get _ready => [
  _order(1038, ar('Ines Duarte', 'هالة منصور'), 2, '09:35', _Stage.ready),
  _order(1039, ar('Tom Alves', 'طارق عيسى'), 6, '09:45', _Stage.ready),
  _order(1040, ar('Jonas Weber', 'يونس وهبة'), 1, '09:55', _Stage.ready),
  _order(1043, ar('Elif Kaya', 'إيلاف قايا'), 2, '10:05', _Stage.ready),
  _order(1044, ar('Bruno Maier', 'باسل معلوف'), 8, '10:10', _Stage.ready),
  _order(1049, ar('Sofie Dahl', 'صوفيا دلّال'), 3, '10:20', _Stage.ready),
  _order(1050, ar('Arne Vik', 'عرفان فكري'), 1, '10:30', _Stage.ready),
  _order(1051, ar('Lotte Janssen', 'لطيفة جنيد'), 5, '10:45', _Stage.ready),
  _order(1052, ar('Kiosk am Park', 'كشك الحديقة'), 30, '11:30', _Stage.ready),
];

/// Collected since the doors opened at seven: 1015 to 1037, most recent
/// first, one every six minutes or so.
List<_Order> get _done => [
  for (var i = 0; i < 23; i++)
    _order(
      1037 - i,
      _regulars[i % _regulars.length],
      const [2, 1, 4, 6, 1, 3, 12, 2, 1, 5][i % 10],
      _clock(9 * 60 + 25 - i * 6 - i % 3),
      _Stage.pickedUp,
    ),
];

List<String> get _regulars => [
  ar('Pia Moreno', 'بشرى مراد'),
  ar('Emil Strand', 'إميل صرّاف'),
  ar('Noor Haddad', 'نور حداد'),
  ar('Café Morgen', 'مقهى الصباح'),
  ar('Felix Aalto', 'فارس العطار'),
  ar('Greta Lund', 'غادة لحود'),
  ar('Studio North', 'استوديو الشمال'),
  ar('Yusuf Demir', 'يوسف دمير'),
  ar('Clara Nyberg', 'كلارا نجار'),
  ar('Theo Brandt', 'ثائر برّاج'),
  ar('Maja Holm', 'مايا حلمي'),
];

/// Minutes past midnight as the day's mono clock (`07:04`).
String _clock(int minutes) =>
    MinimalFormat.clock(DateTime(2026, 8, 28, minutes ~/ 60, minutes % 60));

/// Revenue by day, Saturday to Friday, ending on today.
const List<double> _week = [6, 11, 4, 14, 18, 13, 22];

/// From this wide the orders stand in a table rather than a list.
const double _tableFrom = MinimalLayout.compact;

/// From this wide the table adds the columns a laptop has room for: how the
/// order came in, when it was placed and what it comes to.
const double _wideFrom = 840;

/// How an order came in, by its number.
String _channel(_Order o) => [
  ar('Counter', 'الكاونتر'),
  ar('App', 'التطبيق'),
  ar('Phone', 'الهاتف'),
][o.id % 3];

/// When it was placed: most of an hour before its slot, earlier for the
/// bigger ones, and never later than this morning (it is 09:48).
String _placed(_Order o) {
  final due =
      int.parse(o.due.substring(0, 2)) * 60 + int.parse(o.due.substring(3));
  final placed = due - 40 - (o.id % 4) * 10 - (o.qty > 10 ? 60 : 0);
  final latest = 9 * 60 + 40 - (o.id % 4) * 5;
  return _clock(placed < latest ? placed : latest);
}

/// An item's price, in cents: everything on the counter is €3.40.
const int _each = 340;

/// What it comes to.
String _total(_Order o) => MinimalFormat.money(o.qty * _each, symbol: '€');

/// What is in it: its items over at most three of the counter's goods.
List<({String name, int count})> _lines(_Order o) {
  final goods = [
    ar('Cardamom bun', 'كعكة الهيل'),
    ar('Cinnamon roll', 'لفافة القرفة'),
    ar('Butter croissant', 'كرواسون بالزبدة'),
  ];
  final kinds = o.qty < goods.length ? o.qty : goods.length;
  final lines = <({String name, int count})>[];
  var left = o.qty;
  for (var k = 0; k < kinds; k++) {
    final count = (left / (kinds - k)).ceil();
    left -= count;
    lines.add((name: goods[(o.id + k) % goods.length], count: count));
  }
  return lines;
}

/// "3 items", "1 item".
String _items(int qty) => kitArabic
    ? (qty == 1 ? 'قطعة واحدة' : '$qty قطع')
    : (qty == 1 ? '1 item' : '$qty items');

/// The table's columns by what they hold, so a sort survives the table
/// gaining or losing its wide columns.
enum _Col { id, customer, channel, placed, qty, due, total, status }

/// The Orders root: the bar with the day's range, the KPI strip, the
/// filters and the orders they pick, each opening as itself. [leading]
/// stands at the bar's start (an app's way out).
class KitOrdersPage extends StatefulWidget {
  const KitOrdersPage({super.key, this.leading});

  final Widget? leading;

  @override
  State<KitOrdersPage> createState() => _KitOrdersPageState();
}

class _KitOrdersPageState extends State<KitOrdersPage> {
  static List<String> get _ranges => [
    ar('Today', 'اليوم'),
    ar('Yesterday', 'أمس'),
    ar('This week', 'هذا الأسبوع'),
  ];

  String _range = _ranges.first;
  int _view = 0;
  // The rows stand in due order, and the Due header says so.
  _Col? _sort = _Col.due;
  bool _ascending = true;
  int? _selected;

  // The day so far, which the orders' actions move on.
  final List<_Order> _openRows = [..._open];
  final List<_Order> _readyRows = [..._ready];
  final List<_Order> _doneRows = [..._done];

  List<_Order> get _rows {
    final rows = [
      ...switch (_view) {
        0 => _openRows,
        1 => _readyRows,
        _ => _doneRows,
      },
    ];
    final sort = _sort;
    if (sort == null) return rows;
    int compare(_Order a, _Order b) => switch (sort) {
      _Col.id => a.id.compareTo(b.id),
      _Col.qty || _Col.total => a.qty.compareTo(b.qty),
      _ => a.due.compareTo(b.due),
    };
    rows.sort((a, b) => _ascending ? compare(a, b) : compare(b, a));
    return rows;
  }

  /// What moves [o] on, by where it stands; null once it is collected.
  String? _next(_Order o) => switch (o.stage) {
    _Stage.ready => ar('Mark picked up', 'علّمه مستلمًا'),
    _Stage.pickedUp => null,
    _ => ar('Mark ready', 'علّمه جاهزًا'),
  };

  /// Moves [o] to its next list, with a toast whose Undo puts it back.
  void _advance(_Order o) {
    final from = o.stage == _Stage.ready ? _readyRows : _openRows;
    final to = o.stage == _Stage.ready ? _doneRows : _readyRows;
    final moved = _order(
      o.id,
      o.customer,
      o.qty,
      o.due,
      o.stage == _Stage.ready ? _Stage.pickedUp : _Stage.ready,
    );
    final at = from.indexOf(o);
    setState(() {
      from.removeAt(at);
      to.insert(0, moved);
      if (_selected == o.id) _selected = null;
    });
    showMinimalSnackBar(
      context,
      kitArabic
          ? '#${o.id} ${moved.stage == _Stage.ready ? 'جاهز' : 'استُلم'}'
          : '#${o.id} ${moved.stage == _Stage.ready ? 'ready' : 'picked up'}',
      icon: LucideIcons.check,
      actionLabel: ar('Undo', 'تراجع'),
      onAction: () {
        if (!mounted) return;
        setState(() {
          to.remove(moved);
          from.insert(at.clamp(0, from.length), o);
        });
      },
    );
  }

  /// Opens [o]: beside the table a side sheet, on a phone a page.
  void _openOrder(_Order o, {required bool table}) {
    final next = _next(o);
    if (table) {
      setState(() => _selected = o.id);
      showMinimalSheet<void>(
        context,
        title: ar('Order #${o.id}', 'الطلب #${o.id}'),
        subtitle: o.customer,
        builder: (_) => _OrderDetails(o),
        trailing: next == null
            ? null
            : MinimalSheetAction(
                next,
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  _advance(o);
                },
              ),
      ).whenComplete(() {
        if (mounted && _selected == o.id) setState(() => _selected = null);
      });
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (page) => MinimalScaffold(
          topBar: MinimalAppBar(
            parent: ar('Orders', 'الطلبات'),
            title: '#${o.id}',
            subtitle: o.customer,
          ),
          footer: next == null
              ? null
              : MinimalActionBar(
                  summary: _total(o),
                  detail: _items(o.qty),
                  label: next,
                  onPressed: () {
                    Navigator.of(page).pop();
                    _advance(o);
                  },
                ),
          body: _OrderDetails(o),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => _page(
      context,
      table: box.maxWidth >= _tableFrom,
      wide: box.maxWidth >= _wideFrom,
    ),
  );

  Widget _page(
    BuildContext context, {
    required bool table,
    required bool wide,
  }) {
    final rows = _rows;
    final late = [
      for (final o in _openRows)
        if (o.overdue) o,
    ]..sort((a, b) => a.due.compareTo(b.due));
    final views = [
      (ar('Open', 'مفتوحة'), _openRows.length),
      (ar('Ready', 'جاهزة'), _readyRows.length),
      (ar('Done', 'منتهية'), _doneRows.length),
    ];
    final orders = _openRows.length + _readyRows.length + _doneRows.length;
    return MinimalScaffold(
      topBar: MinimalAppBar(
        leading: widget.leading,
        title: ar('Orders', 'الطلبات'),
        // The range menu stands beside the title it scopes.
        titleTrailing: MinimalMenu.button(
          LucideIcons.calendarDays,
          text: _range,
          label: ar('Date range', 'النطاق الزمني'),
          items: [
            for (final range in _ranges)
              MinimalMenuItem(
                range,
                selected: range == _range,
                onPressed: () => setState(() => _range = range),
              ),
          ],
        ),
      ),
      padding: EdgeInsets.zero,
      scroll: false,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              MinimalChromeMetrics.gutter,
              MinimalSpacing.s16,
              MinimalChromeMetrics.gutter,
              MinimalSpacing.s4,
            ),
            sliver: SliverToBoxAdapter(
              child: MinimalStatRow.joined(
                children: [
                  MinimalStat(
                    label: ar('Revenue', 'الإيرادات'),
                    value: '€1,284',
                    delta: '12%',
                    detail: ar('vs last Fri', 'مقارنة بالجمعة الماضية'),
                    spark: _week,
                    weight: 1.3,
                  ),
                  MinimalStat(
                    label: ar('Orders', 'الطلبات'),
                    value: '$orders',
                    detail: ar(
                      '${_openRows.length} open',
                      '${_openRows.length} مفتوحة',
                    ),
                  ),
                  MinimalStat(
                    label: ar('Late', 'متأخرة'),
                    value: '${late.length}',
                    detail: late.isEmpty
                        ? ar('none', 'لا شيء')
                        : ar(
                            'since ${late.first.due}',
                            'منذ ${late.first.due}',
                          ),
                    tone: late.isEmpty ? null : MinimalTone.warning,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: MinimalFilterBar(
              // The table's header band follows with its own rule.
              divider: !table,
              children: [
                for (final (i, (label, count)) in views.indexed)
                  MinimalFilter(
                    label,
                    count: count,
                    selected: i == _view,
                    onPressed: () => setState(() {
                      _view = i;
                      _selected = null;
                    }),
                  ),
              ],
            ),
          ),
          if (table)
            _table(rows, wide: wide)
          else
            SliverToBoxAdapter(
              child: MinimalListSection(
                children: [
                  for (final o in rows)
                    MinimalListTile(
                      title: o.customer,
                      subtitle: '#${o.id} · ${_items(o.qty)} · ${o.due}',
                      muted: o.stage == _Stage.pickedUp,
                      trailing: MinimalStatusBadge(
                        o.stage.label,
                        tone: o.stage.tone,
                      ),
                      onTap: () => _openOrder(o, table: false),
                    ),
                ],
              ),
            ),
          const SliverSafeArea(
            top: false,
            sliver: SliverToBoxAdapter(child: MinimalGap(MinimalSpacing.s24)),
          ),
        ],
      ),
    );
  }

  /// The orders as a table, with the laptop's columns when [wide].
  Widget _table(List<_Order> rows, {required bool wide}) {
    final cols = [
      _Col.id,
      _Col.customer,
      if (wide) ...[_Col.channel, _Col.placed],
      _Col.qty,
      _Col.due,
      if (wide) _Col.total,
      _Col.status,
    ];
    final sort = _sort;
    return MinimalTable.sliver(
      columns: [
        for (final col in cols)
          switch (col) {
            _Col.id => const MinimalColumn(
              '#',
              width: 40,
              mono: true,
              sortable: true,
            ),
            _Col.customer => MinimalColumn(ar('Customer', 'العميل')),
            _Col.channel => MinimalColumn(ar('Channel', 'القناة'), width: 88),
            _Col.placed => MinimalColumn(
              ar('Placed', 'وقت الطلب'),
              width: 64,
              numeric: true,
            ),
            _Col.qty => MinimalColumn(
              ar('Qty', 'الكمية'),
              width: 38,
              numeric: true,
              sortable: true,
            ),
            _Col.due => MinimalColumn(
              ar('Due', 'الموعد'),
              width: 56,
              numeric: true,
              sortable: true,
            ),
            _Col.total => MinimalColumn(
              ar('Total', 'المجموع'),
              width: 88,
              numeric: true,
              sortable: true,
            ),
            _Col.status => MinimalColumn(
              ar('Status', 'الحالة'),
              width: 88,
              alignEnd: true,
            ),
          },
      ],
      sortColumn: sort == null ? null : cols.indexOf(sort),
      sortAscending: _ascending,
      onSort: (column, ascending) => setState(() {
        _sort = cols[column];
        _ascending = ascending;
      }),
      onRowPressed: (i) => _openOrder(rows[i], table: true),
      rows: [
        for (final o in rows)
          MinimalTableRow(
            [
              for (final col in cols)
                switch (col) {
                  _Col.id => MinimalCell('${o.id}'),
                  _Col.customer => MinimalCell(o.customer, strong: true),
                  _Col.channel => MinimalCell(_channel(o)),
                  _Col.placed => MinimalCell(_placed(o)),
                  _Col.qty => MinimalCell('${o.qty}'),
                  _Col.due => MinimalCell(
                    o.due,
                    tone: o.overdue ? MinimalTone.warning : null,
                  ),
                  _Col.total => MinimalCell(_total(o)),
                  _Col.status => MinimalCell.badge(
                    o.stage.label,
                    tone: o.stage.tone,
                  ),
                },
            ],
            faded: o.stage == _Stage.pickedUp,
            selected: o.id == _selected,
            semanticLabel: kitArabic
                ? 'الطلب ${o.id}، ${o.customer}، ${_items(o.qty)}، '
                      'الموعد ${o.due}، ${o.stage.label}'
                      '${o.overdue && o.stage != _Stage.late ? '، متأخر' : ''}'
                : 'Order ${o.id}, ${o.customer}, ${o.qty} items, '
                      'due ${o.due}, ${o.stage.label}'
                      '${o.overdue && o.stage != _Stage.late ? ', overdue' : ''}',
          ),
      ],
    );
  }
}

/// One order: where it stands, then what is in it and what it comes to.
class _OrderDetails extends StatelessWidget {
  const _OrderDetails(this.order);

  final _Order order;

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalDescriptionList(
          properties: [
            MinimalProperty(
              icon: LucideIcons.circleDot,
              label: ar('Status', 'الحالة'),
              value: o.stage.label,
              tone: o.stage.tone,
            ),
            MinimalProperty(
              icon: LucideIcons.clock,
              label: ar('Due', 'الموعد'),
              value: o.due,
              detail: o.overdue ? ar('overdue', 'متأخر') : null,
              mono: true,
            ),
            MinimalProperty(
              icon: LucideIcons.store,
              label: ar('Channel', 'القناة'),
              value: _channel(o),
            ),
            MinimalProperty(
              icon: LucideIcons.receiptText,
              label: ar('Placed', 'وقت الطلب'),
              value: _placed(o),
              mono: true,
            ),
          ],
        ),
        MinimalSectionHeader(
          ar('Items', 'القطع'),
          count: '${o.qty}',
          padding: const EdgeInsets.fromLTRB(
            0,
            MinimalSpacing.s24,
            0,
            MinimalSpacing.s4,
          ),
        ),
        MinimalListSection(
          children: [
            for (final line in _lines(o))
              MinimalListTile(
                title: line.name,
                subtitle:
                    '${line.count} × ${MinimalFormat.money(_each, symbol: '€')}',
                meta: MinimalFormat.money(line.count * _each, symbol: '€'),
              ),
            MinimalListTile(title: ar('Total', 'المجموع'), meta: _total(o)),
          ],
        ),
      ],
    );
  }
}
