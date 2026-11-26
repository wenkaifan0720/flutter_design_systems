/// Keycap's answer to the shared component list (ui_core's
/// [RawInventoryRow.all]): for each row the part that answers it, as a
/// small live specimen, or why a keyboard leaves it out. The gallery lists
/// it, and a test verifies it (every row answered once, no reason a
/// to-do).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'actions.dart';
import 'button.dart';
import 'charts.dart';
import 'choices.dart';
import 'containers.dart';
import 'dates.dart';
import 'display.dart';
import 'feedback.dart';
import 'fields.dart';
import 'lists.dart';
import 'menus.dart';
import 'navigation.dart';
import 'overlays.dart';
import 'pickers.dart';
import 'select.dart';
import 'sheets.dart';
import 'sliders.dart';
import 'text_field.dart';
import 'theme.dart';
import 'wayfinding.dart';

// The inventory's own types, so an app (and the gallery) can list and
// verify keycapInventory through the look's barrel.
export 'package:ui_core/inventory.dart'
    show RawInventory, RawInventoryEntry, RawInventoryGallery, RawInventoryRow;

void _none() {}

/// [key] with the platform's main modifier: Cmd on Apple's, Ctrl elsewhere.
SingleActivator _primary(LogicalKeyboardKey key) {
  final apple = switch (defaultTargetPlatform) {
    TargetPlatform.macOS || TargetPlatform.iOS => true,
    _ => false,
  };
  return SingleActivator(key, meta: apple, control: !apple);
}

/// [_primary]'s shortcut as the platform writes it, in words (Rubik draws
/// no ⌘).
String _label(BuildContext context, LogicalKeyboardKey key) =>
    rawShortcutLabel(context, _primary(key), appleSymbols: false);

/// A value a specimen holds and changes, so it can be worked.
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

/// A specimen that owns a controller and gives it back when the gallery
/// lets the row go.
class _Owned<C extends ChangeNotifier> extends StatefulWidget {
  const _Owned(this.make, this.builder);

  final C Function() make;
  final Widget Function(BuildContext context, C controller) builder;

  @override
  State<_Owned<C>> createState() => _OwnedState<C>();
}

class _OwnedState<C extends ChangeNotifier> extends State<_Owned<C>> {
  late final C _controller = widget.make();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

/// A scroll specimen's own controller.
class _Scrolled extends StatefulWidget {
  const _Scrolled();

  @override
  State<_Scrolled> createState() => _ScrolledState();
}

class _ScrolledState extends State<_Scrolled> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeycapScrollArea(
    controller: _controller,
    semanticLabel: 'Notes',
    child: ListView(
      controller: _controller,
      children: [
        for (final title in const [
          'Garden plan',
          'Reading list',
          'Train times',
          'Recipe: dal',
          'Gift ideas',
          'Bike repairs',
          'Quotes',
          'Packing list',
          'Meeting notes',
          'Book club',
        ])
          KeycapListTile(title: title),
      ],
    ),
  );
}

const _places = [
  KeycapDestination(icon: LucideIcons.notebookPen, label: 'Notes'),
  KeycapDestination(icon: LucideIcons.folder, label: 'Folders'),
  KeycapDestination(icon: LucideIcons.search, label: 'Search'),
  KeycapDestination(icon: LucideIcons.settings, label: 'Settings'),
];

typedef _Note = ({String title, int words});

const _notes = <_Note>[
  (title: 'Garden plan', words: 412),
  (title: 'Reading list', words: 180),
  (title: 'Train times', words: 96),
];

/// The specimens that fill the height they are given; a gallery frames
/// each in a box of this height.
const Map<String, double> keycapInventoryHeights = {
  'NavigationRail': 320,
  'NavigationDrawer': 320,
  'Scaffold': 360,
  'Resizable': 160,
  'ScrollArea': 200,
  'RefreshIndicator': 200,
  'Sheet': 320,
};

/// Why a keyboard leaves a row out.
abstract final class _Why {
  static const fab =
      'A floating action button is Material vocabulary; a keyboard has no '
      'key hovering over the others. The one main action is the accent key '
      'in the top bar or the screen foot (KeycapButton.accent)';
}

/// Keycap's inventory: every row of the shared component list, answered.
final RawInventory keycapInventory = RawInventory(
  look: 'Keycap',
  entries: [
    // Actions
    RawInventoryEntry.present(
      'Button',
      (_) => const Wrap(
        spacing: KeycapSpacing.small,
        runSpacing: KeycapSpacing.small,
        children: [
          KeycapButton.accent(onPressed: _none, child: Text('Save')),
          KeycapButton(onPressed: _none, child: Text('Cancel')),
          KeycapButton.modifier(onPressed: _none, child: Text('Shift')),
          KeycapButton.text(onPressed: _none, child: Text('Skip')),
          KeycapButton(
            onPressed: _none,
            isDestructiveAction: true,
            child: Text('Delete'),
          ),
          KeycapButton.accent(
            onPressed: _none,
            isDestructiveAction: true,
            child: Text('Delete note'),
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'IconButton',
      (_) => const KeycapIconButton(
        icon: Icon(LucideIcons.pin),
        semanticLabel: 'Pin',
        onPressed: _none,
      ),
    ),
    const RawInventoryEntry.absent('FloatingActionButton', _Why.fab),
    RawInventoryEntry.present(
      'ButtonGroup',
      (_) => const KeycapToolbar(
        semanticLabel: 'Text',
        children: [
          KeycapIconButton(
            icon: Icon(LucideIcons.bold),
            semanticLabel: 'Bold',
            onPressed: _none,
          ),
          KeycapIconButton(
            icon: Icon(LucideIcons.italic),
            semanticLabel: 'Italic',
            onPressed: _none,
          ),
          KeycapIconButton(
            icon: Icon(LucideIcons.list),
            semanticLabel: 'List',
            onPressed: _none,
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'ToggleGroup',
      (_) => _Held<Set<String>>(
        const {'bold'},
        (context, on, set) => KeycapToggleGroup<String>(
          semanticLabel: 'Format',
          options: const [
            KeycapToggleOption(
              value: 'bold',
              icon: LucideIcons.bold,
              semanticLabel: 'Bold',
            ),
            KeycapToggleOption(
              value: 'italic',
              icon: LucideIcons.italic,
              semanticLabel: 'Italic',
            ),
            KeycapToggleOption(
              value: 'strike',
              icon: LucideIcons.strikethrough,
              semanticLabel: 'Strikethrough',
            ),
          ],
          selected: on,
          onSelectionChanged: set,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'SplitButton',
      (_) => const KeycapSplitButton(
        label: 'Export',
        onPressed: _none,
        menuLabel: 'More ways to export',
        actions: [
          RawSplitAction(label: 'Export as PDF', onPressed: _none),
          RawSplitAction(label: 'Export as text', onPressed: _none),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Link',
      (_) => const KeycapLink(onPressed: _none, child: Text('Formatting help')),
    ),
    RawInventoryEntry.present(
      'Kbd',
      (_) => KeycapKbd.shortcut(_primary(LogicalKeyboardKey.keyK)),
    ),
    // Inputs
    RawInventoryEntry.present(
      'TextField',
      (_) => const KeycapTextField(labelText: 'Title', hintText: 'Garden plan'),
    ),
    RawInventoryEntry.present(
      'TextArea',
      (_) => const KeycapTextField(
        labelText: 'Note',
        hintText: 'Start writing',
        maxLines: 4,
        minLines: 3,
      ),
    ),
    RawInventoryEntry.present(
      'SearchField',
      (_) => const KeycapSearchField(hintText: 'Search notes'),
    ),
    RawInventoryEntry.present(
      'PasswordField',
      (_) => const KeycapPasswordField(labelText: 'Password'),
    ),
    RawInventoryEntry.present(
      'InputGroup',
      (_) => const KeycapInputGroup(
        labelText: 'Address',
        prefixText: 'https://',
        suffixText: '.notes',
      ),
    ),
    RawInventoryEntry.present(
      'InputOtp',
      (_) => const KeycapOtpField(semanticLabel: 'Sign-in code'),
    ),
    RawInventoryEntry.present(
      'NumberField',
      (_) => _Held<double?>(
        14,
        (context, n, set) => KeycapStepper(
          value: n,
          min: 10,
          max: 28,
          onChanged: set,
          semanticLabel: 'Text size',
          unit: 'pt',
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Select',
      (_) => _Held<String>(
        'edited',
        (context, v, set) => KeycapSelect<String>(
          labelText: 'Sort by',
          value: v,
          onChanged: set,
          items: const [
            KeycapSelectItem(value: 'edited', label: 'Last edited'),
            KeycapSelectItem(value: 'created', label: 'Created'),
            KeycapSelectItem(value: 'title', label: 'Title'),
          ],
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Combobox',
      (_) => _Held<String?>(
        null,
        (context, v, set) => KeycapCombobox<String>(
          labelText: 'Folder',
          value: v,
          onSelected: set,
          options: const ['Work', 'Home', 'Ideas', 'Travel', 'Recipes'],
        ),
      ),
    ),
    RawInventoryEntry.present(
      'MultiSelect',
      (_) => _Held<List<String>>(
        const ['garden'],
        (context, v, set) => KeycapTagInput<String>(
          labelText: 'Tags',
          values: v,
          onChanged: set,
          options: const ['garden', 'spring', 'to buy', 'ideas'],
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Checkbox',
      (_) => _Held<bool>(
        true,
        (context, v, set) => KeycapCheckbox(
          value: v,
          onChanged: (n) => set(n ?? false),
          semanticLabel: 'Sow the beans',
        ),
      ),
    ),
    RawInventoryEntry.present(
      'RadioGroup',
      (_) => _Held<String>(
        'list',
        (context, v, set) => KeycapRadioGroup<String>(
          options: const ['list', 'grid'],
          groupValue: v,
          labelOf: (value) => value == 'grid' ? 'Grid' : 'List',
          semanticLabel: 'Layout',
          onChanged: set,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Switch',
      (_) => _Held<bool>(
        true,
        (context, v, set) =>
            KeycapSwitch(value: v, onChanged: set, semanticLabel: 'Sync'),
      ),
    ),
    RawInventoryEntry.present(
      'Slider',
      (_) => _Held<double>(
        0.4,
        (context, v, set) => KeycapSlider(
          value: v,
          onChanged: set,
          semanticLabel: 'Line spacing',
          valueText: (value) => '${(value * 100).round()}%',
        ),
      ),
    ),
    RawInventoryEntry.present(
      'RangeSlider',
      (_) => _Held<RawRangeValues>(
        const RawRangeValues(200, 800),
        (context, v, set) => KeycapRangeSlider(
          values: v,
          onChanged: set,
          max: 1000,
          startLabel: 'Fewest words',
          endLabel: 'Most words',
          semanticFormatterCallback: (value) => '${value.round()} words',
        ),
      ),
    ),
    RawInventoryEntry.present(
      'SegmentedButton',
      (_) => _Held<Set<String>>(
        const {'list'},
        (context, v, set) => KeycapSegmentedButton<String>(
          segments: const [
            KeycapSegment(value: 'list', label: 'List'),
            KeycapSegment(value: 'grid', label: 'Grid'),
          ],
          selected: v,
          onSelectionChanged: set,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Chip',
      (_) => _Held<bool>(
        true,
        (context, v, set) => Wrap(
          spacing: KeycapSpacing.small,
          children: [
            KeycapChip('Pinned', selected: v, onSelected: set),
            const KeycapChip('garden', onDeleted: _none),
          ],
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Rating',
      (_) => _Held<double>(
        4,
        (context, v, set) =>
            KeycapRating(value: v, onChanged: set, semanticLabel: 'How useful'),
      ),
    ),
    RawInventoryEntry.present(
      'FileUpload',
      (_) => const KeycapDropZone(
        label: 'Drop a file to attach',
        hint: 'Images or PDFs, up to 10 MB',
        icon: LucideIcons.paperclip,
        onPressed: _none,
      ),
    ),
    RawInventoryEntry.present(
      'DatePicker',
      (_) => _Held<DateTime?>(
        DateTime(2026, 11, 20),
        (context, v, set) => KeycapDatePicker(
          labelText: 'Remind me on',
          value: v,
          firstDate: DateTime(2026, 11, 16),
          lastDate: DateTime(2027, 2, 28),
          currentDate: DateTime(2026, 11, 16),
          onChanged: set,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'DateRangePicker',
      (_) => _Held<RawDateRange?>(
        RawDateRange(DateTime(2026, 12, 20), DateTime(2026, 12, 28)),
        (context, v, set) => KeycapDateRangePicker(
          labelText: 'Trip',
          value: v,
          firstDate: DateTime(2026, 11, 16),
          lastDate: DateTime(2027, 2, 28),
          currentDate: DateTime(2026, 11, 16),
          onChanged: set,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'TimePicker',
      (_) => _Held<RawTimeOfDay?>(
        const RawTimeOfDay(hour: 9, minute: 30),
        (context, v, set) =>
            KeycapTimePicker(labelText: 'At', value: v, onChanged: set),
      ),
    ),
    RawInventoryEntry.present(
      'Calendar',
      (_) => _Owned<RawCalendarController>(
        () => RawCalendarController(
          firstDate: DateTime(2026, 11),
          lastDate: DateTime(2027, 3, 31),
          selectedDate: DateTime(2026, 11, 20),
          currentDate: DateTime(2026, 11, 16),
        ),
        (context, c) => SizedBox(
          width: 7 * RawTapTargets.of(context).touch.width,
          child: KeycapCalendar(controller: c),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'WheelPicker',
      (_) => _Held<List<int>>(
        const [2],
        (context, v, set) => KeycapWheelPicker(
          semanticLabel: 'Remind me',
          selection: v,
          onChanged: set,
          columns: (_) => [
            RawPickerColumn(
              itemCount: 5,
              itemLabel: (i) => const [
                'At the time',
                '5 minutes before',
                '15 minutes before',
                '1 hour before',
                '1 day before',
              ][i],
              semanticLabel: 'When',
            ),
          ],
        ),
      ),
    ),
    RawInventoryEntry.present(
      'ColorPicker',
      (_) => _Owned<RawColorController>(
        () => RawColorController(const Color(0xFF2F59CF)),
        (context, c) =>
            SizedBox(width: 280, child: KeycapColorPicker(controller: c)),
      ),
    ),
    RawInventoryEntry.present(
      'FormField',
      (_) => const KeycapField(
        labelText: 'Folder name',
        helperText: 'Shown in the sidebar',
        required: true,
        child: KeycapTextField(semanticLabel: 'Folder name'),
      ),
    ),
    // Navigation
    RawInventoryEntry.present(
      'AppBar',
      (_) => const KeycapAppBar(title: 'Garden plan', onBack: _none),
    ),
    RawInventoryEntry.present(
      'NavigationBar',
      (_) => _Held<int>(
        0,
        (context, i, set) => KeycapNavigationBar(
          destinations: _places,
          selectedIndex: i,
          onDestinationSelected: set,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'NavigationRail',
      (_) => _Held<int>(
        0,
        (context, i, set) => KeycapNavigationRail(
          destinations: _places,
          selectedIndex: i,
          onDestinationSelected: set,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'NavigationDrawer',
      (_) => _Held<int>(
        0,
        (context, i, set) => KeycapSideNavigation(
          destinations: _places,
          selectedIndex: i,
          onDestinationSelected: set,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'TabBar',
      (_) => _Held<String>(
        'all',
        (context, v, set) => KeycapTabBar<String>(
          tabs: const [
            KeycapSegment(value: 'all', label: 'All'),
            KeycapSegment(value: 'pinned', label: 'Pinned'),
            KeycapSegment(value: 'shared', label: 'Shared'),
          ],
          value: v,
          onChanged: set,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Breadcrumb',
      (_) => const KeycapBreadcrumb(
        crumbs: [
          KeycapCrumb('Folders', onPressed: _none),
          KeycapCrumb('Home', onPressed: _none),
          KeycapCrumb('Garden plan'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Pagination',
      (_) => _Held<int>(
        3,
        (context, p, set) =>
            KeycapPagination(page: p, pageCount: 9, onPageChanged: set),
      ),
    ),
    RawInventoryEntry.present(
      'StepProgress',
      (_) => const KeycapStepProgress(
        steps: ['Account', 'Folders', 'Sync', 'Done'],
        currentStep: 1,
      ),
    ),
    RawInventoryEntry.present(
      'PageDots',
      (_) => _Held<int>(
        1,
        (context, i, set) =>
            KeycapPageDots(pageCount: 4, page: i, onPageChanged: set),
      ),
    ),
    RawInventoryEntry.present(
      'MenuBar',
      (context) => KeycapMenuBar(
        menus: [
          RawMenuEntry(
            label: 'File',
            children: [
              RawMenuEntry(
                label: 'New note',
                shortcut: _label(context, LogicalKeyboardKey.keyN),
                onPressed: _none,
              ),
              const RawMenuEntry(label: 'Export', onPressed: _none),
            ],
          ),
          const RawMenuEntry(
            label: 'View',
            children: [
              RawMenuEntry(
                label: 'Show word count',
                checked: true,
                onPressed: _none,
              ),
            ],
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Command',
      (context) => SizedBox(
        width: 340,
        child: KeycapCommandPalette(
          maxHeight: 200,
          commands: [
            RawCommand(
              label: 'New note',
              group: 'Notes',
              shortcut: _label(context, LogicalKeyboardKey.keyN),
              onPressed: _none,
            ),
            const RawCommand(
              label: 'Open Folders',
              group: 'Go to',
              onPressed: _none,
            ),
            const RawCommand(
              label: 'Settings',
              group: 'Go to',
              onPressed: _none,
            ),
          ],
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Scaffold',
      (_) => _Held<int>(
        0,
        (context, i, set) => KeycapScaffold(
          destinations: _places,
          selectedIndex: i,
          onDestinationSelected: set,
          body: Center(child: Text(_places[i].label)),
        ),
      ),
    ),
    // Containers
    RawInventoryEntry.present(
      'Card',
      (_) =>
          const KeycapCard(child: Text('Sow the beans after the last frost.')),
    ),
    RawInventoryEntry.present(
      'ListTile',
      (_) => const KeycapListTile(
        title: 'Garden plan',
        subtitle: 'Sow the beans after the last frost',
        onTap: _none,
      ),
    ),
    RawInventoryEntry.present(
      'ListSection',
      (_) => const KeycapListGroup(
        header: 'Account',
        children: [
          KeycapListTile(title: 'Profile', onTap: _none),
          KeycapListTile(title: 'Sync', trailingText: 'On', onTap: _none),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'SectionHeader',
      (_) => const KeycapSectionHeader('Pinned'),
    ),
    RawInventoryEntry.present(
      'Disclosure',
      (_) => const KeycapDisclosure(
        title: 'Formatting',
        child: Text('Start a line with a dash to make a list.'),
      ),
    ),
    RawInventoryEntry.present(
      'Table',
      (_) => const KeycapTable(
        columns: [
          KeycapTableColumn('Note', flex: 2),
          KeycapTableColumn('Words', numeric: true),
        ],
        rows: [
          ['Garden plan', '412'],
          ['Reading list', '180'],
        ],
      ),
    ),
    RawInventoryEntry.present(
      'DataTable',
      (_) => _Owned<RawDataTableController<_Note>>(
        () => RawDataTableController<_Note>(
          rows: _notes,
          columns: [
            RawDataColumn<_Note>(
              id: 'title',
              label: 'Note',
              sortKey: (n) => n.title,
            ),
            RawDataColumn<_Note>(
              id: 'words',
              label: 'Words',
              numeric: true,
              sortKey: (n) => n.words,
            ),
          ],
        ),
        (context, c) => KeycapDataTable<_Note>(
          controller: c,
          rowLabel: (n) => n.title,
          cellText: (n, column) =>
              column.id == 'words' ? '${n.words}' : n.title,
        ),
      ),
    ),
    RawInventoryEntry.present('Divider', (_) => const KeycapDivider()),
    RawInventoryEntry.present('ScrollArea', (_) => const _Scrolled()),
    RawInventoryEntry.present(
      'Resizable',
      (_) => const KeycapSplitView(
        minFirst: 80,
        minSecond: 80,
        first: Center(child: Text('Notes')),
        second: Center(child: Text('Garden plan')),
      ),
    ),
    RawInventoryEntry.present(
      'CarouselView',
      (_) => KeycapCarousel(
        itemCount: 3,
        height: 140,
        semanticLabel: 'Tips',
        itemBuilder: (context, i) => Center(
          child: Text(const ['Pin a note', 'Tag a note', 'Share a note'][i]),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'ReorderableListView',
      (_) => _Held<List<String>>(
        const ['Work', 'Home', 'Ideas'],
        (context, items, set) => KeycapReorderableList<String>(
          items: items,
          title: (i) => i,
          onReorder: (from, to) {
            final next = [...items];
            final moved = next.removeAt(from);
            next.insert(to > from ? to - 1 : to, moved);
            set(next);
          },
        ),
      ),
    ),
    RawInventoryEntry.present(
      'SwipeActions',
      (_) => const KeycapSwipeActions(
        endActions: [
          RawSwipeAction(label: 'Delete', destructive: true, onPressed: _none),
        ],
        child: KeycapListTile(title: 'Train times', trailingText: '96 words'),
      ),
    ),
    RawInventoryEntry.present(
      'RefreshIndicator',
      (_) => KeycapRefresh(
        onRefresh: () => Future<void>.delayed(const Duration(seconds: 1)),
        child: ListView(
          children: const [
            KeycapListTile(title: 'Garden plan'),
            KeycapListTile(title: 'Reading list'),
          ],
        ),
      ),
    ),
    RawInventoryEntry.present(
      'TreeView',
      (_) => _Owned<RawTreeController<String>>(
        () => RawTreeController<String>(
          roots: const ['Home', 'Work'],
          expanded: const ['Home'],
          childrenOf: (node) => switch (node) {
            'Home' => const ['Garden', 'Recipes'],
            'Work' => const ['Meetings'],
            _ => const [],
          },
        ),
        (context, c) => KeycapTree<String>(controller: c, labelOf: (n) => n),
      ),
    ),
    RawInventoryEntry.present(
      'Timeline',
      (_) => const KeycapTimeline(
        entries: [
          KeycapTimelineEntry(title: 'Created', time: 'Mon 09:40'),
          KeycapTimelineEntry(title: 'Shared with Sam', time: 'Mon 14:05'),
          KeycapTimelineEntry(
            title: 'Editing',
            detail: 'Sam is adding the spring beds',
            state: KeycapTimelineState.current,
          ),
          KeycapTimelineEntry(
            title: 'Reminder',
            state: KeycapTimelineState.upcoming,
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Avatar',
      (_) => const KeycapAvatar(name: 'Ada Brook'),
    ),
    RawInventoryEntry.present(
      'AvatarGroup',
      (_) => const KeycapAvatarGroup(
        names: ['Ada Brook', 'Sam Lee', 'Kit Ward', 'Jo Hart', 'Ravi Shah'],
      ),
    ),
    RawInventoryEntry.present('Badge', (_) => const KeycapBadge(count: 3)),
    RawInventoryEntry.present(
      'Tag',
      (_) => const Wrap(
        spacing: KeycapSpacing.small,
        children: [
          KeycapTag('Synced', tone: KeycapTone.success),
          KeycapTag('Shared', tone: KeycapTone.info),
          KeycapTag('Draft'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Media',
      (_) => const SizedBox(
        width: 240,
        child: KeycapMedia(
          slotId: 'keycap_garden',
          semanticLabel: 'Seedlings in a tray',
          aspectRatio: 4 / 3,
          placeholder: Icon(LucideIcons.image),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'EmptyState',
      (_) => const KeycapEmptyState(
        title: 'No notes yet',
        message: 'Notes you write stand here, newest first.',
        icon: LucideIcons.notebookPen,
        action: KeycapButton.accent(onPressed: _none, child: Text('New note')),
      ),
    ),
    RawInventoryEntry.present(
      'DescriptionList',
      (_) => const KeycapDescriptionList(
        items: [
          (term: 'Words', value: '412'),
          (term: 'Folder', value: 'Home'),
          (term: 'Edited', value: 'Today, 09:40'),
        ],
      ),
    ),
    // Overlays
    RawInventoryEntry.present(
      'Dialog',
      (_) => const KeycapDialog(
        title: 'Delete this note?',
        content: Text('Garden plan goes to Recently deleted for 30 days.'),
        actions: [
          KeycapButton(onPressed: _none, child: Text('Keep')),
          KeycapButton.accent(
            onPressed: _none,
            isDestructiveAction: true,
            child: Text('Delete'),
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'BottomSheet',
      (_) => const KeycapSheet(
        title: 'Sort',
        onClose: _none,
        child: Text('Last edited first'),
      ),
    ),
    RawInventoryEntry.present(
      'Sheet',
      (_) => const SizedBox(
        width: 300,
        child: KeycapSideSheet(
          title: 'Details',
          onClose: _none,
          child: Text('412 words, edited today'),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'ActionSheet',
      (_) => const KeycapActionSheet(
        title: 'Garden plan',
        onCancel: _none,
        actions: [
          KeycapSheetAction('Duplicate', onPressed: _none),
          KeycapSheetAction(
            'Delete',
            isDestructiveAction: true,
            onPressed: _none,
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Popover',
      (_) => KeycapPopover(
        semanticLabel: 'Word count',
        builder: (context, anchor) =>
            KeycapButton(onPressed: anchor.toggle, child: const Text('Count')),
        content: (context, close) => const Text('412 words, 2,301 letters'),
      ),
    ),
    RawInventoryEntry.present(
      'HoverCard',
      (_) => KeycapHoverCard(
        card: (context) => const Text('Ada Brook, editing since Monday'),
        child: const KeycapLink(onPressed: _none, child: Text('Ada')),
      ),
    ),
    RawInventoryEntry.present(
      'Tooltip',
      (_) => const KeycapTooltip(
        message: 'Pin to the top',
        child: KeycapIconButton(
          icon: Icon(LucideIcons.pin),
          semanticLabel: 'Pin',
          onPressed: _none,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Menu',
      (_) => KeycapMenu(
        semanticLabel: 'Note',
        entries: const [
          RawMenuEntry(label: 'Pin', onPressed: _none),
          RawMenuEntry(label: 'Move', onPressed: _none),
          RawMenuEntry.divider(),
          RawMenuEntry(
            label: 'Delete',
            isDestructiveAction: true,
            onPressed: _none,
          ),
        ],
        builder: (context, anchor) => KeycapIconButton(
          icon: const Icon(LucideIcons.ellipsis),
          semanticLabel: 'More',
          onPressed: anchor.toggle,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'SnackBar',
      (context) => KeycapButton(
        onPressed: () => showKeycapToast(
          context,
          'Note moved to Work',
          actionLabel: 'Undo',
          onAction: _none,
        ),
        child: const Text('Move a note'),
      ),
    ),
    RawInventoryEntry.present(
      'Banner',
      (_) => const KeycapBanner(
        title: 'Offline',
        message: 'Changes sync when you are back online.',
        actions: [KeycapButton.text(onPressed: _none, child: Text('Retry'))],
        onDismissed: _none,
      ),
    ),
    // Feedback
    RawInventoryEntry.present(
      'LinearProgressIndicator',
      (_) => const KeycapProgressBar(value: 0.4, semanticLabel: 'Exporting'),
    ),
    RawInventoryEntry.present(
      'CircularProgressIndicator',
      (_) => const KeycapSpinner(semanticLabel: 'Syncing'),
    ),
    RawInventoryEntry.present(
      'Skeleton',
      (_) => const Row(
        children: [
          KeycapSkeleton(width: 40, height: 40, radius: 10),
          SizedBox(width: KeycapSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeycapSkeleton(width: 160, height: 14),
                SizedBox(height: KeycapSpacing.small),
                KeycapSkeleton(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'StatusView',
      (_) => const KeycapStatusView(
        status: KeycapStatus.error,
        title: 'Couldn’t sync',
        message: 'Your notes are safe on this device.',
        action: KeycapButton.accent(onPressed: _none, child: Text('Try again')),
      ),
    ),
    RawInventoryEntry.present(
      'Meter',
      (_) => const KeycapMeter(
        value: 0.62,
        label: 'Storage',
        valueLabel: '620 of 1,000 MB',
      ),
    ),
    // Charts
    RawInventoryEntry.present(
      'LineChart',
      (_) => const KeycapLineChart(
        semanticLabel: 'Words written by month',
        labels: ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov'],
        series: [
          KeycapChartSeries('This year', [4200, 5800, 5100, 6600, 6100, 7400]),
          KeycapChartSeries('Last year', [3800, 4400, 4900, 4700, 5500, 6000]),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'BarChart',
      (_) => const KeycapBarChart(
        semanticLabel: 'Notes by folder',
        labels: ['Work', 'Home', 'Ideas', 'Travel'],
        series: [
          KeycapChartSeries('Notes', [14, 6, 9, 11]),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'AreaChart',
      (_) => const KeycapAreaChart(
        semanticLabel: 'Notes by week',
        labels: ['W1', 'W2', 'W3', 'W4', 'W5'],
        series: [
          KeycapChartSeries('Notes', [12, 18, 15, 22, 19]),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'PieChart',
      (_) => const KeycapDonutChart(
        semanticLabel: 'Notes by folder',
        centerLabel: 'Notes',
        slices: [('Work', 14), ('Home', 9), ('Ideas', 21)],
      ),
    ),
    RawInventoryEntry.present(
      'Sparkline',
      (_) => const KeycapSparkline(
        values: [3, 5, 4, 7, 6, 9],
        semanticLabel: 'Notes this week, rising',
      ),
    ),
  ],
);
