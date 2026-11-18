/// Studio's answer to the component inventory: a live specimen for every
/// row. [StudioInventory.registry] is what the look's test verifies and
/// what an inventory gallery lists.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../actions.dart';
import '../button.dart';
import '../charts.dart';
import '../choices.dart';
import '../collections.dart';
import '../controls.dart';
import '../display.dart';
import '../entry.dart';
import '../feedback.dart';
import '../lists.dart';
import '../menu.dart';
import '../navigation.dart';
import '../overlays.dart';
import '../panel.dart';
import '../pickers.dart';
import '../popovers.dart';
import '../select.dart';
import '../surface.dart';
import '../text_field.dart';
import '../theme.dart';
import '../wayfinding.dart';

void _none() {}

void _ignore(Object? _) {}

const _places = [
  StudioDestination(icon: Icon(LucideIcons.house), label: 'Home'),
  StudioDestination(icon: Icon(LucideIcons.library), label: 'Library'),
  StudioDestination(icon: Icon(LucideIcons.mic), label: 'Record'),
];

final _first = DateTime(2026, 11);
final _last = DateTime(2026, 12, 31);

DesignInventoryEntry _row(String id, WidgetBuilder builder) =>
    DesignInventoryEntry.present(id, builder);

/// Studio's inventory: every row of [DesignInventoryRow.all] answered with
/// a live specimen.
abstract final class StudioInventory {
  /// The registry.
  static final DesignInventory registry = _registry();
}

DesignInventory _registry() => DesignInventory(
  look: 'Studio',
  entries: [
    // Actions.
    _row('Button', (_) => const StudioButton('Play trailer', onPressed: _none)),
    _row(
      'IconButton',
      (_) => const StudioIconButton(
        onPressed: _none,
        icon: Icon(LucideIcons.heart),
        tooltip: 'Save',
      ),
    ),
    _row(
      'FloatingActionButton',
      (_) => const StudioFloatingKey(
        onPressed: _none,
        icon: Icon(LucideIcons.mic),
        tooltip: 'New recording',
      ),
    ),
    _row(
      'ButtonGroup',
      (_) => const StudioKeyRow(
        semanticLabel: 'Clip',
        items: [
          StudioKeyRowItem(label: 'Cut', onPressed: _none),
          StudioKeyRowItem(label: 'Split', onPressed: _none),
          StudioKeyRowItem(label: 'Fade', onPressed: _none),
        ],
      ),
    ),
    _row(
      'ToggleGroup',
      (_) => StudioToggleBank<String>(
        options: const ['Mute', 'Solo', 'Arm'],
        selected: const {'Solo'},
        onSelectionChanged: _ignore,
        labelOf: (s) => s,
      ),
    ),
    _row(
      'SplitButton',
      (_) => const StudioSplitKey(
        label: 'Export',
        onPressed: _none,
        actions: [StudioMenuItem(label: 'Export as WAV', onPressed: _none)],
      ),
    ),
    _row('Link', (_) => const StudioLink('Show notes', onPressed: _none)),
    _row(
      'Kbd',
      (_) => const StudioKbd.shortcut(
        SingleActivator(LogicalKeyboardKey.keyK, control: true),
      ),
    ),
    // Inputs.
    _row('TextField', (_) => const StudioTextField(label: 'Episode title')),
    _row(
      'TextArea',
      (_) =>
          const StudioTextField(label: 'Show notes', maxLines: 5, minLines: 3),
    ),
    _row('SearchField', (_) => const StudioSearchField(hint: 'Search shows')),
    _row('PasswordField', (_) => const StudioPasswordField(label: 'Password')),
    _row(
      'InputGroup',
      (_) => const StudioInputGroup(
        label: 'Feed address',
        leading: Text('https://'),
        hint: 'roomtone.example/feed',
      ),
    ),
    _row('InputOtp', (_) => const StudioCodeField(label: 'Sign-in code')),
    _row(
      'NumberField',
      (_) => const StudioStepper(
        value: 2,
        semanticLabel: 'Takes',
        onChanged: _ignore,
      ),
    ),
    _row(
      'Select',
      (_) => const StudioSelect<String>(
        label: 'Quality',
        value: 'High',
        items: [
          StudioSelectItem(value: 'Standard', label: 'Standard'),
          StudioSelectItem(value: 'High', label: 'High'),
        ],
        onChanged: _ignore,
      ),
    ),
    _row(
      'Combobox',
      (_) => StudioCombobox<String>(
        label: 'Show',
        options: const ['Night Desk', 'Field Notes', 'Long Table'],
        labelOf: (s) => s,
        onSelected: _ignore,
      ),
    ),
    _row(
      'MultiSelect',
      (_) => StudioTagInput<String>(
        label: 'Topics',
        values: const ['Interviews'],
        options: const ['Interviews', 'Science', 'Music'],
        labelOf: (s) => s,
        onChanged: _ignore,
      ),
    ),
    _row(
      'Checkbox',
      (_) => const StudioCheckbox(
        value: true,
        onChanged: _ignore,
        semanticLabel: 'Explicit',
      ),
    ),
    _row(
      'RadioGroup',
      (_) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StudioRadio<int>(
            value: 1,
            groupValue: 1,
            onChanged: _ignore,
            semanticLabel: 'Mono',
          ),
          SizedBox(width: StudioSpacing.regular),
          StudioRadio<int>(
            value: 2,
            groupValue: 1,
            onChanged: _ignore,
            semanticLabel: 'Stereo',
          ),
        ],
      ),
    ),
    _row(
      'Switch',
      (_) => const StudioSwitch(
        value: true,
        onChanged: _ignore,
        semanticLabel: 'Auto-download',
      ),
    ),
    _row(
      'Slider',
      (_) => const StudioFader(
        value: 0.4,
        onChanged: _ignore,
        semanticLabel: 'Volume',
      ),
    ),
    _row(
      'RangeSlider',
      (_) => const StudioRangeFader(
        values: StudioRangeValues(10, 40),
        max: 60,
        startLabel: 'Shortest',
        endLabel: 'Longest',
        onChanged: _ignore,
      ),
    ),
    _row(
      'SegmentedButton',
      (_) => const StudioSegmentedButton<double>(
        segments: [
          StudioSegment(value: 1, label: '1×'),
          StudioSegment(value: 1.5, label: '1.5×'),
          StudioSegment(value: 2, label: '2×'),
        ],
        value: 1,
        onChanged: _ignore,
      ),
    ),
    _row(
      'Chip',
      (_) => const StudioChip(
        label: 'Interviews',
        selected: true,
        onSelected: _ignore,
      ),
    ),
    _row(
      'Rating',
      (_) => const StudioRating(
        value: 4,
        semanticLabel: 'Your rating',
        onChanged: _ignore,
      ),
    ),
    _row(
      'FileUpload',
      (_) => const StudioFileDrop(
        label: 'Audio',
        hint: 'WAV or MP3, up to 500 MB',
        onChoose: _none,
        files: [StudioFile(name: 'take-3.wav', bytes: 48200000, progress: 0.4)],
      ),
    ),
    _row(
      'DatePicker',
      (_) => StudioDatePicker(
        label: 'Release date',
        value: DateTime(2026, 11, 20),
        firstDate: _first,
        lastDate: _last,
        onChanged: _ignore,
      ),
    ),
    _row(
      'DateRangePicker',
      (_) => StudioDateRangePicker(
        label: 'Recording days',
        value: StudioDateRange(
          start: DateTime(2026, 11, 14),
          end: DateTime(2026, 11, 16),
        ),
        firstDate: _first,
        lastDate: _last,
        onChanged: _ignore,
      ),
    ),
    _row(
      'TimePicker',
      (_) => const StudioTimePicker(
        value: StudioTime(hour: 9, minute: 30),
        semanticLabel: 'Goes out at',
        onChanged: _ignore,
      ),
    ),
    _row(
      'Calendar',
      (_) => SizedBox(
        width: 320,
        child: StudioCalendar(
          firstDate: _first,
          lastDate: _last,
          selectedDate: DateTime(2026, 11, 20),
          currentDate: DateTime(2026, 11, 16),
          onDateChanged: _ignore,
        ),
      ),
    ),
    _row(
      'WheelPicker',
      (_) => StudioWheelPicker<int>(
        items: const [1, 2, 3, 4, 5, 6],
        value: 3,
        labelOf: (n) => '$n',
        semanticLabel: 'Takes',
        onChanged: _ignore,
      ),
    ),
    _row(
      'ColorPicker',
      (_) => const SizedBox(
        width: 300,
        child: StudioColorPicker(value: Color(0xFFE08A1E), onChanged: _ignore),
      ),
    ),
    _row(
      'FormField',
      (_) => const StudioFormField(
        label: 'Episode type',
        helper: 'Trailers play before the first episode.',
        child: StudioSegmentedButton<int>(
          semanticLabel: 'Episode type',
          segments: [
            StudioSegment(value: 0, label: 'Full'),
            StudioSegment(value: 1, label: 'Trailer'),
          ],
          value: 0,
          onChanged: _ignore,
        ),
      ),
    ),
    // Navigation.
    _row('AppBar', (_) => const StudioAppBar(title: 'Library')),
    _row(
      'NavigationBar',
      (_) => const StudioNavigationBar(
        destinations: _places,
        selectedIndex: 0,
        onDestinationSelected: _ignore,
      ),
    ),
    _row(
      'NavigationRail',
      (_) => const SizedBox(
        height: 320,
        child: StudioNavigationRail(
          destinations: _places,
          selectedIndex: 1,
          onDestinationSelected: _ignore,
        ),
      ),
    ),
    _row(
      'NavigationDrawer',
      (_) => const SizedBox(
        height: 320,
        width: 260,
        child: StudioSideNavigation(
          destinations: _places,
          selectedIndex: 2,
          onDestinationSelected: _ignore,
        ),
      ),
    ),
    _row(
      'TabBar',
      (_) => const StudioTabBar(
        tabs: ['Episodes', 'About', 'Clips'],
        selectedIndex: 0,
        onChanged: _ignore,
      ),
    ),
    _row(
      'Breadcrumb',
      (_) => const StudioBreadcrumb(
        crumbs: [
          StudioCrumb('Library', onPressed: _none),
          StudioCrumb('Night Desk', onPressed: _none),
          StudioCrumb('Episode 12'),
        ],
      ),
    ),
    _row(
      'Pagination',
      (_) => const StudioPagination(page: 3, pageCount: 12, onChanged: _ignore),
    ),
    _row(
      'StepProgress',
      (_) => const StudioStepProgress(
        steps: ['Record', 'Edit', 'Publish'],
        current: 1,
      ),
    ),
    _row(
      'PageDots',
      (_) => const StudioPageDots(count: 4, index: 1, onChanged: _ignore),
    ),
    _row(
      'MenuBar',
      (_) => const StudioMenuBar(
        menus: [
          StudioMenuBarMenu('Episode', [
            StudioMenuItem(label: 'New', shortcut: 'Ctrl N', onPressed: _none),
          ]),
          StudioMenuBarMenu('Edit', [
            StudioMenuItem(label: 'Undo', shortcut: 'Ctrl Z', onPressed: _none),
          ]),
        ],
      ),
    ),
    _row(
      'Command',
      (_) => const StudioCommandPalette(
        commands: [
          StudioCommand(
            label: 'New episode',
            group: 'Episodes',
            onPressed: _none,
          ),
          StudioCommand(
            label: 'Start recording',
            group: 'Record',
            onPressed: _none,
          ),
        ],
      ),
    ),
    _row(
      'Scaffold',
      (_) => const SizedBox(
        height: 360,
        child: StudioScaffold(
          appBar: StudioAppBar(title: 'Home'),
          destinations: _places,
          body: Center(child: Text('Your shows')),
        ),
      ),
    ),
    // Containers.
    _row(
      'Card',
      (_) => const StudioPanel(child: Text('Night Desk, episode 12')),
    ),
    _row('ListTile', (_) => const StudioListTile(title: 'Downloads')),
    _row(
      'ListSection',
      (_) => const StudioListGroup(
        header: 'Playback',
        children: [
          StudioListTile(title: 'Skip silences'),
          StudioListTile(title: 'Speed', trailingText: '1.5×'),
        ],
      ),
    ),
    _row('SectionHeader', (_) => const StudioSectionHeader('Up next')),
    _row(
      'Disclosure',
      (_) => const StudioDisclosure(
        title: 'Show notes',
        initiallyExpanded: true,
        child: Text('Recorded in one take, at night.'),
      ),
    ),
    _row(
      'Table',
      (_) => const StudioTable(
        columns: [
          StudioTableColumn('Episode'),
          StudioTableColumn('Plays', numeric: true),
        ],
        rows: [
          ['Pilot', '1,204'],
          ['The long table', '864'],
        ],
      ),
    ),
    _row('DataTable', (_) => const _DataTableSpecimen()),
    _row('Divider', (_) => const StudioGroove()),
    _row('ScrollArea', (_) => const _ScrollSpecimen()),
    _row(
      'Resizable',
      (_) => const SizedBox(
        height: 160,
        child: StudioSplitView(
          minFirst: 60,
          minSecond: 60,
          first: Center(child: Text('Episodes')),
          second: Center(child: Text('Notes')),
        ),
      ),
    ),
    _row(
      'CarouselView',
      (_) => StudioCarousel(
        itemCount: 3,
        semanticLabel: 'Featured shows',
        itemBuilder: (context, i) => Center(child: Text('Show ${i + 1}')),
      ),
    ),
    _row('ReorderableListView', (_) => const _ReorderSpecimen()),
    _row(
      'SwipeActions',
      (_) => const StudioSwipeRow(
        endActions: [
          StudioSwipeAction(
            label: 'Delete',
            icon: Icon(LucideIcons.trash2),
            destructive: true,
            onPressed: _none,
          ),
        ],
        child: StudioListTile(title: 'Episode 11'),
      ),
    ),
    _row(
      'RefreshIndicator',
      (_) => SizedBox(
        height: 200,
        child: StudioPullToRefresh(
          onRefresh: () async {},
          child: ListView(
            children: const [
              StudioListTile(title: 'Episode 12'),
              StudioListTile(title: 'Episode 11'),
            ],
          ),
        ),
      ),
    ),
    _row('TreeView', (_) => const _TreeSpecimen()),
    _row(
      'Timeline',
      (_) => const StudioTimeline(
        entries: [
          StudioTimelineEntry(title: 'Recorded', time: 'Mon 14:00', done: true),
          StudioTimelineEntry(title: 'Edited', time: 'Tue 10:00', done: true),
          StudioTimelineEntry(title: 'Published', time: 'Thu 09:00'),
        ],
      ),
    ),
    _row('Avatar', (_) => const StudioAvatar(name: 'Noor Haddad')),
    _row(
      'AvatarGroup',
      (_) => const StudioAvatarGroup(
        names: [
          'Noor Haddad',
          'Teo Park',
          'Ama Boateng',
          'Lis Varga',
          'Ike Moss',
        ],
      ),
    ),
    _row(
      'Badge',
      (_) => const StudioBadge(count: 3, child: Icon(LucideIcons.bell)),
    ),
    _row('Tag', (_) => const StudioTag('On air', tone: StudioTagTone.lit)),
    _row(
      'Media',
      (_) => const SizedBox(
        width: 320,
        child: StudioMedia(image: null, semanticLabel: 'The cover'),
      ),
    ),
    _row(
      'EmptyState',
      (_) => const StudioStatusView(
        title: 'No episodes yet',
        message: 'Record one, or import a file.',
        actionLabel: 'Record',
        onAction: _none,
      ),
    ),
    _row(
      'DescriptionList',
      (_) => const StudioDescriptionList(
        entries: [
          StudioDescription('Length', '42 min'),
          StudioDescription('Format', 'Stereo, 48 kHz'),
        ],
      ),
    ),
    // Overlays.
    _row(
      'Dialog',
      (_) => const StudioDialog(
        title: 'Discard this take?',
        content: Text('It has not been saved.'),
        actions: [
          StudioButton.text('Keep', onPressed: _none),
          StudioButton('Discard', isDestructiveAction: true, onPressed: _none),
        ],
      ),
    ),
    _row(
      'BottomSheet',
      (_) => const StudioSheet(title: 'Speed', child: Text('1.5×')),
    ),
    _row(
      'Sheet',
      (context) => StudioButton(
        'Filters',
        onPressed: () => showStudioSideSheet<void>(
          context: context,
          title: 'Filters',
          builder: (_) => const Text('Unplayed only'),
        ),
      ),
    ),
    _row(
      'ActionSheet',
      (context) => StudioButton(
        'This take',
        onPressed: () => showStudioActionSheet<String>(
          context: context,
          title: 'This take',
          actions: const [
            StudioSheetAction(label: 'Keep', value: 'keep'),
            StudioSheetAction(
              label: 'Discard',
              value: 'discard',
              isDestructiveAction: true,
            ),
          ],
        ),
      ),
    ),
    _row(
      'Popover',
      (_) => StudioPopover(
        semanticLabel: 'Speed',
        builder: (context, toggle, open) =>
            StudioButton('Speed', onPressed: toggle),
        content: (context, close) => const Text('1.5×'),
      ),
    ),
    _row(
      'HoverCard',
      (_) => StudioHoverCard(
        content: (context) => const Text('Host of Night Desk since 2024.'),
        child: const StudioLink('Noor Haddad', onPressed: _none),
      ),
    ),
    _row(
      'Tooltip',
      (_) => const StudioTooltip(
        message: 'Skip back 15 seconds',
        child: StudioIconButton(
          icon: Icon(LucideIcons.rotateCcw),
          tooltip: 'Skip back',
          onPressed: _none,
        ),
      ),
    ),
    _row(
      'Menu',
      (_) => StudioMenu(
        semanticLabel: 'Episode',
        items: const [
          StudioMenuItem(label: 'Rename', onPressed: _none),
          StudioMenuItem(
            label: 'Delete',
            isDestructiveAction: true,
            onPressed: _none,
          ),
        ],
        builder: (context, toggle, open) => StudioIconButton(
          icon: const Icon(LucideIcons.ellipsis),
          tooltip: 'More',
          selected: open,
          onPressed: toggle,
        ),
      ),
    ),
    _row(
      'SnackBar',
      (context) => StudioButton(
        'Add a marker',
        onPressed: () => showStudioToast(
          context,
          'Marker added at 12:04',
          actionLabel: 'Undo',
          onAction: _none,
        ),
      ),
    ),
    _row(
      'Banner',
      (_) => const StudioBanner(
        message: 'A new mix of episode 12 is ready.',
        actionLabel: 'Listen',
        onAction: _none,
        onClose: _none,
      ),
    ),
    // Feedback.
    _row(
      'LinearProgressIndicator',
      (_) => const StudioProgressBar(value: 0.6, semanticLabel: 'Uploading'),
    ),
    _row(
      'CircularProgressIndicator',
      (_) => const StudioSpinner(semanticLabel: 'Loading'),
    ),
    _row(
      'Skeleton',
      (_) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudioSkeleton(width: 220),
          SizedBox(height: StudioSpacing.small),
          StudioSkeleton(width: 160),
        ],
      ),
    ),
    _row(
      'StatusView',
      (_) => const StudioStatusView.error(
        title: 'Upload failed',
        message: 'The connection dropped at 64%.',
        actionLabel: 'Try again',
        onAction: _none,
      ),
    ),
    _row(
      'Meter',
      (_) => const StudioMeter(level: 0.6, peak: 0.8, semanticLabel: 'Input'),
    ),
    // Charts.
    _row(
      'LineChart',
      (_) => const StudioLineChart(
        semanticLabel: 'Plays by day',
        labels: ['Mon', 'Tue', 'Wed'],
        series: [
          StudioSeries('Plays', [120, 180, 150]),
        ],
      ),
    ),
    _row(
      'BarChart',
      (_) => const StudioBarChart(
        semanticLabel: 'Downloads by episode',
        labels: ['10', '11', '12'],
        series: [
          StudioSeries('Downloads', [340, 410, 290]),
        ],
      ),
    ),
    _row(
      'AreaChart',
      (_) => const StudioAreaChart(
        semanticLabel: 'Listeners',
        labels: ['Mon', 'Tue', 'Wed'],
        series: [
          StudioSeries('Listeners', [820, 940, 760]),
        ],
      ),
    ),
    _row(
      'PieChart',
      (_) => const StudioPieChart(
        semanticLabel: 'Listening by device',
        slices: [
          StudioSlice('Phone', 62),
          StudioSlice('Desktop', 28),
          StudioSlice('Speaker', 10),
        ],
      ),
    ),
    _row(
      'Sparkline',
      (_) => const StudioSparkline(
        semanticLabel: 'Plays this week, rising',
        values: [3, 5, 4, 8, 7, 11],
      ),
    ),
  ],
);

class _Episode {
  const _Episode(this.title, this.plays);
  final String title;
  final int plays;
}

class _DataTableSpecimen extends StatefulWidget {
  const _DataTableSpecimen();

  @override
  State<_DataTableSpecimen> createState() => _DataTableSpecimenState();
}

class _DataTableSpecimenState extends State<_DataTableSpecimen> {
  final _table = StudioTableController<_Episode>(
    rows: const [_Episode('Pilot', 1204), _Episode('The long table', 864)],
    rowKey: (e) => e.title,
    columns: [
      StudioDataColumn(id: 'title', label: 'Episode', sortKey: (e) => e.title),
      StudioDataColumn(
        id: 'plays',
        label: 'Plays',
        sortKey: (e) => e.plays,
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
  Widget build(BuildContext context) => StudioDataTable<_Episode>(
    controller: _table,
    cell: (e, column) => column == 'title' ? e.title : '${e.plays}',
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
    child: StudioScrollArea(
      controller: _scroll,
      child: ListView(
        controller: _scroll,
        children: [
          for (var i = 1; i <= 12; i++) StudioListTile(title: 'Episode $i'),
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
  final _queue = ['Night Desk 12', 'Field Notes 4', 'Long Table 9'];

  @override
  Widget build(BuildContext context) => StudioReorderableList<String>(
    items: _queue,
    labelOf: (a) => a,
    onReorder: (from, to) =>
        setState(() => _queue.insert(to, _queue.removeAt(from))),
    itemBuilder: (context, a) => Text(a),
  );
}

class _Folder {
  const _Folder(this.name, [this.children = const []]);
  final String name;
  final List<_Folder> children;
}

class _TreeSpecimen extends StatefulWidget {
  const _TreeSpecimen();

  @override
  State<_TreeSpecimen> createState() => _TreeSpecimenState();
}

class _TreeSpecimenState extends State<_TreeSpecimen> {
  static const _roots = [
    _Folder('Season 2', [_Folder('Raw takes'), _Folder('Mixes')]),
    _Folder('Season 1', [_Folder('Archive')]),
  ];

  final _tree = StudioTreeController<_Folder>(
    roots: _roots,
    childrenOf: (f) => f.children,
    expanded: [_roots.first],
  );

  @override
  void dispose() {
    _tree.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      StudioTree<_Folder>(controller: _tree, labelOf: (f) => f.name);
}
