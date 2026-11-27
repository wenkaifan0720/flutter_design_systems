// Comic's answer to the shared inventory: every row, a live specimen of the class an app reaches for. A row's class is
// `Comic<Stem>`, so an app written against another look moves here by its import and its prefix.
import 'package:flutter/services.dart';
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

/// A specimen that owns the controller it shows: made once, disposed with the specimen.
class _Owned<T extends ChangeNotifier> extends StatefulWidget {
  const _Owned(this.make, this.show);
  final T Function() make;
  final Widget Function(T controller) show;
  @override
  State<_Owned<T>> createState() => _OwnedState<T>();
}

class _OwnedState<T extends ChangeNotifier> extends State<_Owned<T>> {
  late final T _controller = widget.make();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.show(_controller);
}

Widget _table(BuildContext context) => _Owned(
  () => RawDataTableController<List<String>>(
    rows: const [
      ['Twelve', '24'],
      ['Thirteen', '32'],
    ],
    columns: [
      RawDataColumn<List<String>>(
        id: 'issue',
        label: 'Issue',
        sortKey: (row) => row[0],
      ),
      RawDataColumn<List<String>>(
        id: 'pages',
        label: 'Pages',
        sortKey: (row) => int.parse(row[1]),
        numeric: true,
      ),
    ],
  ),
  (rows) => ComicDataTable<List<String>>(
    controller: rows,
    cellBuilder: (context, row, column) =>
        Text(row[column.id == 'issue' ? 0 : 1]),
  ),
);

Widget _scrollArea(BuildContext context) => _Owned(
  ScrollController.new,
  (scroll) => ComicScrollArea(
    controller: scroll,
    child: ListView(
      controller: scroll,
      children: const [Text('Page one'), Text('Page two')],
    ),
  ),
);

/// Every row of the shared component inventory, each answered by a live Comic part.
final RawInventory comicInventory = RawInventory(
  look: 'Comic',
  entries: [
    // Actions
    RawInventoryEntry.present(
      'Button',
      (context) => const ComicButton('Save', onPressed: _tap),
    ),
    RawInventoryEntry.present(
      'IconButton',
      (context) => const ComicIconButton(
        ComicGlyphs.share,
        semanticLabel: 'Share',
        onPressed: _tap,
      ),
    ),
    const RawInventoryEntry.absent(
      'FloatingActionButton',
      'a circle floating over the page belongs to no layer of a comic page; its one filled action stands in its tier',
    ),
    RawInventoryEntry.present(
      'ButtonGroup',
      (context) => const ComicButtonGroup(
        semanticLabel: 'Text',
        items: [
          ComicButtonGroupItem('Copy', onPressed: _tap),
          ComicButtonGroupItem('Paste', onPressed: _tap),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'ToggleGroup',
      (context) => ComicToggleGroup<String>(
        semanticLabel: 'Style',
        values: const ['Bold', 'Italic'],
        selected: const {'Bold'},
        multiSelectionEnabled: true,
        labelOf: (value) => value,
        onSelectionChanged: _take,
      ),
    ),
    RawInventoryEntry.present(
      'SplitButton',
      (context) => const ComicSplitButton(
        'Save',
        onPressed: _tap,
        actions: [ComicSplitAction('Save as copy', onPressed: _tap)],
      ),
    ),
    RawInventoryEntry.present(
      'Link',
      (context) => const ComicLink('Read more', onPressed: _tap),
    ),
    RawInventoryEntry.present(
      'Kbd',
      (context) => const ComicKbd.shortcut(
        SingleActivator(LogicalKeyboardKey.keyK, control: true),
      ),
    ),
    // Inputs
    RawInventoryEntry.present(
      'TextField',
      (context) =>
          const ComicTextField(labelText: 'Name', hintText: 'Your name'),
    ),
    RawInventoryEntry.present(
      'TextArea',
      (context) => const ComicTextArea(labelText: 'Notes'),
    ),
    RawInventoryEntry.present(
      'SearchField',
      (context) => const ComicSearchField(hintText: 'Search issues'),
    ),
    RawInventoryEntry.present(
      'PasswordField',
      (context) => const ComicPasswordField(labelText: 'Password'),
    ),
    RawInventoryEntry.present(
      'InputGroup',
      (context) => const ComicInputGroup(
        labelText: 'Price',
        hintText: '0.00',
        leading: [Text('USD')],
      ),
    ),
    RawInventoryEntry.present(
      'InputOtp',
      (context) => const ComicInputOtp(labelText: 'Code'),
    ),
    RawInventoryEntry.present(
      'NumberField',
      (context) =>
          ComicNumberField(value: 6, unit: 'copies', onChanged: (_) => _tap()),
    ),
    RawInventoryEntry.present(
      'Select',
      (context) => const ComicSelect<String>(
        labelText: 'Format',
        options: [
          ComicSelectOption('print', 'Print'),
          ComicSelectOption('digital', 'Digital'),
        ],
        value: 'print',
        onChanged: _take,
      ),
    ),
    RawInventoryEntry.present(
      'Combobox',
      (context) => const ComicCombobox<String>(
        labelText: 'City',
        options: ['Lisbon', 'London', 'Lyon'],
      ),
    ),
    RawInventoryEntry.present(
      'MultiSelect',
      (context) => const ComicMultiSelect<String>(
        labelText: 'Genres',
        values: ['Noir'],
        options: ['Noir', 'Western', 'Horror'],
        onChanged: _take,
      ),
    ),
    RawInventoryEntry.present(
      'Checkbox',
      (context) => const ComicCheckbox(
        value: true,
        semanticLabel: 'Unread only',
        onChanged: _take,
      ),
    ),
    RawInventoryEntry.present(
      'RadioGroup',
      (context) => const ComicRadioGroup<String>(
        labelText: 'Format',
        options: [
          ComicRadio('print', 'Print'),
          ComicRadio('digital', 'Digital'),
        ],
        groupValue: 'print',
        onChanged: _take,
      ),
    ),
    RawInventoryEntry.present(
      'Switch',
      (context) => const ComicSwitch(
        value: true,
        semanticLabel: 'Alerts',
        onChanged: _take,
      ),
    ),
    RawInventoryEntry.present(
      'Slider',
      (context) =>
          const ComicSlider(label: 'Volume', value: .5, onChanged: _take),
    ),
    RawInventoryEntry.present(
      'RangeSlider',
      (context) => const ComicRangeSlider(
        label: 'Price',
        values: RawRangeValues(.2, .8),
        onChanged: _take,
      ),
    ),
    RawInventoryEntry.present(
      'SegmentedButton',
      (context) => const ComicSegmentedButton<String>(
        semanticLabel: 'View',
        segments: [
          ComicButtonSegment('all', 'All'),
          ComicButtonSegment('saved', 'Saved'),
        ],
        value: 'all',
        onChanged: _take,
      ),
    ),
    RawInventoryEntry.present(
      'Chip',
      (context) => const ComicChip('Noir', onPressed: _tap),
    ),
    RawInventoryEntry.present(
      'Rating',
      (context) => const ComicRating(
        semanticLabel: 'Rating',
        value: 3,
        onChanged: _take,
      ),
    ),
    RawInventoryEntry.present(
      'FileUpload',
      (context) =>
          const ComicFileUpload(labelText: 'Cover art', onChoose: _tap),
    ),
    RawInventoryEntry.present(
      'DatePicker',
      (context) => ComicDatePicker(
        value: DateTime(2026, 11, 10),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        onChanged: _take,
      ),
    ),
    RawInventoryEntry.present(
      'DateRangePicker',
      (context) => ComicDateRangePicker(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        onChanged: _take,
      ),
    ),
    RawInventoryEntry.present(
      'TimePicker',
      (context) => const ComicTimePicker(onChanged: _take),
    ),
    RawInventoryEntry.present(
      'Calendar',
      (context) => _Owned(
        () => RawCalendarController(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
        ),
        (calendar) => ComicCalendar(controller: calendar, onChanged: (_) {}),
      ),
    ),
    RawInventoryEntry.present(
      'WheelPicker',
      (context) => ComicWheelPicker<int>(
        semanticLabel: 'Copies',
        values: const [1, 2, 3, 4, 5],
        value: 2,
        labelOf: (copies) => '$copies',
        onChanged: _take,
      ),
    ),
    const RawInventoryEntry.absent(
      'ColorPicker',
      'a continuous field of colour can\'t be printed in process inks; a swatch picker in the inks can come later',
    ),
    RawInventoryEntry.present(
      'FormField',
      (context) => const ComicFormField(
        'Your name',
        child: ComicTextField(hintText: 'Name'),
      ),
    ),
    // Navigation
    RawInventoryEntry.present(
      'AppBar',
      (context) => const ComicAppBar(title: 'The plan'),
    ),
    RawInventoryEntry.present(
      'NavigationBar',
      (context) => const ComicNavigationBar(
        destinations: _places,
        onDestinationSelected: _take,
      ),
    ),
    RawInventoryEntry.present(
      'NavigationRail',
      (context) => const ComicNavigationRail(
        destinations: _places,
        onDestinationSelected: _take,
      ),
    ),
    RawInventoryEntry.present(
      'NavigationDrawer',
      (context) => const ComicNavigationDrawer(
        destinations: _places,
        onDestinationSelected: _take,
      ),
    ),
    RawInventoryEntry.present(
      'TabBar',
      (context) => const ComicTabBar(tabs: ['All', 'Saved'], onTap: _take),
    ),
    RawInventoryEntry.present(
      'Breadcrumb',
      (context) => const ComicBreadcrumb([
        ComicCrumb('Shop', onPressed: _tap),
        ComicCrumb('Issue 12'),
      ]),
    ),
    RawInventoryEntry.present(
      'Pagination',
      (context) =>
          const ComicPagination(pageCount: 5, page: 0, onPageChanged: _take),
    ),
    RawInventoryEntry.present(
      'StepProgress',
      (context) =>
          const ComicStepProgress(count: 3, currentStep: 1, name: 'Your order'),
    ),
    RawInventoryEntry.present(
      'PageDots',
      (context) => const ComicPageDots(
        pageCount: 3,
        selectedIndex: 0,
        semanticLabel: 'Pages',
      ),
    ),
    RawInventoryEntry.present(
      'MenuBar',
      (context) => ComicMenuBar(
        menus: [
          RawMenuEntry(
            label: 'File',
            children: [
              RawMenuEntry(
                label: 'New',
                shortcut: ComicKbd.labelOf(
                  context,
                  const SingleActivator(LogicalKeyboardKey.keyN, control: true),
                ),
                onPressed: _tap,
              ),
            ],
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Command',
      (context) => const ComicCommand(
        commands: [RawCommand(label: 'New issue', onPressed: _tap)],
      ),
    ),
    RawInventoryEntry.present(
      'Scaffold',
      (context) => const ComicScaffold(body: Text('Issue 12')),
    ),
    // Containers
    RawInventoryEntry.present(
      'Card',
      (context) => const ComicCard(
        title: 'This issue',
        children: [Text('Twelve pages')],
      ),
    ),
    RawInventoryEntry.present(
      'ListTile',
      (context) => const ComicListTile(title: 'First'),
    ),
    RawInventoryEntry.present(
      'ListSection',
      (context) => const ComicListSection(
        children: [
          ComicListTile(title: 'First'),
          ComicListTile(title: 'Second'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'SectionHeader',
      (context) => const ComicSectionHeader('New this week'),
    ),
    RawInventoryEntry.present(
      'Disclosure',
      (context) => const ComicDisclosure(
        title: 'More about this issue',
        child: Text('The full story'),
      ),
    ),
    RawInventoryEntry.present(
      'Table',
      (context) => const ComicTable(
        columns: ['Issue', 'Pages'],
        rows: [
          ['Twelve', '24'],
          ['Thirteen', '32'],
        ],
      ),
    ),
    const RawInventoryEntry.present('DataTable', _table),
    RawInventoryEntry.present('Divider', (context) => const ComicDivider()),
    const RawInventoryEntry.present('ScrollArea', _scrollArea),
    RawInventoryEntry.present(
      'Resizable',
      (context) =>
          const ComicResizable(first: Text('List'), second: Text('Detail')),
    ),
    RawInventoryEntry.present(
      'CarouselView',
      (context) => const ComicCarouselView(
        semanticLabel: 'This week',
        children: [
          ComicMedia(slotId: 'pick-1', semanticLabel: 'First pick'),
          ComicMedia(slotId: 'pick-2', semanticLabel: 'Second pick'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'ReorderableListView',
      (context) => ComicReorderableListView<String>(
        items: const ['Pencils', 'Inks'],
        labelOf: (item) => item,
        shrinkWrap: true,
        onReorder: (from, to) {},
        itemBuilder: (context, item) => Text(item),
      ),
    ),
    RawInventoryEntry.present(
      'SwipeActions',
      (context) => const ComicSwipeActions(
        endActions: [
          RawSwipeAction(label: 'Delete', onPressed: _tap, destructive: true),
        ],
        child: ComicListTile(title: 'Issue 12'),
      ),
    ),
    RawInventoryEntry.present(
      'RefreshIndicator',
      (context) => ComicRefreshIndicator(
        onRefresh: _settle,
        child: ListView(children: const [Text('Issue 12')]),
      ),
    ),
    RawInventoryEntry.present(
      'TreeView',
      (context) => _Owned(
        () => RawTreeController<String>(
          roots: const ['Issues'],
          childrenOf: (node) => node == 'Issues' ? const ['Twelve'] : const [],
          expanded: const ['Issues'],
        ),
        (tree) =>
            ComicTreeView<String>(controller: tree, labelOf: (node) => node),
      ),
    ),
    RawInventoryEntry.present(
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
    RawInventoryEntry.present(
      'Avatar',
      (context) => const ComicAvatar('NW', name: 'Nia Walker'),
    ),
    RawInventoryEntry.present(
      'AvatarGroup',
      (context) => const ComicAvatarGroup([
        ComicFace('NW'),
        ComicFace('AK'),
      ], semanticLabel: 'Contributors'),
    ),
    RawInventoryEntry.present('Badge', (context) => const ComicBadge(3)),
    RawInventoryEntry.present('Tag', (context) => const ComicTag('New')),
    RawInventoryEntry.present(
      'Media',
      (context) => const ComicMedia(slotId: 'cover', semanticLabel: 'Cover'),
    ),
    RawInventoryEntry.present(
      'EmptyState',
      (context) => const ComicEmptyState(
        title: 'All caught up',
        body: 'No new messages.',
      ),
    ),
    RawInventoryEntry.present(
      'DescriptionList',
      (context) => const ComicDescriptionList(
        entries: [
          ComicDescriptionItem('Writer', 'Ana Ruiz'),
          ComicDescriptionItem('Pages', '24'),
        ],
      ),
    ),
    // Overlays
    RawInventoryEntry.present(
      'Dialog',
      (context) => const ComicDialog(
        title: 'Remove issue?',
        message: 'This cannot be undone.',
      ),
    ),
    RawInventoryEntry.present(
      'BottomSheet',
      (context) =>
          const ComicBottomSheet(title: 'Details', child: Text('Issue 12')),
    ),
    RawInventoryEntry.present(
      'Sheet',
      (context) =>
          const ComicSheet(title: 'Filters', child: Text('Only unread')),
    ),
    RawInventoryEntry.present(
      'ActionSheet',
      (context) => const ComicActionSheet<String>(
        title: 'Issue 12',
        actions: [ComicSheetAction('Share', value: 'share')],
        onSelected: _take,
      ),
    ),
    RawInventoryEntry.present(
      'Popover',
      (context) => ComicPopover(
        anchorBuilder: (context, anchor) =>
            ComicButton('Filter', onPressed: anchor.toggle),
        builder: (context, close) => const Text('Only unread'),
      ),
    ),
    RawInventoryEntry.present(
      'HoverCard',
      (context) => const ComicHoverCard(
        card: Text('Inker, issue 12 on'),
        child: Text('Ada'),
      ),
    ),
    RawInventoryEntry.present(
      'Tooltip',
      (context) => const ComicTooltip(message: 'Share', child: Text('Share')),
    ),
    RawInventoryEntry.present(
      'Menu',
      (context) => const ComicMenu<String>(
        items: [ComicMenuItem('save', 'Save')],
        onSelected: _take,
      ),
    ),
    RawInventoryEntry.present(
      'SnackBar',
      (context) => const ComicSnackBar('Saved to your collection'),
    ),
    RawInventoryEntry.present(
      'Banner',
      (context) => const ComicBanner('Your issue ships Friday'),
    ),
    // Feedback
    RawInventoryEntry.present(
      'LinearProgressIndicator',
      (context) => const ComicLinearProgressIndicator(
        value: .4,
        semanticLabel: 'Saving',
      ),
    ),
    RawInventoryEntry.present(
      'CircularProgressIndicator',
      (context) => const ComicCircularProgressIndicator(
        value: .4,
        semanticLabel: 'Saving',
      ),
    ),
    RawInventoryEntry.present(
      'Skeleton',
      (context) => const ComicSkeleton(width: 120),
    ),
    RawInventoryEntry.present(
      'StatusView',
      (context) => const ComicStatusView.empty(title: 'Nothing here yet'),
    ),
    RawInventoryEntry.present(
      'Meter',
      (context) => const ComicMeter(label: 'Pages read', value: .6),
    ),
    // Charts
    RawInventoryEntry.present(
      'LineChart',
      (context) => const ComicLineChart(
        semanticLabel: 'Pages read',
        labels: _week,
        series: _pages,
      ),
    ),
    RawInventoryEntry.present(
      'BarChart',
      (context) => const ComicBarChart(
        semanticLabel: 'Pages read',
        labels: _week,
        series: _pages,
      ),
    ),
    RawInventoryEntry.present(
      'AreaChart',
      (context) => const ComicAreaChart(
        semanticLabel: 'Pages read',
        labels: _week,
        series: _pages,
      ),
    ),
    RawInventoryEntry.present(
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
    RawInventoryEntry.present(
      'Sparkline',
      (context) => const ComicSparkline(
        semanticLabel: 'Pages',
        values: [12, 18, 16, 22],
      ),
    ),
  ],
);
