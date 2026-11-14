// Fluent 2's answer to the shared component inventory (ui_core's DesignInventoryRow.all, 89 rows): for each row the part
// that answers it, `Fluent2<Stem>`, as a small live specimen. The live gallery lists it, and a test verifies it (every
// row answered once, every specimen the row's own class).
import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';

import '../fluent2.dart';

void _none() {}
void _drop(Object? _) {}

const _home = Fluent2NavItem(Fluent2Icons.home, 'Home');
const _files = Fluent2NavItem(Fluent2Icons.folder, 'Files');
const _people = Fluent2NavItem(Fluent2Icons.person, 'People');

const _sizes = [
  Fluent2Option('small', 'Small'),
  Fluent2Option('medium', 'Medium'),
  Fluent2Option('large', 'Large'),
];

// The specimens' controllers: one gallery shows the inventory at a time, so each specimen keeps one for the app's life.
final _scroll = ScrollController();
final _stay = DesignCalendarController(
  firstDate: DateTime(2026, 6),
  lastDate: DateTime(2026, 9, 30),
  mode: DesignCalendarMode.range,
  selectedRange: DesignDateRange(DateTime(2026, 6, 14), DateTime(2026, 6, 18)),
  currentDate: DateTime(2026, 6, 10),
);
// The colour picker's starts on the theme's brand, the first time it is built.
DesignColorController? _colour;

class _File {
  const _File(this.name, this.pages);
  final String name;
  final int pages;
}

final _rows = DesignTableController<_File>(
  rows: const [_File('Budget', 12), _File('Roadmap', 8), _File('Handbook', 40)],
  columns: [
    DesignTableColumn<_File>(id: 'name', label: 'Name', sortKey: (f) => f.name),
    DesignTableColumn<_File>(
      id: 'pages',
      label: 'Pages',
      numeric: true,
      sortKey: (f) => f.pages,
    ),
  ],
);

/// The specimens that fill the height they are given; a gallery frames each in
/// a box of this height.
const Map<String, double> fluent2InventoryHeights = {
  'NavigationRail': 300,
  'NavigationDrawer': 320,
  'Scaffold': 260,
  'Sheet': 260,
  'Resizable': 160,
  'ScrollArea': 140,
  'RefreshIndicator': 140,
};

Widget _say(String words) => Center(child: Text(words));

/// Fluent 2's inventory: every row of the shared component list, answered.
final DesignInventory fluent2Inventory = DesignInventory(
  look: 'Fluent 2',
  entries: [
    // Actions
    DesignInventoryEntry.present(
      'Button',
      (_) => const Fluent2Button('Share', onPressed: _none),
    ),
    DesignInventoryEntry.present(
      'IconButton',
      (_) => const Fluent2IconButton(
        Fluent2Icons.share,
        label: 'Share',
        onPressed: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'FloatingActionButton',
      (_) => const Fluent2FloatingActionButton(
        icon: Fluent2Icons.add,
        label: 'New',
        onPressed: _none,
      ),
    ),
    DesignInventoryEntry.absent(
      'ButtonGroup',
      'Fluent 2 joins no buttons in one frame: related acts stand in its '
          'Toolbar (Fluent2Toolbar)',
    ),
    DesignInventoryEntry.absent(
      'ToggleGroup',
      'Fluent 2 joins no toggles in one frame: toggles stand in its Toolbar '
          '(Fluent2Toolbar), and one choice of several is its segmented '
          'control (Fluent2SegmentedButton)',
    ),
    DesignInventoryEntry.present(
      'SplitButton',
      (_) => const Fluent2SplitButton(
        'Publish',
        onPressed: _none,
        actions: [
          Fluent2SplitAction('Schedule', onPressed: _none),
          Fluent2SplitAction('Save as draft', onPressed: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Link',
      (_) => const Fluent2Link('Read the guide', onPressed: _none),
    ),
    DesignInventoryEntry.present('Kbd', (_) => const Fluent2Kbd(['Ctrl', 'K'])),
    // Inputs
    DesignInventoryEntry.present(
      'TextField',
      (_) =>
          Fluent2TextField(label: 'Name', value: 'Sam Lee', onChanged: (_) {}),
    ),
    DesignInventoryEntry.present(
      'TextArea',
      (_) => Fluent2TextArea(label: 'Note', onChanged: (_) {}),
    ),
    DesignInventoryEntry.present(
      'SearchField',
      (_) => Fluent2SearchBox(hint: 'Find a file', onChanged: (_) {}),
    ),
    DesignInventoryEntry.present(
      'PasswordField',
      (_) => Fluent2PasswordField(label: 'Password', onChanged: (_) {}),
    ),
    DesignInventoryEntry.present(
      'InputGroup',
      (_) => const Fluent2InputGroup(
        label: 'Website',
        prefix: 'https://',
        suffix: '.com',
      ),
    ),
    DesignInventoryEntry.absent(
      'InputOtp',
      "Fluent 2 has no code boxes: Microsoft's sign-in asks for a code in one "
          'Input (Fluent2TextField with the number keyboard)',
    ),
    DesignInventoryEntry.present(
      'NumberField',
      (_) =>
          const Fluent2SpinButton(label: 'Copies', value: 2, onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'Select',
      (_) => const Fluent2Select<String>(
        label: 'Size',
        value: 'medium',
        options: _sizes,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Combobox',
      (_) => const Fluent2Combobox<String>(
        label: 'Size',
        value: 'medium',
        options: _sizes,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'MultiSelect',
      (_) => const Fluent2MultiSelect<String>(
        label: 'Sizes',
        selected: ['small'],
        options: _sizes,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Checkbox',
      (_) => const Fluent2Checkbox(
        label: 'Include archived files',
        value: true,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'RadioGroup',
      (_) => const Fluent2RadioGroup<String>(
        label: 'Size',
        value: 'medium',
        options: [
          Fluent2Radio('small', 'Small'),
          Fluent2Radio('medium', 'Medium'),
          Fluent2Radio('large', 'Large'),
        ],
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Switch',
      (_) => const Fluent2Switch(label: 'Sync', value: true, onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'Slider',
      (_) => const Fluent2Slider(label: 'Volume', value: 40, onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'RangeSlider',
      (_) => const Fluent2RangeSlider(
        label: 'Pages',
        values: DesignRangeValues(20, 60),
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'SegmentedButton',
      (_) => const Fluent2SegmentedButton<String>(
        label: 'Size',
        value: 'medium',
        segments: [
          Fluent2ButtonSegment('small', 'Small'),
          Fluent2ButtonSegment('medium', 'Medium'),
          Fluent2ButtonSegment('large', 'Large'),
        ],
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Chip',
      (_) => const Fluent2InteractionTag(
        'Shared',
        selected: true,
        onPressed: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'Rating',
      (_) => const Fluent2Rating(label: 'Rating', value: 4, onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'FileUpload',
      (_) => Fluent2FileUpload(label: 'Attachments', onPressed: () {}),
    ),
    DesignInventoryEntry.present(
      'DatePicker',
      (_) => Fluent2DatePicker(
        label: 'Due',
        value: DateTime(2026, 6, 14),
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'DateRangePicker',
      (_) => Fluent2DateRangePicker(controller: _stay),
    ),
    DesignInventoryEntry.present(
      'TimePicker',
      (_) => const Fluent2TimePicker(
        label: 'Start',
        value: Fluent2Time(9, 30),
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Calendar',
      (_) => Fluent2Calendar(
        value: DateTime(2026, 6, 14),
        today: DateTime(2026, 6, 10),
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'WheelPicker',
      (_) => const Fluent2WheelPicker<String>(
        label: 'Size',
        items: ['Small', 'Medium', 'Large'],
        value: 'Medium',
        rows: 3,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'ColorPicker',
      (context) => Fluent2ColorPicker(
        controller: _colour ??= DesignColorController(
          context.fluent2Theme.colors.compoundBrandForeground1,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'FormField',
      (_) => Fluent2FormField(
        label: 'Email',
        helper: 'The link goes here',
        required: true,
        child: Fluent2TextField(hint: 'name@example.com', onChanged: (_) {}),
      ),
    ),
    // Navigation
    DesignInventoryEntry.present(
      'AppBar',
      (_) => const Fluent2AppBar(title: 'Files'),
    ),
    DesignInventoryEntry.present(
      'NavigationBar',
      (_) => const Fluent2NavigationBar(
        items: [_home, _files, _people],
        selectedIndex: 0,
        onDestinationSelected: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationRail',
      (_) => const Fluent2NavigationRail(
        items: [_home, _files, _people],
        selectedIndex: 0,
        onDestinationSelected: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationDrawer',
      (_) => const Fluent2NavigationDrawer(
        items: [_home, _files, _people],
        selectedIndex: 0,
        onDestinationSelected: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'TabBar',
      (_) => const Fluent2TabList(
        tabs: ['Recent', 'Shared', 'Pinned'],
        selectedIndex: 0,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Breadcrumb',
      (_) => const Fluent2Breadcrumb(
        items: [
          Fluent2BreadcrumbItem('Files', onPressed: _none),
          Fluent2BreadcrumbItem('Reports', onPressed: _none),
          Fluent2BreadcrumbItem('Budget'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Pagination',
      (_) => const Fluent2Pagination(
        label: 'Results',
        page: 2,
        pages: 5,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'StepProgress',
      (_) =>
          const Fluent2StepProgress(count: 4, currentStep: 1, name: 'Review'),
    ),
    DesignInventoryEntry.present(
      'PageDots',
      (_) => const Fluent2PageDots(
        count: 4,
        selectedIndex: 1,
        label: 'Page 2 of 4',
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.absent(
      'MenuBar',
      "Fluent 2 has no menu bar: a window's commands are its Toolbar and "
          'its menu buttons (Fluent2Toolbar, Fluent2MenuButton)',
    ),
    DesignInventoryEntry.absent(
      'Command',
      'Fluent 2 has no command palette: a search is its SearchBox '
          '(Fluent2SearchBox)',
    ),
    DesignInventoryEntry.present(
      'Scaffold',
      (_) => const Fluent2Scaffold(
        scroll: false,
        topBar: Fluent2AppBar(title: 'Today'),
        body: Text('Two files changed'),
      ),
    ),
    // Containers
    DesignInventoryEntry.present(
      'Card',
      (_) => const Fluent2Card(
        children: [
          Fluent2CardHeader(header: 'Budget', description: 'Edited today'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'ListTile',
      (_) => const Fluent2ListItem(
        title: 'Budget',
        subtitle: 'Edited today',
        chevron: true,
        onTap: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'ListSection',
      (_) => const Fluent2ListSection(
        title: 'Recent',
        rows: [
          Fluent2ListItem(title: 'Budget', onTap: _none),
          Fluent2ListItem(title: 'Roadmap', onTap: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'SectionHeader',
      (_) => const Fluent2SectionHeader('Recent'),
    ),
    DesignInventoryEntry.present(
      'Disclosure',
      (_) => const Fluent2Accordion(
        items: [
          Fluent2AccordionItem(
            value: 'advanced',
            title: 'Advanced',
            child: Text('Retention and audit'),
          ),
        ],
        collapsible: true,
      ),
    ),
    DesignInventoryEntry.present(
      'Table',
      (_) => const Fluent2Table(
        label: 'Files',
        columns: [
          Fluent2TableColumn('Name'),
          Fluent2TableColumn('Pages', numeric: true),
        ],
        rows: [
          Fluent2TableRow(
            cells: [Fluent2TableCell('Budget'), Fluent2TableCell('12')],
          ),
          Fluent2TableRow(
            cells: [Fluent2TableCell('Roadmap'), Fluent2TableCell('8')],
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'DataTable',
      (_) => Fluent2DataGrid<_File>(
        label: 'Files',
        controller: _rows,
        cell: (row, column) => column.id == 'name' ? row.name : '${row.pages}',
      ),
    ),
    DesignInventoryEntry.present('Divider', (_) => const Fluent2Divider()),
    DesignInventoryEntry.present(
      'ScrollArea',
      (_) => Fluent2ScrollArea(
        controller: _scroll,
        semanticLabel: 'Files',
        child: ListView(
          controller: _scroll,
          children: [
            for (var i = 1; i <= 12; i++)
              Fluent2ListItem(title: 'File $i', onTap: _none),
          ],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Resizable',
      (_) => Fluent2Resizable(first: _say('Files'), second: _say('Details')),
    ),
    DesignInventoryEntry.present(
      'CarouselView',
      (_) => Fluent2CarouselView(
        label: 'Highlights',
        children: [_say('First'), _say('Second'), _say('Third')],
      ),
    ),
    DesignInventoryEntry.present(
      'ReorderableListView',
      (_) => Fluent2ReorderableListView<String>(
        shrinkWrap: true,
        items: const ['Budget', 'Roadmap', 'Handbook'],
        onReorder: (_, _) {},
        labelOf: (item) => item,
        itemBuilder: (_, item) => Text(item),
      ),
    ),
    DesignInventoryEntry.present(
      'SwipeActions',
      (_) => const Fluent2SwipeActions(
        trailing: [
          Fluent2SwipeAction(
            label: 'Share',
            icon: Fluent2Icons.share,
            onPressed: _none,
          ),
        ],
        child: Fluent2ListItem(title: 'Budget'),
      ),
    ),
    DesignInventoryEntry.present(
      'RefreshIndicator',
      (_) => Fluent2RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          children: const [
            Fluent2ListItem(title: 'Budget'),
            Fluent2ListItem(title: 'Roadmap'),
          ],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'TreeView',
      (_) => const Fluent2Tree<String>(
        label: 'Files',
        initiallyExpanded: {'reports'},
        items: [
          Fluent2TreeItem(
            'reports',
            'Reports',
            children: [
              Fluent2TreeItem('budget', 'Budget'),
              Fluent2TreeItem('roadmap', 'Roadmap'),
            ],
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Timeline',
      (_) => const Fluent2Timeline(
        entries: [
          Fluent2TimelineEntry(title: 'Created', time: 'Monday'),
          Fluent2TimelineEntry(title: 'Approved', time: '2:30 PM'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Avatar',
      (_) => const Fluent2Avatar(name: 'Sam Lee'),
    ),
    DesignInventoryEntry.present(
      'AvatarGroup',
      (_) => const Fluent2AvatarGroup(
        people: [
          Fluent2AvatarPerson('Sam Lee'),
          Fluent2AvatarPerson('Ana Ruiz'),
          Fluent2AvatarPerson('Kai Ito'),
        ],
      ),
    ),
    DesignInventoryEntry.present('Badge', (_) => const Fluent2Badge(3)),
    DesignInventoryEntry.present('Tag', (_) => const Fluent2Tag('Draft')),
    DesignInventoryEntry.present(
      'Media',
      (_) => const Fluent2Image(width: 120, height: 80, semanticLabel: 'Cover'),
    ),
    DesignInventoryEntry.present(
      'EmptyState',
      (_) => const Fluent2EmptyState(
        title: 'No files yet',
        body: 'Files you upload appear here.',
      ),
    ),
    DesignInventoryEntry.present(
      'DescriptionList',
      (_) => const Fluent2DescriptionList(
        properties: [
          Fluent2DescriptionItem('Owner', 'Sam Lee'),
          Fluent2DescriptionItem('Size', '2 MB'),
        ],
      ),
    ),
    // Overlays
    DesignInventoryEntry.present(
      'Dialog',
      (_) => const Fluent2Dialog(
        title: 'Discard the draft?',
        message: 'Your changes will be lost.',
      ),
    ),
    DesignInventoryEntry.present(
      'BottomSheet',
      (_) => const Fluent2BottomSheet(
        title: 'Share',
        child: Text('Anyone with the link'),
      ),
    ),
    DesignInventoryEntry.present(
      'Sheet',
      (_) => const Fluent2Sheet(title: 'Details', child: Text('Edited today')),
    ),
    DesignInventoryEntry.present(
      'ActionSheet',
      (_) => const Fluent2ActionSheet<String>(
        title: 'Budget',
        onSelected: _drop,
        onCancel: _none,
        actions: [
          Fluent2ActionSheetAction('share', 'Share'),
          Fluent2ActionSheetAction('delete', 'Delete', destructive: true),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Popover',
      (_) => Fluent2Popover(
        label: 'Filters',
        trigger: (_, toggle) => Fluent2Button('Filters', onPressed: toggle),
        content: const Text('Only shared files'),
      ),
    ),
    DesignInventoryEntry.absent(
      'HoverCard',
      'Fluent 2 has no hover card: more about a person is its Popover '
          '(Fluent2Popover)',
    ),
    DesignInventoryEntry.present(
      'Tooltip',
      (_) => const Fluent2Tooltip(
        message: 'Share this file',
        child: Fluent2Button('Share', onPressed: _none),
      ),
    ),
    DesignInventoryEntry.present(
      'Menu',
      (_) => const Fluent2Menu<String>(
        onSelected: _drop,
        items: [
          Fluent2MenuItem('rename', 'Rename'),
          Fluent2MenuItem('delete', 'Delete', danger: true),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'SnackBar',
      (_) => const Fluent2Toast('Saved to Files'),
    ),
    DesignInventoryEntry.present(
      'Banner',
      (_) => const Fluent2MessageBar(body: 'A new version is ready.'),
    ),
    // Feedback
    DesignInventoryEntry.present(
      'LinearProgressIndicator',
      (_) => const Fluent2ProgressBar(value: .6, semanticLabel: 'Uploading'),
    ),
    DesignInventoryEntry.present(
      'CircularProgressIndicator',
      (_) => const Fluent2Spinner(label: 'Loading files'),
    ),
    DesignInventoryEntry.present(
      'Skeleton',
      (_) => const Fluent2Skeleton(child: Fluent2SkeletonItem(width: 200)),
    ),
    DesignInventoryEntry.present(
      'StatusView',
      (_) => const Fluent2StatusView.success(
        title: 'Invitation sent',
        message: 'Sam will get an email.',
      ),
    ),
    DesignInventoryEntry.absent(
      'Meter',
      "Fluent has no determinate ring: progress toward a goal is its "
          'ProgressBar (Fluent2ProgressBar)',
    ),
    // Charts
    DesignInventoryEntry.present(
      'LineChart',
      (_) => const Fluent2LineChart(
        label: 'Files shared',
        labels: ['Mon', 'Tue', 'Wed', 'Thu'],
        series: [
          Fluent2ChartSeries('You', [3, 5, 4, 7]),
          Fluent2ChartSeries('Team', [2, 4, 6, 5]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'BarChart',
      (_) => const Fluent2BarChart(
        label: 'Files by day',
        bars: [
          Fluent2Bar('Mon', 3),
          Fluent2Bar('Tue', 5),
          Fluent2Bar('Wed', 4),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'AreaChart',
      (_) => const Fluent2AreaChart(
        label: 'Storage used',
        labels: ['Jan', 'Feb', 'Mar'],
        series: [
          Fluent2ChartSeries('Used', [12, 18, 21]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'PieChart',
      (_) => const Fluent2PieChart(
        label: 'Storage',
        slices: [
          Fluent2PieSlice('Documents', 40),
          Fluent2PieSlice('Photos', 25),
          Fluent2PieSlice('Video', 15),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Sparkline',
      (_) => const Fluent2Sparkline(
        label: 'Files this week',
        values: [3, 5, 4, 7, 6],
      ),
    ),
  ],
);

/// Fluent 2's inventory, listed: each group under its heading with how many of
/// its rows the look carries, then each row in a card, its class and what a
/// person calls it over its live specimen. It scrolls itself, so it fills a
/// screen that does not scroll.
///
/// ```dart
/// Fluent2Scaffold(scroll: false, topBar: const Fluent2AppBar(title: 'Components'), body: const Fluent2InventoryGallery())
/// ```
class Fluent2InventoryGallery extends StatelessWidget {
  /// The inventory, listed.
  const Fluent2InventoryGallery({
    super.key,
    this.controller,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 32),
  });

  /// The list's scroll controller.
  final ScrollController? controller;

  /// Space around the list.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return DesignInventoryGallery(
      inventory: fluent2Inventory,
      controller: controller,
      padding: padding,
      groupBuilder: (context, group, live, total) => Padding(
        padding: const EdgeInsets.only(
          top: Fluent2Spacing.xl,
          bottom: Fluent2Spacing.m,
        ),
        child: Fluent2SectionHeader(group, aside: '$live of $total'),
      ),
      rowBuilder: (context, row, entry, specimen) {
        final height = fluent2InventoryHeights[row.id];
        return KeyedSubtree(
          key: ValueKey<String>('inventory-${row.id}'),
          child: Padding(
            padding: const EdgeInsets.only(bottom: Fluent2Spacing.m),
            child: Fluent2Card(
              children: [
                Fluent2CardHeader(
                  header: 'Fluent2${row.id}',
                  description: row.name,
                ),
                if (specimen == null)
                  Text(
                    entry?.absentReason != null
                        ? DesignInventory.absentLabel(entry!.absentReason!)
                        : 'Missing: the inventory does not answer this row',
                    style: t.body1.c(t.textSecondary),
                  )
                else if (height != null)
                  SizedBox(height: height, child: specimen)
                else
                  specimen,
              ],
            ),
          ),
        );
      },
    );
  }
}
