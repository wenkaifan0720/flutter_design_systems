// Neumorphism's answer to the shared component inventory (ui_core's RawInventoryRow.all, 89 rows): for each row the
// part that answers it, `Neumorphic<Stem>`, as a small live specimen. The live gallery lists it, and a test verifies it
// (every row answered once, every specimen the row's own class).
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/inventory.dart';

import 'actions.dart';
import 'calendar.dart';
import 'chart.dart';
import 'chart_kinds.dart';
import 'chrome.dart';
import 'chrome_items.dart';
import 'collections.dart';
import 'controls.dart';
import 'entries.dart';
import 'fields.dart';
import 'glyphs.dart';
import 'heads.dart';
import 'holds.dart';
import 'moves.dart';
import 'overlays.dart';
import 'pickers.dart';
import 'raised.dart';
import 'records.dart';
import 'rows.dart';
import 'sheets.dart';
import 'shows.dart';
import 'tell.dart';
import 'theme.dart';
import 'wheel_picker.dart';

void _none() {}
void _drop(Object? _) {}

const _home = NeumorphicNavItem(
  label: 'Today',
  short: 'Today',
  icon: NeumorphicGlyphs.house,
);
const _rooms = NeumorphicNavItem(
  label: 'Rooms',
  short: 'Rooms',
  icon: NeumorphicGlyphs.lamp,
);
const _sleep = NeumorphicNavItem(
  label: 'Sleep',
  short: 'Sleep',
  icon: NeumorphicGlyphs.moon,
);

// The specimens' controllers, each made when its specimen shows and disposed when it goes (_Owns).
ScrollController _scroll(BuildContext _) => ScrollController();
RawCalendarController _day(BuildContext _) => RawCalendarController(
  firstDate: DateTime(2026, 6),
  lastDate: DateTime(2026, 9, 30),
  selectedDate: DateTime(2026, 6, 14),
  currentDate: DateTime(2026, 6, 10),
);
RawCalendarController _stay(BuildContext _) => RawCalendarController(
  firstDate: DateTime(2026, 6),
  lastDate: DateTime(2026, 9, 30),
  mode: RawCalendarMode.range,
  selectedRange: RawDateRange(DateTime(2026, 6, 14), DateTime(2026, 6, 18)),
  currentDate: DateTime(2026, 6, 10),
);
// The colour picker starts on the theme's pigment.
RawColorController _colour(BuildContext context) =>
    RawColorController(NeumorphicTheme.of(context).colors.pigment);
RawDataTableController<_Room> _table(BuildContext _) =>
    RawDataTableController<_Room>(
      rows: const [
        _Room('Bedroom', 19),
        _Room('Kitchen', 22),
        _Room('Study', 21),
      ],
      columns: [
        RawDataColumn<_Room>(id: 'room', label: 'Room', sortKey: (r) => r.name),
        RawDataColumn<_Room>(
          id: 'heat',
          label: 'Heat',
          numeric: true,
          sortKey: (r) => r.heat,
        ),
      ],
    );
RawTreeController<String> _places(BuildContext _) => RawTreeController<String>(
  roots: const ['Upstairs'],
  expanded: const ['Upstairs'],
  childrenOf: (n) => n == 'Upstairs' ? const ['Bedroom', 'Study'] : const [],
);

/// A specimen's controller, made by [make] when the specimen first shows and disposed when it goes; [builder] shows
/// the specimen with it. A controller kept for the app's life outlived every specimen that used it.
class _Owns<T extends ChangeNotifier> extends StatefulWidget {
  const _Owns(this.make, this.builder);

  final T Function(BuildContext context) make;
  final Widget Function(BuildContext context, T controller) builder;

  @override
  State<_Owns<T>> createState() => _OwnsState<T>();
}

class _OwnsState<T extends ChangeNotifier> extends State<_Owns<T>> {
  T? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= widget.make(context);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller!);
}

/// The specimens that fill the height they are given; a gallery frames each in a box of this height.
const Map<String, double> neumorphicInventoryHeights = {
  'NavigationRail': 300,
  'NavigationDrawer': 340,
  'Scaffold': 260,
  'Sheet': 280,
  'BottomSheet': 220,
  'Resizable': 160,
  'ScrollArea': 140,
};

// The specimens that need a column's whole width: seven days of a month at the touch floor.
const Set<String> _wide = {'DatePicker', 'DateRangePicker', 'Calendar'};

class _Room {
  const _Room(this.name, this.heat);
  final String name;
  final int heat;
}

/// Neumorphism's inventory: every row of the shared component list, answered.
final RawInventory neumorphicInventory = RawInventory(
  look: 'Neumorphism',
  entries: [
    // Actions
    RawInventoryEntry.present(
      'Button',
      // The row names four kinds (filled, outlined, text, danger): one of each.
      (_) => const Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          NeumorphicButton.filled('Save', onPressed: _none),
          NeumorphicButton('Preview', onPressed: _none),
          NeumorphicButton.text('Later', onPressed: _none),
          NeumorphicButton(
            'Delete',
            isDestructiveAction: true,
            onPressed: _none,
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'IconButton',
      (_) => const NeumorphicIconButton(
        NeumorphicGlyphs.share2,
        semanticLabel: 'Share',
        onPressed: _none,
      ),
    ),
    const RawInventoryEntry.absent(
      'FloatingActionButton',
      'a button floating over the page would stack one raised part on others; give the page\'s main action its own place instead, at the end of its column, the foot of the screen or the side bar',
    ),
    RawInventoryEntry.present(
      'ButtonGroup',
      (_) => const NeumorphicButtonGroup(
        semanticLabel: 'Week',
        items: [
          NeumorphicButtonGroupItem('Previous', onPressed: _none),
          NeumorphicButtonGroupItem('Today', onPressed: _none),
          NeumorphicButtonGroupItem('Next', onPressed: _none),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'ToggleGroup',
      (_) => const NeumorphicToggleGroup<String>(
        semanticLabel: 'Rooms',
        selected: {'bed'},
        onChanged: _drop,
        items: [
          NeumorphicButtonSegment('bed', 'Bedroom'),
          NeumorphicButtonSegment('kitchen', 'Kitchen'),
          NeumorphicButtonSegment('study', 'Study'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'SplitButton',
      (_) => const NeumorphicSplitButton(
        'Start',
        onPressed: _none,
        actions: [NeumorphicSplitAction('Start at dusk', onPressed: _none)],
      ),
    ),
    RawInventoryEntry.present(
      'Link',
      (_) => const NeumorphicLink('View details', onPressed: _none),
    ),
    RawInventoryEntry.present('Kbd', (_) => const NeumorphicKbd(['Ctrl', 'K'])),
    // Inputs
    RawInventoryEntry.present(
      'TextField',
      (_) =>
          const NeumorphicTextField(labelText: 'Name', initialValue: 'Marta'),
    ),
    RawInventoryEntry.present(
      'TextArea',
      (_) => const NeumorphicTextArea(labelText: 'Notes'),
    ),
    RawInventoryEntry.present(
      'SearchField',
      (_) => const NeumorphicSearchField(hintText: 'Find a room'),
    ),
    RawInventoryEntry.present(
      'PasswordField',
      (_) => const NeumorphicPasswordField(labelText: 'Password'),
    ),
    RawInventoryEntry.present(
      'InputGroup',
      (_) => const NeumorphicInputGroup(
        labelText: 'Website',
        prefix: 'https://',
        keyboardType: TextInputType.url,
        suffix: '.com',
      ),
    ),
    RawInventoryEntry.present(
      'InputOtp',
      (_) => const NeumorphicInputOtp(labelText: 'Code', length: 6),
    ),
    RawInventoryEntry.present(
      'NumberField',
      (_) => const NeumorphicNumberField(
        value: 2,
        unit: 'Lamps',
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Select',
      // Alone, as a filter, a select keeps to its content; in a form's
      // column it takes the column.
      (_) => const Row(
        children: [
          NeumorphicSelect<String>(
            labelText: 'Room',
            value: 'bed',
            options: [
              NeumorphicMenuItem('bed', 'Bedroom'),
              NeumorphicMenuItem('study', 'Study'),
            ],
            onChanged: _drop,
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Combobox',
      (_) => const NeumorphicCombobox<String>(
        labelText: 'Room',
        hintText: 'Type or choose a room',
        options: ['Bedroom', 'Kitchen', 'Study', 'Hall'],
      ),
    ),
    RawInventoryEntry.present(
      'MultiSelect',
      (_) => const NeumorphicMultiSelect<String>(
        labelText: 'Rooms',
        values: ['Bedroom'],
        onChanged: _drop,
        options: ['Bedroom', 'Kitchen', 'Study'],
      ),
    ),
    RawInventoryEntry.present(
      'Checkbox',
      (_) => const NeumorphicCheckbox(
        semanticLabel: 'Dim at dusk',
        value: true,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'RadioGroup',
      (_) => const NeumorphicRadioGroup<String>(
        semanticLabel: 'Room',
        value: 'bed',
        options: [
          NeumorphicRadio('bed', 'Bedroom'),
          NeumorphicRadio('study', 'Study'),
        ],
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Switch',
      (_) => const NeumorphicSwitch(
        semanticLabel: 'Night light',
        value: true,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Slider',
      (_) => const NeumorphicSlider(
        semanticLabel: 'Warmth',
        value: .5,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'RangeSlider',
      (_) => const NeumorphicRangeSlider(
        label: 'Comfort',
        values: RawRangeValues(18, 22),
        min: 12,
        max: 28,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'SegmentedButton',
      (_) => const NeumorphicSegmentedButton<String>(
        semanticLabel: 'View',
        value: 'day',
        segments: [
          NeumorphicButtonSegment('day', 'Day'),
          NeumorphicButtonSegment('week', 'Week'),
        ],
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Chip',
      (_) => const NeumorphicChip('Warm white', onPressed: _none),
    ),
    RawInventoryEntry.present(
      'Rating',
      (_) => const NeumorphicRating(
        semanticLabel: 'Sleep',
        value: 4,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'FileUpload',
      (_) => const NeumorphicFileUpload(onPressed: _none, hint: 'PDF or JPG'),
    ),
    RawInventoryEntry.present(
      'DatePicker',
      (_) =>
          NeumorphicDatePicker(value: DateTime(2026, 6, 14), onChanged: _drop),
    ),
    RawInventoryEntry.present(
      'DateRangePicker',
      (_) => _Owns(
        _stay,
        (context, stay) => NeumorphicDateRangePicker(controller: stay),
      ),
    ),
    RawInventoryEntry.present(
      'TimePicker',
      (_) => const NeumorphicTimePicker(onChanged: _drop),
    ),
    RawInventoryEntry.present(
      'Calendar',
      (_) => _Owns(_day, (context, day) => NeumorphicCalendar(controller: day)),
    ),
    RawInventoryEntry.present(
      'WheelPicker',
      (_) => const NeumorphicWheelPicker<int>(
        semanticLabel: 'Lamps',
        items: [1, 2, 3, 4, 5, 6],
        value: 2,
        onChanged: _drop,
        rows: 3,
      ),
    ),
    RawInventoryEntry.present(
      'ColorPicker',
      (_) => _Owns(
        _colour,
        (context, colour) => NeumorphicColorPicker(controller: colour),
      ),
    ),
    RawInventoryEntry.present(
      'FormField',
      (_) => const NeumorphicFormField(
        labelText: 'Email',
        helperText: 'The receipt goes here',
        required: true,
        child: NeumorphicTextField(hintText: 'name@example.com'),
      ),
    ),
    // Navigation
    RawInventoryEntry.present(
      'AppBar',
      (_) => const NeumorphicAppBar(title: 'Tonight'),
    ),
    RawInventoryEntry.present(
      'NavigationBar',
      (_) => const NeumorphicNavigationBar(
        items: [_home, _rooms, _sleep],
        onDestinationSelected: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'NavigationRail',
      (_) => const NeumorphicNavigationRail(
        items: [_home, _rooms, _sleep],
        onDestinationSelected: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'NavigationDrawer',
      (_) => const NeumorphicNavigationDrawer(
        items: [_home, _rooms, _sleep],
        onDestinationSelected: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'TabBar',
      (_) => NeumorphicTabBar(
        tabs: const ['Day', 'Week', 'Month'],
        semanticLabel: 'Span',
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Breadcrumb',
      (_) => NeumorphicBreadcrumb(
        crumbs: const [
          NeumorphicCrumb('Home', onPressed: _none),
          NeumorphicCrumb('Upstairs', onPressed: _none),
          NeumorphicCrumb('Bedroom'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Pagination',
      (_) => const NeumorphicPagination(count: 12, page: 4, onChanged: _drop),
    ),
    RawInventoryEntry.present(
      'StepProgress',
      (_) =>
          const NeumorphicStepProgress(count: 3, currentStep: 1, name: 'Setup'),
    ),
    RawInventoryEntry.present(
      'PageDots',
      (_) => const NeumorphicPageDots(
        count: 4,
        selectedIndex: 1,
        semanticLabel: 'Rooms',
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'MenuBar',
      (context) => NeumorphicMenuBar(
        menus: [
          RawMenuEntry(
            label: 'Scene',
            children: [
              RawMenuEntry(
                label: 'New scene',
                shortcut: _primaryKeys(context, LogicalKeyboardKey.keyN),
                onPressed: _none,
              ),
              const RawMenuEntry(label: 'Print', onPressed: _none),
            ],
          ),
          const RawMenuEntry(
            label: 'View',
            children: [
              RawMenuEntry(label: 'Rooms', checked: true, onPressed: _none),
            ],
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Command',
      (context) => NeumorphicCommand(
        maxHeight: 200,
        commands: [
          RawCommand(
            label: 'New scene',
            group: 'Scenes',
            shortcut: _primaryKeys(context, LogicalKeyboardKey.keyN),
          ),
          const RawCommand(label: 'Find a room', group: 'Rooms'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Scaffold',
      (_) => const NeumorphicScaffold(
        scroll: false,
        topBar: NeumorphicAppBar(title: 'Tonight'),
        body: Text('Two lamps on'),
      ),
    ),
    // Containers
    RawInventoryEntry.present(
      'Card',
      (_) => const NeumorphicCard(
        title: 'Bedroom',
        children: [Text('19 degrees, two lamps')],
      ),
    ),
    RawInventoryEntry.present(
      'ListTile',
      (_) => const NeumorphicListTile(
        title: 'Bedroom',
        subtitle: 'Two lamps',
        onPressed: _none,
      ),
    ),
    RawInventoryEntry.present(
      'ListSection',
      (_) => const NeumorphicListSection(
        label: 'Rooms',
        children: [
          NeumorphicListTile(title: 'Bedroom', isFirst: true),
          NeumorphicListTile(title: 'Study'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'SectionHeader',
      (_) => const NeumorphicSectionHeader(title: 'Tonight'),
    ),
    RawInventoryEntry.present(
      'Disclosure',
      (_) => const NeumorphicDisclosure(
        title: 'House rules',
        child: Text('Quiet after ten'),
      ),
    ),
    RawInventoryEntry.present(
      'Table',
      (_) => const NeumorphicTable(
        columns: [
          NeumorphicTableColumn('Room'),
          NeumorphicTableColumn('Heat', numeric: true),
        ],
        rows: [
          NeumorphicTableRow(['Bedroom', '19']),
          NeumorphicTableRow(['Study', '21']),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'DataTable',
      (_) => _Owns(
        _table,
        (context, table) => NeumorphicDataTable<_Room>(
          semanticLabel: 'Rooms',
          controller: table,
          cell: (r, column) => column.id == 'room' ? r.name : '${r.heat}',
        ),
      ),
    ),
    RawInventoryEntry.present('Divider', (_) => const NeumorphicDivider()),
    RawInventoryEntry.present(
      'ScrollArea',
      (_) => _Owns(
        _scroll,
        (context, scroll) => NeumorphicScrollArea(
          controller: scroll,
          semanticLabel: 'Rooms',
          child: ListView(
            controller: scroll,
            children: [
              for (final r in const [
                'Bedroom',
                'Study',
                'Kitchen',
                'Hall',
                'Attic',
                'Cellar',
                'Porch',
              ])
                Padding(padding: const EdgeInsets.all(8), child: Text(r)),
            ],
          ),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Resizable',
      (_) => const NeumorphicResizable(
        first: Text('Rooms'),
        second: Text('Bedroom'),
      ),
    ),
    RawInventoryEntry.present('CarouselView', (context) {
      final c = NeumorphicTheme.of(context).colors;
      // Each slide is its room by its mark, on the one material: tinted in hues of their own the slides wore colours
      // the theme does not hold.
      Widget slide(String title, String line, IconData glyph) => NeumorphicCard(
        title: title,
        trailing: Icon(glyph, size: 20, color: c.inkSecondary),
        children: [Text(line)],
      );
      return NeumorphicCarouselView(
        semanticLabel: 'Rooms',
        height: 132,
        initialPage: 1,
        children: [
          slide('Bedroom', '19°, lamp low', NeumorphicGlyphs.lamp),
          slide('Study', '20.5°, reading', NeumorphicGlyphs.bookOpen),
          slide('Hall', '18°, quiet', NeumorphicGlyphs.doorOpen),
        ],
      );
    }),
    RawInventoryEntry.present(
      'ReorderableListView',
      (_) => NeumorphicReorderableListView<String>(
        items: const ['Bedroom', 'Study', 'Hall'],
        labelOf: (s) => s,
        onReorder: (from, to) {},
        itemBuilder: (context, s) => Text(s),
      ),
    ),
    RawInventoryEntry.present(
      'SwipeActions',
      (_) => const NeumorphicSwipeActions(
        endActions: [RawSwipeAction(label: 'Archive', onPressed: _none)],
        child: NeumorphicListTile(
          title: 'Bedroom',
          subtitle: 'Swipe for actions',
        ),
      ),
    ),
    const RawInventoryEntry.absent(
      'RefreshIndicator',
      'its spinner sat over the list\'s first row; a pull to refresh that opens a gap at the top of the list comes in 0.2.0',
    ),
    RawInventoryEntry.present(
      'TreeView',
      (_) => _Owns(
        _places,
        (context, places) => NeumorphicTreeView<String>(
          semanticLabel: 'Rooms',
          controller: places,
          labelOf: (n) => n,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Timeline',
      (_) => const NeumorphicTimeline(
        stops: [
          NeumorphicTimelineStop(
            time: '19:45',
            title: 'Lamps dim',
            body: 'The hall goes first.',
          ),
          NeumorphicTimelineStop(
            time: '22:30',
            title: 'Lights out',
            state: NeumorphicStepStatus.live,
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Avatar',
      (_) => const NeumorphicAvatar('MR', name: 'Marta Rossi'),
    ),
    RawInventoryEntry.present(
      'AvatarGroup',
      (_) => const NeumorphicAvatarGroup([
        NeumorphicFace('MR'),
        NeumorphicFace('TB'),
        NeumorphicFace('IV'),
      ]),
    ),
    RawInventoryEntry.present('Badge', (_) => const NeumorphicBadge(3)),
    RawInventoryEntry.present('Tag', (_) => const NeumorphicTag('Warm')),
    RawInventoryEntry.present(
      'Media',
      (_) => const NeumorphicMedia(
        semanticLabel: 'Bedroom',
        glyph: NeumorphicGlyphs.lamp,
      ),
    ),
    RawInventoryEntry.present(
      'EmptyState',
      (_) => const NeumorphicEmptyState(
        title: 'All quiet',
        body: 'No rooms are on.',
      ),
    ),
    RawInventoryEntry.present(
      'DescriptionList',
      (_) => const NeumorphicDescriptionList([
        NeumorphicDescription('Lights out', '22:30'),
        NeumorphicDescription('Lamps', '2'),
      ]),
    ),
    // Overlays
    RawInventoryEntry.present(
      'Dialog',
      (_) => const NeumorphicDialog(
        title: 'Remove the scene?',
        message: 'The rooms keep their settings.',
      ),
    ),
    RawInventoryEntry.present(
      'BottomSheet',
      (_) => const NeumorphicBottomSheet(
        title: 'Bedroom',
        showClose: false,
        inPlace: true,
        child: Text('Two lamps'),
      ),
    ),
    RawInventoryEntry.present(
      'Sheet',
      (_) => const NeumorphicSheet(title: 'Filters', child: Text('Warm white')),
    ),
    RawInventoryEntry.present(
      'ActionSheet',
      (_) => const NeumorphicActionSheet<String>(
        title: 'Bedroom',
        onSelected: _drop,
        onCancel: _none,
        actions: [
          NeumorphicActionSheetAction('share', 'Share'),
          NeumorphicActionSheetAction(
            'remove',
            'Remove the room',
            destructive: true,
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Popover',
      (_) => NeumorphicPopover(
        semanticLabel: 'Lights out',
        trigger: (context, toggle) =>
            NeumorphicButton('When', onPressed: toggle),
        content: const Text('At half past ten, every night.'),
      ),
    ),
    RawInventoryEntry.present(
      'HoverCard',
      (_) => const NeumorphicHoverCard(
        content: Text('Asleep by eleven, most nights'),
        child: NeumorphicLink('Marta Rossi', onPressed: _none),
      ),
    ),
    RawInventoryEntry.present(
      'Tooltip',
      (_) => const NeumorphicTooltip(
        message: 'Share',
        child: Icon(NeumorphicGlyphs.share2),
      ),
    ),
    RawInventoryEntry.present(
      'Menu',
      (_) => const NeumorphicMenu<String>(
        autofocus: false,
        items: [
          NeumorphicMenuItem('share', 'Share'),
          NeumorphicMenuItem('print', 'Print'),
        ],
        onSelected: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'SnackBar',
      (_) => const NeumorphicSnackBar(
        'Scene saved',
        actionLabel: 'Undo',
        onAction: _none,
      ),
    ),
    RawInventoryEntry.present(
      'Banner',
      (_) =>
          const NeumorphicBanner('The hall lamp is changing.', title: 'Note'),
    ),
    // Feedback
    RawInventoryEntry.present(
      'LinearProgressIndicator',
      (_) =>
          const NeumorphicLinearProgressIndicator(value: .6, label: 'Upload'),
    ),
    RawInventoryEntry.present(
      'CircularProgressIndicator',
      (_) => const NeumorphicCircularProgressIndicator(
        value: .6,
        semanticLabel: 'Upload',
      ),
    ),
    RawInventoryEntry.present(
      'Skeleton',
      (_) => const NeumorphicSkeleton.lines(3),
    ),
    RawInventoryEntry.present(
      'StatusView',
      (_) => const NeumorphicStatusView.loading(),
    ),
    RawInventoryEntry.present(
      'Meter',
      (_) => const NeumorphicMeter(
        label: 'Hot water',
        value: 18,
        max: 24,
        high: 20,
        valueLabel: '18 of 24',
      ),
    ),
    // Charts
    RawInventoryEntry.present(
      'LineChart',
      (_) => const NeumorphicLineChart(
        semanticLabel: 'Hours slept',
        height: 140,
        labels: ['Mon', 'Tue', 'Wed', 'Thu'],
        series: [
          NeumorphicChartSeries('Hours', [7, 8, 6, 7.5]),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'BarChart',
      (_) => const NeumorphicBarChart(
        semanticLabel: 'Lamp hours',
        height: 140,
        labels: ['June', 'July', 'August'],
        series: [
          NeumorphicChartSeries('Bedroom', [4, 6, 5]),
          NeumorphicChartSeries('Study', [3, 5, 7]),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'AreaChart',
      (_) => const NeumorphicAreaChart(
        semanticLabel: 'Warmth',
        height: 140,
        labels: ['Mon', 'Tue', 'Wed', 'Thu'],
        series: [
          NeumorphicChartSeries('Warmth', [18, 20, 19, 21]),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'PieChart',
      (_) => const NeumorphicPieChart(
        semanticLabel: 'Rooms',
        caption: 'rooms',
        slices: [NeumorphicPieSlice('On', 3), NeumorphicPieSlice('Off', 5)],
      ),
    ),
    RawInventoryEntry.present(
      'Sparkline',
      (_) => const NeumorphicSparkline(
        semanticLabel: 'Hours slept',
        values: [7, 8, 6, 7.5, 8],
      ),
    ),
  ],
);

/// Neumorphism's inventory, listed: each group under its heading with how many of its rows the look carries, then each
/// row on a slab, its class and what a person calls it over its live specimen. It scrolls itself, so it fills a screen
/// that does not scroll (NeumorphicScaffold(scroll: false)).
///
/// ```dart
/// NeumorphicScaffold(scroll: false, topBar: const NeumorphicAppBar(title: 'Components'), body: const NeumorphicInventoryGallery())
/// ```
class NeumorphicInventoryGallery extends StatelessWidget {
  /// The inventory, listed.
  const NeumorphicInventoryGallery({
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
    final t = NeumorphicTheme.of(context);
    return RawInventoryGallery(
      inventory: neumorphicInventory,
      controller: controller,
      padding: padding,
      groupBuilder: (context, group, live, total) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: NeumorphicSectionHeader(
          title: group,
          subtitle: '$live of $total live',
        ),
      ),
      rowBuilder: (context, row, entry, specimen) {
        final height = neumorphicInventoryHeights[row.id];
        final sized = specimen == null || height == null
            ? specimen
            : SizedBox(height: height, child: specimen);
        final wide = sized != null && _wide.contains(row.id);
        final card = NeumorphicCard(
          title: row.name,
          children: [
            if (sized == null)
              Text(
                entry?.absentReason != null
                    ? RawInventory.absentLabel(entry!.absentReason!)
                    : 'Missing: the inventory does not answer this row',
                style: t.textTheme.body.copyWith(color: t.colors.inkSecondary),
              )
            else if (!wide)
              sized,
          ],
        );
        return KeyedSubtree(
          key: ValueKey<String>('inventory-${row.id}'),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: wide
                // A wide part (a month) stands on the wall under its name, not under an empty card: in a card it
                // would be a bump on a bump, and an empty card above it read as the part spilling out of it.
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(row.name, style: t.textTheme.title),
                      const SizedBox(height: 12),
                      sized,
                    ],
                  )
                : card,
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
          defaultValue: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        ),
      );
  }
}

// A shortcut on the platform's own modifier: Command on Apple's, Control elsewhere, spelled as its menus spell it.
String _primaryKeys(BuildContext context, LogicalKeyboardKey key) {
  final apple =
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;
  return rawShortcutLabel(
    context,
    SingleActivator(key, meta: apple, control: !apple),
  );
}
