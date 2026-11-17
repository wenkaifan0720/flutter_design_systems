/// Ledger's answer to ui_core's shared inventory: for each component every
/// look names alike, the Ledger part that is it (a specimen of it, built
/// live) or why a ledger has none.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/inventory.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'components/action-sheet/action_sheet.dart';
import 'components/avatar-stack/avatar_stack.dart';
import 'components/avatar/avatar.dart';
import 'components/badge/badge.dart';
import 'components/banner/banner.dart';
import 'components/breadcrumb/breadcrumb.dart';
import 'components/button/button.dart';
import 'components/carousel/carousel.dart';
import 'components/charts/charts.dart';
import 'components/checkbox/checkbox.dart';
import 'components/chip/chip.dart';
import 'components/choices/choices.dart';
import 'components/code-field/code_field.dart';
import 'components/combobox/combobox.dart';
import 'components/command/command.dart';
import 'components/data-table/data_table.dart';
import 'components/date-picker/date_picker.dart';
import 'components/date-range-picker/date_range_picker.dart';
import 'components/dialog/dialog.dart';
import 'components/disclosure/disclosure.dart';
import 'components/divider/divider.dart';
import 'components/file-upload/file_upload.dart';
import 'components/gauge/gauge.dart';
import 'components/icon-button/icon_button.dart';
import 'components/input-group/input_group.dart';
import 'components/inputs/inputs.dart';
import 'components/kbd/kbd.dart';
import 'components/marks/marks.dart';
import 'components/media/media.dart';
import 'components/money/money.dart';
import 'components/multi-select/multi_select.dart';
import 'components/nav_bar.dart';
import 'components/navigation_frame.dart';
import 'components/page-dots/page_dots.dart';
import 'components/pagination/pagination.dart';
import 'components/password-field/password_field.dart';
import 'components/pie/pie.dart';
import 'components/popover/popover.dart';
import 'components/progress/progress.dart';
import 'components/pull-to-refresh/pull_to_refresh.dart';
import 'components/range-slider/range_slider.dart';
import 'components/receipt/receipt.dart';
import 'components/register/register.dart';
import 'components/reorderable-list/reorderable_list.dart';
import 'components/scroll-area/scroll_area.dart';
import 'components/select/select.dart';
import 'components/sheet.dart';
import 'components/side-sheet/side_sheet.dart';
import 'components/side_bar.dart';
import 'components/slider/slider.dart';
import 'components/split-button/split_button.dart';
import 'components/states.dart';
import 'components/step-progress/step_progress.dart';
import 'components/structure/structure.dart';
import 'components/swipe_actions/swipe_actions.dart';
import 'components/tabs/tabs.dart';
import 'components/text-area/text_area.dart';
import 'components/text-field/text_field.dart';
import 'components/timeline/timeline.dart';
import 'components/toast.dart';
import 'components/toggle-group/toggle_group.dart';
import 'components/tooltip/tooltip.dart';
import 'components/top_bar.dart';
import 'format.dart';
import 'theme.dart';

export 'package:ui_core/inventory.dart'
    show
        DesignInventory,
        DesignInventoryEntry,
        DesignInventoryError,
        DesignInventoryGallery,
        DesignInventoryRow;

void _none() {}

/// A value a specimen keeps, so the control answers a tap as it would on a
/// page.
class _Held<T> extends StatefulWidget {
  const _Held(this.initial, this.builder);

  final T initial;
  final Widget Function(BuildContext context, T value, ValueChanged<T> set)
  builder;

  @override
  State<_Held<T>> createState() => _HeldState<T>();
}

class _HeldState<T> extends State<_Held<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _value, (v) => setState(() => _value = v));
}

/// The day the specimens are dated: a Wednesday in October, as the
/// gallery's books are.
final DateTime _day = DateTime(2026, 10, 28);

const List<String> _payees = [
  'Blue Fern Café',
  'Corner Market',
  'City Water',
  'Northside Rent',
];

const List<LedgerNavItem> _tabs = [
  LedgerNavItem(LucideIcons.house, 'Home'),
  LedgerNavItem(LucideIcons.bookOpen, 'Register'),
  LedgerNavItem(LucideIcons.chartColumn, 'Budgets'),
  LedgerNavItem(LucideIcons.settings, 'Settings'),
];

/// Each row Ledger answers live and the Ledger part that is it, where the
/// part's name is not the row's.
const Map<String, String> ledgerInventoryParts = {
  'Button': 'LedgerButton',
  'IconButton': 'LedgerIconButton',
  'ButtonGroup': 'LedgerButtonRow',
  'ToggleGroup': 'LedgerToggleGroup',
  'SplitButton': 'LedgerSplitButton',
  'Kbd': 'LedgerKbd',
  'Link': 'LedgerMoreLink',
  'TextField': 'LedgerTextField',
  'SearchField': 'LedgerSearchField',
  'PasswordField': 'LedgerPasswordField',
  'TextArea': 'LedgerTextArea',
  'InputGroup': 'LedgerInputGroup',
  'InputOtp': 'LedgerCodeField',
  'Combobox': 'LedgerCombobox',
  'MultiSelect': 'LedgerMultiSelect',
  'RangeSlider': 'LedgerRangeSlider',
  'FileUpload': 'LedgerFileUpload',
  'DateRangePicker': 'LedgerDateRangePicker',
  'Breadcrumb': 'LedgerBreadcrumb',
  'Pagination': 'LedgerPagination',
  'StepProgress': 'LedgerStepProgress',
  'PageDots': 'LedgerPageDots',
  'Command': 'LedgerCommandPalette',
  'Divider': 'LedgerDivider',
  'Badge': 'LedgerBadge',
  'Disclosure': 'LedgerDisclosure',
  'Timeline': 'LedgerTimeline',
  'Media': 'LedgerMedia',
  'LinearProgressIndicator': 'LedgerProgressBar',
  'CircularProgressIndicator': 'LedgerProgressRing',
  'Skeleton': 'LedgerSkeleton',
  'PieChart': 'LedgerPieChart',
  'Sparkline': 'LedgerSparkline',
  'Sheet': 'LedgerSideSheet',
  'ActionSheet': 'LedgerActionSheet',
  'Popover': 'LedgerPopover',
  'Tooltip': 'LedgerTooltip',
  'Banner': 'LedgerBanner',
  'DataTable': 'LedgerDataTable',
  'ScrollArea': 'LedgerScrollArea',
  'CarouselView': 'LedgerCarousel',
  'ReorderableListView': 'LedgerReorderableList',
  'SwipeActions': 'LedgerSwipeActions',
  'RefreshIndicator': 'LedgerPullToRefresh',
  'NumberField': 'LedgerStepper',
  'Select': 'LedgerSelect',
  'Checkbox': 'LedgerCheckbox',
  'RadioGroup': 'LedgerRadio',
  'Switch': 'LedgerSwitch',
  'Slider': 'LedgerSlider',
  'SegmentedButton': 'LedgerSegmentedControl',
  'Chip': 'LedgerChip',
  'DatePicker': 'LedgerDatePicker',
  'TimePicker': 'LedgerDatePicker (time)',
  'Calendar': 'LedgerDatePicker (inline)',
  'WheelPicker': 'LedgerDatePicker (wheel)',
  'FormField': 'LedgerTextField (label, helper, error)',
  'AppBar': 'LedgerTopBar',
  'NavigationBar': 'LedgerNavBar',
  'NavigationRail': 'LedgerSideBar',
  'NavigationDrawer': 'LedgerSideBar (extended)',
  'TabBar': 'LedgerTabs',
  'Scaffold': 'LedgerNavigationFrame',
  'Card': 'LedgerSlip',
  'ListTile': 'LedgerRow',
  'ListSection': 'LedgerSection',
  'SectionHeader': 'LedgerHead',
  'Avatar': 'LedgerAvatar',
  'AvatarGroup': 'LedgerAvatarStack',
  'Tag': 'LedgerTag',
  'EmptyState': 'LedgerEmptyState',
  'DescriptionList': 'LedgerFacts',
  'Dialog': 'LedgerDialog',
  'BottomSheet': 'LedgerSheet',
  'Menu': 'LedgerMenu',
  'SnackBar': 'LedgerToast',
  'StatusView': 'LedgerErrorState',
  'Meter': 'LedgerGauge',
  'LineChart': 'LedgerMonthLine',
  'BarChart': 'LedgerMonthBars',
  'AreaChart': 'LedgerCumulativeChart',
  'Table': 'LedgerRegister',
};

/// Rows whose specimen fills the room it is given (a frame, a rail, a
/// chart): the gallery gives each a height.
const Set<String> ledgerInventoryFills = {
  'Scaffold',
  'NavigationRail',
  'NavigationDrawer',
};

/// Ledger in ui_core's shared inventory: each row's specimen is the Ledger
/// part for it ([ledgerInventoryParts]), built with plain values, and each
/// row a ledger leaves out says why. [DesignInventory.verify] checks every
/// row is answered; [LedgerInventoryGallery] shows them all.
///
/// ```dart
/// LedgerInventoryGallery(inventory: ledgerInventory)
/// ```
final DesignInventory ledgerInventory = DesignInventory(
  look: 'Ledger',
  entries: [
    // Actions
    DesignInventoryEntry.present(
      'Button',
      (_) => const LedgerButton.filled('Save entry', onPressed: _none),
    ),
    DesignInventoryEntry.present(
      'IconButton',
      (_) => const LedgerIconButton(
        LucideIcons.search,
        semanticLabel: 'Search',
        onPressed: _none,
      ),
    ),
    const DesignInventoryEntry.absent(
      'FloatingActionButton',
      "Nothing floats over a ledger's page: its one act is the tab bar's "
          "green disc on a phone and the side bar's New entry on a desk.",
    ),
    DesignInventoryEntry.present(
      'ButtonGroup',
      (_) => const LedgerButtonRow(
        children: [
          LedgerButton('Export', onPressed: _none),
          LedgerButton.filled('Reconcile', onPressed: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'ToggleGroup',
      (_) => _Held<Set<String>>(
        const {'Month'},
        (context, v, set) => LedgerToggleGroup<String>(
          label: 'Range',
          options: const ['Week', 'Month', 'Year'],
          labelOf: (o) => o,
          selected: v,
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'SplitButton',
      (context) => const LedgerSplitButton(
        'Export',
        onPressed: _none,
        actions: [
          LedgerSplitAction(label: 'As CSV', onPressed: _none),
          LedgerSplitAction(label: 'As PDF', onPressed: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Kbd',
      (_) => const LedgerKbd(['⌘', 'K'], semanticLabel: 'Command K'),
    ),
    DesignInventoryEntry.present(
      'Link',
      (_) => const LedgerMoreLink('All of October', onTap: _none),
    ),
    // Inputs
    DesignInventoryEntry.present(
      'TextField',
      (_) => const LedgerTextField(label: 'Payee', hint: 'Who was paid'),
    ),
    DesignInventoryEntry.present(
      'SearchField',
      (_) => const LedgerSearchField(hint: 'Search entries'),
    ),
    DesignInventoryEntry.present(
      'PasswordField',
      (_) => const LedgerPasswordField(
        label: 'Password',
        helper: 'At least 12 characters',
      ),
    ),
    DesignInventoryEntry.present(
      'TextArea',
      (_) => const LedgerTextArea(
        label: 'Memo',
        hint: 'What it was for',
        maxLength: 280,
      ),
    ),
    DesignInventoryEntry.present(
      'InputGroup',
      (_) => const LedgerInputGroup(
        label: 'Shop address',
        before: 'https://',
        after: '.ledger.app',
        hint: 'your-shop',
      ),
    ),
    DesignInventoryEntry.present(
      'InputOtp',
      (_) => const LedgerCodeField(
        label: 'Code from your bank',
        helper: 'Six figures, sent by text',
      ),
    ),
    DesignInventoryEntry.present(
      'Combobox',
      (_) => const LedgerCombobox<String>(
        label: 'Payee',
        hint: 'Who was paid',
        options: _payees,
      ),
    ),
    DesignInventoryEntry.present(
      'MultiSelect',
      (_) => _Held<List<String>>(
        const ['Maren'],
        (context, v, set) => LedgerMultiSelect<String>(
          label: 'Split with',
          values: v,
          options: const ['Maren', 'Theo', 'Ana', 'Jun'],
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'FileUpload',
      (_) => LedgerFileUpload(
        label: 'Receipts',
        files: const [
          LedgerFile('Blue Fern Café.jpg', bytes: 182000),
          LedgerFile('October statement.pdf', bytes: 1240000, progress: .6),
        ],
        onPick: () {},
        onRemove: (_) {},
      ),
    ),
    DesignInventoryEntry.present(
      'DateRangePicker',
      (_) => _Held<LedgerDateRange?>(
        LedgerDateRange(DateTime(2026, 10, 12), DateTime(2026, 10, 19)),
        (context, v, set) => LedgerDateRangePicker(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          today: _day,
          value: v,
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Breadcrumb',
      (_) => LedgerBreadcrumb([
        LedgerCrumb('Accounts', onTap: () {}),
        LedgerCrumb('Everyday', onTap: () {}),
        const LedgerCrumb('October'),
      ]),
    ),
    DesignInventoryEntry.present(
      'Pagination',
      (_) => _Held<int>(
        2,
        (context, v, set) =>
            LedgerPagination(page: v, pageCount: 9, onChanged: set),
      ),
    ),
    DesignInventoryEntry.present(
      'StepProgress',
      (_) => const LedgerStepProgress(
        steps: ['Payee', 'Amount', 'Review'],
        current: 1,
      ),
    ),
    DesignInventoryEntry.present(
      'PageDots',
      (_) => _Held<int>(
        1,
        (context, v, set) => LedgerPageDots(count: 4, index: v, onChanged: set),
      ),
    ),
    DesignInventoryEntry.present(
      'Command',
      (_) => const LedgerCommandPalette(
        commands: [
          LedgerCommand(label: 'New entry', group: 'Entries', shortcut: 'N'),
          LedgerCommand(label: 'Go to Budgets', group: 'Places'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Divider',
      (_) => const LedgerDivider(label: 'Earlier'),
    ),
    DesignInventoryEntry.present(
      'Badge',
      (_) => LedgerBadge(
        count: 3,
        child: LedgerIconButton.outlined(
          LucideIcons.inbox,
          semanticLabel: 'Inbox',
          onPressed: () {},
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Disclosure',
      (_) => const LedgerDisclosure(
        title: 'Fees',
        note: r'$2.40',
        child: Text('A card fee and a foreign exchange fee.'),
      ),
    ),
    DesignInventoryEntry.present(
      'Timeline',
      (_) => const LedgerTimeline(
        entries: [
          LedgerTimelineEntry(when: 'Oct 26', title: 'Sent'),
          LedgerTimelineEntry(
            when: 'Oct 28',
            title: 'Posting',
            state: LedgerTimelineState.current,
          ),
          LedgerTimelineEntry(
            when: 'Oct 29',
            title: 'In their account',
            state: LedgerTimelineState.upcoming,
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Media',
      (_) => const SizedBox(
        width: 200,
        child: LedgerMedia(caption: 'Corner Market, Oct 27'),
      ),
    ),
    DesignInventoryEntry.present(
      'LinearProgressIndicator',
      (_) =>
          const LedgerProgressBar(value: .6, label: 'Uploading the statement'),
    ),
    DesignInventoryEntry.present(
      'CircularProgressIndicator',
      (_) => const LedgerProgressRing(
        value: .4,
        label: 'Saving the budget',
        showValue: true,
      ),
    ),
    // Its sheen held still here, so the inventory page comes to rest.
    DesignInventoryEntry.present(
      'Skeleton',
      (_) => const TickerMode(
        enabled: false,
        child: LedgerSkeleton(lines: 2, avatar: true),
      ),
    ),
    DesignInventoryEntry.present(
      'PieChart',
      (_) => const LedgerPieChart(
        label: 'October by category',
        shares: [
          LedgerShare('Rent', 1150),
          LedgerShare('Groceries', 486.20),
          LedgerShare('Other', 210.75),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Sparkline',
      (_) => const LedgerSparkline(
        label: 'Everyday, 30 days',
        values: [4.2, 4.6, 4.1, 5.0, 4.8, 5.6, 6.2],
        baseline: true,
      ),
    ),
    // The panel as it stands in from the side, drawn in place.
    DesignInventoryEntry.present(
      'Sheet',
      (_) => SizedBox(
        height: 320,
        child: LedgerSideSheet(
          title: 'Filters',
          onClose: () {},
          child: const Text('Everyday, Savings and the Keel Card.'),
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'ActionSheet',
      (_) => LedgerActionSheet<String>(
        message: 'Corner Market, Oct 27',
        acts: const [
          LedgerSheetAct('Download', value: 'download'),
          LedgerSheetAct('Delete', value: 'delete', destructive: true),
        ],
        onSelected: (_) {},
      ),
    ),
    DesignInventoryEntry.present(
      'Popover',
      (_) => LedgerPopover(
        semanticLabel: 'How Safe to spend is worked out',
        title: 'Safe to spend',
        anchor: (context, a) => LedgerButton.text(
          'How is this worked out?',
          size: LedgerButtonSize.medium,
          onPressed: a.toggle,
        ),
        child: const Text('Your balance less the bills due before payday.'),
      ),
    ),
    DesignInventoryEntry.present(
      'Tooltip',
      (_) => LedgerTooltip(
        message: 'Export as CSV',
        child: LedgerIconButton.outlined(
          LucideIcons.download,
          semanticLabel: 'Export',
          onPressed: () {},
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Banner',
      (_) => LedgerBanner(
        title: 'Your October statement is ready',
        actionLabel: 'Open',
        onAction: () {},
      ),
    ),
    DesignInventoryEntry.present('DataTable', (_) => _InventoryTable()),
    DesignInventoryEntry.present('ScrollArea', (_) => _InventoryScroll()),
    DesignInventoryEntry.present(
      'CarouselView',
      (_) => LedgerCarousel(
        semanticLabel: 'Highlights',
        height: 96,
        itemCount: 3,
        itemBuilder: (context, i) => ColoredBox(
          color: context.ledgerTheme.surfaceAlt,
          child: Center(child: Text('Highlight ${i + 1}')),
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'ReorderableListView',
      (_) => LedgerReorderableList<String>(
        items: const ['Everyday', 'Savings', 'Keel Card'],
        labelOf: (n) => n,
        onReorder: (_, _) {},
        itemBuilder: (context, n) => Text(n),
      ),
    ),
    DesignInventoryEntry.present(
      'SwipeActions',
      (_) => LedgerSwipeActions(
        trailing: [
          LedgerSwipeAction(
            'Delete',
            tone: LedgerSwipeTone.destructive,
            onPressed: () {},
          ),
        ],
        child: const LedgerRow(title: 'Studio rent', subtitle: 'Due Nov 1'),
      ),
    ),
    DesignInventoryEntry.present(
      'RefreshIndicator',
      (_) => SizedBox(
        height: 120,
        child: LedgerPullToRefresh(
          onRefresh: () async {},
          child: ListView(
            children: const [
              LedgerRow(title: 'Corner Market', subtitle: 'Groceries'),
            ],
          ),
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'NumberField',
      (_) => _Held<num>(
        2,
        (context, v, set) =>
            LedgerStepper(value: v, label: 'Copies', min: 1, onChanged: set),
      ),
    ),
    DesignInventoryEntry.present(
      'Select',
      (_) => _Held<String>(
        'Everyday',
        (context, v, set) => LedgerSelect<String>(
          label: 'Account',
          value: v,
          onChanged: set,
          items: const [
            LedgerSelectItem(value: 'Everyday', label: 'Everyday'),
            LedgerSelectItem(value: 'Savings', label: 'Savings'),
            LedgerSelectItem(value: 'Keel Card', label: 'Keel Card'),
          ],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Checkbox',
      (_) => _Held<bool?>(
        true,
        (context, v, set) => LedgerCheckbox(
          value: v,
          label: 'Keep the receipt with the entry',
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'RadioGroup',
      (_) => _Held<String?>(
        'monthly',
        (context, v, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label) in const [
              ('weekly', 'Every week'),
              ('monthly', 'Every month'),
            ])
              LedgerRadio<String>(
                value: value,
                groupValue: v,
                label: label,
                onChanged: set,
              ),
          ],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Switch',
      (_) => _Held<bool>(
        true,
        (context, v, set) =>
            LedgerSwitch(value: v, semanticLabel: 'Round-ups', onChanged: set),
      ),
    ),
    DesignInventoryEntry.present(
      'Slider',
      (_) => _Held<double>(
        320,
        (context, v, set) => LedgerSlider(
          label: 'Monthly budget',
          value: v,
          min: 0,
          max: 600,
          divisions: 12,
          unit: r'$',
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'RangeSlider',
      (_) => _Held<LedgerRangeValues>(
        const LedgerRangeValues(40, 180),
        (context, v, set) => LedgerRangeSlider(
          label: 'Amount',
          values: v,
          max: 500,
          divisions: 10,
          format: (x) => '\$${x.round()}',
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'SegmentedButton',
      (_) => _Held<String>(
        'Month',
        (context, v, set) => LedgerSegmentedControl(
          options: const ['Week', 'Month', 'Year'],
          value: v,
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Chip',
      (_) => _Held<bool>(
        true,
        (context, v, set) =>
            LedgerChip('Groceries', selected: v, onTap: () => set(!v)),
      ),
    ),
    const DesignInventoryEntry.absent(
      'Rating',
      'A ledger records what was paid, not what it was worth: stars are a '
          "review's vocabulary.",
    ),
    DesignInventoryEntry.present(
      'DatePicker',
      (_) => _Held<DateTime>(
        _day,
        (context, v, set) => LedgerDatePicker(
          label: 'Day',
          value: v,
          today: _day,
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'TimePicker',
      (_) => _Held<DateTime>(
        _day.add(const Duration(hours: 8, minutes: 12)),
        (context, v, set) => LedgerDatePicker(
          label: 'Time',
          value: v,
          mode: LedgerDatePickerMode.time,
          today: _day,
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Calendar',
      (_) => _Held<DateTime>(
        _day,
        (context, v, set) => LedgerDatePicker(
          label: 'Day',
          value: v,
          presentation: LedgerDatePickerPresentation.inline,
          today: _day,
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'WheelPicker',
      (_) => _Held<DateTime>(
        _day,
        (context, v, set) => LedgerDatePicker(
          label: 'Day',
          value: v,
          presentation: LedgerDatePickerPresentation.wheel,
          today: _day,
          onChanged: set,
        ),
      ),
    ),
    const DesignInventoryEntry.absent(
      'ColorPicker',
      "Colour is ink in a ledger: one green, one vermilion and three inks, "
          'and a category is told by its glyph and its name.',
    ),
    DesignInventoryEntry.present(
      'FormField',
      (_) => const LedgerTextField(
        label: 'Amount',
        hint: '0.00',
        helper: 'What was paid, in dollars',
        error: 'Enter what was paid',
        isRequired: true,
      ),
    ),
    // Navigation
    DesignInventoryEntry.present(
      'AppBar',
      (_) => const LedgerTopBar(title: 'Register', meta: '92 entries'),
    ),
    DesignInventoryEntry.present(
      'NavigationBar',
      (_) => _Held<int>(
        0,
        (context, v, set) => LedgerNavBar(
          items: _tabs,
          selectedIndex: v,
          onDestinationSelected: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationRail',
      (_) => _Held<int>(
        0,
        (context, v, set) => LedgerSideBar(
          extended: false,
          items: _tabs,
          selectedIndex: v,
          onDestinationSelected: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationDrawer',
      (_) => _Held<int>(
        0,
        (context, v, set) => LedgerSideBar(
          items: _tabs,
          selectedIndex: v,
          brand: 'Quill',
          onDestinationSelected: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'TabBar',
      (_) => _Held<int>(
        0,
        (context, v, set) => LedgerTabs(
          tabs: const ['Entries', 'Notes', 'Files'],
          counts: const [12, 3, null],
          selectedIndex: v,
          onSelected: set,
        ),
      ),
    ),
    const DesignInventoryEntry.absent(
      'MenuBar',
      'The side bar goes between pages and the green act acts on one; a '
          "desktop menu bar is the platform's own, above the window.",
    ),
    DesignInventoryEntry.present(
      'Scaffold',
      (_) => _Held<int>(
        0,
        (context, v, set) => LedgerNavigationFrame(
          destinations: _tabs,
          selectedIndex: v,
          onDestinationSelected: set,
          brand: 'Quill',
          body: Center(child: Text(_tabs[v].label)),
        ),
      ),
    ),
    // Containers
    DesignInventoryEntry.present(
      'Card',
      (context) => LedgerSlip(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LedgerSpacing.s20,
            vertical: LedgerSpacing.s12,
          ),
          child: LedgerRows(
            children: [
              const LedgerKeyValue('Status', 'Posted'),
              LedgerKeyValue('Day', LedgerFormat.date(_day)),
            ],
          ),
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'ListTile',
      (_) => const LedgerRow(
        leading: LedgerGlyph(LucideIcons.landmark),
        title: 'Everyday',
        subtitle: '··4821',
        subtitleMonospace: true,
        value: LedgerAmount(4210.55),
        onTap: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'ListSection',
      (_) => const LedgerSection(
        head: LedgerHead('Accounts', note: 'Balance'),
        child: LedgerRows(
          children: [
            LedgerRow(
              leading: LedgerGlyph(LucideIcons.landmark),
              title: 'Everyday',
              value: LedgerAmount(4210.55),
              onTap: _none,
            ),
            LedgerRow(
              leading: LedgerGlyph(LucideIcons.piggyBank),
              title: 'Savings',
              value: LedgerAmount(18400),
              onTap: _none,
            ),
          ],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'SectionHeader',
      (_) => const LedgerHead('Recent', note: 'Register', onTap: _none),
    ),
    DesignInventoryEntry.present(
      'Table',
      (_) => LedgerRegister(
        heads: const ['Time', 'Payee', 'Category', 'Account', 'Amount'],
        children: [
          LedgerDayGroup(
            'Today',
            note: LedgerFormat.date(_day),
            net: -16.4,
            rows: const [
              LedgerTransactionRow(
                title: 'Blue Fern Café',
                category: 'Dining out',
                when: '08:12',
                account: 'Keel Card',
                amount: -9.65,
                initials: 'BF',
                pending: true,
                onTap: _none,
              ),
              LedgerTransactionRow(
                title: 'Corner Basket',
                category: 'Groceries',
                when: '07:40',
                account: 'Everyday',
                amount: -6.75,
                initials: 'CB',
                onTap: _none,
              ),
            ],
          ),
        ],
      ),
    ),
    const DesignInventoryEntry.absent(
      'Resizable',
      "A ledger page keeps its measure: its columns are set, never dragged "
          'apart.',
    ),
    const DesignInventoryEntry.absent(
      'TreeView',
      "A ledger's order is one level deep (accounts, then entries by day); "
          "nested folders are a file system's.",
    ),
    // Display
    DesignInventoryEntry.present(
      'Avatar',
      (_) => const LedgerAvatar(initials: 'MH', label: 'Maren Holt'),
    ),
    DesignInventoryEntry.present(
      'AvatarGroup',
      (_) => const LedgerAvatarStack(
        names: ['Maren Holt', 'Ines Vidal', 'Tomas Berg', 'Ada Moss'],
        max: 3,
      ),
    ),
    DesignInventoryEntry.present('Tag', (_) => const LedgerTag('Pending')),
    DesignInventoryEntry.present(
      'EmptyState',
      (_) => const LedgerEmptyState(
        title: 'Nothing found',
        body: 'No entry has these words. Try a payee or a category.',
      ),
    ),
    DesignInventoryEntry.present(
      'DescriptionList',
      (_) => const LedgerFacts(
        facts: [
          LedgerFact('Opened', 'Mar 2023', note: 'Everyday'),
          LedgerFact.money('Interest', 182.4, note: 'This year'),
        ],
      ),
    ),
    // Overlays
    DesignInventoryEntry.present(
      'Dialog',
      (_) => const LedgerDialog(
        title: 'Archive October?',
        body: 'Its entries stay in the register, closed to edits.',
        confirmLabel: 'Archive',
        onConfirmPressed: _none,
        onCancelPressed: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'BottomSheet',
      (context) => LedgerButton(
        'Open the sheet',
        onPressed: () => LedgerSheet.show<void>(
          context,
          title: 'Everyday',
          builder: (context) => const [
            LedgerFacts(
              facts: [
                LedgerFact.money('Balance', 4210.55, note: 'Today'),
                LedgerFact('Number', '··4821', note: 'Debit card'),
              ],
            ),
          ],
        ),
      ),
    ),
    const DesignInventoryEntry.absent(
      'HoverCard',
      'Facts stand on the page or in a popover a tap opens: nothing appears '
          'on hover alone, which a finger and a screen reader never get.',
    ),
    DesignInventoryEntry.present(
      'Menu',
      (_) => LedgerMenu(
        head: 'Spent by month',
        semanticLabel: 'Months',
        items: [
          for (final (i, (month, amount)) in const [
            ('October', 1840.2),
            ('September', 2104.65),
            ('August', 1977.1),
          ].indexed)
            LedgerMenuItem(
              month,
              amount: amount,
              selected: i == 0,
              onTap: _none,
            ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'SnackBar',
      (context) => LedgerButton(
        'Save',
        onPressed: () =>
            LedgerToast.show(context, 'Entry saved to the register'),
      ),
    ),
    // Feedback
    DesignInventoryEntry.present(
      'StatusView',
      (_) => const LedgerErrorState(
        title: 'The register could not load',
        message: 'Quill could not reach your accounts. Your entries are safe.',
        onRetryPressed: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'Meter',
      (_) => LedgerGauge(
        ratio: 0.62,
        pace: 0.9,
        paceLabel: 'Day 28',
        startLabel: LedgerFormat.money(0, showCents: false),
        endLabel: LedgerFormat.money(3000, showCents: false),
      ),
    ),
    // Charts
    DesignInventoryEntry.present(
      'LineChart',
      (_) => const LedgerMonthLine(
        values: [4200, 4120, 3980, 4460, 4390, 4310, 4210],
        start: 4200,
        days: 31,
        low: 3800,
        high: 4600,
        grid: [LedgerGridLine(4000, r'$4k'), LedgerGridLine(4500, r'$4.5k')],
        month: 'October',
      ),
    ),
    DesignInventoryEntry.present(
      'BarChart',
      (_) => const LedgerMonthBars(
        values: [12.4, 13.1, 14.8, 15.2, 16.9, 18.2],
        months: ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'],
      ),
    ),
    DesignInventoryEntry.present(
      'AreaChart',
      (_) => const LedgerCumulativeChart(
        cumulative: [0, 1450, 1520, 1610, 1690, 1760, 1840],
        budget: 2400,
        days: 31,
        high: 2600,
        grid: [LedgerGridLine(1000, r'$1k'), LedgerGridLine(2000, r'$2k')],
        budgetLabel: r'Budget $2,400',
        month: 'October',
      ),
    ),
  ],
);

/// Every row of [inventory], group by group: a group's head counts the parts
/// Ledger carries, each row names its Ledger part over its specimen, and a
/// row a ledger leaves out reads its reason.
///
/// ```dart
/// const LedgerInventoryGallery()
/// ```
class LedgerInventoryGallery extends StatelessWidget {
  /// The gallery of [inventory], [ledgerInventory] by default.
  const LedgerInventoryGallery({
    this.inventory,
    this.padding = const EdgeInsets.all(LedgerSpacing.s16),
    super.key,
  });

  /// The inventory listed; null lists [ledgerInventory].
  final DesignInventory? inventory;

  /// The room round the list.
  final EdgeInsetsGeometry padding;

  /// The height a filling specimen ([ledgerInventoryFills]) is given.
  static const double fillHeight = 480;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<DesignInventory>(
          'inventory',
          inventory,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return DesignInventoryGallery(
      inventory: inventory ?? ledgerInventory,
      padding: padding,
      groupBuilder: (context, group, present, total) => Padding(
        padding: const EdgeInsets.only(
          top: LedgerSpacing.s32,
          bottom: LedgerSpacing.s8,
        ),
        child: LedgerHead(group, note: '$present of $total'),
      ),
      rowBuilder: (context, row, entry, specimen) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LedgerSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: LedgerSpacing.s8,
          children: [
            Text(
              ledgerInventoryParts[row.id] == null
                  ? row.name
                  : '${ledgerInventoryParts[row.id]} · ${row.name}',
              style: t.label.colored(t.textSecondary),
            ),
            if (specimen == null)
              Text(
                entry?.absentReason == null
                    ? 'Missing'
                    : DesignInventory.absentLabel(entry!.absentReason!),
                style: t.bodySmall.colored(t.textTertiary),
              )
            else if (ledgerInventoryFills.contains(row.id))
              SizedBox(height: fillHeight, child: specimen)
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: specimen,
              ),
          ],
        ),
      ),
    );
  }
}

/// The inventory's table: three entries under their headings.
class _InventoryTable extends StatefulWidget {
  @override
  State<_InventoryTable> createState() => _InventoryTableState();
}

class _InventoryTableState extends State<_InventoryTable> {
  final _table = DesignTableController<(String, double)>(
    rows: const [('Corner Market', 64.18), ('Rent', 1150), ('Payroll', 3200)],
    columns: [
      DesignTableColumn(id: 'entry', label: 'Entry', sortKey: (r) => r.$1),
      DesignTableColumn(
        id: 'amount',
        label: 'Amount',
        numeric: true,
        sortKey: (r) => r.$2,
      ),
    ],
  );

  @override
  void dispose() {
    _table.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LedgerDataTable<(String, double)>(
    controller: _table,
    cellText: (r, column) =>
        column.id == 'entry' ? r.$1 : r.$2.toStringAsFixed(2),
  );
}

/// The inventory's scrolling region: a note longer than its room.
class _InventoryScroll extends StatefulWidget {
  @override
  State<_InventoryScroll> createState() => _InventoryScrollState();
}

class _InventoryScrollState extends State<_InventoryScroll> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 96,
    child: LedgerScrollArea(
      controller: _scroll,
      semanticLabel: 'Terms',
      child: SingleChildScrollView(
        controller: _scroll,
        child: const Text(
          'A transfer between your own accounts arrives the same day when '
          'sent before 5 pm, else the next working day. Transfers to others '
          'may take up to three working days. A scheduled transfer leaves on '
          'its date, or the working day before when that is a holiday.',
        ),
      ),
    ),
  );
}
