// Every doc example in the package's lib, compiled and run (ui_core's testDocExamples). Each `/// Example:` (and
// each fenced dart block) is written out below as the body of an entry, so an example that stops compiling fails
// analysis; the first test fails when lib has an example this file lacks; the rest build each widget example in a
// Comic app. An example's free names (a theme `t`, a callback, the caller's controller) are made first, as the
// docs say the caller has them; one that would leave the test (a network picture, an app of its own, a dialog it
// raises at once) is compiled and not run.
// ignore_for_file: unused_local_variable
import 'dart:io' show Directory;
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show FontLoader, LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';
// The parts library's own (kept out of the barrel), which its docs show.
import 'package:comic_ui/src/comic/balloons.dart';
import 'package:comic_ui/src/comic/frames.dart';
import 'package:comic_ui/src/comic/layout.dart';
import 'package:comic_ui/src/comic/press.dart';
import 'package:comic_ui/src/comic/styled.dart';

import 'doc_examples.dart';

/// What the caller made for an example, disposed once its tree is gone.
final List<VoidCallback> _disposers = [];

T _own<T extends ChangeNotifier>(T value) {
  _disposers.add(value.dispose);
  return value;
}

/// The page an app's example shows.
class IssuePage extends StatelessWidget {
  /// The page.
  const IssuePage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// The app a fenced example runs.
class MyApp extends StatelessWidget {
  /// The app.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class IssueRoute<T> extends RawDialogRoute<T> with ComicScreenedRoute<T> {
  IssueRoute({required super.pageBuilder})
    : super(barrierColor: null, barrierLabel: 'Close');
  @override
  Color? get screenInk => const Color(0x99000000);
}

final Map<String, DocExample> _examples = {
  'ComicLink': (context) {
    void open([Object? a, Object? b]) {}
    return ComicLink('Read the issue', onPressed: open);
  },
  'ComicBalloon': (context) =>
      const ComicBalloon('Bringing the first-aid kit.', by: 'Pat, 09:20'),
  'ComicThought': (context) => const ComicThought('Who has the tent?'),
  'ComicBurstLedger': (context) =>
      const ComicBurstLedger(child: ComicBurst(number: '12')),
  'ComicBurst': (context) =>
      const ComicBurst(number: '23', over: 'In', under: 'days!'),
  'ComicPop': (context) => const ComicPop('4', width: 40, height: 34),
  'ComicStamp': (context) => const ComicStamp('Paid'),
  'ComicChart': (context) => const ComicChart(
    label: 'Weekly pages',
    series: [
      ComicChartSeries('Pages', [12, 18, 16]),
    ],
  ),
  'ComicLineChart': (context) => const ComicLineChart(
    label: 'Pages read',
    labels: ['Mon', 'Tue', 'Wed'],
    series: [
      ComicChartSeries('You', [12, 18, 16]),
    ],
  ),
  'ComicAreaChart': (context) => const ComicAreaChart(
    label: 'Visitors',
    labels: ['Wk 1', 'Wk 2'],
    series: [
      ComicChartSeries('Visitors', [310, 402]),
    ],
  ),
  'ComicBarChart': (context) => const ComicBarChart(
    label: 'Orders',
    labels: ['Wk 1', 'Wk 2'],
    series: [
      ComicChartSeries('Online', [42, 51]),
    ],
  ),
  'ComicSparkline': (context) =>
      const ComicSparkline(label: 'Sales this week', values: [3, 5, 4, 8, 7]),
  'ComicLogo': (context) => const ComicLogo('Saucepot!'),
  'ComicGroupChip': (context) => ComicGroupChip(
    'The Six',
    people: const [ComicPerson(initials: 'AB', size: 26)],
    onPressed: () {},
  ),
  'ComicNavigationBar': (context) {
    void select([Object? a, Object? b]) {}
    return ComicNavigationBar(
      destinations: const [
        ComicNavItem(label: 'Home', short: 'Home', icon: ComicGlyphs.house),
      ],
      selectedIndex: 0,
      onDestinationSelected: select,
    );
  },
  'ComicTab': (context) =>
      const ComicTab(ComicGlyphs.house, 'Home', ValueKey('open-home')),
  'ComicScaffold': (context) {
    const a = Text('A');
    const b = Text('B');
    return const ComicScaffold(
      topBar: ComicAppBar(title: 'Your stay'),
      body: ComicSections(
        children: [
          ComicTier(children: [a, b]),
        ],
      ),
    );
  },
  'ComicSections': (context) {
    const a = Text('A');
    const b = Text('B');
    const c = Text('C');
    const d = Text('D');
    const e = Text('E');
    return const ComicSections(
      children: [
        ComicTier(children: [a, b]),
        ComicSectionHeader('Coming up'),
        ComicTier(children: [c, d, e]),
      ],
    );
  },
  'ComicBackButton': (context) =>
      ComicBackButton(onPressed: () => Navigator.of(context).maybePop()),
  'ComicAppBar': (context) => ComicAppBar(
    title: 'The plan',
    leading: ComicAppBar.autoLeading(context, key: const ValueKey('back')),
    actions: [const ComicIconButton(ComicGlyphs.share2, label: 'Share')],
  ),
  'ComicInput': (context) => ComicInput(
    key: const ValueKey('name'),
    hint: 'Your name',
    onChanged: (text) {},
  ),
  'ComicMedia': (context) =>
      const ComicMedia(slotId: 'item-1', aspect: 1, label: 'First piece'),
  'ComicPictureCard': (context) => ComicPictureCard(
    slotId: 'item-1',
    title: 'First piece',
    subtitle: 'Kind A',
    trailing: const ComicTag('New'),
    onPressed: () {},
  ),
  'ComicLoadingState': (context) =>
      const ComicLoadingState(label: 'Loading issue'),
  'ComicErrorState': (context) => ComicErrorState(
    title: 'Could not load',
    message: 'Check your connection.',
    onRetry: () {},
  ),
  'ComicChip': (context) => ComicChip(
    'Jazz',
    onPressed: () {},
    style: ComicStyle(
      shape: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              )
            : const RoundedRectangleBorder(),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20),
      ),
    ),
  ),
  'ComicButton': (context) =>
      ComicButton.filled('New plan', icon: ComicGlyphs.plus, onPressed: () {}),
  'ComicIconButton': (context) =>
      ComicIconButton(ComicGlyphs.bell, label: 'Alerts', onPressed: () {}),
  'ComicTextField': (context) =>
      ComicTextField(hint: 'Your name', onChanged: (text) {}),
  'ComicSendButton': (context) => ComicSendButton(onPressed: () {}),
  'ComicSelectField': (context) => ComicSelectField(
    value: 'Current ··3108',
    note: 'Change',
    onPressed: () {},
  ),
  'ComicChip (2)': (context) =>
      ComicChip('Fish', selected: true, onPressed: () {}),
  'ComicCheckbox': (context) =>
      ComicCheckbox(label: 'Keep issue', value: true, onChanged: (v) {}),
  'ComicChoiceBox': (context) => ComicChoiceBox(
    selected: true,
    onPressed: () {},
    child: const Text('Mild'),
  ),
  'ComicChoices': (context) => ComicChoices(
    options: const [
      ComicChoice('All'),
      ComicChoice('Mild', note: 'For everyone'),
    ],
    value: 'All',
    onChanged: (v) {},
  ),
  'ComicNumberField': (context) =>
      ComicNumberField(value: 6, unit: 'servings', onChanged: (_) {}),
  'ComicSwitch': (context) {
    var on = true;
    void setState(VoidCallback fn) => fn();
    return ComicSwitch(value: on, onChanged: (v) => setState(() => on = v));
  },
  'TextField': (context) => TextField(
    selectionControls: ComicTextSelectionControls.of(
      Theme.of(context).platform,
    ),
  ),
  'TextField (2)': (context) =>
      const TextField(contextMenuBuilder: ComicTextContextMenu.editable),
  'ComicTextArea': (context) {
    void save([Object? a, Object? b]) {}
    return ComicTextArea(label: 'Notes', onChanged: save);
  },
  'ComicSearchField': (context) {
    void search([Object? a, Object? b]) {}
    return ComicSearchField(hint: 'Search issues', onChanged: search);
  },
  'ComicSelect': (context) {
    void change([Object? a, Object? b]) {}
    return ComicSelect<String>(
      label: 'Format',
      options: const [ComicSelectOption('print', 'Print')],
      value: 'print',
      onChanged: change,
    );
  },
  'ComicCheckRow': (context) {
    void change([Object? a, Object? b]) {}
    return ComicCheckRow(label: 'Keep a copy', value: true, onChanged: change);
  },
  'ComicRadioGroup': (context) {
    void change([Object? a, Object? b]) {}
    return ComicRadioGroup<String>(
      label: 'Format',
      options: const [
        ComicRadio('print', 'Print'),
        ComicRadio('digital', 'Digital'),
      ],
      value: 'print',
      onChanged: change,
    );
  },
  'ComicSegmentedButton': (context) {
    void change([Object? a, Object? b]) {}
    return ComicSegmentedButton<String>(
      label: 'View',
      segments: const [
        ComicButtonSegment('all', 'All'),
        ComicButtonSegment('saved', 'Saved'),
      ],
      value: 'all',
      onChanged: change,
    );
  },
  'ComicFileUpload': (context) {
    const files = [ComicDroppedFile('cover.png', progress: .5)];
    void pick([Object? a, Object? b]) {}
    void remove([Object? a, Object? b]) {}
    return ComicFileUpload(
      label: 'Cover art',
      files: files,
      onChoose: pick,
      onRemove: remove,
    );
  },
  'FontLoader': (context) {
    Future<void> example() async {
      final bytes = Future.value(ByteData(0));
      final loader = FontLoader(comicFontFamily('ShantellSans'))
        ..addFont(bytes);
      await loader.load();
    }

    return example;
  },
  'Future': (context) {
    Future<void> main() async {
      WidgetsFlutterBinding.ensureInitialized();
      await comicLoadFonts();
      runApp(const MyApp());
    }

    return main;
  },
  'Text': (context) {
    final t = ComicTheme.of(context);
    final start = DateTime(2026, 5, 1);
    final end = DateTime(2026, 5, 4);
    return Text(ComicFormat.range(start, end), style: t.type.body);
  },
  'ComicCaption': (context) =>
      const ComicCaption('Meanwhile, by the lake', icon: ComicGlyphs.mapPin),
  'ComicPanel': (context) => const ComicPanel(
    caption: 'Coming up',
    captionIcon: ComicGlyphs.calendar,
    child: ComicListTile(isFirst: true, title: 'Fri 4 Dec'),
  ),
  'ComicTier': (context) {
    const a = Text('A');
    const b = Text('B');
    return const ComicTier(
      spans: [5, 3],
      phone: ComicTierLayout.pairs,
      children: [
        ComicPanel(child: a),
        ComicPanel(child: b),
      ],
    );
  },
  'ComicPanelStack': (context) {
    const a = Text('A');
    const b = Text('B');
    return const ComicPanelStack(
      children: [
        ComicPanel(child: a),
        ComicPanel(child: b),
      ],
    );
  },
  'ComicWell': (context) => const ComicWell(child: Text('30 min')),
  'ComicCompactScope': (context) =>
      const ComicCompactScope(on: true, child: ComicBurst(number: '12')),
  'ComicLetters': (context) => const ComicLetters('All six of us!'),
  'ComicSectionHeader': (context) =>
      const ComicSectionHeader('Coming up', note: 'Next three weeks'),
  'ComicPanelHead': (context) => ComicPanelHead(
    'Who owes who',
    sub: 'Since the last settle-up',
    more: 'See all',
    onMore: () {},
  ),
  'ComicStars': (context) => const ComicStars(4),
  'ComicMoreLink': (context) => ComicMoreLink('See all', onPressed: () {}),
  'ComicLabel': (context) => const ComicLabel('How many'),
  'ComicTag': (context) => const ComicTag(
    'Booked',
    tone: ComicSpeaker.narrator,
    icon: ComicGlyphs.check,
  ),
  'ComicIndicia': (context) => const ComicIndicia(
    'Published on every first Friday. No refunds on the cake.',
    lead: 'Volume 1, number 27.',
  ),
  'ComicRating': (context) {
    var rating = 3;
    void setState(VoidCallback fn) => fn();
    return ComicRating(
      label: 'Rate this issue',
      value: 3,
      onChanged: (v) => setState(() => rating = v),
    );
  },
  'ComicCard': (context) => const ComicCard(
    title: 'This issue',
    children: [
      ComicGrow(child: Text('Twelve pages')),
      ComicButton.text('Read'),
    ],
  ),
  'ComicListSection': (context) => const ComicListSection(
    children: [
      ComicListTile(title: 'First'),
      ComicListTile(title: 'Second'),
    ],
  ),
  'ComicDisclosure': (context) => const ComicDisclosure(
    title: 'More about this issue',
    child: Text('The full story'),
  ),
  'ComicTable': (context) => const ComicTable(
    columns: ['Issue', 'Pages'],
    rows: [
      ['Twelve', '24'],
      ['Thirteen', '32'],
    ],
  ),
  'ComicChromeScope': (context) {
    const page = Text('A page');
    return const ComicChromeScope(
      brand: ComicBrand(name: 'The Issue'),
      nav: [],
      active: 0,
      child: page,
    );
  },
  'ComicHost': (context) {
    const page = Text('A page');
    return ComicHost(light: ComicThemeData.offset(), child: page);
  },
  'ComicPreview': (context) =>
      const ComicPreview(child: ComicScaffold(body: Text('Preview'))),
  'ComicButtonGroup': (context) {
    void copy([Object? a, Object? b]) {}
    void paste([Object? a, Object? b]) {}
    return ComicButtonGroup(
      label: 'Text',
      items: [
        ComicButtonGroupItem('Copy', onPressed: copy),
        ComicButtonGroupItem('Paste', onPressed: paste),
      ],
    );
  },
  'ComicToggleGroup': (context) {
    var on = {'Bold'};
    void setState(VoidCallback fn) => fn();
    return ComicToggleGroup<String>(
      label: 'Style',
      values: const ['Bold', 'Italic'],
      selected: on,
      multiple: true,
      labelOf: (v) => v,
      onChanged: (next) => setState(() => on = next),
    );
  },
  'ComicSplitButton': (context) {
    void copy([Object? a, Object? b]) {}
    void save([Object? a, Object? b]) {}
    return ComicSplitButton(
      'Save',
      onPressed: save,
      actions: [ComicSplitAction('Save as copy', onPressed: copy)],
    );
  },
  'ComicKbd': (context) => const ComicKbd(['Ctrl', 'K']),
  'ComicPasswordField': (context) {
    final password = _own(TextEditingController());
    void signIn() {}
    return ComicPasswordField(
      label: 'Password',
      controller: password,
      onSubmitted: (_) => signIn(),
    );
  },
  'ComicInputGroup': (context) => const ComicInputGroup(
    label: 'Weight',
    leading: [Icon(ComicGlyphs.search)],
    trailing: [Text('kg')],
    keyboardType: TextInputType.number,
  ),
  'ComicMultiSelect': (context) {
    var genres = ['Noir'];
    void setState(VoidCallback fn) => fn();
    return ComicMultiSelect<String>(
      label: 'Genres',
      values: genres,
      options: const ['Noir', 'Western', 'Horror'],
      onChanged: (next) => setState(() => genres = next),
    );
  },
  'ComicRangeSlider': (context) {
    var price = const DesignRangeValues(20, 80);
    void setState(VoidCallback fn) => fn();
    return ComicRangeSlider(
      label: 'Price',
      values: const DesignRangeValues(20, 80),
      max: 100,
      onChanged: (next) => setState(() => price = next),
    );
  },
  'ComicCalendar': (context) {
    void setState(VoidCallback fn) => fn();
    final calendar = _own(
      DesignCalendarController(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
      ),
    );
    return ComicCalendar(
      controller: calendar,
      onChanged: (day) => setState(() {}),
    );
  },
  'ComicDateRangePicker': (context) {
    var stay = DesignDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 4));
    void setState(VoidCallback fn) => fn();
    return ComicDateRangePicker(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      value: stay,
      onChanged: (next) => setState(() => stay = next),
    );
  },
  'showComicDateRangePicker': (context) {
    Future<void> example() async {
      final stay = await showComicDateRangePicker(
        context,
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
      );
    }

    return example;
  },
  'ComicWheelPicker': (context) {
    var copies = 2;
    void setState(VoidCallback fn) => fn();
    return ComicWheelPicker<int>(
      label: 'Copies',
      values: const [1, 2, 3, 4, 5],
      value: copies,
      labelOf: (n) => '$n',
      onChanged: (n) => setState(() => copies = n),
    );
  },
  'ComicInputOtp': (context) {
    void verify([Object? a, Object? b]) {}
    return ComicInputOtp(
      label: 'Verification code',
      length: 6,
      onCompleted: verify,
    );
  },
  'showComicSheet': (context) {
    void example() {
      showComicSheet<void>(
        context,
        builder: (_) =>
            const ComicSheet(title: 'Filters', child: Text('Only unread')),
      );
    }

    return example;
  },
  'ComicSheet': (context) =>
      const ComicSheet(title: 'Filters', child: Text('Only unread')),
  'ComicPopover': (context) => ComicPopover(
    anchorBuilder: (context, a) => ComicButton('Filter', onPressed: a.toggle),
    builder: (context, close) => const Text('Only unread'),
  ),
  'ComicHoverCard': (context) {
    void open([Object? a, Object? b]) {}
    return ComicHoverCard(
      card: const Text('Inker, issue 12 on'),
      child: ComicLink('Ada', onPressed: open),
    );
  },
  'ComicDivider': (context) => const ComicDivider(label: 'or'),
  'ComicTimeline': (context) => const ComicTimeline(
    entries: [
      ComicTimelineEntry('Pencilled', time: 'Mon'),
      ComicTimelineEntry(
        'Inked',
        time: 'Today',
        step: ComicTimelineStatus.current,
      ),
    ],
  ),
  'ComicDescriptionList': (context) => const ComicDescriptionList(
    entries: [
      ComicDescriptionItem('Writer', 'Ana Ruiz'),
      ComicDescriptionItem('Pages', '24'),
    ],
  ),
  'ComicStatusView': (context) {
    void reload([Object? a, Object? b]) {}
    return ComicStatusView.error(
      title: 'The issue did not load',
      onRetry: reload,
    );
  },
  'ComicActionSheet': (context) => ComicActionSheet<String>(
    title: 'Issue 12',
    actions: const [ComicSheetAction('Share', value: 'share')],
    onSelected: (v) {},
  ),
  'showComicActionSheet': (context) {
    Future<void> example() async {
      final choice = await showComicActionSheet<String>(
        context,
        title: 'Issue 12',
        actions: const [
          ComicSheetAction('Delete', value: 'delete', destructive: true),
        ],
      );
    }

    return example;
  },
  'ComicMenuBar': (context) => ComicMenuBar(
    menus: [
      DesignMenuEntry(
        label: 'File',
        children: [
          DesignMenuEntry(
            label: 'New',
            shortcut: ComicKbd.labelOf(
              context,
              const SingleActivator(LogicalKeyboardKey.keyN, control: true),
            ),
          ),
        ],
      ),
    ],
  ),
  'ComicKbd.labelOf': (context) => DesignMenuEntry(
    label: 'New',
    shortcut: ComicKbd.labelOf(
      context,
      const SingleActivator(LogicalKeyboardKey.keyN, control: true),
    ),
  ),
  'ComicCommand': (context) {
    void create([Object? a, Object? b]) {}
    return ComicCommand(
      commands: [
        DesignCommand(label: 'New issue', group: 'Issues', onPressed: create),
      ],
    );
  },
  'showComicCommand': (context) {
    void example() {
      void create([Object? a, Object? b]) {}
      showComicCommand(
        context,
        commands: [DesignCommand(label: 'New issue', onPressed: create)],
      );
    }

    return example;
  },
  'ComicDataTable': (context) {
    final issues = _own(
      DesignTableController<Map<String, String>>(
        rows: const [
          {'issue': 'Twelve'},
        ],
        columns: const [
          DesignTableColumn<Map<String, String>>(id: 'issue', label: 'Issue'),
        ],
      ),
    );
    return ComicDataTable<Map<String, String>>(
      controller: issues,
      cellBuilder: (context, row, column) => Text(row[column.id] ?? ''),
    );
  },
  'ComicScrollArea': (context) {
    final rows = [const Text('One'), const Text('Two')];
    final scroll = _own(ScrollController());
    return ComicScrollArea(
      controller: scroll,
      child: ListView(controller: scroll, children: rows),
    );
  },
  'ComicResizable': (context) {
    const list = Text('List');
    const detail = Text('Detail');
    return const ComicResizable(
      first: list,
      second: detail,
      minFirst: 200,
      minSecond: 280,
    );
  },
  'ComicReorderableListView': (context) {
    final names = ['Ana', 'Ben'];
    void move(int from, int to) {}
    return ComicReorderableListView<String>(
      items: names,
      labelOf: (n) => n,
      onReorder: move,
      itemBuilder: (context, n) => Text(n),
    );
  },
  'ComicSwipeActions': (context) {
    const row = Text('A row');
    void remove([Object? a, Object? b]) {}
    return ComicSwipeActions(
      endActions: [
        DesignSwipeAction(
          label: 'Delete',
          onPressed: remove,
          destructive: true,
        ),
      ],
      child: row,
    );
  },
  'ComicRefreshIndicator': (context) {
    final rows = [const Text('One'), const Text('Two')];
    Future<void> load() async {}
    return ComicRefreshIndicator(
      onRefresh: load,
      child: ListView(children: rows),
    );
  },
  'ComicTreeView': (context) {
    final tree = _own(
      DesignTreeController<String>(
        roots: const ['Issues'],
        childrenOf: (node) => node == 'Issues' ? const ['Twelve'] : const [],
      ),
    );
    void open([Object? a, Object? b]) {}
    return ComicTreeView<String>(
      controller: tree,
      labelOf: (n) => n,
      onActivate: open,
    );
  },
  'ComicThemeData': (context) {
    void example() {
      final theme = ComicThemeData.offset().copyWith(
        strokes: ComicStrokes.bold,
      );
    }

    return example;
  },
  'ComicThemeData (2)': (context) {
    void example() {
      final theme = ComicThemeData.offset().copyWith(
        density: ComicDensity.compact,
      );
    }

    return example;
  },
  'ComicThemeData (3)': (context) {
    void example() {
      final theme = ComicThemeData.offset().copyWith(
        typeface: const ComicTypeface(
          display: 'ShantellSans',
          text: 'ShantellSans',
          displayCapHeight: 0.700,
        ),
      );
    }

    return example;
  },
  'Padding': (context) => const Padding(
    padding: EdgeInsets.all(ComicSpace.near),
    child: Text('Issue 12'),
  ),
  'ComicFill': (context) =>
      const ComicFill(maxWidth: 400, child: Text('A page-width figure')),
  'ComicColumn': (context) => const ComicColumn(
    children: [
      Text('Heading'),
      ComicGrow(child: Text('Body')),
    ],
  ),
  'ComicColumn (2)': (context) =>
      const ComicColumn(gap: 12, children: [Text('Heading'), Text('Body')]),
  'ComicEqualRow': (context) =>
      const ComicEqualRow(flex: [1, 1], children: [Text('One'), Text('Two')]),
  'ComicRow': (context) =>
      const ComicRow(spans: [6, 6], children: [Text('Left'), Text('Right')]),
  'ComicFitRow': (context) => const ComicFitRow(
    fill: 1,
    children: [Icon(ComicGlyphs.house), Text('A label')],
  ),
  'ComicAutoRow': (context) =>
      const ComicAutoRow(children: [Text('One'), Text('Two')]),
  'ComicGridOf': (context) =>
      const ComicGridOf(columns: 2, children: [Text('One'), Text('Two')]),
  'ComicSplit': (context) =>
      ComicSplit(start: const Text('Heading'), end: const Text('Detail')),
  'ComicBalancedText': (context) => ComicBalancedText(
    'A balanced headline',
    style: ComicTheme.of(context).type.title,
  ),
  'ComicBeside': (context) => ComicBeside(
    object: const ComicPerson(initials: 'AB'),
    child: const ComicKvRow('Issue', '12', isFirst: true),
  ),
  'MaterialApp': (context) {
    void example() {
      const home = Text('Home');
      const MaterialApp(
        localizationsDelegates: [ComicLocalizations.delegate],
        home: home,
      );
    }

    return example;
  },
  'ComicNavigationDrawer': (context) {
    const destinations = [
      ComicNavItem(label: 'Home', short: 'Home', icon: ComicGlyphs.house),
    ];
    void select([Object? a, Object? b]) {}
    return ComicNavigationDrawer(
      destinations: destinations,
      selectedIndex: 0,
      onDestinationSelected: select,
    );
  },
  'ComicTabBar': (context) {
    void select([Object? a, Object? b]) {}
    return ComicTabBar(
      tabs: ['All', 'Saved'],
      selectedIndex: 0,
      onChanged: select,
    );
  },
  'ComicPageDots': (context) {
    void select([Object? a, Object? b]) {}
    return ComicPageDots(
      count: 4,
      selectedIndex: 1,
      label: 'Pages',
      onChanged: select,
    );
  },
  'ComicStepProgress': (context) =>
      const ComicStepProgress(count: 3, currentStep: 1, name: 'Your order'),
  'ComicNavigationRail': (context) {
    const destinations = [
      ComicNavItem(label: 'Home', short: 'Home', icon: ComicGlyphs.house),
    ];
    void select([Object? a, Object? b]) {}
    return ComicNavigationRail(
      destinations: destinations,
      selectedIndex: 0,
      onDestinationSelected: select,
    );
  },
  'ComicBreadcrumb': (context) {
    void shop([Object? a, Object? b]) {}
    void comics([Object? a, Object? b]) {}
    return ComicBreadcrumb([
      ComicCrumb('Shop', onPressed: shop),
      ComicCrumb('Comics', onPressed: comics),
      const ComicCrumb('Issue 12'),
    ]);
  },
  'ComicPagination': (context) {
    var page = 2;
    void setState(VoidCallback fn) => fn();
    return ComicPagination(
      count: 12,
      page: 2,
      onChanged: (i) => setState(() => page = i),
    );
  },
  'ComicPerson': (context) => const ComicPerson(initials: 'AB', size: 36),
  'ComicPeople': (context) => const ComicPeople([
    ComicPerson(initials: 'AB', size: 28),
    ComicPerson(initials: 'CD', size: 28),
  ]),
  'ComicLineup': (context) => const ComicLineup([
    ComicCast('Sam', isCurrentUser: true),
    ComicCast('Alex'),
  ]),
  'ComicDatePicker': (context) {
    final day = DateTime(2026, 5, 1);
    final opens = DateTime(2026);
    final closes = DateTime(2027);
    void select([Object? a, Object? b]) {}
    return ComicDatePicker(
      value: day,
      firstDate: opens,
      lastDate: closes,
      onChanged: select,
    );
  },
  'ComicTimePicker': (context) {
    void select([Object? a, Object? b]) {}
    return ComicTimePicker(
      value: const ComicTime(19, 30),
      minuteStep: 15,
      onChanged: select,
    );
  },
  'showComicDatePicker': (context) {
    Future<void> example() async {
      final selected = DateTime(2026, 5, 1);
      final day = await showComicDatePicker(context, value: selected);
    }

    return example;
  },
  'showComicTimePicker': (context) {
    Future<void> example() async {
      final time = await showComicTimePicker(
        context,
        value: const ComicTime(19, 30),
      );
    }

    return example;
  },
  'ComicStateLerp': (context) {
    const ink = Color(0xFF000000);
    const icon = ComicGlyphs.house;
    return ComicStateLerp<Color?>(
      value: ink,
      lerp: Color.lerp,
      builder: (context, ink, _) => Icon(icon, color: ink),
    );
  },
  'ComicStateDecoration': (context) {
    const label = Text('Save');
    const shape = RoundedRectangleBorder();
    const fill = Color(0xFFFFFFFF);
    return const ComicStateDecoration(
      decoration: ShapeDecoration(color: fill, shape: shape),
      child: label,
    );
  },
  'ComicPressable': (context) {
    const tile = Text('Issue 12');
    void open([Object? a, Object? b]) {}
    return ComicPressable(onPressed: open, label: 'Issue 12', child: tile);
  },
  'ComicHighlight': (context) {
    final theme = ComicTheme.of(context);
    const indicator = SizedBox(width: 20, height: 20);
    const states = <WidgetState>{};
    return ComicHighlight(
      states: states,
      shape: theme.shapes.small,
      child: indicator,
    );
  },
  'ComicPlated': (context) {
    final theme = ComicTheme.of(context);
    const face = SizedBox(width: 40, height: 24);
    const states = <WidgetState>{};
    return ComicPlated(
      down: states.pressed,
      shape: theme.shapes.small,
      child: face,
    );
  },
  'ComicScreened': (context) {
    const field = Text('A field');
    const enabled = true;
    return const ComicScreened(on: !enabled, child: field);
  },
  'ComicBenDay': (context) {
    final t = ComicTheme.of(context);
    const words = Text('Pow');
    return ComicBenDay(
      color: t.colors.dotTint,
      pitch: 9,
      radius: 2.4,
      child: words,
    );
  },
  'ComicCoverPrint': (context) => const ComicCoverPrint(
    child: ComicLettering('Volume one', style: ComicLetteringStyle.title),
  ),
  'ComicActionLines': (context) {
    final t = ComicTheme.of(context);
    const drawing = SizedBox(width: 40, height: 40);
    return ComicActionLines(color: t.colors.ray, child: drawing);
  },
  'ComicLettering': (context) {
    final t = ComicTheme.of(context);
    return ComicLettering(
      'Volume one',
      size: 60,
      fill: t.colors.paper,
      style: ComicLetteringStyle.title,
    );
  },
  'ComicSfx': (context) {
    final t = ComicTheme.of(context);
    return ComicSfx('Krash!', size: 32, fill: t.colors.sfxOn(2));
  },
  'showComicNavigationDrawer': (context) {
    void example() {
      const items = [
        ComicNavItem(label: 'Home', short: 'Home', icon: ComicGlyphs.house),
      ];
      const at = 0;
      showComicNavigationDrawer<int>(
        context,
        builder: (context) => ComicNavigationDrawer(
          destinations: items,
          selectedIndex: at,
          onDestinationSelected: (i) => Navigator.of(context).pop(i),
        ),
      );
    }

    return example;
  },
  'showComicDialog': (context) {
    void example() {
      showComicDialog<void>(
        context,
        builder: (_) => const ComicDialog(title: 'Keep this issue?'),
      );
    }

    return example;
  },
  'ComicDialog': (context) {
    void remove([Object? a, Object? b]) {}
    return ComicDialog(
      title: 'Remove issue?',
      message: 'This cannot be undone.',
      actions: [ComicButton.filled('Remove', onPressed: remove)],
    );
  },
  'showComicBottomSheet': (context) {
    void example() {
      showComicBottomSheet<void>(
        context,
        builder: (_) =>
            const ComicBottomSheet(title: 'Details', child: Text('Issue 12')),
      );
    }

    return example;
  },
  'ComicBottomSheet': (context) =>
      const ComicBottomSheet(title: 'Details', child: Text('Issue 12')),
  'ComicMenu': (context) {
    void save([Object? a, Object? b]) {}
    return ComicMenu<String>(
      items: const [ComicMenuItem('save', 'Save')],
      onSelected: save,
    );
  },
  'showComicMenu': (context) {
    Future<void> example() async {
      const rect = Rect.fromLTWH(100, 100, 40, 40);
      final value = await showComicMenu(
        context,
        anchor: rect,
        items: const [ComicMenuItem('save', 'Save')],
      );
    }

    return example;
  },
  'ComicMenuAnchor': (context) => ComicMenuAnchor<String>(
    items: const [ComicMenuItem('save', 'Save')],
    builder: (context, open) => ComicButton.filled('More', onPressed: open),
  ),
  'ComicTooltipFace': (context) =>
      const ComicTooltipFace(message: 'Save this issue'),
  'showComicTooltip': (context) {
    void example() {
      const rect = Rect.fromLTWH(100, 100, 40, 40);
      showComicTooltip(context, message: 'Save this issue', anchor: rect);
    }

    return example;
  },
  'ComicTooltip': (context) {
    const icon = ComicGlyphs.house;
    void save([Object? a, Object? b]) {}
    return ComicTooltip(
      message: 'Save this issue',
      child: ComicIconButton(icon, label: 'Save', onPressed: save),
    );
  },
  'ComicSnackBar': (context) {
    void undo([Object? a, Object? b]) {}
    return ComicSnackBar(
      'Saved to your collection',
      actionLabel: 'Undo',
      onAction: undo,
    );
  },
  'showComicSnackBar': (context) {
    void example() {
      void undo([Object? a, Object? b]) {}
      showComicSnackBar(context, 'Saved', actionLabel: 'Undo', onAction: undo);
    }

    return example;
  },
  'ComicToast': (context) =>
      const ComicToast('Link copied', tone: ComicTone.success),
  'showComicToast': (context) {
    void example() {
      showComicToast(context, 'Link copied', tone: ComicTone.success);
    }

    return example;
  },
  'ComicCombobox': (context) {
    void pick([Object? a, Object? b]) {}
    return ComicCombobox<String>(
      label: 'City',
      options: const ['Lisbon', 'London', 'Lyon'],
      onSelected: pick,
    );
  },
  'ComicScreenScrim': (context) {
    const animation = AlwaysStoppedAnimation<double>(1);
    return ComicScreenScrim(
      animation: animation,
      ink: ComicTheme.of(context).colors.scrim,
    );
  },
  'ComicRuled': (context) => const ComicRuled(child: Text('A row')),
  'ComicList': (context) => const ComicList(
    children: [
      ComicKvRow('Fat', '12 g', isFirst: true),
      ComicKvRow('Salt', '1 g'),
    ],
  ),
  'ComicKvRow': (context) => const ComicKvRow('Protein', '26 g', share: '52%'),
  'ComicTotalRow': (context) => const ComicTotalRow('Your share', '€145 each'),
  'ComicListTile': (context) => ComicListTile(
    title: 'Bring the tent',
    subtitle: 'Sat 09:00',
    leading: const ComicPerson(initials: 'AB', size: 28),
    trailing: const ComicTag('Packed'),
    action: ComicButton('Open', size: ComicButtonSize.small, onPressed: () {}),
  ),
  'ComicTimedRow': (context) => const ComicTimedRow(
    '19:30',
    title: 'Doors',
    subtitle: 'Bring a coat',
    trailing: ComicPerson(initials: 'AB', size: 30),
  ),
  'ComicSwitchRow': (context) {
    var on = true;
    void setState(VoidCallback fn) => fn();
    return ComicSwitchRow(
      label: 'Reminders',
      note: 'The evening before',
      value: on,
      onChanged: (v) => setState(() => on = v),
    );
  },
  'ComicFacts': (context) => const ComicFacts([
    ('162 km', 'by road'),
    ('Sleeps 6', '3 bedrooms'),
    ('€145', 'each'),
  ]),
  'ComicFormField': (context) =>
      const ComicFormField('Your name', child: ComicTextField(hint: 'Name')),
  'ComicTheme (shapes)': (context) => ComicTheme.of(context).shapes.medium,
  'ComicAvatar': (context) {
    void example() {
      const url = 'https://example.com/portrait.png';
      const ComicAvatar('NW', name: 'Nia Walker', image: NetworkImage(url));
    }

    return example;
  },
  'ComicAvatarGroup': (context) => const ComicAvatarGroup([
    ComicFace('NW'),
    ComicFace('AK'),
  ], label: 'Contributors'),
  'ComicMeter': (context) =>
      const ComicMeter(label: 'Capacity', value: 35, max: 100, unit: 'pages'),
  'ComicCarouselView': (context) {
    final picks = [(slotId: 'item-1', title: 'First piece')];
    return ComicCarouselView(
      label: 'This week',
      children: [
        for (final p in picks)
          ComicPictureCard(slotId: p.slotId, title: p.title),
      ],
    );
  },
  'ComicBar': (context) => const ComicBar(
    value: 5,
    of: 6,
    ink: ComicBarFill.leading,
    label: 'Pages inked',
    figure: '5 of 6',
  ),
  'ComicBarList': (context) => const ComicBarList(
    of: 27,
    entries: [
      ComicBarEntry('Sam', 25),
      ComicBarEntry('You', 24, isCurrentUser: true),
    ],
  ),
  'ComicTally': (context) => const ComicTally(
    question: 'Which weekend?',
    subtitle: '5 of 6 voted',
    of: 6,
    options: [
      ComicVote('The first', count: 5, isLeading: true, stamp: 'Leads'),
      ComicVote('The second', count: 2),
    ],
    waiting: 'Waiting on one',
    yours: 'You picked 1',
  ),
  'ComicFlow': (context) => const ComicFlow(
    into: 'Sam',
    intoPerson: ComicPerson(initials: 'SD', size: 64),
    intoFigure: '+€317',
    from: [
      ComicFlowFrom('You', 19, figure: '€19', isCurrentUser: true),
      ComicFlowFrom('Alex', 133, figure: '€133'),
    ],
  ),
  'ComicShares': (context) => const ComicShares(
    stamp: 'Paid',
    parts: [
      ComicShare('Rent', 540, figure: '€540', ink: ComicShareFill.lamp),
      ComicShare('Food', 156, figure: '€156'),
    ],
  ),
  'ComicUnits': (context) => const ComicUnits([
    ComicUnitColumn('Oct', 2),
    ComicUnitColumn('Nov', 3, now: true),
  ]),
  'ComicPieChart': (context) => const ComicPieChart(
    centre: '417',
    unit: 'kcal',
    slices: [
      ComicSlice('Carbs', 200, figure: '200', share: '48%'),
      ComicSlice('Fat', 99, figure: '99', share: '24%'),
    ],
  ),
  'ComicSegments': (context) =>
      const ComicSegments([8, 5, 2, 5, 45, 5], long: 4),
  'ComicProgressCells': (context) =>
      const ComicProgressCells(total: 8, completed: 4, started: 2),
  'ComicCover': (context) => const ComicCover(
    masthead: 'Huzzah!',
    subtitle: 'The first',
    emphasis: 'issue!',
    issue: ComicCoverBox('No. 27', 'plans so far'),
    cast: [ComicCast('Sam'), ComicCast('You', isCurrentUser: true)],
  ),
  'ComicSplash': (context) => const ComicSplash(
    title: 'The long weekend',
    caption: 'Meanwhile, by the lake',
    art: ComicArtBand(ground: 2, leading: Icon(ComicGlyphs.house)),
    burst: ComicCoverBurst('23', over: 'In', under: 'days!'),
    facts: [('162 km', 'by road'), ('Sleeps 6', 'three rooms')],
  ),
  'ComicEmptyState': (context) =>
      const ComicEmptyState(title: 'All caught up', body: 'No new messages.'),
  'ComicArtBand': (context) => const ComicArtBand(
    ground: 2,
    leading: Icon(ComicGlyphs.house),
    sfx: 'Crunch!',
  ),
  'ComicEventPanel': (context) => const ComicEventPanel(
    when: 'Sat 14 Nov',
    title: 'Morning walk',
    where: 'From the station',
    leading: Icon(ComicGlyphs.house),
    people: [ComicPerson(initials: 'AB', size: 24)],
    tally: '5 in',
  ),
  'ComicMarkPanel': (context) => const ComicMarkPanel(
    date: 'Sun 8 Nov',
    leading: Icon(ComicGlyphs.house),
    sfx: 'Munch!',
    title: 'Brunch',
    words: 'Two breakfasts. Both for one.',
  ),
  'ComicStepPanel': (context) => const ComicStepPanel(
    number: '1',
    leading: Icon(ComicGlyphs.house),
    sfx: 'Sizzle!',
    words: 'Soften the onions.',
    action: ComicButton('8 min', size: ComicButtonSize.small),
  ),
  'ComicVoicePanel': (context) => const ComicVoicePanel(
    time: 'Tue 21:16',
    words: 'Booked for the fourth.',
    name: 'Sam',
  ),
  'ComicChapterPanel': (context) => const ComicChapterPanel(
    caption: 'Chapter 1',
    title: 'The drive',
    art: ComicArtBand(ground: 2, leading: Icon(ComicGlyphs.house)),
    children: [
      ComicTimedRow('16:00', title: 'Leave', isFirst: true, inset: 14),
    ],
  ),
  'ComicSpeech': (context) => const ComicSpeech(
    person: ComicPerson(initials: 'AB', size: 48),
    text: 'Chili is on me.',
    author: 'Sam · 21:20',
  ),
  'ComicReply': (context) => ComicReply(
    person: const ComicPerson(initials: 'Me', size: 44),
    hint: 'Say something…',
    onSend: () {},
  ),
  'ComicClaim': (context) => const ComicClaim(
    before: 'You owe Sam',
    figure: '€19',
    note: 'Your share of Saturday.',
    person: ComicPerson(initials: 'SD', size: 56),
  ),
  'ComicFigures': (context) => const ComicFigures([
    ('20 min', 'Prep'),
    ('1 h 10', 'Cook'),
    ('1 h 30', 'Total'),
  ], highlightLast: true),
  'ComicAmountRow': (context) => const ComicAmountRow(
    '2 tsp',
    'smoked paprika',
    note: 'or sweet',
    isFirst: true,
  ),
  'ComicLedgerRow': (context) => const ComicLedgerRow(
    date: 'Tue 10 Nov',
    title: 'Birch Cabin',
    subtitle: '€90 each',
    value: '€540',
    isFirst: true,
  ),
  'ComicSlider': (context) {
    const budget = 200.0;
    void select([Object? a, Object? b]) {}
    return ComicSlider(
      label: 'Budget',
      value: budget,
      max: 500,
      divisions: 10,
      onChanged: select,
    );
  },
  'comicInsetShape': (context) {
    final theme = ComicTheme.of(context);
    return comicInsetShape(theme.shapes.medium, 3);
  },
  'comicCappedShape': (context) {
    final theme = ComicTheme.of(context);
    return comicCappedShape(theme.shapes.small, 7);
  },
  'comicOutsetShape': (context) {
    final theme = ComicTheme.of(context);
    return comicOutsetShape(theme.shapes.small, theme.focus.gap);
  },
  'AnimatedComicShape': (context) {
    const fill = Color(0xFFFFFFFF);
    final pressed = !context.mounted;
    return AnimatedComicShape(
      shape: pressed
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            )
          : const RoundedRectangleBorder(),
      builder: (context, shape) => DecoratedBox(
        decoration: ShapeDecoration(color: fill, shape: shape!),
      ),
    );
  },
  'ComicStyleOf': (context) {
    void example() {
      const states = <WidgetState>{};
      const style = ComicStyle();
      final colors = ComicTheme.of(context).colors;
      final look = ComicStyleOf([
        style,
        ComicTheme.of(context).chipTheme,
      ], states);
      final fill = look.fill ?? colors.card;
    }

    return example;
  },
  'ComicStyleOf (2)': (context) {
    void example() {
      final theme = ComicTheme.of(context);
      const style = ComicStyle();
      final look = ComicStyleOf([style, theme.cardTheme], const {});
      final rim = comicRim(theme, look, theme.colors.outline);
    }

    return example;
  },
  'ComicToneMark': (context) => const ComicToneMark(ComicTone.warning),
  'ComicBanner': (context) =>
      const ComicBanner('Your issue is ready', tone: ComicTone.success),
  'ComicCircularProgressIndicator': (context) =>
      const ComicCircularProgressIndicator(value: .6, label: 'Uploading'),
  'ComicLinearProgressIndicator': (context) =>
      const ComicLinearProgressIndicator(value: .4, label: 'Reading progress'),
  'ComicSkeleton': (context) => const ComicSkeleton(width: 160, height: 20),
  'ComicBadge': (context) => const ComicBadge(12, label: 'Unread issues'),
  'ComicSuccessState': (context) =>
      const ComicSuccessState(title: 'All set', message: 'Your issue is saved'),
  'ComicThemeData (5)': (context) {
    void example() {
      final night = ComicThemeData.offset(Brightness.dark);
      final other = night.copyWith(
        colors: ComicThemeData.sunday(Brightness.dark).colors,
      );
    }

    return example;
  },
  'ComicThemeData (6)': (context) => ComicThemeData.from(
    primary: const Color(0xffa32d67),
    caption: const Color(0xffffdf57),
    shade: const Color(0xff325e98),
  ),
  'MaterialApp (2)': (context) {
    void example() {
      MaterialApp(
        builder: (context, child) => ComicTheme(
          data: ComicThemeData.preset(
            'offset',
            MediaQuery.platformBrightnessOf(context),
          ),
          child: child!,
        ),
        home: const IssuePage(),
      );
    }

    return example;
  },
  'ComicTheme': (context) => ComicTheme(
    data: ComicThemeData.preset('pulp', Brightness.dark),
    child: const ComicPanel(child: Text('Meanwhile...')),
  ),
  'AnimatedComicTheme': (context) {
    const page = Text('A page');
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedComicTheme(
      data: ComicThemeData.preset(
        'offset',
        dark ? Brightness.dark : Brightness.light,
      ),
      child: page,
    );
  },
  'comicPageTransitions': (context) {
    void example() {
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: comicPageTransitions,
          ),
        ),
        home: const Text('The first page'),
      );
    }

    return example;
  },
  'ComicDotsScope': (context) =>
      const ComicDotsScope(child: Text('Over the halftone')),
  'ComicLetteringScope': (context) =>
      const ComicLetteringScope(Colors.white, child: Text('On the lamp')),
};

void main() {
  tearDown(() {
    for (final dispose in _disposers) {
      dispose();
    }
    _disposers.clear();
  });

  testDocExamples(
    self: 'test/doc_examples_test.dart',
    examples: _examples,
    // In drip, Comic's lib is design_system/, beside ui_core's and the app's.
    lib: Directory('lib/design_system').existsSync()
        ? 'lib/design_system'
        : 'lib',
    // art.dart and shell.dart stay in drip (the package leaves them out), so
    // their examples can't be written out in the package's copy of this file.
    skip: const {'comic_parts.dart', 'art.dart', 'shell.dart'},
    wrap: (child) => TickerMode(
      enabled: false,
      child: MaterialApp(
        home: ComicHost(
          light: ComicThemeData.offset(),
          // Flutter's own fields, which some examples dress in Comic, stand on a Material.
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    ),
  );
}
