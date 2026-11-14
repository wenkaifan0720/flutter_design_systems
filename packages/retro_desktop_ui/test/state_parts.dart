// Every part and its states, in one table: design review's sheets draw it and
// state_cells_test holds it to a law. A null cell means the state does not
// apply: a field or a slider has no pressed look of its own, and a part with
// no disabled or error state leaves that cell blank (DECISIONS says why).
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

void _noop() {}
void _take<T>(T _) {}

const stateNames = [
  'idle',
  'hovered',
  'pressed',
  'focused',
  'selected',
  'disabled',
  'error',
];

final _june = DateTime(2026, 6);
final _september = DateTime(2026, 9, 30);

class _Doc {
  const _Doc(this.name, this.size);
  final String name;
  final int size;
}

DesignTableController<_Doc> _table(bool selected) {
  final controller = DesignTableController<_Doc>(
    rows: const [_Doc('Budget', 12), _Doc('Letters', 48)],
    columns: [
      DesignTableColumn<_Doc>(
        id: 'name',
        label: 'Name',
        sortKey: (d) => d.name,
      ),
      DesignTableColumn<_Doc>(
        id: 'size',
        label: 'Size',
        numeric: true,
        sortKey: (d) => d.size,
      ),
    ],
  );
  if (selected) controller.selectAll();
  return controller;
}

DesignTreeController<String> _tree(bool selected) {
  final controller = DesignTreeController<String>(
    roots: const ['System'],
    expanded: const ['System'],
    childrenOf: (n) => n == 'System' ? const ['Fonts', 'Sounds'] : const [],
  );
  if (selected) controller.select('Fonts');
  return controller;
}

final Map<String, Widget? Function(String)> stateParts = {
  'Default button': (s) => s == 'selected' || s == 'error'
      ? null
      : RetroDesktopButton(
          'Save',
          isDefaultAction: true,
          onPressed: s == 'disabled' ? null : _noop,
        ),
  'Line button': (s) => s == 'selected' || s == 'error'
      ? null
      : RetroDesktopButton('Open', onPressed: s == 'disabled' ? null : _noop),
  'Quiet button': (s) => s == 'selected' || s == 'error'
      ? null
      : RetroDesktopButton.text(
          'Cancel',
          onPressed: s == 'disabled' ? null : _noop,
        ),
  'Danger button': (s) => s == 'selected' || s == 'error'
      ? null
      : RetroDesktopButton(
          'Delete',
          isDefaultAction: true,
          isDestructiveAction: true,
          onPressed: s == 'disabled' ? null : _noop,
        ),
  'Icon button': (s) => s == 'error'
      ? null
      : RetroDesktopIconButton(
          RetroDesktopGlyphs.search,
          label: 'Search',
          selected: s == 'selected',
          onPressed: s == 'disabled' ? null : _noop,
        ),
  'Link': (s) => s == 'selected' || s == 'error'
      ? null
      : RetroDesktopLink(
          'Read more',
          onPressed: s == 'disabled' ? null : _noop,
        ),
  'Popup': (s) => s == 'selected' || s == 'error'
      ? null
      : RetroDesktopPopupButton(
          'Medium',
          onPressed: s == 'disabled' ? null : _noop,
        ),
  'Text field': (s) => s == 'selected' || s == 'pressed'
      ? null
      : SizedBox(
          width: 240,
          child: RetroDesktopTextField(
            label: 'Name',
            initial: 'Alex Lee',
            enabled: s != 'disabled',
            error: s == 'error' ? 'Enter your name' : null,
          ),
        ),
  'Search field': (s) => s == 'selected' || s == 'pressed'
      ? null
      : SizedBox(
          width: 240,
          child: RetroDesktopSearchField(
            hint: 'Search files',
            enabled: s != 'disabled',
            error: s == 'error' ? 'Nothing found' : null,
          ),
        ),
  'Code field': (s) => s == 'selected' || s == 'pressed'
      ? null
      : RetroDesktopInputOtp(
          label: 'Code',
          length: 4,
          enabled: s != 'disabled',
          error: s == 'error' ? 'Wrong code' : null,
        ),
  'Select': (s) => s == 'selected' || s == 'pressed'
      ? null
      : SizedBox(
          width: 240,
          child: RetroDesktopSelect<String>(
            label: 'Size',
            value: 'm',
            options: const [
              RetroDesktopOption('s', 'Small'),
              RetroDesktopOption('m', 'Medium'),
            ],
            onChanged: s == 'disabled' ? null : _take,
            error: s == 'error' ? 'Pick a size' : null,
          ),
        ),
  'Checkbox': (s) => RetroDesktopCheckbox(
    label: 'Remember me',
    value: s == 'selected',
    isError: s == 'error',
    onChanged: s == 'disabled' ? null : _take,
  ),
  'Radio group': (s) => RetroDesktopRadioGroup<int>(
    label: 'Delivery',
    value: s == 'selected' ? 1 : null,
    error: s == 'error' ? 'Choose one' : null,
    onChanged: s == 'disabled' ? null : _take,
    options: const [
      RetroDesktopRadio(1, 'Standard'),
      RetroDesktopRadio(2, 'Express'),
    ],
  ),
  'Switch': (s) => s == 'error'
      ? null
      : RetroDesktopSwitch(
          label: 'Wi-Fi',
          value: s == 'selected',
          onChanged: s == 'disabled' ? null : _take,
        ),
  'Chip': (s) => s == 'error'
      ? null
      : RetroDesktopChip(
          'Draft',
          selected: s == 'selected',
          enabled: s != 'disabled',
          onPressed: _noop,
        ),
  'Segmented': (s) => s == 'error' || s == 'selected'
      ? null
      : RetroDesktopSegmentedButton<String>(
          label: 'View',
          value: 'b',
          onChanged: s == 'disabled' ? null : _take,
          segments: const [
            RetroDesktopButtonSegment('a', 'List'),
            RetroDesktopButtonSegment('b', 'Grid'),
            RetroDesktopButtonSegment('c', 'Columns'),
          ],
        ),
  'Slider': (s) => s == 'error' || s == 'selected'
      ? null
      : SizedBox(
          width: 240,
          child: RetroDesktopSlider(
            label: 'Volume',
            value: .4,
            onChanged: s == 'disabled' ? null : _take,
          ),
        ),
  'Stepper': (s) => s == 'error' || s == 'selected'
      ? null
      : RetroDesktopNumberField(
          label: 'Copies',
          value: 3,
          max: 9,
          onChanged: s == 'disabled' ? null : _take,
        ),
  'Folder tabs': (s) => s == 'error' || s == 'selected'
      ? null
      : SizedBox(
          width: 300,
          child: RetroDesktopTabBar(
            tabs: const ['Mail', 'Files', 'Notes'],
            onChanged: s == 'disabled' ? null : _take,
          ),
        ),
  'Pagination': (s) => s == 'error' || s == 'selected'
      ? null
      : RetroDesktopPagination(
          count: 5,
          page: 2,
          onChanged: s == 'disabled' ? null : _take,
        ),
  'Rating': (s) => s == 'error' || s == 'selected'
      ? null
      : RetroDesktopRating(
          label: 'Rating',
          value: 3,
          onChanged: _take,
          enabled: s != 'disabled',
        ),
  'List row': (s) => s == 'error'
      ? null
      : SizedBox(
          width: 300,
          child: RetroDesktopListTile(
            title: 'Project notes',
            subtitle: 'Edited today',
            selected: s == 'selected',
            onPressed: _noop,
            enabled: s != 'disabled',
          ),
        ),
  // The rest of the set.
  'Button group': (s) => s == 'selected' || s == 'error'
      ? null
      : RetroDesktopButtonGroup(
          label: 'Week',
          items: [
            for (final word in const ['Previous', 'Today', 'Next'])
              RetroDesktopButtonGroupItem(
                label: word,
                onPressed: s == 'disabled' ? null : _noop,
              ),
          ],
        ),
  'Toggle group': (s) => s == 'error'
      ? null
      : RetroDesktopToggleGroup<String>(
          label: 'Style',
          values: const ['Bold', 'Italic', 'Underline'],
          selected: s == 'selected' ? const {'Bold'} : const {},
          labelOf: (v) => v,
          multiple: true,
          allowEmpty: true,
          onChanged: s == 'disabled' ? null : _take,
        ),
  'Split button': (s) => s == 'selected' || s == 'error'
      ? null
      : RetroDesktopSplitButton(
          label: 'Save',
          onPressed: s == 'disabled' ? null : _noop,
          actions: [DesignSplitAction(label: 'Save as', onPressed: _noop)],
        ),
  'Text area': (s) => s == 'selected' || s == 'pressed'
      ? null
      : SizedBox(
          width: 280,
          child: RetroDesktopTextArea(
            label: 'Notes',
            initial: 'For the next reader',
            enabled: s != 'disabled',
            error: s == 'error' ? 'Too long' : null,
          ),
        ),
  'Password field': (s) => s == 'selected' || s == 'pressed'
      ? null
      : SizedBox(
          width: 280,
          child: RetroDesktopPasswordField(
            label: 'Password',
            enabled: s != 'disabled',
            error: s == 'error' ? 'Too short' : null,
          ),
        ),
  'Input group': (s) => s == 'selected' || s == 'pressed'
      ? null
      : SizedBox(
          width: 300,
          child: RetroDesktopInputGroup(
            label: 'Site',
            prefix: 'https://',
            suffix: '.example.com',
            hint: 'studio',
            enabled: s != 'disabled',
            error: s == 'error' ? 'Taken' : null,
          ),
        ),
  'Form field': (s) => s == 'selected' || s == 'pressed'
      ? null
      : SizedBox(
          width: 280,
          child: RetroDesktopFormField(
            label: 'Email',
            help: 'The receipt goes here',
            required: true,
            enabled: s != 'disabled',
            error: s == 'error' ? 'Enter your email' : null,
            child: RetroDesktopTextField(
              hint: 'name@example.com',
              enabled: s != 'disabled',
            ),
          ),
        ),
  'Combobox': (s) => s == 'selected' || s == 'pressed'
      ? null
      : SizedBox(
          width: 280,
          child: RetroDesktopCombobox<String>(
            label: 'Country',
            hint: 'Type a country',
            options: const ['Austria', 'Belgium'],
            enabled: s != 'disabled',
            error: s == 'error' ? 'Pick a country' : null,
            onSelected: _take,
          ),
        ),
  'Range slider': (s) => s == 'selected' || s == 'pressed' || s == 'error'
      ? null
      : SizedBox(
          width: 280,
          child: RetroDesktopRangeSlider(
            label: 'Price',
            values: const DesignRangeValues(20, 80),
            max: 100,
            onChanged: s == 'disabled' ? null : _take,
          ),
        ),
  'Calendar': (s) => s == 'disabled' || s == 'error'
      ? null
      : SizedBox(
          width: 320,
          child: RetroDesktopCalendar(
            controller: DesignCalendarController(
              firstDate: _june,
              lastDate: _september,
              selectedDate: s == 'selected' ? DateTime(2026, 6, 14) : null,
              currentDate: DateTime(2026, 6, 10),
            ),
          ),
        ),
  'Date range': (s) => s == 'disabled' || s == 'error'
      ? null
      : SizedBox(
          width: 320,
          child: RetroDesktopDateRangePicker(
            label: 'Stay',
            firstDate: _june,
            lastDate: _september,
            initialMonth: _june,
            value: s == 'selected'
                ? DesignDateRange(DateTime(2026, 6, 14), DateTime(2026, 6, 18))
                : null,
            onChanged: _take,
          ),
        ),
  'Colour picker': (s) => s == 'idle' || s == 'hovered' || s == 'focused'
      ? SizedBox(
          width: 280,
          child: RetroDesktopColorPicker(
            controller: DesignColorController(const Color(0xff3366cc)),
          ),
        )
      : null,
  'Menu bar': (s) => s == 'selected' || s == 'error'
      ? null
      : RetroDesktopMenuBar(
          menus: [
            for (final word in const ['File', 'Edit'])
              DesignMenuEntry(
                label: word,
                // A menu with nothing in it is unavailable.
                children: s == 'disabled'
                    ? const []
                    : [DesignMenuEntry(label: 'New', onPressed: _noop)],
              ),
          ],
        ),
  'Data table': (s) => s == 'disabled' || s == 'error'
      ? null
      : SizedBox(
          width: 420,
          child: RetroDesktopDataTable<_Doc>(
            controller: _table(s == 'selected'),
            cellText: (d, c) => c.id == 'name' ? d.name : '${d.size} KB',
          ),
        ),
  'Tree': (s) => s == 'disabled' || s == 'error'
      ? null
      : SizedBox(
          width: 280,
          child: RetroDesktopTreeView<String>(
            label: 'Folders',
            controller: _tree(s == 'selected'),
            labelOf: (n) => n,
          ),
        ),
  'Scroll area': (s) => s == 'idle' || s == 'hovered'
      ? SizedBox(
          width: 280,
          height: 120,
          child: Builder(
            builder: (context) {
              final controller = ScrollController();
              return RetroDesktopScrollArea(
                controller: controller,
                label: 'Files',
                child: ListView(
                  controller: controller,
                  children: [
                    for (var i = 1; i <= 12; i++)
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('Document $i'),
                      ),
                  ],
                ),
              );
            },
          ),
        )
      : null,
  'Resizable': (s) => s == 'idle' || s == 'hovered' || s == 'focused'
      ? const SizedBox(
          width: 320,
          height: 120,
          child: RetroDesktopResizable(
            minFirst: 60,
            minSecond: 60,
            first: Center(child: Text('Folders')),
            second: Center(child: Text('Files')),
          ),
        )
      : null,
  'Reorderable': (s) => s == 'idle' || s == 'hovered' || s == 'focused'
      ? SizedBox(
          width: 280,
          child: RetroDesktopReorderableListView<String>(
            items: const ['Fonts', 'Sounds'],
            labelOf: (i) => i,
            itemBuilder: (context, i) => Text(i),
            onReorder: (from, to) {},
          ),
        )
      : null,
  'Timeline': (s) => s == 'idle'
      ? const RetroDesktopTimeline(
          entries: [
            RetroDesktopTimelineEntry('Ordered', time: '9:02', done: true),
            RetroDesktopTimelineEntry('Packed', current: true),
            RetroDesktopTimelineEntry('Delivered'),
          ],
        )
      : null,
  'Tag': (s) => s == 'idle'
      ? const RetroDesktopTag('Draft', icon: RetroDesktopGlyphs.tag)
      : null,
  'Status view': (s) => s == 'idle'
      ? SizedBox(
          width: 320,
          child: RetroDesktopStatusView(
            status: RetroDesktopStatus.error,
            title: 'Could not load',
            onRetry: _noop,
          ),
        )
      : null,
  'Sheet': (s) => s == 'idle' || s == 'hovered' || s == 'focused'
      ? const SizedBox(
          width: 320,
          height: 180,
          child: RetroDesktopSheet(
            title: 'Filters',
            onClose: _noop,
            child: Text('Kind and date'),
          ),
        )
      : null,
  'Action sheet': (s) => s == 'selected' || s == 'error' || s == 'disabled'
      ? null
      : SizedBox(
          width: 320,
          child: RetroDesktopActionSheet(
            title: 'Budget',
            actions: [
              RetroDesktopActionSheetAction('Duplicate', onPressed: _noop),
              RetroDesktopActionSheetAction(
                'Delete',
                destructive: true,
                onPressed: _noop,
              ),
            ],
            cancelLabel: 'Cancel',
            onCancel: _noop,
          ),
        ),
  'Popover': (s) => s == 'selected' || s == 'error' || s == 'disabled'
      ? null
      : RetroDesktopPopover(
          label: 'Share',
          content: (context) => const Text('Anyone with the link can read it.'),
        ),
  'Line chart': (s) => s == 'idle' ? _chart(RetroDesktopLineChart.new) : null,
  'Bar chart': (s) => s == 'idle' ? _chart(RetroDesktopBarChart.new) : null,
  'Area chart': (s) => s == 'idle' ? _chart(RetroDesktopAreaChart.new) : null,
  'Pie chart': (s) => s == 'idle' ? _chart(RetroDesktopPieChart.new) : null,
};

Widget _chart(
  Widget Function({
    required String label,
    required List<RetroDesktopChartSeries> series,
    List<String> labels,
    double height,
  })
  make,
) => SizedBox(
  width: 320,
  child: make(
    label: 'Visits',
    labels: const ['Mon', 'Tue', 'Wed', 'Thu'],
    height: 140,
    series: [
      RetroDesktopChartSeries('Visits', const [9, 15, 22, 12]),
    ],
  ),
);

/// A cell on its own, on the window's grey, and its boundary: what the sheets
/// save and the law compares.
Future<GlobalKey> pumpStateHost(
  WidgetTester tester,
  RetroDesktopThemeData theme,
  Widget child,
) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => RetroDesktopTheme(data: theme, child: app!),
      home: Builder(
        builder: (context) => ColoredBox(
          color: RetroDesktopTheme.of(context).colors.platinum,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: RetroDesktopTheme.of(context).colors.platinum,
                child: Padding(padding: const EdgeInsets.all(12), child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

/// Puts what is on screen into [state]: the pointer over or down on the part's
/// first control, or the Tab key's focus. The other states are in the widget.
/// Returns the gesture to lift afterwards, if one is down.
Future<TestGesture?> enterState(
  WidgetTester tester,
  String state,
  TestGesture mouse,
) async {
  final field = find.byType(EditableText);
  final press = find.byWidgetPredicate(
    (w) =>
        w is RetroDesktopPressable &&
        (w.onPressed != null || w.onLongPress != null),
  );
  final raw = find.byWidgetPredicate(
    (w) =>
        w is DesignPressable &&
        (w.enabled ?? (w.onPressed != null || w.onLongPress != null)),
  );
  final target = field.evaluate().isNotEmpty
      ? field.first
      : press.evaluate().isNotEmpty
      ? press.first
      : raw.evaluate().isNotEmpty
      ? raw.first
      : null;
  if (state == 'focused') {
    // Keyboard focus as a person gets it: the Tab key, which moves to the
    // part's first stop and turns the traditional highlight on.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return null;
  }
  if (target == null) return null;
  final at = tester.getCenter(target);
  switch (state) {
    case 'hovered':
      await mouse.moveTo(at);
      await tester.pump(const Duration(milliseconds: 200));
      return null;
    case 'pressed':
      final down = await tester.startGesture(at);
      await tester.pump(kPressTimeout);
      await tester.pump(const Duration(milliseconds: 100));
      return down;
  }
  return null;
}

/// The boundary at [key], for the sheets and the law.
RenderRepaintBoundary stateBoundary(GlobalKey key) =>
    key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
