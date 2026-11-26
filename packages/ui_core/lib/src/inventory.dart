/// The component inventory: a checklist of the components an ordinary app
/// expects from a design system, one [RawInventoryRow] each, and a
/// look's [RawInventory], which answers every row with a live specimen
/// or the reason the look deliberately leaves it out.
///
/// A row's id is a label for the thing (Material's name where Material has
/// it, shadcn's where only shadcn does), not a name a look must use: each
/// look names its own components, and their API is its own.
///
/// A look's test calls [RawInventory.verify]; its example lists the
/// inventory with [RawInventoryGallery], so an absent row reads
/// `Deliberately absent: <reason>` rather than going missing.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// One row of the inventory: a component every look either carries or
/// leaves out with a reason.
@immutable
class RawInventoryRow {
  const RawInventoryRow._(
    this.id,
    this.group,
    this.name, {
    this.refs = '',
    this.behaviour,
  });

  /// The row's id, the string a look's entry names it by: a label for the
  /// component (Material's or shadcn's name for it), not a class name.
  final String id;

  /// Its group: Actions, Inputs, Navigation, Containers, Overlays, Feedback
  /// or Charts.
  final String group;

  /// What a person calls it.
  final String name;

  /// Which references carry it: M (Material), C (Cupertino), S (shadcn).
  final String refs;

  /// For a behaviour row, the foundation API a look paints (built once,
  /// headless, here); null for a row a look draws whole.
  final String? behaviour;

  /// Whether the row is behaviour (focus, overlays, keyboard, controllers,
  /// timers) the foundation carries.
  bool get isBehaviour => behaviour != null;

  @override
  String toString() => 'RawInventoryRow($id)';

  /// Button (filled, outlined, text, danger).
  static const button = RawInventoryRow._(
    'Button',
    'Actions',
    'Button (filled/outlined/text/danger)',
    refs: 'MCS',
  );

  /// Icon button.
  static const iconButton = RawInventoryRow._(
    'IconButton',
    'Actions',
    'Icon button',
    refs: 'MCS',
  );

  /// Floating action button (extended, menu).
  static const floatingActionButton = RawInventoryRow._(
    'FloatingActionButton',
    'Actions',
    'Floating action button (+extended, menu)',
    refs: 'M',
  );

  /// Button group or toolbar.
  static const buttonGroup = RawInventoryRow._(
    'ButtonGroup',
    'Actions',
    'Button group / toolbar',
    refs: 'MS',
  );

  /// Toggle button or toggle group; a single-choice one is the [segmentedButton].
  static const toggleGroup = RawInventoryRow._(
    'ToggleGroup',
    'Actions',
    'Toggle button / toggle group',
    refs: 'MS',
    behaviour: 'RawSegmentedButton',
  );

  /// Split button.
  static const splitButton = RawInventoryRow._(
    'SplitButton',
    'Actions',
    'Split button',
    refs: 'M',
    behaviour: 'RawSplitButton',
  );

  /// Link.
  static const link = RawInventoryRow._('Link', 'Actions', 'Link', refs: 'S');

  /// Keyboard key (Kbd).
  static const kbd = RawInventoryRow._(
    'Kbd',
    'Actions',
    'Keyboard key (Kbd)',
    refs: 'S',
  );

  /// Text field.
  static const textField = RawInventoryRow._(
    'TextField',
    'Inputs',
    'Text field',
    refs: 'MCS',
  );

  /// Text area.
  static const textArea = RawInventoryRow._(
    'TextArea',
    'Inputs',
    'Text area',
    refs: 'S',
  );

  /// Search field or search bar.
  static const searchField = RawInventoryRow._(
    'SearchField',
    'Inputs',
    'Search field / search bar',
    refs: 'MC',
  );

  /// Password field with reveal.
  static const passwordField = RawInventoryRow._(
    'PasswordField',
    'Inputs',
    'Password field (reveal)',
    refs: 'S',
    behaviour: 'RawPasswordReveal',
  );

  /// Input group (prefix and suffix add-ons).
  static const inputGroup = RawInventoryRow._(
    'InputGroup',
    'Inputs',
    'Input group (prefix/suffix add-ons)',
    refs: 'S',
    behaviour: 'RawInputGroup',
  );

  /// OTP or PIN code.
  static const inputOtp = RawInventoryRow._(
    'InputOtp',
    'Inputs',
    'OTP / PIN code',
    refs: 'S',
    behaviour: 'RawOtpField',
  );

  /// Number field or quantity stepper.
  static const numberField = RawInventoryRow._(
    'NumberField',
    'Inputs',
    'Number field / quantity stepper',
    behaviour: 'RawNumberField',
  );

  /// Select or dropdown.
  static const select = RawInventoryRow._(
    'Select',
    'Inputs',
    'Select / dropdown',
    refs: 'MS',
  );

  /// Combobox or autocomplete.
  static const combobox = RawInventoryRow._(
    'Combobox',
    'Inputs',
    'Combobox / autocomplete',
    refs: 'MS',
    behaviour: 'RawCombobox',
  );

  /// Multi-select or tag input.
  static const multiSelect = RawInventoryRow._(
    'MultiSelect',
    'Inputs',
    'Multi-select / tag input',
    behaviour: 'RawTagInput',
  );

  /// Checkbox.
  static const checkbox = RawInventoryRow._(
    'Checkbox',
    'Inputs',
    'Checkbox',
    refs: 'MCS',
  );

  /// Radio group.
  static const radioGroup = RawInventoryRow._(
    'RadioGroup',
    'Inputs',
    'Radio group',
    refs: 'MCS',
  );

  /// Switch.
  static const switchControl = RawInventoryRow._(
    'Switch',
    'Inputs',
    'Switch',
    refs: 'MCS',
  );

  /// Slider.
  static const slider = RawInventoryRow._(
    'Slider',
    'Inputs',
    'Slider',
    refs: 'MCS',
  );

  /// Range slider.
  static const rangeSlider = RawInventoryRow._(
    'RangeSlider',
    'Inputs',
    'Range slider',
    refs: 'M',
    behaviour: 'RawRangeSlider',
  );

  /// Segmented control: a single-choice [toggleGroup].
  static const segmentedButton = RawInventoryRow._(
    'SegmentedButton',
    'Inputs',
    'Segmented control',
    refs: 'MC',
    behaviour: 'RawSegmentedButton',
  );

  /// Chips (filter, choice, input).
  static const chip = RawInventoryRow._(
    'Chip',
    'Inputs',
    'Chips (filter/choice/input)',
    refs: 'M',
  );

  /// Rating.
  static const rating = RawInventoryRow._(
    'Rating',
    'Inputs',
    'Rating',
    behaviour: 'RawRating',
  );

  /// File upload or drop zone.
  static const fileUpload = RawInventoryRow._(
    'FileUpload',
    'Inputs',
    'File upload / drop zone',
  );

  /// Date picker.
  static const datePicker = RawInventoryRow._(
    'DatePicker',
    'Inputs',
    'Date picker',
    refs: 'MCS',
  );

  /// Date range picker.
  static const dateRangePicker = RawInventoryRow._(
    'DateRangePicker',
    'Inputs',
    'Date range picker',
    refs: 'M',
    behaviour: 'RawCalendarDatePicker',
  );

  /// Time picker.
  static const timePicker = RawInventoryRow._(
    'TimePicker',
    'Inputs',
    'Time picker',
    refs: 'MCS',
    behaviour: 'RawTimeField',
  );

  /// Inline calendar.
  static const calendar = RawInventoryRow._(
    'Calendar',
    'Inputs',
    'Inline calendar',
    refs: 'MS',
    behaviour: 'RawCalendarDatePicker',
  );

  /// Wheel picker.
  static const wheelPicker = RawInventoryRow._(
    'WheelPicker',
    'Inputs',
    'Wheel picker',
    refs: 'C',
    behaviour: 'RawPicker',
  );

  /// Color picker.
  static const colorPicker = RawInventoryRow._(
    'ColorPicker',
    'Inputs',
    'Color picker',
    behaviour: 'RawColorPicker',
  );

  /// Form and field (label, help, error).
  static const formField = RawInventoryRow._(
    'FormField',
    'Inputs',
    'Form + field (label, help, error)',
    refs: 'MCS',
    behaviour: 'RawInputDecorator',
  );

  /// App bar, large and collapsing included.
  static const appBar = RawInventoryRow._(
    'AppBar',
    'Navigation',
    'App bar (incl. large/collapsing)',
    refs: 'MC',
  );

  /// Bottom navigation bar.
  static const navigationBar = RawInventoryRow._(
    'NavigationBar',
    'Navigation',
    'Bottom navigation bar',
    refs: 'MC',
    behaviour: 'RawAdaptiveShell',
  );

  /// Navigation rail.
  static const navigationRail = RawInventoryRow._(
    'NavigationRail',
    'Navigation',
    'Navigation rail',
    refs: 'M',
    behaviour: 'RawAdaptiveShell',
  );

  /// Navigation drawer or sidebar.
  static const navigationDrawer = RawInventoryRow._(
    'NavigationDrawer',
    'Navigation',
    'Navigation drawer / sidebar',
    refs: 'MS',
    behaviour: 'RawAdaptiveShell',
  );

  /// Tabs.
  static const tabBar = RawInventoryRow._(
    'TabBar',
    'Navigation',
    'Tabs',
    refs: 'MCS',
    behaviour: 'RawTabBar',
  );

  /// Breadcrumbs.
  static const breadcrumb = RawInventoryRow._(
    'Breadcrumb',
    'Navigation',
    'Breadcrumbs',
    refs: 'S',
  );

  /// Pagination.
  static const pagination = RawInventoryRow._(
    'Pagination',
    'Navigation',
    'Pagination',
    refs: 'S',
  );

  /// Step progress or wizard.
  static const stepProgress = RawInventoryRow._(
    'StepProgress',
    'Navigation',
    'Step progress / wizard',
    refs: 'M',
  );

  /// Page indicator dots.
  static const pageDots = RawInventoryRow._(
    'PageDots',
    'Navigation',
    'Page indicator dots',
  );

  /// Menubar (desktop).
  static const menuBar = RawInventoryRow._(
    'MenuBar',
    'Navigation',
    'Menubar (desktop)',
    refs: 'MS',
    behaviour: 'RawMenuBar',
  );

  /// Command palette.
  static const command = RawInventoryRow._(
    'Command',
    'Navigation',
    'Command palette',
    refs: 'S',
    behaviour: 'RawCommandPalette',
  );

  /// Adaptive app shell or scaffold.
  static const scaffold = RawInventoryRow._(
    'Scaffold',
    'Navigation',
    'Adaptive app shell / scaffold',
    refs: 'MC',
    behaviour: 'RawAdaptiveShell',
  );

  /// Card.
  static const card = RawInventoryRow._(
    'Card',
    'Containers',
    'Card',
    refs: 'MCS',
  );

  /// List row or list tile.
  static const listTile = RawInventoryRow._(
    'ListTile',
    'Containers',
    'List row / list tile',
    refs: 'MCS',
  );

  /// Grouped or inset list.
  static const listSection = RawInventoryRow._(
    'ListSection',
    'Containers',
    'Grouped / inset list',
    refs: 'C',
  );

  /// Section header.
  static const sectionHeader = RawInventoryRow._(
    'SectionHeader',
    'Containers',
    'Section header',
    refs: 'C',
  );

  /// Accordion, expansion or collapsible.
  static const disclosure = RawInventoryRow._(
    'Disclosure',
    'Containers',
    'Accordion / expansion / collapsible',
    refs: 'MCS',
  );

  /// Table.
  static const table = RawInventoryRow._(
    'Table',
    'Containers',
    'Table',
    refs: 'MS',
  );

  /// Data table (sort, select, paginate).
  static const dataTable = RawInventoryRow._(
    'DataTable',
    'Containers',
    'Data table (sort, select, paginate)',
    refs: 'MS',
    behaviour: 'RawDataTableController',
  );

  /// Divider or separator.
  static const divider = RawInventoryRow._(
    'Divider',
    'Containers',
    'Divider / separator',
    refs: 'MCS',
  );

  /// Scroll area or scrollbar.
  static const scrollArea = RawInventoryRow._(
    'ScrollArea',
    'Containers',
    'Scroll area / scrollbar',
    refs: 'MCS',
    behaviour: 'RawScrollArea',
  );

  /// Resizable panels or split view.
  static const resizable = RawInventoryRow._(
    'Resizable',
    'Containers',
    'Resizable panels / split view',
    refs: 'S',
    behaviour: 'RawSplitView',
  );

  /// Carousel.
  static const carouselView = RawInventoryRow._(
    'CarouselView',
    'Containers',
    'Carousel',
    refs: 'MS',
    behaviour: 'RawCarousel',
  );

  /// Reorderable list.
  static const reorderableListView = RawInventoryRow._(
    'ReorderableListView',
    'Containers',
    'Reorderable list',
    refs: 'M',
    behaviour: 'RawReorderableList',
  );

  /// Swipe actions or dismissible.
  static const swipeActions = RawInventoryRow._(
    'SwipeActions',
    'Containers',
    'Swipe actions / dismissible',
    refs: 'C',
    behaviour: 'RawSwipeActions',
  );

  /// Pull to refresh.
  static const refreshIndicator = RawInventoryRow._(
    'RefreshIndicator',
    'Containers',
    'Pull to refresh',
    refs: 'MC',
    behaviour: 'RawRefreshIndicator',
  );

  /// Tree view.
  static const treeView = RawInventoryRow._(
    'TreeView',
    'Containers',
    'Tree view',
    behaviour: 'RawTree',
  );

  /// Timeline.
  static const timeline = RawInventoryRow._(
    'Timeline',
    'Containers',
    'Timeline',
  );

  /// Avatar.
  static const avatar = RawInventoryRow._(
    'Avatar',
    'Containers',
    'Avatar',
    refs: 'MS',
  );

  /// Avatar group or face pile.
  static const avatarGroup = RawInventoryRow._(
    'AvatarGroup',
    'Containers',
    'Avatar group / face pile',
  );

  /// Badge (count).
  static const badge = RawInventoryRow._(
    'Badge',
    'Containers',
    'Badge (count)',
    refs: 'MS',
  );

  /// Tag or label pill.
  static const tag = RawInventoryRow._(
    'Tag',
    'Containers',
    'Tag / label pill',
    refs: 'S',
  );

  /// Image or media with a fallback.
  static const media = RawInventoryRow._(
    'Media',
    'Containers',
    'Image / media with fallback',
  );

  /// Empty state.
  static const emptyState = RawInventoryRow._(
    'EmptyState',
    'Containers',
    'Empty state',
    refs: 'S',
  );

  /// Key-value or description list.
  static const descriptionList = RawInventoryRow._(
    'DescriptionList',
    'Containers',
    'Key-value / description list',
  );

  /// Dialog or alert dialog.
  static const dialog = RawInventoryRow._(
    'Dialog',
    'Overlays',
    'Dialog / alert dialog',
    refs: 'MCS',
    behaviour: 'RawModalDialogRoute',
  );

  /// Bottom sheet or modal sheet.
  static const bottomSheet = RawInventoryRow._(
    'BottomSheet',
    'Overlays',
    'Bottom sheet / modal sheet',
    refs: 'MCS',
    behaviour: 'RawBottomSheetRoute',
  );

  /// Side sheet or drawer overlay.
  static const sheet = RawInventoryRow._(
    'Sheet',
    'Overlays',
    'Side sheet / drawer overlay',
    refs: 'MS',
    behaviour: 'RawSideSheetRoute',
  );

  /// Action sheet.
  static const actionSheet = RawInventoryRow._(
    'ActionSheet',
    'Overlays',
    'Action sheet',
    refs: 'C',
  );

  /// Popover.
  static const popover = RawInventoryRow._(
    'Popover',
    'Overlays',
    'Popover',
    refs: 'S',
    behaviour: 'RawPopover',
  );

  /// Hover card.
  static const hoverCard = RawInventoryRow._(
    'HoverCard',
    'Overlays',
    'Hover card',
    refs: 'S',
    behaviour: 'RawPopover',
  );

  /// Tooltip.
  static const tooltip = RawInventoryRow._(
    'Tooltip',
    'Overlays',
    'Tooltip',
    refs: 'MS',
    behaviour: 'RawTooltip',
  );

  /// Menu or context menu.
  static const menu = RawInventoryRow._(
    'Menu',
    'Overlays',
    'Menu / context menu',
    refs: 'MCS',
    behaviour: 'RawContextMenu',
  );

  /// Toast or snackbar, stacking.
  static const snackBar = RawInventoryRow._(
    'SnackBar',
    'Overlays',
    'Toast / snackbar (stacking)',
    refs: 'MS',
    behaviour: 'RawToaster',
  );

  /// Banner or inline alert.
  static const banner = RawInventoryRow._(
    'Banner',
    'Overlays',
    'Banner / inline alert',
    refs: 'MS',
  );

  /// Linear progress.
  static const linearProgressIndicator = RawInventoryRow._(
    'LinearProgressIndicator',
    'Feedback',
    'Linear progress',
    refs: 'MCS',
  );

  /// Circular progress or spinner.
  static const circularProgressIndicator = RawInventoryRow._(
    'CircularProgressIndicator',
    'Feedback',
    'Circular progress / spinner',
    refs: 'MCS',
  );

  /// Skeleton.
  static const skeleton = RawInventoryRow._(
    'Skeleton',
    'Feedback',
    'Skeleton',
    refs: 'S',
  );

  /// Loading, error and success states.
  static const statusView = RawInventoryRow._(
    'StatusView',
    'Feedback',
    'Loading / error / success states',
  );

  /// Meter or gauge.
  static const meter = RawInventoryRow._('Meter', 'Feedback', 'Meter / gauge');

  /// Line chart.
  static const lineChart = RawInventoryRow._(
    'LineChart',
    'Charts',
    'Line chart',
    behaviour: 'RawChart',
  );

  /// Bar chart.
  static const barChart = RawInventoryRow._(
    'BarChart',
    'Charts',
    'Bar chart',
    behaviour: 'RawChart',
  );

  /// Area chart.
  static const areaChart = RawInventoryRow._(
    'AreaChart',
    'Charts',
    'Area chart',
    behaviour: 'RawChart',
  );

  /// Donut or pie.
  static const pieChart = RawInventoryRow._(
    'PieChart',
    'Charts',
    'Donut / pie',
    behaviour: 'RawPieChart',
  );

  /// Sparkline.
  static const sparkline = RawInventoryRow._(
    'Sparkline',
    'Charts',
    'Sparkline',
    behaviour: 'RawChart',
  );

  /// Every row, group by group in [groups]' order.
  static const List<RawInventoryRow> all = [
    button,
    iconButton,
    floatingActionButton,
    buttonGroup,
    toggleGroup,
    splitButton,
    link,
    kbd,
    textField,
    textArea,
    searchField,
    passwordField,
    inputGroup,
    inputOtp,
    numberField,
    select,
    combobox,
    multiSelect,
    checkbox,
    radioGroup,
    switchControl,
    slider,
    rangeSlider,
    segmentedButton,
    chip,
    rating,
    fileUpload,
    datePicker,
    dateRangePicker,
    timePicker,
    calendar,
    wheelPicker,
    colorPicker,
    formField,
    appBar,
    navigationBar,
    navigationRail,
    navigationDrawer,
    tabBar,
    breadcrumb,
    pagination,
    stepProgress,
    pageDots,
    menuBar,
    command,
    scaffold,
    card,
    listTile,
    listSection,
    sectionHeader,
    disclosure,
    table,
    dataTable,
    divider,
    scrollArea,
    resizable,
    carouselView,
    reorderableListView,
    swipeActions,
    refreshIndicator,
    treeView,
    timeline,
    avatar,
    avatarGroup,
    badge,
    tag,
    media,
    emptyState,
    descriptionList,
    dialog,
    bottomSheet,
    sheet,
    actionSheet,
    popover,
    hoverCard,
    tooltip,
    menu,
    snackBar,
    banner,
    linearProgressIndicator,
    circularProgressIndicator,
    skeleton,
    statusView,
    meter,
    lineChart,
    barChart,
    areaChart,
    pieChart,
    sparkline,
  ];

  /// The row with [id], or null when no row has it.
  static RawInventoryRow? byId(String id) {
    for (final row in all) {
      if (row.id == id) return row;
    }
    return null;
  }

  /// The groups, in order.
  static const List<String> groups = [
    'Actions',
    'Inputs',
    'Navigation',
    'Containers',
    'Overlays',
    'Feedback',
    'Charts',
  ];
}

/// A look's answer to one row: a live specimen ([builder]) or the reason
/// the look leaves it out ([absentReason]).
///
/// ```dart
/// RawInventoryEntry.present('Link', (context) => const Text('Terms'))
/// ```
@immutable
class RawInventoryEntry {
  /// An entry for [row] (a [RawInventoryRow.id]). Give exactly one of
  /// [builder] and [absentReason]; [RawInventory.verify] fails otherwise.
  const RawInventoryEntry(this.row, {this.builder, this.absentReason});

  /// [row] is present: [builder] makes a live specimen of it, in whatever
  /// class the look gives the component (the gallery frames it).
  const RawInventoryEntry.present(this.row, WidgetBuilder this.builder)
    : absentReason = null;

  /// [row] is deliberately absent, for [absentReason] ("a floating action
  /// button is Material vocabulary"; "not built yet" is not a reason).
  const RawInventoryEntry.absent(this.row, String this.absentReason)
    : builder = null;

  /// The row's id ([RawInventoryRow.id]).
  final String row;

  /// Makes a live specimen of the row, in the look's own hand.
  final WidgetBuilder? builder;

  /// Why the look leaves the row out.
  final String? absentReason;

  /// Whether the look carries the row.
  bool get isPresent => builder != null;
}

/// Thrown by [RawInventory.verify]: the rows an inventory answers wrong.
class RawInventoryError extends Error {
  /// An error listing [problems].
  RawInventoryError(this.look, this.problems);

  /// The look whose inventory it is.
  final String look;

  /// One line per problem.
  final List<String> problems;

  @override
  String toString() =>
      '$look inventory: ${problems.length} problem(s)\n${problems.join('\n')}';
}

/// A look's inventory: one entry per [RawInventoryRow].
///
/// ```dart
/// const RawInventory(look: 'Comic', entries: [RawInventoryEntry.absent('FloatingActionButton', 'A floating action button is Material vocabulary')])
/// ```
@immutable
class RawInventory {
  /// The inventory of [look].
  const RawInventory({required this.look, required this.entries});

  /// The look's display name.
  final String look;

  /// One entry per row, in any order.
  final List<RawInventoryEntry> entries;

  /// The entry for the row [id], or null when the inventory has none.
  RawInventoryEntry? entryFor(String id) {
    for (final entry in entries) {
      if (entry.row == id) return entry;
    }
    return null;
  }

  /// How many rows the look carries live.
  int get presentCount => entries.where((e) => e.isPresent).length;

  /// How many rows the look leaves out with a reason.
  int get absentCount =>
      entries.where((e) => !e.isPresent && e.absentReason != null).length;

  /// What a gap reads as in a gallery.
  static String absentLabel(String reason) => 'Deliberately absent: $reason';

  /// Words that mark a reason as a to-do rather than a reason.
  static final RegExp _placeholder = RegExp(
    r'\b(todo|tbd|wip|fixme|coming soon)\b|\bnot (yet )?(built|done|implemented|ready|ported)\b|\bnot \w+ yet\b',
    caseSensitive: false,
  );

  /// Every way the inventory answers the rows wrong, one line each: an
  /// unknown row id, a row answered twice, a row not answered, an entry
  /// with neither a specimen nor a reason (or both), and a reason that is
  /// a to-do ("not built yet").
  List<String> get problems {
    final out = <String>[];
    final seen = <String>{};
    for (final entry in entries) {
      final row = RawInventoryRow.byId(entry.row);
      if (row == null) {
        out.add('unknown row id "${entry.row}"');
        continue;
      }
      if (!seen.add(entry.row)) {
        out.add('${entry.row}: answered more than once');
      }
      final reason = entry.absentReason?.trim();
      if (entry.builder == null && (reason == null || reason.isEmpty)) {
        out.add(
          '${entry.row}: neither a live specimen nor a reason it is absent',
        );
      } else if (entry.builder != null && entry.absentReason != null) {
        out.add('${entry.row}: both a live specimen and a reason it is absent');
      } else if (reason != null && _placeholder.hasMatch(reason)) {
        out.add(
          '${entry.row}: "$reason" is a to-do, not a reason the look leaves '
          'it out',
        );
      }
    }
    for (final row in RawInventoryRow.all) {
      if (!seen.contains(row.id)) {
        out.add('${row.id}: missing (${row.name})');
      }
    }
    return out;
  }

  /// Throws a [RawInventoryError] naming every [problems] line; a look's
  /// test calls it.
  void verify() {
    final found = problems;
    if (found.isNotEmpty) throw RawInventoryError(look, found);
  }
}

/// Builds a group's heading in a [RawInventoryGallery]: [present] of
/// [total] rows carried.
typedef RawInventoryGroupBuilder = Widget Function(
  BuildContext context,
  String group,
  int present,
  int total,
);

/// Builds one row in a [RawInventoryGallery]. [entry] is null when the
/// inventory does not answer the row; [specimen] is the entry's live
/// specimen, built, when it has one.
typedef RawInventoryRowBuilder = Widget Function(
  BuildContext context,
  RawInventoryRow row,
  RawInventoryEntry? entry,
  Widget? specimen,
);

/// Lists an inventory, group by group in [RawInventoryRow.groups]' order: each row's
/// live specimen, or `Deliberately absent: <reason>` for a gap, or
/// "Missing" for a row the inventory does not answer. Lazy: a row builds
/// when it scrolls in.
///
/// The look paints it through [groupBuilder] and [rowBuilder]; without
/// them each row is its name over its specimen or its reason, in the
/// ambient text style.
class RawInventoryGallery extends StatelessWidget {
  /// A gallery of [inventory].
  const RawInventoryGallery({
    super.key,
    required this.inventory,
    this.groupBuilder,
    this.rowBuilder,
    this.padding = const EdgeInsets.all(16),
    this.controller,
    this.behaviourOnly = false,
  });

  /// The inventory to list.
  final RawInventory inventory;

  /// Draws a group's heading.
  final RawInventoryGroupBuilder? groupBuilder;

  /// Draws a row.
  final RawInventoryRowBuilder? rowBuilder;

  /// Space around the list.
  final EdgeInsetsGeometry padding;

  /// The list's scroll controller. The caller's, who disposes it; null: the
  /// list's scroll view makes its own.
  final ScrollController? controller;

  /// Whether to list only the behaviour rows.
  final bool behaviourOnly;

  @override
  Widget build(BuildContext context) {
    final items = <Object>[];
    for (final group in RawInventoryRow.groups) {
      final rows = RawInventoryRow.all
          .where((r) => r.group == group && (!behaviourOnly || r.isBehaviour))
          .toList();
      if (rows.isEmpty) continue;
      items
        ..add(group)
        ..addAll(rows);
    }
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is String) {
          final rows = RawInventoryRow.all.where((r) => r.group == item);
          final present = rows.where(
            (r) => inventory.entryFor(r.id)?.isPresent ?? false,
          );
          return Semantics(
            header: true,
            child:
                groupBuilder?.call(
                  context,
                  item,
                  present.length,
                  rows.length,
                ) ??
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text('$item (${present.length}/${rows.length})'),
                ),
          );
        }
        final row = item as RawInventoryRow;
        final entry = inventory.entryFor(row.id);
        final specimen = entry?.builder?.call(context);
        final builder = rowBuilder;
        if (builder != null) return builder(context, row, entry, specimen);
        return KeyedSubtree(
          key: ValueKey<String>('inventory-${row.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  specimen == null
                      ? row.name
                      : '${specimen.runtimeType.toString().split('<').first} · ${row.name}',
                ),
                const SizedBox(height: 4),
                specimen ??
                    Text(
                      entry?.absentReason != null
                          ? RawInventory.absentLabel(entry!.absentReason!)
                          : 'Missing: the inventory does not answer this row',
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
      ..add(DiagnosticsProperty<RawInventory>('inventory', inventory))
      ..add(
        ObjectFlagProperty<RawInventoryGroupBuilder>.has(
          'groupBuilder',
          groupBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawInventoryRowBuilder>.has(
          'rowBuilder',
          rowBuilder,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: const EdgeInsets.all(16),
        ),
      )
      ..add(
        DiagnosticsProperty<ScrollController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'behaviourOnly',
          value: behaviourOnly,
          ifTrue: 'behaviourOnly',
          defaultValue: false,
        ),
      );
  }
}
