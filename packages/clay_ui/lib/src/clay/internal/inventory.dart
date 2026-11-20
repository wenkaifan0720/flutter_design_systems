/// Live examples of the Clay parts in [DesignInventoryRow.all]: each one
/// answers to its keys, pointer and screen reader as it will in an app.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../actions.dart';
import '../button.dart';
import '../charts.dart';
import '../choices.dart';
import '../collections.dart';
import '../display.dart';
import '../entry.dart';
import '../feedback.dart';
import '../lists.dart';
import '../navigation.dart';
import '../overlays.dart';
import '../pickers.dart';
import '../popovers.dart';
import '../select.dart';
import '../selection.dart';
import '../text_field.dart';
import '../theme.dart';
import '../wayfinding.dart';

void _none() {}

const _places = [
  ClayDestination(icon: LucideIcons.sun, label: 'Today'),
  ClayDestination(icon: LucideIcons.listChecks, label: 'Habits'),
  ClayDestination(icon: LucideIcons.chartColumn, label: 'Progress'),
];

final _first = DateTime(2026);
final _last = DateTime(2027, 12, 31);

DesignInventoryEntry _row(String id, WidgetBuilder builder) =>
    DesignInventoryEntry.present(id, builder);

/// A value an example keeps, so it answers as it will in an app.
class _Live<T> extends StatefulWidget {
  const _Live(this.initial, this.builder);

  final T initial;
  final Widget Function(BuildContext context, T value, ValueChanged<T> set)
  builder;

  @override
  State<_Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<_Live<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _value, (next) => setState(() => _value = next));
}

/// The component examples in the Clay inventory.
abstract final class ClayInventory {
  /// Component rows with their example builders and availability.
  static final DesignInventory registry = _registry();
}

DesignInventory _registry() => DesignInventory(
  look: 'Clay',
  entries: [
    // Actions.
    _row(
      'Button',
      (_) => const ClayButton.filled('Add habit', onPressed: _none),
    ),
    _row(
      'IconButton',
      (_) => const ClayIconButton(
        onPressed: _none,
        icon: Icon(LucideIcons.pencil),
        tooltip: 'Edit',
      ),
    ),
    const DesignInventoryEntry.absent(
      'FloatingActionButton',
      "Clay's one action is the coral ball at the dock's end",
    ),
    _row(
      'ButtonGroup',
      (_) => const ClayButtonGroup(
        items: [
          ClayButtonGroupItem(label: 'Skip', onPressed: _none),
          ClayButtonGroupItem(label: 'Snooze', onPressed: _none),
        ],
      ),
    ),
    _row(
      'ToggleGroup',
      (_) => _Live<Set<String>>(
        const {'m'},
        (context, on, set) => ClayToggleGroup<String>(
          toggles: const [
            ClayToggle(value: 'm', label: 'Morning'),
            ClayToggle(value: 'a', label: 'Afternoon'),
            ClayToggle(value: 'e', label: 'Evening'),
          ],
          selected: on,
          onSelectionChanged: set,
        ),
      ),
    ),
    _row(
      'SplitButton',
      (_) => const ClaySplitButton(
        label: 'Log it',
        onPressed: _none,
        actions: [
          ClaySplitAction(label: 'Log for yesterday', onPressed: _none),
        ],
      ),
    ),
    _row('Link', (_) => const ClayLink('See all habits', onPressed: _none)),
    _row(
      'Kbd',
      (_) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClayKbd('Ctrl'),
          SizedBox(width: ClaySpacing.tight),
          ClayKbd('K'),
        ],
      ),
    ),
    // Inputs.
    _row('TextField', (_) => const ClayTextField(label: 'Habit name')),
    _row('TextArea', (_) => const ClayTextArea(label: 'Note')),
    _row('SearchField', (_) => const ClaySearchField(hint: 'Search habits')),
    _row('PasswordField', (_) => const ClayPasswordField(label: 'Password')),
    _row(
      'InputGroup',
      (_) => const ClayInputGroup(label: 'Goal', suffixText: 'glasses'),
    ),
    _row('InputOtp', (_) => const ClayOtpField(semanticLabel: 'Code')),
    _row(
      'NumberField',
      (_) => _Live<double>(
        8,
        (context, n, set) => ClayNumberField(
          value: n,
          min: 1,
          max: 20,
          onChanged: (v) => set(v ?? n),
          semanticLabel: 'Glasses a day',
        ),
      ),
    ),
    _row(
      'Select',
      (_) => _Live<String>(
        'daily',
        (context, v, set) => ClaySelect<String>(
          label: 'Repeat',
          value: v,
          items: const [
            ClaySelectItem(value: 'daily', label: 'Every day'),
            ClaySelectItem(value: 'weekdays', label: 'Weekdays'),
            ClaySelectItem(value: 'weekly', label: 'Once a week'),
          ],
          onChanged: set,
        ),
      ),
    ),
    _row(
      'Combobox',
      (_) => const ClayCombobox<String>(
        label: 'Category',
        options: ['Health', 'Mind', 'Home', 'Work'],
      ),
    ),
    _row(
      'MultiSelect',
      (_) => _Live<List<String>>(
        const ['Morning'],
        (context, tags, set) => ClayTagInput<String>(
          label: 'Tags',
          values: tags,
          options: const ['Morning', 'Outdoors', 'Quick', 'With friends'],
          onChanged: set,
        ),
      ),
    ),
    _row(
      'Checkbox',
      (_) => _Live<bool?>(
        true,
        (context, v, set) =>
            ClayCheckbox(value: v, onChanged: set, semanticLabel: 'Done'),
      ),
    ),
    _row(
      'RadioGroup',
      (_) => _Live<String>(
        'morning',
        (context, v, set) => ClayRadioGroup<String>(
          options: const ['morning', 'evening'],
          value: v,
          labelOf: (o) => o == 'morning' ? 'Morning' : 'Evening',
          onChanged: set,
        ),
      ),
    ),
    _row(
      'Switch',
      (_) => _Live<bool>(
        true,
        (context, v, set) =>
            ClaySwitch(value: v, onChanged: set, semanticLabel: 'Reminders'),
      ),
    ),
    _row(
      'Slider',
      (_) => _Live<double>(
        0.6,
        (context, v, set) =>
            ClaySlider(value: v, onChanged: set, semanticLabel: 'Volume'),
      ),
    ),
    _row(
      'RangeSlider',
      (_) => _Live<ClayRangeValues>(
        const ClayRangeValues(6, 9),
        (context, v, set) => ClayRangeSlider(
          values: v,
          min: 5,
          max: 12,
          divisions: 7,
          onChanged: set,
        ),
      ),
    ),
    _row(
      'SegmentedButton',
      (_) => _Live<String>(
        'week',
        (context, v, set) => ClaySegmentedButton<String>(
          segments: const [
            ClaySegment(value: 'week', label: 'Week'),
            ClaySegment(value: 'month', label: 'Month'),
            ClaySegment(value: 'year', label: 'Year'),
          ],
          selected: v,
          onChanged: set,
        ),
      ),
    ),
    _row(
      'Chip',
      (_) => _Live<bool>(
        true,
        (context, v, set) =>
            ClayChip(label: 'Morning', selected: v, onSelected: set),
      ),
    ),
    _row(
      'Rating',
      (_) => _Live<double>(
        4,
        (context, v, set) => ClayRating(
          value: v,
          onChanged: set,
          semanticLabel: 'How the week felt',
        ),
      ),
    ),
    _row(
      'FileUpload',
      (_) => const ClayFileDrop(
        label: 'Photo',
        hint: 'A picture for this habit, up to 5 MB',
        onChoose: _none,
      ),
    ),
    _row(
      'DatePicker',
      (_) => _Live<DateTime?>(
        DateTime(2026, 11, 23),
        (context, v, set) => ClayDatePicker(
          label: 'Starts on',
          value: v,
          firstDate: _first,
          lastDate: _last,
          onChanged: set,
        ),
      ),
    ),
    _row(
      'DateRangePicker',
      (_) => _Live<ClayDateRange?>(
        null,
        (context, v, set) => ClayDateRangePicker(
          label: 'A break',
          value: v,
          firstDate: _first,
          lastDate: _last,
          onChanged: set,
        ),
      ),
    ),
    _row(
      'TimePicker',
      (_) => _Live<ClayTime?>(
        const ClayTime(hour: 7, minute: 30),
        (context, v, set) =>
            ClayTimeField(label: 'Remind me at', value: v, onChanged: set),
      ),
    ),
    _row(
      'Calendar',
      (_) => _Live<DateTime?>(
        DateTime(2026, 11, 19),
        (context, v, set) => ClayCalendar(
          firstDate: _first,
          lastDate: _last,
          selectedDate: v,
          currentDate: DateTime(2026, 11, 19),
          onDateChanged: set,
        ),
      ),
    ),
    _row(
      'WheelPicker',
      (_) => _Live<int>(
        10,
        (context, v, set) => ClayWheelPicker<int>(
          items: const [5, 10, 15, 20, 30, 45],
          value: v,
          labelOf: (n) => '$n min',
          onChanged: set,
          semanticLabel: 'Duration',
        ),
      ),
    ),
    _row(
      'ColorPicker',
      (_) => _Live<Color>(
        const Color(0xFFF08A6B),
        (context, v, set) => ClayColorPicker(value: v, onChanged: set),
      ),
    ),
    _row(
      'FormField',
      (_) => _Live<bool>(
        true,
        (context, v, set) => ClayFormField(
          labelText: 'Reminders',
          helperText: 'A nudge at its time',
          child: ClaySwitch(value: v, onChanged: set),
        ),
      ),
    ),
    // Navigation.
    _row('AppBar', (_) => const ClayTopBar(title: 'Habits')),
    _row(
      'NavigationBar',
      (_) => _Live<int>(
        0,
        (context, i, set) => ClayNavigationBar(
          destinations: _places,
          selectedIndex: i,
          onSelected: set,
        ),
      ),
    ),
    _row(
      'NavigationRail',
      (_) => SizedBox(
        height: 320,
        child: _Live<int>(
          0,
          (context, i, set) => ClayNavigationRail(
            destinations: _places,
            selectedIndex: i,
            onSelected: set,
          ),
        ),
      ),
    ),
    _row(
      'NavigationDrawer',
      (_) => SizedBox(
        height: 320,
        child: _Live<int>(
          0,
          (context, i, set) => ClaySidebar(
            destinations: _places,
            selectedIndex: i,
            onSelected: set,
          ),
        ),
      ),
    ),
    _row(
      'TabBar',
      (_) => _Live<int>(
        0,
        (context, i, set) => ClayTabBar(
          tabs: const ['Week', 'Month', 'Year'],
          selectedIndex: i,
          onSelected: set,
        ),
      ),
    ),
    _row(
      'Breadcrumb',
      (_) => const ClayBreadcrumb(
        crumbs: [
          ClayCrumb(label: 'Habits', onPressed: _none),
          ClayCrumb(label: 'Drink water'),
        ],
      ),
    ),
    _row(
      'Pagination',
      (_) => _Live<int>(
        3,
        (context, p, set) => ClayPagination(page: p, count: 12, onChanged: set),
      ),
    ),
    _row(
      'StepProgress',
      (_) => const ClayStepProgress(
        steps: ['Habit', 'Schedule', 'Reminder'],
        current: 1,
      ),
    ),
    _row(
      'PageDots',
      (_) => _Live<int>(
        1,
        (context, i, set) => ClayPageDots(count: 4, index: i, onChanged: set),
      ),
    ),
    _row(
      'MenuBar',
      (_) => const ClayMenuBar(
        menus: [
          ClayMenuBarMenu(
            label: 'Habit',
            items: [
              ClayMenuItem(label: 'New habit', onPressed: _none),
              ClayMenuItem(label: 'Archive', onPressed: _none),
            ],
          ),
          ClayMenuBarMenu(
            label: 'View',
            items: [ClayMenuItem(label: 'Show archived', onPressed: _none)],
          ),
        ],
      ),
    ),
    _row(
      'Command',
      (_) => const SizedBox(
        height: 320,
        child: ClayCommandPalette(
          commands: [
            ClayCommand(
              label: 'New habit',
              onPressed: _none,
              icon: LucideIcons.plus,
            ),
            ClayCommand(
              label: 'Log water',
              onPressed: _none,
              icon: LucideIcons.glassWater,
            ),
            ClayCommand(
              label: 'Settings',
              onPressed: _none,
              icon: LucideIcons.settings,
            ),
          ],
        ),
      ),
    ),
    _row(
      'Scaffold',
      (_) => SizedBox(
        height: 360,
        child: _Live<int>(
          0,
          (context, i, set) => ClayScaffold(
            topBar: const ClayTopBar(title: 'Today'),
            destinations: _places,
            selectedIndex: i,
            onSelected: set,
            body: const SizedBox.expand(),
          ),
        ),
      ),
    ),
    // Containers.
    _row('Card', (_) => const ClayCard(child: Text('Drink water, 6 of 8'))),
    _row(
      'ListTile',
      (_) => const ClayListTile(
        title: 'Reminders',
        subtitle: 'Every day at 8:00',
        onTap: _none,
      ),
    ),
    _row(
      'ListSection',
      (_) => const ClayGroup(
        header: 'Reminders',
        children: [
          ClayListTile(title: 'Morning check-in', trailingText: '8:00'),
          ClayListTile(title: 'Evening review', trailingText: '21:00'),
        ],
      ),
    ),
    _row('SectionHeader', (_) => const ClaySectionHeader('Morning')),
    _row(
      'Disclosure',
      (_) => const ClayDisclosure(
        title: 'Why it matters',
        child: Text('A glass before coffee sets the day.'),
      ),
    ),
    _row(
      'Table',
      (_) => const ClayTable(
        columns: [
          ClayTableColumn('Habit', flex: 2),
          ClayTableColumn('Streak', numeric: true),
        ],
        rows: [
          ['Drink water', '12'],
          ['Read', '4'],
        ],
      ),
    ),
    _row('DataTable', (_) => const _DataTableSpecimen()),
    _row('Divider', (_) => const ClayGroove()),
    _row('ScrollArea', (_) => const _ScrollSpecimen()),
    _row(
      'Resizable',
      (_) => const SizedBox(
        height: 200,
        child: ClaySplitView(
          first: Center(child: Text('Habits')),
          second: Center(child: Text('Drink water')),
        ),
      ),
    ),
    _row(
      'CarouselView',
      (_) => ClayCarousel(
        itemCount: 3,
        itemBuilder: (context, i) => Center(child: Text('Tip ${i + 1}')),
      ),
    ),
    _row('ReorderableListView', (_) => const _ReorderSpecimen()),
    _row(
      'SwipeActions',
      (_) => const ClaySwipeRow(
        endActions: [
          ClaySwipeAction(
            label: 'Delete',
            onPressed: _none,
            isDestructiveAction: true,
          ),
        ],
        child: ClayListTile(title: 'Drink water'),
      ),
    ),
    _row(
      'RefreshIndicator',
      (_) => SizedBox(
        height: 200,
        child: ClayPullToRefresh(
          onRefresh: () async {},
          child: ListView(
            children: const [
              ClayListTile(title: 'Drink water'),
              ClayListTile(title: 'Read'),
            ],
          ),
        ),
      ),
    ),
    _row('TreeView', (_) => const _TreeSpecimen()),
    _row(
      'Timeline',
      (_) => const ClayTimeline(
        entries: [
          ClayTimelineEntry(title: 'Started Drink water', time: '2 Nov'),
          ClayTimelineEntry(title: 'First week kept', time: '9 Nov'),
          ClayTimelineEntry(title: 'Thirty days', time: '2 Dec', done: false),
        ],
      ),
    ),
    _row('Avatar', (_) => const ClayAvatar(name: 'Mia Okafor')),
    _row(
      'AvatarGroup',
      (_) => const ClayAvatarGroup(
        avatars: [
          ClayAvatar(name: 'Mia Okafor'),
          ClayAvatar(name: 'Sam Lee'),
          ClayAvatar(name: 'Ana Ruiz'),
          ClayAvatar(name: 'Tom Berg'),
          ClayAvatar(name: 'Ida Holm'),
        ],
      ),
    ),
    _row(
      'Badge',
      (_) => const ClayBadge(count: 3, child: Icon(LucideIcons.bell, size: 24)),
    ),
    _row('Tag', (_) => const ClayTag('Morning', tone: ClayTagTone.accent)),
    _row(
      'Media',
      (_) => const SizedBox(
        width: 280,
        child: ClayMedia(image: null, semanticLabel: 'A path through birches'),
      ),
    ),
    _row(
      'EmptyState',
      (_) => const ClayStateView(
        state: ClayState.empty,
        title: 'No habits yet',
        message: 'Start with one small thing.',
      ),
    ),
    _row(
      'DescriptionList',
      (_) => const ClayDescriptionList(
        entries: [
          ClayDescription('Started', '2 November'),
          ClayDescription('Best streak', '21 days'),
        ],
      ),
    ),
    // Overlays.
    _row(
      'Dialog',
      // At rest, a picture: its keys take no focus from the page.
      (_) => const ExcludeFocus(
        child: ClayDialog(
          title: 'Delete this habit?',
          content: Text('Its 42-day streak goes with it.'),
          actions: [
            ClayDialogAction(label: 'Keep', onPressed: _none),
            ClayDialogAction(
              label: 'Delete',
              onPressed: _none,
              primary: true,
              destructive: true,
            ),
          ],
        ),
      ),
    ),
    _row(
      'BottomSheet',
      (context) => ClayButton(
        'Reminder time',
        onPressed: () => showClayBottomSheet<void>(
          context: context,
          title: 'Reminder time',
          builder: (context) => const Text('8:00'),
        ),
      ),
    ),
    _row(
      'Sheet',
      (context) => ClayButton(
        'Filters',
        onPressed: () => showClaySideSheet<void>(
          context: context,
          title: 'Filters',
          builder: (context) => const Text('Every habit'),
        ),
      ),
    ),
    _row(
      'ActionSheet',
      (context) => ClayButton(
        'Habit actions',
        onPressed: () => showClayActionSheet<String>(
          context: context,
          title: 'Drink water',
          actions: const [
            ClaySheetAction(label: 'Pause', value: 'pause'),
            ClaySheetAction(
              label: 'Delete',
              value: 'delete',
              isDestructiveAction: true,
            ),
          ],
        ),
      ),
    ),
    _row(
      'Popover',
      (_) => ClayPopover(
        builder: (context, toggle, open) =>
            ClayButton('Streak', onPressed: toggle),
        content: (context, close) => const Text('Twelve days running'),
      ),
    ),
    _row(
      'HoverCard',
      (_) => ClayHoverCard(
        content: (context) => const Text('Mia, a 41-day streak'),
        child: const ClayLink('Mia', onPressed: _none),
      ),
    ),
    _row(
      'Tooltip',
      (_) => const ClayTooltip(
        message: 'Edit',
        child: ClayIconButton(
          onPressed: _none,
          icon: Icon(LucideIcons.pencil),
          tooltip: 'Edit',
        ),
      ),
    ),
    _row(
      'Menu',
      (_) => ClayMenu(
        items: const [
          ClayMenuItem(label: 'Edit', onPressed: _none),
          ClayMenuItem(
            label: 'Delete',
            onPressed: _none,
            isDestructiveAction: true,
          ),
        ],
        builder: (context, toggle, open) =>
            ClayButton('More', onPressed: toggle),
      ),
    ),
    _row(
      'SnackBar',
      (context) => ClayButton(
        'Archive',
        onPressed: () =>
            showClayToast(context, 'Habit archived', actionLabel: 'Undo'),
      ),
    ),
    _row(
      'Banner',
      (_) => const ClayBanner(
        title: 'Reminders are off',
        message: 'Turn them on in Settings to be nudged.',
        tone: ClayBannerTone.warning,
      ),
    ),
    // Feedback.
    _row(
      'LinearProgressIndicator',
      (_) => const ClayProgressBar(value: 0.6, semanticLabel: 'Weekly goal'),
    ),
    _row(
      'CircularProgressIndicator',
      (_) => const ClaySpinner(semanticLabel: 'Loading habits'),
    ),
    _row('Skeleton', (_) => const ClaySkeleton(width: 200)),
    _row(
      'StatusView',
      (_) => const ClayStateView(
        state: ClayState.error,
        title: 'Sync failed',
        message: 'Your habits are safe on this phone.',
        actions: [ClayButton('Try again', onPressed: _none)],
      ),
    ),
    _row(
      'Meter',
      (_) => const ClayMeter(
        value: 6,
        max: 8,
        label: 'Glasses today',
        valueText: '6 of 8',
      ),
    ),
    // Charts.
    _row(
      'LineChart',
      (_) => const ClayLineChart(
        semanticLabel: 'Glasses a day',
        xAxis: ClayChartXAxis.band,
        categories: _week,
        series: [ClayChartSeries(label: 'Glasses', points: _glasses)],
      ),
    ),
    _row(
      'BarChart',
      (_) => const ClayBarChart(
        semanticLabel: 'Habits kept',
        categories: _week,
        series: [ClayChartSeries(label: 'Kept', points: _kept)],
      ),
    ),
    _row(
      'AreaChart',
      (_) => const ClayAreaChart(
        semanticLabel: 'Minutes read',
        xAxis: ClayChartXAxis.band,
        categories: _week,
        series: [ClayChartSeries(label: 'Minutes', points: _minutes)],
      ),
    ),
    _row(
      'PieChart',
      (_) => const ClayPieChart(
        semanticLabel: 'Time by habit',
        centerLabel: '5h',
        centerCaption: 'this week',
        slices: [
          ClayPieSlice(label: 'Walk', value: 140),
          ClayPieSlice(label: 'Read', value: 95),
          ClayPieSlice(label: 'Stretch', value: 65),
        ],
      ),
    ),
    _row(
      'Sparkline',
      (_) => const ClaySparkline(
        semanticLabel: 'Water this week',
        width: 160,
        values: [5, 7, 6, 8, 7, 8, 6],
      ),
    ),
  ],
);

const _week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _glasses = [
  ClayChartPoint(0, 5),
  ClayChartPoint(1, 7),
  ClayChartPoint(2, 6),
  ClayChartPoint(3, 8),
  ClayChartPoint(4, 7),
  ClayChartPoint(5, 8),
  ClayChartPoint(6, 6),
];

const _kept = [
  ClayChartPoint(0, 4),
  ClayChartPoint(1, 5),
  ClayChartPoint(2, 3),
  ClayChartPoint(3, 5),
  ClayChartPoint(4, 4),
  ClayChartPoint(5, 2),
  ClayChartPoint(6, 5),
];

const _minutes = [
  ClayChartPoint(0, 12),
  ClayChartPoint(1, 20),
  ClayChartPoint(2, 15),
  ClayChartPoint(3, 25),
  ClayChartPoint(4, 18),
  ClayChartPoint(5, 30),
  ClayChartPoint(6, 22),
];

class _Habit {
  const _Habit(this.name, this.streak);
  final String name;
  final int streak;
}

class _DataTableSpecimen extends StatefulWidget {
  const _DataTableSpecimen();

  @override
  State<_DataTableSpecimen> createState() => _DataTableSpecimenState();
}

class _DataTableSpecimenState extends State<_DataTableSpecimen> {
  final _table = ClayTableController<_Habit>(
    rows: const [
      _Habit('Drink water', 12),
      _Habit('Read', 4),
      _Habit('Stretch', 21),
    ],
    rowKey: (h) => h.name,
    columns: [
      ClayDataColumn(id: 'name', label: 'Habit', sortKey: (h) => h.name),
      ClayDataColumn(
        id: 'streak',
        label: 'Streak',
        sortKey: (h) => h.streak,
        numeric: true,
      ),
    ],
  );

  @override
  void dispose() {
    _table.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClayDataTable<_Habit>(
    controller: _table,
    selectable: true,
    cell: (h, column) => column == 'name' ? h.name : '${h.streak}',
  );
}

class _ScrollSpecimen extends StatefulWidget {
  const _ScrollSpecimen();

  @override
  State<_ScrollSpecimen> createState() => _ScrollSpecimenState();
}

class _ScrollSpecimenState extends State<_ScrollSpecimen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 180,
    child: ClayScrollArea(
      controller: _scroll,
      child: ListView(
        controller: _scroll,
        children: [for (var i = 1; i <= 12; i++) ClayListTile(title: 'Day $i')],
      ),
    ),
  );
}

class _ReorderSpecimen extends StatefulWidget {
  const _ReorderSpecimen();

  @override
  State<_ReorderSpecimen> createState() => _ReorderSpecimenState();
}

class _ReorderSpecimenState extends State<_ReorderSpecimen> {
  final _habits = ['Drink water', 'Read', 'Stretch'];

  @override
  Widget build(BuildContext context) => ClayReorderableList<String>(
    items: _habits,
    labelOf: (s) => s,
    onReorder: (from, to) =>
        setState(() => _habits.insert(to, _habits.removeAt(from))),
    itemBuilder: (context, s) => Text(s),
  );
}

class _Area {
  const _Area(this.name, [this.children = const []]);
  final String name;
  final List<_Area> children;
}

class _TreeSpecimen extends StatefulWidget {
  const _TreeSpecimen();

  @override
  State<_TreeSpecimen> createState() => _TreeSpecimenState();
}

class _TreeSpecimenState extends State<_TreeSpecimen> {
  static const _roots = [
    _Area('Health', [_Area('Drink water'), _Area('Walk')]),
    _Area('Mind', [_Area('Read')]),
  ];

  final _tree = ClayTreeController<_Area>(
    roots: _roots,
    childrenOf: (a) => a.children,
    expanded: [_roots.first],
  );

  @override
  void dispose() {
    _tree.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ClayTree<_Area>(controller: _tree, labelOf: (a) => a.name);
}
