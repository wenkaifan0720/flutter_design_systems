// Shared inventory for the source-enumerated reach and keyboard laws.
import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../example/lib/demo_art.dart';

final retroDesktopInteractiveSamples = <String, Widget Function(VoidCallback?)>{
  'RetroDesktopPressable': (hit) =>
      RetroDesktopPressable(onPressed: hit, child: Text('Press')),
  'RetroDesktopButton (isDefaultAction)': (hit) =>
      RetroDesktopButton('Save', isDefaultAction: true, onPressed: hit),
  'RetroDesktopButton': (hit) => RetroDesktopButton('Back', onPressed: hit),
  'RetroDesktopButton (wide)': (hit) =>
      RetroDesktopButton('Go', wide: true, onPressed: hit),
  'RetroDesktopIconButton': (hit) =>
      RetroDesktopIconButton(LucideIcons.tag, label: 'Tag', onPressed: hit),
  'RetroDesktopPopupButton': (hit) =>
      RetroDesktopPopupButton('Pick one', onPressed: hit),
  'RetroDesktopTextField': (hit) => RetroDesktopTextField(
    hint: 'Search',
    enabled: hit != null,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopInput': (hit) => RetroDesktopInput(
    hint: 'Your name',
    enabled: hit != null,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopCheckbox': (hit) => RetroDesktopCheckbox(
    value: true,
    onChanged: hit == null ? null : (_) => hit(),
    label: 'Option',
  ),
  'RetroDesktopRadioGroup': (hit) => RetroDesktopRadioGroup<int>(
    label: 'Choice',
    options: const [
      RetroDesktopRadio<int>(1, 'First'),
      RetroDesktopRadio<int>(2, 'Second'),
    ],
    value: 1,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopCheckRow': (hit) => RetroDesktopCheckRow(
    label: 'Before something is due',
    value: true,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopChip': (hit) => RetroDesktopChip('All', onPressed: hit),
  'RetroDesktopDisclosure': (hit) => RetroDesktopDisclosure(
    enabled: hit != null,
    onExpansionChanged: hit == null ? null : (_) => hit(),
    note: '12',
    title: 'Versions',
    child: Text('Inside'),
  ),
  'RetroDesktopChoiceBox': (hit) => RetroDesktopChoiceBox(
    onPressed: hit,
    selected: true,
    child: Text('Today'),
  ),
  'RetroDesktopChoices': (hit) => RetroDesktopChoices(
    options: [
      RetroDesktopChoice('Every day', note: 'At nine'),
      RetroDesktopChoice('Every week', note: 'On Monday'),
      RetroDesktopChoice('Never'),
    ],
    onChanged: hit == null ? null : (_) => hit(),
    value: 'Every week',
  ),
  'RetroDesktopNumberField': (hit) => RetroDesktopNumberField(
    value: 2,
    unit: 'a day',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopTabBar': (hit) => RetroDesktopTabBar(
    tabs: ['Today', 'Soon', 'Later'],
    onChanged: hit == null ? null : (_) => hit(),
    selectedIndex: 0,
    counts: ['3', '4', '5'],
    child: RetroDesktopWell(child: Text('One row')),
  ),
  'RetroDesktopWindow': (hit) => RetroDesktopWindow(
    title: 'A window',
    onClose: hit,
    child: Text('Inside'),
  ),
  'RetroDesktopWindowShade': (hit) => RetroDesktopWindowShade(
    title: 'Inbox, 4 new',
    icon: LucideIcons.inbox,
    onPressed: hit,
  ),
  'RetroDesktopListTile': (hit) => RetroDesktopListTile(
    title: 'A row',
    subtitle: 'Under it',
    onPressed: hit,
  ),
  'RetroDesktopTaskRow': (hit) => RetroDesktopTaskRow(
    title: 'The first thing',
    subtitle: 'First folder',
    onPressed: hit,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopMonthHead': (hit) => RetroDesktopMonthHead(
    'March 2026',
    onPrevious: hit,
    onToday: hit,
    onNext: hit,
  ),
  'RetroDesktopMonthGrid': (hit) => RetroDesktopMonthGrid(
    year: 2026,
    month: 3,
    today: 14,
    onDay: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopListTableRow': (hit) => RetroDesktopListTable(
    columns: [
      RetroDesktopListTableColumn('Name'),
      RetroDesktopListTableColumn('Edited', width: 90),
    ],
    rows: [
      RetroDesktopListTableRow(
        title: 'One',
        cells: [('09:14', 'today')],
        onPressed: hit,
      ),
      RetroDesktopListTableRow(
        title: 'Two',
        cells: [('18:05', 'yesterday')],
        onPressed: hit,
      ),
    ],
  ),
  // The table as one control: a row is chosen and opened through the table.
  'RetroDesktopListTable': (hit) => RetroDesktopListTable(
    columns: [
      RetroDesktopListTableColumn('Name'),
      RetroDesktopListTableColumn('Edited', width: 90),
    ],
    rows: [
      RetroDesktopListTableRow(title: 'One', cells: [('09:14', 'today')]),
      RetroDesktopListTableRow(title: 'Two', cells: [('18:05', 'yesterday')]),
    ],
    onSelected: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopDeskIcon': (hit) => RetroDesktopDeskIcon(
    'Documents',
    art: RetroDesktopSystemMark(size: 40),
    onPressed: hit,
  ),
  'RetroDesktopFolder': (hit) => RetroDesktopFolderGrid(
    items: [
      RetroDesktopFolder(
        'First',
        note: '6 things',
        onPressed: hit,
        art: RetroDesktopFolderArt(selected: false, icon: null),
      ),
      RetroDesktopFolder(
        'Second',
        note: '4 things',
        onPressed: hit,
        art: RetroDesktopFolderArt(selected: false, icon: null),
      ),
      RetroDesktopFolder(
        'Third',
        note: '2 things',
        onPressed: hit,
        art: RetroDesktopFolderArt(selected: false, icon: null),
      ),
    ],
  ),
  'RetroDesktopFile': (hit) => RetroDesktopFileGrid(
    items: [
      RetroDesktopFile(
        'a.pdf',
        kind: 'PDF',
        onPressed: hit,
        art: RetroDesktopFilePageArt(
          kind: RetroDesktopFileArt.text,
          selected: false,
        ),
      ),
      RetroDesktopFile(
        'b.csv',
        kind: 'CSV',
        onPressed: hit,
        art: RetroDesktopFilePageArt(
          kind: RetroDesktopFileArt.text,
          selected: false,
        ),
      ),
      RetroDesktopFile(
        'c.svg',
        kind: 'SVG',
        onPressed: hit,
        art: RetroDesktopFilePageArt(
          kind: RetroDesktopFileArt.text,
          selected: false,
        ),
      ),
    ],
  ),
  'RetroDesktopCheckItem': (hit) => RetroDesktopChecklist(
    title: 'Checklist',
    items: [
      RetroDesktopCheckItem(
        'The first step',
        value: true,
        onChanged: hit == null ? null : (_) => hit(),
      ),
      RetroDesktopCheckItem(
        'The next step',
        isCurrent: true,
        onChanged: hit == null ? null : (_) => hit(),
      ),
      RetroDesktopCheckItem(
        'The last step',
        onChanged: hit == null ? null : (_) => hit(),
      ),
    ],
  ),
  'RetroDesktopPictureCard': (hit) => RetroDesktopPictureCard(
    art: RetroDesktopObjectArt(RetroDesktopObject.folder),
    title: 'One thing',
    onPressed: hit,
  ),
  'RetroDesktopErrorState': (hit) => RetroDesktopErrorState(
    title: 'That did not load',
    message: 'Try again.',
    onRetry: hit,
  ),
  'RetroDesktopBackButton': (hit) => RetroDesktopBackButton(onPressed: hit),
  'RetroDesktopNavItem': (hit) => RetroDesktopNavigationBar(
    items: [
      RetroDesktopNavItem(
        label: 'Today',
        short: 'Today',
        icon: LucideIcons.house,
        onPressed: hit,
      ),
      RetroDesktopNavItem(
        label: 'Places',
        short: 'Places',
        icon: LucideIcons.compass,
        onPressed: hit,
      ),
      RetroDesktopNavItem(
        label: 'You',
        short: 'You',
        icon: LucideIcons.user,
        onPressed: hit,
      ),
    ],
  ),
  'RetroDesktopButton.text': (hit) =>
      RetroDesktopButton.text('More', onPressed: hit),
  'RetroDesktopButton (isDestructiveAction)': (hit) => RetroDesktopButton(
    'Delete',
    isDefaultAction: true,
    isDestructiveAction: true,
    onPressed: hit,
  ),
  'RetroDesktopLink': (hit) => RetroDesktopLink('Help', onPressed: hit),
  'RetroDesktopSearchField': (hit) => RetroDesktopSearchField(
    hint: 'Search',
    enabled: hit != null,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopInputOtp': (hit) => RetroDesktopInputOtp(
    label: 'Code',
    enabled: hit != null,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopSelect': (hit) => RetroDesktopSelect<String>(
    label: 'Destination',
    options: const [RetroDesktopOption('local', 'Local')],
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopSwitch': (hit) => RetroDesktopSwitch(
    value: true,
    label: 'Sync',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopSwitchRow': (hit) => RetroDesktopSwitchRow(
    value: true,
    label: 'Sync',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopSegmentedButton': (hit) => RetroDesktopSegmentedButton<String>(
    label: 'View',
    value: 'list',
    segments: const [
      RetroDesktopButtonSegment('list', 'List'),
      RetroDesktopButtonSegment('grid', 'Grid'),
    ],
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopSlider': (hit) => RetroDesktopSlider(
    label: 'Volume',
    value: .5,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopDatePicker': (hit) => RetroDesktopDatePicker(
    value: DateTime(2026, 11, 6),
    first: DateTime(2026, 11, 6),
    last: DateTime(2026, 11, 6),
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopTimePicker': (hit) => RetroDesktopTimePicker(
    value: const RetroDesktopTime(12, 30),
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopBottomSheet': (hit) => RetroDesktopBottomSheet(
    title: 'Folder',
    onClose: hit,
    child: const Text('Contents'),
  ),
  'RetroDesktopDialogAction': (hit) => RetroDesktopDialogAction<void>(
    'Close',
    enabled: hit != null,
    onPressed: hit,
  ),
  'RetroDesktopMenu': (hit) => RetroDesktopMenu<String>(
    label: 'Commands',
    items: const [RetroDesktopMenuItem('open', 'Open')],
    onSelected: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopMenuAnchor': (hit) => RetroDesktopMenuAnchor<String>(
    items: const [RetroDesktopMenuItem('open', 'Open')],
    onSelected: hit == null ? null : (_) => hit(),
    builder: (context, open) => RetroDesktopButton('Commands', onPressed: open),
  ),
  'RetroDesktopNavigationBar': (hit) => RetroDesktopNavigationBar(
    items: const [
      RetroDesktopNavItem(
        label: 'Files',
        short: 'Files',
        icon: RetroDesktopGlyphs.fileText,
      ),
    ],
    onDestinationSelected: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopNavigationDrawer': (hit) => RetroDesktopNavigationDrawer(
    items: const [
      RetroDesktopNavItem(
        label: 'Files',
        short: 'Files',
        icon: RetroDesktopGlyphs.fileText,
      ),
    ],
    onDestinationSelected: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopNavigationRail': (hit) => RetroDesktopNavigationRail(
    items: const [
      RetroDesktopNavItem(
        label: 'Files',
        short: 'Files',
        icon: RetroDesktopGlyphs.fileText,
      ),
    ],
    onDestinationSelected: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopPageDots': (hit) => RetroDesktopPageDots(
    count: 3,
    selectedIndex: 0,
    label: 'Pages',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopBreadcrumbItem': (hit) => RetroDesktopBreadcrumb(
    items: [
      RetroDesktopBreadcrumbItem('Home', onPressed: hit),
      const RetroDesktopBreadcrumbItem('Notes'),
    ],
  ),
  'RetroDesktopPagination': (hit) => RetroDesktopPagination(
    count: 5,
    page: 1,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopRating': (hit) => RetroDesktopRating(
    label: 'Rating',
    value: 3,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopFileUpload': (hit) => RetroDesktopFileUpload(
    label: 'Attachments',
    onChoose: hit,
    files: const ['notes.txt'],
    onRemove: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopBanner': (hit) =>
      RetroDesktopBanner(title: 'Saved', onDismissed: hit),
  'RetroDesktopSnackBar': (hit) =>
      RetroDesktopSnackBar('Saved', actionLabel: 'Undo', onAction: hit),
  'RetroDesktopSurface': (hit) => RetroDesktopSurface(
    label: 'Open',
    onPressed: hit,
    child: const Text('Contents'),
  ),
  // Round 4's parts.
  'RetroDesktopButtonGroupItem': (hit) => RetroDesktopButtonGroup(
    label: 'Steps',
    items: [RetroDesktopButtonGroupItem(label: 'Next', onPressed: hit)],
  ),
  'RetroDesktopSplitButton': (hit) => RetroDesktopSplitButton(
    label: 'Save',
    onPressed: hit,
    actions: [DesignSplitAction(label: 'Save as', onPressed: () {})],
  ),
  'RetroDesktopTextArea': (hit) => RetroDesktopTextArea(
    hint: 'Notes',
    enabled: hit != null,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopPasswordField': (hit) => RetroDesktopPasswordField(
    label: 'Password',
    enabled: hit != null,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopInputGroup': (hit) => RetroDesktopInputGroup(
    label: 'Site',
    prefix: 'https://',
    enabled: hit != null,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopCombobox': (hit) => RetroDesktopCombobox<String>(
    label: 'Country',
    options: const ['Austria', 'Belgium'],
    enabled: hit != null,
    onSelected: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopRangeSlider': (hit) => RetroDesktopRangeSlider(
    label: 'Price',
    values: const DesignRangeValues(20, 80),
    max: 100,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopCalendar': (hit) => RetroDesktopCalendar(
    controller: DesignCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      currentDate: DateTime(2026, 6, 10),
    ),
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopDateRangePicker': (hit) => RetroDesktopDateRangePicker(
    label: 'Stay',
    firstDate: DateTime(2026),
    lastDate: DateTime(2027),
    initialMonth: DateTime(2026, 6),
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopDataTable': (hit) => RetroDesktopDataTable<String>(
    controller: DesignTableController<String>(
      rows: const ['Ada', 'Grace'],
      columns: [
        DesignTableColumn<String>(id: 'name', label: 'Name', sortKey: (r) => r),
      ],
    ),
    cellText: (row, column) => row,
    onActivate: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopResizable': (hit) => SizedBox(
    height: 200,
    child: RetroDesktopResizable(
      first: const Text('Folders'),
      second: const Text('Files'),
      onChanged: hit == null ? null : (_) => hit(),
    ),
  ),
  'RetroDesktopTreeView': (hit) => RetroDesktopTreeView<String>(
    controller: DesignTreeController<String>(
      roots: const ['Documents'],
      childrenOf: (node) => const [],
    ),
    labelOf: (node) => node,
    onActivate: hit == null ? null : (_) => hit(),
  ),
  'RetroDesktopSheet': (hit) => RetroDesktopSheet(
    title: 'Filters',
    onClose: hit,
    child: const Text('Contents'),
  ),
  'RetroDesktopActionSheet': (hit) => RetroDesktopActionSheet(
    actions: const [],
    cancelLabel: 'Cancel',
    onCancel: hit,
  ),
  'RetroDesktopStatusView': (hit) => RetroDesktopStatusView(
    status: RetroDesktopStatus.error,
    title: 'Could not load',
    onRetry: hit,
  ),
};
