// Comic's answer to the shared inventory: every row, a live specimen of the class an app reaches for. A row's class is
// `Comic<Stem>`, so an app written against another look moves here by its import and its prefix.
import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';

import '../../comic.dart';

void _tap() {}

void _take<T>(T _) {}

Future<void> _settle() async {}

const List<ComicNavItem> _places = [
  ComicNavItem(label: 'Home', short: 'Home', icon: ComicGlyphs.house),
  ComicNavItem(label: 'Search', short: 'Search', icon: ComicGlyphs.search),
];

const List<String> _week = ['Mon', 'Tue', 'Wed', 'Thu'];

const List<ComicChartSeries> _pages = [
  ComicChartSeries('Pages', [12, 18, 16, 22]),
];

Widget _table(BuildContext context) {
  final rows = DesignTableController<List<String>>(
    rows: const [
      ['Twelve', '24'],
      ['Thirteen', '32'],
    ],
    columns: [
      DesignTableColumn<List<String>>(
        id: 'issue',
        label: 'Issue',
        sortKey: (row) => row[0],
      ),
      DesignTableColumn<List<String>>(
        id: 'pages',
        label: 'Pages',
        sortKey: (row) => int.parse(row[1]),
        numeric: true,
      ),
    ],
  );
  return ComicDataTable<List<String>>(
    controller: rows,
    cellBuilder: (context, row, column) =>
        Text(row[column.id == 'issue' ? 0 : 1]),
  );
}

Widget _scrollArea(BuildContext context) {
  final scroll = ScrollController();
  return ComicScrollArea(
    controller: scroll,
    child: ListView(
      controller: scroll,
      children: const [Text('Page one'), Text('Page two')],
    ),
  );
}

/// Every row of the shared component inventory, each answered by a live Comic part.
final DesignInventory comicInventory = DesignInventory(
  look: 'Comic',
  entries: [
    // Actions
    DesignInventoryEntry.present(
      'Button',
      (context) => ComicButton('Save', onPressed: _tap),
    ),
    DesignInventoryEntry.present(
      'IconButton',
      (context) =>
          ComicIconButton(ComicGlyphs.share, label: 'Share', onPressed: _tap),
    ),
    DesignInventoryEntry.absent(
      'FloatingActionButton',
      'a circle floating over the page belongs to no layer of a comic page; its one filled action stands in its tier',
    ),
    DesignInventoryEntry.present(
      'ButtonGroup',
      (context) => ComicButtonGroup(
        label: 'Text',
        items: [
          ComicButtonGroupItem('Copy', onPressed: _tap),
          ComicButtonGroupItem('Paste', onPressed: _tap),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'ToggleGroup',
      (context) => ComicToggleGroup<String>(
        label: 'Style',
        values: const ['Bold', 'Italic'],
        selected: const {'Bold'},
        multiple: true,
        labelOf: (value) => value,
        onChanged: _take,
      ),
    ),
    DesignInventoryEntry.present(
      'SplitButton',
      (context) => ComicSplitButton(
        'Save',
        onPressed: _tap,
        actions: [ComicSplitAction('Save as copy', onPressed: _tap)],
      ),
    ),
    DesignInventoryEntry.present(
      'Link',
      (context) => ComicLink('Read more', onPressed: _tap),
    ),
    DesignInventoryEntry.present(
      'Kbd',
      (context) => const ComicKbd(['Ctrl', 'K']),
    ),
    // Inputs
    DesignInventoryEntry.present(
      'TextField',
      (context) => const ComicTextField(label: 'Name', hint: 'Your name'),
    ),
    DesignInventoryEntry.present(
      'TextArea',
      (context) => const ComicTextArea(label: 'Notes'),
    ),
    DesignInventoryEntry.present(
      'SearchField',
      (context) => const ComicSearchField(hint: 'Search issues'),
    ),
    DesignInventoryEntry.present(
      'PasswordField',
      (context) => const ComicPasswordField(label: 'Password'),
    ),
    DesignInventoryEntry.present(
      'InputGroup',
      (context) => const ComicInputGroup(
        label: 'Price',
        hint: '0.00',
        leading: [Text('USD')],
      ),
    ),
    DesignInventoryEntry.present(
      'InputOtp',
      (context) => const ComicInputOtp(label: 'Code'),
    ),
    DesignInventoryEntry.present(
      'NumberField',
      (context) =>
          ComicNumberField(value: 6, unit: 'copies', onChanged: (_) => _tap()),
    ),
    DesignInventoryEntry.present(
      'Select',
      (context) => ComicSelect<String>(
        label: 'Format',
        options: const [
          ComicSelectOption('print', 'Print'),
          ComicSelectOption('digital', 'Digital'),
        ],
        value: 'print',
        onChanged: _take,
      ),
    ),
    DesignInventoryEntry.present(
      'Combobox',
      (context) => const ComicCombobox<String>(
        label: 'City',
        options: ['Lisbon', 'London', 'Lyon'],
      ),
    ),
    DesignInventoryEntry.present(
      'MultiSelect',
      (context) => ComicMultiSelect<String>(
        label: 'Genres',
        values: const ['Noir'],
        options: const ['Noir', 'Western', 'Horror'],
        onChanged: _take,
      ),
    ),
    DesignInventoryEntry.present(
      'Checkbox',
      (context) =>
          ComicCheckbox(value: true, label: 'Unread only', onChanged: _take),
    ),
    DesignInventoryEntry.present(
      'RadioGroup',
      (context) => ComicRadioGroup<String>(
        label: 'Format',
        options: const [
          ComicRadio('print', 'Print'),
          ComicRadio('digital', 'Digital'),
        ],
        value: 'print',
        onChanged: _take,
      ),
    ),
    DesignInventoryEntry.present(
      'Switch',
      (context) => ComicSwitch(value: true, label: 'Alerts', onChanged: _take),
    ),
    DesignInventoryEntry.present(
      'Slider',
      (context) => ComicSlider(label: 'Volume', value: .5, onChanged: _take),
    ),
    DesignInventoryEntry.present(
      'RangeSlider',
      (context) => ComicRangeSlider(
        label: 'Price',
        values: const DesignRangeValues(.2, .8),
        onChanged: _take,
      ),
    ),
    DesignInventoryEntry.present(
      'SegmentedButton',
      (context) => ComicSegmentedButton<String>(
        label: 'View',
        segments: const [
          ComicButtonSegment('all', 'All'),
          ComicButtonSegment('saved', 'Saved'),
        ],
        value: 'all',
        onChanged: _take,
      ),
    ),
    DesignInventoryEntry.present(
      'Chip',
      (context) => ComicChip('Noir', onPressed: _tap),
    ),
    DesignInventoryEntry.present(
      'Rating',
      (context) => ComicRating(label: 'Rating', value: 3, onChanged: _take),
    ),
    DesignInventoryEntry.present(
      'FileUpload',
      (context) => ComicFileUpload(label: 'Cover art', onChoose: _tap),
    ),
    DesignInventoryEntry.present(
      'DatePicker',
      (context) => ComicDatePicker(
        value: DateTime(2026, 11, 10),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        onChanged: _take,
      ),
    ),
    DesignInventoryEntry.present(
      'DateRangePicker',
      (context) => ComicDateRangePicker(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        onChanged: _take,
      ),
    ),
    DesignInventoryEntry.present(
      'TimePicker',
      (context) => ComicTimePicker(onChanged: _take),
    ),
    DesignInventoryEntry.present(
      'Calendar',
      (context) => ComicCalendar(
        controller: DesignCalendarController(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
        ),
        onChanged: (_) {},
      ),
    ),
    DesignInventoryEntry.present(
      'WheelPicker',
      (context) => ComicWheelPicker<int>(
        label: 'Copies',
        values: const [1, 2, 3, 4, 5],
        value: 2,
        labelOf: (copies) => '$copies',
        onChanged: _take,
      ),
    ),
    DesignInventoryEntry.absent(
      'ColorPicker',
      'a continuous field of colour can\'t be printed in process inks; a swatch picker in the inks can come later',
    ),
    DesignInventoryEntry.present(
      'FormField',
      (context) => const ComicFormField(
        'Your name',
        child: ComicTextField(hint: 'Name'),
      ),
    ),
    // Navigation
    DesignInventoryEntry.present(
      'AppBar',
      (context) => const ComicAppBar(title: 'The plan'),
    ),
    DesignInventoryEntry.present(
      'NavigationBar',
      (context) => ComicNavigationBar(
        destinations: _places,
        onDestinationSelected: _take,
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationRail',
      (context) => ComicNavigationRail(
        destinations: _places,
        onDestinationSelected: _take,
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationDrawer',
      (context) => ComicNavigationDrawer(
        destinations: _places,
        onDestinationSelected: _take,
      ),
    ),
    DesignInventoryEntry.present(
      'TabBar',
      (context) => ComicTabBar(tabs: const ['All', 'Saved'], onChanged: _take),
    ),
    DesignInventoryEntry.present(
      'Breadcrumb',
      (context) => ComicBreadcrumb([
        ComicCrumb('Shop', onPressed: _tap),
        const ComicCrumb('Issue 12'),
      ]),
    ),
    DesignInventoryEntry.present(
      'Pagination',
      (context) => ComicPagination(count: 5, page: 0, onChanged: _take),
    ),
    DesignInventoryEntry.present(
      'StepProgress',
      (context) =>
          const ComicStepProgress(count: 3, currentStep: 1, name: 'Your order'),
    ),
    DesignInventoryEntry.present(
      'PageDots',
      (context) =>
          const ComicPageDots(count: 3, selectedIndex: 0, label: 'Pages'),
    ),
    DesignInventoryEntry.present(
      'MenuBar',
      (context) => ComicMenuBar(
        menus: [
          DesignMenuEntry(
            label: 'File',
            children: [
              DesignMenuEntry(
                label: 'New',
                shortcut: 'Ctrl+N',
                onPressed: _tap,
              ),
            ],
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Command',
      (context) => ComicCommand(
        commands: [DesignCommand(label: 'New issue', onPressed: _tap)],
      ),
    ),
    DesignInventoryEntry.present(
      'Scaffold',
      (context) => const ComicScaffold(body: Text('Issue 12')),
    ),
    // Containers
    DesignInventoryEntry.present(
      'Card',
      (context) => const ComicCard(
        title: 'This issue',
        children: [Text('Twelve pages')],
      ),
    ),
    DesignInventoryEntry.present(
      'ListTile',
      (context) => const ComicListTile(title: 'First'),
    ),
    DesignInventoryEntry.present(
      'ListSection',
      (context) => const ComicListSection(
        children: [
          ComicListTile(title: 'First'),
          ComicListTile(title: 'Second'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'SectionHeader',
      (context) => const ComicSectionHeader('New this week'),
    ),
    DesignInventoryEntry.present(
      'Disclosure',
      (context) => const ComicDisclosure(
        title: 'More about this issue',
        child: Text('The full story'),
      ),
    ),
    DesignInventoryEntry.present(
      'Table',
      (context) => const ComicTable(
        columns: ['Issue', 'Pages'],
        rows: [
          ['Twelve', '24'],
          ['Thirteen', '32'],
        ],
      ),
    ),
    DesignInventoryEntry.present('DataTable', _table),
    DesignInventoryEntry.present('Divider', (context) => const ComicDivider()),
    DesignInventoryEntry.present('ScrollArea', _scrollArea),
    DesignInventoryEntry.present(
      'Resizable',
      (context) =>
          const ComicResizable(first: Text('List'), second: Text('Detail')),
    ),
    DesignInventoryEntry.present(
      'CarouselView',
      (context) => const ComicCarouselView(
        label: 'This week',
        children: [
          ComicMedia(slotId: 'pick-1', label: 'First pick'),
          ComicMedia(slotId: 'pick-2', label: 'Second pick'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'ReorderableListView',
      (context) => ComicReorderableListView<String>(
        items: const ['Pencils', 'Inks'],
        labelOf: (item) => item,
        shrinkWrap: true,
        onReorder: (from, to) {},
        itemBuilder: (context, item) => Text(item),
      ),
    ),
    DesignInventoryEntry.present(
      'SwipeActions',
      (context) => ComicSwipeActions(
        endActions: [
          DesignSwipeAction(
            label: 'Delete',
            onPressed: _tap,
            destructive: true,
          ),
        ],
        child: const ComicListTile(title: 'Issue 12'),
      ),
    ),
    DesignInventoryEntry.present(
      'RefreshIndicator',
      (context) => ComicRefreshIndicator(
        onRefresh: _settle,
        child: ListView(children: const [Text('Issue 12')]),
      ),
    ),
    DesignInventoryEntry.present(
      'TreeView',
      (context) => ComicTreeView<String>(
        controller: DesignTreeController<String>(
          roots: const ['Issues'],
          childrenOf: (node) => node == 'Issues' ? const ['Twelve'] : const [],
          expanded: const ['Issues'],
        ),
        labelOf: (node) => node,
      ),
    ),
    DesignInventoryEntry.present(
      'Timeline',
      (context) => const ComicTimeline(
        entries: [
          ComicTimelineEntry('Pencilled', time: 'Mon'),
          ComicTimelineEntry(
            'Inked',
            time: 'Today',
            step: ComicTimelineStatus.current,
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Avatar',
      (context) => const ComicAvatar('NW', name: 'Nia Walker'),
    ),
    DesignInventoryEntry.present(
      'AvatarGroup',
      (context) => const ComicAvatarGroup([
        ComicFace('NW'),
        ComicFace('AK'),
      ], label: 'Contributors'),
    ),
    DesignInventoryEntry.present('Badge', (context) => const ComicBadge(3)),
    DesignInventoryEntry.present('Tag', (context) => const ComicTag('New')),
    DesignInventoryEntry.present(
      'Media',
      (context) => const ComicMedia(slotId: 'cover', label: 'Cover'),
    ),
    DesignInventoryEntry.present(
      'EmptyState',
      (context) => const ComicEmptyState(
        title: 'All caught up',
        body: 'No new messages.',
      ),
    ),
    DesignInventoryEntry.present(
      'DescriptionList',
      (context) => const ComicDescriptionList(
        entries: [
          ComicDescriptionItem('Writer', 'Ana Ruiz'),
          ComicDescriptionItem('Pages', '24'),
        ],
      ),
    ),
    // Overlays
    DesignInventoryEntry.present(
      'Dialog',
      (context) => const ComicDialog(
        title: 'Remove issue?',
        message: 'This cannot be undone.',
      ),
    ),
    DesignInventoryEntry.present(
      'BottomSheet',
      (context) =>
          const ComicBottomSheet(title: 'Details', child: Text('Issue 12')),
    ),
    DesignInventoryEntry.present(
      'Sheet',
      (context) =>
          const ComicSheet(title: 'Filters', child: Text('Only unread')),
    ),
    DesignInventoryEntry.present(
      'ActionSheet',
      (context) => ComicActionSheet<String>(
        title: 'Issue 12',
        actions: const [ComicSheetAction('Share', value: 'share')],
        onSelected: _take,
      ),
    ),
    DesignInventoryEntry.present(
      'Popover',
      (context) => ComicPopover(
        anchorBuilder: (context, anchor) =>
            ComicButton('Filter', onPressed: anchor.toggle),
        builder: (context, close) => const Text('Only unread'),
      ),
    ),
    DesignInventoryEntry.present(
      'HoverCard',
      (context) => const ComicHoverCard(
        card: Text('Inker, issue 12 on'),
        child: Text('Ada'),
      ),
    ),
    DesignInventoryEntry.present(
      'Tooltip',
      (context) => const ComicTooltip(message: 'Share', child: Text('Share')),
    ),
    DesignInventoryEntry.present(
      'Menu',
      (context) => ComicMenu<String>(
        items: const [ComicMenuItem('save', 'Save')],
        onSelected: _take,
      ),
    ),
    DesignInventoryEntry.present(
      'SnackBar',
      (context) => const ComicSnackBar('Saved to your collection'),
    ),
    DesignInventoryEntry.present(
      'Banner',
      (context) => const ComicBanner('Your issue ships Friday'),
    ),
    // Feedback
    DesignInventoryEntry.present(
      'LinearProgressIndicator',
      (context) =>
          const ComicLinearProgressIndicator(value: .4, label: 'Saving'),
    ),
    DesignInventoryEntry.present(
      'CircularProgressIndicator',
      (context) =>
          const ComicCircularProgressIndicator(value: .4, label: 'Saving'),
    ),
    DesignInventoryEntry.present(
      'Skeleton',
      (context) => const ComicSkeleton(width: 120),
    ),
    DesignInventoryEntry.present(
      'StatusView',
      (context) => const ComicStatusView.empty(title: 'Nothing here yet'),
    ),
    DesignInventoryEntry.present(
      'Meter',
      (context) => const ComicMeter(label: 'Pages read', value: .6),
    ),
    // Charts
    DesignInventoryEntry.present(
      'LineChart',
      (context) => const ComicLineChart(
        label: 'Pages read',
        labels: _week,
        series: _pages,
      ),
    ),
    DesignInventoryEntry.present(
      'BarChart',
      (context) => const ComicBarChart(
        label: 'Pages read',
        labels: _week,
        series: _pages,
      ),
    ),
    DesignInventoryEntry.present(
      'AreaChart',
      (context) => const ComicAreaChart(
        label: 'Pages read',
        labels: _week,
        series: _pages,
      ),
    ),
    DesignInventoryEntry.present(
      'PieChart',
      (context) => const ComicPieChart(
        centre: '417',
        unit: 'kcal',
        slices: [
          ComicSlice('Carbs', 200, figure: '200', share: '48%'),
          ComicSlice('Fat', 99, figure: '99', share: '24%'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Sparkline',
      (context) =>
          const ComicSparkline(label: 'Pages', values: [12, 18, 16, 22]),
    ),
  ],
);
