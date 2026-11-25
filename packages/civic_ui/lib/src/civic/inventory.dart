// Civic's answer to the shared component inventory (ui_core's
// RawInventoryRow.all): for each row the part that answers it, as a
// small live specimen, or the reason a public service leaves it out. The
// gallery lists it, and a test verifies it (every row answered once, no
// reason a to-do).
import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'components/avatar/avatar.dart';
import 'components/badge/badge.dart';
import 'components/breadcrumbs/breadcrumbs.dart';
import 'components/button-group/button_group.dart';
import 'components/button/button.dart';
import 'components/calendar/calendar.dart';
import 'components/card/card.dart';
import 'components/carousel/carousel.dart';
import 'components/charts/charts.dart';
import 'components/charts/pie_chart.dart';
import 'components/checkbox/checkbox.dart';
import 'components/chip/chip.dart';
import 'components/code-field/code_field.dart';
import 'components/color-picker/color_picker.dart';
import 'components/combobox/combobox.dart';
import 'components/command-palette/command_palette.dart';
import 'components/date-picker/date_picker.dart';
import 'components/details/details.dart';
import 'components/dialog/dialog.dart';
import 'components/empty-state/empty_state.dart';
import 'components/file-upload/file_upload.dart';
import 'components/icon-button/icon_button.dart';
import 'components/image/image.dart';
import 'components/kbd/kbd.dart';
import 'components/link/link.dart';
import 'components/list-row/list_row.dart';
import 'components/menu/menu.dart';
import 'components/meter/meter.dart';
import 'components/multi-select/multi_select.dart';
import 'components/navigation/navigation.dart';
import 'components/number-field/number_field.dart';
import 'components/page-dots/page_dots.dart';
import 'components/pagination/pagination.dart';
import 'components/panel/panel.dart';
import 'components/password-field/password_field.dart';
import 'components/popover/popover.dart';
import 'components/progress-bar/progress_bar.dart';
import 'components/pull-to-refresh/pull_to_refresh.dart';
import 'components/radio/radio.dart';
import 'components/rating/rating.dart';
import 'components/reorderable-list/reorderable_list.dart';
import 'components/scaffold/scaffold.dart';
import 'components/scroll-area/scroll_area.dart';
import 'components/search-field/search_field.dart';
import 'components/section-break/section_break.dart';
import 'components/section-header/section_header.dart';
import 'components/select/select.dart';
import 'components/sheet/sheet.dart';
import 'components/skeleton/skeleton.dart';
import 'components/slider/slider.dart';
import 'components/spinner/spinner.dart';
import 'components/split-button/split_button.dart';
import 'components/split-view/split_view.dart';
import 'components/step-indicator/step_indicator.dart';
import 'components/summary-list/summary_list.dart';
import 'components/swipe-actions/swipe_actions.dart';
import 'components/switch/switch.dart';
import 'components/table/table.dart';
import 'components/tabs/tabs.dart';
import 'components/tag/tag.dart';
import 'components/text-area/text_area.dart';
import 'components/text-field/text_field.dart';
import 'components/timeline/timeline.dart';
import 'components/toast/toast.dart';
import 'components/toggle-group/toggle_group.dart';
import 'components/top-bar/top_bar.dart';
import 'components/tree/tree.dart';
import 'components/wheel-picker/wheel_picker.dart';
import 'internal/frame_scope.dart';
import 'theme.dart';

// The inventory's own types, so an app (and Civic's gallery) can list and
// verify civicInventory through Civic's barrel.
export 'package:ui_core/inventory.dart'
    show RawInventory, RawInventoryEntry, RawInventoryGallery, RawInventoryRow;

void _none() {}
void _drop(Object? _) {}

/// A specimen that keeps the value its control last chose, so the arrow
/// keys move a radio group's choice along with its focus.
class _Held<T> extends StatefulWidget {
  const _Held(this.initial, this.builder);

  final T initial;
  final Widget Function(T value, ValueChanged<T> change) builder;

  @override
  State<_Held<T>> createState() => _HeldState<T>();
}

class _HeldState<T> extends State<_Held<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (next) => setState(() => _value = next));
}

const _places = [
  CivicNavigationDestination(icon: LucideIcons.house, label: 'Home'),
  CivicNavigationDestination(icon: LucideIcons.fileText, label: 'Applications'),
  CivicNavigationDestination(icon: LucideIcons.settings, label: 'Settings'),
];

typedef _Fee = ({String permit, String year});

/// The fee table's specimen: it owns its controller, and gives it back when
/// the gallery lets the row go.
class _Fees extends StatefulWidget {
  const _Fees({this.selectable = false});

  final bool selectable;

  @override
  State<_Fees> createState() => _FeesState();
}

class _FeesState extends State<_Fees> {
  final _fees = RawDataTableController<_Fee>(
    rows: const [
      (permit: 'Resident permit', year: '€60'),
      (permit: 'Electric vehicle', year: '€30'),
    ],
    columns: [
      RawDataColumn<_Fee>(
        id: 'permit',
        label: 'Permit',
        sortKey: (f) => f.permit,
      ),
      RawDataColumn<_Fee>(
        id: 'year',
        label: 'A year',
        numeric: true,
        sortKey: (f) => f.year,
      ),
    ],
  );

  @override
  void dispose() {
    _fees.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CivicTable<_Fee>(
    controller: _fees,
    cellBuilder: _fee,
    selectable: widget.selectable,
  );
}

Widget _fee(BuildContext context, _Fee fee, RawDataColumn<_Fee> column) =>
    Text(column.id == 'year' ? fee.year : fee.permit);

/// The calendar's specimen: it owns its controller.
class _Days extends StatefulWidget {
  const _Days();

  @override
  State<_Days> createState() => _DaysState();
}

class _DaysState extends State<_Days> {
  final _days = RawCalendarController(
    firstDate: DateTime(2026),
    lastDate: DateTime(2026, 12, 31),
    selectedDate: DateTime(2026, 11, 24),
    initialMonth: DateTime(2026, 11),
  );

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CivicCalendar(controller: _days);
}

/// The colour picker's specimen: it owns its controller.
class _Colour extends StatefulWidget {
  const _Colour();

  @override
  State<_Colour> createState() => _ColourState();
}

class _ColourState extends State<_Colour> {
  final _colour = RawColorController(const Color(0xFF0F4C81));

  @override
  void dispose() {
    _colour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CivicColorPicker(
    labelText: 'Badge colour',
    controller: _colour,
    swatches: const [
      CivicColorSwatch(Color(0xFF0F4C81), 'Harbour blue'),
      CivicColorSwatch(Color(0xFF0B6136), 'Park green'),
      CivicColorSwatch(Color(0xFF8A1C1C), 'Brick red'),
    ],
  );
}

/// A pane of the split view's and the carousel's specimens: its words on
/// the pale ground.
class _Pane extends StatelessWidget {
  const _Pane(this.words);

  final String words;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.civicTheme.surface,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(CivicSpacing.s8),
        child: Text(words, textAlign: TextAlign.center),
      ),
    ),
  );
}

/// The scroll area's specimen: it owns its controller.
class _Terms extends StatefulWidget {
  const _Terms();

  @override
  State<_Terms> createState() => _TermsState();
}

class _TermsState extends State<_Terms> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 120,
    child: CivicScrollArea(
      controller: _scroll,
      focusable: true,
      semanticLabel: 'Terms of the permit',
      child: SingleChildScrollView(
        controller: _scroll,
        child: const Padding(
          padding: EdgeInsetsDirectional.only(end: CivicSpacing.s24),
          child: Text(
            'The permit is for the vehicle named on it. Show it on the '
            'windscreen, where a warden can read it. It lets the vehicle '
            'park in its zone\'s permit bays at any time. It does not let '
            'it park on a yellow line, in a disabled bay or in a bay for '
            'loading. Tell us within 14 days if the vehicle changes.',
          ),
        ),
      ),
    ),
  );
}

/// The reorderable list's specimen: it keeps its order.
class _Order extends StatefulWidget {
  const _Order();

  @override
  State<_Order> createState() => _OrderState();
}

class _OrderState extends State<_Order> {
  final _documents = ['Proof of address', 'Vehicle logbook', 'Photo ID'];

  @override
  Widget build(BuildContext context) => CivicReorderableList<String>(
    items: _documents,
    labelOf: (d) => d,
    onReorder: (from, to) =>
        setState(() => _documents.insert(to, _documents.removeAt(from))),
  );
}

/// The tree's specimen: it owns its controller.
class _Sections extends StatefulWidget {
  const _Sections();

  @override
  State<_Sections> createState() => _SectionsState();
}

class _SectionsState extends State<_Sections> {
  static const _under = {
    'Parking': ['Permits', 'Fines'],
    'Permits': ['Resident', 'Visitor'],
  };

  final _sections = RawTreeController<String>(
    roots: const ['Parking', 'Bins'],
    childrenOf: (s) => _under[s] ?? const [],
    expanded: const ['Parking'],
  );

  @override
  void dispose() {
    _sections.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CivicTree<String>(
    controller: _sections,
    labelOf: (s) => s,
    semanticLabel: 'Council services',
  );
}

/// The specimens that fill the height they are given; a gallery frames
/// each in a box of this height.
const Map<String, double> civicInventoryHeights = {
  'NavigationDrawer': 260,
  'RefreshIndicator': 200,
  'Resizable': 160,
  'Scaffold': 320,
};

/// Civic's inventory: every row of the shared component list, answered.
final RawInventory civicInventory = RawInventory(
  look: 'Civic',
  entries: [
    // Actions
    RawInventoryEntry.present(
      'Button',
      (_) => const CivicButton(onPressed: _none, child: Text('Continue')),
    ),
    RawInventoryEntry.present(
      'IconButton',
      (_) => const CivicIconButton(
        icon: LucideIcons.x,
        semanticLabel: 'Close',
        onPressed: _none,
      ),
    ),
    const RawInventoryEntry.absent(
      'FloatingActionButton',
      'A floating button is Material vocabulary: a page\'s action is a '
          'button where the page ends (CivicButton), after what it acts on',
    ),
    RawInventoryEntry.present(
      'ButtonGroup',
      (_) => const CivicButtonGroup(
        children: [
          CivicButton(onPressed: _none, child: Text('Save and continue')),
          CivicLink(onPressed: _none, child: Text('Come back later')),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'ToggleGroup',
      (_) => const CivicToggleGroup<String>(
        labelText: 'Show applications',
        segments: [
          CivicSegment(value: 'drafts', label: 'Drafts'),
          CivicSegment(value: 'sent', label: 'Sent'),
        ],
        selected: {'sent'},
        onSelectionChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'SplitButton',
      (_) => const CivicSplitButton(
        label: 'Send application',
        onPressed: _none,
        actions: [
          CivicSplitAction('Save and come back later', onPressed: _none),
          CivicSplitAction('Print your answers', onPressed: _none),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Link',
      (_) => const CivicLink(
        onPressed: _none,
        child: Text('Read the guidance on permit zones'),
      ),
    ),
    RawInventoryEntry.present(
      'Kbd',
      (_) => const CivicKbd.combination(['Ctrl', 'K']),
    ),
    // Inputs
    RawInventoryEntry.present(
      'TextField',
      (_) => const CivicTextField(labelText: 'Full name'),
    ),
    RawInventoryEntry.present(
      'TextArea',
      (_) => const CivicTextArea(
        labelText: 'Why do you need a second permit?',
        maxLength: 200,
        minLines: 3,
      ),
    ),
    RawInventoryEntry.present(
      'SearchField',
      (_) => const CivicSearchField(onSubmitted: _drop),
    ),
    RawInventoryEntry.present(
      'PasswordField',
      (_) => const CivicPasswordField(labelText: 'Password'),
    ),
    RawInventoryEntry.present(
      'InputGroup',
      (_) => const CivicTextField(
        labelText: 'Weight of the vehicle',
        suffix: Text('kg'),
        widthInCharacters: 5,
      ),
    ),
    RawInventoryEntry.present(
      'InputOtp',
      (_) => const CivicCodeField(labelText: 'Security code'),
    ),
    RawInventoryEntry.present(
      'NumberField',
      (_) => const CivicNumberField(
        labelText: 'Visitor days',
        value: 3,
        min: 1,
        max: 30,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Select',
      (_) => const CivicSelect<String>(
        labelText: 'Permit zone',
        value: 'b',
        onChanged: _drop,
        items: [
          CivicSelectItem(value: 'a', label: 'Zone A: Old Town'),
          CivicSelectItem(value: 'b', label: 'Zone B: Harbourside'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Combobox',
      (_) => const CivicCombobox<String>(
        labelText: 'Country',
        options: ['France', 'Germany', 'Ireland', 'Italy', 'Spain'],
      ),
    ),
    RawInventoryEntry.present(
      'MultiSelect',
      (_) => const CivicMultiSelect<String>(
        labelText: 'Languages you speak',
        options: ['English', 'Polish', 'Punjabi', 'Welsh'],
        values: ['English', 'Welsh'],
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Checkbox',
      (_) => const CivicCheckbox(
        value: true,
        onChanged: _drop,
        labelText: 'Email',
      ),
    ),
    RawInventoryEntry.present(
      'RadioGroup',
      (_) => _Held<String?>(
        'car',
        (chosen, change) => CivicRadioGroup<String>(
          labelText: 'Vehicle',
          groupValue: chosen,
          onChanged: change,
          children: const [
            CivicRadio(value: 'car', labelText: 'Car or van'),
            CivicRadio(value: 'motorcycle', labelText: 'Motorcycle'),
          ],
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Switch',
      (_) => const CivicSwitch(
        value: true,
        onChanged: _drop,
        labelText: 'Renewal reminders',
      ),
    ),
    RawInventoryEntry.present(
      'Slider',
      (_) => const CivicSlider(
        labelText: 'Text size',
        value: 150,
        min: 100,
        max: 200,
        divisions: 4,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Rating',
      (_) => const CivicRating(
        labelText: 'How easy was it to apply?',
        value: 4,
        labels: ['Very hard', 'Hard', 'Neither', 'Easy', 'Very easy'],
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'RangeSlider',
      (_) => const CivicRangeSlider(
        labelText: 'Monthly cost',
        values: RawRangeValues(20, 60),
        max: 100,
        divisions: 20,
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'SegmentedButton',
      (_) => _Held<String>(
        'month',
        (chosen, change) => CivicSegmentedControl<String>(
          labelText: 'Period',
          segments: const [
            CivicSegment(value: 'week', label: 'Week'),
            CivicSegment(value: 'month', label: 'Month'),
            CivicSegment(value: 'year', label: 'Year'),
          ],
          value: chosen,
          onChanged: change,
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Chip',
      (_) => const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          CivicChip(label: 'Open now', selected: true, onSelected: _drop),
          CivicChip.removable(label: 'Zone B', onDeleted: _none),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'FileUpload',
      (_) => const CivicFileUpload(
        labelText: 'Proof of address',
        chooseLabel: 'Choose file',
        emptyLabel: 'No file chosen',
        onChoose: _none,
      ),
    ),
    // A date typed in the reader's order, with the calendar a button
    // away; a date of birth stays three boxes (CivicDateInput).
    RawInventoryEntry.present(
      'DatePicker',
      (_) => CivicDatePicker(
        labelText: 'When do you want the permit to start?',
        value: DateTime(2026, 11, 24),
        firstDate: DateTime(2026),
        lastDate: DateTime(2026, 12, 31),
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'DateRangePicker',
      (_) => CivicDateRangePicker(
        labelText: 'When will your visitor stay?',
        value: null,
        firstDate: DateTime(2026),
        lastDate: DateTime(2026, 12, 31),
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'TimePicker',
      (_) => const CivicTimeInput(
        labelText: 'What time will you arrive?',
        value: RawTimeOfDay(hour: 9, minute: 30),
        onChanged: _drop,
      ),
    ),
    RawInventoryEntry.present('Calendar', (_) => const _Days()),
    RawInventoryEntry.present(
      'WheelPicker',
      // The columns' names and figures in the app's language and digits: ui_core's words. Hour then minute, left
      // to right in every language, as Material's time picker keeps them: right to left, the minutes come first.
      (context) {
        final words = RawWidgetsLocalizations.of(context);
        final hour = RawPickerColumn(
          itemCount: 24,
          itemLabel: (i) => words.formatHour(
            RawTimeOfDay(hour: i, minute: 0),
            alwaysUse24HourFormat: true,
          ),
          semanticLabel: words.timePickerHourLabel,
        );
        final minute = RawPickerColumn(
          itemCount: 4,
          itemLabel: (i) =>
              words.formatMinute(RawTimeOfDay(hour: 0, minute: i * 15)),
          semanticLabel: words.timePickerMinuteLabel,
        );
        final ltr = Directionality.of(context) == TextDirection.ltr;
        return CivicWheelPicker(
          labelText: 'Collection time',
          columns: (_) => ltr ? [hour, minute] : [minute, hour],
          selection: ltr ? const [9, 2] : const [2, 9],
          onChanged: _drop,
        );
      },
    ),
    RawInventoryEntry.present('ColorPicker', (_) => const _Colour()),
    RawInventoryEntry.present(
      'FormField',
      (_) => const CivicTextField(
        labelText: 'Postcode',
        helperText: 'For example, BR4 7QX',
        errorText: 'Enter a postcode',
        widthInCharacters: 10,
      ),
    ),
    // Navigation
    RawInventoryEntry.present(
      'AppBar',
      (_) => const CivicTopBar(title: 'Brindlemere parking permits'),
    ),
    RawInventoryEntry.present(
      'NavigationBar',
      (_) => const CivicNavigationBar(
        destinations: _places,
        selectedIndex: 1,
        onDestinationSelected: _drop,
      ),
    ),
    // A tablet's places: the navigation bar a scaffold or an app's frame
    // stands down the start from 600 wide, each glyph over its name.
    RawInventoryEntry.present(
      'NavigationRail',
      (_) => const SizedBox(
        height: 360,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CivicRailScope(
              child: CivicNavigationBar(
                destinations: _places,
                selectedIndex: 1,
                onDestinationSelected: _drop,
              ),
            ),
          ],
        ),
      ),
    ),
    RawInventoryEntry.present(
      'NavigationDrawer',
      (_) => const CivicSideNavigation(
        destinations: _places,
        selectedIndex: 1,
        onDestinationSelected: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'TabBar',
      (_) => const CivicTabBar(
        tabs: ['Details', 'Documents', 'History'],
        selectedIndex: 0,
        onTap: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'Breadcrumb',
      (_) => const CivicBreadcrumbs(
        items: [
          CivicBreadcrumb(label: 'Home', onPressed: _none),
          CivicBreadcrumb(label: 'Parking', onPressed: _none),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Pagination',
      (_) => const CivicPagination(
        pageCount: 12,
        selectedIndex: 4,
        onPageChanged: _drop,
      ),
    ),
    RawInventoryEntry.present(
      'StepProgress',
      (_) => const CivicStepIndicator(
        steps: ['Your vehicle', 'Your details', 'Proof of address', 'Check'],
        currentStep: 1,
      ),
    ),
    RawInventoryEntry.present(
      'PageDots',
      (_) => const CivicPageDots(
        pageCount: 5,
        selectedIndex: 1,
        onPageChanged: _drop,
      ),
    ),
    const RawInventoryEntry.absent(
      'MenuBar',
      'A public service has no menus: its places are its navigation '
          '(CivicNavigationBar, CivicSideNavigation), its acts are buttons',
    ),
    RawInventoryEntry.present(
      'Command',
      (_) => Builder(
        builder: (context) => CivicButton.secondary(
          onPressed: () => showCivicCommandPalette(
            context: context,
            commands: const [
              RawCommand(
                label: 'Your applications',
                group: 'Pages',
                onPressed: _none,
              ),
              RawCommand(
                label: 'Apply for a permit',
                group: 'Actions',
                onPressed: _none,
              ),
            ],
          ),
          child: const Text('Find a page or action'),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Scaffold',
      (_) => const CivicScaffold(
        topBar: CivicTopBar(title: 'Brindlemere parking permits'),
        navigationBar: CivicNavigationBar(
          destinations: _places,
          selectedIndex: 0,
          onDestinationSelected: _drop,
        ),
        body: CivicPageBody(
          title: 'Your permits',
          children: [Text('One resident permit, Zone B.')],
        ),
      ),
    ),
    // Containers
    RawInventoryEntry.present(
      'Card',
      (_) => const CivicCard(
        title: 'Resident permit, Zone B',
        onPressed: _none,
        child: Text('Runs out on 3 November 2027.'),
      ),
    ),
    RawInventoryEntry.present(
      'ListTile',
      (_) => const CivicListRow(
        title: Text('Resident permit, Zone B'),
        subtitle: Text('BRM-4821-K, sent 3 November'),
        trailing: CivicTag(label: 'In review', tone: CivicTone.info),
        onTap: _none,
      ),
    ),
    RawInventoryEntry.present(
      'ListSection',
      (_) => const CivicSummaryCard(
        title: 'Your vehicle',
        child: CivicSummaryList(
          rows: [
            CivicSummaryRow(label: 'Vehicle', value: Text('Car or van')),
            CivicSummaryRow(label: 'Registration', value: Text('BR21 KLM')),
          ],
        ),
      ),
    ),
    RawInventoryEntry.present(
      'SectionHeader',
      (_) => const CivicSectionHeader(title: 'Before you start'),
    ),
    RawInventoryEntry.present(
      'Disclosure',
      (_) => const CivicDetails(
        title: 'Help with proof of address',
        child: Text('A council tax bill or a tenancy agreement.'),
      ),
    ),
    RawInventoryEntry.present('Table', (_) => const _Fees()),
    RawInventoryEntry.present(
      'DataTable',
      (_) => const _Fees(selectable: true),
    ),
    RawInventoryEntry.present(
      'Divider',
      (_) => const CivicSectionBreak(size: CivicSectionBreakSize.medium),
    ),
    RawInventoryEntry.present('ScrollArea', (_) => const _Terms()),
    RawInventoryEntry.present(
      'Resizable',
      (_) => const CivicSplitView(
        first: _Pane('Your applications'),
        second: _Pane('Resident permit, Zone B'),
        minFirst: 120,
        minSecond: 120,
      ),
    ),
    RawInventoryEntry.present(
      'CarouselView',
      (_) => CivicCarousel(
        semanticLabel: 'Permit zones',
        height: 120,
        itemCount: 3,
        itemBuilder: (context, index) =>
            _Pane(const ['Zone A', 'Zone B', 'Zone C'][index]),
      ),
    ),
    RawInventoryEntry.present('ReorderableListView', (_) => const _Order()),
    RawInventoryEntry.present(
      'SwipeActions',
      (_) => const CivicSwipeActions(
        menuLabel: 'Actions for Resident permit',
        endActions: [
          CivicSwipeAction(label: 'Archive', onPressed: _none),
          CivicSwipeAction(
            label: 'Withdraw',
            onPressed: _none,
            isDestructiveAction: true,
          ),
        ],
        child: CivicListRow(title: Text('Resident permit, Zone B')),
      ),
    ),
    RawInventoryEntry.present(
      'RefreshIndicator',
      (_) => CivicPullToRefresh(
        onRefresh: () async {},
        child: ListView(
          children: const [
            CivicListRow(title: Text('Resident permit, Zone B')),
            CivicListRow(title: Text('Visitor permit')),
          ],
        ),
      ),
    ),
    RawInventoryEntry.present('TreeView', (_) => const _Sections()),
    RawInventoryEntry.present(
      'Timeline',
      (_) => const CivicTimeline(
        entries: [
          CivicTimelineEntry(title: 'Permit approved', date: '7 November'),
          CivicTimelineEntry(title: 'Application received', date: '3 November'),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Avatar',
      (_) => const CivicAvatar(name: 'Amara Okafor'),
    ),
    RawInventoryEntry.present(
      'AvatarGroup',
      (_) => const CivicAvatarGroup(
        names: ['Amara Okafor', 'Ben Hale', 'Chi Lee', 'Dev Rao', 'Eli Moss'],
      ),
    ),
    RawInventoryEntry.present(
      'Badge',
      (_) => const CivicBadge(
        count: 2,
        noun: 'update',
        child: Text('Your applications'),
      ),
    ),
    RawInventoryEntry.present(
      'Tag',
      (_) => const CivicTag(label: 'Approved', tone: CivicTone.success),
    ),
    RawInventoryEntry.present(
      'Media',
      (_) => const SizedBox(
        width: 240,
        child: CivicImage(
          image: null,
          description: 'Map of Zone B',
          caption: 'Zone B runs from the river to Mill Lane.',
        ),
      ),
    ),
    RawInventoryEntry.present(
      'EmptyState',
      (_) => const CivicEmptyState(
        title: 'You have no applications yet',
        children: [Text('When you apply for a permit, it will show here.')],
      ),
    ),
    RawInventoryEntry.present(
      'DescriptionList',
      (_) => const CivicSummaryList(
        rows: [
          CivicSummaryRow(label: 'Name', value: Text('Amara Okafor')),
          CivicSummaryRow(label: 'Postcode', value: Text('BR4 7QX')),
        ],
      ),
    ),
    // Overlays
    RawInventoryEntry.present(
      'Dialog',
      (_) => const CivicDialog(
        title: 'You will be signed out soon',
        actions: [CivicButton(onPressed: _none, child: Text('Stay signed in'))],
        content: Text(
          'We will sign you out in 2 minutes to protect your answers.',
        ),
      ),
    ),
    RawInventoryEntry.present(
      'BottomSheet',
      (_) => Builder(
        builder: (context) => CivicButton.secondary(
          onPressed: () => showCivicBottomSheet<void>(
            context: context,
            title: 'Filter applications',
            builder: (_) =>
                const Text('Show applications that are in progress.'),
          ),
          child: const Text('Filter applications'),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Sheet',
      (_) => Builder(
        builder: (context) => CivicButton.secondary(
          onPressed: () => showCivicSideSheet<void>(
            context: context,
            title: 'Filter applications',
            builder: (_) =>
                const Text('Show applications that are in progress.'),
          ),
          child: const Text('Filter applications'),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'ActionSheet',
      (_) => Builder(
        builder: (context) => CivicButton.secondary(
          onPressed: () => showCivicActionSheet<String>(
            context: context,
            title: 'Application BRM-4821-K',
            actions: const [
              CivicActionSheetAction(
                value: 'print',
                label: 'Print your answers',
              ),
              CivicActionSheetAction(
                value: 'withdraw',
                label: 'Withdraw application',
                isDestructiveAction: true,
              ),
            ],
          ),
          child: const Text('Application actions'),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Popover',
      (_) => CivicPopover(
        title: 'Who counts as a visitor',
        content: const Text(
          'Anyone staying less than 14 days who does not live at the address.',
        ),
        builder: (context, anchor) => CivicLink(
          onPressed: anchor.toggle,
          child: const Text('Who counts as a visitor?'),
        ),
      ),
    ),
    const RawInventoryEntry.absent(
      'HoverCard',
      'Nothing in Civic opens on a hover alone, out of reach of a finger, '
          'the keys and a screen reader: more to know opens on a press '
          '(CivicPopover) or folds in place (CivicDetails)',
    ),
    RawInventoryEntry.present(
      'Tooltip',
      (_) => const CivicIconButton(
        icon: LucideIcons.printer,
        semanticLabel: 'Print this page',
        tooltip: 'Print this page',
        onPressed: _none,
      ),
    ),
    RawInventoryEntry.present(
      'Menu',
      (_) => CivicMenu<String>(
        semanticLabel: 'Application actions',
        items: const [
          CivicMenuItem(value: 'print', label: 'Print your answers'),
          CivicMenuItem(
            value: 'withdraw',
            label: 'Withdraw application',
            isDestructiveAction: true,
            startsGroup: true,
          ),
        ],
        onSelected: (_) {},
        builder: (context, anchor) => CivicButton.secondary(
          onPressed: anchor.toggle,
          child: const Text('Actions'),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'SnackBar',
      (_) => CivicToaster(
        child: Builder(
          builder: (context) => CivicButton.secondary(
            onPressed: () =>
                CivicToast.show(context, 'Your settings have been saved'),
            child: const Text('Save settings'),
          ),
        ),
      ),
    ),
    RawInventoryEntry.present(
      'Banner',
      (_) => const CivicNotificationBanner(
        title: 'Important',
        child: Text('Permits for Zone C are paused until 1 December.'),
      ),
    ),
    // Feedback
    RawInventoryEntry.present(
      'LinearProgressIndicator',
      (_) => const CivicProgressBar(
        label: 'Uploading proof of address',
        value: 0.4,
        valueLabel: '2 of 5 pages uploaded',
      ),
    ),
    RawInventoryEntry.present(
      'CircularProgressIndicator',
      (_) => const CivicSpinner(label: 'Checking your vehicle'),
    ),
    RawInventoryEntry.present(
      'Skeleton',
      (_) => const CivicSkeleton(child: CivicSkeletonText(lines: 2)),
    ),
    RawInventoryEntry.present(
      'StatusView',
      (_) => const CivicEmptyState(
        title: 'Sorry, the service is unavailable',
        children: [Text('You will be able to use the service later.')],
      ),
    ),
    RawInventoryEntry.present(
      'Meter',
      (_) => const CivicMeter(
        label: 'Visitor days used this year',
        value: 38,
        max: 60,
        high: 50,
        valueLabel: '38 of 60 days used',
      ),
    ),
    // Charts
    RawInventoryEntry.present(
      'LineChart',
      (_) => const CivicLineChart(
        title: 'Permits issued each month',
        labels: ['Jan', 'Feb', 'Mar', 'Apr'],
        series: [
          CivicChartSeries('Resident', [120, 135, 128, 142]),
          CivicChartSeries('Visitor', [80, 92, 110, 104]),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'BarChart',
      (_) => const CivicBarChart(
        title: 'Fines paid by quarter',
        labels: ['Q1', 'Q2', 'Q3', 'Q4'],
        series: [
          CivicChartSeries('Fines paid', [310, 280, 355, 290]),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'AreaChart',
      (_) => const CivicAreaChart(
        title: 'Applications waiting',
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        series: [
          CivicChartSeries('Waiting', [42, 38, 51, 47, 33]),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'PieChart',
      (_) => const CivicPieChart(
        title: 'Permits by kind',
        slices: [
          CivicPieSlice('Resident', 1240),
          CivicPieSlice('Visitor', 610),
          CivicPieSlice('Business', 150),
        ],
      ),
    ),
    RawInventoryEntry.present(
      'Sparkline',
      (_) => const CivicSparkline(
        label: 'Visitor permits this week',
        values: [12, 18, 15, 22, 19, 26, 31],
      ),
    ),
  ],
);
