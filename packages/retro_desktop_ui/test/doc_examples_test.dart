// Every example in the look's docs, compiled and run: an example that stops compiling fails analysis, one missing
// from here fails the first test, and each one builds in a Retro Desktop app without an exception. Written out from
// the examples in lib; an example changed in the docs changes here too.
// ignore_for_file: unused_local_variable — an example names values it shows, not all of which it uses.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_parts.dart';

import 'doc_examples.dart';

// What the examples name without making it, everywhere.
const Widget page = SizedBox();
const Widget child = SizedBox();

// A painter an example paints with.
class _Box extends RetroDesktopPixelPainter {
  const _Box();

  @override
  void paint(RetroDesktopPixelGrid px, Size size) {}

  @override
  bool shouldRepaint(_Box old) => false;
}

void main() {
  testDocExamples(
    self: 'test/doc_examples_test.dart',
    lib: 'lib/src/retro_desktop',
    skip: const {'fonts.dart'},
    wrap: (child) => MaterialApp(
      builder: (context, home) => RetroDesktopTheme(
        data: RetroDesktopThemeData.classic(),
        child: home!,
      ),
      home: child,
    ),
    examples: {
      'RetroDesktopButton': (context) =>
          RetroDesktopButton('Save', isDefaultAction: true, onPressed: () {}),
      'RetroDesktopLink': (context) =>
          RetroDesktopLink('Read more', onPressed: () {}),
      'RetroDesktopButtonGroup': (context) => RetroDesktopButtonGroup(
        items: [
          RetroDesktopButtonGroupItem(
            icon: RetroDesktopGlyphs.chevronLeft,
            tooltip: 'Back',
            onPressed: () {},
          ),
          RetroDesktopButtonGroupItem(
            icon: RetroDesktopGlyphs.chevronRight,
            tooltip: 'Forward',
            onPressed: () {},
          ),
        ],
      ),
      'RetroDesktopToggleGroup': (context) => RetroDesktopToggleGroup<String>(
        values: const ['b', 'i', 'u'],
        selected: const {'b'},
        labelOf: (v) => v.toUpperCase(),
        multiple: true,
        onChanged: (_) {},
      ),
      'RetroDesktopSplitButton': (context) => RetroDesktopSplitButton(
        label: 'Save',
        onPressed: () {},
        actions: [RawSplitAction(label: 'Save as…', onPressed: () {})],
      ),
      'RetroDesktopMotion': (context) =>
          const RetroDesktopMotion(state: Duration(milliseconds: 100)),
      'RetroDesktopPageRoute': (context) => RetroDesktopPageRoute<void>(
        builder: (context) => const Text('Project notes'),
      ),
      'RetroDesktopChart': (context) => const RetroDesktopChart(
        label: 'Weekly activity',
        series: [
          RetroDesktopChartSeries('Visits', [12, 18, 9]),
        ],
        labels: ['Mon', 'Tue', 'Wed'],
      ),
      'RetroDesktopSparkline': (context) => const RetroDesktopSparkline(
        label: 'Visits this week',
        values: [3, 5, 4, 8, 6, 9, 7],
      ),
      'RetroDesktopLineChart': (context) => const RetroDesktopLineChart(
        label: 'Visits',
        series: [
          RetroDesktopChartSeries('Visits', [9, 15, 22, 12]),
        ],
        labels: ['Mon', 'Tue', 'Wed', 'Thu'],
      ),
      'RetroDesktopBarChart': (context) => const RetroDesktopBarChart(
        label: 'Files',
        series: [
          RetroDesktopChartSeries('Documents', [4, 8, 6, 12]),
        ],
        labels: ['Mon', 'Tue', 'Wed', 'Thu'],
      ),
      'RetroDesktopAreaChart': (context) => const RetroDesktopAreaChart(
        label: 'Disk used',
        series: [
          RetroDesktopChartSeries('Disk used', [12, 15, 21, 24, 30]),
        ],
        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
      ),
      'RetroDesktopPieChart': (context) => const RetroDesktopPieChart(
        label: 'Storage',
        series: [
          RetroDesktopChartSeries('Storage', [52, 28, 20]),
        ],
        labels: ['Documents', 'Pictures', 'Other'],
      ),
      'RetroDesktopSystemMark': (context) =>
          const RetroDesktopSystemMark(size: 24),
      'RetroDesktopNavigationBar': (context) => RetroDesktopNavigationBar(
        items: const [
          RetroDesktopNavItem(
            label: 'Files',
            short: 'Files',
            icon: RetroDesktopGlyphs.folder,
          ),
        ],
        onDestinationSelected: (_) {},
      ),
      'RetroDesktopDeskStrip': (context) => const RetroDesktopDeskStrip(
        items: [
          RetroDesktopStripItem(
            'Sunrise 07:22',
            icon: RetroDesktopGlyphs.sunrise,
            highlighted: true,
          ),
          RetroDesktopStripItem('SW 24 km/h', icon: RetroDesktopGlyphs.wind),
        ],
      ),
      'RetroDesktopTab': (context) => const RetroDesktopTab(
        RetroDesktopGlyphs.calendarDays,
        'Today',
        ValueKey('open-today'),
      ),
      'RetroDesktopScaffold': (context) {
        const Widget hero = SizedBox();
        const Widget list = SizedBox();
        return const RetroDesktopScaffold(
          topBar: RetroDesktopAppBar(title: 'Today'),
          body: RetroDesktopDesktop(
            active: 'Today',
            tiles: [
              RetroDesktopWindowColumn(
                span: 8,
                windows: [RetroDesktopWindow(title: 'Today', child: hero)],
              ),
              RetroDesktopWindowColumn(
                span: 4,
                windows: [RetroDesktopWindow(title: 'Recent', child: list)],
              ),
            ],
          ),
        );
      },
      'RetroDesktopBackButton': (context) =>
          RetroDesktopBackButton(onPressed: () => Navigator.maybePop(context)),
      'RetroDesktopAppBar': (context) => RetroDesktopAppBar(
        title: 'Build plan',
        leading: RetroDesktopAppBar.autoLeading(
          context,
          key: const ValueKey('back'),
        ),
      ),
      'RetroDesktopInput': (context) => RetroDesktopInput(
        key: const ValueKey('name'),
        hint: 'Your name',
        onChanged: (text) {},
      ),
      'RetroDesktopMedia': (context) => const RetroDesktopMedia(
        slotId: 'workshop-bench',
        aspect: 4 / 3,
        label: 'The bench',
      ),
      'RetroDesktopPictureCard': (context) {
        void open() {}
        return RetroDesktopPictureCard(
          slotId: 'item-1',
          title: 'First piece',
          subtitle: 'Oak',
          trailing: const RetroDesktopFlag('new'),
          onPressed: open,
        );
      },
      'RetroDesktopLoadingState': (context) =>
          const RetroDesktopLoadingState(title: 'Opening documents'),
      'RetroDesktopErrorState': (context) {
        void retry() {}
        return RetroDesktopErrorState(
          title: 'Could not load',
          message: 'Check your connection.',
          onRetry: retry,
        );
      },
      'SizedBox': (context) =>
          SizedBox(height: RetroDesktopChromeMetrics.targetOf(context)),
      'RetroDesktopStyle': (context) => const RetroDesktopStyle(
        fill: WidgetStatePropertyAll(Color(0xFFE0E0E0)),
      ),
      'RetroDesktopStyleOf': (context) {
        const RetroDesktopStyle? style = null;
        final theme = RetroDesktopTheme.of(context);
        const states = <WidgetState>{};
        return RetroDesktopStyleOf([style, theme.buttonTheme], states).fill;
      },
      'RetroDesktopIconButton': (context) => RetroDesktopIconButton(
        RetroDesktopGlyphs.tag,
        label: 'Tag',
        onPressed: () {},
      ),
      'RetroDesktopTriangleMark': (context) =>
          const RetroDesktopTriangleMark(AxisDirection.right),
      'RetroDesktopPopupButton': (context) => RetroDesktopPopupButton(
        'Workshop',
        icon: RetroDesktopGlyphs.notebook,
        onPressed: () {},
      ),
      'RetroDesktopTextField': (context) => const RetroDesktopTextField(
        hint: 'Search 40 notes',
        leading: Icon(RetroDesktopGlyphs.search),
        trailing: RetroDesktopKbd('/'),
      ),
      'RetroDesktopKbd': (context) => const RetroDesktopKbd('Ctrl+S'),
      'RetroDesktopCheckbox': (context) {
        bool? done = false;
        void setState(VoidCallback change) => change();
        return RetroDesktopCheckbox(
          value: done,
          onChanged: (v) => setState(() => done = v),
          label: 'Option',
        );
      },
      'RetroDesktopCheckRow': (context) {
        var on = false;
        void setState(VoidCallback change) => change();
        return RetroDesktopCheckRow(
          label: 'Sync on start',
          note: 'Over any network',
          value: on,
          onChanged: (v) => setState(() => on = v),
        );
      },
      'RetroDesktopChip': (context) => RetroDesktopChip(
        'walnut',
        leading: const Text('#'),
        onPressed: () {},
      ),
      'RetroDesktopFlag': (context) => const RetroDesktopFlag('2 days late'),
      'RetroDesktopPriority': (context) => const RetroDesktopPriority(1),
      'RetroDesktopLinearProgressIndicator': (context) =>
          const RetroDesktopLinearProgressIndicator(
            value: .6,
            label: 'Uploading files',
          ),
      'RetroDesktopDisclosure': (context) {
        const Widget table = SizedBox();
        return const RetroDesktopDisclosure(
          note: '18 parts',
          title: 'Cut list',
          child: table,
        );
      },
      'RetroDesktopChoiceBox': (context) => RetroDesktopChoiceBox(
        onPressed: () {},
        selected: true,
        child: const Text('Today'),
      ),
      'RetroDesktopChoices': (context) => RetroDesktopChoices(
        options: const [
          RetroDesktopChoice('All'),
          RetroDesktopChoice('Near mint', note: 'Sharp corners'),
        ],
        onChanged: (v) {},
        value: 'All',
      ),
      'RetroDesktopNumberField': (context) => RetroDesktopNumberField(
        value: 2,
        unit: 'coats',
        onChanged: (_) {
          (() {})();
        },
      ),
      'RetroDesktopGroupBox': (context) {
        const Widget list = SizedBox();
        return const RetroDesktopGroupBox(
          title: 'Checklist',
          icon: RetroDesktopGlyphs.listChecks,
          count: '6 of 10',
          child: list,
        );
      },
      'RetroDesktopTabBar': (context) {
        const Widget list = SizedBox();
        return RetroDesktopTabBar(
          tabs: const ['Today', 'Later'],
          onChanged: (i) {},
          selectedIndex: 0,
          counts: const ['6', '5'],
          child: list,
        );
      },
      // A TextField stands on a Material.
      'TextField': (context) => Material(
        child: TextField(
          selectionControls: RetroDesktopTextSelectionControls.of(
            Theme.of(context).platform,
          ),
        ),
      ),
      'TextField 2': (context) => const Material(
        child: TextField(
          contextMenuBuilder: RetroDesktopTextContextMenu.editable,
        ),
      ),
      'RetroDesktopSearchField': (context) =>
          RetroDesktopSearchField(hint: 'Search documents', onChanged: (_) {}),
      'RetroDesktopInputOtp': (context) => RetroDesktopInputOtp(
        label: 'Verification code',
        length: 6,
        onCompleted: (_) {},
      ),
      'RetroDesktopSelect': (context) => RetroDesktopSelect(
        label: 'Sort by',
        value: 'name',
        options: const [
          RetroDesktopOption('name', 'Name'),
          RetroDesktopOption('date', 'Date'),
        ],
        onChanged: (_) {},
      ),
      'RetroDesktopSwitch': (context) => RetroDesktopSwitch(
        value: true,
        label: 'Notifications',
        onChanged: (_) {},
      ),
      'RetroDesktopSwitchRow': (context) => RetroDesktopSwitchRow(
        label: 'Notifications',
        value: true,
        note: 'Show desktop alerts',
        onChanged: (_) {},
      ),
      'RetroDesktopRadioGroup': (context) => RetroDesktopRadioGroup(
        label: 'Appearance',
        value: 'day',
        options: const [
          RetroDesktopRadio('day', 'Day'),
          RetroDesktopRadio('night', 'Night'),
        ],
        onChanged: (_) {},
      ),
      'RetroDesktopSegmentedButton': (context) => RetroDesktopSegmentedButton(
        label: 'View',
        value: 'list',
        segments: const [
          RetroDesktopButtonSegment('list', 'List'),
          RetroDesktopButtonSegment('grid', 'Grid'),
        ],
        onChanged: (_) {},
      ),
      'RetroDesktopSlider': (context) =>
          RetroDesktopSlider(label: 'Volume', value: .5, onChanged: (_) {}),
      'RetroDesktopTextArea': (context) => const RetroDesktopTextArea(
        label: 'Notes',
        hint: 'Anything the courier should know',
        lines: 4,
      ),
      'RetroDesktopPasswordField': (context) =>
          RetroDesktopPasswordField(label: 'Password', onChanged: (_) {}),
      'RetroDesktopInputGroup': (context) => const RetroDesktopInputGroup(
        label: 'Site',
        prefix: 'https://',
        suffix: '.example.com',
        hint: 'studio',
      ),
      'RetroDesktopCombobox': (context) => RetroDesktopCombobox<String>(
        label: 'Country',
        options: const ['Austria', 'Belgium', 'Chile'],
        onSelected: (_) {},
      ),
      'RetroDesktopFormField': (context) => const RetroDesktopFormField(
        label: 'Email',
        help: 'We send the receipt here',
        required: true,
        child: RetroDesktopTextField(hint: 'name@example.com'),
      ),
      'Text': (context) => Text(RetroDesktopFormat.number(1200)),
      'RetroDesktopWindowScope': (context) => const RetroDesktopWindowScope(
        active: true,
        compact: false,
        child: Text('Active pane'),
      ),
      'RetroDesktopWindow': (context) {
        const Widget list = SizedBox();
        return const RetroDesktopWindow(
          title: 'Recent',
          icon: RetroDesktopGlyphs.fileText,
          info: '6 of 40',
          status: ['Synced'],
          child: RetroDesktopWell(child: list),
        );
      },
      'RetroDesktopWell': (context) {
        const rows = <Widget>[Text('One'), Text('Two')];
        return const RetroDesktopWell(child: RetroDesktopList(children: rows));
      },
      'RetroDesktopToolbar': (context) => RetroDesktopToolbar(
        children: [
          const Expanded(child: RetroDesktopTextField(hint: 'Search')),
          RetroDesktopButton(
            'New',
            isDefaultAction: true,
            icon: RetroDesktopGlyphs.plus,
            onPressed: () {},
          ),
        ],
      ),
      'RetroDesktopToolRule': (context) => const RetroDesktopToolRule(),
      'RetroDesktopToolNote': (context) => const RetroDesktopToolNote(
        'Synced',
        icon: RetroDesktopGlyphs.cloudCheck,
      ),
      'RetroDesktopDeskIcon': (context) {
        void open() {}
        void select() {}
        return RetroDesktopDeskIcon(
          'Documents',
          art: const RetroDesktopSystemMark(size: 40),
          selected: true,
          onPressed: select,
          onOpen: open,
        );
      },
      'RetroDesktopWindowShade': (context) {
        void open() {}
        return RetroDesktopWindowShade(
          title: 'Inbox · 18 open',
          icon: RetroDesktopGlyphs.inbox,
          onPressed: open,
        );
      },
      'RetroDesktopAlert': (context) => RetroDesktopAlert(
        icon: RetroDesktopGlyphs.alarmClock,
        title: 'Due at 14:00',
        body: 'The next step wants a warm room.',
        meta: 'in 4 h',
        actions: [
          RetroDesktopButton('Snooze', onPressed: () {}),
          RetroDesktopButton('Open', isDefaultAction: true, onPressed: () {}),
        ],
      ),
      'RetroDesktopDesktop': (context) {
        const Widget list = SizedBox();
        const Widget other = SizedBox();
        return const RetroDesktopDesktop(
          active: 'Today',
          tiles: [
            RetroDesktopWindowColumn(
              span: 8,
              windows: [RetroDesktopWindow(title: 'Today', child: list)],
            ),
            RetroDesktopWindowColumn(
              span: 4,
              windows: [RetroDesktopWindow(title: 'Recent', child: other)],
            ),
          ],
        );
      },
      'RetroDesktopText': (context) {
        final t = RetroDesktopTheme.of(context);
        return RetroDesktopText(
          'Read *The Lamp Room*, ch. 3 to 4',
          style: t.type.row,
        );
      },
      'RetroDesktopEyebrow': (context) =>
          const RetroDesktopEyebrow('Good morning · 09:20'),
      'RetroDesktopHeadline': (context) =>
          const RetroDesktopHeadline('4 left today'),
      'RetroDesktopSectionHeader': (context) => const RetroDesktopSectionHeader(
        'Storage and sync',
        note: 'All changes saved',
        trailing: RetroDesktopButton(
          'Manage',
          size: RetroDesktopButtonSize.small,
        ),
      ),
      'RetroDesktopPartHead': (context) => const RetroDesktopPartHead(
        'Next 12 hours',
        note: 'sky, °C, rain %',
        open: true,
      ),
      'RetroDesktopLabel': (context) => const RetroDesktopLabel('Notebook'),
      'RetroDesktopMonogram': (context) => const RetroDesktopMonogram('AC'),
      'RetroDesktopDataTable': (context) {
        final orders = RawDataTableController<Map<String, String>>(
          rows: const [
            {'id': '1', 'item': 'Chair'},
          ],
          columns: const [RawDataColumn(id: 'item', label: 'Item')],
        );
        addTearDown(orders.dispose);
        return RetroDesktopDataTable<Map<String, String>>(
          controller: orders,
          cellText: (row, column) => row[column.id] ?? '',
        );
      },
      'RetroDesktopScrollArea': (context) {
        const rows = <Widget>[Text('One'), Text('Two')];
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        return RetroDesktopScrollArea(
          controller: scroll,
          child: ListView(controller: scroll, children: rows),
        );
      },
      'RetroDesktopResizable': (context) {
        const Widget folders = SizedBox();
        const Widget files = SizedBox();
        return const RetroDesktopResizable(
          first: folders,
          second: files,
          minFirst: 160,
          minSecond: 240,
        );
      },
      'RetroDesktopReorderableListView': (context) {
        const steps = ['Sand', 'Prime', 'Paint'];
        return RetroDesktopReorderableListView<String>(
          items: steps,
          labelOf: (s) => s,
          itemBuilder: (context, s) => Text(s),
          onReorder: (from, to) {},
        );
      },
      'RetroDesktopTreeView': (context) {
        final tree = DesignTreeController<String>(
          roots: const ['Documents'],
          childrenOf: (name) => const [],
        );
        addTearDown(tree.dispose);
        return RetroDesktopTreeView<String>(
          controller: tree,
          labelOf: (name) => name,
        );
      },
      'RetroDesktopTimeline': (context) => const RetroDesktopTimeline(
        entries: [
          RetroDesktopTimelineEntry('Ordered', time: '9:02', done: true),
          RetroDesktopTimelineEntry('Packed', current: true),
          RetroDesktopTimelineEntry('Delivered'),
        ],
      ),
      'RetroDesktopTag': (context) =>
          const RetroDesktopTag('Draft', icon: RetroDesktopGlyphs.tag),
      'RetroDesktopStatusView': (context) => RetroDesktopStatusView(
        status: RetroDesktopStatus.error,
        title: 'Could not load',
        onRetry: () {},
      ),
      'RetroDesktopUtility': (context) => const RetroDesktopUtility(
        'Synced 09:18',
        icon: RetroDesktopGlyphs.cloudCheck,
        highlighted: true,
      ),
      'RetroDesktopChromeScope': (context) => const RetroDesktopChromeScope(
        brand: 'Workspace',
        nav: [
          RetroDesktopNavItem(
            label: 'Files',
            short: 'Files',
            icon: RetroDesktopGlyphs.folder,
          ),
        ],
        active: 0,
        child: Text('Files'),
      ),
      'RetroDesktopHost': (context) =>
          const RetroDesktopHost(child: Text('Workspace')),
      'RetroDesktopPreview': (context) =>
          const RetroDesktopPreview(child: Text('A page preview')),
      'RetroDesktopScaffold 2': (context) => const RetroDesktopScaffold(
        scroll: false,
        topBar: RetroDesktopAppBar(title: 'Components'),
        body: RetroDesktopInventoryGallery(),
      ),
      'RetroDesktopReach': (context) =>
          const RetroDesktopReach(child: Text('Reachable control')),
      'RetroDesktopFill': (context) => const RetroDesktopFill(
        maxWidth: 480,
        child: Text('Readable content'),
      ),
      'RetroDesktopColumn': (context) => const RetroDesktopColumn(
        gap: 12,
        children: [Text('First'), Text('Second')],
      ),
      'RetroDesktopEqualRow': (context) => const RetroDesktopEqualRow(
        flex: [1, 1],
        gap: 12,
        children: [Text('Left'), Text('Right')],
      ),
      'RetroDesktopRow': (context) => const RetroDesktopRow(
        spans: [1, 2],
        children: [Text('Label'), Text('Value')],
      ),
      'RetroDesktopFitRow': (context) => const RetroDesktopFitRow(
        fill: 0,
        children: [Text('A growing title'), Text('Detail')],
      ),
      'RetroDesktopAutoRow': (context) =>
          const RetroDesktopAutoRow(children: [Text('First'), Text('Second')]),
      'RetroDesktopGridOf': (context) => const RetroDesktopGridOf(
        columns: 2,
        children: [Text('First'), Text('Second')],
      ),
      'RetroDesktopSplit': (context) => RetroDesktopSplit(
        start: const Text('Main content'),
        end: const Text('Details'),
      ),
      'RetroDesktopBalancedText': (context) => RetroDesktopBalancedText(
        'A carefully balanced heading',
        style: RetroDesktopTheme.of(context).type.head,
      ),
      'RetroDesktopBeside': (context) => RetroDesktopBeside(
        object: const Icon(RetroDesktopGlyphs.folder),
        child: const RetroDesktopDescriptionList([
          RetroDesktopFact('Holds', '1.4 GB'),
        ]),
      ),
      'MaterialApp': (context) {
        const Widget home = SizedBox();
        return const MaterialApp(
          localizationsDelegates: [RetroDesktopLocalizations.delegate],
          home: home,
        );
      },
      'RetroDesktopNavigationDrawer': (context) => RetroDesktopNavigationDrawer(
        items: const [
          RetroDesktopNavItem(
            label: 'Files',
            short: 'Files',
            icon: RetroDesktopGlyphs.folder,
          ),
        ],
        onDestinationSelected: (_) {},
      ),
      'RetroDesktopNavigationRail': (context) => RetroDesktopNavigationRail(
        items: const [
          RetroDesktopNavItem(
            label: 'Files',
            short: 'Files',
            icon: RetroDesktopGlyphs.folder,
          ),
        ],
        onDestinationSelected: (_) {},
      ),
      'RetroDesktopPageDots': (context) => RetroDesktopPageDots(
        count: 3,
        selectedIndex: 1,
        label: 'Introduction pages',
        onChanged: (_) {},
      ),
      'RetroDesktopStepProgress': (context) => const RetroDesktopStepProgress(
        count: 4,
        currentStep: 1,
        name: 'Installation',
      ),
      'RetroDesktopDatePicker': (context) => RetroDesktopDatePicker(
        value: DateTime(2026, 11, 6),
        onChanged: (_) {},
      ),
      'RetroDesktopTimePicker': (context) => RetroDesktopTimePicker(
        value: const RetroDesktopTime(9, 30),
        onChanged: (_) {},
      ),
      'RetroDesktopRangeSlider': (context) => RetroDesktopRangeSlider(
        label: 'Price',
        values: const RawRangeValues(20, 80),
        max: 100,
        onChanged: (_) {},
      ),
      'RetroDesktopColorPicker': (context) {
        final example = RetroDesktopColorPicker(
          controller: RawColorController(
            RetroDesktopTheme.of(context).colors.highlight,
          ),
        );
        addTearDown(example.controller.dispose);
        return example;
      },
      'RetroDesktopCalendar': (context) {
        final example = RetroDesktopCalendar(
          controller: RawCalendarController(
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
          ),
        );
        addTearDown(example.controller.dispose);
        return example;
      },
      'RetroDesktopDateRangePicker': (context) => RetroDesktopDateRangePicker(
        label: 'Stay',
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        onChanged: (_) {},
      ),
      'RetroDesktopPixelPaint': (context) {
        const painter = _Box();
        return const RetroDesktopPixelPaint(
          painter: painter,
          child: SizedBox(width: 80, height: 40),
        );
      },
      'RetroDesktopPressable': (context) {
        const Widget tile = SizedBox();
        void open() {}
        return RetroDesktopPressable(
          label: 'Open',
          onPressed: open,
          child: tile,
        );
      },
      'RetroDesktopHighlight': (context) {
        const Widget face = SizedBox();
        return RetroDesktopHighlight(
          shape: RetroDesktopTheme.of(context).shapes.small,
          focused: true,
          child: face,
        );
      },
      'RetroDesktopDialog': (context) => const RetroDesktopDialog(
        title: 'Save changes?',
        message: 'Your document has changed.',
        actions: [
          RetroDesktopDialogAction('Save', value: true, isDefaultAction: true),
        ],
      ),
      'RetroDesktopBottomSheet': (context) => const RetroDesktopBottomSheet(
        title: 'Details',
        child: Text('Document details'),
      ),
      'RetroDesktopMenu': (context) => RetroDesktopMenu(
        label: 'Document actions',
        items: const [
          RetroDesktopMenuItem('open', 'Open'),
          RetroDesktopMenuItem('rename', 'Rename'),
        ],
        onSelected: (_) {},
      ),
      'RetroDesktopTooltipFace': (context) =>
          const RetroDesktopTooltipFace(message: 'Save this document'),
      'RetroDesktopTooltip': (context) => RetroDesktopTooltip(
        message: 'Save this document',
        child: RetroDesktopButton(
          'Save',
          isDefaultAction: true,
          onPressed: () {},
        ),
      ),
      'RetroDesktopSnackBar': (context) => RetroDesktopSnackBar(
        'Document saved',
        actionLabel: 'Undo',
        onAction: () {},
      ),
      'RetroDesktopMenuAnchor': (context) => RetroDesktopMenuAnchor(
        items: const [RetroDesktopMenuItem('open', 'Open')],
        builder: (context, open) =>
            RetroDesktopButton('Actions', onPressed: open),
        onSelected: (_) {},
      ),
      'RetroDesktopDialogAction': (context) => const RetroDesktopDialogAction(
        'Save',
        value: true,
        isDefaultAction: true,
      ),
      'RetroDesktopMenuBar': (context) => RetroDesktopMenuBar(
        menus: [
          RawMenuEntry(
            label: 'File',
            children: [
              RawMenuEntry(label: 'New', shortcut: 'Ctrl+N', onPressed: () {}),
            ],
          ),
        ],
      ),
      'RetroDesktopSheet': (context) {
        const Widget filters = SizedBox();
        return const RetroDesktopSheet(title: 'Filters', child: filters);
      },
      'RetroDesktopActionSheet': (context) => RetroDesktopActionSheet(
        title: 'Project notes',
        actions: [
          RetroDesktopActionSheetAction('Duplicate', onPressed: () {}),
          RetroDesktopActionSheetAction(
            'Delete',
            destructive: true,
            onPressed: () {},
          ),
        ],
        cancelLabel: 'Cancel',
        onCancel: () {},
      ),
      'RetroDesktopPopover': (context) => RetroDesktopPopover(
        label: 'Share',
        content: (context) => const Text('Anyone with the link can view'),
      ),
      'RetroDesktopWell 2': (context) {
        const rows = <Widget>[Text('One'), Text('Two')];
        return const RetroDesktopWell(child: RetroDesktopList(children: rows));
      },
      'RetroDesktopListTile': (context) => RetroDesktopListTile(
        title: 'Port Linden',
        subtitle: 'Cloudy',
        figure: '10°',
        leading: const Icon(RetroDesktopGlyphs.cloud),
        onPressed: () {},
      ),
      'RetroDesktopTaskRow': (context) => RetroDesktopTaskRow(
        title: 'Renew the card',
        subtitle: 'Home · due Tue',
        overdue: '1 day late',
        priority: 3,
        onChanged: (v) {},
      ),
      'RetroDesktopDescriptionList': (context) =>
          const RetroDesktopDescriptionList([
            RetroDesktopFact(
              'Wind',
              'SW 24 km/h',
              icon: RetroDesktopGlyphs.wind,
            ),
          ], leaders: true),
      'RetroDesktopStats': (context) => const RetroDesktopStats([
        ('Open tasks', '18', null),
        ('Rain today', '6.4', 'mm'),
      ]),
      'RetroDesktopReadings': (context) => const RetroDesktopReadings([
        ('High', '11°', null),
        ('Rain today', '6.4', 'mm'),
      ]),
      'RetroDesktopMeasures': (context) => const RetroDesktopMeasures([
        ('PM2.5', '6', 'µg/m³'),
        ('NO₂', '17', 'µg/m³'),
      ]),
      'RetroDesktopSections': (context) {
        const Widget gauge = SizedBox();
        const Widget tree = SizedBox();
        return const RetroDesktopSections(
          children: [
            RetroDesktopSectionHeader('Storage'),
            gauge,
            RetroDesktopDivider.etched(),
            tree,
          ],
        );
      },
      'RetroDesktopAvatar': (context) =>
          const RetroDesktopAvatar('AL', name: 'Alex Lee'),
      'RetroDesktopAvatarGroup': (context) => const RetroDesktopAvatarGroup(
        children: [
          RetroDesktopAvatar('AL', name: 'Alex Lee'),
          RetroDesktopAvatar('JM', name: 'Jo Morgan'),
        ],
      ),
      'RetroDesktopPicture': (context) => const RetroDesktopPicture(
        label: 'Document preview',
        child: Text('Preview'),
      ),
      'RetroDesktopSurface': (context) =>
          const RetroDesktopSurface(child: Text('A desktop plate')),
      'RetroDesktopCard': (context) => const RetroDesktopCard(
        title: 'Documents',
        child: Text('Three documents'),
      ),
      'RetroDesktopListSection': (context) => const RetroDesktopListSection(
        title: 'Preferences',
        children: [
          RetroDesktopListTile(title: 'Appearance'),
          RetroDesktopListTile(title: 'Notifications'),
        ],
      ),
      'RetroDesktopDivider': (context) =>
          const RetroDesktopDivider(indent: 12, endIndent: 12),
      'RetroDesktopAmount': (context) =>
          const RetroDesktopAmount('42', label: 'Storage used', unit: 'MB'),
      'RetroDesktopMeter': (context) =>
          const RetroDesktopMeter(label: 'Storage used', value: .65),
      'RetroDesktopThumbGauge': (context) =>
          const RetroDesktopThumbGauge(share: .28),
      'RetroDesktopGaugeBlock': (context) => const RetroDesktopGaugeBlock(
        value: '1.38 GB',
        of: 'of 5 GB',
        share: .28,
        endLabel: '28%',
        footStart: 'Used',
        footEnd: '3.62 GB free',
      ),
      'RetroDesktopMonthHead': (context) => RetroDesktopMonthHead(
        'November 2026',
        onPrevious: () {},
        onToday: () {},
        onNext: () {},
      ),
      'RetroDesktopMonthGrid': (context) => const RetroDesktopMonthGrid(
        year: 2026,
        month: 11,
        today: 11,
        days: {
          11: RetroDesktopDayMarks(remaining: 4, completed: 1),
          9: RetroDesktopDayMarks(remaining: 1, overdue: true),
        },
      ),
      'RetroDesktopLegend': (context) => const RetroDesktopLegend([
        (RetroDesktopLegendMark.solid, 'open'),
        (RetroDesktopLegendMark.outline, 'done'),
      ]),
      'RetroDesktopPixelSky': (context) => const RetroDesktopPixelSky(
        kinds: [
          RetroDesktopSkyCondition.rain,
          RetroDesktopSkyCondition.cloud,
          RetroDesktopSkyCondition.sun,
        ],
        height: 72,
      ),
      'RetroDesktopHourStrip': (context) => const RetroDesktopHourStrip(
        hours: [
          RetroDesktopHour(
            label: 'Now',
            icon: RetroDesktopGlyphs.cloudRain,
            value: 8,
            reading: '8°',
            kind: RetroDesktopSkyCondition.rain,
            share: .6,
            shareLabel: '60',
          ),
        ],
      ),
      'RetroDesktopRangeShape': (context) => const RetroDesktopRangeShape(
        days: [
          RetroDesktopDayRange(
            weekday: 'Mon',
            date: '16',
            icon: RetroDesktopGlyphs.cloudRain,
            low: 7,
            high: 12,
            share: .95,
            warn: true,
          ),
        ],
        keyLabel: 'Rain chance, rain mm',
        dry: 'dry',
        wet: 'wet',
      ),
      'RetroDesktopHatchBars': (context) => const RetroDesktopHatchBars(
        values: [.8, 1.4, 0, 0],
        max: 1.5,
        axis: ['1.5', '1.0', '0.5', '0'],
        labels: ['09', '', '', '12'],
        notes: [RetroDesktopBarNote(1, '1.4 at 10:00')],
      ),
      'RetroDesktopDayBars': (context) => const RetroDesktopDayBars(
        values: [41, 52, 47],
        labels: ['Thu\n5', 'Fri\n6', 'Sat\n7'],
        limit: 50,
        max: 62,
      ),
      'RetroDesktopScaleBar': (context) => const RetroDesktopScaleBar(
        at: .14,
        bands: ['Good\n0–50', 'Fair\n51–100', 'Poor\n101+'],
        fine: '* for sensitive groups',
      ),
      'RetroDesktopSpanBar': (context) => const RetroDesktopSpanBar(
        from: .31,
        to: .68,
        at: .39,
        fromLabel: '07:22',
        toLabel: '16:21',
        startLabel: '00',
        endLabel: '24',
      ),
      'RetroDesktopEmpty': (context) => const RetroDesktopEmpty(
        title: 'Nothing here yet',
        body: 'Notes you file here show up in this window.',
      ),
      'RetroDesktopListTable': (context) => const RetroDesktopListTable(
        columns: [
          RetroDesktopListTableColumn('Name'),
          RetroDesktopListTableColumn('Edited', width: 100, sorted: true),
        ],
        rows: [
          RetroDesktopListTableRow(
            title: 'A note',
            note: 'Where it is',
            cells: [('09:14', 'today')],
          ),
        ],
        total: 40,
      ),
      'RetroDesktopTable': (context) => const RetroDesktopTable(
        columns: [
          RetroDesktopTableColumn('Part'),
          RetroDesktopTableColumn('Qty', width: 40, figures: true),
        ],
        rows: [
          ['Leg', '4'],
          ['Wedge', '8'],
        ],
        total: ['Total', '12'],
      ),
      'RetroDesktopFolderGrid': (context) => const RetroDesktopFolderGrid(
        items: [
          RetroDesktopFolder(
            'Workshop',
            icon: RetroDesktopGlyphs.hammer,
            note: '9 notes',
            selected: true,
          ),
        ],
      ),
      'RetroDesktopFileGrid': (context) => const RetroDesktopFileGrid(
        items: [RetroDesktopFile('plan.pdf', kind: 'PDF', note: '2 pages')],
      ),
      'RetroDesktopTreeBars': (context) => const RetroDesktopTreeBars(
        rows: [
          RetroDesktopTreeRow('Pictures', '538 MB', share: .39, open: true),
          RetroDesktopTreeRow('Scans', '412 MB', share: .3, level: 1),
        ],
        totalName: 'Total',
        total: '950 MB',
      ),
      'RetroDesktopChecklist': (context) => const RetroDesktopChecklist(
        title: 'Checklist',
        items: [
          RetroDesktopCheckItem('Cut the legs', value: true),
          RetroDesktopCheckItem(
            'Glue up',
            isCurrent: true,
            chips: ['today 14:00'],
            selectedChip: 'today 14:00',
          ),
        ],
      ),
      'RetroDesktopDocument': (context) => const RetroDesktopDocument(
        path: ['Notes', 'Workshop'],
        title: 'Build plan',
        meta: [('Edited', 'today 09:14')],
        tags: ['walnut'],
        paragraphs: ['Seat first, then the legs.'],
      ),
      'RetroDesktopDayTile': (context) => const RetroDesktopDayTile(
        month: 'NOV',
        year: '2026',
        day: '11',
        weekday: 'Wednesday',
      ),
      'RetroDesktopBigFigure': (context) =>
          const RetroDesktopBigFigure('8', unit: '°'),
      'RetroDesktopHeroHeader': (context) => const RetroDesktopHeroHeader(
        object: RetroDesktopDayTile(month: 'NOV', day: '11'),
        eyebrow: 'Good morning',
        title: '4 left today',
        progress: .2,
        progressLabel: '1 of 5 done',
        stats: [('Open', '18', null)],
      ),
      'RetroDesktopFigureHero': (context) => const RetroDesktopFigureHero(
        value: '8',
        unit: '°',
        title: 'Showers',
        note: 'Clearing by 14:00',
        reads: [('High', '11°', null)],
        summary: 'Dry and bright from 14:00.',
      ),
      'RetroDesktopReadingHead': (context) => const RetroDesktopReadingHead(
        value: '28',
        title: 'Good',
        note: 'Main pollutant: ozone.',
      ),
      'RetroDesktopBanner': (context) => const RetroDesktopBanner(
        title: 'Saved',
        message: 'Your changes are ready.',
        tone: RetroDesktopTone.success,
      ),
      'RetroDesktopBadge': (context) =>
          const RetroDesktopBadge(3, label: 'Unread messages'),
      'RetroDesktopCircularProgressIndicator': (context) =>
          const RetroDesktopCircularProgressIndicator(
            value: .6,
            label: 'Upload',
          ),
      'RetroDesktopSkeleton': (context) =>
          const RetroDesktopSkeleton(lines: 3, label: 'Loading messages'),
      'RetroDesktopSuccessState': (context) {
        const Widget files = SizedBox();
        return const RetroDesktopSuccessState(
          title: 'All done',
          message: 'Your files are saved.',
        );
      },
      'RetroDesktopEmptyState': (context) => const RetroDesktopEmptyState(
        title: 'No documents',
        message: 'Create a document to get started.',
      ),
      'PageTransitionsTheme': (context) =>
          const PageTransitionsTheme(builders: retroDesktopPageTransitions),
      'RetroDesktopTheme': (context) =>
          RetroDesktopTheme(data: RetroDesktopThemeData.classic(), child: page),
      'AnimatedRetroDesktopTheme': (context) => AnimatedRetroDesktopTheme(
        data: RetroDesktopThemeData.berry(),
        child: page,
      ),
      'RetroDesktopOnHighlight': (context) =>
          const RetroDesktopOnHighlight(child: Text('Selected item')),
      'Padding': (context) => const Padding(
        padding: EdgeInsets.all(RetroDesktopSpacing.s6),
        child: child,
      ),
      'RetroDesktopBreadcrumb': (context) => RetroDesktopBreadcrumb(
        items: [
          RetroDesktopBreadcrumbItem('Everything', onPressed: () {}),
          const RetroDesktopBreadcrumbItem('Letters'),
        ],
      ),
      'RetroDesktopPagination': (context) =>
          RetroDesktopPagination(count: 12, page: 3, onChanged: (_) {}),
      'RetroDesktopRating': (context) =>
          RetroDesktopRating(label: 'Your rating', value: 4, onChanged: (_) {}),
      'RetroDesktopFileUpload': (context) => RetroDesktopFileUpload(
        label: 'Attachments',
        onChoose: () {},
        files: const ['notes.txt'],
      ),
    },
  );
}
