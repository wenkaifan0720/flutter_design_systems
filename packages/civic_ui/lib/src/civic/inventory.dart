// Civic's answer to the shared component inventory (ui_core's
// DesignInventoryRow.all): for each row the part that answers it, as a
// small live specimen, or the reason a public service leaves it out. The
// gallery lists it, and a test verifies it (every row answered once, no
// reason a to-do).
import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'components/breadcrumbs/breadcrumbs.dart';
import 'components/button-group/button_group.dart';
import 'components/button/button.dart';
import 'components/checkbox/checkbox.dart';
import 'components/combobox/combobox.dart';
import 'components/date-input/date_input.dart';
import 'components/details/details.dart';
import 'components/dialog/dialog.dart';
import 'components/empty-state/empty_state.dart';
import 'components/file-upload/file_upload.dart';
import 'components/icon-button/icon_button.dart';
import 'components/link/link.dart';
import 'components/list-row/list_row.dart';
import 'components/navigation/navigation.dart';
import 'components/pagination/pagination.dart';
import 'components/panel/panel.dart';
import 'components/password-field/password_field.dart';
import 'components/radio/radio.dart';
import 'components/scaffold/scaffold.dart';
import 'components/search-field/search_field.dart';
import 'components/section-break/section_break.dart';
import 'components/section-header/section_header.dart';
import 'components/select/select.dart';
import 'components/summary-list/summary_list.dart';
import 'components/switch/switch.dart';
import 'components/table/table.dart';
import 'components/tabs/tabs.dart';
import 'components/tag/tag.dart';
import 'components/text-field/text_field.dart';
import 'components/timeline/timeline.dart';
import 'components/toast/toast.dart';
import 'components/top-bar/top_bar.dart';
import 'internal/frame_scope.dart';
import 'theme.dart';

// The inventory's own types, so an app (and Civic's gallery) can list and
// verify civicInventory through Civic's barrel.
export 'package:ui_core/inventory.dart'
    show
        DesignInventory,
        DesignInventoryEntry,
        DesignInventoryGallery,
        DesignInventoryRow;

void _none() {}
void _drop(Object? _) {}

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
  final _fees = DesignTableController<_Fee>(
    rows: const [
      (permit: 'Resident permit', year: '€60'),
      (permit: 'Electric vehicle', year: '€30'),
    ],
    columns: [
      DesignTableColumn<_Fee>(
        id: 'permit',
        label: 'Permit',
        sortKey: (f) => f.permit,
      ),
      DesignTableColumn<_Fee>(
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

Widget _fee(BuildContext context, _Fee fee, DesignTableColumn<_Fee> column) =>
    Text(column.id == 'year' ? fee.year : fee.permit);

/// The specimens that fill the height they are given; a gallery frames
/// each in a box of this height.
const Map<String, double> civicInventoryHeights = {
  'NavigationDrawer': 260,
  'Scaffold': 320,
};

/// The words a public service puts where another look puts a control: why
/// Civic leaves a row out, and what it uses instead.
abstract final class _Why {
  static const charts =
      'A public service gives its numbers in words and in a table '
      '(CivicTable), which every reader and every screen reader can read; '
      'a chart says less to fewer people';
  static const hidden =
      'A public service keeps every action in sight as a button or a link '
      '(CivicButton, CivicLink): an action behind a hover, a long press or '
      'a gesture is one some readers never find';
  static const overPage =
      'A public service asks one thing per page: what another look lays '
      'over the page, Civic puts on a page of its own, or folds under its '
      'title in place (CivicDetails); the one interruption it keeps is the '
      'dialog (CivicDialog)';
}

/// Civic's inventory: every row of the shared component list, answered.
final DesignInventory civicInventory = DesignInventory(
  look: 'Civic',
  entries: [
    // Actions
    DesignInventoryEntry.present(
      'Button',
      (_) => const CivicButton(onPressed: _none, child: Text('Continue')),
    ),
    DesignInventoryEntry.present(
      'IconButton',
      (_) => const CivicIconButton(
        icon: LucideIcons.x,
        semanticLabel: 'Close',
        onPressed: _none,
      ),
    ),
    const DesignInventoryEntry.absent(
      'FloatingActionButton',
      'A floating button is Material vocabulary: a page\'s action is a '
          'button where the page ends (CivicButton), after what it acts on',
    ),
    DesignInventoryEntry.present(
      'ButtonGroup',
      (_) => const CivicButtonGroup(
        children: [
          CivicButton(onPressed: _none, child: Text('Save and continue')),
          CivicLink(onPressed: _none, child: Text('Come back later')),
        ],
      ),
    ),
    const DesignInventoryEntry.absent(
      'ToggleGroup',
      'A public service asks for one answer of several with radios '
          '(CivicRadioGroup), whose every answer is labelled in words, and '
          'for several with checkboxes (CivicCheckbox)',
    ),
    const DesignInventoryEntry.absent('SplitButton', _Why.hidden),
    DesignInventoryEntry.present(
      'Link',
      (_) => const CivicLink(
        onPressed: _none,
        child: Text('Read the guidance on permit zones'),
      ),
    ),
    const DesignInventoryEntry.absent(
      'Kbd',
      'A public service teaches no shortcuts: every page works with Tab and '
          'Enter alone, so there are no keys to show',
    ),
    // Inputs
    DesignInventoryEntry.present(
      'TextField',
      (_) => const CivicTextField(labelText: 'Full name'),
    ),
    DesignInventoryEntry.present(
      'TextArea',
      (_) => const CivicTextField(
        labelText: 'Why do you need a second permit?',
        maxLines: 4,
        minLines: 3,
      ),
    ),
    DesignInventoryEntry.present(
      'SearchField',
      (_) => const CivicSearchField(onSubmitted: _drop),
    ),
    DesignInventoryEntry.present(
      'PasswordField',
      (_) => const CivicPasswordField(labelText: 'Password'),
    ),
    DesignInventoryEntry.present(
      'InputGroup',
      (_) => const CivicTextField(
        labelText: 'Weight of the vehicle',
        suffix: Text('kg'),
        widthInCharacters: 5,
      ),
    ),
    const DesignInventoryEntry.absent(
      'InputOtp',
      'A code is typed in one box (CivicTextField with the number '
          'keyboard): boxes that jump the caret between them confuse a '
          'screen reader and break a paste',
    ),
    const DesignInventoryEntry.absent(
      'NumberField',
      'A number is typed in a box sized for it (CivicTextField with '
          'widthInCharacters and the number keyboard): a stepper\'s small '
          'buttons are slow and easy to miss',
    ),
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'Combobox',
      (_) => const CivicCombobox<String>(
        labelText: 'Country',
        options: ['France', 'Germany', 'Ireland', 'Italy', 'Spain'],
      ),
    ),
    const DesignInventoryEntry.absent(
      'MultiSelect',
      'Several answers are checkboxes (CivicCheckbox in a CivicFieldset): '
          'each answer in sight and in words, where tags in a box hide '
          'what was not chosen',
    ),
    DesignInventoryEntry.present(
      'Checkbox',
      (_) => const CivicCheckbox(
        value: true,
        onChanged: _drop,
        labelText: 'Email',
      ),
    ),
    DesignInventoryEntry.present(
      'RadioGroup',
      (_) => const CivicRadioGroup<String>(
        labelText: 'Vehicle',
        groupValue: 'car',
        onChanged: _drop,
        children: [
          CivicRadio(value: 'car', labelText: 'Car or van'),
          CivicRadio(value: 'motorcycle', labelText: 'Motorcycle'),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Switch',
      (_) => const CivicSwitch(
        value: true,
        onChanged: _drop,
        labelText: 'Renewal reminders',
      ),
    ),
    const DesignInventoryEntry.absent(
      'Slider',
      'A public service asks for an amount in a box sized for it '
          '(CivicTextField): a slider is hard to set exactly, by a hand '
          'that shakes or by the keys',
    ),
    const DesignInventoryEntry.absent(
      'Rating',
      'A public service asks how it went in words a reader picks '
          '(CivicRadio: very good to very poor) and a box for why: a row '
          'of stars is hard to hear, to reach by the keys and to tap '
          'exactly',
    ),
    const DesignInventoryEntry.absent(
      'RangeSlider',
      'A range is two boxes, from and to (CivicTextField): two thumbs on '
          'one track are harder still to set exactly',
    ),
    const DesignInventoryEntry.absent(
      'SegmentedButton',
      'One answer of several is a radio group (CivicRadioGroup), whose '
          'answers wrap and grow with the text where segments squeeze',
    ),
    const DesignInventoryEntry.absent(
      'Chip',
      'Filters are checkboxes in the filter column (CivicCheckbox), and a '
          'status is a tag (CivicTag): chips mix the two',
    ),
    DesignInventoryEntry.present(
      'FileUpload',
      (_) => const CivicFileUpload(
        labelText: 'Proof of address',
        chooseLabel: 'Choose file',
        emptyLabel: 'No file chosen',
        onChoose: _none,
      ),
    ),
    DesignInventoryEntry.present(
      'DatePicker',
      (_) => const CivicDateInput(
        labelText: 'Date of birth',
        helperText: 'For example, 27 3 1987',
        dayLabel: 'Day',
        monthLabel: 'Month',
        yearLabel: 'Year',
      ),
    ),
    const DesignInventoryEntry.absent(
      'DateRangePicker',
      'A range of dates is two date inputs, from and to (CivicDateInput), '
          'each typed as the reader knows it',
    ),
    const DesignInventoryEntry.absent(
      'TimePicker',
      'A time is typed (CivicTextField, "for example, 2:30pm"), or chosen '
          'from the times free as radios (CivicRadioGroup)',
    ),
    const DesignInventoryEntry.absent(
      'Calendar',
      'A date the reader knows is typed (CivicDateInput); a date chosen '
          'from what is free is a list of radios (CivicRadioGroup), which a '
          'screen reader reads as easily as an eye',
    ),
    const DesignInventoryEntry.absent(
      'WheelPicker',
      'A wheel is a phone\'s gesture: a date is typed (CivicDateInput) and '
          'one answer of several is a radio group (CivicRadioGroup)',
    ),
    const DesignInventoryEntry.absent(
      'ColorPicker',
      'A public service never asks for a colour it cannot also take in '
          'words: a vehicle\'s colour is typed (CivicTextField)',
    ),
    DesignInventoryEntry.present(
      'FormField',
      (_) => const CivicTextField(
        labelText: 'Postcode',
        helperText: 'For example, BR4 7QX',
        errorText: 'Enter a postcode',
        widthInCharacters: 10,
      ),
    ),
    // Navigation
    DesignInventoryEntry.present(
      'AppBar',
      (_) => const CivicTopBar(title: 'Brindlemere parking permits'),
    ),
    DesignInventoryEntry.present(
      'NavigationBar',
      (_) => const CivicNavigationBar(
        destinations: _places,
        selectedIndex: 1,
        onDestinationSelected: _drop,
      ),
    ),
    // A tablet's places: the navigation bar a scaffold or an app's frame
    // stands down the start from 600 wide, each glyph over its name.
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'NavigationDrawer',
      (_) => const CivicSideNavigation(
        destinations: _places,
        selectedIndex: 1,
        onDestinationSelected: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'TabBar',
      (_) => const CivicTabBar(
        tabs: ['Details', 'Documents', 'History'],
        selectedIndex: 0,
        onTap: _drop,
      ),
    ),
    DesignInventoryEntry.present(
      'Breadcrumb',
      (_) => const CivicBreadcrumbs(
        items: [
          CivicBreadcrumb(label: 'Home', onPressed: _none),
          CivicBreadcrumb(label: 'Parking', onPressed: _none),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Pagination',
      (_) => const CivicPagination(
        pageCount: 12,
        selectedIndex: 4,
        onPageChanged: _drop,
      ),
    ),
    const DesignInventoryEntry.absent(
      'StepProgress',
      'A public service says where the reader is in words over the '
          'question (CivicPageBody\'s caption, "Step 2 of 3") and lists '
          'what is left as a task list (CivicListRow with CivicTag): a '
          'progress bar promises an end the answers can move',
    ),
    const DesignInventoryEntry.absent(
      'PageDots',
      'Civic has no carousel, so nothing to count: every page of a service '
          'is a page',
    ),
    const DesignInventoryEntry.absent(
      'MenuBar',
      'A public service has no menus: its places are its navigation '
          '(CivicNavigationBar, CivicSideNavigation), its acts are buttons',
    ),
    const DesignInventoryEntry.absent(
      'Command',
      'A public service is found by its words, not commands: a search box '
          '(CivicSearchField) finds what a reader looks for',
    ),
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'Card',
      (_) => const CivicSummaryCard(
        title: 'Resident permit',
        child: CivicSummaryList(
          rows: [CivicSummaryRow(label: 'Zone', value: Text('B: Harbourside'))],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'ListTile',
      (_) => const CivicListRow(
        title: Text('Resident permit, Zone B'),
        subtitle: Text('BRM-4821-K, sent 3 November'),
        trailing: CivicTag(label: 'In review', tone: CivicTone.info),
        onTap: _none,
      ),
    ),
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'SectionHeader',
      (_) => const CivicSectionHeader(title: 'Before you start'),
    ),
    DesignInventoryEntry.present(
      'Disclosure',
      (_) => const CivicDetails(
        title: 'Help with proof of address',
        child: Text('A council tax bill or a tenancy agreement.'),
      ),
    ),
    DesignInventoryEntry.present('Table', (_) => const _Fees()),
    DesignInventoryEntry.present(
      'DataTable',
      (_) => const _Fees(selectable: true),
    ),
    DesignInventoryEntry.present(
      'Divider',
      (_) => const CivicSectionBreak(size: CivicSectionBreakSize.medium),
    ),
    const DesignInventoryEntry.absent(
      'ScrollArea',
      'A service\'s page scrolls whole, with the platform\'s own '
          'scrollbar: Civic puts nothing that scrolls inside a page, where '
          'a reader with a magnifier loses it',
    ),
    const DesignInventoryEntry.absent(
      'Resizable',
      'A public service is one reading column: there are no panes to size',
    ),
    const DesignInventoryEntry.absent(
      'CarouselView',
      'A carousel hides all but one of its items and moves on its own: '
          'Civic lists them (CivicListRow)',
    ),
    const DesignInventoryEntry.absent(
      'ReorderableListView',
      'An order of preference is asked as a question per place ("First '
          'choice", CivicSelect): dragging rows is hard by the keys and by '
          'a screen reader',
    ),
    const DesignInventoryEntry.absent('SwipeActions', _Why.hidden),
    const DesignInventoryEntry.absent(
      'RefreshIndicator',
      'A service\'s page says when it was true and offers Try again '
          '(CivicEmptyState with a CivicButton): a pull is a gesture some '
          'readers cannot make and none can see',
    ),
    const DesignInventoryEntry.absent(
      'TreeView',
      'A public service is shallow: a place below another is a page with '
          'breadcrumbs (CivicBreadcrumbs), not a branch to open',
    ),
    DesignInventoryEntry.present(
      'Timeline',
      (_) => const CivicTimeline(
        entries: [
          CivicTimelineEntry(title: 'Permit approved', date: '7 November'),
          CivicTimelineEntry(title: 'Application received', date: '3 November'),
        ],
      ),
    ),
    const DesignInventoryEntry.absent(
      'Avatar',
      'A public service knows a reader by their name and a reference, '
          'which it writes out: it shows no faces',
    ),
    const DesignInventoryEntry.absent(
      'AvatarGroup',
      'A public service shows no faces, so no pile of them: people are '
          'named in a list (CivicSummaryList)',
    ),
    const DesignInventoryEntry.absent(
      'Badge',
      'A count is said in words beside what it counts ("3 applications"): '
          'a number in a dot says nothing of what it counts',
    ),
    DesignInventoryEntry.present(
      'Tag',
      (_) => const CivicTag(label: 'Approved', tone: CivicTone.success),
    ),
    const DesignInventoryEntry.absent(
      'Media',
      'A public service carries its meaning in words: a picture that a '
          'reader needs is a file to open (CivicLink)',
    ),
    DesignInventoryEntry.present(
      'EmptyState',
      (_) => const CivicEmptyState(
        title: 'You have no applications yet',
        children: [Text('When you apply for a permit, it will show here.')],
      ),
    ),
    DesignInventoryEntry.present(
      'DescriptionList',
      (_) => const CivicSummaryList(
        rows: [
          CivicSummaryRow(label: 'Name', value: Text('Amara Okafor')),
          CivicSummaryRow(label: 'Postcode', value: Text('BR4 7QX')),
        ],
      ),
    ),
    // Overlays
    DesignInventoryEntry.present(
      'Dialog',
      (_) => const CivicDialog(
        title: 'You will be signed out soon',
        actions: [CivicButton(onPressed: _none, child: Text('Stay signed in'))],
        content: Text(
          'We will sign you out in 2 minutes to protect your answers.',
        ),
      ),
    ),
    const DesignInventoryEntry.absent('BottomSheet', _Why.overPage),
    const DesignInventoryEntry.absent('Sheet', _Why.overPage),
    const DesignInventoryEntry.absent('ActionSheet', _Why.hidden),
    const DesignInventoryEntry.absent('Popover', _Why.overPage),
    const DesignInventoryEntry.absent(
      'HoverCard',
      'A hover is out of reach of a finger, the keys and a screen reader: '
          'what more there is to know is in sight or folded (CivicDetails)',
    ),
    const DesignInventoryEntry.absent(
      'Tooltip',
      'Civic writes an action\'s name on it; its few glyph-only buttons '
          '(CivicIconButton: Close) carry their name for a screen reader, '
          'and a tip a finger cannot reach is help some readers never get',
    ),
    const DesignInventoryEntry.absent('Menu', _Why.hidden),
    DesignInventoryEntry.present(
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
    DesignInventoryEntry.present(
      'Banner',
      (_) => const CivicNotificationBanner(
        title: 'Important',
        child: Text('Permits for Zone C are paused until 1 December.'),
      ),
    ),
    // Feedback
    const DesignInventoryEntry.absent(
      'LinearProgressIndicator',
      'A public service\'s page loads whole and says how far through a '
          'service the reader is in words (CivicPageBody\'s caption)',
    ),
    const DesignInventoryEntry.absent(
      'CircularProgressIndicator',
      'A public service\'s page loads whole; a wait it cannot avoid is a '
          'page that says what is happening, in words',
    ),
    const DesignInventoryEntry.absent(
      'Skeleton',
      'A skeleton shows the shape of nothing to a reader who cannot see it '
          'and is silent to one who uses a screen reader: Civic\'s pages '
          'load whole',
    ),
    DesignInventoryEntry.present(
      'StatusView',
      (_) => const CivicEmptyState(
        title: 'Sorry, the service is unavailable',
        children: [Text('You will be able to use the service later.')],
      ),
    ),
    const DesignInventoryEntry.absent(
      'Meter',
      'An amount against a limit is said in words ("€60 of €120"): a gauge '
          'says less to fewer people',
    ),
    // Charts
    const DesignInventoryEntry.absent('LineChart', _Why.charts),
    const DesignInventoryEntry.absent('BarChart', _Why.charts),
    const DesignInventoryEntry.absent('AreaChart', _Why.charts),
    const DesignInventoryEntry.absent('PieChart', _Why.charts),
    const DesignInventoryEntry.absent('Sparkline', _Why.charts),
  ],
);
