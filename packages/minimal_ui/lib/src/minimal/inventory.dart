/// Minimal's answer to ui_core's shared inventory: for each of the 89
/// components every look names alike, the Minimal class that is it (a
/// specimen of it, built live) or why Minimal has none.
library;

import 'package:material_ui/material_ui.dart';
import 'package:ui_core/inventory.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'chrome_metrics.dart';
import 'components/action_sheet.dart';
import 'components/activity.dart';
import 'components/avatar.dart';
import 'components/badge.dart';
import 'components/banner.dart';
import 'components/breadcrumb.dart';
import 'components/button.dart';
import 'components/button_group.dart';
import 'components/calendar.dart';
import 'components/card.dart';
import 'components/carousel.dart';
import 'components/charts.dart';
import 'components/check.dart';
import 'components/chip.dart';
import 'components/code.dart';
import 'components/color_picker.dart';
import 'components/combobox.dart';
import 'components/command.dart';
import 'components/data_table.dart';
import 'components/date_picker.dart';
import 'components/dialog.dart';
import 'components/disclosure.dart';
import 'components/divider.dart';
import 'components/feedback.dart';
import 'components/file_upload.dart';
import 'components/form_field.dart';
import 'components/group_header.dart';
import 'components/icon_button.dart';
import 'components/img.dart';
import 'components/input.dart';
import 'components/input_group.dart';
import 'components/link.dart';
import 'components/list_behaviours.dart';
import 'components/list_row.dart';
import 'components/menu.dart';
import 'components/menu_bar.dart';
import 'components/nav_bar.dart';
import 'components/navigation.dart';
import 'components/overlays.dart';
import 'components/pagination.dart';
import 'components/panes.dart';
import 'components/picker.dart';
import 'components/progress.dart';
import 'components/property.dart';
import 'components/radio.dart';
import 'components/range_slider.dart';
import 'components/rating.dart';
import 'components/screen.dart';
import 'components/search.dart';
import 'components/segmented.dart';
import 'components/series_charts.dart';
import 'components/sheet.dart';
import 'components/slider.dart';
import 'components/split_button.dart';
import 'components/states.dart';
import 'components/stepper.dart';
import 'components/swipe.dart';
import 'components/table.dart';
import 'components/tabs.dart';
import 'components/tag.dart';
import 'components/text_area.dart';
import 'components/time_picker.dart';
import 'components/toast.dart';
import 'components/toggle.dart';
import 'components/toggle_group.dart';
import 'components/tooltip.dart';
import 'components/top_bar.dart';
import 'theme.dart';

void _none() {}

DesignInventoryEntry _live(String stem, WidgetBuilder builder) =>
    DesignInventoryEntry.present(stem, builder);

/// A file or folder of the specimen tree.
class _Node {
  const _Node(this.name, [this.children = const []]);

  final String name;
  final List<_Node> children;
}

const List<_Node> _files = [
  _Node('lib', [_Node('main.dart'), _Node('theme.dart')]),
  _Node('pubspec.yaml'),
];

/// The scroll area's content: more lines than its height shows.
const List<String> _notes = [
  '1.4.0 — Calendar picks a range across two months.',
  '1.3.2 — The data table keeps its selection across pages.',
  '1.3.1 — Toasts pause while a pointer rests on them.',
  '1.3.0 — The menu bar opens its submenus on the arrow keys.',
  '1.2.4 — A colour picker reads and writes hex.',
  '1.2.3 — Sheets come from either side.',
];

/// One carousel slide: the card's hairline round a title and a line.
class _Slide extends StatelessWidget {
  const _Slide(this.title, this.line);

  final String title;
  final String line;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: t.card,
        shape: t.shapes.medium.copyWith(
          side: BorderSide(color: t.border, width: t.hairline),
        ),
      ),
      child: Padding(
        padding: MinimalInsets.all16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: t.h3.c(t.foreground)),
            const MinimalGap(MinimalSpacing.s4),
            Text(line, style: t.bodySmall.c(t.mutedForeground)),
          ],
        ),
      ),
    );
  }
}

/// One pane of the split: its caps name over a quiet line.
class _Pane extends StatelessWidget {
  const _Pane(this.name, this.line);

  final String name;
  final String line;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Padding(
      padding: MinimalInsets.all12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name.toUpperCase(), style: t.label),
          const MinimalGap(MinimalSpacing.s8),
          Text(
            line,
            style: t.bodySmall.c(t.mutedForeground),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Minimal in ui_core's shared inventory: each row's specimen is the
/// Minimal part that answers it, built with plain values, and the one
/// absent row says why. [DesignInventory.verify] checks every row is
/// answered; a [DesignInventoryGallery] shows them all.
///
/// ```dart
/// DesignInventoryGallery(inventory: minimalInventory)
/// ```
final DesignInventory minimalInventory = DesignInventory(
  look: 'Minimal',
  entries: [
    // Actions
    _live(
      'Button',
      // One part per row (the Buttons page shows every variant).
      (_) => const MinimalButton('Book a table', onPressed: _none),
    ),
    _live(
      'IconButton',
      (_) => const MinimalIconButton(
        LucideIcons.search,
        label: 'Search',
        onPressed: _none,
      ),
    ),
    const DesignInventoryEntry.absent(
      'FloatingActionButton',
      'A floating action button is Material vocabulary; Minimal puts the '
          "page's one action in its top bar or a primary MinimalButton.",
    ),
    _live(
      'ButtonGroup',
      (_) => MinimalButtonGroup(
        // Acts that run once (a kept choice is the toggle group's).
        items: const [
          MinimalButtonGroupItem(
            icon: LucideIcons.chevronLeftDir,
            semanticLabel: 'Previous week',
            onPressed: _none,
          ),
          MinimalButtonGroupItem(label: 'Today', onPressed: _none),
          MinimalButtonGroupItem(
            icon: LucideIcons.chevronRightDir,
            semanticLabel: 'Next week',
            onPressed: _none,
          ),
        ],
      ),
    ),
    _live(
      'ToggleGroup',
      (_) => MinimalToggleGroup<String>(
        label: 'View',
        selected: const {'list'},
        onChanged: (_) {},
        items: const [
          MinimalToggleItem('list', label: 'List'),
          MinimalToggleItem('board', label: 'Board'),
        ],
      ),
    ),
    _live(
      'SplitButton',
      (_) => const MinimalSplitButton(
        'Save',
        onPressed: _none,
        actions: [MinimalMenuItem('Save as…', onPressed: _none)],
      ),
    ),
    _live(
      'Link',
      (_) => const MinimalLink('Forgot password?', onPressed: _none),
    ),
    _live('Kbd', (_) => const MinimalKbd('K')),
    // Inputs
    _live('TextField', (_) => const MinimalTextField(label: 'Name')),
    _live('TextArea', (_) => const MinimalTextArea(label: 'Notes')),
    _live('SearchField', (_) => const MinimalSearchField(hint: 'Search')),
    _live(
      'PasswordField',
      (_) => const MinimalPasswordField(label: 'Password'),
    ),
    _live(
      'InputGroup',
      (_) => const MinimalInputGroup(label: 'Website', prefixText: 'https://'),
    ),
    _live('InputOtp', (_) => const MinimalInputOtp(label: 'Code')),
    _live(
      'NumberField',
      (_) => MinimalNumberField(
        label: 'Guests',
        value: 2,
        min: 1,
        max: 8,
        onChanged: (_) {},
      ),
    ),
    _live(
      'Select',
      (_) => MinimalSelect<String>(
        label: 'Repeats',
        value: 'daily',
        options: const [
          MinimalSelectOption('daily', 'Every day'),
          MinimalSelectOption('weekly', 'Every week'),
        ],
        onChanged: (_) {},
      ),
    ),
    _live(
      'Combobox',
      (_) => MinimalCombobox<String>(
        label: 'City',
        options: const ['Lisbon', 'London', 'Lyon'],
        displayString: (c) => c,
        onSelected: (_) {},
      ),
    ),
    _live(
      'MultiSelect',
      (_) => MinimalMultiSelect<String>(
        label: 'Labels',
        values: const ['Bug'],
        options: const ['Bug', 'Design', 'Docs'],
        displayString: (l) => l,
        onChanged: (_) {},
      ),
    ),
    _live(
      'Checkbox',
      (_) => MinimalCheckbox(
        value: true,
        label: 'Agree to the guidelines',
        onChanged: (_) {},
      ),
    ),
    _live(
      'RadioGroup',
      (_) => MinimalRadioGroup<String>(
        value: 'free',
        onChanged: (_) {},
        options: const [
          MinimalRadioOption(value: 'free', label: 'Free'),
          MinimalRadioOption(value: 'pro', label: 'Pro'),
        ],
      ),
    ),
    _live(
      'Switch',
      // A setting is a row: its words in the ink, the switch at its end (the
      // labelled switch is a footer's quiet register).
      (_) => MinimalListTile(
        title: 'Reminders',
        // On the specimen column's keyline, as the check and radio stand.
        padding: EdgeInsets.zero,
        trailing: MinimalSwitch(
          value: true,
          label: 'Reminders',
          onChanged: (_) {},
        ),
      ),
    ),
    _live(
      'Slider',
      (_) => MinimalSlider(label: 'Volume', value: 0.4, onChanged: (_) {}),
    ),
    _live(
      'RangeSlider',
      (_) => MinimalRangeSlider(
        label: 'Price',
        values: const DesignRangeValues(40, 140),
        max: 200,
        format: (v) => '\$${v.round()}',
        onChanged: (_) {},
      ),
    ),
    _live(
      'SegmentedButton',
      (_) => MinimalSegmentedButton<int>(
        segments: const [
          MinimalButtonSegment(0, 'Week'),
          MinimalButtonSegment(1, 'Month'),
        ],
        value: 0,
        onChanged: (_) {},
      ),
    ),
    _live(
      'Chip',
      (_) => const MinimalChipRow(
        children: [
          MinimalChip('Open', count: 2, selected: true, onPressed: _none),
          MinimalChip('Week', onPressed: _none),
          MinimalChip('Month', onPressed: _none),
        ],
      ),
    ),
    _live(
      'Rating',
      (_) => MinimalRating(value: 4, label: 'Your rating', onChanged: (_) {}),
    ),
    _live(
      'FileUpload',
      (_) => const MinimalFileUpload(
        title: 'Drop a CSV here, or browse',
        link: 'browse',
        onBrowse: _none,
      ),
    ),
    _live(
      'DatePicker',
      (_) => MinimalDatePicker(
        label: 'Due',
        value: DateTime(2026, 3, 12, 9),
        onChanged: (_) {},
      ),
    ),
    _live(
      'DateRangePicker',
      (_) => MinimalDateRangePicker(
        label: 'Stay',
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        onChanged: (_) {},
      ),
    ),
    _live(
      'TimePicker',
      (_) => MinimalTimePicker(
        label: 'Remind me at',
        value: DateTime(2026, 1, 1, 7, 0),
        onChanged: (_) {},
      ),
    ),
    _live(
      'Calendar',
      (_) => MinimalCalendar(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        today: DateTime(2026, 3, 12),
        onChanged: (_) {},
      ),
    ),
    const DesignInventoryEntry.absent(
      'WheelPicker',
      'A wheel picker is an iOS idiom; Minimal chooses from a MinimalSelect, '
          'a MinimalCombobox or a MinimalCommand, and a time from a '
          'MinimalTimePicker.',
    ),
    _live(
      'ColorPicker',
      (_) =>
          MinimalColorPicker(value: const Color(0xFF2563EB), onChanged: (_) {}),
    ),
    _live(
      'FormField',
      // The error stands where the help would.
      (_) => const MinimalFormField(
        label: 'Issue ID',
        help: 'Shown to your team.',
        error: 'An issue ID ends in its number, like HAB-12.',
        child: MinimalTextField(),
      ),
    ),
    // Navigation
    _live('AppBar', (_) => const MinimalAppBar(title: 'Today')),
    _live(
      'NavigationBar',
      (_) => MinimalNavigationBar(
        items: const [
          MinimalNavItem(LucideIcons.calendarCheck, 'Today'),
          MinimalNavItem(LucideIcons.listChecks, 'Habits'),
          MinimalNavItem(LucideIcons.activity, 'Trends'),
          MinimalNavItem(LucideIcons.settings, 'Settings'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
    ),
    _live(
      'NavigationRail',
      (_) => MinimalNavigationRail(
        destinations: const [
          MinimalNavItem(LucideIcons.inbox, 'Inbox'),
          MinimalNavItem(LucideIcons.folder, 'Projects'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
    ),
    _live(
      'NavigationDrawer',
      (_) => MinimalNavigationDrawer(
        sections: const [
          MinimalNavigationSection(
            destinations: [
              MinimalNavItem(LucideIcons.inbox, 'Inbox'),
              MinimalNavItem(LucideIcons.listTodo, 'My issues'),
            ],
          ),
        ],
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
    ),
    _live(
      'TabBar',
      (_) => MinimalTabBar(
        tabs: const ['Overview', 'Activity'],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
    ),
    _live(
      'Breadcrumb',
      (_) => const MinimalBreadcrumb(
        crumbs: [
          MinimalBreadcrumbItem('Habits', onPressed: _none),
          MinimalBreadcrumbItem('HAB-4', mono: true),
        ],
      ),
    ),
    _live(
      'Pagination',
      (_) => MinimalPagination(page: 2, pageCount: 12, onPageChanged: (_) {}),
    ),
    _live(
      'StepProgress',
      (_) => const MinimalStepProgress(
        steps: ['Account', 'Plan', 'Pay'],
        current: 1,
      ),
    ),
    _live('PageDots', (_) => const MinimalPageDots(count: 4, selectedIndex: 1)),
    _live(
      'MenuBar',
      (_) => const MinimalMenuBar(
        menus: [
          MinimalMenuEntry(
            'File',
            children: [MinimalMenuEntry('New', onPressed: _none)],
          ),
          MinimalMenuEntry(
            'Edit',
            children: [MinimalMenuEntry('Undo', onPressed: _none)],
          ),
          MinimalMenuEntry(
            'View',
            children: [MinimalMenuEntry('Board', onPressed: _none)],
          ),
        ],
      ),
    ),
    _live(
      'Command',
      (_) => const MinimalCommand(
        autofocus: false,
        actions: [
          MinimalCommandItem(
            'New habit',
            icon: LucideIcons.plus,
            group: 'Habits',
            shortcut: 'N',
            onSelected: _none,
          ),
          MinimalCommandItem(
            'Search habits',
            icon: LucideIcons.search,
            group: 'Habits',
            shortcut: '/',
            onSelected: _none,
          ),
          MinimalCommandItem(
            'Open settings',
            icon: LucideIcons.settings,
            group: 'Go to',
            shortcut: 'G S',
            onSelected: _none,
          ),
        ],
      ),
    ),
    _live(
      'Scaffold',
      (_) => const MinimalScaffold(
        topBar: MinimalAppBar(title: 'Today', subtitle: 'Fri 28 Aug'),
        padding: EdgeInsets.zero,
        // The page's rows on the bar's keyline (the screen gutter), as on a
        // phone: the frame round the specimen is not a card of the page's.
        body: MinimalListSection(
          children: [
            MinimalListTile(
              title: 'Meditate',
              meta: '4d',
              padding: MinimalInsets.gutter,
            ),
            MinimalListTile(
              title: 'Morning run',
              meta: '12d',
              padding: MinimalInsets.gutter,
            ),
            MinimalListTile(
              title: 'Drink water',
              meta: '10d',
              padding: MinimalInsets.gutter,
            ),
          ],
        ),
      ),
    ),
    // Containers
    _live('Card', (context) {
      final t = context.minimalTheme;
      return MinimalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Morning run', style: t.body.medium.c(t.foreground)),
            const MinimalGap(MinimalSpacing.s4),
            Text(
              'Out the door before 8. Any distance counts.',
              style: t.bodySmall.c(t.mutedForeground),
            ),
          ],
        ),
      );
    }),
    _live(
      'ListTile',
      (_) => const MinimalListTile(title: 'Drink water', meta: '10d'),
    ),
    _live(
      'ListSection',
      (_) => const MinimalListSection(
        inset: true,
        children: [
          MinimalListTile(title: 'Morning run', meta: '12d'),
          MinimalListTile(title: 'Drink water', meta: '10d'),
          MinimalListTile(title: 'Journal', meta: '3d'),
        ],
      ),
    ),
    _live('SectionHeader', (_) => const MinimalSectionHeader('Morning')),
    _live(
      'Disclosure',
      (_) => const MinimalDisclosure(
        title: 'Advanced',
        child: Text('Webhooks and API keys.'),
      ),
    ),
    _live(
      'Table',
      (_) => const MinimalTable(
        columns: [
          MinimalColumn('Customer'),
          MinimalColumn('Qty', numeric: true),
        ],
        rows: [
          MinimalTableRow([MinimalCell('Ana Souza'), MinimalCell('3')]),
        ],
      ),
    ),
    _live(
      'DataTable',
      (_) => MinimalDataTable<(String, String, double)>(
        rows: const [
          ('Ben Okafor', 'ORD-1039', 84),
          ('Ana Souza', 'ORD-1042', 129),
          ('Hanna Berg', 'ORD-1044', 46.5),
          ('Chen Wei', 'ORD-1047', 212),
        ],
        columns: [
          MinimalDataColumn<(String, String, double)>(
            'Customer',
            value: (r) => r.$1,
            sortable: true,
          ),
          MinimalDataColumn<(String, String, double)>(
            'Order',
            value: (r) => r.$2,
            mono: true,
          ),
          MinimalDataColumn<(String, String, double)>(
            'Total',
            value: (r) => '\$${r.$3.toStringAsFixed(2)}',
            sortKey: (r) => r.$3,
            numeric: true,
          ),
        ],
        pageSize: 2,
      ),
    ),
    _live('Divider', (_) => const MinimalDivider(label: 'or')),
    _live(
      'ScrollArea',
      (context) => MinimalScrollArea(
        height: 120,
        alwaysShown: true,
        label: 'Release notes',
        padding: const EdgeInsetsDirectional.only(start: MinimalCard.inset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final note in _notes)
              Padding(
                padding: MinimalInsets.vertical8,
                child: Text(
                  note,
                  style: context.minimalTheme.bodySmall.c(
                    context.minimalTheme.foreground,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    _live(
      'Resizable',
      (_) => const MinimalResizable(
        initialFraction: 0.4,
        handle: true,
        // A count and its noun stay on one line (the gallery's panes, too).
        first: _Pane('Inbox', '12\u00a0threads'),
        second: _Pane('Thread', 'Ana Souza · 3 replies'),
      ),
    ),
    _live(
      'CarouselView',
      (context) => MinimalCarouselView(
        // As tall as a slide's words at any text size.
        height: MediaQuery.textScalerOf(context).scale(120),
        children: const [
          _Slide('Plan the week', 'Every promise, one row each.'),
          _Slide('Keep the day', 'Tick it off where you stand.'),
          _Slide('See the trend', 'Weeks as bars, no guilt.'),
        ],
      ),
    ),
    _live(
      'ReorderableListView',
      (_) => MinimalReorderableListView<String>(
        items: const ['Warm up', 'Intervals', 'Stretch'],
        labelOf: (s) => s,
        onReorder: (_, _) {},
        itemBuilder: (context, s) => Text(s),
      ),
    ),
    _live(
      'SwipeActions',
      // Open, as a row stands mid-swipe: its acts are what it shows.
      (_) => const MinimalSwipeActions(
        initiallyOpen: true,
        trailing: [
          MinimalSwipeAction('Archive', onPressed: _none),
          MinimalSwipeAction('Delete', destructive: true, onPressed: _none),
        ],
        child: MinimalListTile(title: 'Morning run', meta: '12d'),
      ),
    ),
    _live(
      'RefreshIndicator',
      (_) => MinimalRefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          shrinkWrap: true,
          children: const [
            MinimalListTile(title: 'Ana Souza', meta: '09:32'),
            MinimalListTile(title: 'Ben Okafor', meta: '08:05'),
            MinimalListTile(title: 'Hanna Berg', meta: '07:40'),
          ],
        ),
      ),
    ),
    _live(
      'TreeView',
      (_) => MinimalTreeView<_Node>(
        roots: _files,
        childrenOf: (n) => n.children,
        labelOf: (n) => n.name,
      ),
    ),
    _live(
      'Timeline',
      (_) => MinimalTimeline(
        entries: [
          MinimalActivity(
            at: DateTime(2026, 3, 12, 7, 12),
            actor: 'Ana',
            text: 'marked it done',
            tone: MinimalTone.success,
          ),
          // Every event on the rail: a dot on the first alone reads as an
          // unread flag.
          MinimalActivity(
            at: DateTime(2026, 3, 11, 20, 15),
            text: 'Reminder moved to',
            figure: '07:00',
            tone: MinimalTone.neutral,
          ),
          MinimalActivity(
            at: DateTime(2026, 3, 10, 9, 2),
            actor: 'Ana',
            text: 'created it',
            tone: MinimalTone.neutral,
          ),
        ],
      ),
    ),
    _live('Avatar', (_) => const MinimalAvatar('Hanna Berg')),
    _live(
      'AvatarGroup',
      // The faces as big as a lone avatar's, so their initials read.
      (_) => const MinimalAvatarGroup([
        'Hanna Berg',
        'Oskar Lind',
        'Ines Duarte',
      ], size: 28),
    ),
    _live(
      'Badge',
      (_) => const MinimalBadge(count: 3, child: MinimalIcon(LucideIcons.bell)),
    ),
    _live('Tag', (_) => const MinimalTag('Bug', dot: MinimalTone.destructive)),
    _live(
      'Media',
      (_) => const MinimalMedia(
        MinimalPlaceholderImage(MinimalMediaKind.food, 0),
        // Under 110 px a stand-in shows its kind's glyph; a large one stays
        // a bare fill.
        width: 96,
        height: 72,
      ),
    ),
    _live(
      'EmptyState',
      (_) => const MinimalEmptyState(
        icon: LucideIcons.inbox,
        title: 'No habits yet',
      ),
    ),
    _live(
      'DescriptionList',
      (_) => const MinimalDescriptionList(
        properties: [
          MinimalProperty(
            icon: LucideIcons.bell,
            label: 'Reminder',
            value: '07:00',
            mono: true,
          ),
        ],
      ),
    ),
    // Overlays
    _live(
      'Dialog',
      (_) => const MinimalDialog(
        title: 'Delete habit?',
        message: 'Its history goes too.',
        confirmLabel: 'Delete',
        cancelLabel: 'Keep',
        destructive: true,
        // It stands for the raised card, so it floats like the sheets.
        elevated: true,
        onConfirm: _none,
        onCancel: _none,
      ),
    ),
    _live(
      'BottomSheet',
      (_) => const MinimalBottomSheet(
        title: 'New habit',
        subtitle: 'Habits',
        leading: MinimalSheetAction('Cancel', onPressed: _none),
        trailing: MinimalSheetAction(
          'Create habit',
          onPressed: _none,
          isDefaultAction: true,
        ),
        child: MinimalTextField(label: 'Name', hint: 'Stretch before bed'),
      ),
    ),
    _live(
      'Sheet',
      (_) => MinimalSheet(
        title: 'Filters',
        onClose: _none,
        trailing: const MinimalSheetAction(
          'Apply',
          onPressed: _none,
          isDefaultAction: true,
        ),
        child: MinimalListTile(
          title: 'Open only',
          // The sheet pads its body; the row adds none of its own.
          padding: EdgeInsets.zero,
          trailing: MinimalSwitch(
            value: true,
            label: 'Open only',
            onChanged: (_) {},
          ),
        ),
      ),
    ),
    _live(
      'ActionSheet',
      (_) => const MinimalActionSheet(
        title: 'Morning run',
        actions: [
          MinimalActionSheetAction(
            'Share',
            icon: LucideIcons.share2,
            onPressed: _none,
          ),
          MinimalActionSheetAction(
            'Archive',
            icon: LucideIcons.archive,
            onPressed: _none,
          ),
          MinimalActionSheetAction(
            'Delete',
            icon: LucideIcons.trash2,
            destructive: true,
            onPressed: _none,
          ),
        ],
        onCancel: _none,
      ),
    ),
    _live(
      'Popover',
      (_) => MinimalPopover(
        anchor: (context, toggle, open) =>
            MinimalButton('Share', onPressed: toggle),
        content: (context, close) => const Text('ritual.app/s/8f2k'),
      ),
    ),
    _live(
      'HoverCard',
      (_) => const MinimalHoverCard(
        card: Text('Ana Souza · Design lead'),
        // A handle is a code: it reads left to right in every language.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MinimalLink('@ana', onPressed: _none),
        ),
      ),
    ),
    _live(
      'Tooltip',
      (_) => const MinimalTooltip(
        message: 'Archive',
        child: MinimalIconButton(
          LucideIcons.archive,
          label: 'Archive',
          onPressed: _none,
        ),
      ),
    ),
    _live(
      'Menu',
      (_) => const MinimalMenu(
        label: 'Habit actions',
        items: [MinimalMenuItem('Rename', onPressed: _none)],
        child: MinimalIcon(LucideIcons.ellipsis),
      ),
    ),
    _live(
      'SnackBar',
      (_) => const MinimalSnackBar('Habit archived', actionLabel: 'Undo'),
    ),
    _live(
      'Banner',
      (_) => const MinimalBanner(
        tone: MinimalTone.warning,
        title: 'Your trial ends Friday',
      ),
    ),
    // Feedback
    _live(
      'LinearProgressIndicator',
      (_) => const MinimalLinearProgressIndicator(value: 0.62, label: 'Upload'),
    ),
    _live(
      'CircularProgressIndicator',
      (_) => const MinimalCircularProgressIndicator(),
    ),
    _live('Skeleton', (_) => const MinimalSkeleton.text(lines: 3)),
    _live(
      'StatusView',
      (_) => const MinimalStatusView.success(title: 'Invite sent'),
    ),
    _live(
      'Meter',
      (_) => const MinimalMeter(label: 'Storage', value: 7.2, max: 10),
    ),
    // Charts
    _live(
      'LineChart',
      (_) => const MinimalLineChart(
        series: [
          MinimalChartSeries('Signups', [3, 5, 4, 8, 7, 9, 12]),
        ],
        labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      ),
    ),
    _live(
      'BarChart',
      // The line chart's week: seven days.
      (_) => const MinimalBarChart(
        [4, 9, 6, 12, 7, 5, 10],
        labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      ),
    ),
    _live(
      'AreaChart',
      (_) => const MinimalAreaChart(
        series: [
          MinimalChartSeries('Revenue', [12, 18, 15, 22]),
        ],
        labels: ['Jan', 'Feb', 'Mar', 'Apr'],
      ),
    ),
    _live(
      'PieChart',
      (_) => const MinimalPieChart(
        slices: [
          MinimalChartSlice('Design', 42),
          MinimalChartSlice('Build', 31),
        ],
      ),
    ),
    _live('Sparkline', (_) => const MinimalSparkline([3, 5, 4, 8, 7])),
  ],
);

/// The height a row's part stands in, for a part that fills the height it
/// is given: a page as tall as its bar and its three rows (no empty band
/// under the last, inside its card's hairline), a side sheet and a split
/// 220. Null for a part that keeps its own height.
double? _heightOf(String id, MinimalThemeData t) => switch (id) {
  'Scaffold' =>
    MinimalChromeMetrics.barHeight + 3 * t.rowHeight + 2 * t.hairline,
  'Sheet' || 'Resizable' => 220,
  _ => null,
};

/// The rows whose part runs the height of its page (a navigation rail, a
/// drawer: their foot is pushed to the bottom): in a list each stands as
/// tall as its own rows, so its rule ends with them and no empty band
/// hangs under them.
const Set<String> _pageTall = {'NavigationRail', 'NavigationDrawer'};

/// The rows whose part has no outline of its own (a page, a split, a
/// scroll region, a palette composed in place): each stands in a card.
const Set<String> _framed = {'Scaffold', 'Resizable', 'ScrollArea', 'Command'};

/// The rows whose part spans the column.
const Set<String> _spans = {'Card', ..._framed};

/// The rows whose part stands at the width its route shows it at, on the
/// column's start: a dialog (340), a side sheet (380), a sheet, an action
/// sheet and a toast (at most 560). Across the column they had read as
/// banners.
double? _ownWidth(String id) => switch (id) {
  'Dialog' => MinimalDialog.maxWidth,
  'Sheet' => 380,
  'BottomSheet' ||
  'ActionSheet' ||
  'SnackBar' => MinimalBottomSheet.centredWidth,
  _ => null,
};

/// The rows whose part floats over a page (a dialog, the sheets): each
/// keeps room for its one soft shadow, so the shadow ends before the next
/// row's name and, on a wide page, inside the column.
const Set<String> _floats = {'Dialog', 'BottomSheet', 'Sheet', 'ActionSheet'};

/// The rows whose part fills its column as a control does (a colour
/// picker): held to a control's measure from a tablet up, as a select is.
const Set<String> _capped = {'ColorPicker'};

/// The rows whose value is a code (a URL): it reads left to right on any
/// page, its add-on before the typed text, while its label keeps the
/// page's start edge.
const Set<String> _codes = {'InputGroup'};

/// The rows whose part stands in a row's own air above its words (a 44 px
/// row or hit target, a setting's row, a month's header band): no gap under
/// their name, so the words stand as near it as a field's label does.
const Set<String> _airAbove = {
  'Select',
  'DatePicker',
  'TimePicker',
  'Breadcrumb',
  'Switch',
  'Calendar',
};

/// The rows whose part keeps a hit target's air under it (radios, a
/// slider's thumb, crumbs): no padding under them, so the next row's name
/// stands no further off than elsewhere.
const Set<String> _airBelow = {
  'RadioGroup',
  'Slider',
  'RangeSlider',
  'Breadcrumb',
  'Switch',
};

/// How far a row's part reaches above its own box: a count on a glyph's
/// corner rides half its 16 px height over it, its ring outside that. The
/// row keeps that much more air under its name, so the count stands as far
/// from the name as any part does.
double _overhangOf(String id, MinimalThemeData t) => switch (id) {
  'Badge' => MinimalSpacing.s8 + t.focusWidth,
  _ => 0,
};

/// What a lone check prints after its square: the words it announces, as a
/// form sets them beside it (the part itself only announces them).
String? _wordsOf(Widget? specimen) =>
    specimen is MinimalCheckbox ? specimen.label : null;

/// [minimalInventory] listed in Minimal's own hand: each group under a
/// section header counting the rows Minimal carries, each row its name in
/// mono over its live specimen (a page in a card as tall as its bar and
/// rows; a split in a card, and a side sheet, in a 220 px band; a scroll
/// area and a palette in a card; a card across the column; a dialog, the
/// sheets and a toast at their own widths; the floating parts with room for
/// their shadow), and the gap's reason in
/// place of one.
///
/// A page to see every part at once, as the gallery's Inventory page and
/// the example's Foundations page show it; it scrolls on its own.
///
/// ```dart
/// MinimalInventoryGallery(padding: EdgeInsets.all(MinimalSpacing.s16))
/// ```
class MinimalInventoryGallery extends StatelessWidget {
  /// The inventory as one scrolling list.
  const MinimalInventoryGallery({
    super.key,
    this.padding = EdgeInsets.zero,
    this.controller,
  });

  /// Space round the list.
  final EdgeInsetsGeometry padding;

  /// Its scroll position.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return DesignInventoryGallery(
      inventory: minimalInventory,
      padding: padding,
      controller: controller,
      // On the rows' keyline (the gallery pads the page already), with the
      // header band's own air above and a little more below.
      groupBuilder: (context, group, live, total) => Padding(
        padding: const EdgeInsets.only(
          top: MinimalSpacing.s8,
          bottom: MinimalSpacing.s4,
        ),
        child: MinimalSectionHeader(
          group,
          count: '$live/$total',
          padding: MinimalSectionHeader.inset.copyWith(left: 0, right: 0),
        ),
      ),
      rowBuilder: (context, row, entry, specimen) {
        var part = specimen == null || !_framed.contains(row.id)
            ? specimen
            : MinimalCard(
                // The palette keeps a little air round its field and rows;
                // the others run to the card's hairline, inside it, so the
                // rim shows all round (a page's bar would cover it).
                padding: row.id == 'Command'
                    ? MinimalInsets.all8
                    : EdgeInsets.all(t.hairline),
                child: specimen,
              );
        final words = _wordsOf(specimen);
        if (part != null && words != null) {
          part = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              part,
              const MinimalGap(MinimalChromeMetrics.rowIconGap),
              // The check announces them already.
              ExcludeSemantics(
                child: Text(words, style: t.body.c(t.foreground)),
              ),
            ],
          );
        }
        if (part != null && _codes.contains(row.id)) {
          final rtl = Directionality.of(context) == TextDirection.rtl;
          part = DefaultTextStyle.merge(
            // The label aligns by this, set as the page reads.
            textAlign: rtl ? TextAlign.right : TextAlign.left,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: part,
            ),
          );
        }
        if (part != null && _capped.contains(row.id)) {
          part = MinimalLayout.capControl(context, part);
        }
        if (part != null && _pageTall.contains(row.id)) {
          part = IntrinsicHeight(child: part);
        }
        final height = _heightOf(row.id, t);
        final own = _ownWidth(row.id);
        Widget? placed = part == null
            ? null
            : own != null
            ? Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(width: own, height: height, child: part),
              )
            : _spans.contains(row.id)
            ? SizedBox(height: height, child: part)
            // A rail or a drawer stands at its own width, on the start.
            : Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(height: height, child: part),
              );
        final overhang = _overhangOf(row.id, t);
        if (placed != null && overhang > 0) {
          placed = Padding(
            padding: EdgeInsets.only(top: overhang),
            child: placed,
          );
        }
        if (placed != null && _floats.contains(row.id)) {
          // The large shadow runs about 40 px out each side and 60 below.
          final side = MinimalLayout.isCompact(context)
              ? 0.0
              : MinimalSpacing.s40;
          placed = Padding(
            padding: EdgeInsets.fromLTRB(side, 0, side, MinimalSpacing.s48),
            child: placed,
          );
        }
        return Padding(
          padding: EdgeInsets.only(
            top: MinimalSpacing.s8,
            bottom: _airBelow.contains(row.id) ? 0 : MinimalSpacing.s8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The row's name only: a specimen's runtimeType is minified in
              // a release build ("minified:kD").
              Text(row.name, style: t.mono.c(t.mutedForeground)),
              if (!_airAbove.contains(row.id))
                const MinimalGap(MinimalSpacing.s8),
              placed ??
                  Text(
                    DesignInventory.absentLabel(entry?.absentReason ?? ''),
                    style: t.bodySmall.c(t.textTertiary),
                  ),
            ],
          ),
        );
      },
    );
  }
}
