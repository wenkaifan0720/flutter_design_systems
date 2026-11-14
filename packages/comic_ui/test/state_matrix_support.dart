// The state matrix: one row per part an app can press, disable or mark wrong. A builder returning null leaves that state's
// cell blank; the reason is in the pack's DECISIONS.md. `press` is false for a part with no pressed look of its own (a
// field takes the caret, a slider takes the thumb).
import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

/// Which states one cell of the matrix shows.
typedef MatrixFlags = ({bool selected, bool disabled, bool error});

/// One row: its name, its cell's width, whether it has a pressed look, and its builder.
typedef MatrixRow = ({
  String name,
  double width,
  bool press,
  Widget? Function(MatrixFlags f) build,
});

void _tap() {}

void _no(Object? _) {}

MatrixRow _row(
  String name,
  double width,
  Widget? Function(MatrixFlags f) build, {
  bool press = true,
}) => (name: name, width: width, press: press, build: build);

/// A part with neither a selected nor an error state.
MatrixRow _plain(
  String name,
  double width,
  Widget Function(bool off) build, {
  bool press = true,
}) => _row(
  name,
  width,
  (f) => f.selected || f.error ? null : build(f.disabled),
  press: press,
);

/// A part with no state an app can set: only its idle cell is filled, and the pointer and the keyboard act on that.
MatrixRow _idle(String name, double width, Widget Function() build) => _row(
  name,
  width,
  (f) => f.selected || f.disabled || f.error ? null : build(),
  press: false,
);

/// Every row of the matrix.
List<MatrixRow> matrixRows() {
  final day = DateTime(2026, 11, 9);
  return [
    _plain(
      'Button',
      150,
      (off) => ComicButton('Save', onPressed: off ? null : _tap),
    ),
    _plain(
      'Act button',
      150,
      (off) => ComicButton.filled('Save', onPressed: off ? null : _tap),
    ),
    _plain(
      'Line button',
      150,
      (off) => ComicButton('Later', onPressed: off ? null : _tap),
    ),
    _plain(
      'Quiet button',
      150,
      (off) => ComicButton.text('Skip', onPressed: off ? null : _tap),
    ),
    _plain(
      'Danger button',
      150,
      (off) => ComicButton(
        'Delete',
        isDestructiveAction: true,
        icon: ComicGlyphs.trash2,
        onPressed: off ? null : _tap,
      ),
    ),
    _plain(
      'Link',
      150,
      (off) => ComicLink('Read more', onPressed: off ? null : _tap),
    ),
    _row(
      'Icon button',
      100,
      (f) => f.error
          ? null
          : ComicIconButton(
              ComicGlyphs.bell,
              label: 'Alerts',
              selected: f.selected,
              onPressed: f.disabled ? null : _tap,
            ),
    ),
    _plain(
      'Button group',
      240,
      (off) => ComicButtonGroup(
        label: 'Text',
        items: [
          ComicButtonGroupItem('Copy', onPressed: off ? null : _tap),
          ComicButtonGroupItem('Paste', onPressed: off ? null : _tap),
        ],
      ),
    ),
    _row(
      'Toggle group',
      260,
      (f) => f.error
          ? null
          : ComicToggleGroup<String>(
              label: 'Style',
              values: const ['Bold', 'Italic'],
              selected: f.selected ? const {'Bold'} : const {},
              allowEmpty: true,
              labelOf: (value) => value,
              isEnabled: (_) => !f.disabled,
              onChanged: _no,
            ),
    ),
    _plain(
      'Split button',
      200,
      (off) => ComicSplitButton(
        'Save',
        onPressed: off ? null : _tap,
        actions: [ComicSplitAction('Copy', onPressed: off ? null : _tap)],
      ),
    ),
    _row(
      'Chip',
      130,
      (f) => f.error
          ? null
          : ComicChip(
              'Saved',
              selected: f.selected,
              onPressed: f.disabled ? null : _tap,
            ),
    ),
    _row(
      'Checkbox',
      150,
      (f) => ComicCheckbox(
        value: f.selected,
        label: 'Agree',
        isError: f.error,
        onChanged: f.disabled ? null : _no,
      ),
    ),
    _row(
      'Radio group',
      170,
      (f) => f.error
          ? null
          : ComicRadioGroup<int>(
              label: 'Format',
              value: f.selected ? 1 : null,
              options: const [ComicRadio(1, 'Print'), ComicRadio(2, 'Digital')],
              onChanged: f.disabled ? null : _no,
            ),
    ),
    _row(
      'Switch',
      100,
      (f) => f.error
          ? null
          : ComicSwitch(
              value: f.selected,
              label: 'On',
              onChanged: f.disabled ? null : _no,
            ),
    ),
    _plain(
      'Slider',
      200,
      (off) =>
          ComicSlider(label: 'Volume', value: .4, onChanged: off ? null : _no),
      press: false,
    ),
    _plain(
      'Range slider',
      240,
      (off) => ComicRangeSlider(
        label: 'Price',
        values: const DesignRangeValues(.2, .7),
        onChanged: off ? null : _no,
      ),
      press: false,
    ),
    _row(
      'Segmented button',
      250,
      (f) => f.error
          ? null
          : ComicSegmentedButton<int>(
              label: 'View',
              value: f.selected ? 1 : 0,
              segments: const [
                ComicButtonSegment(0, 'Day'),
                ComicButtonSegment(1, 'Week'),
              ],
              onChanged: f.disabled ? null : _no,
            ),
    ),
    _row(
      'Tab bar',
      300,
      (f) => f.error
          ? null
          : ComicTabBar(
              tabs: const ['All', 'Saved', 'Read'],
              selectedIndex: f.selected ? 1 : 0,
              onChanged: f.disabled ? null : _no,
            ),
    ),
    _row(
      'Navigation bar',
      390,
      (f) => f.error
          ? null
          : ComicNavigationBar(
              destinations: const [
                ComicNavItem(
                  label: 'Home',
                  short: 'Home',
                  icon: ComicGlyphs.house,
                ),
                ComicNavItem(
                  label: 'Search',
                  short: 'Search',
                  icon: ComicGlyphs.search,
                ),
              ],
              selectedIndex: f.selected ? 1 : 0,
              onDestinationSelected: f.disabled ? null : _no,
            ),
    ),
    _plain(
      'Number field',
      220,
      (off) => ComicNumberField(
        value: 3,
        unit: 'nights',
        onChanged: off ? null : (_) => _tap(),
      ),
    ),
    _row(
      'Pagination',
      330,
      (f) => f.error
          ? null
          : ComicPagination(
              count: 6,
              page: f.selected ? 4 : 1,
              onChanged: f.disabled ? null : _no,
            ),
    ),
    _row(
      'Select',
      200,
      (f) => f.selected
          ? null
          : ComicSelect<int>(
              label: 'Size',
              value: 1,
              error: f.error ? 'Choose a size' : null,
              options: const [
                ComicSelectOption(1, 'Small'),
                ComicSelectOption(2, 'Large'),
              ],
              onChanged: f.disabled ? null : _no,
            ),
      press: false,
    ),
    _row(
      'Text field',
      200,
      (f) => f.selected
          ? null
          : ComicTextField(
              label: 'Name',
              initialValue: 'Alex',
              enabled: !f.disabled,
              error: f.error ? 'Required' : null,
            ),
      press: false,
    ),
    _row(
      'Text area',
      200,
      (f) => f.selected
          ? null
          : ComicTextArea(
              label: 'Notes',
              maxLines: 2,
              enabled: !f.disabled,
              error: f.error ? 'Required' : null,
            ),
      press: false,
    ),
    _plain(
      'Search field',
      200,
      (off) => ComicSearchField(hint: 'Search', enabled: !off),
      press: false,
    ),
    _row(
      'Password field',
      220,
      (f) => f.selected
          ? null
          : ComicPasswordField(
              label: 'Password',
              enabled: !f.disabled,
              error: f.error ? 'Too short' : null,
            ),
      press: false,
    ),
    _row(
      'Input group',
      220,
      (f) => f.selected
          ? null
          : ComicInputGroup(
              label: 'Price',
              hint: '0.00',
              leading: const [Text('USD')],
              enabled: !f.disabled,
              error: f.error ? 'Required' : null,
            ),
      press: false,
    ),
    _row(
      'Input OTP',
      300,
      (f) => f.selected
          ? null
          : ComicInputOtp(
              label: 'Code',
              length: 4,
              enabled: !f.disabled,
              error: f.error ? 'Wrong code' : null,
            ),
      press: false,
    ),
    _row(
      'Multi select',
      260,
      (f) => f.selected
          ? null
          : ComicMultiSelect<String>(
              label: 'Genres',
              values: const ['Noir'],
              options: const ['Noir', 'Western'],
              enabled: !f.disabled,
              error: f.error ? 'Pick one more' : null,
              onChanged: _no,
            ),
      press: false,
    ),
    _row(
      'Form field',
      240,
      (f) => f.selected
          ? null
          : ComicFormField(
              'Your name',
              enabled: !f.disabled,
              error: f.error ? 'Required' : null,
              child: ComicTextField(hint: 'Name', enabled: !f.disabled),
            ),
      press: false,
    ),
    _row(
      'List tile',
      240,
      (f) => f.error
          ? null
          : ComicListSection(
              children: [
                ComicListTile(
                  title: 'Weekly summary',
                  subtitle: 'Mondays',
                  isFirst: true,
                  selected: f.selected,
                  enabled: !f.disabled,
                  onPressed: _tap,
                ),
              ],
            ),
    ),
    _row(
      'Switch row',
      240,
      (f) => f.error
          ? null
          : ComicSwitchRow(
              label: 'New messages',
              value: f.selected,
              isFirst: true,
              onChanged: f.disabled ? null : _no,
            ),
    ),
    _row(
      'Menu',
      200,
      (f) => f.error
          ? null
          : ComicMenu<int>(
              items: [
                ComicMenuItem(1, 'Save', selected: f.selected),
                const ComicMenuItem(2, 'Share'),
              ],
              onSelected: f.disabled ? null : _no,
            ),
    ),
    _row(
      'Rating',
      250,
      (f) => f.error
          ? null
          : ComicRating(
              label: 'Rating',
              value: f.selected ? 4 : 0,
              onChanged: f.disabled ? null : _no,
            ),
    ),
    // A crumb with no press is a plain word in the trail, not a disabled crumb: no disabled cell.
    _row(
      'Breadcrumb',
      240,
      (f) => f.selected || f.disabled || f.error
          ? null
          : ComicBreadcrumb([
              ComicCrumb('Home', onPressed: _tap),
              const ComicCrumb('Issue 12'),
            ]),
    ),
    _row(
      'Date picker',
      340,
      (f) => f.error
          ? null
          : ComicDatePicker(
              value: f.selected ? day : null,
              currentDate: day,
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
              onChanged: f.disabled ? null : _no,
            ),
    ),
    _plain(
      'Menu bar',
      300,
      (off) => ComicMenuBar(
        menus: [
          DesignMenuEntry(
            label: 'File',
            children: [
              if (!off) DesignMenuEntry(label: 'New', onPressed: _tap),
            ],
          ),
          DesignMenuEntry(
            label: 'Edit',
            children: [
              if (!off) DesignMenuEntry(label: 'Undo', onPressed: _tap),
            ],
          ),
        ],
      ),
    ),
    _row(
      'Calendar',
      360,
      (f) => f.error
          ? null
          : ComicCalendar(
              controller: DesignCalendarController(
                firstDate: DateTime(2026),
                lastDate: DateTime(2027, 12, 31),
                initialMonth: DateTime(2026, 11),
                currentDate: day,
                selectedDate: f.selected ? day : null,
              ),
              onChanged: f.disabled ? null : (_) {},
            ),
    ),
    _row(
      'Date range picker',
      360,
      (f) => f.error
          ? null
          : ComicDateRangePicker(
              firstDate: DateTime(2026),
              lastDate: DateTime(2027, 12, 31),
              currentDate: day,
              value: f.selected
                  ? DesignDateRange(day, DateTime(2026, 11, 13))
                  : null,
              onChanged: f.disabled ? null : _no,
            ),
    ),
    _plain(
      'Wheel picker',
      220,
      (off) => ComicWheelPicker<int>(
        label: 'Copies',
        values: const [1, 2, 3, 4, 5],
        value: 3,
        labelOf: (n) => '$n',
        onChanged: off ? null : _no,
      ),
      press: false,
    ),
    _idle('Key cap', 200, () => const ComicKbd(['Ctrl', 'K'])),
    _idle(
      'Divider',
      240,
      () => const ComicColumn(
        gap: 8,
        children: [
          ComicDivider(),
          ComicDivider(label: 'Or'),
        ],
      ),
    ),
    _idle(
      'Timeline',
      280,
      () => const ComicTimeline(
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
      ),
    ),
    _idle(
      'Description list',
      320,
      () => const ComicDescriptionList(
        entries: [
          ComicDescriptionItem('Writer', 'Ana Ruiz'),
          ComicDescriptionItem('Pages', '24'),
        ],
      ),
    ),
    _idle(
      'Status view',
      340,
      () => ComicColumn(
        gap: 16,
        children: [
          const ComicStatusView.empty(title: 'No issues on this shelf'),
          ComicStatusView.error(title: 'It did not load', onRetry: _tap),
        ],
      ),
    ),
    _plain(
      'Action sheet',
      340,
      (off) => ComicActionSheet<String>(
        title: 'Issue 12',
        actions: [
          ComicSheetAction('Share', value: 'share', enabled: !off),
          ComicSheetAction('Duplicate', value: 'copy', enabled: !off),
        ],
        onSelected: _no,
      ),
    ),
    _plain(
      'Command',
      360,
      (off) => ComicCommand(
        maxHeight: 200,
        commands: [
          DesignCommand(label: 'New issue', enabled: !off, onPressed: _tap),
          DesignCommand(
            label: 'Share the page',
            enabled: !off,
            onPressed: _tap,
          ),
        ],
      ),
    ),
    _row('Data table', 560, (f) {
      if (f.disabled || f.error) return null;
      final table = DesignTableController<String>(
        rows: const ['The Long Night', 'Harbor Lights'],
        pageSize: 4,
        columns: [
          DesignTableColumn(id: 'title', label: 'Issue', sortKey: (row) => row),
        ],
      );
      if (f.selected) table.toggle('The Long Night');
      return ComicDataTable<String>(
        controller: table,
        cellBuilder: (context, row, column) => Text(row),
      );
    }),
    _row('Tree view', 280, (f) {
      if (f.disabled || f.error) return null;
      final tree = DesignTreeController<String>(
        roots: const ['Issue 12', 'Issue 13'],
        expanded: const ['Issue 12'],
        childrenOf: (node) =>
            node == 'Issue 12' ? const ['Cover', 'Story'] : const [],
      );
      if (f.selected) tree.select('Cover');
      return ComicTreeView<String>(controller: tree, labelOf: (node) => node);
    }),
    _idle(
      'Reorderable list',
      300,
      () => ComicReorderableListView<String>(
        items: const ['Pencils', 'Inks'],
        labelOf: (step) => step,
        shrinkWrap: true,
        onReorder: (from, to) {},
        itemBuilder: (context, step) => Text(step),
      ),
    ),
    _idle(
      'Swipe actions',
      320,
      () => ComicSwipeActions(
        initiallyOpen: true,
        endActions: [
          DesignSwipeAction(
            label: 'Delete',
            destructive: true,
            onPressed: _tap,
          ),
        ],
        child: const ComicListTile(title: 'Issue 12', subtitle: 'Slide left'),
      ),
    ),
    _idle('Scroll area', 260, () {
      final held = ScrollController();
      return SizedBox(
        height: 120,
        child: ComicScrollArea(
          controller: held,
          visibility: DesignScrollbarVisibility.always,
          child: ListView(
            controller: held,
            children: [
              for (var i = 1; i <= 10; i++)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text('Letter $i'),
                ),
            ],
          ),
        ),
      );
    }),
    _idle(
      'Resizable',
      340,
      () => const SizedBox(
        height: 100,
        child: ComicResizable(
          first: Center(child: Text('Issues')),
          second: Center(child: Text('The page')),
        ),
      ),
    ),
    _idle(
      'Refresh indicator',
      300,
      () => SizedBox(
        height: 110,
        child: ComicRefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            children: const [ComicListTile(title: 'Pull this list down')],
          ),
        ),
      ),
    ),
    _idle(
      'Side sheet',
      320,
      () => SizedBox(
        height: 240,
        child: ComicSheet(
          title: 'Filters',
          onClose: _tap,
          actions: [ComicButton('Apply', onPressed: _tap)],
          child: const Text('Only unread issues.'),
        ),
      ),
    ),
    _plain(
      'Popover',
      200,
      (off) => ComicPopover(
        label: 'Filters',
        anchorBuilder: (context, anchor) =>
            ComicButton('Filter', onPressed: off ? null : anchor.toggle),
        builder: (context, close) => const Text('Only unread'),
      ),
    ),
    _plain(
      'Hover card',
      200,
      (off) => ComicHoverCard(
        card: const Text('Inks the run from issue 12 on.'),
        child: ComicLink('Ada Okafor', onPressed: off ? null : _tap),
      ),
    ),
    _idle(
      'Carousel',
      360,
      () => ComicCarouselView(
        label: 'Covers',
        height: 120,
        itemWidth: 140,
        children: [
          for (final word in ['One', 'Two', 'Three'])
            ComicPanel(
              label: word,
              child: Center(child: Text(word)),
            ),
        ],
      ),
    ),
    _idle(
      'Line chart',
      360,
      () => const ComicLineChart(
        label: 'Pages read',
        labels: _weeks,
        series: [
          ComicChartSeries('You', [12, 18, 16, 24]),
          ComicChartSeries('The group', [10, 14, 15, 17]),
        ],
        band: ComicChartBand(15, 22, label: 'Target'),
      ),
    ),
    _idle(
      'Area chart',
      360,
      () => const ComicAreaChart(
        label: 'Visitors',
        labels: _weeks,
        series: [
          ComicChartSeries('Visitors', [320, 410, 380, 520]),
        ],
      ),
    ),
    _idle(
      'Bar chart',
      360,
      () => const ComicBarChart(
        label: 'Orders',
        labels: _weeks,
        series: [
          ComicChartSeries('Online', [42, 51, 38, 60]),
          ComicChartSeries('In store', [30, 28, 35, 32]),
        ],
      ),
    ),
  ];
}

const List<String> _weeks = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
