import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Panels and rows: faceplates, legends, rows split by seams.
Widget kitListsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Lists and tables',
  sections: const [_Lists(), _Tables()],
);

class _Lists extends StatefulWidget {
  const _Lists();

  @override
  State<_Lists> createState() => _ListsState();
}

class _ListsState extends State<_Lists> {
  int _chosen = 1;
  bool _updates = true;

  @override
  Widget build(BuildContext context) {
    final t = context.applianceTheme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppliancePanel(
          child: Text(
            'A faceplate: smooth plastic seated in the housing.',
            style: t.body,
          ),
        ),
        const SizedBox(height: ApplianceSpacing.medium),
        AppliancePanel(
          onTap: () {},
          semanticLabel: 'A pressable faceplate',
          child: Text('A faceplate you can press.', style: t.body),
        ),
        const SizedBox(height: ApplianceSpacing.extraLarge),
        ApplianceListGroup(
          header: 'Rows',
          footer: 'Rows share a faceplate, split by hairline seams.',
          children: [
            ApplianceListTile(
              leading: const Icon(LucideIcons.bell),
              title: 'Order updates',
              subtitle: 'When an order ships and arrives',
              trailing: ApplianceSwitch(
                value: _updates,
                semanticLabel: 'Order updates',
                onChanged: (v) => setState(() => _updates = v),
              ),
            ),
            ApplianceListTile(
              leading: const Icon(LucideIcons.mapPin),
              title: 'Address',
              trailingText: '14 Orchard Row',
              onTap: () {},
            ),
            const ApplianceListTile(title: 'Disabled', enabled: false),
            ApplianceListTile(
              title: 'Delete account',
              isDestructiveAction: true,
              showChevron: false,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: ApplianceSpacing.extraLarge),
        ApplianceListGroup(
          header: 'A chosen row',
          children: [
            for (final (i, name) in const ['Chalk', 'Clay', 'Slate'].indexed)
              ApplianceListTile(
                title: name,
                selected: i == _chosen,
                showChevron: false,
                onTap: () => setState(() => _chosen = i),
              ),
          ],
        ),
      ],
    );
  }
}

typedef _Line = ({String item, String room, double price});

/// Tables, a tree, a lid, a list to reorder and rows to swipe, a split
/// view and a carousel.
class _Tables extends StatefulWidget {
  const _Tables();

  @override
  State<_Tables> createState() => _TablesState();
}

class _TablesState extends State<_Tables> {
  final _table = RawDataTableController<_Line>(
    rows: const [
      (item: 'Kettle', room: 'Kitchen', price: 48),
      (item: 'Toaster', room: 'Kitchen', price: 36),
      (item: 'Door mat', room: 'Hall', price: 18),
      (item: 'Watering can', room: 'Garden', price: 24),
    ],
    columns: [
      RawDataColumn<_Line>(id: 'item', label: 'Item', sortKey: (l) => l.item),
      RawDataColumn<_Line>(id: 'room', label: 'Room', sortKey: (l) => l.room),
      RawDataColumn<_Line>(
        id: 'price',
        label: 'Price',
        numeric: true,
        sortKey: (l) => l.price,
      ),
    ],
  );
  final _tree = DesignTreeController<String>(
    roots: const ['Kitchen', 'Hall', 'Garden'],
    expanded: const ['Kitchen'],
    childrenOf: (node) => switch (node) {
      'Kitchen' => const ['Kettles', 'Toasters', 'Teapots'],
      'Hall' => const ['Mats', 'Hooks'],
      'Garden' => const ['Cans'],
      _ => const [],
    },
  );
  final _scroll = ScrollController();
  List<String> _list = const ['Milk', 'Eggs', 'Bread', 'Butter'];

  @override
  void dispose() {
    _table.dispose();
    _tree.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const KitSection(
        title: 'Tables',
        note: 'Rows ruled on the panel; figures set to the end.',
        children: [
          ApplianceTable(
            columns: [
              ApplianceTableColumn('Item', flex: 2),
              ApplianceTableColumn('Qty', numeric: true),
              ApplianceTableColumn('Price', numeric: true),
            ],
            rows: [
              ['Kettle', '1', '£48.00'],
              ['Teapot', '2', '£44.00'],
            ],
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Data table',
        note: 'Legends sort; a selected row is pressed into the panel.',
        children: [
          ApplianceDataTable<_Line>(
            controller: _table,
            rowLabel: (l) => l.item,
            cellText: (l, c) => switch (c.id) {
              'room' => l.room,
              'price' => '£${l.price.toStringAsFixed(2)}',
              _ => l.item,
            },
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Tree and lids',
        note: 'Rows open under their chevrons; a lid lifts on more.',
        children: [
          ApplianceTree<String>(controller: _tree, labelOf: (n) => n),
          const ApplianceDisclosure(
            title: 'Care and cleaning',
            subtitle: 'Descaling, the filter, the base',
            child: Text('Descale monthly; wipe the outside with a damp cloth.'),
          ),
          const ApplianceDisclosure(
            title: 'Warranty',
            initiallyOpen: true,
            child: Text('Two years, parts and labour.'),
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Lists that move',
        note: 'Drag a row by its grip; swipe a row for the keys behind it.',
        children: [
          ApplianceReorderableList<String>(
            items: _list,
            labelOf: (i) => i,
            title: (i) => i,
            onReorder: (from, to) => setState(() {
              final next = [..._list];
              final moved = next.removeAt(from);
              next.insert(to > from ? to - 1 : to, moved);
              _list = next;
            }),
          ),
          ApplianceSwipeActions(
            startActions: [RawSwipeAction(label: 'Save', onPressed: () {})],
            endActions: [
              RawSwipeAction(
                label: 'Remove',
                destructive: true,
                onPressed: () {},
              ),
            ],
            child: const ApplianceListTile(
              title: 'Kettle',
              subtitle: 'Swipe either way',
              trailingText: '£48',
            ),
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Panes and slides',
        note: 'A grip shares the room; a window of slides with its lamps.',
        children: [
          SizedBox(
            height: 160,
            child: ApplianceSplitView(
              minFirst: 80,
              minSecond: 80,
              first: ApplianceScrollArea(
                controller: _scroll,
                semanticLabel: 'Orders',
                child: ListView(
                  controller: _scroll,
                  children: [
                    for (var i = 1048; i > 1030; i--)
                      ApplianceListTile(title: 'Order $i'),
                  ],
                ),
              ),
              second: const Center(child: Text('Order 1048')),
            ),
          ),
          ApplianceCarousel(
            itemCount: 3,
            height: 140,
            semanticLabel: 'Offers',
            itemBuilder: (context, i) => Center(
              child: Text(const ['Kettles', 'Toasters', 'Teapots'][i]),
            ),
          ),
        ],
      ),
    ],
  );
}
