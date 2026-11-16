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

Widget kitSpecimenButtonGroup() => Builder(
  builder: (context) => ComicButtonGroup(
    label: kitSay(context, 'Text'),
    items: [
      ComicButtonGroupItem(kitSay(context, 'Copy'), onPressed: () {}),
      ComicButtonGroupItem(kitSay(context, 'Paste'), onPressed: () {}),
      ComicButtonGroupItem(kitSay(context, 'Clear'), onPressed: () {}),
    ],
  ),
);

Widget kitSpecimenToggleGroup() => kitState<Set<String>>(
  const {'Bold'},
  (context, on, change) => ComicToggleGroup<String>(
    label: kitSay(context, 'Style'),
    values: const ['Bold', 'Italic', 'Underline'],
    selected: on,
    multiple: true,
    allowEmpty: true,
    labelOf: (value) => kitSay(context, value),
    onChanged: change,
  ),
);

Widget kitSpecimenSplitButton() => Builder(
  builder: (context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ComicSplitButton(
      kitSay(context, 'Save'),
      onPressed: () {},
      actions: [
        ComicSplitAction(kitSay(context, 'Save as copy'), onPressed: () {}),
        ComicSplitAction(kitSay(context, 'Save and close'), onPressed: () {}),
      ],
    ),
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

Widget kitSpecimenPasswordField() => Builder(
  builder: (context) => ComicPasswordField(
    label: kitSay(context, 'Password'),
    hint: kitSay(context, 'At least eight letters'),
    helper: kitSay(context, 'Letters and a number.'),
  ),
);

Widget kitSpecimenInputGroup() => Builder(
  builder: (context) => ComicInputGroup(
    label: kitSay(context, 'Price'),
    hint: '0.00',
    leading: [Text(kitSay(context, 'USD'))],
    trailing: [Icon(ComicGlyphs.info, size: 18)],
    keyboardType: TextInputType.number,
  ),
);

Widget kitSpecimenCode() => Builder(
  builder: (context) =>
      ComicInputOtp(label: kitSay(context, 'Verification code')),
);

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

Widget kitSpecimenDivider() => Builder(
  builder: (context) => ComicColumn(
    gap: 8,
    children: [
      ComicDivider(),
      ComicDivider(label: kitSay(context, 'Or')),
    ],
  ),
);

Widget kitSpecimenTimeline() => Builder(
  builder: (context) => ComicTimeline(
    entries: [
      ComicTimelineEntry(
        kitSay(context, 'Pencilled'),
        time: kitSay(context, 'Monday'),
      ),
      ComicTimelineEntry(
        kitSay(context, 'Inked'),
        time: kitSay(context, 'Today'),
        step: ComicTimelineStatus.current,
      ),
      ComicTimelineEntry(
        kitSay(context, 'At the printer'),
        time: kitSay(context, 'Friday'),
        step: ComicTimelineStatus.upcoming,
      ),
    ],
  ),
);

Widget kitSpecimenDescriptionList() => Builder(
  builder: (context) => ComicDescriptionList(
    entries: [
      ComicDescriptionItem(
        kitSay(context, 'Writer'),
        kitSay(context, 'Ana Ruiz'),
      ),
      ComicDescriptionItem(
        kitSay(context, 'Inks'),
        kitSay(context, 'Nia Walker'),
      ),
      ComicDescriptionItem(kitSay(context, 'Pages'), '24'),
    ],
  ),
);

// One state at a time, as an app shows it: four stacked read as four answers at once.
Widget kitSpecimenStatusView() => Builder(
  builder: (context) => kitState<int>(
    2,
    (context, state, change) => ComicColumn(
      gap: 16,
      children: [
        ComicSegmentedButton<int>(
          label: kitSay(context, 'State'),
          value: state,
          segments: [
            ComicButtonSegment(0, kitSay(context, 'Busy')),
            ComicButtonSegment(1, kitSay(context, 'Empty')),
            ComicButtonSegment(2, kitSay(context, 'Error')),
            ComicButtonSegment(3, kitSay(context, 'Done')),
          ],
          onChanged: change,
        ),
        switch (state) {
          0 => ComicStatusView.loading(
            label: kitSay(context, 'Fetching your issues'),
          ),
          1 => ComicStatusView.empty(
            title: kitSay(context, 'No issues on this shelf'),
          ),
          2 => ComicStatusView.error(
            title: kitSay(context, 'The issue did not load'),
            onRetry: () => change(0),
          ),
          _ => ComicStatusView.success(
            title: kitSay(context, 'Sent to the printer'),
            message: kitSay(context, 'It goes out on Friday.'),
          ),
        },
      ],
    ),
  ),
);

Widget kitSpecimenActionSheet() => Builder(
  builder: (context) => Builder(
    builder: (context) => ComicColumn(
      gap: 12,
      children: [
        ComicActionSheet<String>(
          title: kitSay(context, 'Issue 12'),
          actions: [
            ComicSheetAction(kitSay(context, 'Share'), value: 'share'),
            ComicSheetAction(kitSay(context, 'Duplicate'), value: 'copy'),
          ],
          onSelected: (_) {},
        ),
        ComicButton(
          kitSay(context, 'Open as a sheet'),
          onPressed: () => showComicActionSheet<String>(
            context,
            title: kitSay(context, 'Issue 12'),
            actions: [
              ComicSheetAction(kitSay(context, 'Share'), value: 'share'),
              ComicSheetAction(kitSay(context, 'Duplicate'), value: 'copy'),
            ],
          ),
        ),
      ],
    ),
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
      ComicCommand(commands: _commands),
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

Widget kitSpecimenDataTable() => Builder(
  builder: (context) => _Held<DesignTableController<_Issue>>(
    create: () => DesignTableController<_Issue>(
      rows: _issues,
      pageSize: 4,
      columns: [
        DesignTableColumn(
          id: 'title',
          label: kitSay(context, 'Issue'),
          sortKey: (issue) => issue.title,
        ),
        DesignTableColumn(
          id: 'writer',
          label: kitSay(context, 'Writer'),
          sortKey: (issue) => issue.writer,
        ),
        DesignTableColumn(
          id: 'pages',
          label: kitSay(context, 'Pages'),
          sortKey: (issue) => issue.pages,
          numeric: true,
        ),
      ],
    ),
    dispose: (held) => held.dispose(),
    builder: (context, held) => ComicDataTable<_Issue>(
      controller: held,
      cellBuilder: (context, issue, column) =>
          Text(kitSay(context, _cell(issue, column.id))),
    ),
  ),
);

Widget kitScrollArea() => Builder(
  builder: (context) => _Held<ScrollController>(
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
          label: kitSay(context, 'Letters to the editor'),
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
  ),
);

Widget kitResizable() => Builder(
  builder: (context) => SizedBox(
    height: 160,
    child: ComicResizable(
      minFirst: 80,
      minSecond: 80,
      first: Builder(
        builder: (context) => ColoredBox(
          color: ComicTheme.of(context).colors.card,
          child: Center(child: Text(kitSay(context, 'Issues'))),
        ),
      ),
      second: Builder(
        builder: (context) => ColoredBox(
          color: ComicTheme.of(context).colors.inset,
          child: Center(child: Text(kitSay(context, 'The page'))),
        ),
      ),
    ),
  ),
);

Widget kitSpecimenReorderable() => kitState<List<String>>(
  const ['Pencils', 'Inks', 'Letters', 'Colours'],
  (context, steps, change) => ComicReorderableListView<String>(
    items: steps,
    labelOf: (step) => kitSay(context, step),
    shrinkWrap: true,
    onReorder: (from, to) {
      final next = [...steps];
      next.insert(to, next.removeAt(from));
      change(next);
    },
    itemBuilder: (context, step) => Text(kitSay(context, step)),
  ),
);

Widget kitSpecimenSwipeActions() => Builder(
  builder: (context) => ComicColumn(
    gap: 8,
    children: [
      ComicSwipeActions(
        initiallyOpen: true,
        endActions: [
          DesignSwipeAction(
            label: kitSay(context, 'Archive'),
            data: ComicGlyphs.check,
            onPressed: () {},
          ),
          DesignSwipeAction(
            label: kitSay(context, 'Delete'),
            data: ComicGlyphs.delete,
            destructive: true,
            onPressed: () {},
          ),
        ],
        // A row slid open shows its end beside the actions: give it one, as a list row has.
        child: ComicListTile(
          title: kitSay(context, 'Issue 12'),
          subtitle: kitSay(context, 'Slide left'),
          trailing: ComicTag(kitSay(context, 'Unread')),
        ),
      ),
      ComicSwipeActions(
        endActions: [
          DesignSwipeAction(
            label: kitSay(context, 'Delete'),
            destructive: true,
            onPressed: () {},
          ),
        ],
        child: ComicListTile(
          title: kitSay(context, 'Issue 13'),
          subtitle: kitSay(context, 'Slide left'),
          trailing: ComicTag(kitSay(context, 'Read')),
        ),
      ),
    ],
  ),
);

Widget kitRefresh() => Builder(
  builder: (context) => SizedBox(
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
          children: [
            ComicListTile(title: kitSay(context, 'Pull this list down')),
            ComicListTile(title: kitSay(context, 'Issue 12')),
            ComicListTile(title: kitSay(context, 'Issue 13')),
          ],
        ),
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
      label: kitSay(context, 'The run'),
      labelOf: (node) => kitSay(context, node),
    ),
  ),
);

// ------------------------------------------------------------------- raised

// On a stage of its own, the page dimmed under it like a route below a barrier: a sheet beside a hole read as a
// card floating in the column (r3).
Widget kitSpecimenSideSheet() => Builder(
  builder: (context) => SizedBox(
    height: 340,
    child: Builder(
      builder: (context) => Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: Semantics(
              enabled: false,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  kitSay(context, 'Your collection\nIssue 12\nIssue 11'),
                ),
              ),
            ),
          ),
          // The modal's screen: Ben-Day dots over the page, as a live modal draws it.
          ComicScreenScrim(
            animation: kAlwaysCompleteAnimation,
            ink: ComicTheme.of(context).colors.scrim,
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SizedBox(
              width: 320,
              child: ComicSheet(
                title: kitSay(context, 'Filters'),
                showClose: true,
                onClose: () {},
                actions: [
                  ComicButton(kitSay(context, 'Apply'), onPressed: () {}),
                ],
                child: Text(
                  kitSay(context, 'Only unread issues, newest first.'),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

Widget kitOpenSideSheet() => Builder(
  builder: (context) => Builder(
    builder: (context) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ComicButton(
          kitSay(context, 'From the end'),
          onPressed: () => showComicSheet<void>(
            context,
            builder: (context) => ComicSheet(
              title: kitSay(context, 'Filters'),
              actions: [
                ComicButton(
                  kitSay(context, 'Apply'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
              child: Text(kitSay(context, 'Only unread issues, newest first.')),
            ),
          ),
        ),
        ComicButton(
          kitSay(context, 'From the start'),
          onPressed: () => showComicSheet<void>(
            context,
            edge: DesignSheetEdge.start,
            builder: (context) => ComicSheet(
              title: kitSay(context, 'The run'),
              child: Text(kitSay(context, 'Twelve issues so far.')),
            ),
          ),
        ),
      ],
    ),
  ),
);

Widget kitPopover() => Builder(
  builder: (context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ComicPopover(
      label: kitSay(context, 'Filters'),
      anchorBuilder: (context, anchor) =>
          ComicButton(kitSay(context, 'Filter'), onPressed: anchor.toggle),
      builder: (context, close) => ComicColumn(
        gap: 8,
        children: [
          Text(kitSay(context, 'Show only the issues you have not read.')),
          ComicButton(kitSay(context, 'Apply'), onPressed: close),
        ],
      ),
    ),
  ),
);

Widget kitHoverCard() => Builder(
  builder: (context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ComicHoverCard(
      label: kitSay(context, 'About Ada Okafor'),
      card: Text(kitSay(context, 'Ada Okafor inks the run from issue 12 on.')),
      child: ComicLink(kitSay(context, 'Ada Okafor'), onPressed: () {}),
    ),
  ),
);

Widget kitToastStack() => Builder(
  builder: (context) => kitState<int>(
    1,
    (context, next, change) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: ComicButton(
        kitSay(context, 'Raise a notice'),
        onPressed: () {
          showComicSnackBar(
            context,
            KitWords.arabicOf(context)
                ? 'حُفظ العدد $next'
                : 'Issue $next saved',
            actionLabel: kitSay(context, 'Undo'),
            onAction: () {},
            duration: const Duration(seconds: 6),
          );
          change(next + 1);
        },
      ),
    ),
  ),
);
