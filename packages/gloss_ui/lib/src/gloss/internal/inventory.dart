/// Interactive examples of the Gloss components in [DesignInventoryRow.all].
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

void _ignore(Object? _) {}

const _places = [
  GlossDestination(icon: LucideIcons.chefHat, label: 'Recipes'),
  GlossDestination(icon: LucideIcons.calendarDays, label: 'Plan'),
  GlossDestination(icon: LucideIcons.shoppingBasket, label: 'Shopping'),
];

final _first = DateTime(2026, 11);
final _last = DateTime(2026, 12, 31);

DesignInventoryEntry _row(String id, WidgetBuilder builder) =>
    DesignInventoryEntry.present(id, builder);

/// The component examples in the Gloss inventory.
abstract final class GlossInventory {
  /// Component rows with their example builders and availability.
  static final DesignInventory registry = _registry();
}

DesignInventory _registry() => DesignInventory(
  look: 'Gloss',
  entries: [
    // Actions.
    _row(
      'Button',
      (_) => const GlossButton.filled('Cook this', onPressed: _none),
    ),
    _row(
      'IconButton',
      (_) => const GlossIconButton(
        onPressed: _none,
        icon: Icon(LucideIcons.heart),
        tooltip: 'Save',
      ),
    ),
    const DesignInventoryEntry.absent(
      'FloatingActionButton',
      "Gloss's one action is the gel key in reach",
    ),
    _row(
      'ButtonGroup',
      (_) => const GlossButtonGroup(
        items: [
          GlossButtonGroupItem(label: 'Halve', onPressed: _none),
          GlossButtonGroupItem(label: 'Double', onPressed: _none),
        ],
      ),
    ),
    _row(
      'ToggleGroup',
      (_) => const GlossToggleGroup<String>(
        semanticLabel: 'Diet',
        toggles: [
          GlossToggle(value: 'veg', label: 'Vegetarian'),
          GlossToggle(value: 'gf', label: 'Gluten-free'),
        ],
        selected: {'veg'},
        onSelectionChanged: _ignore,
      ),
    ),
    _row(
      'SplitButton',
      (_) => const GlossSplitButton.filled(
        label: 'Plan',
        onPressed: _none,
        actions: [GlossSplitAction(label: 'Plan for Friday', onPressed: _none)],
      ),
    ),
    _row('Link', (_) => const GlossLink('Method', onPressed: _none)),
    _row('Kbd', (_) => const GlossKbd('Ctrl K')),
    // Inputs.
    _row('TextField', (_) => const GlossTextField(label: 'Name')),
    _row('TextArea', (_) => const GlossTextArea(label: 'Notes')),
    _row('SearchField', (_) => const GlossSearchField(hint: 'Search recipes')),
    _row('PasswordField', (_) => const GlossPasswordField(label: 'Password')),
    _row(
      'InputGroup',
      (_) => const GlossInputGroup(
        label: 'Weight',
        prefixText: '≈',
        suffixText: 'g',
      ),
    ),
    _row('InputOtp', (_) => const GlossOtpField(semanticLabel: 'Code')),
    _row(
      'NumberField',
      (_) => const GlossStepper(
        value: 4,
        onChanged: _ignore,
        semanticLabel: 'Servings',
      ),
    ),
    _row(
      'Select',
      (_) => const GlossSelect<String>(
        label: 'Course',
        value: 'main',
        onChanged: _ignore,
        items: [
          GlossSelectItem(value: 'main', label: 'Main'),
          GlossSelectItem(value: 'side', label: 'Side'),
        ],
      ),
    ),
    _row(
      'Combobox',
      (_) => const GlossCombobox<String>(
        label: 'Ingredient',
        options: ['Basil', 'Bay leaf', 'Butter'],
      ),
    ),
    _row(
      'MultiSelect',
      (_) => const GlossTagInput<String>(
        label: 'Tags',
        values: ['Quick'],
        onChanged: _ignore,
        options: ['Quick', 'Batch', 'Freezer'],
      ),
    ),
    _row(
      'Checkbox',
      (_) => const GlossCheckbox(
        value: true,
        onChanged: _ignore,
        semanticLabel: 'Bought',
      ),
    ),
    _row(
      'RadioGroup',
      (_) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlossRadio<int>(
            value: 1,
            groupValue: 1,
            onChanged: _ignore,
            semanticLabel: 'Lunch',
          ),
          SizedBox(width: GlossSpacing.regular),
          GlossRadio<int>(
            value: 2,
            groupValue: 1,
            onChanged: _ignore,
            semanticLabel: 'Dinner',
          ),
        ],
      ),
    ),
    _row(
      'Switch',
      (_) => const GlossSwitch(
        value: true,
        onChanged: _ignore,
        semanticLabel: 'Reminders',
      ),
    ),
    _row(
      'Slider',
      (_) => const GlossSlider(
        value: 0.4,
        onChanged: _ignore,
        semanticLabel: 'Spice',
      ),
    ),
    _row(
      'RangeSlider',
      (_) => const GlossRangeSlider(
        values: GlossRangeValues(15, 45),
        max: 90,
        onChanged: _ignore,
        startLabel: 'Shortest',
        endLabel: 'Longest',
      ),
    ),
    _row(
      'SegmentedButton',
      (_) => const GlossSegmentedButton<int>(
        selected: 0,
        onChanged: _ignore,
        segments: [
          GlossSegment(value: 0, label: 'Week'),
          GlossSegment(value: 1, label: 'Month'),
        ],
      ),
    ),
    _row(
      'Chip',
      (_) =>
          const GlossChip(label: 'Quick', selected: true, onSelected: _ignore),
    ),
    _row(
      'Rating',
      (_) => const GlossRating(
        value: 4,
        onChanged: _ignore,
        semanticLabel: 'Rating',
      ),
    ),
    _row(
      'FileUpload',
      (_) => const GlossFileDrop(
        onChoose: _none,
        hint: 'A photo of the dish',
        files: [GlossFile(name: 'risotto.jpg', bytes: 240000)],
      ),
    ),
    _row(
      'DatePicker',
      (_) => GlossDatePicker(
        label: 'Cook on',
        value: null,
        onChanged: _ignore,
        firstDate: _first,
        lastDate: _last,
      ),
    ),
    _row(
      'DateRangePicker',
      (_) => GlossDateRangePicker(
        label: 'Plan for',
        value: null,
        onChanged: _ignore,
        firstDate: _first,
        lastDate: _last,
      ),
    ),
    _row(
      'TimePicker',
      (_) => const GlossTimePicker(
        value: GlossTime(hour: 18, minute: 30),
        onChanged: _ignore,
        semanticLabel: 'Dinner',
      ),
    ),
    _row(
      'Calendar',
      (_) => GlossCalendar(
        firstDate: _first,
        lastDate: _last,
        selectedDate: DateTime(2026, 11, 20),
        currentDate: DateTime(2026, 11, 16),
        onDateChanged: _ignore,
      ),
    ),
    _row(
      'WheelPicker',
      (_) => GlossWheelPicker<int>(
        items: const [1, 2, 3, 4, 5, 6],
        value: 4,
        onChanged: _ignore,
        labelOf: (n) => '$n',
        semanticLabel: 'Servings',
      ),
    ),
    _row(
      'ColorPicker',
      (_) =>
          const GlossColorPicker(value: Color(0xFF2E9E7A), onChanged: _ignore),
    ),
    _row(
      'FormField',
      (_) => const GlossFormField(
        labelText: 'Reminders',
        helperText: 'An hour before',
        child: GlossSwitch(value: true, onChanged: _ignore),
      ),
    ),
    // Navigation.
    _row('AppBar', (_) => const GlossTopBar(title: 'Recipes')),
    _row(
      'NavigationBar',
      (_) => const GlossNavigationBar(
        destinations: _places,
        selectedIndex: 0,
        onSelected: _ignore,
      ),
    ),
    _row(
      'NavigationRail',
      (_) => const SizedBox(
        height: 320,
        child: GlossNavigationRail(
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
        child: GlossSidebar(
          destinations: _places,
          selectedIndex: 0,
          onSelected: _ignore,
        ),
      ),
    ),
    _row(
      'TabBar',
      (_) => const GlossTabBar(
        tabs: ['Method', 'Ingredients'],
        selectedIndex: 0,
        onSelected: _ignore,
      ),
    ),
    _row(
      'Breadcrumb',
      (_) => const GlossBreadcrumb(
        crumbs: [
          GlossCrumb('Recipes', onPressed: _none),
          GlossCrumb('Lemon risotto'),
        ],
      ),
    ),
    _row(
      'Pagination',
      (_) => const GlossPagination(page: 1, pageCount: 8, onChanged: _ignore),
    ),
    _row(
      'StepProgress',
      (_) =>
          const GlossStepProgress(steps: ['Prep', 'Cook', 'Serve'], current: 1),
    ),
    _row(
      'PageDots',
      (_) => const GlossPageDots(count: 4, index: 1, onChanged: _ignore),
    ),
    _row(
      'MenuBar',
      (_) => const GlossMenuBar(
        menus: [
          GlossMenuBarMenu('Plan', [
            GlossMenuItem(label: 'New week', onPressed: _none),
          ]),
          GlossMenuBarMenu('Edit', [
            GlossMenuItem(label: 'Undo', onPressed: _none),
          ]),
        ],
      ),
    ),
    _row(
      'Command',
      (_) => const SizedBox(
        height: 300,
        child: GlossCommandPalette(
          commands: [
            GlossCommand(label: 'Find a recipe', onPressed: _none),
            GlossCommand(label: 'Settings', onPressed: _none),
          ],
        ),
      ),
    ),
    _row(
      'Scaffold',
      (_) => const SizedBox(
        height: 360,
        child: GlossScaffold(
          topBar: GlossTopBar(title: 'Recipes'),
          destinations: _places,
          onSelected: _ignore,
          body: SizedBox.expand(),
        ),
      ),
    ),
    // Containers.
    _row('Card', (_) => const GlossCard(child: Text('Lemon risotto, 35 min'))),
    _row('ListTile', (_) => const GlossListTile(title: 'Reminders')),
    _row(
      'ListSection',
      (_) => const GlossWell(
        header: 'Account',
        children: [
          GlossListTile(title: 'Name', trailingText: 'Noa Ferreira'),
          GlossListTile(title: 'Email', trailingText: 'noa@example.com'),
        ],
      ),
    ),
    _row('SectionHeader', (_) => const GlossSectionHeader('This week')),
    _row(
      'Disclosure',
      (_) => const GlossDisclosure(
        title: 'Storage',
        child: Text('Keeps three days in the fridge.'),
      ),
    ),
    _row(
      'Table',
      (_) => const GlossTable(
        columns: [
          GlossTableColumn('Ingredient'),
          GlossTableColumn('Grams', numeric: true),
        ],
        rows: [
          ['Rice', '320'],
          ['Parmesan', '60'],
        ],
      ),
    ),
    _row('DataTable', (_) => const _DataTableSpecimen()),
    _row('Divider', (_) => const GlossDivider()),
    _row('ScrollArea', (_) => const _ScrollSpecimen()),
    _row(
      'Resizable',
      (_) => const SizedBox(
        height: 160,
        child: GlossSplitView(
          first: Center(child: Text('Recipes')),
          second: Center(child: Text('Lemon risotto')),
        ),
      ),
    ),
    _row(
      'CarouselView',
      (_) => GlossCarousel(
        itemCount: 3,
        semanticLabel: 'Photos',
        itemBuilder: (context, i) => Center(child: Text('Photo ${i + 1}')),
      ),
    ),
    _row('ReorderableListView', (_) => const _ReorderSpecimen()),
    _row(
      'SwipeActions',
      (_) => const GlossSwipeRow(
        endActions: [
          GlossSwipeAction(
            label: 'Delete',
            icon: LucideIcons.trash2,
            isDestructiveAction: true,
            onPressed: _none,
          ),
        ],
        child: GlossListTile(title: 'Lemon risotto'),
      ),
    ),
    _row(
      'RefreshIndicator',
      (_) => SizedBox(
        height: 160,
        child: GlossPullToRefresh(
          onRefresh: () async {},
          child: ListView(
            children: const [GlossListTile(title: 'Pull to sync')],
          ),
        ),
      ),
    ),
    _row('TreeView', (_) => const _TreeSpecimen()),
    _row(
      'Timeline',
      (_) => const GlossTimeline(
        entries: [
          GlossTimelineEntry(title: 'Soak the beans', done: true),
          GlossTimelineEntry(title: 'Simmer'),
        ],
      ),
    ),
    _row('Avatar', (_) => const GlossAvatar(name: 'Noa Ferreira')),
    _row(
      'AvatarGroup',
      (_) => const GlossAvatarGroup(
        avatars: [
          GlossAvatar(name: 'Noa Ferreira'),
          GlossAvatar(name: 'Iko Tanaka'),
          GlossAvatar(name: 'Rui Alves'),
        ],
      ),
    ),
    _row(
      'Badge',
      (_) => const GlossBadge(count: 3, child: Icon(LucideIcons.bell)),
    ),
    _row('Tag', (_) => const GlossTag('Quick', tone: GlossTagTone.jade)),
    _row(
      'Media',
      (_) => const SizedBox(
        width: 280,
        child: GlossMedia(image: null, semanticLabel: 'The dish'),
      ),
    ),
    _row(
      'EmptyState',
      (_) => const GlossStateView(
        state: GlossState.empty,
        title: 'Nothing planned yet',
      ),
    ),
    _row(
      'DescriptionList',
      (_) => const GlossDescriptionList(
        entries: [GlossDescription('Serves', '4')],
      ),
    ),
    // Overlays.
    _row(
      'Dialog',
      // At rest, a picture: its safe key takes no focus from the page.
      (_) => const ExcludeFocus(
        child: GlossDialog(
          title: 'Delete this plan?',
          actions: [
            GlossDialogAction(label: 'Keep', onPressed: _none),
            GlossDialogAction(
              label: 'Delete',
              onPressed: _none,
              destructive: true,
            ),
          ],
        ),
      ),
    ),
    _row(
      'BottomSheet',
      (context) => GlossButton(
        'Open a sheet',
        onPressed: () => showGlossSheet<void>(
          context: context,
          title: 'Filter',
          builder: (context) => const Text('Courses'),
        ),
      ),
    ),
    _row(
      'Sheet',
      (context) => GlossButton(
        'Open a side sheet',
        onPressed: () => showGlossSideSheet<void>(
          context: context,
          title: 'Filters',
          builder: (context) => const Text('Courses'),
        ),
      ),
    ),
    _row(
      'ActionSheet',
      (context) => GlossButton(
        'Recipe actions',
        onPressed: () => showGlossActionSheet<String>(
          context: context,
          title: 'This recipe',
          actions: const [GlossSheetAction(label: 'Share', value: 's')],
        ),
      ),
    ),
    _row(
      'Popover',
      (_) => GlossPopover(
        builder: (context, toggle, open) =>
            GlossButton('Share', onPressed: toggle),
        content: (context, close) => const Text('Share Lemon risotto'),
      ),
    ),
    _row(
      'HoverCard',
      (_) => GlossHoverCard(
        content: (context) => const Text('35 min, serves 4'),
        child: const GlossLink('Lemon risotto', onPressed: _none),
      ),
    ),
    _row(
      'Tooltip',
      (_) => const GlossTooltip(
        message: 'Save',
        child: GlossIconButton(
          onPressed: _none,
          icon: Icon(LucideIcons.heart),
          tooltip: 'Save',
        ),
      ),
    ),
    _row(
      'Menu',
      (_) => GlossMenu(
        items: const [GlossMenuItem(label: 'Share', onPressed: _none)],
        builder: (context, toggle, open) =>
            GlossButton('More', onPressed: toggle),
      ),
    ),
    _row(
      'SnackBar',
      (context) => GlossButton(
        'Show a toast',
        onPressed: () => showGlossToast(context, 'Added to Thursday'),
      ),
    ),
    _row('Banner', (_) => const GlossBanner(title: 'Sync is paused')),
    // Feedback.
    _row(
      'LinearProgressIndicator',
      (_) => const GlossProgressBar(value: 0.4, semanticLabel: 'Upload'),
    ),
    _row(
      'CircularProgressIndicator',
      (_) => const GlossSpinner(semanticLabel: 'Loading'),
    ),
    _row('Skeleton', (_) => const GlossSkeleton(width: 200)),
    _row(
      'StatusView',
      (_) => const GlossStateView(
        state: GlossState.error,
        title: 'The week did not load',
      ),
    ),
    _row('Meter', (_) => const GlossMeter(value: 0.6, label: 'Pantry')),
    // Charts.
    _row(
      'LineChart',
      (_) => const GlossLineChart(
        semanticLabel: 'Cooked',
        labels: ['Mon', 'Tue', 'Wed'],
        series: [
          GlossSeries('Cooked', [2, 3, 1]),
        ],
      ),
    ),
    _row(
      'BarChart',
      (_) => const GlossBarChart(
        semanticLabel: 'Cooked',
        labels: ['Mon', 'Tue', 'Wed'],
        series: [
          GlossSeries('Cooked', [2, 3, 1]),
        ],
      ),
    ),
    _row(
      'AreaChart',
      (_) => const GlossAreaChart(
        semanticLabel: 'Saved',
        labels: ['Mon', 'Tue', 'Wed'],
        series: [
          GlossSeries('Saved', [4, 7, 5]),
        ],
      ),
    ),
    _row(
      'PieChart',
      (_) => const GlossPieChart(
        semanticLabel: 'By course',
        slices: [GlossSlice('Mains', 9), GlossSlice('Sides', 4)],
      ),
    ),
    _row(
      'Sparkline',
      (_) => const GlossSparkline(
        semanticLabel: 'This week',
        values: [3, 5, 4, 8],
      ),
    ),
  ],
);

class _Dish {
  const _Dish(this.name, this.minutes);
  final String name;
  final int minutes;
}

class _DataTableSpecimen extends StatefulWidget {
  const _DataTableSpecimen();

  @override
  State<_DataTableSpecimen> createState() => _DataTableSpecimenState();
}

class _DataTableSpecimenState extends State<_DataTableSpecimen> {
  final _table = GlossTableController<_Dish>(
    rows: const [_Dish('Lemon risotto', 35), _Dish('Green curry', 25)],
    rowKey: (d) => d.name,
    columns: [
      GlossDataColumn(id: 'name', label: 'Dish', sortKey: (d) => d.name),
      GlossDataColumn(
        id: 'minutes',
        label: 'Minutes',
        sortKey: (d) => d.minutes,
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
  Widget build(BuildContext context) => GlossDataTable<_Dish>(
    controller: _table,
    cell: (d, column) => column == 'name' ? d.name : '${d.minutes}',
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
    child: GlossScrollArea(
      controller: _scroll,
      child: ListView(
        controller: _scroll,
        children: [
          for (var i = 1; i <= 12; i++) GlossListTile(title: 'Step $i'),
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
  final _steps = ['Toast the rice', 'Add the stock', 'Stir in the lemon'];

  @override
  Widget build(BuildContext context) => GlossReorderableList<String>(
    items: _steps,
    labelOf: (s) => s,
    onReorder: (from, to) =>
        setState(() => _steps.insert(to, _steps.removeAt(from))),
    itemBuilder: (context, s) => Text(s),
  );
}

class _Shelf {
  const _Shelf(this.name, [this.children = const []]);
  final String name;
  final List<_Shelf> children;
}

class _TreeSpecimen extends StatefulWidget {
  const _TreeSpecimen();

  @override
  State<_TreeSpecimen> createState() => _TreeSpecimenState();
}

class _TreeSpecimenState extends State<_TreeSpecimen> {
  static const _roots = [
    _Shelf('Pantry', [_Shelf('Grains'), _Shelf('Spices')]),
    _Shelf('Fridge', [_Shelf('Dairy')]),
  ];

  final _tree = GlossTreeController<_Shelf>(
    roots: _roots,
    childrenOf: (s) => s.children,
    expanded: [_roots.first],
  );

  @override
  void dispose() {
    _tree.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      GlossTree<_Shelf>(controller: _tree, labelOf: (s) => s.name);
}
