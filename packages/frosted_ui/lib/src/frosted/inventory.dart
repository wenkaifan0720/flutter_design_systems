export 'package:ui_core/inventory.dart'
    show
        DesignInventory,
        DesignInventoryEntry,
        DesignInventoryGallery,
        DesignInventoryRow;

import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';

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

/// Every row of the shared inventory (INVENTORY.md, ui_core's
/// [DesignInventoryRow.all]) as Frosted answers it: a live specimen of the
/// row's `Frosted<Stem>` class, or the reason it is deliberately absent.
/// The gallery lists it ([DesignInventoryGallery]); a test holds it whole
/// (`frostedInventory.verify()`). The specimens read the theme, so
/// build them under a [FrostedHost].
final DesignInventory frostedInventory = DesignInventory(
  look: 'Frosted',
  entries: [
    // Actions
    DesignInventoryEntry.present(
      'Button',
      (context) => FrostedButton('Save', onPressed: _none),
    ),
    DesignInventoryEntry.present(
      'IconButton',
      (context) =>
          FrostedIconButton(FrostedGlyphs.add, label: 'Add', onPressed: _none),
    ),
    const DesignInventoryEntry.absent(
      'FloatingActionButton',
      "Frosted's one act stands in the navigation bar's middle "
          '(FrostedNavAction) or at the page\'s foot, never floating over the '
          'content.',
    ),
    DesignInventoryEntry.present(
      'ButtonGroup',
      (context) => const FrostedButtonGroup(
        items: [
          FrostedButtonGroupItem(label: 'Day', onPressed: _none),
          FrostedButtonGroupItem(label: 'Week', onPressed: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'ToggleGroup',
      (context) => FrostedToggleGroup<String>(
        segments: const [
          FrostedButtonSegment('b', 'Bold'),
          FrostedButtonSegment('i', 'Italic'),
        ],
        selected: const {'b'},
        multiple: true,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'SplitButton',
      (context) => FrostedSplitButton(
        label: 'Save',
        onPressed: _none,
        actions: const [
          FrostedSplitAction(label: 'Save as…', onPressed: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Link',
      (context) => const FrostedLink('Terms', link: 'Terms', onPressed: _none),
    ),
    DesignInventoryEntry.present('Kbd', (context) => FrostedKbd('Esc')),
    // Inputs
    DesignInventoryEntry.present(
      'TextField',
      (context) => const FrostedTextField(label: 'Name', onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'TextArea',
      (context) => const FrostedTextArea(label: 'Notes', onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'SearchField',
      (context) => const FrostedSearchField(hint: 'Search'),
    ),
    DesignInventoryEntry.present(
      'PasswordField',
      (context) => const FrostedPasswordField(label: 'Password'),
    ),
    DesignInventoryEntry.present(
      'InputGroup',
      (context) => const FrostedInputGroup(
        label: 'Website',
        prefix: Text('https://'),
        suffix: Text('.com'),
      ),
    ),
    DesignInventoryEntry.present(
      'InputOtp',
      (context) => const FrostedInputOtp(label: 'Code'),
    ),
    DesignInventoryEntry.present(
      'NumberField',
      // A budget's stepper (its well an amount), at $250 so both rounds are
      // live.
      (context) => const FrostedNumberField(
        value: 250,
        onChanged: _drop,
        label: 'the budget',
        note: 'a month',
      ),
    ),
    DesignInventoryEntry.present(
      'Select',
      (context) => const FrostedSelect<String>(
        label: 'Size',
        value: 'm',
        options: [
          FrostedSelectOption('s', 'Small'),
          FrostedSelectOption('m', 'Medium'),
        ],
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Combobox',
      (context) => const FrostedCombobox<String>(
        label: 'Country',
        options: ['Canada', 'Chile', 'Japan', 'Portugal'],
      ),
    ),
    DesignInventoryEntry.present(
      'MultiSelect',
      (context) => const FrostedMultiSelect<String>(
        label: 'Tags',
        values: ['travel'],
        options: ['food', 'travel', 'work'],
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Checkbox',
      (context) =>
          const FrostedCheckbox(value: true, label: 'Agree', onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'RadioGroup',
      (context) => const FrostedRadioGroup<String>(
        label: 'Plan',
        value: 'a',
        options: [FrostedRadio('a', 'Monthly'), FrostedRadio('b', 'Yearly')],
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Switch',
      (context) =>
          const FrostedSwitch(value: true, onChanged: _drop, label: 'Wi-Fi'),
    ),
    DesignInventoryEntry.present(
      'Slider',
      (context) =>
          const FrostedSlider(value: .4, onChanged: _drop, label: 'Volume'),
    ),
    DesignInventoryEntry.present(
      'RangeSlider',
      (context) => const FrostedRangeSlider(
        values: DesignRangeValues(.2, .7),
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'Chip',
      (context) => const FrostedChip('Vegetarian', onPressed: _none),
    ),
    DesignInventoryEntry.present(
      'Rating',
      (context) => const FrostedRating(value: 4, label: 'Your rating'),
    ),
    DesignInventoryEntry.present(
      'FileUpload',
      (context) =>
          const FrostedFileUpload(label: 'Attachments', onPressed: _none),
    ),
    DesignInventoryEntry.present(
      'DatePicker',
      (context) => FrostedDatePicker(currentDate: DateTime(2026, 11, 10)),
    ),
    DesignInventoryEntry.present(
      'DateRangePicker',
      (context) => FrostedDateRangePicker(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        currentDate: DateTime(2026, 11, 10),
      ),
    ),
    DesignInventoryEntry.present(
      'TimePicker',
      (context) => const FrostedTimePicker(
        value: FrostedTime(hour: 9, minute: 30),
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Calendar',
      (context) => FrostedCalendar(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        currentDate: DateTime(2026, 11, 10),
      ),
    ),
    DesignInventoryEntry.present(
      'WheelPicker',
      (context) => const FrostedWheelPicker<int>(
        options: [FrostedSelectOption(1, 'One'), FrostedSelectOption(2, 'Two')],
        value: 1,
        label: 'Count',
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'ColorPicker',
      (context) =>
          const FrostedColorPicker(value: Color(0xFF0A7CFF), onChanged: _drop),
    ),
    DesignInventoryEntry.present(
      'FormField',
      (context) => const FrostedFormField(
        label: 'Notify me',
        helper: 'Pick at least one',
        // A chip is a control of its own, not the field's one value.
        mergeSemantics: false,
        child: FrostedChip('Email', onPressed: _none),
      ),
    ),
    // Navigation
    DesignInventoryEntry.present(
      'AppBar',
      (context) => const FrostedAppBar(title: 'Settings'),
    ),
    DesignInventoryEntry.present(
      'NavigationBar',
      (context) => FrostedNavigationBar(
        items: const [
          FrostedNavItem(FrostedGlyphs.house, 'Home'),
          FrostedNavItem(FrostedGlyphs.person, 'You'),
        ],
        selectedIndex: 0,
        onDestinationSelected: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationRail',
      (context) => const FrostedNavigationRail(
        items: [
          FrostedNavItem(FrostedGlyphs.house, 'Home'),
          FrostedNavItem(FrostedGlyphs.person, 'You'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationDrawer',
      (context) => const FrostedNavigationDrawer(
        items: [
          FrostedNavItem(FrostedGlyphs.house, 'Home'),
          FrostedNavItem(FrostedGlyphs.person, 'You'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'TabBar',
      (context) => const FrostedTabBar(tabs: ['Overview', 'Activity']),
    ),
    DesignInventoryEntry.present(
      'Breadcrumb',
      (context) => const FrostedBreadcrumb(
        items: [
          FrostedBreadcrumbItem('Home', onPressed: _none),
          FrostedBreadcrumbItem('Settings'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Pagination',
      (context) => const FrostedPagination(
        pageCount: 5,
        selectedIndex: 1,
        onChanged: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'StepProgress',
      (context) =>
          const FrostedStepProgress(count: 4, currentStep: 1, name: 'Details'),
    ),
    DesignInventoryEntry.present(
      'PageDots',
      (context) =>
          const FrostedPageDots(count: 4, selectedIndex: 0, label: 'Page'),
    ),
    DesignInventoryEntry.present(
      'MenuBar',
      (context) => const FrostedMenuBar(
        menus: [
          DesignMenuEntry(
            label: 'File',
            children: [DesignMenuEntry(label: 'New', onPressed: _none)],
          ),
          DesignMenuEntry(
            label: 'Edit',
            children: [DesignMenuEntry(label: 'Copy', onPressed: _none)],
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Command',
      (context) => const FrostedCommand(
        width: 340,
        commands: [
          DesignCommand(label: 'New payment', group: 'Money'),
          DesignCommand(label: 'Settings'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Scaffold',
      (context) => const FrostedScaffold(body: Text('Page')),
    ),
    // Containers
    DesignInventoryEntry.present(
      'Card',
      (context) => const FrostedCard(child: Text('Card')),
    ),
    DesignInventoryEntry.present(
      'ListTile',
      (context) => const FrostedListTile(title: 'Wi-Fi', meta: 'Home'),
    ),
    DesignInventoryEntry.present(
      'ListSection',
      (context) => const FrostedListSection(
        title: 'Account',
        rows: [FrostedListTile(title: 'Profile')],
      ),
    ),
    DesignInventoryEntry.present(
      'SectionHeader',
      (context) => const FrostedSectionHeader('Recent'),
    ),
    DesignInventoryEntry.present(
      'Disclosure',
      (context) => const FrostedDisclosure(
        title: 'Details',
        child: Text('More about it'),
      ),
    ),
    DesignInventoryEntry.present(
      'Table',
      (context) => const FrostedTable(
        columns: [FrostedTableColumn('Item'), FrostedTableColumn('Qty')],
        rows: [
          ['Notebook', '2'],
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'DataTable',
      (context) => FrostedDataTable<(String, int)>(
        controller: DesignTableController<(String, int)>(
          rows: const [('Notebook', 2), ('Pens', 10)],
          columns: [
            DesignTableColumn(id: 'item', label: 'Item', sortKey: (r) => r.$1),
            DesignTableColumn(
              id: 'qty',
              label: 'Qty',
              numeric: true,
              sortKey: (r) => r.$2,
            ),
          ],
        ),
        cellBuilder: (context, row, column) =>
            Text(column.id == 'item' ? row.$1 : '${row.$2}'),
      ),
    ),
    DesignInventoryEntry.present(
      'Divider',
      (context) => const FrostedDivider(),
    ),
    DesignInventoryEntry.present('ScrollArea', (context) {
      final scroll = ScrollController();
      return FrostedScrollArea(
        controller: scroll,
        child: SizedBox(
          height: 120,
          child: ListView(
            controller: scroll,
            children: [for (var i = 1; i <= 12; i++) Text('Row $i')],
          ),
        ),
      );
    }),
    DesignInventoryEntry.present(
      'Resizable',
      (context) => const FrostedResizable(
        first: Center(child: Text('List')),
        second: Center(child: Text('Detail')),
      ),
    ),
    DesignInventoryEntry.present(
      'CarouselView',
      (context) => FrostedCarouselView(
        height: 120,
        children: [
          for (final hue in [0, 1, 2])
            ColoredBox(color: context.frostedTheme.hue(hue).tint),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'ReorderableListView',
      (context) => FrostedReorderableListView<String>(
        items: const ['Wake', 'Run', 'Read'],
        labelOf: (s) => s,
        shrinkWrap: true,
        onReorder: (from, to) {},
        itemBuilder: (context, s) => Text(s),
      ),
    ),
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'RefreshIndicator',
      (context) => FrostedRefreshIndicator(
        onRefresh: () async {},
        child: SizedBox(
          height: 120,
          child: ListView(children: const [Text('Pull down')]),
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'TreeView',
      (context) => FrostedTreeView<String>(
        controller: DesignTreeController<String>(
          roots: const ['Documents', 'Photos'],
          childrenOf: (n) => n == 'Documents' ? const ['Taxes'] : const [],
          expanded: const ['Documents'],
        ),
        labelOf: (n) => n,
      ),
    ),
    DesignInventoryEntry.present(
      'Timeline',
      (context) => const FrostedTimeline(
        entries: [
          FrostedTimelineEntry(title: 'Ordered'),
          FrostedTimelineEntry(title: 'Shipped', current: true),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Avatar',
      (context) => const FrostedAvatar('MC'),
    ),
    DesignInventoryEntry.present(
      'AvatarGroup',
      (context) => const FrostedAvatarGroup(['Maya Chen', 'Leo Park']),
    ),
    DesignInventoryEntry.present('Badge', (context) => const FrostedBadge(3)),
    DesignInventoryEntry.present('Tag', (context) => const FrostedTag('New')),
    DesignInventoryEntry.present(
      'Media',
      (context) => const FrostedMedia(seed: 'Lisbon in May', aspect: 16 / 9),
    ),
    DesignInventoryEntry.present(
      'EmptyState',
      (context) => const FrostedEmptyState(title: 'Nothing here yet'),
    ),
    DesignInventoryEntry.present(
      'DescriptionList',
      (context) => const FrostedDescriptionList(
        children: [FrostedKeyValue(label: 'Plan', value: 'Yearly')],
      ),
    ),
    // Overlays
    DesignInventoryEntry.present(
      'Dialog',
      (context) =>
          const FrostedDialog(title: 'Leave this page?', onConfirm: _none),
    ),
    DesignInventoryEntry.present(
      'BottomSheet',
      (context) => const FrostedBottomSheet(child: Text('Sheet')),
    ),
    DesignInventoryEntry.present(
      'Sheet',
      (context) =>
          const FrostedSheet(title: 'Filters', children: [Text('Options')]),
    ),
    DesignInventoryEntry.present(
      'ActionSheet',
      (context) => const FrostedActionSheet<String>(
        actions: [FrostedActionSheetAction('Share', value: 'share')],
      ),
    ),
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'HoverCard',
      (context) => const FrostedHoverCard(
        content: Text('Maya Chen · Design lead'),
        child: Text('@maya'),
      ),
    ),
    DesignInventoryEntry.present(
      'Tooltip',
      (context) => const FrostedTooltip(message: 'Copy', child: Text('Copy')),
    ),
    DesignInventoryEntry.present(
      'Menu',
      (context) => FrostedMenu<String>(
        items: const [
          FrostedMenuItem('rename', 'Rename'),
          FrostedMenuItem('delete', 'Delete'),
        ],
        onSelected: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'SnackBar',
      (context) => const FrostedSnackBar('Saved'),
    ),
    DesignInventoryEntry.present(
      'Banner',
      (context) => const FrostedBanner(
        icon: FrostedGlyphs.info,
        title: 'Card frozen',
        body: 'Payments stop until you unfreeze it.',
      ),
    ),
    // Feedback
    DesignInventoryEntry.present(
      'LinearProgressIndicator',
      (context) =>
          const FrostedLinearProgressIndicator(value: .4, label: 'Upload'),
    ),
    DesignInventoryEntry.present(
      'CircularProgressIndicator',
      (context) => const FrostedCircularProgressIndicator(),
    ),
    DesignInventoryEntry.present(
      'Skeleton',
      (context) => const FrostedSkeleton(width: 120, height: 16),
    ),
    DesignInventoryEntry.present(
      'StatusView',
      (context) => const FrostedStatusView.loading(),
    ),
    DesignInventoryEntry.present(
      'Meter',
      (context) => FrostedMeter(.6, hue: context.frostedTheme.hue(0)),
    ),
    // Charts
    DesignInventoryEntry.present(
      'LineChart',
      (context) => const FrostedLineChart(
        label: 'Spending',
        series: [
          FrostedChartSeries('This month', [3, 5, 4, 6]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'BarChart',
      (context) => const FrostedBarChart(
        label: 'Spending',
        series: [
          FrostedChartSeries('This month', [3, 5, 4, 6]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'AreaChart',
      (context) => const FrostedAreaChart(
        label: 'Spending',
        series: [
          FrostedChartSeries('This month', [3, 5, 4, 6]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'PieChart',
      (context) => const FrostedPieChart(
        label: 'Budget',
        slices: [FrostedPieSlice('Rent', 40), FrostedPieSlice('Food', 25)],
      ),
    ),
    DesignInventoryEntry.present(
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
  /// scaffold's gutter stands (with its own 16 as well, the list stood at
  /// twice the gutter of every other page, self-review round 3).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return DesignInventoryGallery(
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
                      child: specimen,
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
}
