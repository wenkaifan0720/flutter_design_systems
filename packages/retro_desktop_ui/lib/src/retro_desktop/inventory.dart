// Retro Desktop's answer to the shared component inventory (ui_core's DesignInventoryRow.all, 89 rows): for each row the
// part that answers it, `RetroDesktop<Stem>`, as a small live specimen, or the reason the look leaves it out. The live
// gallery lists it, and a test verifies it (every row answered once, every specimen the row's own class).
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/inventory.dart';

import 'acts.dart';
import 'acts_more.dart';
import 'chart.dart';
import 'chart_set.dart';
import 'chrome.dart';
import 'controls.dart';
import 'entries.dart';
import 'fields_more.dart';
import 'glyphs.dart';
import 'heads.dart';
import 'holds_more.dart';
import 'layout.dart' show RetroDesktopColumn;
import 'moves.dart';
import 'pickers.dart';
import 'pickers_more.dart';
import 'raised.dart';
import 'raised_more.dart';
import 'rows.dart';
import 'show.dart';
import 'signatures/lists.dart';
import 'tell.dart';
import 'theme.dart';
import 'tone.dart';
import 'wayfinding.dart';

void _none() {}
void _drop(Object? _) {}

const _desk = RetroDesktopNavItem(
  label: 'Desktop',
  short: 'Desktop',
  icon: RetroDesktopGlyphs.folder,
);
const _mail = RetroDesktopNavItem(
  label: 'Mail',
  short: 'Mail',
  icon: RetroDesktopGlyphs.email,
);
const _bin = RetroDesktopNavItem(
  label: 'Trash',
  short: 'Trash',
  icon: RetroDesktopGlyphs.delete,
);

// The specimens' controllers: one gallery shows the inventory at a time, so each specimen keeps one for the app's life.
// A scroll controller is the exception: a page laid out again (a lazy list growing) can hold the old specimen and the new
// one for a frame, and one controller under both scroll views throws; each scroll area keeps its own (_OwnScroll).
final _day = DesignCalendarController(
  firstDate: DateTime(2026, 6),
  lastDate: DateTime(2026, 9, 30),
  selectedDate: DateTime(2026, 6, 14),
  currentDate: DateTime(2026, 6, 10),
);
// The colour picker's starts on the theme's highlight, the first time it is built.
DesignColorController? _colour;
final _files = DesignTableController<_File>(
  rows: const [_File('Budget', 12), _File('Letters', 48), _File('Notes', 3)],
  columns: [
    DesignTableColumn<_File>(id: 'name', label: 'Name', sortKey: (f) => f.name),
    DesignTableColumn<_File>(
      id: 'size',
      label: 'Size',
      numeric: true,
      sortKey: (f) => f.size,
    ),
  ],
);
final _folders = DesignTreeController<String>(
  roots: const ['System'],
  expanded: const ['System'],
  childrenOf: (n) => n == 'System' ? const ['Fonts', 'Sounds'] : const [],
);

class _File {
  const _File(this.name, this.size);
  final String name;
  final int size;
}

/// The specimens that fill the height they are given; a gallery frames each in a box of this height.
const Map<String, double> retroDesktopInventoryHeights = {
  'NavigationRail': 280,
  'NavigationDrawer': 320,
  'Scaffold': 260,
  'Sheet': 240,
  'Resizable': 160,
  'ScrollArea': 140,
};

const _absentSwipe =
    'Swiping a row aside isn\'t of the period, and nothing here slides; a '
    'row\'s actions go in its contextual menu or a menu button.';

const _absentCarousel =
    'Slides that move and play on their own aren\'t of the period; show one '
    'picture with Previous and Next and where you are.';

const _absentRefresh =
    'Pull to refresh is a phone\'s gesture the desktop never had; a Refresh '
    'command (a button or a menu item) shows the busy pointer while it works.';

const _absentHoverCard =
    'A card that opens on hover isn\'t of the period: Balloon Help showed words,'
    ' which is the tooltip; for more, a popover on a press.';

const _absentMultiSelect =
    'Tags with close boxes inside a field aren\'t of the period; several choices'
    ' are check rows in a sunken list.';

const _absentFab =
    'A button floating over the content isn\'t of the period; the window\'s '
    'default button, in its toolbar, does its job.';

const _absentWheel =
    'A wheel picker is a phone\'s; the period chose from a pop-up button.';

const _absentCommand =
    'A command palette came later; a 1990s desktop ran commands from its menu bar '
    'and their keys.';

/// Retro Desktop's inventory: every row of the shared component list, answered.
final DesignInventory retroDesktopInventory = DesignInventory(
  look: 'Retro Desktop',
  entries: [
    // Actions
    // Every kind the row names: the default (filled), a plain one (outlined), a quiet one (text) and a destructive one.
    DesignInventoryEntry.present(
      'Button',
      (_) => const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          RetroDesktopButton('Save', isDefaultAction: true, onPressed: _none),
          RetroDesktopButton('Cancel', onPressed: _none),
          // Room for the face a quiet button shows held, which stands out past its start by its padding.
          Padding(
            padding: EdgeInsetsDirectional.only(start: 10),
            child: RetroDesktopButton.text('More', onPressed: _none),
          ),
          RetroDesktopButton(
            'Delete',
            isDestructiveAction: true,
            onPressed: _none,
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'IconButton',
      (_) => const RetroDesktopIconButton(
        RetroDesktopGlyphs.search,
        label: 'Find',
        onPressed: _none,
      ),
    ),
    const DesignInventoryEntry.absent('FloatingActionButton', _absentFab),
    DesignInventoryEntry.present(
      'ButtonGroup',
      (_) => const RetroDesktopButtonGroup(
        label: 'Week',
        items: [
          RetroDesktopButtonGroupItem(label: 'Previous', onPressed: _none),
          RetroDesktopButtonGroupItem(label: 'Today', onPressed: _none),
          RetroDesktopButtonGroupItem(label: 'Next', onPressed: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'ToggleGroup',
      (_) => RetroDesktopToggleGroup<String>(
        label: 'Style',
        values: const ['Bold', 'Italic', 'Underline'],
        selected: const {'Bold'},
        labelOf: (v) => v,
        multiple: true,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'SplitButton',
      (_) => RetroDesktopSplitButton(
        label: 'Save',
        onPressed: _none,
        actions: [
          DesignSplitAction(label: 'Save as', onPressed: _none),
          DesignSplitAction(label: 'Save a copy', onPressed: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Link',
      (_) => const RetroDesktopLink('Read the manual', onPressed: _none),
    ),
    DesignInventoryEntry.present('Kbd', (_) => const RetroDesktopKbd('Ctrl+S')),
    // Inputs
    DesignInventoryEntry.present(
      'TextField',
      (_) => const RetroDesktopTextField(label: 'Name', hint: 'File name'),
    ),
    DesignInventoryEntry.present(
      'TextArea',
      (_) => const RetroDesktopTextArea(
        label: 'Notes',
        hint: 'Anything the next reader should know',
      ),
    ),
    DesignInventoryEntry.present(
      'SearchField',
      (_) => const RetroDesktopSearchField(hint: 'Search files'),
    ),
    DesignInventoryEntry.present(
      'PasswordField',
      (_) => RetroDesktopPasswordField(label: 'Password', onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'InputGroup',
      (_) => const RetroDesktopInputGroup(
        label: 'Site',
        prefix: 'https://',
        suffix: '.example.com',
        hint: 'studio',
      ),
    ),
    DesignInventoryEntry.present(
      'InputOtp',
      (_) => const RetroDesktopInputOtp(label: 'Verification code', length: 6),
    ),
    DesignInventoryEntry.present(
      'NumberField',
      (_) => const RetroDesktopNumberField(
        label: 'Copies',
        value: 2,
        min: 1,
        max: 9,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Select',
      (_) => const RetroDesktopSelect<String>(
        label: 'Paper',
        value: 'a4',
        options: [
          RetroDesktopOption('a4', 'A4'),
          RetroDesktopOption('letter', 'Letter'),
        ],
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Combobox',
      (_) => const RetroDesktopCombobox<String>(
        label: 'Country',
        hint: 'Type a country',
        options: ['Austria', 'Belgium', 'Chile', 'Denmark'],
        onSelected: _drop,
      ),
    ),
    const DesignInventoryEntry.absent('MultiSelect', _absentMultiSelect),
    DesignInventoryEntry.present(
      'Checkbox',
      (_) => const RetroDesktopCheckbox(
        label: 'Keep a backup',
        value: true,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'RadioGroup',
      (_) => const RetroDesktopRadioGroup<String>(
        label: 'Paper',
        value: 'a4',
        options: [
          RetroDesktopRadio('a4', 'A4'),
          RetroDesktopRadio('letter', 'Letter'),
        ],
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Switch',
      (_) => const RetroDesktopSwitch(
        label: 'Sound',
        value: true,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Slider',
      (_) => const RetroDesktopSlider(
        label: 'Volume',
        value: .6,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'RangeSlider',
      (_) => const RetroDesktopRangeSlider(
        label: 'Price',
        values: DesignRangeValues(20, 80),
        max: 100,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'SegmentedButton',
      (_) => const RetroDesktopSegmentedButton<String>(
        label: 'View',
        value: 'list',
        segments: [
          RetroDesktopButtonSegment('icons', 'Icons'),
          RetroDesktopButtonSegment('list', 'List'),
        ],
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Chip',
      (_) => const RetroDesktopChip('Drafts', onPressed: _none),
    ),
    DesignInventoryEntry.present(
      'Rating',
      (_) => const RetroDesktopRating(
        label: 'Your rating',
        value: 4,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'FileUpload',
      (_) => const RetroDesktopFileUpload(
        label: 'Attachments',
        onChoose: _none,
        files: ['notes.txt'],
        onRemove: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'DatePicker',
      (_) => RetroDesktopDatePicker(
        value: DateTime(2026, 6, 14),
        first: DateTime(2026, 6),
        last: DateTime(2026, 9, 30),
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'DateRangePicker',
      (_) => RetroDesktopDateRangePicker(
        label: 'Stay',
        firstDate: DateTime(2026, 6),
        lastDate: DateTime(2026, 9, 30),
        initialMonth: DateTime(2026, 6),
        value: DesignDateRange(DateTime(2026, 6, 14), DateTime(2026, 6, 18)),
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'TimePicker',
      (_) => const RetroDesktopTimePicker(
        value: RetroDesktopTime(9, 30),
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Calendar',
      (_) => RetroDesktopCalendar(controller: _day),
    ),
    const DesignInventoryEntry.absent('WheelPicker', _absentWheel),
    DesignInventoryEntry.present(
      'ColorPicker',
      (context) => RetroDesktopColorPicker(
        controller: _colour ??= DesignColorController(
          RetroDesktopTheme.of(context).colors.highlight,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'FormField',
      (_) => const RetroDesktopFormField(
        label: 'Email',
        help: 'The receipt goes here',
        required: true,
        child: RetroDesktopTextField(hint: 'name@example.com'),
      ),
    ),
    // Navigation
    DesignInventoryEntry.present(
      'AppBar',
      (_) => const RetroDesktopAppBar(title: 'Documents'),
    ),
    DesignInventoryEntry.present(
      'NavigationBar',
      (_) => const RetroDesktopNavigationBar(
        items: [_desk, _mail, _bin],
        onDestinationSelected: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationRail',
      (_) => const RetroDesktopNavigationRail(
        label: 'Places',
        items: [_desk, _mail, _bin],
        onDestinationSelected: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationDrawer',
      (_) => const RetroDesktopNavigationDrawer(
        label: 'Places',
        items: [_desk, _mail, _bin],
        onDestinationSelected: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'TabBar',
      (_) => const RetroDesktopTabBar(
        label: 'Settings',
        tabs: ['General', 'Sharing', 'Memory'],
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Breadcrumb',
      (_) => const RetroDesktopBreadcrumb(
        items: [
          RetroDesktopBreadcrumbItem('Disk', onPressed: _none),
          RetroDesktopBreadcrumbItem('Documents', onPressed: _none),
          RetroDesktopBreadcrumbItem('Letters'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Pagination',
      (_) => const RetroDesktopPagination(count: 5, page: 1, onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'StepProgress',
      (_) => const RetroDesktopStepProgress(
        count: 4,
        currentStep: 1,
        name: 'Details',
      ),
    ),
    DesignInventoryEntry.present(
      'PageDots',
      (_) => const RetroDesktopPageDots(
        count: 4,
        selectedIndex: 1,
        label: 'Pages',
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'MenuBar',
      (_) => RetroDesktopMenuBar(
        menus: [
          DesignMenuEntry(
            label: 'File',
            children: [
              DesignMenuEntry(label: 'New', onPressed: _none),
              DesignMenuEntry(label: 'Open', onPressed: _none),
            ],
          ),
          DesignMenuEntry(
            label: 'Edit',
            children: [DesignMenuEntry(label: 'Undo', onPressed: _none)],
          ),
        ],
      ),
    ),
    const DesignInventoryEntry.absent('Command', _absentCommand),
    // Layout
    DesignInventoryEntry.present(
      'Scaffold',
      (_) => const RetroDesktopScaffold(
        scroll: false,
        topBar: RetroDesktopAppBar(title: 'Documents'),
        body: Center(child: Text('Four items')),
      ),
    ),
    DesignInventoryEntry.present(
      'Card',
      (_) => const RetroDesktopCard(
        title: 'Disk',
        child: Text('40 MB free of 80 MB'),
      ),
    ),
    DesignInventoryEntry.present(
      'ListTile',
      (_) => const RetroDesktopListTile(
        title: 'Budget',
        subtitle: '12 KB',
        onPressed: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'ListSection',
      (_) => const RetroDesktopListSection(
        title: 'Recent',
        children: [
          RetroDesktopListTile(
            title: 'Budget',
            onPressed: _none,
            isFirst: true,
          ),
          RetroDesktopListTile(title: 'Letters', onPressed: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'SectionHeader',
      (_) => const RetroDesktopSectionHeader('Recent files', note: 'Today'),
    ),
    DesignInventoryEntry.present(
      'Disclosure',
      (_) => const RetroDesktopDisclosure(
        title: 'Advanced',
        initiallyExpanded: true,
        child: Text('Memory and start-up disk'),
      ),
    ),
    DesignInventoryEntry.present(
      'Table',
      (_) => const RetroDesktopTable(
        columns: [
          RetroDesktopTableColumn('Name'),
          RetroDesktopTableColumn('Size', figures: true, end: true),
        ],
        rows: [
          ['Budget', '12 KB'],
          ['Letters', '48 KB'],
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'DataTable',
      (_) => RetroDesktopDataTable<_File>(
        controller: _files,
        cellText: (f, column) => column.id == 'name' ? f.name : '${f.size} KB',
      ),
    ),
    DesignInventoryEntry.present('Divider', (_) => const RetroDesktopDivider()),
    DesignInventoryEntry.present(
      'ScrollArea',
      (_) => _OwnScroll(
        (scroll) => RetroDesktopScrollArea(
          controller: scroll,
          label: 'Files',
          child: ListView(
            controller: scroll,
            children: [
              for (var i = 1; i <= 12; i++)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text('Document $i'),
                ),
            ],
          ),
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Resizable',
      (_) => const RetroDesktopResizable(
        minFirst: 60,
        minSecond: 60,
        first: Center(child: Text('Folders')),
        second: Center(child: Text('Files')),
      ),
    ),
    const DesignInventoryEntry.absent('CarouselView', _absentCarousel),
    DesignInventoryEntry.present(
      'ReorderableListView',
      (_) => RetroDesktopReorderableListView<String>(
        items: const ['Fonts', 'Sounds', 'Scripts'],
        labelOf: (s) => s,
        itemBuilder: (context, s) => Text(s),
        onReorder: (from, to) {},
      ),
    ),
    const DesignInventoryEntry.absent('SwipeActions', _absentSwipe),
    const DesignInventoryEntry.absent('RefreshIndicator', _absentRefresh),
    DesignInventoryEntry.present(
      'TreeView',
      (_) => RetroDesktopTreeView<String>(
        label: 'Folders',
        controller: _folders,
        labelOf: (n) => n,
      ),
    ),
    DesignInventoryEntry.present(
      'Timeline',
      (_) => const RetroDesktopTimeline(
        entries: [
          RetroDesktopTimelineEntry('Ordered', time: '9:02', done: true),
          RetroDesktopTimelineEntry('Packed', current: true),
          RetroDesktopTimelineEntry('Delivered'),
        ],
      ),
    ),
    // Display
    DesignInventoryEntry.present(
      'Avatar',
      (_) => const RetroDesktopAvatar('AL', name: 'Alex Lee'),
    ),
    DesignInventoryEntry.present(
      'AvatarGroup',
      (_) => const RetroDesktopAvatarGroup(
        children: [
          RetroDesktopAvatar('AL', name: 'Alex Lee'),
          RetroDesktopAvatar('JM', name: 'Jo Morgan'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Badge',
      (_) => const RetroDesktopBadge(3, label: 'Three unread'),
    ),
    DesignInventoryEntry.present(
      'Tag',
      (_) => const RetroDesktopTag('Draft', icon: RetroDesktopGlyphs.tag),
    ),
    DesignInventoryEntry.present(
      'Media',
      (_) => const RetroDesktopMedia(
        slotId: 'desk-photo',
        label: 'The desk',
        aspect: 16 / 9,
      ),
    ),
    DesignInventoryEntry.present(
      'EmptyState',
      (_) => const RetroDesktopEmptyState(
        title: 'No documents',
        message: 'A new document appears here.',
      ),
    ),
    DesignInventoryEntry.present(
      'DescriptionList',
      (_) => const RetroDesktopDescriptionList([
        RetroDesktopFact('Kind', 'Document'),
        RetroDesktopFact('Size', '12 KB'),
      ]),
    ),
    // Raised
    DesignInventoryEntry.present(
      'Dialog',
      (_) => const RetroDesktopDialog(
        title: 'Save changes?',
        message: 'Your changes are lost if you don\'t save them.',
        actions: [
          RetroDesktopButton(
            'Save',
            wide: true,
            isDefaultAction: true,
            onPressed: _none,
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'BottomSheet',
      (_) => const RetroDesktopBottomSheet(
        title: 'Share',
        inPlace: true,
        child: Text('Anyone with the link can read it.'),
      ),
    ),
    DesignInventoryEntry.present(
      'Sheet',
      (_) => const RetroDesktopSheet(
        title: 'Filters',
        onClose: _none,
        child: Text('Kind and date'),
      ),
    ),
    DesignInventoryEntry.present(
      'ActionSheet',
      (_) => RetroDesktopActionSheet(
        title: 'Budget',
        actions: [
          RetroDesktopActionSheetAction('Duplicate', onPressed: _none),
          RetroDesktopActionSheetAction(
            'Delete',
            destructive: true,
            onPressed: _none,
          ),
        ],
        cancelLabel: 'Cancel',
        onCancel: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'Popover',
      (_) => RetroDesktopPopover(
        label: 'Share',
        content: (context) => const Text('Anyone with the link can read it.'),
      ),
    ),
    const DesignInventoryEntry.absent('HoverCard', _absentHoverCard),
    DesignInventoryEntry.present(
      'Tooltip',
      (_) => const RetroDesktopTooltip(
        message: 'Find a document',
        child: RetroDesktopIconButton(
          RetroDesktopGlyphs.search,
          label: 'Find',
          onPressed: _none,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Menu',
      (_) => const RetroDesktopMenu<String>(
        label: 'File',
        items: [
          RetroDesktopMenuItem('open', 'Open'),
          RetroDesktopMenuItem('close', 'Close'),
        ],
        onSelected: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'SnackBar',
      (_) => const RetroDesktopSnackBar(
        'Saved to Documents',
        actionLabel: 'Undo',
        onAction: _none,
        onDismissed: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'Banner',
      (_) => const RetroDesktopBanner(
        title: 'The disk is almost full',
        tone: RetroDesktopTone.warning,
      ),
    ),
    // Feedback
    DesignInventoryEntry.present(
      'LinearProgressIndicator',
      (_) => const RetroDesktopLinearProgressIndicator(
        value: .6,
        label: 'Copying',
      ),
    ),
    DesignInventoryEntry.present(
      'CircularProgressIndicator',
      (_) => const RetroDesktopCircularProgressIndicator(
        value: .6,
        label: 'Copying',
      ),
    ),
    DesignInventoryEntry.present(
      'Skeleton',
      (_) => const RetroDesktopSkeleton(label: 'Loading documents'),
    ),
    DesignInventoryEntry.present(
      'StatusView',
      (_) => RetroDesktopStatusView(
        status: RetroDesktopStatus.error,
        title: 'Could not load',
        onRetry: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'Meter',
      (_) => const RetroDesktopMeter(label: 'Disk', value: .7),
    ),
    // Charts
    DesignInventoryEntry.present(
      'LineChart',
      (_) => RetroDesktopLineChart(
        label: 'Visits',
        height: 140,
        labels: const ['Mon', 'Tue', 'Wed', 'Thu'],
        series: [
          RetroDesktopChartSeries('Visits', const [9, 15, 22, 12]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'BarChart',
      (_) => RetroDesktopBarChart(
        label: 'Files',
        height: 140,
        labels: const ['Mon', 'Tue', 'Wed', 'Thu'],
        series: [
          RetroDesktopChartSeries('Documents', const [4, 8, 6, 12]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'AreaChart',
      (_) => RetroDesktopAreaChart(
        label: 'Disk used',
        height: 140,
        labels: const ['Jan', 'Feb', 'Mar', 'Apr'],
        series: [
          RetroDesktopChartSeries('Disk used', const [12, 15, 21, 24]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'PieChart',
      (_) => RetroDesktopPieChart(
        label: 'Storage',
        height: 140,
        labels: const ['Documents', 'Pictures', 'Other'],
        series: [
          RetroDesktopChartSeries('Storage', const [52, 28, 20]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Sparkline',
      (_) =>
          const RetroDesktopSparkline(label: 'Visits', values: [4, 6, 5, 9, 8]),
    ),
  ],
);

/// Retro Desktop's inventory, listed: each group under its heading with how many of its rows the look carries, then
/// each row in a card, its class and what a person calls it over its live specimen, or the reason the look leaves it
/// out. It scrolls itself, so it fills a screen that does not scroll (RetroDesktopScaffold(scroll: false)).
///
/// ```dart
/// RetroDesktopScaffold(scroll: false, topBar: const RetroDesktopAppBar(title: 'Components'), body: const RetroDesktopInventoryGallery())
/// ```
class RetroDesktopInventoryGallery extends StatelessWidget {
  /// Creates a [RetroDesktopInventoryGallery].
  const RetroDesktopInventoryGallery({
    super.key,
    this.controller,
    this.padding = const EdgeInsetsDirectional.fromSTEB(16, 8, 32, 32),
  });

  /// The list's scroll controller.
  final ScrollController? controller;

  /// Space around the list. The scroll bar (16 wide) stands over its end: the default keeps 16 clear of it (the cards
  /// stood against the bar, their edge doubling the track's).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final own = controller;
    // The period's scroll bar beside the list, as every window that holds more than it shows has one.
    if (own == null) return _OwnScroll((scroll) => _list(context, scroll));
    return _list(context, own);
  }

  Widget _list(BuildContext context, ScrollController scroll) =>
      RetroDesktopScrollArea(
        controller: scroll,
        label: 'Components',
        child: _gallery(context, scroll),
      );

  Widget _gallery(BuildContext context, ScrollController scroll) {
    final t = RetroDesktopTheme.of(context);
    return DesignInventoryGallery(
      inventory: retroDesktopInventory,
      controller: scroll,
      padding: padding,
      groupBuilder: (context, group, live, total) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: RetroDesktopSectionHeader(group, note: '$live of $total'),
      ),
      rowBuilder: (context, row, entry, specimen) {
        final height = retroDesktopInventoryHeights[row.id];
        final sized = specimen == null || height == null
            ? specimen
            : SizedBox(height: height, child: specimen);
        // The specimen's class (type arguments aside), or the row's name
        // where Retro Desktop has none or a release build has minified the
        // class's ("minified:vU"). A row shown as several of one class
        // (the Button row's four kinds) names that class.
        final kind = row.id == 'Button'
            ? 'RetroDesktopButton'
            : '${specimen.runtimeType}'.split('<').first;
        final title = specimen == null || kind.startsWith('minified:')
            ? row.name
            : kind;
        return KeyedSubtree(
          key: ValueKey<String>('inventory-${row.id}'),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RetroDesktopCard(
              child: RetroDesktopColumn(
                gap: 12,
                children: [
                  // The card's title. A class name has no space to break
                  // at: a narrow card shrinks it onto one line instead.
                  // Words wrap at their size (shrunk, a long row name stood
                  // smaller than its neighbours' titles).
                  Semantics(
                    container: true,
                    header: true,
                    child: title.contains(' ')
                        ? Text(title, style: t.type.sub)
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(title, style: t.type.sub),
                          ),
                  ),
                  RetroDesktopColumn(
                    gap: 8,
                    children: [
                      if (title != row.name) ...[
                        Text(row.name, style: t.type.meta),
                        const SizedBox(height: 8),
                      ],
                      sized ??
                          Text(
                            entry?.absentReason != null
                                ? DesignInventory.absentLabel(
                                    entry!.absentReason!,
                                  )
                                : 'Missing: the inventory does not answer '
                                      'this row',
                            style: t.type.body,
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// A scroll view's own controller, made and disposed with it.
class _OwnScroll extends StatefulWidget {
  const _OwnScroll(this.builder);
  final Widget Function(ScrollController scroll) builder;
  @override
  State<_OwnScroll> createState() => _OwnScrollState();
}

class _OwnScrollState extends State<_OwnScroll> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_scroll);
}
