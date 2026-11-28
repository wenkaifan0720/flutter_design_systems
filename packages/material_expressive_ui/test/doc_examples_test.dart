// Every doc example in the look's lib, compiled and run (ui_core 0.2.0's
// template). Each `/// Example:` (a fenced dart block in the package) is
// written out below as the body of an entry, so an example that stops
// compiling fails analysis; the first test fails when lib has an example
// this file lacks; the rest build each widget example (and run each call)
// in an Expressive app.
//
// An example names what its caller has: a value, a callback, a controller.
// Its entry makes them first, as the caller would; a value that changes is
// a StatefulBuilder's, whose `setState` the example calls.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/corners.dart';

import 'doc_examples.dart';

/// What the caller made for an example, disposed once its tree is gone.
final List<VoidCallback> _disposers = [];

T _own<T extends ChangeNotifier>(T value) {
  _disposers.add(value.dispose);
  return value;
}

/// Runs [show] (an example that opens a menu, a sheet, a snack bar) once
/// the frame that asked for it is done, as a tap would.
Object? _later(BuildContext context, VoidCallback show) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) show();
  });
  return null;
}

void _nothing() {}

const _destinations = [
  ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
  ExpressiveNavItem(ExpressiveSymbols.search, 'Search'),
];

const _week = [
  ExpressiveChartPoint('Mon', 32),
  ExpressiveChartPoint('Tue', 18),
  ExpressiveChartPoint('Wed', 44),
  ExpressiveChartPoint('Thu', 26),
  ExpressiveChartPoint('Fri', 51),
  ExpressiveChartPoint('Sat', 12),
  ExpressiveChartPoint('Sun', 38),
];

final Map<String, DocExample> _examples = {
  'ExpressiveThemeData.shapeScheme': (context) =>
      ExpressiveThemeData.baseline().copyWith(
        shapeScheme: ExpressiveThemeData.defaultShapeScheme.copyWith(
          corners: ExpressiveThemeData.defaultShapeScheme.corners.copyWith(
            medium: 16,
          ),
        ),
      ),
  'expressiveOutline': (context) => expressiveOutline(
    context.expressiveTheme,
    const ExpressiveComponentThemeData(),
    const {},
    context.expressiveTheme.shapes.medium,
  ),
  'expressiveCornersOver': (context) => expressiveCornersOver(
    context.expressiveTheme,
    const RawCorners(bottomStart: RawCorner.none, bottomEnd: RawCorner.none),
    context.expressiveTheme.shapes.medium,
  ),
  'ExpressiveColorScheme.copyWith': (context) =>
      context.expressiveTheme.colors.copyWith(primary: const Color(0xFF006A60)),
  'ExpressiveComponentThemeData on a theme': (context) {
    final data = ExpressiveThemeData.preset('baseline', Brightness.light)
        .copyWith(
          chipTheme: ExpressiveComponentThemeData(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? const Color(0xFFFFD8E4)
                  : null,
            ),
          ),
        );
    return ExpressiveTheme(
      data: data,
      child: const ExpressiveChip(
        'Vegetarian',
        selected: true,
        onPressed: _nothing,
      ),
    );
  },
  'ExpressiveComponentThemeData on a part': (context) {
    const style = ExpressiveComponentThemeData(
      backgroundColor: WidgetStatePropertyAll(Color(0xff6750a4)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
    );
    return const ExpressiveFilledButton(
      'Save',
      style: style,
      onPressed: _nothing,
    );
  },
  'ExpressiveAppBarScroll': (context) => const ExpressiveAppBar(
    title: 'Trips',
    large: true,
    scroll: ExpressiveAppBarScroll(heightOffset: -28),
  ),
  'ExpressiveAppBarAction': (context) {
    void share() {}
    return ExpressiveAppBarAction(
      ExpressiveSymbols.share,
      label: 'Share',
      onPressed: share,
    );
  },
  'ExpressiveAppBar': (context) {
    void search() {}
    return ExpressiveAppBar(
      title: 'Trips',
      subtitle: '3 upcoming',
      large: true,
      collapsing: true,
      actions: [
        ExpressiveAppBarAction(
          ExpressiveSymbols.search,
          label: 'Search',
          onPressed: search,
        ),
      ],
    );
  },
  'ExpressiveSearchBar': (context) {
    const veg = false;
    void toggleVeg() {}
    Widget recipeResults(String query) => Text('Recipes for $query');
    return ExpressiveSearchBar(
      hintText: 'Search recipes',
      avatar: const ExpressiveAvatar(name: 'Ana Ruiz'),
      filters: [
        ExpressiveChip('Vegetarian', selected: veg, onPressed: toggleVeg),
      ],
      results: (context, query) => recipeResults(query),
    );
  },
  'ExpressiveSearchField': (context) {
    void filter(String query) {}
    void endSearch() {}
    return ExpressiveSearchField(
      hintText: 'Search messages',
      onChanged: filter,
      onCancel: endSearch,
    );
  },
  'ExpressiveTag': (context) =>
      const ExpressiveTag('New', tone: ExpressiveTone.primary),
  'ExpressiveButton': (context) {
    void save() {}
    void share() {}
    ExpressiveFilledButton('Save', onPressed: save);
    ExpressiveFilledButton.tonal(
      'Share',
      size: ExpressiveButtonSize.large,
      onPressed: share,
    );
    return null;
  },
  'ExpressiveFilledButton.styleFrom': (context) {
    void delete() {}
    final c = context.expressiveTheme.colors;
    ExpressiveFilledButton(
      'Delete',
      style: ExpressiveFilledButton.styleFrom(
        backgroundColor: c.error,
        foregroundColor: c.onError,
      ),
      onPressed: delete,
    );
    return null;
  },
  'ExpressiveSegmentedButton': (context) {
    const range = 0;
    void setRange(int value) {}
    return ExpressiveSegmentedButton<int>(
      segments: [
        const ExpressiveButtonSegment(0, 'Day'),
        const ExpressiveButtonSegment(1, 'Week'),
      ],
      value: range,
      onChanged: setRange,
    );
  },
  'ExpressiveMultiChoiceSegmentedButton': (context) {
    const amenities = {'wifi'};
    void setAmenities(Set<String> value) {}
    return ExpressiveMultiChoiceSegmentedButton<String>(
      segments: [
        const ExpressiveButtonSegment('wifi', 'Wi-Fi'),
        const ExpressiveButtonSegment('pool', 'Pool'),
      ],
      value: amenities,
      onChanged: setAmenities,
    );
  },
  'ExpressiveToggleGroup': (context) {
    const view = 'list';
    void setView(String value) {}
    return ExpressiveToggleGroup<String>(
      label: 'View',
      segments: const [
        ExpressiveButtonSegment('list', 'List', icon: ExpressiveSymbols.list),
        ExpressiveButtonSegment(
          'grid',
          'Grid',
          icon: ExpressiveSymbols.gridView,
        ),
      ],
      value: view,
      onChanged: setView,
    );
  },
  'ExpressiveCard': (context) {
    void open() {}
    return ExpressiveCard.elevated(
      onPressed: open,
      padding: const EdgeInsets.all(ExpressiveSpacing.s16),
      child: const Text('Ridge trail'),
    );
  },
  'ExpressiveCarouselView': (context) {
    const trips = [(slot: 'trip-lisbon'), (slot: 'trip-porto')];
    return ExpressiveCarouselView.multiBrowse(
      itemCount: trips.length,
      height: 220,
      itemBuilder: (context, i) => ExpressiveMedia(slotId: trips[i].slot),
    );
  },
  'ExpressivePageDots': (context) {
    final controller = _own(ExpressiveCarouselController());
    return ExpressivePageDots(
      pageCount: 5,
      page: controller.currentItem,
      onChanged: controller.animateToItem,
    );
  },
  'ExpressiveChart': (context) {
    const week = _week;
    return const ExpressiveChart.bar(
      points: week,
      highlight: 6,
      semanticLabel: 'Minutes read, last 7 days',
    );
  },
  'ExpressiveLineChart': (context) {
    const pulse = [
      ExpressiveChartPoint('Mon', 64),
      ExpressiveChartPoint('Tue', 71),
      ExpressiveChartPoint('Wed', 78),
    ];
    return const ExpressiveLineChart(
      points: pulse,
      semanticLabel: 'Pulse this week, 64 to 78 beats a minute',
    );
  },
  'ExpressiveAreaChart': (context) {
    final mood = [
      for (var day = 1; day <= 14; day++)
        ExpressiveChartPoint('$day', (day * 7 % 10).toDouble()),
    ];
    return ExpressiveAreaChart(
      points: mood,
      highlight: 11,
      semanticLabel: 'Mood over two weeks',
    );
  },
  'ExpressiveBarChart': (context) {
    const week = _week;
    return const ExpressiveBarChart(
      points: week,
      highlight: 5,
      semanticLabel: 'Minutes read this week',
    );
  },
  'ExpressivePieChart': (context) {
    const spend = [
      ExpressiveChartPoint('Rent', 1400),
      ExpressiveChartPoint('Food', 620),
      ExpressiveChartPoint('Travel', 400),
    ];
    return const ExpressivePieChart(
      points: spend,
      centerValue: '2,420',
      centerLabel: 'Spent in March',
    );
  },
  'ExpressiveSparkline': (context) {
    const pulse = [
      ExpressiveChartPoint('Mon', 64),
      ExpressiveChartPoint('Tue', 71),
      ExpressiveChartPoint('Wed', 78),
    ];
    return const SizedBox(
      width: 88,
      height: 36,
      child: ExpressiveSparkline(points: pulse),
    );
  },
  'ExpressiveChip': (context) {
    var veg = false;
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveChip(
        'Vegetarian',
        selected: veg,
        onPressed: () => setState(() => veg = !veg),
      ),
    );
  },
  'ExpressiveChipRow': (context) {
    var open = false;
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveChipRow(
        children: [
          ExpressiveChip(
            'Open now',
            selected: open,
            onPressed: () => setState(() => open = !open),
          ),
        ],
      ),
    );
  },
  'ExpressiveChoiceTile': (context) {
    var source = 'hand';
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveChoiceTile(
        icon: ExpressiveSymbols.sync,
        title: 'Bluetooth arm cuff',
        supportingText: 'Readings arrive on their own',
        selected: source == 'cuff',
        onPressed: () => setState(() => source = 'cuff'),
      ),
    );
  },
  'ExpressiveChoiceGroup': (context) {
    var source = 'cuff';
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveChoiceGroup<String>.single(
        value: source,
        onChanged: (v) => setState(() => source = v),
        semanticLabel: 'How readings arrive',
        options: const [
          ExpressiveChoiceOption(
            value: 'cuff',
            title: 'Bluetooth arm cuff',
            icon: ExpressiveSymbols.sync,
          ),
          ExpressiveChoiceOption(
            value: 'hand',
            title: 'Enter by hand',
            icon: ExpressiveSymbols.edit,
          ),
        ],
      ),
    );
  },
  'ExpressiveColorPicker': (context) {
    const brand = Color(0xFF6750A4);
    void setBrand(Color color) {}
    return ExpressiveColorPicker(value: brand, onChanged: setBrand);
  },
  'ExpressiveText': (context) => const ExpressiveText.headline(
    'Morning pages',
    size: ExpressiveTextSize.small,
  ),
  'ExpressiveCounter': (context) {
    const steps = 8421;
    return ExpressiveCounter(
      steps,
      style: context.expressiveTheme.type.displaySmall,
    );
  },
  'ExpressiveStat': (context) => const ExpressiveStat(
    label: 'Pages this week',
    value: 42,
    supporting: '+6 from last week',
    trend: ExpressiveTrend.up,
  ),
  'ExpressiveAmount': (context) => const ExpressiveAmount(
    r'$1,299.00',
    size: ExpressiveAmountSize.display,
    was: r'$1,499.00',
  ),
  'ExpressiveRating': (context) =>
      const ExpressiveRating(value: 4.5, size: ExpressiveRatingSize.small),
  'ExpressiveMessageBubble': (context) => const ExpressiveMessageBubble(
    text: 'See you at the trailhead',
    side: ExpressiveMessageSide.outgoing,
    timestamp: '9:41',
    status: ExpressiveMessageStatus.read,
  ),
  'ExpressiveDataTable': (context) {
    final orders = _own(
      RawDataTableController<String>(
        rows: ['#4821', '#4822'],
        columns: const [RawDataColumn(id: 'order', label: 'Order')],
      ),
    );
    return ExpressiveDataTable<String>(
      controller: orders,
      cellBuilder: (context, order, column) => Text(order),
    );
  },
  'ExpressiveTimeline': (context) => const ExpressiveTimeline(
    currentStep: 1,
    entries: [
      ExpressiveTimelineEntry(title: 'Order placed', time: '09:12'),
      ExpressiveTimelineEntry(title: 'Shipped', time: '14:40'),
    ],
  ),
  'ExpressiveDescriptionList': (context) => const ExpressiveDescriptionList(
    items: [
      ExpressiveDescriptionItem('Order', '#4821'),
      ExpressiveDescriptionItem('Placed', '14 March'),
    ],
  ),
  'ExpressiveBanner': (context) {
    void retry() {}
    return ExpressiveBanner(
      icon: ExpressiveSymbols.wifi,
      title: 'You are offline',
      message: 'Changes will sync when you reconnect.',
      actions: [ExpressiveBannerAction('Retry', onPressed: retry)],
    );
  },
  'ExpressiveSkeleton': (context) => const ExpressiveSkeleton.text(lines: 2),
  'ExpressiveLoadingState': (context) => const ExpressiveScaffold(
    body: ExpressiveLoadingState(message: 'Loading plants'),
  ),
  'ExpressiveErrorState': (context) {
    void reload() {}
    return ExpressiveErrorState(
      title: 'Could not load',
      message: 'Check your connection',
      onRetry: reload,
    );
  },
  'ExpressiveEmptyState': (context) {
    void add() {}
    return ExpressiveEmptyState(
      icon: ExpressiveSymbols.inbox,
      title: 'Nothing here yet',
      actionLabel: 'Add one',
      onAction: add,
    );
  },
  'ExpressiveSuccessState': (context) {
    void close() {}
    return ExpressiveSuccessState(
      title: 'Table booked',
      message: 'We sent the details to your inbox.',
      actionLabel: 'Done',
      onAction: close,
    );
  },
  'ExpressiveStatusView': (context) {
    void reload() {}
    return ExpressiveStatusView.error(
      title: 'Could not load',
      message: 'Check your connection',
      onRetry: reload,
    );
  },
  'ExpressiveFileUpload': (context) {
    void pickFiles() {}
    void remove(int index) {}
    const chosen = [ExpressiveChosenFile('receipt.pdf', detail: '84 KB')];
    return ExpressiveFileUpload(
      labelText: 'Drop a receipt here',
      helperText: 'PDF or JPG, up to 10 MB',
      onBrowse: pickFiles,
      files: chosen,
      onRemove: remove,
    );
  },
  'ExpressiveInputGroup': (context) => ExpressiveInputGroup(
    hintText: 'example.com',
    leading: [ExpressiveInputGroup.text('https://')],
  ),
  'ExpressiveFormField': (context) {
    const on = true;
    void setOn(bool value) {}
    return ExpressiveFormField(
      labelText: 'Notify me',
      helperText: 'At most once a day',
      child: ExpressiveSwitch(value: on, onChanged: setOn),
    );
  },
  'ExpressiveListTile': (context) {
    void openWifi() {}
    return ExpressiveListTile(
      title: const Text('Wi-Fi'),
      subtitle: const Text('Home network'),
      leading: const Icon(ExpressiveSymbols.wifi),
      onTap: openWifi,
    );
  },
  'ExpressiveListSection': (context) {
    void openWifi() {}
    void openBluetooth() {}
    return ExpressiveListSection(
      header: 'Network',
      children: [
        ExpressiveListTile(title: const Text('Wi-Fi'), onTap: openWifi),
        ExpressiveListTile(
          title: const Text('Bluetooth'),
          onTap: openBluetooth,
        ),
      ],
    );
  },
  'ExpressiveSectionHeader': (context) =>
      const ExpressiveSectionHeader('Recent'),
  'ExpressiveDivider': (context) =>
      const ExpressiveDivider(inset: ExpressiveDividerInset.start),
  'ExpressiveReorderableListView': (context) {
    const tasks = ['Water the fern', 'Repot the cactus'];
    void move(int from, int to) {}
    return ExpressiveReorderableListView(
      itemCount: tasks.length,
      onReorder: move,
      itemBuilder: (context, i) => ExpressiveListTile(
        key: ValueKey(tasks[i]),
        title: Text(tasks[i]),
        trailing: ExpressiveReorderHandle(index: i),
      ),
    );
  },
  'ExpressiveSwipeToDismiss': (context) {
    const mail = (id: 4821, subject: 'Your trip to Porto');
    void archive(Object mail) {}
    return ExpressiveSwipeToDismiss(
      key: ValueKey(mail.id),
      onDismissed: (_) => archive(mail),
      child: ExpressiveListTile(title: Text(mail.subject)),
    );
  },
  'ExpressiveSwipeActions': (context) {
    void delete() {}
    void archive() {}
    return ExpressiveSwipeActions(
      trailing: [
        ExpressiveSwipeAction(
          label: 'Delete',
          icon: ExpressiveSymbols.delete,
          isDestructiveAction: true,
          onPressed: delete,
        ),
        ExpressiveSwipeAction(
          label: 'Archive',
          icon: ExpressiveSymbols.archive,
          onPressed: archive,
        ),
      ],
      child: const ExpressiveListTile(title: Text('Trip')),
    );
  },
  'ExpressiveDisclosure': (context) => const ExpressiveDisclosure(
    title: Text('Shipping'),
    child: Text('Ships in two days.'),
  ),
  'ExpressiveGrid': (context) {
    const photos = ['Fern', 'Cactus', 'Monstera'];
    Widget photoTile(String photo) => Text(photo);
    return ExpressiveGrid(
      itemCount: photos.length,
      columns: 3,
      itemBuilder: (context, i) => photoTile(photos[i]),
    );
  },
  'ExpressiveLoadingIndicator': (context) => const ExpressiveLoadingIndicator(
    contained: true,
    semanticLabel: 'Loading recipes',
  ),
  'ExpressiveRefreshIndicator': (context) {
    Future<void> reload() async {}
    const tasks = <Widget>[Text('Water the fern')];
    return ExpressiveRefreshIndicator(
      onRefresh: reload,
      child: ListView(children: tasks),
    );
  },
  'ExpressiveMedia': (context) => const ExpressiveMedia(
    slotId: 'hero',
    aspectRatio: 16 / 9,
    corner: ExpressiveCorner.extraLarge,
  ),
  'ExpressiveAvatar': (context) => const ExpressiveAvatar(
    name: 'Mara Quist',
    slotId: 'face-mara',
    size: ExpressiveAvatarSize.large,
  ),
  'ExpressiveAvatarGroup': (context) => const ExpressiveAvatarGroup(
    faces: [
      ExpressiveFace('Noor Wahid'),
      ExpressiveFace('Ada Kim'),
      ExpressiveFace('Jon Ruiz'),
    ],
    total: 7,
  ),
  'showExpressivePopover': (context) => _later(
    context,
    () => showExpressivePopover(
      context,
      builder: (context) => const Text('Saved to your library'),
    ),
  ),
  'showExpressiveMenu': (context) {
    void rename() {}
    return _later(
      context,
      () => showExpressiveMenu(
        context,
        entries: [ExpressiveMenuItem('Rename', onPressed: rename)],
      ),
    );
  },
  'ExpressiveMultiSelect': (context) {
    const tags = ['red'];
    void setTags(List<String> value) {}
    return ExpressiveMultiSelect<String>(
      labelText: 'Tags',
      options: const [
        ExpressiveSelectOption('red', 'Red'),
        ExpressiveSelectOption('blue', 'Blue'),
      ],
      values: tags,
      onChanged: setTags,
    );
  },
  'ExpressiveMenuBar': (context) {
    void create() {}
    return ExpressiveMenuBar(
      menus: [
        ExpressiveMenuBarEntry(
          'File',
          children: [
            ExpressiveMenuBarEntry(
              'New',
              onPressed: create,
              shortcut: 'Ctrl N',
            ),
          ],
        ),
      ],
    );
  },
  'showExpressiveNavigationDrawer': (context) {
    const destinations = _destinations;
    const page = 0;
    Future<void> open() async {
      final index = await showExpressiveNavigationDrawer(
        context,
        destinations: destinations,
        selectedIndex: page,
      );
      debugPrint('chose $index');
    }

    return _later(context, () => unawaited(open()));
  },
  'ExpressiveNavigationDrawer': (context) {
    const destinations = _destinations;
    const page = 0;
    void go(int index) {}
    return ExpressiveNavigationDrawer(
      destinations: destinations,
      selectedIndex: page,
      onDestinationSelected: go,
    );
  },
  'ExpressiveScrollArea': (context) {
    final scroll = _own(ScrollController());
    final rows = [for (var i = 0; i < 30; i++) Text('Row $i')];
    return ExpressiveScrollArea(
      controller: scroll,
      child: ListView(controller: scroll, children: rows),
    );
  },
  'ExpressiveResizable': (context) {
    const folders = Text('Folders');
    const messages = Text('Messages');
    return const ExpressiveResizable(
      first: folders,
      second: messages,
      initialFraction: 0.3,
      minFirst: 200,
    );
  },
  'ExpressiveSheet': (context) {
    const filters = Text('Price, rating, distance');
    return _later(
      context,
      () => ExpressiveSheet.show<void>(
        context,
        title: 'Filters',
        builder: (context) => filters,
      ),
    );
  },
  'ExpressiveCalendar': (context) {
    final day = DateTime(2026, 3, 14);
    void setDay(DateTime value) {}
    return ExpressiveCalendar(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      value: day,
      onChanged: setDay,
    );
  },
  'ExpressivePreview': (context) => const ExpressivePreview(
    platform: PreviewPlatform.ios,
    presentation: RoutePresentation.pushed,
    child: TripPage(),
  ),
  'ExpressiveLinearProgressIndicator': (context) =>
      const ExpressiveLinearProgressIndicator(
        value: 0.4,
        semanticLabel: 'Upload',
      ),
  'ExpressiveMeter': (context) => const ExpressiveMeter(
    label: 'Storage',
    value: 148,
    limit: 200,
    note: '52 GB left',
  ),
  'ExpressiveCircularProgressIndicator': (context) =>
      const ExpressiveCircularProgressIndicator(semanticLabel: 'Syncing'),
  'ExpressiveStepProgress': (context) => const ExpressiveStepProgress(
    count: 3,
    currentStep: 1,
    labels: ['Cart', 'Address', 'Pay'],
  ),
  'ExpressiveScaffold': (context) {
    const sections = <Widget>[Text('Upcoming'), Text('Past')];
    return const ExpressiveScaffold(
      title: 'Trips',
      body: Column(children: sections),
    );
  },
  'ExpressiveCheckbox': (context) {
    var done = false;
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveCheckbox(
        value: done,
        onChanged: (v) => setState(() => done = v),
      ),
    );
  },
  'ExpressiveRadio': (context) {
    var plan = 'yearly';
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveRadio(
        selected: plan == 'monthly',
        onPressed: () => setState(() => plan = 'monthly'),
      ),
    );
  },
  'ExpressiveRadioGroup': (context) {
    var plan = 'monthly';
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveRadioGroup<String>(
        value: plan,
        onChanged: (v) => setState(() => plan = v),
        options: const [
          ExpressiveRadioOption(value: 'monthly', label: 'Monthly'),
          ExpressiveRadioOption(value: 'yearly', label: 'Yearly'),
        ],
      ),
    );
  },
  'ExpressiveSwitch': (context) {
    var alerts = true;
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveSwitch(
        value: alerts,
        onChanged: (v) => setState(() => alerts = v),
        checkedIcon: const Icon(ExpressiveSymbols.check),
      ),
    );
  },
  'ExpressiveCheckboxRow': (context) {
    var receipts = true;
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveCheckboxRow(
        label: 'Email me receipts',
        value: receipts,
        onChanged: (v) => setState(() => receipts = v),
      ),
    );
  },
  'ExpressiveRadioRow': (context) {
    var plan = 'yearly';
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveRadioRow(
        label: 'Monthly',
        selected: plan == 'monthly',
        onPressed: () => setState(() => plan = 'monthly'),
      ),
    );
  },
  'ExpressiveSwitchRow': (context) {
    var calling = false;
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveSwitchRow(
        label: 'Wi-Fi calling',
        value: calling,
        onChanged: (v) => setState(() => calling = v),
      ),
    );
  },
  'showExpressiveBottomSheet': (context) => _later(
    context,
    () => showExpressiveBottomSheet<void>(
      context,
      builder: (context) => const ExpressiveListTile(title: Text('Share')),
    ),
  ),
  'ExpressiveShellScaffold': (context) {
    const tabs = [
      NavTab(icon: ExpressiveSymbols.home, label: 'Home', location: '/'),
      NavTab(icon: ExpressiveSymbols.search, label: 'Search', location: '/s'),
    ];
    const branches = <Widget>[Text('Home'), Text('Search')];
    var tab = 0;
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveShellScaffold(
        tabs: tabs,
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        body: IndexedStack(index: tab, children: branches),
      ),
    );
  },
  'ExpressiveSlider': (context) {
    var volume = 0.4;
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveSlider(
        value: volume,
        onChanged: (v) => setState(() => volume = v),
      ),
    );
  },
  'ExpressiveVerticalSlider': (context) {
    var level = 0.6;
    return StatefulBuilder(
      builder: (context, setState) => SizedBox(
        height: 240,
        child: ExpressiveVerticalSlider(
          value: level,
          topToBottom: false,
          onChanged: (v) => setState(() => level = v),
        ),
      ),
    );
  },
  'ExpressiveRangeSlider': (context) {
    var low = 120.0;
    var high = 380.0;
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveRangeSlider(
        start: low,
        end: high,
        min: 0,
        max: 500,
        onChanged: (s, e) => setState(() {
          low = s;
          high = e;
        }),
      ),
    );
  },
  'ExpressiveNumberField': (context) {
    var guests = 2;
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveNumberField(
        value: guests,
        min: 1,
        max: 8,
        labelText: 'Guests',
        onChanged: (v) => setState(() => guests = v),
      ),
    );
  },
  'ExpressiveSplashScreenMark': (context) => const ExpressiveSplashScreenMark(
    wordmark: 'Steady',
    ground: ExpressiveSplashScreenGround.primary,
  ),
  'ExpressiveSplashScreenSource': (context) {
    final t = context.expressiveTheme;
    const bigBlock = SizedBox(width: 120, height: 120);
    return ExpressiveSplashScreenSource(
      corner: ExpressiveCorner.extraLarge,
      color: t.colors.primaryContainer,
      child: bigBlock,
    );
  },
  'ExpressiveSplashScreenAnchor': (context) {
    final t = context.expressiveTheme;
    void measure() {}
    return ExpressiveSplashScreenAnchor(
      corner: ExpressiveCorner.full,
      color: t.colors.primary,
      child: ExpressiveFilledButton('Measure now', onPressed: measure),
    );
  },
  'ExpressiveSplashScreen': (context) {
    const session = (isRestoring: false);
    // The app builder's child, which Flutter types as nullable.
    Widget? splashChild() => const Text('Home');
    final child = splashChild();
    return ExpressiveSplashScreen(
      restoring: session.isRestoring,
      restoringLabel: 'Restoring your session',
      mark: const ExpressiveSplashScreenMark(wordmark: 'Steady'),
      child: child!,
    );
  },
  'ExpressiveTable': (context) => const ExpressiveTable(
    columns: [
      ExpressiveTableColumn('Plant', flex: 2),
      ExpressiveTableColumn('Water', numeric: true),
    ],
    rows: [
      ExpressiveTableRow(['Fern', '200 ml']),
      ExpressiveTableRow(['Cactus', '50 ml']),
    ],
  ),
  'ExpressivePasswordField': (context) {
    final password = _own(TextEditingController());
    return ExpressivePasswordField(labelText: 'Password', controller: password);
  },
  'showExpressiveSnackBar': (context) {
    void undo() {}
    return _later(context, () {
      showExpressiveSnackBar(
        context,
        'Message archived',
        actionLabel: 'Undo',
        onAction: undo,
      );
    });
  },
  'ExpressiveBreadcrumb': (context) {
    void goHome() {}
    void goOrders() {}
    return ExpressiveBreadcrumb(
      items: [
        ExpressiveBreadcrumbItem('Home', onPressed: goHome),
        ExpressiveBreadcrumbItem('Orders', onPressed: goOrders),
        const ExpressiveBreadcrumbItem('#1042'),
      ],
    );
  },
  'ExpressivePagination': (context) {
    var page = 1;
    return StatefulBuilder(
      builder: (context, setState) => ExpressivePagination(
        page: page,
        pageCount: 12,
        onChanged: (p) => setState(() => page = p),
      ),
    );
  },
  'ExpressiveIcon': (context) {
    const liked = true;
    return const ExpressiveIcon(
      ExpressiveSymbols.favorite,
      selected: liked,
      semanticLabel: 'Liked',
    );
  },
  'ExpressiveDensity': (context) => ExpressiveThemeData.preset(
    'baseline',
    Brightness.light,
  ).copyWith(density: ExpressiveDensity.compact),
  'expressiveInventory': (context) {
    expressiveInventory.verify();
    return null;
  },
  'ExpressiveInventoryGallery': (context) => const ExpressiveInventoryGallery(),
  'ExpressiveMotion.copyWith': (context) => context.expressiveTheme.motion
      .copyWith(scheme: ExpressiveMotionScheme.standard),
  'ExpressiveStyleScope': (context) {
    final resolved = ExpressiveStyleScope.maybeOf(context);
    final padding = resolved?.style.padding?.resolve(resolved.states);
    return padding;
  },
  'ExpressiveContentBorder': (context) {
    const border = ExpressiveContentBorder(
      ExpressiveMaterialShapeBorder(ExpressiveMaterialShape.cookie6Sided),
      inset: 12,
    );
    return border;
  },
  'ExpressiveThemeData.from': (context) {
    final theme = ExpressiveThemeData.from(seed: const Color(0xff00695c));
    final high = ExpressiveThemeData.from(
      seed: const Color(0xff00695c),
      contrastLevel: 1,
    );
    return ExpressiveTheme(
      data: theme,
      child: ExpressiveTheme(
        data: high,
        child: const ExpressiveFilledButton('Save'),
      ),
    );
  },
  'ExpressiveThemeData.preset': (context) {
    final high = ExpressiveThemeData.preset(
      'grove',
      Brightness.dark,
      contrastLevel: 1,
    );
    return ExpressiveTheme(
      data: high,
      child: const ExpressiveFilledButton('Save'),
    );
  },
  'ExpressiveHost.highContrastLight': (context) {
    const brand = Color(0xff00695c);
    const child = ExpressiveFilledButton('Save');
    return ExpressiveHost(
      theme: ExpressiveThemeData.from(seed: brand),
      highContrastTheme: ExpressiveThemeData.from(
        seed: brand,
        contrastLevel: 1,
      ),
      child: child,
    );
  },
  'ExpressiveHost.density': (context) {
    // The app builder's child.
    Widget app() => const ExpressiveFilledButton('Save');
    final child = app();
    return ExpressiveHost(density: ExpressiveDensity.compact, child: child);
  },
  'ExpressiveThemeData.palettes': (context) {
    const id = 'grove';
    const app = ExpressiveFilledButton('Save');
    return ExpressiveHost(
      palette: ExpressiveThemeData.palettes.firstWhere((p) => p.id == id),
      child: app,
    );
  },
  'ExpressiveAppShell.branches': (context) {
    var index = 0;
    return StatefulBuilder(
      builder: (context, setState) => ExpressiveAppShell.branches(
        destinations: const [
          ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
          ExpressiveNavItem(ExpressiveSymbols.search, 'Search'),
          ExpressiveNavItem(ExpressiveSymbols.settings, 'Settings'),
        ],
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        branches: [
          (context) => const HomePage(),
          (context) => const SearchPage(),
          (context) => const SettingsPage(),
        ],
      ),
    );
  },
  'ExpressiveTextTheme': (context) {
    final type = const ExpressiveTextTheme().copyWith(textFamily: 'Inter');
    const world = ExpressiveTextTheme(
      fontFamilyFallback: ['NotoSansJP', 'NotoSansArabic'],
    );
    return ExpressiveTheme(
      data: ExpressiveThemeData.baseline().copyWith(type: type),
      child: ExpressiveTheme(
        data: ExpressiveThemeData.baseline().copyWith(type: world),
        child: const ExpressiveFilledButton('Save'),
      ),
    );
  },
  'ExpressiveComponentThemeData.layered': (context) {
    final pressedOnly = ExpressiveComponentThemeData(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? const Color(0xff4f378b)
            : null,
      ),
    );
    final style = ExpressiveComponentThemeData.layered([
      pressedOnly,
      const ExpressiveComponentThemeData(
        backgroundColor: WidgetStatePropertyAll(Color(0xff6750a4)),
      ),
    ]);
    return ExpressiveFilledButton('Save', onPressed: () {}, style: style);
  },
  'ExpressiveTheme': (context) => ExpressiveTheme(
    data: ExpressiveThemeData.bloom(Brightness.dark),
    child: const ExpressiveFilledButton('Save'),
  ),
  'AnimatedExpressiveTheme': (context) {
    const id = 'ember';
    return AnimatedExpressiveTheme(
      data: ExpressiveThemeData.preset(id, Brightness.light),
      child: const ExpressiveFilledButton('Save'),
    );
  },
};

// The examples that make an app, not a part: compiled, never run here.

/// ExpressiveThemeData's: an app wearing the baseline in the platform's
/// brightness.
Widget themedApp() => WidgetsApp(
  color: const Color(0xFF6750A4),
  builder: (context, child) => ExpressiveTheme(
    data: ExpressiveThemeData.preset(
      'baseline',
      MediaQuery.platformBrightnessOf(context),
    ),
    child: child!,
  ),
);

/// expressivePageTransitions's: an app on Flutter's own MaterialApp that
/// pushes with the look's transitions.
Widget pagedApp() => MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: expressivePageTransitions,
    ),
  ),
  builder: (context, child) => ExpressiveTheme(
    data: ExpressiveThemeData.grove(Brightness.light),
    child: child!,
  ),
);

/// expressiveFontFamily's: Roboto Flex loaded from the app's own bytes.
Future<void> loadOwnFont(Future<ByteData> bytes) async {
  final loader = FontLoader(expressiveFontFamily('RobotoFlex'))..addFont(bytes);
  await loader.load();
}

/// expressiveLoadFonts's: the fonts loaded before the app runs.
Future<void> appMain() async {
  await expressiveLoadFonts();
  runApp(const MyApp());
}

/// The app [appMain] runs.
class MyApp extends StatelessWidget {
  /// The app.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: ExpressiveHost(child: TripPage()));
}

/// The page [ExpressivePreview]'s example frames.
class TripPage extends StatelessWidget {
  /// The page.
  const TripPage({super.key});

  @override
  Widget build(BuildContext context) => const ExpressiveScaffold(
    title: 'Lisbon',
    body: Text('Three days in May'),
  );
}

// ExpressiveLocalizations's: French words for a host's delegates (its file
// is skipped above, its imports being the test's own).
class FrenchWords extends DefaultRawWidgetsLocalizations {
  const FrenchWords();

  @override
  String get cancelButtonLabel => 'Annuler';
}

class French<T> extends LocalizationsDelegate<T> {
  const French(this.words);

  final T words;

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'fr';

  @override
  Future<T> load(Locale locale) => SynchronousFuture(words);

  @override
  bool shouldReload(French<T> old) => false;
}

const frenchDelegates = <LocalizationsDelegate<dynamic>>[
  French<RawWidgetsLocalizations>(FrenchWords()),
  French<ExpressiveLocalizations>(
    ExpressiveLocalizations(selectDate: 'Choisir une date'),
  ),
];

// Files whose examples are a library's head, not code to run: the parts
// library's imports, and the French words above (written out without the
// imports they open with).
const Set<String> _heads = {'material_expressive_parts.dart', 'strings.dart'};

/// An Expressive app, its animations held still (a loader turns for ever).
Widget _app(Widget child) => MaterialApp(
  builder: (context, app) => ExpressiveHost(child: app!),
  home: ExpressiveScaffold(body: TickerMode(enabled: false, child: child)),
);

void main() {
  tearDown(() {
    for (final dispose in _disposers) {
      dispose();
    }
    _disposers.clear();
  });

  testWidgets('the French words load for French', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: const [Locale('en'), Locale('fr')],
        localizationsDelegates: frenchDelegates,
        builder: (context, app) => ExpressiveHost(child: app!),
        home: Builder(
          builder: (context) =>
              Text(RawWidgetsLocalizations.of(context).cancelButtonLabel),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.takeException();
    expect(find.text('Annuler'), findsOneWidget);
  });

  testDocExamples(
    self: 'test/doc_examples_test.dart',
    examples: _examples,
    wrap: _app,
    skip: _heads,
    lib: [
      'lib/src/material_expressive',
      'lib/src/material_expressive',
    ].firstWhere((path) => Directory(path).existsSync()),
  );
}

/// A place's first page, for the shell's example.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Home');
}

/// A place's first page, for the shell's example.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Search');
}

/// A place's first page, for the shell's example.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Settings');
}
