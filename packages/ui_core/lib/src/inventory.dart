/// The component inventory: a checklist of the components an ordinary app
/// expects from a design system, one [DesignInventoryRow] each, and a
/// look's [DesignInventory], which answers every row with a live specimen
/// or the reason the look deliberately leaves it out.
///
/// A row's id is a label for the thing (Material's name where Material has
/// it, shadcn's where only shadcn does), not a name a look must use: each
/// look names its own components, and their API is its own.
///
/// A look's test calls [DesignInventory.verify]; its gallery lists the
/// inventory with [DesignInventoryGallery], so an absent row reads
/// `Deliberately absent: <reason>` rather than going missing.
library;

import 'package:flutter/widgets.dart';

/// One row of the inventory: a component every look either carries or
/// leaves out with a reason.
@immutable
class DesignInventoryRow {
  const DesignInventoryRow._(
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
  String toString() => 'DesignInventoryRow($id)';

  /// Button (filled, outlined, text, danger).
  static const button = DesignInventoryRow._(
    'Button',
    'Actions',
    'Button (filled/outlined/text/danger)',
    refs: 'MCS',
  );

  /// Icon button.
  static const iconButton = DesignInventoryRow._(
    'IconButton',
    'Actions',
    'Icon button',
    refs: 'MCS',
  );

  /// Floating action button (extended, menu).
  static const floatingActionButton = DesignInventoryRow._(
    'FloatingActionButton',
    'Actions',
    'Floating action button (+extended, menu)',
    refs: 'M',
  );

  /// Button group or toolbar.
  static const buttonGroup = DesignInventoryRow._(
    'ButtonGroup',
    'Actions',
    'Button group / toolbar',
    refs: 'MS',
  );

  /// Toggle button or toggle group.
  static const toggleGroup = DesignInventoryRow._(
    'ToggleGroup',
    'Actions',
    'Toggle button / toggle group',
    refs: 'MS',
    behaviour: 'DesignToggleGroup',
  );

  /// Split button.
  static const splitButton = DesignInventoryRow._(
    'SplitButton',
    'Actions',
    'Split button',
    refs: 'M',
    behaviour: 'DesignSplitButton',
  );

  /// Link.
  static const link = DesignInventoryRow._(
    'Link',
    'Actions',
    'Link',
    refs: 'S',
  );

  /// Keyboard key (Kbd).
  static const kbd = DesignInventoryRow._(
    'Kbd',
    'Actions',
    'Keyboard key (Kbd)',
    refs: 'S',
  );

  /// Text field.
  static const textField = DesignInventoryRow._(
    'TextField',
    'Inputs',
    'Text field',
    refs: 'MCS',
  );

  /// Text area.
  static const textArea = DesignInventoryRow._(
    'TextArea',
    'Inputs',
    'Text area',
    refs: 'S',
  );

  /// Search field or search bar.
  static const searchField = DesignInventoryRow._(
    'SearchField',
    'Inputs',
    'Search field / search bar',
    refs: 'MC',
  );

  /// Password field with reveal.
  static const passwordField = DesignInventoryRow._(
    'PasswordField',
    'Inputs',
    'Password field (reveal)',
    refs: 'S',
    behaviour: 'DesignPasswordReveal',
  );

  /// Input group (prefix and suffix add-ons).
  static const inputGroup = DesignInventoryRow._(
    'InputGroup',
    'Inputs',
    'Input group (prefix/suffix add-ons)',
    refs: 'S',
    behaviour: 'DesignInputGroup',
  );

  /// OTP or PIN code.
  static const inputOtp = DesignInventoryRow._(
    'InputOtp',
    'Inputs',
    'OTP / PIN code',
    refs: 'S',
    behaviour: 'DesignOtpField',
  );

  /// Number field or quantity stepper.
  static const numberField = DesignInventoryRow._(
    'NumberField',
    'Inputs',
    'Number field / quantity stepper',
  );

  /// Select or dropdown.
  static const select = DesignInventoryRow._(
    'Select',
    'Inputs',
    'Select / dropdown',
    refs: 'MS',
  );

  /// Combobox or autocomplete.
  static const combobox = DesignInventoryRow._(
    'Combobox',
    'Inputs',
    'Combobox / autocomplete',
    refs: 'MS',
    behaviour: 'DesignCombobox',
  );

  /// Multi-select or tag input.
  static const multiSelect = DesignInventoryRow._(
    'MultiSelect',
    'Inputs',
    'Multi-select / tag input',
    behaviour: 'DesignTagInput',
  );

  /// Checkbox.
  static const checkbox = DesignInventoryRow._(
    'Checkbox',
    'Inputs',
    'Checkbox',
    refs: 'MCS',
  );

  /// Radio group.
  static const radioGroup = DesignInventoryRow._(
    'RadioGroup',
    'Inputs',
    'Radio group',
    refs: 'MCS',
  );

  /// Switch.
  static const switchControl = DesignInventoryRow._(
    'Switch',
    'Inputs',
    'Switch',
    refs: 'MCS',
  );

  /// Slider.
  static const slider = DesignInventoryRow._(
    'Slider',
    'Inputs',
    'Slider',
    refs: 'MCS',
  );

  /// Range slider.
  static const rangeSlider = DesignInventoryRow._(
    'RangeSlider',
    'Inputs',
    'Range slider',
    refs: 'M',
    behaviour: 'DesignRangeSlider',
  );

  /// Segmented control.
  static const segmentedButton = DesignInventoryRow._(
    'SegmentedButton',
    'Inputs',
    'Segmented control',
    refs: 'MC',
  );

  /// Chips (filter, choice, input).
  static const chip = DesignInventoryRow._(
    'Chip',
    'Inputs',
    'Chips (filter/choice/input)',
    refs: 'M',
  );

  /// Rating.
  static const rating = DesignInventoryRow._('Rating', 'Inputs', 'Rating');

  /// File upload or drop zone.
  static const fileUpload = DesignInventoryRow._(
    'FileUpload',
    'Inputs',
    'File upload / drop zone',
  );

  /// Date picker.
  static const datePicker = DesignInventoryRow._(
    'DatePicker',
    'Inputs',
    'Date picker',
    refs: 'MCS',
  );

  /// Date range picker.
  static const dateRangePicker = DesignInventoryRow._(
    'DateRangePicker',
    'Inputs',
    'Date range picker',
    refs: 'M',
    behaviour: 'DesignCalendar',
  );

  /// Time picker.
  static const timePicker = DesignInventoryRow._(
    'TimePicker',
    'Inputs',
    'Time picker',
    refs: 'MCS',
  );

  /// Inline calendar.
  static const calendar = DesignInventoryRow._(
    'Calendar',
    'Inputs',
    'Inline calendar',
    refs: 'MS',
    behaviour: 'DesignCalendar',
  );

  /// Wheel picker.
  static const wheelPicker = DesignInventoryRow._(
    'WheelPicker',
    'Inputs',
    'Wheel picker',
    refs: 'C',
  );

  /// Color picker.
  static const colorPicker = DesignInventoryRow._(
    'ColorPicker',
    'Inputs',
    'Color picker',
    behaviour: 'DesignColorPicker',
  );

  /// Form and field (label, help, error).
  static const formField = DesignInventoryRow._(
    'FormField',
    'Inputs',
    'Form + field (label, help, error)',
    refs: 'MCS',
    behaviour: 'DesignField',
  );

  /// App bar, large and collapsing included.
  static const appBar = DesignInventoryRow._(
    'AppBar',
    'Navigation',
    'App bar (incl. large/collapsing)',
    refs: 'MC',
  );

  /// Bottom navigation bar.
  static const navigationBar = DesignInventoryRow._(
    'NavigationBar',
    'Navigation',
    'Bottom navigation bar',
    refs: 'MC',
  );

  /// Navigation rail.
  static const navigationRail = DesignInventoryRow._(
    'NavigationRail',
    'Navigation',
    'Navigation rail',
    refs: 'M',
  );

  /// Navigation drawer or sidebar.
  static const navigationDrawer = DesignInventoryRow._(
    'NavigationDrawer',
    'Navigation',
    'Navigation drawer / sidebar',
    refs: 'MS',
  );

  /// Tabs.
  static const tabBar = DesignInventoryRow._(
    'TabBar',
    'Navigation',
    'Tabs',
    refs: 'MCS',
  );

  /// Breadcrumbs.
  static const breadcrumb = DesignInventoryRow._(
    'Breadcrumb',
    'Navigation',
    'Breadcrumbs',
    refs: 'S',
  );

  /// Pagination.
  static const pagination = DesignInventoryRow._(
    'Pagination',
    'Navigation',
    'Pagination',
    refs: 'S',
  );

  /// Step progress or wizard.
  static const stepProgress = DesignInventoryRow._(
    'StepProgress',
    'Navigation',
    'Step progress / wizard',
    refs: 'M',
  );

  /// Page indicator dots.
  static const pageDots = DesignInventoryRow._(
    'PageDots',
    'Navigation',
    'Page indicator dots',
  );

  /// Menubar (desktop).
  static const menuBar = DesignInventoryRow._(
    'MenuBar',
    'Navigation',
    'Menubar (desktop)',
    refs: 'MS',
    behaviour: 'DesignMenuBar',
  );

  /// Command palette.
  static const command = DesignInventoryRow._(
    'Command',
    'Navigation',
    'Command palette',
    refs: 'S',
    behaviour: 'DesignCommandPalette',
  );

  /// Adaptive app shell or scaffold.
  static const scaffold = DesignInventoryRow._(
    'Scaffold',
    'Navigation',
    'Adaptive app shell / scaffold',
    refs: 'MC',
  );

  /// Card.
  static const card = DesignInventoryRow._(
    'Card',
    'Containers',
    'Card',
    refs: 'MCS',
  );

  /// List row or list tile.
  static const listTile = DesignInventoryRow._(
    'ListTile',
    'Containers',
    'List row / list tile',
    refs: 'MCS',
  );

  /// Grouped or inset list.
  static const listSection = DesignInventoryRow._(
    'ListSection',
    'Containers',
    'Grouped / inset list',
    refs: 'C',
  );

  /// Section header.
  static const sectionHeader = DesignInventoryRow._(
    'SectionHeader',
    'Containers',
    'Section header',
    refs: 'C',
  );

  /// Accordion, expansion or collapsible.
  static const disclosure = DesignInventoryRow._(
    'Disclosure',
    'Containers',
    'Accordion / expansion / collapsible',
    refs: 'MCS',
  );

  /// Table.
  static const table = DesignInventoryRow._(
    'Table',
    'Containers',
    'Table',
    refs: 'MS',
  );

  /// Data table (sort, select, paginate).
  static const dataTable = DesignInventoryRow._(
    'DataTable',
    'Containers',
    'Data table (sort, select, paginate)',
    refs: 'MS',
    behaviour: 'DesignTableController',
  );

  /// Divider or separator.
  static const divider = DesignInventoryRow._(
    'Divider',
    'Containers',
    'Divider / separator',
    refs: 'MCS',
  );

  /// Scroll area or scrollbar.
  static const scrollArea = DesignInventoryRow._(
    'ScrollArea',
    'Containers',
    'Scroll area / scrollbar',
    refs: 'MCS',
    behaviour: 'DesignScrollArea',
  );

  /// Resizable panels or split view.
  static const resizable = DesignInventoryRow._(
    'Resizable',
    'Containers',
    'Resizable panels / split view',
    refs: 'S',
    behaviour: 'DesignSplitView',
  );

  /// Carousel.
  static const carouselView = DesignInventoryRow._(
    'CarouselView',
    'Containers',
    'Carousel',
    refs: 'MS',
    behaviour: 'DesignCarousel',
  );

  /// Reorderable list.
  static const reorderableListView = DesignInventoryRow._(
    'ReorderableListView',
    'Containers',
    'Reorderable list',
    refs: 'M',
    behaviour: 'DesignReorderableList',
  );

  /// Swipe actions or dismissible.
  static const swipeActions = DesignInventoryRow._(
    'SwipeActions',
    'Containers',
    'Swipe actions / dismissible',
    refs: 'C',
    behaviour: 'DesignSwipeActions',
  );

  /// Pull to refresh.
  static const refreshIndicator = DesignInventoryRow._(
    'RefreshIndicator',
    'Containers',
    'Pull to refresh',
    refs: 'MC',
    behaviour: 'DesignPullToRefresh',
  );

  /// Tree view.
  static const treeView = DesignInventoryRow._(
    'TreeView',
    'Containers',
    'Tree view',
    behaviour: 'DesignTree',
  );

  /// Timeline.
  static const timeline = DesignInventoryRow._(
    'Timeline',
    'Containers',
    'Timeline',
  );

  /// Avatar.
  static const avatar = DesignInventoryRow._(
    'Avatar',
    'Containers',
    'Avatar',
    refs: 'MS',
  );

  /// Avatar group or face pile.
  static const avatarGroup = DesignInventoryRow._(
    'AvatarGroup',
    'Containers',
    'Avatar group / face pile',
  );

  /// Badge (count).
  static const badge = DesignInventoryRow._(
    'Badge',
    'Containers',
    'Badge (count)',
    refs: 'MS',
  );

  /// Tag or label pill.
  static const tag = DesignInventoryRow._(
    'Tag',
    'Containers',
    'Tag / label pill',
    refs: 'S',
  );

  /// Image or media with a fallback.
  static const media = DesignInventoryRow._(
    'Media',
    'Containers',
    'Image / media with fallback',
  );

  /// Empty state.
  static const emptyState = DesignInventoryRow._(
    'EmptyState',
    'Containers',
    'Empty state',
    refs: 'S',
  );

  /// Key-value or description list.
  static const descriptionList = DesignInventoryRow._(
    'DescriptionList',
    'Containers',
    'Key-value / description list',
  );

  /// Dialog or alert dialog.
  static const dialog = DesignInventoryRow._(
    'Dialog',
    'Overlays',
    'Dialog / alert dialog',
    refs: 'MCS',
  );

  /// Bottom sheet or modal sheet.
  static const bottomSheet = DesignInventoryRow._(
    'BottomSheet',
    'Overlays',
    'Bottom sheet / modal sheet',
    refs: 'MCS',
  );

  /// Side sheet or drawer overlay.
  static const sheet = DesignInventoryRow._(
    'Sheet',
    'Overlays',
    'Side sheet / drawer overlay',
    refs: 'MS',
    behaviour: 'DesignSideSheetRoute',
  );

  /// Action sheet.
  static const actionSheet = DesignInventoryRow._(
    'ActionSheet',
    'Overlays',
    'Action sheet',
    refs: 'C',
  );

  /// Popover.
  static const popover = DesignInventoryRow._(
    'Popover',
    'Overlays',
    'Popover',
    refs: 'S',
    behaviour: 'DesignAnchoredOverlay',
  );

  /// Hover card.
  static const hoverCard = DesignInventoryRow._(
    'HoverCard',
    'Overlays',
    'Hover card',
    refs: 'S',
    behaviour: 'DesignAnchoredOverlay',
  );

  /// Tooltip.
  static const tooltip = DesignInventoryRow._(
    'Tooltip',
    'Overlays',
    'Tooltip',
    refs: 'MS',
  );

  /// Menu or context menu.
  static const menu = DesignInventoryRow._(
    'Menu',
    'Overlays',
    'Menu / context menu',
    refs: 'MCS',
  );

  /// Toast or snackbar, stacking.
  static const snackBar = DesignInventoryRow._(
    'SnackBar',
    'Overlays',
    'Toast / snackbar (stacking)',
    refs: 'MS',
    behaviour: 'DesignToaster',
  );

  /// Banner or inline alert.
  static const banner = DesignInventoryRow._(
    'Banner',
    'Overlays',
    'Banner / inline alert',
    refs: 'MS',
  );

  /// Linear progress.
  static const linearProgressIndicator = DesignInventoryRow._(
    'LinearProgressIndicator',
    'Feedback',
    'Linear progress',
    refs: 'MCS',
  );

  /// Circular progress or spinner.
  static const circularProgressIndicator = DesignInventoryRow._(
    'CircularProgressIndicator',
    'Feedback',
    'Circular progress / spinner',
    refs: 'MCS',
  );

  /// Skeleton.
  static const skeleton = DesignInventoryRow._(
    'Skeleton',
    'Feedback',
    'Skeleton',
    refs: 'S',
  );

  /// Loading, error and success states.
  static const statusView = DesignInventoryRow._(
    'StatusView',
    'Feedback',
    'Loading / error / success states',
  );

  /// Meter or gauge.
  static const meter = DesignInventoryRow._(
    'Meter',
    'Feedback',
    'Meter / gauge',
  );

  /// Line chart.
  static const lineChart = DesignInventoryRow._(
    'LineChart',
    'Charts',
    'Line chart',
  );

  /// Bar chart.
  static const barChart = DesignInventoryRow._(
    'BarChart',
    'Charts',
    'Bar chart',
  );

  /// Area chart.
  static const areaChart = DesignInventoryRow._(
    'AreaChart',
    'Charts',
    'Area chart',
  );

  /// Donut or pie.
  static const pieChart = DesignInventoryRow._(
    'PieChart',
    'Charts',
    'Donut / pie',
  );

  /// Sparkline.
  static const sparkline = DesignInventoryRow._(
    'Sparkline',
    'Charts',
    'Sparkline',
  );

  /// Every row, group by group in [groups]' order.
  static const List<DesignInventoryRow> all = [
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
  static DesignInventoryRow? byId(String id) {
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
/// DesignInventoryEntry.present('Link', (context) => const Text('Terms'))
/// ```
@immutable
class DesignInventoryEntry {
  /// An entry for [row] (a [DesignInventoryRow.id]). Give exactly one of
  /// [builder] and [absentReason]; [DesignInventory.verify] fails otherwise.
  const DesignInventoryEntry(this.row, {this.builder, this.absentReason});

  /// [row] is present: [builder] makes a live specimen of it, in whatever
  /// class the look gives the component (the gallery frames it).
  const DesignInventoryEntry.present(this.row, WidgetBuilder this.builder)
    : absentReason = null;

  /// [row] is deliberately absent, for [absentReason] ("a floating action
  /// button is Material vocabulary"; "not built yet" is not a reason).
  const DesignInventoryEntry.absent(this.row, String this.absentReason)
    : builder = null;

  /// The row's id ([DesignInventoryRow.id]).
  final String row;

  /// Makes a live specimen of the row, in the look's own hand.
  final WidgetBuilder? builder;

  /// Why the look leaves the row out.
  final String? absentReason;

  /// Whether the look carries the row.
  bool get isPresent => builder != null;
}

/// Thrown by [DesignInventory.verify]: the rows an inventory answers wrong.
class DesignInventoryError extends Error {
  /// An error listing [problems].
  DesignInventoryError(this.look, this.problems);

  /// The look whose inventory it is.
  final String look;

  /// One line per problem.
  final List<String> problems;

  @override
  String toString() =>
      '$look inventory: ${problems.length} problem(s)\n${problems.join('\n')}';
}

/// A look's inventory: one entry per [DesignInventoryRow].
///
/// ```dart
/// const DesignInventory(look: 'Comic', entries: [DesignInventoryEntry.absent('FloatingActionButton', 'A floating action button is Material vocabulary')])
/// ```
@immutable
class DesignInventory {
  /// The inventory of [look].
  const DesignInventory({required this.look, required this.entries});

  /// The look's display name.
  final String look;

  /// One entry per row, in any order.
  final List<DesignInventoryEntry> entries;

  /// The entry for the row [id], or null when the inventory has none.
  DesignInventoryEntry? entryFor(String id) {
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
      final row = DesignInventoryRow.byId(entry.row);
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
    for (final row in DesignInventoryRow.all) {
      if (!seen.contains(row.id)) {
        out.add('${row.id}: missing (${row.name})');
      }
    }
    return out;
  }

  /// Throws a [DesignInventoryError] naming every [problems] line; a look's
  /// test calls it.
  void verify() {
    final found = problems;
    if (found.isNotEmpty) throw DesignInventoryError(look, found);
  }
}

/// Builds a group's heading in a [DesignInventoryGallery]: [present] of
/// [total] rows carried.
typedef DesignInventoryGroupBuilder = Widget Function(
  BuildContext context,
  String group,
  int present,
  int total,
);

/// Builds one row in a [DesignInventoryGallery]. [entry] is null when the
/// inventory does not answer the row; [specimen] is the entry's live
/// specimen, built, when it has one.
typedef DesignInventoryRowBuilder = Widget Function(
  BuildContext context,
  DesignInventoryRow row,
  DesignInventoryEntry? entry,
  Widget? specimen,
);

/// Lists an inventory, group by group in [DesignInventoryRow.groups]' order: each row's
/// live specimen, or `Deliberately absent: <reason>` for a gap, or
/// "Missing" for a row the inventory does not answer. Lazy: a row builds
/// when it scrolls in.
///
/// The look paints it through [groupBuilder] and [rowBuilder]; without
/// them each row is its name over its specimen or its reason, in the
/// ambient text style.
class DesignInventoryGallery extends StatelessWidget {
  /// A gallery of [inventory].
  const DesignInventoryGallery({
    super.key,
    required this.inventory,
    this.groupBuilder,
    this.rowBuilder,
    this.padding = const EdgeInsets.all(16),
    this.controller,
    this.behaviourOnly = false,
  });

  /// The inventory to list.
  final DesignInventory inventory;

  /// Draws a group's heading.
  final DesignInventoryGroupBuilder? groupBuilder;

  /// Draws a row.
  final DesignInventoryRowBuilder? rowBuilder;

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
    for (final group in DesignInventoryRow.groups) {
      final rows = DesignInventoryRow.all
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
          final rows = DesignInventoryRow.all.where((r) => r.group == item);
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
        final row = item as DesignInventoryRow;
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
                          ? DesignInventory.absentLabel(entry!.absentReason!)
                          : 'Missing: the inventory does not answer this row',
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
