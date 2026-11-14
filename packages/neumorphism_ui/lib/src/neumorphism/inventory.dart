// Neumorphism's answer to the shared component inventory (ui_core's DesignInventoryRow.all, 89 rows): for each row the
// part that answers it, `Neumorphic<Stem>`, as a small live specimen. The live gallery lists it, and a test verifies it
// (every row answered once, every specimen the row's own class).
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

// The specimens' controllers: one gallery shows the inventory at a time, so each specimen keeps one for the app's life.
final _scroll = ScrollController();
final _day = DesignCalendarController(
  firstDate: DateTime(2026, 6),
  lastDate: DateTime(2026, 9, 30),
  selectedDate: DateTime(2026, 6, 14),
  currentDate: DateTime(2026, 6, 10),
);
final _stay = DesignCalendarController(
  firstDate: DateTime(2026, 6),
  lastDate: DateTime(2026, 9, 30),
  mode: DesignCalendarMode.range,
  selectedRange: DesignDateRange(DateTime(2026, 6, 14), DateTime(2026, 6, 18)),
  currentDate: DateTime(2026, 6, 10),
);
// The colour picker starts on the theme's pigment, the first time it is built.
DesignColorController? _colour;
final _table = DesignTableController<_Room>(
  rows: const [_Room('Bedroom', 19), _Room('Kitchen', 22), _Room('Study', 21)],
  columns: [
    DesignTableColumn<_Room>(id: 'room', label: 'Room', sortKey: (r) => r.name),
    DesignTableColumn<_Room>(
      id: 'heat',
      label: 'Heat',
      numeric: true,
      sortKey: (r) => r.heat,
    ),
  ],
);
final _places = DesignTreeController<String>(
  roots: const ['Upstairs'],
  expanded: const ['Upstairs'],
  childrenOf: (n) => n == 'Upstairs' ? const ['Bedroom', 'Study'] : const [],
);

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

// The specimens that need a column's whole width: seven days of a month at a phone's 48 px targets.
const Set<String> _wide = {'DatePicker', 'DateRangePicker', 'Calendar'};

class _Room {
  const _Room(this.name, this.heat);
  final String name;
  final int heat;
}

/// Neumorphism's inventory: every row of the shared component list, answered.
final DesignInventory neumorphicInventory = DesignInventory(
  look: 'Neumorphism',
  entries: [
    // Actions
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'IconButton',
      (_) => const NeumorphicIconButton(
        NeumorphicGlyphs.share2,
        label: 'Share',
        onPressed: _none,
      ),
    ),
    DesignInventoryEntry.absent(
      'FloatingActionButton',
      'a button floating over the page would stack one raised part on others; give the page\'s main action its own place instead, at the end of its column, the foot of the screen or the side bar',
    ),
    DesignInventoryEntry.present(
      'ButtonGroup',
      (_) => const NeumorphicButtonGroup(
        label: 'Week',
        items: [
          NeumorphicButtonGroupItem('Previous', onPressed: _none),
          NeumorphicButtonGroupItem('Today', onPressed: _none),
          NeumorphicButtonGroupItem('Next', onPressed: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'ToggleGroup',
      (_) => const NeumorphicToggleGroup<String>(
        label: 'Rooms',
        selected: {'bed'},
        onChanged: _drop,
        items: [
          NeumorphicButtonSegment('bed', 'Bedroom'),
          NeumorphicButtonSegment('kitchen', 'Kitchen'),
          NeumorphicButtonSegment('study', 'Study'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'SplitButton',
      (_) => const NeumorphicSplitButton(
        'Start',
        onPressed: _none,
        actions: [NeumorphicSplitAction('Start at dusk', onPressed: _none)],
      ),
    ),
    DesignInventoryEntry.present(
      'Link',
      (_) => const NeumorphicLink('View details', onPressed: _none),
    ),
    DesignInventoryEntry.present(
      'Kbd',
      (_) => const NeumorphicKbd(['Ctrl', 'K']),
    ),
    // Inputs
    DesignInventoryEntry.present(
      'TextField',
      (_) => const NeumorphicTextField(label: 'Name', initialValue: 'Marta'),
    ),
    DesignInventoryEntry.present(
      'TextArea',
      (_) => const NeumorphicTextArea(label: 'Notes'),
    ),
    DesignInventoryEntry.present(
      'SearchField',
      (_) => const NeumorphicSearchField(hint: 'Find a room'),
    ),
    DesignInventoryEntry.present(
      'PasswordField',
      (_) => const NeumorphicPasswordField(label: 'Password'),
    ),
    DesignInventoryEntry.present(
      'InputGroup',
      (_) => const NeumorphicInputGroup(
        label: 'Website',
        prefix: 'https://',
        keyboardType: TextInputType.url,
        suffix: '.com',
      ),
    ),
    DesignInventoryEntry.present(
      'InputOtp',
      (_) => const NeumorphicInputOtp(label: 'Code', length: 6),
    ),
    DesignInventoryEntry.present(
      'NumberField',
      (_) => const NeumorphicNumberField(
        value: '2',
        unit: 'Lamps',
        onIncrease: _none,
        onDecrease: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'Select',
      (_) => const NeumorphicSelect<String>(
        label: 'Room',
        value: 'bed',
        options: [
          NeumorphicMenuItem('bed', 'Bedroom'),
          NeumorphicMenuItem('study', 'Study'),
        ],
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Combobox',
      (_) => const NeumorphicCombobox<String>(
        label: 'Room',
        hint: 'Type or choose a room',
        options: ['Bedroom', 'Kitchen', 'Study', 'Hall'],
      ),
    ),
    DesignInventoryEntry.present(
      'MultiSelect',
      (_) => const NeumorphicMultiSelect<String>(
        label: 'Rooms',
        values: ['Bedroom'],
        onChanged: _drop,
        options: ['Bedroom', 'Kitchen', 'Study'],
      ),
    ),
    DesignInventoryEntry.present(
      'Checkbox',
      (_) => const NeumorphicCheckbox(
        label: 'Dim at dusk',
        value: true,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'RadioGroup',
      (_) => const NeumorphicRadioGroup<String>(
        label: 'Room',
        value: 'bed',
        options: [
          NeumorphicRadio('bed', 'Bedroom'),
          NeumorphicRadio('study', 'Study'),
        ],
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Switch',
      (_) => const NeumorphicSwitch(
        label: 'Night light',
        value: true,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Slider',
      (_) =>
          const NeumorphicSlider(label: 'Warmth', value: .5, onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'RangeSlider',
      (_) => const NeumorphicRangeSlider(
        label: 'Comfort',
        values: DesignRangeValues(18, 22),
        min: 12,
        max: 28,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'SegmentedButton',
      (_) => const NeumorphicSegmentedButton<String>(
        label: 'View',
        value: 'day',
        segments: [
          NeumorphicButtonSegment('day', 'Day'),
          NeumorphicButtonSegment('week', 'Week'),
        ],
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Chip',
      (_) => const NeumorphicChip('Warm white', onPressed: _none),
    ),
    DesignInventoryEntry.present(
      'Rating',
      (_) => const NeumorphicRating(label: 'Sleep', value: 4, onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'FileUpload',
      (_) => const NeumorphicFileUpload(onPressed: _none, hint: 'PDF or JPG'),
    ),
    DesignInventoryEntry.present(
      'DatePicker',
      (_) =>
          NeumorphicDatePicker(value: DateTime(2026, 6, 14), onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'DateRangePicker',
      (_) => NeumorphicDateRangePicker(controller: _stay),
    ),
    DesignInventoryEntry.present(
      'TimePicker',
      (_) => const NeumorphicTimePicker(onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'Calendar',
      (_) => NeumorphicCalendar(controller: _day),
    ),
    DesignInventoryEntry.present(
      'WheelPicker',
      (_) => const NeumorphicWheelPicker<int>(
        label: 'Lamps',
        items: [1, 2, 3, 4, 5, 6],
        value: 2,
        onChanged: _drop,
        rows: 3,
      ),
    ),
    DesignInventoryEntry.present(
      'ColorPicker',
      (context) => NeumorphicColorPicker(
        controller: _colour ??= DesignColorController(
          NeumorphicTheme.of(context).colors.pigment,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'FormField',
      (_) => const NeumorphicFormField(
        label: 'Email',
        help: 'The receipt goes here',
        required: true,
        child: NeumorphicTextField(hint: 'name@example.com'),
      ),
    ),
    // Navigation
    DesignInventoryEntry.present(
      'AppBar',
      (_) => const NeumorphicAppBar(title: 'Tonight'),
    ),
    DesignInventoryEntry.present(
      'NavigationBar',
      (_) => const NeumorphicNavigationBar(
        items: [_home, _rooms, _sleep],
        onDestinationSelected: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationRail',
      (_) => const NeumorphicNavigationRail(
        items: [_home, _rooms, _sleep],
        onDestinationSelected: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationDrawer',
      (_) => const NeumorphicNavigationDrawer(
        items: [_home, _rooms, _sleep],
        onDestinationSelected: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'TabBar',
      (_) => NeumorphicTabBar(
        tabs: const ['Day', 'Week', 'Month'],
        label: 'Span',
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Breadcrumb',
      (_) => NeumorphicBreadcrumb(
        crumbs: const [
          NeumorphicCrumb('Home', onPressed: _none),
          NeumorphicCrumb('Upstairs', onPressed: _none),
          NeumorphicCrumb('Bedroom'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Pagination',
      (_) => const NeumorphicPagination(count: 12, page: 4, onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'StepProgress',
      (_) =>
          const NeumorphicStepProgress(count: 3, currentStep: 1, name: 'Setup'),
    ),
    DesignInventoryEntry.present(
      'PageDots',
      (_) => const NeumorphicPageDots(
        count: 4,
        selectedIndex: 1,
        label: 'Rooms',
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'MenuBar',
      (_) => const NeumorphicMenuBar(
        menus: [
          DesignMenuEntry(
            label: 'Scene',
            children: [
              DesignMenuEntry(
                label: 'New scene',
                shortcut: 'Ctrl N',
                onPressed: _none,
              ),
              DesignMenuEntry(label: 'Print', onPressed: _none),
            ],
          ),
          DesignMenuEntry(
            label: 'View',
            children: [
              DesignMenuEntry(label: 'Rooms', checked: true, onPressed: _none),
            ],
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Command',
      (_) => const NeumorphicCommand(
        maxHeight: 200,
        commands: [
          DesignCommand(
            label: 'New scene',
            group: 'Scenes',
            shortcut: 'Ctrl N',
          ),
          DesignCommand(label: 'Find a room', group: 'Rooms'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Scaffold',
      (_) => const NeumorphicScaffold(
        scroll: false,
        topBar: NeumorphicAppBar(title: 'Tonight'),
        body: Text('Two lamps on'),
      ),
    ),
    // Containers
    DesignInventoryEntry.present(
      'Card',
      (_) => const NeumorphicCard(
        title: 'Bedroom',
        children: [Text('19 degrees, two lamps')],
      ),
    ),
    DesignInventoryEntry.present(
      'ListTile',
      (_) => const NeumorphicListTile(
        title: 'Bedroom',
        subtitle: 'Two lamps',
        onPressed: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'ListSection',
      (_) => const NeumorphicListSection(
        label: 'Rooms',
        children: [
          NeumorphicListTile(title: 'Bedroom', isFirst: true),
          NeumorphicListTile(title: 'Study'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'SectionHeader',
      (_) => const NeumorphicSectionHeader(title: 'Tonight'),
    ),
    DesignInventoryEntry.present(
      'Disclosure',
      (_) => const NeumorphicDisclosure(
        title: 'House rules',
        child: Text('Quiet after ten'),
      ),
    ),
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'DataTable',
      (_) => NeumorphicDataTable<_Room>(
        label: 'Rooms',
        controller: _table,
        cell: (r, column) => column.id == 'room' ? r.name : '${r.heat}',
      ),
    ),
    DesignInventoryEntry.present('Divider', (_) => const NeumorphicDivider()),
    DesignInventoryEntry.present(
      'ScrollArea',
      (_) => NeumorphicScrollArea(
        controller: _scroll,
        label: 'Rooms',
        child: ListView(
          controller: _scroll,
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
    DesignInventoryEntry.present(
      'Resizable',
      (_) => const NeumorphicResizable(
        first: Text('Rooms'),
        second: Text('Bedroom'),
      ),
    ),
    DesignInventoryEntry.present('CarouselView', (context) {
      final c = NeumorphicTheme.of(context).colors;
      // Each slide is its room by its mark, on the one material: tinted in hues of their own the slides wore colours
      // the theme does not hold.
      Widget slide(String title, String line, IconData glyph) => NeumorphicCard(
        title: title,
        trailing: Icon(glyph, size: 20, color: c.inkSecondary),
        children: [Text(line)],
      );
      return NeumorphicCarouselView(
        label: 'Rooms',
        height: 132,
        initialPage: 1,
        children: [
          slide('Bedroom', '19°, lamp low', NeumorphicGlyphs.lamp),
          slide('Study', '20.5°, reading', NeumorphicGlyphs.bookOpen),
          slide('Hall', '18°, quiet', NeumorphicGlyphs.doorOpen),
        ],
      );
    }),
    DesignInventoryEntry.present(
      'ReorderableListView',
      (_) => NeumorphicReorderableListView<String>(
        items: const ['Bedroom', 'Study', 'Hall'],
        labelOf: (s) => s,
        onReorder: (from, to) {},
        itemBuilder: (context, s) => Text(s),
      ),
    ),
    DesignInventoryEntry.present(
      'SwipeActions',
      (_) => const NeumorphicSwipeActions(
        endActions: [DesignSwipeAction(label: 'Archive', onPressed: _none)],
        child: NeumorphicListTile(
          title: 'Bedroom',
          subtitle: 'Swipe for actions',
        ),
      ),
    ),
    DesignInventoryEntry.absent(
      'RefreshIndicator',
      'its spinner sat over the list\'s first row; a pull to refresh that opens a gap at the top of the list comes in 0.2.0',
    ),
    DesignInventoryEntry.present(
      'TreeView',
      (_) => NeumorphicTreeView<String>(
        label: 'Rooms',
        controller: _places,
        labelOf: (n) => n,
      ),
    ),
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'Avatar',
      (_) => const NeumorphicAvatar('MR', name: 'Marta Rossi'),
    ),
    DesignInventoryEntry.present(
      'AvatarGroup',
      (_) => const NeumorphicAvatarGroup([
        NeumorphicFace('MR'),
        NeumorphicFace('TB'),
        NeumorphicFace('IV'),
      ]),
    ),
    DesignInventoryEntry.present('Badge', (_) => const NeumorphicBadge(3)),
    DesignInventoryEntry.present('Tag', (_) => const NeumorphicTag('Warm')),
    DesignInventoryEntry.present(
      'Media',
      (_) =>
          const NeumorphicMedia(label: 'Bedroom', glyph: NeumorphicGlyphs.lamp),
    ),
    DesignInventoryEntry.present(
      'EmptyState',
      (_) => const NeumorphicEmptyState(
        title: 'All quiet',
        body: 'No rooms are on.',
      ),
    ),
    DesignInventoryEntry.present(
      'DescriptionList',
      (_) => const NeumorphicDescriptionList([
        NeumorphicDescription('Lights out', '22:30'),
        NeumorphicDescription('Lamps', '2'),
      ]),
    ),
    // Overlays
    DesignInventoryEntry.present(
      'Dialog',
      (_) => const NeumorphicDialog(
        title: 'Remove the scene?',
        message: 'The rooms keep their settings.',
      ),
    ),
    DesignInventoryEntry.present(
      'BottomSheet',
      (_) => const NeumorphicBottomSheet(
        title: 'Bedroom',
        showClose: false,
        inPlace: true,
        child: Text('Two lamps'),
      ),
    ),
    DesignInventoryEntry.present(
      'Sheet',
      (_) => const NeumorphicSheet(title: 'Filters', child: Text('Warm white')),
    ),
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'Popover',
      (_) => NeumorphicPopover(
        label: 'Lights out',
        trigger: (context, toggle) =>
            NeumorphicButton('When', onPressed: toggle),
        content: const Text('At half past ten, every night.'),
      ),
    ),
    DesignInventoryEntry.present(
      'HoverCard',
      (_) => const NeumorphicHoverCard(
        content: Text('Asleep by eleven, most nights'),
        child: NeumorphicLink('Marta Rossi', onPressed: _none),
      ),
    ),
    DesignInventoryEntry.present(
      'Tooltip',
      (_) => const NeumorphicTooltip(
        message: 'Share',
        child: Icon(NeumorphicGlyphs.share2),
      ),
    ),
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'SnackBar',
      (_) => const NeumorphicSnackBar(
        'Scene saved',
        actionLabel: 'Undo',
        onAction: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'Banner',
      (_) =>
          const NeumorphicBanner('The hall lamp is changing.', title: 'Note'),
    ),
    // Feedback
    DesignInventoryEntry.present(
      'LinearProgressIndicator',
      (_) =>
          const NeumorphicLinearProgressIndicator(value: .6, label: 'Upload'),
    ),
    DesignInventoryEntry.present(
      'CircularProgressIndicator',
      (_) =>
          const NeumorphicCircularProgressIndicator(value: .6, label: 'Upload'),
    ),
    DesignInventoryEntry.present(
      'Skeleton',
      (_) => const NeumorphicSkeleton.lines(3),
    ),
    DesignInventoryEntry.present(
      'StatusView',
      (_) => const NeumorphicStatusView.loading(),
    ),
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'LineChart',
      (_) => const NeumorphicLineChart(
        label: 'Hours slept',
        height: 140,
        labels: ['Mon', 'Tue', 'Wed', 'Thu'],
        series: [
          NeumorphicChartSeries('Hours', [7, 8, 6, 7.5]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'BarChart',
      (_) => const NeumorphicBarChart(
        label: 'Lamp hours',
        height: 140,
        labels: ['June', 'July', 'August'],
        series: [
          NeumorphicChartSeries('Bedroom', [4, 6, 5]),
          NeumorphicChartSeries('Study', [3, 5, 7]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'AreaChart',
      (_) => const NeumorphicAreaChart(
        label: 'Warmth',
        height: 140,
        labels: ['Mon', 'Tue', 'Wed', 'Thu'],
        series: [
          NeumorphicChartSeries('Warmth', [18, 20, 19, 21]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'PieChart',
      (_) => const NeumorphicPieChart(
        label: 'Rooms',
        caption: 'rooms',
        slices: [NeumorphicPieSlice('On', 3), NeumorphicPieSlice('Off', 5)],
      ),
    ),
    DesignInventoryEntry.present(
      'Sparkline',
      (_) => const NeumorphicSparkline(
        label: 'Hours slept',
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
    return DesignInventoryGallery(
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
                    ? DesignInventory.absentLabel(entry!.absentReason!)
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
}
