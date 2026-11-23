/// Expressive's answer to ui_core's shared inventory (looks/INVENTORY.md):
/// for each of the 89 components every look names alike, the Expressive
/// class that is it, built live, or why the look leaves it out (six
/// that are not Material's). [ExpressiveInventoryGallery] lists them, group by group.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';
import 'package:ui_core/ui_core.dart';

import 'components/app_bar.dart';
import 'components/badge.dart';
import 'components/buttons.dart';
import 'components/cards.dart';
import 'components/carousel.dart';
import 'components/chart.dart';
import 'components/chips.dart';
import 'components/color_picker.dart';
import 'components/content.dart';
import 'components/data_table.dart';
import 'components/display.dart';
import 'components/fab.dart';
import 'components/feedback.dart';
import 'components/file_input.dart';
import 'components/form.dart';
import 'components/icon_buttons.dart';
import 'components/lists.dart';
import 'components/loading.dart';
import 'components/media.dart';
import 'components/menus.dart';
import 'components/nav.dart';
import 'components/overlays.dart';
import 'components/panes.dart';
import 'components/pickers.dart';
import 'components/progress.dart';
import 'components/screen.dart';
import 'components/select.dart';
import 'components/selection.dart';
import 'components/sheet.dart';
import 'components/sliders.dart';
import 'components/split_button.dart';
import 'components/table.dart';
import 'components/text_fields.dart';
import 'components/toast.dart';
import 'components/wayfinding.dart';
import 'icons.dart';
import 'internal/owned.dart';
import 'shape.dart';
import 'spacing.dart';
import 'theme.dart';

/// Every inventory row, each a live specimen of its `Expressive<Stem>`.
///
/// ```dart
/// expressiveInventory.verify();
/// ```
const DesignInventory expressiveInventory = DesignInventory(
  look: 'Material Expressive',
  entries: <DesignInventoryEntry>[
    // Actions
    DesignInventoryEntry.present('Button', _button),
    DesignInventoryEntry.present('IconButton', _iconButton),
    DesignInventoryEntry.present('FloatingActionButton', _fab),
    DesignInventoryEntry.present('ButtonGroup', _buttonGroup),
    DesignInventoryEntry.present('ToggleGroup', _toggleGroup),
    DesignInventoryEntry.present('SplitButton', _splitButton),
    DesignInventoryEntry.present('Link', _link),
    DesignInventoryEntry.absent(
      'Kbd',
      "Material draws no keyboard keys (shadcn's Kbd): a shortcut is a menu item's trailing text",
    ),
    // Inputs
    DesignInventoryEntry.present('TextField', _textField),
    DesignInventoryEntry.present('TextArea', _textArea),
    DesignInventoryEntry.present('SearchField', _searchField),
    DesignInventoryEntry.present('PasswordField', _passwordField),
    DesignInventoryEntry.present('InputGroup', _inputGroup),
    DesignInventoryEntry.present('InputOtp', _inputOtp),
    DesignInventoryEntry.present('NumberField', _numberField),
    DesignInventoryEntry.present('Select', _select),
    DesignInventoryEntry.present('Combobox', _combobox),
    DesignInventoryEntry.present('MultiSelect', _multiSelect),
    DesignInventoryEntry.present('Checkbox', _checkbox),
    DesignInventoryEntry.present('RadioGroup', _radioGroup),
    DesignInventoryEntry.present('Switch', _switch),
    DesignInventoryEntry.present('Slider', _slider),
    DesignInventoryEntry.present('RangeSlider', _rangeSlider),
    DesignInventoryEntry.present('SegmentedButton', _segmentedButton),
    DesignInventoryEntry.present('Chip', _chip),
    DesignInventoryEntry.present('Rating', _rating),
    DesignInventoryEntry.present('FileUpload', _fileUpload),
    DesignInventoryEntry.present('DatePicker', _datePicker),
    DesignInventoryEntry.present('DateRangePicker', _dateRangePicker),
    DesignInventoryEntry.present('TimePicker', _timePicker),
    DesignInventoryEntry.present('Calendar', _calendar),
    DesignInventoryEntry.absent(
      'WheelPicker',
      "Material has no wheel: a number takes ExpressiveScrollField (Compose's ScrollField), a word the select",
    ),
    DesignInventoryEntry.present('ColorPicker', _colorPicker),
    DesignInventoryEntry.present('FormField', _formField),
    // Navigation
    DesignInventoryEntry.present('AppBar', _appBar),
    DesignInventoryEntry.present('NavigationBar', _navigationBar),
    DesignInventoryEntry.present('NavigationRail', _navigationRail),
    DesignInventoryEntry.present('NavigationDrawer', _navigationDrawer),
    DesignInventoryEntry.present('TabBar', _tabBar),
    DesignInventoryEntry.present('Breadcrumb', _breadcrumb),
    DesignInventoryEntry.present('Pagination', _pagination),
    DesignInventoryEntry.present('StepProgress', _stepProgress),
    DesignInventoryEntry.present('PageDots', _pageDots),
    DesignInventoryEntry.present('MenuBar', _menuBar),
    DesignInventoryEntry.absent(
      'Command',
      "shadcn's command palette: Material searches with the search bar and its view (ExpressiveSearchBar)",
    ),
    DesignInventoryEntry.present('Scaffold', _scaffold),
    // Containers
    DesignInventoryEntry.present('Card', _card),
    DesignInventoryEntry.present('ListTile', _listTile),
    DesignInventoryEntry.present('ListSection', _listSection),
    DesignInventoryEntry.present('SectionHeader', _sectionHeader),
    DesignInventoryEntry.present('Disclosure', _disclosure),
    DesignInventoryEntry.present('Table', _table),
    DesignInventoryEntry.present('DataTable', _dataTable),
    DesignInventoryEntry.present('Divider', _divider),
    DesignInventoryEntry.present('ScrollArea', _scrollArea),
    DesignInventoryEntry.present('Resizable', _resizable),
    DesignInventoryEntry.present('CarouselView', _carouselView),
    DesignInventoryEntry.present('ReorderableListView', _reorderableListView),
    DesignInventoryEntry.present('SwipeActions', _swipeActions),
    DesignInventoryEntry.present('RefreshIndicator', _refreshIndicator),
    DesignInventoryEntry.absent(
      'TreeView',
      "shadcn's tree; Material has none: a list or the navigation drawer's sections hold a hierarchy",
    ),
    DesignInventoryEntry.present('Timeline', _timeline),
    DesignInventoryEntry.present('Avatar', _avatar),
    DesignInventoryEntry.present('AvatarGroup', _avatarGroup),
    DesignInventoryEntry.present('Badge', _badge),
    DesignInventoryEntry.present('Tag', _tag),
    DesignInventoryEntry.present('Media', _media),
    DesignInventoryEntry.present('EmptyState', _emptyState),
    DesignInventoryEntry.present('DescriptionList', _descriptionList),
    // Overlays
    DesignInventoryEntry.present('Dialog', _dialog),
    DesignInventoryEntry.present('BottomSheet', _bottomSheet),
    DesignInventoryEntry.present('Sheet', _sheet),
    DesignInventoryEntry.absent(
      'ActionSheet',
      "iOS's action sheet: Material lists a context's actions in a modal bottom sheet (showExpressiveBottomSheet)",
    ),
    DesignInventoryEntry.present('Popover', _popover),
    DesignInventoryEntry.absent(
      'HoverCard',
      "shadcn's hover card; Material has none: a rich tooltip carries what one would",
    ),
    DesignInventoryEntry.present('Tooltip', _tooltip),
    DesignInventoryEntry.present('Menu', _menu),
    DesignInventoryEntry.present('SnackBar', _snackBar),
    DesignInventoryEntry.present('Banner', _banner),
    // Feedback
    DesignInventoryEntry.present('LinearProgressIndicator', _linearProgress),
    DesignInventoryEntry.present(
      'CircularProgressIndicator',
      _circularProgress,
    ),
    DesignInventoryEntry.present('Skeleton', _skeleton),
    DesignInventoryEntry.present('StatusView', _statusView),
    DesignInventoryEntry.present('Meter', _meter),
    // Charts
    DesignInventoryEntry.present('LineChart', _lineChart),
    DesignInventoryEntry.present('BarChart', _barChart),
    DesignInventoryEntry.present('AreaChart', _areaChart),
    DesignInventoryEntry.present('PieChart', _pieChart),
    DesignInventoryEntry.present('Sparkline', _sparkline),
  ],
);

void _none() {}
void _drop(Object? _) {}
void _dropTwo(Object? _, Object? _) {}

// --- Actions -----------------------------------------------------------------

Widget _button(BuildContext context) =>
    const ExpressiveFilledButton('Save', onPressed: _none);

Widget _iconButton(BuildContext context) => const ExpressiveIconButton(
  ExpressiveSymbols.favorite,
  semanticLabel: 'Favourite',
  onPressed: _none,
);

Widget _fab(BuildContext context) => const ExpressiveFloatingActionButton(
  icon: ExpressiveSymbols.add,
  semanticLabel: 'New trip',
  onPressed: _none,
);

Widget _buttonGroup(BuildContext context) => const ExpressiveButtonGroup(
  children: <Widget>[
    ExpressiveFilledButton.tonal('Day', onPressed: _none),
    ExpressiveFilledButton.tonal('Week', onPressed: _none),
    ExpressiveFilledButton.tonal('Month', onPressed: _none),
  ],
);

Widget _toggleGroup(BuildContext context) =>
    const ExpressiveToggleGroup<String>(
      label: 'Alignment',
      value: 'center',
      onChanged: _drop,
      segments: <ExpressiveButtonSegment<String>>[
        ExpressiveButtonSegment('start', 'Start'),
        ExpressiveButtonSegment('center', 'Centre'),
        ExpressiveButtonSegment('end', 'End'),
      ],
    );

Widget _splitButton(BuildContext context) =>
    const ExpressiveSplitButton('Send', onPressed: _none);

Widget _link(BuildContext context) =>
    const ExpressiveLink('Terms of service', onPressed: _none);

// --- Inputs ------------------------------------------------------------------

Widget _textField(BuildContext context) =>
    const ExpressiveTextField(labelText: 'City');

Widget _textArea(BuildContext context) =>
    const ExpressiveTextArea(labelText: 'Notes');

Widget _searchField(BuildContext context) =>
    const ExpressiveSearchField(hintText: 'Search messages');

Widget _passwordField(BuildContext context) =>
    const ExpressivePasswordField(labelText: 'Password');

Widget _inputGroup(BuildContext context) => ExpressiveInputGroup(
  hintText: 'example.com',
  semanticLabel: 'Website',
  leading: <Widget>[ExpressiveInputGroup.text('https://')],
);

Widget _inputOtp(BuildContext context) => const ExpressiveInputOtp();

Widget _numberField(BuildContext context) => const ExpressiveNumberField(
  value: 2,
  min: 1,
  max: 8,
  labelText: 'Guests',
  onChanged: _drop,
);

const List<ExpressiveSelectOption<String>> _sizes =
    <ExpressiveSelectOption<String>>[
      ExpressiveSelectOption('s', 'Small'),
      ExpressiveSelectOption('m', 'Medium'),
      ExpressiveSelectOption('l', 'Large'),
    ];

Widget _select(BuildContext context) => const ExpressiveSelect<String>(
  options: _sizes,
  value: 'm',
  onChanged: _drop,
  labelText: 'Size',
);

Widget _combobox(BuildContext context) =>
    const ExpressiveCombobox<String>(options: _sizes, labelText: 'Size');

Widget _multiSelect(BuildContext context) =>
    const ExpressiveMultiSelect<String>(
      labelText: 'Sizes',
      options: _sizes,
      values: <String>['s', 'm'],
      onChanged: _drop,
    );

Widget _checkbox(BuildContext context) => const ExpressiveCheckbox(
  value: true,
  semanticLabel: 'Email receipts',
  onChanged: _drop,
);

Widget _radioGroup(BuildContext context) => const ExpressiveRadioGroup<String>(
  value: 'monthly',
  onChanged: _drop,
  options: <ExpressiveRadioOption<String>>[
    ExpressiveRadioOption(value: 'monthly', label: 'Monthly'),
    ExpressiveRadioOption(value: 'yearly', label: 'Yearly'),
  ],
);

Widget _switch(BuildContext context) => const ExpressiveSwitch(
  value: true,
  semanticLabel: 'Wi-Fi',
  onChanged: _drop,
);

Widget _slider(BuildContext context) =>
    const ExpressiveSlider(value: 0.4, onChanged: _drop);

Widget _rangeSlider(BuildContext context) => const ExpressiveRangeSlider(
  start: 120,
  end: 340,
  min: 0,
  max: 500,
  onChanged: _dropTwo,
);

Widget _segmentedButton(BuildContext context) =>
    const ExpressiveSegmentedButton<int>(
      segments: <ExpressiveButtonSegment<int>>[
        ExpressiveButtonSegment(0, 'Day'),
        ExpressiveButtonSegment(1, 'Week'),
        ExpressiveButtonSegment(2, 'Month'),
      ],
      value: 1,
      onChanged: _drop,
    );

Widget _chip(BuildContext context) =>
    const ExpressiveChip('Vegetarian', selected: true, onPressed: _none);

Widget _rating(BuildContext context) => const ExpressiveRating(value: 4.5);

Widget _fileUpload(BuildContext context) => const ExpressiveFileUpload(
  labelText: 'Drop a receipt here',
  helperText: 'PDF or JPG, up to 10 MB',
  onBrowse: _none,
);

final DateTime _today = DateTime(2026, 11, 10);

Widget _datePicker(BuildContext context) =>
    ExpressiveDatePicker(currentDate: _today, onChanged: _drop);

Widget _dateRangePicker(BuildContext context) =>
    ExpressiveDateRangePicker(currentDate: _today, onChanged: _dropTwo);

Widget _timePicker(BuildContext context) => Owned(
  create: () => ExpressiveTimePickerController(hour: 8, minute: 15),
  builder: (context, controller) =>
      ExpressiveTimePicker(controller: controller),
);

Widget _calendar(BuildContext context) => ExpressiveCalendar(
  firstDate: DateTime(2026),
  lastDate: DateTime(2027, 12, 31),
  currentDate: _today,
  value: DateTime(2026, 11, 12),
  onChanged: _drop,
);

Widget _colorPicker(BuildContext context) =>
    const ExpressiveColorPicker(value: Color(0xFF6750A4), onChanged: _drop);

Widget _formField(BuildContext context) => const ExpressiveFormField(
  labelText: 'Notify me',
  helperText: 'At most once a day',
  child: ExpressiveSwitch(value: true, onChanged: _drop),
);

// --- Navigation --------------------------------------------------------------

const List<ExpressiveNavItem> _destinations = <ExpressiveNavItem>[
  ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
  ExpressiveNavItem(ExpressiveSymbols.search, 'Search'),
  ExpressiveNavItem(ExpressiveSymbols.person, 'Profile'),
];

Widget _appBar(BuildContext context) =>
    const ExpressiveAppBar(title: 'Trips', subtitle: '3 upcoming');

Widget _navigationBar(BuildContext context) => const ExpressiveNavigationBar(
  destinations: _destinations,
  selectedIndex: 0,
  onDestinationSelected: _drop,
);

Widget _navigationRail(BuildContext context) => const ExpressiveNavigationRail(
  destinations: _destinations,
  selectedIndex: 0,
  onDestinationSelected: _drop,
);

Widget _navigationDrawer(BuildContext context) =>
    const ExpressiveNavigationDrawer(
      destinations: _destinations,
      selectedIndex: 1,
      onDestinationSelected: _drop,
    );

Widget _tabBar(BuildContext context) => const ExpressiveTabBar(
  tabs: <ExpressiveTab>[
    ExpressiveTab(label: 'Flights'),
    ExpressiveTab(label: 'Hotels'),
    ExpressiveTab(label: 'Cars'),
  ],
  selectedIndex: 0,
  onChanged: _drop,
);

Widget _breadcrumb(BuildContext context) => const ExpressiveBreadcrumb(
  items: <ExpressiveBreadcrumbItem>[
    ExpressiveBreadcrumbItem('Home', onPressed: _none),
    ExpressiveBreadcrumbItem('Orders', onPressed: _none),
    ExpressiveBreadcrumbItem('#1042'),
  ],
);

Widget _pagination(BuildContext context) =>
    const ExpressivePagination(page: 3, pageCount: 12, onChanged: _drop);

Widget _stepProgress(BuildContext context) => const ExpressiveStepProgress(
  count: 3,
  currentStep: 1,
  labels: <String>['Cart', 'Address', 'Pay'],
);

Widget _pageDots(BuildContext context) =>
    const ExpressivePageDots(pageCount: 5, page: 1, onChanged: _drop);

Widget _menuBar(BuildContext context) => ExpressiveMenuBar(
  menus: <ExpressiveMenuBarEntry>[
    ExpressiveMenuBarEntry(
      'File',
      children: <ExpressiveMenuBarEntry>[
        ExpressiveMenuBarEntry(
          'New',
          shortcut: _shortcut(context, LogicalKeyboardKey.keyN),
          onPressed: _none,
        ),
        ExpressiveMenuBarEntry(
          'Open…',
          shortcut: _shortcut(context, LogicalKeyboardKey.keyO),
          onPressed: _none,
        ),
      ],
    ),
    ExpressiveMenuBarEntry(
      'Edit',
      children: <ExpressiveMenuBarEntry>[
        ExpressiveMenuBarEntry(
          'Undo',
          shortcut: _shortcut(context, LogicalKeyboardKey.keyZ),
          onPressed: _none,
        ),
      ],
    ),
  ],
);

/// [key] with the platform's command modifier (⌘ on macOS and iOS, Ctrl
/// elsewhere), labelled as the platform's menus label it.
String _shortcut(BuildContext context, LogicalKeyboardKey key) {
  final apple =
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;
  return designShortcutLabel(
    context,
    SingleActivator(key, meta: apple, control: !apple),
  );
}

Widget _scaffold(BuildContext context) =>
    const ExpressiveScaffold(title: 'Trips', body: Text('Three upcoming'));

// --- Containers --------------------------------------------------------------

Widget _card(BuildContext context) => const ExpressiveCard(
  child: Padding(
    padding: EdgeInsets.all(ExpressiveSpacing.s16),
    child: Text('Ridge trail · 6 km'),
  ),
);

Widget _listTile(BuildContext context) => const ExpressiveListTile(
  title: Text('Wi-Fi'),
  subtitle: Text('Home network'),
  leading: Icon(ExpressiveSymbols.wifi),
  onTap: _none,
);

Widget _listSection(BuildContext context) => const ExpressiveListSection(
  header: 'Network',
  children: <Widget>[
    ExpressiveListTile(title: Text('Wi-Fi'), onTap: _none),
    ExpressiveListTile(title: Text('Bluetooth'), onTap: _none),
  ],
);

Widget _sectionHeader(BuildContext context) =>
    const ExpressiveSectionHeader('Recent');

Widget _disclosure(BuildContext context) => const ExpressiveDisclosure(
  title: Text('Shipping'),
  child: Text('Ships in two days.'),
);

Widget _table(BuildContext context) => const ExpressiveTable(
  columns: <ExpressiveTableColumn>[
    ExpressiveTableColumn('Plant', flex: 2),
    ExpressiveTableColumn('Water', numeric: true),
  ],
  rows: <ExpressiveTableRow>[
    ExpressiveTableRow(<Object>['Fern', '200 ml']),
    ExpressiveTableRow(<Object>['Cactus', '50 ml']),
  ],
);

Widget _dataTable(BuildContext context) => Owned(
  create: () => RawDataTableController<List<String>>(
    rows: const <List<String>>[
      <String>['#4821', 'Ada Okafor', '128.40'],
      <String>['#4822', 'Ben Ito', '42.00'],
    ],
    rowKey: (row) => row.first,
    columns: <RawDataColumn<List<String>>>[
      RawDataColumn<List<String>>(
        id: '0',
        label: 'Order',
        sortKey: (row) => row[0],
      ),
      const RawDataColumn<List<String>>(id: '1', label: 'Customer'),
      RawDataColumn<List<String>>(
        id: '2',
        label: 'Total',
        numeric: true,
        sortKey: (row) => double.parse(row[2]),
      ),
    ],
  ),
  builder: (context, controller) => ExpressiveDataTable<List<String>>(
    controller: controller,
    cellBuilder: (context, row, column) => Text(row[int.parse(column.id)]),
  ),
);

Widget _divider(BuildContext context) => const ExpressiveDivider();

Widget _scrollArea(BuildContext context) =>
    const Owned(create: ScrollController.new, builder: _scrollAreaWith);

Widget _scrollAreaWith(BuildContext context, ScrollController scroll) {
  return ExpressiveScrollArea(
    controller: scroll,
    alwaysShown: true,
    child: ListView(
      controller: scroll,
      shrinkWrap: true,
      children: <Widget>[
        for (var i = 1; i <= 12; i++)
          Padding(
            padding: const EdgeInsets.all(ExpressiveSpacing.s8),
            child: Text('Version 1.$i'),
          ),
      ],
    ),
  );
}

Widget _resizable(BuildContext context) => const ExpressiveResizable(
  initialFraction: 0.4,
  first: Center(child: Text('Folders')),
  second: Center(child: Text('Messages')),
);

Widget _carouselView(BuildContext context) =>
    ExpressiveCarouselView.multiBrowse(
      itemCount: 4,
      height: 160,
      itemBuilder: (context, i) => ExpressiveMedia(slotId: 'trip-$i'),
    );

Widget _reorderableListView(BuildContext context) =>
    ExpressiveReorderableListView(
      itemCount: 3,
      onReorder: _dropTwo,
      itemBuilder: (context, i) => ExpressiveListTile(
        key: ValueKey<int>(i),
        title: Text(<String>['Pack', 'Book', 'Go'][i]),
        trailing: ExpressiveReorderHandle(index: i),
      ),
    );

Widget _swipeActions(BuildContext context) => const ExpressiveSwipeActions(
  trailing: <ExpressiveSwipeAction>[
    ExpressiveSwipeAction(
      label: 'Archive',
      icon: ExpressiveSymbols.archive,
      onPressed: _none,
    ),
  ],
  child: ExpressiveListTile(title: Text('Trip to Lisbon')),
);

Future<void> _refresh() async {}

Widget _refreshIndicator(BuildContext context) => ExpressiveRefreshIndicator(
  onRefresh: _refresh,
  child: ListView(
    shrinkWrap: true,
    children: const <Widget>[
      ExpressiveListTile(title: Text('Pull to refresh')),
    ],
  ),
);

Widget _timeline(BuildContext context) => const ExpressiveTimeline(
  currentStep: 1,
  entries: <ExpressiveTimelineEntry>[
    ExpressiveTimelineEntry(title: 'Order placed', time: '09:12'),
    ExpressiveTimelineEntry(title: 'Shipped', time: '14:40'),
  ],
);

Widget _avatar(BuildContext context) =>
    const ExpressiveAvatar(name: 'Mara Quist');

Widget _avatarGroup(BuildContext context) => const ExpressiveAvatarGroup(
  faces: <ExpressiveFace>[
    ExpressiveFace('Noor Wahid'),
    ExpressiveFace('Ada Kim'),
    ExpressiveFace('Jon Ruiz'),
  ],
  total: 7,
);

Widget _badge(BuildContext context) => const ExpressiveBadge.count(3);

Widget _tag(BuildContext context) =>
    const ExpressiveTag('New', tone: ExpressiveTone.primary);

Widget _media(BuildContext context) => const ExpressiveMedia(
  slotId: 'hero',
  aspectRatio: 16 / 9,
  corner: ExpressiveCorner.large,
);

Widget _emptyState(BuildContext context) => const ExpressiveEmptyState(
  icon: ExpressiveSymbols.inbox,
  title: 'Nothing here yet',
);

Widget _descriptionList(BuildContext context) =>
    const ExpressiveDescriptionList(
      items: <ExpressiveDescriptionItem>[
        ExpressiveDescriptionItem('Order', '#4821'),
        ExpressiveDescriptionItem('Placed', '14 March'),
      ],
    );

// --- Overlays ----------------------------------------------------------------

Widget _dialog(BuildContext context) => const ExpressiveDialog(
  title: 'Discard draft?',
  text: 'The message you started will be lost.',
);

Widget _bottomSheet(BuildContext context) => const ExpressiveBottomSheet(
  child: Padding(
    padding: EdgeInsets.all(ExpressiveSpacing.s16),
    child: Text('Share to…'),
  ),
);

Widget _sheet(BuildContext context) => const ExpressiveSheet(
  title: 'Filters',
  onClose: _none,
  child: Text('Open orders only'),
);

Widget _popoverContent(BuildContext context) =>
    const Text('Saved to your library');

Widget _popover(BuildContext context) =>
    const ExpressivePopover(content: _popoverContent, child: Text('Library'));

Widget _tooltip(BuildContext context) => const ExpressiveTooltip.plain(
  message: 'Share',
  child: Icon(ExpressiveSymbols.share),
);

Widget _menu(BuildContext context) => const ExpressiveMenu(
  entries: <ExpressiveMenuEntry>[
    ExpressiveMenuItem('Rename', onPressed: _none),
    ExpressiveMenuItem('Archive', onPressed: _none),
  ],
  child: Text('Trip'),
);

Widget _snackBar(BuildContext context) =>
    const ExpressiveSnackBar('Message archived');

Widget _banner(BuildContext context) => const ExpressiveBanner(
  icon: ExpressiveSymbols.wifi,
  title: 'You are offline',
  message: 'Changes will sync when you reconnect.',
  actions: <ExpressiveBannerAction>[
    ExpressiveBannerAction('Retry', onPressed: _none),
  ],
);

// --- Feedback ----------------------------------------------------------------

Widget _linearProgress(BuildContext context) =>
    const ExpressiveLinearProgressIndicator(
      value: 0.4,
      semanticLabel: 'Upload',
    );

Widget _circularProgress(BuildContext context) =>
    const ExpressiveCircularProgressIndicator(semanticLabel: 'Syncing');

Widget _skeleton(BuildContext context) =>
    const ExpressiveSkeleton.text(lines: 2);

Widget _statusView(BuildContext context) => const ExpressiveStatusView.error(
  title: 'Could not load',
  message: 'Check your connection',
  onRetry: _none,
);

Widget _meter(BuildContext context) => const ExpressiveMeter(
  label: 'Storage',
  value: 148,
  limit: 200,
  note: '52 GB left',
);

// --- Charts ------------------------------------------------------------------

const List<ExpressiveChartPoint> _week = <ExpressiveChartPoint>[
  ExpressiveChartPoint('Mon', 64),
  ExpressiveChartPoint('Tue', 70),
  ExpressiveChartPoint('Wed', 67),
  ExpressiveChartPoint('Thu', 75),
  ExpressiveChartPoint('Fri', 72),
  ExpressiveChartPoint('Sat', 78),
  ExpressiveChartPoint('Sun', 69),
];

const List<ExpressiveChartPoint> _spend = <ExpressiveChartPoint>[
  ExpressiveChartPoint('Rent', 1200),
  ExpressiveChartPoint('Food', 640),
  ExpressiveChartPoint('Travel', 380),
  ExpressiveChartPoint('Other', 200),
];

Widget _lineChart(BuildContext context) =>
    const ExpressiveLineChart(points: _week, semanticLabel: 'Pulse this week');

Widget _barChart(BuildContext context) => const ExpressiveBarChart(
  points: _week,
  highlight: 5,
  semanticLabel: 'Minutes read this week',
);

Widget _areaChart(BuildContext context) =>
    const ExpressiveAreaChart(points: _week, semanticLabel: 'Mood this week');

Widget _pieChart(BuildContext context) => const ExpressivePieChart(
  points: _spend,
  centerValue: '2,420',
  centerLabel: 'Spent in March',
  aspectRatio: 1.4,
);

Widget _sparkline(BuildContext context) =>
    const ExpressiveSparkline(points: _week);

// --- The gallery -------------------------------------------------------------

/// The box a specimen stands in: a card's column, wide and tall enough for
/// the docked date picker, the tallest.
const double _specimenExtent = 560;

/// The behaviour rows whose part paints ui_core's behaviour (the row's
/// [DesignInventoryRow.behaviour]). The other behaviour rows keep
/// Expressive's own (the split button, combobox, range slider, date range
/// picker, command palette, carousel, reorderable list, swipe actions, pull
/// to refresh, tree, popover, hover card and snackbar; and of the rows
/// ui_core 0.3.0 adds, the number field, rating, time and wheel pickers,
/// navigation, tabs, scaffold, bottom sheet, tooltip, menu and charts), so
/// the gallery names no behaviour for them.
const Set<String> _onBehaviour = {
  'ToggleGroup',
  'PasswordField',
  'InputGroup',
  'InputOtp',
  'MultiSelect',
  'Calendar',
  'ColorPicker',
  'FormField',
  'MenuBar',
  'DataTable',
  'ScrollArea',
  'Resizable',
  'Dialog',
  'Sheet',
};

/// The inventory as one scrolling list, group by group: each group's
/// heading in `titleLarge` with how many rows it carries, each row its
/// name in `titleSmall`, its class in `labelMedium` (and, for a part that
/// paints a ui_core behaviour, that behaviour), then its specimen, live, in
/// a card's column: at most 560dp wide and 560dp tall.
///
/// ```dart
/// const ExpressiveInventoryGallery()
/// ```
class ExpressiveInventoryGallery extends StatelessWidget {
  /// The inventory as one scrolling list.
  const ExpressiveInventoryGallery({
    this.behaviourOnly = false,
    this.controller,
    super.key,
  });

  /// Whether to list only the rows ui_core's behaviours hold.
  final bool behaviourOnly;

  /// The list's scroll controller.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    return DesignInventoryGallery(
      inventory: expressiveInventory,
      behaviourOnly: behaviourOnly,
      controller: controller,
      padding: const EdgeInsets.all(ExpressiveSpacing.s16),
      groupBuilder: (context, group, live, total) => Padding(
        padding: const EdgeInsets.only(
          top: ExpressiveSpacing.s24,
          bottom: ExpressiveSpacing.s8,
        ),
        child: Text(
          '$group · $live of $total',
          style: t.type.titleLarge.copyWith(color: c.onSurface),
        ),
      ),
      rowBuilder: (context, row, entry, specimen) {
        final reason = entry?.absentReason;
        final code = row.isBehaviour && _onBehaviour.contains(row.id)
            ? 'Expressive${row.id} · on ${row.behaviour}'
            : 'Expressive${row.id}';
        return KeyedSubtree(
          key: ValueKey<String>('inventory-${row.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: ExpressiveSpacing.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  row.name,
                  style: t.type.titleSmall.copyWith(color: c.onSurface),
                ),
                const SizedBox(height: ExpressiveSpacing.s2),
                Text(
                  _wordBreaks(code),
                  semanticsLabel: code,
                  style: t.type.labelMedium.copyWith(color: c.onSurfaceVariant),
                ),
                const SizedBox(height: ExpressiveSpacing.s12),
                if (specimen != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _specimenExtent,
                      maxHeight: _specimenExtent,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      widthFactor: 1,
                      heightFactor: 1,
                      child: specimen,
                    ),
                  )
                else
                  Text(
                    reason == null
                        ? 'Missing'
                        : DesignInventory.absentLabel(reason),
                    style: t.type.bodyMedium.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
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
        FlagProperty(
          'behaviourOnly',
          value: behaviourOnly,
          ifTrue: 'behaviourOnly',
        ),
      )
      ..add(
        DiagnosticsProperty<ScrollController?>(
          'controller',
          controller,
          defaultValue: null,
        ),
      );
  }
}

/// A code name breakable only where its next word starts (a zero-width
/// space there): `ExpressiveFloating|Action|Button` wraps between its words
/// in a narrow column or at large text, never inside one.
String _wordBreaks(String name) =>
    name.replaceAll(RegExp('(?<=[a-z0-9])(?=[A-Z])'), '\u200B');
