/// Brutal's answer to the component inventory: a live specimen for every
/// row. [BrutalInventory.registry] is what the look's test verifies and
/// what an inventory gallery lists.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../actions.dart';
import '../block.dart';
import '../button.dart';
import '../charts.dart';
import '../choices.dart';
import '../collections.dart';
import '../display.dart';
import '../entry.dart';
import '../feedback.dart';
import '../lists.dart';
import '../menu.dart';
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

void _ignore(Object? _) {}

/// A specimen that keeps the value its control last chose, so the arrow
/// keys move a radio group's choice along with its focus.
class _Held<T> extends StatefulWidget {
  const _Held(this.initial, this.builder);

  final T initial;
  final Widget Function(T value, ValueChanged<T> change) builder;

  @override
  State<_Held<T>> createState() => _HeldState<T>();
}

class _HeldState<T> extends State<_Held<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (next) => setState(() => _value = next));
}

const _places = [
  BrutalDestination(icon: LucideIcons.house, label: 'Home'),
  BrutalDestination(icon: LucideIcons.calendarDays, label: 'Events'),
  BrutalDestination(icon: LucideIcons.ticket, label: 'Tickets'),
];

final _first = DateTime(2026, 11);
final _last = DateTime(2026, 12, 31);

DesignInventoryEntry _row(String id, WidgetBuilder builder) =>
    DesignInventoryEntry.present(id, builder);

/// Brutal's inventory: every row of [DesignInventoryRow.all] answered with
/// a live specimen.
abstract final class BrutalInventory {
  /// The registry.
  static final DesignInventory registry = _registry();
}

DesignInventory _registry() => DesignInventory(
  look: 'Brutal',
  entries: [
    // Actions.
    _row('Button', (_) => const BrutalButton('Get tickets', onPressed: _none)),
    _row(
      'IconButton',
      (_) => const BrutalIconButton(
        onPressed: _none,
        icon: Icon(LucideIcons.heart),
        tooltip: 'Save',
      ),
    ),
    _row(
      'FloatingActionButton',
      (_) => const BrutalFloatingButton(
        onPressed: _none,
        icon: Icon(LucideIcons.plus),
        tooltip: 'New event',
      ),
    ),
    _row(
      'ButtonGroup',
      (_) => const BrutalButtonGroup(
        semanticLabel: 'Text',
        items: [
          BrutalButtonGroupItem(onPressed: _none, label: 'Bold'),
          BrutalButtonGroupItem(onPressed: _none, label: 'Italic'),
        ],
      ),
    ),
    _row(
      'ToggleGroup',
      (_) => BrutalToggleGroup<String>(
        options: const ['Music', 'Talks', 'Film'],
        selected: const {'Music'},
        onSelectionChanged: _ignore,
        labelOf: (s) => s,
      ),
    ),
    _row(
      'SplitButton',
      (_) => const BrutalSplitButton(
        label: 'Share',
        onPressed: _none,
        actions: [BrutalMenuItem(label: 'Copy link', onPressed: _none)],
      ),
    ),
    _row('Link', (_) => const BrutalLink('Terms', onPressed: _none)),
    _row(
      'Kbd',
      (_) => const BrutalKbd.shortcut(
        SingleActivator(LogicalKeyboardKey.keyK, control: true),
      ),
    ),
    // Inputs.
    _row('TextField', (_) => const BrutalTextField(label: 'Name')),
    _row(
      'TextArea',
      (_) => const BrutalTextField(label: 'Note', maxLines: 4, minLines: 3),
    ),
    _row('SearchField', (_) => const BrutalSearchField()),
    _row('PasswordField', (_) => const BrutalPasswordField(label: 'Password')),
    _row(
      'InputGroup',
      (_) => const BrutalInputGroup(label: 'Price', before: '£', after: 'each'),
    ),
    _row('InputOtp', (_) => const BrutalCodeField(label: 'Code')),
    _row(
      'NumberField',
      (_) => const BrutalStepper(value: 2, onChanged: _ignore),
    ),
    _row(
      'Select',
      (_) => const BrutalSelect<String>(
        label: 'Venue',
        value: 'shed',
        onChanged: _ignore,
        items: [
          BrutalSelectItem(value: 'shed', label: 'The Shed'),
          BrutalSelectItem(value: 'dock', label: 'Dock 4'),
        ],
      ),
    ),
    _row(
      'Combobox',
      (_) => BrutalCombobox<String>(
        label: 'Venue',
        options: const ['The Shed', 'Dock 4', 'Cellar'],
        labelOf: (s) => s,
      ),
    ),
    _row(
      'MultiSelect',
      (_) => BrutalTagInput<String>(
        label: 'Genres',
        values: const ['Jazz'],
        onChanged: _ignore,
        options: const ['Jazz', 'Folk', 'Techno'],
        labelOf: (s) => s,
      ),
    ),
    _row(
      'Checkbox',
      (_) => const BrutalCheckbox(
        value: true,
        onChanged: _ignore,
        semanticLabel: 'Reminders',
      ),
    ),
    _row(
      'RadioGroup',
      (_) => _Held<int>(
        1,
        (chosen, change) => RadioGroup<int>(
          groupValue: chosen,
          onChanged: (value) => change(value!),
          child: const RadioGroupKeyboardFix<int>(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrutalRadio<int>(value: 1, semanticLabel: 'One'),
                SizedBox(width: BrutalSpacing.regular),
                BrutalRadio<int>(value: 2, semanticLabel: 'Two'),
              ],
            ),
          ),
        ),
      ),
    ),
    _row(
      'Switch',
      (_) => const BrutalSwitch(
        value: true,
        onChanged: _ignore,
        semanticLabel: 'Reminders',
      ),
    ),
    _row(
      'Slider',
      (_) => const BrutalSlider(
        value: 0.4,
        onChanged: _ignore,
        semanticLabel: 'Volume',
      ),
    ),
    _row(
      'RangeSlider',
      (_) => const BrutalRangeSlider(
        values: BrutalRangeValues(0.2, 0.7),
        onChanged: _ignore,
      ),
    ),
    _row(
      'SegmentedButton',
      (_) => _Held<int>(
        0,
        (chosen, change) => BrutalSegmentedButton<int>(
          value: chosen,
          onChanged: change,
          segments: const [
            BrutalSegment(value: 0, label: 'Week'),
            BrutalSegment(value: 1, label: 'Month'),
          ],
        ),
      ),
    ),
    _row(
      'Chip',
      (_) =>
          const BrutalChip(label: 'Free', selected: true, onSelected: _ignore),
    ),
    _row(
      'Rating',
      (_) => const BrutalRating(
        value: 4,
        onChanged: _ignore,
        semanticLabel: 'Rating',
      ),
    ),
    _row(
      'FileUpload',
      (_) => const BrutalFileDrop(
        onChoose: _none,
        files: [BrutalFile(name: 'poster.png', bytes: 482000)],
      ),
    ),
    _row(
      'DatePicker',
      (_) => BrutalDatePicker(
        label: 'Date',
        value: null,
        onChanged: _ignore,
        firstDate: _first,
        lastDate: _last,
      ),
    ),
    _row(
      'DateRangePicker',
      (_) => BrutalDateRangePicker(
        label: 'Dates',
        value: null,
        onChanged: _ignore,
        firstDate: _first,
        lastDate: _last,
      ),
    ),
    _row(
      'TimePicker',
      (_) => const BrutalTimePicker(
        value: BrutalTime(hour: 19, minute: 30),
        onChanged: _ignore,
        semanticLabel: 'Doors',
      ),
    ),
    _row(
      'Calendar',
      (_) => BrutalCalendar(
        firstDate: _first,
        lastDate: _last,
        selectedDate: DateTime(2026, 11, 14),
        currentDate: DateTime(2026, 11, 14),
        onDateChanged: _ignore,
      ),
    ),
    _row(
      'WheelPicker',
      (_) => BrutalWheelPicker<int>(
        items: const [1, 2, 3, 4, 5],
        value: 2,
        onChanged: _ignore,
        labelOf: (n) => '$n',
        semanticLabel: 'Tickets',
      ),
    ),
    _row(
      'ColorPicker',
      (_) =>
          const BrutalColorPicker(value: Color(0xFF3355FF), onChanged: _ignore),
    ),
    _row(
      'FormField',
      (_) => const BrutalFormField(
        labelText: 'Reminders',
        helperText: 'A day before',
        child: BrutalSwitch(value: true, onChanged: _ignore),
      ),
    ),
    // Navigation.
    _row('AppBar', (_) => const BrutalAppBar(title: 'Events')),
    _row(
      'NavigationBar',
      (_) => const BrutalNavigationBar(
        destinations: _places,
        selectedIndex: 0,
        onSelected: _ignore,
      ),
    ),
    _row(
      'NavigationRail',
      (_) => const SizedBox(
        height: 320,
        child: BrutalNavigationRail(
          destinations: _places,
          selectedIndex: 0,
          onSelected: _ignore,
        ),
      ),
    ),
    _row(
      'NavigationDrawer',
      (_) => const SizedBox(
        height: 320,
        width: 280,
        child: BrutalSideNavigation(
          destinations: _places,
          selectedIndex: 0,
          onSelected: _ignore,
        ),
      ),
    ),
    _row(
      'TabBar',
      (_) => const BrutalTabBar(
        tabs: ['Upcoming', 'Past'],
        selectedIndex: 0,
        onSelected: _ignore,
      ),
    ),
    _row(
      'Breadcrumb',
      (_) => const BrutalBreadcrumb(
        crumbs: [
          BrutalCrumb('Events', onPressed: _none),
          BrutalCrumb('Low Tide'),
        ],
      ),
    ),
    _row(
      'Pagination',
      (_) => const BrutalPagination(page: 2, pageCount: 8, onChanged: _ignore),
    ),
    _row(
      'StepProgress',
      (_) =>
          const BrutalStepProgress(steps: ['Seats', 'Pay', 'Done'], current: 1),
    ),
    _row(
      'PageDots',
      (_) => const BrutalPageDots(count: 4, index: 1, onChanged: _ignore),
    ),
    _row(
      'MenuBar',
      (_) => const BrutalMenuBar(
        menus: [
          BrutalMenuBarMenu('File', [
            BrutalMenuItem(label: 'New', onPressed: _none),
          ]),
          BrutalMenuBarMenu('Edit', [
            BrutalMenuItem(label: 'Undo', onPressed: _none),
          ]),
        ],
      ),
    ),
    _row(
      'Command',
      (_) => const SizedBox(
        height: 300,
        child: BrutalCommandPalette(
          commands: [
            BrutalCommand(label: 'Find an event', onPressed: _none),
            BrutalCommand(label: 'Settings', onPressed: _none),
          ],
        ),
      ),
    ),
    _row(
      'Scaffold',
      (_) => const SizedBox(
        height: 360,
        child: BrutalScaffold(
          appBar: BrutalAppBar(title: 'Events'),
          destinations: _places,
          onSelected: _ignore,
          body: SizedBox.expand(),
        ),
      ),
    ),
    // Containers.
    _row('Card', (_) => const BrutalBlock(child: Text('Low Tide, Friday'))),
    _row('ListTile', (_) => const BrutalListTile(title: 'Reminders')),
    _row(
      'ListSection',
      (_) => const BrutalListGroup(
        header: 'Account',
        children: [
          BrutalListTile(title: 'Name', trailingText: 'Ada Park'),
          BrutalListTile(title: 'Email', trailingText: 'ada@example.com'),
        ],
      ),
    ),
    _row('SectionHeader', (_) => const BrutalSectionHeader('This week')),
    _row(
      'Disclosure',
      (_) => const BrutalDisclosure(
        title: 'Refunds',
        child: Text('Up to a day before.'),
      ),
    ),
    _row(
      'Table',
      (_) => const BrutalTable(
        columns: [
          BrutalTableColumn('Night'),
          BrutalTableColumn('Sold', numeric: true),
        ],
        rows: [
          ['Friday', '212'],
          ['Saturday', '340'],
        ],
      ),
    ),
    _row('DataTable', (_) => const _DataTableSpecimen()),
    _row('Divider', (_) => const BrutalRule()),
    _row('ScrollArea', (_) => const _ScrollSpecimen()),
    _row(
      'Resizable',
      (_) => const SizedBox(
        height: 160,
        child: BrutalSplitView(first: Text('Nights'), second: Text('Low Tide')),
      ),
    ),
    _row(
      'CarouselView',
      (_) => BrutalCarousel(
        itemCount: 3,
        itemBuilder: (context, i) => Center(child: Text('Slide ${i + 1}')),
      ),
    ),
    _row('ReorderableListView', (_) => const _ReorderSpecimen()),
    _row(
      'SwipeActions',
      (_) => const BrutalSwipeRow(
        endActions: [
          BrutalSwipeAction(
            label: 'Delete',
            destructive: true,
            onPressed: _none,
          ),
        ],
        child: BrutalListTile(title: 'Low Tide'),
      ),
    ),
    _row(
      'RefreshIndicator',
      (_) => SizedBox(
        height: 160,
        child: BrutalPullToRefresh(
          onRefresh: () async {},
          child: ListView(
            children: const [BrutalListTile(title: 'Pull me down')],
          ),
        ),
      ),
    ),
    _row('TreeView', (_) => const _TreeSpecimen()),
    _row(
      'Timeline',
      (_) => const BrutalTimeline(
        entries: [
          BrutalTimelineEntry(title: 'Ordered', done: true),
          BrutalTimelineEntry(title: 'Doors'),
        ],
      ),
    ),
    _row('Avatar', (_) => const BrutalAvatar(name: 'Ada Park')),
    _row(
      'AvatarGroup',
      (_) => const BrutalAvatarGroup(
        avatars: [
          BrutalAvatar(name: 'Ada Park'),
          BrutalAvatar(name: 'Jun Arai'),
          BrutalAvatar(name: 'Ruth Mensah'),
        ],
      ),
    ),
    _row(
      'Badge',
      (_) => const BrutalBadge(count: 3, child: Icon(LucideIcons.bell)),
    ),
    _row('Tag', (_) => const BrutalTag('Few left', tone: BrutalTagTone.signal)),
    _row(
      'Media',
      (_) => const BrutalMedia(image: null, semanticLabel: 'The stage'),
    ),
    _row(
      'EmptyState',
      (_) => const BrutalStateView(
        state: BrutalState.empty,
        title: 'No tickets yet',
      ),
    ),
    _row(
      'DescriptionList',
      (_) => const BrutalDescriptionList(
        entries: [BrutalDescription('Doors', '19:30')],
      ),
    ),
    // Overlays.
    _row(
      'Dialog',
      (_) => const BrutalDialog(
        title: 'Cancel this ticket?',
        actions: [
          BrutalDialogAction(label: 'Keep', onPressed: _none),
          BrutalDialogAction(
            label: 'Cancel it',
            onPressed: _none,
            destructive: true,
          ),
        ],
      ),
    ),
    _row(
      'BottomSheet',
      (context) => BrutalButton(
        'Open a sheet',
        onPressed: () => showBrutalBottomSheet<void>(
          context: context,
          title: 'Filter',
          builder: (context) => const Text('Venues'),
        ),
      ),
    ),
    _row(
      'Sheet',
      (context) => BrutalButton(
        'Open a side sheet',
        onPressed: () => showBrutalSideSheet<void>(
          context: context,
          title: 'Filters',
          builder: (context) => const Text('Venues'),
        ),
      ),
    ),
    _row(
      'ActionSheet',
      (context) => BrutalButton(
        'Ticket actions',
        onPressed: () => showBrutalActionSheet<String>(
          context: context,
          title: 'This ticket',
          actions: const [BrutalSheetAction(label: 'Transfer', value: 't')],
        ),
      ),
    ),
    _row(
      'Popover',
      (_) => BrutalPopover(
        builder: (context, toggle, open) =>
            BrutalButton('Share', onPressed: toggle),
        content: (context, close) => const Text('Share Low Tide'),
      ),
    ),
    _row(
      'HoverCard',
      (_) => BrutalHoverCard(
        content: (context) => const Text('12 Quay Street'),
        child: const BrutalLink('The Shed', onPressed: _none),
      ),
    ),
    _row(
      'Tooltip',
      (_) => const BrutalTooltip(
        message: 'Save',
        child: BrutalIconButton(
          onPressed: _none,
          icon: Icon(LucideIcons.heart),
          tooltip: 'Save',
        ),
      ),
    ),
    _row(
      'Menu',
      (_) => BrutalMenu(
        items: const [BrutalMenuItem(label: 'Share', onPressed: _none)],
        builder: (context, toggle, open) =>
            BrutalButton('More', onPressed: toggle),
      ),
    ),
    _row(
      'SnackBar',
      (context) => BrutalButton(
        'Show a toast',
        onPressed: () => showBrutalToast(context, 'Ticket saved'),
      ),
    ),
    _row('Banner', (_) => const BrutalNotice(title: 'Doors open at 19:00')),
    // Feedback.
    _row(
      'LinearProgressIndicator',
      (_) => const BrutalProgressBar(value: 0.4, semanticLabel: 'Upload'),
    ),
    _row(
      'CircularProgressIndicator',
      (_) => const BrutalSpinner(semanticLabel: 'Loading'),
    ),
    _row('Skeleton', (_) => const BrutalSkeleton(width: 200)),
    _row(
      'StatusView',
      (_) => const BrutalStateView(
        state: BrutalState.error,
        title: 'The week did not load',
      ),
    ),
    _row('Meter', (_) => const BrutalMeter(value: 0.6, label: 'Capacity')),
    // Charts.
    _row(
      'LineChart',
      (_) => const BrutalLineChart(
        semanticLabel: 'Sold',
        labels: ['Mon', 'Tue', 'Wed'],
        series: [
          BrutalSeries('Sold', [120, 180, 150]),
        ],
      ),
    ),
    _row(
      'BarChart',
      (_) => const BrutalBarChart(
        semanticLabel: 'Sold',
        labels: ['Mon', 'Tue', 'Wed'],
        series: [
          BrutalSeries('Sold', [120, 180, 150]),
        ],
      ),
    ),
    _row(
      'AreaChart',
      (_) => const BrutalAreaChart(
        semanticLabel: 'Visits',
        labels: ['Mon', 'Tue', 'Wed'],
        series: [
          BrutalSeries('Visits', [820, 940, 760]),
        ],
      ),
    ),
    _row(
      'PieChart',
      (_) => const BrutalPieChart(
        semanticLabel: 'By type',
        slices: [BrutalSlice('Standing', 340), BrutalSlice('Seated', 120)],
      ),
    ),
    _row(
      'Sparkline',
      (_) => const BrutalSparkline(
        semanticLabel: 'This week',
        values: [3, 5, 4, 8],
      ),
    ),
  ],
);

class _Night {
  const _Night(this.title, this.sold);
  final String title;
  final int sold;
}

class _DataTableSpecimen extends StatefulWidget {
  const _DataTableSpecimen();

  @override
  State<_DataTableSpecimen> createState() => _DataTableSpecimenState();
}

class _DataTableSpecimenState extends State<_DataTableSpecimen> {
  final _table = BrutalTableController<_Night>(
    rows: const [_Night('Low Tide', 212), _Night('Paper Walls', 340)],
    rowKey: (n) => n.title,
    columns: [
      BrutalDataColumn(id: 'title', label: 'Night', sortKey: (n) => n.title),
      BrutalDataColumn(
        id: 'sold',
        label: 'Sold',
        sortKey: (n) => n.sold,
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
  Widget build(BuildContext context) => BrutalDataTable<_Night>(
    controller: _table,
    cell: (n, column) => column == 'title' ? n.title : '${n.sold}',
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
    height: 160,
    child: BrutalScrollArea(
      controller: _scroll,
      child: ListView(
        controller: _scroll,
        children: [
          for (var i = 1; i <= 12; i++) BrutalListTile(title: 'Row $i'),
        ],
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
  final _acts = ['Doors', 'Support', 'Headline'];

  @override
  Widget build(BuildContext context) => BrutalReorderableList<String>(
    items: _acts,
    labelOf: (a) => a,
    onReorder: (from, to) =>
        setState(() => _acts.insert(to, _acts.removeAt(from))),
    itemBuilder: (context, a) => Text(a),
  );
}

class _Place {
  const _Place(this.name, [this.children = const []]);
  final String name;
  final List<_Place> children;
}

class _TreeSpecimen extends StatefulWidget {
  const _TreeSpecimen();

  @override
  State<_TreeSpecimen> createState() => _TreeSpecimenState();
}

class _TreeSpecimenState extends State<_TreeSpecimen> {
  static const _roots = [
    _Place('North quay', [_Place('The Shed'), _Place('Dock 4')]),
    _Place('Old town', [_Place('Cellar')]),
  ];

  final _tree = BrutalTreeController<_Place>(
    roots: _roots,
    childrenOf: (p) => p.children,
    expanded: [_roots.first],
  );

  @override
  void dispose() {
    _tree.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BrutalTree<_Place>(controller: _tree, labelOf: (p) => p.name);
}
