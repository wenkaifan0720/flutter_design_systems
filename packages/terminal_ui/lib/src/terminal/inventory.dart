/// Terminal's answer to ui_core's inventory: for each of the components
/// every look names alike, Terminal's part, built live, or why the look
/// leaves it out (five that would make its structure move or leave the
/// grid). [TermInventoryGallery] lists them, group by group.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/inventory.dart';

import 'components/actions.dart';
import 'components/button.dart';
import 'components/charts.dart';
import 'components/chips.dart';
import 'components/command_palette.dart';
import 'components/containers.dart';
import 'components/dialog.dart';
import 'components/feedback.dart';
import 'components/inputs.dart';
import 'components/key_hint.dart';
import 'components/list_tile.dart';
import 'components/navigation.dart';
import 'components/notice.dart';
import 'components/overlays.dart';
import 'components/pane.dart';
import 'components/pickers.dart';
import 'components/range.dart';
import 'components/select.dart';
import 'components/selection.dart';
import 'components/status.dart';
import 'components/text_field.dart';
import 'components/wayfinding.dart';
import 'theme.dart';

/// Every inventory row: Terminal's part for it, live, or the reason it
/// has none.
///
/// ```dart
/// termInventory.verify();
/// ```
const DesignInventory termInventory = DesignInventory(
  look: 'Terminal',
  entries: <DesignInventoryEntry>[
    // Actions
    DesignInventoryEntry.present('Button', _button),
    DesignInventoryEntry.present('IconButton', _iconButton),
    DesignInventoryEntry.absent(
      'FloatingActionButton',
      'a terminal floats nothing over its text: the screen\'s main action '
          'is the filled [ button ] in its top bar or at its foot, with its '
          'key in the status line',
    ),
    DesignInventoryEntry.present('ButtonGroup', _buttonGroup),
    DesignInventoryEntry.present('ToggleGroup', _toggleGroup),
    DesignInventoryEntry.present('SplitButton', _splitButton),
    DesignInventoryEntry.present('Link', _link),
    DesignInventoryEntry.present('Kbd', _kbd),
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
    DesignInventoryEntry.present('SegmentedButton', _segmented),
    DesignInventoryEntry.present('Chip', _chip),
    DesignInventoryEntry.present('Rating', _rating),
    DesignInventoryEntry.present('FileUpload', _fileUpload),
    DesignInventoryEntry.present('DatePicker', _datePicker),
    DesignInventoryEntry.present('DateRangePicker', _dateRangePicker),
    DesignInventoryEntry.present('TimePicker', _timePicker),
    DesignInventoryEntry.present('Calendar', _calendar),
    DesignInventoryEntry.absent(
      'WheelPicker',
      'a wheel spins values past a lens, which a grid of fixed cells '
          'cannot draw: a value is typed (a time steps with the arrows) or '
          'chosen from a list',
    ),
    DesignInventoryEntry.present('ColorPicker', _colorPicker),
    DesignInventoryEntry.present('FormField', _formField),
    // Navigation
    DesignInventoryEntry.present('AppBar', _appBar),
    DesignInventoryEntry.present('NavigationBar', _navigationBar),
    DesignInventoryEntry.present('NavigationRail', _navigationRail),
    DesignInventoryEntry.present('NavigationDrawer', _sideBar),
    DesignInventoryEntry.present('TabBar', _tabBar),
    DesignInventoryEntry.present('Breadcrumb', _breadcrumb),
    DesignInventoryEntry.present('Pagination', _pagination),
    DesignInventoryEntry.present('StepProgress', _steps),
    DesignInventoryEntry.present('PageDots', _pageDots),
    DesignInventoryEntry.present('MenuBar', _menuBar),
    DesignInventoryEntry.present('Command', _command),
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
    DesignInventoryEntry.absent(
      'CarouselView',
      'a carousel slides cards sideways under a finger, and Terminal\'s '
          'structure never travels: a set of pages is a list, or tabs with '
          'page dots',
    ),
    DesignInventoryEntry.present('ReorderableListView', _reorderable),
    DesignInventoryEntry.absent(
      'SwipeActions',
      'swiping a row aside moves the structure, which Terminal never '
          'does: a row\'s actions are its keys and a menu on the row',
    ),
    DesignInventoryEntry.present('RefreshIndicator', _refresh),
    DesignInventoryEntry.present('TreeView', _tree),
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
    DesignInventoryEntry.present('Sheet', _sideSheet),
    DesignInventoryEntry.present('ActionSheet', _actionSheet),
    DesignInventoryEntry.present('Popover', _popover),
    DesignInventoryEntry.present('HoverCard', _hoverCard),
    DesignInventoryEntry.present('Tooltip', _tooltip),
    DesignInventoryEntry.present('Menu', _menu),
    DesignInventoryEntry.present('SnackBar', _snackBar),
    DesignInventoryEntry.present('Banner', _banner),
    // Feedback
    DesignInventoryEntry.present('LinearProgressIndicator', _progress),
    DesignInventoryEntry.present('CircularProgressIndicator', _spinner),
    DesignInventoryEntry.present('Skeleton', _skeleton),
    DesignInventoryEntry.present('StatusView', _statusView),
    DesignInventoryEntry.present('Meter', _meter),
    // Charts
    DesignInventoryEntry.present('LineChart', _lineChart),
    DesignInventoryEntry.present('BarChart', _barChart),
    DesignInventoryEntry.present('AreaChart', _areaChart),
    DesignInventoryEntry.absent(
      'PieChart',
      'slices are angles, and a text grid draws lengths: a share is a bar '
          'of blocks, which reads to the eighth of a cell',
    ),
    DesignInventoryEntry.present('Sparkline', _sparkline),
  ],
);

void _noop() {}

List<T> _moved<T>(List<T> list, int from, int to) {
  final next = [...list];
  final item = next.removeAt(from);
  return next..insert(to, item);
}

/// A value a specimen changes, held while it shows.
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
      widget.builder(context, _value, (v) => setState(() => _value = v));
}

/// A controller a specimen needs, made when it shows and disposed after.
class _Held<C extends ChangeNotifier> extends StatefulWidget {
  const _Held(this.create, this.builder);

  final C Function() create;
  final Widget Function(BuildContext context, C controller) builder;

  @override
  State<_Held<C>> createState() => _HeldState<C>();
}

class _HeldState<C extends ChangeNotifier> extends State<_Held<C>> {
  late final C _c = widget.create();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _c);
}

const _places = [
  TermNavigationDestination(label: 'runs', glyph: '#'),
  TermNavigationDestination(label: 'deploys', glyph: '↑'),
  TermNavigationDestination(label: 'config', glyph: '='),
];

// Actions

Widget _button(BuildContext context) => const TermButtonGroup(
  children: [
    TermButton(label: 'cancel', onPressed: _noop),
    TermButton.filled(label: 'deploy', onPressed: _noop),
    TermButton(label: 'delete', isDestructiveAction: true, onPressed: _noop),
    TermButton(label: 'disabled'),
  ],
);

Widget _iconButton(BuildContext context) => const TermButtonGroup(
  children: [
    TermIconButton(glyph: 'r', semanticLabel: 'rerun', onPressed: _noop),
    TermIconButton(glyph: '⋯', semanticLabel: 'more', onPressed: _noop),
  ],
);

Widget _buttonGroup(BuildContext context) => const TermButtonGroup(
  semanticLabel: 'run',
  children: [
    TermButton(label: 'rerun', onPressed: _noop),
    TermButton(label: 'cancel run', onPressed: _noop),
    TermButton(label: 'logs', onPressed: _noop),
  ],
);

Widget _toggleGroup(BuildContext context) => _Live<Set<String>>(
  const {'build', 'test'},
  (context, v, set) => TermToggleGroup<String>(
    options: const ['build', 'test', 'deploy'],
    selected: v,
    multiSelectionEnabled: true,
    emptySelectionAllowed: true,
    labelOf: (s) => s,
    semanticLabel: 'stages',
    onSelectionChanged: set,
  ),
);

Widget _splitButton(BuildContext context) => const TermSplitButton(
  label: 'deploy',
  filled: true,
  onPressed: _noop,
  actions: [
    DesignSplitAction(label: 'deploy to staging', onPressed: _noop),
    DesignSplitAction(label: 'deploy to production', onPressed: _noop),
  ],
);

Widget _link(BuildContext context) =>
    const TermLink(label: 'view the full log', onPressed: _noop);

Widget _kbd(BuildContext context) => Wrap(
  spacing: context.termGrid.cellWidth,
  children: const [TermKey('^K'), TermKey('⏎'), TermKey('g h')],
);

// Inputs

Widget _textField(BuildContext context) =>
    const TermTextField(labelText: 'branch', hintText: 'main');

Widget _textArea(BuildContext context) => const TermTextField(
  labelText: 'release notes',
  hintText: 'what changed',
  lines: 4,
);

Widget _searchField(BuildContext context) =>
    const TermTextField(prompt: '/', hintText: 'search runs');

Widget _passwordField(BuildContext context) =>
    const TermPasswordField(labelText: 'deploy token');

Widget _inputGroup(BuildContext context) => const TermTextField(
  labelText: 'preview url',
  prefixText: 'https://',
  suffixText: '.slipway.dev',
);

Widget _inputOtp(BuildContext context) => const TermOtpField();

Widget _numberField(BuildContext context) => _Live<int>(
  3,
  (context, v, set) => TermNumberField(
    value: v,
    onChanged: set,
    semanticLabel: 'replicas',
    min: 1,
    max: 9,
    unit: 'replicas',
  ),
);

Widget _select(BuildContext context) => _Live<String>(
  'staging',
  (context, v, set) => TermSelect<String>(
    labelText: 'environment',
    value: v,
    onChanged: set,
    items: const [
      TermSelectItem(value: 'staging', label: 'staging'),
      TermSelectItem(value: 'production', label: 'production'),
      TermSelectItem(value: 'preview', label: 'preview'),
    ],
  ),
);

Widget _combobox(BuildContext context) => const TermCombobox<String>(
  labelText: 'branch',
  hintText: 'type to filter',
  options: ['main', 'release/2.4', 'fix/cache-key', 'feat/desk'],
);

Widget _multiSelect(BuildContext context) => _Live<List<String>>(
  const ['api'],
  (context, v, set) => TermTagInput<String>(
    labelText: 'services',
    values: v,
    onChanged: set,
    options: const ['api', 'web', 'worker', 'cron'],
  ),
);

Widget _checkbox(BuildContext context) => _Live<bool?>(
  true,
  (context, v, set) =>
      TermCheckbox(value: v, onChanged: set, label: 'run the tests first'),
);

Widget _radioGroup(BuildContext context) => _Live<String?>(
  'rolling',
  (context, v, set) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final s in const ['rolling', 'blue-green', 'all at once'])
        TermRadio<String>(value: s, groupValue: v, onChanged: set, label: s),
    ],
  ),
);

Widget _switch(BuildContext context) => _Live<bool>(
  true,
  (context, v, set) =>
      TermSwitch(value: v, onChanged: set, label: 'deploy on merge'),
);

Widget _slider(BuildContext context) => _Live<double>(
  0.4,
  (context, v, set) => TermSlider(
    value: v,
    onChanged: set,
    divisions: 10,
    semanticLabel: 'traffic to canary',
  ),
);

Widget _rangeSlider(BuildContext context) => _Live<DesignRangeValues>(
  const DesignRangeValues(9, 17),
  (context, v, set) => TermRangeSlider(
    values: v,
    onChanged: set,
    min: 0,
    max: 24,
    divisions: 24,
    startLabel: 'from',
    endLabel: 'to',
  ),
);

Widget _rating(BuildContext context) => _Live<int>(
  3,
  (context, v, set) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TermRating(
        value: v,
        onChanged: set,
        semanticLabel: 'how did the deploy go',
      ),
      const TermRating(
        value: 4,
        onChanged: null,
        semanticLabel: 'the team rated it',
      ),
    ],
  ),
);

Widget _segmented(BuildContext context) => _Live<Set<String>>(
  const {'day'},
  (context, v, set) => TermToggleGroup<String>(
    options: const ['day', 'week', 'month'],
    selected: v,
    selectFollowsFocus: true,
    labelOf: (s) => s,
    semanticLabel: 'period',
    onSelectionChanged: set,
  ),
);

Widget _chip(BuildContext context) => _Live<bool>(
  true,
  (context, v, set) => Wrap(
    spacing: context.termGrid.cellWidth,
    children: [
      TermChip(label: 'failed', selected: v, onSelected: set),
      TermChip(label: 'mine', selected: !v, onSelected: (x) => set(!x)),
    ],
  ),
);

Widget _fileUpload(BuildContext context) => _Live<List<String>>(
  const ['build.log'],
  (context, v, set) => TermFileField(
    labelText: 'attach logs',
    files: v,
    onBrowse: () => set([...v, 'trace-${v.length}.txt']),
    onRemoved: (i) => set([...v]..removeAt(i)),
  ),
);

final _first = DateTime(2026);
final _last = DateTime(2027, 12, 31);

Widget _datePicker(BuildContext context) => _Live<DateTime?>(
  DateTime(2026, 11, 14),
  (context, v, set) => TermDatePicker(
    labelText: 'release on',
    value: v,
    onChanged: set,
    firstDate: _first,
    lastDate: _last,
  ),
);

Widget _dateRangePicker(BuildContext context) => _Live<DesignDateRange?>(
  DesignDateRange(DateTime(2026, 11, 9), DateTime(2026, 11, 14)),
  (context, v, set) => TermDateRangePicker(
    labelText: 'runs between',
    value: v,
    onChanged: set,
    firstDate: _first,
    lastDate: _last,
  ),
);

Widget _timePicker(BuildContext context) => _Live<TermTime?>(
  const TermTime(hour: 9, minute: 30),
  (context, v, set) =>
      TermTimeField(labelText: 'nightly build at', value: v, onChanged: set),
);

Widget _calendar(BuildContext context) => _Held<DesignCalendarController>(
  () => DesignCalendarController(
    firstDate: DateTime(2026),
    lastDate: DateTime(2027, 12, 31),
    selectedDate: DateTime(2026, 11, 14),
    currentDate: DateTime(2026, 11, 14),
  ),
  (context, c) => TermCalendar(controller: c),
);

Widget _colorPicker(BuildContext context) => _Held<DesignColorController>(
  () => DesignColorController(const Color(0xFF3FB8C9)),
  (context, c) => TermColorPicker(controller: c, lines: 6),
);

Widget _formField(BuildContext context) => const TermTextField(
  labelText: 'service name',
  helperText: 'lower case, a-z and -',
  errorText: 'no spaces in a service name',
);

// Navigation

Widget _appBar(BuildContext context) => const TermTopBar(
  title: 'slipway',
  subtitle: '~/atlas-api',
  actions: [TermButton.filled(label: 'deploy', onPressed: _noop)],
);

Widget _navigationBar(BuildContext context) => _Live<int>(
  0,
  (context, v, set) => TermNavigationBar(
    destinations: _places,
    selectedIndex: v,
    onDestinationSelected: set,
  ),
);

Widget _navigationRail(BuildContext context) => _Live<int>(
  0,
  (context, v, set) => SizedBox(
    height: 200,
    child: TermNavigationRail(
      destinations: _places,
      selectedIndex: v,
      onDestinationSelected: set,
    ),
  ),
);

Widget _sideBar(BuildContext context) => _Live<int>(
  0,
  (context, v, set) => SizedBox(
    height: 200,
    width: 260,
    child: TermSideBar(
      title: 'atlas-api',
      destinations: _places,
      selectedIndex: v,
      onDestinationSelected: set,
    ),
  ),
);

Widget _tabBar(BuildContext context) => _Live<int>(
  0,
  (context, v, set) => TermTabBar(
    tabs: const ['steps', 'log', 'env'],
    selectedIndex: v,
    onTap: set,
  ),
);

Widget _breadcrumb(BuildContext context) => const TermBreadcrumb(
  crumbs: [
    (label: '~', onPressed: _noop),
    (label: 'atlas-api', onPressed: _noop),
    (label: 'runs', onPressed: _noop),
    (label: '#1482', onPressed: null),
  ],
);

Widget _pagination(BuildContext context) => _Live<int>(
  5,
  (context, v, set) => TermPagination(page: v, pageCount: 21, onChanged: set),
);

Widget _steps(BuildContext context) => const TermSteps(
  steps: [
    (label: 'source', state: TermStepState.done),
    (label: 'build', state: TermStepState.done),
    (label: 'test', state: TermStepState.current),
    (label: 'deploy', state: TermStepState.upcoming),
  ],
);

Widget _pageDots(BuildContext context) => _Live<int>(
  1,
  (context, v, set) => TermPageDots(count: 5, index: v, onChanged: set),
);

Widget _menuBar(BuildContext context) => const TermMenuBar(
  menus: [
    DesignMenuEntry(
      label: 'run',
      children: [
        DesignMenuEntry(label: 'rerun', shortcut: 'R', onPressed: _noop),
        DesignMenuEntry(label: 'cancel', shortcut: '^C', onPressed: _noop),
        DesignMenuEntry.divider(),
        DesignMenuEntry(label: 'delete logs', onPressed: _noop),
      ],
    ),
    DesignMenuEntry(
      label: 'view',
      children: [
        DesignMenuEntry(label: 'wrap lines', checked: true, onPressed: _noop),
        DesignMenuEntry(label: 'timestamps', checked: false, onPressed: _noop),
      ],
    ),
  ],
);

Widget _command(BuildContext context) => const SizedBox(
  height: 240,
  child: TermCommandPalette(
    commands: [
      DesignCommand(
        label: 'deploy to staging',
        group: 'deploy',
        onPressed: _noop,
      ),
      DesignCommand(
        label: 'open the runs',
        group: 'go',
        shortcut: 'M-2',
        onPressed: _noop,
      ),
      DesignCommand(
        label: 'rerun the last run',
        group: 'run',
        shortcut: 'R',
        onPressed: _noop,
      ),
    ],
    maxLines: 5,
  ),
);

Widget _scaffold(BuildContext context) => _Live<int>(
  0,
  (context, v, set) => SizedBox(
    height: 220,
    child: TermScaffold(
      topBar: const TermTopBar(title: 'slipway'),
      destinations: _places,
      selectedIndex: v,
      onDestinationSelected: set,
      body: Center(child: Text(_places[v].label)),
    ),
  ),
);

// Containers

Widget _card(BuildContext context) => const TermPane(
  title: 'atlas-api',
  trailing: '✓ healthy',
  child: Text('3 replicas · last deploy 2h ago'),
);

Widget _listTile(BuildContext context) => const TermListTile(
  leading: Text('✓'),
  title: Text('#1482 fix the cache key'),
  subtitle: Text('main · 2m 14s'),
  onTap: _noop,
);

Widget _listSection(BuildContext context) => TermPane.list(
  title: 'recent runs',
  children: const [
    TermListTile(title: Text('#1482 fix the cache key'), onTap: _noop),
    TermListTile(title: Text('#1481 bump the runtime'), onTap: _noop),
    TermListTile(title: Text('#1480 desk: tiled panes'), onTap: _noop),
  ],
);

Widget _sectionHeader(BuildContext context) =>
    const TermSectionHeader(title: 'environments', trailing: '3');

Widget _disclosure(BuildContext context) => const TermDisclosure(
  title: 'environment',
  initiallyExpanded: true,
  child: Text('NODE_ENV=production\nREGION=eu-west'),
);

Widget _table(BuildContext context) => const TermTable(
  semanticLabel: 'runs',
  columns: [
    TermColumn(label: 'run', cols: 6),
    TermColumn(label: 'branch', cols: 14),
    TermColumn(label: 'took', cols: 7, numeric: true),
  ],
  rows: [
    [Text('#1482'), Text('main'), Text('2m 14s')],
    [Text('#1481'), Text('release/2.4'), Text('3m 02s')],
  ],
);

Widget _dataTable(BuildContext context) =>
    _Held<DesignTableController<List<String>>>(
      () => DesignTableController<List<String>>(
        rows: const [
          ['#1482', 'main', '134'],
          ['#1481', 'release/2.4', '182'],
          ['#1480', 'feat/desk', '97'],
        ],
        rowKey: (r) => r.first,
        columns: [
          DesignTableColumn<List<String>>(
            id: '0',
            label: 'run',
            sortKey: (r) => r[0],
          ),
          const DesignTableColumn<List<String>>(id: '1', label: 'branch'),
          DesignTableColumn<List<String>>(
            id: '2',
            label: 'secs',
            numeric: true,
            sortKey: (r) => int.parse(r[2]),
          ),
        ],
      ),
      (context, c) => TermDataTable<List<String>>(
        controller: c,
        widths: const {'0': 6, '2': 5},
        cellBuilder: (context, row, column) => Text(row[int.parse(column.id)]),
      ),
    );

Widget _divider(BuildContext context) => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    TermDivider(),
    TermDivider(label: 'older'),
  ],
);

Widget _scrollArea(BuildContext context) => _Held<ScrollController>(
  ScrollController.new,
  (context, c) => SizedBox(
    height: 144,
    child: TermScrollArea(
      controller: c,
      semanticLabel: 'versions',
      child: ListView(
        controller: c,
        children: [for (var i = 1; i <= 16; i++) Text('v2.4.$i')],
      ),
    ),
  ),
);

Widget _resizable(BuildContext context) => const SizedBox(
  height: 120,
  child: TermSplitView(
    initialFraction: 0.4,
    semanticLabel: 'files and preview',
    first: Center(child: Text('files')),
    second: Center(child: Text('preview')),
  ),
);

Widget _reorderable(BuildContext context) => _Live<List<String>>(
  const ['lint', 'test', 'build', 'deploy'],
  (context, v, set) => TermReorderableList<String>(
    items: v,
    labelOf: (s) => s,
    shrinkWrap: true,
    onReorder: (from, to) => set(_moved(v, from, to)),
  ),
);

Widget _refresh(BuildContext context) => SizedBox(
  height: 144,
  child: TermPullToRefresh(
    onRefresh: () => Future<void>.delayed(const Duration(seconds: 1)),
    child: ListView(
      children: [for (var i = 0; i < 8; i++) Text('#${1482 - i} passed')],
    ),
  ),
);

class _Node {
  const _Node(this.name, [this.children = const []]);

  final String name;
  final List<_Node> children;
}

const _src = _Node('src', [
  _Node('app', [_Node('main.dart'), _Node('routes.dart')]),
  _Node('theme.dart'),
]);

Widget _tree(BuildContext context) => _Held<DesignTreeController<_Node>>(
  () => DesignTreeController<_Node>(
    roots: const [_src, _Node('pubspec.yaml')],
    childrenOf: (n) => n.children,
    expanded: [_src, _src.children.first],
  ),
  (context, c) => TermTree<_Node>(
    controller: c,
    labelOf: (n) => n.name,
    semanticLabel: 'files',
  ),
);

Widget _timeline(BuildContext context) => const TermTimeline(
  entries: [
    TermTimelineEntry(
      time: '14:02',
      title: 'build passed',
      tone: TermTone.success,
    ),
    TermTimelineEntry(
      time: '14:05',
      title: 'deploy started',
      detail: 'to staging',
    ),
    TermTimelineEntry(
      time: '14:07',
      title: 'health check failed',
      tone: TermTone.error,
    ),
  ],
);

Widget _avatar(BuildContext context) => Wrap(
  spacing: context.termGrid.cellWidth,
  children: const [
    TermAvatar(name: 'Ada Okafor'),
    TermAvatar(name: 'Ben Ito', lines: 2),
  ],
);

Widget _avatarGroup(BuildContext context) => const TermAvatarGroup(
  names: ['Ada Okafor', 'Ben Ito', 'Chen Wu', 'Dara Kim', 'Eli Moss', 'Fay Ng'],
);

Widget _badge(BuildContext context) => Wrap(
  spacing: context.termGrid.cellWidth,
  children: const [
    TermBadge(count: 3, tone: TermTone.error, semanticLabel: 'failed runs'),
    TermBadge(count: 120, semanticLabel: 'queued'),
  ],
);

Widget _tag(BuildContext context) => Wrap(
  spacing: context.termGrid.cellWidth,
  children: const [
    TermTag(label: 'production', tone: TermTone.warning),
    TermTag(label: 'v2.4.1'),
  ],
);

Widget _media(BuildContext context) => const TermMedia(
  slotId: 'deploy-graph',
  alt: 'the deploy graph',
  caption: 'graph',
  lines: 6,
);

Widget _emptyState(BuildContext context) => const TermEmptyState(
  title: 'no runs yet',
  message: 'push a commit to start one',
);

Widget _descriptionList(BuildContext context) => const TermDescriptionList(
  items: [('branch', 'main'), ('commit', '4f2a91c'), ('took', '2m 14s')],
);

// Overlays

Widget _dialog(BuildContext context) => const TermDialog(
  title: 'discard changes',
  content: Text('the form has edits that are not saved.'),
  actions: [
    TermButton(label: 'keep', onPressed: _noop),
    TermButton.filled(label: 'discard', onPressed: _noop),
  ],
);

Widget _bottomSheet(BuildContext context) => const TermSheet(
  title: 'share run',
  actions: [TermButton.filled(label: 'copy link', onPressed: _noop)],
  child: Text('a link anyone on the team can open'),
);

Widget _sideSheet(BuildContext context) => TermButton(
  label: 'open details',
  onPressed: () => showTermSideSheet<void>(
    context: context,
    builder: (context) => const TermSideSheet(
      title: 'run #1482',
      child: TermDescriptionList(
        items: [('branch', 'main'), ('took', '2m 14s')],
      ),
    ),
  ),
);

Widget _actionSheet(BuildContext context) => TermActionSheet<String>(
  title: 'run #1482',
  onSelected: (_) {},
  actions: const [
    TermSheetAction(label: 'rerun', value: 'rerun'),
    TermSheetAction(
      label: 'delete logs',
      value: 'delete',
      isDestructiveAction: true,
    ),
  ],
);

Widget _popover(BuildContext context) => TermPopover(
  title: 'filters',
  anchorBuilder: (context, anchor) =>
      TermButton(label: 'filters', onPressed: anchor.toggle),
  builder: (context) => const Text('status: failed\nbranch: main'),
);

Widget _hoverCard(BuildContext context) => TermHoverCard(
  title: '4f2a91c',
  builder: (context) => const Text('fix the cache key\nAda Okafor · 2h ago'),
  child: const TermLink(label: '4f2a91c', onPressed: _noop),
);

Widget _tooltip(BuildContext context) => const TermTooltip(
  message: 'rerun (r)',
  child: TermIconButton(glyph: 'r', semanticLabel: 'rerun', onPressed: _noop),
);

Widget _menu(BuildContext context) => TermMenu(
  semanticLabel: 'run actions',
  anchorBuilder: (context, anchor) => TermIconButton(
    glyph: '⋯',
    semanticLabel: 'more',
    onPressed: anchor.toggle,
  ),
  items: const [
    TermMenuItem(label: 'rerun', shortcut: 'r', onPressed: _noop),
    TermMenuItem(label: 'copy link', shortcut: 'y', onPressed: _noop),
    TermMenuItem(
      label: 'delete logs',
      isDestructiveAction: true,
      onPressed: _noop,
    ),
  ],
);

Widget _snackBar(BuildContext context) => TermButton(
  label: 'show a toast',
  onPressed: () => TermToaster.show(
    context,
    message: 'deployed atlas-api to staging',
    tone: TermTone.success,
  ),
);

Widget _banner(BuildContext context) => const TermBanner(
  tone: TermTone.warning,
  title: 'degraded',
  message: 'builds queue longer than usual',
);

// Feedback

Widget _progress(BuildContext context) =>
    const TermProgressBar(value: 0.62, semanticLabel: 'uploading');

Widget _spinner(BuildContext context) => const TermSpinner();

Widget _skeleton(BuildContext context) => const TermSkeleton(cols: 32);

Widget _statusView(BuildContext context) => const TermStatusView(
  status: TermStatus.error,
  title: "couldn't load runs",
  message: 'the server did not answer in 30s',
  action: TermButton(label: 'retry', onPressed: _noop),
);

Widget _meter(BuildContext context) =>
    const TermMeter(value: 0.72, label: 'disk', reading: '72%');

// Charts

Widget _lineChart(BuildContext context) => const TermLineChart(
  lines: 6,
  xLabels: ('mon', 'sun'),
  series: [
    TermSeries(label: 'p95 ms', values: [120, 135, 128, 160, 142, 150, 131]),
    TermSeries(label: 'p50 ms', values: [60, 64, 58, 71, 66, 69, 62]),
  ],
);

Widget _barChart(BuildContext context) => const TermBarChart(
  unit: 'min',
  bars: [('api', 42), ('web', 18), ('worker', 7)],
);

Widget _areaChart(BuildContext context) => const TermAreaChart(
  lines: 6,
  semanticLabel: 'requests a minute',
  series: [
    TermSeries(label: 'requests', values: [4, 9, 7, 12, 10, 14, 11]),
  ],
);

Widget _sparkline(BuildContext context) => const TermSparkline(
  values: [3, 5, 4, 8, 6, 9, 7, 11],
  semanticLabel: 'build minutes, last 8 runs',
);

/// [termInventory], listed group by group in Terminal's own look: each
/// group a pane-style header with its count, each row its name, its
/// part's class (and the ui_core behaviour it stands on), then the live
/// part or the reason it is left out.
class TermInventoryGallery extends StatelessWidget {
  /// The inventory's gallery.
  const TermInventoryGallery({super.key, this.controller});

  /// The list's scroll controller (the caller's), or null.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    return DesignInventoryGallery(
      inventory: termInventory,
      controller: controller,
      padding: EdgeInsets.symmetric(
        horizontal: grid.cellWidth * 2,
        vertical: grid.lineHeight,
      ),
      groupBuilder: (context, group, present, total) => Padding(
        padding: EdgeInsets.only(top: grid.lineHeight),
        child: TermSectionHeader(
          title: group.toLowerCase(),
          trailing: '$present/$total',
        ),
      ),
      rowBuilder: (context, row, entry, specimen) {
        final reason = entry?.absentReason;
        return KeyedSubtree(
          key: ValueKey<String>('inventory-${row.id}'),
          child: Padding(
            padding: EdgeInsets.only(bottom: grid.lineHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.name, style: theme.boldStyle),
                Text(
                  row.isBehaviour ? 'on ${row.behaviour}' : row.id,
                  style: theme.dimStyle,
                ),
                SizedBox(height: grid.lineHeight / 2),
                if (specimen != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: grid.cols(60)),
                    child: specimen,
                  )
                else
                  Text(
                    reason == null
                        ? 'missing'
                        : DesignInventory.absentLabel(reason),
                    style: theme.dimStyle,
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
    properties.add(IntProperty('rows', termInventory.entries.length));
  }
}
