/// Appliance's answer to the shared component list (ui_core's
/// [DesignInventoryRow.all]): for each row the part that answers it, as a
/// small live specimen, or why a household device leaves it out. The
/// gallery lists it, and a test verifies it (every row answered once, no
/// reason a to-do).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';
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
import 'navigation.dart';
import 'overlays.dart';
import 'pickers.dart';
import 'popovers.dart';
import 'select.dart';
import 'sliders.dart';
import 'text_field.dart';
import 'theme.dart';
import 'wayfinding.dart';

// The inventory's own types, so an app (and the gallery) can list and
// verify applianceInventory through the look's barrel.
export 'package:ui_core/inventory.dart'
    show
        DesignInventory,
        DesignInventoryEntry,
        DesignInventoryGallery,
        DesignInventoryRow;

void _none() {}

/// [key] with the platform's main modifier: Cmd on Apple's, Ctrl elsewhere.
SingleActivator _primary(LogicalKeyboardKey key) {
  final apple = switch (defaultTargetPlatform) {
    TargetPlatform.macOS || TargetPlatform.iOS => true,
    _ => false,
  };
  return SingleActivator(key, meta: apple, control: !apple);
}

/// [_primary]'s shortcut as the platform writes it, in words (Barlow draws
/// no ⌘).
String _label(BuildContext context, LogicalKeyboardKey key) =>
    designShortcutLabel(context, _primary(key), appleSymbols: false);

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
  Widget build(BuildContext context) => ApplianceScrollArea(
    controller: _controller,
    semanticLabel: 'Pantry',
    child: ListView(
      controller: _controller,
      children: [
        for (final item in const [
          'Flour',
          'Oats',
          'Rice',
          'Lentils',
          'Honey',
          'Tea',
          'Coffee',
          'Salt',
          'Pepper',
          'Vinegar',
        ])
          ApplianceListTile(title: item),
      ],
    ),
  );
}

const _places = [
  ApplianceDestination(icon: LucideIcons.house, label: 'Home'),
  ApplianceDestination(icon: LucideIcons.store, label: 'Shop'),
  ApplianceDestination(icon: LucideIcons.shoppingBasket, label: 'Basket'),
  ApplianceDestination(icon: LucideIcons.settings, label: 'Settings'),
];

typedef _Line = ({String item, double price});

const _lines = <_Line>[
  (item: 'Kettle', price: 48),
  (item: 'Toaster', price: 36),
  (item: 'Teapot', price: 22),
];

/// The specimens that fill the height they are given; a gallery frames
/// each in a box of this height.
const Map<String, double> applianceInventoryHeights = {
  'NavigationDrawer': 300,
  'Scaffold': 360,
  'Resizable': 160,
  'ScrollArea': 200,
  'RefreshIndicator': 200,
  'Sheet': 320,
};

/// The words a household device puts where another look puts a control.
abstract final class _Why {
  static const fab =
      'A floating action button is Material vocabulary; an appliance has '
      'one signal key in its panel for the main action '
      '(ApplianceButton.filled), where the hand expects it';
}

/// Appliance's inventory: every row of the shared component list,
/// answered.
final DesignInventory applianceInventory = DesignInventory(
  look: 'Appliance',
  entries: [
    // Actions
    DesignInventoryEntry.present(
      'Button',
      (_) => const ApplianceButton.filled('Start', onPressed: _none),
    ),
    DesignInventoryEntry.present(
      'IconButton',
      (_) => const ApplianceIconButton(
        icon: Icon(LucideIcons.timer),
        semanticLabel: 'Timer',
        onPressed: _none,
      ),
    ),
    const DesignInventoryEntry.absent('FloatingActionButton', _Why.fab),
    DesignInventoryEntry.present(
      'ButtonGroup',
      (_) => const ApplianceToolbar(
        semanticLabel: 'Text',
        children: [
          ApplianceIconButton(
            icon: Icon(LucideIcons.bold),
            semanticLabel: 'Bold',
            onPressed: _none,
          ),
          ApplianceIconButton(
            icon: Icon(LucideIcons.italic),
            semanticLabel: 'Italic',
            onPressed: _none,
          ),
          ApplianceIconButton(
            icon: Icon(LucideIcons.underline),
            semanticLabel: 'Underline',
            onPressed: _none,
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'ToggleGroup',
      (_) => _Held<Set<String>>(
        const {'eco'},
        (context, on, set) => ApplianceToggleGroup<String>(
          semanticLabel: 'Programme',
          options: const [
            ApplianceToggleOption(value: 'eco', label: 'Eco'),
            ApplianceToggleOption(value: 'quick', label: 'Quick'),
            ApplianceToggleOption(value: 'deep', label: 'Deep'),
          ],
          selected: on,
          onSelectionChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'SplitButton',
      (_) => const ApplianceSplitButton(
        label: 'Save',
        onPressed: _none,
        menuLabel: 'More ways to save',
        actions: [
          DesignSplitAction(label: 'Save a copy', onPressed: _none),
          DesignSplitAction(label: 'Save as a template', onPressed: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Link',
      (_) => const ApplianceLink('Delivery and returns', onPressed: _none),
    ),
    DesignInventoryEntry.present(
      'Kbd',
      (_) => ApplianceKbd.shortcut(_primary(LogicalKeyboardKey.keyK)),
    ),
    // Inputs
    DesignInventoryEntry.present(
      'TextField',
      (_) => const ApplianceTextField(label: 'Name', hint: 'Ada Brook'),
    ),
    DesignInventoryEntry.present(
      'TextArea',
      (_) => const ApplianceTextField(
        label: 'Delivery note',
        hint: 'Leave by the back door',
        maxLines: 4,
        minLines: 3,
      ),
    ),
    DesignInventoryEntry.present(
      'SearchField',
      (_) => const ApplianceSearchField(hint: 'Search the shop'),
    ),
    DesignInventoryEntry.present(
      'PasswordField',
      (_) => const AppliancePasswordField(),
    ),
    DesignInventoryEntry.present(
      'InputGroup',
      (_) => const ApplianceInputGroup(
        label: 'Budget',
        prefix: '£',
        suffix: 'a month',
      ),
    ),
    DesignInventoryEntry.present('InputOtp', (_) => const ApplianceOtpField()),
    DesignInventoryEntry.present(
      'NumberField',
      (_) => _Held<int>(
        2,
        (context, n, set) => ApplianceStepper(
          value: n,
          min: 1,
          max: 9,
          onChanged: set,
          semanticLabel: 'Quantity',
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Select',
      (_) => _Held<String>(
        'standard',
        (context, v, set) => ApplianceSelect<String>(
          label: 'Delivery',
          value: v,
          onChanged: set,
          items: const [
            ApplianceSelectItem(value: 'standard', label: 'Standard'),
            ApplianceSelectItem(value: 'next', label: 'Next day'),
            ApplianceSelectItem(value: 'collect', label: 'Collect'),
          ],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Combobox',
      (_) => _Held<String?>(
        null,
        (context, v, set) => ApplianceCombobox<String>(
          label: 'Town',
          value: v,
          onSelected: set,
          options: const ['Leith', 'Portobello', 'Musselburgh', 'Dalkeith'],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'MultiSelect',
      (_) => _Held<List<String>>(
        const ['Kitchen'],
        (context, v, set) => ApplianceTagInput<String>(
          label: 'Rooms',
          values: v,
          onChanged: set,
          options: const ['Kitchen', 'Hall', 'Garden', 'Larder'],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Checkbox',
      (_) => _Held<bool>(
        true,
        (context, v, set) => ApplianceCheckbox(
          value: v,
          onChanged: (n) => set(n ?? false),
          semanticLabel: 'Gift wrap',
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'RadioGroup',
      (_) => _Held<String>(
        'standard',
        (context, v, set) => Semantics(
          container: true,
          label: 'Delivery',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (value, label) in const [
                ('standard', 'Standard'),
                ('next', 'Next day'),
              ])
                ApplianceListTile(
                  title: label,
                  leading: ApplianceRadio<String>(
                    value: value,
                    groupValue: v,
                    onChanged: set,
                    semanticLabel: label,
                  ),
                  onTap: () => set(value),
                ),
            ],
          ),
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Switch',
      (_) => _Held<bool>(
        true,
        (context, v, set) => ApplianceSwitch(
          value: v,
          onChanged: set,
          semanticLabel: 'Order updates',
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Slider',
      (_) => _Held<double>(
        0.4,
        (context, v, set) =>
            ApplianceSlider(value: v, onChanged: set, semanticLabel: 'Volume'),
      ),
    ),
    DesignInventoryEntry.present(
      'RangeSlider',
      (_) => _Held<DesignRangeValues>(
        const DesignRangeValues(20, 60),
        (context, v, set) => ApplianceRangeSlider(
          values: v,
          onChanged: set,
          max: 100,
          startLabel: 'Lowest price',
          endLabel: 'Highest price',
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'SegmentedButton',
      (_) => _Held<String>(
        'grid',
        (context, v, set) => ApplianceSegmentedButton<String>(
          segments: const [
            ApplianceSegment(value: 'grid', label: 'Grid'),
            ApplianceSegment(value: 'list', label: 'List'),
          ],
          value: v,
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Chip',
      (_) => _Held<bool>(
        true,
        (context, v, set) => Wrap(
          spacing: ApplianceSpacing.small,
          children: [
            ApplianceChip('In stock', selected: v, onSelected: set),
            const ApplianceChip('Kettles', onDeleted: _none),
          ],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Rating',
      (_) => _Held<double>(
        4,
        (context, v, set) =>
            ApplianceRating(value: v, onChanged: (n) => set(n.toDouble())),
      ),
    ),
    DesignInventoryEntry.present(
      'FileUpload',
      (_) => const ApplianceDropZone(
        label: 'Drop a photo of the receipt',
        hint: 'PNG or JPG, up to 10 MB',
        icon: Icon(LucideIcons.imageUp),
        onPressed: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'DatePicker',
      (_) => _Held<DateTime?>(
        DateTime(2026, 11, 20),
        (context, v, set) => ApplianceDatePicker(
          label: 'Delivery day',
          value: v,
          firstDate: DateTime(2026, 11, 16),
          lastDate: DateTime(2027, 2, 28),
          currentDate: DateTime(2026, 11, 16),
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'DateRangePicker',
      (_) => _Held<DesignDateRange?>(
        DesignDateRange(DateTime(2026, 12, 20), DateTime(2026, 12, 28)),
        (context, v, set) => ApplianceDateRangePicker(
          label: 'Away',
          value: v,
          firstDate: DateTime(2026, 11, 16),
          lastDate: DateTime(2027, 2, 28),
          currentDate: DateTime(2026, 11, 16),
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'TimePicker',
      (_) => _Held<ApplianceTime>(
        const ApplianceTime(18, 30),
        (context, v, set) => ApplianceTimePicker(value: v, onChanged: set),
      ),
    ),
    DesignInventoryEntry.present(
      'Calendar',
      (_) => _Owned<DesignCalendarController>(
        () => DesignCalendarController(
          firstDate: DateTime(2026, 11),
          lastDate: DateTime(2027, 3, 31),
          selectedDate: DateTime(2026, 11, 20),
          currentDate: DateTime(2026, 11, 16),
        ),
        (context, c) =>
            SizedBox(width: 308, child: ApplianceCalendar(controller: c)),
      ),
    ),
    DesignInventoryEntry.present(
      'WheelPicker',
      (_) => _Held<String>(
        'medium',
        (context, v, set) => ApplianceKnob<String>(
          semanticLabel: 'Browning',
          value: v,
          onChanged: set,
          options: const [
            ApplianceKnobOption(value: 'light', label: 'Light'),
            ApplianceKnobOption(value: 'medium', label: 'Medium'),
            ApplianceKnobOption(value: 'dark', label: 'Dark'),
          ],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'ColorPicker',
      (_) => _Owned<DesignColorController>(
        () => DesignColorController(const Color(0xFFEE6A26)),
        (context, c) =>
            SizedBox(width: 280, child: ApplianceColorPicker(controller: c)),
      ),
    ),
    DesignInventoryEntry.present(
      'FormField',
      (_) => const ApplianceField(
        labelText: 'Postcode',
        helperText: 'For the delivery',
        required: true,
        child: ApplianceTextField(semanticLabel: 'Postcode'),
      ),
    ),
    // Navigation
    DesignInventoryEntry.present(
      'AppBar',
      (_) => const ApplianceAppBar(title: 'Kitchen timer', onBack: _none),
    ),
    DesignInventoryEntry.present(
      'NavigationBar',
      (_) => _Held<int>(
        0,
        (context, i, set) => ApplianceNavigationBar(
          destinations: _places,
          selectedIndex: i,
          onSelected: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationRail',
      (_) => _Held<int>(
        0,
        (context, i, set) => SizedBox(
          height: 300,
          child: ApplianceNavigationRail(
            destinations: _places,
            selectedIndex: i,
            onSelected: set,
          ),
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'NavigationDrawer',
      (_) => _Held<int>(
        0,
        (context, i, set) => ApplianceSideNavigation(
          destinations: _places,
          selectedIndex: i,
          onSelected: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'TabBar',
      (_) => _Held<String>(
        'open',
        (context, v, set) => ApplianceTabBar<String>(
          tabs: const [
            ApplianceSegment(value: 'open', label: 'Open'),
            ApplianceSegment(value: 'past', label: 'Past'),
          ],
          value: v,
          onChanged: set,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Breadcrumb',
      (_) => const ApplianceBreadcrumb(
        crumbs: [
          ApplianceCrumb('Shop', onPressed: _none),
          ApplianceCrumb('Kitchen', onPressed: _none),
          ApplianceCrumb('Kettles'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Pagination',
      (_) => _Held<int>(
        3,
        (context, p, set) =>
            AppliancePagination(page: p, pageCount: 9, onChanged: set),
      ),
    ),
    DesignInventoryEntry.present(
      'StepProgress',
      (_) => const ApplianceStepProgress(
        steps: ['Basket', 'Delivery', 'Payment', 'Done'],
        current: 1,
      ),
    ),
    DesignInventoryEntry.present(
      'PageDots',
      (_) => _Held<int>(
        1,
        (context, i, set) =>
            AppliancePageDots(count: 4, index: i, onChanged: set),
      ),
    ),
    DesignInventoryEntry.present(
      'MenuBar',
      (context) => ApplianceMenuBar(
        menus: [
          DesignMenuEntry(
            label: 'List',
            children: [
              const DesignMenuEntry(label: 'New list', onPressed: _none),
              DesignMenuEntry(
                label: 'Print',
                shortcut: _label(context, LogicalKeyboardKey.keyP),
                onPressed: _none,
              ),
            ],
          ),
          const DesignMenuEntry(
            label: 'View',
            children: [
              DesignMenuEntry(
                label: 'Show prices',
                checked: true,
                onPressed: _none,
              ),
            ],
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Command',
      (context) => SizedBox(
        width: 340,
        child: ApplianceCommandPalette(
          maxHeight: 200,
          commands: [
            const DesignCommand(
              label: 'New list',
              group: 'Lists',
              onPressed: _none,
            ),
            DesignCommand(
              label: 'Open the basket',
              group: 'Go to',
              shortcut: _label(context, LogicalKeyboardKey.keyB),
              onPressed: _none,
            ),
            const DesignCommand(
              label: 'Settings',
              group: 'Go to',
              onPressed: _none,
            ),
          ],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Scaffold',
      (_) => _Held<int>(
        0,
        (context, i, set) => ApplianceScaffold(
          destinations: _places,
          selectedIndex: i,
          onSelected: set,
          body: const Center(child: Text('Home')),
        ),
      ),
    ),
    // Containers
    DesignInventoryEntry.present(
      'Card',
      (_) => const AppliancePanel(child: Text('Descale the kettle monthly.')),
    ),
    DesignInventoryEntry.present(
      'ListTile',
      (_) => const ApplianceListTile(
        title: 'Order updates',
        subtitle: 'When an order ships and arrives',
        onTap: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'ListSection',
      (_) => const ApplianceListGroup(
        header: 'Account',
        children: [
          ApplianceListTile(title: 'Addresses', onTap: _none),
          ApplianceListTile(title: 'Payment', onTap: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'SectionHeader',
      (_) => const ApplianceSectionHeader('Recently viewed'),
    ),
    DesignInventoryEntry.present(
      'Disclosure',
      (_) => const ApplianceDisclosure(
        title: 'Care and cleaning',
        child: Text('Descale monthly; wipe the outside with a damp cloth.'),
      ),
    ),
    DesignInventoryEntry.present(
      'Table',
      (_) => const ApplianceTable(
        columns: [
          ApplianceTableColumn('Item', flex: 2),
          ApplianceTableColumn('Price', numeric: true),
        ],
        rows: [
          ['Kettle', '£48.00'],
          ['Toaster', '£36.00'],
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'DataTable',
      (_) => _Owned<DesignTableController<_Line>>(
        () => DesignTableController<_Line>(
          rows: _lines,
          columns: [
            DesignTableColumn<_Line>(
              id: 'item',
              label: 'Item',
              sortKey: (l) => l.item,
            ),
            DesignTableColumn<_Line>(
              id: 'price',
              label: 'Price',
              numeric: true,
              sortKey: (l) => l.price,
            ),
          ],
        ),
        (context, c) => ApplianceDataTable<_Line>(
          controller: c,
          rowLabel: (l) => l.item,
          cellText: (l, column) =>
              column.id == 'price' ? '£${l.price.toStringAsFixed(2)}' : l.item,
        ),
      ),
    ),
    DesignInventoryEntry.present('Divider', (_) => const ApplianceDivider()),
    DesignInventoryEntry.present('ScrollArea', (_) => const _Scrolled()),
    DesignInventoryEntry.present(
      'Resizable',
      (_) => const ApplianceSplitView(
        minFirst: 80,
        minSecond: 80,
        first: Center(child: Text('Orders')),
        second: Center(child: Text('Order 1042')),
      ),
    ),
    DesignInventoryEntry.present(
      'CarouselView',
      (_) => ApplianceCarousel(
        itemCount: 3,
        height: 140,
        semanticLabel: 'Offers',
        itemBuilder: (context, i) =>
            Center(child: Text(const ['Kettles', 'Toasters', 'Teapots'][i])),
      ),
    ),
    DesignInventoryEntry.present(
      'ReorderableListView',
      (_) => _Held<List<String>>(
        const ['Milk', 'Eggs', 'Bread'],
        (context, items, set) => ApplianceReorderableList<String>(
          items: items,
          labelOf: (i) => i,
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
    DesignInventoryEntry.present(
      'SwipeActions',
      (_) => const ApplianceSwipeActions(
        endActions: [
          DesignSwipeAction(
            label: 'Remove',
            destructive: true,
            onPressed: _none,
          ),
        ],
        child: ApplianceListTile(title: 'Kettle', trailingText: '£48'),
      ),
    ),
    DesignInventoryEntry.present(
      'RefreshIndicator',
      (_) => ApplianceRefresh(
        onRefresh: () => Future<void>.delayed(const Duration(seconds: 1)),
        child: ListView(
          children: const [
            ApplianceListTile(title: 'Order 1042'),
            ApplianceListTile(title: 'Order 1039'),
          ],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'TreeView',
      (_) => _Owned<DesignTreeController<String>>(
        () => DesignTreeController<String>(
          roots: const ['Kitchen', 'Hall'],
          expanded: const ['Kitchen'],
          childrenOf: (node) => switch (node) {
            'Kitchen' => const ['Kettles', 'Toasters'],
            'Hall' => const ['Mats'],
            _ => const [],
          },
        ),
        (context, c) => ApplianceTree<String>(controller: c, labelOf: (n) => n),
      ),
    ),
    DesignInventoryEntry.present(
      'Timeline',
      (_) => const ApplianceTimeline(
        entries: [
          ApplianceTimelineEntry(title: 'Ordered', time: 'Mon 09:40'),
          ApplianceTimelineEntry(title: 'Packed', time: 'Mon 14:05'),
          ApplianceTimelineEntry(
            title: 'Out for delivery',
            detail: 'Due between 10:00 and 12:00',
            state: ApplianceTimelineState.current,
          ),
          ApplianceTimelineEntry(
            title: 'Delivered',
            state: ApplianceTimelineState.upcoming,
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Avatar',
      (_) => const ApplianceAvatar(name: 'Ada Brook'),
    ),
    DesignInventoryEntry.present(
      'AvatarGroup',
      (_) => const ApplianceAvatarGroup(
        names: ['Ada Brook', 'Sam Lee', 'Kit Ward', 'Jo Hart', 'Ravi Shah'],
      ),
    ),
    DesignInventoryEntry.present('Badge', (_) => const ApplianceBadge('3')),
    DesignInventoryEntry.present(
      'Tag',
      (_) => const Wrap(
        spacing: ApplianceSpacing.small,
        children: [
          ApplianceTag('In stock', tone: ApplianceTagTone.ready),
          ApplianceTag('New', tone: ApplianceTagTone.signal),
          ApplianceTag('Discontinued'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Media',
      (_) => const SizedBox(
        width: 240,
        child: ApplianceMedia(
          slotId: 'appliance_kettle',
          semanticLabel: 'A cream kettle',
          aspectRatio: 4 / 3,
          placeholder: Icon(LucideIcons.cookingPot),
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'EmptyState',
      (_) => const ApplianceEmptyState(
        title: 'Your basket is empty',
        message: 'Things you add stand here until you check out.',
        action: ApplianceButton('Browse the shop', onPressed: _none),
      ),
    ),
    DesignInventoryEntry.present(
      'DescriptionList',
      (_) => const ApplianceDescriptionList(
        items: [
          ('Capacity', '1.7 litres'),
          ('Power', '3 kW'),
          ('Warranty', 'Two years'),
        ],
      ),
    ),
    // Overlays
    DesignInventoryEntry.present(
      'Dialog',
      (_) => const ApplianceDialog(
        title: 'Remove this item?',
        content: Text('The kettle leaves your basket.'),
        actions: [
          ApplianceButton('Keep', onPressed: _none),
          ApplianceButton.filled('Remove', onPressed: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'BottomSheet',
      (_) => const ApplianceSheet(
        title: 'Filter',
        onClose: _none,
        child: Text('In stock only'),
      ),
    ),
    DesignInventoryEntry.present(
      'Sheet',
      (_) => const SizedBox(
        width: 300,
        child: ApplianceSideSheet(
          title: 'Filters',
          onClose: _none,
          child: Text('In stock only'),
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'ActionSheet',
      (_) => const ApplianceActionSheet(
        title: 'Order 1042',
        onCancel: _none,
        actions: [
          ApplianceSheetAction('Track the order', onPressed: _none),
          ApplianceSheetAction(
            'Cancel the order',
            destructive: true,
            onPressed: _none,
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Popover',
      (_) => AppliancePopover(
        semanticLabel: 'Delivery note',
        builder: (context, anchor) =>
            ApplianceButton('Delivery note', onPressed: anchor.toggle),
        content: (context, close) =>
            const Text('Leave parcels by the back door.'),
      ),
    ),
    DesignInventoryEntry.present(
      'HoverCard',
      (_) => ApplianceHoverCard(
        card: (context) => const Text('Ships in two days from Leith.'),
        child: const ApplianceLink('Kettle', onPressed: _none),
      ),
    ),
    DesignInventoryEntry.present(
      'Tooltip',
      (_) => const ApplianceTooltip(
        message: 'Keeps warm for 30 minutes',
        child: ApplianceIconButton(
          icon: Icon(LucideIcons.thermometer),
          semanticLabel: 'Keep warm',
          onPressed: _none,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Menu',
      (_) => ApplianceMenu(
        semanticLabel: 'Order',
        entries: [
          const DesignMenuEntry(label: 'Track', onPressed: _none),
          const DesignMenuEntry(label: 'Reorder', onPressed: _none),
          const DesignMenuEntry.divider(),
          const DesignMenuEntry(label: 'Cancel', onPressed: _none),
        ],
        builder: (context, anchor) => ApplianceIconButton(
          icon: const Icon(LucideIcons.ellipsis),
          semanticLabel: 'More',
          onPressed: anchor.toggle,
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'SnackBar',
      (context) => ApplianceButton(
        'Show a toast',
        onPressed: () => showApplianceToast(context, 'Added to the basket'),
      ),
    ),
    DesignInventoryEntry.present(
      'Banner',
      (_) => const ApplianceBanner(
        title: 'Card expiring',
        message: 'Your card on file runs out this month.',
        action: ApplianceButton.text('Update', onPressed: _none),
        onClose: _none,
      ),
    ),
    // Feedback
    DesignInventoryEntry.present(
      'LinearProgressIndicator',
      (_) => const ApplianceProgressBar(value: 0.4, semanticLabel: 'Uploading'),
    ),
    DesignInventoryEntry.present(
      'CircularProgressIndicator',
      (_) => const ApplianceProgressRing(semanticLabel: 'Saving'),
    ),
    DesignInventoryEntry.present(
      'Skeleton',
      (_) => const Row(
        children: [
          ApplianceSkeleton(width: 40, height: 40, circle: true),
          SizedBox(width: ApplianceSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApplianceSkeleton(width: 160, height: 14),
                SizedBox(height: ApplianceSpacing.small),
                ApplianceSkeleton(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'StatusView',
      (_) => const ApplianceStatusView(
        status: ApplianceStatus.error,
        title: 'Payment failed',
        message: 'Your card was declined. Nothing was taken.',
        actions: [ApplianceButton.filled('Try again', onPressed: _none)],
      ),
    ),
    DesignInventoryEntry.present(
      'Meter',
      (_) => const ApplianceMeter(
        value: 0.62,
        label: 'Storage',
        valueText: '6.2 of 10 GB',
      ),
    ),
    // Charts
    DesignInventoryEntry.present(
      'LineChart',
      (_) => ApplianceLineChart(
        semanticLabel: 'Spending by month',
        labels: const ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov'],
        valueText: (v) => '£${v.round()}',
        series: const [
          ApplianceChartSeries('This year', [42, 58, 51, 66, 61, 74]),
          ApplianceChartSeries('Last year', [38, 44, 49, 47, 55, 60]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'BarChart',
      (_) => const ApplianceBarChart(
        semanticLabel: 'Items by room',
        labels: ['Kitchen', 'Hall', 'Garden', 'Larder'],
        series: [
          ApplianceChartSeries('Items', [14, 6, 9, 11]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'AreaChart',
      (_) => const ApplianceAreaChart(
        semanticLabel: 'Orders by week',
        labels: ['W1', 'W2', 'W3', 'W4', 'W5'],
        series: [
          ApplianceChartSeries('Orders', [12, 18, 15, 22, 19]),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'PieChart',
      (_) => const ApplianceDonutChart(
        semanticLabel: 'Spending by room',
        slices: [('Kitchen', 120), ('Hall', 40), ('Garden', 64)],
      ),
    ),
    DesignInventoryEntry.present(
      'Sparkline',
      (_) => const ApplianceSparkline(
        values: [3, 5, 4, 7, 6, 9],
        semanticLabel: 'Orders this week, rising',
      ),
    ),
  ],
);
