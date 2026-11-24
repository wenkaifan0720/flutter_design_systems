// Fluent 2's answer to the shared component inventory (ui_core's RawInventoryRow.all, 89 rows): for each row the part
// that answers it, `Fluent2<Stem>`, as a small live specimen. The live gallery lists it, and a test verifies it (every
// row answered once, every specimen the row's own class).
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';

import '../fluent2_design.dart';

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

/// A specimen that owns a controller while it stands, as an app's page
/// would: [make] makes it the first time the specimen builds, and it is
/// disposed with the specimen.
class _Owning<T extends ChangeNotifier> extends StatefulWidget {
  const _Owning(this.make, this.builder);

  final T Function(BuildContext context) make;
  final Widget Function(BuildContext context, T controller) builder;

  @override
  State<_Owning<T>> createState() => _OwningState<T>();
}

class _OwningState<T extends ChangeNotifier> extends State<_Owning<T>> {
  T? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _controller ??= widget.make(context));
}

Widget _choice<T>(T initial, Widget Function(T, ValueChanged<T>) build) =>
    _Owning<ValueNotifier<T>>(
      (_) => ValueNotifier(initial),
      (_, choice) => ValueListenableBuilder<T>(
        valueListenable: choice,
        builder: (_, value, child) =>
            build(value, (next) => choice.value = next),
      ),
    );

class _File {
  const _File(this.name, this.pages);
  final String name;
  final int pages;
}

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

/// Component names, availability, and live examples for the Fluent 2 gallery.
final RawInventory fluent2Inventory = RawInventory(
  look: 'Fluent 2',
  entries: [
    // Actions
    RawInventoryEntry.present(
      'Button',
      (_) => const Fluent2Button('Share', onPressed: _none),
    ),
    RawInventoryEntry.present(
      'IconButton',
      (_) => const Fluent2IconButton(
        Fluent2Icons.share,
        label: 'Share',
        onPressed: _none,
      ),
    ),
    RawInventoryEntry.present(
      'FloatingActionButton',
      (_) => const Fluent2FloatingActionButton(
        icon: Fluent2Icons.add,
        label: 'New',
        onPressed: _none,
      ),
    ),
    RawInventoryEntry.present(
      'ButtonGroup',
      (_) => const Fluent2ToolbarGroup(
        label: 'Share',
        items: [
          Fluent2ToolbarItem.button(
            icon: Fluent2Icons.link,
            label: 'Copy link',
            onPressed: _none,
          ),
          Fluent2ToolbarItem.button(
            icon: Fluent2Icons.mail,
            label: 'Email',
            onPressed: _none,
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'ToggleGroup',
      (_) => _choice<Set<String>>(
        const {'list'},
        (selected, select) => Fluent2ToolbarToggleGroup<String>(
          label: 'Layout',
          toggles: const [
            Fluent2ToolbarToggle(
              'list',
              icon: Fluent2Icons.list,
              label: 'List',
            ),
            Fluent2ToolbarToggle(
              'grid',
              icon: Fluent2Icons.grid,
              label: 'Tiles',
            ),
          ],
          selected: selected,
          onSelectionChanged: select,
        ),
      ),
    ),
    RawInventoryEntry.present(
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
    RawInventoryEntry.present(
      'Link',
      (_) => const Fluent2Link('Read the guide', onPressed: _none),
    ),
    RawInventoryEntry.present('Kbd', (_) => const Fluent2Kbd(['Ctrl', 'K'])),
    // Inputs
    RawInventoryEntry.present(
      'TextField',
      (_) =>
          Fluent2TextField(label: 'Name', value: 'Sam Lee', onChanged: (_) {}),
    ),
    RawInventoryEntry.present(
      'TextArea',
      (_) => Fluent2TextArea(label: 'Note', onChanged: (_) {}),
    ),
    RawInventoryEntry.present(
      'SearchField',
      (_) => Fluent2SearchBox(hintText: 'Find a file', onChanged: (_) {}),
    ),
    RawInventoryEntry.present(
      'PasswordField',
      (_) => Fluent2PasswordField(label: 'Password', onChanged: (_) {}),
    ),
    RawInventoryEntry.present(
      'InputGroup',
      (_) => const Fluent2InputGroup(
        label: 'Website',
        prefix: 'https://',
        suffix: '.com',
      ),
    ),
    const RawInventoryEntry.absent(
      'InputOtp',
      'No Fluent 2 platform has code boxes: Microsoft\'s sign-in asks for '
          'a code in one Input (Fluent2TextField with the number keyboard)',
    ),
    RawInventoryEntry.present(
      'NumberField',
      (_) =>
          const Fluent2SpinButton(label: 'Copies', value: 2, onChanged: _drop),
    ),
    RawInventoryEntry.present(
      'Select',
      (_) => const Fluent2Select<String>(
        label: 'Size',
        value: 'medium',
        options: _sizes,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Combobox',
      (_) => const Fluent2Combobox<String>(
        label: 'Size',
        value: 'medium',
        options: _sizes,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'MultiSelect',
      (_) => const Fluent2MultiSelect<String>(
        label: 'Sizes',
        selected: ['small'],
        options: _sizes,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Checkbox',
      (_) => const Fluent2Checkbox(
        label: 'Include archived files',
        value: true,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'RadioGroup',
      (_) => _choice<String>(
        'medium',
        (selected, select) => Fluent2RadioGroup<String>(
          label: 'Size',
          value: selected,
          options: const [
            Fluent2Radio('small', 'Small'),
            Fluent2Radio('medium', 'Medium'),
            Fluent2Radio('large', 'Large'),
          ],
          onChanged: select,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Switch',
      (_) => const Fluent2Switch(label: 'Sync', value: true, onChanged: _drop),
    ),
    RawInventoryEntry.present(
      'Slider',
      (_) => const Fluent2Slider(label: 'Volume', value: 40, onChanged: _drop),
    ),
    RawInventoryEntry.present(
      'RangeSlider',
      (_) => const Fluent2RangeSlider(
        label: 'Pages',
        values: RawRangeValues(20, 60),
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
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
    RawInventoryEntry.present(
      'Chip',
      (_) => const Fluent2InteractionTag(
        'Shared',
        selected: true,
        onPressed: _none,
      ),
    ),
    RawInventoryEntry.present(
      'Rating',
      (_) => const Fluent2Rating(label: 'Rating', value: 4, onChanged: _drop),
    ),
    RawInventoryEntry.present(
      'FileUpload',
      (_) => Fluent2FileUpload(label: 'Attachments', onPressed: () {}),
    ),
    RawInventoryEntry.present(
      'DatePicker',
      (_) => Fluent2DatePicker(
        label: 'Due',
        value: DateTime(2026, 6, 14),
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'DateRangePicker',
      (_) => _Owning(
        (_) => RawCalendarController(
          firstDate: DateTime(2026, 6),
          lastDate: DateTime(2026, 9, 30),
          mode: RawCalendarMode.range,
          selectedRange: RawDateRange(
            DateTime(2026, 6, 14),
            DateTime(2026, 6, 18),
          ),
          currentDate: DateTime(2026, 6, 10),
        ),
        (_, stay) => Fluent2DateRangePicker(controller: stay),
      ),
    ),
    RawInventoryEntry.present(
      'TimePicker',
      (_) => const Fluent2TimePicker(
        label: 'Start',
        value: Fluent2Time(9, 30),
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Calendar',
      (_) => Fluent2Calendar(
        value: DateTime(2026, 6, 14),
        today: DateTime(2026, 6, 10),
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'WheelPicker',
      (_) => const Fluent2WheelPicker<String>(
        label: 'Size',
        items: ['Small', 'Medium', 'Large'],
        value: 'Medium',
        rows: 3,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'ColorPicker',
      // It starts on the theme's brand.
      (_) => _Owning(
        (context) => RawColorController(
          context.fluent2Theme.colors.compoundBrandForeground1,
        ),
        (_, colour) => Fluent2ColorPicker(controller: colour),
      ),
    ),
    RawInventoryEntry.present(
      'FormField',
      (_) => Fluent2FormField(
        labelText: 'Email',
        helperText: 'The link goes here',
        required: true,
        child: Fluent2TextField(
          hintText: 'name@example.com',
          onChanged: (_) {},
        ),
      ),
    ),
    // Navigation
    RawInventoryEntry.present(
      'AppBar',
      (_) => const Fluent2AppBar(title: 'Files'),
    ),
    RawInventoryEntry.present(
      'NavigationBar',
      (_) => const Fluent2NavigationBar(
        items: [_home, _files, _people],
        selectedIndex: 0,
        onDestinationSelected: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'NavigationRail',
      (_) => const Fluent2NavigationRail(
        items: [_home, _files, _people],
        selectedIndex: 0,
        onDestinationSelected: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'NavigationDrawer',
      (_) => const Fluent2NavigationDrawer(
        items: [_home, _files, _people],
        selectedIndex: 0,
        onDestinationSelected: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'TabBar',
      (_) => const Fluent2TabList(
        tabs: ['Recent', 'Shared', 'Pinned'],
        selectedIndex: 0,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Breadcrumb',
      (_) => const Fluent2Breadcrumb(
        items: [
          Fluent2BreadcrumbItem('Files', onPressed: _none),
          Fluent2BreadcrumbItem('Reports', onPressed: _none),
          Fluent2BreadcrumbItem('Budget'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Pagination',
      (_) => const Fluent2Pagination(
        label: 'Results',
        page: 2,
        pages: 5,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'StepProgress',
      (_) =>
          const Fluent2StepProgress(count: 4, currentStep: 1, name: 'Review'),
    ),
    RawInventoryEntry.present(
      'PageDots',
      (_) => const Fluent2PageDots(
        count: 4,
        selectedIndex: 1,
        label: 'Page 2 of 4',
        onChanged: _drop,
      ),
    ),
    const RawInventoryEntry.absent(
      'MenuBar',
      "Fluent 2's web, iOS and Android kits have no menu bar; its Windows "
          "kit has one (WinUI's MenuBar), planned here. Until then a window's "
          'commands are its Toolbar and menu buttons (Fluent2Toolbar, '
          'Fluent2MenuButton)',
    ),
    const RawInventoryEntry.absent(
      'Command',
      'No Fluent 2 platform has a command palette (WinUI\'s CommandBar is '
          'a toolbar: Fluent2Toolbar); a search is its SearchBox '
          '(Fluent2SearchBox)',
    ),
    RawInventoryEntry.present(
      'Scaffold',
      (_) => const Fluent2Scaffold(
        scroll: false,
        topBar: Fluent2AppBar(title: 'Today'),
        body: Text('Two files changed'),
      ),
    ),
    // Containers
    RawInventoryEntry.present(
      'Card',
      (_) => const Fluent2Card(
        children: [
          Fluent2CardHeader(header: 'Budget', description: 'Edited today'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'ListTile',
      (_) => const Fluent2ListItem(
        title: 'Budget',
        subtitle: 'Edited today',
        chevron: true,
        onTap: _none,
      ),
    ),
    RawInventoryEntry.present(
      'ListSection',
      (_) => const Fluent2ListSection(
        title: 'Recent',
        rows: [
          Fluent2ListItem(title: 'Budget', onTap: _none),
          Fluent2ListItem(title: 'Roadmap', onTap: _none),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'SectionHeader',
      (_) => const Fluent2SectionHeader('Recent'),
    ),
    RawInventoryEntry.present(
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
    RawInventoryEntry.present(
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
    RawInventoryEntry.present(
      'DataTable',
      (_) => _Owning(
        (_) => RawDataTableController<_File>(
          rows: const [
            _File('Budget', 12),
            _File('Roadmap', 8),
            _File('Handbook', 40),
          ],
          columns: [
            RawDataColumn<_File>(
              id: 'name',
              label: 'Name',
              sortKey: (f) => f.name,
            ),
            RawDataColumn<_File>(
              id: 'pages',
              label: 'Pages',
              numeric: true,
              sortKey: (f) => f.pages,
            ),
          ],
        ),
        (_, rows) => Fluent2DataGrid<_File>(
          label: 'Files',
          controller: rows,
          cell: (row, column) =>
              column.id == 'name' ? row.name : '${row.pages}',
        ),
      ),
    ),
    RawInventoryEntry.present('Divider', (_) => const Fluent2Divider()),
    RawInventoryEntry.present(
      'ScrollArea',
      (_) => _Owning(
        (_) => ScrollController(),
        (_, scroll) => Fluent2ScrollArea(
          controller: scroll,
          semanticLabel: 'Files',
          child: ListView(
            controller: scroll,
            children: [
              for (var i = 1; i <= 12; i++)
                Fluent2ListItem(title: 'File $i', onTap: _none),
            ],
          ),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Resizable',
      (_) => Fluent2Resizable(first: _say('Files'), second: _say('Details')),
    ),
    RawInventoryEntry.present(
      'CarouselView',
      (_) => Fluent2CarouselView(
        label: 'Highlights',
        children: [_say('First'), _say('Second'), _say('Third')],
      ),
    ),
    RawInventoryEntry.present(
      'ReorderableListView',
      (_) => Fluent2ReorderableListView<String>(
        shrinkWrap: true,
        items: const ['Budget', 'Roadmap', 'Handbook'],
        onReorder: (_, _) {},
        labelOf: (item) => item,
        itemBuilder: (_, item) => Text(item),
      ),
    ),
    RawInventoryEntry.present(
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
    RawInventoryEntry.present(
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
    RawInventoryEntry.present(
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
    RawInventoryEntry.present(
      'Timeline',
      (_) => const Fluent2Timeline(
        entries: [
          Fluent2TimelineEntry(title: 'Created', time: 'Monday'),
          Fluent2TimelineEntry(title: 'Approved', time: '2:30 PM'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Avatar',
      (_) => const Fluent2Avatar(name: 'Sam Lee'),
    ),
    RawInventoryEntry.present(
      'AvatarGroup',
      (_) => const Fluent2AvatarGroup(
        people: [
          Fluent2AvatarPerson('Sam Lee'),
          Fluent2AvatarPerson('Ana Ruiz'),
          Fluent2AvatarPerson('Kai Ito'),
        ],
      ),
    ),
    RawInventoryEntry.present('Badge', (_) => const Fluent2Badge(3)),
    RawInventoryEntry.present('Tag', (_) => const Fluent2Tag('Draft')),
    RawInventoryEntry.present(
      'Media',
      (_) => const Fluent2Image(width: 120, height: 80, semanticLabel: 'Cover'),
    ),
    RawInventoryEntry.present(
      'EmptyState',
      (_) => const Fluent2EmptyState(
        title: 'No files yet',
        body: 'Files you upload appear here.',
      ),
    ),
    RawInventoryEntry.present(
      'DescriptionList',
      (_) => const Fluent2DescriptionList(
        properties: [
          Fluent2DescriptionItem('Owner', 'Sam Lee'),
          Fluent2DescriptionItem('Size', '2 MB'),
        ],
      ),
    ),
    // Overlays
    RawInventoryEntry.present(
      'Dialog',
      (_) => const Fluent2Dialog(
        title: 'Discard the draft?',
        message: 'Your changes will be lost.',
      ),
    ),
    RawInventoryEntry.present(
      'BottomSheet',
      (_) => const Fluent2BottomSheet(
        title: 'Share',
        child: Text('Anyone with the link'),
      ),
    ),
    RawInventoryEntry.present(
      'Sheet',
      (_) => const Fluent2Sheet(title: 'Details', child: Text('Edited today')),
    ),
    RawInventoryEntry.present(
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
    RawInventoryEntry.present(
      'Popover',
      (_) => Fluent2Popover(
        label: 'Filters',
        trigger: (_, toggle) => Fluent2Button('Filters', onPressed: toggle),
        content: const Text('Only shared files'),
      ),
    ),
    RawInventoryEntry.present(
      'HoverCard',
      (_) => Fluent2Popover(
        label: 'Mara Okafor',
        openOnHover: true,
        trigger: (_, toggle) => Fluent2Link('Mara Okafor', onPressed: toggle),
        content: const Text('Design lead · Seattle'),
      ),
    ),
    RawInventoryEntry.present(
      'Tooltip',
      (_) => const Fluent2Tooltip(
        message: 'Share this file',
        child: Fluent2Button('Share', onPressed: _none),
      ),
    ),
    RawInventoryEntry.present(
      'Menu',
      (_) => const Fluent2Menu<String>(
        onSelected: _drop,
        items: [
          Fluent2MenuItem('rename', 'Rename'),
          Fluent2MenuItem('delete', 'Delete', danger: true),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'SnackBar',
      (_) => const Fluent2Toast('Saved to Files'),
    ),
    RawInventoryEntry.present(
      'Banner',
      (_) => const Fluent2MessageBar(body: 'A new version is ready.'),
    ),
    // Feedback
    RawInventoryEntry.present(
      'LinearProgressIndicator',
      (_) => const Fluent2ProgressBar(value: .6, semanticLabel: 'Uploading'),
    ),
    RawInventoryEntry.present(
      'CircularProgressIndicator',
      (_) => const Fluent2Spinner(label: 'Loading files'),
    ),
    RawInventoryEntry.present(
      'Skeleton',
      (_) => const Fluent2Skeleton(child: Fluent2SkeletonItem(width: 200)),
    ),
    RawInventoryEntry.present(
      'StatusView',
      (_) => const Fluent2StatusView.success(
        title: 'Invitation sent',
        message: 'Sam will get an email.',
      ),
    ),
    RawInventoryEntry.present(
      'Meter',
      (_) =>
          const Fluent2Spinner(label: 'Storage used', value: .62, below: false),
    ),
    // Charts
    RawInventoryEntry.present(
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
    RawInventoryEntry.present(
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
    RawInventoryEntry.present(
      'AreaChart',
      (_) => const Fluent2AreaChart(
        label: 'Storage used',
        labels: ['Jan', 'Feb', 'Mar'],
        series: [
          Fluent2ChartSeries('Used', [12, 18, 21]),
        ],
      ),
    ),
    RawInventoryEntry.present(
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
    RawInventoryEntry.present(
      'Sparkline',
      (_) => const Fluent2Sparkline(
        label: 'Files this week',
        values: [3, 5, 4, 7, 6],
      ),
    ),
  ],
);

/// A scrollable gallery of Fluent 2 components grouped by purpose.
/// Each entry shows the widget name and a live example.
///
/// ```dart
/// Fluent2Scaffold(scroll: false, topBar: const Fluent2AppBar(title: 'Components'), body: const Fluent2InventoryGallery())
/// ```
class Fluent2InventoryGallery extends StatelessWidget {
  /// Creates a scrollable component gallery.
  const Fluent2InventoryGallery({
    super.key,
    this.controller,
    this.padding = const EdgeInsets.only(
      top: Fluent2Spacing.s,
      bottom: Fluent2Spacing.xxxl,
    ),
  });

  /// The list's scroll controller.
  final ScrollController? controller;

  /// Space above and below the list. It has none at its sides: the screen
  /// round it (a Fluent2Scaffold) stands it on the page's margin.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return RawInventoryGallery(
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
                        ? RawInventory.absentLabel(entry!.absentReason!)
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ScrollController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: const EdgeInsets.only(
            top: Fluent2Spacing.s,
            bottom: Fluent2Spacing.xxxl,
          ),
        ),
      );
  }
}
