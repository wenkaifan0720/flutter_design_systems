/// The rest of the shared inventory, every part working: menus open, the palette narrows, the table sorts and pages, a
/// tree folds, rows reorder and notices stack.
library;

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';

Widget kitInventoryDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Everything else',
  sections: [
    kitSection(
      'Actions',
      children: [
        kitSpecimenButtonGroup(),
        kitSpecimenToggleGroup(),
        kitSpecimenSplitButton(),
        kitSpecimenKbd(),
      ],
    ),
    kitSection(
      'Entry',
      children: [
        kitSpecimenPasswordField(),
        kitSpecimenInputGroup(),
        kitSpecimenCode(),
        kitSpecimenMultiSelect(),
        kitSpecimenRangeSlider(),
      ],
    ),
    kitSection(
      'Dates',
      children: [
        kitSpecimenCalendar(),
        kitSpecimenDateRange(),
        kitSpecimenWheelPicker(),
      ],
    ),
    kitSection(
      'Reading',
      children: [
        kitSpecimenDivider(),
        kitSpecimenTimeline(),
        kitSpecimenDescriptionList(),
        kitSpecimenStatusView(),
        kitSpecimenActionSheet(),
      ],
    ),
    kitSection(
      'Structure',
      children: [
        kitSpecimenMenuBar(),
        kitSpecimenCommand(),
        kitSpecimenDataTable(),
        kitScrollArea(),
        kitResizable(),
        kitSpecimenReorderable(),
        kitSpecimenSwipeActions(),
        kitRefresh(),
        kitSpecimenTree(),
      ],
    ),
    kitSection(
      'Raised',
      children: [
        kitSpecimenSideSheet(),
        kitOpenSideSheet(),
        kitPopover(),
        kitHoverCard(),
        kitToastStack(),
      ],
    ),
  ],
);

/// Keeps something a part needs alive for as long as the part is on the page, and disposes of it.
class _Held<T> extends StatefulWidget {
  const _Held({required this.create, required this.builder, this.dispose});
  final T Function() create;
  final Widget Function(BuildContext context, T held) builder;
  final void Function(T held)? dispose;
  @override
  State<_Held<T>> createState() => _HeldState<T>();
}

class _HeldState<T> extends State<_Held<T>> {
  late final T held = widget.create();
  @override
  void dispose() {
    widget.dispose?.call(held);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, held);
}

// ------------------------------------------------------------------ actions

Widget kitSpecimenButtonGroup() => ComicButtonGroup(
  label: 'Text',
  items: [
    ComicButtonGroupItem('Copy', onPressed: () {}),
    ComicButtonGroupItem('Paste', onPressed: () {}),
    ComicButtonGroupItem('Clear', onPressed: () {}),
  ],
);

Widget kitSpecimenToggleGroup() => kitState<Set<String>>(
  const {'Bold'},
  (context, on, change) => ComicToggleGroup<String>(
    label: 'Style',
    values: const ['Bold', 'Italic', 'Underline'],
    selected: on,
    multiple: true,
    allowEmpty: true,
    labelOf: (value) => value,
    onChanged: change,
  ),
);

Widget kitSpecimenSplitButton() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: ComicSplitButton(
    'Save',
    onPressed: () {},
    actions: [
      ComicSplitAction('Save as copy', onPressed: () {}),
      ComicSplitAction('Save and close', onPressed: () {}),
    ],
  ),
);

Widget kitSpecimenKbd() => const Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [
    ComicKbd(['Ctrl', 'K']),
    ComicKbd(['Esc']),
    ComicKbd(['Shift', 'Enter']),
  ],
);

// -------------------------------------------------------------------- entry

Widget kitSpecimenPasswordField() => const ComicPasswordField(
  label: 'Password',
  hint: 'At least eight letters',
  helper: 'Letters and a number.',
);

Widget kitSpecimenInputGroup() => const ComicInputGroup(
  label: 'Price',
  hint: '0.00',
  leading: [Text('USD')],
  trailing: [Icon(ComicGlyphs.info, size: 18)],
  keyboardType: TextInputType.number,
);

Widget kitSpecimenCode() => const ComicInputOtp(label: 'Verification code');

Widget kitSpecimenMultiSelect() => kitState<List<String>>(
  const ['Noir', 'Western'],
  (context, genres, change) => ComicMultiSelect<String>(
    label: 'Genres',
    hint: 'Add a genre',
    values: genres,
    options: const ['Noir', 'Western', 'Horror', 'Romance', 'Science fiction'],
    onChanged: change,
  ),
);

Widget kitSpecimenRangeSlider() => kitState<DesignRangeValues>(
  const DesignRangeValues(.2, .7),
  (context, values, change) => ComicRangeSlider(
    label: 'Price',
    values: values,
    valueLabel: (value) => '\$${(value * 40).round()}',
    onChanged: change,
  ),
);

// ------------------------------------------------------- dates and colours

Widget kitSpecimenCalendar() => _Held<DesignCalendarController>(
  create: () => DesignCalendarController(
    firstDate: DateTime(2026),
    lastDate: DateTime(2027, 12, 31),
    initialMonth: DateTime(2026, 11),
    currentDate: kitToday,
  ),
  dispose: (held) => held.dispose(),
  builder: (context, held) =>
      ComicCalendar(controller: held, onChanged: (_) {}),
);

// A stay already chosen, so the range reads as one.
Widget kitSpecimenDateRange() => kitState<DesignDateRange?>(
  DesignDateRange(DateTime(2026, 11, 13), DateTime(2026, 11, 16)),
  (context, stay, change) => ComicDateRangePicker(
    firstDate: DateTime(2026),
    lastDate: DateTime(2027, 12, 31),
    value: stay,
    currentDate: kitToday,
    onChanged: change,
  ),
);

Widget kitSpecimenWheelPicker() => kitState<int>(
  3,
  (context, copies, change) => ComicWheelPicker<int>(
    label: 'Copies',
    values: const [1, 2, 3, 4, 5, 6, 7, 8],
    value: copies,
    labelOf: (n) => '$n',
    onChanged: change,
  ),
);

// ------------------------------------------------------------------ reading

Widget kitSpecimenDivider() => const ComicColumn(
  gap: 8,
  children: [
    ComicDivider(),
    ComicDivider(label: 'Or'),
  ],
);

Widget kitSpecimenTimeline() => const ComicTimeline(
  entries: [
    ComicTimelineEntry('Pencilled', time: 'Monday'),
    ComicTimelineEntry(
      'Inked',
      time: 'Today',
      step: ComicTimelineStatus.current,
    ),
    ComicTimelineEntry(
      'At the printer',
      time: 'Friday',
      step: ComicTimelineStatus.upcoming,
    ),
  ],
);

Widget kitSpecimenDescriptionList() => const ComicDescriptionList(
  entries: [
    ComicDescriptionItem('Writer', 'Ana Ruiz'),
    ComicDescriptionItem('Inks', 'Nia Walker'),
    ComicDescriptionItem('Pages', '24'),
  ],
);

// One state at a time, as an app shows it: four stacked read as four answers at once.
Widget kitSpecimenStatusView() => kitState<int>(
  2,
  (context, state, change) => ComicColumn(
    gap: 16,
    children: [
      ComicSegmentedButton<int>(
        label: 'State',
        value: state,
        segments: const [
          ComicButtonSegment(0, 'Busy'),
          ComicButtonSegment(1, 'Empty'),
          ComicButtonSegment(2, 'Error'),
          ComicButtonSegment(3, 'Done'),
        ],
        onChanged: change,
      ),
      switch (state) {
        0 => const ComicStatusView.loading(label: 'Fetching your issues'),
        1 => const ComicStatusView.empty(title: 'No issues on this shelf'),
        2 => ComicStatusView.error(
          title: 'The issue did not load',
          onRetry: () => change(0),
        ),
        _ => const ComicStatusView.success(
          title: 'Sent to the printer',
          message: 'It goes out on Friday.',
        ),
      },
    ],
  ),
);

Widget kitSpecimenActionSheet() => Builder(
  builder: (context) => ComicColumn(
    gap: 12,
    children: [
      ComicActionSheet<String>(
        title: 'Issue 12',
        actions: const [
          ComicSheetAction('Share', value: 'share'),
          ComicSheetAction('Duplicate', value: 'copy'),
        ],
        onSelected: (_) {},
      ),
      ComicButton(
        'Open as a sheet',
        onPressed: () => showComicActionSheet<String>(
          context,
          title: 'Issue 12',
          actions: const [
            ComicSheetAction('Share', value: 'share'),
            ComicSheetAction('Duplicate', value: 'copy'),
          ],
        ),
      ),
    ],
  ),
);

// ---------------------------------------------------------------- structure

Widget kitSpecimenMenuBar() => ComicMenuBar(
  menus: [
    DesignMenuEntry(
      label: 'File',
      children: [
        DesignMenuEntry(label: 'New', shortcut: 'Ctrl+N', onPressed: () {}),
        DesignMenuEntry(label: 'Open', shortcut: 'Ctrl+O', onPressed: () {}),
        const DesignMenuEntry.divider(),
        DesignMenuEntry(
          label: 'Export',
          children: [
            DesignMenuEntry(label: 'As PDF', onPressed: () {}),
            DesignMenuEntry(label: 'As images', onPressed: () {}),
          ],
        ),
      ],
    ),
    DesignMenuEntry(
      label: 'Edit',
      children: [
        DesignMenuEntry(label: 'Undo', shortcut: 'Ctrl+Z', onPressed: () {}),
        const DesignMenuEntry(label: 'Redo', shortcut: 'Ctrl+Y'),
      ],
    ),
    DesignMenuEntry(
      label: 'View',
      children: [
        DesignMenuEntry(label: 'Show grid', checked: true, onPressed: () {}),
        DesignMenuEntry(label: 'Show bleed', checked: false, onPressed: () {}),
      ],
    ),
  ],
);

final List<DesignCommand> _commands = [
  DesignCommand(
    label: 'New issue',
    group: 'Issues',
    shortcut: 'Ctrl+N',
    data: ComicGlyphs.plus,
    onPressed: () {},
  ),
  DesignCommand(
    label: 'Search issues',
    group: 'Issues',
    data: ComicGlyphs.search,
    keywords: const ['find'],
    onPressed: () {},
  ),
  DesignCommand(
    label: 'Share the page',
    group: 'Page',
    data: ComicGlyphs.share,
    onPressed: () {},
  ),
  DesignCommand(
    label: 'Send to the printer',
    group: 'Page',
    data: ComicGlyphs.send,
    onPressed: () {},
  ),
  const DesignCommand(label: 'Archive the run', group: 'Page', enabled: false),
];

Widget kitSpecimenCommand() => Builder(
  builder: (context) => ComicColumn(
    gap: 12,
    children: [
      ComicCommand(commands: _commands, maxHeight: 240),
      ComicButton(
        'Open over the page',
        onPressed: () => showComicCommand(context, commands: _commands),
      ),
    ],
  ),
);

typedef _Issue = ({String title, String writer, int pages});

const List<_Issue> _issues = [
  (title: 'The Long Night', writer: 'Ana Ruiz', pages: 24),
  (title: 'Harbor Lights', writer: 'Nia Walker', pages: 32),
  (title: 'Second Printing', writer: 'Ada Okafor', pages: 28),
  (title: 'The Inkwell', writer: 'Ana Ruiz', pages: 20),
  (title: 'Paper Moon', writer: 'Jun Sato', pages: 36),
  (title: 'Last Panel', writer: 'Ada Okafor', pages: 22),
  (title: 'Old Newsprint', writer: 'Jun Sato', pages: 26),
];

String _cell(_Issue issue, String column) => switch (column) {
  'title' => issue.title,
  'writer' => issue.writer,
  _ => '${issue.pages}',
};

Widget kitSpecimenDataTable() => _Held<DesignTableController<_Issue>>(
  create: () => DesignTableController<_Issue>(
    rows: _issues,
    pageSize: 4,
    columns: [
      DesignTableColumn(
        id: 'title',
        label: 'Issue',
        sortKey: (issue) => issue.title,
      ),
      DesignTableColumn(
        id: 'writer',
        label: 'Writer',
        sortKey: (issue) => issue.writer,
      ),
      DesignTableColumn(
        id: 'pages',
        label: 'Pages',
        sortKey: (issue) => issue.pages,
        numeric: true,
      ),
    ],
  ),
  dispose: (held) => held.dispose(),
  builder: (context, held) => ComicDataTable<_Issue>(
    controller: held,
    cellBuilder: (context, issue, column) => Text(_cell(issue, column.id)),
  ),
);

Widget kitScrollArea() => _Held<ScrollController>(
  create: ScrollController.new,
  dispose: (held) => held.dispose(),
  // The region stands in a panel, so the line the scroll cuts reads as the region's edge, not a fault.
  builder: (context, held) => SizedBox(
    height: 180,
    child: ComicPanel(
      bleed: true,
      child: ComicScrollArea(
        controller: held,
        visibility: DesignScrollbarVisibility.always,
        label: 'Letters to the editor',
        child: ListView(
          controller: held,
          padding: const EdgeInsetsDirectional.only(start: 16),
          children: [
            for (var i = 1; i <= 14; i++)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
                child: Text('Letter $i to the editor'),
              ),
          ],
        ),
      ),
    ),
  ),
);

Widget kitResizable() => SizedBox(
  height: 160,
  child: ComicResizable(
    minFirst: 80,
    minSecond: 80,
    first: Builder(
      builder: (context) => ColoredBox(
        color: ComicTheme.of(context).colors.card,
        child: const Center(child: Text('Issues')),
      ),
    ),
    second: Builder(
      builder: (context) => ColoredBox(
        color: ComicTheme.of(context).colors.inset,
        child: const Center(child: Text('The page')),
      ),
    ),
  ),
);

Widget kitSpecimenReorderable() => kitState<List<String>>(
  const ['Pencils', 'Inks', 'Letters', 'Colours'],
  (context, steps, change) => ComicReorderableListView<String>(
    items: steps,
    labelOf: (step) => step,
    shrinkWrap: true,
    onReorder: (from, to) {
      final next = [...steps];
      next.insert(to, next.removeAt(from));
      change(next);
    },
    itemBuilder: (context, step) => Text(step),
  ),
);

Widget kitSpecimenSwipeActions() => ComicColumn(
  gap: 8,
  children: [
    ComicSwipeActions(
      initiallyOpen: true,
      endActions: [
        DesignSwipeAction(
          label: 'Archive',
          data: ComicGlyphs.check,
          onPressed: () {},
        ),
        DesignSwipeAction(
          label: 'Delete',
          data: ComicGlyphs.delete,
          destructive: true,
          onPressed: () {},
        ),
      ],
      // A row slid open shows its end beside the actions: give it one, as a list row has.
      child: const ComicListTile(
        title: 'Issue 12',
        subtitle: 'Slide left',
        trailing: ComicTag('Unread'),
      ),
    ),
    ComicSwipeActions(
      endActions: [
        DesignSwipeAction(label: 'Delete', destructive: true, onPressed: () {}),
      ],
      child: const ComicListTile(
        title: 'Issue 13',
        subtitle: 'Slide left',
        trailing: ComicTag('Read'),
      ),
    ),
  ],
);

Widget kitRefresh() => SizedBox(
  height: 200,
  // A mouse may pull it too, here where there is no finger.
  child: ScrollConfiguration(
    behavior: const MaterialScrollBehavior().copyWith(
      dragDevices: PointerDeviceKind.values.toSet(),
    ),
    child: ComicRefreshIndicator(
      onRefresh: () => Future<void>.delayed(const Duration(seconds: 1)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: const [
          ComicListTile(title: 'Pull this list down'),
          ComicListTile(title: 'Issue 12'),
          ComicListTile(title: 'Issue 13'),
        ],
      ),
    ),
  ),
);

Widget kitSpecimenTree() => _Held<DesignTreeController<String>>(
  create: () => DesignTreeController<String>(
    roots: const ['Issue 12', 'Issue 13'],
    expanded: const ['Issue 12'],
    childrenOf: (node) => switch (node) {
      'Issue 12' => const ['Cover', 'Story'],
      'Story' => const ['Page 1', 'Page 2'],
      'Issue 13' => const ['Cover art'],
      _ => const [],
    },
  ),
  dispose: (held) => held.dispose(),
  // A tree's rows are a menu's opaque faces: it stands in a panel, as a menu's rows stand in the menu.
  builder: (context, held) => ComicPanel(
    shrinkWrap: true,
    child: ComicTreeView<String>(
      controller: held,
      label: 'The run',
      labelOf: (node) => node,
    ),
  ),
);

// ------------------------------------------------------------------- raised

// On a stage of its own, the page dimmed under it like a route below a barrier: a sheet beside a hole read as a
// card floating in the column (r3).
Widget kitSpecimenSideSheet() => SizedBox(
  height: 340,
  child: Builder(
    builder: (context) => Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: Semantics(
            enabled: false,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Your collection\nIssue 12\nIssue 11'),
            ),
          ),
        ),
        ColoredBox(color: ComicTheme.of(context).colors.scrim),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 320,
            child: ComicSheet(
              title: 'Filters',
              showClose: true,
              onClose: () {},
              actions: [ComicButton('Apply', onPressed: () {})],
              child: const Text('Only unread issues, newest first.'),
            ),
          ),
        ),
      ],
    ),
  ),
);

Widget kitOpenSideSheet() => Builder(
  builder: (context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ComicButton(
        'From the end',
        onPressed: () => showComicSheet<void>(
          context,
          builder: (context) => ComicSheet(
            title: 'Filters',
            actions: [
              ComicButton(
                'Apply',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            child: const Text('Only unread issues, newest first.'),
          ),
        ),
      ),
      ComicButton(
        'From the start',
        onPressed: () => showComicSheet<void>(
          context,
          edge: DesignSheetEdge.start,
          builder: (context) => const ComicSheet(
            title: 'The run',
            child: Text('Twelve issues so far.'),
          ),
        ),
      ),
    ],
  ),
);

Widget kitPopover() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: ComicPopover(
    label: 'Filters',
    anchorBuilder: (context, anchor) =>
        ComicButton('Filter', onPressed: anchor.toggle),
    builder: (context, close) => ComicColumn(
      gap: 8,
      children: [
        const Text('Show only the issues you have not read.'),
        ComicButton('Apply', onPressed: close),
      ],
    ),
  ),
);

Widget kitHoverCard() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: ComicHoverCard(
    label: 'About Ada Okafor',
    card: const Text('Ada Okafor inks the run from issue 12 on.'),
    child: ComicLink('Ada Okafor', onPressed: () {}),
  ),
);

Widget kitToastStack() => kitState<int>(
  1,
  (context, next, change) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ComicButton(
      'Raise a notice',
      onPressed: () {
        showComicSnackBar(
          context,
          'Issue $next saved',
          actionLabel: 'Undo',
          onAction: () {},
          duration: const Duration(seconds: 6),
        );
        change(next + 1);
      },
    ),
  ),
);
