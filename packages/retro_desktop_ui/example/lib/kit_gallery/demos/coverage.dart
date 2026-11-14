/// The rest of the shared component list, live: every part works as it does
/// in an application.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../kit.dart';

Widget kitCoverageDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'The rest of the set',
  sections: [
    kitSection(
      'Buttons together',
      children: [
        kitSpecimenButtonGroup(),
        kitSpecimenToggleGroup(),
        kitSpecimenSplitButton(),
      ],
    ),
    kitSection(
      'More fields',
      children: [
        kitSpecimenTextArea(),
        kitSpecimenPasswordField(),
        kitSpecimenInputGroup(),
        kitSpecimenFormField(),
      ],
    ),
    kitSection('A range', children: [kitSpecimenRangeSlider()]),
    kitSection(
      'More pickers',
      children: [
        kitSpecimenCombobox(),
        kitSpecimenCalendar(),
        kitSpecimenDateRangePicker(),
        kitSpecimenColorPicker(),
      ],
    ),
    kitSection('Menus', children: [kitSpecimenMenuBar()]),
    kitSection(
      'Tables, trees and lists that move',
      children: [
        kitSpecimenDataTable(),
        kitSpecimenTreeView(),
        kitSpecimenScrollArea(),
        kitSpecimenResizable(),
        kitSpecimenReorderable(),
        kitSpecimenTimeline(),
      ],
    ),
    kitSection(
      'Raised panels',
      children: [
        kitSpecimenSheet(),
        kitSheetLauncher(),
        kitSpecimenActionSheet(),
        kitActionSheetLauncher(),
        kitSpecimenPopover(),
      ],
    ),
    kitSection(
      'Tags and states',
      children: [kitSpecimenTag(), kitSpecimenStatusView()],
    ),
  ],
);

/// Keeps a controller for as long as the specimen is on the page.
class _Held<C extends ChangeNotifier> extends StatefulWidget {
  const _Held({required this.make, required this.builder});
  final C Function(BuildContext context) make;
  final Widget Function(C controller) builder;
  @override
  State<_Held<C>> createState() => _HeldState<C>();
}

class _HeldState<C extends ChangeNotifier> extends State<_Held<C>> {
  C? _held;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _held ??= widget.make(context);
  }

  @override
  void dispose() {
    _held?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_held!);
}

Widget kitSpecimenButtonGroup() => kitAction(
  'Moved through the week',
  (press) => RetroDesktopButtonGroup(
    label: 'Week',
    items: [
      RetroDesktopButtonGroupItem(label: 'Previous', onPressed: press),
      RetroDesktopButtonGroupItem(label: 'Today', onPressed: press),
      RetroDesktopButtonGroupItem(label: 'Next', onPressed: press),
    ],
  ),
);
Widget kitSpecimenToggleGroup() => kitValue<Set<String>>(
  const {'Bold'},
  (value, change) => RetroDesktopToggleGroup<String>(
    label: 'Style',
    values: const ['Bold', 'Italic', 'Underline'],
    selected: value,
    labelOf: (v) => v,
    multiple: true,
    onChanged: change,
  ),
);
Widget kitSpecimenSplitButton() => kitAction(
  'Saved',
  (press) => RetroDesktopSplitButton(
    label: 'Save',
    onPressed: press,
    actions: [
      DesignSplitAction(label: 'Save as', onPressed: press),
      DesignSplitAction(label: 'Save a copy', onPressed: press),
    ],
  ),
);
Widget kitSpecimenTextArea() => const RetroDesktopTextArea(
  label: 'Notes',
  hint: 'Anything the next reader should know',
);
Widget kitSpecimenPasswordField() =>
    const RetroDesktopPasswordField(label: 'Password');
Widget kitSpecimenInputGroup() => const RetroDesktopInputGroup(
  label: 'Site',
  prefix: 'https://',
  suffix: '.example.com',
  hint: 'studio',
);
Widget kitSpecimenFormField() => const RetroDesktopFormField(
  label: 'Email',
  help: 'The receipt goes here',
  required: true,
  child: RetroDesktopTextField(hint: 'name@example.com'),
);
Widget kitSpecimenRangeSlider() => kitValue(
  const DesignRangeValues(20, 80),
  (value, change) => RetroDesktopRangeSlider(
    label: 'Price',
    values: value,
    max: 100,
    semanticFormatterCallback: (v) => '\$${v.round()}',
    onChanged: change,
  ),
);

const _countries = [
  'Austria',
  'Belgium',
  'Chile',
  'Denmark',
  'Estonia',
  'Finland',
];
Widget kitSpecimenCombobox() => Builder(
  builder: (context) => RetroDesktopCombobox<String>(
    label: 'Country',
    hint: 'Type a country',
    helper: 'Words no country fits say so in the list',
    options: _countries,
    onSelected: (country) =>
        showRetroDesktopSnackBar(context, 'Chose $country'),
  ),
);
Widget kitSpecimenCalendar() => _Held(
  make: (_) => DesignCalendarController(
    firstDate: DateTime(2026, 6),
    lastDate: DateTime(2026, 9, 30),
    selectedDate: DateTime(2026, 6, 14),
    currentDate: DateTime(2026, 6, 10),
  ),
  builder: (controller) => RetroDesktopCalendar(controller: controller),
);
Widget kitSpecimenDateRangePicker() => kitValue<DesignDateRange?>(
  DesignDateRange(DateTime(2026, 6, 14), DateTime(2026, 6, 18)),
  (value, change) => RetroDesktopDateRangePicker(
    label: 'Stay',
    firstDate: DateTime(2026, 6),
    lastDate: DateTime(2026, 9, 30),
    initialMonth: DateTime(2026, 6),
    value: value,
    onChanged: change,
  ),
);
Widget kitSpecimenColorPicker() => _Held(
  make: (context) =>
      DesignColorController(RetroDesktopTheme.of(context).colors.highlight),
  builder: (controller) => RetroDesktopColorPicker(controller: controller),
);
Widget kitSpecimenMenuBar() => kitAction(
  'Chose from the menu',
  (press) => RetroDesktopMenuBar(
    menus: [
      DesignMenuEntry(
        label: 'File',
        children: [
          DesignMenuEntry(label: 'New', onPressed: press),
          DesignMenuEntry(label: 'Open', onPressed: press),
          DesignMenuEntry(label: 'Close', onPressed: press),
        ],
      ),
      DesignMenuEntry(
        label: 'Edit',
        children: [
          DesignMenuEntry(label: 'Undo', onPressed: press),
          DesignMenuEntry(label: 'Copy', onPressed: press),
        ],
      ),
    ],
  ),
);

class _Doc {
  const _Doc(this.name, this.size);
  final String name;
  final int size;
}

Widget kitSpecimenDataTable() => _Held(
  make: (_) => DesignTableController<_Doc>(
    rows: const [
      _Doc('Budget', 12),
      _Doc('Letters', 48),
      _Doc('Notes', 3),
      _Doc('Plans', 27),
    ],
    columns: [
      DesignTableColumn<_Doc>(
        id: 'name',
        label: 'Name',
        sortKey: (doc) => doc.name,
      ),
      DesignTableColumn<_Doc>(
        id: 'size',
        label: 'Size',
        numeric: true,
        sortKey: (doc) => doc.size,
      ),
    ],
    // It opens sorted by name, so its head shows the mark a press moves.
  )..sort('name'),
  builder: (controller) => RetroDesktopDataTable<_Doc>(
    controller: controller,
    cellText: (doc, column) =>
        column.id == 'name' ? doc.name : '${doc.size} KB',
  ),
);
Widget kitSpecimenTreeView() => _Held(
  make: (_) => DesignTreeController<String>(
    roots: const ['System', 'Documents'],
    expanded: const ['System'],
    childrenOf: (node) => switch (node) {
      'System' => const ['Fonts', 'Sounds'],
      'Documents' => const ['Letters', 'Plans'],
      _ => const [],
    },
  ),
  builder: (controller) => RetroDesktopTreeView<String>(
    label: 'Folders',
    controller: controller,
    labelOf: (node) => node,
  ),
);
// In a well, as a list in a window is: the bare rows on the window's ground, with a bar beside them, read as an
// unfinished part.
Widget kitSpecimenScrollArea() => _Held(
  make: (_) => ScrollController(),
  builder: (controller) => SizedBox(
    height: 140,
    child: RetroDesktopWell(
      padding: EdgeInsets.zero,
      child: RetroDesktopScrollArea(
        controller: controller,
        label: 'Files',
        child: ListView(
          controller: controller,
          padding: const EdgeInsetsDirectional.only(start: 10),
          children: [
            for (var i = 1; i <= 12; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Document $i'),
              ),
          ],
        ),
      ),
    ),
  ),
);
// Two lists side by side, as a Finder window's folders and their files: the handle between them moves the line.
Widget kitSpecimenResizable() => const SizedBox(
  height: 180,
  child: RetroDesktopResizable(
    minFirst: 120,
    minSecond: 120,
    first: _Pane(['Documents', 'Pictures', 'System Folder']),
    second: _Pane(['Project notes', 'Budget', 'Letters']),
  ),
);

class _Pane extends StatelessWidget {
  const _Pane(this.names);
  final List<String> names;
  @override
  Widget build(BuildContext context) => RetroDesktopWell(
    child: SingleChildScrollView(
      child: RetroDesktopList(
        share: true,
        children: [for (final name in names) RetroDesktopListTile(title: name)],
      ),
    ),
  );
}

Widget kitSpecimenReorderable() => kitValue(
  const ['Fonts', 'Sounds', 'Scripts', 'Stationery'],
  (items, change) => RetroDesktopReorderableListView<String>(
    items: items,
    labelOf: (item) => item,
    itemBuilder: (context, item) => Text(item),
    onReorder: (from, to) {
      final next = [...items];
      next.insert(to, next.removeAt(from));
      change(next);
    },
  ),
);
Widget kitSpecimenTimeline() => const RetroDesktopTimeline(
  entries: [
    RetroDesktopTimelineEntry('Ordered', time: '9:02', done: true),
    RetroDesktopTimelineEntry('Packed', current: true),
    RetroDesktopTimelineEntry('Delivered'),
  ],
);
// A side sheet is a pane at the page's end, the page beside it: from 600 up
// 320 wide next to the documents it filters; on a phone the whole width.
Widget kitSpecimenSheet() => kitDismissible(
  'the sheet',
  (close) => LayoutBuilder(
    builder: (context, room) {
      final sheet = RetroDesktopSheet(
        title: 'Filters',
        onClose: close,
        child: const _SheetFilters(),
      );
      if (room.maxWidth < 600) return SizedBox(height: 300, child: sheet);
      return SizedBox(
        height: 300,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(
              child: ExcludeSemantics(
                child: RetroDesktopWell(
                  child: RetroDesktopList(
                    share: true,
                    children: [
                      RetroDesktopListTile(
                        title: 'Project notes',
                        subtitle: 'Edited today',
                      ),
                      RetroDesktopListTile(
                        title: 'Archive',
                        subtitle: '12 documents',
                      ),
                      RetroDesktopListTile(
                        title: 'First sheet',
                        subtitle: 'Edited Monday',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 320, child: sheet),
          ],
        ),
      );
    },
  ),
);

class _SheetFilters extends StatefulWidget {
  const _SheetFilters();
  @override
  State<_SheetFilters> createState() => _SheetFiltersState();
}

class _SheetFiltersState extends State<_SheetFilters> {
  var _documents = true;
  var _pictures = false;
  var _since = 'week';
  @override
  Widget build(BuildContext context) => RetroDesktopColumn(
    gap: 8,
    children: [
      RetroDesktopCheckRow(
        label: 'Documents',
        value: _documents,
        onChanged: (v) => setState(() => _documents = v),
      ),
      RetroDesktopCheckRow(
        label: 'Pictures',
        value: _pictures,
        onChanged: (v) => setState(() => _pictures = v),
      ),
      RetroDesktopSelect<String>(
        label: 'Changed',
        value: _since,
        options: const [
          RetroDesktopOption('week', 'This week'),
          RetroDesktopOption('month', 'This month'),
          RetroDesktopOption('any', 'Any time'),
        ],
        onChanged: (v) => setState(() => _since = v),
      ),
    ],
  );
}

Widget kitSheetLauncher() => Builder(
  builder: (context) => RetroDesktopButton(
    'Open a sheet from the side',
    onPressed: () => showRetroDesktopSheet<void>(
      context,
      title: 'Filters',
      builder: (_) => const _SheetFilters(),
    ),
  ),
);

List<RetroDesktopActionSheetAction> _sheetActions(VoidCallback press) => [
  RetroDesktopActionSheetAction('Duplicate', onPressed: press),
  RetroDesktopActionSheetAction('Delete', destructive: true, onPressed: press),
];
// Shown in a page, the sheet's column stands at the page column's start, as
// every example does; raised, it keeps the middle of its sheet.
Widget kitSpecimenActionSheet() => kitAction(
  'Chose an action',
  (press) => Builder(
    builder: (context) {
      // In its sheet window, as it opens: the choices alone stood as loose buttons on the page's plate.
      final sheet = RetroDesktopBottomSheet(
        inPlace: true,
        child: RetroDesktopActionSheet(
          title: 'Budget',
          actions: _sheetActions(press),
          cancelLabel: 'Cancel',
          onCancel: press,
        ),
      );
      if (MediaQuery.sizeOf(context).width < 600) return sheet;
      return Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          // The sheet's own column width from 600 up, a form cell.
          constraints: const BoxConstraints(maxWidth: 320),
          child: sheet,
        ),
      );
    },
  ),
);
Widget kitActionSheetLauncher() => kitAction(
  'Chose an action',
  (press) => Builder(
    builder: (context) => RetroDesktopButton(
      'Open the actions',
      onPressed: () => showRetroDesktopActionSheet(
        context,
        title: 'Budget',
        actions: _sheetActions(press),
      ),
    ),
  ),
);
Widget kitSpecimenPopover() => RetroDesktopPopover(
  label: 'Share',
  content: (context) => const Text('Anyone with the link can read it.'),
);

Widget kitSpecimenTag() => const Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    RetroDesktopTag('Draft', icon: RetroDesktopGlyphs.tag),
    RetroDesktopTag('Shared'),
  ],
);
Widget kitSpecimenStatusView() => kitValue(
  RetroDesktopStatus.error,
  (status, change) => RetroDesktopColumn(
    gap: 12,
    children: [
      RetroDesktopSegmentedButton<RetroDesktopStatus>(
        label: 'State',
        value: status,
        segments: [
          for (final s in RetroDesktopStatus.values)
            RetroDesktopButtonSegment(s, s.name),
        ],
        onChanged: change,
      ),
      RetroDesktopStatusView(
        status: status,
        title: 'Your documents, ${status.name}',
        onRetry: status == RetroDesktopStatus.error ? () {} : null,
      ),
    ],
  ),
);
