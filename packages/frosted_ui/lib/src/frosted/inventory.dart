export 'package:ui_core/inventory.dart'
    show RawInventory, RawInventoryEntry, RawInventoryGallery, RawInventoryRow;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';

import 'chrome_metrics.dart';
import 'components/actions/actions.dart';
import 'components/avatar/avatar.dart';
import 'components/button/button.dart';
import 'components/calendar/calendar.dart';
import 'components/charts/plots.dart';
import 'components/choices/choices.dart';
import 'components/color_picker/color_picker.dart';
import 'components/combobox/combobox.dart';
import 'components/command/command.dart';
import 'components/controls/controls.dart';
import 'components/data/data.dart';
import 'components/dialog/dialog.dart';
import 'components/entry/entry.dart';
import 'components/forms/forms.dart';
import 'components/hold/hold.dart';
import 'components/icon-button/round_button.dart';
import 'components/image/image.dart';
import 'components/marks/marks.dart';
import 'components/menu/menu.dart';
import 'components/meters/meters.dart';
import 'components/move/move.dart';
import 'components/nav_bar.dart';
import 'components/pickers/pickers.dart';
import 'components/popover/popover.dart';
import 'components/progress/progress.dart';
import 'components/rail/rail.dart';
import 'components/raise/raise.dart';
import 'components/screen.dart';
import 'components/scroll/scroll.dart';
import 'components/sheet.dart';
import 'components/side_bar.dart';
import 'components/slider/range_slider.dart';
import 'components/slider/slider.dart';
import 'components/states.dart';
import 'components/structure/list_section.dart';
import 'components/structure/structure.dart';
import 'components/swipe/swipe.dart';
import 'components/tabs/tabs.dart';
import 'components/toast.dart';
import 'components/toggle/toggle.dart';
import 'components/top_bar.dart';
import 'glyphs.dart';
import 'theme.dart';

void _none() {}
void _drop<T>(T _) {}

/// Every row of the shared inventory (ui_core's
/// [RawInventoryRow.all]) as Frosted answers it: a live specimen of the
/// row's `Frosted<Stem>` class, or the reason it is deliberately absent.
/// The gallery lists it ([RawInventoryGallery]); a test holds it whole
/// (`frostedInventory.verify()`). The specimens read the theme, so
/// build them under a [FrostedHost].
final RawInventory frostedInventory = RawInventory(
  look: 'Frosted',
  entries: [
    // Actions
    RawInventoryEntry.present(
      'Button',
      (context) => const FrostedButton('Save', onPressed: _none),
    ),
    RawInventoryEntry.present(
      'IconButton',
      (context) => const FrostedIconButton(
        FrostedGlyphs.add,
        semanticLabel: 'Add',
        onPressed: _none,
      ),
    ),
    const RawInventoryEntry.absent(
      'FloatingActionButton',
      "Frosted's one act stands in the navigation bar's middle "
          '(FrostedNavAction) or at the page\'s foot, never floating over the '
          'content.',
    ),
    RawInventoryEntry.present(
      'ButtonGroup',
      (context) => const FrostedButtonGroup(
        items: [
          FrostedButtonGroupItem(label: 'Day', onPressed: _none),
          FrostedButtonGroupItem(label: 'Week', onPressed: _none),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'ToggleGroup',
      (context) => const FrostedToggleGroup<String>(
        segments: [
          FrostedButtonSegment('b', 'Bold'),
          FrostedButtonSegment('i', 'Italic'),
        ],
        selected: {'b'},
        multiSelectionEnabled: true,
        onSelectionChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'SplitButton',
      (context) => const FrostedSplitButton(
        label: 'Save',
        onPressed: _none,
        actions: [FrostedSplitAction(label: 'Save as…', onPressed: _none)],
      ),
    ),
    RawInventoryEntry.present(
      'Link',
      (context) => const FrostedLink('Terms', link: 'Terms', onPressed: _none),
    ),
    RawInventoryEntry.present('Kbd', (context) => const FrostedKbd('Esc')),
    // Inputs
    RawInventoryEntry.present(
      'TextField',
      (context) => const FrostedTextField(labelText: 'Name', onChanged: _drop),
    ),
    RawInventoryEntry.present(
      'TextArea',
      (context) => const FrostedTextArea(labelText: 'Notes', onChanged: _drop),
    ),
    RawInventoryEntry.present(
      'SearchField',
      (context) => const FrostedSearchField(hintText: 'Search'),
    ),
    RawInventoryEntry.present(
      'PasswordField',
      (context) => const FrostedPasswordField(labelText: 'Password'),
    ),
    RawInventoryEntry.present(
      'InputGroup',
      (context) => const FrostedInputGroup(
        labelText: 'Website',
        prefix: Text('https://'),
        suffix: Text('.com'),
      ),
    ),
    RawInventoryEntry.present(
      'InputOtp',
      (context) => const FrostedInputOtp(labelText: 'Code'),
    ),
    RawInventoryEntry.present(
      'NumberField',
      // A budget's stepper (its well an amount), at $250 so both rounds are
      // live.
      (context) => const FrostedNumberField(
        value: 250,
        onChanged: _drop,
        labelText: 'the budget',
        note: 'a month',
        money: true,
      ),
    ),
    RawInventoryEntry.present(
      'Select',
      // Alone, as a filter, a select keeps to its content; in a form's
      // column it takes the column.
      (context) => const Row(
        children: [
          FrostedSelect<String>(
            labelText: 'Size',
            value: 'm',
            options: [
              FrostedSelectOption('s', 'Small'),
              FrostedSelectOption('m', 'Medium'),
            ],
            onChanged: _drop,
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Combobox',
      (context) => const FrostedCombobox<String>(
        labelText: 'Country',
        options: ['Canada', 'Chile', 'Japan', 'Portugal'],
      ),
    ),
    RawInventoryEntry.present(
      'MultiSelect',
      (context) => const FrostedMultiSelect<String>(
        labelText: 'Tags',
        values: ['travel'],
        options: ['food', 'travel', 'work'],
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Checkbox',
      (context) => const FrostedCheckbox(
        value: true,
        semanticLabel: 'Agree',
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'RadioGroup',
      (context) => const FrostedRadioGroup<String>(
        labelText: 'Plan',
        value: 'a',
        options: [FrostedRadio('a', 'Monthly'), FrostedRadio('b', 'Yearly')],
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Switch',
      (context) => const FrostedSwitch(
        value: true,
        onChanged: _drop,
        semanticLabel: 'Wi-Fi',
      ),
    ),
    RawInventoryEntry.present(
      'Slider',
      (context) => const FrostedSlider(
        value: .4,
        onChanged: _drop,
        semanticLabel: 'Volume',
      ),
    ),
    RawInventoryEntry.present(
      'RangeSlider',
      (context) => const FrostedRangeSlider(
        values: RawRangeValues(.2, .7),
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'SegmentedButton',
      (context) => const FrostedSegmentedButton<String>(
        segments: [
          FrostedButtonSegment('d', 'Day'),
          FrostedButtonSegment('w', 'Week'),
        ],
        value: 'd',
        onChanged: _drop,
        label: 'Range',
      ),
    ),
    RawInventoryEntry.present(
      'Chip',
      (context) => const FrostedChip('Vegetarian', onPressed: _none),
    ),
    RawInventoryEntry.present(
      'Rating',
      (context) => const FrostedRating(value: 4, semanticLabel: 'Your rating'),
    ),
    RawInventoryEntry.present(
      'FileUpload',
      (context) =>
          const FrostedFileUpload(labelText: 'Attachments', onPressed: _none),
    ),
    RawInventoryEntry.present(
      'DatePicker',
      (context) => FrostedDatePicker(currentDate: DateTime(2026, 11, 10)),
    ),
    RawInventoryEntry.present(
      'DateRangePicker',
      (context) => FrostedDateRangePicker(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        currentDate: DateTime(2026, 11, 10),
      ),
    ),
    RawInventoryEntry.present(
      'TimePicker',
      (context) => const FrostedTimePicker(
        value: FrostedTime(hour: 9, minute: 30),
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Calendar',
      (context) => FrostedCalendar(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        currentDate: DateTime(2026, 11, 10),
      ),
    ),
    RawInventoryEntry.present(
      'WheelPicker',
      (context) => const FrostedWheelPicker<int>(
        options: [FrostedSelectOption(1, 'One'), FrostedSelectOption(2, 'Two')],
        value: 1,
        semanticLabel: 'Count',
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'ColorPicker',
      (context) =>
          const FrostedColorPicker(value: Color(0xFF0A7CFF), onChanged: _drop),
    ),
    RawInventoryEntry.present(
      'FormField',
      (context) => const FrostedFormField(
        labelText: 'Notify me',
        helperText: 'Pick at least one',
        // A chip is a control of its own, not the field's one value.
        mergeSemantics: false,
        child: FrostedChip('Email', onPressed: _none),
      ),
    ),
    // Navigation
    RawInventoryEntry.present(
      'AppBar',
      (context) => const FrostedAppBar(title: 'Settings'),
    ),
    RawInventoryEntry.present(
      'NavigationBar',
      (context) => const FrostedNavigationBar(
        items: [
          FrostedNavItem(FrostedGlyphs.house, 'Home'),
          FrostedNavItem(FrostedGlyphs.person, 'You'),
        ],
        selectedIndex: 0,
        onDestinationSelected: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'NavigationRail',
      (context) => const FrostedNavigationRail(
        items: [
          FrostedNavItem(FrostedGlyphs.house, 'Home'),
          FrostedNavItem(FrostedGlyphs.person, 'You'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'NavigationDrawer',
      (context) => const FrostedNavigationDrawer(
        items: [
          FrostedNavItem(FrostedGlyphs.house, 'Home'),
          FrostedNavItem(FrostedGlyphs.person, 'You'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'TabBar',
      (context) => const FrostedTabBar(tabs: ['Overview', 'Activity']),
    ),
    RawInventoryEntry.present(
      'Breadcrumb',
      (context) => const FrostedBreadcrumb(
        items: [
          FrostedBreadcrumbItem('Home', onPressed: _none),
          FrostedBreadcrumbItem('Settings'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Pagination',
      (context) => const FrostedPagination(
        pageCount: 5,
        selectedIndex: 1,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'StepProgress',
      (context) =>
          const FrostedStepProgress(count: 4, currentStep: 1, name: 'Details'),
    ),
    RawInventoryEntry.present(
      'PageDots',
      (context) => const FrostedPageDots(
        pageCount: 4,
        selectedIndex: 0,
        semanticLabel: 'Page',
      ),
    ),
    RawInventoryEntry.present(
      'MenuBar',
      (context) => const FrostedMenuBar(
        menus: [
          RawMenuEntry(
            label: 'File',
            children: [RawMenuEntry(label: 'New', onPressed: _none)],
          ),
          RawMenuEntry(
            label: 'Edit',
            children: [RawMenuEntry(label: 'Copy', onPressed: _none)],
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Command',
      (context) => const FrostedCommand(
        width: 340,
        commands: [
          RawCommand(label: 'New payment', group: 'Money'),
          RawCommand(label: 'Settings'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Scaffold',
      (context) => const FrostedScaffold(body: Text('Page')),
    ),
    // Containers
    RawInventoryEntry.present(
      'Card',
      (context) => const FrostedCard(child: Text('Card')),
    ),
    RawInventoryEntry.present(
      'ListTile',
      (context) => const FrostedListTile(title: 'Wi-Fi', meta: 'Home'),
    ),
    RawInventoryEntry.present(
      'ListSection',
      (context) => const FrostedListSection(
        title: 'Account',
        rows: [FrostedListTile(title: 'Profile')],
      ),
    ),
    RawInventoryEntry.present(
      'SectionHeader',
      (context) => const FrostedSectionHeader('Recent'),
    ),
    RawInventoryEntry.present(
      'Disclosure',
      (context) => const FrostedDisclosure(
        title: 'Details',
        child: Text('More about it'),
      ),
    ),
    RawInventoryEntry.present(
      'Table',
      (context) => const FrostedTable(
        columns: [FrostedTableColumn('Item'), FrostedTableColumn('Qty')],
        rows: [
          ['Notebook', '2'],
        ],
      ),
    ),
    RawInventoryEntry.present(
      'DataTable',
      (context) => _Owned(
        create: () => RawDataTableController<(String, int)>(
          rows: const [('Notebook', 2), ('Pens', 10)],
          columns: [
            RawDataColumn(id: 'item', label: 'Item', sortKey: (r) => r.$1),
            RawDataColumn(
              id: 'qty',
              label: 'Qty',
              numeric: true,
              sortKey: (r) => r.$2,
            ),
          ],
        ),
        builder: (context, table) => FrostedDataTable<(String, int)>(
          controller: table,
          cellBuilder: (context, row, column) =>
              Text(column.id == 'item' ? row.$1 : '${row.$2}'),
        ),
      ),
    ),
    RawInventoryEntry.present('Divider', (context) => const FrostedDivider()),
    RawInventoryEntry.present(
      'ScrollArea',
      (context) => _Owned(
        create: ScrollController.new,
        builder: (context, scroll) => FrostedScrollArea(
          controller: scroll,
          child: SizedBox(
            height: 120,
            child: ListView(
              controller: scroll,
              children: [for (var i = 1; i <= 12; i++) Text('Row $i')],
            ),
          ),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Resizable',
      (context) => const FrostedResizable(
        first: Center(child: Text('List')),
        second: Center(child: Text('Detail')),
      ),
    ),
    RawInventoryEntry.present(
      'CarouselView',
      (context) => FrostedCarouselView(
        height: 120,
        children: [
          for (final hue in [0, 1, 2])
            ColoredBox(color: context.frostedTheme.hue(hue).tint),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'ReorderableListView',
      (context) => FrostedReorderableListView<String>(
        items: const ['Wake', 'Run', 'Read'],
        labelOf: (s) => s,
        shrinkWrap: true,
        onReorder: (from, to) {},
        itemBuilder: (context, s) => Text(s),
      ),
    ),
    RawInventoryEntry.present(
      'SwipeActions',
      (context) => const FrostedSwipeActions(
        trailing: [
          FrostedSwipeAction(
            label: 'Delete',
            icon: FrostedGlyphs.delete,
            tone: FrostedSwipeTone.destructive,
            onPressed: _none,
          ),
        ],
        child: FrostedListTile(title: 'Swipe me'),
      ),
    ),
    RawInventoryEntry.present(
      'RefreshIndicator',
      (context) => FrostedRefreshIndicator(
        onRefresh: () async {},
        child: SizedBox(
          height: 120,
          child: ListView(children: const [Text('Pull down')]),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'TreeView',
      (context) => _Owned(
        create: () => RawTreeController<String>(
          roots: const ['Documents', 'Photos'],
          childrenOf: (n) => n == 'Documents' ? const ['Taxes'] : const [],
          expanded: const ['Documents'],
        ),
        builder: (context, tree) =>
            FrostedTreeView<String>(controller: tree, labelOf: (n) => n),
      ),
    ),
    RawInventoryEntry.present(
      'Timeline',
      (context) => const FrostedTimeline(
        entries: [
          FrostedTimelineEntry(title: 'Ordered'),
          FrostedTimelineEntry(title: 'Shipped', current: true),
        ],
      ),
    ),
    RawInventoryEntry.present('Avatar', (context) => const FrostedAvatar('MC')),
    RawInventoryEntry.present(
      'AvatarGroup',
      (context) => const FrostedAvatarGroup(['Maya Chen', 'Leo Park']),
    ),
    RawInventoryEntry.present('Badge', (context) => const FrostedBadge(3)),
    RawInventoryEntry.present('Tag', (context) => const FrostedTag('New')),
    RawInventoryEntry.present(
      'Media',
      (context) => const FrostedMedia(seed: 'Lisbon in May', aspect: 16 / 9),
    ),
    RawInventoryEntry.present(
      'EmptyState',
      (context) => const FrostedEmptyState(title: 'Nothing here yet'),
    ),
    RawInventoryEntry.present(
      'DescriptionList',
      (context) => const FrostedDescriptionList(
        children: [FrostedKeyValue(label: 'Plan', value: 'Yearly')],
      ),
    ),
    // Overlays
    RawInventoryEntry.present(
      'Dialog',
      (context) =>
          const FrostedDialog(title: 'Leave this page?', onConfirm: _none),
    ),
    RawInventoryEntry.present(
      'BottomSheet',
      (context) => const FrostedBottomSheet(child: Text('Sheet')),
    ),
    RawInventoryEntry.present(
      'Sheet',
      (context) =>
          const FrostedSheet(title: 'Filters', children: [Text('Options')]),
    ),
    RawInventoryEntry.present(
      'ActionSheet',
      (context) => const FrostedActionSheet<String>(
        actions: [FrostedActionSheetAction('Share', value: 'share')],
      ),
    ),
    RawInventoryEntry.present(
      'Popover',
      (context) => FrostedPopover(
        builder: (context, controller, _) => FrostedButton.glass(
          'Filter',
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
        content: const Text('Only unread'),
      ),
    ),
    RawInventoryEntry.present(
      'HoverCard',
      (context) => const FrostedHoverCard(
        content: Text('Maya Chen · Design lead'),
        child: Text('@maya'),
      ),
    ),
    RawInventoryEntry.present(
      'Tooltip',
      (context) => const FrostedTooltip(message: 'Copy', child: Text('Copy')),
    ),
    RawInventoryEntry.present(
      'Menu',
      (context) => const FrostedMenu<String>(
        items: [
          FrostedMenuItem('rename', 'Rename'),
          FrostedMenuItem('delete', 'Delete'),
        ],
        onSelected: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'SnackBar',
      (context) => const FrostedSnackBar('Saved'),
    ),
    RawInventoryEntry.present(
      'Banner',
      (context) => const FrostedBanner(
        icon: FrostedGlyphs.info,
        title: 'Card frozen',
        body: 'Payments stop until you unfreeze it.',
      ),
    ),
    // Feedback
    RawInventoryEntry.present(
      'LinearProgressIndicator',
      (context) =>
          const FrostedLinearProgressIndicator(value: .4, label: 'Upload'),
    ),
    RawInventoryEntry.present(
      'CircularProgressIndicator',
      (context) => const FrostedCircularProgressIndicator(),
    ),
    RawInventoryEntry.present(
      'Skeleton',
      (context) => const FrostedSkeleton(width: 120, height: 16),
    ),
    RawInventoryEntry.present(
      'StatusView',
      (context) => const FrostedStatusView.loading(),
    ),
    RawInventoryEntry.present(
      'Meter',
      (context) => FrostedMeter(.6, hue: context.frostedTheme.hue(0)),
    ),
    // Charts
    RawInventoryEntry.present(
      'LineChart',
      (context) => const FrostedLineChart(
        label: 'Spending',
        series: [
          FrostedChartSeries('This month', [3, 5, 4, 6]),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'BarChart',
      (context) => const FrostedBarChart(
        label: 'Spending',
        series: [
          FrostedChartSeries('This month', [3, 5, 4, 6]),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'AreaChart',
      (context) => const FrostedAreaChart(
        label: 'Spending',
        series: [
          FrostedChartSeries('This month', [3, 5, 4, 6]),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'PieChart',
      (context) => const FrostedPieChart(
        label: 'Budget',
        slices: [FrostedPieSlice('Rent', 40), FrostedPieSlice('Food', 25)],
      ),
    ),
    RawInventoryEntry.present(
      'Sparkline',
      (context) => const FrostedSparkline([3, 5, 4, 6], label: 'Trend'),
    ),
  ],
);

/// Frosted's inventory, listed: each group under its heading with how many
/// of its rows Frosted carries, then each row in a [FrostedCard], its class
/// over its live specimen, or what a person calls the row over the reason
/// Frosted leaves it out. It scrolls itself, so it fills a screen that does
/// not scroll (`FrostedScaffold(scroll: false)`).
///
/// ```dart
/// FrostedScaffold(scroll: false, topBar: const FrostedAppBar(title: 'Inventory'), body: const FrostedInventoryGallery())
/// ```
class FrostedInventoryGallery extends StatelessWidget {
  /// Lists [frostedInventory].
  const FrostedInventoryGallery({
    super.key,
    this.controller,
    this.padding = const EdgeInsets.only(
      top: FrostedSpacing.s8,
      bottom: FrostedSpacing.s32,
    ),
  });

  /// The list's scroll controller.
  final ScrollController? controller;

  /// Space round the list; none at the sides by default, where the
  /// scaffold's gutter stands (with its own 16 as well, the list would stand
  /// at twice the gutter of every other page).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return RawInventoryGallery(
      inventory: frostedInventory,
      controller: controller,
      padding: padding,
      groupBuilder: (context, group, live, total) => Padding(
        padding: const EdgeInsets.only(
          top: FrostedSpacing.s24,
          bottom: FrostedSpacing.s12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                group,
                style: t.textTheme.titleSmall.c(t.colorScheme.textPrimary),
              ),
            ),
            Text('$live of $total', style: t.textTheme.labelMedium),
          ],
        ),
      ),
      rowBuilder: (context, row, entry, specimen) => KeyedSubtree(
        key: ValueKey('inventory-${row.id}'),
        child: Padding(
          padding: const EdgeInsets.only(bottom: FrostedSpacing.s16),
          child: FrostedCard(
            padding: const EdgeInsets.all(FrostedSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FrostedSpacing.s12,
              children: [
                Text(
                  entry?.isPresent ?? false ? 'Frosted${row.id}' : row.name,
                  style: t.textTheme.labelLarge.semibold.c(
                    t.colorScheme.textPrimary,
                  ),
                ),
                if (specimen != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 480),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      heightFactor: 1,
                      child: row.id == 'NavigationBar'
                          ? _CanvasStage(child: specimen)
                          : specimen,
                    ),
                  )
                else
                  Text(
                    entry?.absentReason ?? 'Not answered',
                    style: t.textTheme.titleMedium.c(
                      t.colorScheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
          defaultValue: const EdgeInsets.only(
            top: FrostedSpacing.s8,
            bottom: FrostedSpacing.s32,
          ),
        ),
      );
  }
}

// The navigation bar stands at a screen's foot on its fade into the canvas:
// on the card it stands on a stage of the canvas the fade's height, so the
// fade meets the canvas as at a screen's foot rather than drawing a box on
// the card.
class _CanvasStage extends StatelessWidget {
  const _CanvasStage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(
      FrostedBreakpoints.innerRadius(context),
    ),
    child: ColoredBox(
      color: context.frostedTheme.colorScheme.background,
      child: Padding(
        padding: const EdgeInsets.only(
          top:
              FrostedChromeMetrics.tabBarFade -
              FrostedChromeMetrics.slabHeight -
              FrostedChromeMetrics.tabBarBottom,
        ),
        child: child,
      ),
    ),
  );
}

// A specimen's controller, made once and disposed of with the specimen, as
// an app's State would hold it.
class _Owned<T extends ChangeNotifier> extends StatefulWidget {
  const _Owned({required this.create, required this.builder});

  final T Function() create;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<_Owned<T>> createState() => _OwnedState<T>();
}

class _OwnedState<T extends ChangeNotifier> extends State<_Owned<T>> {
  late final T _value = widget.create();

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
