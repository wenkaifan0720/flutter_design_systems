// The behaviour law (behaviour_law.dart) over the package's parts: every part in the library that takes a callback,
// but the page patterns and the sign-in buttons, which the package leaves out.
import 'package:material_ui/material_ui.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import 'behaviour_law.dart';

void main() => behaviourLaw(_parts, reads: (path) => !lawLeftOut(path));

const _nav = [
  Fluent2NavItem(Fluent2Icons.home, 'Home'),
  Fluent2NavItem(Fluent2Icons.folder, 'Files'),
];

const _options = [Fluent2Option('a', 'First'), Fluent2Option('b', 'Second')];

Widget _tall(Widget child) => SizedBox(height: 480, child: child);

final _table = DesignTableController<String>(
  rows: const ['One', 'Two'],
  columns: [
    DesignTableColumn<String>(id: 'n', label: 'Name', sortKey: (s) => s),
  ],
);

final _range = DesignCalendarController(
  firstDate: DateTime(2026, 6),
  lastDate: DateTime(2026, 7, 31),
  mode: DesignCalendarMode.range,
  currentDate: DateTime(2026, 6, 10),
);

final _parts = <String, LawPart>{
  'Fluent2Accordion': LawPart(
    (hit) => Fluent2Accordion(
      items: const [
        Fluent2AccordionItem(
          value: 'a',
          title: 'Advanced',
          child: Text('More'),
        ),
      ],
      onExpansionChanged: hit == null ? null : (_, _) => hit(),
    ),
    disables: false,
  ),
  'Fluent2ActionSheet': LawPart(
    (hit) => Fluent2ActionSheet<String>(
      actions: const [Fluent2ActionSheetAction('a', 'Share')],
      onSelected: (_) => hit?.call(),
    ),
    disables: false,
  ),
  'Fluent2Avatar': LawPart((hit) => Fluent2Avatar(name: 'Sam', onPressed: hit)),
  'Fluent2AvatarGroup': LawPart(
    (hit) => Fluent2AvatarGroup(
      people: const [Fluent2AvatarPerson('Sam Lee')],
      onPressed: hit,
    ),
  ),
  // With no callback a back goes back a page, as Flutter's BackButton.
  'Fluent2Back': LawPart((hit) => Fluent2Back(onPressed: hit), disables: false),
  'Fluent2MessageBar': LawPart(
    (hit) => Fluent2MessageBar(body: 'A new version', onDismiss: hit),
  ),
  'Fluent2BarChart': LawPart(
    (hit) => Fluent2BarChart(
      bars: const [Fluent2Bar('Mon', 3), Fluent2Bar('Tue', 5)],
      onHighlight: lawOn(hit),
    ),
    keys: false,
    focus: false,
    pressable: false,
    disables: false,
  ),
  'Fluent2BottomActionBar': LawPart(
    (hit) => Fluent2BottomActionBar(primaryLabel: 'Pay', onPrimaryPressed: hit),
  ),
  'Fluent2BottomSheet': LawPart(
    (hit) => Fluent2BottomSheet(
      title: 'Share',
      onClose: hit,
      child: const Text('Anyone'),
    ),
  ),
  'Fluent2BreadcrumbItem': LawPart(
    (hit) => Fluent2Breadcrumb(
      items: [
        Fluent2BreadcrumbItem('Home', onPressed: hit),
        const Fluent2BreadcrumbItem('Now'),
      ],
    ),
  ),
  'Fluent2Button': LawPart((hit) => Fluent2Button('Go', onPressed: hit)),
  'Fluent2Calendar': LawPart(
    (hit) =>
        Fluent2Calendar(value: DateTime(2026, 6, 14), onChanged: lawOn(hit)),
    keys: false,
    disables: false,
  ),
  'Fluent2Card': LawPart(
    (hit) => Fluent2Card(
      onPressed: hit,
      label: 'Budget',
      children: const [Text('Budget')],
    ),
  ),
  'Fluent2CarouselView': LawPart(
    (hit) => Fluent2CarouselView(
      label: 'Highlights',
      onChanged: lawOn(hit),
      children: const [Text('One'), Text('Two')],
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'Fluent2Checkbox': LawPart(
    (hit) => Fluent2Checkbox(value: false, label: 'A', onChanged: lawOn(hit)),
  ),
  'Fluent2InteractionTag': LawPart(
    (hit) => Fluent2InteractionTag('Shared', onPressed: hit),
  ),
  'Fluent2Combobox': LawPart(
    (hit) => Fluent2Combobox<String>(
      label: 'Size',
      value: 'a',
      options: _options,
      onChanged: lawOn(hit),
    ),
    keys: false,
    pressable: false,
  ),
  'Fluent2CompletionCheck': LawPart(
    (hit) => Fluent2CompletionCheck(
      value: false,
      label: 'Done',
      onChanged: lawOn(hit),
    ),
  ),
  'Fluent2Composer': lawText((hit) => Fluent2Composer(onSend: lawOn(hit))),
  'Fluent2CompoundButton': LawPart(
    (hit) => Fluent2CompoundButton('Go', secondary: 'Now', onPressed: hit),
  ),
  'Fluent2DataGrid': LawPart(
    (hit) => Fluent2DataGrid<String>(
      controller: _table,
      cell: (row, _) => row,
      onActivate: lawOn(hit),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'Fluent2DatePicker': LawPart(
    (hit) => Fluent2DatePicker(
      label: 'Due',
      value: DateTime(2026, 6, 14),
      onChanged: lawOn(hit),
    ),
    keys: false,
  ),
  'Fluent2DateRangePicker': LawPart(
    (hit) => Fluent2DateRangePicker(controller: _range, onChanged: lawOn(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'Fluent2DescriptionItem': LawPart(
    (hit) => Fluent2DescriptionList(
      properties: [Fluent2DescriptionItem('Owner', 'Sam', onPressed: hit)],
    ),
  ),
  'Fluent2EmptyState': LawPart(
    (hit) =>
        Fluent2EmptyState(title: 'Nothing', actionLabel: 'Add', onAction: hit),
  ),
  'Fluent2ErrorState': LawPart(
    (hit) => Fluent2ErrorState(title: 'Failed', onRetry: hit),
  ),
  'Fluent2FileUpload': LawPart(
    (hit) => Fluent2FileUpload(label: 'Files', onPressed: hit),
  ),
  'Fluent2FloatingActionButton': LawPart(
    (hit) => Fluent2FloatingActionButton(
      icon: Fluent2Icons.add,
      label: 'New',
      onPressed: hit,
    ),
  ),
  'Fluent2IconButton': LawPart(
    (hit) =>
        Fluent2IconButton(Fluent2Icons.share, label: 'Share', onPressed: hit),
  ),
  'Fluent2InputGroup': lawText(
    (hit) => Fluent2InputGroup(label: 'Site', onChanged: lawOn(hit)),
  ),
  'Fluent2Link': LawPart((hit) => Fluent2Link('Read', onPressed: hit)),
  'Fluent2ListItem': LawPart(
    (hit) => Fluent2ListItem(title: 'Budget', onTap: hit),
  ),
  'Fluent2MenuButton': LawPart(
    (hit) => Fluent2MenuButton('Sort', onPressed: hit),
  ),
  'Fluent2NavigationDrawer': LawPart(
    (hit) => _tall(
      Fluent2NavigationDrawer(
        items: _nav,
        selectedIndex: 0,
        onDestinationSelected: (_) => hit?.call(),
        onToggle: hit,
      ),
    ),
    disables: false,
  ),
  'Fluent2NavigationDrawerItem': LawPart(
    (hit) => Fluent2NavigationDrawerItem(
      icon: Fluent2Icons.home,
      label: 'Home',
      selected: false,
      onPressed: hit,
    ),
  ),
  'Fluent2NavigationRail': LawPart(
    (hit) => _tall(
      Fluent2NavigationRail(
        items: _nav,
        selectedIndex: 0,
        onDestinationSelected: lawOn(hit),
      ),
    ),
  ),
  'Fluent2SpinButton': LawPart(
    (hit) =>
        Fluent2SpinButton(label: 'Copies', value: 2, onChanged: lawOn(hit)),
    keys: false,
    pressable: false,
  ),
  'Fluent2PageDots': LawPart(
    (hit) => Fluent2PageDots(
      count: 3,
      selectedIndex: 0,
      label: 'Page 1 of 3',
      onChanged: lawOn(hit),
    ),
    keys: false,
    pressable: false,
  ),
  'Fluent2Pagination': LawPart(
    (hit) => Fluent2Pagination(page: 2, pages: 5, onChanged: lawOn(hit)),
  ),
  'Fluent2PasswordField': lawText(
    (hit) => Fluent2PasswordField(label: 'Password', onChanged: lawOn(hit)),
  ),
  'Fluent2Pressable': LawPart(
    (hit) => Fluent2Pressable(
      onPressed: hit,
      label: 'A tile',
      builder: (context, states) => const Text('A tile'),
    ),
  ),
  'Fluent2RadioGroup': LawPart(
    (hit) => Fluent2RadioGroup<String>(
      value: 'a',
      options: const [Fluent2Radio('a', 'First'), Fluent2Radio('b', 'Second')],
      onChanged: lawOn(hit),
    ),
    keys: false,
  ),
  'Fluent2RangeSlider': LawPart(
    (hit) => Fluent2RangeSlider(
      label: 'Pages',
      values: const DesignRangeValues(20, 60),
      onChanged: lawOn(hit),
    ),
    keys: false,
    pressable: false,
  ),
  'Fluent2Rating': LawPart(
    (hit) => Fluent2Rating(value: 3, label: 'Rating', onChanged: lawOn(hit)),
    keys: false,
    pressable: false,
  ),
  'Fluent2Resizable': LawPart(
    (hit) => SizedBox(
      height: 200,
      child: Fluent2Resizable(
        first: const Text('Files'),
        second: const Text('Details'),
        onChanged: lawOn(hit),
      ),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'Fluent2SearchEntry': LawPart((hit) => Fluent2SearchEntry(onPressed: hit)),
  'Fluent2SearchBox': lawText((hit) => Fluent2SearchBox(onChanged: lawOn(hit))),
  'Fluent2SegmentedButton': LawPart(
    (hit) => Fluent2SegmentedButton<String>(
      label: 'View',
      value: 'a',
      segments: const [
        Fluent2ButtonSegment('a', 'List'),
        Fluent2ButtonSegment('b', 'Board'),
      ],
      onChanged: lawOn(hit),
    ),
    keys: false,
  ),
  'Fluent2Select': LawPart(
    (hit) => Fluent2Select<String>(
      label: 'Size',
      value: 'a',
      options: _options,
      onChanged: lawOn(hit),
    ),
    keys: false,
  ),
  'Fluent2Sheet': LawPart(
    (hit) => _tall(
      Fluent2Sheet(title: 'Details', onClose: hit, child: const Text('Body')),
    ),
    // With no onClose the dismiss pops the sheet's route, so it stays live.
    disables: false,
  ),
  'Fluent2Slider': LawPart(
    (hit) => Fluent2Slider(value: 40, label: 'Volume', onChanged: lawOn(hit)),
    keys: false,
    pressable: false,
  ),
  'Fluent2Toast': LawPart(
    (hit) => Fluent2Toast('Saved', actionLabel: 'Undo', onAction: hit),
  ),
  'Fluent2SplitButton': LawPart(
    (hit) => Fluent2SplitButton(
      'Publish',
      onPressed: hit,
      actions: [
        if (hit != null) Fluent2SplitAction('Schedule', onPressed: hit),
      ],
    ),
  ),
  'Fluent2Stat': LawPart(
    (hit) => Fluent2Stat(label: 'Files', value: '12', onPressed: hit),
  ),
  'Fluent2StatusView': LawPart(
    (hit) => Fluent2StatusView.error(title: 'Failed', onAction: hit),
  ),
  'Fluent2Switch': LawPart(
    (hit) => Fluent2Switch(value: false, label: 'Sync', onChanged: lawOn(hit)),
  ),
  'Fluent2TabList': LawPart(
    (hit) => Fluent2TabList(
      tabs: const ['One', 'Two'],
      selectedIndex: 0,
      onChanged: lawOn(hit),
    ),
    keys: false,
  ),
  'Fluent2Table': LawPart(
    (hit) => Fluent2Table(
      columns: const [Fluent2TableColumn('Name', sortable: true)],
      rows: const [
        Fluent2TableRow(cells: [Fluent2TableCell('Budget')]),
      ],
      onSort: lawOn(hit),
    ),
  ),
  'Fluent2TableRow': LawPart(
    (hit) => Fluent2Table(
      columns: const [Fluent2TableColumn('Name')],
      rows: [
        Fluent2TableRow(
          cells: const [Fluent2TableCell('Budget')],
          onPressed: hit,
        ),
      ],
    ),
  ),
  'Fluent2Tag': LawPart((hit) => Fluent2Tag('Draft', onDeleted: hit)),
  'Fluent2TagGroup': LawPart(
    (hit) => Fluent2TagGroup<String>(
      label: 'Tags',
      items: const [Fluent2TagItem('a', 'Draft')],
      onDeleted: lawOn(hit),
    ),
  ),
  'Fluent2TeachingPopover': LawPart(
    (hit) => Fluent2TeachingPopover(
      title: 'New',
      body: 'A new place for files',
      onPrimaryPressed: hit,
    ),
    disables: false,
  ),
  'Fluent2TextArea': lawText(
    (hit) => Fluent2TextArea(label: 'Note', onChanged: lawOn(hit)),
  ),
  'Fluent2TextField': lawText(
    (hit) => Fluent2TextField(label: 'Name', onChanged: lawOn(hit)),
  ),
  'Fluent2TimePicker': LawPart(
    (hit) => Fluent2TimePicker(label: 'Start', onChanged: lawOn(hit)),
    keys: false,
  ),
  'Fluent2ToggleButton': LawPart(
    (hit) => Fluent2ToggleButton('Bold', value: false, onChanged: lawOn(hit)),
  ),
  'Fluent2ToolbarItem': LawPart(
    (hit) => Fluent2Toolbar(
      items: [
        Fluent2ToolbarItem.button(
          icon: Fluent2Icons.share,
          label: 'Share',
          onPressed: hit,
        ),
      ],
    ),
  ),
  'Fluent2Tree': LawPart(
    (hit) => Fluent2Tree<String>(
      label: 'Files',
      items: const [Fluent2TreeItem('a', 'Reports')],
      onChanged: lawOn(hit),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'Fluent2WeekStrip': LawPart(
    (hit) =>
        Fluent2WeekStrip(value: DateTime(2026, 6, 14), onChanged: lawOn(hit)),
    keys: false,
  ),
  'Fluent2WheelPicker': LawPart(
    (hit) => Fluent2WheelPicker<String>(
      label: 'Size',
      items: const ['Small', 'Large'],
      value: 'Small',
      rows: 3,
      onChanged: lawOn(hit),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
};
